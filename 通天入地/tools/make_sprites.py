#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把色键抠图（洋红底）转成带透明通道的世界精灵 PNG。

用法：
    python3 tools/make_sprites.py --dir assets/sprites/player --size 128
    python3 tools/make_sprites.py --dir assets/sprites/resource --size 128 --pad 0.06

处理流程：
1. 抹除右下角「AI生成」水印区域（洋红底直接覆盖）
2. 洋红 #FF00FF 色键抠除（带边缘羽化）
3. 裁剪掉全透明边框
4. 补边成正方形并缩放到目标尺寸
"""
import argparse
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

KEY = (255, 0, 255)


def _chroma_distance(p):
    """像素与洋红键色的距离，0 表示完全命中键色。"""
    return max(
        abs(p[0] - KEY[0]),
        max(abs(p[1] - KEY[1]), abs(p[2] - KEY[2])),
    )


def _is_magentaish(p):
    """洋红系（键色或水印的浅洋红描边）。"""
    r, g, b = p[0], p[1], p[2]
    return r > 170 and b > 140 and g < r - 60 and g < b - 40


def strip_watermark(img: Image.Image) -> Image.Image:
    """把右下角「AI生成」水印框区域直接刷成键色。"""
    w, h = img.size
    x0, x1 = int(w * 0.72), int(w * 0.998)
    y0, y1 = int(h * 0.855), int(h * 0.998)
    if x1 <= x0 or y1 <= y0:
        return img
    overlay = Image.new("RGB", (x1 - x0, y1 - y0), KEY)
    img.paste(overlay, (x0, y0))
    return img


def key_out(img: Image.Image) -> Image.Image:
    """洋红键色转透明；键色边缘做柔和过渡，避免硬锯齿。"""
    w, h = img.size
    src = img.convert("RGB")
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src_px = src.load()
    out_px = out.load()
    soft = 70.0
    for y in range(h):
        for x in range(w):
            p = src_px[x, y]
            if _is_magentaish(p):
                # 越接近键色越透明（键色本身 alpha=0），越远越不透明
                alpha = int(min(255.0, (max(p[0], p[1], p[2]) - 60) * 255.0 / soft))
                if alpha <= 0:
                    continue
                out_px[x, y] = (p[0], p[1], p[2], alpha)
            else:
                out_px[x, y] = (p[0], p[1], p[2], 255)
    return out


def trim(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    return img.crop(bbox)


def pad_square(img: Image.Image, size: int, pad_ratio: float) -> Image.Image:
    """把精灵补成正方形并留出 pad_ratio 的安全边距。"""
    w, h = img.size
    side = max(w, h)
    side = int(side * (1.0 + pad_ratio * 2.0))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas.resize((size, size), Image.LANCZOS)


def process(dir_rel: str, size: int, pad_ratio: float) -> int:
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
            img = Image.open(path).convert("RGB")
        except Exception as exc:  # noqa: BLE001
            print("fail open %s: %s" % (path, exc))
            continue
        img = strip_watermark(img)
        img = key_out(img)
        img = trim(img)
        if img.size[0] == 0 or img.size[1] == 0:
            print("empty after key out: %s" % path)
            continue
        img = pad_square(img, size, pad_ratio)
        out_path = os.path.splitext(path)[0] + ".png"
        img.save(out_path, "PNG", optimize=True)
        if out_path != path:
            os.remove(path)
            stale = path + ".import"
            if os.path.exists(stale):
                os.remove(stale)
        count += 1
    print("%s -> %d sprites at %dx%d" % (dir_rel, count, size, size))
    return count


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--size", type=int, default=128)
    ap.add_argument("--pad", type=float, default=0.06)
    args = ap.parse_args()
    process(args.dir, args.size, args.pad)


if __name__ == "__main__":
    main()
