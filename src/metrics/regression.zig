const std = @import("std");
const f = @import("../maths/functions.zig");
const u = @import("../utils/conversions.zig");


const Epsilon = struct {
    epsilon: f64 = 1e-8,
};

pub fn rmse(y: anytype, yhat: anytype) !f64 {
    if (y.len != yhat.len) {
        return error.SizeMismatch;
    }
    
    var y_difference: f64 = 0;

    for (y, yhat) |y_j, yhat_j| {
        const y_i = u.to_float(y_j);
        const yhat_i = u.to_float(yhat_j);

        y_difference += f.sq(y_i - yhat_i);
    }

    const N: f64 = @floatFromInt(y.len);
    return @sqrt(y_difference / N);
}

pub fn mae(y: anytype, yhat: anytype) !f64{
    if (y.len != yhat.len) {
        return error.SizeMismatch;
    }
    
    var y_difference: f64 = 0;

    for (y, yhat) |y_j, yhat_j| {
        const y_i = u.to_float(y_j);
        const yhat_i = u.to_float(yhat_j);

        y_difference += @abs(y_i - yhat_i);
    }

    const N: f64 = @floatFromInt(y.len);
    return y_difference / N;
}


pub fn mape(y: anytype, yhat: anytype, opts: Epsilon) !f64 {
    if (y.len != yhat.len) {
        return error.SizeMismatch;
    }
    
    var y_difference: f64 = 0;
    const epsilon = opts.epsilon;

    for (y, yhat) |y_j, yhat_j| {
        const y_i = u.to_float(y_j);
        const yhat_i = u.to_float(yhat_j);

        y_difference += @abs(y_i - yhat_i)/@max(@abs(y_i), epsilon);
    }

    const N: f64 = @floatFromInt(y.len);
    return y_difference / N;
}


pub fn log_mse(y: anytype, yhat: anytype) !f64  {
    if (y.len != yhat.len) {
        return error.SizeMismatch;
    }

    var y_difference: f64 = 0; 

    for (y, yhat) |y_j, yhat_j| {
        const y_i = u.to_float(y_j);
        const yhat_i = u.to_float(yhat_j);

        var y_difference_i = f.math.log1p(y_i) - f.math.log1p(yhat_i);
        y_difference_i = f.sq(y_difference_i);

        y_difference += y_difference_i;
    }
    const N: f64 = @floatFromInt(y.len);
    return y_difference / N;
}





