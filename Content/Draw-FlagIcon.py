# Draws the CTF Flag item's inventory icon in the style of the game's weapon-select icons: grey shaded line art on a
# transparent 256x256 canvas. Pure Python (no PIL), 4x4 supersampled.
import math, struct, zlib, sys
W = H = 256
SS = 4
PX = 70.0                      # pole centre
POLE_TOP, POLE_BOT, POLE_R = 34.0, 214.0, 4.5
FX0, FX1 = PX + POLE_R, 214.0  # flag cloth
FTOP, FBOT = 44.0, 124.0
OUT = 2.6                      # outline width

def wave(x):
    t = (x - FX0) / (FX1 - FX0)
    return math.sin(t * math.pi * 2.0) * 9.0 * t, t

def sample(x, y):
    """(grey, alpha) at a point, or None"""
    # finial ball
    d = math.hypot(x - PX, y - (POLE_TOP - 4))
    if d <= 7.5:
        if d >= 7.5 - OUT: return (40, 255)
        return (int(235 - 60 * max(0, (x - PX + 3) / 8)), 255)
    # pole
    if POLE_TOP <= y <= POLE_BOT and abs(x - PX) <= POLE_R:
        if abs(x - PX) >= POLE_R - OUT * 0.8 or y >= POLE_BOT - OUT: return (40, 255)
        return (int(225 - 70 * (x - PX + POLE_R) / (2 * POLE_R)), 255)
    # cloth
    if FX0 - 1 <= x <= FX1:
        dy, t = wave(x)
        top, bot = FTOP + dy, FBOT + dy - 6 * t
        if top <= y <= bot:
            # slope of the edge, so the outline keeps its width on the curves
            dy2, _ = wave(x + 0.5)
            k = math.sqrt(1 + ((dy2 - dy) / 0.5) ** 2)
            if (y - top) / k < OUT or (bot - y) / k < OUT or FX1 - x < OUT: return (40, 255)
            shade = math.cos(t * math.pi * 2.0 + 0.6)
            g = 222 + 26 * shade
            # a light fold line at each crest
            return (int(max(120, min(250, g))), 255)
    return None

rows = []
for py in range(H):
    row = bytearray([0])
    for px in range(W):
        r = a = 0.0
        for sy in range(SS):
            for sx in range(SS):
                s = sample(px + (sx + 0.5) / SS, py + (sy + 0.5) / SS)
                if s:
                    r += s[0]; a += 1
        n = SS * SS
        if a:
            g = int(r / a)
            row += bytes([g, g, g, int(255 * a / n)])
        else:
            row += bytes([0, 0, 0, 0])
    rows.append(bytes(row))

def chunk(t, d):
    return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) \
    + chunk(b'IDAT', zlib.compress(b''.join(rows), 9)) + chunk(b'IEND', b'')
open(sys.argv[1], 'wb').write(png)
