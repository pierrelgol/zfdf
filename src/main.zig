const std = @import("std");
const libmlx = @cImport({
    @cInclude("stdlib.h");
    @cInclude("stdio.h");
    @cInclude("string.h");
    @cInclude("unistd.h");
    @cInclude("fcntl.h");
    @cInclude("sys/mman.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("sys/ipc.h");
    @cInclude("sys/shm.h");
    @cInclude("X11/extensions/XShm.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("mlx_int.h");
    @cInclude("mlx.h");
});

extern fn mlx_init() ?*anyopaque;
extern fn mlx_get_data_addr(img_handle: ?*anyopaque, img_bpp: *i32, img_size: *i32, img_endian: *i32) [*:0]u8;
extern fn mlx_hook(win_handle: ?*anyopaque, x_event: i32, x_mask: i32, callback: ?*const fn (?*anyopaque) callconv(.C) c_int, arg: ?*anyopaque) callconv(.C) c_int;

pub const MlxRessources = packed struct {
    const width: i32 = 800;
    const height: i32 = 600;
    const title: [:0]const u8 = "fdf";
    allocator: *std.mem.Allocator,
    mlx: ?*anyopaque,
    win: ?*anyopaque,
    img: ?*anyopaque,
    data: [*:0]u8,
    win_width: i32,
    win_height: i32,
    img_size: i32,
    img_bits_per_pixel: i32,
    img_endian: i32,

    pub fn init(allocator: *std.mem.Allocator) !*MlxRessources {
        var result = try allocator.create(MlxRessources);
        result.*.allocator = allocator;
        result.*.mlx = libmlx.mlx_init();
        result.*.win = libmlx.mlx_new_window(result.*.mlx, width, height, @constCast(@alignCast(@ptrCast(title.ptr))));
        result.*.img = libmlx.mlx_new_image(result.*.mlx, width, height);
        std.debug.print("init mlx_ptr = {*}\n", .{result.*.mlx});
        std.debug.print("init win_ptr = {*}\n", .{result.*.win});
        std.debug.print("init img_ptr = {*}\n", .{result.*.img});
        result.*.data = mlx_get_data_addr(result.*.img, &result.img_bits_per_pixel, &result.*.img_size, &result.*.img_endian);
        return (result);
    }

    pub fn on_program_quit(arg: ?*anyopaque) callconv(.C) c_int {
        const maybe_mlx_res = @as(?*MlxRessources, @alignCast(@ptrCast(arg)));
        if (maybe_mlx_res != null) {
            maybe_mlx_res.?.deinit();
        }
        return 1;
    }

    pub fn loop(mlx_res: *MlxRessources) void {
        _ = mlx_hook(mlx_res.win, @as(i32, 17), @as(i32, 1 << 17), on_program_quit, mlx_res);
        _ = libmlx.mlx_loop(mlx_res.mlx);
    }

    pub fn deinit(mlx_res: *MlxRessources) void {
        const allocator = mlx_res.allocator;
        _ = libmlx.mlx_destroy_image(mlx_res.*.mlx, mlx_res.*.img);
        _ = libmlx.mlx_destroy_window(mlx_res.*.mlx, mlx_res.*.win);
        _ = libmlx.mlx_destroy_display(mlx_res.*.mlx.?);
        _ = libmlx.free(mlx_res.*.mlx.?);
        allocator.destroy(mlx_res);
        std.posix.exit(0);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();
    const mlx_res = try MlxRessources.init(&allocator);
    mlx_res.loop();
    // defer mlx_res.deinit();
}
