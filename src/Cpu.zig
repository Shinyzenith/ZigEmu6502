// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/Cpu.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Self = @This();
const std = @import("std");

const Memory = @import("Memory.zig");
const OpCodes = @import("op_codes.zig").OpCodes;

program_counter: u16 = undefined,
stack_pointer: u8 = undefined,
cycles: i32 = undefined,

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

pub fn tick(self: *Self) void {
    self.cycles -= 1;
}

pub fn reset(self: *Self, program_counter_addr: u16) void {
    self.program_counter = program_counter_addr;
    self.stack_pointer = 0x0;
    self.reg_A = 0;
    self.reg_X = 0;
    self.reg_Y = 0;
}

/// Set the required bits
fn LDA_set_bits(self: *Self) void {
    self.bit_Z = @intFromBool(self.reg_A == 0);
    self.bit_N = @as(u1, @truncate(self.reg_A & (1 << 7)));
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

pub fn execute(self: *Self, cycles: i32) void {
    self.cycles = cycles;

    while (self.cycles > 0) {
        const op_code = self.memory.fetch_data(u8);
        switch (@as(OpCodes, @enumFromInt(op_code))) {
            OpCodes.LDA_IM => {
                const val = self.memory.fetch_data(u8);
                self.reg_A = val;

                self.LDA_set_bits();
            },
            OpCodes.LDA_ABS => {
                const address = self.memory.fetch_data(u16);
                self.reg_A = self.memory.read_data(u8, address);

                self.LDA_set_bits();
            },
            OpCodes.LDA_ABS_X => {
                var address = self.memory.fetch_data(u16);
                address += self.reg_X;

                if (self.reg_X >= 0xFF) {
                    self.tick(); // Page boundary cross cycle!
                }

                self.reg_A = self.memory.read_data(u8, address);
            },
            OpCodes.LDA_IND_X => {
                var zero_page_addr = self.memory.fetch_data(u8);
                zero_page_addr += self.reg_X;

                self.tick(); // Adding the reg_X value consumes a cycle :)

                const effective_adddr = self.memory.read_data(u16, zero_page_addr);

                self.reg_A = self.memory.read_data(u8, effective_adddr);
            },
            OpCodes.LDA_IND_Y => {
                const zero_page_addr = self.memory.fetch_data(u8);
                var effective_addr = self.memory.read_data(u16, zero_page_addr);

                effective_addr += self.reg_Y;

                if (self.reg_Y >= 0xFF) {
                    self.tick(); // Page boundary cross cycle!
                }

                self.reg_A = self.memory.read_data(u8, effective_addr);
            },
            OpCodes.LDA_ABS_Y => {
                var address = self.memory.fetch_data(u16);
                address += self.reg_Y;

                if (self.reg_Y >= 0xFF) {
                    self.tick(); // Page boundary cross cycle!
                }

                self.reg_A = self.memory.read_data(u8, address);
            },
            OpCodes.LDA_ZP => {
                const address = self.memory.fetch_data(u8);
                self.reg_A = self.memory.read_data(u8, address);

                self.LDA_set_bits();
            },
            OpCodes.LDA_ZP_X => {
                var address = self.memory.fetch_data(u8);
                address +%= self.reg_X;
                address &= 0xFF;

                self.reg_A = self.memory.read_data(u8, address);

                self.tick();
                self.LDA_set_bits();
            },
            OpCodes.JSR_ABS => {
                // Stack pointer needs to be incremented here.
                const address = self.memory.fetch_data(u16);
                self.memory.write_data(self.program_counter - 1, self.stack_pointer);
                self.stack_pointer += 1;
                self.program_counter = address;
            },
            OpCodes.NOP => {
                self.program_counter += 1;
                self.tick();
            },
            else => {
                @panic("Opcode not handled");
            },
        }
    }
}
