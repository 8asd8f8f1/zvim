const std = @import("std");
const ArrayList = std.ArrayList;

pub inline fn isUint(comptime T: type) void {
    switch (@typeInfo(T)) {
        .Int => |I| {
            if (I.signedness == .signed)
                @compileError("Point struct cannot accept a signed integer as a generic type parameter.");
            switch (I.bits) {
                8, 16, 32, 64 => {},
                else => @compileError("Point struct can only accept a unsigned integer of 8, 16, 32 and 64 bitwidth."),
            }
        },
        else => @compileError("Point struct cannot accept a generic type parameter of non interger type."),
    }
}

pub fn Point(comptime T: type) type {
    isUint(T);

    return packed struct {
        x: T = 0,
        y: T = 0,

        const Self = @This();

        pub inline fn dx(self: *Self, other: *Self) T {
            return @as(T, @bitCast(@abs(self.x - other.x)));
        }

        pub inline fn dy(self: *Self, other: *Self) T {
            return @as(T, @bitCast(@abs(self.y - other.y)));
        }

        pub inline fn dxy(self: *Self, other: *Self) Self {
            return .{
                .x = self.dx(other),
                .y = self.dy(other),
            };
        }
    };
}

// pub const Window = packed struct {
//     const Self = @This();
//
//     alloc: ?std.mem.Allocator = null,
//
//     id: u16 = 0,
//
//     position: Point(u16),
//     cursor: Point(u16),
//     scroll: Point(u16),
//
//     // For implementing multicursor functionality
//     cursors: ?ArrayList(Point(u16)),
//     width: u16,
//     height: u16,
//     parent: ?*Self,
//
//     is_active: u1 = 0,
//     is_split: u1 = 0,
//
//     pub inline fn set_parent(self: *Self, parent: *Self) void {
//         self.parent = parent;
//     }
// };

pub fn Window(comptime T: type) type {
    isUint(T);

    return packed struct {
        const Self = @This();

        allocator: ?std.mem.Allocator = null,

        id: u16,

        position: Point(T),
        cursor: Point(T),
        scroll: Point(T),

        // For implementing multicursor functionality
        cursors: ?ArrayList(Point(T)),
        width: T,
        height: T,
        parent: ?*Self,

        is_active: u1 = 0,
        is_split: u1 = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .id = 0,
                .position = Point(T),
                .cursor = Point(T),
                .scroll = Point(T),
                .cursors = ArrayList(Point(T)).init(allocator),
                .parent = null,
                .is_active = 0,
                .is_split = 0,
            };
        }

        pub inline fn set_parent(self: *Self, parent: *Self) void {
            self.parent = parent;
        }
    };
}

/// Global UI state object
/// tracks:
///     windows
///
pub const UiState = struct {
    windows: ArrayList(Window),
};
