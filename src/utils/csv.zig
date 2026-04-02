const std = @import("std");

// ─── Column Types ───────────────────────────────────────────────────────────

pub const ColumnType = enum {
    integer,
    float,
    boolean,
    string,

    pub fn name(self: ColumnType) []const u8 {
        return switch (self) {
            .integer => "integer",
            .float => "float",
            .boolean => "boolean",
            .string => "string",
        };
    }
};

/// A single cell that carries both the raw text and the parsed typed value.
pub const TypedCell = struct {
    raw: []const u8,
    value: TypedValue,
};

pub const TypedValue = union(ColumnType) {
    integer: i64,
    float: f64,
    boolean: bool,
    string: []const u8,
};

// ─── CsvMatrix ──────────────────────────────────────────────────────────────

pub const CsvMatrix = struct {
    cells: []TypedCell,
    col_types: []ColumnType,
    col_names: [][]const u8,
    rows: usize,
    cols: usize,
    allocator: std.mem.Allocator,

    /// Access a cell by row and column index.
    pub fn get(self: CsvMatrix, row: usize, col: usize) ?TypedCell {
        if (row >= self.rows or col >= self.cols) return null;
        return self.cells[row * self.cols + col];
    }

    /// Convenience: get the integer value at (row, col) or null.
    pub fn getInt(self: CsvMatrix, row: usize, col: usize) ?i64 {
        const cell = self.get(row, col) orelse return null;
        return switch (cell.value) {
            .integer => |v| v,
            else => null,
        };
    }

    /// Convenience: get the float value at (row, col) or null.
    pub fn getFloat(self: CsvMatrix, row: usize, col: usize) ?f64 {
        const cell = self.get(row, col) orelse return null;
        return switch (cell.value) {
            .float => |v| v,
            .integer => |v| @as(f64, @floatFromInt(v)),
            else => null,
        };
    }

    /// Convenience: get the boolean value at (row, col) or null.
    pub fn getBool(self: CsvMatrix, row: usize, col: usize) ?bool {
        const cell = self.get(row, col) orelse return null;
        return switch (cell.value) {
            .boolean => |v| v,
            else => null,
        };
    }

    /// Convenience: get the raw string at (row, col) or null.
    pub fn getString(self: CsvMatrix, row: usize, col: usize) ?[]const u8 {
        const cell = self.get(row, col) orelse return null;
        return cell.raw;
    }

    /// Return a full column as a slice of TypedCell. Caller must free the returned slice.
    pub fn getColumn(self: CsvMatrix, col: usize) ![]TypedCell {
        if (col >= self.cols) return error.ColumnOutOfBounds;
        const result = try self.allocator.alloc(TypedCell, self.rows);
        for (0..self.rows) |r| {
            result[r] = self.cells[r * self.cols + col];
        }
        return result;
    }

    /// Return a column as a slice of ?i64. Empty or non-integer cells become null. Caller must free.
    pub fn getColumnInt(self: CsvMatrix, col: usize) ![]?i64 {
        if (col >= self.cols) return error.ColumnOutOfBounds;
        const result = try self.allocator.alloc(?i64, self.rows);
        for (0..self.rows) |r| {
            const cell = self.cells[r * self.cols + col];
            result[r] = switch (cell.value) {
                .integer => |v| v,
                else => null,
            };
        }
        return result;
    }

    /// Return a column as a slice of ?f64. Ints are promoted. Empty/string cells become null. Caller must free.
    pub fn getColumnFloat(self: CsvMatrix, col: usize) ![]?f64 {
        if (col >= self.cols) return error.ColumnOutOfBounds;
        const result = try self.allocator.alloc(?f64, self.rows);
        for (0..self.rows) |r| {
            const cell = self.cells[r * self.cols + col];
            result[r] = switch (cell.value) {
                .float => |v| v,
                .integer => |v| @as(f64, @floatFromInt(v)),
                else => null,
            };
        }
        return result;
    }

    /// Return a column as a slice of ?bool. Empty/non-bool cells become null. Caller must free.
    pub fn getColumnBool(self: CsvMatrix, col: usize) ![]?bool {
        if (col >= self.cols) return error.ColumnOutOfBounds;
        const result = try self.allocator.alloc(?bool, self.rows);
        for (0..self.rows) |r| {
            const cell = self.cells[r * self.cols + col];
            result[r] = switch (cell.value) {
                .boolean => |v| v,
                else => null,
            };
        }
        return result;
    }

    /// Return a column as a slice of raw strings. Caller must free the returned slice.
    pub fn getColumnStrings(self: CsvMatrix, col: usize) ![][]const u8 {
        if (col >= self.cols) return error.ColumnOutOfBounds;
        const result = try self.allocator.alloc([]const u8, self.rows);
        for (0..self.rows) |r| {
            result[r] = self.cells[r * self.cols + col].raw;
        }
        return result;
    }

    /// Look up a column index by name. Returns null if not found.
    pub fn columnIndex(self: CsvMatrix, name: []const u8) ?usize {
        for (self.col_names, 0..) |col_name, i| {
            if (std.mem.eql(u8, col_name, name)) return i;
        }
        return null;
    }

    /// Free all memory owned by the matrix.
    pub fn deinit(self: *CsvMatrix) void {
        for (self.cells) |cell| {
            self.allocator.free(cell.raw);
        }
        self.allocator.free(self.cells);
        for (self.col_names) |n| {
            self.allocator.free(n);
        }
        self.allocator.free(self.col_names);
        self.allocator.free(self.col_types);
    }
};

