const std = @import("std");

const CFLAGS_WARN = &[_][]const u8{
    "-Wsystem-headers",
    "-Wall",
    "-W",
    "-Wno-unused-parameter",
    "-Wstrict-prototypes",
    "-Wmissing-prototypes",
    "-Wpointer-arith",
    "-Wold-style-definition",
    "-Wreturn-type",
    "-Wwrite-strings",
    "-Wswitch",
    "-Wshadow",
    "-Wcast-align",
    "-Wunused-parameter",
    "-Wchar-subscripts",
    "-Winline",
    "-Wnested-externs",
};

fn common(step: *std.Build.Step.Compile) void {
    const SRCS_COMMON = &[_][]const u8{
        "tcplay.c",
        "main.c",
        "safe_mem.c",
        "io.c",
        "hdr.c",
        "humanize.c",
        "crypto.c",
        "generic_xts.c",
    };
    step.addCSourceFiles(.{
        .files = SRCS_COMMON,
        .flags = CFLAGS_WARN,
    });
    step.addSystemIncludePath(.{ .path = "/usr/include" });
    step.linkSystemLibrary("devmapper");
    step.linkSystemLibrary("uuid");
    step.linkSystemLibrary("gcrypt");
    step.addCSourceFiles(.{ .files = &.{
        "crypto-gcrypt.c",
    }, .flags = CFLAGS_WARN });
    step.defineCMacro("MAJ_VER", "3");
    step.defineCMacro("MIN_VER", "3");
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    const options = .{
        .name = "tcplay",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    };
    const exe = b.addExecutable(options);
    common(exe);

    // replace zig-out/bin path with with build
    const artifact_dest = std.Build.Step.InstallArtifact.Options{
        .dest_dir = std.Build.Step.InstallArtifact.Options.Dir{
            .override = std.Build.InstallDir{ .custom = "../build" },
        },
    };
    const exe_install_artifact = b.addInstallArtifact(
        exe,
        artifact_dest,
    );
    b.getInstallStep().dependOn(&exe_install_artifact.step);

    const lib_static = b.addStaticLibrary(options);
    common(lib_static);
    const t = .{
        .files = &[_][]const u8{
            "tcplay_api.c",
        },
        .flags = CFLAGS_WARN,
    };
    lib_static.addCSourceFiles(t);
    lib_static.version_script = .{ .path = "tcplay.map" };
    const lib_static_artifact = b.addInstallArtifact(
        lib_static,
        artifact_dest,
    );
    b.getInstallStep().dependOn(&lib_static_artifact.step);

    const lib_shared = b.addSharedLibrary(options);
    common(lib_shared);
    lib_shared.addCSourceFiles(t);
    const lib_shared_artifact = b.addInstallArtifact(
        lib_shared,
        artifact_dest,
    );
    lib_shared.version_script = .{ .path = "tcplay.map" };
    b.getInstallStep().dependOn(&lib_shared_artifact.step);

    const crc32 = b.addObject(.{
        .name = "crc32",
        .root_source_file = .{ .path = "crc32.zig" },
        .target = target,
        .optimize = optimize,
        .pic = true,
    });
    exe.addObject(crc32);
    lib_static.addObject(crc32);
    lib_shared.addObject(crc32);

    const pbkdf2 = b.addObject(.{
        .name = "pbkdf2_",
        .root_source_file = .{ .path = "pbkdf2.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    pbkdf2.addIncludePath(.{ .path = "." });
    exe.addObject(pbkdf2);
    lib_static.addObject(pbkdf2);
    lib_shared.addObject(pbkdf2);

    const libcrypto_dep = b.dependency("libcrypto", .{
        .target = target,
        .optimize = optimize,
    });
    const libcrypto_mod = libcrypto_dep.module("libcrypto");
    pbkdf2.root_module.addImport("libcrypto", libcrypto_mod);
}
