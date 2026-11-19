#!/usr/bin/env python3
"""放大 synth 盲区：孤立水格四角、L形凹角；并排原作浪花。"""
import os
from PIL import Image, ImageDraw

BASE2 = "/Users/l/game/report-assets/qa_wave2/2026-11-19T15-46-28"
OUT = "/Users/l/game/report-assets/qa_wave2/2026-11-19T15-45-25/zoom"
im = Image.open(os.path.join(BASE2, "synth_all_2026-11-19T15-46-28.png")).convert("RGBA")

def zoom(box, name, scale):
    c = im.crop(box)
    c = c.resize((c.width * scale, c.height * scale), Image.NEAREST)
    p = os.path.join(OUT, name)
    c.save(p)
    return p

paths = []
# 单格孤立水格 (x=3*32=96,y=7*32=224) 32x32 + 周边
paths.append(zoom((88, 216, 136, 264), "synth_isolated_cell.png", 10))
# L形凹角：右侧大块挖去的缺口。大块 col9..14 => x288..480, row2..8 => y64..288
# L陆地 (10,4)(10,5)(11,4) => x320..384, y128..192
paths.append(zoom((304, 112, 400, 208), "synth_L_corner.png", 8))
# 竖条陆地 col6 => x192..224, row5..11 => y160..384。取中段
paths.append(zoom((176, 224, 256, 320), "synth_vertical_strip.png", 8))

# 原作浪花：QQ 竖图 620x1170，水在左，右侧是地面，竖边浪花在 x≈? 先全图缩略 + 边界带放大
qq = Image.open("/Users/l/game/report-assets/QQ_shore_crop_153247.png").convert("RGBA")
print("QQ size", qq.size)
# 找水(蓝)与地面的竖直分界：扫描若干 y 行，找蓝色像素的最大 x
for y in [100, 300, 500, 700, 900]:
    maxblue = -1
    for x in range(qq.width):
        r, g, b, a = qq.getpixel((x, y))
        if b > 150 and b > r + 40 and b > g + 20:  # 蓝
            maxblue = x
    print(f"  y={y} maxblue x={maxblue}")
# 裁 x=400..470 全高缩小一半看
qc = qq.crop((390, 0, 480, 600))
qc = qc.resize((qc.width * 3, qc.height * 3), Image.NEAREST)
p = os.path.join(OUT, "original_shore_vertical_edge.png")
qc.save(p); paths.append(p)

for p in paths:
    print(p)
