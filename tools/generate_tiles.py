"""Generate prototype tile atlas for inkTD (run once: python tools/generate_tiles.py)."""
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    raise SystemExit("Install Pillow: pip install pillow")

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)

CELL = 16
COLORS = {
    "wall": (28, 24, 32),
    "damage": (200, 55, 45),
    "poison": (55, 170, 75),
    "slow": (55, 120, 210),
    "floor": (0, 0, 0, 0),
}


def glow_cell(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple, glow: tuple) -> None:
    draw.rectangle((x + 1, y + 1, x + CELL - 2, y + CELL - 2), fill=glow)
    draw.rectangle((x + 3, y + 3, x + CELL - 4, y + CELL - 4), fill=color)


def make_atlas() -> None:
    names = ["floor", "wall", "damage", "poison", "slow"]
    img = Image.new("RGBA", (CELL * len(names), CELL), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    glows = {
        "wall": (60, 50, 80),
        "damage": (255, 100, 80),
        "poison": (100, 255, 120),
        "slow": (100, 180, 255),
    }
    for i, name in enumerate(names):
        x = i * CELL
        if name == "floor":
            draw.rectangle((x, 0, x + CELL - 1, CELL - 1), fill=(0, 0, 0, 0))
        else:
            glow_cell(draw, x, 0, COLORS[name], glows[name])
    img.save(OUT / "ink_atlas.png")
    print(f"Wrote {OUT / 'ink_atlas.png'}")


if __name__ == "__main__":
    make_atlas()
