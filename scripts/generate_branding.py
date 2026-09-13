#!/usr/bin/env python3
"""Generate the app icon, adaptive foreground and splash mark.

Pure Python (zlib + struct), so the brand assets are reproducible from source
with no design tool or image library in the loop:

    python3 scripts/generate_branding.py

Outputs into assets/branding/:
    app_icon.png             1024² — rounded royal-blue tile + white wrench
    app_icon_foreground.png  1024² — glyph only, inside the adaptive safe zone
    splash_logo.png           512² — glyph only, for the blue splash screen
"""
import math
import pathlib
import struct
import zlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "branding"
OUT.mkdir(parents=True, exist_ok=True)

PRIMARY = (0x0A, 0x6C, 0xFF)
PRIMARY_DARK = (0x0A, 0x4F, 0xBF)
WHITE = (0xFF, 0xFF, 0xFF)

SS = 2  # supersampling factor per axis


def write_png(path: pathlib.Path, width: int, height: int, pixels: bytearray) -> None:
    """pixels is RGBA, row-major, len == width * height * 4."""
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # filter type 0 (None)
        raw.extend(pixels[y * stride:(y + 1) * stride])

    def chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def rounded_square(x: float, y: float, radius: float) -> bool:
    """x, y in [0, 1]. Rounded tile with corner `radius` (fraction of a side).

    Standard rounded-box distance: only the corner quadrant is measured
    radially; the straight side bands are inside whenever the other axis is.
    """
    dx = abs(x - 0.5) - (0.5 - radius)
    dy = abs(y - 0.5) - (0.5 - radius)
    return math.hypot(max(dx, 0.0), max(dy, 0.0)) <= radius


def wrench(x: float, y: float, scale: float = 1.0) -> bool:
    """A wrench mark: an open-jaw ring joined to a rounded handle.

    Coordinates are normalised to the tile; `scale` shrinks the glyph about the
    centre so the adaptive foreground stays inside Android's safe zone.
    """
    x = (x - 0.5) / scale + 0.5
    y = (y - 0.5) / scale + 0.5

    # Handle: capsule from lower-left to upper-right.
    ax, ay = 0.34, 0.70
    bx, by = 0.60, 0.44
    half_width = 0.075
    vx, vy = bx - ax, by - ay
    wx, wy = x - ax, y - ay
    t = max(0.0, min(1.0, (wx * vx + wy * vy) / (vx * vx + vy * vy)))
    if math.hypot(wx - t * vx, wy - t * vy) <= half_width:
        return True

    # Head: annulus with a wedge removed, opening away from the handle.
    cx, cy = 0.665, 0.335
    distance = math.hypot(x - cx, y - cy)
    if 0.105 <= distance <= 0.195:
        angle = math.degrees(math.atan2(cy - y, x - cx)) % 360
        # Jaw opening points up-right, opposite the handle.
        if not (12.0 <= angle <= 78.0):
            return True
    return False


def render(size: int, *, tile: bool, glyph_scale: float) -> bytearray:
    pixels = bytearray(size * size * 4)
    samples = SS * SS
    for py in range(size):
        for px in range(size):
            tile_hits = 0
            glyph_hits = 0
            for sy in range(SS):
                for sx in range(SS):
                    x = (px + (sx + 0.5) / SS) / size
                    y = (py + (sy + 0.5) / SS) / size
                    if tile and rounded_square(x, y, 0.22):
                        tile_hits += 1
                    if wrench(x, y, glyph_scale):
                        glyph_hits += 1

            index = (py * size + px) * 4
            glyph_alpha = glyph_hits / samples
            if tile:
                tile_alpha = tile_hits / samples
                # Diagonal gradient across the tile.
                mix = (px + py) / (2 * size)
                base = tuple(
                    round(PRIMARY[c] + (PRIMARY_DARK[c] - PRIMARY[c]) * mix)
                    for c in range(3)
                )
                colour = tuple(
                    round(base[c] + (WHITE[c] - base[c]) * glyph_alpha)
                    for c in range(3)
                )
                alpha = round(255 * tile_alpha)
            else:
                colour = WHITE
                alpha = round(255 * glyph_alpha)

            pixels[index] = colour[0]
            pixels[index + 1] = colour[1]
            pixels[index + 2] = colour[2]
            pixels[index + 3] = alpha
    return pixels


def main() -> None:
    jobs = [
        ("app_icon.png", 1024, True, 1.0),
        ("app_icon_foreground.png", 1024, False, 0.62),
        ("splash_logo.png", 512, False, 0.9),
    ]
    for name, size, tile, scale in jobs:
        write_png(OUT / name, size, size, render(size, tile=tile, glyph_scale=scale))
        print(f"{name}: {size}×{size}")


if __name__ == "__main__":
    main()
