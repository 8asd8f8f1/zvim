const c = @import("./base.zig");
const Plane = @import("./plane.zig").Plane;
const Input = c.Input;

pub const Context = struct {
    nc: *c.notcurses,

    pub const Options = c.notcurses_options;
    pub const option = struct {
        pub const INHIBIT_SETLOCALE = c.NCOPTION_INHIBIT_SETLOCALE;
        pub const NO_CLEAR_BITMAPS = c.NCOPTION_NO_CLEAR_BITMAPS;
        pub const NO_WINCH_SIGHANDLER = c.NCOPTION_NO_WINCH_SIGHANDLER;
        pub const NO_QUIT_SIGHANDLERS = c.NCOPTION_NO_QUIT_SIGHANDLERS;
        pub const PRESERVE_CURSOR = c.NCOPTION_PRESERVE_CURSOR;
        pub const SUPPRESS_BANNERS = c.NCOPTION_SUPPRESS_BANNERS;
        pub const NO_ALTERNATE_SCREEN = c.NCOPTION_NO_ALTERNATE_SCREEN;
        pub const NO_FONT_CHANGES = c.NCOPTION_NO_FONT_CHANGES;
        pub const DRAIN_INPUT = c.NCOPTION_DRAIN_INPUT;
        pub const SCROLLING = c.NCOPTION_SCROLLING;
        pub const CLI_MODE = c.NCOPTION_CLI_MODE;
    };

    const Self = @This();

    pub fn core_init(opts: *const Options, fp: ?*c.FILE) !Self {
        return .{ .nc = c.notcurses_core_init(opts, fp) orelse return error.NCInitFailed };
    }

    pub fn stop(self: Self) void {
        _ = c.notcurses_stop(self.nc);
    }

    pub fn mice_enable(self: Self, eventmask: c_uint) !void {
        const result = c.notcurses_mice_enable(self.nc, eventmask);
        if (result != 0)
            return error.NCMiceEnableFailed;
    }

    /// Disable mouse events. Any events in the input queue can still be delivered.
    pub fn mice_disable(self: Self) !void {
        const result = c.notcurses_mice_disable(self.nc);
        if (result != 0)
            return error.NCMiceDisableFailed;
    }

    /// Disable signals originating from the terminal's line discipline, i.e.
    /// SIGINT (^C), SIGQUIT (^\), and SIGTSTP (^Z). They are enabled by default.
    pub fn linesigs_disable(self: Self) !void {
        const result = c.notcurses_linesigs_disable(self.nc);
        if (result != 0)
            return error.NCLinesigsDisableFailed;
    }

    /// Restore signals originating from the terminal's line discipline, i.e.
    /// SIGINT (^C), SIGQUIT (^\), and SIGTSTP (^Z), if disabled.
    pub fn linesigs_enable(self: Self) !void {
        const result = c.notcurses_linesigs_enable(self.nc);
        if (result != 0)
            return error.NCLinesigsEnableFailed;
    }

    /// Refresh the physical screen to match what was last rendered (i.e., without
    /// reflecting any changes since the last call to notcurses_render()). This is
    /// primarily useful if the screen is externally corrupted, or if an
    /// NCKEY_RESIZE event has been read and you're not yet ready to render. The
    /// current screen geometry is returned in 'y' and 'x', if they are not NULL.
    pub fn refresh(self: Self) !void {
        const result = c.notcurses_refresh(self.nc, null, null);
        if (result != 0)
            return error.NCRefreshFailed;
    }

    /// Get a reference to the standard plane (one matching our current idea of the
    /// terminal size) for this terminal. The standard plane always exists, and its
    /// origin is always at the uppermost, leftmost cell of the terminal.
    pub fn stdplane(self: Self) Plane {
        return .{ .n = c.notcurses_stdplane(self.nc) orelse unreachable };
    }

    /// notcurses_stdplane(), plus free bonus dimensions written to non-NULL y/x!
    pub fn stddim_yx(self: Self, y: ?*c_uint, x: ?*c_uint) Plane {
        return .{ .n = c.notcurses_stddim_yx(self.nc, y, x) orelse unreachable };
    }

    /// Return the topmost plane of the standard pile.
    pub fn top(self: Self) Plane {
        return .{ .n = c.notcurses_top(self.nc).? };
    }

    /// Return the bottommost plane of the standard pile.
    pub fn bottom(self: Self) Plane {
        return .{ .n = c.notcurses_bottom(self.nc) };
    }

    /// Renders and rasterizes the standard pile in one shot. Blocking call.
    pub fn render(self: Self) !void {
        const err = c.notcurses_render(self.nc);
        return if (err != 0)
            error.NCRenderFailed
        else {};
    }

    /// Read a UTF-32-encoded Unicode codepoint from input. This might only be part
    /// of a larger EGC. Provide a NULL 'ts' to block at length, and otherwise a
    /// timespec specifying an absolute deadline calculated using CLOCK_MONOTONIC.
    /// Returns a single Unicode code point, or a synthesized special key constant,
    /// or (uint32_t)-1 on error. Returns 0 on a timeout. If an event is processed,
    /// the return value is the 'id' field from that event. 'ni' may be NULL.
    pub fn get(self: Self, ts: ?*const c.struct_timespec, ni: ?*Input) !u32 {
        const ret = c.notcurses_get(self.nc, ts, ni);
        return if (ret < 0)
            error.NCGetFailed
        else
            ret;
    }

    /// Acquire up to 'vcount' ncinputs at the vector 'ni'. The number read will be
    /// returned, or -1 on error without any reads, 0 on timeout.
    pub fn getvec(self: Self, ts: ?*const c.struct_timespec, ni: []Input) ![]Input {
        const ret = c.notcurses_getvec(self.nc, ts, ni.ptr, @intCast(ni.len));
        return if (ret < 0)
            error.NCGetFailed
        else
            ni[0..@intCast(ret)];
    }

    pub fn getvec_nblock(self: Self, ni: []Input) ![]Input {
        const ret = c.notcurses_getvec_nblock(self.nc, ni.ptr, @intCast(ni.len));
        return if (ret < 0)
            error.NCGetFailed
        else
            ni[0..@intCast(ret)];
    }

    /// Get a file descriptor suitable for input event poll()ing. When this
    /// descriptor becomes available, you can call notcurses_get_nblock(),
    /// and input ought be ready. This file descriptor is *not* necessarily
    /// the file descriptor associated with stdin (but it might be!).
    pub fn inputready_fd(self: Self) c_int {
        return c.notcurses_inputready_fd(self.nc);
    }

    /// Enable or disable the terminal's cursor, if supported, placing it at
    /// 'y', 'x'. Immediate effect (no need for a call to notcurses_render()).
    /// It is an error if 'y', 'x' lies outside the standard plane. Can be
    /// called while already visible to move the cursor.
    pub fn cursor_enable(self: Self, y: c_int, x: c_int) !void {
        const err = c.notcurses_cursor_enable(self.nc, y, x);
        return if (err != 0) error.NCCursorEnableFailed else {};
    }

    /// Disable the hardware cursor. It is an error to call this while the
    /// cursor is already disabled.
    pub fn cursor_disable(self: Self) !void {
        const err = c.notcurses_cursor_disable(self.nc);
        return if (err != 0) error.NCCursorDisableFailed else {};
    }

    /// Get the current location of the terminal's cursor, whether visible or not.
    pub fn cursor_yx(self: Self) !struct { y: isize, x: isize } {
        var y: c_int = undefined;
        var x: c_int = undefined;
        const err = c.notcurses_cursor_yx(self.nc, &y, &x);
        return if (err != 0) error.NCCursorYXFailed else .{ .y = y, .x = x };
    }

    /// Shift to the alternate screen, if available. If already using the alternate
    /// screen, this returns 0 immediately. If the alternate screen is not
    /// available, this returns -1 immediately. Entering the alternate screen turns
    /// off scrolling for the standard plane.
    pub fn enter_alternate_screen(self: Self) void {
        _ = c.notcurses_enter_alternate_screen(self.nc);
    }

    /// Exit the alternate screen. Immediately returns 0 if not currently using the
    /// alternate screen.
    pub fn leave_alternate_screen(self: Self) void {
        _ = c.notcurses_leave_alternate_screen(self.nc);
    }
};
