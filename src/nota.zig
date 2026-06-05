const std = @import("std");
const regex = @import("regex/mod.zig");

test {
    _ = @import("regex/parser.zig");
    std.testing.refAllDecls(@This());
}
