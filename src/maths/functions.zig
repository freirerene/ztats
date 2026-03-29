const std = @import("std");
pub const math = std.math;
const u = @import("../utils.zig");

pub fn sq(x: anytype) @TypeOf(x) {
    return x * x;
}

pub fn mean(x: anytype) f64 {
    var sum: f64 = 0;
    const N: f64 = @floatFromInt(x.len);

    for (x) |i| {
        sum += u.to_float(i);
    }

    return sum / N;
}

pub fn variance(x: anytype) f64 {
    var sum: f64 = 0;
    const N: f64 = @floatFromInt(x.len);
    const mean_x: f64 = mean(x);

    for (x) |i| {
        sum += sq(@abs(u.to_float(i) - mean_x));
    }

    return sum / N;
}


