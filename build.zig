const std = @import("std");
const builtin = @import("builtin");

// --- HELPER ------------------------------------------------------------------
pub inline fn addExternalImport(c: *std.Build.Step.Compile, b: *std.Build, comptime name: []const u8) void {
    c.root_module.addImport(name, b.dependency(name, .{}).module(name));
}

// --- BUILD -------------------------------------------------------------------
pub fn build(b: *std.Build) !void {
    // --- OPTIONS -------------------------------------------------------------
    const use_system_notcurses = b.option(bool, "use_system_notcurses", "Build against system notcurses [default: NO]") orelse false;
    const build_options = b.addOptions();
    build_options.addOption(bool, "use_system_notcurses", use_system_notcurses);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- NOTCURSES -----------------------------------------------------------

    const ncsrc = "ext/notcurses";

    const notcurses_cflags = [_][]const u8{
        "-DPUBLIC",
        // "-D_XOPEN_SOURCE=700",
        "-DPRIVATE",
        "-D_GNU_SOURCE",
        "-D_DEFAULT_SOURCE",
        "-Wall",
        "-Wno-deprecated-pragma",
        "-Wno-deprecated-declarations",
        "-Wno-bitwise-instead-of-logical",
        "-Wno-unused-but-set-variable",
        "-Werror",
        "-fno-sanitize=undefined",
    };

    const notcurses = b.addStaticLibrary(.{
        .name = "notcurses",
        .optimize = optimize,
        .target = target,
        .link_libc = true,
    });

    const ncSysDeps = comptime [_][]const u8{ "deflate", "ncurses", "readline", "unistring", "z" };
    for (ncSysDeps) |dep|
        notcurses.linkSystemLibrary(dep);

    notcurses.addIncludePath(b.path(ncsrc ++ "/include"));
    notcurses.addIncludePath(b.path(ncsrc ++ "/build/include"));
    notcurses.addIncludePath(b.path(ncsrc ++ "/src"));
    notcurses.addIncludePath(b.path("src/core/notcurses"));

    notcurses.addCSourceFiles(.{
        .root = b.path(ncsrc ++ "/src"),
        // .files = names.allocatedSlice(),
        .files = &[_][]const u8{
            "compat/compat.c",
            "lib/automaton.c",
            "lib/banner.c",
            "lib/blit.c",
            "lib/debug.c",
            "lib/direct.c",
            "lib/fade.c",
            "lib/fd.c",
            "lib/fill.c",
            "lib/gpm.c",
            "lib/in.c",
            "lib/kitty.c",
            "lib/layout.c",
            "lib/linux.c",
            "lib/menu.c",
            "lib/metric.c",
            "lib/mice.c",
            "lib/notcurses.c",
            "lib/plot.c",
            "lib/progbar.c",
            "lib/reader.c",
            "lib/reel.c",
            "lib/render.c",
            "lib/selector.c",
            "lib/sixel.c",
            "lib/sprite.c",
            "lib/stats.c",
            "lib/tabbed.c",
            "lib/termdesc.c",
            "lib/tree.c",
            "lib/unixsig.c",
            "lib/util.c",
            "lib/visual.c",
            "lib/windows.c",
            "media/shim.c",
            "media/none.c",
            "media/ffmpeg.c",
        },
        .flags = &notcurses_cflags,
    });

    const notcurses_module = b.addModule("notcurses", .{
        .root_source_file = b.path("src/core/notcurses/notcurses.zig"),
        .target = target,
        .optimize = optimize,
    });
    notcurses_module.addIncludePath(b.path("src/core/notcurses"));

    if (use_system_notcurses) {
        notcurses_module.linkSystemLibrary("notcurses", .{});
        notcurses_module.linkSystemLibrary("avcodec", .{});
        notcurses_module.linkSystemLibrary("avdevice", .{});
        notcurses_module.linkSystemLibrary("avutil", .{});
        notcurses_module.linkSystemLibrary("avformat", .{});
        notcurses_module.linkSystemLibrary("unistring", .{});

        const wrappers = b.addStaticLibrary(.{
            .name = "wrappers",
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        wrappers.addIncludePath(b.path("src/core/notcurses"));

        notcurses_module.linkLibrary(wrappers);
    } else {
        notcurses_module.linkLibrary(notcurses);
    }

    // --- OUTPUT EXECUTABLES --------------------------------------------------

    const zvim = b.addExecutable(.{
        .name = "zvim",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    addExternalImport(zvim, b, "vaxis");
    addExternalImport(zvim, b, "spice");
    b.installArtifact(zvim);

    const run_cmd = b.addRunArtifact(zvim);

    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const nctest = b.addExecutable(.{
        .name = "nctest",
        .root_source_file = b.path("src/notcurses_test.zig"),
        .target = target,
        .optimize = .ReleaseFast,
        .use_llvm = true,
        .use_lld = true,
        .link_libc = false,
        .strip = true,
    });
    nctest.root_module.addImport("notcurses", notcurses_module);
    nctest.addIncludePath(.{ .cwd_relative = ncsrc ++ "/src/include" });
    nctest.linkLibrary(notcurses);
    nctest.linkSystemLibrary("qrcodegen");

    b.installArtifact(nctest);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