// ─── Type Inference Helpers ─────────────────────────────────────────────────

fn tryParseInt(s: []const u8) ?i64 {
    return std.fmt.parseInt(i64, s, 10) catch null;
}

fn tryParseFloat(s: []const u8) ?f64 {
    return std.fmt.parseFloat(f64, s) catch null;
}

fn tryParseBool(s: []const u8) ?bool {
    const lower = blk: {
        var buf: [16]u8 = undefined;
        if (s.len > buf.len) break :blk s;
        for (s, 0..) |c, i| {
            buf[i] = std.ascii.toLower(c);
        }
        break :blk buf[0..s.len];
    };
    if (std.mem.eql(u8, lower, "true") or std.mem.eql(u8, lower, "yes") or std.mem.eql(u8, lower, "1")) return true;
    if (std.mem.eql(u8, lower, "false") or std.mem.eql(u8, lower, "no") or std.mem.eql(u8, lower, "0")) return false;
    return null;
}

/// Infer the type of a single raw cell string.
fn inferCellType(s: []const u8) ColumnType {
    const trimmed = std.mem.trim(u8, s, " \t");
    if (trimmed.len == 0) return .string;
    if (tryParseInt(trimmed) != null) return .integer;
    if (tryParseBool(trimmed) != null) return .boolean;
    if (tryParseFloat(trimmed) != null) return .float;
    return .string;
}

/// Given two column types, determine the widest compatible type.
/// Promotion rules: bool stays bool, int + float → float, anything + string → string.
fn promoteType(a: ColumnType, b: ColumnType) ColumnType {
    if (a == b) return a;
    if (a == .string or b == .string) return .string;
    if ((a == .boolean and b != .boolean) or (b == .boolean and a != .boolean)) return .string;
    if ((a == .integer and b == .float) or (a == .float and b == .integer)) return .float;
    return .string;
}

/// Convert a raw cell into a TypedValue according to the resolved column type.
fn castCell(raw: []const u8, col_type: ColumnType) TypedValue {
    const trimmed = std.mem.trim(u8, raw, " \t");
    switch (col_type) {
        .boolean => {
            if (tryParseBool(trimmed)) |v| return .{ .boolean = v };
            return .{ .string = raw };
        },
        .integer => {
            if (tryParseInt(trimmed)) |v| return .{ .integer = v };
            return .{ .string = raw };
        },
        .float => {
            if (tryParseFloat(trimmed)) |v| return .{ .float = v };
            if (tryParseInt(trimmed)) |v| return .{ .float = @floatFromInt(v) };
            return .{ .string = raw };
        },
        .string => return .{ .string = raw },
    }
}

// ─── CSV Parsing ────────────────────────────────────────────────────────────

/// Reads a CSV file from disk and returns a typed CsvMatrix.
pub fn readCsv(
    allocator: std.mem.Allocator,
    file_path: []const u8,
    delimiter: u8,
) !CsvMatrix {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source);

    return parseCsvSource(allocator, source, delimiter);
}

