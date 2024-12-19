const std = @import("std");
const c = @import("./base.zig");
const Context = @import("./context.zig").Context;
const Cell = @import("./cell.zig").Cell;

pub const Plane = struct {
    n: *c_plane,

    pub const c_plane = c.struct_ncplane;

    pub const Options = c.struct_ncplane_options;
    pub const option = struct {
        pub const HORALIGNED = c.NCPLANE_OPTION_HORALIGNED;
        pub const VERALIGNED = c.NCPLANE_OPTION_VERALIGNED;
        pub const MARGINALIZED = c.NCPLANE_OPTION_MARGINALIZED;
        pub const FIXED = c.NCPLANE_OPTION_FIXED;
        pub const AUTOGROW = c.NCPLANE_OPTION_AUTOGROW;
        pub const VSCROLL = c.NCPLANE_OPTION_VSCROLL;
    };

    const Self = @This();

    /// Create a new ncplane bound to parent plane 'n', at the offset 'y'x'x' (relative to
    /// the origin of 'n') and the specified size. The number of 'rows' and 'cols'
    /// must both be positive. This plane is initially at the top of the z-buffer,
    /// as if ncplane_move_top() had been called on it. The void* 'userptr' can be
    /// retrieved (and reset) later. A 'name' can be set, used in debugging.
    pub fn init(nopts: *const Options, parent_: Self) !Self {
        const child = c.ncplane_create(parent_.n, nopts);
        return if (child) |p| .{ .n = p } else error.OutOfMemory;
    }

    /// Destroy the specified ncplane. None of its contents will be visible after
    /// the next call to notcurses_render(). It is an error to attempt to destroy
    /// the standard plane.
    pub fn deinit(self: Self) void {
        _ = c.ncplane_destroy(self.n);
    }

    /// Extract the Notcurses context to which this plane is attached.
    pub fn context(self: Self) Context {
        return .{ .nc = c.ncplane_notcurses(self.n) orelse unreachable };
    }

    /// Resize the specified ncplane. The four parameters 'keepy', 'keepx',
    /// 'keepleny', and 'keeplenx' define a subset of the ncplane to keep,
    /// unchanged. This may be a region of size 0, though none of these four
    /// parameters may be negative. 'keepx' and 'keepy' are relative to the ncplane.
    /// They must specify a coordinate within the ncplane's totality. 'yoff' and
    /// 'xoff' are relative to 'keepy' and 'keepx', and place the upper-left corner
    /// of the resized ncplane. Finally, 'ylen' and 'xlen' are the dimensions of the
    /// ncplane after resizing. 'ylen' must be greater than or equal to 'keepleny',
    /// and 'xlen' must be greater than or equal to 'keeplenx'. It is an error to
    /// attempt to resize the standard plane. If either of 'keepleny' or 'keeplenx'
    /// is non-zero, both must be non-zero.
    ///
    /// Essentially, the kept material does not move. It serves to anchor the
    /// resized plane. If there is no kept material, the plane can move freely.
    pub fn resize_keep(self: Self, keepy: c_int, keepx: c_int, keepleny: c_uint, keeplenx: c_uint, yoff: c_int, xoff: c_int, ylen: c_uint, xlen: c_uint) !void {
        const err = c.ncplane_resize(self.n, keepy, keepx, keepleny, keeplenx, yoff, xoff, ylen, xlen);
        if (err != 0)
            return error.NCPResizeFailed;
    }

    /// Resize the plane, retaining what data we can (everything, unless we're
    /// shrinking in some dimension). Keep the origin where it is.
    pub fn resize_simple(self: Self, ylen: c_uint, xlen: c_uint) !void {
        const err = c.ncplane_resize_simple(self.n, ylen, xlen);
        if (err != 0)
            return error.NCPResizeFailed;
    }

    /// Return the dimensions of this ncplane. y or x may be NULL.
    pub fn dim_yx(self: Self, noalias y_: ?*c_uint, noalias x_: ?*c_uint) void {
        c.ncplane_dim_yx(self.n, y_, x_);
    }

    /// Return the dimensions of this ncplane. y or x may be NULL.
    pub fn dim_y(self: Self) c_uint {
        return c.ncplane_dim_y(self.n);
    }

    /// Return the dimensions of this ncplane. y or x may be NULL.
    pub fn dim_x(self: Self) c_uint {
        return c.ncplane_dim_x(self.n);
    }

    /// Get the origin of plane 'n' relative to its pile. Either or both of 'x' and
    /// 'y' may be NULL.
    pub fn abs_yx(self: Self, noalias y_: ?*c_int, noalias x_: ?*c_int) void {
        c.ncplane_abs_yx(self.n, y_, x_);
    }

    /// Get the origin of plane 'n' relative to its pile. Either or both of 'x' and
    /// 'y' may be NULL.
    pub fn abs_y(self: Self) c_int {
        return c.ncplane_abs_y(self.n);
    }

    /// Get the origin of plane 'n' relative to its pile. Either or both of 'x' and
    /// 'y' may be NULL.
    pub fn abs_x(self: Self) c_int {
        return c.ncplane_abs_x(self.n);
    }

    /// Get the origin of plane 'n' relative to its bound plane, or pile (if 'n' is
    /// a root plane). To get absolute coordinates, use ncplane_abs_yx().
    pub fn yx(self: Self, noalias y_: ?*c_int, noalias x_: ?*c_int) void {
        c.ncplane_yx(self.n, y_, x_);
    }

    /// Get the origin of plane 'n' relative to its bound plane, or pile (if 'n' is
    /// a root plane). To get absolute coordinates, use ncplane_abs_yx().
    pub fn y(self: Self) c_int {
        return c.ncplane_y(self.n);
    }

    /// Get the origin of plane 'n' relative to its bound plane, or pile (if 'n' is
    /// a root plane). To get absolute coordinates, use ncplane_abs_yx().
    pub fn x(self: Self) c_int {
        return c.ncplane_x(self.n);
    }

    /// Return the topmost plane of the pile containing 'n'.
    pub fn top(self: Self) Plane {
        return .{ .n = c.ncpile_top(self.n) };
    }

    /// Return the bottommost plane of the pile containing 'n'.
    pub fn bottom(self: Self) Plane {
        return .{ .n = c.ncpile_bottom(self.n) };
    }

    /// Convert absolute to relative coordinates based on this plane
    pub fn abs_yx_to_rel(self: Self, y_: ?*c_int, x_: ?*c_int) void {
        var origin_y: c_int = undefined;
        var origin_x: c_int = undefined;
        self.abs_yx(&origin_y, &origin_x);
        if (y_) |y__| y__.* = y__.* - origin_y;
        if (x_) |x__| x__.* = x__.* - origin_x;
    }

    /// Convert relative to absolute coordinates based on this plane
    pub fn rel_yx_to_abs(self: Self, y_: ?*c_int, x_: ?*c_int) void {
        var origin_y: c_int = undefined;
        var origin_x: c_int = undefined;
        self.abs_yx(&origin_y, &origin_x);
        if (y_) |y__| y__.* = y__.* + origin_y;
        if (x_) |x__| x__.* = x__.* + origin_x;
    }

    /// Get the plane to which the plane 'n' is bound, if any.
    pub inline fn parent(self: Self) Plane {
        return .{ .n = c.ncplane_parent(self.n) orelse unreachable };
    }

    /// Return non-zero iff 'n' is a proper descendent of 'ancestor'.
    pub inline fn descendant_p(self: Self, ancestor: Self) bool {
        return c.ncplane_descendant_p(self.n, ancestor.n) != 0;
    }

    /// Splice ncplane 'n' out of the z-buffer, and reinsert it above 'above'.
    /// Returns non-zero if 'n' is already in the desired location. 'n' and
    /// 'above' must not be the same plane. If 'above' is NULL, 'n' is moved
    /// to the bottom of its pile.
    pub fn move_above(self: Self, above_: Self) bool {
        return c.ncplane_move_above(self.n, above_.n) != 0;
    }

    /// Splice ncplane 'n' out of the z-buffer, and reinsert it below 'below'.
    /// Returns non-zero if 'n' is already in the desired location. 'n' and
    /// 'below' must not be the same plane. If 'below' is NULL, 'n' is moved to
    /// the top of its pile.
    pub fn move_below(self: Self, above_: Self) bool {
        return c.ncplane_move_below(self.n, above_.n) != 0;
    }

    /// Splice ncplane 'n' out of the z-buffer; reinsert it at the top.
    pub inline fn move_top(self: Self) void {
        _ = c.ncplane_move_below(self.n, null);
    }

    /// Splice ncplane 'n' out of the z-buffer; reinsert it at the bottom.
    pub inline fn move_bottom(self: Self) void {
        _ = c.ncplane_move_above(self.n, null);
    }

    /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
    /// them above 'targ'. Relative order will be maintained between the
    /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
    /// moving the C family to the top results in C E A B D, while moving it to
    /// the bottom results in A B D C E.
    pub inline fn move_family_above(self: Self, targ: Self) void {
        _ = c.ncplane_move_family_above(self.n, targ.n);
    }

    /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
    /// them below 'targ'. Relative order will be maintained between the
    /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
    /// moving the C family to the top results in C E A B D, while moving it to
    /// the bottom results in A B D C E.
    pub inline fn move_family_below(self: Self, targ: Self) void {
        _ = c.ncplane_move_family_below(self.n, targ.n);
    }

    /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
    /// them at the top. Relative order will be maintained between the
    /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
    /// moving the C family to the top results in C E A B D, while moving it to
    /// the bottom results in A B D C E.
    pub inline fn move_family_top(self: Self) void {
        _ = c.ncplane_move_family_below(self.n, null);
    }

    /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
    /// them at the bottom. Relative order will be maintained between the
    /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
    /// moving the C family to the top results in C E A B D, while moving it to
    /// the bottom results in A B D C E.
    pub inline fn move_family_bottom(self: Self) void {
        _ = c.ncplane_move_family_above(self.n, null);
    }

    /// Return the plane below this one, or NULL if this is at the bottom.
    pub inline fn below(self: Self) ?Self {
        return .{ .n = c.ncplane_below(self.n) orelse return null };
    }

    /// Return the plane above this one, or NULL if this is at the top.
    pub inline fn above(self: Self) ?Self {
        return .{ .n = c.ncplane_above(self.n) orelse return null };
    }

    /// Effect |r| scroll events on the plane |n|. Returns an error if |n| is not
    /// a scrolling plane, and otherwise returns the number of lines scrolled.
    pub inline fn scrollup(self: Self, r: c_int) c_int {
        return c.ncplane_scrollup(self.n, r);
    }

    /// Scroll |n| up until |child| is no longer hidden beneath it. Returns an
    /// error if |child| is not a child of |n|, or |n| is not scrolling, or |child|
    /// is fixed. Returns the number of scrolling events otherwise (might be 0).
    /// If the child plane is not fixed, it will likely scroll as well.
    pub inline fn scrollup_child(self: Self, child: Plane) c_int {
        return c.ncplane_scrollup_child(self.n, child.n);
    }

    /// Retrieve the current contents of the cell under the cursor into 'c'. This
    /// cell is invalidated if the associated plane is destroyed. Returns the number
    /// of bytes in the EGC, or -1 on error.
    pub inline fn at_cursor_cell(self: Self, cell: *Cell) !usize {
        const bytes_in_cell = c.ncplane_at_cursor_cell(self.n, cell);

        return if (bytes_in_cell < 0)
            error.NCAtCellFailed
        else
            @intCast(bytes_in_cell);
    }

    /// Retrieve the current contents of the specified cell into 'c'. This cell is
    /// invalidated if the associated plane is destroyed. Returns the number of
    /// bytes in the EGC, or -1 on error. Unlike ncplane_at_yx(), when called upon
    /// the secondary columns of a wide glyph, the return can be distinguished from
    /// the primary column (nccell_wide_right_p(c) will return true). It is an
    /// error to call this on a sprixel plane (unlike ncplane_at_yx()).
    pub fn at_yx_cell(self: Self, y_: c_int, x_: c_int, cell: *Cell) !usize {
        const bytes_in_cell = c.ncplane_at_yx_cell(self.n, y_, x_, cell);
        return if (bytes_in_cell < 0)
            error.NCAtCellFailed
        else
            @intCast(bytes_in_cell);
    }

    /// Return a heap-allocated copy of the plane's name, or NULL if it has none.
    pub fn name(self: Self, buf: []u8) []u8 {
        const s = c.ncplane_name(self.n);
        defer c.free(s);
        const s_len = std.mem.len(s);
        const s_ = s[0..s_len :0];
        @memcpy(buf[0..s_len], s_);
        return buf[0..s_len];
    }

    /// Erase every cell in the ncplane (each cell is initialized to the null glyph
    /// and the default channels/styles). All cells associated with this ncplane are
    /// invalidated, and must not be used after the call, *excluding* the base cell.
    /// The cursor is homed. The plane's active attributes are unaffected.
    pub inline fn erase(self: Self) void {
        c.ncplane_erase(self.n);
    }

    /// Erase every cell in the region starting at {ystart, xstart} and having size
    /// {|ylen|x|xlen|} for non-zero lengths. If ystart and/or xstart are -1, the current
    /// cursor position along that axis is used; other negative values are an error. A
    /// negative ylen means to move up from the origin, and a negative xlen means to move
    /// left from the origin. A positive ylen moves down, and a positive xlen moves right.
    /// A value of 0 for the length erases everything along that dimension. It is an error
    /// if the starting coordinate is not in the plane, but the ending coordinate may be
    /// outside the plane.
    ///
    /// For example, on a plane of 20 rows and 10 columns, with the cursor at row 10 and
    /// column 5, the following would hold:
    ///
    ///  (-1, -1, 0, 1): clears the column to the right of the cursor (column 6)
    ///  (-1, -1, 0, -1): clears the column to the left of the cursor (column 4)
    ///  (-1, -1, INT_MAX, 0): clears all rows with or below the cursor (rows 10--19)
    ///  (-1, -1, -INT_MAX, 0): clears all rows with or above the cursor (rows 0--10)
    ///  (-1, 4, 3, 3): clears from row 5, column 4 through row 7, column 6
    ///  (-1, 4, -3, -3): clears from row 5, column 4 through row 3, column 2
    ///  (4, -1, 0, 3): clears columns 5, 6, and 7
    ///  (-1, -1, 0, 0): clears the plane *if the cursor is in a legal position*
    ///  (0, 0, 0, 0): clears the plane in all cases
    pub fn erase_region(self: Self, ystart: isize, xstart: isize, ylen: isize, xlen: isize) !void {
        const ret = c.ncplane_erase_region(self.n, ystart, xstart, ylen, xlen);
        if (ret != 0)
            return error.NCPEraseFailed;
    }

    /// Set the ncplane's base nccell to 'c'. The base cell is used for purposes of
    /// rendering anywhere that the ncplane's gcluster is 0. Note that the base cell
    /// is not affected by ncplane_erase(). 'c' must not be a secondary cell from a
    /// multicolumn EGC.
    pub fn set_base(self: Self, egc: [*:0]const u8, stylemask: u16, channels_: u64) !isize {
        const bytes_copied = c.ncplane_set_base(self.n, egc, stylemask, channels_);
        return if (bytes_copied < 0)
            error.NCSetBaseFailed
        else
            @intCast(bytes_copied);
    }

    /// Extract the ncplane's base nccell into 'c'. The reference is invalidated if
    /// 'ncp' is destroyed.
    pub inline fn base(self: Self, cell: *Cell) void {
        _ = c.ncplane_base(self.n, cell);
    }

    /// Set the ncplane's foreground palette index, set the foreground palette index
    /// bit, set it foreground-opaque, and clear the foreground default color bit.
    pub fn set_fg_palindex(self: Self, idx: c_uint) !void {
        const err = c.ncplane_set_fg_palindex(self.n, idx);
        if (err != 0) return error.NCSetPalIndexFailed;
    }

    /// Set the ncplane's background palette index, set the background palette index
    /// bit, set it background-opaque, and clear the background default color bit.
    pub fn set_bg_palindex(self: Self, idx: c_uint) !void {
        const err = c.ncplane_set_bg_palindex(self.n, idx);
        if (err != 0)
            return error.NCSetPalIndexFailed;
    }

    /// Set the current foreground color using RGB specifications. If the
    /// terminal does not support directly-specified 3x8b cells (24-bit "TrueColor",
    /// indicated by the "RGB" terminfo capability), the provided values will be
    /// interpreted in some lossy fashion. None of r, g, or b may exceed 255.
    /// "HP-like" terminals require setting foreground and background at the same
    /// time using "color pairs"; Notcurses will manage color pairs transparently.
    pub fn set_fg_rgb(self: Self, channel: u32) !void {
        const err = c.ncplane_set_fg_rgb(self.n, channel);
        if (err != 0)
            return error.NCSetRgbFailed;
    }

    /// Set the current background color using RGB specifications. If the
    /// terminal does not support directly-specified 3x8b cells (24-bit "TrueColor",
    /// indicated by the "RGB" terminfo capability), the provided values will be
    /// interpreted in some lossy fashion. None of r, g, or b may exceed 255.
    /// "HP-like" terminals require setting foreground and background at the same
    /// time using "color pairs"; Notcurses will manage color pairs transparently.
    pub fn set_bg_rgb(self: Self, channel: u32) !void {
        const err = c.ncplane_set_bg_rgb(self.n, channel);
        if (err != 0)
            return error.NCSetRgbFailed;
    }

    /// Set the alpha parameters for ncplane 'n'.
    pub fn set_bg_alpha(self: Self, alpha: c_int) !void {
        const err = c.ncplane_set_bg_alpha(self.n, alpha);
        if (err != 0)
            return error.NCSetAlphaFailed;
    }

    /// Set the alpha and coloring bits of the plane's current channels from a
    /// 64-bit pair of channels.
    pub inline fn set_channels(self: Self, channels_: u64) void {
        c.ncplane_set_channels(self.n, channels_);
    }

    /// Move this plane relative to the standard plane, or the plane to which it is
    /// bound (if it is bound to a plane). It is an error to attempt to move the
    /// standard plane.
    pub fn move_yx(self: Self, y_: c_int, x_: c_int) !void {
        const err = c.ncplane_move_yx(self.n, y_, x_);
        if (err != 0)
            return error.NCPlaneMoveFailed;
    }

    /// Replace the cell at the specified coordinates with the provided cell 'c',
    /// and advance the cursor by the width of the cell (but not past the end of the
    /// plane). On success, returns the number of columns the cursor was advanced.
    /// 'c' must already be associated with 'n'. On failure, -1 is returned.
    pub fn putc_yx(self: Self, y_: c_int, x_: c_int, cell: *const Cell) !usize {
        const ret = c.ncplane_putc_yx(self.n, y_, x_, cell);
        return if (ret < 0)
            error.NCPlanePutYZFailed
        else
            @intCast(ret);
    }

    /// Call ncplane_putc_yx() for the current cursor location.
    pub inline fn putc(self: Self, cell: *const Cell) !usize {
        return self.putc_yx(-1, -1, cell);
    }

    /// Write a series of EGCs to the current location, using the current style.
    /// They will be interpreted as a series of columns (according to the definition
    /// of ncplane_putc()). Advances the cursor by some positive number of columns
    /// (though not beyond the end of the plane); this number is returned on success.
    pub fn putstr(self: Self, gclustarr: [*:0]const u8) !usize {
        const ret = c.c__ncplane_putstr(self.n, gclustarr);
        return if (ret < 0)
            error.NCPlanePutStrFailed
        else
            @intCast(ret);
    }

    /// Write an aligned series of EGCs to the current location, using the current style.
    pub fn putstr_aligned(self: Self, y_: c_int, align_: c.Align, s: [*:0]const u8) !usize {
        const ret = c.c__ncplane_putstr_aligned(self.n, y_, @intFromEnum(align_), s);
        return if (ret < 0)
            error.NCPlanePutStrFailed
        else
            @intCast(ret);
    }

    /// Write a zig formatted series of EGCs to the current location, using the current style.
    /// They will be interpreted as a series of columns (according to the definition
    /// of ncplane_putc()). Advances the cursor by some positive number of columns
    /// (though not beyond the end of the plane); this number is returned on success.
    pub fn print(self: Self, comptime fmt: anytype, args: anytype) !usize {
        var buf: [fmt.len + 4096]u8 = undefined;
        const output = try std.fmt.bufPrint(&buf, fmt, args);
        buf[output.len] = 0;
        if (output.len == 0)
            return 0;
        return self.putstr(@ptrCast(output[0 .. output.len - 1]));
    }

    /// Write an aligned zig formatted series of EGCs to the current location, using the current style.
    pub fn print_aligned(self: Self, y_: c_int, align_: c.Align, comptime fmt: anytype, args: anytype) !usize {
        var buf: [fmt.len + 4096]u8 = undefined;
        const output = try std.fmt.bufPrint(&buf, fmt, args);
        buf[output.len] = 0;
        return self.putstr_aligned(y_, align_, @ptrCast(output[0 .. output.len - 1]));
    }

    /// Get the opaque user pointer associated with this plane.
    pub inline fn userptr(self: Self) ?*anyopaque {
        return c.ncplane_userptr(self.n);
    }

    /// Set the opaque user pointer associated with this plane.
    /// Returns the previous userptr after replacing it.
    pub fn set_userptr(self: Self, p: ?*anyopaque) ?*anyopaque {
        return c.ncplane_set_userptr(self.n, p);
    }

    /// Utility resize callbacks. When a parent plane is resized, it invokes each
    /// child's resize callback. Any logic can be run in a resize callback, but
    /// these are some generically useful ones.
    pub const resize = struct {
        /// resize the plane to the visual region's size (used for the standard plane).
        pub const maximize = c.ncplane_resize_maximize;

        /// resize the plane to its parent's size, attempting to enforce the margins
        /// supplied along with NCPLANE_OPTION_MARGINALIZED.
        pub const marginalized = c.ncplane_resize_marginalized;

        /// realign the plane 'n' against its parent, using the alignments specified
        /// with NCPLANE_OPTION_HORALIGNED and/or NCPLANE_OPTION_VERALIGNED.
        pub const realign = c.ncplane_resize_realign;

        /// move the plane such that it is entirely within its parent, if possible.
        /// no resizing is performed.
        pub const placewithin = c.ncplane_resize_placewithin;

        pub fn maximize_vertical(n_: ?*c_plane) callconv(.C) c_int {
            if (n_) |p| {
                const self: Plane = .{ .n = p };
                const rows = self.parent().dim_y();
                const cols = self.dim_x();
                self.resize_simple(rows, cols) catch return -1;
            }
            return 0;
        }
    };

    /// realign the plane 'n' against its parent, using the alignments specified
    /// with NCPLANE_OPTION_HORALIGNED and/or NCPLANE_OPTION_VERALIGNED.
    pub inline fn realign(self: Self) void {
        _ = c.ncplane_resize_realign(self.n);
    }

    /// Replace the ncplane's existing resizecb with 'resizecb' (which may be NULL).
    /// The standard plane's resizecb may not be changed.
    pub inline fn set_resizecb(self: Self, resizecb: ?*const fn (?*c_plane) callconv(.C) c_int) void {
        return c.ncplane_set_resizecb(self.n, resizecb);
    }

    /// Move the cursor to the specified position (the cursor needn't be visible).
    /// Pass -1 as either coordinate to hold that axis constant. Returns an erro if the
    /// move would place the cursor outside the plane.
    pub fn cursor_move_yx(self: Self, y_: c_int, x_: c_int) !void {
        const err = c.ncplane_cursor_move_yx(self.n, y_, x_);
        if (err != 0)
            return error.NCPlaneCursorMoveFailed;
    }

    /// Move the cursor relative to the current cursor position (the cursor needn't
    /// be visible). Returns -1 on error, including target position exceeding the
    /// plane's dimensions.
    pub fn cursor_move_rel(self: Self, y_: c_int, x_: c_int) !void {
        const err = c.ncplane_cursor_move_rel(self.n, y_, x_);
        if (err != 0)
            return error.NCPlaneCursorMoveFailed;
    }

    /// Move the cursor to 0, 0.
    pub inline fn home(self: Self) void {
        c.ncplane_home(self.n);
    }

    /// Get the current position of the cursor within n. y and/or x may be NULL.
    pub inline fn cursor_yx(self: Self, noalias y_: *c_uint, noalias x_: *c_uint) void {
        c.ncplane_cursor_yx(self.n, y_, x_);
    }

    /// Get the current y position of the cursor within n.
    pub inline fn cursor_y(self: Self) c_uint {
        return c.ncplane_cursor_y(self.n);
    }

    /// Get the current x position of the cursor within n.
    pub inline fn cursor_x(self: Self) c_uint {
        return c.ncplane_cursor_x(self.n);
    }

    /// Get the current colors and alpha values for ncplane 'n'.
    pub inline fn channels(self: Self) u64 {
        return c.ncplane_channels(self.n);
    }

    /// Get the current styling for the ncplane 'n'.
    pub inline fn styles(self: Self) u16 {
        return c.ncplane_styles(self.n);
    }

    /// Set the specified style bits for the ncplane 'n', whether they're actively
    /// supported or not.
    pub inline fn set_styles(self: Self, stylebits: c_uint) void {
        c.ncplane_set_styles(self.n, stylebits);
    }

    /// Add the specified styles to the ncplane's existing spec.
    pub inline fn on_styles(self: Self, stylebits: c_uint) void {
        c.ncplane_on_styles(self.n, stylebits);
    }

    /// Remove the specified styles from the ncplane's existing spec.
    pub inline fn off_styles(self: Self, stylebits: c_uint) void {
        c.ncplane_off_styles(self.n, stylebits);
    }

    /// Initialize a cell with the planes current style and channels
    pub inline fn cell_init(self: Self) Cell {
        return .{
            .gcluster = 0,
            .gcluster_backstop = 0,
            .width = 0,
            .stylemask = self.styles(),
            .channels = self.channels(),
        };
    }

    /// Breaks the UTF-8 string in 'gcluster' down, setting up the nccell 'c'.
    /// Returns the number of bytes copied out of 'gcluster', or -1 on failure. The
    /// styling of the cell is left untouched, but any resources are released.
    pub inline fn cell_load(self: Self, cell: *Cell, gcluster: [:0]const u8) !usize {
        const ret = c.nccell_load(self.n, cell, gcluster);
        return if (ret < 0) error.NCCellLoadFailed else @intCast(ret);
    }
};
