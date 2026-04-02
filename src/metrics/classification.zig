
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









