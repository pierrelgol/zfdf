// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   controller.zig                                     :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/18 12:31:32 by pollivie          #+#    #+#             //
//   Updated: 2024/07/18 12:31:33 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const fdf_type = @import("type.zig");
const mapdata = @import("map_data.zig");
const cam = @import("camera.zig");
const backend = @import("backend.zig");
const rend = @import("renderer.zig");
const fdf_config = @import("parsing.zig");
const MlxBackend = backend.MlxBackend;
const MapDataError = mapdata.MapDataError;
const MapData = mapdata.MapData;
const ArrayList = std.ArrayList;
const AllocatorError = Allocator.Error;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const Vec3 = fdf_type.Vec3;
const Color = fdf_type.Color;
const Pixel = fdf_type.Pixel;
const Camera = cam.Camera;
const CameraControl = cam.CameraControl;
const RendererConfig = rend.RendererConfig;
const Renderer = rend.Renderer;
const Config = fdf_config.Config;

pub const ControllerCommand = enum(i32) {
    default = 0,

    camera_move_left = 97,
    camera_move_right = 100,
    camera_move_up = 119,
    camera_move_down = 115,
    camera_move_forward = 116,
    camera_move_backward = 103,

    camera_pitch_up = 121,
    camera_pitch_down = 104,
    camera_yaw_left = 117,
    camera_yaw_right = 106,
    camera_roll_left = 111,
    camera_roll_right = 108,

    camera_zoom_in = 61,
    camera_zoom_out = 45,

    camera_scale_in = 91,
    camera_scale_out = 93,

    camera_reset = 114,

    controller_quit = 65307,

    pub fn enumFromI32(keycode: i32) ControllerCommand {
        return switch (keycode) {
            0 => ControllerCommand.default,
            97 => ControllerCommand.camera_move_left,
            100 => ControllerCommand.camera_move_right,
            119 => ControllerCommand.camera_move_up,
            115 => ControllerCommand.camera_move_down,
            116 => ControllerCommand.camera_move_forward,
            103 => ControllerCommand.camera_move_backward,
            121 => ControllerCommand.camera_pitch_up,
            104 => ControllerCommand.camera_pitch_down,
            117 => ControllerCommand.camera_yaw_left,
            106 => ControllerCommand.camera_yaw_right,
            111 => ControllerCommand.camera_roll_left,
            108 => ControllerCommand.camera_roll_right,
            61 => ControllerCommand.camera_zoom_in,
            45 => ControllerCommand.camera_zoom_out,
            91 => ControllerCommand.camera_scale_in,
            93 => ControllerCommand.camera_scale_out,
            114 => ControllerCommand.camera_reset,
            65307 => ControllerCommand.controller_quit,
            else => ControllerCommand.default,
        };
    }
};

pub fn OnEventQuit(argument: ?*anyopaque) callconv(.C) c_int {
    const maybe_controller = @as(?*Controller, @alignCast(@ptrCast(argument)));
    const controller = maybe_controller orelse return (0);
    _ = controller.mlx.loopEnd();
    return (0);
}

