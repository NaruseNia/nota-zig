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

    /// Peeks characters while the `predicate` returns `true`, without advancing the cursor.
    fn peekWhile(self: *const Self, predicate: fn (u8) bool) []const u8 {
        const start = self.curr;
        while (self.isInBounds() and predicate(self.currChar())) {
            self.curr += 1;
        }
        return self.input[start..self.curr];
    }

    /// Peeks characters until the `terminator` is found, without advancing the cursor.
    fn peekUntil(self: *const Self, terminator: u8) []const u8 {
        const start = self.curr;
        while (self.isInBounds() and self.currChar() != terminator) {
            self.curr += 1;
        }
        return self.input[start..self.curr];
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

    /// Takes characters while the `predicate` returns `true` and advances the cursor.
    fn takeWhile(self: *Self, predicate: fn (u8) bool) []const u8 {
        const start = self.curr;
        while (self.isInBounds() and predicate(self.currChar())) {
            self.curr += 1;
        }
        return self.input[start..self.curr];
    }

    /// Takes characters until the `terminator` is found and advances the cursor.
    fn takeUntil(self: *Self, terminator: u8) []const u8 {
        const start = self.curr;
        while (self.isInBounds() and self.currChar() != terminator) {
            self.curr += 1;
        }
        return self.input[start..self.curr];
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
            // Range
            '[' => nodes = nodes ++ &[_]ast.Node{parseCharClass(&state)},
            // Repetition
            '{' => {
                // If { becomes the first node, it's an error because there is nothing to repeat
                if (nodes.len == 0) @compileError("Nothing to repeat before '{'");

                const rep = parseRepetition(&state);
                nodes = nodes[0 .. nodes.len - 1] ++ &[_]ast.Node{
                    ast.Node.repeatNode(&nodes[nodes.len - 1], rep.min, rep.max),
                };
            },
            // Repeat operators
            '*' => {
                // If * becomes the first node, it's an error because there is nothing to repeat
                if (nodes.len == 0) @compileError("Nothing to repeat before '*'");

                // Replace previous node with a repeat node
                nodes = nodes[0 .. nodes.len - 1] ++ &[_]ast.Node{
                    ast.Node.repeatNode(&nodes[nodes.len - 1], 0, null),
                };
            },
            '+' => {
                // If + becomes the first node, it's an error because there is nothing to repeat
                if (nodes.len == 0) @compileError("Nothing to repeat before '+'");

                nodes = nodes[0 .. nodes.len - 1] ++ &[_]ast.Node{
                    ast.Node.repeatNode(&nodes[nodes.len - 1], 1, null),
                };
            },
            '?' => {
                // If ? becomes the first node, it's an error because there is nothing to repeat
                if (nodes.len == 0) @compileError("Nothing to repeat before '?'");

                nodes = nodes[0 .. nodes.len - 1] ++ &[_]ast.Node{
                    ast.Node.repeatNode(&nodes[nodes.len - 1], 0, 1),
                };
            },
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

fn parseDigits(comptime cursor: *Cursor) usize {
    const digits = cursor.takeWhile(std.ascii.isDigit);
    if (digits.len == 0) {
        @compileError("Expected digits for repetition");
    }

    var result: usize = 0;
    for (digits) |d| {
        result = result * 10 + (d - '0');
    }
    return result;
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

        // Handle ranges (e.g. a-z)
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

const Repetition = struct {
    min: usize,
    max: ?usize,
};

fn parseRepetition(comptime cursor: *Cursor) Repetition {
    if (cursor.isOutOfBounds()) {
        @compileError("Unexpected end of pattern in character class");
    }

    // Handle repetition (e.g. {3}, {2,5})
    const min = parseDigits(cursor);
    if (cursor.isOutOfBounds()) {
        @compileError("Unexpected end of pattern in character class");
    }

    if (cursor.currChar() == ',') {
        cursor.skip(); // Skip ','
        // {2,} pattern means min 2, max unlimited
        if (cursor.isOutOfBounds() or cursor.currChar() == '}') {
            cursor.skip(); // Skip '}'
            return .{
                .min = min,
                .max = null,
            };
        }

        const max = parseDigits(cursor);

        // Expected: closing '}' after max digits
        if (cursor.isOutOfBounds() or cursor.currChar() != '}') {
            @compileError("Expected '}' after max digits in repetition");
        }

        cursor.skip(); // Skip '}'
        return .{ .min = min, .max = max };
    } else {
        // Expected: closing '}' after min digits
        if (cursor.isOutOfBounds() or cursor.currChar() != '}') {
            @compileError("Expected '}' after digits in repetition");
        }

        cursor.skip(); // Skip '}'
        return .{ .min = min, .max = min };
    }
    @compileError("Expected '}' to close repetition");
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

test "parse * repeat operator" {
    const node = comptime parse("a*");
    try std.testing.expect(node == .repeat);
    try std.testing.expectEqual(0, node.repeat.min);
    try std.testing.expect(node.repeat.max == null);
}

test "parse + repeat operator" {
    const node = comptime parse("a+");
    try std.testing.expect(node == .repeat);
    try std.testing.expectEqual(1, node.repeat.min);
    try std.testing.expect(node.repeat.max == null);
}

test "parse ? repeat operator" {
    const node = comptime parse("a?");
    try std.testing.expect(node == .repeat);
    try std.testing.expectEqual(0, node.repeat.min);
    try std.testing.expectEqual(1, node.repeat.max.?);
}

test "parse {3} repeat operator" {
    const node = comptime parse("a{3}");
    try std.testing.expect(node == .repeat);
    try std.testing.expectEqual(3, node.repeat.min);
    try std.testing.expectEqual(3, node.repeat.max.?);
}

test "parse {2,5} repeat operator" {
    const node = comptime parse("a{2,5}");
    try std.testing.expect(node == .repeat);
    try std.testing.expectEqual(2, node.repeat.min);
    try std.testing.expectEqual(5, node.repeat.max.?);
}

test "parse {2,} repeat operator" {
    const node = comptime parse("a{2,}");
    try std.testing.expect(node == .repeat);
    try std.testing.expectEqual(2, node.repeat.min);
    try std.testing.expect(node.repeat.max == null);
}
