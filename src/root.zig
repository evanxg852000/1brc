const std = @import("std");
const Allocator = std.mem.Allocator;

const Info = struct {
    min: f64,
    max: f64,
    mean: f64,
    sum: f64,
    count: f64,
};

// const StringHashMap = std.StringHashMap(Info);
const StringHashMap = std.ArrayHashMap(String, Info, StringContext, true);

fn lessThan (_: void, lhs: *String, rhs: *String) bool {
    return std.mem.lessThan(u8, lhs.data, rhs.data);
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
        var iter = self.groups.iterator();
        while(iter.next()) |entry| {
            entry.key_ptr.deinit();
        }
        self.groups.deinit();
    }

    pub fn add(self: *Aggregator, city_bytes: []const u8, val: f64) !void {
        const city = try String.new(self.allocator, city_bytes);
        var entry = try self.groups.getOrPut(city);
        if (entry.found_existing) {
            (&city).deinit();
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
        var cities = std.ArrayList(*String).init(allocator);
        defer cities.deinit();
        cities.ensureTotalCapacity(self.groups.count()) catch unreachable;
        var iter = self.groups.iterator();
        while (iter.next()) |entry| {
            cities.appendAssumeCapacity(entry.key_ptr);
        }

        const sorted_cities = cities.toOwnedSlice() catch unreachable;
        defer allocator.free(sorted_cities);
        std.mem.sort(*String, sorted_cities, {}, lessThan);

        for(sorted_cities) |city| {
            const info = self.groups.get(city.*) orelse unreachable;
            std.debug.print("{s}={}/{}/{}\n", .{city.data, info.min, info.mean, info.max});
        }

    }
}; 


const String = struct {
    data: []const u8,
    allocator: std.mem.Allocator,

    pub fn new(allocator: Allocator, str: [] const u8) !String {
        const data = try allocator.alloc(u8, str.len);
        @memcpy(data, str);
        return String{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: String) void {
        self.allocator.free(self.data);
    }
};

const StringContext = struct {
    pub fn hash(_: StringContext, key: String) u32 {
        var h = std.hash.Fnv1a_32.init();
        h.update(key.data);
        return h.final();
    }

    pub fn eql(_: StringContext, a: String, b: String, _: usize) bool {
        return std.mem.eql(u8, a.data, b.data);
    }
};
