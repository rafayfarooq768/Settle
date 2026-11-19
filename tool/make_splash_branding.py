"""Renders the splash-screen branding image ("Settle" in white Manrope Bold).

Android's splash API only accepts branding as an image, so this file is
generated from the bundled font rather than drawn by hand (BRAND.md §6).

Usage: python -I tool/make_splash_branding.py
Output: assets/icon/splash_branding.png (800 x 320 px = 200 x 80 dp at 4x,
the Android 12 branding image size).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "Manrope-Bold.ttf"
OUT = ROOT / "assets" / "icon" / "splash_branding.png"

WIDTH, HEIGHT = 800, 320  # 200 x 80 dp at xxxhdpi (4x)
FONT_SIZE = 128  # 32 dp
LETTER_SPACING = -0.03  # BRAND.md §2: -3%


def main() -> None:
    font = ImageFont.truetype(str(FONT), FONT_SIZE)
    text = "Settle"
    spacing = LETTER_SPACING * FONT_SIZE

    # Measure with letter spacing applied.
    advances = [font.getlength(ch) for ch in text]
    total = sum(advances) + spacing * (len(text) - 1)
    ascent, descent = font.getmetrics()

    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    x = (WIDTH - total) / 2
    y = (HEIGHT - (ascent + descent)) / 2
    for ch, advance in zip(text, advances):
        draw.text((x, y), ch, font=font, fill=(255, 255, 255, 255))
        x += advance + spacing

    image.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
