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

fn common(mod: *std.Build.Module, devmapper: bool) void {
    const SRCS_COMMON = &[_][]const u8{
        "tcplay.c",
        "main.c",
        "safe_mem.c",
        "io.c",
        "hdr.c",
        "humanize.c",
        "crypto.c",
    };
    mod.addCSourceFiles(.{
        .files = SRCS_COMMON,
        .flags = CFLAGS_WARN,
    });
    mod.addSystemIncludePath(.{ .cwd_relative = "/usr/include" });
    if (devmapper) {
        mod.linkSystemLibrary("devmapper", .{});
        mod.linkSystemLibrary("uuid", .{});
    } else {
        mod.addCMacro("TCPLAY_NO_DEVMAPPER", "1");
    }
    mod.addCMacro("MAJ_VER", "3");
    mod.addCMacro("MIN_VER", "3");
    mod.addCMacro("_GNU_SOURCE", "");
    mod.addCMacro("_DEFAULT_SOURCE", "");
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const devmapper = b.option(bool, "devmapper", "Use device-mapper (dm-crypt) for mapping volumes") orelse true;

    const libcrypto_dep = b.dependency("libcrypto", .{
        .target = target,
        .optimize = optimize,
    });
    const libcrypto_mod = libcrypto_dep.module("libcrypto");

    const tcplay_h = b.addTranslateC(.{
        .root_source_file = b.path("tcplay.h"),
        .target = target,
        .optimize = optimize,
    });
    tcplay_h.addIncludePath(b.path("."));
    if (!devmapper) tcplay_h.defineCMacro("TCPLAY_NO_DEVMAPPER", "1");
    const tcplay_h_mod = tcplay_h.createModule();

    const crc32 = b.addObject(.{
        .name = "crc32",
        .root_module = b.createModule(.{
            .root_source_file = b.path("crc32.zig"),
            .target = target,
            .optimize = optimize,
            .pic = true,
        }),
    });

    const pbkdf2 = b.addObject(.{
        .name = "pbkdf2_",
        .root_module = b.createModule(.{
            .root_source_file = b.path("pbkdf2.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = true,
            .imports = &.{
                .{ .name = "libcrypto", .module = libcrypto_mod },
                .{ .name = "tcplay", .module = tcplay_h_mod },
            },
        }),
    });

    const crypto = b.addObject(.{
        .name = "crypto",
        .root_module = b.createModule(.{
            .root_source_file = b.path("crypto-libcrypto.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = true,
            .imports = &.{
                .{ .name = "libcrypto", .module = libcrypto_mod },
            },
        }),
    });

    // replace zig-out/bin path with with build
    const artifact_dest = std.Build.Step.InstallArtifact.Options{
        .dest_dir = .{ .override = .{ .custom = "../build" } },
    };

    const exe = b.addExecutable(.{
        .name = "tcplay",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    common(exe.root_module, devmapper);

    const lib_static = b.addLibrary(.{
        .name = "tcplay",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    common(lib_static.root_module, devmapper);

    const lib_shared = b.addLibrary(.{
        .name = "tcplay",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    common(lib_shared.root_module, devmapper);

    for ([_]*std.Build.Step.Compile{ lib_static, lib_shared }) |lib| {
        lib.root_module.addCSourceFiles(.{
            .files = &.{"tcplay_api.c"},
            .flags = CFLAGS_WARN,
        });
        lib.setVersionScript(b.path("tcplay.map"));
    }

    for ([_]*std.Build.Step.Compile{ exe, lib_static, lib_shared }) |step| {
        step.root_module.addObject(crc32);
        step.root_module.addObject(pbkdf2);
        step.root_module.addObject(crypto);
        b.getInstallStep().dependOn(&b.addInstallArtifact(step, artifact_dest).step);
    }
}
