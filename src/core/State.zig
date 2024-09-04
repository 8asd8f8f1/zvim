const std = @import("std");
const builtin = @import("builtin");
const vaxis = @import("vaxis");

const State = @This();

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
    foo: u8,
};

const StateError = error{
    OutOfMemory,
    CannotInitializeTTY,
};

allocator: std.mem.Allocator = undefined,

vx: vaxis.Vaxis = undefined,
tty: vaxis.Tty = undefined,
event_loop: vaxis.Loop(Event) = undefined,

// -----------------------------------------------------------------------------

pub fn init(this: *State, allocator: std.mem.Allocator) void {
    if (builtin.os.tag == .linux)
        _ = std.os.linux.syscall3(.ioctl, @as(usize, @bitCast(@as(isize, std.posix.STDIN_FILENO))), std.os.linux.T.CFLSH, 0);

    this.allocator = allocator;
    this.tty = vaxis.Tty.init() catch unreachable;

    this.vx = vaxis.Vaxis.init(allocator, .{
        .system_clipboard_allocator = allocator,
    }) catch unreachable;

    this.event_loop = .{
        .tty = &this.tty,
        .vaxis = &this.vx,
    };

    this.event_loop.init() catch unreachable;
}

pub fn deinit(this: *State) void {
    defer this.tty.deinit();
    defer this.vx.deinit(this.allocator, this.tty.anyWriter());
}

pub inline fn start_loop(this: *State) !void {
    try this.event_loop.start();
}

pub inline fn stop_loop(this: *State) void {
    this.event_loop.stop();
}
