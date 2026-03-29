const std = @import("std");
const zboost = @import("zboost");

pub fn main() !void {
    const a: [3]f32 = .{ 1.0, 2.0, 1.0 };
    const b: [3]f32 = .{ 0.5, 2.0, 2.1 };

    const r = try zboost.regression.rmse(a, b);
    std.debug.print("{any}\n", .{r});
}
