const m = @import("../maths/functions.zig");
const special = @import("../maths/specials.zig");

pub fn ttest(a: anytype, b: anytype) ![3]f64 {
    const N_a: i32 = a.len;
    const N_b: i32 = b.len;
    
    const mean_a: f64 = m.mean(a);
    const mean_b: f64 = m.mean(b);

    const var_a: f64 = m.variance(a);
    const var_b: f64 = m.variance(b);

    const se: f64 = @sqrt(var_a/N_a + var_b/N_b);
    const t: f64 = (mean_a - mean_b) / se;
    
    const df_numerator: f64 = m.sq(var_a/N_a + var_b/N_b);
    const df_denominator: f64 = m.sq(var_a/N_a)/(N_a-1) +  m.sq(var_b/N_b)/(N_b-1);

    const df: f64 = df_numerator / df_denominator;
    const x: f64 = df / (df + m.sq(t));
    const p = try special.betainc(df / 2, 0.5, x);
    return .{t, df, p};
}





