// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   renderer.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/18 10:19:53 by pollivie          #+#    #+#             //
//   Updated: 2024/07/18 10:19:54 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const fdf_type = @import("type.zig");
const mapdata = @import("map_data.zig");
const cam = @import("camera.zig");
const backend = @import("backend.zig");
const MlxBackend = backend.MlxBackend;
const MapDataError = mapdata.MapDataError;
const MapData = mapdata.MapData;
const ArrayList = std.ArrayList;
const AllocatorError = Allocator.Error;
const Allocator = std.mem.Allocator;
const Vec3 = fdf_type.Vec3;
const Color = fdf_type.Color;
const Pixel = fdf_type.Pixel;
const Camera = cam.Camera;
const CameraControl = cam.CameraControl;
const COS30: f32 = 0.86602540378;
const SIN30: f32 = 0.5;
const assert = std.debug.assert;

pub const RendererConfig = struct {
    cam_position: Vec3,
    cam_cos_rota: Vec3,
    cam_sin_rota: Vec3,
    cam_zoom: f32,
    cam_scale: f32,
    height: usize,
    width: usize,
    screen_height: usize,
    screen_width: usize,
    world_colors: []const i32,
    world_z_axis: []const i32,

    pub fn init(map_data: *const MapData, camera: *const Camera, screen_width: usize, screen_height: usize) RendererConfig {
        return RendererConfig{
            .cam_position = camera.getPositition(),
            .cam_cos_rota = camera.getCosRotations(),
            .cam_sin_rota = camera.getSinRotations(),
            .cam_zoom = camera.getZoomLvl(),
            .cam_scale = camera.getScaleLvl(),
            .world_colors = map_data.getWorldColors(),
            .world_z_axis = map_data.getWorldCoord(),
            .width = map_data.getWidth(),
            .height = map_data.getHeight(),
            .screen_width = screen_width,
            .screen_height = screen_height,
        };
    }

    pub fn debug_log(cfg: *RendererConfig) void {
        std.log.debug("RENDERER CONFIG", .{});
        std.log.debug("cam_position {any}", .{cfg.cam_position});
        std.log.debug("cam_cos_rota {any}", .{cfg.cam_cos_rota});
        std.log.debug("cam_sin_rota {any}", .{cfg.cam_sin_rota});
        std.log.debug("cam_zoom {any}", .{cfg.cam_zoom});
        std.log.debug("cam_scale {any}", .{cfg.cam_scale});
        std.log.debug("height {d}", .{cfg.height});
        std.log.debug("width {d}", .{cfg.width});
        std.log.debug("world_colors {*}", .{&cfg.world_colors});
        std.log.debug("world_z_axis {*}", .{&cfg.world_z_axis});
    }
};

pub const Renderer = struct {
    arena: Allocator,
    mlx_backend: *MlxBackend,

    rendered: ArrayList(Pixel),
    config: *RendererConfig,

    pub fn init(arena: Allocator, mlx_backend: *MlxBackend, config: *RendererConfig) Renderer {
        assert(config.height != 0);
        assert(config.width != 0);
        return Renderer{
            .arena = arena,
            .mlx_backend = mlx_backend,
            .config = config,
            .rendered = ArrayList(Pixel).init(arena),
        };
    }

    pub fn reset(renderer: *Renderer, config: *RendererConfig) void {
        renderer.mlx_backend.clearImageBuffer();
        renderer.rendered.deinit();
        renderer.rendered = ArrayList(Pixel).initCapacity(renderer.arena, config.height * config.width) catch unreachable;
        renderer.config = config;
    }

    pub fn render(renderer: *Renderer) void {
        const height = renderer.config.height;
        const width = renderer.config.width;
        const center_scale_x: f32 = @floatFromInt(renderer.config.screen_height);
        const center_scale_y: f32 = @floatFromInt(renderer.config.screen_width);
        const config = renderer.config;
        const world = config.world_z_axis;
        const color = config.world_colors;

        assert(height != 0);
        assert(width != 0);
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                const z: f32 = @floatFromInt(world[(y) * width + (x)]);
                const world_point = Vec3{
                    .x = @floatFromInt(x),
                    .y = @floatFromInt(y),
                    .z = (z * config.cam_scale),
                };
                const zoomed_point = world_point.mulScalar(config.cam_zoom);
                const translated_point = zoomed_point.add(config.cam_position);
                const rotated_point = translated_point.rotXYZ(config.cam_cos_rota, config.cam_sin_rota);
                const projected_pixel = Pixel{
                    .x = @intFromFloat(((center_scale_x - @floor((rotated_point.x - rotated_point.y) * COS30)) * 0.5)),
                    .y = @intFromFloat(((center_scale_y - @floor(((-rotated_point.z) + (rotated_point.x + rotated_point.y) * SIN30))) * 0.5)),
                    .color = color[(y) * width + (x)],
                };
                renderer.rendered.append(projected_pixel) catch unreachable;
            }
        }
    }

    pub fn draw(renderer: *Renderer) void {
        const height = renderer.config.height;
        const width = renderer.config.width;
        assert(height != 0);
        assert(width != 0);

        var y: usize = 0;
        while (y < height - 1) : (y += 1) {
            var x: usize = 0;
            while (x < width - 1) : (x += 1) {
                renderer.drawLine(renderer.rendered.items[(y) * width + (x)], renderer.rendered.items[(y) * width + (x + 1)]);
                renderer.drawLine(renderer.rendered.items[(y) * width + (x)], renderer.rendered.items[(y + 1) * width + (x)]);
            }
        }
    }

    fn drawLine(renderer: *Renderer, start: Pixel, end: Pixel) void {
        const dx: i32 = end.x - start.x;
        const dy: i32 = end.y - start.y;
        const abs_dx: i32 = if (dx < 0) -dx else dx;
        const abs_dy: i32 = if (dy < 0) -dy else dy;

        var x: i32 = start.x;
        var y: i32 = start.y;

        const sx: i32 = if (start.x < end.x) 1 else -1;
        const sy: i32 = if (start.y < end.y) 1 else -1;

        var err: i32 = if (abs_dx > abs_dy) @divFloor(abs_dx, 2) else -@divFloor(abs_dy, 2);

        while (true) {
            renderer.mlx_backend.putPixelImage(x, y, start.color);
            if (x == end.x and y == end.y) break;

            const e2: i32 = err;
            if (e2 > -abs_dx) {
                err -= abs_dy;
                x += sx;
            }
            if (e2 < abs_dy) {
                err += abs_dx;
                y += sy;
            }
        }
    }

    pub fn debug_log(renderer: *const Renderer) void {
        std.log.debug("RENDERER", .{});
        std.log.debug("arena = {*}", .{&renderer.arena});
        std.log.debug("mlx_backend = {*}", .{renderer.mlx_backend});
        std.log.debug("rendered = {*}", .{&renderer.rendered});
        std.log.debug("config = {*}", .{renderer.config});
    }
};
