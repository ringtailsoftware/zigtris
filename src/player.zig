// player tetronimo

const Stage = @import("stage.zig").Stage;
const std = @import("std");
const Debris = @import("debris.zig").Debris;
const time = @import("time.zig");

var prng: std.Random.Xoshiro256 = undefined;
var rand: std.Random = undefined;

pub const TetronimoData = [16]Stage.PixelStyle;

const TetI: TetronimoData = .{
    0, 2, 0, 0,
    0, 2, 0, 0,
    0, 2, 0, 0,
    0, 2, 0, 0,
};

const TetJ: TetronimoData = .{
    0, 0, 0, 0,
    0, 3, 0, 0,
    0, 3, 3, 3,
    0, 0, 0, 0,
};

const TetL: TetronimoData = .{
    0, 0, 0, 0,
    0, 0, 4, 0,
    4, 4, 4, 0,
    0, 0, 0, 0,
};

const TetO: TetronimoData = .{
    0, 0, 0, 0,
    0, 5, 5, 0,
    0, 5, 5, 0,
    0, 0, 0, 0,
};

const TetS: TetronimoData = .{
    0, 0, 0, 0,
    0, 6, 6, 0,
    6, 6, 0, 0,
    0, 0, 0, 0,
};

const TetZ: TetronimoData = .{
    0, 0, 0, 0,
    1, 1, 0, 0,
    0, 1, 1, 0,
    0, 0, 0, 0,
};

const TetT: TetronimoData = .{
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 2, 2, 2,
    0, 0, 2, 0,
};

pub const pieces = [7]TetronimoData{ TetI, TetJ, TetL, TetO, TetS, TetZ, TetT };

