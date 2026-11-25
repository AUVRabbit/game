#!/usr/bin/env python3
# ============================================================
# make_action_grid.py
# 用 Pillow 把 16 张职业肖像 PNG 应用 40 种程序化形变（仿 SpriteAnim.gd 的公式）
# 然后 montage 成 16 行 × 40 列的完整动作总览
# 输出：docs/ACTION_GRID_2026-11-25/contact_sheet.png + 每张独立 jpg
# ============================================================

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math, os, glob

ROOT = "/workspace/通天入地"
PORTRAIT_DIR = os.path.join(ROOT, "assets/portraits")
OUT_DIR = os.path.join(ROOT, "docs/ACTION_GRID_2026-11-25")

os.makedirs(OUT_DIR, exist_ok=True)

# ---------- 职业列表 ----------
CLASSES = [
    ("warrior", "战士"), ("mage", "法师"), ("runeward", "咒铠师"), ("priest", "牧师"),
    ("necromancer", "亡灵法师"), ("bomber", "炸弹专家"), ("mech_pilot", "机甲师"), ("engineer", "工程师"),
    ("bounty_hunter", "赏金猎人"), ("death_knight", "死亡骑士"), ("archer", "弓箭手"), ("thief", "小偷"),
    ("qi_adept", "气宗"), ("sniper", "狙击手"), ("cyborg", "义体卫士"), ("hacker", "黑客"),
]

# ---------- 固定采样时间点（捕捉代表帧）----------
BT = 0.7           # breath_t 采样
AT = 0.35          # attack_timer / attack_total 采样（0~1）
HR = 0.05          # hurt_timer 采样
DR = 0.20          # dead_timer 采样
JT = 0.4           # jump_phase 1=起跳 2=上升 3=下落
ROLL_T = 0.3       # 翻滚阶段
PORTAL_T = 1.5     # 传送仪式
FALL_T = 1.0       # 跌落
FORCE_T = 0.15     # force_ready timer
FORCE_SUBTYPE = "forge"

