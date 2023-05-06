// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// src/OpCodes.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const Self = @This();

pub const OpCodes = enum(u16) {
    LDA_IM = 0xA9,
    LDA_ZP = 0xA5,
    LDA_ZP_X = 0xB5,
    LDA_ABS = 0xAD,
    LDA_ABS_X = 0xBD,
    LDA_ABS_Y = 0xB9,
    LDA_IND_X = 0xA1,
    LDA_IND_Y = 0xB1,

    JMP_ABS = 0x4C,
    JMP_IND = 0x6C,
    JSR_ABS = 0x20,

    NO_OP = 0xEA,
};
