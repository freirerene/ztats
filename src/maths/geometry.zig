const std = @import("std");

pub const Point = struct {
    x: f64 = 0.0,
    y: f64 = 0.0,
};

fn find_rectangle(points: anytype) [2]Point {
    var supx: f64 = -std.math.inf(f64);
    var supy: f64 = -std.math.inf(f64);
    var infx: f64 = std.math.inf(f64);
    var infy: f64 = std.math.inf(f64);

    for (points) |p| {
        if (p.x > supx) supx = p.x;
        if (p.x < infx) infx = p.x;
        if (p.y > supy) supy = p.y;
        if (p.y < infy) infy = p.y;
    }

    return .{ Point{ .x = infx, .y = infy }, Point{ .x = supx, .y = supy } };
}
