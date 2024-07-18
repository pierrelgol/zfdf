// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   main.zig                                           :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/17 17:41:27 by pollivie          #+#    #+#             //
//   Updated: 2024/07/17 17:41:27 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");
const parser = @import("parsing.zig");
const mapdata = @import("map_data.zig");
const ctrl = @import("controller.zig");
const ConfigError = parser.ConfigError;
const Config = parser.Config;
const MapDataError = mapdata.MapDataError;
const MapData = mapdata.MapData;
const Controller = ctrl.Controller;
const AllocatorError = std.mem.Allocator.Error;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    const page_allocator= std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();


    var config = Config.init(allocator);
    defer config.deinit();

    config.parse() catch |err| switch (err) {
        error.invalid_witdth => std.log.err("Invalid width here are the supported parameters\n\t- 800\n\t- 1280\n\t- 1920\n\t- 2560", .{}),
        error.invalid_height => std.log.err("Invalid height here are the supported parameters\n\t- 600\n\t- 720\n\t- 1080\n\t- 1440", .{}),
        error.missing_file_path => std.log.err("Missing File Path, you need to provide a valid path to a xxxxxxx.fdf file", .{}),
        error.invalid_file_path => std.log.err("The provided path is invalid, this can be because the file doesn't exist, or you don't have the right to access it", .{}),
        error.invalid_file_extension => std.log.err("The file provided is in the wrong format make sure to provide a file ending with '.fdf'", .{}),
        error.invalid_number_of_arguments => std.log.err("Not enought arguments were provided\nusage:\n\n./zfdf <file.fdf> <?screen_width> <?screen_height> <?default_color>", .{}),
        error.invalid_ratio => std.log.err("Invalid screen ration. Here are the supported parameters\n\t- 800/600\n\t- 1280/720\n\t- 1920/1080\n\t- 2560/1440", .{}),
        error.OutOfMemory => std.log.err("Fdf failed because it encountered an Out Of Memory error\n", .{}),
    };

    if (!config.is_valid)
        std.process.exit(1);

    var fdf_map: MapData = undefined;

    if (config.maybe_path_to_file) |fdf_map_path| {
        if (MapData.init(allocator, fdf_map_path)) |*valid_map| {
            fdf_map = valid_map.*;
        } else |err| {
            switch (err) {
                error.invalid_format => std.log.err("Invalid map format, make sure each entries of the map are formated as follow <i32><?,0xXXXXXXX><' '>\nexample:\n1 1\n1 1\nor\n2,0xFF 1 2,0xAA\n2,0xFF 1 2,0xAA\n2,0xFF 1 2,0xAA", .{}),
                error.invalid_dimension => std.log.err("Invalid map dimension, make sure the map is formatted as a Square or as a Rectangle", .{}),
                else => std.log.err("Unexpected error encountered while opening {s}\n", .{fdf_map_path}),
            }
            std.process.exit(1);
        }
    }
    defer fdf_map.deinit();

    fdf_map.parse(config.default_color) catch |err| switch (err) {
        error.invalid_format => std.log.err("Invalid map format, make sure each entries of the map are formated as follow <i32><?,0xXXXXXXX><' '>\nexample:\n1 1\n1 1\nor\n2,0xFF 1 2,0xAA\n2,0xFF 1 2,0xAA\n2,0xFF 1 2,0xAA", .{}),
        error.invalid_dimension => std.log.err("Invalid map dimension, make sure the map is formatted as a Square or as a Rectangle", .{}),
        else => std.log.err("Unexpected error encountered while parsing map\n", .{}),
    };
    var controller : *Controller = undefined;
    if (Controller.init(allocator, config, &fdf_map)) |ok| {
        controller = ok;
    }else |err| {
        switch (err) {
            AllocatorError.OutOfMemory => std.log.err("OutOfMemory error encountered while rendering map\n", .{}),
        }
        std.process.exit(1);
    }
    defer controller.deinit();
    // controller.renderingLoopBegin();
    controller.renderingLoopLiveBegin();
}
