// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/Cpu.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Self = @This();
const std = @import("std");

const Memory = @import("Memory.zig");
const OpCodes = @import("OpCodes.zig");

program_counter: u16 = undefined,
stack_pointer: u16 = undefined,
cycles: u32 = undefined,

memory: Memory = undefined,

reg_A: u8 = undefined, // Accumulator register
reg_X: u8 = undefined,
reg_Y: u8 = undefined,

bit_C: u1 = undefined, // Carry
bit_Z: u1 = undefined, // Zero
bit_I: u1 = undefined, // Interrupt
bit_D: u1 = undefined, // Decimal
bit_B: u1 = undefined, // Break
bit_U: u1 = undefined, // Unused
bit_V: u1 = undefined, // Overflow
bit_N: u1 = undefined, // Negative

pub fn reset(self: *Self, program_counter_addr: u16) void {
    self.program_counter = program_counter_addr;
    self.stack_pointer = 0x0100;
    self.reg_A = 0;
    self.reg_X = 0;
    self.reg_Y = 0;
}

pub fn execute(self: *Self, cycles: u32) void {
    self.cycles = cycles;

    while (self.cycles > 0) {
        const op_code = self.memory.fetch_opcode();
        switch (@intToEnum(OpCodes.codes, op_code)) {
            OpCodes.codes.LDA_IM => {
                const val = self.memory.fetch_opcode();
                self.reg_A = val;

                self.LDA_set_bits();
            },
            OpCodes.codes.LDA_ZP => {
                const address = self.memory.fetch_opcode();
                self.reg_A = self.memory.read_opcode(address);

                self.LDA_set_bits();
            },
            else => std.debug.print("OpCode: {d} not handled\n", .{op_code}),
        }
    }
}

pub fn print_internal_state(self: *Self) void {
    std.io.getStdOut().writer().print(
        "Carry={d} Zero={d} Interrupt={d} Decimal={d} Break={d} Overflow={d} Negative={d}\nAccumulator={d} X={d} Y={d}\n",
        .{
            self.bit_C, self.bit_Z, self.bit_I, self.bit_D, self.bit_B, self.bit_V, self.bit_N,
            self.reg_A, self.reg_X, self.reg_Y,
        },
    ) catch unreachable;
}

/// Set the required bits
fn LDA_set_bits(self: *Self) void {
    self.bit_Z = @boolToInt(self.reg_A == 0);
    self.bit_N = @truncate(u1, self.reg_A & (1 << 7));
}
