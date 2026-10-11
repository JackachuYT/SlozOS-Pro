#!/usr/bin/env python3
"""SlozOS Pro wallpaper: soft translucent petals blooming from the centre.
Original artwork (procedural), CC-BY-SA-4.0. Renders light and dark variants.
    python3 make-wallpaper.py   ->  slozos-pro-light.jpg, slozos-pro-dark.jpg
"""
import math
import numpy as np
from PIL import Image, ImageFilter

W, H = 3840, 2160
S = 2  # supersampling for smooth edges is done by rendering at 1x then blurring

def lerp(a, b, t):
    return a + (b - a) * t

def render(dark):
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    # background: soft vertical wash
    if dark:
        top, bottom = np.array([10, 18, 38]), np.array([4, 8, 20])
    else:
        top, bottom = np.array([226, 236, 248]), np.array([244, 247, 252])
    t = (y / H)[..., None]
    img = top * (1 - t) + bottom * t

    cx, cy = W * 0.5, H * 0.66
    # back petals first (longer, paler), front petals last (shorter, deeper)
    layout = [(-62, 0.80, 0.50), (62, 0.80, 0.50), (-38, 0.92, 0.58), (38, 0.92, 0.58),
              (-14, 1.00, 0.66), (14, 1.00, 0.66), (-50, 0.62, 0.72), (50, 0.62, 0.72), (0, 0.78, 0.80)]
    for deg, scale, alpha in layout:
        ang = math.radians(-90 + deg)
        length, width = H * 0.64 * scale, H * 0.13 * scale
        dx, dy = x - cx, y - cy
        u = dx * math.cos(ang) + dy * math.sin(ang)          # along the petal
        v = -dx * math.sin(ang) + dy * math.cos(ang)         # across it
        k = np.clip(u / length, 0, 1)
        # pointed at both ends, widest just past the middle
        half = width * np.maximum(np.sin(np.pi * k), 0) ** 0.85 * (0.75 + 0.25 * k)
        edge = half - np.abs(v)
        inside = (u > 0) & (u < length)
        mask = np.where(inside, np.clip(edge / 3.0, 0, 1), 0)   # crisp, anti-aliased edge
        root, tip = (np.array([0, 66, 176]), np.array([96, 196, 255])) if not dark else \
                    (np.array([0, 52, 150]), np.array([64, 160, 250]))
        col = root * (1 - k[..., None]) + tip * k[..., None]
        # folded silk: one half of each petal catches the light
        side = np.clip(0.5 + v / (2 * np.maximum(half, 1)), 0, 1)
        col = col * (0.72 + 0.42 * side[..., None] ** 1.6)
        # a bright rim along the edge
        rim = np.exp(-np.maximum(edge, 0) / 6.0) * mask
        col = col + 70 * rim[..., None]
        a = (mask * alpha)[..., None]
        img = img * (1 - a) + col * a

    # glow behind the bloom
    r = np.sqrt((x - cx) ** 2 + ((y - cy) * 1.3) ** 2) / H
    glow = np.exp(-(r / 0.45) ** 2)[..., None]
    gcol = np.array([120, 180, 255]) if not dark else np.array([30, 90, 200])
    img = img * (1 - 0.25 * glow) + gcol * 0.25 * glow

    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    return out.filter(ImageFilter.GaussianBlur(0.6))

for name, dark in (("slozos-pro-light", False), ("slozos-pro-dark", True)):
    im = render(dark)
    im.save(f"{name}.jpg", quality=90, optimize=True, progressive=True)
    im.resize((960, 540), Image.LANCZOS).save(f"{name}-preview.png")
    print(name, im.size)
