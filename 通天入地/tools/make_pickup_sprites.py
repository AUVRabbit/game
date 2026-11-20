#!/usr/bin/env python3
"""从 256x256 物品图标中提取主体，生成 128x128 透明掉落物贴图。

输入：assets/icons/item/<id>.png（深色底 + 居中主体）
输出：assets/sprites/world/item_<id>.png（RGBA 透明）

方法：
1. 用四边边框像素的中位数估计背景色；
2. 计算逐像素与背景色的差异图；
3. Otsu 阈值 + 最大连通域（剔除触边连通域）得到主体掩膜；
4. 差异图做软化得到柔和 alpha（保留发光晕圈）；
5. 按内容 bbox 裁剪 → 补成正方形 → 缩放居中写入 128x128 画布。
"""

import os
import sys

import cv2
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "assets", "icons", "item")
OUT_DIR = os.path.join(ROOT, "assets", "sprites", "world")

CANVAS = 128
CONTENT = 112

IDS = [
    "slime_gel",
    "mech_core",
    "ghost_dust",
    "gold_coin",
]


def border_median(rgb: np.ndarray) -> np.ndarray:
    h, w, _ = rgb.shape
    band = 6
    parts = [
        rgb[:band, :, :].reshape(-1, 3),
        rgb[-band:, :, :].reshape(-1, 3),
        rgb[:, :band, :].reshape(-1, 3),
        rgb[:, -band:, :].reshape(-1, 3),
    ]
    stack = np.concatenate(parts, axis=0).astype(np.float32)
    return np.median(stack, axis=0)


def extract(path: str) -> Image.Image:
    img = Image.open(path).convert("RGB")
    rgb = np.asarray(img).astype(np.float32)
    h, w, _ = rgb.shape

    bg = border_median(rgb)
    diff = np.linalg.norm(rgb - bg.reshape(1, 1, 3), axis=2)

    diff_u8 = np.clip(diff, 0, 255).astype(np.uint8)
    thr, binary = cv2.threshold(diff_u8, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    num, labels, stats, _ = cv2.connectedComponentsWithStats(binary, connectivity=8)
    if num <= 1:
        raise RuntimeError("no subject found in %s" % path)

    best_label = 0
    best_area = 0
    for i in range(1, num):
        x, y, cw, ch, area = stats[i]
        if x == 0 and y == 0 and cw == w and ch == h:
            continue
        touches_border = x <= 1 or y <= 1 or x + cw >= w - 1 or y + ch >= h - 1
        if touches_border:
            continue
        if area > best_area:
            best_area = area
            best_label = i
    if best_label == 0:
        raise RuntimeError("no inner subject found in %s" % path)

    core = (labels == best_label).astype(np.uint8)
    core = cv2.morphologyEx(core, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    holes = cv2.morphologyEx(core, cv2.MORPH_CLOSE, np.ones((13, 13), np.uint8))
    core = holes

    alpha = np.clip((diff - thr * 0.10) / max(6.0, thr * 0.40), 0.0, 1.0)
    near = cv2.dilate(core, np.ones((11, 11), np.uint8))
    alpha = alpha * near

    ys, xs = np.where(alpha > 0.12)
    if len(xs) == 0:
        raise RuntimeError("empty alpha in %s" % path)
    x0, x1 = int(xs.min()), int(xs.max())
    y0, y1 = int(ys.min()), int(ys.max())
    pad = 2
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(w - 1, x1 + pad)
    y1 = min(h - 1, y1 + pad)

    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = rgb.astype(np.uint8)
    rgba[:, :, 3] = (alpha * 255.0).astype(np.uint8)

    crop = Image.fromarray(rgba, mode="RGBA").crop((x0, y0, x1 + 1, y1 + 1))
    side = max(crop.width, crop.height)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(crop, ((side - crop.width) // 2, (side - crop.height) // 2), crop)
    square = square.resize((CONTENT, CONTENT), Image.LANCZOS)

    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.paste(square, ((CANVAS - CONTENT) // 2, (CANVAS - CONTENT) // 2), square)
    return out


def main() -> int:
    os.makedirs(OUT_DIR, exist_ok=True)
    ok = 0
    for item_id in IDS:
        src = os.path.join(SRC_DIR, "%s.png" % item_id)
        if not os.path.exists(src):
            print("[skip] %s" % item_id)
            continue
        try:
            out_img = extract(src)
        except Exception as exc:  # noqa: BLE001
            print("[fail] %s: %s" % (item_id, exc))
            continue
        dst = os.path.join(OUT_DIR, "item_%s.png" % item_id)
        out_img.save(dst)
        print("[ok] %s -> %s" % (item_id, os.path.relpath(dst, ROOT)))
        ok += 1
    print("generated %d pickup sprites" % ok)
    return 0


if __name__ == "__main__":
    sys.exit(main())
