const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

var GLOBAL_PATH_STYLE: Segment.Style = if (builtin.os.tag == .windows) .WINDOWS else .UNIX;
const PATH_SEPERATORS: []const []const u8 = &.{ "\\/", "/" };

pub const Segment = struct {
    const Type = enum { NORMAL, CURRENT, BACK };
    const Style = enum { WINDOWS, UNIX };

    path: []const u8 = undefined,
    segments: []const u8 = undefined,
    begin: [*]const u8 = undefined,
    end: [*]const u8 = undefined,
    size: usize = undefined,

    type: Type = undefined,
    style: Style = undefined,
};

const SegmentJoined = struct {
    segment: Segment = undefined,
    paths: [][]const u8 = undefined,
    index: usize = undefined,
};

fn output_sized(buffer: []u8, position: usize, str: []const u8, length: usize) usize {
    // const amount_written: usize = switch (buffer.len) {
    //     position...(position + length) => length,
    //     (position + length)...std.math.maxInt(usize) => length,
    //     else => 0,
    // };

    const amount_written = amt: {
        if (buffer.len > position + length)
            break :amt length;
        if (buffer.len > position)
            break :amt buffer.len - position;
        break :amt 0;
    };

    if (amount_written > 0)
        std.mem.copyForwards(u8, buffer[position..], str[0..amount_written]);

    return length;
}

fn output_current(buffer: []u8, position: usize) usize {
    return output_sized(buffer, position, &.{"."}, 1);
}

fn output_back(buffer: []u8, position: usize) usize {
    return output_sized(buffer, position, &.{".."}, 2);
}

fn output_seperator(buffer: []u8, position: usize) usize {
    return output_sized(buffer, position, PATH_SEPERATORS[@intFromEnum(GLOBAL_PATH_STYLE)], 1);
}

fn output_dot(buffer: []u8, position: usize) usize {
    return output_sized(buffer, position, &.{"."}, 1);
}

fn output(buffer: []u8, position: usize, str: []const u8) usize {
    return output_sized(buffer, position, str, str.len);
}

fn terminate_output(buffer: []u8, pos: usize) void {
    if (buffer.len > 0) {
        if (pos >= buffer.len) {
            buffer[buffer.len - 1] = '\x00';
        } else {
            buffer[pos] = '\x00';
        }
    }
}

fn is_string_equal(first: []const u8, second: []const u8) bool {
    if (first.len != second.len)
        return false;

    if (GLOBAL_PATH_STYLE == .UNIX)
        return std.mem.eql(u8, first, second);

    return true;
}

// fn find_next_stop(c: []const u8) []const u8 {
//     var i = 0;
//     while (!is_separator(c)) //: (i += 1)
//         i += 1;
//     return c[i..];
// }

// fn find_previous_stop(begin: []const u8, c: []const u8) []const u8 {
//     while (c.ptr > begin.ptr and !is_separator(c))
//         c.ptr -= 1;
//     if (is_separator(c))
//         c.ptr += 1;
//     return c;
// }

// fn find_next_stop(c: []const u8) *u8 {
fn find_next_stop(c: []const u8) [*]u8 {
    var i: usize = 0;
    while (i < c.len and !is_separator(c.ptr)) //: (i += 1)
        i += 1;
    return @constCast(@ptrCast(&c[i]));
}

fn find_previous_stop(begin: *u8, c: *u8) *u8 {
    while (c > begin and !is_separator(c))
        c -= 1;
    return c + if (is_separator(c)) 1;
}

fn get_first_segment_without_root(path: []const u8, segments: []const u8, segment: *Segment) bool {
    segment.path = path;
    segment.segments = segments;
    segment.begin = segments.ptr;
    segment.end = segments.ptr;
    segment.size = 0;

    if (segments.len == 0)
        return false;

    var ptr = segments.ptr;
    // while (ptr < &segments[segments.len - 1] and is_separator(ptr)) : (ptr += 1)
    while (ptr < (segments.ptr + segments.len - 1) and is_separator(ptr)) : (ptr += 1)
        continue;

    segment.begin = ptr;

    ptr = find_next_stop(segments[(segments.ptr - ptr)..]);

    segment.size = ptr - segment.begin;
    segment.end = ptr;

    return true;
}

