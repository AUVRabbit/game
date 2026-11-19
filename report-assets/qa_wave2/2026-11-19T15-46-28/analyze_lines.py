#!/usr/bin/env python3
"""定位构造图内水平蓝线的根因：统计颜色与行位置。"""
from PIL import Image
from collections import Counter

P = "/Users/l/game/report-assets/qa_wave2/2026-11-19T15-46-28/synth_all_2026-11-19T15-46-28.png"
im = Image.open(P).convert("RGBA")
W, H = im.size

def px(x, y):
    r, g, b, a = im.getpixel((x, y))
    return (r, g, b)

# 左上水块 x=32..224 (col1-6), y=32..96 (row1-2)。关注 row 边界 y=64 (tile 行 y=1 与 y=2 之间)
print("=== 左上水块 垂直扫描 x=100, y=28..100 ===")
for y in range(28, 100):
    c = px(100, y)
    print(f"  y={y:3d} rgb={c}")

# 找该水块内所有"接近纯蓝/亮蓝横线"的行：统计每行在 x=40..220 的像素众数
print("\n=== 左上水块 每行众数颜色 (x40..220) ===")
for y in range(30, 98):
    cnt = Counter(px(x, y) for x in range(40, 220))
    mode, n = cnt.most_common(1)[0]
    print(f"  y={y:3d} mode={mode} count={n}/180")
