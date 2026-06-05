const std = @import("std");
const ast = @import("ast.zig");

const State = struct {
    input: []const u8,
    curr: usize,
};

pub fn parse(comptime pattern: []const u8) ast.Node {
    comptime var state = State{
        .input = pattern,
        .curr = 0,
    };
    comptime var nodes: []const ast.Node = &.{};
    // Reading each character of the `pattern`
    while (state.curr < state.input.len) {
        const c = state.input[state.curr];
        state.curr += 1;

        // Escape sequences
        if (c == '\\') {
            if (state.curr >= state.input.len) {
                @compileError("Unexpected end of pattern after '\\'");
            }
            const next = state.input[state.curr];
            state.curr += 1;
            switch (next) {
                't' => nodes = nodes ++ &[_]ast.Node{.{ .literal = '\t' }},
                'n' => nodes = nodes ++ &[_]ast.Node{.{ .literal = '\n' }},
                'r' => nodes = nodes ++ &[_]ast.Node{.{ .literal = '\r' }},
                '\\' => nodes = nodes ++ &[_]ast.Node{.{ .literal = '\\' }},
                'w' => nodes = nodes ++ &[_]ast.Node{.{ .char_class = ast.CharClass{
                    .ranges = &[_]ast.Range{
                        .{ .start = 'a', .end = 'z' },
                        .{ .start = 'A', .end = 'Z' },
                        .{ .start = '0', .end = '9' },
                        .{ .start = '_', .end = '_' },
                    },
                    .negated = false,
                } }},
                'd' => nodes = nodes ++ &[_]ast.Node{.{ .char_class = ast.CharClass{
                    .ranges = &[_]ast.Range{
                        .{ .start = '0', .end = '9' },
                    },
                    .negated = false,
                } }},
                's' => nodes = nodes ++ &[_]ast.Node{.{ .char_class = ast.CharClass{
                    .ranges = &[_]ast.Range{
                        .{ .start = ' ', .end = ' ' },
                        .{ .start = '\t', .end = '\t' },
                        .{ .start = '\n', .end = '\n' },
                        .{ .start = '\r', .end = '\r' },
                    },
                    .negated = false,
                } }},
                else => @compileError("Unsupported escape sequence"),
            }
        } else {
            nodes = nodes ++ &[_]ast.Node{.{ .literal = c }};
        }
    }

    return switch (nodes.len) {
        0 => @compileError("Empty pattern is not supported"),
        1 => nodes[0],
        else => ast.Node{ .concat = nodes },
    };
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
