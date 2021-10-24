const std = @import("std");
const string = []const u8;
const range = @import("range").range;

pub const DateTime = struct {
    ms: u16,
    seconds: u16,
    minutes: u16,
    hours: u16,
    days: u16,
    months: u16,
    years: u16,
    timezone: TimeZone,
    weekday: WeekDay,
    era: Era,

    const Self = @This();

    pub fn initUnixMs(unix: u64) Self {
        return epoch_unix.addMs(unix);
    }

    pub fn initUnix(unix: u64) Self {
        return epoch_unix.addSecs(unix);
    }

    /// Caller asserts that this is > epoch
    pub fn init(year: u16, month: u16, day: u16, hr: u16, min: u16, sec: u16) Self {
        return epoch_unix
            .addYears(year - epoch_unix.years)
            .addMonths(month)
            .addDays(day)
            .addHours(hr)
            .addMins(min)
            .addSecs(sec);
    }

    pub fn now() Self {
        return initUnixMs(@intCast(u64, std.time.milliTimestamp()));
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
        .weekday = .Thu,
        .era = .AD,
    };

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
        result.ms += @intCast(u16, count % 1000);
        return result.addSecs(count / 1000);
    }

    pub fn addSecs(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.seconds += @intCast(u16, count % 60);
        return result.addMins(count / 60);
    }

    pub fn addMins(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.minutes += @intCast(u16, count % 60);
        return result.addHours(count / 60);
    }

    pub fn addHours(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        result.hours += @intCast(u16, count % 24);
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
                result.incrementWeekday(year_len);
                continue;
            }
            break;
        }
        while (true) {
            const month_len = result.daysThisMonth();
            if (input >= month_len) {
                result.months += 1;
                input -= month_len;
                result.incrementWeekday(month_len);

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
                const left = month_len - result.days;
                input -= left;
                result.months += 1;
                result.days = 0;
                result.incrementWeekday(left);
            }
            result.days += @intCast(u16, input);
            result.incrementWeekday(input);

            if (result.months == 12) {
                result.years += 1;
                result.months = 0;
            }
        }

        return result;
    }

    pub fn addMonths(self: Self, count: u64) Self {
        if (count == 0) return self;
        var result = self;
        var input = count;
        while (input > 0) {
            const new = result.addDays(result.daysThisMonth());
            result = new;
            input -= 1;
        }
        return result;
    }

    pub fn addYears(self: Self, count: u64) Self {
        if (count == 0) return self;
        return self.addMonths(count * 12);
    }

    pub fn isLeapYear(self: Self) bool {
        const y = self.years;
        var ret = false;
        if (y % 4 == 0) ret = true;
        if (y % 100 == 0) ret = false;
        if (y % 400 == 0) ret = true;
        return ret;
    }

    pub fn daysThisYear(self: Self) u64 {
        return if (self.isLeapYear()) 366 else 365;
    }

    pub fn daysThisMonth(self: Self) u16 {
        return self.daysInMonth(self.months);
    }

    fn daysInMonth(self: Self, month: u16) u16 {
        const norm = [12]u16{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
        const leap = [12]u16{ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
        const month_days = if (!self.isLeapYear()) norm else leap;
        return month_days[month];
    }

    fn incrementWeekday(self: *Self, count: u64) void {
        for (range(count % 7)) |_| {
            self.weekday = self.weekday.next();
        }
    }

    pub fn dayOfThisYear(self: Self) u16 {
        var ret: u16 = 0;
        for (range(self.months)) |_, item| {
            ret += self.daysInMonth(@intCast(u16, item));
        }
        ret += self.days;
        return ret;
    }

    /// fmt is based on https://momentjs.com/docs/#/displaying/format/
    pub fn format(self: Self, comptime fmt: string, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        if (fmt.len == 0) @compileError("DateTime: format string can't be empty");

        _ = writer;
        _ = self;

        @setEvalBranchQuota(100000);

        comptime var s = 0;
        comptime var e = 0;
        comptime var next: ?FormatSeq = null;
        inline for (fmt) |c, i| {
            e = i + 1;

            if (comptime std.meta.stringToEnum(FormatSeq, fmt[s..e])) |tag| {
                next = tag;
                if (i < fmt.len - 1) continue;
            }

            if (next) |tag| {
                switch (tag) {
                    .ddd => try writer.writeAll(@tagName(self.weekday)),
                    .DD => try writer.print("{:0>2}", .{self.days + 1}),
                    .YYYY => try writer.print("{:0>4}", .{self.years}),
                    .HH => try writer.print("{:0>2}", .{self.hours}),
                    .mm => try writer.print("{:0>2}", .{self.minutes}),
                    .ss => try writer.print("{:0>2}", .{self.seconds}),
                    .SSS => try writer.print("{:0>3}", .{self.ms}),
                    .MM => try writer.print("{:0>2}", .{self.months + 1}),
                    .z => try writer.writeAll(@tagName(self.timezone)),
                    .M => try writer.print("{}", .{self.months + 1}),
                    .Mo => try printOrdinal(writer, self.months + 1),
                    .MMM => try printLongName(writer, self.months, &[_]string{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }),
                    .MMMM => try printLongName(writer, self.months, &[_]string{ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }),
                    .Q => try writer.print("{}", .{self.months / 3 + 1}),
                    .Qo => try printOrdinal(writer, self.months / 3 + 1),
                    .D => try writer.print("{}", .{self.days + 1}),
                    .Do => try printOrdinal(writer, self.days + 1),
                    .DDD => try writer.print("{}", .{self.dayOfThisYear() + 1}),
                    .DDDo => try printOrdinal(writer, self.dayOfThisYear() + 1),
                    .DDDD => try writer.print("{:0>3}", .{self.dayOfThisYear() + 1}),
                    .d => try writer.print("{}", .{@enumToInt(self.weekday)}),
                    .do => try printOrdinal(writer, @enumToInt(self.weekday)),
                    .dd => try writer.writeAll(@tagName(self.weekday)[0..2]),
                    .dddd => try printLongName(writer, @enumToInt(self.weekday), &[_]string{ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }),
                    .E => try writer.print("{}", .{@enumToInt(self.weekday) + 1}),
                    .w => try writer.print("{}", .{self.dayOfThisYear() / 7 + 1}),
                    .wo => try printOrdinal(writer, self.dayOfThisYear() / 7 + 1),
                    .ww => try writer.print("{:0>2}", .{self.dayOfThisYear() / 7 + 1}),

                    else => @compileError("'" ++ @tagName(tag) ++ "' not currently supported"),
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
                => {
                    try writer.writeAll(&.{c});
                    s = i + 1;
                    continue;
                },
                else => {},
            }

            if (i < fmt.len - 1) @compileError(comptime std.fmt.comptimePrint("'{s}' is not a valid format sequence", .{fmt[s..e]}));
        }
    }

    pub fn formatAlloc(self: Self, alloc: *std.mem.Allocator, comptime fmt: string) !string {
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
        W, // 1 2 ... 52 53 (ISO)
        Wo, // 1st 2nd ... 52nd 53rd
        WW, // 01 02 ... 52 53
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
        X, // unix
        x, // unix milli
    };
};

pub const format = struct {
    pub const LT = "";
    pub const LTS = "";
    pub const L = "";
    pub const l = "";
    pub const LL = "";
    pub const ll = "";
    pub const LLL = "";
    pub const lll = "";
    pub const LLLL = "";
    pub const llll = "";
};

pub const TimeZone = enum {
    UTC,
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
};

pub const Era = enum {
    // BC,
    AD,
};

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
