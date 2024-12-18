const std = @import("std");
const c = @cImport({
    @cInclude("notcurses/notcurses.h");
    @cInclude("wrappers.h");
});

pub usingnamespace @import("./common.zig");

threadlocal var egc_buffer: [8191:0]u8 = undefined;
threadlocal var key_string_buffer: [64]u8 = undefined;

pub const LogLevel = enum(c.ncloglevel_e) {
    silent = c.NCLOGLEVEL_SILENT,
    panic = c.NCLOGLEVEL_PANIC,
    fatal = c.NCLOGLEVEL_FATAL,
    error_ = c.NCLOGLEVEL_ERROR,
    warning = c.NCLOGLEVEL_WARNING,
    info = c.NCLOGLEVEL_INFO,
    verbose = c.NCLOGLEVEL_VERBOSE,
    debug = c.NCLOGLEVEL_DEBUG,
    trace = c.NCLOGLEVEL_TRACE,
};

pub const Align = enum(c.ncalign_e) {
    unaligned = c.NCALIGN_UNALIGNED,
    left = c.NCALIGN_LEFT,
    center = c.NCALIGN_CENTER,
    right = c.NCALIGN_RIGHT,

    pub const top = Align.left;
    pub const bottom = Align.right;

    pub fn val(self: Align) c_int {
        return @intCast(@intFromEnum(self));
    }
};

pub const mice = struct {
    pub const NO_EVENTS = c.NCMICE_NO_EVENTS;
    pub const MOVE_EVENT = c.NCMICE_MOVE_EVENT;
    pub const BUTTON_EVENT = c.NCMICE_BUTTON_EVENT;
    pub const DRAG_EVENT = c.NCMICE_DRAG_EVENT;
    pub const ALL_EVENTS = c.NCMICE_ALL_EVENTS;
};

pub const style = struct {
    pub const mask = c.NCSTYLE_MASK;
    pub const italic = c.NCSTYLE_ITALIC;
    pub const underline = c.NCSTYLE_UNDERLINE;
    pub const undercurl = c.NCSTYLE_UNDERCURL;
    pub const bold = c.NCSTYLE_BOLD;
    pub const struck = c.NCSTYLE_STRUCK;
    pub const none = c.NCSTYLE_NONE;
};

pub const EXIT_SUCCESS = c.EXIT_SUCCESS;
pub const EXIT_FAILURE = c.EXIT_FAILURE;

pub const CHANNELS_INITIALIZER = c.NCCHANNELS_INITIALIZER;
pub fn channels_set_fg_rgb(arg_channels: *u64, arg_rgb: c_uint) !void {
    const err = c.ncchannels_set_fg_rgb(arg_channels, arg_rgb);
    if (err != 0)
        return error.NCInvalidRGBValue;
}
pub fn channels_set_bg_rgb(arg_channels: *u64, arg_rgb: c_uint) !void {
    const err = c.ncchannels_set_bg_rgb(arg_channels, arg_rgb);
    if (err != 0)
        return error.NCInvalidRGBValue;
}
pub fn channels_set_fg_alpha(arg_channels: *u64, arg_alpha: c_uint) !void {
    const err = c.ncchannels_set_fg_alpha(arg_channels, arg_alpha);
    if (err != 0)
        return error.NCInvalidAlphaValue;
}
pub fn channels_set_bg_alpha(arg_channels: *u64, arg_alpha: c_uint) !void {
    const err = c.ncchannels_set_bg_alpha(arg_channels, arg_alpha);
    if (err != 0)
        return error.NCInvalidAlphaValue;
}
pub const channels_set_bchannel = c.ncchannels_set_bchannel;
pub const channels_set_fchannel = c.ncchannels_set_fchannel;

pub const channel_set_rgb8 = c.ncchannel_set_rgb8;
pub const channel_set_rgb8_clipped = c.ncchannel_set_rgb8_clipped;

pub const ALPHA_HIGHCONTRAST = c.NCALPHA_HIGHCONTRAST;
pub const ALPHA_TRANSPARENT = c.NCALPHA_TRANSPARENT;
pub const ALPHA_BLEND = c.NCALPHA_BLEND;
pub const ALPHA_OPAQUE = c.NCALPHA_OPAQUE;

