// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/main.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Self = @This();
const std = @import("std");

const Cpu = @import("Cpu.zig");
const Memory = @import("Memory.zig");
const OpCodes = @import("OpCodes.zig");

pub fn main() !void {
    var cpu: Cpu = undefined;

    cpu.reset(0xFFFC);
    cpu.memory.reset();

    // Start - Little inline program
    cpu.memory.data[0xFFFC] = @enumToInt(OpCodes.codes.LDA_ZP);
    cpu.memory.data[0xFFFD] = 0x00;
    cpu.memory.data[0x00] = 0x84;
    // End - Little inline program

    // ZeroPage LDA needs 3 clock cycles
    cpu.execute(3);

    cpu.print_internal_state();
}
