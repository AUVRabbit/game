#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""世界精灵透明化工具。

输入目录里的 PNG 保留了 AI 生成时的洋红色键背景，alpha 通道里残留
不均匀的半透明灰底。本工具负责把主体抠出来并输出干净的带 alpha 贴图。

处理步骤：
1. 以内容区外圈 alpha 的中位数为背景基线，自适应算出阈值
2. 阈值分割出主体，连通域取最大块并补洞
3. 收缩 1px 去掉被背景污染的洋红描边
4. 对边缘仍偏洋红的像素，用最近的内部像素颜色回填（去色边）
5. 高斯羽化并裁到正方形

用法：
    python3 tools/fix_alpha.py --dir assets/sprites/world --size 128 --pad 0.06
"""
import argparse
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _magentaish(rgb: np.ndarray) -> np.ndarray:
    """判断像素是否属于洋红色系（键色污染）。"""
    r = rgb[:, :, 0]
    g = rgb[:, :, 1]
    b = rgb[:, :, 2]
    return (r > 120) & (b > 110) & (g < r - 45) & (g < b - 25)


def _largest_component(mask: np.ndarray) -> np.ndarray:
    lbl, n = ndimage.label(mask)
    if n == 0:
        return mask
    sizes = ndimage.sum(mask, lbl, range(1, n + 1))
    return lbl == (int(np.argmax(sizes)) + 1)


def _background_magenta(rgb: np.ndarray, content: np.ndarray, band: np.ndarray) -> np.ndarray:
    """在主体外围一圈内找出残留的洋红键色像素（主体内部的洋红不受影响）。"""
    return _magentaish(rgb) & band & content


def _defringe(rgb: np.ndarray, core: np.ndarray) -> np.ndarray:
    """把主体边缘偏洋红的像素换成最近内部像素的颜色。"""
    band = ndimage.binary_dilation(core, iterations=3) & ~core
    bad = band & _magentaish(rgb)
    if not bad.any():
        return rgb
    dist, inds = ndimage.distance_transform_edt(~core, return_indices=True)
    out = rgb.copy()
    out[bad] = rgb[inds[0][bad], inds[1][bad]]
    return out


def process_one(src: str, size: int, pad_ratio: float) -> bool:
    im = Image.open(src).convert("RGBA")
    arr = np.asarray(im).astype(np.float64)
    rgb = arr[:, :, :3]
    alpha = arr[:, :, 3]
    h, w = alpha.shape

    content = alpha > 2
    ys, xs = np.nonzero(content)
    if len(ys) < 100:
        return False
    cy0, cy1, cx0, cx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1

    ring = np.zeros((h, w), dtype=bool)
    ring[cy0 + 4:cy1 - 4, cx0 + 4:cx1 - 4] = True
    ring[cy0:cy1, cx0:cx1] = False
    if int(ring.sum()) < 50:
        ring = content.copy()
    base = float(np.median(alpha[ring]))
    peak = float(np.percentile(alpha[content], 99.0))
    thr = base + 0.35 * max(peak - base, 1.0)

    fg = alpha > thr
    fg = ndimage.binary_closing(fg, iterations=2)
    fg = _largest_component(fg)
    fg = ndimage.binary_fill_holes(fg)

    core = ndimage.binary_erosion(fg, iterations=1)
    if int(core.sum()) < 30:
        core = fg

    # 主体外围一圈的洋红键色残留直接剔除（主体内部的洋红不受影响）
    band = ndimage.binary_dilation(fg, iterations=6) & ~core
    bg_mag = _background_magenta(rgb, content, band)

    rgb = _defringe(rgb, core)

    soft = ndimage.gaussian_filter(core.astype(np.float64), 0.8)
    soft = np.clip((soft - 0.25) / 0.5, 0.0, 1.0)
    soft[~fg] = 0.0
    soft[bg_mag] = 0.0
    soft = np.clip(soft, 0.0, 1.0)

    out = np.dstack([rgb.astype(np.uint8), (soft * 255.0).astype(np.uint8)])
    img = Image.fromarray(out.astype(np.uint8), "RGBA")

    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    side = max(img.size)
    side = int(side * (1.0 + pad_ratio * 2.0))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - img.size[0]) // 2, (side - img.size[1]) // 2), img)
    canvas = canvas.resize((size, size), Image.LANCZOS)
    canvas.save(src, "PNG", optimize=True)
    return True


def process_dir(dir_rel: str, size: int, pad_ratio: float) -> int:
    target = os.path.join(ROOT, dir_rel)
    if not os.path.isdir(target):
        print("skip missing dir %s" % dir_rel)
        return 0
    count = 0
    for name in sorted(os.listdir(target)):
        if not name.lower().endswith(".png"):
            continue
        path = os.path.join(target, name)
        try:
            if process_one(path, size, pad_ratio):
                count += 1
        except Exception as exc:  # noqa: BLE001
            print("fail %s: %s" % (path, exc))
    print("%s -> %d sprites cleaned at %dx%d" % (dir_rel, count, size, size))
    return count


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--size", type=int, default=128)
    ap.add_argument("--pad", type=float, default=0.06)
    args = ap.parse_args()
    process_dir(args.dir, args.size, args.pad)


if __name__ == "__main__":
    main()
