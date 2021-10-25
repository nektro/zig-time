const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.build.Builder) void {
    const t = b.addTest("main.zig");
    deps.addAllTo(t);

    const t_step = b.step("run", "Run all the tests.");
    t_step.dependOn(&t.step);
}
