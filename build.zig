// SPDX-License-Identifier: BSD 2-Clause "Simplified" License
//
// build.zig
//
// Created by:	Aakash Sen Sharma, May 2023
// Copyright:	(C) 2023, Aakash Sen Sharma & Contributors

const std = @import("std");

pub fn build(builder: *std.build.Builder) void {
    const target = builder.standardTargetOptions(.{});
    const mode = builder.standardReleaseOptions();

    const exe = builder.addExecutable("main", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    // Run SubCMD
    const run_cmd = exe.run();
    run_cmd.step.dependOn(builder.getInstallStep());
    if (builder.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = builder.step("run", "Run the emulator");
    run_step.dependOn(&run_cmd.step);

    // Test SubCMD
    const exe_tests = builder.addTest("src/tests.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = builder.step("test", "Run tests");
    test_step.dependOn(&exe_tests.step);
}
