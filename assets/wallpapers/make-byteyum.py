#!/usr/bin/env python3
"""SlozOS Pro "ByteYum" wallpapers: liquid-glass ribbons in pear greens and
gold. Original procedural artwork, CC-BY-SA-4.0.
    python3 make-byteyum.py  ->  byteyum-light.jpg, byteyum-dark.jpg
"""
import numpy as np
from PIL import Image, ImageFilter

W, H = 3840, 2160

def render(dark):
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    u, v = x / W, y / H
    if dark:
        top, bottom = np.array([6, 16, 12]), np.array([10, 30, 22])
    else:
        top, bottom = np.array([236, 244, 228]), np.array([250, 248, 236])
    img = top * (1 - v[..., None]) + bottom * v[..., None]

    # ribbons: (height at centre, slope, amplitude, wavelength, phase, thickness, colour A, colour B, alpha)
    ribbons = [
        (0.86, -0.30, 0.06, 1.7, 0.4, 0.26, (24, 84, 52),   (70, 150, 92),   0.95),
        (0.66, -0.42, 0.08, 1.4, 1.6, 0.24, (78, 140, 36),  (168, 206, 70),  0.90),
        (0.50, -0.50, 0.07, 1.2, 2.9, 0.18, (190, 150, 30), (252, 210, 96),  0.88),
        (0.98, -0.20, 0.05, 2.0, 3.6, 0.22, (40, 110, 70),  (120, 186, 120), 0.92),
    ]
    for cy, slope, amp, lam, ph, thick, ca, cb, alpha in ribbons:
        centre = cy + slope * (u - 0.5) + amp * np.sin(2 * np.pi * u / lam + ph)
        d = (v - centre) / thick                        # -1 (top edge) … 1 (bottom edge)
        mask = np.clip((1 - np.abs(d)) * thick * H / 2.5, 0, 1)   # crisp, anti-aliased edge
        k = np.clip((d + 1) / 2, 0, 1)
        col = np.array(ca) * (1 - k[..., None]) + np.array(cb) * k[..., None]
        # rounded, like a ribbon of glass: lit across the middle, darker at the edges
        shade = 0.70 + 0.42 * np.maximum(np.cos(np.clip(d, -1, 1) * np.pi / 2), 0) ** 0.8
        col = col * shade[..., None]
        # a thin bright rim along the top edge
        rim = np.exp(-((d + 0.96) / 0.025) ** 2)
        col = col + (255 - col) * 0.65 * rim[..., None]
        if dark:
            col = col * 0.78
        shadow = np.exp(-((d - 1.18) / 0.30) ** 2) * (1 - mask)
        img = img * (1 - (0.16 if not dark else 0.40) * shadow[..., None])
        a = (mask * alpha)[..., None]
        img = img * (1 - a) + col * a

    # gentle vignette
    r = np.sqrt((u - 0.5) ** 2 + (v - 0.45) ** 2)
    img = img * (1 - (0.10 if not dark else 0.30) * np.clip(r / 0.75, 0, 1) ** 2)[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.4))

for name, dark in (("byteyum-light", False), ("byteyum-dark", True)):
    im = render(dark)
    im.save(f"{name}.jpg", quality=90, optimize=True, progressive=True)
    im.resize((960, 540), Image.LANCZOS).save(f"{name}-preview.png")
    print(name)
