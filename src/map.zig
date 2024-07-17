// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   map.zig                                            :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/17 10:11:16 by pollivie          #+#    #+#             //
//   Updated: 2024/07/17 10:11:17 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const cty = @import("type.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Order = std.math.Order;
const white = 0x00_FF_FF_FF;
const Pixel = cty.Pixel;
const Vec3 = cty.Vec3;
const Color = cty.Color;

pub const MapError = error{
    InvalidEntry,
    InvalidValue,
    InvalidMap,
};

pub const Map = struct {
    allocator: Allocator,
    height: i32,
    width: i32,
    color_buffer: ArrayList(Color),
    color: ArrayList([]Color),
    world_buffer: ArrayList(Vec3),
    world: ArrayList([]Vec3),

    pub fn initWithCapacity(allocator: Allocator, width: i32, height: i32) Allocator.Error!*Map {
        const result = try allocator.create(Map);
        result.*.allocator = allocator;
        const size = @as(usize, @intCast(width * height));
        result.*.color_buffer = try ArrayList(Color).initCapacity(allocator, size);
        result.*.world_buffer = try ArrayList(Vec3).initCapacity(allocator, size);
        result.*.color = try ArrayList([]Color).initCapacity(allocator, @intCast(height));
        result.*.world = try ArrayList([]Vec3).initCapacity(allocator, @intCast(height));
        result.*.height = height;
        result.*.width = width;
        return (result);
    }

    pub fn getWorldBufferCopy(self: *Map, allocator: Allocator) Allocator.Error![]Vec3 {
        return (try allocator.dupe(Vec3, self.world_buffer.items[0..]));
    }

    pub fn getColorBufferCopy(self: *Map, allocator: Allocator) Allocator.Error![]Color {
        return (try allocator.dupe(Color, self.color_buffer.items[0..]));
    }
    pub fn parse(self: *Map, map_data: []const u8) MapError!void {
        const height: usize = @intCast(self.height);
        const width: usize = @intCast(self.width);
        var y: i32 = 0;
        var row_iterator = std.mem.tokenizeScalar(u8, map_data, '\n');
        while (row_iterator.next()) |map_row| : (y += 1) {
            var x: i32 = 0;
            var entry_iterator = std.mem.tokenizeScalar(u8, map_row, ' ');
            while (entry_iterator.next()) |map_entry| : (x += 1) {
                var entry_values = std.mem.tokenizeScalar(u8, map_entry, ',');

                const entry_z_buffer = entry_values.next() orelse return MapError.InvalidEntry;
                if (std.fmt.parseFloat(f32, entry_z_buffer)) |z_value| {
                    self.world_buffer.appendAssumeCapacity(Vec3.init(@floatFromInt(x), @floatFromInt(y), z_value));
                } else |_| {
                    return MapError.InvalidValue;
                }

                if (entry_values.next()) |hex_color_buffer| {
                    var color: i32 = undefined;

                    if (hex_color_buffer.len >= 3)
                        color = std.fmt.parseInt(i32, hex_color_buffer, 16) catch 0
                    else
                        return MapError.InvalidValue;
                    self.color_buffer.appendAssumeCapacity(Color.initFromHexToRGBA(color));
                } else {
                    self.color_buffer.appendAssumeCapacity(Color.initFromHexToRGBA(0));
                }
            }
        }

        for (0..height) |h| {
            const start = h * width;
            const end = start + width;
            self.color.appendAssumeCapacity(self.color_buffer.items[start..end]);
            self.world.appendAssumeCapacity(self.world_buffer.items[start..end]);
        }
    }

    pub fn deinit(self: *Map) void {
        self.color_buffer.deinit();
        self.color.deinit();
        self.world_buffer.deinit();
        self.world.deinit();
        self.allocator.destroy(self);
    }
};
