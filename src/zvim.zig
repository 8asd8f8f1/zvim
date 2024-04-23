const std = @import("std");

pub const zvim = struct {
    cmdline_row: u32,
    msg_row: u32,
};

pub const UpdateScreenChange = enum(u8) {
    VALID_NO_UPDATE = 5,
    VALID = 10,
    INVERTED = 20,
    INVERTED_ALL = 25,
    REDRAW_TOP = 30,
    SOME_VALID = 35,
    NOT_VALID = 40,
    CLEAR = 50,
};

pub const WValid = enum(u8) {
    WROW = 0x01,
    WCOL = 0x02,
    VIRTCOL = 0x04,
    CHEIGHT = 0x08,
    CROW = 0x10,
    BOTLINE = 0x20,
    BOTLINE_AP = 0x40,
    TOPLINE = 0x80,
};

pub const POPF = enum(u16) {
    IS_POPUP = 0x01,
    HIDDEN = 0x02,
    HIDDEN_FORCE = 0x04,
    CURSORLINE = 0x08,
    ON_CMDLINE = 0x10,
    DRAG = 0x20,
    DRAGALL = 0x40,
    RESIZE = 0x80,
    MAPPING = 0x100,
    INFO = 0x200,
    INFO_MENU = 0x400,
    POSINVERT = 0x800,
};
