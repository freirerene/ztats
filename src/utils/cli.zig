const std = @import("std");

pub const CliArgs = struct {
    csv_file: []const u8,
    col1: []const u8,
    col2: []const u8,
    function_name: []const u8,
};

pub const CliError = error{
    NoCsvPassed,
    NeedColumns,
    NoColumn1,
    NoColumn2,
    NeedFunction,
    UnknownArgument,
};

pub fn parseArgs(args: []const [:0]const u8) CliError!CliArgs {
    var csv_file: ?[]const u8 = null;
    var col1: ?[]const u8 = null;
    var col2: ?[]const u8 = null;
    var function_name: ?[]const u8 = null;

    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            std.debug.print("Usage: program --csv=path --columns=col1,col2 --function=fn\n", .{});
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--csv=")) {
            const value = arg["--csv=".len..];
            if (value.len == 0) return error.NoCsvPassed;
            csv_file = value;
        } else if (std.mem.startsWith(u8, arg, "--columns=")) {
            const columns = arg["--columns=".len..];
            if (columns.len == 0) return error.NeedColumns;
            var it = std.mem.splitScalar(u8, columns, ',');
            col1 = it.next() orelse return error.NoColumn1;
            col2 = it.next() orelse return error.NoColumn2;
        } else if (std.mem.startsWith(u8, arg, "--function=")) {
            const value = arg["--function=".len..];
            if (value.len == 0) return error.NeedFunction;
            function_name = value;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return error.UnknownArgument;
        }
    }

    return CliArgs{
        .csv_file = csv_file orelse return error.NoCsvPassed,
        .col1 = col1 orelse return error.NoColumn1,
        .col2 = col2 orelse return error.NoColumn2,
        .function_name = function_name orelse return error.NeedFunction,
    };
}

