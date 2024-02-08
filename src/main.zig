const std = @import("std");

const Aggregator = @import("./root.zig").Aggregator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer  _ = gpa.deinit();
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile("weather_stations.csv", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var aggregator = Aggregator.init(allocator);
    defer aggregator.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.split(u8, line, ";");

        const city = it.next().? ;
        const value = try std.fmt.parseFloat(f64, it.next().?);

        // std.debug.print("{s} {d}\n", .{ city, value });
        try aggregator.add(city, value);
    }

    aggregator.display(allocator);
}

