const std = @import("std");

pub const c_source_files = &[_][]const u8{
    "mlx_init.c",                   "mlx_new_window.c",          "mlx_pixel_put.c",             "mlx_loop.c",
    "mlx_mouse_hook.c",             "mlx_key_hook.c",            "mlx_expose_hook.c",           "mlx_loop_hook.c",
    "mlx_int_anti_resize_win.c",    "mlx_int_do_nothing.c",      "mlx_int_wait_first_expose.c", "mlx_int_get_visual.c",
    "mlx_flush_event.c",            "mlx_string_put.c",          "mlx_set_font.c",              "mlx_new_image.c",
    "mlx_get_data_addr.c",          "mlx_put_image_to_window.c", "mlx_get_color_value.c",       "mlx_clear_window.c",
    "mlx_xpm.c",                    "mlx_int_str_to_wordtab.c",  "mlx_destroy_window.c",        "mlx_int_param_event.c",
    "mlx_int_set_win_event_mask.c", "mlx_hook.c",                "mlx_rgb.c",                   "mlx_destroy_image.c",
    "mlx_mouse.c",                  "mlx_screen_size.c",         "mlx_destroy_display.c",
};

pub const c_release_flags = &[_][]const u8{
    "-Ofast",
};
pub const source_dir = "src/source/";

// pub fn build(b: *std.Build) void {
//     const target = b.standardTargetOptions(.{});
//     const optimize = b.standardOptimizeOption(.{});
//     const c_source_flags = switch (optimize) {
//         .Debug => c_debug_flags,
//         else => c_release_flags,
//     };

//     const lib = b.addStaticLibrary(.{
//         .name = "minilibx",
//         .root_source_file = b.path("src/mlx.zig"),
//         .target = target,
//         .optimize = optimize,
//         .link_libc = true,
//     });
//     lib.addIncludePath(b.path("src/include"));
//     lib.linkSystemLibrary("bsd");
//     lib.linkSystemLibrary("X11");
//     lib.linkSystemLibrary("Xext");
//     lib.linkSystemLibrary("m");
//     inline for (c_source_files) |file| {
//         lib.addCSourceFile(.{
//             .file = b.path(source_dir ++ file),
//             .flags = c_source_flags,
//         });
//     }
// }

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const c_source_flags = c_release_flags;

    // const lib = b.addStaticLibrary(.{
    //     .name = "minilibx",
    //     .root_source_file = b.path("src/mlx.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .link_libc = true,
    // });
    // lib.addIncludePath(b.path("src/include"));
    // lib.linkSystemLibrary("bsd");
    // lib.linkSystemLibrary("X11");
    // lib.linkSystemLibrary("Xext");
    // lib.linkSystemLibrary("m");
    // inline for (c_source_files) |file| {
    //     lib.addCSourceFile(.{
    //         .file = b.path(source_dir ++ file),
    //         .flags = c_source_flags,
    //     });
    // }

    const upstream = b.addModule("minilibx", .{
        .root_source_file = b.path("src/mlx.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    upstream.addIncludePath(b.path("src/include"));
    upstream.linkSystemLibrary("bsd", .{
        .needed = true,
    });
    upstream.linkSystemLibrary("X11", .{
        .needed = true,
    });
    upstream.linkSystemLibrary("Xext", .{
        .needed = true,
    });
    upstream.linkSystemLibrary("m", .{
        .needed = true,
    });
    inline for (c_source_files) |file| {
        upstream.addCSourceFile(.{
            .file = b.path(source_dir ++ file),
            .flags = c_source_flags,
        });
    }
    // b.installArtifact(lib);
}
