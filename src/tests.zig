// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/tests.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const std = @import("std");
const Cpu = @import("Cpu.zig");
const OpCodes = @import("OpCodes.zig").OpCodes;
const testing = std.testing;

const initial_address = 0xFFFC;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

test "Creating the CPU" {
    var cpu = try init_cpu();
    try testing.expectEqual(cpu.*.program_counter, initial_address);
}

test "JSR Absolute" {
    var cpu = try init_cpu();

    // Required Addresses
    const cycles = 9;
    const data = 0x84;
    const jump_addr = 0x4243;
    const jump_addr_lsb = 0x43;
    const jump_addr_msb = 0x42;

    // Jump Subroutine Absolute Instruction
    cpu.memory.data[initial_address] = @enumToInt(OpCodes.JSR_ABS);
    cpu.memory.data[initial_address + 1] = jump_addr_lsb;
    cpu.memory.data[initial_address + 2] = jump_addr_msb;

    // Load Accumulator Immediate Instruction
    cpu.memory.data[jump_addr] = @enumToInt(OpCodes.LDA_IM);
    cpu.memory.data[jump_addr + 1] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.reg_A, data);
}

fn init_cpu() !*Cpu {
    var cpu = try allocator.create(Cpu);
    cpu.reset(initial_address);
    cpu.*.memory.reset();

    return cpu;
}
