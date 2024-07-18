// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   map_data.zig                                       :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/18 07:50:20 by pollivie          #+#    #+#             //
//   Updated: 2024/07/18 07:50:21 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const parser = @import("parsing.zig");
const fdf_type = @import("type.zig");
const Config = parser.Config;
const Vec3 = fdf_type.Vec3;
const Color = fdf_type.Color;
const File = std.fs.File;
const Allocator = std.mem.Allocator;
const AllocatorError = Allocator.Error;
const ArrayList = std.ArrayList;
const FileOpenError = File.OpenError;
const FileStatError = File.StatError;

pub const MapDataError = error{
    invalid_format,
    invalid_dimension,
    invalid_character,
    file_handling_error,
};

pub const MapData = struct {
    allocator: Allocator,
    fdf_map: File,
    world_coord: ArrayList(i32),
    world_color: ArrayList(i32),
    world_height: usize,
    world_width: usize,
    world_center: Vec3,
    world_min: Vec3,
    world_max: Vec3,

    pub fn init(allocator: Allocator, fdf_map_path: []const u8) (FileOpenError || MapDataError)!MapData {
        return MapData{
            .allocator = allocator,
            .fdf_map = try std.fs.openFileAbsolute(fdf_map_path, .{ .mode = .read_only }),
            .world_coord = ArrayList(i32).init(allocator),
            .world_color = ArrayList(i32).init(allocator),
            .world_height = 0,
            .world_width = 0,
            .world_center = Vec3.init(0, 0, 0),
            .world_min = Vec3.init(0, 0, 0),
            .world_max = Vec3.init(0, 0, 0),
        };
    }

    pub fn findDimension(map_data: *MapData, file_buffer: []const u8) MapDataError!void {
        var maybe_prev_width: ?usize = null;

        var row_iterator = std.mem.tokenizeScalar(u8, file_buffer, '\n');
        while (row_iterator.next()) |row| : (map_data.*.world_height += 1) {
            var entry_iterator = std.mem.tokenizeScalar(u8, row, ' ');
            map_data.*.world_width = 0;

            while (entry_iterator.next()) |_| : (map_data.*.world_width += 1) {}

            if (maybe_prev_width) |prev_width| {
                if (prev_width != map_data.world_width)
                    return (MapDataError.invalid_dimension);
            } else {
                maybe_prev_width = map_data.world_width;
            }
        }
    }

    pub fn parse(map_data: *MapData, default_color: i32) anyerror!void {
        const file_buffer = try map_data.fdf_map.readToEndAlloc(map_data.allocator, std.math.maxInt(i32));
        errdefer map_data.allocator.free(file_buffer);
        try map_data.findDimension(file_buffer);

        var row_iterator = std.mem.tokenizeScalar(u8, file_buffer, '\n');
        while (row_iterator.next()) |row| {
            var entry_iterator = std.mem.tokenizeScalar(u8, row, ' ');
            while (entry_iterator.next()) |entry| {
                var values_iterator = std.mem.tokenizeScalar(u8, entry, ',');

                if (values_iterator.next()) |z_axis_str| {
                    const z = std.fmt.parseInt(i32, z_axis_str, 10) catch 0;
                    try map_data.world_coord.append(z);
                }

                if (values_iterator.next()) |color_str| {
                    const c = std.fmt.parseInt(i32, color_str, 0) catch default_color;
                    try map_data.world_color.append(Color.init(c));
                } else {
                    try map_data.world_color.append(Color.init(default_color));
                }
            }
        }
        const min_max = std.mem.minMax(i32, map_data.world_coord.items[0..]);
        map_data.world_min = Vec3.init(0, 0, @floatFromInt(min_max[0]));
        map_data.world_max = Vec3.init(0, 0, @floatFromInt(min_max[1]));
        map_data.allocator.free(file_buffer);
        map_data.debug_log();
    }

    pub fn getWorldCoord(map_data: MapData) []const i32 {
        return map_data.world_coord.items[0..];
    }

    pub fn getWorldColors(map_data: MapData) []const i32 {
        return map_data.world_color.items[0..];
    }

    pub fn getWidth(map_data: MapData) usize {
        return map_data.world_width;
    }

    pub fn getHeight(map_data: MapData) usize {
        return map_data.world_height;
    }

    pub fn deinit(map_data: MapData) void {
        map_data.fdf_map.close();
        map_data.world_coord.deinit();
        map_data.world_color.deinit();
    }

    pub fn debug_log(map_data: MapData) void {
        std.log.debug("MAPDATA", .{});
        std.log.debug("allocator : {*}", .{&map_data.allocator});
        std.log.debug("fdf_map = {}", .{map_data.fdf_map});
        std.log.debug("world_coord = {*}", .{&map_data.world_coord});
        std.log.debug("world_coord_len = {d}", .{map_data.world_coord.items.len});
        std.log.debug("world_color = {*}", .{&map_data.world_color});
        std.log.debug("world_color_len = {d}", .{map_data.world_color.items.len});
        std.log.debug("world_height = {any}", .{map_data.world_height});
        std.log.debug("world_width = {any}", .{map_data.world_width});
        std.log.debug("world_center = {any}", .{map_data.world_center});
        std.log.debug("world_min = {any}", .{map_data.world_min});
        std.log.debug("world_max = {any}\n", .{map_data.world_max});
    }
};
