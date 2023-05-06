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
const OpCodes = @import("OpCodes.zig").OpCodes;

pub fn main() !void {
    var cpu: Cpu = undefined;

    cpu.reset(0xFFFC);
    cpu.memory.reset();

    // Start - Little inline program
    cpu.memory.data[0xFFFC] = @enumToInt(OpCodes.JSR_ABS);
    cpu.memory.data[0xFFFD] = 0x42;
    cpu.memory.data[0xFFFE] = 0x42;
    cpu.memory.data[0x4242] = @enumToInt(OpCodes.LDA_IM);
    cpu.memory.data[0x4243] = 0x84;
    // End - Little inline program

    cpu.execute(9);
    cpu.print_internal_state();
}
