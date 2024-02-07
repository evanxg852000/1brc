const std = @import("std");
const Allocator = std.mem.Allocator;

const Info = struct {
    min: f64,
    max: f64,
    mean: f64,
    sum: f64,
    count: f64,
};

const StringHashMap = std.StringHashMap(Info);

fn lessThan (_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

pub const Aggregator = struct {
    groups: StringHashMap,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Aggregator {
        return Aggregator {
            .groups = StringHashMap.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Aggregator) void {
        self.groups.deinit();
    }

    pub fn add(self: *Aggregator, city: []const u8, val: f64) !void {
        var entry = try self.groups.getOrPut(city);
        if (entry.found_existing) {
            if (entry.value_ptr.min > val) {
                entry.value_ptr.min = val;
            }
            if (entry.value_ptr.max < val) {
                entry.value_ptr.max = val;
            }
            entry.value_ptr.sum += val;
            entry.value_ptr.count += 1.0;
            entry.value_ptr.mean = entry.value_ptr.sum / entry.value_ptr.count;
        } else {
            entry.value_ptr.* = Info{
                .min = val,
                .max = val,
                .sum = val,
                .count = 1.0,
                .mean = 1.0,
            };
        }
    }

    pub fn display(self: *Aggregator, allocator: Allocator) void {
        var cities = std.ArrayList([]const u8).init(allocator);
        defer cities.deinit();
        cities.ensureTotalCapacity(self.groups.count()) catch unreachable;
        var iter = self.groups.keyIterator();
        while (iter.next()) |city| {
            cities.appendAssumeCapacity(city.*);
        }

        const sorted_cities = cities.toOwnedSlice() catch unreachable;
        defer allocator.free(sorted_cities);
        std.mem.sort([]const u8, sorted_cities, {}, lessThan);

        for(sorted_cities) |city| {
            const info = self.groups.get(city) orelse unreachable;
            std.debug.print("{s}={}/{}/{}\n", .{city, info.min, info.mean, info.max});
        }

    }
}; 