# 从 sprite_anim.gd 提取的 40 种动作 scale_x, scale_y, rot_deg, offset_x, offset_y, modulate(可选)
# 固定时间点下的代表帧参数
ACTIONS = [
    # idx  enum                 sx   sy   rot   ox   oy   alpha(0~1)   color_tint
    (0,  "IDLE",          1.00, 1.00,  1.2, 0.0, 0.5*math.sin(BT*6), 1.0, (1.0,1.0,1.0)),
    (1,  "RUN",           0.96, 1.04, -2.4, -4.0, -4.0*math.sin(BT*9), 1.0, (1.0,1.0,1.0)),
    (2,  "ATTACK",        1.10, 1.10, 20.0, 28.0, -6.0, 1.0, (1.0,1.0,1.0)),
    (3,  "CAST",          1.02, 1.02, 2.0,  6.0,  -2.0, 1.0, (0.85,0.90,1.0)),
    (4,  "DASH",          1.04, 1.04, 0.0,  18.0, -4.0, 1.0, (1.0,1.0,1.0)),
    (5,  "BLINK",         1.00, 1.00, 0.0,  0.0,  0.0, 0.7, (1.0,1.0,1.0)),
    (6,  "HURT",          0.94, 1.06, -10.0, -10.0, 2.0, 0.85, (1.0,0.85,0.85)),
    (7,  "DEAD",          0.92, 0.92, 45.0,  0.0,  0.0, 0.55, (1.0,1.0,1.0)),
    (8,  "STAGGER",       0.95, 1.05, -5.0,  4.0,  2.0, 0.9, (1.0,0.95,0.9)),
    (9,  "RESURRECTING",  1.00, 1.00, 0.0,  0.0,  -4.0*math.sin(BT), 0.95, (1.0,1.0,1.0)),
    (10, "SWORD_SWING",   1.15, 1.15, 30.0, 30.0, -4.0, 1.0, (1.0,1.0,1.0)),
    (11, "BOW_DRAW",      1.00, 1.00, -8.0, -8.0, -2.0, 1.0, (1.0,1.0,1.0)),
    (12, "THROW_BOMB",    1.08, 1.08, 18.0, 12.0, -10.0, 1.0, (1.0,1.0,1.0)),
    (13, "CAST_SPELL",    1.04, 1.04, 6.0,  3.0,  -4.0, 1.0, (0.80,0.85,1.0)),
    (14, "SUMMON_RITUAL", 1.08, 1.08, 12.0, 2.0,  4.0, 1.0, (0.65,0.85,0.95)),
    (15, "CHARGING",      0.94, 1.10, 0.0,  0.0,  2.0, 0.95, (1.0,0.90,0.55)),
    (16, "CAST_FOCUS",    1.10, 1.10, 3.0,  0.0,  -3.0, 0.95, (0.85,0.95,1.0)),
    (17, "BLOCK",         1.02, 0.98, -4.0,  -3.0, 0.0, 1.0, (1.0,1.0,1.0)),
    (18, "READY",         1.00, 1.00, 0.0,  2.0,  0.0, 1.0, (1.0,1.0,1.0)),
    (19, "CROUCH",        1.05, 0.78, 0.0,  0.0,  7.0, 1.0, (1.0,1.0,1.0)),
    (20, "WALK_CROUCH",   1.05, 0.78, 0.4,  1.5,  7.5, 1.0, (1.0,1.0,1.0)),
    (21, "PRONE",         1.15, 0.45, 0.0,  0.0,  12.0, 1.0, (1.0,1.0,1.0)),
    (22, "LURK",          1.02, 0.88, 3.0,  2.5,  3.5, 0.85, (0.75,0.85,1.0)),
    (23, "JUMP",          1.05, 0.95, 5.0,  0.0,  -6.0, 1.0, (1.0,1.0,1.0)),
    (24, "JUMP_FALLING",  1.10, 0.88, -5.0, 0.0,  0.0, 1.0, (1.0,1.0,1.0)),
    (25, "JUMP_LAND",     1.00, 0.85, 3.0,  0.0,  3.0, 1.0, (1.0,1.0,1.0)),
    (26, "SWIM",          1.05, 0.95, 3.0,  0.0,  2.0, 1.0, (0.75,0.92,1.0)),
    (27, "CLIMB",         0.90, 1.05, 2.0,  0.0,  0.0, 1.0, (1.0,1.0,1.0)),
    (28, "ROLL",          0.55, 1.25, 130.0, -10.0, 1.0, 0.75, (1.0,1.0,1.0)),
    (29, "MOUNTED",       0.95, 0.92, 2.0,  0.0,  -1.5, 1.0, (1.0,1.0,1.0)),
    (30, "FORCE_READY",   1.00, 1.00, 0.0,  0.0,  -1.0, 1.0, (1.0,1.0,1.0)),  # dialog sub
    (31, "DRINK",         1.00, 1.02, 1.0,  0.0,  -1.0, 1.0, (1.0,1.0,1.0)),
    (32, "CARRY",         1.05, 1.00, -2.0, -1.5, 2.0, 1.0, (1.0,1.0,1.0)),
    (33, "SIT",           1.02, 0.82, 0.0,  0.0,  5.5, 1.0, (1.0,1.0,1.0)),
    (34, "TRAP_SET",      1.00, 0.95, 3.0,  0.0,  3.0, 1.0, (1.0,1.0,1.0)),
    (35, "PORTAL",        1.10, 1.10, 17.2, 0.0,  -5.0, 1.0, (0.70,0.80,1.0)),
    (36, "CELEBRATE",     1.00, 1.08, 4.0,  2.0,  -3.5, 1.0, (1.0,0.95,0.6)),
    (37, "FALL",          0.90, 1.15, 26.0, 0.0,  0.0, 1.0, (1.0,1.0,1.0)),
    (38, "AOE_SWING",     1.15, 1.15, 69.0, 40.0, -2.0, 1.0, (1.0,1.0,1.0)),
    (39, "RAPID_STRIKES", 1.10, 1.10, 46.0, 20.0, -3.0, 1.0, (1.0,1.0,1.0)),
]

# 动作中文/描述
ACTION_CN = {
    "IDLE": "待机呼吸", "RUN": "奔跑", "ATTACK": "普攻出拳", "CAST": "法术咏唱", "DASH": "冲刺前冲",
    "BLINK": "瞬步闪现", "HURT": "受击后仰", "DEAD": "死亡倒地", "STAGGER": "硬直抖动",
    "RESURRECTING": "复活弹起", "SWORD_SWING": "挥剑蓄力", "BOW_DRAW": "拉弓瞄准",
    "THROW_BOMB": "投掷炸弹", "CAST_SPELL": "双手上抬施法", "SUMMON_RITUAL": "召唤法阵",
    "CHARGING": "能量汇聚蓄力", "CAST_FOCUS": "长施法双手高举", "BLOCK": "举盾格挡",
    "READY": "武器举起重试", "CROUCH": "蹲下", "WALK_CROUCH": "蹲走", "PRONE": "趴下",
    "LURK": "潜伏探头", "JUMP": "起跳伸展", "JUMP_FALLING": "下落收缩", "JUMP_LAND": "落地压缩回弹",
    "SWIM": "游泳划水", "CLIMB": "攀爬", "ROLL": "翻滚", "MOUNTED": "骑乘颠簸",
    "FORCE_READY": "对话/搜寻/锻造", "DRINK": "喝药水", "CARRY": "搬运负重", "SIT": "坐下",
    "TRAP_SET": "放置陷阱", "PORTAL": "传送仪式", "CELEBRATE": "庆祝跳跃", "FALL": "跌落旋转",
    "AOE_SWING": "范围重斩", "RAPID_STRIKES": "快速连击",
}


