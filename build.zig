const std = @import("std");
const builtin = @import("builtin");

// --- HELPER ------------------------------------------------------------------
pub inline fn addExternalImport(c: *std.Build.Step.Compile, b: *std.Build, comptime name: []const u8) void {
    c.root_module.addImport(name, b.dependency(name, .{}).module(name));
}

// --- BUILD -------------------------------------------------------------------

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --- DEPENDENCIES --------------------------------------------------------

    const notcurses = b.addStaticLibrary(.{
        .name = "notcurses",
        .optimize = optimize,
        .target = target,
    });

    notcurses.linkSystemLibrary2("notcurses", .{
        .needed = true,
        .preferred_link_mode = .static,
        .use_pkg_config = .force,
        .search_strategy = .paths_first,
    });

    notcurses.linkLibC();

    // --- DEPENDENCIES --------------------------------------------------------

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

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
