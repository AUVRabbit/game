#!/usr/bin/env python3
"""QA 独立浪花形态分析 —— 查无漏。产物写入 qa_wave2/<stamp>/zoom/，不覆盖已有图。"""
import os
from PIL import Image, ImageDraw

BASE = "/Users/l/game/report-assets/qa_wave2/2026-11-19T15-45-25"
OUT = os.path.join(BASE, "zoom")
os.makedirs(OUT, exist_ok=True)
TS = "2026-11-19T15-45-25"


def load(n):
    return Image.open(os.path.join(BASE, f"{n}_{TS}.png")).convert("RGBA")


def is_white(c):
    r, g, b, a = c
    return a > 200 and r > 0.82 * 255 and g > 0.84 * 255 and b > 0.86 * 255


def white_rows(img, x0, x1, y0, y1):
    """返回该 x 区间内每行白像素数。"""
    rows = []
    for y in range(y0, y1):
        n = sum(1 for x in range(x0, x1) if is_white(img.getpixel((x, y))))
        rows.append((y, n))
    return rows


pillar = load("real_pillar")
bottom = load("real_bottom")
left = load("real_left")
top = load("real_top")
with_ab = load("real_AB_with")
without_ab = load("real_AB_without")
anims = [load(f"real_anim_f{i}") for i in range(4)]

print("=== 尺寸 ===")
for n, im in [("top", top), ("bottom", bottom), ("pillar", pillar),
              ("left", left), ("AB_with", with_ab), ("AB_without", without_ab)]:
    print(f"  {n}: {im.size}")

# 自动定位水平浪花带：在顶部水域视角，扫描 x=20..200 的白像素行
print("\n=== real_top 白像素行分布 (x 20..200, y 110..140) ===")
for y, n in white_rows(top, 20, 200, 110, 140):
    if n > 0:
        print(f"  y={y} white={n}")

print("\n=== real_pillar 竖条底端拐角区域白像素行 (x 360..440, y 108..140) ===")
for y, n in white_rows(pillar, 360, 440, 108, 140):
    if n > 0:
        print(f"  y={y} white={n}")

# 自动找 AB 差异区域（有/无浪花）：逐像素找不同的像素及颜色
print("\n=== A/B 差异统计（有浪花 vs 关浪花，同视角）===")
diff = 0
diff_white_with = 0
rows_diff = {}
for y in range(with_ab.height):
    for x in range(with_ab.width):
        a = with_ab.getpixel((x, y))
        b = without_ab.getpixel((x, y))
        if a != b:
            diff += 1
            rows_diff[y] = rows_diff.get(y, 0) + 1
            if is_white(a):
                diff_white_with += 1
print(f"  差异像素总数={diff}，其中有浪花侧为白色的={diff_white_with}")
yd = sorted(rows_diff.items())
print(f"  差异行范围 y={yd[0][0]}..{yd[-1][0]}（共{len(yd)}行）" if yd else "  无差异")
print("  差异行明细(前30行):", yd[:30])

# 裁剪放大
def crop_zoom(img, box, name, scale=6):
    c = img.crop(box)
    c = c.resize((c.width * scale, c.height * scale), Image.NEAREST)
    p = os.path.join(OUT, name)
    c.save(p)
    return p

paths = []
# 顶部水域下沿浪花（水平）
paths.append(crop_zoom(top, (20, 118, 200, 132), "zoom_top_horizontal.png", 6))
# 竖条陆地右侧竖边 + 底端 L 拐角
paths.append(crop_zoom(pillar, (380, 100, 440, 145), "zoom_pillar_corner.png", 8))
# 底部水域上沿浪花（水平）
paths.append(crop_zoom(bottom, (20, 210, 200, 226), "zoom_bottom_horizontal.png", 6))
# 左列竖边浪花
paths.append(crop_zoom(left, (0, 100, 40, 180), "zoom_left_vertical.png", 6))

# 动画 4 帧：同一水平浪花带并排
anim_crops = []
for i, im in enumerate(anims):
    c = im.crop((20, 118, 200, 132)).resize((180 * 3, 14 * 3), Image.NEAREST)
    anim_crops.append(c)
combo = Image.new("RGBA", (180 * 3, 14 * 3 * 4 + 12 * 4), (255, 255, 255, 255))
d = ImageDraw.Draw(combo)
for i, c in enumerate(anim_crops):
    y = i * (14 * 3 + 12)
    combo.paste(c, (0, y))
    d.text((2, y + 14 * 3), f"frame {i}", fill=(0, 0, 0, 255))
p = os.path.join(OUT, "zoom_anim_4frames.png")
combo.save(p)
paths.append(p)

# A/B 并排（同视角水平带）
wa = with_ab.crop((20, 118, 200, 132)).resize((180 * 3, 14 * 3), Image.NEAREST)
wb = without_ab.crop((20, 118, 200, 132)).resize((180 * 3, 14 * 3), Image.NEAREST)
ab = Image.new("RGBA", (180 * 3, 14 * 3 * 2 + 24), (255, 255, 255, 255))
d = ImageDraw.Draw(ab)
ab.paste(wa, (0, 0)); d.text((2, 14 * 3), "WITH shore (QA independent)", fill=(0, 0, 0, 255))
ab.paste(wb, (0, 14 * 3 + 24)); d.text((2, 14 * 3 * 2 + 24), "WITHOUT shore (runtime disabled)", fill=(0, 0, 0, 255))
p = os.path.join(OUT, "zoom_AB_compare.png")
ab.save(p)
paths.append(p)

# 原作浪花裁剪放大（若存在）
qq_path = "/Users/l/game/report-assets/QQ_shore_crop_153247.png"
if os.path.exists(qq_path):
    qq = Image.open(qq_path).convert("RGBA")
    print(f"\n=== 原作图尺寸 ===")
    print(f"  QQ_shore_crop: {qq.size}")
    # 原作图是竖图，浪花在右侧竖带；裁右侧一条并旋转成水平便于对比
    qcrop = qq.crop((max(0, qq.width - 90), 0, qq.width, min(qq.height, 400)))
    qcrop = qcrop.resize((qcrop.width * 4, qcrop.height * 4), Image.NEAREST)
    p = os.path.join(OUT, "zoom_original_qq_shore.png")
    qcrop.save(p)
    paths.append(p)

print("\n=== 生成的放大图 ===")
for p in paths:
    print("  " + p)
