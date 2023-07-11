const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "rounds3d",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Zlm - math lib
    const zlm = b.dependency("zlm", .{});
    exe.addModule("zlm", zlm.module("zlm"));

    // Compile glad and add include path
    exe.addIncludePath(srcdir ++ "/libs/glad/include");
    exe.addCSourceFile(srcdir ++ "/libs/glad/src/glad.c", &[_][]const u8{"-std=c99"});

    // Link against glfw and deps, add include path
    exe.addIncludePath(srcdir ++ "/external/glfw-3.3.8.bin.WIN64/include");
    exe.addLibraryPath(srcdir ++ "/external/glfw-3.3.8.bin.WIN64/lib-mingw-w64");
    exe.linkLibC();
    exe.linkSystemLibrary("glfw3");
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

const srcdir = struct {
    fn getSrcDir() []const u8 {
        return std.fs.path.dirname(@src().file).?;
    }
}.getSrcDir();
