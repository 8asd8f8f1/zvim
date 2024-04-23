const std = @import("std");

pub fn main() !void {
    // init params and real argc and argv
    // avoid: platforn specific code
    // language and gui specific code
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
