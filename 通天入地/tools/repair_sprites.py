#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""修复被误涂成洋红色的水印区域（用上方同背景色块覆盖）。

用法：python3 tools/repair_sprites.py --dir assets/sprites
"""
import argparse
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

KEY = (255, 0, 255)


def _is_magentaish(p):
    r, g, b = p[0], p[1], p[2]
    return r > 170 and b > 140 and g < r - 60 and g < b - 40


def repair(path: str) -> bool:
    img = Image.open(path).convert("RGB")
    w, h = img.size
    px = img.load()
    # 找出所有洋红像素的包围盒
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if _is_magentaish(px[x, y]):
                xs.append(x)
                ys.append(y)
    if not xs:
        return False
    x0, x1 = min(xs), max(xs) + 1
    y0, y1 = min(ys), max(ys) + 1
    # 从同一行左侧等高处横向取样再镜像覆盖，保证渐变背景过渡自然
    span = x1 - x0
    src_x1 = max(0, x0 - 2)
    src_x0 = max(0, src_x1 - span)
    patch = img.crop((src_x0, y0, src_x1, y1)).transpose(Image.FLIP_LEFT_RIGHT)
    img.paste(patch, (x0, y0))
    img.save(path, "PNG", optimize=True)
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    args = ap.parse_args()
    target = os.path.join(ROOT, args.dir)
    if not os.path.isdir(target):
        print("skip missing dir %s" % args.dir)
        return
    for name in sorted(os.listdir(target)):
        if not name.lower().endswith(".png"):
            continue
        path = os.path.join(target, name)
        if repair(path):
            print("repaired %s" % path)


if __name__ == "__main__":
    main()