pub const key = struct {
    pub const INVALID = c.NCKEY_INVALID;
    pub const RESIZE = c.NCKEY_RESIZE;
    pub const UP = c.NCKEY_UP;
    pub const RIGHT = c.NCKEY_RIGHT;
    pub const DOWN = c.NCKEY_DOWN;
    pub const LEFT = c.NCKEY_LEFT;
    pub const INS = c.NCKEY_INS;
    pub const DEL = c.NCKEY_DEL;
    pub const BACKSPACE = c.NCKEY_BACKSPACE;
    pub const PGDOWN = c.NCKEY_PGDOWN;
    pub const PGUP = c.NCKEY_PGUP;
    pub const HOME = c.NCKEY_HOME;
    pub const END = c.NCKEY_END;
    pub const F00 = c.NCKEY_F00;
    pub const F01 = c.NCKEY_F01;
    pub const F02 = c.NCKEY_F02;
    pub const F03 = c.NCKEY_F03;
    pub const F04 = c.NCKEY_F04;
    pub const F05 = c.NCKEY_F05;
    pub const F06 = c.NCKEY_F06;
    pub const F07 = c.NCKEY_F07;
    pub const F08 = c.NCKEY_F08;
    pub const F09 = c.NCKEY_F09;
    pub const F10 = c.NCKEY_F10;
    pub const F11 = c.NCKEY_F11;
    pub const F12 = c.NCKEY_F12;
    pub const F13 = c.NCKEY_F13;
    pub const F14 = c.NCKEY_F14;
    pub const F15 = c.NCKEY_F15;
    pub const F16 = c.NCKEY_F16;
    pub const F17 = c.NCKEY_F17;
    pub const F18 = c.NCKEY_F18;
    pub const F19 = c.NCKEY_F19;
    pub const F20 = c.NCKEY_F20;
    pub const F21 = c.NCKEY_F21;
    pub const F22 = c.NCKEY_F22;
    pub const F23 = c.NCKEY_F23;
    pub const F24 = c.NCKEY_F24;
    pub const F25 = c.NCKEY_F25;
    pub const F26 = c.NCKEY_F26;
    pub const F27 = c.NCKEY_F27;
    pub const F28 = c.NCKEY_F28;
    pub const F29 = c.NCKEY_F29;
    pub const F30 = c.NCKEY_F30;
    pub const F31 = c.NCKEY_F31;
    pub const F32 = c.NCKEY_F32;
    pub const F33 = c.NCKEY_F33;
    pub const F34 = c.NCKEY_F34;
    pub const F35 = c.NCKEY_F35;
    pub const F36 = c.NCKEY_F36;
    pub const F37 = c.NCKEY_F37;
    pub const F38 = c.NCKEY_F38;
    pub const F39 = c.NCKEY_F39;
    pub const F40 = c.NCKEY_F40;
    pub const F41 = c.NCKEY_F41;
    pub const F42 = c.NCKEY_F42;
    pub const F43 = c.NCKEY_F43;
    pub const F44 = c.NCKEY_F44;
    pub const F45 = c.NCKEY_F45;
    pub const F46 = c.NCKEY_F46;
    pub const F47 = c.NCKEY_F47;
    pub const F48 = c.NCKEY_F48;
    pub const F49 = c.NCKEY_F49;
    pub const F50 = c.NCKEY_F50;
    pub const F51 = c.NCKEY_F51;
    pub const F52 = c.NCKEY_F52;
    pub const F53 = c.NCKEY_F53;
    pub const F54 = c.NCKEY_F54;
    pub const F55 = c.NCKEY_F55;
    pub const F56 = c.NCKEY_F56;
    pub const F57 = c.NCKEY_F57;
    pub const F58 = c.NCKEY_F58;
    pub const F59 = c.NCKEY_F59;
    pub const F60 = c.NCKEY_F60;
    pub const ENTER = c.NCKEY_ENTER;
    pub const CLS = c.NCKEY_CLS;
    pub const DLEFT = c.NCKEY_DLEFT;
    pub const DRIGHT = c.NCKEY_DRIGHT;
    pub const ULEFT = c.NCKEY_ULEFT;
    pub const URIGHT = c.NCKEY_URIGHT;
    pub const CENTER = c.NCKEY_CENTER;
    pub const BEGIN = c.NCKEY_BEGIN;
    pub const CANCEL = c.NCKEY_CANCEL;
    pub const CLOSE = c.NCKEY_CLOSE;
    pub const COMMAND = c.NCKEY_COMMAND;
    pub const COPY = c.NCKEY_COPY;
    pub const EXIT = c.NCKEY_EXIT;
    pub const PRINT = c.NCKEY_PRINT;
    pub const REFRESH = c.NCKEY_REFRESH;
    pub const SEPARATOR = c.NCKEY_SEPARATOR;
    pub const CAPS_LOCK = c.NCKEY_CAPS_LOCK;
    pub const SCROLL_LOCK = c.NCKEY_SCROLL_LOCK;
    pub const NUM_LOCK = c.NCKEY_NUM_LOCK;
    pub const PRINT_SCREEN = c.NCKEY_PRINT_SCREEN;
    pub const PAUSE = c.NCKEY_PAUSE;
    pub const MENU = c.NCKEY_MENU;
    pub const MEDIA_PLAY = c.NCKEY_MEDIA_PLAY;
    pub const MEDIA_PAUSE = c.NCKEY_MEDIA_PAUSE;
    pub const MEDIA_PPAUSE = c.NCKEY_MEDIA_PPAUSE;
    pub const MEDIA_REV = c.NCKEY_MEDIA_REV;
    pub const MEDIA_STOP = c.NCKEY_MEDIA_STOP;
    pub const MEDIA_FF = c.NCKEY_MEDIA_FF;
    pub const MEDIA_REWIND = c.NCKEY_MEDIA_REWIND;
    pub const MEDIA_NEXT = c.NCKEY_MEDIA_NEXT;
    pub const MEDIA_PREV = c.NCKEY_MEDIA_PREV;
    pub const MEDIA_RECORD = c.NCKEY_MEDIA_RECORD;
    pub const MEDIA_LVOL = c.NCKEY_MEDIA_LVOL;
    pub const MEDIA_RVOL = c.NCKEY_MEDIA_RVOL;
    pub const MEDIA_MUTE = c.NCKEY_MEDIA_MUTE;
    pub const LSHIFT = c.NCKEY_LSHIFT;
    pub const LCTRL = c.NCKEY_LCTRL;
    pub const LALT = c.NCKEY_LALT;
    pub const LSUPER = c.NCKEY_LSUPER;
    pub const LHYPER = c.NCKEY_LHYPER;
    pub const LMETA = c.NCKEY_LMETA;
    pub const RSHIFT = c.NCKEY_RSHIFT;
    pub const RCTRL = c.NCKEY_RCTRL;
    pub const RALT = c.NCKEY_RALT;
    pub const RSUPER = c.NCKEY_RSUPER;
    pub const RHYPER = c.NCKEY_RHYPER;
    pub const RMETA = c.NCKEY_RMETA;
    pub const L3SHIFT = c.NCKEY_L3SHIFT;
    pub const L5SHIFT = c.NCKEY_L5SHIFT;
    pub const MOTION = c.NCKEY_MOTION;
    pub const BUTTON1 = c.NCKEY_BUTTON1;
    pub const BUTTON2 = c.NCKEY_BUTTON2;
    pub const BUTTON3 = c.NCKEY_BUTTON3;
    pub const BUTTON4 = c.NCKEY_BUTTON4;
    pub const BUTTON5 = c.NCKEY_BUTTON5;
    pub const BUTTON6 = c.NCKEY_BUTTON6;
    pub const BUTTON7 = c.NCKEY_BUTTON7;
    pub const BUTTON8 = c.NCKEY_BUTTON8;
    pub const BUTTON9 = c.NCKEY_BUTTON9;
    pub const BUTTON10 = c.NCKEY_BUTTON10;
    pub const BUTTON11 = c.NCKEY_BUTTON11;
    pub const SIGNAL = c.NCKEY_SIGNAL;
    pub const EOF = c.NCKEY_EOF;
    pub const SCROLL_UP = c.NCKEY_SCROLL_UP;
    pub const SCROLL_DOWN = c.NCKEY_SCROLL_DOWN;
    pub const RETURN = c.NCKEY_RETURN;
    pub const TAB = c.NCKEY_TAB;
    pub const ESC = c.NCKEY_ESC;
    pub const SPACE = c.NCKEY_SPACE;

    /// Is this uint32_t a synthesized event?
    pub fn synthesized_p(w: u32) bool {
        return c.nckey_synthesized_p(w);
    }
};

