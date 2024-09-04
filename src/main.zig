const std = @import("std");
const vaxis = @import("vaxis");

const State = @import("core/State.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak)
            std.log.err("memory leaked", .{});
    }
    const alloc = gpa.allocator();

    var global = State{};
    global.init(alloc);
    defer global.deinit();

    try global.start_loop();
    defer global.stop_loop();

    try global.vx.enterAltScreen(global.tty.anyWriter());

    var text_input = vaxis.widgets.TextInput.init(alloc, &global.vx.unicode);
    defer text_input.deinit();

    try global.vx.queryTerminal(global.tty.anyWriter(), 1 * std.time.ns_per_s);

    while (true) {
        const e = global.event_loop.nextEvent();

        switch (e) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    global.vx.queueRefresh();
                } else {
                    try text_input.update(.{ .key_press = key });
                }
            },

            .winsize => |ws| try global.vx.resize(alloc, global.tty.anyWriter(), ws),

            else => {},
        }

        const win = global.vx.window();
        win.clear();

        const style = vaxis.Style{ .fg = .{ .index = 0 } };

        const child = win.child(.{
            .x_off = win.width / 2 - 20,
            .y_off = win.height / 2 - 3,
            .width = .{ .limit = 40 },
            .height = .{ .limit = 3 },
            .border = .{
                .where = .all,
                .style = style,
            },
        });

        text_input.draw(child);
        try global.vx.render(global.tty.anyWriter());
    }
}
