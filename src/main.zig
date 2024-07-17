const std = @import("std");
const opt = @import("builtin");
const ctrl = @import("controller.zig");
const MlxBackend = @import("backend.zig").MlxBackend;
const FdfController = ctrl.FdfController;
const fdf_map = @embedFile("elem-fract.fdf");

pub const ConfigError = error{
    missing_arguments,
    missing_file_path,
    missing_width,
    missing_height,
    wrong_file_format,
};

pub const Config = struct {
    file_path: []const u8,
    width: i32,
    height: i32,
    is_valid: bool,

    pub fn init() Config {
        return Config{
            .file_path = undefined,
            .width = undefined,
            .height = undefined,
            .is_valid = false,
        };
    }

    pub fn parse(config: *Config, it: *std.process.ArgIterator) ConfigError!void {
        if (it.skip() == false) return ConfigError.missing_arguments;
        config.file_path = it.next() orelse return ConfigError.missing_file_path;
        if (it.next()) |maybe_width| {
            config.width = std.fmt.parseInt(i32, maybe_width, 10) catch 800;
        } else {
            return ConfigError.missing_width;
        }
        if (it.next()) |maybe_height| {
            config.width = std.fmt.parseInt(i32, maybe_height, 10) catch 600;
        } else {
            return ConfigError.missing_height;
        }
        if (std.mem.endsWith(u8, config.file_path, ".fdf") == false)
            return ConfigError.wrong_file_format;
        config.is_valid = true;
    }
};

pub fn reportError(msg: []const u8) !void {
    const stderr_handle = std.io.getStdErr();
    defer stderr_handle.close();
    const writer = stderr_handle.writer();
    try writer.print("{s}\n", .{msg});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var fdf = try FdfController.init(allocator, fdf_map, 500, 500);
    try fdf.startRendering();
    defer fdf.deinit();
}
