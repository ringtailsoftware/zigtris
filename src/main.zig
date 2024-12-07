const std = @import("std");

const Display = @import("display.zig").Display;
const Stage = @import("stage.zig").Stage;
const Debris = @import("debris.zig").Debris;
const Player = @import("player.zig").Player;
const Decor = @import("decor.zig").Decor;

const io = std.io;

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;
const utils = mibu.utils;
const color = mibu.color;
const cursor = mibu.cursor;

const time = @import("time.zig");

// position of stage in display coords
const STAGE_OFF_X = 2;
const STAGE_OFF_Y = 1;

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    const reader = std.io.getStdIn();
    var gameOver = false;
    time.initTime();

    var display = try Display.init(writer, reader, true); // raw terminal
    display.cls();
    defer display.destroy(writer);

    var stage = try Stage.init();
    stage.cls();

    var debris = try Debris.init();
    debris.cls();
    debris.addRandom();

    var player = try Player.init();

    try display.paint(writer);

    var decor = try Decor.init();

    var lastTick: u32 = 0;

    while (!gameOver) {
        const next = try display.getEvent(reader);
        if (time.millis() >= lastTick + 100) { // 100ms tick (mubi operates at 0.1Hz)
            lastTick = time.millis();
            if (!player.advance(&debris)) {
                gameOver = true;
            }
        }

        switch (next) {
            .key => |k| switch (k) {
                .down => {
                    _ = player.moveDown(&debris);
                },
                .up => {
                    player.rotate(&debris);
                },
                .left => {
                    player.moveHorz(-1, &debris);
                },
                .right => {
                    player.moveHorz(1, &debris);
                },
                .char => |c| switch (c) {
                    'q' => break,
                    ' ' => player.dropDown(&debris),
                    else => {},
                },
                else => {},
            },
            else => {},
        }

        stage.cls();
        try debris.paint(&stage);
        try player.paint(&stage);
        try stage.paint(&display, STAGE_OFF_X, STAGE_OFF_Y);
        try decor.paint(&display, (STAGE_OFF_X + Stage.STAGEW) * 2 + 1, 1, player.level, player.numLines, player.score, player.nextTimo);
        try display.paint(writer);
    }
}
