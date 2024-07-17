// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   renderer.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/17 10:10:23 by pollivie          #+#    #+#             //
//   Updated: 2024/07/17 10:10:23 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const backend = @import("backend.zig");
const ctype = @import("type.zig");
const map = @import("map.zig");
const COS30: f32 = 0.86602540378;
const SIN30: f32 = 0.5;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const MapError = map.MapError;
const Map = map.Map;
const Pixel = ctype.Pixel;
const Color = ctype.Color;
const Vec3 = ctype.Vec3;

pub const RenderingParameters = struct {
    screen_width: i32,
    screen_height: i32,
    screen_center: Vec3,
    translation: Vec3,
    sin_rotates: Vec3,
    cos_rotates: Vec3,
    zoom_level: f32,
};

pub const Renderer = struct {
    backing_allocator: Allocator,
    arena: ArenaAllocator,
    allocator: Allocator,

    parameters: ?RenderingParameters,
    map_input: *Map,

    height: usize,
    width: usize,
    color_buffer: []Color,
    world_buffer: []Vec3,
    world: [][]Vec3,
    color: [][]Color,
    is_dirty: bool,

    pub fn init(allocator: Allocator, map_input: *Map, parameters: RenderingParameters) Allocator.Error!*Renderer {
        const self: *Renderer = try allocator.create(Renderer);
        self.*.height = @intCast(map_input.height);
        self.*.width = @intCast(map_input.width);
        self.*.backing_allocator = allocator;
        self.*.arena = std.heap.ArenaAllocator.init(allocator);
        self.*.allocator = self.arena.allocator();
        self.*.parameters = parameters;
        self.*.map_input = map_input;
        self.*.color_buffer = try map_input.getColorBufferCopy(self.allocator);
        self.*.world_buffer = try map_input.getWorldBufferCopy(self.allocator);
        self.*.world = blk: {
            var buffer = try ArrayList([]Vec3).initCapacity(self.allocator, self.height);
            for (0..self.height) |h| {
                const start = h * self.width;
                const end = start + self.width;
                buffer.appendAssumeCapacity(self.world_buffer[start..end]);
            }
            break :blk try buffer.toOwnedSlice();
        };
        self.*.color = blk: {
            var buffer = try ArrayList([]Color).initCapacity(self.allocator, self.height);
            for (0..self.height) |h| {
                const start = h * self.width;
                const end = start + self.width;
                buffer.appendAssumeCapacity(self.color_buffer[start..end]);
            }
            break :blk try buffer.toOwnedSlice();
        };
        self.*.is_dirty = false;
        return (self);
    }

    pub fn reset(self: *Renderer) !void {
        const map_input = self.map_input;
        _ = self.arena.reset(.retain_capacity);
        self.*.color_buffer = try map_input.getColorBufferCopy(self.allocator);
        self.*.world_buffer = try map_input.getWorldBufferCopy(self.allocator);
        self.*.world = blk: {
            var buffer = try ArrayList([]Vec3).initCapacity(self.allocator, self.height);
            for (0..self.height) |h| {
                const start = h * self.width;
                const end = start + self.width;
                buffer.appendAssumeCapacity(self.world_buffer[start..end]);
            }
            break :blk try buffer.toOwnedSlice();
        };
        self.*.color = blk: {
            var buffer = try ArrayList([]Color).initCapacity(self.allocator, self.height);
            for (0..self.height) |h| {
                const start = h * self.width;
                const end = start + self.width;
                buffer.appendAssumeCapacity(self.color_buffer[start..end]);
            }
            break :blk try buffer.toOwnedSlice();
        };
        self.parameters = null;
        self.is_dirty = false;
    }

    pub fn render(self: *Renderer) !?[][]Pixel {
        const parameters = self.parameters orelse return (null);
        defer self.is_dirty = true;
        var pixel_buffer = try ArrayList(Pixel).initCapacity(self.allocator, self.width * self.height);

        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                const world_point = self.world[y][x];
                const zoomed_point = world_point.mulScalar(parameters.zoom_level);
                const translated_point = zoomed_point.add(parameters.translation);
                const rotated_point = translated_point.rotXYZ(parameters.cos_rotates, parameters.sin_rotates);
                const projected_pixel = Pixel{
                    .x = @intFromFloat((rotated_point.x - rotated_point.y) * COS30),
                    .y = @intFromFloat(((-rotated_point.z) + (rotated_point.x + rotated_point.y) * SIN30)),
                    .color = self.color[y][x].color,
                };
                pixel_buffer.appendAssumeCapacity(projected_pixel);
            }
        }
        var pixels = try ArrayList([]Pixel).initCapacity(self.allocator, self.height);
        for (0..self.height) |h| {
            const start = h * self.width;
            const end = start + self.width;
            pixels.appendAssumeCapacity(pixel_buffer.items[start..end]);
        }
        return (try pixels.toOwnedSlice());
    }

    pub fn deinit(self: *Renderer) void {
        self.arena.deinit();
        self.backing_allocator.destroy(self);
    }
};