pub const Tetronimo = struct {
    const Self = @This();
    data: TetronimoData,

    pub fn paint(self: *Self, stage: *Stage, px: isize, py: isize) !void {
        // paint to Stage
        for (0..4) |y| {
            for (0..4) |x| {
                const ps = self.data[y * 4 + x];
                if (ps != 0) { // 0 is transparent
                    const xo = px + @as(isize, @intCast(x));
                    const yo = py + @as(isize, @intCast(y));

                    if (xo >= 0 and xo < Stage.STAGEW and yo >= 0 and yo < Stage.STAGEH) {
                        try stage.setPixel(@intCast(xo), @intCast(yo), ps);
                    }
                }
            }
        }
    }

    pub fn collidesDebris(self: *Self, px: isize, py: isize, debris: *Debris) bool {
        for (0..4) |y| {
            for (0..4) |x| {
                const ps = self.data[y * 4 + x];
                if (ps != 0) { // 0 is transparent
                    const xo = px + @as(isize, @intCast(x));
                    const yo = py + @as(isize, @intCast(y));

                    // check edges
                    if (xo < 0 or xo >= Stage.STAGEW or yo < 0 or yo >= Stage.STAGEH) {
                        return true;
                    }

                    if (!debris.isEmpty(@intCast(xo), @intCast(yo))) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
};

pub const Player = struct {
    const Self = @This();
    px: isize, // need to be signed because coord of top-left of tetronimo could be offscreen
    py: isize,
    timo: Tetronimo,
    nextTimo: Tetronimo,
    atRest: bool,
    atRestTime: u32,
    moveDownTime: u32,
    numLines: usize,
    score: usize,
    level: usize,

    pub fn init() !Self {
        prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        rand = prng.random();

        return Self{
            .px = Stage.STAGEW / 2,
            .py = 0,
            .timo = .{ .data = pieces[(rand.int(u8)) % pieces.len] },
            .nextTimo = .{ .data = pieces[(rand.int(u8)) % pieces.len] },
            .atRest = false,
            .atRestTime = 0,
            .moveDownTime = 0,
            .numLines = 0,
            .score = 0,
            .level = 1,
        };
    }

    pub fn setupTetronimo(self: *Self) void {
        self.px = Stage.STAGEW / 2;
        self.py = 0;
        self.timo = self.nextTimo;
        self.nextTimo = .{ .data = pieces[(rand.int(u8)) % pieces.len] };
        self.atRest = false;
        self.atRestTime = 0;
        self.moveDownTime = 0;
    }

    fn dropDelay(self: *Self) u32 {
        // decrease the drop delay based on number of lines completed
        // mubi library is hardcoded to 0.1Hz tick

        switch(self.level) {
            1 => return 500,
            2 => return 450,
            3 => return 400,
            4 => return 350,
            5 => return 300,
            6 => return 250,
            7 => return 200,
            8 => return 150,
            else => return 100,
        }
    }

    fn calcLevel(self: *Self) usize {
        return (self.numLines / 5) + 1;
    }

    pub fn advance(self: *Self, debris: *Debris) bool {
        if (time.millis() > self.moveDownTime + self.dropDelay()) { // try to move down
            if (self.moveDown(debris)) {
                self.moveDownTime = time.millis(); // update last move time, iff moved ok
            }
        }

        if (self.atRest) {
            if (self.atRest and time.millis() > self.atRestTime + 500) {
                // add tetronimo to debris
                self.debrisPaint(debris);
                const lines = debris.collapse();
                self.numLines += lines;
                self.score += lines * self.level * 10;  // multi-line bonus based on level
                self.score += 1;    // for dropping a piece
                self.level = self.calcLevel();
                self.setupTetronimo();
                if (self.timo.collidesDebris(self.px, self.py, debris)) {
                    return false;
                }
            }
        }
        return true;
    }

    pub fn debrisPaint(self: *Self, debris: *Debris) void {
        // paint Player to Debris
        for (0..4) |y| {
            for (0..4) |x| {
                const ps = self.timo.data[y * 4 + x];
                if (ps != 0) { // 0 is transparent
                    const xo = self.px + @as(isize, @intCast(x));
                    const yo = self.py + @as(isize, @intCast(y));

                    if (xo >= 0 and xo < Stage.STAGEW and yo >= 0 and yo < Stage.STAGEH) {
                        debris.setPixel(@intCast(xo), @intCast(yo), ps);
                    }
                }
            }
        }
    }

    pub fn paint(self: *Self, stage: *Stage) !void {
        try self.timo.paint(stage, self.px, self.py);
    }



    pub fn rotate(self: *Self, debris: *Debris) void {
        // Tetronimo is 4x4 grid and is indexed as in centre of diagram (single hex digit per index)
        // Rotating left or right will reorder indices
        // 37BF    0123    C840 
        // 26AE <- 4567 -> D951
        // 159D    89AB    EA62
        // 048C    CDEF    FB73

        const rotRightIndexMapping:[16]u8 = .{
            0xC, 0x8, 0x4, 0x0,
            0xD, 0x9, 0x5, 0x1,
            0xE, 0xA, 0x6, 0x2,
            0xF, 0xB, 0x7, 0x3,
        };

        var newTimo:Tetronimo = undefined;

        for (0..16) |i| {
            newTimo.data[i] = self.timo.data[rotRightIndexMapping[i]];
        }

        // only allow if new timo at px,py does not intersect debris (or game walls)
        if (!newTimo.collidesDebris(self.px, self.py, debris)) {
            self.timo = newTimo;
        } else {
            if (!newTimo.collidesDebris(self.px-1, self.py, debris)) { // kick left 1
                self.px -= 1;
                self.timo = newTimo;
            } else if (!newTimo.collidesDebris(self.px+1, self.py, debris)) {   // kick right 1
                self.px += 1;
                self.timo = newTimo;
            } else if (!newTimo.collidesDebris(self.px-2, self.py, debris)) {   // kick left 2
                self.px -= 2;
                self.timo = newTimo;
            } else if (!newTimo.collidesDebris(self.px+2, self.py, debris)) {   // kick right 2
                self.px += 2;
                self.timo = newTimo;
            }
        }
    }

    pub fn moveHorz(self: *Self, xd: i2, debris: *Debris) void {
        var newpx = self.px;

        // self.px could actually be negative as it's top left of tetronimo
        if (xd < 0) {
            newpx -= 1;
        }
        if (xd > 0) {
            newpx += 1;
        }

        if (!self.timo.collidesDebris(newpx, self.py, debris)) {
            self.px = newpx;
        }
    }

    pub fn moveDown(self: *Self, debris: *Debris) bool {
        var newpy = self.py;

        newpy += 1;

        if (!self.timo.collidesDebris(self.px, newpy, debris)) {
            self.py = newpy;
            self.atRest = false;
            return true; // moved down ok
        }
        if (!self.atRest) {
            self.atRest = true;
            self.atRestTime = time.millis();
        }
        return false; // unable to move down
    }
};
