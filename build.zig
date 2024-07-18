const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("minilibx", .{});
    const minilibx = upstream.module("minilibx");

    const exe = b.addExecutable(.{
        .name = "zfdf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = .ReleaseFast,
        .link_libc = true,
    });
    exe.installHeadersDirectory(upstream.path("minilibx/src/include/"), "", .{});
    exe.root_module.addImport("minilibx", minilibx);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addArg("./map/elem-fract-no-color.fdf");
    run_cmd.addArg("800");
    run_cmd.addArg("600");
    run_cmd.addArg("0x000000FF");

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
    exe_unit_tests.root_module.addImport("minilibx", upstream.module("minilibx"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
