const f = @import("functions.zig");

const TINY: f64 = 1e-300;
const EPS: f64 = 1e-15;
const MAX_ITER: i32  = 500;
const LANCZOS_COEFF: [9]f64 = .{0.99999999999980993,
                                676.5203681218851,
                                -1259.1392167224028,
                                771.32342877765313,
                                -176.61502916214059,
                                12.507343278686905,
                                -0.13857109526572012,
                                9.9843695780195716e-6,
                                1.5056327351493116e-7,};

pub fn log_gamma(z: f64) f64 {
    if (z < 0.5) {
        return @log(f.math.pi) - @log(@abs(@sin(z * f.math.pi))) - log_gamma(1.0 - z);
    }
    if (z == 1) {
        return 0.0;
    }
    const x: f64 = z - 1.0;
    var Ag: f64 = LANCZOS_COEFF[0];

    for (LANCZOS_COEFF[1..], 1..) |c, i| {
        const j: f64 = @floatFromInt(i);
        const xi: f64 = x + j;
        Ag += c / xi;
    }

    const t: f64 = x + 7.5;

    return 0.5 * @log(2.0 * f.math.pi) + (x + 0.5) * @log(t) - t + @log(Ag);
}

pub fn log_beta(a: f64, b: f64) f64 {
    return log_gamma(a) + log_gamma(b) - log_gamma(a + b);
}

fn d_condition(d: f64) f64 {
    var x: f64 = d;
    if (@abs(d) < TINY){
        x = TINY;
    }
    return 1.0 / x;
}


pub fn I_xab(a: f64, b: f64, x: f64) !f64 {
    const qab: f64 = a + b;
    const qap: f64 = a + 1.0;
    const qam: f64 = a - 1.0;

    var d: f64 = 1.0 - qab * x / qap;
    d = d_condition(d);

    var c: f64 = 1.0;
    var mult: f64 = d;

    for (1..MAX_ITER) |j| {
        const i: f64 = @floatFromInt(j);
        const num_even: f64 = i * (b - i) * x / ((qam + 2*i) * (a + 2*i)); 
        d = 1.0 + num_even * d;
        d = d_condition(d);

        c = 1.0 + num_even / c;
        if (@abs(c) < TINY) {
            c = TINY;
        }

        mult *= d * c;

        const num_odd: f64 = -(a + i) * (qab + i) * x / ((a + 2*i) * (qap + 2*i));
        d = 1.0 + num_odd * d;
        d = d_condition(d);

        c = 1.0 + num_odd / c;
        if (@abs(c) < TINY) {
            c = TINY;
        }
        mult *= d * c;
        if (@abs(d * c - 1.0) < EPS) {
            return mult;
        }
    }
    return error.NoConvergence;
}

const validIntervals = error{
    xNotIn01,
    abNotGreater0,
};

pub fn betainc(a: f64, b: f64, x: f64) !f64 {
    if (x < 0.0 or x > 1.0) {
        return validIntervals.xNotIn01;
    }
    if (a <= 0.0 or b <= 0.0) {
        return validIntervals.abNotGreater0;
    }
    if (x == 0.0 or x == 1.0) {
        return x;
    }

    const log_prefix: f64 = a * @log(x) + b * @log(1.0 - x) - log_beta(a, b);

    if (x < (a + 1.0)/(a + b + 2.0)) {
        const cf = try I_xab(a, b, x);
        return @exp(log_prefix) * cf / a;
    } else {
        const cf = try I_xab(b, a, 1.0 - x);
        return 1.0 - @exp(log_prefix) * cf / b;
    }
}








