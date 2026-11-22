#!/usr/bin/env python3
# ============================================================
# gen_advanced_icons.py — 生成进阶主动技能图标
# 设计规则：进阶技能是其基础分支的进化形态，图标 = 同分支基础图标
#   + 阶位符印框（槽 4 金 / 槽 5 青 / 槽 6 紫），右上角菱形数 = 阶位。
# 该规则可审计、可复现，避免为 48 个进阶技能单独绘制的风格漂移。
# 用法：python3 tools/gen_advanced_icons.py
# ============================================================

import json
import os
from PIL import Image, ImageDraw, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKILL_DIR = os.path.join(ROOT, "assets", "icons", "skill")

# 槽位 -> (边框色, 菱形数)
SLOT_STYLE = {
    4: ((214, 176, 72), 1),
    5: ((86, 205, 232), 2),
    6: ((168, 122, 255), 3),
}


def _tinted_icon(base, color, pips):
    im = base.convert("RGBA")
    im = ImageEnhance.Brightness(im).enhance(1.08)
    im = ImageEnhance.Color(im).enhance(1.12)
    draw = ImageDraw.Draw(im)
    w, h = im.size
    inset = 10
    # 外框 + 内描边，形成“进阶符印”
    draw.rounded_rectangle([inset, inset, w - inset - 1, h - inset - 1], radius=26,
                           outline=color + (230,), width=8)
    inner = inset + 9
    draw.rounded_rectangle([inner, inner, w - inner - 1, h - inner - 1], radius=20,
                           outline=color + (90,), width=2)
    # 右上角阶位菱形
    for i in range(pips):
        cx = w - 40 - i * 26
        cy = 38
        r = 9
        draw.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)],
                     fill=color + (245,), outline=(255, 255, 255, 220))
    return im


def main():
    with open(os.path.join(ROOT, "data", "classes.json"), encoding="utf-8") as f:
        classes = json.load(f)["classes"]
    made = 0
    missing = []
    for cid, cdef in classes.items():
        skills = cdef.get("skills", [])
        for skill in skills:
            if not skill.get("advanced"):
                continue
            slot = int(skill.get("slot", 0))
            if slot not in SLOT_STYLE:
                continue
            base_skill = skills[slot - 4]
            base_path = os.path.join(SKILL_DIR, str(base_skill.get("icon", ""))[6:] + ".png")
            if not os.path.isfile(base_path):
                missing.append(base_path)
                continue
            color, pips = SLOT_STYLE[slot]
            out = os.path.join(SKILL_DIR, str(skill.get("icon", ""))[6:] + ".png")
            _tinted_icon(Image.open(base_path), color, pips).save(out, optimize=True)
            made += 1
    print("已生成进阶图标 %d 个" % made)
    if missing:
        print("缺少基础图标 %d 个：" % len(missing))
        for m in missing:
            print("  -", os.path.relpath(m, ROOT))


if __name__ == "__main__":
    main()
