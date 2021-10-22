const std = @import("std");
const string = []const u8;
const time = @import("time");

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});
}

fn assertOk(input: u64, expected: string) !void {
    const alloc = std.testing.allocator;

    const actual = try time.DateTime.initUnix(input).formatAlloc(alloc, "YYYY-MM-DD HH:mm:ss");
    defer alloc.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}

// zig fmt: off
test { try assertOk(0, "1970-01-01 00:00:00"); }
test { try assertOk(1257894000, "2009-11-10 23:00:00"); }
test { try assertOk(1634858430, "2021-10-21 23:20:30"); }
