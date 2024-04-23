const std = @import("std");

pub const Id = struct {
    val: []const u8,

    HELP: []const u8 = "help",
    VERSION: []const u8 = "version",
    EXTERNAL: []const u8 = "",

    pub fn as_str(self: Id) []u8 {
        return self;
    }

    pub fn from(name: []const u8) Id {
        return Id{
            .val = name,
        };
    }
};
