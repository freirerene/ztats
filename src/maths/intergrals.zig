const std = @import("std");
const Point = @import("../maths/geometry.zig").Point;

fn f_on_x(points: anytype, x_point: f64) f64 {

    var x: f64 = -std.math.inf(f64);
    var dmin: f64 = std.math.inf(f64);

    for (points) |p| {
        const dist = @abs(p.x - x_point);
        if (dist < dmin) {
            dmin = dist;
            x = p.x;
        }
    }

    var fx: f64 = 0;
    for (points) |p| {
        if (x == p.x) {
            fx = p.y;
        }
    }

    return fx;
}


pub fn monte_carlo_int(points: anytype, a: f64, b: f64,  comptime iterations: u64) !f64 {
    
    if (a >= b) return error.MakeALessB;

    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();
    
    var sum_f: f64 = 0.0;

    for (0..iterations) |_| {
        const p = a + rand.float(f64) * (b - a);
        sum_f += f_on_x(points, p);
    }

    const N: f64 = @floatFromInt(iterations);
    return (b - a) * sum_f / N;
}








