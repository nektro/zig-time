const std = @import("std");
const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.OptimizeMode, "mode", "") orelse .Debug;
    const disable_llvm = b.option(bool, "disable_llvm", "use the non-llvm zig codegen") orelse false;

    const t = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test.zig"),
            .target = target,
            .optimize = mode,
        }),
    });
    deps.addAllTo(t);
    t.use_llvm = !disable_llvm;
    t.use_lld = !disable_llvm;
    b.getInstallStep().dependOn(&t.step);

    const run_t = b.addRunArtifact(t);
    run_t.setCwd(b.path("."));
    run_t.has_side_effects = true;

    const t_step = b.step("test", "Run all library tests");
    t_step.dependOn(&run_t.step);

    //

    const g = b.addExecutable(.{
        .name = "generate",
        .root_module = b.addModule("root", .{
            .root_source_file = b.path("./generate.zig"),
            .target = target,
            .optimize = mode,
            .link_libc = true,
        }),
    });
    deps.addAllTo(g);
    g.use_llvm = !disable_llvm;
    g.use_lld = !disable_llvm;
    b.getInstallStep().dependOn(&g.step);

    const run_g = b.addRunArtifact(g);
    run_g.setCwd(b.path("."));
    run_g.has_side_effects = true;

    const g_step = b.step("generate", "");
    g_step.dependOn(&run_g.step);
}