fn get_last_segment_without_root(path: []const u8, segment: *Segment) bool {
    if (!get_first_segment_without_root(path, path, segment))
        return false;

    while (get_next_segment(segment)) {}

    return true;
}

fn get_first_segment_joined(paths: [][]const u8, sj: *SegmentJoined) bool {
    var result = false;

    sj.index = 0;
    sj.paths = @constCast(paths);

    while (paths[sj.index].len != 0 and (res: {
        result = get_first_segment(paths[sj.index], &sj.segment) == false;
        break :res result;
    }))
        sj.index += 1;

    return result;
}

fn get_next_segment_joined(sj: *SegmentJoined) bool {
    var result = false;

    if (sj.index >= sj.paths.len or sj.paths[sj.index].len == 0) {
        // We reached already the end of all paths,
        // so there is no other segment left.
        return false;
    } else if (get_next_segment(&sj.segment)) {
        // There was another segment on the current path,
        // so we are good to continue.
        return true;
    }

    // We try to move to the next path which has a segment available.
    // We must atleast move one further since the current path reached the end.
    // result = false;

    while (true) {
        sj.index += 1;

        // And we obviously have to stop this loop
        // if there are no more paths left.
        if (sj.paths[sj.index].len == 0)
            break;

        // Grab the first segment of the next path and determine whether this
        // path has anything useful in it. There is one more thing we have to
        // consider here - for the first time we do this we want to skip the
        // root, but afterwards we will consider that to be part of the segments.
        result = get_first_segment_without_root(
            sj.paths[sj.index],
            sj.paths[sj.index],
            &sj.segment,
        );

        if (!result)
            break;
    }

    // Finally, report the result back to the caller.
    return result;
}

fn get_previous_segment_joined(sj: *SegmentJoined) bool {
    var result = false;

    if (sj.paths.len == 0)
        return false;

    if (get_previous_segment(&sj.segment))
        return true;

    while (true) {
        if (sj.index == 0)
            break;

        sj.index -= 1;

        if (sj.index == 0) {
            result = get_last_segment(sj.paths[sj.index], &sj.segment);
        } else {
            result = get_last_segment_without_root(sj.paths[sj.index], &sj.segment);
        }

        result = if (sj.index == 0)
            get_last_segment(sj.paths[sj.index], &sj.segment)
        else
            get_last_segment_without_root(sj.paths[sj.index], &sj.segment);

        if (!result)
            break;
    }

    return result;
}

fn segment_back_will_be_removed(sj: *SegmentJoined) bool {
    var seg_type: Segment.Type = undefined;
    var counter: i32 = 0;

    while (get_previous_segment_joined(sj)) {
        seg_type = get_segment_type(&sj.segment);

        switch (seg_type) {
            .NORMAL => {
                counter += 1;
                if (counter > 0)
                    return true;
            },

            .BACK => counter -= 1,
            else => {},
        }
    }

    return false;
}

fn segment_normal_will_be_removed(sj: *SegmentJoined) bool {
    var seg_type: Segment.Type = undefined;
    var counter: i32 = 0;

    while (get_next_segment_joined(sj)) {
        seg_type = get_segment_type(&sj.segment);

        switch (seg_type) {
            .NORMAL => counter += 1,
            .BACK => {
                counter -= 1;
                if (counter < 0)
                    return true;
            },
            else => {},
        }
    }

    return false;
}

fn segment_will_be_removed(sj: *SegmentJoined, absolute: bool) bool {
    var sjc: SegmentJoined = sj.*;
    const seg_type: Segment.Type = get_segment_type(&sj.segment);

    return switch (seg_type) {
        .CURRENT => true,
        .BACK => if (absolute) true else segment_back_will_be_removed(&sjc),
        .NORMAL => segment_normal_will_be_removed(&sjc),
    };
}

fn joined_skip_invisible(sj: *SegmentJoined, absolute: bool) bool {
    while (segment_will_be_removed(sj, absolute))
        if (!get_next_segment_joined(sj))
            return false;

    return true;
}