def load_portrait(cid):
    """加载职业肖像 PNG（带透明通道）"""
    for ext in ("png", "jpg"):
        p = os.path.join(PORTRAIT_DIR, f"{cid}.{ext}")
        if os.path.exists(p):
            img = Image.open(p).convert("RGBA")
            # 正方形居中裁出主体区域（portrait 是 512×512 带空边）
            w, h = img.size
            size = min(w, h)
            left = (w - size) // 2
            top = (h - size) // 2
            return img.crop((left, top, left + size, top + size))
    return None


def apply_action(img, sx, sy, rot_deg, ox, oy, alpha, tint):
    """对肖像应用仿射变换并居中到透明画布"""
    w, h = img.size
    cx, cy = w / 2, h / 2
    # scale → rot → translate（Godot CanvasItem.transform 顺序）
    # 1. 缩放
    scaled = img.resize((int(w * sx), int(h * sy)), Image.LANCZOS)
    sw, sh = scaled.size
    # 2. 旋转
    rot_img = scaled.rotate(-rot_deg, resample=Image.BICUBIC, expand=True)
    rw, rh = rot_img.size
    # 3. 合成 tint（乘色）
    r, g, b, a = rot_img.split()
    r = r.point(lambda v: int(v * tint[0]))
    g = g.point(lambda v: int(v * tint[1]))
    b = b.point(lambda v: int(v * tint[2]))
    if alpha < 1.0:
        a = a.point(lambda v: int(v * alpha))
    tinted = Image.merge("RGBA", (r, g, b, a))
    # 4. 贴到 320×240 画布
    canvas = Image.new("RGBA", (320, 240), (20, 24, 32, 255))
    # 画一层光晕
    draw = ImageDraw.Draw(canvas)
    draw.ellipse([20, 30, 300, 220], fill=(28, 34, 44, 255))
    # 居中粘贴 + 偏移
    px = 160 - rw // 2 + int(ox * 4)
    py = 120 - rh // 2 + int(oy * 4)
    canvas.alpha_composite(tinted, dest=(px, py))
    # 画地面阴影
    draw2 = ImageDraw.Draw(canvas)
    shadow_y = py + rh - 4 + int(oy * 4)
    draw2.ellipse([px + 10, shadow_y - 2, px + rw - 10, shadow_y + 6], fill=(0, 0, 0, 70))
    return canvas


