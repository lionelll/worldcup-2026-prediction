#!/usr/bin/env python3
"""Create reusable cover assets from the locally provided Group 3 reference."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "tmp/reference_renders/第3组-朴素贝叶斯算法在新闻分类中的应用-01.png"
ASSETS = ROOT / "assets"


def main():
    ASSETS.mkdir(exist_ok=True)
    reference = Image.open(REFERENCE).convert("RGBA")

    # Keep the complete PKU emblem, Chinese wordmark, and English wordmark.
    wordmark = reference.crop((225, 200, 765, 370))
    wordmark.save(ASSETS / "pku_group3_wordmark.png")

    # Remove only the near-white paper background so the exact reference
    # wordmark can sit cleanly over a textured cover image.
    transparent = wordmark.copy()
    pixels = []
    for red, green, blue, _ in transparent.getdata():
        distance = max(255 - red, 255 - green, 255 - blue)
        if distance <= 5:
            pixels.append((255, 255, 255, 0))
            continue
        alpha = 255 if distance >= 35 else round((distance - 5) / 30 * 255)
        pixels.append((red, green, blue, alpha))
    transparent.putdata(pixels)
    transparent.save(ASSETS / "pku_group3_wordmark-transparent.png")

    width, height = 1600, 250
    banner = Image.new("RGBA", (width, height), "white")
    draw = ImageDraw.Draw(banner)
    # Sampled from the dominant masthead color in the Group 3 reference cover.
    red = "#94070A"
    draw.polygon(
        [(0, 0), (width, 0), (width, 230), (width // 2, 160), (0, 230)],
        fill=red,
    )
    draw.line(
        [(0, 235), (width // 2, 165), (width, 235)],
        fill="#d5d5d5",
        width=2,
    )
    banner.save(ASSETS / "group3_cover_banner.png")


if __name__ == "__main__":
    main()
