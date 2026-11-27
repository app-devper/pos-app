#!/usr/bin/env python3
"""Transparency for the icon renderer, with the standard library only.

QuickLook paints white wherever an SVG is transparent, so make-icons.sh renders
a shape twice, once on black and once on white, and this script recovers the
alpha channel from the difference.

  png_alpha.py matte <on-black.png> <on-white.png> <out.png>
  png_alpha.py range <file.png>      prints "<corner alpha> <min alpha> <max alpha>"
"""
import struct
import sys
import zlib

SIGNATURE = b"\x89PNG\r\n\x1a\n"
CHANNELS = {2: 3, 6: 4}  # colour type -> bytes per pixel (8-bit RGB / RGBA)


def _unfilter(kind, line, previous, bpp):
    for x in range(len(line)):
        left = line[x - bpp] if x >= bpp else 0
        up = previous[x]
        corner = previous[x - bpp] if x >= bpp else 0
        if kind == 1:
            predicted = left
        elif kind == 2:
            predicted = up
        elif kind == 3:
            predicted = (left + up) // 2
        elif kind == 4:
            pa, pb, pc = abs(up - corner), abs(left - corner), abs(left + up - 2 * corner)
            predicted = left if pa <= pb and pa <= pc else up if pb <= pc else corner
        else:
            return line
        line[x] = (line[x] + predicted) & 255
    return line


def read_png(path):
    """Returns (width, height, bytes per pixel, list of rows) of an 8-bit RGB(A) PNG."""
    data = open(path, "rb").read()
    if data[:8] != SIGNATURE:
        raise ValueError(f"{path} is not a PNG")
    position, compressed, header = 8, b"", None
    while position < len(data):
        length, kind = struct.unpack(">I4s", data[position:position + 8])
        chunk = data[position + 8:position + 8 + length]
        position += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", chunk)
        elif kind == b"IDAT":
            compressed += chunk
    width, height, depth, colour, _, _, interlace = header
    if depth != 8 or colour not in CHANNELS or interlace:
        raise ValueError(f"{path}: only 8-bit RGB or RGBA, not interlaced, is read")
    bpp = CHANNELS[colour]
    raw, stride, rows, previous, offset = zlib.decompress(compressed), width * bpp, [], None, 0
    previous = bytearray(stride)
    for _ in range(height):
        line = _unfilter(raw[offset], bytearray(raw[offset + 1:offset + 1 + stride]), previous, bpp)
        offset += 1 + stride
        rows.append(line)
        previous = line
    return width, height, bpp, rows


def write_rgba(path, width, height, rows):
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))

    raw = b"".join(b"\x00" + bytes(row) for row in rows)
    with open(path, "wb") as out:
        out.write(SIGNATURE)
        out.write(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
        out.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        out.write(chunk(b"IEND", b""))


def matte(on_black, on_white, out):
    width, height, bpp_black, black = read_png(on_black)
    width_white, height_white, bpp_white, white = read_png(on_white)
    if (width, height) != (width_white, height_white):
        raise ValueError("the two renders differ in size")
    rows = []
    for y in range(height):
        row = bytearray(width * 4)
        b_line, w_line = black[y], white[y]
        for x in range(width):
            b = b_line[x * bpp_black:x * bpp_black + 3]
            w = w_line[x * bpp_white:x * bpp_white + 3]
            # white render = colour*a + 255*(1-a); black render = colour*a
            alpha = 255 - max(w[0] - b[0], w[1] - b[1], w[2] - b[2], 0)
            if alpha:
                row[x * 4:x * 4 + 4] = bytes(min(255, c * 255 // alpha) for c in b) + bytes([alpha])
        rows.append(row)
    write_rgba(out, width, height, rows)


def alpha_range(path):
    width, height, bpp, rows = read_png(path)
    if bpp != 4:
        return 255, 255, 255
    alphas = [row[x * 4 + 3] for row in rows for x in range(width)]
    return rows[0][3], min(alphas), max(alphas)


def main(argv):
    if len(argv) == 5 and argv[1] == "matte":
        matte(argv[2], argv[3], argv[4])
    elif len(argv) == 3 and argv[1] == "range":
        print(*alpha_range(argv[2]))
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
