#!/usr/bin/env python3
"""Generates 8 store screenshots (1920x1200) for the Amazon listing.
Illustrative promo renders of the real UI. Run: python3 tools/make_screenshots.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "store", "screenshots")
W, H = 1920, 1200

PURPLE = (91, 84, 232)
INK = (59, 54, 99)
GREY = (107, 100, 142)
WHITE = (255, 255, 255)
BG_TOP = (255, 246, 233)
BG_BOT = (234, 243, 255)

EMOJI_FONT = "/usr/share/fonts/google-noto-emoji/NotoColorEmoji.ttf"
FONT_BOLD = "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf"


def font(size):
    return ImageFont.truetype(FONT_BOLD, size)


def emoji_img(char, px):
    """Render a color emoji (Noto CBDT only loads at size 109)."""
    f = ImageFont.truetype(EMOJI_FONT, 109)
    tile = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    d.text((10, 10), char, font=f, embedded_color=True)
    bbox = tile.getbbox()
    if bbox:
        tile = tile.crop(bbox)
    tile.thumbnail((px, px), Image.LANCZOS)
    return tile


def gradient(size, top, bottom):
    img = Image.new("RGB", size, top)
    d = ImageDraw.Draw(img)
    w, h = size
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(
            int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img


def base():
    img = gradient((W, H), BG_TOP, BG_BOT).convert("RGBA")
    d = ImageDraw.Draw(img)
    # floating dots
    for i in range(40):
        x = (i * 173) % W
        y = (i * 271) % H
        r = 4 + (i % 3) * 3
        d.ellipse([x, y, x + r, y + r], fill=(255, 255, 255, 120))
    return img


def card(d, xy, r=36, fill=WHITE, shadow=True):
    x0, y0, x1, y1 = xy
    if shadow:
        d.rounded_rectangle([x0 + 6, y0 + 10, x1 + 6, y1 + 10], r, fill=(0, 0, 0, 25))
    d.rounded_rectangle(xy, r, fill=fill)


def paste_emoji(img, char, cx, cy, px):
    e = emoji_img(char, px)
    img.paste(e, (int(cx - e.width / 2), int(cy - e.height / 2)), e)


def title_bar(img, game_emoji, game_title):
    d = ImageDraw.Draw(img)
    card(d, (60, 50, 700, 150), 40)
    paste_emoji(img, game_emoji, 130, 100, 64)
    d.text((180, 72), game_title, font=font(52), fill=INK)
    paste_emoji(img, "🚀", W - 130, 100, 84)


def answer_pad(img, options, cy):
    d = ImageDraw.Draw(img)
    n = len(options)
    bw = 150
    gap = 40
    total = n * bw + (n - 1) * gap
    x = (W - total) / 2
    for v in options:
        card(d, (x, cy, x + bw, cy + bw), 30)
        t = str(v)
        f = font(72)
        tw = d.textlength(t, font=f)
        d.text((x + (bw - tw) / 2, cy + 34), t, font=f, fill=INK)
        x += bw + gap


def stars_row(img, cx, cy, n, filled, px=44):
    for i in range(n):
        paste_emoji(img, "⭐" if i < filled else "⚪", cx + (i - n / 2) * (px + 8), cy, px)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.convert("RGB").save(os.path.join(OUT, name), quality=92)
    print("wrote", name)


def shot_hero():
    img = base()
    d = ImageDraw.Draw(img)
    paste_emoji(img, "🚀", 480, 430, 380)
    t = "Math Buddies"
    f = font(150)
    d.text((830, 300), t, font=f, fill=INK)
    d.text((836, 480), "Playful math adventures for little learners!",
           font=font(56), fill=GREY)
    d.text((836, 590), "8 worlds  •  Buddy talks  •  32 stickers",
           font=font(48), fill=PURPLE)
    for i, e in enumerate(["🍎", "✏️", "➕", "🔷", "🎨", "⚖️", "🫧", "🃏"]):
        paste_emoji(img, e, 140 + i * 235, 900, 110)
    stars_row(img, W / 2, 1060, 5, 5, 60)
    save(img, "01-hero.png")


def shot_map():
    img = base()
    d = ImageDraw.Draw(img)
    d.text((80, 60), "Adventure Map", font=font(72), fill=INK)
    games = [("🍎", "Counting"), ("✏️", "Trace"), ("➕", "Add"),
             ("🔷", "Shapes"), ("🎨", "Patterns"), ("⚖️", "Compare")]
    grads = [((255, 154, 139), (255, 106, 136)), ((255, 195, 160), (255, 175, 189)),
             ((86, 204, 242), (47, 128, 237)), ((161, 140, 209), (251, 194, 235)),
             ((250, 217, 97), (247, 107, 28)), ((67, 233, 123), (56, 178, 249))]
    for i, (e, name) in enumerate(games):
        left = i % 2 == 0
        cx = 560 if left else 1360
        cy = 260 + i * 160
        # dotted connector
        if i > 0:
            pcx = 560 if (i - 1) % 2 == 0 else 1360
            pcy = 260 + (i - 1) * 160
            for k in range(8):
                t = k / 7
                x = pcx + (cx - pcx) * t
                y = pcy + (cy - pcy) * t
                d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(185, 175, 255))
        g0, g1 = grads[i]
        for r in range(95, 0, -1):
            t = r / 95
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=tuple(
                int(g0[c] + (g1[c] - g0[c]) * (1 - t)) for c in range(3)))
        d.ellipse([cx - 95, cy - 95, cx + 95, cy + 95], outline=WHITE, width=8)
        paste_emoji(img, e, cx, cy, 90)
        tx = cx + (140 if left else -140)
        anchor = "lm" if left else "rm"
        d.text((tx, cy - 20), name, font=font(52), fill=INK, anchor=anchor)
    save(img, "02-adventure-map.png")


def shot_counting():
    img = base()
    title_bar(img, "🍎", "Counting — Farm World")
    stars_row(img, W - 400, 100, 12, 5)
    positions = [(500, 380), (760, 350), (1020, 390), (1280, 360),
                 (630, 620), (900, 640), (1160, 620)]
    for i, (x, y) in enumerate(positions):
        card(ImageDraw.Draw(img), (x - 85, y - 85, x + 85, y + 85), 28)
        paste_emoji(img, "🍎", x, y, 90)
        d = ImageDraw.Draw(img)
        d.ellipse([x + 40, y - 90, x + 92, y - 38], fill=(67, 233, 123))
        f = font(40)
        t = str(i + 1)
        d.text((x + 66 - d.textlength(t, font=f) / 2, y - 84), t, font=f, fill=WHITE)
    answer_pad(img, [6, 7, 8], 900)
    save(img, "03-counting.png")


def shot_tracing():
    img = base()
    title_bar(img, "✏️", "Trace Numbers — Space Station")
    d = ImageDraw.Draw(img)
    card(d, (560, 200, 1360, 940), 40)
    f = font(560)
    t = "4"
    tw = d.textlength(t, font=f)
    d.text(((W - tw) / 2, 260), t, font=f, fill=(59, 54, 99, 38))
    # rainbow stroke over the number
    pts = [(900, 420), (880, 520), (870, 640), (900, 760), (990, 780)]
    cols = [(255, 106, 136), (76, 201, 240), (124, 92, 255), (67, 233, 123)]
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i + 1]], fill=cols[i % 4], width=34)
        d.ellipse([pts[i + 1][0] - 17, pts[i + 1][1] - 17,
                   pts[i + 1][0] + 17, pts[i + 1][1] + 17], fill=cols[i % 4])
    for i, e in enumerate(["↩️", "↪️", "🧽", "✅"]):
        paste_emoji(img, e, 640 + i * 220, 1030, 84)
    save(img, "04-tracing.png")


def shot_jodtod():
    img = base()
    title_bar(img, "➕", "Add & Take Away — Ocean Bay")
    d = ImageDraw.Draw(img)
    card(d, (240, 300, 760, 720), 32)
    for i in range(3):
        paste_emoji(img, "🐠", 360 + (i % 2) * 140, 420 + (i // 2) * 140, 100)
    paste_emoji(img, "🐠", 500, 560, 100)
    paste_emoji(img, "➕", 960, 500, 110)
    card(d, (1160, 300, 1680, 720), 32)
    paste_emoji(img, "🐠", 1330, 430, 100)
    paste_emoji(img, "🐠", 1500, 560, 100)
    d.text((780, 780), "3 + 2 = ?", font=font(110), fill=INK)
    answer_pad(img, [4, 5, 6], 960)
    save(img, "05-add-subtract.png")


def shot_shapes():
    img = base()
    title_bar(img, "🔷", "Shapes — Shape Kingdom")
    d = ImageDraw.Draw(img)
    d.text((760, 200), "Find the star!", font=font(64), fill=INK)
    card(d, (810, 290, 1110, 590), 36)
    ghost = emoji_img("⭐", 200).convert("RGBA")
    ghost.putalpha(70)
    img.paste(ghost, (860, 340), ghost)
    for i, e in enumerate(["🔵", "🟥", "⭐", "❤️"]):
        x = 420 + i * 360
        card(d, (x - 110, 760, x + 110, 980), 30)
        paste_emoji(img, e, x, 870, 130)
    save(img, "06-shapes.png")


def shot_patterns():
    img = base()
    title_bar(img, "🎨", "Patterns — Jungle Jam")
    d = ImageDraw.Draw(img)
    d.text((720, 210), "What comes next?", font=font(64), fill=INK)
    seq = ["🦁", "🐵", "🦁", "🐵", "🦁", "❓"]
    for i, e in enumerate(seq):
        x = 300 + i * 250
        card(d, (x - 95, 380, x + 95, 570), 26)
        paste_emoji(img, e, x, 475, 110)
    for i, e in enumerate(["🐵", "🦁", "🐸"]):
        x = 640 + i * 320
        card(d, (x - 110, 760, x + 110, 980), 30)
        paste_emoji(img, e, x, 870, 130)
    save(img, "07-patterns.png")


def shot_stickers():
    img = gradient((W, H), (43, 37, 101), PURPLE).convert("RGBA")
    d = ImageDraw.Draw(img)
    d.text((80, 60), "My Space Scene 🌌", font=font(72), fill=WHITE)
    d.text((80, 170), "Decorate with the stickers you win!",
           font=font(44), fill=(200, 195, 255))
    scene = [("🐮", 400, 500), ("🚀", 700, 380), ("🐠", 1000, 520),
             ("👑", 1300, 420), ("🦁", 560, 750), ("🦕", 1150, 780),
             ("🪐", 1520, 640), ("🌟", 880, 680), ("🐙", 250, 800)]
    for e, x, y in scene:
        paste_emoji(img, e, x, y, 130)
    for i, e in enumerate(["🐮", "🥕", "🚀", "🐠", "👑", "🦁", "🦕", "🌺"]):
        x = 260 + i * 190
        card(d, (x - 75, 990, x + 75, 1140), 24)
        paste_emoji(img, e, x, 1065, 90)
    save(img, "08-sticker-scene.png")


def shot_bubbles():
    img = base()
    title_bar(img, "🫧", "Bubble Pop — Bubble Sky")
    stars_row(img, W - 400, 100, 10, 4)
    d = ImageDraw.Draw(img)
    d.text((640, 205), "Pop from 1 to 8!  Next: 3", font=font(58), fill=GREY)
    positions = [(420, 480), (760, 400), (1100, 470), (1440, 420),
                 (560, 780), (940, 750), (1300, 800), (1600, 740)]
    nums = [4, 1, 7, 2, 8, 3, 6, 5]
    for (x, y), n in zip(positions, nums):
        popped = n in (1, 2)
        r = 34 if popped else 88
        color = (200, 220, 255) if popped else (102, 166, 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=color, outline=WHITE, width=6)
        if not popped:
            f = font(74)
            t = str(n)
            d.text((x - d.textlength(t, font=f) / 2, y - 42), t, font=f, fill=WHITE)
    save(img, "09-bubbles.png")


def shot_memory():
    img = base()
    title_bar(img, "🃏", "Memory Match — Memory Meadow")
    stars_row(img, W - 400, 100, 6, 2)
    d = ImageDraw.Draw(img)
    cards = ["🦊", None, None, "🐼", None, "🦊", None, None, "🐼", None, None, None]
    for i, e in enumerate(cards):
        col = i % 4
        row = i // 4
        x = 400 + col * 300
        y = 240 + row * 300
        if e:
            card(d, (x, y, x + 220, y + 220), 28)
            paste_emoji(img, e, x + 110, y + 110, 120)
        else:
            card(d, (x, y, x + 220, y + 220), 28, fill=(240, 87, 108))
            paste_emoji(img, "✨", x + 110, y + 110, 90)
    save(img, "10-memory.png")


def main():
    shot_hero()
    shot_map()
    shot_counting()
    shot_tracing()
    shot_jodtod()
    shot_shapes()
    shot_patterns()
    shot_stickers()
    shot_bubbles()
    shot_memory()
    print("done ->", OUT)


if __name__ == "__main__":
    main()
