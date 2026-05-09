const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    var buf: [4096]u8 = undefined;
    var fw: Io.File.Writer = .init(.stdout(), io, &buf);
    const out = &fw.interface;

    try out.print("Architecture : {s}\n", .{@tagName(builtin.cpu.arch)});
    try out.print("Compile-time : {s}\n", .{builtin.cpu.model.name});

    // /proc/cpuinfo is virtual: stat reports size 0, so force streaming mode
    // so the reader doesn't prematurely return EOF from a zero-size hint.
    const file = Io.Dir.openFileAbsolute(io, "/proc/cpuinfo", .{}) catch |err| {
        try out.print("Runtime      : (unavailable: {})\n", .{err});
        try out.flush();
        return;
    };
    defer file.close(io);
    var reader_buf: [4096]u8 = undefined;
    var file_reader = file.readerStreaming(io, &reader_buf);
    const content = try file_reader.interface.allocRemaining(arena, .unlimited);

    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "model name")) {
            if (std.mem.indexOf(u8, line, ": ")) |i| {
                try out.print("Runtime      : {s}\n", .{line[i + 2 ..]});
                break;
            }
        }
    }

    try out.flush();
}
