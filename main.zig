const std = @import("std");
const string = []const u8;
const time = @import("time");

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});
}

fn assertOk(unix_ms: u64, comptime format: []const u8, expected: string) !void {
    const alloc = std.testing.allocator;

    const actual = try time.DateTime.initUnixMs(unix_ms).formatAlloc(alloc, format);
    defer alloc.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}

// zig fmt: off
test { try assertOk(0,             "YYY-MM-DD HH:mm:ss", "1970-01-01 00:00:00"); }
test { try assertOk(1257894000000, "YYY-MM-DD HH:mm:ss", "2009-11-10 23:00:00"); }
test { try assertOk(1634858430000, "YYY-MM-DD HH:mm:ss", "2021-10-21 23:20:30"); }
test { try assertOk(1634858430023, "YYY-MM-DD HH:mm:ss.SSS", "2021-10-21 23:20:30.023"); }
test { try assertOk(1144509852789, "YYY-MM-DD HH:mm:ss.SSS", "2006-04-08 15:24:12.789"); }

// test every field
test { try assertOk(1144509852789, "M",    "4"); }
test { try assertOk(1144509852789, "Mo",   "4th"); }
test { try assertOk(1144509852789, "MM",   "04"); }
test { try assertOk(1144509852789, "MMM",  "Apr"); }
test { try assertOk(1144509852789, "MMMM", "April"); }
