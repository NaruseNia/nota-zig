pub const CharClass = struct {
    ranges: []const Range,
    negated: bool,
};

pub fn charClass(ranges: []const Range, negated: bool) CharClass {
    return CharClass{
        .ranges = ranges,
        .negated = negated,
    };
}

pub const Group = struct {
    child: *const Node,
};

pub fn group(child: *const Node) Group {
    return Group{ .child = child };
}

pub const Alt = struct {
    options: []const Node,
};

pub fn alt(options: []const Node) Alt {
    if (options.len < 2) {
        @compileError("Alternation requires at least two options");
    }
    return Alt{ .options = options };
}

pub const Range = struct {
    start: u8,
    end: u8,
};

pub fn range(start: u8, end: u8) Range {
    if (start > end) {
        @compileError("Invalid range: start must be less than or equal to end");
    }
    return Range{ .start = start, .end = end };
}

pub const Repeat = struct {
    child: *const Node,
    min: usize,
    /// If `null`, it means there is no upper bound on the number of repetitions.
    max: ?usize,
};

pub fn repeat(child: *const Node, min: usize, max: ?usize) Repeat {
    if (max != null and min > max.?) {
        @compileError("Invalid repetition: min must be less than or equal to max");
    }
    return Repeat{
        .child = child,
        .min = min,
        .max = max,
    };
}

/// A regex AST node
pub const Node = union(enum) {
    literal: u8,
    dot,
    concat: []const Node,
    alt: Alt,
    char_class: CharClass,
    group: Group,
    repeat: Repeat,

    pub fn literalNode(c: u8) Node {
        return Node{ .literal = c };
    }

    pub fn dotNode() Node {
        return Node{ .dot = {} };
    }

    pub fn concatNodes(nodes: []const Node) Node {
        return Node{ .concat = nodes };
    }

    pub fn altNodes(nodes: []const Node) Node {
        return Node{ .alt = alt(nodes) };
    }

    pub fn charClassNode(ranges: []const Range, negated: bool) Node {
        return Node{ .char_class = charClass(ranges, negated) };
    }

    pub fn groupNode(child: *const Node) Node {
        return Node{ .group = group(child) };
    }

    pub fn repeatNode(child: *const Node, min: usize, max: ?usize) Node {
        return Node{ .repeat = repeat(child, min, max) };
    }
};
