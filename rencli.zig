const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const StringArray = ArrayList([]const u8);
const StringMatrix = ArrayList(StringArray);

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

fn buildMatrix(allocator: mem.Allocator, input: []const []const u8) !StringMatrix {
    var matrix = StringMatrix.init(allocator);
    var row = StringArray.init(allocator);
    for (input) |char| {
        if (mem.eql(u8, char, "-2")) {
            try matrix.append(row);
            row = StringArray.init(allocator);
        } else {
            try row.append(char);
        }
    }
    return matrix;
}

// its like lmove in nim code lol

fn moveLeft(allocator: mem.Allocator, matrix: StringMatrix) !StringMatrix {
    var newMatrix = StringMatrix.init(allocator);
    for (matrix.items) |row| {
        var newRow = StringArray.init(allocator);
        for (row.items[1..]) |item| {
            try newRow.append(item);
        }
        try newRow.append(row.items[0]);
        try newMatrix.append(newRow);
    }
    return newMatrix;
}

fn moveRight(allocator: mem.Allocator, matrix: StringMatrix) !StringMatrix {
    var newMatrix = StringMatrix.init(allocator);
    for (matrix.items) |row| {
        var newRow = StringArray.init(allocator);
        try newRow.append(row.items[row.items.len - 1]);
        for (row.items[0..row.items.len - 1]) |item| {
            try newRow.append(item);
        }
        try newMatrix.append(newRow);
    }
    return newMatrix;
}

fn moveUp(allocator: mem.Allocator, matrix: StringMatrix) !StringMatrix {
    var newMatrix = StringMatrix.init(allocator);
    try newMatrix.append(matrix.items[matrix.items.len - 1]);
    for (matrix.items[0..matrix.items.len - 1]) |row| {
        try newMatrix.append(row);
    }
    return newMatrix;
}

fn moveDown(allocator: mem.Allocator, matrix: StringMatrix) !StringMatrix {
    var newMatrix = StringMatrix.init(allocator);
    for (matrix.items[1..]) |row| {
        try newMatrix.append(row);
    }
    try newMatrix.append(matrix.items[0]);
    return newMatrix;
}

fn matrixToArray(allocator: mem.Allocator, matrix: StringMatrix) ![]const []const u8 {
    var array = ArrayList([]const u8).init(allocator);
    for (matrix.items) |row| {
        for (row.items) |item| {
            try array.append(item);
        }
        try array.append("-2");
    }
    return array.toOwnedSlice();
}

fn color_char(allocator: mem.Allocator, char: []const u8, shadow: u8) ![]const u8 {
    const cust = [_][]const u8{
        "0", "\x1B[30;1m", "\x1B[40;1m",
        "1", "\x1B[31;1m", "\x1B[41;1m",
        "2", "\x1B[32;1m", "\x1B[42;1m",
    };
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
                    .{ if (shadow == 0) bg_code else "", color_code, vj },
                );
            }
        }
        return try fmt.allocPrint(allocator, "\x1B[0m\x1B[1m{s}{s}\x1B[0m", .{ char, char });
    }
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const input = [_][]const u8{
        "0", "0", "0", "0", "-2",
        "0", "2", "1", "0", "-2",
        "0", "0", "1", "0", "-2",
    };

    var matrix = try buildMatrix(allocator, &input);
    defer matrix.deinit();

    var movedDown = try moveDown(allocator, matrix);
    defer movedDown.deinit();

    const array = try matrixToArray(allocator, movedDown);
    defer allocator.free(array);

    const cp_out = UTF8ConsoleOutput.init();
    defer cp_out.deinit();

    var bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = bw.writer();

    for (array) |char| {
        const colored = try color_char(allocator, char, 0);
        defer allocator.free(colored);
        try writer.writeAll(colored);
    }

    try bw.flush();
}
