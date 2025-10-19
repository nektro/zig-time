const std = @import("std");
const string = []const u8;
const extras = @import("extras");
const time = @This();

pub const DateTime = struct {
    ms: u16,
    seconds: u8,
    minutes: u8,
    hours: u8,
    days: u8,
    months: u8,
    years: u16,
    timezone: TimeZone,

    const Self = @This();

    pub fn initUnixMs(unix: u64) Self {
        return epoch_unix.addMs(unix);
    }

    pub fn initUnix(unix: u64) Self {
        return epoch_unix.addSecs(unix);
    }

    /// Caller asserts that this is > epoch
    pub fn init(year: u16, month: u16, day: u16, hr: u16, min: u16, sec: u16, ms: u16) Self {
        return epoch_unix
            .addYears(year - epoch_unix.years)
            .addMonths(month)
            .addDays(day)
            .addHours(hr)
            .addMins(min)
            .addSecs(sec)
            .addMs(ms);
    }

    pub fn now() Self {
        return initUnixMs(@intCast(std.time.milliTimestamp()));
    }

    pub const epoch_unix = Self{
        .ms = 0,
        .seconds = 0,
        .minutes = 0,
        .hours = 0,
        .days = 0,
        .months = 0,
        .years = 1970,
        .timezone = .UTC,
    };

    pub fn toISOString(self: Self) [20]u8 {
        // "2021-10-21T23:20:30Z"
        var result: [20]u8 = @splat(0);
        var fbs = std.io.fixedBufferStream(&result);
        self.format("YYYY-MM-DD HH:mm:ss", .{}, fbs.writer()) catch unreachable;
        result[10] = 'T';
        result[19] = 'Z';
        return result;
    }

    pub fn eql(self: Self, other: Self) bool {
        return self.ms == other.ms and
            self.seconds == other.seconds and
            self.minutes == other.minutes and
            self.hours == other.hours and
            self.days == other.days and
            self.months == other.months and
            self.years == other.years and
            self.timezone == other.timezone and
            self.weekday == other.weekday;
    }

    pub fn addMs(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.ms += @intCast(count % 1000);
        return result.addSecs(count / 1000);
    }

    pub fn addSecs(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.seconds += @intCast(count % 60);
        return result.addMins(count / 60);
    }

    pub fn addMins(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.minutes += @intCast(count % 60);
        return result.addHours(count / 60);
    }

    pub fn addHours(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.hours += @intCast(count % 24);
        return result.addDays(count / 24);
    }

    pub fn addDays(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        var input = count;

        while (true) {
            const year_len = result.daysThisYear();
            if (input >= year_len) {
                result.years += 1;
                input -= year_len;
                continue;
            }
            break;
        }
        while (true) {
            const month_len = result.daysThisMonth();
            if (input >= month_len) {
                result.months += 1;
                input -= month_len;

                if (result.months == 12) {
                    result.years += 1;
                    result.months = 0;
                }
                continue;
            }
            break;
        }
        {
            const month_len = result.daysThisMonth();
            if (result.days + input > month_len) {
                const left = month_len -| result.days;
                input -= left;
                result.months += 1;
                result.days = 0;
            }
            result.days += @intCast(input);

            if (result.days == result.daysThisMonth()) {
                result.months += 1;
                result.days = 0;
            }
            if (result.months == 12) {
                result.years += 1;
                result.months = 0;
            }
        }

        std.debug.assert(result.ms < 1000);
        std.debug.assert(result.seconds < 60);
        std.debug.assert(result.minutes < 60);
        std.debug.assert(result.hours < 24);
        std.debug.assert(result.days < result.daysThisMonth());
        std.debug.assert(result.months < 12);
        return result;
    }

    pub fn addWeeks(self: Self, count: u64) Self {
        if (count == 0) return self;
        return self.addDays(7).addWeeks(count - 1);
    }

    pub fn addMonths(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        var input = count;
        result.years += @intCast(input / 12);
        input %= 12;
        result.months += @intCast(input);
        if (result.months >= 12) result.years += 1;
        result.months %= 12;
        result.days = @min(result.days, result.daysInMonth(result.months) - 1);
        return result;
    }

    pub fn addYears(self: Self, count: u64) Self {
        var result = self;
        for (0..count) |_| {
            result = result.addDays(result.daysThisYear());
        }
        return result;
    }

    pub fn addQuarters(self: Self, count: u64) Self {
        if (count == 0) return self;
        return self.addMonths(3).addQuarters(count - 1);
    }

    pub fn isLeapYear(self: Self) bool {
        return time.isLeapYear(self.years);
    }

    pub fn daysThisYear(self: Self) u16 {
        return time.daysInYear(self.years);
    }

    pub fn daysThisMonth(self: Self) u16 {
        return self.daysInMonth(self.months);
    }

    fn daysInMonth(self: Self, month: u16) u16 {
        return time.daysInMonth(self.years, month);
    }

    pub fn dayOfThisYear(self: Self) u16 {
        var ret: u16 = 0;
        for (0..self.months) |item| {
            ret += self.daysInMonth(@intCast(item));
        }
        ret += self.days;
        return ret;
    }

    pub fn toUnix(self: Self) u64 {
        const x = self.toUnixMilli();
        return x / 1000;
    }

    pub fn toUnixMilli(self: Self) u64 {
        var res: u64 = 0;
        res += self.ms;
        res += @as(u64, self.seconds) * ms_per_s;
        res += @as(u64, self.minutes) * ms_per_min;
        res += @as(u64, self.hours) * ms_per_hour;
        res += self.daysSinceEpoch() * ms_per_day;
        return res;
    }

    fn daysSinceEpoch(self: Self) u64 {
        var res: u64 = 0;
        res += self.days;
        for (0..self.years - epoch_unix.years) |i| res += time.daysInYear(@intCast(i));
        for (0..self.months) |i| res += self.daysInMonth(@intCast(i));
        return res;
    }

    /// fmt is based on https://momentjs.com/docs/#/displaying/format/
    pub fn format(self: Self, comptime fmt: string, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        if (fmt.len == 0) @compileError("DateTime: format string can't be empty");

        @setEvalBranchQuota(100000);

        comptime var s = 0;
        comptime var e = 0;
        comptime var next: ?FormatSeq = null;
        inline for (fmt, 0..) |c, i| {
            e = i + 1;

            if (comptime std.meta.stringToEnum(FormatSeq, fmt[s..e])) |tag| {
                next = tag;
                if (i < fmt.len - 1) continue;
            }

            if (next) |tag| {
                switch (tag) {
                    .MM => try writer.print("{:0>2}", .{self.months + 1}),
                    .M => try writer.print("{}", .{self.months + 1}),
                    .Mo => try printOrdinal(writer, self.months + 1),
                    .MMM => try printLongName(writer, self.months, &[_]string{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }),
                    .MMMM => try printLongName(writer, self.months, &[_]string{ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }),

                    .Q => try writer.print("{}", .{self.months / 3 + 1}),
                    .Qo => try printOrdinal(writer, self.months / 3 + 1),

                    .D => try writer.print("{}", .{self.days + 1}),
                    .Do => try printOrdinal(writer, self.days + 1),
                    .DD => try writer.print("{:0>2}", .{self.days + 1}),

                    .DDD => try writer.print("{}", .{self.dayOfThisYear() + 1}),
                    .DDDo => try printOrdinal(writer, self.dayOfThisYear() + 1),
                    .DDDD => try writer.print("{:0>3}", .{self.dayOfThisYear() + 1}),

                    .d => try writer.print("{}", .{@intFromEnum(self.weekday())}),
                    .do => try printOrdinal(writer, @intFromEnum(self.weekday())),
                    .dd => try writer.writeAll(@tagName(self.weekday())[0..2]),
                    .ddd => try writer.writeAll(@tagName(self.weekday())),
                    .dddd => try printLongName(writer, @intFromEnum(self.weekday()), &[_]string{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }),
                    .e => try writer.print("{}", .{@intFromEnum(self.weekday())}),
                    .E => try writer.print("{}", .{@intFromEnum(self.weekday()) + 1}),

                    .w => try writer.print("{}", .{self.dayOfThisYear() / 7 + 1}),
                    .wo => try printOrdinal(writer, self.dayOfThisYear() / 7 + 1),
                    .ww => try writer.print("{:0>2}", .{self.dayOfThisYear() / 7 + 1}),

                    .Y => try writer.print("{}", .{self.years + 10000}),
                    .YY => try writer.print("{:0>2}", .{self.years % 100}),
                    .YYY => try writer.print("{}", .{self.years}),
                    .YYYY => try writer.print("{:0>4}", .{self.years}),

                    .N => try writer.writeAll(@tagName(self.era())),
                    .NN => try writer.writeAll("Anno Domini"),

                    .A => try printLongName(writer, self.hours / 12, &[_]string{ "AM", "PM" }),
                    .a => try printLongName(writer, self.hours / 12, &[_]string{ "am", "pm" }),

                    .H => try writer.print("{}", .{self.hours}),
                    .HH => try writer.print("{:0>2}", .{self.hours}),
                    .h => try writer.print("{}", .{wrap(self.hours, 12)}),
                    .hh => try writer.print("{:0>2}", .{wrap(self.hours, 12)}),
                    .k => try writer.print("{}", .{wrap(self.hours, 24)}),
                    .kk => try writer.print("{:0>2}", .{wrap(self.hours, 24)}),

                    .m => try writer.print("{}", .{self.minutes}),
                    .mm => try writer.print("{:0>2}", .{self.minutes}),

                    .s => try writer.print("{}", .{self.seconds}),
                    .ss => try writer.print("{:0>2}", .{self.seconds}),

                    .S => try writer.print("{}", .{self.ms / 100}),
                    .SS => try writer.print("{:0>2}", .{self.ms / 10}),
                    .SSS => try writer.print("{:0>3}", .{self.ms}),

                    .z => try writer.writeAll(@tagName(self.timezone)),
                    .Z => try writer.writeAll("+00:00"),
                    .ZZ => try writer.writeAll("+0000"),

                    .x => try writer.print("{}", .{self.toUnixMilli()}),
                    .X => try writer.print("{}", .{self.toUnix()}),
                }
                next = null;
                s = i;
            }

            switch (c) {
                ',',
                ' ',
                ':',
                '-',
                '.',
                'T',
                'W',
                '/',
                => {
                    try writer.writeAll(&.{c});
                    s = i + 1;
                    continue;
                },
                else => {},
            }
        }
    }

    pub fn formatAlloc(self: Self, alloc: std.mem.Allocator, comptime fmt: string) !string {
        var list = std.ArrayList(u8).init(alloc);
        defer list.deinit();

        try self.format(fmt, .{}, list.writer());
        return list.toOwnedSlice();
    }

    const FormatSeq = enum {
        M, // 1 2 ... 11 12
        Mo, // 1st 2nd ... 11th 12th
        MM, // 01 02 ... 11 12
        MMM, // Jan Feb ... Nov Dec
        MMMM, // January February ... November December
        Q, // 1 2 3 4
        Qo, // 1st 2nd 3rd 4th
        D, // 1 2 ... 30 31
        Do, // 1st 2nd ... 30th 31st
        DD, // 01 02 ... 30 31
        DDD, // 1 2 ... 364 365
        DDDo, // 1st 2nd ... 364th 365th
        DDDD, // 001 002 ... 364 365
        d, // 0 1 ... 5 6
        do, // 0th 1st ... 5th 6th
        dd, // Su Mo ... Fr Sa
        ddd, // Sun Mon ... Fri Sat
        dddd, // Sunday Monday ... Friday Saturday
        e, // 0 1 ... 5 6 (locale)
        E, // 1 2 ... 6 7 (ISO)
        w, // 1 2 ... 52 53
        wo, // 1st 2nd ... 52nd 53rd
        ww, // 01 02 ... 52 53
        Y, // 11970 11971 ... 19999 20000 20001 (Holocene calendar)
        YY, // 70 71 ... 29 30
        YYY, // 1 2 ... 1970 1971 ... 2029 2030
        YYYY, // 0001 0002 ... 1970 1971 ... 2029 2030
        N, // BC AD
        NN, // Before Christ ... Anno Domini
        A, // AM PM
        a, // am pm
        H, // 0 1 ... 22 23
        HH, // 00 01 ... 22 23
        h, // 1 2 ... 11 12
        hh, // 01 02 ... 11 12
        k, // 1 2 ... 23 24
        kk, // 01 02 ... 23 24
        m, // 0 1 ... 58 59
        mm, // 00 01 ... 58 59
        s, // 0 1 ... 58 59
        ss, // 00 01 ... 58 59
        S, // 0 1 ... 8 9 (second fraction)
        SS, // 00 01 ... 98 99
        SSS, // 000 001 ... 998 999
        z, // EST CST ... MST PST
        Z, // -07:00 -06:00 ... +06:00 +07:00
        ZZ, // -0700 -0600 ... +0600 +0700
        x, // unix milli
        X, // unix
    };

    pub fn since(self: Self, other_in_the_past: Self) Duration {
        return Duration{
            .ms = self.toUnixMilli() - other_in_the_past.toUnixMilli(),
        };
    }

    pub fn era(self: Self) Era {
        if (self.years >= 0) return .AD;
        @compileError("TODO");
    }

    pub fn weekday(self: Self) WeekDay {
        var i = self.daysSinceEpoch() % 7;
        var result = WeekDay.Thu; // weekday of epoch_unix
        while (i > 0) : (i -= 1) {
            result = result.next();
        }
        return result;
    }
};

