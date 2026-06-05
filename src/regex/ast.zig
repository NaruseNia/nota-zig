pub const CharClass = struct {
    ranges: []const Range,
    negated: bool,
};

pub const Group = struct {
    child: *const Node,
};

pub const Range = struct {
    start: u8,
    end: u8,
};

pub const Repeat = struct {
    child: *const Node,
    min: usize,
    /// If `null`, it means there is no upper bound on the number of repetitions.
    max: ?usize,
};

/// A regex AST node
pub const Node = union(enum) {
    literal: u8,
    dot,
    concat: []const Node,
    alt: []const Node,
    char_class: CharClass,
    group: Group,
    repeat: Repeat,
};