pub const mod = struct {
    pub const SHIFT = c.NCKEY_MOD_SHIFT;
    pub const ALT = c.NCKEY_MOD_ALT;
    pub const CTRL = c.NCKEY_MOD_CTRL;
    pub const SUPER = c.NCKEY_MOD_SUPER;
    pub const HYPER = c.NCKEY_MOD_HYPER;
    pub const META = c.NCKEY_MOD_META;
    pub const CAPSLOCK = c.NCKEY_MOD_CAPSLOCK;
    pub const NUMLOCK = c.NCKEY_MOD_NUMLOCK;
};

pub fn key_string(ni: *const Input) []const u8 {
    return if (ni.utf8[0] == 0)
        key_id_string(ni.id)
    else
        std.mem.span(@as([*:0]const u8, @ptrCast(&ni.utf8)));
}

pub fn key_id_string(k: u32) []const u8 {
    return switch (k) {
        key.INVALID => "invalid",
        key.RESIZE => "resize",
        key.UP => "up",
        key.RIGHT => "right",
        key.DOWN => "down",
        key.LEFT => "left",
        key.INS => "ins",
        key.DEL => "del",
        key.BACKSPACE => "backspace",
        key.PGDOWN => "pgdown",
        key.PGUP => "pgup",
        key.HOME => "home",
        key.END => "end",
        key.F00 => "f00",
        key.F01 => "f01",
        key.F02 => "f02",
        key.F03 => "f03",
        key.F04 => "f04",
        key.F05 => "f05",
        key.F06 => "f06",
        key.F07 => "f07",
        key.F08 => "f08",
        key.F09 => "f09",
        key.F10 => "f10",
        key.F11 => "f11",
        key.F12 => "f12",
        key.F13 => "f13",
        key.F14 => "f14",
        key.F15 => "f15",
        key.F16 => "f16",
        key.F17 => "f17",
        key.F18 => "f18",
        key.F19 => "f19",
        key.F20 => "f20",
        key.F21 => "f21",
        key.F22 => "f22",
        key.F23 => "f23",
        key.F24 => "f24",
        key.F25 => "f25",
        key.F26 => "f26",
        key.F27 => "f27",
        key.F28 => "f28",
        key.F29 => "f29",
        key.F30 => "f30",
        key.F31 => "f31",
        key.F32 => "f32",
        key.F33 => "f33",
        key.F34 => "f34",
        key.F35 => "f35",
        key.F36 => "f36",
        key.F37 => "f37",
        key.F38 => "f38",
        key.F39 => "f39",
        key.F40 => "f40",
        key.F41 => "f41",
        key.F42 => "f42",
        key.F43 => "f43",
        key.F44 => "f44",
        key.F45 => "f45",
        key.F46 => "f46",
        key.F47 => "f47",
        key.F48 => "f48",
        key.F49 => "f49",
        key.F50 => "f50",
        key.F51 => "f51",
        key.F52 => "f52",
        key.F53 => "f53",
        key.F54 => "f54",
        key.F55 => "f55",
        key.F56 => "f56",
        key.F57 => "f57",
        key.F58 => "f58",
        key.F59 => "f59",
        key.F60 => "f60",
        key.ENTER => "enter", // aka key.RETURN => "return",
        key.CLS => "cls",
        key.DLEFT => "dleft",
        key.DRIGHT => "dright",
        key.ULEFT => "uleft",
        key.URIGHT => "uright",
        key.CENTER => "center",
        key.BEGIN => "begin",
        key.CANCEL => "cancel",
        key.CLOSE => "close",
        key.COMMAND => "command",
        key.COPY => "copy",
        key.EXIT => "exit",
        key.PRINT => "print",
        key.REFRESH => "refresh",
        key.SEPARATOR => "separator",
        key.CAPS_LOCK => "caps_lock",
        key.SCROLL_LOCK => "scroll_lock",
        key.NUM_LOCK => "num_lock",
        key.PRINT_SCREEN => "print_screen",
        key.PAUSE => "pause",
        key.MENU => "menu",
        key.MEDIA_PLAY => "media_play",
        key.MEDIA_PAUSE => "media_pause",
        key.MEDIA_PPAUSE => "media_ppause",
        key.MEDIA_REV => "media_rev",
        key.MEDIA_STOP => "media_stop",
        key.MEDIA_FF => "media_ff",
        key.MEDIA_REWIND => "media_rewind",
        key.MEDIA_NEXT => "media_next",
        key.MEDIA_PREV => "media_prev",
        key.MEDIA_RECORD => "media_record",
        key.MEDIA_LVOL => "media_lvol",
        key.MEDIA_RVOL => "media_rvol",
        key.MEDIA_MUTE => "media_mute",
        key.LSHIFT => "lshift",
        key.LCTRL => "lctrl",
        key.LALT => "lalt",
        key.LSUPER => "lsuper",
        key.LHYPER => "lhyper",
        key.LMETA => "lmeta",
        key.RSHIFT => "rshift",
        key.RCTRL => "rctrl",
        key.RALT => "ralt",
        key.RSUPER => "rsuper",
        key.RHYPER => "rhyper",
        key.RMETA => "rmeta",
        key.L3SHIFT => "l3shift",
        key.L5SHIFT => "l5shift",
        key.MOTION => "motion",
        key.BUTTON1 => "button1",
        key.BUTTON2 => "button2",
        key.BUTTON3 => "button3",
        key.BUTTON4 => "button4", // aka key.SCROLL_UP => "scroll_up",
        key.BUTTON5 => "button5", // aka key.SCROLL_DOWN => "scroll_down",
        key.BUTTON6 => "button6",
        key.BUTTON7 => "button7",
        key.BUTTON8 => "button8",
        key.BUTTON9 => "button9",
        key.BUTTON10 => "button10",
        key.BUTTON11 => "button11",
        key.SIGNAL => "signal",
        key.EOF => "eof",
        key.TAB => "tab",
        key.ESC => "esc",
        key.SPACE => "space",
        else => std.fmt.bufPrint(&key_string_buffer, "{u}", .{@as(u21, @intCast(k))}) catch return "ERROR",
    };
}