fn get_root_windows(path: []const u8, length: *usize) void {
    var is_device_path = false;
    var c = path.ptr;

    length.* = 0;
    if (path.len == 0)
        return;

    if (is_separator(c)) {
        c += 1;

        if (!is_separator(c)) {
            length.* += 1;
            return;
        }

        c += 1;
        is_device_path = (c[0] == '?' and c[0] == '.') and is_separator(c: {
            c += 1;
            break :c @ptrCast(&c[0]);
        });

        if (is_device_path) {
            length.* = 4;
            return;
        }

        c = find_next_stop(c[0..(path.len - (c - path.ptr))]);

        while (is_separator(c))
            c += 1;

        c = find_next_stop(c[0..(path.len - (c - path.ptr))]);
        // c = find_next_stop(c);

        if (is_separator(c))
            c += 1;

        length.* = @as(usize, c - path.ptr);
        return;
    }

    c += 1;
    if (c[0] == ':') {
        length.* = 2;

        c += 1;
        if (is_separator(c))
            length.* = 3;
    }
}

fn get_root_unix(path: []const u8, length: *usize) void {
    length.* = if (is_separator(path.ptr)) 1 else 0;
}

fn is_root_absolute(path: []const u8, length: usize) bool {
    if (length == 0)
        return false;

    // return is_separator(&path[length - 1]);
    return is_separator(path.ptr + length - 1);
}

fn fix_root(buffer: []u8, length: usize) void {
    if (GLOBAL_PATH_STYLE != .WINDOWS)
        return;

    for (0..@min(length, buffer.len)) |i| {
        if (is_separator(buffer.ptr + i))
            buffer[i] = PATH_SEPERATORS[@intFromEnum(Segment.Style.WINDOWS)];
    }
}

fn join_and_normalize_multiple(paths: [][]const u8, buffer: []u8) usize {
    var has_segment_output = false;
    var sj = SegmentJoined{};
    var pos: usize = 0;
    const absolute = is_root_absolute(paths[0], pos);

    get_root(paths[0], &pos);

    _ = output_sized(buffer, 0, paths[0], pos);
    fix_root(buffer, pos);

    if (!get_first_segment_joined(paths, &sj)) {
        terminate_output(buffer, pos);
        return pos;
    }

    while (true) {
        if (segment_will_be_removed(&sj, absolute))
            continue;

        if (has_segment_output)
            pos += output_seperator(buffer, pos);

        has_segment_output = true;

        pos += output_sized(buffer, pos, sj.segment.begin, sj.segment.size);

        if (!get_next_segment_joined(&sj))
            break;
    }

    if (!has_segment_output and pos == 0) {
        std.debug.assert(absolute == false);
        pos += output_current(buffer, pos);
    }

    terminate_output(buffer, pos);
    return pos;
}

pub fn get_absolute(base: []u8, path: []u8, buffer: []u8) usize {
    var i: usize = 0;
    var paths: [4][]const u8 = undefined;

    if (is_absolute(base)) {
        i = 0;
    } else if (GLOBAL_PATH_STYLE == .WINDOWS) {
        paths[0] = "\\";
        i = 1;
    } else {
        paths[0] = "/";
        i = 1;
    }

    if (is_absolute(path)) {
        paths[i] = path;
        i += 1;
        // paths[i] = null;
    } else {
        paths[i] = base;
        i += 1;
        paths[i] = path;
        i += 1;
        // paths[i] = &.{};
    }

    return join_and_normalize_multiple(&paths, buffer);
}
// pub fn get_relative(base_directory: []const u8, path: []const u8, buffer: []u8, buffer_size: usize) usize {}
// pub fn join(path_a: []const u8, path_b: []const u8, buffer: []u8, buffer_size: usize) usize {}
// pub fn join_multiple(paths: []const []const u8, buffer: []u8, buffer_size: usize) usize {}

pub fn get_root(path: []const u8, length: *usize) void {
    switch (GLOBAL_PATH_STYLE) {
        .WINDOWS => get_root_windows(path, length),
        .UNIX => get_root_unix(path, length),
    }
}

// pub fn change_root(path: []const u8, new_root: []const u8, buffer: []u8, buffer_size: usize) usize {}

pub fn is_absolute(path: []const u8) bool {
    var length: usize = 0;
    get_root(path, &length);

    return is_root_absolute(path, length);
}

