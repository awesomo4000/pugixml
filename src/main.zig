//
// test program to parse xml file and record elapsed time
//

const std = @import("std");
const pugixml = @import("pugixml");

pub fn main() !void {
    var gpa =
        std.heap.GeneralPurposeAllocator(.{}){};

    defer if (gpa.deinit() == .leak) {
        std.debug.panic("leaks detected", .{});
    };
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    const prog = std.fs.path.basename(args[0]);

    defer std.process.argsFree(allocator, args);

    if (args.len <= 1) {
        std.debug.print("Usage: {s} filename\n", .{prog});
        std.process.exit(1);
    }

    const filename = args[1];

    const t_start = try std.time.Instant.now();

    // Do the load and parse
    // const result = doc.loadFile(args[1]);
    //

    //const file = try std.fs.cwd().openFile(filename, .{});
    //     .mode = .read_write,
    // });
    //defer file.close();

    //const md = try file.metadata();
    //std.debug.print("{d}\n", .{md.size()});

    // const buffer = try std.posix.mmap(
    //     null,
    //     md.size(),
    //     std.posix.PROT.READ | std.posix.PROT.WRITE,
    //     .{ .TYPE = .SHARED },
    //     file.handle,
    //     0,
    // );
    // defer std.posix.munmap(buffer);

    var doc = pugixml.Doc.init();
    defer doc.deinit();

    // const buffer = try std.fs.cwd().readFileAlloc(
    //     allocator,
    //     filename,
    //     std.math.maxInt(usize),
    // );

    //const result = doc.loadBufferInplace(buffer);

    const result = doc.loadFile(filename);
    const t_end = try std.time.Instant.now();
    const t_elapsed: f64 = @floatFromInt(t_end.since(t_start));
    const millis: f64 = t_elapsed / std.time.ns_per_ms;

    //const description = "--foo--"; // result.description

    std.debug.print(
        "{s}: {s}.\nElapsed time: {d:.3}ms.\n",
        .{ args[1], result.description, millis },
    );
    // doc.walkTree();
}
