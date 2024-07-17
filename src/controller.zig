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
        self.position = self.position.add(offset_vec);
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
        self.rotation = self.rotation.add(offset_vec);
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

pub const CommandCode = enum(u32) {
    ignore = 0,
    move_left = 65361,
    move_right = 65363,
    move_up = 65362,
    move_down = 65364,
    move_forward = 119,
    move_backward = 115,
    rota_pitch_more = 97,
    rota_pitch_less = 100,
    rota_roll_more = 112,
    rota_roll_less = 101,
    rota_yaw_more = 777,
    rota_yaw_less = 776,
    zoom_more = 61,
    zoom_less = 45,
    scale_more = 999,
    scale_less = 998,
    reset_state = 997,
    change_projection = 888,
    quit = 65307,

    pub fn toEnum(keycode: i32) CommandCode {
        return switch (keycode) {
            0 => return .ignore,
            65361 => return .move_left,
            65363 => return .move_right,
            65362 => return .move_up,
            65364 => return .move_down,
            119 => return .move_forward,
            115 => return .move_backward,
            97 => return .rota_pitch_more,
            100 => return .rota_pitch_less,
            112 => return .rota_roll_more,
            101 => return .rota_roll_less,
            777 => return .rota_yaw_more,
            776 => return .rota_yaw_less,
            61 => return .zoom_more,
            45 => return .zoom_less,
            999 => return .scale_more,
            998 => return .scale_less,
            997 => return .reset_state,
            888 => return .change_projection,
            65307 => return .quit,
            else => .ignore,
        };
    }
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
            .screen_center = Vec3.init(400, 300, 1),
            .translation = Vec3.init(0, 0, 0),
            .sin_rotates = Vec3.init(30, 20, 0),
            .cos_rotates = Vec3.init(30, 20, 0),
            .zoom_level = 1.5,
        };
        self.*.camera.fillRenderingParameters(&self.rendering_parameters);
        self.*.map_input = try Map.initWithCapacity(allocator, height, width);
        try Map.parse(self.map_input, map_data);
        self.*.renderer = try Renderer.init(allocator, self.map_input, self.rendering_parameters);
        self.*.mlx = try MlxBackend.init(allocator, 1920, 1080, name);
        self.is_dirty = false;
        return (self);
    }

    pub fn fdfKeyHandler(keycode: i32, arg: ?*anyopaque) callconv(.C) c_int {
        const maybe_fdf_controller = @as(?*FdfController, @alignCast(@ptrCast(arg)));
        const fdf_controller = maybe_fdf_controller orelse return (0);
        const action = CommandCode.toEnum(keycode);
        switch (action) {
            .ignore => return (0),
            .move_left => fdf_controller.camera.move(.left),
            .move_right => fdf_controller.camera.move(.right),
            .move_up => fdf_controller.camera.move(.up),
            .move_down => fdf_controller.camera.move(.down),
            .move_forward => fdf_controller.camera.move(.forward),
            .move_backward => fdf_controller.camera.move(.backward),
            .zoom_more => fdf_controller.camera.zoom += 1,
            .zoom_less => fdf_controller.camera.zoom -= 1,
            .rota_pitch_more => fdf_controller.camera.rotate(.pitch_up),
            .rota_pitch_less => fdf_controller.camera.rotate(.pitch_down),
            .rota_roll_more => fdf_controller.camera.rotate(.roll_left),
            .rota_roll_less => fdf_controller.camera.rotate(.roll_right),
            .rota_yaw_more => fdf_controller.camera.rotate(.yaw_more),
            .rota_yaw_less => fdf_controller.camera.rotate(.yaw_less),
            .quit => fdf_controller.deinitAndDie(),
            else => return (0),
        }
        fdf_controller.draw();
        return (0);
    }

    pub fn on_program_quit(arg: ?*anyopaque) callconv(.C) c_int {
        const maybe_fdf_controller = @as(?*FdfController, @alignCast(@ptrCast(arg)));
        const fdf_controller = maybe_fdf_controller orelse return (0);
        fdf_controller.deinitAndDie();
        return (0);
    }

    pub fn startRendering(self: *FdfController) !void {
        _ = self.mlx.genericHookOne(17, 9, on_program_quit, @alignCast(@ptrCast(self)));
        _ = self.mlx.keyHookTwo(fdfKeyHandler, @alignCast(@ptrCast(self)));
        _ = self.mlx.loopStart();
    }

    pub fn clear(self: *FdfController) void {
        var height: i32 = 0;
        while (height < self.mlx.height) : (height += 1) {
            var width: i32 = 0;
            while (width < self.mlx.width) : (width += 1) {
                self.mlx.putPixelImage(height, width, 0x00_00_00_00);
            }
        }
        self.renderer.reset() catch unreachable;
        self.is_dirty = false;
    }

    pub fn draw(self: *FdfController) void {
        self.clear();
        self.camera.fillRenderingParameters(&self.renderer.parameters);
        const maybe_rendered = self.renderer.render() catch unreachable;
        const rendered = maybe_rendered orelse unreachable;
        var height: usize = 0;
        while (height < self.height - 1) : (height += 1) {
            var width: usize = 0;
            while (width < self.width - 1) : (width += 1) {
                if (height + 1 < self.height and height + 1 < self.mlx.dheight)
                    self.drawLine(rendered[height][width], rendered[height + 1][width]);
                if (width + 1 < self.width and width + 1 < self.mlx.dwidth)
                    self.drawLine(rendered[height][width], rendered[height][width + 1]);
            }
        }
        self.is_dirty = true;
        _ = self.mlx.putImageToWindow(0, 0);
        _ = self.mlx.doSync();
    }

    pub fn drawLine(self: *FdfController, start: Pixel, end: Pixel) void {
        var x0 = start.x;
        var y0 = start.y;
        const x1 = end.x;
        const y1 = end.y;
        const dx: u32 = @abs(x1 - x0);
        const dy: u32 = @abs(y1 - y0);
        const sx: i32 = if (x0 < x1) 1 else -1;
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err = dx + dy;
        while (x0 != x1 and y0 != y1) {
            self.mlx.putPixelImage(x0, y0, 0x00FFFFFF);
            const e2 = 2 * err;
            if (e2 >= dy) {
                if (x0 == x1) break;
                err += dy;
                x0 += sx;
            }
            if (e2 <= dx) {
                if (y0 == y1) break;
                err += dx;
                y0 += sy;
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

    pub fn deinitAndDie(self: *FdfController) void {
        const allocator = self.allocator;
        self.renderer.deinit();
        self.map_input.deinit();
        self.mlx.deinit();
        allocator.destroy(self);
        std.process.exit(0);
    }
};