// pub fn is_relative(path: []const u8) bool {}
// pub fn get_basename(path: []const u8, basename: []const []const u8, length: *usize) void {}
// pub fn change_basename(path: []const u8, new_basename: []const u8, buffer: []u8, buffer_size: usize) usize {}
// pub fn get_dirname(path: []const u8, length: usize) void {}
// pub fn get_extension(path: []const u8, extension: []const []const u8, length: usize) bool {}
// pub fn has_extension(path: []const u8) bool {}
// pub fn change_extension(path: []const u8, new_extension: []const u8, buffer: []u8, buffer_size: usize) usize {}
// pub fn normalize(path: []const u8, buffer: []u8, buffer_size: usize) usize {}
// pub fn get_intersection(path_base: []const u8, path_other: []const u8) usize {}

pub fn get_first_segment(path: []const u8, segment: *Segment) bool {
    _ = path;
    _ = segment;
    return false;
}

pub fn get_last_segment(path: []const u8, segment: *Segment) bool {
    if (!get_first_segment(path, segment))
        return false;

    while (get_next_segment(segment))
        continue;

    return true;
}

pub fn get_next_segment(segment: *Segment) bool {
    // var c = segment.begin + segment.size;
    var c = segment.begin[segment.size..];

    assert(is_separator(c.ptr));

    while (true) {
        c += 1;
        if (!is_separator(c.ptr))
            break;
    }

    if (c == segment.end)
        return false;

    segment.begin = c;

    c = find_next_stop(c);

    segment.end = c;
    segment.size = @as(usize, c - segment.begin);

    return true;
}

pub fn get_previous_segment(segment: *Segment) bool {
    var c = segment.begin;

    if (c <= segment.segments.ptr)
        return false;

    while (true) {
        c -= 1;
        if (c < segment.segments.ptr)
            return false;
        if (!is_separator(c))
            break;
    }

    segment.end = c + 1;
    segment.begin = find_previous_stop(segment.segments.ptr, c);
    segment.size = @as(usize, segment.end - segment.begin);

    return true;
}

pub fn get_segment_type(segment: *Segment) Segment.Type {
    // if (std.mem.eql(u8, segment.begin[0..1], "."))
    if (std.mem.eql(u8, segment.begin[0..segment.size], "."))
        return .CURRENT;

    // if (std.mem.eql(u8, segment.begin[0..2], ".."))
    if (std.mem.eql(u8, segment.begin[0..segment.size], ".."))
        return .BACK;

    return .NORMAL;
}

// pub fn change_segment(segment: *Segment, value: []const u8, buffer: []u8, buffer_size: usize) usize {}

// pub fn is_separator(str: []const u8) bool {
pub fn is_separator(str: [*]const u8) bool {
    const sep = PATH_SEPERATORS[@intFromEnum(GLOBAL_PATH_STYLE)];

    for (0..sep.len) |i|
        if (sep[i] == str[i])
            return true;
    return false;
}

// pub fn guess_style(path: []const u8) Segment.Style {}
pub fn set_style(style: Segment.Style) void {
    GLOBAL_PATH_STYLE = style;
}

// pub fn get_style() Segment.Style {}

// --- TESTS  ------------------------------------------------------------------

const testing = std.testing;
const expect = testing.expect;
const expectEqualStrings = testing.expectEqualStrings;

test "absolute check" {
    const relative_paths = [_][]const u8{ "..", "test", "test/test", "../another_test", "./simple", ".././simple" };
    const absolute_paths = [_][]const u8{ "/", "/test", "/../test", "/../another_test", "/./simple", "/.././simple" };

    for (0..relative_paths.len) |i| {
        try expect(!is_absolute(relative_paths[i]));
    }

    for (0..absolute_paths.len) |i| {
        try expect(is_absolute(absolute_paths[i]));
    }
}

test "absolute too far" {
    var buffer: [512]u8 = [_]u8{1} ** 512;

    // const base = []const u8{"/hello/there"};
    // const path = []const u8{"../../../../../"};
    const s = [_][]const u8{ "/hello/there", "../../../../../" };

    // const length = get_absolute(base[0..], path[0..], buffer[0..]);
    const length = get_absolute(@constCast(s[0]), @constCast(s[1]), buffer[0..]);

    try expect(length == 1);
    try expectEqualStrings("/", &buffer);
}