pub const format = struct {
    pub const LT = "h:mm A";
    pub const LTS = "h:mm:ss A";
    pub const L = "MM/DD/YYYY";
    pub const l = "M/D/YYY";
    pub const LL = "MMMM D, YYYY";
    pub const ll = "MMM D, YYY";
    pub const LLL = LL ++ " " ++ LT;
    pub const lll = ll ++ " " ++ LT;
    pub const LLLL = "dddd, " ++ LLL;
    pub const llll = "ddd, " ++ lll;
};

pub const TimeZone = enum {
    UTC,

    usingnamespace extras.TagNameJsonStringifyMixin(@This());
};

pub const WeekDay = enum {
    Sun,
    Mon,
    Tue,
    Wed,
    Thu,
    Fri,
    Sat,

    pub fn next(self: WeekDay) WeekDay {
        return switch (self) {
            .Sun => .Mon,
            .Mon => .Tue,
            .Tue => .Wed,
            .Wed => .Thu,
            .Thu => .Fri,
            .Fri => .Sat,
            .Sat => .Sun,
        };
    }

    usingnamespace extras.TagNameJsonStringifyMixin(@This());
};

pub const Era = enum {
    // BC,
    AD,

    usingnamespace extras.TagNameJsonStringifyMixin(@This());
};

