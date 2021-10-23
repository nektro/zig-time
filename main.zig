const std = @import("std");
const string = []const u8;
const time = @import("time");

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});
}

fn assertOk(dt: time.DateTime, comptime format: []const u8, expected: string) !void {
    const alloc = std.testing.allocator;

    const actual = try dt.formatAlloc(alloc, format);
    defer alloc.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}

// zig fmt: off
const initUnix = time.DateTime.initUnix;
test { try assertOk(initUnix(0),          "YYY-MM-DD HH:mm:ss", "1970-01-01 00:00:00"); }
test { try assertOk(initUnix(1257894000), "YYY-MM-DD HH:mm:ss", "2009-11-10 23:00:00"); }
test { try assertOk(initUnix(1634858430), "YYY-MM-DD HH:mm:ss", "2021-10-21 23:20:30"); }

const initUnixMs = time.DateTime.initUnixMs;
test { try assertOk(initUnixMs(1634858430023), "YYY-MM-DD HH:mm:ss.SSS", "2021-10-21 23:20:30.023"); }

