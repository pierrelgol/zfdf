// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   controller.zig                                     :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/17 12:49:33 by pollivie          #+#    #+#             //
//   Updated: 2024/07/17 12:49:33 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const backend = @import("backend.zig");
const ctype = @import("type.zig");
const map = @import("map.zig");
const rend = @import("renderer.zig");
const MlxBackend = backend.MlxBackend;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const MapError = map.MapError;
const Map = map.Map;
const Pixel = ctype.Pixel;
const Color = ctype.Color;
const Vec3 = ctype.Vec3;
const RenderingParameters = rend.RenderingParameters;
const Renderer = rend.Renderer;
const DEG2RAD = std.math.deg_per_rad;

pub const Camera = struct {
    position: Vec3,
    rotation: Vec3,
    zoom: f32,
    move_step: f32,
    rotate_step: f32,

    pub const Move = enum {
        forward,
        backward,
        left,
        right,
        up,
        down,
    };

    pub const Rotate = enum {
        pitch_up,
        pitch_down,
        roll_left,
        roll_right,
        yaw_more,
        yaw_less,
    };

    pub fn init(move_step: f32, rotate_step: f32) Camera {
        return Camera{
            .position = Vec3.init(0, 0, 0),
            .rotation = Vec3.init(0, 0, 0),
            .zoom = 1.0,
            .move_step = move_step,
            .rotate_step = rotate_step,
        };
    }

    pub fn move(self: *Camera, action: Move) void {
        const step = self.move_step;
        const offset_vec = switch (action) {
            .left => Vec3{ .x = -step, .y = 0, .z = 0 },
            .right => Vec3{ .x = step, .y = 0, .z = 0 },
            .up => Vec3{ .x = 0, .y = -step, .z = 0 },
            .down => Vec3{ .x = 0, .y = step, .z = 0 },
            .forward => Vec3{ .x = 0, .y = 0, .z = -step },
            .backward => Vec3{ .x = 0, .y = 0, .z = step },
        };
        self.position.add(offset_vec);
    }

    pub fn rotate(self: *Camera, action: Rotate) void {
        const step = self.rotate_step;
        const offset_vec = switch (action) {
            .pitch_up => Vec3{ .x = -step, .y = 0, .z = 0 },
            .pitch_down => Vec3{ .x = step, .y = 0, .z = 0 },
            .roll_left => Vec3{ .x = 0, .y = -step, .z = 0 },
            .roll_right => Vec3{ .x = 0, .y = step, .z = 0 },
            .yaw_more => Vec3{ .x = 0, .y = 0, .z = -step },
            .yaw_less => Vec3{ .x = 0, .y = 0, .z = step },
        };
        self.position.add(offset_vec);
    }

    pub fn zoom(self: *Camera, amount: f32) void {
        self.*.zoom += amount;
    }

    pub fn fillRenderingParameters(self: *Camera, out_parameters: *RenderingParameters) void {
        out_parameters.translation = self.position;
        out_parameters.cos_rotates = Vec3{
            .x = @cos(self.rotation.x * DEG2RAD),
            .y = @cos(self.rotation.y * DEG2RAD),
            .z = @cos(self.rotation.z * DEG2RAD),
        };
        out_parameters.sin_rotates = Vec3{
            .x = @sin(self.rotation.x * DEG2RAD),
            .y = @sin(self.rotation.y * DEG2RAD),
            .z = @sin(self.rotation.z * DEG2RAD),
        };
        out_parameters.zoom_level = self.zoom;
    }
};

pub const CommandCode = enum {
    ignore,
    move_left,
    move_right,
    move_up,
    move_down,
    move_forward,
    move_backward,
    rota_pitch_more,
    rota_pitch_less,
    rota_roll_more,
    rota_roll_less,
    rota_yaw_more,
    rota_yaw_less,
    zoom_more,
    zoom_less,
    scale_more,
    scale_less,
    reset_state,
    change_projection,
    quit,
};

pub const FdfController = struct {
    const name: []const u8 = "fdf";
    allocator: Allocator,
    camera: Camera,
    height: i32,
    width: i32,
    input: CommandCode,
    map_input: *Map,
    mlx: *MlxBackend,
    rendering_parameters: RenderingParameters,
    rendered_buffer: ?[][]Pixel,
    renderer: *Renderer,
    is_dirty: bool,

    pub fn init(allocator: Allocator, map_data: []const u8, width: i32, height: i32) (Allocator.Error || MapError)!*FdfController {
        const self = try allocator.create(FdfController);
        self.*.allocator = allocator;
        self.*.height = height;
        self.*.width = width;
        self.*.camera = Camera.init(10.0, 1.0);
        self.*.rendering_parameters = RenderingParameters{
            .screen_width = 0,
            .screen_height = 0,
            .screen_center = Vec3.init(200, 200, 1),
            .translation = Vec3.init(500, 500, 1),
            .sin_rotates = Vec3.init(1, 1, 1),
            .cos_rotates = Vec3.init(1, 1, 1),
            .zoom_level = 1.0,
        };
        self.*.camera.fillRenderingParameters(&self.rendering_parameters);
        self.*.map_input = try Map.initWithCapacity(allocator, height, width);
        try Map.parse(self.map_input, map_data);
        self.*.renderer = try Renderer.init(allocator, self.map_input, self.rendering_parameters);
        self.*.mlx = try MlxBackend.init(allocator, 800, 600, name);
        self.is_dirty = false;
        return (self);
    }

    pub fn startRendering(self: *FdfController) !void {
        while (true) {
            if (self.is_dirty) {
                try self.renderer.reset();
                self.is_dirty = false;
            }
            if (try self.renderer.render()) |rendered| {
                var y: usize = 0;
                while (y < self.height) : (y += 1) {
                    var x: usize = 0;
                    while (x < self.width) : (x += 1) {
                        const pixel = rendered[y][x];
                        self.mlx.putPixelImage(pixel.x, pixel.y, pixel.color);
                    }
                }
                self.is_dirty = true;
                _ = self.mlx.putImageToWindow(0, 0);
                _ = self.mlx.doSync();
            }
        }
    }

    pub fn deinit(self: *FdfController) void {
        const allocator = self.allocator;
        self.renderer.deinit();
        self.map_input.deinit();
        self.mlx.deinit();
        allocator.destroy(self);
    }
};
