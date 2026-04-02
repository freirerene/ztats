const std = @import("std");
pub const math = std.math;
const u = @import("../utils/conversions.zig");

pub fn sq(x: anytype) @TypeOf(x) {
    return x * x;
}

pub fn mean(x: anytype) f64 {
    var sum: f64 = 0;
    var count: usize = 0;

    for (x) |i| {
        if (@typeInfo(@TypeOf(i)) == .optional) {
            if (i) |v| {
                sum += u.to_float(v);
                count += 1;
            }
        } else {
            sum += u.to_float(i);
            count += 1;
        }
    }

    return sum / @as(f64, @floatFromInt(count));
}

pub fn variance(x: anytype) f64 {
    var sum: f64 = 0;
    var count: usize = 0;
    const mean_x: f64 = mean(x);

    for (x) |i| {
        if (@typeInfo(@TypeOf(i)) == .optional) {
            if (i) |v| {
                sum += sq(@abs(u.to_float(v) - mean_x));
                count += 1;
            }
        } else {
            sum += sq(@abs(u.to_float(i) - mean_x));
            count += 1;
        }
    }

    return sum / @as(f64, @floatFromInt(count));
}

pub fn countNonNull(x: anytype) f64 {
    if (@typeInfo(std.meta.Elem(@TypeOf(x))) == .optional) {
        var count: usize = 0;
        for (x) |i| {
            if (i != null) count += 1;
        }
        return @floatFromInt(count);
    }
    return @floatFromInt(x.len);
}
