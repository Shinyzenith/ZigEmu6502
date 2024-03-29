// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/Memory.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Self = @This();
const std = @import("std");
const mem = std.mem;
const Cpu = @import("Cpu.zig");
const OpCodes = @import("op_codes.zig").OpCodes;
const max_mem: usize = 1024 * 64; // 64 KiB of memory

data: [max_mem]u8 = undefined,
cpu: *Cpu = undefined,

pub fn reset(self: *Self) void {
    // Fill the entire memory with NOP (no-op) opcode.
    @memset(&self.data, @intFromEnum(OpCodes.NOP));
    self.cpu = @fieldParentPtr(Cpu, "memory", self);
}

/// Depletes 1 cycle for u8, 2 cycles for u16
pub fn fetch_data(self: *Self, comptime T: type) T {
    if (self.cpu.program_counter >= max_mem) {
        _ = std.io.getStdOut().write(
            "Attempt to overflow the program counter past 64 KiB.",
        ) catch unreachable;
        std.os.exit(1);
    }

    var data: T = self.data[self.cpu.program_counter];

    self.cpu.program_counter += 1;
    self.cpu.tick();

    if (T == u16) {
        data |= (@as(T, @intCast(self.data[self.cpu.program_counter])) << 8);
        data = mem.littleToNative(T, data); //NOTE: Do we need to do this? What if the host system in big endian. That should crash as 6502 is little endian.

        self.cpu.program_counter += 1;
        self.cpu.tick();
    } else if (T != u8) {
        _ = std.io.getStdOut().writer().print(
            "{s} Not implemented for fetch_opcode",
            .{@typeName(T)},
        ) catch unreachable;
        std.os.exit(1);
    }

    return data;
}

pub fn read_data(self: *Self, comptime T: type, address: u16) T {
    if (T == u8) {
        return self._read_data(address);
    } else if (T == u16) {
        var lsb = self._read_data(address);
        const msb = self._read_data(address + 1);

        return lsb | (@as(T, @intCast(msb)) << 8);
    }
}

fn _read_data(self: *Self, address: u16) u8 {
    if (address >= max_mem) {
        _ = std.io.getStdOut().write("Address out of bounds (64 KiB) max.") catch unreachable;
        std.os.exit(1);
    }

    const data = self.data[address];
    self.cpu.tick();

    return data;
}

pub fn write_data(
    self: *Self,
    value: u16,
    address: u32,
) void {
    self.data[address] = @as(u8, @intCast(value & 0xFF));
    self.data[address + 1] = @as(u8, @intCast((value >> 8)));

    // Tick twice.
    comptime var i = 1;
    inline while (i <= 2) : (i += 1)
        self.cpu.tick();
}