pub fn isLeapYear(year: u16) bool {
    var ret = false;
    if (year % 4 == 0) ret = true;
    if (year % 100 == 0) ret = false;
    if (year % 400 == 0) ret = true;
    return ret;
}

pub fn daysInYear(year: u16) u16 {
    return if (isLeapYear(year)) 366 else 365;
}

fn daysInMonth(year: u16, month: u16) u16 {
    const norm = [12]u16{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    const leap = [12]u16{ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    const month_days = if (!isLeapYear(year)) norm else leap;
    return month_days[month];
}

fn printOrdinal(writer: anytype, num: u16) !void {
    try writer.print("{}", .{num});
    try writer.writeAll(switch (num) {
        1 => "st",
        2 => "nd",
        3 => "rd",
        else => "th",
    });
}

fn printLongName(writer: anytype, index: u16, names: []const string) !void {
    try writer.writeAll(names[index]);
}

fn wrap(val: u16, at: u16) u16 {
    const tmp = val % at;
    return if (tmp == 0) at else tmp;
}

pub const Duration = struct {
    ms: u64,
};

// Divisions of a nanosecond.
pub const ns_per_us = 1000;
pub const ns_per_ms = 1000 * ns_per_us;
pub const ns_per_s = 1000 * ns_per_ms;
pub const ns_per_min = 60 * ns_per_s;
pub const ns_per_hour = 60 * ns_per_min;
pub const ns_per_day = 24 * ns_per_hour;
pub const ns_per_week = 7 * ns_per_day;

// Divisions of a microsecond.
pub const us_per_ms = 1000;
pub const us_per_s = 1000 * us_per_ms;
pub const us_per_min = 60 * us_per_s;
pub const us_per_hour = 60 * us_per_min;
pub const us_per_day = 24 * us_per_hour;
pub const us_per_week = 7 * us_per_day;

// Divisions of a millisecond.
pub const ms_per_s = 1000;
pub const ms_per_min = 60 * ms_per_s;
pub const ms_per_hour = 60 * ms_per_min;
pub const ms_per_day = 24 * ms_per_hour;
pub const ms_per_week = 7 * ms_per_day;

// Divisions of a second.
pub const s_per_min = 60;
pub const s_per_hour = s_per_min * 60;
pub const s_per_day = s_per_hour * 24;
pub const s_per_week = s_per_day * 7;
