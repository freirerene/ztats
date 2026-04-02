const std = @import("std");
const z = @import("ztats");

const FnType = *const fn ([]const u8, []const u8, []const u8) anyerror!void;

const commands = std.StaticStringMap(FnType).initComptime(.{
    .{ "ttest", z.normaltests.run_ttest },
});

fn dispatch(cli: z.cli.CliArgs) !void {
    const func = commands.get(cli.function_name) orelse {
        std.debug.print("Unknown function: {s}\n", .{cli.function_name});
        return error.UnknownFunction;
    };
    try func(cli.csv_file, cli.col1, cli.col2);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const cli = try z.cli.parseArgs(args[1..]);
    try dispatch(cli);
}
