#!/usr/bin/env python3
"""把 AI 生成的敌人原图（洋红键背景）转成透明的 128x128 游戏精灵。

流程：
1. 抹掉右下角「AI生成」水印（该区域本来就是纯背景，直接填键色）；
2. 以键色距离做反解算（unmatte），得到柔和 alpha 与去色边的颜色；
3. 取最大连通域并补洞，丢弃键色残留；
4. 裁到内容包围盒，补正方形，缩放到 128x128 输出。

用法：
    python3 tools/make_enemy_sprites.py
输入：/tmp/enemy_raw/enemy_*.jpg
输出：assets/sprites/enemy_*.png
"""
import os

import cv2
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = "/tmp/enemy_raw"
OUT_DIR = os.path.join(ROOT, "assets", "sprites")

IDS = ["enemy_slime", "enemy_mech_spider", "enemy_wraith", "enemy_boss"]
SIZE = 128
PAD = 0.04


def strip_watermark(arr: np.ndarray) -> np.ndarray:
    h, w, _ = arr.shape
    out = arr.copy()
    x0, x1 = int(w * 0.76), int(w * 0.995)
    y0, y1 = int(h * 0.85), int(h * 0.99)
    corner = np.concatenate([
        arr[:40, :40].reshape(-1, 3),
        arr[:40, -40:].reshape(-1, 3),
        arr[-40:, :40].reshape(-1, 3),
    ], axis=0).astype(np.float32)
    key = np.median(corner, axis=0)
    out[y0:y1, x0:x1] = key.astype(np.uint8)
    return out


def unmatte(arr: np.ndarray) -> tuple:
    rgb = arr[:, :, :3].astype(np.float32)
    corner = np.concatenate([
        arr[:40, :40, :3].reshape(-1, 3),
        arr[:40, -40:, :3].reshape(-1, 3),
        arr[-40:, :40, :3].reshape(-1, 3),
    ], axis=0).astype(np.float32)
    key = np.median(corner, axis=0)

    dist = np.linalg.norm(rgb - key.reshape(1, 1, 3), axis=2)
    alpha = np.clip((dist - 38.0) / 55.0, 0.0, 1.0)

    solid = (alpha > 0.5).astype(np.uint8)
    solid = cv2.morphologyEx(solid, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
    count, labels, stats, _ = cv2.connectedComponentsWithStats(solid, 8)
    if count > 1:
        best = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        solid = (labels == best).astype(np.uint8)
    solid = cv2.morphologyEx(solid, cv2.MORPH_CLOSE, np.ones((13, 13), np.uint8))
    filled = solid.copy()
    flood = solid.copy()
    mask = np.zeros((solid.shape[0] + 2, solid.shape[1] + 2), np.uint8)
    cv2.floodFill(flood, mask, (0, 0), 1)
    filled = solid | (1 - flood)
    solid = filled

    near = cv2.dilate(solid, np.ones((7, 7), np.uint8))
    alpha = alpha * near

    a = np.maximum(alpha, 0.08)[:, :, None]
    color = np.clip((rgb - (1.0 - a) * key.reshape(1, 1, 3)) / a, 0, 255)
    color = np.where((alpha > 0.05)[:, :, None], color, rgb)
    return color, alpha


def process(path: str) -> None:
    img = Image.open(path).convert("RGB")
    arr = np.asarray(img)
    arr = strip_watermark(arr)
    color, alpha = unmatte(arr)

    rgba = np.dstack([color.astype(np.uint8), (alpha * 255.0).astype(np.uint8)])
    out = Image.fromarray(rgba, "RGBA")

    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    side = max(out.size)
    side = int(side * (1.0 + PAD * 2.0))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(out, ((side - out.size[0]) // 2, (side - out.size[1]) // 2), out)
    canvas = canvas.resize((SIZE, SIZE), Image.LANCZOS)

    dst = os.path.join(OUT_DIR, "%s.png" % os.path.splitext(os.path.basename(path))[0])
    canvas.save(dst, "PNG", optimize=True)
    print("ok %s -> %s" % (os.path.basename(path), os.path.relpath(dst, ROOT)))


def main() -> None:
    for name in IDS:
        src = os.path.join(RAW_DIR, "%s.jpg" % name)
        if not os.path.exists(src):
            print("skip (missing): %s" % src)
            continue
        process(src)


if __name__ == "__main__":
    main()
