const std = @import("std");

pub const Entry = packed struct {
    name: []u8,
    time: std.time.Instant,
    mode: std.c.mode_t,
    blocks: u40,
    nlen: u16,
    flags: u8,
};
