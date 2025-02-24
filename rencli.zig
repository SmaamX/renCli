const std = @import("std");
const builtin = @import("builtin");
const fmt = std.fmt;
const time = std.time;
const mem = std.mem;
const process = std.process;
const ArrayList = std.ArrayList;
const StringArray = ArrayList([]const u8);
const StringMatrix = ArrayList(StringArray);
const unicode = std.unicode;
const stdout = std.io.getStdOut().outStream();

// from github.com/ziglang/zig/issues/18229
const UTF8ConsoleOutput = struct {
    original: if (builtin.os.tag == .windows) c_uint else void,

    fn init() UTF8ConsoleOutput {
        if (builtin.os.tag == .windows) {
            const original = std.os.windows.kernel32.GetConsoleOutputCP();
            _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
            return .{ .original = original };
        }
        return .{ .original = {} };
    }

    fn deinit(self: UTF8ConsoleOutput) void {
        if (builtin.os.tag == .windows) {
            _ = std.os.windows.kernel32.SetConsoleOutputCP(self.original);
        }
    }
};

const cust = [_][]const u8{
    "0", "\x1B[30;1m", "\x1B[40;1m",
    "1", "\x1B[31;1m", "\x1B[41;1m",
    "2", "\x1B[32;1m", "\x1B[42;1m",
};

var fp: i32 = 0;
var backlog: []const u8 = "";
var bol: bool = false;
var mand: bool = true;

fn addLists(allocator: mem.Allocator, list1: StringArray, list2: StringArray) !StringArray {
    var result = StringArray.init(allocator);
    for (list1.items, list2.items) |a, b| {
        const num1 = try fmt.parseInt(i32, a, 10);
        const num2 = try fmt.parseInt(i32, b, 10);
        try result.append(try fmt.allocPrint(allocator, "{d}", .{num1 + num2}));
    }
    return result;
}

fn delLists(allocator: mem.Allocator, list1: StringArray, list2: StringArray) !StringArray {
    var result = StringArray.init(allocator);
    for (list1.items, list2.items) |a, b| {
        const num1 = try fmt.parseInt(i32, a, 10);
        const num2 = try fmt.parseInt(i32, b, 10);
        try result.append(try fmt.allocPrint(allocator, "{d}", .{num1 - num2}));
    }
    return result;
}

fn color_char(allocator: std.mem.Allocator, char: []const u8, shadow: u8) ![]const u8 {
    const vj = switch (shadow) {
        0 => "█",
        1 => "▓",
        2 => "▒",
        3 => "░",
        else => return error.InvalidShadow,
    };

    if (mem.eql(u8, char, "-2")) {
        return try fmt.allocPrint(allocator, "\x1B[0m\n", .{});
    } else if (mem.eql(u8, char, "-1")) {
        return try fmt.allocPrint(allocator, "\x1B[0m\r", .{});
    } else {
        for (cust, 0..) |c, i| {
            if (mem.eql(u8, c, char) and i % 3 == 0) {
                const color_code = cust[i + 1];
                const bg_code = cust[i + 2];
                return try fmt.allocPrint(
                    allocator,
                    "\x1B[0m{s}{s}{s}\x1B[0m",
                    .{ if (shadow == 0) bg_code else "", color_code, vj }
                );
            }
        }
        return try fmt.allocPrint(allocator, "\x1B[0m\x1B[1m{s}{s}\x1B[0m", .{ char, char });
    }
}

fn colorize_array(
    allocator: std.mem.Allocator,
    chars: []const []const u8,
    shadow: u8
) ![]const u8 {
    var buffer = ArrayList(u8).init(allocator);
    defer buffer.deinit();

    for (chars) |c| {
        const colored = try color_char(allocator, c, shadow);
        defer allocator.free(colored);
        try buffer.appendSlice(colored);
    }

    return buffer.toOwnedSlice();
}

//pub fn main() !void {
//    const allocator = std.heap.page_allocator;
//    const input = [_][]const u8{"1", "2", "0", "1", "-2", "1"};
//    const result = try colorize_array(allocator, &input, 0);
//    defer allocator.free(result);
//    const cp_out = UTF8ConsoleOutput.init();
//    defer cp_out.deinit();
//    try std.io.getStdOut().writer().print("{s}", .{result});
//}
