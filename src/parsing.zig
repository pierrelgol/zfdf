// ************************************************************************** //
//                                                                            //
//                                                        :::      ::::::::   //
//   parsing.zig                                        :+:      :+:    :+:   //
//                                                    +:+ +:+         +:+     //
//   By: pollivie <pollivie.student.42.fr>          +#+  +:+       +#+        //
//                                                +#+#+#+#+#+   +#+           //
//   Created: 2024/07/18 06:28:57 by pollivie          #+#    #+#             //
//   Updated: 2024/07/18 06:28:57 by pollivie         ###   ########.fr       //
//                                                                            //
// ************************************************************************** //

const std = @import("std");

const process = std.process;
const log = std.log;

const Allocator = std.mem.Allocator;
const ArgIterator = process.ArgIterator;
const ArgIteratorError = ArgIterator.InitError;
const PATH_MAX = std.fs.max_path_bytes;
const RealPathError = std.fs.Dir.RealPathError;

pub const ConfigError = error{
    missing_file_path,
    invalid_file_path,
    invalid_file_extension,
    invalid_number_of_arguments,
    invalid_witdth,
    invalid_height,
    invalid_ratio,
};

pub const Config = struct {
    allocator: Allocator,
    cwd: std.fs.Dir,
    maybe_path_to_file: ?[]const u8,
    screen_width: usize,
    screen_height: usize,
    default_color : i32,
    is_valid: bool,

    pub fn init(allocator: Allocator) Config {
        return Config{
            .allocator = allocator,
            .cwd = std.fs.cwd(),
            .maybe_path_to_file = null,
            .screen_width = 800,
            .screen_height = 600,
            .default_color = 0,
            .is_valid = false,
        };
    }

    pub fn resolvePath(config: *Config, path: []const u8, out_buffer: []u8, out_len : *usize) bool {
        const result = config.cwd.realpath(path, out_buffer) catch |e| switch (e) {
            RealPathError.FileNotFound => |err| {
                log.err("While opening :{s} encountered : {any}. Make sure to provide a correct path to the map\n", .{ path, err });
                return (false);
            },
            RealPathError.AccessDenied => |err| {
                log.err("While opening :{s} encountered : {any}. Make sure you have the right permission for this file\n", .{ path, err });
                return (false);
            },
            else => |err| {
                log.err("While opening {s} encountered fatal error {any}\n", .{ path, err });
                return (false);
            },
        };
        out_len.* = result.len;
        return (true);
    }

    pub fn parse(config: *Config) (Allocator.Error || ConfigError)!void {
        var path_buffer: [PATH_MAX]u8 = undefined;
        var it = process.ArgIterator.initWithAllocator(config.allocator) catch |e| switch (e) {
            error.OutOfMemory => |err| std.log.err("encountered fatal error : {e}", .{err}),
        };
        defer it.deinit();
        if (it.skip() == false)
            return ConfigError.invalid_number_of_arguments;
        if (it.next()) |maybe_path_to_file| {
            var path_len : usize = 0;
            if (config.resolvePath(maybe_path_to_file, &path_buffer, &path_len))
                config.maybe_path_to_file = try config.allocator.dupe(u8, path_buffer[0..path_len]);
            if (std.mem.endsWith(u8, path_buffer[0..path_len], ".fdf") == false)
                return ConfigError.invalid_file_extension;
        }

        if (it.next()) |maybe_screen_width| {
            config.screen_width = std.fmt.parseInt(u32, maybe_screen_width, 10) catch 800;
            switch (config.screen_width) {
                800, 1280, 1920, 2560 => |OK| _ = OK,
                else => return ConfigError.invalid_witdth,
            }
        }

        if (it.next()) |maybe_screen_height| {
            config.screen_height = std.fmt.parseInt(u32, maybe_screen_height, 10) catch 600;
            switch (config.screen_height) {
                600, 720, 1080, 1440 => |OK| _ = OK,
                else => return ConfigError.invalid_height,
            }
        }

        if (it.next()) |maybe_default_color| {
            config.default_color = std.fmt.parseInt(i32, maybe_default_color, 0) catch 0x00_FF_FF_FF;
        }

        switch (config.screen_width * config.screen_height) {
            (800 * 600), (1280 * 720), (1920 * 1080), (2560 * 1440) => |OK| _ = OK,
            else => return ConfigError.invalid_ratio,
        }
        config.is_valid = true;
        config.debug_log();
    }

    pub fn deinit(self: *Config) void {
        if (self.maybe_path_to_file) |path_to_file| {
            self.allocator.free(path_to_file);
        }
    }

    pub fn debug_log(config: *Config) void {
        std.log.debug("CONFIG", .{});
        std.log.debug("allocator = {*}", .{&config.allocator});
        std.log.debug("cwd = {any}", .{config.cwd});
        if (config.maybe_path_to_file) |path|
            std.log.debug("maybe_path_to_file = {s}", .{path})
        else
            std.log.debug("maybe_path_to_file = {s}", .{"(null)"});
        std.log.debug("screen_width = {d}", .{config.screen_width});
        std.log.debug("screen_height = {d}", .{config.screen_height});
        std.log.debug("default_color = {x}", .{config.default_color});
        std.log.debug("is_valid = {any}\n", .{config.is_valid});
    }
};
