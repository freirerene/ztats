const Point = @import("../maths/geometry.zig").Point;
const integrals = @import("../maths/intergrals.zig");

pub fn TP(y: anytype, yhat: anytype, cutoff: f64) f64 {
    var sum_tp: f64 = 0.0;

    for (yhat, y) |yhat_i, y_i| {
        if (yhat_i.? >= cutoff) {
            sum_tp += 1.0*y_i.?;
        } 
    }
    return sum_tp;
}

pub fn TN(y: anytype, yhat: anytype, cutoff: f64) f64 {
    var sum_tn: f64 = 0.0;

    for (yhat, y) |yhat_i, y_i| {
        if (yhat_i.? < cutoff) {
            sum_tn += 1.0*(1.0 - y_i.?);
        } 
    }
    return sum_tn;
}

pub fn FP(y: anytype, yhat: anytype, cutoff: f64) f64 {
    var sum_fp: f64 = 0.0;

    for (yhat, y) |yhat_i, y_i| {
        if (yhat_i.? >= cutoff) {
            sum_fp += 1.0*(1.0 - y_i.?);
        } 
    }
    return sum_fp;
}

pub fn FN(y: anytype, yhat: anytype, cutoff: f64) f64 {
    var sum_fn: f64 = 0.0;

    for (yhat, y) |yhat_i, y_i| {
        if (yhat_i.? < cutoff) {
            sum_fn += 1.0*y_i.?;
        } 
    }
    return sum_fn;
}

pub fn accuracy(y: anytype, yhat: anytype, cutoff: f64) f64 {
    const N: f64 = @floatFromInt(y.len);
    return (TP(y, yhat, cutoff) + TN(y, yhat, cutoff))/N;
}

pub fn recall(y: anytype, yhat: anytype, cutoff: f64) f64 {
    return TP(y, yhat, cutoff)/(TP(y, yhat, cutoff) + FN(y, yhat, cutoff));
}

pub fn precision(y: anytype, yhat: anytype, cutoff: f64) f64 {
    return TP(y, yhat, cutoff)/(TP(y, yhat, cutoff) + FP(y, yhat, cutoff));
}

pub fn f1(y: anytype, yhat: anytype, cutoff: f64) f64 {
    return 2*(precision(y, yhat, cutoff) * recall(y, yhat, cutoff))/(precision(y, yhat, cutoff) + recall(y, yhat, cutoff));
}


pub fn roc(y: anytype, yhat: anytype, comptime cutoff_values: u64) [cutoff_values]Point {
    var positive_vals: f64 = 0;
    var negative_vals: f64 = 0;

    for (y) |y_i| {
        positive_vals += y_i.?;
        negative_vals += (1 - y_i.?);
    }
    
    var roc_value: [cutoff_values]Point = undefined;

    for (1..cutoff_values) |i| {
        const c: f64 = @as(f64,@floatFromInt(i)) / cutoff_values;

        const TPR: f64 = TP(y, yhat, c) / positive_vals;
        const FPR: f64 = FP(y, yhat, c) / negative_vals;
        
        roc_value[i-1] = Point{
            .x = FPR,
            .y = TPR,
        };
    }
    return roc_value;
}

pub fn roc_auc(roc_points: anytype, comptime iterations: u64) !f64 {
    return try integrals.monte_carlo_int(roc_points, 0.0, 1.0,  iterations);
}