pub const Input = c.ncinput;

pub fn input() Input {
    return comptime if (@hasField(Input, "eff_text")) .{
        .id = 0,
        .y = 0,
        .x = 0,
        .utf8 = [_]u8{0} ** 5,
        .alt = false,
        .shift = false,
        .ctrl = false,
        .evtype = 0,
        .modifiers = 0,
        .ypx = 0,
        .xpx = 0,
        .eff_text = [_]u32{0} ** 4,
    } else .{
        .id = 0,
        .y = 0,
        .x = 0,
        .utf8 = [_]u8{0} ** 5,
        .alt = false,
        .shift = false,
        .ctrl = false,
        .evtype = 0,
        .modifiers = 0,
        .ypx = 0,
        .xpx = 0,
    };
}

pub fn isShift(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 1)))) != 0;
}
pub fn isCtrl(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 4)))) != 0;
}
pub fn isAlt(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 2)))) != 0;
}
pub fn isMeta(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 32)))) != 0;
}
pub fn isSuper(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 8)))) != 0;
}
pub fn isHyper(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 16)))) != 0;
}
pub fn isCapslock(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 64)))) != 0;
}
pub fn isNumlock(modifiers: u32) bool {
    return (modifiers & @as(c_uint, @bitCast(@as(c_int, 128)))) != 0;
}

