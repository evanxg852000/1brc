const std = @import("std");
const Allocator = std.mem.Allocator;

const Info = struct {
    min: f64,
    max: f64,
    mean: f64,
    sum: f64,
    count: f64,
};

const String = struct {
    allocator: Allocator,
    data: [] const u8,

    fn init(allocator: Allocator, data: []const u8) !String {
        const buffer = try allocator.alloc(u8, data.len);
        @memcpy(buffer, data);
        return String {
            .allocator = allocator,
            .data = buffer,
        };
    }

    fn deinit(self: String) void {
        self.allocator.free(self.data);
    }
};

const StringHashMap = std.StringHashMap(Info);

// const StringHashMap = std.AutoHashMap([]const u8, Info);

fn lessThan (_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

pub const Aggregator = struct {
    groups: StringHashMap,
    dict: std.ArrayList(String),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Aggregator {
        return Aggregator {
            .groups = StringHashMap.init(allocator),
            .dict = std.ArrayList(String).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Aggregator) void {
        for(self.dict.items) |key| {
            key.deinit();
        }
        self.dict.deinit();
        self.groups.deinit();
    }

    pub fn add(self: *Aggregator, city: []const u8, val: f64) !void {
        const owned_city = try String.init(self.allocator, city);
        var entry = try self.groups.getOrPut(owned_city.data);
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
            owned_city.deinit();
        } else {
            try self.dict.append(owned_city);
            entry.value_ptr.* = Info{
                .min = val,
                .max = val,
                .sum = val,
                .count = 1.0,
                .mean = val,
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
            std.debug.print("{s}={d:.2}/{d:.2}/{d:.2}\n", .{city, info.min, info.mean, info.max});
        }

    }
}; 
