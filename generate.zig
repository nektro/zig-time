// grep '^Zone' africa antarctica asia australasia europe northamerica southamerica etcetera factory backward | cut -d':' -f2- | awk '{$1=$1}1' | cut -d' ' -f2 | sort | grep -e '/'

const std = @import("std");
const nfs = @import("nfs");
const nio = @import("nio");
const extras = @import("extras");

const deps = @import("./deps.zig");

pub fn main() !void {
    const sources = [_][:0]const u8{
        "africa",
        "antarctica",
        "asia",
        "australasia",
        "europe",
        "northamerica",
        "southamerica",
        "etcetera",
        "factory",
        "backward",
    };

    const path = deps.dirs._xw6xua7fqgft;
    const allocator = std.heap.c_allocator;

    var dir = try nfs.cwd().openDir(path, .{});
    defer dir.close();

    var zones: std.ArrayList([]const u8) = .empty;
    defer zones.deinit(allocator);

    for (&sources) |nm| {
        var file = try dir.openFile(nm, .{});
        defer file.close();

        const content = try file.mmap();
        defer nfs.munmap(content);

        var iter = std.mem.splitScalar(u8, content, '\n');
        while (iter.next()) |line| {
            if (!std.mem.startsWith(u8, line, "Zone")) continue;

            var jter = std.mem.tokenizeAny(u8, line, " \t");
            _ = jter.next().?;
            const name = jter.next().?;
            if (std.mem.indexOfScalar(u8, name, '/') == null) continue;
            try zones.append(allocator, try allocator.dupe(u8, name));
        }
    }

    std.mem.sort([]const u8, zones.items, {}, extras.lessThanSlice([]const u8));

    var out_file = try nfs.cwd().createFile("zone.zig", .{});
    defer out_file.close();
    var out_w: nio.BufferedWriter(4096, nfs.File) = .init(out_file);

    try out_w.writeAll("pub const Zone = enum {\n");
    for (zones.items) |z| {
        try out_w.print("    {},\n", .{FormatId{ .bytes = z }});
    }
    try out_w.writeAll("};\n");
    try out_w.flush();
}

const FormatId = struct {
    bytes: []const u8,

    /// Print the string as a Zig identifier, escaping it with `@""` syntax if needed.
    pub fn nprint(ctx: FormatId, writer: anytype) !void {
        const bytes = ctx.bytes;
        if (std.zig.isValidId(bytes) and (!std.zig.isPrimitive(bytes)) and (!std.zig.isUnderscore(bytes))) {
            return writer.writeAll(bytes);
        }
        try writer.writeAll("@\"");
        try stringEscape(bytes, writer);
        try writer.writeAll("\"");
    }

    fn stringEscape(bytes: []const u8, w: anytype) !void {
        for (bytes) |byte| switch (byte) {
            '\n' => try w.writeAll("\\n"),
            '\r' => try w.writeAll("\\r"),
            '\t' => try w.writeAll("\\t"),
            '\\' => try w.writeAll("\\\\"),
            '"' => try w.writeAll("\\\""),
            '\'' => try w.writeAll("'"),
            ' ', '!', '#'...'&', '('...'[', ']'...'~' => try w.writeAll(&.{byte}),
            else => {
                try w.writeAll("\\x");
                try w.print("{x:2>0}", .{byte});
            },
        };
    }
};
