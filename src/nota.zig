const std = @import("std");
const ast = @import("regex/ast.zig");

test {
    std.testing.refAllDecls(@This());
}
