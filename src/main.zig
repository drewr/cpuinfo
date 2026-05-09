const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;

fn runtimeModel(arena: std.mem.Allocator, io: Io) ![]const u8 {
    switch (builtin.os.tag) {
        .linux => {
            const file = Io.Dir.openFileAbsolute(io, "/proc/cpuinfo", .{}) catch return "(unavailable)";
            defer file.close(io);
            var reader_buf: [4096]u8 = undefined;
            var file_reader = file.readerStreaming(io, &reader_buf);
            const content = try file_reader.interface.allocRemaining(arena, .unlimited);
            var lines = std.mem.splitScalar(u8, content, '\n');
            while (lines.next()) |line| {
                if (std.mem.startsWith(u8, line, "model name")) {
                    if (std.mem.indexOf(u8, line, ": ")) |i| return line[i + 2 ..];
                }
            }
            return "(not found)";
        },
        .macos => {
            var buf: [256]u8 = undefined;
            var len: usize = buf.len;
            const rc = std.posix.system.sysctlbyname("machdep.cpu.brand_string", &buf, &len, null, 0);
            if (std.posix.errno(rc) != .SUCCESS) return "(unavailable)";
            return try arena.dupe(u8, buf[0 .. len - 1]); // len includes null terminator
        },
        else => return "(unsupported OS)",
    }
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    var buf: [4096]u8 = undefined;
    var fw: Io.File.Writer = .init(.stdout(), io, &buf);
    const out = &fw.interface;

    try out.print("Architecture : {s}\n", .{@tagName(builtin.cpu.arch)});
    try out.print("Compile-time : {s}\n", .{builtin.cpu.model.name});
    try out.print("Cores        : {d}\n", .{try std.Thread.getCpuCount()});
    try out.print("Runtime      : {s}\n", .{try runtimeModel(arena, io)});

    try out.flush();
}