/// Parses an in-memory CSV string into a typed CsvMatrix.
/// The first row is treated as a header row.
pub fn parseCsvSource(
    allocator: std.mem.Allocator,
    source: []const u8,
    delimiter: u8,
) !CsvMatrix {
    // --- Pass 1: collect raw strings into rows ---
    var raw_rows: std.ArrayListUnmanaged([][]const u8) = .{};
    defer {
        for (raw_rows.items) |row| allocator.free(row);
        raw_rows.deinit(allocator);
    }

    var max_cols: usize = 0;
    {
        var row_cells: std.ArrayListUnmanaged([]const u8) = .{};
        defer row_cells.deinit(allocator);

        var cell_start: usize = 0;
        var in_quotes = false;
        var i: usize = 0;

        while (i < source.len) : (i += 1) {
            const c = source[i];
            if (c == '"') {
                in_quotes = !in_quotes;
            } else if (!in_quotes and (c == delimiter or c == '\n' or c == '\r')) {
                try row_cells.append(allocator, try extractCell(allocator, source[cell_start..i]));

                if (c == delimiter) {
                    // continue on same row
                } else {
                    if (c == '\r' and i + 1 < source.len and source[i + 1] == '\n') i += 1;
                    const owned = try allocator.dupe([]const u8, row_cells.items);
                    if (owned.len > max_cols) max_cols = owned.len;
                    try raw_rows.append(allocator, owned);
                    row_cells.clearRetainingCapacity();
                }
                cell_start = i + 1;
            }
        }
        // Last cell if no trailing newline.
        if (cell_start < source.len) {
            const remaining = std.mem.trim(u8, source[cell_start..source.len], " \t\r\n");
            if (remaining.len > 0) {
                try row_cells.append(allocator, try extractCell(allocator, source[cell_start..source.len]));
            }
        }
        if (row_cells.items.len > 0) {
            const owned = try allocator.dupe([]const u8, row_cells.items);
            if (owned.len > max_cols) max_cols = owned.len;
            try raw_rows.append(allocator, owned);
        }
    }

    if (raw_rows.items.len == 0 or max_cols == 0) {
        return CsvMatrix{
            .cells = &[_]TypedCell{},
            .col_types = &[_]ColumnType{},
            .col_names = &[_][]const u8{},
            .rows = 0,
            .cols = 0,
            .allocator = allocator,
        };
    }

    // --- Extract header row ---
    const header_row = raw_rows.items[0];
    const col_names = try allocator.alloc([]const u8, max_cols);
    for (0..max_cols) |c| {
        if (c < header_row.len) {
            col_names[c] = try allocator.dupe(u8, header_row[c]);
        } else {
            col_names[c] = try allocator.dupe(u8, "");
        }
    }

    const data_row_count = raw_rows.items.len - 1;
    if (data_row_count == 0) {
        const empty_types = try allocator.alloc(ColumnType, max_cols);
        for (empty_types) |*t| t.* = .string;
        return CsvMatrix{
            .cells = &[_]TypedCell{},
            .col_types = empty_types,
            .col_names = col_names,
            .rows = 0,
            .cols = max_cols,
            .allocator = allocator,
        };
    }

    // --- Pass 2: infer column types from data rows ---
    const col_types = try allocator.alloc(ColumnType, max_cols);
    for (0..max_cols) |c| {
        var resolved: ?ColumnType = null;
        for (1..raw_rows.items.len) |r| {
            const row = raw_rows.items[r];
            if (c >= row.len) continue;
            const trimmed = std.mem.trim(u8, row[c], " \t");
            if (trimmed.len == 0) continue;
            const cell_type = inferCellType(row[c]);
            if (resolved) |prev| {
                resolved = promoteType(prev, cell_type);
            } else {
                resolved = cell_type;
            }
        }
        col_types[c] = resolved orelse .string;
    }

    // --- Pass 3: build typed cells ---
    const total = data_row_count * max_cols;
    const cells = try allocator.alloc(TypedCell, total);

    for (0..data_row_count) |r| {
        const row = raw_rows.items[r + 1];
        for (0..max_cols) |c| {
            const raw_str = if (c < row.len) row[c] else "";
            const owned = try allocator.dupe(u8, raw_str);
            cells[r * max_cols + c] = TypedCell{
                .raw = owned,
                .value = castCell(owned, col_types[c]),
            };
        }
    }

    // Free raw cell strings (we duped what we need).
    for (raw_rows.items) |row| {
        for (row) |cell| allocator.free(cell);
    }

    return CsvMatrix{
        .cells = cells,
        .col_types = col_types,
        .col_names = col_names,
        .rows = data_row_count,
        .cols = max_cols,
        .allocator = allocator,
    };
}

/// Extracts a single CSV cell value, handling quotes and escaped quotes.
fn extractCell(allocator: std.mem.Allocator, raw: []const u8) ![]const u8 {
    var trimmed = std.mem.trim(u8, raw, " \t");

    if (trimmed.len >= 2 and trimmed[0] == '"' and trimmed[trimmed.len - 1] == '"') {
        trimmed = trimmed[1 .. trimmed.len - 1];
    }

    var escaped_count: usize = 0;
    {
        var j: usize = 0;
        while (j < trimmed.len) : (j += 1) {
            if (trimmed[j] == '"' and j + 1 < trimmed.len and trimmed[j + 1] == '"') {
                escaped_count += 1;
                j += 1;
            }
        }
    }

    if (escaped_count == 0) {
        return try allocator.dupe(u8, trimmed);
    }

    const result = try allocator.alloc(u8, trimmed.len - escaped_count);
    var dst: usize = 0;
    var j: usize = 0;
    while (j < trimmed.len) : (j += 1) {
        if (trimmed[j] == '"' and j + 1 < trimmed.len and trimmed[j + 1] == '"') {
            result[dst] = '"';
            dst += 1;
            j += 1;
        } else {
            result[dst] = trimmed[j];
            dst += 1;
        }
    }
    return result;
}



