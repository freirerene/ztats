const std = @import("std");

pub fn convert_to_array(list: anytype, allocator: std.mem.Allocator) ![]f32 {
    const T = @TypeOf(list.*);
    const ElemType = std.meta.Elem(T.Slice);

    const result = try allocator.alloc(f32, list.items.len);
    errdefer allocator.free(result);

    for (list.items, 0..) |item, i| {
        result[i] = switch (@typeInfo(ElemType)) {
            .Int, .ComptimeInt => @floatFromInt(item),
            .Float, .ComptimeFloat => @floatCast(item),
            else => @compileError("unsupported element type: " ++ @typeName(ElemType)),
        };
    }

    return result;
}

pub fn to_float(val: anytype) f64 {
    return switch (@typeInfo(@TypeOf(val))) {
        .int, .comptime_int => @floatFromInt(val),
        .float, .comptime_float => @floatCast(val),
        .optional => to_float(val.?),
        else => @compileError("expected numeric type"),
    };
}

