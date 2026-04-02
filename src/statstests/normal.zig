const std = @import("std");
const m = @import("../maths/functions.zig");
const special = @import("../maths/specials.zig");
const csv = @import("../utils/csv.zig");

pub fn ttest(a: anytype, b: anytype) ![3]f64 {
    const N_a: f64 = m.countNonNull(a);
    const N_b: f64 = m.countNonNull(b);
    
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

pub fn run_ttest(csv_path: []const u8, col1: []const u8, col2: []const u8) !void {
    const allocator = std.heap.page_allocator;

    var matrix = try csv.readCsv(allocator, csv_path, ',');
    defer matrix.deinit();

    const yhat_col = matrix.columnIndex(col2) orelse return error.NotFound;
    const yhat = try matrix.getColumnFloat(yhat_col);
    
    const y_col = matrix.columnIndex(col1) orelse return error.NotFound;
    const y = try matrix.getColumnFloat(y_col);

    defer allocator.free(yhat);
    defer allocator.free(y);

    const results = try ttest(y, yhat);
    const t = results[0];
    const df = results[1];
    const p = results[2];
    std.debug.print("t {any}; df {any}; p {any}\n", .{t, df, p});
}




