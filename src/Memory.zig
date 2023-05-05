// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/Memory.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Self = @This();
const std = @import("std");
const Cpu = @import("Cpu.zig");
const max_mem: usize = 1024 * 64; // 64 KiB of memory

data: [max_mem]u8 = undefined,
cpu: *Cpu = undefined,

pub fn reset(self: *Self) void {
    self.data = [_]u8{0} ** max_mem;
    self.cpu = @fieldParentPtr(Cpu, "memory", self);
}

pub fn fetch_opcode(self: *Self) u8 {
    if (self.cpu.program_counter >= max_mem) {
        _ = std.io.getStdOut().write(
            "Attempt to overflow the program counter past 64 KiB.",
        ) catch unreachable;
        std.os.exit(1);
    }

    const data = self.data[self.cpu.program_counter];
    self.cpu.program_counter += 1;
    self.cpu.cycles -= 1;

    return data;
}

pub fn read_opcode(self: *Self, address: u8) u8 {
    const data = self.data[address];
    self.cpu.cycles -= 1;

    return data;
}
