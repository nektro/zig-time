const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.build.Builder) void {
    const t = b.addTest(.{
        .root_source_file = .{ .path = "main.zig" },
    });
    deps.addAllTo(t);

    const run_t = b.addRunArtifact(t);

    const t_step = b.step("run", "Run all the tests.");
    t_step.dependOn(&run_t.step);
}
