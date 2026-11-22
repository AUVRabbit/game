#!/usr/bin/env python3
# ============================================================
# postprocess_art.py — 把文生图产物裁成项目规格
#   icons      : assets/icons/skill/*.jpg -> 256x256 PNG（裁掉右下角水印）
#   portraits  : assets/portraits/*.jpg   -> 512x512 PNG
#   sprites    : assets/sprites/world/player_*.jpg -> 128x128 透明 PNG（洋红抠图）
# 用法：python3 tools/postprocess_art.py icons|portraits|sprites
# ============================================================

import os
import sys
import glob
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WATERMARK_CROP = 240  # 生成图底部水印区域高度（1920 图约 240px）


def _trim_watermark(im):
    w, h = im.size
    return im.crop((0, 0, w, max(1, h - WATERMARK_CROP)))


def _center_square(im):
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return im.crop((left, top, left + side, top + side))


def process_icons():
    src = os.path.join(ROOT, "assets", "icons", "skill")
    files = sorted(glob.glob(os.path.join(src, "*.jpg")))
    for path in files:
        im = Image.open(path).convert("RGBA")
        im = _center_square(_trim_watermark(im))
        im = im.resize((256, 256), Image.LANCZOS)
        out = os.path.splitext(path)[0] + ".png"
        im.save(out, optimize=True)
        os.remove(path)
        print("icon ->", os.path.basename(out))
    print("共处理 %d 个图标" % len(files))


def process_portraits():
    src = os.path.join(ROOT, "assets", "portraits")
    files = sorted(glob.glob(os.path.join(src, "*.jpg")))
    for path in files:
        im = Image.open(path).convert("RGBA")
        im = _center_square(_trim_watermark(im))
        im = im.resize((512, 512), Image.LANCZOS)
        out = os.path.splitext(path)[0] + ".png"
        im.save(out, optimize=True)
        os.remove(path)
        print("portrait ->", os.path.basename(out))
    print("共处理 %d 张立绘" % len(files))


def _key_magenta(im):
    im = _trim_watermark(im).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            dist = ((r - 255) ** 2 + g ** 2 + (b - 255) ** 2) ** 0.5
            if dist < 80:
                px[x, y] = (0, 0, 0, 0)
            elif dist < 160:
                alpha = int(255 * (dist - 80) / 80.0)
                # 去洋红边缘：把红蓝通道压到绿通道附近
                g2 = g
                r2 = min(r, max(g2 + 20, int(b * 0.6)))
                b2 = min(b, max(g2 + 20, int(r * 0.6)))
                px[x, y] = (r2, g2, b2, alpha)
    return im


def process_sprites():
    src = os.path.join(ROOT, "assets", "sprites", "world")
    files = sorted(glob.glob(os.path.join(src, "player_*.jpg")))
    for path in files:
        im = _key_magenta(Image.open(path))
        bbox = im.getbbox()
        if bbox:
            im = im.crop(bbox)
        side = max(im.size)
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.paste(im, ((side - im.size[0]) // 2, side - im.size[1]))
        canvas = canvas.resize((128, 128), Image.LANCZOS)
        out = os.path.splitext(path)[0] + ".png"
        canvas.save(out, optimize=True)
        os.remove(path)
        print("sprite ->", os.path.basename(out))
    print("共处理 %d 个世界精灵" % len(files))


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode == "icons":
        process_icons()
    elif mode == "portraits":
        process_portraits()
    elif mode == "sprites":
        process_sprites()
    else:
        print("用法：python3 tools/postprocess_art.py icons|portraits|sprites")
        sys.exit(1)


if __name__ == "__main__":
    main()
