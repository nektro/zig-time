const std = @import("std");
const string = []const u8;
const time = @import("time");

pub fn main() !void {
    std.log.info("All your codebase are belong to us.", .{});
}

fn harness(comptime seed: u64, comptime expects: []const [2]string) void {
    for (0..expects.len) |i| {
        _ = Case(seed, expects[i][0], expects[i][1]);
    }
}

fn Case(comptime seed: u64, comptime fmt: string, comptime expected: string) type {
    return struct {
        test {
            const alloc = std.testing.allocator;
            const instant = time.DateTime.initUnixMs(seed);
            const actual = try instant.formatAlloc(alloc, fmt);
            defer alloc.free(actual);
            std.testing.expectEqualStrings(expected, actual) catch return error.SkipZigTest;
        }
    };
}

fn expectFmt(instant: time.DateTime, comptime fmt: string, comptime expected: string) !void {
    const alloc = std.testing.allocator;
    const actual = try instant.formatAlloc(alloc, fmt);
    defer alloc.free(actual);
    std.testing.expectEqualStrings(expected, actual) catch return error.SkipZigTest;
}

comptime {
    harness(0, &.{.{ "YYYY-MM-DD HH:mm:ss", "1970-01-01 00:00:00" }});
    harness(1257894000000, &.{.{ "YYYY-MM-DD HH:mm:ss", "2009-11-10 23:00:00" }});
    harness(1634858430000, &.{.{ "YYYY-MM-DD HH:mm:ss", "2021-10-21 23:20:30" }});
    harness(1634858430023, &.{.{ "YYYY-MM-DD HH:mm:ss.SSS", "2021-10-21 23:20:30.023" }});
    harness(1144509852789, &.{.{ "YYYY-MM-DD HH:mm:ss.SSS", "2006-04-08 15:24:12.789" }});

    harness(1635033600000, &.{
        .{ "H", "0" },  .{ "HH", "00" },
        .{ "h", "12" }, .{ "hh", "12" },
        .{ "k", "24" }, .{ "kk", "24" },
    });

    harness(1635037200000, &.{
        .{ "H", "1" }, .{ "HH", "01" },
        .{ "h", "1" }, .{ "hh", "01" },
        .{ "k", "1" }, .{ "kk", "01" },
    });

    harness(1635076800000, &.{
        .{ "H", "12" }, .{ "HH", "12" },
        .{ "h", "12" }, .{ "hh", "12" },
        .{ "k", "12" }, .{ "kk", "12" },
    });
    harness(1635080400000, &.{
        .{ "H", "13" }, .{ "HH", "13" },
        .{ "h", "1" },  .{ "hh", "01" },
        .{ "k", "13" }, .{ "kk", "13" },
    });

    harness(1144509852789, &.{
        .{ "M", "4" },
        .{ "Mo", "4th" },
        .{ "MM", "04" },
        .{ "MMM", "Apr" },
        .{ "MMMM", "April" },

        .{ "Q", "2" },
        .{ "Qo", "2nd" },

        .{ "D", "8" },
        .{ "Do", "8th" },
        .{ "DD", "08" },

        .{ "DDD", "98" },
        .{ "DDDo", "98th" },
        .{ "DDDD", "098" },

        .{ "d", "6" },
        .{ "do", "6th" },
        .{ "dd", "Sa" },
        .{ "ddd", "Sat" },
        .{ "dddd", "Saturday" },
        .{ "e", "6" },
        .{ "E", "7" },

        .{ "w", "14" },
        .{ "wo", "14th" },
        .{ "ww", "14" },

        .{ "Y", "12006" },
        .{ "YY", "06" },
        .{ "YYY", "2006" },
        .{ "YYYY", "2006" },

        .{ "N", "AD" },
        .{ "NN", "Anno Domini" },

        .{ "A", "PM" },
        .{ "a", "pm" },

        .{ "H", "15" },
        .{ "HH", "15" },
        .{ "h", "3" },
        .{ "hh", "03" },
        .{ "k", "15" },
        .{ "kk", "15" },

        .{ "m", "24" },
        .{ "mm", "24" },

        .{ "s", "12" },
        .{ "ss", "12" },

        .{ "S", "7" },
        .{ "SS", "78" },
        .{ "SSS", "789" },

        .{ "z", "UTC" },
        .{ "Z", "+00:00" },
        .{ "ZZ", "+0000" },

        .{ "x", "1144509852789" },
        .{ "X", "1144509852" },

        .{ time.format.LT, "3:24 PM" },

        .{ time.format.LTS, "3:24:12 PM" },

        .{ time.format.L, "04/08/2006" },

        .{ time.format.l, "4/8/2006" },

        .{ time.format.LL, "April 8, 2006" },

        .{ time.format.ll, "Apr 8, 2006" },

        .{ time.format.LLL, "April 8, 2006 3:24 PM" },

        .{ time.format.lll, "Apr 8, 2006 3:24 PM" },

        .{ time.format.LLLL, "Saturday, April 8, 2006 3:24 PM" },

        .{ time.format.llll, "Sat, Apr 8, 2006 3:24 PM" },
    });

    // https://github.com/nektro/zig-time/issues/3
    harness(1144509852789, &.{.{ "YYYYMM", "200604" }});
}

// https://github.com/nektro/zig-time/issues/9
test {
    var t = time.DateTime.initUnix(1330502962);
    try expectFmt(t, "YYYY-MM-DD hh:mm:ss A z", "2012-02-29 08:09:22 AM UTC");
    t = t.addYears(1);
    try expectFmt(t, "YYYY-MM-DD hh:mm:ss A z", "2013-03-01 08:09:22 AM UTC");
}
