const std = @import("std");
const nc = @import("notcurses");

fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak)
            std.log.err("memory leaked", .{});
    }
    const alloc = gpa.allocator();

    
}
