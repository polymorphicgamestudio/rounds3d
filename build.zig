const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zlm = b.dependency("zlm", .{});

    const exe = b.addExecutable(.{
        .name = "rounds3d",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("zlm", zlm.module("zlm"));
    exe.addCSourceFile("../glad/src/glad.c", &[_][]const u8{"-std=c99"});

    // exe.addIncludePath("../glew-2.1.0-win32/glew-2.1.0/include");
    exe.addIncludePath("../glad/include");
    exe.addIncludePath("../glfw-3.3.8.bin.WIN64/include");

    exe.linkLibC();
    exe.linkLibCpp();

    exe.addLibraryPath("../glfw-3.3.8.bin.WIN64/lib-mingw-w64");
    exe.linkSystemLibrary("glfw3");

    // exe.addLibraryPath("../glew-2.1.0-win32/glew-2.1.0/bin/Release/Win32");
    // exe.linkSystemLibrary("glew32");

    exe.addLibraryPath("C:/Windows/System32");
    exe.linkSystemLibrary("gdi32");

    exe.linkSystemLibrary("opengl32");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
