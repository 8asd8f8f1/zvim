const c = @import("../common.zig");
const Plane = @import("../plane.zig");

pub const Menu = struct {
    n: *c.ncmenu,

    pub const Options = c.ncmenu_options;
    pub const option = struct {
        pub const BOTTOM = c.NCMENU_OPTION_BOTTOM;
        pub const HIDING = c.NCMENU_OPTION_HIDING;
    };

    const Self = @This();

    /// Create a menu with the specified options, bound to the specified plane.
    pub fn init(parent: Plane, opts: Options) !Menu {
        const opts_ = opts;
        return .{ .n = c.ncmenu_create(parent.n, &opts_) orelse return error.NCMenuCreateFailed };
    }

    /// Destroy a menu created with Menu.init().
    pub fn deinit(self: *Self) void {
        c.ncmenu_destroy(self.n);
    }

    /// Offer the input to the menu. If it's relevant, this function returns true,
    /// and the input ought not be processed further. If it's irrelevant to the
    /// menu, false is returned. Relevant inputs include:
    ///  * mouse movement over a hidden menu
    ///  * a mouse click on a menu section (the section is unrolled)
    ///  * a mouse click outside of an unrolled menu (the menu is rolled up)
    ///  * left or right on an unrolled menu (navigates among sections)
    ///  * up or down on an unrolled menu (navigates among items)
    ///  * escape on an unrolled menu (the menu is rolled up)
    pub fn offer_input(self: *Self, nc: *const c.ncinput) bool {
        return c.ncmenu_offer_input(self.n, nc);
    }

    /// Return the item description corresponding to the mouse click 'click'. The
    /// item must be on an actively unrolled section, and the click must be in the
    /// area of a valid item.
    pub fn mouse_selected(self: Self, click: *const Input) ?[]const u8 {
        const p = c.ncmenu_mouse_selected(self.n, click, null);
        return if (p) |p_| p_[0..std.mem.len(p_)] else null;
    }

    /// Return the selected item description, or NULL if no section is unrolled. If
    /// 'ni' is not NULL, and the selected item has a shortcut, 'ni' will be filled
    /// in with that shortcut--this can allow faster matching.
    pub fn selected(self: *Self, ni: *Input) ?[:0]const u8 {
        const p = c.ncmenu_selected(self.n, ni);
        return if (p) |p_| p_[0..std.mem.len(p_) :0] else null;
    }

    /// Disable or enable a menu item. Returns an error if the item was not found.
    pub fn item_set_status(self: Self, section: [:0]const u8, item: [:0]const u8, enabled: bool) !void {
        const err = c.ncmenu_item_set_status(self.n, section, item, enabled);
        if (err != 0) return error.NCMenuItemNotFound;
    }

    pub const Item = c.ncmenu_item;
    pub const Section = c.ncmenu_section;
};
