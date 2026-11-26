#!/usr/bin/env python3
"""
v7 — 程序化 2D 骨架动画 (每一帧独立绘制, 不切割, 无贴图)

核心理念: 纯 Python/PIL 程序化绘制。不依赖任何原始角色贴图。
  每帧 = FK 骨架 → 绘制骨骼胶囊 → 填充色块 + 硬阴影 + 轮廓线 + 细节
  → 完整角色图, 从头到尾都是画出来的。

技术参数:
  7 关节骨架, 与 v6 相同 parent chain
  每个 bone 由 1-2 个胶囊/椭圆 body part 构成
  3 层绘制: 底层色块 → 中层硬阴影/高光 → 顶层描边 + 细节装饰
  6 动作 × 4 帧 = 24 帧/角色
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/PROcedural_2D_SKELETON_v7"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 骨架系统 (和 v6 相同 parent chain, 但用 bind pose 的 bone 长度)
# ============================================================

# bind pose 关节位置 (512×512 画布, pelvis 居中)
# 这是"虚拟骨架"的绝对位置, 不依赖任何贴图
BIND = {
    "pelvis": (256, 310),
    "torso":  (256, 160),
    "head":   (256, 80),
    "arm_l":  (180, 175),   # 角色左臂 (图像右侧)
    "arm_r":  (332, 175),   # 角色右臂 (图像左侧)
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

def bind_angle(name):
    """该 bone 在 bind pose 下相对于 parent 的角度 (度, 向下为正)"""
    dx, dy = bone_offset(name)
    return math.degrees(math.atan2(dy, dx))

def fk(bone_rots, facing=1.0, pelvis_pos=(256, 310)):
    """
    bone_rots: {bone_name: rot_degrees} 相对 parent 的附加旋转
    facing: 1.0 或 -1.0 (水平翻转)
    返回: {bone_name: (world_rot, world_pos)}
    """
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
# 角色配色方案 (4 职业)
# ============================================================

# 主色, 次色, 高光, 阴影, 肤色
# 格式: (base, light, dark, accent, skin)
CLASS_PALETTE = {
    "barbarian": {
        "name": "野蛮人",
        "weapon": "巨剑",
        "weapon_cn": "旋风斩",
        "body":   ((35, 25, 28),  # base 深皮甲
                   (60, 42, 45),  # light
                   (18, 12, 14),  # dark
                   (200, 40, 40)),# accent 红焰
        "skin":   (210, 170, 140),
        "hair":   (20, 15, 12),
        "outline":(10, 8, 12),
    },
    "sorceress": {
        "name": "女巫",
        "weapon": "法杖",
        "weapon_cn": "陨石术",
        "body":   ((30, 30, 60),
                   (55, 55, 100),
                   (15, 15, 35),
                   (80, 180, 255)),
        "skin":   (220, 185, 165),
        "hair":   (60, 35, 25),
        "outline":(12, 10, 22),
    },
    "amazon": {
        "name": "亚马逊",
        "weapon": "长弓",
        "weapon_cn": "多重射击",
        "body":   ((55, 85, 45),
                   (85, 120, 70),
                   (28, 45, 22),
                   (180, 220, 100)),
        "skin":   (225, 190, 160),
        "hair":   (120, 60, 30),
        "outline":(12, 16, 10),
    },
    "assassin": {
        "name": "刺客",
        "weapon": "双匕",
        "weapon_cn": "影袭",
        "body":   ((22, 22, 28),
                   (48, 48, 58),
                   (8, 8, 12),
                   (220, 180, 60)),
        "skin":   (200, 170, 150),
        "hair":   (10, 10, 14),
        "outline":(6, 6, 10),
    },
}

# ============================================================
# 身体部位定义 (每个 bone 对应什么形状)
# ============================================================

# 每个部位: (bone_name, base_radius, end_radius, color_key, 额外形状)
# 形状: 'capsule' (胶囊), 'ellipse' (椭圆), 'head' (圆形+发型)

BODY_PARTS = {
    "torso": [
        ("torso", 42, 40, "body", "capsule"),   # 躯干
        ("torso", 35, 32, "body", "capsule"),   # 内层
    ],
    "head": [
        ("head", 22, 22, "skin", "ellipse"),     # 脸
        ("head", 26, 22, "hair", "hair"),       # 发型
    ],
    "arm_l": [
        ("arm_l", 14, 11, "body", "capsule"),
    ],
    "arm_r": [
        ("arm_r", 14, 11, "body", "capsule"),
    ],
    "leg_l": [
        ("leg_l", 17, 14, "body", "capsule"),
    ],
    "leg_r": [
        ("leg_r", 17, 14, "body", "capsule"),
    ],
    "pelvis": [
        ("pelvis", 28, 26, "body", "ellipse"),
    ],
}

def rotate_point(cx, cy, px, py, angle_deg):
    """绕 (cx,cy) 旋转 (px,py), 返回新坐标"""
    rad = math.radians(angle_deg)
    dx, dy = px - cx, py - cy
    rx = dx * math.cos(rad) - dy * math.sin(rad)
    ry = dx * math.sin(rad) + dy * math.cos(rad)
    return (cx + rx, cy + ry)

def draw_capsule(draw, p1, p2, r1, r2, fill_color, outline_color, outline_w=2):
    """画一个胶囊 (两端椭圆 + 中间矩形)"""
    x1, y1 = p1; x2, y2 = p2
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    length = math.hypot(x2 - x1, y2 - y1)
    
    # 旋转矩形的四个角点
    perp = angle + 90
    hx1 = r1 * math.cos(math.radians(perp))
    hy1 = r1 * math.sin(math.radians(perp))
    hx2 = r2 * math.cos(math.radians(perp))
    hy2 = r2 * math.sin(math.radians(perp))
    
    corners = [
        (x1 + hx1, y1 + hy1),
        (x2 + hx2, y2 + hy2),
        (x2 - hx2, y2 - hy2),
        (x1 - hx1, y1 - hy1),
    ]
    draw.polygon(corners, fill=fill_color, outline=None)
    
    # 两端椭圆 (先平移到 p1/p2 中心)
    def ellipse_rot(d, cx, cy, w, h, ang, fill, outline, ow):
        # 用 polygon 画旋转椭圆 (近似)
        pts = []
        steps = 24
        for i in range(steps + 1):
            a = 2 * math.pi * i / steps
            ex = cx + w * math.cos(a)
            ey = cy + h * math.sin(a)
            pts.append(rotate_point(cx, cy, ex, ey, ang))
        d.polygon(pts, fill=fill, outline=outline)
    
    ellipse_rot(draw, x1, y1, r1, r1, angle, fill_color, None, 0)
    ellipse_rot(draw, x2, y2, r2, r2, angle, fill_color, None, 0)

def blend(c1, c2, t):
    return tuple(int(c1[i]*(1-t) + c2[i]*t) for i in range(3))

# ============================================================
# 绘制一个完整角色 (程序化, 不依赖任何贴图)
# ============================================================

def draw_character(draw, bone_transforms, cls, facing=1.0, pose_info=None):
    """
    纯程序化绘制一个角色帧。
    bone_transforms: FK 结果 {name: (rot, pos)}
    pose_info: 额外绘制提示 (smile/skill glow 等)
    """
    pal = CLASS_PALETTE[cls]
    body_base, body_light, body_dark, accent = pal["body"]
    skin = pal["skin"]
    hair = pal["hair"]
    outline = pal["outline"]
    
    # 辅助函数: 取 bone 的 parent world pos 和自身 world pos
    def bone_segment(name):
        parent = PARENT[name]
        if parent is None: return bone_transforms[name][1], bone_transforms[name][1]
        return bone_transforms[parent][1], bone_transforms[name][1]
    
    # ---- 绘制顺序: 腿 → 躯干 → 臂 → 头 (后画的在上层) ----
    
    # 1. 腿
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        draw_capsule(draw, p1, p2, 17, 13, body_base, outline, 2)
        # 腿高光
        mx, my = (p1[0]+p2[0])/2, (p1[1]+p2[1])/2
        # 简单暗面条纹
        dx, dy = p2[0]-p1[0], p2[1]-p1[1]
        seg_len = math.hypot(dx, dy)
        if seg_len > 1:
            nx, ny = -dy/seg_len, dx/seg_len  # 法线
            draw.line([(mx - 5*nx - 3, my - 5*ny - 3), 
                      (mx + 5*nx - 3, my + 5*ny - 3)], fill=body_dark, width=4)
    
    # 2. 骨盆
    px, py = bone_transforms["pelvis"][1]
    draw.ellipse([px-26, py-20, px+26, py+22], fill=body_base, outline=None)
    # 腰带
    draw.rectangle([px-22, py-4, px+22, py+6], fill=body_dark)
    
    # 3. 躯干 (分 3 层: 底层大块 + 中高光 + 上层轮廓)
    torso_pelvis = bone_transforms["pelvis"][1]
    torso_shoulder = bone_transforms["torso"][1]
    draw_capsule(draw, torso_pelvis, torso_shoulder, 42, 38, body_base, outline, 2)
    # 胸甲高光
    mx, my = (torso_pelvis[0] + torso_shoulder[0])/2, (torso_pelvis[1] + torso_shoulder[1])/2
    draw.ellipse([mx-18, my-25, mx+18, my+15], fill=body_light, outline=None)
    # 职业胸甲装饰
    if cls == "barbarian":
        # 铁钉
        for i in range(-2, 3):
            draw.ellipse([mx+i*14-2, my-4+i*2-2, mx+i*14+2, my-4+i*2+2], fill=accent)
    elif cls == "sorceress":
        # 紫色符文纹
        draw.text((mx-16, my-8), "❖", fill=accent)
    elif cls == "amazon":
        # 叶子形
        draw.polygon([(mx,my-18),(mx+10,my-4),(mx,my+14),(mx-10,my-4)], fill=accent)
    elif cls == "assassin":
        # 锁链图案
        for i in range(3):
            draw.ellipse([mx-10+i*10-2, my-10-2, mx-10+i*10+2, my-10+2], fill=accent)
    
    # 4. 肩膀装甲 (每职业不同)
    shoulder_pos = bone_transforms["torso"][1]
    for side in [("arm_l", -1), ("arm_r", 1)]:
        arm_name, dir_side = side
        arm_pos = bone_transforms[arm_name][1]
        # 肩甲椭圆
        sx = (shoulder_pos[0] + arm_pos[0]) / 2
        sy = (shoulder_pos[1] + arm_pos[1]) / 2 - 6
        draw.ellipse([sx-16, sy-14, sx+16, sy+14], fill=body_light, outline=None)
        # 肩甲边缘
        draw.arc([sx-18, sy-16, sx+18, sy+16], 200*dir_side+180, 340*dir_side+180, fill=accent, width=3)
    
    # 5. 手臂
    for arm in ["arm_l", "arm_r"]:
        p1, p2 = bone_segment(arm)
        draw_capsule(draw, p1, p2, 13, 9, body_base, outline, 2)
        # 护手
        hx, hy = p2
        draw.ellipse([hx-10, hy-10, hx+10, hy+10], fill=body_light, outline=None)
        draw.ellipse([hx-7, hy-7, hx+7, hy+7], fill=skin, outline=None)
    
    # 6. 武器 (画在右手 arm_r 末端)
    if "weapon" in pal:
        arm_r_end = bone_transforms["arm_r"][1]
        arm_r_rot = bone_transforms["arm_r"][0]
        draw_weapon(draw, arm_r_end, arm_r_rot, cls, facing)
    
    # 7. 头
    head_pos = bone_transforms["head"][1]
    head_rot = bone_transforms["head"][0]
    hx, hy = head_pos
    # 脖子
    torso_pos = bone_transforms["torso"][1]
    draw.line([(hx, hy+18), (torso_pos[0], torso_pos[1]-6)], fill=skin, width=6)
    # 头部椭圆
    draw.ellipse([hx-22, hy-24, hx+22, hy+22], fill=skin, outline=outline, width=2)
    
    # 发型/帽子 (每职业不同)
    if cls == "barbarian":
        # 棕色长发 + 胡子
        draw.pieslice([hx-26, hy-28, hx+26, hy+10], 200, 340, fill=hair)
        # 胡子
        draw.ellipse([hx-16, hy+10, hx+16, hy+26], fill=hair, outline=None)
    elif cls == "sorceress":
        # 兜帽
        draw.pieslice([hx-28, hy-32, hx+28, hy+6], 180, 360, fill=body_base, outline=outline, width=2)
        # 兜帽尖
        draw.polygon([(hx, hy-32), (hx-12, hy-10), (hx+12, hy-10)], fill=body_dark, outline=None)
        # 银发
        draw.arc([hx-20, hy-20, hx+20, hy+12], 200, 340, fill=hair, width=3)
    elif cls == "amazon":
        # 高马尾
        draw.pieslice([hx-22, hy-28, hx+22, hy+8], 200, 340, fill=hair)
        # 马尾 (向图像右上延伸)
        draw_capsule(draw, (hx+14, hy-18), (hx+32, hy-8), 6, 4, hair, outline, 1)
    elif cls == "assassin":
        # 头巾 + 面罩
        draw.pieslice([hx-24, hy-28, hx+24, hy-4], 180, 360, fill=hair, outline=outline, width=1)
        draw.rectangle([hx-20, hy-2, hx+20, hy+16], fill=hair)  # 面罩
    
    # 眼睛 (所有职业通用, 左右各一个)
    eye_rot = math.radians(head_rot)
    for ex, ey_off in [(-7, -2), (7, -2)]:
        epx = hx + ex * math.cos(eye_rot) - ey_off * math.sin(eye_rot)
        epy = hy + ex * math.sin(eye_rot) + ey_off * math.cos(eye_rot)
        # 眼白
        draw.ellipse([epx-3, epy-2, epx+3, epy+2], fill=(250, 240, 230), outline=None)
        # 瞳孔
        pupil_color = accent if cls == "sorceress" else (40, 30, 25)
        draw.ellipse([epx-1.5, epy-1.5, epx+1.5, epy+1.5], fill=pupil_color)
    
    # 嘴
    if cls != "assassin":
        draw.arc([hx-5, hy+6, hx+5, hy+12], 10, 170, fill=(160, 80, 70), width=2)
    
    # 8. 阴影 (地面椭圆)
    px, py = bone_transforms["pelvis"][1]
    foot_y = py + 110
    draw.ellipse([px-55, foot_y, px+55, foot_y+14], fill=(0, 0, 0, 70))

def draw_weapon(draw, hand_pos, arm_rot, cls, facing):
    """在右手末端绘制武器 (每职业独特)"""
    hx, hy = hand_pos
    rad = math.radians(arm_rot + 90)  # 让武器顺着 arm 方向
    
    if cls == "barbarian":
        # 巨剑 (刃朝外, 与 arm 方向成 90°)
        sword_len = 120
        sword_end = (hx + math.cos(rad) * sword_len, hy + math.sin(rad) * sword_len)
        # 剑柄
        draw.line([(hx, hy), (hx + math.cos(rad)*18, hy + math.sin(rad)*18)], fill=(60, 30, 15), width=6)
        # 护手
        gx = hx + math.cos(rad) * 18; gy = hy + math.sin(rad) * 18
        perp = (rad + math.pi/2)
        draw.line([(gx + math.cos(perp)*12, gy + math.sin(perp)*12),
                  (gx - math.cos(perp)*12, gy - math.sin(perp)*12)],
                 fill=(180, 140, 40), width=6)
        # 剑刃 (梯形)
        bx1 = gx + math.cos(perp)*20; by1 = gy + math.sin(perp)*20
        bx2 = gx - math.cos(perp)*20; by2 = gy - math.sin(perp)*20
        ex = sword_end[0] + math.cos(perp)*6; ey = sword_end[1] + math.sin(perp)*6
        ex2 = sword_end[0] - math.cos(perp)*6; ey2 = sword_end[1] - math.sin(perp)*6
        draw.polygon([(bx1,by1),(bx2,by2),(ex2,ey2),(ex,ey)], fill=(190, 195, 210), outline=(100,100,115))
        # 剑刃火焰
        for i in range(3):
            fx = sword_end[0] - math.cos(rad)*(10+i*6)
            fy = sword_end[1] - math.sin(rad)*(10+i*6)
            draw.ellipse([fx-3, fy-3, fx+3, fy+3], fill=(255, 100, 30))
    
    elif cls == "sorceress":
        # 法杖
        staff_len = 180
        staff_top = (hx + math.cos(rad)*staff_len, hy + math.sin(rad)*staff_len)
        bottom = (hx - math.cos(rad)*30, hy - math.sin(rad)*30)
        draw.line([bottom, staff_top], fill=(90, 60, 35), width=5)
        # 顶部宝石
        draw.ellipse([staff_top[0]-12, staff_top[1]-12, staff_top[0]+12, staff_top[1]+12], fill=(80, 180, 255), outline=(120, 200, 255), width=2)
        draw.ellipse([staff_top[0]-6, staff_top[1]-6, staff_top[0]+6, staff_top[1]+6], fill=(200, 230, 255))
        # 底部小宝石
        draw.ellipse([bottom[0]-6, bottom[1]-6, bottom[0]+6, bottom[1]+6], fill=(80, 180, 255))
    
    elif cls == "amazon":
        # 长弓 (C 形)
        bow_len = 140
        bx1 = hx + math.cos(rad)*60; by1 = hy + math.sin(rad)*60
        bx2 = hx - math.cos(rad)*80; by2 = hy - math.sin(rad)*80
        # 弯弓
        perp = (rad + math.pi/2)
        mid_x = (bx1+bx2)/2 + math.cos(perp)*40
        mid_y = (by1+by2)/2 + math.sin(perp)*40
        draw.arc([min(bx1,bx2,mid_x)-20, min(by1,by2,mid_y)-20, max(bx1,bx2,mid_x)+20, max(by1,by2,mid_y)+20],
                 200, 340 if facing>0 else 140, fill=(100, 70, 40), width=6)
        # 弓弦
        draw.line([(bx1, by1), (bx2, by2)], fill=(220, 220, 200), width=1)
    
    elif cls == "assassin":
        # 两把匕首 (右手一把明显, 左手藏)
        dagger_len = 50
        tip = (hx + math.cos(rad)*dagger_len, hy + math.sin(rad)*dagger_len)
        # 刀柄
        draw.line([(hx, hy), (hx + math.cos(rad)*14, hy + math.sin(rad)*14)], fill=(40, 40, 50), width=5)
        # 护手
        draw.line([(hx + math.cos(rad)*14 + math.sin(rad)*8, hy + math.sin(rad)*14 - math.cos(rad)*8),
                  (hx + math.cos(rad)*14 - math.sin(rad)*8, hy + math.sin(rad)*14 + math.cos(rad)*8)],
                 fill=(200, 180, 60), width=4)
        # 刀身 (三角)
        bx = hx + math.cos(rad)*14; by = hy + math.sin(rad)*14
        perp = (rad + math.pi/2)
        draw.polygon([(bx+math.cos(perp)*8, by+math.sin(perp)*8),
                     (bx-math.cos(perp)*8, by-math.sin(perp)*8),
                     tip], fill=(180, 185, 200), outline=(80,80,95))

# ============================================================
# 动作库 (和 v6 相同动作定义, 但用在绑定骨架上)
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
        "leg_l": 0,
        "leg_r": 0,
    }

RUN_BASE = {
    "barbarian": {"pelvis":0,"torso":4,"head":0,"arm_l":-28,"arm_r":28,"leg_l":-34,"leg_r":34},
    "sorceress": {"pelvis":0,"torso":3,"head":0,"arm_l":-22,"arm_r":22,"leg_l":-28,"leg_r":28},
    "amazon":    {"pelvis":0,"torso":3,"head":0,"arm_l":-26,"arm_r":26,"leg_l":-32,"leg_r":32},
    "assassin":  {"pelvis":0,"torso":5,"head":0,"arm_l":-32,"arm_r":32,"leg_l":-36,"leg_r":36},
}
def run_frame(cls, k):
    phase = math.sin(2 * math.pi * k / 4)
    base = RUN_BASE[cls]
    rots = {n: v * (0.8 + phase * 0.4) for n, v in base.items()}
    rots["pelvis"] = phase * 2.0
    return rots

ATTACK_KFS = {
    "barbarian": [
        (0.00, {"pelvis":0,"torso":-4,"head":0,"arm_l":18,"arm_r":-90,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":2,"torso":18,"head":8,"arm_l":-35,"arm_r":-165,"leg_l":-8,"leg_r":8}),
        (0.60, {"pelvis":0,"torso":22,"head":10,"arm_l":-45,"arm_r":-170,"leg_l":-10,"leg_r":10}),
        (1.00, {"pelvis":0,"torso":-4,"head":0,"arm_l":18,"arm_r":-90,"leg_l":0,"leg_r":0}),
    ],
    "sorceress": [
        (0.00, {"pelvis":0,"torso":0,"head":3,"arm_l":22,"arm_r":-22,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":0,"torso":-4,"head":10,"arm_l":90,"arm_r":-90,"leg_l":2,"leg_r":-2}),
        (0.60, {"pelvis":0,"torso":-7,"head":16,"arm_l":110,"arm_r":-110,"leg_l":3,"leg_r":-3}),
        (1.00, {"pelvis":0,"torso":0,"head":3,"arm_l":22,"arm_r":-22,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [
        (0.00, {"pelvis":0,"torso":-2,"head":2,"arm_l":8,"arm_r":-8,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":-4,"torso":7,"head":5,"arm_l":-22,"arm_r":40,"leg_l":4,"leg_r":-4}),
        (0.60, {"pelvis":-6,"torso":10,"head":5,"arm_l":-30,"arm_r":55,"leg_l":5,"leg_r":-5}),
        (1.00, {"pelvis":0,"torso":-2,"head":2,"arm_l":8,"arm_r":-8,"leg_l":0,"leg_r":0}),
    ],
    "assassin": [
        (0.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":12,"arm_r":-12,"leg_l":0,"leg_r":0}),
        (0.25, {"pelvis":3,"torso":9,"head":3,"arm_l":-25,"arm_r":25,"leg_l":-5,"leg_r":5}),
        (0.55, {"pelvis":5,"torso":13,"head":5,"arm_l":-40,"arm_r":40,"leg_l":-8,"leg_r":8}),
        (1.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":12,"arm_r":-12,"leg_l":0,"leg_r":0}),
    ],
}

SKILL_KFS = {
    "barbarian": [
        (0.00, {"pelvis":0,"torso":-8,"head":-4,"arm_l":55,"arm_r":-110,"leg_l":6,"leg_r":-6}),
        (0.25, {"pelvis":0,"torso":-22,"head":-10,"arm_l":110,"arm_r":-140,"leg_l":12,"leg_r":-12}),
        (0.50, {"pelvis":0,"torso":-35,"head":-18,"arm_l":160,"arm_r":-160,"leg_l":18,"leg_r":-18}),
        (1.00, {"pelvis":0,"torso":-8,"head":-4,"arm_l":55,"arm_r":-110,"leg_l":6,"leg_r":-6}),
    ],
    "sorceress": [
        (0.00, {"pelvis":0,"torso":-4,"head":8,"arm_l":85,"arm_r":-85,"leg_l":0,"leg_r":0}),
        (0.25, {"pelvis":-2,"torso":-9,"head":18,"arm_l":125,"arm_r":-125,"leg_l":2,"leg_r":-2}),
        (0.50, {"pelvis":-4,"torso":-14,"head":25,"arm_l":155,"arm_r":-155,"leg_l":3,"leg_r":-3}),
        (1.00, {"pelvis":0,"torso":-4,"head":8,"arm_l":85,"arm_r":-85,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [
        (0.00, {"pelvis":-4,"torso":9,"head":6,"arm_l":-45,"arm_r":75,"leg_l":8,"leg_r":-8}),
        (0.25, {"pelvis":-8,"torso":16,"head":8,"arm_l":-65,"arm_r":95,"leg_l":12,"leg_r":-12}),
        (0.50, {"pelvis":-10,"torso":20,"head":10,"arm_l":-78,"arm_r":110,"leg_l":14,"leg_r":-14}),
        (1.00, {"pelvis":-4,"torso":9,"head":6,"arm_l":-45,"arm_r":75,"leg_l":8,"leg_r":-8}),
    ],
    "assassin": [
        (0.00, {"pelvis":-2,"torso":4,"head":2,"arm_l":18,"arm_r":-18,"leg_l":-6,"leg_r":6}),
        (0.25, {"pelvis":-3,"torso":10,"head":4,"arm_l":-5,"arm_r":5,"leg_l":-12,"leg_r":12}),
        (0.50, {"pelvis":-4,"torso":15,"head":5,"arm_l":-15,"arm_r":15,"leg_l":-16,"leg_r":16}),
        (1.00, {"pelvis":-2,"torso":4,"head":2,"arm_l":18,"arm_r":-18,"leg_l":-6,"leg_r":6}),
    ],
}

def wave_frame(k):
    phase = math.sin(2 * math.pi * k / 4)
    return {"pelvis":0,"torso":phase*-3,"head":phase*-2,
            "arm_l":8+phase*6,"arm_r":-135-phase*20,"leg_l":0,"leg_r":0}

def cheer_frame(k):
    phases = [0.0, 1.0, 1.0, 0.3]; p = phases[k]
    return {"pelvis":0,"torso":-1-p*4,"head":2+p*5,
            "arm_l":55+p*95,"arm_r":-55-p*95,"leg_l":p*-3,"leg_r":p*3}

# 动作组: (中文标签, 前缀, 生成函数, 描述)
ACTION_GROUPS = [
    ("待机", "idle",   lambda cls, k: idle_frame(k), "站立呼吸微摆"),
    ("行走", "run",    lambda cls, k: run_frame(cls, k), "行走循环"),
    ("普攻", "attack", None,                              "基础攻击"),
    ("技能", "skill",  None,                              None),  # 按职业变标签
    ("挥手致意", "wave",   lambda cls, k: wave_frame(k),  "日常交互"),
    ("欢呼庆祝", "cheer",  lambda cls, k: cheer_frame(k), "日常交互"),
]

# ============================================================
# 主流程 — 纯程序化绘制 4×24=96 帧
# ============================================================

CANVAS_W, CANVAS_H = 420, 540

print("=" * 60)
print("v7 — 程序化 2D 骨架动画 (每一帧独立绘制, 不切割, 无贴图)")
print("     6 动作 × 4 帧 = 24 帧/职业, 4 职业 = 96 帧")
print("=" * 60)

all_sheets = {}

for cls in CLASS_PALETTE:
    cn = CLASS_PALETTE[cls]["name"]
    skill_cn = CLASS_PALETTE[cls]["weapon_cn"]
    weapon = CLASS_PALETTE[cls]["weapon"]
    print(f"\n{'─'*8} {cls} / {cn} ({weapon}) {'─'*8}")
    
    frames = {}
    
    for gidx, (cn_label, en_pfx, gen_func, desc) in enumerate(ACTION_GROUPS):
        label = skill_cn if cn_label == "技能" else cn_label
        for k in range(4):
            # 计算关节旋转
            if en_pfx == "attack":
                rots = interp(ATTACK_KFS[cls], ATTACK_KFS[cls][k][0])
            elif en_pfx == "skill":
                rots = interp(SKILL_KFS[cls], SKILL_KFS[cls][k][0])
            else:
                rots = gen_func(cls, k)
            
            # FK (绑定骨架)
            bt = fk(rots, facing=1.0, pelvis_pos=(CANVAS_W//2, CANVAS_H-120))
            
            # 创建 canvas
            canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), (12, 14, 22))
            draw = ImageDraw.Draw(canvas)
            
            # 渐变背景
            for y in range(CANVAS_H):
                t = y / CANVAS_H
                r = int(12 * (1-t) + 28 * t)
                g = int(14 * (1-t) + 20 * t)
                b = int(22 * (1-t) + 36 * t)
                draw.line([(0, y), (CANVAS_W, y)], fill=(r, g, b))
            
            # 地面线
            draw.line([(40, CANVAS_H-50), (CANVAS_W-40, CANVAS_H-50)], fill=(30, 38, 52), width=1)
            
            # 程序化绘制角色
            draw_character(draw, bt, cls, facing=1.0)
            
            fname = f"{en_pfx}_{k+1}"
            frames[fname] = (canvas, label, k+1)
    
    # 保存各帧
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, (frm, _, _) in frames.items():
        frm.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # ---- Contact Sheet (全中文) ----
    cats = []
    for cn_label, en_pfx, gen_func, desc in ACTION_GROUPS:
        label = skill_cn if cn_label == "技能" else cn_label
        cats.append((label, [f"{en_pfx}_{k}" for k in range(1, 5)]))
    
    COLS = 4; TW, TH = 130, 165; LH = 26; MAR = 8
    rows = len(cats)
    sw = MAR * 2 + COLS * (TW + 8)
    sh = MAR + 30 + MAR + rows * (LH + TH + MAR)
    sheet = Image.new("RGB", (sw, sh), (10, 12, 20))
    d = ImageDraw.Draw(sheet)
    
    d.text((MAR+8, MAR+4), f"{cn} ({cls})  ·  武器: {weapon}  ·  技能: {skill_cn}", fill=(230, 210, 150))
    d.text((MAR+8, MAR+20), "▸ 程序化 2D 骨架动画  |  每一帧独立绘制  |  纯 Python/PIL 无贴图", fill=(120, 140, 170))
    
    y0 = MAR + 40 + MAR
    for ri, (label, fnames) in enumerate(cats):
        y = y0 + ri * (LH + TH + MAR)
        d.rectangle([MAR, y, sw-MAR, y+LH], fill=(20, 28, 40))
        d.rectangle([MAR, y, MAR+4, y+LH], fill=(220, 60, 60))
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

# ---- 总览 ----
COLS2=2; ROWS2=2; TW2,TH2=340,390; MAR2=24
sw2 = COLS2*TW2 + (COLS2+1)*MAR2
sh2 = ROWS2*TH2 + (ROWS2+1)*MAR2 + 100
ov = Image.new("RGB", (sw2, sh2), (6, 8, 16))
d = ImageDraw.Draw(ov)
d.text((MAR2, 22), "⚔ v7 程序化 2D 骨架动画 (每一帧独立绘制, 不切割, 无贴图)", fill=(230, 60, 60))
d.text((MAR2, 46), "纯 Python/PIL 从零绘制 — 7 关节骨架 → 胶囊身体 → 色块/硬阴影/描边/武器", fill=(150, 165, 190))
d.text((MAR2, 64), f"4 职业 × 6 动作 × 4 帧 = 共 {4*6*4} 帧  |  6 动作: 待机 / 行走 / 普攻 / 技能 / 挥手 / 欢呼", fill=(100, 115, 140))

for idx, cls in enumerate(CLASS_PALETTE):
    r, c = divmod(idx, COLS2)
    sx = MAR2 + c*(TW2+MAR2); sy = 100 + MAR2 + r*(TH2+MAR2)
    s = all_sheets[cls]
    crop = s.crop((8, 40+8, min(s.size[0], 8+TW2), 40+8+TH2)).resize((TW2, TH2), Image.BILINEAR)
    ov.paste(crop, (sx, sy))
    cn = CLASS_PALETTE[cls]["name"]
    skill = CLASS_PALETTE[cls]["weapon_cn"]
    label = f"▸ {cn}  |  武器: {CLASS_PALETTE[cls]['weapon']}  |  技能: {skill}"
    d.rectangle([sx, sy-22, sx+TW2, sy+2], fill=(14, 20, 30))
    d.text((sx+8, sy-18), label, fill=(255, 220, 150))
    d.rectangle([sx, sy, sx+TW2, sy+TH2], outline=(200, 70, 70), width=2)

ov.save(f"{OUT}/overview_v7.jpg", "JPEG", quality=92)
print(f"\n✓ 总览 overview_v7.jpg: {sw2}×{sh2}")
print(f"\n全部完成! 输出: {OUT}/")
print(f"  4 职业 × 6 动作 × 4 帧 = 96 帧 — 每帧独立程序化绘制, 不切割, 无贴图")