pub fn OnEvenKeyPressed(keycode: i32, argument: ?*anyopaque) callconv(.C) c_int {
    const maybe_controller = @as(?*Controller, @alignCast(@ptrCast(argument)));
    const controller = maybe_controller orelse return (0);
    std.log.info("keypressed : {d}", .{keycode});
    controller.event = ControllerCommand.enumFromI32(keycode);

    switch (controller.event) {
        .camera_move_left => controller.camera.move(.move_left, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_right => controller.camera.move(.move_right, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_up => controller.camera.move(.move_up, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_down => controller.camera.move(.move_down, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_forward => controller.camera.move(.move_forward, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_backward => controller.camera.move(.move_backward, controller.move_step + controller.camera.zoom_lvl),

        .camera_pitch_up => controller.camera.rotate(.pitch_up, controller.rota_step + controller.camera.zoom_lvl),
        .camera_pitch_down => controller.camera.rotate(.pitch_down, controller.rota_step + controller.camera.zoom_lvl),
        .camera_roll_left => controller.camera.rotate(.roll_left, controller.rota_step + controller.camera.zoom_lvl),
        .camera_roll_right => controller.camera.rotate(.roll_right, controller.rota_step + controller.camera.zoom_lvl),
        .camera_yaw_left => controller.camera.rotate(.yaw_left, controller.rota_step + controller.camera.zoom_lvl),
        .camera_yaw_right => controller.camera.rotate(.yaw_right, controller.rota_step + controller.camera.zoom_lvl),

        .camera_zoom_in => controller.camera.zoom(.zoom_in, controller.zoom_step),
        .camera_zoom_out => controller.camera.zoom(.zoom_out, controller.zoom_step),

        .camera_scale_in => controller.camera.scale(.scale_in, controller.scal_step),
        .camera_scale_out => controller.camera.scale(.scale_out, controller.scal_step),
        .camera_reset => controller.camera.reset(),
        .controller_quit => {
            return OnEventQuit(argument);
        },
        else => return (0),
    }
    controller.renderer_config = RendererConfig.init(controller.map_data, &controller.camera);
    controller.renderer.render();
    controller.renderer.draw();
    _ = controller.arena.reset(.retain_capacity);
    controller.renderer.reset(&controller.renderer_config);
    return (0);
}

pub fn OnEvenKeyPressedLive(keycode: i32, argument: ?*anyopaque) callconv(.C) c_int {
    const maybe_controller = @as(?*Controller, @alignCast(@ptrCast(argument)));
    const controller = maybe_controller orelse return (0);
    std.log.info("keypressed : {d}", .{keycode});
    controller.event = ControllerCommand.enumFromI32(keycode);

    switch (controller.event) {
        .camera_move_left => controller.camera.move(.move_left, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_right => controller.camera.move(.move_right, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_up => controller.camera.move(.move_up, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_down => controller.camera.move(.move_down, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_forward => controller.camera.move(.move_forward, controller.move_step + controller.camera.zoom_lvl),
        .camera_move_backward => controller.camera.move(.move_backward, controller.move_step + controller.camera.zoom_lvl),

        .camera_pitch_up => controller.camera.rotate(.pitch_up, controller.rota_step + controller.camera.zoom_lvl),
        .camera_pitch_down => controller.camera.rotate(.pitch_down, controller.rota_step + controller.camera.zoom_lvl),
        .camera_roll_left => controller.camera.rotate(.roll_left, controller.rota_step + controller.camera.zoom_lvl),
        .camera_roll_right => controller.camera.rotate(.roll_right, controller.rota_step + controller.camera.zoom_lvl),
        .camera_yaw_left => controller.camera.rotate(.yaw_left, controller.rota_step + controller.camera.zoom_lvl),
        .camera_yaw_right => controller.camera.rotate(.yaw_right, controller.rota_step + controller.camera.zoom_lvl),

        .camera_zoom_in => controller.camera.zoom(.zoom_in, controller.zoom_step),
        .camera_zoom_out => controller.camera.zoom(.zoom_out, controller.zoom_step),

        .camera_scale_in => controller.camera.scale(.scale_in, controller.scal_step),
        .camera_scale_out => controller.camera.scale(.scale_out, controller.scal_step),
        .camera_reset => controller.camera.reset(),
        .controller_quit => {
            return OnEventQuit(argument);
        },
        else => return (0),
    }
    return (0);
}

pub const Controller = struct {
    const name: []const u8 = "fdf";
    move_step: f32,
    rota_step: f32,
    zoom_step: f32,
    scal_step: f32,
    allocator: Allocator,
    arena: ArenaAllocator,
    screen_height: usize,
    screen_width: usize,
    map_data: *MapData,
    mlx: *MlxBackend,
    camera: Camera,
    renderer_config: RendererConfig,
    renderer: Renderer,
    event: ControllerCommand,
    timer: std.time.Timer,
    time_start: i128,
    time_end: i128,

    pub fn init(allocator: Allocator, config: Config, map_data: *MapData) !*Controller {
        var self: *Controller = try allocator.create(Controller);
        errdefer allocator.destroy(self);

        self.*.arena = ArenaAllocator.init(allocator);
        errdefer self.*.arena.deinit();
        const screen_width: i32 = @intCast(@as(usize, config.screen_width));
        const screen_height: i32 = @intCast(@as(usize, config.screen_height));
        const screen_center_x: f32 = @as(f32, @floatFromInt(screen_width)) / @as(f32, 2.0);
        const screen_center_y: f32 = @as(f32, @floatFromInt(screen_height)) / @as(f32, 2.0);
        const map_center_x: f32 = @as(f32, @floatFromInt(map_data.world_width)) / @as(f32, 2.0);
        const map_center_y: f32 = @as(f32, @floatFromInt(map_data.world_height)) / @as(f32, 2.0);

        self.screen_height = @intCast(screen_height);
        self.screen_width = @intCast(screen_width);
        self.*.allocator = allocator;
        self.*.mlx = try MlxBackend.init(allocator, screen_width, screen_height, name);
        self.*.map_data = map_data;
        self.*.camera = Camera.init(.{ .x = (screen_center_x - map_center_x), .y = -(screen_center_y - map_center_y), .z = 1 }, .{ .x = 0, .y = 0, .z = 0 }, 1, 0.01);
        self.*.renderer_config = RendererConfig.init(map_data, &self.camera, config.screen_width, config.screen_height);
        self.event = .default;
        self.*.renderer = Renderer.init(self.arena.allocator(), self.*.mlx, &self.*.renderer_config);
        self.move_step = 30.0;
        self.rota_step = 10.0;
        self.zoom_step = 0.5;
        self.scal_step = 0.1;
        return (self);
    }

    pub fn renderingLoopBegin(controller: *Controller) void {
        const opaque_handle: ?*anyopaque = @alignCast(@ptrCast(controller));
        controller.renderer_config = RendererConfig.init(controller.map_data, &controller.camera, controller.screen_width, controller.screen_height);
        controller.renderer.render();
        controller.renderer.draw();
        _ = controller.arena.reset(.retain_capacity);
        controller.renderer.reset(&controller.renderer_config);
        _ = controller.mlx.genericHookOne(@as(i32, 17), @as(i32, 9), OnEventQuit, opaque_handle);
        _ = controller.mlx.keyHookTwo(OnEvenKeyPressed, opaque_handle);
        _ = controller.mlx.loopStart();
    }

    pub fn renderingLoopLiveBegin(controller: *Controller) void {
        const opaque_handle: ?*anyopaque = @alignCast(@ptrCast(controller));
        controller.renderer_config = RendererConfig.init(controller.map_data, &controller.camera, controller.screen_width, controller.screen_height);
        _ = controller.arena.reset(.retain_capacity);
        controller.renderer.reset(&controller.renderer_config);
        _ = controller.mlx.genericHookOne(@as(i32, 17), @as(i32, 9), OnEventQuit, opaque_handle);
        _ = controller.mlx.keyHookTwo(OnEvenKeyPressedLive, opaque_handle);
        _ = controller.mlx.loopHookOne(renderingLoopLive, opaque_handle);
        _ = controller.mlx.loopStart();
    }

    pub fn renderingLoopLive(argument: ?*anyopaque) callconv(.C) c_int {
        const maybe_controller = @as(?*Controller, @alignCast(@ptrCast(argument)));
        const controller = maybe_controller orelse return (0);
        controller.time_start = std.time.nanoTimestamp();
        controller.renderer_config = RendererConfig.init(controller.map_data, &controller.camera, controller.screen_width, controller.screen_height);
        _ = controller.arena.reset(.retain_capacity);
        controller.renderer.reset(&controller.renderer_config);
        controller.renderer.render();
        controller.renderer.draw();
        controller.time_end = std.time.nanoTimestamp();
        _ = controller.mlx.putImageToWindow(0, 0);
        _ = controller.mlx.doSync();
        const delta_time_ns = controller.time_end - controller.time_start;
        const delta_time_s = @as(f32, @floatFromInt(delta_time_ns)) / std.time.ns_per_s;
        const fps = 1 / delta_time_s;
        std.debug.print("curr fps = {d}\n", .{fps});
        var fps_str_buf: [64:0]u8 = undefined;
        if (std.fmt.bufPrintZ(&fps_str_buf, "{d}", .{fps})) |result| {
            const fps_str: [*:0]u8 = result[0.. :0].ptr;
            _ = controller.mlx.stringPut(fps_str, 930, 20);
        } else |_| {}
        return (0);
    }

    pub fn deinit(controller: *Controller) void {
        const allocator = controller.allocator;
        _ = controller.arena.reset(.free_all);
        controller.arena.deinit();
        controller.*.mlx.deinit();
        allocator.destroy(controller);
    }

    pub fn debug_log(controller: *Controller) void {
        std.log.debug("CONTROLLER", .{});
        std.log.debug("allocator = {*}", .{&controller.allocator});
        std.log.debug("arena = {*}", .{&controller.arena});
        std.log.debug("mlx {*}", .{controller.mlx});
        controller.map_data.debug_log();
        controller.camera.debug_log();
        controller.renderer_config.debug_log();
        controller.renderer.debug_log();
    }
};
