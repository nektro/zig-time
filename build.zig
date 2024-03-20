const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const extras = b.dependency("extras", .{});
    const time = b.addModule(
        "time",
        .{
            .source_file = .{ .path = "time.zig" },
            .dependencies = &.{
                .{
                    .name = "extras",
                    .module = extras.module("extras"),
                },
            },
        },
    );

    const t = b.addTest(.{
        .root_source_file = .{ .path = "main.zig" },
    });
    t.addModule("time", time);

    const run_t = b.addRunArtifact(t);

    const t_step = b.step("test", "Run all the tests.");
    t_step.dependOn(&run_t.step);
}
