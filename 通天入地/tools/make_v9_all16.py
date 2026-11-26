#!/usr/bin/env python3
"""
v9 — Cel-Shading 赛璐璐硬阴影 · 全部 16 职业程序化 2D 骨架动画

基于 v9_celshade 核心, 扩展到项目全部 16 个职业 (assets/portraits/):
  warrior, mage, archer, thief, bomber, bounty_hunter, cyborg, death_knight,
  engineer, hacker, mech_pilot, necromancer, priest, qi_adept, runeward, sniper

每职业独立设计: 配色 band + 武器 + 发型 + 胸甲装饰 + rim light 主题色
保证: 每一帧独立绘制, 不切割, 无贴图
  6 动作 × 4 帧 = 24 帧/职业, 16 职业 = 384 帧
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/CEL_SHADING_v9_ALL16"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 骨架系统 (和 v7/v9 相同 — 7 关节, bind pose)
# ============================================================
BIND = {
    "pelvis": (256, 310),
    "torso":  (256, 160),
    "head":   (256, 80),
    "arm_l":  (180, 175),
    "arm_r":  (332, 175),
    "leg_l":  (228, 400),
    "leg_r":  (284, 400),
}
PARENT = {
    "pelvis": None,
    "torso": "pelvis", "head": "torso",
    "arm_l": "torso", "arm_r": "torso",
    "leg_l": "pelvis", "leg_r": "pelvis",
}

def bone_length(name):
    parent = PARENT[name]
    if parent is None: return 0
    dx = BIND[name][0] - BIND[parent][0]
    dy = BIND[name][1] - BIND[parent][1]
    return math.hypot(dx, dy)

def bone_offset(name):
    parent = PARENT[name]
    if parent is None: return (0, 0)
    return (BIND[name][0] - BIND[parent][0], BIND[name][1] - BIND[parent][1])

def fk(bone_rots, facing=1.0, pelvis_pos=(256, 310)):
    transforms = {}
    def calc(name):
        if name in transforms: return transforms[name]
        parent = PARENT[name]
        if parent is None:
            transforms[name] = (bone_rots.get(name, 0.0), pelvis_pos)
        else:
            parent_rot, parent_pos = calc(parent)
            bo = bone_offset(name)
            angle = math.radians(parent_rot + bone_rots.get(name, 0.0))
            lx = bo[0] * facing
            ly = bo[1]
            tx = parent_pos[0] + lx * math.cos(angle) - ly * math.sin(angle)
            ty = parent_pos[1] + lx * math.sin(angle) + ly * math.cos(angle)
            transforms[name] = (parent_rot + bone_rots.get(name, 0.0), (tx, ty))
        return transforms[name]
    for name in BIND: calc(name)
    return transforms

# ============================================================
# 辅助: 从主色自动生成 5 档赛璐璐 band
# ============================================================
def _shade(c, f):
    return tuple(max(0, min(255, int(ch * f + 0.5))) for ch in c)

def make_palette(name_cn, weapon, skill_cn,
                 body_main, accent, rim,
                 skin_main=(210, 175, 145), skin_rim=(250, 235, 215),
                 hair_main=(25, 18, 14), hair_rim=(60, 45, 35),
                 outline=None, eye_color=None):
    outline = outline or tuple(max(2, c//15) for c in body_main)
    eye_color = eye_color or rim
    return {
        "name": name_cn, "weapon": weapon, "weapon_cn": skill_cn,
        "body_bands": [
            _shade(body_main, 0.12),
            _shade(body_main, 0.28),
            _shade(body_main, 0.55),
            _shade(body_main, 0.85),
            rim,
        ],
        "skin_bands": [
            _shade(skin_main, 0.62), _shade(skin_main, 0.80),
            skin_main, _shade(skin_main, 1.15), skin_rim,
        ],
        "hair_bands": [
            _shade(hair_main, 0.12), _shade(hair_main, 0.38),
            hair_main, _shade(hair_main, 1.30), hair_rim,
        ],
        "outline": outline, "rim": rim, "accent": accent, "eye_color": eye_color,
    }

# ============================================================
# 全部 16 职业 Palette
# ============================================================
CLASS_PALETTE = {}

# 1. warrior → 野蛮人
CLASS_PALETTE["warrior"] = make_palette(
    "野蛮人", "巨剑", "旋风斩",
    body_main=(76, 54, 40), accent=(220, 55, 45), rim=(110, 80, 72),
    skin_main=(205, 165, 135), skin_rim=(250, 235, 215),
    hair_main=(20, 15, 12), hair_rim=(60, 45, 35),
    outline=(8, 6, 8), eye_color=(255, 120, 50),
)

# 2. mage → 女巫
CLASS_PALETTE["mage"] = make_palette(
    "女巫", "法杖", "陨石术",
    body_main=(50, 55, 110), accent=(80, 180, 255), rim=(120, 200, 255),
    skin_main=(218, 182, 162), skin_rim=(252, 240, 225),
    hair_main=(72, 38, 22), hair_rim=(140, 85, 55),
    outline=(6, 6, 18), eye_color=(120, 200, 255),
)

# 3. archer → 亚马逊
CLASS_PALETTE["archer"] = make_palette(
    "亚马逊", "长弓", "多重射击",
    body_main=(58, 88, 45), accent=(180, 220, 100), rim=(210, 240, 110),
    skin_main=(222, 188, 158), skin_rim=(253, 240, 222),
    hair_main=(118, 58, 28), hair_rim=(200, 120, 80),
    outline=(6, 10, 6), eye_color=(160, 210, 90),
)

# 4. thief → 刺客
CLASS_PALETTE["thief"] = make_palette(
    "刺客", "双匕", "影袭",
    body_main=(44, 44, 56), accent=(220, 180, 60), rim=(240, 210, 80),
    skin_main=(198, 168, 148), skin_rim=(245, 230, 215),
    hair_main=(12, 12, 18), hair_rim=(40, 40, 55),
    outline=(3, 3, 5), eye_color=(255, 220, 100),
)

# 5. bomber → 投弹手 (工装橙)
CLASS_PALETTE["bomber"] = make_palette(
    "投弹手", "炸弹", "爆破投掷",
    body_main=(180, 110, 50), accent=(255, 180, 40), rim=(255, 200, 80),
    skin_main=(208, 172, 142), skin_rim=(248, 232, 210),
    hair_main=(42, 30, 22), hair_rim=(90, 70, 50),
    outline=(12, 10, 8), eye_color=(255, 180, 60),
)

# 6. bounty_hunter → 赏金猎人 (土黄+暗金)
CLASS_PALETTE["bounty_hunter"] = make_palette(
    "赏金猎人", "霰弹枪", "精准射击",
    body_main=(140, 105, 65), accent=(200, 160, 60), rim=(230, 190, 100),
    skin_main=(212, 178, 148), skin_rim=(248, 232, 210),
    hair_main=(55, 40, 28), hair_rim=(110, 85, 55),
    outline=(10, 8, 6), eye_color=(220, 180, 90),
)

# 7. cyborg → 赛博格 (银/青金属)
CLASS_PALETTE["cyborg"] = make_palette(
    "赛博格", "能量炮", "等离子冲击",
    body_main=(140, 150, 160), accent=(0, 220, 220), rim=(80, 240, 255),
    skin_main=(180, 185, 195), skin_rim=(220, 230, 240),
    hair_main=(18, 22, 28), hair_rim=(60, 70, 85),
    outline=(8, 10, 14), eye_color=(0, 240, 255),
)

# 8. death_knight → 死亡骑士 (暗紫+绿火)
CLASS_PALETTE["death_knight"] = make_palette(
    "死亡骑士", "符文大剑", "亡灵召唤",
    body_main=(55, 30, 70), accent=(50, 255, 80), rim=(100, 255, 120),
    skin_main=(185, 182, 195), skin_rim=(230, 228, 240),
    hair_main=(8, 4, 14), hair_rim=(40, 12, 60),
    outline=(10, 4, 16), eye_color=(50, 255, 80),
)

# 9. engineer → 工程师 (橙+铁灰)
CLASS_PALETTE["engineer"] = make_palette(
    "工程师", "扳手", "炮台架设",
    body_main=(120, 90, 70), accent=(230, 150, 50), rim=(255, 180, 80),
    skin_main=(215, 180, 150), skin_rim=(250, 235, 215),
    hair_main=(38, 28, 22), hair_rim=(80, 62, 48),
    outline=(10, 8, 6), eye_color=(255, 180, 70),
)

# 10. hacker → 黑客 (荧光绿+黑)
CLASS_PALETTE["hacker"] = make_palette(
    "黑客", "数据匕首", "网络入侵",
    body_main=(40, 48, 42), accent=(0, 255, 90), rim=(100, 255, 140),
    skin_main=(200, 192, 180), skin_rim=(240, 235, 225),
    hair_main=(6, 10, 8), hair_rim=(30, 45, 35),
    outline=(2, 6, 4), eye_color=(0, 255, 90),
)

# 11. mech_pilot → 机甲驾驶员 (深蓝+金属)
CLASS_PALETTE["mech_pilot"] = make_palette(
    "机甲驾驶员", "操控装置", "机甲重击",
    body_main=(35, 55, 95), accent=(200, 210, 225), rim=(220, 230, 245),
    skin_main=(210, 180, 155), skin_rim=(248, 235, 220),
    hair_main=(32, 28, 28), hair_rim=(75, 65, 65),
    outline=(6, 10, 18), eye_color=(100, 180, 255),
)

# 12. necromancer → 死灵法师 (暗绿+紫)
CLASS_PALETTE["necromancer"] = make_palette(
    "死灵法师", "亡灵法杖", "骷髅复活",
    body_main=(45, 75, 50), accent=(180, 80, 220), rim=(220, 130, 255),
    skin_main=(180, 200, 185), skin_rim=(225, 240, 230),
    hair_main=(8, 18, 12), hair_rim=(30, 55, 38),
    outline=(6, 14, 8), eye_color=(180, 80, 220),
)

# 13. priest → 牧师 (白金)
CLASS_PALETTE["priest"] = make_palette(
    "牧师", "权杖", "圣光治愈",
    body_main=(215, 200, 165), accent=(255, 215, 100), rim=(255, 240, 180),
    skin_main=(222, 192, 168), skin_rim=(252, 240, 225),
    hair_main=(55, 45, 35), hair_rim=(120, 100, 80),
    outline=(50, 42, 30), eye_color=(255, 215, 100),
)

# 14. qi_adept → 气功师 (白红太极)
CLASS_PALETTE["qi_adept"] = make_palette(
    "气功师", "赤手空拳", "气功波",
    body_main=(235, 228, 220), accent=(220, 40, 40), rim=(255, 80, 80),
    skin_main=(218, 185, 158), skin_rim=(252, 240, 225),
    hair_main=(12, 10, 10), hair_rim=(40, 36, 36),
    outline=(18, 15, 15), eye_color=(220, 40, 40),
)

# 15. runeward → 符文剑士 (银蓝)
CLASS_PALETTE["runeward"] = make_palette(
    "符文剑士", "符文剑", "符文爆发",
    body_main=(100, 120, 160), accent=(120, 200, 255), rim=(180, 230, 255),
    skin_main=(210, 178, 150), skin_rim=(248, 232, 215),
    hair_main=(28, 28, 36), hair_rim=(70, 70, 90),
    outline=(6, 8, 14), eye_color=(120, 200, 255),
)

# 16. sniper → 狙击手 (黑灰红)
CLASS_PALETTE["sniper"] = make_palette(
    "狙击手", "狙击步枪", "穿透射击",
    body_main=(55, 58, 62), accent=(200, 40, 40), rim=(230, 80, 80),
    skin_main=(208, 175, 148), skin_rim=(248, 232, 215),
    hair_main=(30, 32, 34), hair_rim=(70, 72, 76),
    outline=(4, 4, 6), eye_color=(200, 40, 40),
)

# 光照方向
LIGHT_DIR = (-0.35, -0.55)
_llen = math.hypot(LIGHT_DIR[0], LIGHT_DIR[1])
LIGHT_N = (LIGHT_DIR[0]/_llen, LIGHT_DIR[1]/_llen)

# ============================================================
# 几何辅助
# ============================================================
def rotate_point(cx, cy, px, py, angle_deg):
    rad = math.radians(angle_deg)
    dx, dy = px - cx, py - cy
    rx = dx * math.cos(rad) - dy * math.sin(rad)
    ry = dx * math.sin(rad) + dy * math.cos(rad)
    return (cx + rx, cy + ry)

def blend(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(c1[i]*(1-t) + c2[i]*t + 0.5) for i in range(3))

# ============================================================
# Cel-Shading 核心绘制 (复用 v9 函数)
# ============================================================
def draw_rot_ellipse(draw, cx, cy, w, h, ang_deg, fill_color):
    steps = 32
    pts = []
    for i in range(steps + 1):
        a = 2 * math.pi * i / steps
        ex = cx + w * math.cos(a)
        ey = cy + h * math.sin(a)
        pts.append(rotate_point(cx, cy, ex, ey, ang_deg))
    draw.polygon(pts, fill=fill_color, outline=None)
    return pts

def draw_cel_capsule(draw, p1, p2, r1, r2, body_bands, light_direction=LIGHT_N):
    x1, y1 = p1; x2, y2 = p2
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    length = math.hypot(x2 - x1, y2 - y1)
    if length < 0.1:
        cx, cy = (x1+x2)/2, (y1+y2)/2
        draw.ellipse([cx-r1, cy-r1, cx+r1, cy+r1], fill=body_bands[2], outline=None)
        return
    perp_deg = angle + 90
    perp = math.radians(perp_deg)
    hx1 = r1 * math.cos(perp); hy1 = r1 * math.sin(perp)
    hx2 = r2 * math.cos(perp); hy2 = r2 * math.sin(perp)
    
    corners = [
        (x1 + hx1, y1 + hy1), (x2 + hx2, y2 + hy2),
        (x2 - hx2, y2 - hy2), (x1 - hx1, y1 - hy1),
    ]
    draw.polygon(corners, fill=body_bands[2], outline=None)
    draw_rot_ellipse(draw, x1, y1, r1, r1, angle, body_bands[2])
    draw_rot_ellipse(draw, x2, y2, r2, r2, angle, body_bands[2])
    
    dot_perp = light_direction[0] * math.cos(perp) + light_direction[1] * math.sin(perp)
    shadow_depth = min(0.7, 0.45 + abs(dot_perp) * 0.35)
    shadow_r1 = r1 * shadow_depth; shadow_r2 = r2 * shadow_depth
    sx1 = shadow_r1 * math.cos(perp); sy1 = shadow_r1 * math.sin(perp)
    sx2 = shadow_r2 * math.cos(perp); sy2 = shadow_r2 * math.sin(perp)
    
    if dot_perp > 0:
        shadow_corners = [
            (x1 - hx1, y1 - hy1), (x2 - hx2, y2 - hy2),
            (x2 - hx2 - sx2 * 0.6, y2 - hy2 - sy2 * 0.6),
            (x1 - hx1 - sx1 * 0.6, y1 - hy1 - sy1 * 0.6),
        ]
    else:
        shadow_corners = [
            (x1 + hx1, y1 + hy1), (x2 + hx2, y2 + hy2),
            (x2 + hx2 + sx2 * 0.6, y2 + hy2 + sy2 * 0.6),
            (x1 + hx1 + sx1 * 0.6, y1 + hy1 + sy1 * 0.6),
        ]
    draw.polygon(shadow_corners, fill=body_bands[1], outline=None)
    
    deep_r1 = r1 * 0.12; deep_r2 = r2 * 0.12
    dx1 = deep_r1 * math.cos(perp); dy1 = deep_r1 * math.sin(perp)
    dx2 = deep_r2 * math.cos(perp); dy2 = deep_r2 * math.sin(perp)
    if dot_perp > 0:
        deep_pts = [
            (x1 - hx1, y1 - hy1), (x2 - hx2, y2 - hy2),
            (x2 - hx2 - dx2, y2 - hy2 - dy2), (x1 - hx1 - dx1, y1 - hy1 - dy1),
        ]
    else:
        deep_pts = [
            (x1 + hx1, y1 + hy1), (x2 + hx2, y2 + hy2),
            (x2 + hx2 + dx2, y2 + hy2 + dy2), (x1 + hx1 + dx1, y1 + hy1 + dy1),
        ]
    draw.polygon(deep_pts, fill=body_bands[0], outline=None)
    
    rim_r1 = r1 * 0.12; rim_r2 = r2 * 0.12
    rx1 = rim_r1 * math.cos(perp); ry1 = rim_r1 * math.sin(perp)
    rx2 = rim_r2 * math.cos(perp); ry2 = rim_r2 * math.sin(perp)
    if dot_perp > 0:
        rim_pts = [
            (x1 + hx1 - rx1, y1 + hy1 - ry1), (x2 + hx2 - rx2, y2 + hy2 - ry2),
            (x2 + hx2, y2 + hy2), (x1 + hx1, y1 + hy1),
        ]
    else:
        rim_pts = [
            (x1 - hx1 + rx1, y1 - hy1 + ry1), (x2 - hx2 + rx2, y2 - hy2 + ry2),
            (x2 - hx2, y2 - hy2), (x1 - hx1, y1 - hy1),
        ]
    draw.polygon(rim_pts, fill=body_bands[4], outline=None)

def draw_cel_ellipse(draw, cx, cy, rw, rh, bands, light_direction=LIGHT_N, rotation_deg=0):
    ang = math.radians(rotation_deg)
    draw_rot_ellipse(draw, cx, cy, rw, rh, rotation_deg, bands[2])
    
    local_lx = light_direction[0] * math.cos(-ang) - light_direction[1] * math.sin(-ang)
    local_ly = light_direction[0] * math.sin(-ang) + light_direction[1] * math.cos(-ang)
    
    shadow_pts = []
    steps = 28
    for i in range(steps + 1):
        t = 2 * math.pi * i / steps
        ex_local = rw * math.cos(t); ey_local = rh * math.sin(t)
        nx = math.cos(t); ny = math.sin(t)
        dot = nx * local_lx + ny * local_ly
        if dot < 0.05:
            gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
            gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
            shadow_pts.append((gx, gy))
    if len(shadow_pts) >= 3:
        shadow_pts.append((cx, cy))
        draw.polygon(shadow_pts, fill=bands[1], outline=None)
        
        deep_pts = []
        for i in range(steps + 1):
            t = 2 * math.pi * i / steps
            nx = math.cos(t); ny = math.sin(t)
            dot = nx * local_lx + ny * local_ly
            if dot < -0.35:
                ex_local = rw * math.cos(t); ey_local = rh * math.sin(t)
                gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
                gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
                deep_pts.append((gx, gy))
        if len(deep_pts) >= 3:
            deep_pts.append((cx, cy))
            draw.polygon(deep_pts, fill=bands[0], outline=None)
    
    rim_pts = []
    for i in range(steps + 1):
        t = 2 * math.pi * i / steps
        nx = math.cos(t); ny = math.sin(t)
        dot = nx * local_lx + ny * local_ly
        if dot > 0.65:
            ex_local = rw * 0.87 * math.cos(t); ey_local = rh * 0.87 * math.sin(t)
            gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
            gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
            rim_pts.append((gx, gy))
    if len(rim_pts) >= 3:
        outer_pts = []
        for i in range(steps + 1):
            t = 2 * math.pi * i / steps
            nx = math.cos(t); ny = math.sin(t)
            dot = nx * local_lx + ny * local_ly
            if dot > 0.65:
                ex_local = rw * math.cos(t); ey_local = rh * math.sin(t)
                gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
                gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
                outer_pts.append((gx, gy))
        combined = outer_pts + list(reversed(rim_pts))
        if len(combined) >= 4:
            draw.polygon(combined, fill=bands[4], outline=None)

# ============================================================
# 轮廓描边
# ============================================================
def draw_capsule_outline(draw, p1, p2, r1, r2, outline_color, width=2):
    x1, y1 = p1; x2, y2 = p2
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    perp = math.radians(angle + 90)
    hx1 = r1 * math.cos(perp); hy1 = r1 * math.sin(perp)
    hx2 = r2 * math.cos(perp); hy2 = r2 * math.sin(perp)
    
    flat = [x1 + hx1, y1 + hy1, x2 + hx2, y2 + hy2,
            x2 - hx2, y2 - hy2, x1 - hx1, y1 - hy1,
            x1 + hx1, y1 + hy1]
    draw.line(flat, fill=outline_color, width=width)
    draw.arc([x1-r1, y1-r1, x1+r1, y1+r1], angle+90, angle+270, fill=outline_color, width=width)
    draw.arc([x2-r2, y2-r2, x2+r2, y2+r2], angle-90, angle+90, fill=outline_color, width=width)

# ============================================================
# Rim light 描边辅助 (腿/手臂/躯干)
# ============================================================
def draw_rim_stroke(draw, p1, p2, r, rim_color):
    x1, y1 = p1; x2, y2 = p2
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    perp = math.radians(angle + 90)
    dot_perp = LIGHT_N[0] * math.cos(perp) + LIGHT_N[1] * math.sin(perp)
    if dot_perp > 0:
        hx_l = r * math.cos(perp); hy_l = r * math.sin(perp)
    else:
        hx_l = -r * math.cos(perp); hy_l = -r * math.sin(perp)
    draw.line([(x1+hx_l, y1+hy_l), (x2+hx_l, y2+hy_l)], fill=rim_color, width=1)

# ============================================================
# 16 种赛璐璐武器
# ============================================================
def draw_weapon_cel(draw, hand_pos, arm_rot, cls, facing, pal):
    hx, hy = hand_pos
    rad = math.radians(arm_rot + 90)
    accent = pal["accent"]
    body_bands = pal["body_bands"]
    metal_dark = (55, 58, 72)
    metal_mid  = (155, 160, 178)
    metal_light= (215, 220, 235)
    metal_edge = (30, 32, 44)
    perp = (rad + math.pi/2)

    def _perp(rad):
        return rad + math.pi/2

    # --- warrior: 巨剑 ---
    if cls == "warrior":
        sword_len = 130
        sword_end = (hx + math.cos(rad) * sword_len, hy + math.sin(rad) * sword_len)
        draw_cel_capsule(draw, (hx, hy), 
                        (hx + math.cos(rad)*20, hy + math.sin(rad)*20), 
                        5, 4, [(30,18,10),(48,30,18),(68,42,24),(95,62,38),(130,90,60)])
        gx = hx + math.cos(rad) * 20; gy = hy + math.sin(rad) * 20
        guard_p1 = (gx + math.cos(perp)*14, gy + math.sin(perp)*14)
        guard_p2 = (gx - math.cos(perp)*14, gy - math.sin(perp)*14)
        draw_cel_capsule(draw, guard_p1, guard_p2, 5, 5, [metal_edge,metal_dark,metal_mid,metal_light,(250,230,180)])
        bx1 = gx + math.cos(perp)*22; by1 = gy + math.sin(perp)*22
        bx2 = gx - math.cos(perp)*22; by2 = gy - math.sin(perp)*22
        ex = sword_end[0] + math.cos(perp)*5; ey = sword_end[1] + math.sin(perp)*5
        ex2 = sword_end[0] - math.cos(perp)*5; ey2 = sword_end[1] - math.sin(perp)*5
        draw.polygon([(bx1,by1),(bx2,by2),(ex2,ey2),(ex,ey)], fill=metal_mid)
        mid1x = (bx1+bx2)/2; mid1y = (by1+by2)/2
        mid2x = (ex+ex2)/2; mid2y = (ey+ey2)/2
        draw.line([(mid1x,mid1y),(mid2x,mid2y)], fill=metal_light, width=3)
        for side_off in [4, -4]:
            s1x = mid1x + math.cos(perp)*side_off
            s1y = mid1y + math.sin(perp)*side_off
            s2x = mid2x + math.cos(perp)*side_off * 0.5
            s2y = mid2y + math.sin(perp)*side_off * 0.5
            draw.line([(s1x,s1y),(s2x,s2y)], fill=metal_edge, width=1)
        draw.line([(bx1,by1),(ex,ey)], fill=metal_edge, width=2)
        draw.line([(bx2,by2),(ex2,ey2)], fill=metal_edge, width=2)
        draw.line([(ex,ey),(ex2,ey2)], fill=metal_edge, width=2)
        for i in range(4):
            fx = sword_end[0] - math.cos(rad)*(8+i*7)
            fy = sword_end[1] - math.sin(rad)*(8+i*7)
            size = max(2, 5 - i)
            c = blend((255, 200, 80), (255, 60, 30), i/3)
            draw.ellipse([fx-size, fy-size, fx+size, fy+size], fill=c)

    # --- mage: 法杖 ---
    elif cls == "mage" or cls == "necromancer":
        staff_len = 190
        staff_top = (hx + math.cos(rad)*staff_len, hy + math.sin(rad)*staff_len)
        bottom = (hx - math.cos(rad)*30, hy - math.sin(rad)*30)
        staff_colors = [(35,22,14),(58,38,22),(82,55,32),(115,78,48),(160,115,75)]
        if cls == "necromancer":
            staff_colors = [(18,32,22),(30,52,36),(42,72,50),(60,100,72),(88,140,100)]
        draw_cel_capsule(draw, bottom, staff_top, 4, 3, staff_colors)
        ring_positions = [0.2, 0.5, 0.75]
        for rp in ring_positions:
            rx_p = bottom[0] + (staff_top[0]-bottom[0])*rp
            ry_p = bottom[1] + (staff_top[1]-bottom[1])*rp
            draw.line([(rx_p+math.cos(perp)*6, ry_p+math.sin(perp)*6),
                      (rx_p-math.cos(perp)*6, ry_p-math.sin(perp)*6)],
                     fill=(200,180,100), width=3)
        gcx, gcy = staff_top
        gem_colors = [(60, 120, 200), (80, 180, 255), (180, 230, 255), (255, 255, 255)]
        if cls == "necromancer":
            gem_colors = [(180, 80, 220), (220, 130, 255), (240, 180, 255), (255, 255, 255)]
        for i, rg in enumerate([16, 12, 8, 4]):
            draw.ellipse([gcx-rg, gcy-rg, gcx+rg, gcy+rg], fill=gem_colors[i])
        draw.ellipse([gcx-3, gcy-5, gcx+2, gcy-1], fill=(255,255,255))

    # --- archer: 长弓 ---
    elif cls == "archer":
        bow_len = 150
        bx1 = hx + math.cos(rad)*65; by1 = hy + math.sin(rad)*65
        bx2 = hx - math.cos(rad)*85; by2 = hy - math.sin(rad)*85
        mid_x = (bx1+bx2)/2 + math.cos(perp)*48
        mid_y = (by1+by2)/2 + math.sin(perp)*48
        steps_bow = 20
        bow_pts = []
        for i in range(steps_bow+1):
            t = i / steps_bow
            qx = (1-t)*(1-t)*bx1 + 2*(1-t)*t*mid_x + t*t*bx2
            qy = (1-t)*(1-t)*by1 + 2*(1-t)*t*mid_y + t*t*by2
            bow_pts.append((qx, qy))
        offset_outer = [(p[0] + math.cos(perp)*4, p[1] + math.sin(perp)*4) for p in bow_pts]
        offset_inner = [(p[0] - math.cos(perp)*4, p[1] - math.sin(perp)*4) for p in bow_pts]
        bow_body = offset_outer + list(reversed(offset_inner))
        draw.polygon(bow_body, fill=(100, 70, 40), outline=None)
        draw.line(bow_pts, fill=(140, 100, 60), width=2)
        rev_bow = list(reversed(bow_pts))
        draw.line(rev_bow, fill=(60, 40, 22), width=2)
        draw.line([(bx1, by1), (bx2, by2)], fill=(230, 225, 200), width=1)
        draw.line([(bx1, by1), (bx2, by2)], fill=(255, 255, 240), width=1)
        draw.ellipse([bx1-3, by1-3, bx1+3, by1+3], fill=accent)
        draw.ellipse([bx2-3, by2-3, bx2+3, by2+3], fill=accent)

    # --- thief: 双匕 ---
    elif cls == "thief":
        dagger_len = 55
        tip = (hx + math.cos(rad)*dagger_len, hy + math.sin(rad)*dagger_len)
        draw_cel_capsule(draw, (hx, hy), 
                        (hx + math.cos(rad)*16, hy + math.sin(rad)*16),
                        4, 3, [(18,18,24),(32,32,42),(48,48,60),(72,72,86),(100,100,120)])
        bx_h = hx + math.cos(rad)*16; by_h = hy + math.sin(rad)*16
        g1 = (bx_h + math.cos(perp)*9, by_h + math.sin(perp)*9)
        g2 = (bx_h - math.cos(perp)*9, by_h - math.sin(perp)*9)
        draw.line([g1, g2], fill=(220, 180, 60), width=4)
        draw.line([g1, g2], fill=(250, 215, 110), width=2)
        tip_off = (math.cos(perp)*9, math.sin(perp)*9)
        blade_pts = [
            (bx_h + tip_off[0], by_h + tip_off[1]),
            (bx_h - tip_off[0], by_h - tip_off[1]),
            tip,
        ]
        draw.polygon(blade_pts, fill=metal_mid)
        draw.line([(bx_h, by_h), tip], fill=metal_light, width=2)
        draw.line([(bx_h + tip_off[0], by_h + tip_off[1]), tip], fill=metal_edge, width=2)
        draw.line([(bx_h - tip_off[0], by_h - tip_off[1]), tip], fill=metal_edge, width=2)

    # --- bomber: 手榴弹/炸弹 ---
    elif cls == "bomber":
        # 右手举着炸弹
        bomb_r = 18
        bx_c = hx + math.cos(rad)*30; by_c = hy + math.sin(rad)*30
        # 炸弹主体 (深灰金属)
        draw_cel_ellipse(draw, bx_c, by_c, bomb_r, bomb_r, [(20,18,16),(40,36,32),(62,56,50),(88,80,72),(130,120,110)], LIGHT_N, 0)
        # 炸弹轮廓
        draw.ellipse([bx_c-bomb_r, by_c-bomb_r, bx_c+bomb_r, by_c+bomb_r], outline=(10,8,6), width=2)
        # 引信 (顶部延伸)
        fx = bx_c + math.cos(rad)*bomb_r; fy = by_c + math.sin(rad)*bomb_r
        fx2 = fx + math.cos(rad)*22; fy2 = fy + math.sin(rad)*22
        draw.line([(fx, fy), (fx2, fy2)], fill=(120, 100, 60), width=3)
        # 引信火花
        for i in range(5):
            sx = fx2 - math.cos(rad)*(i*3) + math.sin(rad)*i*2 - math.sin(rad)*i
            sy = fy2 - math.sin(rad)*(i*3) + math.cos(rad)*i*2 + math.cos(rad)*i
            sc = blend((255, 200, 80), (255, 80, 30), i/4)
            draw.ellipse([sx-2, sy-2, sx+2, sy+2], fill=sc)
        # 炸弹上的小钩子
        draw.line([(bx_c-bomb_r+4, by_c), (bx_c-bomb_r+4, by_c+8)], fill=(80,70,50), width=2)

    # --- bounty_hunter: 霰弹枪 ---
    elif cls == "bounty_hunter" or cls == "sniper":
        # 长步枪
        rifle_len = 170
        barrel_end = (hx + math.cos(rad)*rifle_len, hy + math.sin(rad)*rifle_len)
        # 枪托
        stock_start = (hx - math.cos(rad)*25, hy - math.sin(rad)*25)
        stock_end = (hx - math.cos(rad)*50 + math.sin(rad)*8, 
                     hy - math.sin(rad)*50 - math.cos(rad)*8)
        draw_cel_capsule(draw, stock_start, stock_end, 8, 6,
                        [(30,20,12),(52,36,22),(78,54,32),(110,78,48),(150,110,75)])
        # 枪管
        barrel_start = (hx + math.cos(rad)*10, hy + math.sin(rad)*10)
        draw_cel_capsule(draw, barrel_start, barrel_end, 5, 4,
                        [(20,22,28),(40,44,56),(65,70,88),(95,100,120),(150,155,170)])
        # 枪管轮廓
        draw.line([barrel_start, barrel_end], fill=metal_edge, width=1)
        # 瞄准镜 (bounty_hunter 用普通瞄具, sniper 用大镜)
        if cls == "sniper":
            # 大瞄准镜
            scope_cx = barrel_start[0] + (barrel_end[0]-barrel_start[0])*0.35
            scope_cy = barrel_start[1] + (barrel_end[1]-barrel_start[1])*0.35
            perp_up_x = -math.sin(rad)*12; perp_up_y = math.cos(rad)*12
            draw.rectangle([scope_cx-4+perp_up_x, scope_cy-3+perp_up_y, 
                           scope_cx+30+perp_up_x, scope_cy+3+perp_up_y], fill=(30,30,34))
            draw.rectangle([scope_cx-2+perp_up_x, scope_cy-4+perp_up_y, 
                           scope_cx+28+perp_up_x, scope_cy+perp_up_y], fill=(45,45,50))
            # 瞄准镜镜片反光
            draw.ellipse([scope_cx+4+perp_up_x, scope_cy-3+perp_up_y, 
                         scope_cx+10+perp_up_x, scope_cy+3+perp_up_y], fill=(200,50,50))
        # 枪口
        draw.ellipse([barrel_end[0]-4, barrel_end[1]-4, barrel_end[0]+4, barrel_end[1]+4], fill=metal_edge)

    # --- cyborg: 能量炮 ---
    elif cls == "cyborg":
        # 机械臂+能量炮 (右手臂变成炮)
        gun_len = 90
        g_end = (hx + math.cos(rad)*gun_len, hy + math.sin(rad)*gun_len)
        # 炮身 (金属)
        draw_cel_capsule(draw, (hx, hy), g_end, 16, 10,
                        [(30,34,40),(60,66,78),(100,108,125),(140,150,170),(180,195,215)])
        # 炮身能量条 (青色发光)
        draw.line([(hx+math.cos(rad)*20, hy+math.sin(rad)*20), 
                  (g_end[0]-math.cos(rad)*10, g_end[1]-math.sin(rad)*10)], 
                 fill=(0, 220, 220), width=3)
        draw.line([(hx+math.cos(rad)*22, hy+math.sin(rad)*22), 
                  (g_end[0]-math.cos(rad)*12, g_end[1]-math.sin(rad)*12)],
                 fill=(100, 255, 255), width=1)
        # 炮口发光球
        gcx, gcy = g_end
        for i, rg in enumerate([18, 12, 7, 3]):
            c = [(0, 180, 180), (0, 230, 230), (120, 255, 255), (255, 255, 255)][i]
            draw.ellipse([gcx-rg, gcy-rg, gcx+rg, gcy+rg], fill=c)

    # --- death_knight: 符文大剑 ---
    elif cls == "death_knight" or cls == "runeward":
        sword_len = 140
        sword_end = (hx + math.cos(rad) * sword_len, hy + math.sin(rad) * sword_len)
        blade_colors = [(20,30,24),(40,56,48),(65,90,78),(100,140,125),(150,200,170)]
        accent_g = (50, 255, 80) if cls == "death_knight" else (120, 200, 255)
        draw_cel_capsule(draw, (hx, hy), 
                        (hx + math.cos(rad)*22, hy + math.sin(rad)*22), 
                        6, 5, [(20,10,28),(36,20,48),(56,34,72),(80,52,100),(120,80,150)])
        gx = hx + math.cos(rad) * 22; gy = hy + math.sin(rad) * 22
        guard_p1 = (gx + math.cos(perp)*16, gy + math.sin(perp)*16)
        guard_p2 = (gx - math.cos(perp)*16, gy - math.sin(perp)*16)
        draw.line([guard_p1, guard_p2], fill=(100,80,130), width=5)
        draw.line([guard_p1, guard_p2], fill=(accent_g[0], accent_g[1], accent_g[2]), width=2)
        bx1 = gx + math.cos(perp)*24; by1 = gy + math.sin(perp)*24
        bx2 = gx - math.cos(perp)*24; by2 = gy - math.sin(perp)*24
        ex = sword_end[0] + math.cos(perp)*6; ey = sword_end[1] + math.sin(perp)*6
        ex2 = sword_end[0] - math.cos(perp)*6; ey2 = sword_end[1] - math.sin(perp)*6
        draw.polygon([(bx1,by1),(bx2,by2),(ex2,ey2),(ex,ey)], fill=(55,75,65) if cls=="death_knight" else (100,120,160))
        # 符文发光纹理
        mid1x = (bx1+bx2)/2; mid1y = (by1+by2)/2
        mid2x = (ex+ex2)/2; mid2y = (ey+ey2)/2
        for i in range(5):
            t = i / 4
            rx = mid1x + (mid2x-mid1x)*t
            ry = mid1y + (mid2y-mid1y)*t
            sz = 3 + (1-abs(t-0.5))*2
            draw.ellipse([rx-sz, ry-sz, rx+sz, ry+sz], fill=accent_g)
        draw.line([(bx1,by1),(ex,ey)], fill=(10,5,16), width=2)
        draw.line([(bx2,by2),(ex2,ey2)], fill=(10,5,16), width=2)

    # --- engineer: 扳手 ---
    elif cls == "engineer":
        wrench_len = 70
        w_end = (hx + math.cos(rad)*wrench_len, hy + math.sin(rad)*wrench_len)
        # 握柄
        handle_end = (hx + math.cos(rad)*45, hy + math.sin(rad)*45)
        draw_cel_capsule(draw, (hx, hy), handle_end, 6, 5,
                        [(40,30,20),(68,50,32),(98,72,48),(135,100,68),(180,140,100)])
        # 扳手头 (开口扳)
        hx_w, hy_w = handle_end
        head_cx = hx_w + math.cos(rad)*25
        head_cy = hy_w + math.sin(rad)*25
        draw_cel_ellipse(draw, head_cx, head_cy, 14, 14,
                        [(35,38,45),(55,60,72),(80,86,100),(110,118,135),(150,160,180)], LIGHT_N, 0)
        # 扳手开口
        draw.rectangle([head_cx-6, head_cy-10, head_cx+6, head_cy-2], fill=(0,0,0))
        draw.rectangle([head_cx-6, head_cy+2, head_cx+6, head_cy+10], fill=(0,0,0))
        draw.ellipse([head_cx-4, head_cy-4, head_cx+4, head_cy+4], fill=(0,0,0))

    # --- hacker: 数据匕首 (短刺) ---
    elif cls == "hacker":
        blade_len = 50
        tip = (hx + math.cos(rad)*blade_len, hy + math.sin(rad)*blade_len)
        # 握柄 (黑)
        draw_cel_capsule(draw, (hx, hy), 
                        (hx + math.cos(rad)*18, hy + math.sin(rad)*18),
                        4, 3, [(0,0,0),(6,8,6),(14,18,14),(28,34,28),(60,70,60)])
        bx_h = hx + math.cos(rad)*18; by_h = hy + math.sin(rad)*18
        g1 = (bx_h + math.cos(perp)*8, by_h + math.sin(perp)*8)
        g2 = (bx_h - math.cos(perp)*8, by_h - math.sin(perp)*8)
        draw.line([g1, g2], fill=(0, 255, 90), width=3)
        # 刀刃 (短三角 + 绿色数据流动)
        tip_off = (math.cos(perp)*7, math.sin(perp)*7)
        blade_pts = [(bx_h + tip_off[0], by_h + tip_off[1]),
                    (bx_h - tip_off[0], by_h - tip_off[1]), tip]
        draw.polygon(blade_pts, fill=(30, 40, 34))
        draw.line([(bx_h, by_h), tip], fill=(0, 255, 90), width=2)
        # 数据碎片飘散
        for i in range(3):
            dx_d = math.cos(rad + i*1.2)*12 + math.sin(rad)*6
            dy_d = math.sin(rad + i*1.2)*12 - math.cos(rad)*6
            px_d = bx_h + dx_d; py_d = by_h + dy_d
            draw.rectangle([px_d-1, py_d-1, px_d+3, py_d+1], fill=(0, 255, 90))

    # --- mech_pilot: 操控装置 (右手举控制杆) ---
    elif cls == "mech_pilot":
        stick_top = (hx + math.cos(rad)*55, hy + math.sin(rad)*55)
        draw_cel_capsule(draw, (hx, hy), stick_top, 6, 4,
                        [(20,28,42),(40,54,78),(65,88,125),(95,125,170),(140,170,210)])
        # 球形控制头
        draw_cel_ellipse(draw, stick_top[0], stick_top[1], 10, 10,
                        [(30,40,60),(60,80,110),(95,125,170),(135,170,220),(200,230,250)], LIGHT_N, 0)
        # 控制杆上的蓝色按钮
        draw.ellipse([stick_top[0]-3, stick_top[1]-3, stick_top[0]+3, stick_top[1]+3], fill=(100, 180, 255))
        # 连接的电线
        draw.line([(hx+math.cos(rad)*10+5, hy+math.sin(rad)*10-5), 
                  (hx+math.cos(rad)*10-5, hy+math.sin(rad)*10+5)], 
                 fill=(60, 90, 140), width=2)

    # --- priest: 权杖 ---
    elif cls == "priest":
        staff_len = 180
        staff_top = (hx + math.cos(rad)*staff_len, hy + math.sin(rad)*staff_len)
        bottom = (hx - math.cos(rad)*30, hy - math.sin(rad)*30)
        draw_cel_capsule(draw, bottom, staff_top, 5, 3,
                        [(40,30,18),(70,55,35),(100,80,52),(135,110,72),(180,150,105)])
        # 顶部金色圆环 + 十字架
        gcx, gcy = staff_top
        # 光环
        for i, rg in enumerate([22, 16, 10]):
            c = [(180, 160, 100), (220, 195, 120), (255, 225, 140)][i]
            draw.ellipse([gcx-rg, gcy-rg, gcx+rg, gcy+rg], outline=c, width=2)
        # 十字架
        draw.rectangle([gcx-2, gcy-14, gcx+2, gcy+14], fill=(255, 215, 100))
        draw.rectangle([gcx-10, gcy-4, gcx+10, gcy+2], fill=(255, 215, 100))
        # 圣光粒子
        for i in range(4):
            ang_p = i * math.pi / 2 + 0.3
            px_p = gcx + math.cos(ang_p)*28; py_p = gcy + math.sin(ang_p)*28
            draw.ellipse([px_p-2, py_p-2, px_p+2, py_p+2], fill=(255, 235, 160))

    # --- qi_adept: 赤手空拳 (画一个气拳) ---
    elif cls == "qi_adept":
        fist_cx = hx + math.cos(rad)*35; fist_cy = hy + math.sin(rad)*35
        # 拳头 (皮肤)
        draw_cel_ellipse(draw, fist_cx, fist_cy, 14, 14, pal["skin_bands"], LIGHT_N, 0)
        draw.ellipse([fist_cx-14, fist_cy-14, fist_cx+14, fist_cy+14], outline=pal["outline"], width=2)
        # 气功波 (红色圆环)
        qi_r = 28
        for i in range(3):
            rr = qi_r + i*10
            alpha = [200, 140, 70][i]
            draw.ellipse([fist_cx-rr, fist_cy-rr, fist_cx+rr, fist_cy+rr], 
                        outline=(alpha, 0, 0), width=2)
        # 内圈气团
        for i, rg in enumerate([20, 14, 8]):
            c = [(220, 40, 40), (255, 80, 60), (255, 200, 180)][i]
            draw.ellipse([fist_cx-rg, fist_cy-rg, fist_cx+rg, fist_cy+rg], fill=c)


# ============================================================
# 16 种发型/头饰绘制
# ============================================================
def _half_circle_pts(hx, hy, r_top, r_bot, rng_func, n_steps=36):
    """生成上半圆+下半扩展的发型轮廓"""
    pts = []
    for i in range(n_steps+1):
        a = math.pi * i / n_steps
        r = r_top + rng_func(a)
        pts.append((hx - r * math.cos(a), hy - r * math.sin(a)))
    return pts

def draw_head_cel(draw, head_pos, head_rot, cls, pal):
    hx, hy = head_pos
    skin_bands = pal["skin_bands"]
    hair_bands = pal["hair_bands"]
    outline = pal["outline"]
    rim = pal["rim"]
    eye_color = pal["eye_color"]
    
    # 1. 脸部
    draw_cel_ellipse(draw, hx, hy, 22, 24, skin_bands, LIGHT_N, head_rot)
    draw.ellipse([hx-22, hy-24, hx+22, hy+22], outline=outline, width=2)
    
    # 2. 发型/头饰 — 16 职业差异化
    if cls == "warrior":
        # 棕色长发 + 胡须
        pts = []
        for i in range(33):
            a = math.pi * i / 32
            r = 24 + math.sin(a*3) * 2
            pts.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        pts.extend([(hx-26, hy+6), (hx-24, hy+18), (hx-18, hy+28),
                    (hx+18, hy+28), (hx+24, hy+18), (hx+26, hy+6)])
        draw.polygon(pts, fill=hair_bands[2])
        shadow = []
        for i in range(33):
            a = math.pi * i / 32
            r = 20 + math.sin(a*3) * 1.5
            shadow.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        draw.polygon(shadow, fill=hair_bands[1])
        for i in range(int(33*0.6), int(33*0.9)):
            a = math.pi * i / 32
            r = 24.5
            draw.line([(hx - r * math.cos(a), hy - r * math.sin(a))], fill=hair_bands[4], width=2)
        beard = []
        for i in range(20):
            t = i / 19
            beard.append((hx - 16 + t * 32, hy + 10 + abs(math.sin(t*math.pi*2)) * 14 + 6))
        beard.extend([(hx+16, hy+10), (hx-16, hy+10)])
        draw.polygon(beard, fill=hair_bands[2])
    
    elif cls == "mage":
        # 兜帽 + 银发
        hood = []
        for i in range(41):
            a = math.pi * i / 40
            hood.append((hx - 30 * math.cos(a), hy - 4 - 30 * math.sin(a)))
        hood.extend([(hx-28, hy-2), (hx, hy-40), (hx+28, hy-2)])
        draw.polygon(hood, fill=pal["body_bands"][2])
        inner = []
        for i in range(41):
            a = math.pi * i / 40
            inner.append((hx - 23 * math.cos(a), hy - 4 - 23 * math.sin(a)))
        inner.extend([(hx-23, hy-2), (hx+23, hy-2)])
        draw.polygon(inner, fill=pal["body_bands"][0])
        for i in range(int(41*0.35), int(41*0.65)):
            a = math.pi * i / 40
            r = 30
            draw.point((int(hx - r * math.cos(a)), int(hy - 4 - r * math.sin(a))), fill=rim)
        draw.polygon([(hx, hy-44), (hx-10, hy-10), (hx+10, hy-10)], fill=pal["body_bands"][1])
        draw.arc([hx-22, hy-18, hx+22, hy+12], 200, 340, fill=hair_bands[3], width=3)
        draw.arc([hx-20, hy-16, hx+20, hy+10], 200, 340, fill=hair_bands[4], width=1)
        draw.arc([hx-30, hy-38, hx+30, hy+10], 180, 360, fill=outline, width=2)
    
    elif cls == "archer":
        # 高马尾 + 束发带
        hair = []
        for i in range(33):
            a = math.pi * 0.8 + math.pi * 0.4 * i / 32
            r = 23 + math.sin(i*0.6) * 1.5
            hair.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        hair.extend([(hx-22, hy+4), (hx-20, hy-6), (hx+10, hy-12), (hx+14, hy-4)])
        draw.polygon(hair, fill=hair_bands[2])
        dark = []
        for i in range(33):
            a = math.pi * 0.8 + math.pi * 0.4 * i / 32
            r = 18 + math.sin(i*0.6)
            dark.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        draw.polygon(dark, fill=hair_bands[1])
        draw.polygon([(hx-18, hy-12), (hx+10, hy-16), (hx+12, hy-10), (hx-16, hy-6)], fill=pal["accent"])
        plait_p1 = (hx+16, hy-10); plait_p2 = (hx+34, hy-22)
        draw_cel_capsule(draw, plait_p1, plait_p2, 6, 4, hair_bands)
    
    elif cls == "thief":
        # 头巾 + 面罩
        turban = []
        for i in range(37):
            a = math.pi * i / 36
            r = 26 + math.sin(a*4) * 3
            turban.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        turban.extend([(hx-24, hy-4), (hx+24, hy-4)])
        draw.polygon(turban, fill=hair_bands[2])
        shadow_t = []
        for i in range(37):
            a = math.pi * i / 36
            r = 20 + math.sin(a*4) * 2
            shadow_t.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        shadow_t.extend([(hx-20, hy-4), (hx+20, hy-4)])
        draw.polygon(shadow_t, fill=hair_bands[1])
        for i in range(int(37*0.3), int(37*0.7)):
            a = math.pi * i / 36
            draw.point((int(hx - 26.5 * math.cos(a)), int(hy - 2 - 26.5 * math.sin(a))), fill=rim)
        tail = []
        for i in range(10):
            t = i / 9
            tail.append((hx + 20 + t*14, hy - 4 + t*18 + math.sin(t*math.pi)*4))
        tail.reverse()
        for i in range(10):
            t = i / 9
            tail.append((hx + 24 + t*14, hy - 4 + t*18 + math.sin(t*math.pi)*4 + 4))
        draw.polygon(tail, fill=hair_bands[2])
        mask = [(hx-22, hy-2), (hx-24, hy+22), (hx-18, hy+26),
                (hx, hy+28), (hx+18, hy+26), (hx+24, hy+22), (hx+22, hy-2)]
        draw.polygon(mask, fill=hair_bands[0])
        draw.polygon([(hx-22, hy-2), (hx-24, hy+8), (hx+24, hy+8), (hx+22, hy-2)], fill=hair_bands[1])
    
    elif cls == "bomber":
        # 短寸 + 护目镜挂脖子
        hair = []
        for i in range(33):
            a = math.pi * i / 32
            r = 22 + math.sin(a*5) * 1
            hair.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        hair.extend([(hx-22, hy+6), (hx+22, hy+6)])
        draw.polygon(hair, fill=hair_bands[2])
        shadow = []
        for i in range(33):
            a = math.pi * i / 32
            r = 18 + math.sin(a*5)
            shadow.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        draw.polygon(shadow, fill=hair_bands[1])
        # 护目镜挂在头顶
        gog_y = hy - 2
        draw.ellipse([hx-16, gog_y-6, hx-4, gog_y+6], fill=(40,40,40), outline=(20,20,20))
        draw.ellipse([hx+4, gog_y-6, hx+16, gog_y+6], fill=(40,40,40), outline=(20,20,20))
        draw.rectangle([hx-4, gog_y-2, hx+4, gog_y+2], fill=(60,60,60))
        # 护目镜镜片反光
        draw.ellipse([hx-14, gog_y-4, hx-6, gog_y+2], fill=(255, 180, 60))
        draw.ellipse([hx+6, gog_y-4, hx+14, gog_y+2], fill=(255, 180, 60))
    
    elif cls == "bounty_hunter":
        # 宽檐帽
        # 帽檐 (大椭圆)
        brim_pts = []
        for i in range(41):
            a = 2 * math.pi * i / 40
            brim_pts.append((hx + 34 * math.cos(a), hy - 4 + 14 * math.sin(a)))
        draw.polygon(brim_pts, fill=hair_bands[2])
        # 帽檐阴影
        shadow_brim = []
        for i in range(41):
            a = 2 * math.pi * i / 40
            if math.sin(a) < 0.3:
                shadow_brim.append((hx + 34 * math.cos(a), hy - 4 + 14 * math.sin(a)))
        if len(shadow_brim) >= 3:
            shadow_brim.append((hx, hy-4))
            draw.polygon(shadow_brim, fill=hair_bands[1])
        # 帽冠 (半圆)
        crown = []
        for i in range(21):
            a = math.pi * i / 20
            crown.append((hx - 20 * math.cos(a), hy - 18 - 18 * math.sin(a)))
        crown.extend([(hx-20, hy-4), (hx+20, hy-4)])
        draw.polygon(crown, fill=hair_bands[2])
        # 帽冠阴影
        crown_shadow = []
        for i in range(21):
            a = math.pi * i / 20
            if math.cos(a) < 0.3:
                crown_shadow.append((hx - 16 * math.cos(a), hy - 18 - 14 * math.sin(a)))
        if len(crown_shadow) >= 3:
            crown_shadow.append((hx, hy-18))
            draw.polygon(crown_shadow, fill=hair_bands[1])
        # 帽带
        draw.rectangle([hx-22, hy-6, hx+22, hy-2], fill=pal["accent"])
    
    elif cls == "cyborg":
        # 半机械头 (金属+光头+电子眼)
        # 皮肤部分 (后上方)
        draw_cel_ellipse(draw, hx, hy-6, 18, 16, hair_bands if hair_bands[2] != (18,22,28) else skin_bands, LIGHT_N, 0)
        # 金属半球 (前下方) — 机械头盖
        metal_bands = [(30,34,40),(55,62,72),(95,105,120),(130,142,160),(180,195,215)]
        metal_pts = []
        steps = 24
        for i in range(steps+1):
            a = math.pi * i / steps  # 下半圆从右到左
            metal_pts.append((hx + 22 * math.cos(a), hy + 6 - 12 * math.sin(a)))
        metal_pts.extend([(hx-22, hy+8), (hx+22, hy+8)])
        draw.polygon(metal_pts, fill=metal_bands[2])
        # 金属光影
        metal_shadow = []
        for i in range(steps+1):
            a = math.pi * i / steps
            if math.cos(a) < 0.2:
                metal_shadow.append((hx + 18 * math.cos(a), hy + 6 - 8 * math.sin(a)))
        if len(metal_shadow) >= 3:
            metal_shadow.append((hx, hy+6))
            draw.polygon(metal_shadow, fill=metal_bands[1])
        # 金属 rim
        draw.line([(hx-18, hy+2), (hx+18, hy+2)], fill=metal_bands[4], width=1)
        # 右侧电子眼 (方形红光)
        draw.rectangle([hx+6, hy-4, hx+18, hy+4], fill=(255, 0, 0), outline=(100,0,0))
        draw.rectangle([hx+9, hy-2, hx+15, hy+2], fill=(255, 120, 120))
        # 左侧人类眼 (小)
        draw.ellipse([hx-14, hy-4, hx-6, hy+2], fill=eye_color)
    
    elif cls == "death_knight":
        # 骷髅头盔 + 暗绿火焰
        # 头盔 (金属+骷髅面)
        helm = []
        for i in range(41):
            a = math.pi * i / 40
            r = 24
            helm.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        helm.extend([(hx-22, hy+4), (hx-18, hy-4), (hx-12, hy+10), 
                     (hx+12, hy+10), (hx+18, hy-4), (hx+22, hy+4)])
        draw.polygon(helm, fill=pal["body_bands"][2])
        helm_shadow = []
        for i in range(41):
            a = math.pi * i / 40
            if math.cos(a) < 0.3:
                helm_shadow.append((hx - 20 * math.cos(a), hy - 4 - 20 * math.sin(a)))
        helm_shadow.append((hx, hy-4))
        draw.polygon(helm_shadow, fill=pal["body_bands"][0])
        # 骷髅面 (白色)
        draw.ellipse([hx-16, hy-4, hx+16, hy+16], fill=(230, 225, 210))
        # 眼窝 (黑)
        draw.ellipse([hx-12, hy-2, hx-4, hy+6], fill=(0,0,0))
        draw.ellipse([hx+4, hy-2, hx+12, hy+6], fill=(0,0,0))
        # 眼窝中绿火
        draw.ellipse([hx-10, hy, hx-6, hy+5], fill=(50, 255, 80))
        draw.ellipse([hx+6, hy, hx+10, hy+5], fill=(50, 255, 80))
        # 牙齿
        for i in range(5):
            tx = hx - 8 + i*4
            draw.rectangle([tx, hy+10, tx+2, hy+14], fill=(230,225,210))
        # 头盔顶角 (尖刺)
        draw.polygon([(hx, hy-30), (hx-8, hy-18), (hx+8, hy-18)], fill=pal["body_bands"][1])
        # 暗绿火焰 (颈后飘起)
        for i in range(4):
            fx = hx - 18 + i*6; fy = hy - 20 - i*8
            c = [(50,255,80), (30,200,60), (20,150,40), (15,100,30)][i]
            sz = 6 - i
            draw.ellipse([fx-sz, fy-sz, fx+sz, fy+sz], fill=c)
    
    elif cls == "engineer":
        # 鸭舌帽 + 护目镜
        # 帽身
        cap = []
        for i in range(25):
            a = math.pi * i / 24
            r = 22 + math.sin(a*3) * 1
            cap.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        cap.extend([(hx-22, hy+2), (hx+22, hy+2)])
        draw.polygon(cap, fill=hair_bands[2])
        # 帽檐 (向右前突出)
        visor = [(hx-22, hy+2), (hx+22, hy+2), 
                 (hx+30, hy+10), (hx-22, hy+8)]
        draw.polygon(visor, fill=hair_bands[1])
        draw.polygon([(hx-22, hy+2), (hx+22, hy+2), (hx+30, hy+10)], fill=hair_bands[0])
        # 护目镜挂在头顶
        gog_y = hy - 6
        draw.ellipse([hx-18, gog_y-4, hx-4, gog_y+6], fill=(50,40,30), outline=None)
        draw.ellipse([hx+4, gog_y-4, hx+18, gog_y+6], fill=(50,40,30), outline=None)
        draw.rectangle([hx-4, gog_y, hx+4, gog_y+2], fill=(80,60,40))
        # 护目镜反光
        draw.ellipse([hx-16, gog_y-2, hx-8, gog_y+2], fill=(230,230,230))
        draw.ellipse([hx+8, gog_y-2, hx+16, gog_y+2], fill=(230,230,230))
    
    elif cls == "hacker":
        # 兜帽 (深帽兜) + 发光眼罩
        hood = []
        for i in range(41):
            a = math.pi * i / 40
            r = 26
            hood.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        hood.extend([(hx-24, hy+8), (hx-20, hy-2), (hx, hy-36), (hx+20, hy-2), (hx+24, hy+8)])
        draw.polygon(hood, fill=pal["body_bands"][2])
        hood_shadow = []
        for i in range(41):
            a = math.pi * i / 40
            if math.cos(a) < 0.2:
                hood_shadow.append((hx - 22 * math.cos(a), hy - 4 - 22 * math.sin(a)))
        hood_shadow.append((hx, hy-4))
        draw.polygon(hood_shadow, fill=pal["body_bands"][0])
        # 兜帽 rim (绿边)
        draw.arc([hx-26, hy-34, hx+26, hy+10], 200, 340, fill=(0, 255, 90), width=2)
        # 发光眼罩 (遮眼条)
        visor = [(hx-22, hy-4), (hx+22, hy-4), (hx+20, hy+2), (hx-20, hy+2)]
        draw.polygon(visor, fill=(0, 0, 0))
        visor2 = [(hx-20, hy-3), (hx+20, hy-3), (hx+18, hy+1), (hx-18, hy+1)]
        draw.polygon(visor2, fill=(0, 255, 90))
        # 数据流
        for i in range(6):
            dx_d = hx - 15 + i*6
            draw.line([(dx_d, hy+4), (dx_d+2, hy+10)], fill=(0, 255, 90), width=1)
    
    elif cls == "mech_pilot":
        # 飞行头盔 + 护目镜
        helm = []
        for i in range(41):
            a = math.pi * i / 40
            r = 24
            helm.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        helm.extend([(hx-22, hy+6), (hx+22, hy+6)])
        draw.polygon(helm, fill=pal["body_bands"][2])
        helm_shadow = []
        for i in range(41):
            a = math.pi * i / 40
            if math.cos(a) < 0.3:
                helm_shadow.append((hx - 20 * math.cos(a), hy - 2 - 20 * math.sin(a)))
        helm_shadow.append((hx, hy-2))
        draw.polygon(helm_shadow, fill=pal["body_bands"][0])
        # 护目镜 (大透明面)
        visor = [(hx-20, hy-6), (hx+20, hy-6), (hx+18, hy+6), (hx-18, hy+6)]
        draw.polygon(visor, fill=(40, 60, 100))
        # 护目镜反光
        reflect = [(hx-16, hy-5), (hx+8, hy-5), (hx+6, hy-1), (hx-14, hy-1)]
        draw.polygon(reflect, fill=(120, 160, 220))
        # 通讯耳机
        draw.ellipse([hx-26, hy-6, hx-20, hy+4], fill=(40,50,70))
        draw.ellipse([hx+20, hy-6, hx+26, hy+4], fill=(40,50,70))
        # 麦克风 (从左耳边伸出)
        draw.line([(hx-26, hy), (hx-34, hy-4)], fill=(50,60,80), width=2)
        draw.ellipse([hx-36, hy-6, hx-32, hy-2], fill=(60,70,90))
    
    elif cls == "necromancer":
        # 暗色兜帽 + 骷髅装饰
        hood = []
        for i in range(41):
            a = math.pi * i / 40
            r = 28
            hood.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        hood.extend([(hx-26, hy+4), (hx, hy-44), (hx+26, hy+4)])
        draw.polygon(hood, fill=pal["body_bands"][2])
        hood_inner = []
        for i in range(41):
            a = math.pi * i / 40
            r = 22
            hood_inner.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        hood_inner.extend([(hx-22, hy+4), (hx+22, hy+4)])
        draw.polygon(hood_inner, fill=pal["body_bands"][0])
        # 兜帽 rim (紫色)
        for i in range(int(41*0.3), int(41*0.7)):
            a = math.pi * i / 40
            draw.point((int(hx - 28.5 * math.cos(a)), int(hy - 4 - 28.5 * math.sin(a))), 
                      fill=pal["rim"])
        # 兜帽下露出的脸 (苍白)
        draw.ellipse([hx-14, hy-2, hx+14, hy+12], fill=(200, 210, 195))
        # 眼窝
        draw.ellipse([hx-10, hy, hx-4, hy+6], fill=(0,0,0))
        draw.ellipse([hx+4, hy, hx+10, hy+6], fill=(0,0,0))
        # 紫色眼睛
        draw.ellipse([hx-9, hy+2, hx-5, hy+5], fill=(180, 80, 220))
        draw.ellipse([hx+5, hy+2, hx+9, hy+5], fill=(180, 80, 220))
        # 小型骷髅挂饰 (垂在胸前)
        draw.ellipse([hx-4, hy+16, hx+4, hy+24], fill=(220, 215, 200))
        draw.ellipse([hx-2, hy+18, hx-1, hy+20], fill=(0,0,0))
        draw.ellipse([hx+1, hy+18, hx+2, hy+20], fill=(0,0,0))
    
    elif cls == "priest":
        # 长发 + 金色头饰 (光环)
        hair = []
        for i in range(33):
            a = math.pi * i / 32
            r = 24 + math.sin(a*2) * 2
            hair.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        hair.extend([(hx-28, hy+8), (hx-26, hy+28), (hx+26, hy+28), (hx+28, hy+8)])
        draw.polygon(hair, fill=hair_bands[2])
        shadow_h = []
        for i in range(33):
            a = math.pi * i / 32
            r = 20 + math.sin(a*2) * 1.5
            shadow_h.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        draw.polygon(shadow_h, fill=hair_bands[1])
        # 头饰 (金色圆环在头后方)
        halo_r = 30
        for i in range(3):
            rr = halo_r + i*2
            c = [(180,150,80), (220,195,120), (255,225,140)][i]
            draw.ellipse([hx-rr, hy-rr-4, hx+rr, hy+rr-4], outline=c, width=2)
        # 光环装饰点
        for i in range(8):
            ang_h = 2 * math.pi * i / 8
            px_h = hx + halo_r * math.cos(ang_h)
            py_h = hy + halo_r * math.sin(ang_h) - 4
            draw.ellipse([px_h-2, py_h-2, px_h+2, py_h+2], fill=(255, 215, 100))
    
    elif cls == "qi_adept":
        # 黑色长发 + 丸子头 (顶)
        # 丸子头
        draw_cel_ellipse(draw, hx, hy-32, 12, 12, hair_bands, LIGHT_N, 0)
        # 主头发 (两侧垂下)
        hair = []
        for i in range(33):
            a = math.pi * i / 32
            r = 22 + math.sin(a*2) * 1
            hair.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        hair.extend([(hx-24, hy+8), (hx-28, hy+22), (hx-22, hy+28), 
                     (hx+22, hy+28), (hx+28, hy+22), (hx+24, hy+8)])
        draw.polygon(hair, fill=hair_bands[2])
        shadow_h = []
        for i in range(33):
            a = math.pi * i / 32
            r = 18 + math.sin(a*2) * 1
            shadow_h.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        draw.polygon(shadow_h, fill=hair_bands[1])
        # 束发带 (红色)
        draw.rectangle([hx-20, hy-8, hx+20, hy-2], fill=(220, 40, 40))
    
    elif cls == "runeward":
        # 长发束起 + 符文头饰
        hair = []
        for i in range(33):
            a = math.pi * i / 32
            r = 23 + math.sin(a*3) * 1
            hair.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        hair.extend([(hx-24, hy+6), (hx-20, hy+20), (hx+20, hy+20), (hx+24, hy+6)])
        draw.polygon(hair, fill=hair_bands[2])
        shadow_h = []
        for i in range(33):
            a = math.pi * i / 32
            r = 19 + math.sin(a*3) * 1
            shadow_h.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        draw.polygon(shadow_h, fill=hair_bands[1])
        # 符文头饰 (前额上的发光符文)
        draw.rectangle([hx-16, hy-28, hx+16, hy-22], fill=(60, 80, 120))
        draw.rectangle([hx-14, hy-27, hx+14, hy-23], fill=(80, 100, 150))
        # 符文发光
        rune_positions = [(-10, -25), (0, -26), (10, -25)]
        for rx_r, ry_r in rune_positions:
            draw.ellipse([hx+rx_r-2, hy+ry_r-2, hx+rx_r+2, hy+ry_r+2], fill=(120, 200, 255))
    
    elif cls == "sniper":
        # 短发 + 伪装迷彩头带 + 瞄准镜面罩
        hair = []
        for i in range(33):
            a = math.pi * i / 32
            r = 22 + math.sin(a*4) * 1
            hair.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        hair.extend([(hx-22, hy+4), (hx+22, hy+4)])
        draw.polygon(hair, fill=hair_bands[2])
        shadow_h = []
        for i in range(33):
            a = math.pi * i / 32
            r = 18 + math.sin(a*4) * 1
            shadow_h.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        draw.polygon(shadow_h, fill=hair_bands[1])
        # 迷彩头带
        draw.rectangle([hx-22, hy-6, hx+22, hy-2], fill=(55, 65, 45))
        # 迷彩斑点
        for dx_s in [-16, -8, 0, 8, 14]:
            draw.ellipse([hx+dx_s-2, hy-5, hx+dx_s+2, hy-3], fill=(30,40,25))
            draw.ellipse([hx+dx_s-1, hy-4, hx+dx_s+1, hy-2], fill=(80,90,60))
        # 瞄准镜面罩 (下半脸黑罩)
        mask = [(hx-18, hy-2), (hx-20, hy+22), (hx-14, hy+26),
                (hx, hy+28), (hx+14, hy+26), (hx+20, hy+22), (hx+18, hy-2)]
        draw.polygon(mask, fill=(10, 12, 14))
        draw.polygon([(hx-18, hy-2), (hx-20, hy+6), (hx+20, hy+6), (hx+18, hy-2)], fill=(20, 22, 26))

    # 3. 眼睛 (所有职业通用)
    eye_rot = math.radians(head_rot)
    for ex_off, ey_off in [(-8, -2), (8, -2)]:
        epx = hx + ex_off * math.cos(eye_rot) - ey_off * math.sin(eye_rot)
        epy = hy + ex_off * math.sin(eye_rot) + ey_off * math.cos(eye_rot)
        draw.arc([epx-6, epy-4, epx+6, epy+6], 200, 340, fill=skin_bands[0], width=1)
        draw.ellipse([epx-4, epy-3, epx+4, epy+3], fill=skin_bands[4])
        draw.ellipse([epx-2.5, epy-2.5, epx+2.5, epy+2.5], fill=eye_color)
        draw.ellipse([epx-1.5, epy-1.5, epx+1.5, epy+1.5], fill=(20, 15, 12))
        draw.ellipse([epx-0.5, epy-2, epx+1.5, epy-0.5], fill=(255, 255, 255))
    
    # 4. 嘴 (除了 thief/死亡骑士有面罩/骷髅面)
    if cls not in ["thief", "cyborg", "death_knight", "hacker", "sniper"]:
        mouth_cx = hx; mouth_cy = hy + 10
        draw.arc([mouth_cx-5, mouth_cy+2, mouth_cx+5, mouth_cy+8], 10, 170, 
                 fill=skin_bands[0], width=2)
        lip_color = (160, 75, 65) if cls not in ["priest"] else (180, 100, 85)
        draw.arc([mouth_cx-5, mouth_cy-2, mouth_cx+5, mouth_cy+4], 10, 170, 
                 fill=lip_color, width=2)


# ============================================================
# 脖子
# ============================================================
def draw_neck_cel(draw, head_pos, torso_pos, skin_bands):
    hx, hy = head_pos
    tx, ty = torso_pos
    mid_x = (hx + tx) / 2
    draw.line([(hx-8, hy+18), (tx-6, ty-8)], fill=skin_bands[0], width=8)
    draw.line([(hx-6, hy+18), (tx-4, ty-8)], fill=skin_bands[2], width=5)
    draw.line([(hx+2, hy+18), (tx+4, ty-8)], fill=skin_bands[3], width=3)

# ============================================================
# 16 种胸甲装饰
# ============================================================
def draw_torso_folds(draw, pelvis_pos, torso_pos, body_bands, accent, cls, pal):
    px, py = pelvis_pos
    tx, ty = torso_pos
    mid_x = (px + tx) / 2
    mid_y = (py + ty) / 2
    
    # 通用: 中央分割暗线 + 腰带
    draw.line([(mid_x - 2, mid_y + 15), (mid_x - 2, py - 8)], fill=body_bands[0], width=2)
    draw.line([(mid_x + 2, mid_y + 15), (mid_x + 2, py - 8)], fill=body_bands[0], width=2)
    draw.rectangle([px-30, py-4, px+30, py+8], fill=body_bands[0])
    draw.rectangle([px-30, py-4, px+30, py-2], fill=body_bands[1])
    draw.ellipse([px-4, py-1, px+4, py+5], fill=accent)
    
    # 通用肩甲接缝
    for side_x in [tx - 18, tx + 18]:
        draw.line([(side_x, ty + 14), (side_x + 3, mid_y + 20)], fill=body_bands[0], width=1)
    
    # 职业专属胸甲装饰
    if cls == "warrior":
        for sx in [tx - 26, tx + 26]:
            for sy_off in [6, 14]:
                draw.ellipse([sx-3, ty+sy_off-3, sx+3, ty+sy_off+3], fill=accent)
        draw.polygon([(tx, ty+8), (tx-5, ty+18), (tx, ty+28), (tx+5, ty+18)], fill=accent)
    
    elif cls == "mage":
        draw.pieslice([tx-40, ty-6, tx+40, ty+20], 0, 180, fill=body_bands[0])
        draw.text((tx-8, ty+8), "❖", fill=accent)
    
    elif cls == "archer":
        draw.polygon([(tx, ty+4), (tx+14, ty+14), (tx, ty+28), (tx-14, ty+14)], fill=accent)
        for sx in [tx - 22, tx + 22]:
            draw.line([(sx, ty+8), (sx+2, ty+22)], fill=accent, width=2)
    
    elif cls == "thief":
        for i in range(4):
            cx_i = tx - 12 + i * 8
            for j in range(2):
                cy_i = ty + 10 + j * 10
                draw.ellipse([cx_i-2, cy_i-2, cx_i+2, cy_i+2], fill=accent)
        draw.rectangle([tx-22, ty-4, tx+22, ty+12], fill=body_bands[0])
    
    elif cls == "bomber":
        # 炸弹腰带
        for i in range(6):
            bx_b = px - 28 + i * 10
            draw.rectangle([bx_b-3, py-16, bx_b+3, py-6], fill=body_bands[0])
            draw.rectangle([bx_b-2, py-14, bx_b+2, py-8], fill=accent)
        # 胸上炸弹挂
        draw.rectangle([tx-6, ty+6, tx+6, ty+22], fill=(60, 50, 40))
        draw.ellipse([tx-5, ty+4, tx+5, ty+14], fill=(60, 56, 50))
    
    elif cls == "bounty_hunter":
        # 子弹带斜跨
        draw.line([(tx-22, ty+6), (tx+22, ty+28)], fill=body_bands[0], width=4)
        draw.line([(tx-20, ty+6), (tx+20, ty+28)], fill=body_bands[1], width=2)
        # 子弹
        for i in range(5):
            t = i / 4
            bx_b = tx - 22 + (22+22)*t; by_b = ty + 6 + (28-6)*t
            draw.ellipse([bx_b-2, by_b-3, bx_b+2, by_b+3], fill=accent)
        # 肩章
        for sx in [tx - 28, tx + 28]:
            draw.rectangle([sx-6, ty-6, sx+6, ty+8], fill=accent)
    
    elif cls == "cyborg":
        # 金属胸甲 + 能量核心
        draw.rectangle([tx-26, ty+4, tx+26, mid_y+22], fill=body_bands[2])
        draw.rectangle([tx-24, ty+6, tx+24, mid_y+20], fill=body_bands[1])
        # 能量核心 (胸部中央)
        for i, rg in enumerate([12, 8, 4]):
            c = [(0,180,180), (0,230,230), (255,255,255)][i]
            draw.ellipse([tx-rg, ty+12-rg, tx+rg, ty+12+rg], fill=c)
        # 金属接缝
        for dx_m in [-14, 14]:
            draw.line([(tx+dx_m, ty+6), (tx+dx_m, mid_y+20)], fill=body_bands[0], width=1)
        # 左上机械接口
        draw.rectangle([tx-32, ty+4, tx-22, ty+18], fill=(80,88,100))
        draw.ellipse([tx-29, ty+8, tx-25, ty+12], fill=(0,220,220))
    
    elif cls == "death_knight":
        # 黑色符文铠甲
        draw.rectangle([tx-26, ty+4, tx+26, mid_y+22], fill=body_bands[0])
        draw.rectangle([tx-24, ty+6, tx+24, mid_y+20], fill=body_bands[1])
        # 骷髅胸饰
        draw.ellipse([tx-10, ty+6, tx+10, ty+22], fill=(230, 225, 210))
        draw.ellipse([tx-6, ty+10, tx-3, ty+14], fill=(0,0,0))
        draw.ellipse([tx+3, ty+10, tx+6, ty+14], fill=(0,0,0))
        # 暗绿符文
        draw.rectangle([tx-18, ty+4, tx-14, mid_y+18], fill=(50, 255, 80))
        draw.rectangle([tx+14, ty+4, tx+18, mid_y+18], fill=(50, 255, 80))
    
    elif cls == "engineer":
        # 工具腰带 + 护目镜挂
        for i in range(4):
            tx_t = tx - 22 + i * 14
            draw.rectangle([tx_t-4, ty+14, tx_t+4, ty+28], fill=body_bands[0])
            draw.rectangle([tx_t-3, ty+16, tx_t+3, ty+26], fill=accent)
        # 肩甲 (方形金属板)
        for sx in [tx - 26, tx + 26]:
            draw.rectangle([sx-10, ty-6, sx+10, ty+8], fill=(120, 130, 140))
            draw.rectangle([sx-8, ty-4, sx+8, ty+6], fill=(140, 150, 160))
    
    elif cls == "hacker":
        # 深色风衣 + 数据线
        draw.rectangle([tx-28, ty+2, tx+28, mid_y+24], fill=body_bands[2])
        # 数据线 (从肩延伸)
        for dx_w in [-18, 18]:
            draw.line([(tx+dx_w, ty+8), (tx+dx_w*0.4, mid_y+20)], fill=(0, 255, 90), width=2)
            draw.line([(tx+dx_w, ty+10), (tx+dx_w*0.3, mid_y+22)], fill=(100, 255, 140), width=1)
        # 胸上发光符文
        draw.rectangle([tx-6, ty+10, tx+6, ty+22], fill=(0, 30, 18))
        draw.ellipse([tx-3, ty+12, tx+3, ty+20], fill=(0, 255, 90))
    
    elif cls == "mech_pilot":
        # 驾驶服 + 管线
        draw.rectangle([tx-26, ty+4, tx+26, mid_y+22], fill=body_bands[2])
        draw.rectangle([tx-24, ty+6, tx+24, mid_y+20], fill=body_bands[1])
        # 驾驶服拉链 (中央)
        draw.line([(tx, ty+6), (tx, mid_y+20)], fill=(60, 70, 85), width=2)
        draw.line([(tx, ty+6), (tx, mid_y+20)], fill=(80, 95, 115), width=1)
        # 胸前管线
        for dx_p in [-16, 16]:
            draw.line([(tx+dx_p, ty+8), (tx+dx_p*0.5, mid_y+20)], fill=(60, 100, 160), width=3)
        # 胸口圆形仪表
        draw.ellipse([tx-8, ty+10, tx+8, ty+22], fill=(40, 55, 80))
        draw.ellipse([tx-5, ty+13, tx+5, ty+19], fill=(80, 180, 255))
        draw.ellipse([tx-2, ty+15, tx+2, ty+17], fill=(255, 255, 255))
    
    elif cls == "necromancer":
        # 黑袍 V 形领口 + 骷髅胸饰
        draw.pieslice([tx-44, ty-4, tx+44, ty+22], 0, 180, fill=body_bands[0])
        draw.pieslice([tx-40, ty-2, tx+40, ty+20], 0, 180, fill=body_bands[1])
        # 骷髅头 (胸前)
        draw.ellipse([tx-12, ty+8, tx+12, ty+24], fill=(220, 215, 200))
        draw.ellipse([tx-8, ty+12, tx-4, ty+17], fill=(0,0,0))
        draw.ellipse([tx+4, ty+12, tx+8, ty+17], fill=(0,0,0))
        # 紫色光晕
        for i, rg in enumerate([18, 22, 28]):
            c = [(180,80,220), (120,40,160), None][i]
            if c:
                draw.ellipse([tx-rg, ty+6-rg, tx+rg, ty+6+rg], outline=c, width=1)
    
    elif cls == "priest":
        # 白袍 V 形领口 + 金色十字架
        draw.pieslice([tx-44, ty-4, tx+44, ty+24], 0, 180, fill=body_bands[0])
        draw.pieslice([tx-40, ty-2, tx+40, ty+22], 0, 180, fill=(230, 215, 185))
        # 金色十字架 (胸上)
        cx_c, cy_c = tx, ty + 16
        draw.rectangle([cx_c-3, cy_c-14, cx_c+3, cy_c+14], fill=(255, 215, 100))
        draw.rectangle([cx_c-10, cy_c-4, cx_c+10, cy_c+2], fill=(255, 215, 100))
        draw.rectangle([cx_c-2, cy_c-12, cx_c+2, cy_c+12], fill=(255, 230, 140))
    
    elif cls == "qi_adept":
        # 太极服 + 太极图
        draw.rectangle([tx-30, ty+2, tx+30, mid_y+24], fill=body_bands[2])
        # 领口
        draw.pieslice([tx-28, ty-4, tx+28, ty+16], 0, 180, fill=body_bands[0])
        # 红色盘扣 (3个)
        for i in range(3):
            cx_k = tx; cy_k = ty + 12 + i * 12
            draw.ellipse([cx_k-3, cy_k-3, cx_k+3, cy_k+3], fill=(220, 40, 40))
        # 太极图 (左胸)
        tai_x = tx - 18; tai_y = ty + 16
        draw.ellipse([tai_x-10, tai_y-10, tai_x+10, tai_y+10], fill=(240, 240, 240))
        draw.pieslice([tai_x-10, tai_y-10, tai_x+10, tai_y+10], 0, 180, fill=(20, 20, 20))
        draw.ellipse([tai_x-5, tai_y-5, tai_x+5, tai_y+5], fill=(240, 240, 240))
        draw.pieslice([tai_x-5, tai_y-5, tai_x+5, tai_y+5], 0, 180, fill=(20, 20, 20))
        draw.ellipse([tai_x-2, tai_y-7, tai_x+2, tai_y-3], fill=(240, 240, 240))
        draw.ellipse([tai_x-2, tai_y+3, tai_x+2, tai_y+7], fill=(20, 20, 20))
    
    elif cls == "runeward":
        # 符文铠甲 + 发光符文
        draw.rectangle([tx-28, ty+2, tx+28, mid_y+24], fill=body_bands[2])
        draw.rectangle([tx-26, ty+4, tx+26, mid_y+22], fill=body_bands[1])
        # 符文刻线 (3条垂直)
        for dx_r in [-18, 0, 18]:
            draw.line([(tx+dx_r, ty+4), (tx+dx_r, mid_y+22)], fill=accent, width=1)
        # 符文发光点
        rune_pattern = [(-18, 10), (-18, 22), (0, 16), (18, 10), (18, 22)]
        for rx_r, ry_r in rune_pattern:
            draw.ellipse([tx+rx_r-2, ty+ry_r-2, tx+rx_r+2, ty+ry_r+2], fill=accent)
        # 肩甲金属板
        for sx in [tx - 30, tx + 30]:
            draw.rectangle([sx-10, ty-8, sx+10, ty+8], fill=(120, 140, 180))
            draw.rectangle([sx-8, ty-6, sx+8, ty+6], fill=(140, 165, 210))
    
    elif cls == "sniper":
        # 迷彩作战服
        draw.rectangle([tx-28, ty+2, tx+28, mid_y+24], fill=body_bands[2])
        # 迷彩斑点 (随机但固定)
        import random
        rng = random.Random(42)
        for _ in range(15):
            cx_c = tx - 26 + rng.randint(0, 52)
            cy_c = ty + 4 + rng.randint(0, int(mid_y+20 - (ty+4)))
            sz = rng.randint(3, 8)
            col = [(35,42,30), (55,65,45), (25,30,22), (70,50,40)][rng.randint(0,3)]
            draw.ellipse([cx_c-sz, cy_c-sz, cx_c+sz, cy_c+sz], fill=col)
        # 肩章 (红色)
        for sx in [tx - 30, tx + 30]:
            draw.rectangle([sx-10, ty-6, sx+10, ty+6], fill=(55, 55, 55))
            draw.rectangle([sx-8, ty-4, sx+8, ty+4], fill=(180, 40, 40))


# ============================================================
# 完整绘制一个赛璐璐角色帧
# ============================================================
def draw_character_cel(draw, bone_transforms, cls, facing=1.0, pose_info=None):
    pal = CLASS_PALETTE[cls]
    body_bands = pal["body_bands"]
    skin_bands = pal["skin_bands"]
    outline = pal["outline"]
    rim = pal["rim"]
    accent = pal["accent"]
    
    def bone_segment(name):
        parent = PARENT[name]
        if parent is None: return bone_transforms[name][1], bone_transforms[name][1]
        return bone_transforms[parent][1], bone_transforms[name][1]
    
    # 1. 腿
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        draw_cel_capsule(draw, p1, p2, 17, 13, body_bands)
    
    # 2. 骨盆
    px, py = bone_transforms["pelvis"][1]
    draw_cel_ellipse(draw, px, py, 28, 24, body_bands, LIGHT_N, 0)
    
    # 3. 躯干
    torso_pelvis = bone_transforms["pelvis"][1]
    torso_shoulder = bone_transforms["torso"][1]
    draw_cel_capsule(draw, torso_pelvis, torso_shoulder, 42, 38, body_bands)
    draw_torso_folds(draw, torso_pelvis, torso_shoulder, body_bands, accent, cls, pal)
    
    # 4. 肩膀装甲
    shoulder_pos = bone_transforms["torso"][1]
    for arm_name in ["arm_l", "arm_r"]:
        arm_pos = bone_transforms[arm_name][1]
        sx = (shoulder_pos[0] + arm_pos[0]) / 2
        sy = (shoulder_pos[1] + arm_pos[1]) / 2 - 4
        draw_cel_ellipse(draw, sx, sy, 16, 14, body_bands, LIGHT_N, 0)
        draw.arc([sx-17, sy-15, sx+17, sy+15], 190, 350, fill=accent, width=2)
    
    # 5. 手臂
    for arm in ["arm_l", "arm_r"]:
        p1, p2 = bone_segment(arm)
        draw_cel_capsule(draw, p1, p2, 13, 9, body_bands)
        hx, hy = p2
        # cyborg: 右臂是机械臂, 不画手 (已在武器里画)
        if cls != "cyborg" or arm != "arm_r":
            draw_cel_ellipse(draw, hx, hy, 10, 10, skin_bands, LIGHT_N, 0)
    
    # 6. 武器 (右手)
    arm_r_end = bone_transforms["arm_r"][1]
    arm_r_rot = bone_transforms["arm_r"][0]
    draw_weapon_cel(draw, arm_r_end, arm_r_rot, cls, facing, pal)
    
    # 7. 脖子
    head_pos = bone_transforms["head"][1]
    torso_pos = bone_transforms["torso"][1]
    draw_neck_cel(draw, head_pos, torso_pos, skin_bands)
    
    # 8. 头 + 发型 + 面部
    draw_head_cel(draw, head_pos, bone_transforms["head"][0], cls, pal)
    
    # ---- 轮廓描边 ----
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        draw_capsule_outline(draw, p1, p2, 17, 13, outline, 2)
    draw.ellipse([px-28, py-24, px+28, py+24], outline=outline, width=2)
    draw_capsule_outline(draw, torso_pelvis, torso_shoulder, 42, 38, outline, 2)
    for arm_name in ["arm_l", "arm_r"]:
        arm_pos = bone_transforms[arm_name][1]
        sx = (shoulder_pos[0] + arm_pos[0]) / 2
        sy = (shoulder_pos[1] + arm_pos[1]) / 2 - 4
        draw.ellipse([sx-16, sy-14, sx+16, sy+14], outline=outline, width=2)
    for arm in ["arm_l", "arm_r"]:
        p1, p2 = bone_segment(arm)
        draw_capsule_outline(draw, p1, p2, 13, 9, outline, 2)
    hx, hy = head_pos
    draw.ellipse([hx-22, hy-24, hx+22, hy+22], outline=outline, width=2)
    
    # ---- Rim Light 描边 ----
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        draw_rim_stroke(draw, p1, p2, 15, rim)
    
    # ---- 地面阴影 ----
    foot_y = py + 120
    for i, (w_s, dy_s) in enumerate([(55, 0), (48, 3), (40, 6)]):
        alpha = 60 - i*20
        s = Image.new("L", (1,1), alpha)  # just placeholder, we draw solid
        draw.ellipse([px-w_s, foot_y+dy_s, px+w_s, foot_y+14+dy_s], fill=(0, 0, 0))

# ============================================================
# 动作库
# ============================================================
def interp(kfs, t):
    ka, kb = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        if kfs[i][0] <= t <= kfs[i+1][0]: ka, kb = kfs[i], kfs[i+1]; break
    if ka == kb: return dict(ka[1])
    r = (t - ka[0]) / max(0.001, kb[0] - ka[0])
    r = 1 - (1 - r) ** 2.5
    out = {}
    for k in set(ka[1].keys()) | set(kb[1].keys()):
        ra = ka[1].get(k, 0); rb = kb[1].get(k, 0)
        out[k] = ra * (1 - r) + rb * r
    return out

def idle_frame(k):
    phase = math.sin(2 * math.pi * k / 4)
    return {
        "pelvis": phase * 1.5,
        "torso": -1 + phase * 1.5,
        "head": phase * 0.5,
        "arm_l": 6 + phase * 3,
        "arm_r": -6 - phase * 3,
        "leg_l": 0, "leg_r": 0,
    }

def run_frame(cls, k):
    phase = math.sin(2 * math.pi * k / 4)
    # 不同职业跑步姿态差异
    RUN_BASE = {
        "warrior": {"torso":4,"arm_l":-28,"arm_r":28,"leg_l":-34,"leg_r":34},
        "mage":    {"torso":3,"arm_l":-22,"arm_r":22,"leg_l":-28,"leg_r":28},
        "archer":  {"torso":3,"arm_l":-26,"arm_r":26,"leg_l":-32,"leg_r":32},
        "thief":   {"torso":5,"arm_l":-32,"arm_r":32,"leg_l":-36,"leg_r":36},
        "bomber":  {"torso":3,"arm_l":-24,"arm_r":24,"leg_l":-30,"leg_r":30},
        "bounty_hunter": {"torso":4,"arm_l":-26,"arm_r":26,"leg_l":-32,"leg_r":32},
        "cyborg":  {"torso":3,"arm_l":-20,"arm_r":20,"leg_l":-28,"leg_r":28},
        "death_knight": {"torso":5,"arm_l":-22,"arm_r":22,"leg_l":-28,"leg_r":28},
        "engineer": {"torso":3,"arm_l":-22,"arm_r":22,"leg_l":-28,"leg_r":28},
        "hacker":  {"torso":5,"arm_l":-30,"arm_r":30,"leg_l":-34,"leg_r":34},
        "mech_pilot": {"torso":3,"arm_l":-20,"arm_r":20,"leg_l":-26,"leg_r":26},
        "necromancer": {"torso":2,"arm_l":-20,"arm_r":20,"leg_l":-24,"leg_r":24},
        "priest":  {"torso":2,"arm_l":-18,"arm_r":18,"leg_l":-22,"leg_r":22},
        "qi_adept": {"torso":2,"arm_l":-20,"arm_r":20,"leg_l":-26,"leg_r":26},
        "runeward": {"torso":4,"arm_l":-24,"arm_r":24,"leg_l":-30,"leg_r":30},
        "sniper":  {"torso":4,"arm_l":-22,"arm_r":22,"leg_l":-28,"leg_r":28},
    }
    base = RUN_BASE.get(cls, {"torso":3,"arm_l":-24,"arm_r":24,"leg_l":-30,"leg_r":30})
    rots = {"pelvis": phase * 2.0}
    for n, v in base.items():
        rots[n] = v * (0.8 + phase * 0.4)
    return rots

def wave_frame(k):
    phase = math.sin(2 * math.pi * k / 4)
    return {"pelvis":0,"torso":phase*-3,"head":phase*-2,
            "arm_l":8+phase*6,"arm_r":-135-phase*20,"leg_l":0,"leg_r":0}

def cheer_frame(k):
    phases = [0.0, 1.0, 1.0, 0.3]; p = phases[k]
    return {"pelvis":0,"torso":-1-p*4,"head":2+p*5,
            "arm_l":55+p*95,"arm_r":-55-p*95,"leg_l":p*-3,"leg_r":p*3}

# 通用攻击/技能插值
def _attack_kfs(cls):
    """返回该职业的普攻关键帧"""
    ALL_ATTACK = {
        "warrior": [
            (0.00, {"pelvis":0,"torso":-4,"head":0,"arm_l":18,"arm_r":-90,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":2,"torso":18,"head":8,"arm_l":-35,"arm_r":-165,"leg_l":-8,"leg_r":8}),
            (0.60, {"pelvis":0,"torso":22,"head":10,"arm_l":-45,"arm_r":-170,"leg_l":-10,"leg_r":10}),
            (1.00, {"pelvis":0,"torso":-4,"head":0,"arm_l":18,"arm_r":-90,"leg_l":0,"leg_r":0}),
        ],
        "mage": [
            (0.00, {"pelvis":0,"torso":0,"head":3,"arm_l":22,"arm_r":-22,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":0,"torso":-4,"head":10,"arm_l":90,"arm_r":-90,"leg_l":2,"leg_r":-2}),
            (0.60, {"pelvis":0,"torso":-7,"head":16,"arm_l":110,"arm_r":-110,"leg_l":3,"leg_r":-3}),
            (1.00, {"pelvis":0,"torso":0,"head":3,"arm_l":22,"arm_r":-22,"leg_l":0,"leg_r":0}),
        ],
        "archer": [
            (0.00, {"pelvis":0,"torso":-2,"head":2,"arm_l":8,"arm_r":-8,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":-4,"torso":7,"head":5,"arm_l":-22,"arm_r":40,"leg_l":4,"leg_r":-4}),
            (0.60, {"pelvis":-6,"torso":10,"head":5,"arm_l":-30,"arm_r":55,"leg_l":5,"leg_r":-5}),
            (1.00, {"pelvis":0,"torso":-2,"head":2,"arm_l":8,"arm_r":-8,"leg_l":0,"leg_r":0}),
        ],
        "thief": [
            (0.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":12,"arm_r":-12,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":3,"torso":9,"head":3,"arm_l":-25,"arm_r":25,"leg_l":-5,"leg_r":5}),
            (0.55, {"pelvis":5,"torso":13,"head":5,"arm_l":-40,"arm_r":40,"leg_l":-8,"leg_r":8}),
            (1.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":12,"arm_r":-12,"leg_l":0,"leg_r":0}),
        ],
        # 新职业: 简化攻击动作 (和 thief/archer 类似的快速刺击/射击)
        "bomber": [
            (0.00, {"pelvis":0,"torso":0,"head":0,"arm_l":15,"arm_r":-15,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":2,"torso":-4,"head":4,"arm_l":-10,"arm_r":-100,"leg_l":-3,"leg_r":3}),
            (0.60, {"pelvis":3,"torso":-5,"head":6,"arm_l":-5,"arm_r":-130,"leg_l":-5,"leg_r":5}),
            (1.00, {"pelvis":0,"torso":0,"head":0,"arm_l":15,"arm_r":-15,"leg_l":0,"leg_r":0}),
        ],
        "bounty_hunter": [
            (0.00, {"pelvis":0,"torso":0,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":-3,"torso":4,"head":3,"arm_l":-15,"arm_r":45,"leg_l":3,"leg_r":-3}),
            (0.60, {"pelvis":-5,"torso":6,"head":4,"arm_l":-20,"arm_r":65,"leg_l":4,"leg_r":-4}),
            (1.00, {"pelvis":0,"torso":0,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
        ],
        "cyborg": [
            (0.00, {"pelvis":0,"torso":0,"head":0,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":2,"torso":6,"head":2,"arm_l":-10,"arm_r":-80,"leg_l":-4,"leg_r":4}),
            (0.60, {"pelvis":3,"torso":8,"head":3,"arm_l":-15,"arm_r":-100,"leg_l":-6,"leg_r":6}),
            (1.00, {"pelvis":0,"torso":0,"head":0,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
        ],
        "death_knight": [
            (0.00, {"pelvis":0,"torso":-6,"head":-2,"arm_l":25,"arm_r":-95,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":4,"torso":16,"head":10,"arm_l":-45,"arm_r":-165,"leg_l":-10,"leg_r":10}),
            (0.60, {"pelvis":2,"torso":20,"head":12,"arm_l":-55,"arm_r":-175,"leg_l":-12,"leg_r":12}),
            (1.00, {"pelvis":0,"torso":-6,"head":-2,"arm_l":25,"arm_r":-95,"leg_l":0,"leg_r":0}),
        ],
        "engineer": [
            (0.00, {"pelvis":0,"torso":0,"head":2,"arm_l":12,"arm_r":-12,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":3,"torso":5,"head":4,"arm_l":-15,"arm_r":-60,"leg_l":-4,"leg_r":4}),
            (0.60, {"pelvis":4,"torso":7,"head":5,"arm_l":-20,"arm_r":-80,"leg_l":-6,"leg_r":6}),
            (1.00, {"pelvis":0,"torso":0,"head":2,"arm_l":12,"arm_r":-12,"leg_l":0,"leg_r":0}),
        ],
        "hacker": [
            (0.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":2,"torso":8,"head":3,"arm_l":-20,"arm_r":20,"leg_l":-4,"leg_r":4}),
            (0.55, {"pelvis":4,"torso":12,"head":4,"arm_l":-35,"arm_r":35,"leg_l":-6,"leg_r":6}),
            (1.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
        ],
        "mech_pilot": [
            (0.00, {"pelvis":0,"torso":0,"head":2,"arm_l":18,"arm_r":-18,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":0,"torso":-3,"head":6,"arm_l":85,"arm_r":-85,"leg_l":1,"leg_r":-1}),
            (0.60, {"pelvis":-2,"torso":-5,"head":10,"arm_l":110,"arm_r":-110,"leg_l":2,"leg_r":-2}),
            (1.00, {"pelvis":0,"torso":0,"head":2,"arm_l":18,"arm_r":-18,"leg_l":0,"leg_r":0}),
        ],
        "necromancer": [
            (0.00, {"pelvis":0,"torso":0,"head":3,"arm_l":20,"arm_r":-20,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":0,"torso":-5,"head":12,"arm_l":95,"arm_r":-95,"leg_l":2,"leg_r":-2}),
            (0.60, {"pelvis":-2,"torso":-8,"head":18,"arm_l":120,"arm_r":-120,"leg_l":3,"leg_r":-3}),
            (1.00, {"pelvis":0,"torso":0,"head":3,"arm_l":20,"arm_r":-20,"leg_l":0,"leg_r":0}),
        ],
        "priest": [
            (0.00, {"pelvis":0,"torso":0,"head":2,"arm_l":20,"arm_r":-20,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":0,"torso":-3,"head":10,"arm_l":80,"arm_r":-80,"leg_l":1,"leg_r":-1}),
            (0.60, {"pelvis":-2,"torso":-5,"head":14,"arm_l":105,"arm_r":-105,"leg_l":2,"leg_r":-2}),
            (1.00, {"pelvis":0,"torso":0,"head":2,"arm_l":20,"arm_r":-20,"leg_l":0,"leg_r":0}),
        ],
        "qi_adept": [
            (0.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":8,"arm_r":-8,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":2,"torso":8,"head":5,"arm_l":-40,"arm_r":50,"leg_l":-5,"leg_r":5}),
            (0.60, {"pelvis":4,"torso":12,"head":8,"arm_l":-60,"arm_r":80,"leg_l":-8,"leg_r":8}),
            (1.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":8,"arm_r":-8,"leg_l":0,"leg_r":0}),
        ],
        "runeward": [
            (0.00, {"pelvis":0,"torso":-3,"head":0,"arm_l":15,"arm_r":-85,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":2,"torso":14,"head":8,"arm_l":-30,"arm_r":-150,"leg_l":-8,"leg_r":8}),
            (0.60, {"pelvis":0,"torso":18,"head":10,"arm_l":-40,"arm_r":-160,"leg_l":-10,"leg_r":10}),
            (1.00, {"pelvis":0,"torso":-3,"head":0,"arm_l":15,"arm_r":-85,"leg_l":0,"leg_r":0}),
        ],
        "sniper": [
            (0.00, {"pelvis":0,"torso":2,"head":4,"arm_l":-35,"arm_r":35,"leg_l":0,"leg_r":0}),
            (0.30, {"pelvis":-5,"torso":8,"head":6,"arm_l":-50,"arm_r":55,"leg_l":5,"leg_r":-5}),
            (0.60, {"pelvis":-8,"torso":10,"head":8,"arm_l":-55,"arm_r":65,"leg_l":6,"leg_r":-6}),
            (1.00, {"pelvis":0,"torso":2,"head":4,"arm_l":-35,"arm_r":35,"leg_l":0,"leg_r":0}),
        ],
    }
    return ALL_ATTACK.get(cls, ALL_ATTACK["archer"])

def _skill_kfs(cls):
    """返回该职业的技能关键帧 — 每个职业独特的大招姿态"""
    ALL_SKILL = {
        "warrior": [
            (0.00, {"pelvis":0,"torso":-8,"head":-4,"arm_l":55,"arm_r":-110,"leg_l":6,"leg_r":-6}),
            (0.25, {"pelvis":0,"torso":-22,"head":-10,"arm_l":110,"arm_r":-140,"leg_l":12,"leg_r":-12}),
            (0.50, {"pelvis":0,"torso":-35,"head":-18,"arm_l":160,"arm_r":-160,"leg_l":18,"leg_r":-18}),
            (1.00, {"pelvis":0,"torso":-8,"head":-4,"arm_l":55,"arm_r":-110,"leg_l":6,"leg_r":-6}),
        ],
        "mage": [
            (0.00, {"pelvis":0,"torso":-4,"head":8,"arm_l":85,"arm_r":-85,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":-2,"torso":-9,"head":18,"arm_l":125,"arm_r":-125,"leg_l":2,"leg_r":-2}),
            (0.50, {"pelvis":-4,"torso":-14,"head":25,"arm_l":155,"arm_r":-155,"leg_l":3,"leg_r":-3}),
            (1.00, {"pelvis":0,"torso":-4,"head":8,"arm_l":85,"arm_r":-85,"leg_l":0,"leg_r":0}),
        ],
        "archer": [
            (0.00, {"pelvis":-4,"torso":9,"head":6,"arm_l":-45,"arm_r":75,"leg_l":8,"leg_r":-8}),
            (0.25, {"pelvis":-8,"torso":16,"head":8,"arm_l":-65,"arm_r":95,"leg_l":12,"leg_r":-12}),
            (0.50, {"pelvis":-10,"torso":20,"head":10,"arm_l":-78,"arm_r":110,"leg_l":14,"leg_r":-14}),
            (1.00, {"pelvis":-4,"torso":9,"head":6,"arm_l":-45,"arm_r":75,"leg_l":8,"leg_r":-8}),
        ],
        "thief": [
            (0.00, {"pelvis":-2,"torso":4,"head":2,"arm_l":18,"arm_r":-18,"leg_l":-6,"leg_r":6}),
            (0.25, {"pelvis":-3,"torso":10,"head":4,"arm_l":-5,"arm_r":5,"leg_l":-12,"leg_r":12}),
            (0.50, {"pelvis":-4,"torso":15,"head":5,"arm_l":-15,"arm_r":15,"leg_l":-16,"leg_r":16}),
            (1.00, {"pelvis":-2,"torso":4,"head":2,"arm_l":18,"arm_r":-18,"leg_l":-6,"leg_r":6}),
        ],
        # 新职业技能姿态
        "bomber": [
            (0.00, {"pelvis":-2,"torso":4,"head":2,"arm_l":-10,"arm_r":-90,"leg_l":-4,"leg_r":4}),
            (0.25, {"pelvis":-4,"torso":10,"head":6,"arm_l":-20,"arm_r":-140,"leg_l":-8,"leg_r":8}),
            (0.50, {"pelvis":-6,"torso":14,"head":10,"arm_l":-30,"arm_r":-160,"leg_l":-10,"leg_r":10}),
            (1.00, {"pelvis":-2,"torso":4,"head":2,"arm_l":-10,"arm_r":-90,"leg_l":-4,"leg_r":4}),
        ],
        "bounty_hunter": [
            (0.00, {"pelvis":0,"torso":3,"head":3,"arm_l":-35,"arm_r":45,"leg_l":-3,"leg_r":3}),
            (0.25, {"pelvis":-3,"torso":8,"head":5,"arm_l":-50,"arm_r":65,"leg_l":-6,"leg_r":6}),
            (0.50, {"pelvis":-5,"torso":12,"head":8,"arm_l":-60,"arm_r":80,"leg_l":-8,"leg_r":8}),
            (1.00, {"pelvis":0,"torso":3,"head":3,"arm_l":-35,"arm_r":45,"leg_l":-3,"leg_r":3}),
        ],
        "cyborg": [
            (0.00, {"pelvis":0,"torso":0,"head":2,"arm_l":15,"arm_r":-70,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":0,"torso":5,"head":6,"arm_l":-15,"arm_r":-120,"leg_l":-4,"leg_r":4}),
            (0.50, {"pelvis":0,"torso":8,"head":10,"arm_l":-25,"arm_r":-150,"leg_l":-6,"leg_r":6}),
            (1.00, {"pelvis":0,"torso":0,"head":2,"arm_l":15,"arm_r":-70,"leg_l":0,"leg_r":0}),
        ],
        "death_knight": [
            (0.00, {"pelvis":0,"torso":-15,"head":-8,"arm_l":70,"arm_r":-130,"leg_l":10,"leg_r":-10}),
            (0.25, {"pelvis":-2,"torso":-30,"head":-14,"arm_l":120,"arm_r":-155,"leg_l":16,"leg_r":-16}),
            (0.50, {"pelvis":-4,"torso":-40,"head":-20,"arm_l":160,"arm_r":-170,"leg_l":20,"leg_r":-20}),
            (1.00, {"pelvis":0,"torso":-15,"head":-8,"arm_l":70,"arm_r":-130,"leg_l":10,"leg_r":-10}),
        ],
        "engineer": [
            (0.00, {"pelvis":0,"torso":2,"head":4,"arm_l":10,"arm_r":-50,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":0,"torso":8,"head":10,"arm_l":-5,"arm_r":-90,"leg_l":-3,"leg_r":3}),
            (0.50, {"pelvis":2,"torso":12,"head":14,"arm_l":-10,"arm_r":-120,"leg_l":-5,"leg_r":5}),
            (1.00, {"pelvis":0,"torso":2,"head":4,"arm_l":10,"arm_r":-50,"leg_l":0,"leg_r":0}),
        ],
        "hacker": [
            (0.00, {"pelvis":0,"torso":-2,"head":4,"arm_l":60,"arm_r":-60,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":-2,"torso":-6,"head":12,"arm_l":100,"arm_r":-100,"leg_l":2,"leg_r":-2}),
            (0.50, {"pelvis":-4,"torso":-10,"head":18,"arm_l":130,"arm_r":-130,"leg_l":3,"leg_r":-3}),
            (1.00, {"pelvis":0,"torso":-2,"head":4,"arm_l":60,"arm_r":-60,"leg_l":0,"leg_r":0}),
        ],
        "mech_pilot": [
            (0.00, {"pelvis":0,"torso":0,"head":3,"arm_l":65,"arm_r":-65,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":-2,"torso":-5,"head":12,"arm_l":100,"arm_r":-100,"leg_l":1,"leg_r":-1}),
            (0.50, {"pelvis":-3,"torso":-10,"head":20,"arm_l":130,"arm_r":-130,"leg_l":2,"leg_r":-2}),
            (1.00, {"pelvis":0,"torso":0,"head":3,"arm_l":65,"arm_r":-65,"leg_l":0,"leg_r":0}),
        ],
        "necromancer": [
            (0.00, {"pelvis":0,"torso":-5,"head":10,"arm_l":75,"arm_r":-75,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":-2,"torso":-12,"head":22,"arm_l":115,"arm_r":-115,"leg_l":1,"leg_r":-1}),
            (0.50, {"pelvis":-4,"torso":-18,"head":32,"arm_l":150,"arm_r":-150,"leg_l":2,"leg_r":-2}),
            (1.00, {"pelvis":0,"torso":-5,"head":10,"arm_l":75,"arm_r":-75,"leg_l":0,"leg_r":0}),
        ],
        "priest": [
            (0.00, {"pelvis":0,"torso":-3,"head":8,"arm_l":70,"arm_r":-70,"leg_l":0,"leg_r":0}),
            (0.25, {"pelvis":0,"torso":-8,"head":18,"arm_l":105,"arm_r":-105,"leg_l":1,"leg_r":-1}),
            (0.50, {"pelvis":-2,"torso":-12,"head":26,"arm_l":140,"arm_r":-140,"leg_l":2,"leg_r":-2}),
            (1.00, {"pelvis":0,"torso":-3,"head":8,"arm_l":70,"arm_r":-70,"leg_l":0,"leg_r":0}),
        ],
        "qi_adept": [
            (0.00, {"pelvis":-2,"torso":-4,"head":0,"arm_l":30,"arm_r":-30,"leg_l":4,"leg_r":-4}),
            (0.25, {"pelvis":-4,"torso":-10,"head":4,"arm_l":75,"arm_r":-75,"leg_l":10,"leg_r":-10}),
            (0.50, {"pelvis":-6,"torso":-15,"head":8,"arm_l":120,"arm_r":-120,"leg_l":14,"leg_r":-14}),
            (1.00, {"pelvis":-2,"torso":-4,"head":0,"arm_l":30,"arm_r":-30,"leg_l":4,"leg_r":-4}),
        ],
        "runeward": [
            (0.00, {"pelvis":0,"torso":-10,"head":-5,"arm_l":40,"arm_r":-120,"leg_l":8,"leg_r":-8}),
            (0.25, {"pelvis":-2,"torso":-25,"head":-12,"arm_l":80,"arm_r":-150,"leg_l":14,"leg_r":-14}),
            (0.50, {"pelvis":-4,"torso":-38,"head":-20,"arm_l":120,"arm_r":-170,"leg_l":18,"leg_r":-18}),
            (1.00, {"pelvis":0,"torso":-10,"head":-5,"arm_l":40,"arm_r":-120,"leg_l":8,"leg_r":-8}),
        ],
        "sniper": [
            (0.00, {"pelvis":-6,"torso":10,"head":8,"arm_l":-60,"arm_r":70,"leg_l":10,"leg_r":-10}),
            (0.25, {"pelvis":-10,"torso":18,"head":10,"arm_l":-75,"arm_r":85,"leg_l":14,"leg_r":-14}),
            (0.50, {"pelvis":-12,"torso":22,"head":12,"arm_l":-85,"arm_r":95,"leg_l":16,"leg_r":-16}),
            (1.00, {"pelvis":-6,"torso":10,"head":8,"arm_l":-60,"arm_r":70,"leg_l":10,"leg_r":-10}),
        ],
    }
    return ALL_SKILL.get(cls, ALL_SKILL["archer"])

ACTION_GROUPS = [
    ("待机", "idle",    "idle",   "站立呼吸微摆"),
    ("行走", "run",     "run",    "行走循环"),
    ("普攻", "attack",  "attack", "基础攻击"),
    ("技能", "skill",   "skill",  "大招动作"),
    ("挥手致意", "wave",   "wave",   "日常交互"),
    ("欢呼庆祝", "cheer",  "cheer",  "日常交互"),
]


# ============================================================
# 背景生成
# ============================================================
CANVAS_W, CANVAS_H = 420, 540

def make_bg(w, h, cls):
    pal = CLASS_PALETTE[cls]
    dark_c = pal["body_bands"][0]
    bg_top = (8, 10, 18)
    bg_bot = (dark_c[0]//2, dark_c[1]//2 + 2, dark_c[2]//2 + 4)
    canvas = Image.new("RGB", (w, h), bg_top)
    draw = ImageDraw.Draw(canvas)
    for y in range(h):
        t = y / h
        r = int(bg_top[0]*(1-t) + bg_bot[0]*t)
        g = int(bg_top[1]*(1-t) + bg_bot[1]*t)
        b = int(bg_top[2]*(1-t) + bg_bot[2]*t)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    draw.line([(30, h-50), (w-30, h-50)], fill=(30, 38, 52), width=1)
    import random
    rng = random.Random(hash(cls))
    for _ in range(20):
        gx = rng.randint(30, w-30)
        gy = rng.randint(h-48, h-35)
        draw.point((gx, gy), fill=(40, 50, 70))
    return canvas

# ============================================================
# 主流程
# ============================================================
print("=" * 70)
print("v9 ALL16 — Cel-Shading 赛璐璐硬阴影 · 全部 16 职业程序化 2D 骨架动画")
print("     16 职业 × 6 动作 × 4 帧 = 384 帧")
print("     硬阴影带 + 双轮廓描边 + 衣褶 + 金属高光 + 面部细节")
print("=" * 70)

all_sheets = {}
cls_list = list(CLASS_PALETTE.keys())

for cls in cls_list:
    pal = CLASS_PALETTE[cls]
    cn = pal["name"]
    weapon = pal["weapon"]
    skill_cn = pal["weapon_cn"]
    print(f"\n{'─'*12} {cls:20s} / {cn} ({weapon} / {skill_cn}) {'─'*12}")
    
    frames = {}
    
    for gidx, (cn_label, en_pfx, mode, desc) in enumerate(ACTION_GROUPS):
        label = skill_cn if cn_label == "技能" else cn_label
        for k in range(4):
            if en_pfx == "idle":
                rots = idle_frame(k)
            elif en_pfx == "run":
                rots = run_frame(cls, k)
            elif en_pfx == "wave":
                rots = wave_frame(k)
            elif en_pfx == "cheer":
                rots = cheer_frame(k)
            elif en_pfx == "attack":
                kfs = _attack_kfs(cls)
                rots = interp(kfs, kfs[k][0])
            elif en_pfx == "skill":
                kfs = _skill_kfs(cls)
                rots = interp(kfs, kfs[k][0])
            
            bt = fk(rots, facing=1.0, pelvis_pos=(CANVAS_W//2, CANVAS_H-120))
            canvas = make_bg(CANVAS_W, CANVAS_H, cls)
            draw = ImageDraw.Draw(canvas)
            draw_character_cel(draw, bt, cls, facing=1.0)
            fname = f"{en_pfx}_{k+1}"
            frames[fname] = (canvas, label, k+1)
    
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, (frm, _, _) in frames.items():
        frm.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # ---- 单职业 Contact Sheet ----
    cats = []
    for cn_label, en_pfx, mode, desc in ACTION_GROUPS:
        label = skill_cn if cn_label == "技能" else cn_label
        cats.append((label, [f"{en_pfx}_{k}" for k in range(1, 5)]))
    
    COLS = 4; TW, TH = 130, 165; LH = 26; MAR = 8
    rows = len(cats)
    sw = MAR * 2 + COLS * (TW + 8)
    sh = MAR + 30 + MAR + rows * (LH + TH + MAR)
    sheet = Image.new("RGB", (sw, sh), (10, 12, 20))
    d = ImageDraw.Draw(sheet)
    
    d.text((MAR+8, MAR+4), 
           f"{cn} ({cls})  ·  武器: {weapon}  ·  技能: {skill_cn}", 
           fill=(230, 210, 150))
    d.text((MAR+8, MAR+20), 
           "▸ Cel-Shading 赛璐璐硬阴影  |  纯程序化绘制  |  不切割无贴图", 
           fill=(120, 140, 170))
    
    y0 = MAR + 40 + MAR
    for ri, (label, fnames) in enumerate(cats):
        y = y0 + ri * (LH + TH + MAR)
        d.rectangle([MAR, y, sw-MAR, y+LH], fill=(20, 28, 40))
        d.rectangle([MAR, y, MAR+4, y+LH], fill=pal["rim"])
        d.text((MAR+12, y+5), label, fill=(230, 210, 150))
        d.text((MAR+120, y+5), "4 帧", fill=(100, 120, 150))
        
        for ci in range(COLS):
            x = MAR + ci * (TW + 8)
            fi = fnames[ci] if ci < len(fnames) else None
            d.rectangle([x, y+LH, x+TW, y+LH+TH], outline=(45, 60, 85), width=1)
            if fi and fi in frames:
                frame_img, _, _ = frames[fi]
                f = frame_img.resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, y+LH))
                d.text((x+4, y+LH+TH-12), f"帧 {ci+1}", fill=(90, 110, 140))
    
    sheet.save(f"{OUT}/{cls}_sheet.jpg", "JPEG", quality=92)
    all_sheets[cls] = sheet
    print(f"  ✓ {cls}_sheet.jpg ({sw}×{sh}) — 24 帧")

# ============================================================
# 4×4 总览 Contact Sheet
# ============================================================
print(f"\n{'='*70}")
print("生成 4×4 总览 Contact Sheet ...")

# 每个 sheet 裁 4 个代表帧 (idle, run3, attack3, skill3) 的缩略图
CELL_W = 340  # 每个 cell 宽度
CELL_H = 300  # 每个 cell 高度 (含标题)
THUMB_H = 230

COLS_OV = 4
ROWS_OV = 4
MARGIN = 24
HEADER_H = 100

SW_OV = MARGIN + COLS_OV * (CELL_W + MARGIN)
SH_OV = MARGIN + HEADER_H + MARGIN + ROWS_OV * (CELL_H + MARGIN)

ov = Image.new("RGB", (SW_OV, SH_OV), (6, 8, 16))
d = ImageDraw.Draw(ov)

# 标题
d.text((MARGIN, MARGIN + 10), 
       "⚔ v9 ALL16 Cel-Shading 赛璐璐硬阴影 · 全部 16 职业程序化 2D 骨架动画", 
       fill=(255, 80, 60))
d.text((MARGIN, MARGIN + 34), 
       "硬阴影带 (3 档亮度) + 双轮廓描边 + 职业主题色 Rim Light + 金属武器高光", 
       fill=(150, 165, 190))
d.text((MARGIN, MARGIN + 54), 
       f"16 职业 × 6 动作 × 4 帧 = 共 {16*6*4} 帧  |  纯 Python/PIL · 每一帧独立绘制 · 不切割无贴图", 
       fill=(100, 115, 140))
d.text((MARGIN, MARGIN + 72), 
       "光照: 左上偏上  |  轮廓: 深色外 + Rim Light 主题色  |  武器: 每职业独立几何绘制", 
       fill=(80, 95, 120))

# 职业网格
for idx, cls in enumerate(cls_list):
    r, c = divmod(idx, COLS_OV)
    sx = MARGIN + c * (CELL_W + MARGIN)
    sy = MARGIN + HEADER_H + MARGIN + r * (CELL_H + MARGIN)
    
    pal = CLASS_PALETTE[cls]
    cn = pal["name"]
    weapon = pal["weapon"]
    skill = pal["weapon_cn"]
    rim_c = pal["rim"]
    accent_c = pal["accent"]
    
    # 从 sheet 里挑一个代表帧 — 裁 sheet 的中间偏下区域 (动作预览)
    sheet = all_sheets[cls]
    sw, sh_sheet = sheet.size
    
    # 裁 contact sheet 中间一行 (skill 行) 作为代表
    # 每行高 = LH + TH + MAR, 总共 6 行, skill 是第 4 行 (idx=3)
    rows_h = (26 + 165 + 8) * 6
    y_skill = 40 + 8 + 3 * (26 + 165 + 8) + 26 + 8
    # 裁 sheet 的主图像区域 (跳过标题和 skill 行标签)
    crop_left = 8 + 4
    crop_top = 40 + 8 + 3 * (26 + 165 + 8) + 26  # 第4行图像起始
    crop_right = min(sw - 8, crop_left + 4 * (130 + 8))
    crop_bot = crop_top + 165
    
    if crop_top < sh_sheet and crop_right > crop_left:
        crop = sheet.crop((crop_left, crop_top, crop_right, min(crop_bot, sh_sheet)))
    else:
        crop = sheet.crop((8, 48, min(sw-8, 8+CELL_W), min(sh_sheet, 48+THUMB_H)))
    
    # 缩放到固定宽度
    crop_w, crop_h = crop.size
    target_h = THUMB_H
    target_w = int(crop_w * target_h / crop_h)
    if target_w > CELL_W - 8:
        target_w = CELL_W - 8
        target_h = int(crop_h * target_w / crop_w)
    
    resized = crop.resize((target_w, target_h), Image.BILINEAR)
    cx = sx + (CELL_W - target_w) // 2
    cy = sy + 30 + (THUMB_H - target_h) // 2
    
    # 职业名 + 武器 + 技能 标签
    label_top = sy
    d.rectangle([sx, label_top, sx+CELL_W, label_top+28], fill=(14, 20, 30))
    # Rim 色左边条
    d.rectangle([sx, label_top, sx+5, label_top+28], fill=rim_c)
    d.text((sx+12, label_top+5), f"▸ {cn}", fill=(255, 220, 150))
    d.text((sx+80, label_top+5), f"武器: {weapon}", fill=(160, 175, 200))
    d.text((sx+80, label_top+18), f"技能: {skill}", fill=rim_c)
    
    # 图像外框
    d.rectangle([sx, cy-4, sx+CELL_W, cy+target_h+4], outline=(40, 55, 80), width=1)
    d.rectangle([sx+1, cy-3, sx+CELL_W-1, cy+target_h+3], fill=(10, 12, 20))
    ov.paste(resized, (cx, cy))
    
    # 职业名缩写 (底部)
    d.text((sx+4, cy+target_h+8), 
           f"{cls}  |  Rim({rim_c[0]},{rim_c[1]},{rim_c[2]})  |  Accent({accent_c[0]},{accent_c[1]},{accent_c[2]})",
           fill=(90, 110, 140))
    
    # 右上角编号
    d.text((sx+CELL_W-28, label_top+5), f"#{idx+1:02d}", fill=(80, 95, 120))

ov.save(f"{OUT}/overview_v9_all16.jpg", "JPEG", quality=92)
print(f"✓ 总览 overview_v9_all16.jpg: {SW_OV}×{SH_OV}")
print(f"\n全部完成! 输出: {OUT}/")
print(f"  16 职业 × 6 动作 × 4 帧 = 384 帧")
print(f"  Cel-Shading: 硬阴影带 + 深色外轮廓 + 职业主题色 Rim Light + 金属武器高光")
print(f"  纯 Python/PIL 程序化绘制 — 不切割, 无贴图")

