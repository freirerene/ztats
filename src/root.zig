pub const maths = @import("maths/functions.zig");
pub const specials = @import("maths/specials.zig"); 
pub const regression = @import("metrics/regression.zig");
pub const normaltests = @import("statstests/normal.zig");
pub const conversions = @import("utils/conversions.zig");
pub const csv = @import("utils/csv.zig");
pub const cli = @import("utils/cli.zig")
;
const std = @import("std");
const series = @import("consts.zig");

test "test metrics" {
    const a: [3]f32 = .{ 1.0, 2.0, 1.0 };
    const b: [3]f32 = .{ 0.5, 2.0, 2.1 };

    const r = try regression.rmse(a, b);
    std.debug.print("rmse: {any}\n", .{r});

    const r_mae = try regression.mae(a, b);
    std.debug.print("mae: {any}\n", .{r_mae});

    const r_msle = try regression.log_mse(a, b);
    std.debug.print("{any}\n", .{r_msle});

    const r_mape = try regression.mape(a, b, .{});
    std.debug.print("mape: {any}\n", .{r_mape});

    const r_mape_1 = try regression.mape(a, b, .{.epsilon = 0.01});
    std.debug.print("mape (eps=0.01): {any}\n", .{r_mape_1});
}

test "special functions" {
    const TestValues = struct {
        v_0: [4]f64,
        v_1: [4]f64,
        v_2: [4]f64,
        v_3: [4]f64,
        v_4: [4]f64,
        v_5: [4]f64,
        v_6: [4]f64,
        v_7: [4]f64,
        v_8: [4]f64,
        v_9: [4]f64,
        v_10: [4]f64,
    };
    const log_gamma_test = TestValues{
        .v_0 = .{ 0.001, 6.907178885383854, 0.0, 0.0 },
        .v_1 = .{ 0.01, 4.599479878042022, 0.0, 0.0 },
        .v_2 = .{ 0.1, 2.2527126517342055, 0.0, 0.0 },
        .v_3 = .{ 0.5, 0.5723649429247004, 0.0, 0.0 },
        .v_4 = .{ 1.0, 0.0, 0.0, 0.0 },
        .v_5 = .{ 1.5, -0.12078223763524543, 0.0, 0.0 },
        .v_6 = .{ 2.0, 0.0, 0.0, 0.0 },
        .v_7 = .{ 5.0, 3.178053830347945, 0.0, 0.0 },
        .v_8 = .{ 10.0, 12.801827480081467, 0.0, 0.0 },
        .v_9 = .{ 50.0, 144.5657439463449, 0.0, 0.0 },
        .v_10 = .{ 100.0, 359.1342053695754, 0.0, 0.0 },
    };
    
    const betainc_test = TestValues{
        .v_0 = .{0.5, 0.5, 0.5, 0.5000000000000001},
        .v_1 = .{1.0, 1.0, 0.3, 0.3},
        .v_2 = .{2.0, 5.0, 0.4, 0.7667200000000001},
        .v_3 = .{5.0, 2.0, 0.8, 0.65536},
        .v_4 = .{0.1, 0.1, 0.9, 0.593614906063724},
        .v_5 = .{10.0, 10.0, 0.5, 0.5},
        .v_6 = .{50.0, 30.0, 0.6, 0.3170571539691119},
        .v_7 = .{100.0, 200.0, 0.3, 0.10884306564490986},
        .v_8 = .{1.0, 3.0, 0.99, 0.999999},
        .v_9 = .{500.0, 500.0, 0.5, 0.5},
        .v_10 = .{0.001, 1000.0, 0.5, 1.0},
    };

    const fields = @typeInfo(TestValues).@"struct".fields;

    inline for (fields) |field| {
        const gamma_pair = @field(log_gamma_test, field.name);
        const input = gamma_pair[0];
        const expected = gamma_pair[1];
        const result = specials.log_gamma(input);

        try std.testing.expectApproxEqAbs(expected, result, 0.001);

        const beta_pair = @field(betainc_test, field.name);
        const input_a = beta_pair[0];
        const input_b = beta_pair[1];
        const input_x = beta_pair[2];
        const expected_beta = beta_pair[3];

        const result_beta = try specials.betainc(input_a, input_b, input_x);
        try std.testing.expectApproxEqAbs(expected_beta, result_beta, 0.001);
    }
}

test "t-test" {
    const series_1: [100]f64 = series.series_1;
    const series_2: [100]f64 = series.series_2;

    const results = try normaltests.ttest(series_1, series_2);
    const t = results[0];
    const df = results[1];
    const p = results[2];
    std.debug.print("t {any}; df {any}; p {any}\n", .{t, df, p});
}

test "test csv reader" {
    const allocator = std.heap.page_allocator;

    var matrix = try csv.readCsv(allocator, "classification_results.csv", ',');
    defer matrix.deinit();

    for (0..matrix.cols) |c| {
        std.debug.print("  {s}: {s}\n", .{ matrix.col_names[c], matrix.col_types[c].name() });
    }

    const yhat_col = matrix.columnIndex("yhat") orelse return error.NotFound;
    const yhat = try matrix.getColumnFloat(yhat_col);
    defer allocator.free(yhat);

    std.debug.print("yhat[0] {any}\n", .{yhat[0]});
}




