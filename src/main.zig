// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/main.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Cpu = @import("Cpu.zig");
const OpCodes = @import("op_codes.zig").OpCodes;

pub fn main() !void {
    var cpu: Cpu = undefined;
    const initial_address = 0xFFFC;

    cpu.reset(initial_address);
    cpu.memory.reset();

    const jump_addr = 0x4243;
    const jump_addr_lsb = 0x43;
    const jump_addr_msb = 0x42;
    const data = 0x84;

    cpu.memory.data[initial_address] = @intFromEnum(OpCodes.JSR_ABS);
    cpu.memory.data[initial_address + 1] = jump_addr_lsb;
    cpu.memory.data[initial_address + 2] = jump_addr_msb;
    cpu.memory.data[jump_addr] = @intFromEnum(OpCodes.LDA_IM);
    cpu.memory.data[jump_addr + 1] = data;

    cpu.execute(9);
    cpu.print_internal_state();
}
