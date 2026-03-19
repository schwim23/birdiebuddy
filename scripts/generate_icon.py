#!/usr/bin/env python3
"""
Generate BirdieBuddy app icon PNG files from scratch using Pillow.

Outputs:
  BirdieBuddy/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png  (1024×1024)

Usage:
  python3 scripts/generate_icon.py
"""

import math, os, sys
from PIL import Image, ImageDraw

# ── Brand colours ──────────────────────────────────────────────
EMERALD       = (46, 125, 50)
DARK_GREEN    = (27, 94, 32)
LIGHT_GREEN   = (67, 160, 71)
WHITE         = (255, 255, 255)
GOLD          = (255, 193, 7)

# ── Canvas ─────────────────────────────────────────────────────
S = 1024          # icon size
img = Image.new("RGB", (S, S), DARK_GREEN)
draw = ImageDraw.Draw(img)


# ── Helpers ────────────────────────────────────────────────────
def bezier_cubic(p0, p1, p2, p3, n=120):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**3*p0[0] + 3*u**2*t*p1[0] + 3*u*t**2*p2[0] + t**3*p3[0]
        y = u**3*p0[1] + 3*u**2*t*p1[1] + 3*u*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts

def bezier_quad(p0, p1, p2, n=80):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**2*p0[0] + 2*u*t*p1[0] + t**2*p2[0]
        y = u**2*p0[1] + 2*u*t*p1[1] + t**2*p2[1]
        pts.append((x, y))
    return pts

def flatten(list_of_lists):
    out = []
    for l in list_of_lists:
        out.extend(l)
    return out


# ── 1. Radial gradient background ─────────────────────────────
# Overlay concentric ellipses from dark centre to slightly lighter edge
for r in range(0, 520, 4):
    t = r / 520
    c = tuple(int(DARK_GREEN[i] + (EMERALD[i] - DARK_GREEN[i]) * t) for i in range(3))
    draw.ellipse([S//2 - r, S//2 - r, S//2 + r, S//2 + r], fill=c)


# ── 2. Bird silhouette ─────────────────────────────────────────
# All coords scaled for 1024×1024
# Bird faces right, centred slightly above middle.
#
# Anatomy:
#   body     – tilted ellipse
#   head     – circle
#   beak     – small triangle
#   tail     – forked polygon (left side)
#   wing     – large swept Bezier shape above the body

cx, cy = 530, 400          # body centre

# Body (rotated ellipse approximation via polygon)
bw, bh, angle = 200, 80, -15   # half-widths + tilt degrees
body_pts = []
for deg in range(0, 361, 5):
    rad = math.radians(deg)
    a = math.radians(angle)
    ex = bw * math.cos(rad)
    ey = bh * math.sin(rad)
    rx = cx + ex * math.cos(a) - ey * math.sin(a)
    ry = cy + ex * math.sin(a) + ey * math.cos(a)
    body_pts.append((rx, ry))
draw.polygon(body_pts, fill=WHITE)

# Head
hx, hy, hr = 700, 345, 72
draw.ellipse([hx-hr, hy-hr, hx+hr, hy+hr], fill=WHITE)

# Beak (triangle pointing right)
beak = [(hx+hr, hy-14), (hx+hr+80, hy+8), (hx+hr, hy+28)]
draw.polygon(beak, fill=WHITE)

# Eye (dark green on head)
draw.ellipse([730, 328, 758, 356], fill=DARK_GREEN)

# Tail fork (two prongs going left)
tail = [
    (cx - 178, cy - 22),   # tail root top
    (cx - 260, cy - 95),   # upper prong tip
    (cx - 232, cy - 45),   # upper prong inner
    (cx - 278, cy + 10),   # lower prong tip
    (cx - 178, cy + 22),   # tail root bottom
]
draw.polygon(tail, fill=WHITE)

# Wing – large swept shape above body
# Upper edge: from tail-root sweeping up and forward to head
wing_top = bezier_cubic(
    (cx - 140, cy - 50),   # near tail
    (cx - 80,  cy - 280),  # left control
    (cx + 80,  cy - 300),  # right control
    (cx + 160, cy - 110),  # near head
)
# Lower edge: tucked close to body line
wing_bot = bezier_cubic(
    (cx + 160, cy - 110),  # near head (same end)
    (cx + 80,  cy - 60),
    (cx - 40,  cy - 50),
    (cx - 140, cy - 50),   # back to start
)
wing_poly = wing_top + wing_bot
draw.polygon(wing_poly, fill=WHITE)

# Subtle wing highlight (lighter inner band)
wing_hi_top = bezier_quad(
    (cx - 80, cy - 80),
    (cx,      cy - 260),
    (cx + 120, cy - 130),
)
wing_hi_bot = bezier_quad(
    (cx + 120, cy - 130),
    (cx + 30,  cy - 70),
    (cx - 80,  cy - 80),
)
draw.polygon(wing_hi_top + wing_hi_bot, fill=(230, 255, 230))


# ── 3. Golf flag + pin ─────────────────────────────────────────
px, py_top, py_bot = 500, 560, 870   # pole x, top, base y
pole_w = 14

# Pole
draw.rounded_rectangle([px - pole_w//2, py_top, px + pole_w//2, py_bot],
                        radius=7, fill=WHITE)

# Flag triangle (gold)
flag_pts = [
    (px + pole_w//2,       py_top),
    (px + pole_w//2 + 160, py_top + 80),
    (px + pole_w//2,       py_top + 160),
]
draw.polygon(flag_pts, fill=GOLD)

# Gold flag highlight
flag_hi = [
    (px + pole_w//2,       py_top),
    (px + pole_w//2 + 100, py_top + 40),
    (px + pole_w//2,       py_top + 80),
]
draw.polygon(flag_hi, fill=(255, 214, 70))

# Cup / hole at base
draw.ellipse([px - 44, py_bot - 16, px + 44, py_bot + 16], fill=DARK_GREEN)
draw.ellipse([px - 34, py_bot - 10, px + 34, py_bot + 10], fill=(36, 100, 40))


# ── 4. Save ────────────────────────────────────────────────────
out_dir = os.path.join(
    os.path.dirname(__file__), "..",
    "BirdieBuddy", "Assets.xcassets", "AppIcon.appiconset"
)
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "AppIcon-1024.png")
img.save(out_path, "PNG")
print(f"Saved → {os.path.abspath(out_path)}")
