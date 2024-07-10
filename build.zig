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

pub const c_source_flags = &[_][]const u8{
    "-g3",
    "-fno-omit-frame-pointer",
};

pub const system_library = &[_][]const u8{
    "bsd", "X11", "Xext", "m",
};

pub const mlx_source_dir = "src/mlx/";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "mlx",
        .root_source_file = b.path(mlx_source_dir ++ "mlx.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.linkLibC();
    lib.addIncludePath(b.path("include"));

    inline for (system_library) |syslib| {
        lib.linkSystemLibrary(syslib);
    }

    inline for (c_source_files) |file| {
        lib.addCSourceFile(.{
            .file = b.path(mlx_source_dir ++ file),
            .flags = c_source_flags,
        });
    }
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zfdf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe.addIncludePath(b.path("include"));
    inline for (system_library) |syslib| {
        exe.linkSystemLibrary(syslib);
    }
    exe.linkLibrary(lib);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe_unit_tests.addIncludePath(b.path("include"));
    inline for (system_library) |syslib| {
        exe_unit_tests.linkSystemLibrary(syslib);
    }

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
