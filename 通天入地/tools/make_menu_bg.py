#!/usr/bin/env python3
"""主菜单背景后处理：去水印 → 压暗中部 → 裁切到 16:9 → 输出 PNG。

用法:
    python3 tools/make_menu_bg.py
输入: assets/ui/menu_bg_raw.jpg
输出: assets/ui/menu_bg.png
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI_DIR = os.path.join(ROOT, "assets", "ui")
OUT_SIZE = (1920, 1080)


def crop_away_watermark(img: Image.Image) -> Image.Image:
    """裁掉右下角"AI生成"水印所在的边缘条带。

    水印位于画面最右下角的平坦雾气区，裁掉约 12% 宽 / 13% 高的边缘不会破坏
    主体构图（通天塔与左侧塔体都在保留区内）。
    """
    w, h = img.size
    crop_w = int(w * 0.875)
    crop_h = int(h * 0.865)
    # 保持 16:9
    target = 16.0 / 9.0
    if crop_w / crop_h > target:
        crop_h = int(crop_w / target)
    else:
        crop_w = int(crop_h * target)
    return img.crop((0, 0, crop_w, crop_h))


def darken_center(img: Image.Image, strength: float = 0.55) -> Image.Image:
    """中部压暗，保证标题与按钮文字可读。"""
    arr = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w, _ = arr.shape
    ys = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]
    xs = np.linspace(0.0, 1.0, w, dtype=np.float32)[None, :]
    # 椭圆中心区最暗
    d = np.sqrt(((xs - 0.5) / 0.42) ** 2 + ((ys - 0.5) / 0.52) ** 2)
    factor = 1.0 - strength * np.clip(1.6 - d * 1.6, 0.0, 1.0)
    out = arr * factor[:, :, None]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def process() -> None:
    src = os.path.join(UI_DIR, "menu_bg_raw.jpg")
    dst = os.path.join(UI_DIR, "menu_bg.png")
    if not os.path.exists(src):
        print("skip (missing): %s" % src)
        return
    img = Image.open(src).convert("RGB")
    img = crop_away_watermark(img)
    img = img.resize(OUT_SIZE, Image.LANCZOS)
    img = darken_center(img)
    img.save(dst, "PNG", optimize=True)
    print("wrote %s (%dx%d)" % (os.path.basename(dst), img.size[0], img.size[1]))


if __name__ == "__main__":
    process()
