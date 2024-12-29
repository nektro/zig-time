const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;

    const t = b.addTest(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = mode,
    });
    deps.addAllTo(t);

    const run_t = b.addRunArtifact(t);
    run_t.has_side_effects = true;

    const t_step = b.step("test", "Run all the tests.");
    t_step.dependOn(&run_t.step);
}
