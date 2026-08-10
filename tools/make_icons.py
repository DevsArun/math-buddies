#!/usr/bin/env python3
"""Generates the Math Buddies launcher icon PNGs + store feature graphic.
Draws a friendly rocket with stars on the brand purple. Run once locally:
    python3 tools/make_icons.py
Outputs: android_icons/mipmap-*/ic_launcher.png, store/icon-512.png,
store/feature-graphic-1024x500.png
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PURPLE = (91, 84, 232, 255)
PURPLE_DARK = (62, 55, 176, 255)
WHITE = (255, 255, 255, 255)
YELLOW = (255, 197, 61, 255)
PINK = (255, 106, 136, 255)
STAR = (255, 226, 138, 255)


def draw_rocket(size):
    """Render the rocket icon at the given pixel size (square)."""
    S = 512
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Background: full-bleed purple with a soft diagonal feel.
    d.rectangle([0, 0, S, S], fill=PURPLE)
    d.polygon([(0, S), (S, S), (S, int(S * 0.55))], fill=PURPLE_DARK)

    def star(cx, cy, r, color):
        pts = []
        for i in range(10):
            ang = -math.pi / 2 + i * math.pi / 5
            rr = r if i % 2 == 0 else r * 0.45
            pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
        d.polygon(pts, fill=color)

    star(110, 130, 42, STAR)
    star(410, 92, 30, STAR)
    star(430, 300, 22, STAR)
    star(90, 330, 20, STAR)

    # Rocket body (rounded capsule via ellipse + rect).
    cx = S // 2
    top, bottom = 120, 360
    half = 62
    d.rounded_rectangle([cx - half, top, cx + half, bottom], radius=half, fill=WHITE)
    # Window.
    d.ellipse([cx - 34, 205, cx + 34, 273], fill=PURPLE)
    d.ellipse([cx - 24, 215, cx + 24, 263], fill=(124, 140, 255, 255))
    # Fins.
    d.polygon([(cx - half, 300), (cx - half - 44, 380), (cx - half, 350)], fill=YELLOW)
    d.polygon([(cx + half, 300), (cx + half + 44, 380), (cx + half, 350)], fill=YELLOW)
    # Flame.
    d.polygon([(cx - 28, bottom - 6), (cx + 28, bottom - 6), (cx, bottom + 78)], fill=PINK)
    d.polygon([(cx - 14, bottom - 6), (cx + 14, bottom - 6), (cx, bottom + 44)], fill=YELLOW)

    return img.resize((size, size), Image.LANCZOS)


def main():
    out_dir = os.path.join(ROOT, "android_icons")
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in densities.items():
        path = os.path.join(out_dir, folder)
        os.makedirs(path, exist_ok=True)
        draw_rocket(px).save(os.path.join(path, "ic_launcher.png"))
        print("wrote", path, px)

    os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)
    draw_rocket(512).save(os.path.join(ROOT, "store", "icon-512.png"))

    # Feature graphic 1024x500 for the store listing.
    fg = Image.new("RGBA", (1024, 500), PURPLE)
    d = ImageDraw.Draw(fg)
    d.rectangle([0, 380, 1024, 500], fill=PURPLE_DARK)
    rocket = draw_rocket(360)
    fg.paste(rocket, (70, 70), rocket)
    try:
        font_big = ImageFont.truetype(
            "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf", 96)
        font_small = ImageFont.truetype(
            "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf", 40)
    except Exception:  # noqa: BLE001
        font_big = ImageFont.load_default()
        font_small = ImageFont.load_default()
    d.text((470, 150), "Math Buddies", font=font_big, fill=WHITE)
    d.text((474, 280), "Playful math adventures", font=font_small, fill=STAR)
    fg.convert("RGB").save(os.path.join(ROOT, "store", "feature-graphic-1024x500.png"))
    print("wrote store graphics")


if __name__ == "__main__":
    main()
