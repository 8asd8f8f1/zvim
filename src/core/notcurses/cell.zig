const c = @import("./common.zig");

pub const Cell = c.nccell;
pub const cell_empty = Cell{
    .gcluster = 0,
    .gcluster_backstop = 0,
    .width = 0,
    .stylemask = 0,
    .channels = 0,
};

/// return the number of columns occupied by 'c'. see ncstrwidth() for an
/// equivalent for multiple EGCs.
pub const cell_cols = c.nccell_cols;

/// Is the cell part of a multicolumn element?
pub const cell_double_wide_p = c.nccell_double_wide_p;

/// Is this the right half of a wide character?
pub const cell_wide_right_p = c.nccell_wide_right_p;

/// Is this the left half of a wide character?
pub const cell_wide_left_p = c.nccell_wide_left_p;

/// Set the specified style bits for the nccell 'c', whether they're actively
/// supported or not. Only the lower 16 bits are meaningful.
pub const cell_set_styles = c.nccell_set_styles;

/// Add the specified styles (in the LSBs) to the nccell's existing spec,
/// whether they're actively supported or not.
pub const cell_on_styles = c.nccell_on_styles;

/// Remove the specified styles (in the LSBs) from the nccell's existing spec.
pub const cell_off_styles = c.nccell_off_styles;
