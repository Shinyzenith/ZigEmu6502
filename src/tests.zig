// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/tests.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const std = @import("std");
const Cpu = @import("Cpu.zig");
const OpCodes = @import("op_codes.zig").OpCodes;
const testing = std.testing;

const initial_address = 0xFFFC;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

test "CPU_INIT" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    try testing.expectEqual(cpu.*.program_counter, initial_address);
}

test "OpCode_JSR_ABS" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    // Required Addresses
    const cycles = 9;
    const data = 0x84;
    const jump_addr = 0x4243;
    const jump_addr_lsb = 0x43;
    const jump_addr_msb = 0x42;

    // Jump Subroutine Absolute Instruction
    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.JSR_ABS);
    cpu.memory.data[initial_address + 1] = jump_addr_lsb;
    cpu.memory.data[initial_address + 2] = jump_addr_msb;

    // Load Accumulator Immediate Instruction
    cpu.memory.data[jump_addr] = @intFromEnum(OpCodes.LDA_IM);
    cpu.memory.data[jump_addr + 1] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, data);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_IM" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    const cycles = 2;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_IM);
    cpu.memory.data[initial_address + 1] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, data);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ZP" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    const cycles = 3;
    const address = 0x42;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ZP);
    cpu.memory.data[initial_address + 1] = address;
    cpu.memory.data[address] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, data);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ZP_X_no_overflow" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    // Setting the X register;
    cpu.reg_X = 0x1;

    const cycles = 4;
    const address = 0x42;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ZP_X);
    cpu.memory.data[initial_address + 1] = address;
    cpu.memory.data[address + cpu.reg_X] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, data);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ZP_X_overflow" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    // Setting the X register;
    cpu.reg_X = 0xFF;

    const cycles = 4;
    const data = 0x84;

    const address = 0x80;
    const overflow_addr = 0x7F;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ZP_X);
    cpu.memory.data[initial_address + 1] = address;
    cpu.memory.data[overflow_addr] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, data);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_NOP" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    const cycles = 2;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.NOP);
    cpu.execute(cycles);

    // One PC increment due to fetch_opcode, next one due to NOP
    try testing.expectEqual(cpu.program_counter, initial_address + 2);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "CPU_NoTaskOn-0_Cycles" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    const cycles = 0;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
}

test "CPU_ExecuteMoreCycleRequiredByInst" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    const cycles = 1;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_IM);
    cpu.memory.data[initial_address + 1] = data;

    cpu.execute(cycles);

    // First one is accessing the cpu inst, second cycle is ticking for the LDA_IM :)
    try testing.expectEqual(cpu.cycles, -1);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_IM-Can_Set_Zero_Bit" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    // Putting garbage value to ensure bit is changed.
    cpu.reg_A = 0x44;

    const cycles = 2;
    const data = 0x0;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_IM);
    cpu.memory.data[initial_address + 1] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, 0x0);
    try testing.expectEqual(cpu.bit_Z, 1);
    try testing.expectEqual(cpu.bit_N, 0);
}

test "OpCode_LDA_ABS" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    const cycles = 4;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ABS);
    cpu.memory.data[initial_address + 1] = 0x80;
    cpu.memory.data[initial_address + 2] = 0x44; // Final addr: 0x4480 (little endian)
    cpu.memory.data[0x4480] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.cycles, 0);
    try testing.expectEqual(cpu.reg_A, data);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ABS_X" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_X = 1; // The offset :)

    const final_addr = 0x4481; // 0x4480 + cpu.reg_X
    const final_addr_lsb = 0x80;
    const final_addr_msb = 0x44;

    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ABS_X);
    cpu.memory.data[initial_address + 1] = final_addr_lsb;
    cpu.memory.data[initial_address + 2] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(4);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ABS-X_Page_cross" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_X = 0xFF; // The offset :)

    const final_addr = 0x4501; // 0x4402 + 0xFF  ( Crosses page boundary! )
    const final_addr_lsb = 0x02;
    const final_addr_msb = 0x44;

    const cycles = 5;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ABS_X);
    cpu.memory.data[initial_address + 1] = final_addr_lsb;
    cpu.memory.data[initial_address + 2] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ABS_Y" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_Y = 1; // The offset :)

    const final_addr = 0x4481; //0x4480 + cpu.reg_Y
    const final_addr_lsb = 0x80;
    const final_addr_msb = 0x44;

    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ABS_Y);
    cpu.memory.data[initial_address + 1] = final_addr_lsb;
    cpu.memory.data[initial_address + 2] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(4);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_ABS_Y-Page_cross" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_Y = 0xFF; // The offset :)

    const final_addr = 0x4501; // 0x4402 + 0xFF = 0x4501  ( Crosses page boundary! )

    const final_addr_lsb = 0x02;
    const final_addr_msb = 0x44;

    const cycles = 5;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_ABS_Y);
    cpu.memory.data[initial_address + 1] = final_addr_lsb;
    cpu.memory.data[initial_address + 2] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(cycles);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_IND_X" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_X = 0x04;

    const final_addr = 0x4402;
    const final_addr_lsb = 0x02;
    const final_addr_msb = 0x44;

    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_IND_X);
    cpu.memory.data[initial_address + 1] = 0x02;
    cpu.memory.data[0x0006] = final_addr_lsb; // 0x0006 = 0x02 + 0x04 (cpu.reg_X)
    cpu.memory.data[0x0007] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(6);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_IND_Y" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_Y = 0x04;

    const final_addr = 0x4406; // 0x4402 + 0x04;
    const final_addr_lsb = 0x02;
    const final_addr_msb = 0x44;

    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_IND_Y);
    cpu.memory.data[initial_address + 1] = 0x02;
    cpu.memory.data[0x0002] = final_addr_lsb;
    cpu.memory.data[0x0003] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(5);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

test "OpCode_LDA_IND_Y-Page_cross" {
    var cpu = try init_cpu();
    defer allocator.destroy(cpu);

    cpu.reg_Y = 0xFF;

    const final_addr = 0x4501; // 0x4402 + cpu.reg_Y;
    const final_addr_lsb = 0x02;
    const final_addr_msb = 0x44;

    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.LDA_IND_Y);
    cpu.memory.data[initial_address + 1] = 0x02;
    cpu.memory.data[0x0002] = final_addr_lsb;
    cpu.memory.data[0x0003] = final_addr_msb;
    cpu.memory.data[final_addr] = data;

    cpu.execute(6);

    try testing.expectEqual(cpu.reg_A, data);
    try testing.expectEqual(cpu.cycles, 0);
    try test_bits(cpu, 0, 0, 0, 0, 0, 0, 0);
}

fn test_bits(cpu: *Cpu, B: u1, C: u1, D: u1, I: u1, N: u1, V: u1, Z: u1) !void {
    try testing.expectEqual(cpu.bit_B, B);
    try testing.expectEqual(cpu.bit_C, C);
    try testing.expectEqual(cpu.bit_D, D);
    try testing.expectEqual(cpu.bit_I, I);
    try testing.expectEqual(cpu.bit_N, N);
    try testing.expectEqual(cpu.bit_V, V);
    try testing.expectEqual(cpu.bit_Z, Z);
}

fn init_cpu() !*Cpu {
    var cpu = try allocator.create(Cpu);
    cpu.reset(initial_address);
    cpu.*.memory.reset();

    return cpu;
}