def montage_grid(tiles, rows, cols, tile_size=(320, 240)):
    """把 tiles（list of PIL Images）拼成 rows×cols 网格，带标签"""
    tw, th = tile_size
    margin = 4
    label_h = 24
    label_font = ImageFont.load_default()
    label_font_big = label_font
    total_w = cols * (tw + margin) + margin
    total_h = rows * (th + label_h + margin) + margin + label_h + margin * 2  # top header
    big = Image.new("RGBA", (total_w, total_h), (12, 14, 22, 255))
    draw = ImageDraw.Draw(big)
    # 顶部表头：动作名
    draw.rectangle([0, 0, total_w - 1, label_h + margin], fill=(26, 32, 42, 255))
    for ci, (enum, _, _) in enumerate(zip([a[1] for a in ACTIONS], [None] * cols, [None] * cols)):
        x0 = margin + ci * (tw + margin)
        cn = ACTION_CN.get(enum, enum)
        draw.text((x0 + tw // 2 - len(cn) * 6, 6), cn, fill=(220, 235, 255, 255), font=label_font)
        draw.text((x0 + tw // 2 - len(enum) * 3, 14), enum, fill=(110, 130, 160, 255), font=label_font)
    for ri, (cid, cn) in enumerate(CLASSES):
        y0 = label_h + margin + ri * (th + label_h + margin) + margin
        # 行标签（职业名）
        draw.rectangle([0, y0, 120, y0 + th + label_h], fill=(18, 22, 32, 255))
        draw.text((14, y0 + 10), cn, fill=(220, 235, 255, 255), font=label_font_big)
        draw.text((14, y0 + 26), cid, fill=(110, 130, 160, 255), font=label_font)
        # 行色块
        color_map = {
            "warrior": (224, 83, 61), "mage": (90, 123, 255), "runeward": (125, 107, 255),
            "priest": (255, 230, 160), "necromancer": (138, 107, 191), "bomber": (224, 122, 58),
            "mech_pilot": (168, 168, 184), "engineer": (217, 164, 65), "bounty_hunter": (200, 122, 154),
            "death_knight": (122, 47, 63), "archer": (95, 191, 95), "thief": (79, 195, 161),
            "qi_adept": (111, 224, 176), "sniper": (200, 180, 90), "cyborg": (88, 200, 232), "hacker": (74, 214, 255),
        }
        col = color_map.get(cid, (200, 200, 220))
        draw.rectangle([0, y0, 6, y0 + th + label_h], fill=col)
        for ci, tile in enumerate(tiles[ri * cols:(ri + 1) * cols]):
            x0 = 120 + margin + ci * (tw + margin)
            big.alpha_composite(tile, dest=(x0, y0))
            draw.rectangle([x0, y0 + th, x0 + tw, y0 + th + label_h], fill=(18, 22, 32, 255))
            draw.text((x0 + 6, y0 + th + 4), f"{ci+1:02d}", fill=(130, 160, 200, 255), font=label_font)
    return big


def main():
    print(f"=== 开始生成 {len(CLASSES)}×{len(ACTIONS)} = {len(CLASSES)*len(ACTIONS)} 张动作图 ===")
    tiles = []
    missing = []
    for ri, (cid, cn) in enumerate(CLASSES):
        img = load_portrait(cid)
        if img is None:
            print(f"  [SKIP] {cid} 肖像缺失")
            missing.append(cid)
            # 占位空白 tile
            for _ in ACTIONS:
                tiles.append(Image.new("RGBA", (320, 240), (40, 44, 52, 255)))
            continue
        class_dir = os.path.join(OUT_DIR, cid)
        os.makedirs(class_dir, exist_ok=True)
        print(f"  [{ri+1}/{len(CLASSES)}] {cn} ({cid}) 肖像 {img.size[0]}×{img.size[1]}")
        for ai, (idx, enum, sx, sy, rot, ox, oy, alpha, tint) in enumerate(ACTIONS):
            frame = apply_action(img, sx, sy, rot, ox, oy, alpha, tint)
            tiles.append(frame)
            frame.save(os.path.join(class_dir, f"{idx:02d}_{enum}.png"))
    # montage
    print("=== 拼接总表 ===")
    sheet = montage_grid(tiles, len(CLASSES), len(ACTIONS))
    out_path = os.path.join(OUT_DIR, "action_contact_sheet_16x40.png")
    sheet.save(out_path)
    print(f"总表：{out_path}  {sheet.size[0]}×{sheet.size[1]}")
    # 单职业 contact sheet（每个职业单独一页）
    for ri, (cid, cn) in enumerate(CLASSES):
        row_tiles = tiles[ri * len(ACTIONS):(ri + 1) * len(ACTIONS)]
        cols = 8
        rows = (len(ACTIONS) + cols - 1) // cols
        tw, th = 200, 150
        margin = 3
        label_h = 20
        total_w = cols * (tw + margin) + margin
        total_h = rows * (th + label_h + margin) + margin * 2 + label_h + margin
        big = Image.new("RGBA", (total_w, total_h), (12, 14, 22, 255))
        draw = ImageDraw.Draw(big)
        draw.rectangle([0, 0, total_w - 1, label_h + margin], fill=(26, 32, 42, 255))
        draw.text((10, 4), f"{cn} {cid}", fill=(220, 235, 255, 255))
        for ci, tile in enumerate(row_tiles):
            ro = ci // cols
            co = ci % cols
            x0 = margin + co * (tw + margin)
            y0 = label_h + margin + ro * (th + label_h + margin) + margin
            small = tile.resize((tw, th))
            big.alpha_composite(small, dest=(x0, y0))
            draw.rectangle([x0, y0 + th, x0 + tw, y0 + th + label_h], fill=(18, 22, 32, 255))
            enum_name = ACTIONS[ci][1]
            cn_name = ACTION_CN.get(enum_name, enum_name)
            draw.text((x0 + 4, y0 + th + 3), f"{ci+1:02d} {cn_name}", fill=(180, 210, 240, 255))
        sheet_path = os.path.join(OUT_DIR, f"{cid}_action_sheet.png")
        big.save(sheet_path)
    print("=== 完成 ===")
    print(f"输出目录：{OUT_DIR}")
    print(f"缺失肖像：{missing}")


if __name__ == "__main__":
    main()