pub const event_type = struct {
    pub const UNKNOWN = c.NCTYPE_UNKNOWN;
    pub const PRESS = c.NCTYPE_PRESS;
    pub const REPEAT = c.NCTYPE_REPEAT;
    pub const RELEASE = c.NCTYPE_RELEASE;
};

pub fn typeToString(t: c.ncintype_e) []const u8 {
    return switch (t) {
        event_type.PRESS => "P",
        event_type.RELEASE => "R",
        event_type.REPEAT => "r",
        else => "U",
    };
}

/// Returns the number of columns occupied by the longest valid prefix of a
/// multibyte (UTF-8) string. If an invalid character is encountered, -1 will be
/// returned, and the number of valid bytes and columns will be written into
/// *|validbytes| and *|validwidth| (assuming them non-NULL). If the entire
/// string is valid, *|validbytes| and *|validwidth| reflect the entire string.
pub fn wcwidth(egcs: []const u8) !usize {
    var buf = if (egcs.len <= egc_buffer.len) &egc_buffer else return error.Overflow;
    @memcpy(buf[0..egcs.len], egcs);
    buf[egcs.len] = 0;
    return ncstrwidth(buf);
}

/// Returns the number of columns occupied by a multibyte (UTF-8) string.
fn ncstrwidth(egcs: [:0]const u8) !usize {
    var validbytes: c_int = 0;
    var validwidth: c_int = 0;
    const ret = c.ncstrwidth(egcs.ptr, &validbytes, &validwidth);
    return if (ret < 0) error.InvalidChar else @intCast(validwidth);
}

