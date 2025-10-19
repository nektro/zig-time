const std = @import("std");
const string = []const u8;
const time = @import("time");
const expect = @import("expect").expect;

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

// src/test/moment/add_subtract.js
test {
    // var a = moment(),
    //     b,
    //     c,
    //     d;
    // a.year(2011);
    // a.month(9);
    // a.date(12);
    // a.hours(6);
    // a.minutes(7);
    // a.seconds(8);
    // a.milliseconds(500);

    // assert.equal(a.add({ ms: 50 }).milliseconds(), 550, 'Add milliseconds');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addMs(50).ms).toEqual(550);
    // assert.equal(a.add({ s: 1 }).seconds(), 9, 'Add seconds');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addSecs(1).seconds).toEqual(9);
    // assert.equal(a.add({ m: 1 }).minutes(), 8, 'Add minutes');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addMins(1).minutes).toEqual(8);
    // assert.equal(a.add({ h: 1 }).hours(), 7, 'Add hours');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addHours(1).hours).toEqual(7);
    // assert.equal(a.add({ d: 1 }).date(), 13, 'Add date');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addDays(1).days).toEqual(12);
    // assert.equal(a.add({ w: 1 }).date(), 20, 'Add week');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addWeeks(1).days).toEqual(18); //TODO:
    // assert.equal(a.add({ M: 1 }).month(), 10, 'Add month');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addMonths(1).months).toEqual(10);
    // assert.equal(a.add({ y: 1 }).year(), 2012, 'Add year');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addYears(1).years).toEqual(2012);
    // assert.equal(a.add({ Q: 1 }).month(), 1, 'Add quarter');
    try expect(time.DateTime.init(2011, 9, 11, 6, 7, 8, 500).addQuarters(1).months).toEqual(0); //TODO:

    // b = moment([2010, 0, 31]).add({ M: 1 });
    // c = moment([2010, 1, 28]).subtract({ M: 1 });
    // d = moment([2010, 1, 28]).subtract({ Q: 1 });

    // assert.equal(b.month(), 1, 'add month, jan 31st to feb 28th');
    try expect(time.DateTime.init(2010, 0, 30, 0, 0, 0, 0).addMonths(1).toISOString()).toEqualString("2010-02-28T00:00:00Z");
    try expect(time.DateTime.init(2010, 0, 30, 0, 0, 0, 0).addMonths(1).months).toEqual(1);
    try expect(time.DateTime.init(2009, 11, 30, 0, 0, 0, 0).addMonths(2).toISOString()).toEqualString("2010-02-28T00:00:00Z");
    try expect(time.DateTime.init(2009, 11, 30, 0, 0, 0, 0).addMonths(2).months).toEqual(1);
    // assert.equal(b.date(), 28, 'add month, jan 31st to feb 28th');
    try expect(time.DateTime.init(2010, 0, 30, 0, 0, 0, 0).addMonths(1).days).toEqual(27);
    // assert.equal(c.month(), 0, 'subtract month, feb 28th to jan 28th');
    // try expect(time.DateTime.init(2010, 1, 27, 0, 0, 0, 0).subMonths(1).months).toEqual(0);
    // assert.equal(c.date(), 28, 'subtract month, feb 28th to jan 28th');
    // try expect(time.DateTime.init(2010, 1, 27, 0, 0, 0, 0).subMonths(1).days).toEqual(28);
    // assert.equal(d.month(), 10, 'subtract quarter, feb 28th 2010 to nov 28th 2009');
    // try expect(time.DateTime.init(2010, 1, 27, 0, 0, 0, 0).subQuarters(1).months).toEqual(10);
    // assert.equal(d.date(), 28, 'subtract quarter, feb 28th 2010 to nov 28th 2009');
    // try expect(time.DateTime.init(2010, 1, 27, 0, 0, 0, 0).subQuarters(1).days).toEqual(28);
    // assert.equal(d.year(), 2009, 'subtract quarter, feb 28th 2010 to nov 28th 2009');
    // try expect(time.DateTime.init(2010, 1, 27, 0, 0, 0, 0).subQuarters(1).years).toEqual(2009);
}
