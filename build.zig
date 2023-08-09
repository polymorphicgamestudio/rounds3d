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

    // zlm - math
    const zlm = b.dependency("zlm", .{});
    exe.addModule("zlm", zlm.module("zlm"));

    // cgltf
    exe.addCSourceFile(.{
        .file = .{ .path = srcdir ++ "/src/cgltf.c" },
        .flags = &[_][]const u8{"-std=c99"},
    });
    exe.addIncludePath(.{ .path = srcdir ++ "/libs/cgltf" });

    // glad
    exe.addIncludePath(.{ .path = srcdir ++ "/../rounds3d-non-source/foreign/glad/include" });
    exe.addCSourceFile(.{
        .file = .{ .path = srcdir ++ "/../rounds3d-non-source/foreign/glad/src/glad.c" },
        .flags = &[_][]const u8{"-std=c99"},
    });

    // freetype TODO(caleb): Finish freetype build..
    // const ft2_flags: []const []const u8 = &.{
    //     "-DFT2_BUILD_LIBRARY",
    // };
    // _ = ft2_flags;
    // var ft2_c_files = try std.ArrayList([]const u8).initCapacity(b.allocator, ft2_srcs.len);
    // _ = ft2_c_files;

    // Link against glfw and deps, add include path
    exe.addIncludePath(.{ .path = srcdir ++ "/../rounds3d-non-source/foreign/glfw-3.3.8.bin.WIN64/include" });
    exe.addLibraryPath(.{ .path = srcdir ++ "/../rounds3d-non-source/foreign/glfw-3.3.8.bin.WIN64/lib-mingw-w64" });
    exe.addObjectFile(.{ .path = srcdir ++ "/../rounds3d-non-source/foreign/glfw-3.3.8.bin.WIN64/lib-mingw-w64/libglfw3.a" });
    // exe.linkSystemLibrary("libglfw3");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("opengl32");

    exe.linkLibC();
    exe.linkLibCpp();

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

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

// const ft2_root = thisDir() ++ "/third_party/freetype/";

const ft2_srcs: []const []const u8 = &.{
    "src/autofit/autofit.c",
    "src/base/ftbase.c",
    "src/base/ftbbox.c",
    "src/base/ftbdf.c",
    "src/base/ftbitmap.c",
    "src/base/ftcid.c",
    "src/base/ftfstype.c",
    "src/base/ftgasp.c",
    "src/base/ftglyph.c",
    "src/base/ftgxval.c",
    "src/base/ftinit.c",
    "src/base/ftmm.c",
    "src/base/ftotval.c",
    "src/base/ftpatent.c",
    "src/base/ftpfr.c",
    "src/base/ftstroke.c",
    "src/base/ftsynth.c",
    "src/base/ftsystem.c", // we will provide our own primitives
    "src/base/fttype1.c",
    "src/base/ftwinfnt.c",
    "src/bdf/bdf.c",
    "src/bzip2/ftbzip2.c",
    "src/cache/ftcache.c",
    "src/cff/cff.c",
    "src/cid/type1cid.c",
    "src/gzip/ftgzip.c",
    "src/lzw/ftlzw.c",
    "src/pcf/pcf.c",
    "src/pfr/pfr.c",
    "src/psaux/psaux.c",
    "src/pshinter/pshinter.c",
    "src/psnames/psnames.c",
    "src/raster/raster.c",
    "src/sdf/sdf.c",
    "src/sfnt/sfnt.c",
    "src/smooth/smooth.c",
    "src/svg/svg.c",
    "src/truetype/truetype.c",
    "src/type1/type1.c",
    "src/type42/type42.c",
    "src/winfonts/winfnt.c",
};

// pub fn buildFreetypeFor(exe: *std.build.LibExeObjStep) !*std.build.LibExeObjStep {
//     var builder = exe.builder;
//     const allocator = builder.allocator;

//     const ft2_flags: []const []const u8 = &.{
//         "-DFT2_BUILD_LIBRARY",
//     };
//     var ft2_c_files = try std.ArrayList([]const u8).initCapacity(allocator, ft2_srcs.len);
//     inline for (ft2_srcs) |f| {
//         ft2_c_files.appendAssumeCapacity(ft2_root ++ f);
//     }
//     if ((exe.target.os_tag orelse builder.host.target.os.tag) == .windows) {
//         try ft2_c_files.append(ft2_root ++ "builds/windows/ftdebug.c");
//     } else {
//         try ft2_c_files.append(ft2_root ++ "src/base/ftdebug.c");
//     }

//     const ft2_lib = builder.addStaticLibrary("freetype2", null);
//     ft2_lib.addCSourceFiles(ft2_c_files.items, ft2_flags);
//     ft2_lib.addIncludeDir(thisDir() ++ "/src/ft/");
//     ft2_lib.addIncludeDir(ft2_root ++ "include/");
//     ft2_lib.linkLibC();

//     exe.addIncludeDir(thisDir() ++ "/src/ft/");
//     exe.addIncludeDir(ft2_root ++ "include/");
//     exe.linkLibC();
//     exe.linkLibrary(ft2_lib);

//     return ft2_lib;
// }

// pub fn addFreetype(exe: *std.build.LibExeObjStep) !void {
//     _ = try buildFreetypeFor(exe);
// }
