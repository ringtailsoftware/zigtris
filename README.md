# Zigtris

A minimal terminal Tetris written in Zig. Tested with Zig 0.13.0

`zig build run`

Cursor keys to move, space to drop, `q` to quit.

![](demo.gif)

# Why?

This was a quick weekend project to get back into writing some Zig. I've never tried to implement Tetris, so it was a fun challenge.

Some notes for anyone looking at the code:

 - It's messy and unoptimised. I was working out how to do it while doing it (and trying to remember Zig syntax)
 - `Display` is a thin wrapper on top of the `mibu` terminal library, it provides a double buffered one pixel per character interface where it only redraws changed pixels on the buffer flip
 - `Stage` is the game stage and provides a square pixel interface on top of `Display` (by printing two chars for each pixel)
 - `Player` holds the `Tetronimo` shapes and movement logic
 - `Debris` holds the list of fallen blocks for hitchecking and completed line detection

# License

MIT

