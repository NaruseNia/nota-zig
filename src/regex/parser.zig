const std = @import("std");
const ast = @import("ast.zig");

const Cursor = struct {
    const Self = @This();

    input: []const u8,
    curr: usize,

    /// Gets the current character without advancing the cursor.
    /// If the cursor is out of bounds, it will cause a compile error.
    fn currChar(self: *const Self) u8 {
        if (self.isOutOfBounds()) {
            @compileError("Unexpected end of pattern");
        }
        return self.input[self.curr];
    }

    /// Peeks ahead by `amount` characters without advancing the cursor.
    fn peek(self: *const Self, amount: u8) ?u8 {
        if (self.curr + amount < self.input.len) {
            return self.input[self.curr + amount];
        }

        return null;
    }

    /// Peeks the next character without advancing the cursor.
    fn peekNext(self: *const Self) ?u8 {
        if (self.curr + 1 < self.input.len) {
            return self.input[self.curr + 1];
        }
        return null;
    }

    /// Takes the next `amount` characters and advances the cursor.
    fn take(self: *Self, amount: usize) []const u8 {
        if (self.curr + amount > self.input.len) {
            @compileError("Unexpected end of pattern");
        }
        const slice = self.input[self.curr .. self.curr + amount];
        self.curr += amount;

        return slice;
    }

    /// Takes the next character and advances the cursor.
    fn takeNext(self: *Self) u8 {
        if (self.curr >= self.input.len) {
            @compileError("Unexpected end of pattern");
        }
        const c = self.input[self.curr];
        self.curr += 1;
        return c;
    }

    /// Increments the cursor by 1 without returning the current character.
    fn skip(self: *Self) void {
        self.curr += 1;
    }

    /// Checks if the cursor is out of bounds (i.e. has reached the end of the input).
    fn isOutOfBounds(self: *const Self) bool {
        return self.curr >= self.input.len;
    }

    /// Checks if the cursor is in bounds (i.e. has not reached the end of the input).
    fn isInBounds(self: *const Self) bool {
        return self.curr < self.input.len;
    }
};

/// Parses a regex pattern at compile time and returns an `ast.Node` representing the parsed pattern.
pub fn parse(comptime pattern: []const u8) ast.Node {
    comptime var state = Cursor{
        .input = pattern,
        .curr = 0,
    };
    comptime var nodes: []const ast.Node = &.{};
    // Reading each character of the `pattern`
    while (state.isInBounds()) {
        const c = state.takeNext();

        switch (c) {
            // Escape sequences
            '\\' => nodes = nodes ++ &[_]ast.Node{parseEscaped(&state)},
            // Char class
            '[' => nodes = nodes ++ &[_]ast.Node{parseCharClass(&state)},
            // Literals
            else => {
                nodes = nodes ++ &[_]ast.Node{ast.Node.literalNode(c)};
            },
        }
    }

    return switch (nodes.len) {
        0 => @compileError("Empty pattern is not supported"),
        1 => nodes[0],
        else => ast.Node.concatNodes(nodes),
    };
}

/// Parses an escape sequence (e.g. \n, \t, \w) and returns an `ast.Node` representing it.
fn parseEscaped(comptime cursor: *Cursor) ast.Node {
    if (cursor.isOutOfBounds()) {
        @compileError("Unexpected end of pattern after '\\'");
    }

    const next = cursor.takeNext();

    switch (next) {
        't' => return ast.Node.literalNode('\t'),
        'n' => return ast.Node.literalNode('\n'),
        'r' => return ast.Node.literalNode('\r'),
        '\\' => return ast.Node.literalNode('\\'),
        'w' => return ast.Node.charClassNode(&[_]ast.Range{
            ast.range('a', 'z'),
            ast.range('A', 'Z'),
            ast.range('0', '9'),
            ast.range('_', '_'),
        }, false),
        'd' => return ast.Node.charClassNode(&[_]ast.Range{
            ast.range('0', '9'),
        }, false),
        's' => return ast.Node.charClassNode(&[_]ast.Range{
            ast.range(' ', ' '),
            ast.range('\t', '\t'),
            ast.range('\n', '\n'),
            ast.range('\r', '\r'),
        }, false),
        else => @compileError("Unsupported escape sequence"),
    }
}

/// Parses a character class (e.g. [abc], [a-z], [^0-9]) and returns an `ast.Node` representing it.
fn parseCharClass(comptime cursor: *Cursor) ast.Node {
    if (cursor.isOutOfBounds()) {
        @compileError("Unexpected end of pattern in character class");
    }

    comptime var ranges: []const ast.Range = &.{};

    comptime var negated = false;
    if (cursor.isInBounds() and cursor.currChar() == '^') {
        negated = true;
        cursor.skip();
    }

    // Read until closing ']'
    while (cursor.isInBounds()) {
        if (cursor.currChar() == ']') {
            cursor.skip();
            break;
        }

        // Handle ranges (e.g. a-z) and escape sequences
        const next = cursor.takeNext();
        if (cursor.isOutOfBounds()) {
            @compileError("Unexpected end of pattern in character class");
        }

        // Range (e.g. [a-z]) Peek next character to check for '-'
        if (cursor.currChar() == '-') {
            cursor.skip(); // Skip '-'
            const end = cursor.takeNext();

            // Add range to char class
            ranges = ranges ++ &[_]ast.Range{ast.range(next, end)};
        } else {
            // Literals (e.g [abc])
            ranges = ranges ++ &[_]ast.Range{ast.range(next, next)};
        }
    }

    return ast.Node.charClassNode(ranges, negated);
}

test "parse single literal" {
    const node = comptime parse("a");
    try std.testing.expect(node == .literal);
    try std.testing.expectEqual(@as(u8, 'a'), node.literal);
}

test "parse two characters" {
    const node = comptime parse("ab");
    try std.testing.expect(node == .concat);
    try std.testing.expectEqual(2, node.concat.len);
}

test "parse \\n literal" {
    const node = comptime parse("\\n");
    try std.testing.expect(node == .literal);
    try std.testing.expectEqual(@as(u8, '\n'), node.literal);
}

test "parse \\w character class" {
    const node = comptime parse("\\w");
    try std.testing.expect(node == .char_class);
    try std.testing.expectEqual(4, node.char_class.ranges.len);
}

test "parse simple char class" {
    const node = comptime parse("[abc]");
    try std.testing.expect(node == .char_class);
    try std.testing.expectEqual(3, node.char_class.ranges.len);
}

test "parse simple range char class" {
    const node = comptime parse("[a-z]");
    try std.testing.expect(node == .char_class);
    try std.testing.expectEqual(1, node.char_class.ranges.len);
}

test "parse negated char class" {
    const node = comptime parse("[^0-9]");
    try std.testing.expect(node == .char_class);
    try std.testing.expect(node.char_class.negated);
    try std.testing.expectEqual(1, node.char_class.ranges.len);
}
