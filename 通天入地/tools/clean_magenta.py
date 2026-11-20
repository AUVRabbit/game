#!/usr/bin/env python3
"""清理个别世界精灵里的洋红色抠图残留。

AI 生成图以洋红为键色，少量主体边缘会被染成洋红。这里只处理肉眼明显是
残留的两张贴图，其余贴图保留朋克霓虹洋红装饰。

- npc_merchant：商人本体被一圈洋红花环淹没 → 裁出人物本体并重新居中放大；
- block_fence：栅栏缝隙里透出洋红底 → 挖成透明缝隙。

用法：
    python3 tools/clean_magenta.py
"""
import os

import cv2
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORLD_DIR = os.path.join(ROOT, "assets", "sprites", "world")

CANVAS = 128
MERCHANT_BOX = (30, 2, 78, 82)  # 人物本体包围盒（128x128 源图坐标）


def pink_mask(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    bright = rgb.mean(axis=2)
    return (alpha > 10) & (r - g > 50) & (b - g > 30) & (bright > 90)


def rebuild_merchant(path: str) -> None:
    img = Image.open(path).convert("RGBA")
    crop = img.crop(MERCHANT_BOX)
    arr = np.asarray(crop).astype(int)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    alpha = alpha.copy()
    alpha[pink_mask(rgb, alpha)] = 0
    # 只保留人物本体（最大连通域），丢弃花环碎屑
    solid = (alpha > 20).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(solid, 8)
    if count > 1:
        best = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        alpha = np.where(labels == best, alpha, 0).astype(int)
    crop = Image.fromarray(
        np.dstack([rgb.astype(np.uint8), alpha.astype(np.uint8)]), "RGBA"
    )
    target_h = 108
    scale = target_h / crop.height
    target_w = max(1, int(round(crop.width * scale)))
    crop = crop.resize((target_w, target_h), Image.LANCZOS)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.paste(crop, ((CANVAS - target_w) // 2, CANVAS - target_h), crop)
    out.save(path)
    print("clean: npc_merchant.png (rebuilt %dx%d)" % (target_w, target_h))


def punch_fence(path: str) -> None:
    img = Image.open(path).convert("RGBA")
    arr = np.asarray(img).astype(int)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    mask = pink_mask(rgb, alpha)
    # 缝隙里的高亮星点同样是残留
    sparkle = (alpha > 10) & (rgb.min(axis=2) > 165)
    alpha = alpha.copy()
    alpha[mask | sparkle] = 0
    result = np.dstack([rgb.astype(np.uint8), alpha.astype(np.uint8)])
    Image.fromarray(result, "RGBA").save(path)
    print("clean: block_fence.png (%d px punched out)" % int((mask | sparkle).sum()))


def main() -> None:
    merchant = os.path.join(WORLD_DIR, "npc_merchant.png")
    fence = os.path.join(WORLD_DIR, "block_fence.png")
    if os.path.exists(merchant):
        rebuild_merchant(merchant)
    if os.path.exists(fence):
        punch_fence(fence)


if __name__ == "__main__":
    main()
