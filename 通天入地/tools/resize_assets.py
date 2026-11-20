#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把生成的素材统一缩放到目标尺寸（保持中心裁切为正方形）并转为 PNG。

用法：python3 tools/resize_assets.py --dir assets/icons/skill --size 256
"""
import argparse
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def strip_watermark(img: Image.Image) -> Image.Image:
    """抹除生成图右下角的「AI生成」水印：用其正上方的背景块覆盖。"""
    w, h = img.size
    x0 = int(w * 0.74)
    x1 = int(w * 0.995)
    y1 = int(h * 0.995)
    y0 = int(h * 0.86)
    box_h = y1 - y0
    src_y0 = max(0, y0 - box_h - int(h * 0.02))
    src = img.crop((x0, src_y0, x1, src_y0 + box_h))
    img.paste(src, (x0, y0))
    return img


def process(dir_rel: str, size: int) -> int:
    target = os.path.join(ROOT, dir_rel)
    if not os.path.isdir(target):
        print("skip missing dir %s" % dir_rel)
        return 0
    count = 0
    for name in sorted(os.listdir(target)):
        if not name.lower().endswith((".png", ".jpg", ".jpeg", ".webp")):
            continue
        path = os.path.join(target, name)
        try:
            img = Image.open(path).convert("RGBA")
        except Exception as exc:  # noqa: BLE001
            print("fail open %s: %s" % (path, exc))
            continue
        img = strip_watermark(img)
        w, h = img.size
        side = min(w, h)
        left = (w - side) // 2
        top = (h - side) // 2
        img = img.crop((left, top, left + side, top + side)).resize((size, size), Image.LANCZOS)
        out_path = os.path.splitext(path)[0] + ".png"
        img.save(out_path, "PNG", optimize=True)
        if out_path != path:
            os.remove(path)
            stale = path + ".import"
            if os.path.exists(stale):
                os.remove(stale)
        count += 1
    print("%s -> %d files at %dx%d" % (dir_rel, count, size, size))
    return count


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--size", type=int, default=256)
    args = ap.parse_args()
    process(args.dir, args.size)


if __name__ == "__main__":
    main()
