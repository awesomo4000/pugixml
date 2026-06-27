//
// test program to parse xml file and record elapsed time
//

const std = @import("std");
const pugixml = @import("pugixml");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const prog = std.fs.path.basename(args[0]);

    if (args.len <= 1) {
        std.debug.print("Usage: {s} filename\n", .{prog});
        std.process.exit(1);
    }

    const filename = args[1];

    const io = init.io;
    const t_start = std.Io.Timestamp.now(io, .awake);

    var doc = pugixml.Doc.init();
    defer doc.deinit();

    const result = doc.loadFile(filename);
    const t_end = std.Io.Timestamp.now(io, .awake);
    const t_elapsed: f64 = @floatFromInt(t_end.nanoseconds - t_start.nanoseconds);
    const millis: f64 = t_elapsed / std.time.ns_per_ms;

    //const description = "--foo--"; // result.description

    std.debug.print(
        "{s}: {s}.\nElapsed time: {d:.3}ms.\n",
        .{ args[1], result.description, millis },
    );
    // doc.walkTree();
}
