#!/usr/bin/env python3
"""地面贴图后处理：去除 AI 水印 → 无缝化 → 输出 256x256 PNG。

用法:
    python3 tools/make_ground_tiles.py
输入: assets/ground/raw_grass.jpg, assets/ground/raw_tower.jpg
输出: assets/ground/grass.png, assets/ground/tower.png
"""
import os
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GROUND_DIR = os.path.join(ROOT, "assets", "ground")
OUT_SIZE = 256


def remove_watermark(img: Image.Image) -> Image.Image:
    """把右下角的水印区域用正上方同尺寸的石板内容覆盖掉。"""
    w, h = img.size
    # 水印位于右下角约 (0.80w, 0.88h) - (0.98w, 0.97h)
    x0, y0 = int(w * 0.80), int(h * 0.88)
    x1, y1 = int(w * 0.98), int(h * 0.97)
    if x1 - x0 < 10 or y1 - y0 < 10:
        return img
    region_w, region_h = x1 - x0, y1 - y0
    # 取正上方同尺寸内容，纵向延续石板纹理
    patch = img.crop((x0, y0 - region_h, x1, y0))
    # 区域完全覆盖，仅左边缘做羽化
    arr = np.full((region_h, region_w), 255, dtype=np.uint8)
    feather = max(4, region_w // 10)
    arr[:, :feather] = np.linspace(0, 255, feather, dtype=np.uint8)[None, :]
    img.paste(patch, (x0, y0), Image.fromarray(arr))
    return img


def make_seamless(img: Image.Image, size: int = OUT_SIZE) -> Image.Image:
    """offset 混合法生成无缝贴图。"""
    a = np.asarray(img.convert("RGB").resize((size, size), Image.LANCZOS)).astype(np.float32)
    h, w, _ = a.shape
    b = np.roll(a, (h // 2, w // 2), axis=(0, 1))

    ys = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]
    xs = np.linspace(0.0, 1.0, w, dtype=np.float32)[None, :]

    # 上半部分沿 x 方向混合，下半部分沿 y 方向混合，形成十字羽化
    ramp_x = np.clip(xs / 0.5, 0.0, 1.0)
    ramp_y = np.clip((1.0 - ys) / 0.5, 0.0, 1.0)
    mask = np.where(ys < 0.5, ramp_x, ramp_y).astype(np.float32)
    mask = np.clip(mask, 0.0, 1.0)
    mask = np.asarray(
        Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6)),
        dtype=np.float32,
    ) / 255.0
    out = a * (1.0 - mask[:, :, None]) + b * mask[:, :, None]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def process(src_name: str, dst_name: str) -> None:
    src_path = os.path.join(GROUND_DIR, src_name)
    dst_path = os.path.join(GROUND_DIR, dst_name)
    if not os.path.exists(src_path):
        print("skip (missing): %s" % src_name)
        return
    img = Image.open(src_path).convert("RGB")
    img = remove_watermark(img)
    out = make_seamless(img, OUT_SIZE)
    out.save(dst_path, "PNG")
    print("wrote %s (%dx%d)" % (dst_name, out.size[0], out.size[1]))


if __name__ == "__main__":
    process("raw_grass.jpg", "grass.png")
    process("raw_tower.jpg", "tower.png")