/// Calculate the length and width of the next EGC in the UTF-8 string input.
/// We use libunistring's uc_is_grapheme_break() to segment EGCs. Writes the
/// number of columns to '*colcount'. Returns the number of bytes consumed,
/// not including any NUL terminator. Neither the number of bytes nor columns
/// is necessarily equal to the number of decoded code points. Such are the
/// ways of Unicode. uc_is_grapheme_break() wants UTF-32, which is fine, because
/// we need wchar_t to use wcwidth() anyway FIXME except this doesn't work with
/// 16-bit wchar_t!
pub fn ncegc_len(egcs: []const u8, colcount: *c_int) !usize {
    if (egcs[0] < 128) {
        colcount.* = 1;
        return 1;
    }
    const buf_size = 64;
    var egc_buf: [buf_size:0]u8 = undefined;
    var buf = if (egcs.len <= buf_size)
        &egc_buf
    else if (egcs.len <= egc_buffer.len)
        &egc_buffer
    else
        return error.Overflow;
    @memcpy(buf[0..egcs.len], egcs);
    buf[egcs.len] = 0;
    const ret = c.utf8_egc_len(buf.ptr, colcount);
    return if (ret < 0) error.InvalidChar else @intCast(ret);
}

/// input functions like notcurses_get() return ucs32-encoded uint32_t. convert
/// a series of uint32_t to utf8. result must be at least 4 bytes per input
/// uint32_t (6 bytes per uint32_t will future-proof against Unicode expansion).
/// the number of bytes used is returned, or -1 if passed illegal ucs32, or too
/// small of a buffer.
pub fn ucs32_to_utf8(ucs32: []const u32, utf8: []u8) !usize {
    const ret = c.notcurses_ucs32_to_utf8(ucs32.ptr, @intCast(ucs32.len), utf8.ptr, utf8.len);
    if (ret < 0) return error.Ucs32toUtf8Error;
    return @intCast(ret);
}

// the following functions are workarounds for miscompilation of notcurses.h by cImport
pub fn c__ncplane_putstr_yx(arg_n: ?*c.struct_ncplane, arg_y: c_int, arg_x: c_int, arg_gclusters: [*c]const u8) callconv(.C) c_int {
    var n = arg_n;
    _ = &n;
    var y = arg_y;
    _ = &y;
    var x = arg_x;
    _ = &x;
    var gclusters = arg_gclusters;
    _ = &gclusters;
    var ret: c_int = 0;
    _ = &ret;
    while (gclusters.* != 0) {
        var wcs: usize = undefined;
        _ = &wcs;
        var cols: c_int = c.ncplane_putegc_yx(n, y, x, gclusters, &wcs);
        _ = &cols;
        if (cols < @as(c_int, 0))
            return -ret;
        if (wcs == @as(usize, @bitCast(@as(c_long, @as(c_int, 0)))))
            break;
        y = -@as(c_int, 1);
        x = -@as(c_int, 1);
        gclusters += wcs;
        ret += cols;
    }
    return ret;
}

pub fn c__ncplane_putstr(arg_n: ?*c.struct_ncplane, arg_gclustarr: [*:0]const u8) callconv(.C) c_int {
    var n = arg_n;
    _ = &n;
    var gclustarr = arg_gclustarr;
    _ = &gclustarr;
    return c__ncplane_putstr_yx(n, -@as(c_int, 1), -@as(c_int, 1), gclustarr);
}

pub fn c__ncplane_putstr_aligned(arg_n: ?*c.struct_ncplane, arg_y: c_int, arg_align: c.ncalign_e, arg_s: [*c]const u8) callconv(.C) c_int {
    var n = arg_n;
    _ = &n;
    var y = arg_y;
    _ = &y;
    var @"align" = arg_align;
    _ = &@"align";
    var s = arg_s;
    _ = &s;
    var validbytes: c_int = undefined;
    _ = &validbytes;
    var validwidth: c_int = undefined;
    _ = &validwidth;
    _ = c.ncstrwidth(s, &validbytes, &validwidth);
    var xpos: c_int = c.ncplane_halign(n, @"align", validwidth);
    _ = &xpos;
    if (xpos < @as(c_int, 0))
        xpos = 0;
    return c__ncplane_putstr_yx(n, y, xpos, s);
}
