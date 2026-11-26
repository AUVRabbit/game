#!/usr/bin/env python3
"""
v9 — Cel-Shading (赛璐璐硬阴影) 程序化 2D 骨架动画

基于 v7 纯程序化骨架架构, 核心升级:
  1. 硬阴影带 (cel bands) — 每身体部位按光照方向切 2-3 档亮度 band
  2. 双轮廓描边 — 深色外轮廓 + 职业主题色 rim light (职业光边)
  3. 衣褶/装甲板块 — 躯干/披风褶皱暗线, 护甲板块接缝
  4. 武器金属质感 — 金属高光渐变 (暗→亮→暗), 刀刃高光条, 装饰尖刺
  5. 面部细节 — 瞳孔高光点, 嘴角微表情, 胡须纹理

保证: 每一帧独立绘制, 不切割, 无贴图。
  6 动作 × 4 帧 = 24 帧/职业, 4 职业 = 96 帧
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/CEL_SHADING_v9"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 骨架系统 (和 v7 完全相同 — 7 关节, bind pose)
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
# Class Palette — 每职业 5 档亮度 band (赛璐璐硬阴影需要)
#  band 0 = 最暗 (阴影深处)
#  band 1 = 暗阴影
#  band 2 = 主色 (标准)
#  band 3 = 亮色
#  band 4 = 高光/rim light
# ============================================================
CLASS_PALETTE = {
    "barbarian": {
        "name": "野蛮人",
        "weapon": "巨剑",
        "weapon_cn": "旋风斩",
        "body_bands": [
            (14, 10, 12),   # 0 深阴影
            (26, 18, 20),   # 1 暗部
            (42, 30, 32),   # 2 主色 (深皮甲)
            (72, 50, 52),   # 3 亮色
            (110, 80, 72),  # 4 高光
        ],
        "skin_bands": [
            (130, 95, 75),  # 0
            (170, 128, 102),# 1
            (205, 165, 135),# 2 主色
            (230, 200, 175),# 3
            (250, 235, 215),# 4 高光
        ],
        "hair_bands": [
            (6, 5, 4),
            (12, 9, 8),
            (20, 15, 12),
            (35, 26, 20),
            (60, 45, 35),
        ],
        "outline": (8, 6, 8),
        "rim":     (255, 80, 50),   # 红焰 rim light
        "accent":  (220, 55, 45),
        "eye_color": (255, 120, 50),
    },
    "sorceress": {
        "name": "女巫",
        "weapon": "法杖",
        "weapon_cn": "陨石术",
        "body_bands": [
            (8, 8, 22),
            (16, 16, 42),
            (28, 28, 70),
            (50, 55, 110),
            (90, 100, 160),
        ],
        "skin_bands": [
            (140, 108, 92),
            (180, 145, 125),
            (218, 182, 162),
            (240, 215, 198),
            (252, 240, 225),
        ],
        "hair_bands": [
            (30, 12, 8),
            (50, 22, 14),
            (72, 38, 22),
            (100, 58, 36),
            (140, 85, 55),
        ],
        "outline": (6, 6, 18),
        "rim":     (120, 200, 255),  # 冰蓝 rim
        "accent":  (80, 180, 255),
        "eye_color": (120, 200, 255),
    },
    "amazon": {
        "name": "亚马逊",
        "weapon": "长弓",
        "weapon_cn": "多重射击",
        "body_bands": [
            (22, 35, 16),
            (38, 58, 28),
            (58, 88, 45),
            (90, 130, 72),
            (130, 170, 105),
        ],
        "skin_bands": [
            (145, 115, 88),
            (185, 150, 120),
            (222, 188, 158),
            (245, 218, 192),
            (253, 240, 222),
        ],
        "hair_bands": [
            (50, 22, 8),
            (80, 38, 14),
            (118, 58, 28),
            (160, 85, 48),
            (200, 120, 80),
        ],
        "outline": (6, 10, 6),
        "rim":     (210, 240, 110),  # 叶绿 rim
        "accent":  (180, 220, 100),
        "eye_color": (160, 210, 90),
    },
    "assassin": {
        "name": "刺客",
        "weapon": "双匕",
        "weapon_cn": "影袭",
        "body_bands": [
            (4, 4, 6),
            (10, 10, 14),
            (22, 22, 30),
            (44, 44, 56),
            (75, 75, 95),
        ],
        "skin_bands": [
            (120, 95, 82),
            (160, 128, 110),
            (198, 168, 148),
            (225, 200, 182),
            (245, 230, 215),
        ],
        "hair_bands": [
            (2, 2, 4),
            (6, 6, 10),
            (12, 12, 18),
            (22, 22, 32),
            (40, 40, 55),
        ],
        "outline": (3, 3, 5),
        "rim":     (240, 210, 80),   # 暗金 rim
        "accent":  (220, 180, 60),
        "eye_color": (255, 220, 100),
    },
}

# 光照方向 (左上偏上)
LIGHT_DIR = (-0.35, -0.55)  # x负=左, y负=上
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

def draw_capsule_polygon(draw, p1, p2, r1, r2, fill_color):
    """只画填充 (不含描边), 返回 polygon 点集方便后续阴影带处理"""
    x1, y1 = p1; x2, y2 = p2
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    length = math.hypot(x2 - x1, y2 - y1)
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
    return corners, angle

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

def blend(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(c1[i]*(1-t) + c2[i]*t + 0.5) for i in range(3))

# ============================================================
# Cel-Shading 带阴影绘制核心
# ============================================================
def light_band(light_factor, bands, n_bands=3, threshold_dark=0.35, threshold_mid=0.65):
    """
    根据光照因子 (0..1) 在 5 档 band 中选一档硬边颜色
    n_bands=3: 深阴影 / 主色 / 高光  (经典 3 档赛璐璐)
    """
    if light_factor < threshold_dark:
        return bands[1]  # 暗阴影 band
    elif light_factor < threshold_mid:
        return bands[2]  # 主色
    else:
        return bands[3]  # 亮色 band

def rim_color(bands):
    return bands[4]  # 最亮高光

def draw_cel_capsule(draw, p1, p2, r1, r2, body_bands, light_direction=LIGHT_N):
    """
    赛璐璐胶囊: 1 主色 + 硬阴影带 + rim 高光条
    """
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
    
    # 1. 主色填充
    corners = [
        (x1 + hx1, y1 + hy1),
        (x2 + hx2, y2 + hy2),
        (x2 - hx2, y2 - hy2),
        (x1 - hx1, y1 - hy1),
    ]
    draw.polygon(corners, fill=body_bands[2], outline=None)
    # 两端圆
    draw_rot_ellipse(draw, x1, y1, r1, r1, angle, body_bands[2])
    draw_rot_ellipse(draw, x2, y2, r2, r2, angle, body_bands[2])
    
    # 2. 硬阴影带 (暗部 — 背向光的一侧)
    # 计算胶囊表面法线的光照点积, 以胶囊中心法线方向判断阴影侧
    mid_x = (x1 + x2) / 2; mid_y = (y1 + y2) / 2
    # 胶囊的"表面"法线方向在 perp 和 -perp 两侧
    dot_perp = light_direction[0] * math.cos(perp) + light_direction[1] * math.sin(perp)
    # 如果 dot_perp < 0, 阴影在 perp 的反方向 (即 -perp 一侧), 我们画阴影多边形
    shadow_depth = min(0.7, 0.45 + abs(dot_perp) * 0.35)
    
    # 阴影多边形: 在光源对面一侧, 宽度 = radius * shadow_depth
    shadow_r1 = r1 * shadow_depth
    shadow_r2 = r2 * shadow_depth
    sx1 = shadow_r1 * math.cos(perp); sy1 = shadow_r1 * math.sin(perp)
    sx2 = shadow_r2 * math.cos(perp); sy2 = shadow_r2 * math.sin(perp)
    shadow_corners = [
        (x1 - hx1 + sx1, y1 - hy1 + sy1),
        (x2 - hx2 + sx2, y2 - hy2 + sy2),
        (x2 - hx2 - sx2, y2 - hy2 - sy2),
        (x1 - hx1 - sx1, y1 - hy1 - sy1),
    ]
    # 根据 dot_perp 决定阴影在哪侧
    if dot_perp > 0:
        # 光在 +perp 侧, 阴影在 -perp 侧 (corners[2-3] 那半边)
        shadow_corners = [
            (x1 - hx1, y1 - hy1),
            (x2 - hx2, y2 - hy2),
            (x2 - hx2 - sx2 * 0.6, y2 - hy2 - sy2 * 0.6),
            (x1 - hx1 - sx1 * 0.6, y1 - hy1 - sy1 * 0.6),
        ]
    else:
        shadow_corners = [
            (x1 + hx1, y1 + hy1),
            (x2 + hx2, y2 + hy2),
            (x2 + hx2 + sx2 * 0.6, y2 + hy2 + sy2 * 0.6),
            (x1 + hx1 + sx1 * 0.6, y1 + hy1 + sy1 * 0.6),
        ]
    draw.polygon(shadow_corners, fill=body_bands[1], outline=None)
    
    # 暗部最深处 (band 0) — 贴边
    deep_r1 = r1 * 0.12; deep_r2 = r2 * 0.12
    dx1 = deep_r1 * math.cos(perp); dy1 = deep_r1 * math.sin(perp)
    dx2 = deep_r2 * math.cos(perp); dy2 = deep_r2 * math.sin(perp)
    if dot_perp > 0:
        # 光在 +perp, 最暗在 -perp 边缘
        deep_pts = [
            (x1 - hx1, y1 - hy1),
            (x2 - hx2, y2 - hy2),
            (x2 - hx2 - dx2, y2 - hy2 - dy2),
            (x1 - hx1 - dx1, y1 - hy1 - dy1),
        ]
    else:
        deep_pts = [
            (x1 + hx1, y1 + hy1),
            (x2 + hx2, y2 + hy2),
            (x2 + hx2 + dx2, y2 + hy2 + dy2),
            (x1 + hx1 + dx1, y1 + hy1 + dy1),
        ]
    draw.polygon(deep_pts, fill=body_bands[0], outline=None)
    
    # 3. Rim light 高光条 (亮部最顶) — 光源同侧顶部 10% 半径窄条
    rim_r1 = r1 * 0.12; rim_r2 = r2 * 0.12
    rx1 = rim_r1 * math.cos(perp); ry1 = rim_r1 * math.sin(perp)
    rx2 = rim_r2 * math.cos(perp); ry2 = rim_r2 * math.sin(perp)
    if dot_perp > 0:
        rim_pts = [
            (x1 + hx1 - rx1, y1 + hy1 - ry1),
            (x2 + hx2 - rx2, y2 + hy2 - ry2),
            (x2 + hx2, y2 + hy2),
            (x1 + hx1, y1 + hy1),
        ]
    else:
        rim_pts = [
            (x1 - hx1 + rx1, y1 - hy1 + ry1),
            (x2 - hx2 + rx2, y2 - hy2 + ry2),
            (x2 - hx2, y2 - hy2),
            (x1 - hx1, y1 - hy1),
        ]
    draw.polygon(rim_pts, fill=body_bands[4], outline=None)

def draw_cel_ellipse(draw, cx, cy, rw, rh, bands, light_direction=LIGHT_N, rotation_deg=0):
    """赛璐璐椭圆: 主色 + 硬阴影 + rim light"""
    # 旋转后的长短轴方向
    ang = math.radians(rotation_deg)
    # 椭圆"表面"法线采样 — 用半椭圆片作为阴影
    # 简化: 阴影用多边形画在光源对面半椭圆内
    
    # 1. 主色
    draw_rot_ellipse(draw, cx, cy, rw, rh, rotation_deg, bands[2])
    
    # 2. 阴影片 — 根据光照方向确定椭圆阴影边界
    # 将 LIGHT_N 变换到椭圆局部坐标 (去旋转)
    local_lx = light_direction[0] * math.cos(-ang) - light_direction[1] * math.sin(-ang)
    local_ly = light_direction[0] * math.sin(-ang) + light_direction[1] * math.cos(-ang)
    
    # 阴影椭圆的"分界方向" = -LIGHT_N (阴影侧)
    # 画一个填充椭圆 (暗色), 只保留阴影侧 — 用多边形裁剪近似
    shadow_pts = []
    steps = 28
    # 椭圆上一点 (cos t, sin t) * (rw, rh) 在局部空间
    # 光照点积 = (x/rw) * lx + (y/rh) * ly  (归一化后)
    for i in range(steps + 1):
        t = 2 * math.pi * i / steps
        ex_local = rw * math.cos(t)
        ey_local = rh * math.sin(t)
        # 归一化法线方向
        nx = math.cos(t)
        ny = math.sin(t)
        dot = nx * local_lx + ny * local_ly
        if dot < 0.05:  # 阴影侧
            gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
            gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
            shadow_pts.append((gx, gy))
    if len(shadow_pts) >= 3:
        # 还要加上椭圆中心封闭
        shadow_pts.append((cx, cy))
        draw.polygon(shadow_pts, fill=bands[1], outline=None)
        
        # 深阴影 (bands[0]) — 在最远离光源的那片, 更窄
        deep_pts = []
        for i in range(steps + 1):
            t = 2 * math.pi * i / steps
            nx = math.cos(t); ny = math.sin(t)
            dot = nx * local_lx + ny * local_ly
            if dot < -0.35:  # 更深阴影
                ex_local = rw * math.cos(t)
                ey_local = rh * math.sin(t)
                gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
                gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
                deep_pts.append((gx, gy))
        if len(deep_pts) >= 3:
            deep_pts.append((cx, cy))
            draw.polygon(deep_pts, fill=bands[0], outline=None)
    
    # 3. Rim light — 最亮窄条在光源侧边缘
    rim_pts = []
    for i in range(steps + 1):
        t = 2 * math.pi * i / steps
        nx = math.cos(t); ny = math.sin(t)
        dot = nx * local_lx + ny * local_ly
        if dot > 0.65:  # 光源侧
            # 只画外侧窄环, 向内缩 15%
            ex_local = rw * 0.87 * math.cos(t)
            ey_local = rh * 0.87 * math.sin(t)
            gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
            gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
            rim_pts.append((gx, gy))
    if len(rim_pts) >= 3:
        # 再加上外圈, 形成环
        outer_pts = []
        for i in range(steps + 1):
            t = 2 * math.pi * i / steps
            nx = math.cos(t); ny = math.sin(t)
            dot = nx * local_lx + ny * local_ly
            if dot > 0.65:
                ex_local = rw * math.cos(t)
                ey_local = rh * math.sin(t)
                gx = cx + ex_local * math.cos(ang) - ey_local * math.sin(ang)
                gy = cy + ex_local * math.sin(ang) + ey_local * math.cos(ang)
                outer_pts.append((gx, gy))
        # 组合: 外圈反向 + 内圈正向
        combined = outer_pts + list(reversed(rim_pts))
        if len(combined) >= 4:
            draw.polygon(combined, fill=bands[4], outline=None)

# ============================================================
# 轮廓描边 (deep outline + rim outline)
# ============================================================
def draw_outline_polygon(draw, poly_points, outline_color, width=2):
    """用 arc 在 polygon 边上画描边"""
    if len(poly_points) < 2: return
    flat = [coord for pt in poly_points for coord in pt]
    if len(flat) >= 4:
        draw.line(flat, fill=outline_color, width=width)
        # 画终点到起点闭合
        draw.line([poly_points[-1], poly_points[0]], fill=outline_color, width=width)
        # 顶点小圆 (让转角不尖)
        for pt in poly_points:
            draw.ellipse([pt[0]-width//2, pt[1]-width//2, pt[0]+width//2, pt[1]+width//2], 
                        fill=outline_color, outline=None)

def draw_capsule_outline(draw, p1, p2, r1, r2, outline_color, width=2):
    x1, y1 = p1; x2, y2 = p2
    angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
    perp = math.radians(angle + 90)
    hx1 = r1 * math.cos(perp); hy1 = r1 * math.sin(perp)
    hx2 = r2 * math.cos(perp); hy2 = r2 * math.sin(perp)
    
    # 外轮廓点 (顺时针)
    outer = [
        (x1 + hx1, y1 + hy1),
        (x2 + hx2, y2 + hy2),
        (x2 - hx2, y2 - hy2),
        (x1 - hx1, y1 - hy1),
    ]
    draw_outline_polygon(draw, outer, outline_color, width)
    
    # 两端圆弧 (用 arc)
    draw.arc([x1-r1, y1-r1, x1+r1, y1+r1], angle+90, angle+270, fill=outline_color, width=width)
    draw.arc([x2-r2, y2-r2, x2+r2, y2+r2], angle-90, angle+90, fill=outline_color, width=width)

# ============================================================
# 衣褶 / 装甲板块细节
# ============================================================
def draw_torso_folds(draw, pelvis_pos, torso_pos, body_bands, accent, cls, light_dir=LIGHT_N):
    """躯干褶皱暗线 + 职业装甲板块"""
    px, py = pelvis_pos
    tx, ty = torso_pos
    mid_x = (px + tx) / 2
    mid_y = (py + ty) / 2
    
    # 1. 中央分割暗线 (腰部褶皱)
    draw.line([(mid_x - 2, mid_y + 15), (mid_x - 2, py - 8)], 
              fill=body_bands[0], width=2)
    draw.line([(mid_x + 2, mid_y + 15), (mid_x + 2, py - 8)], 
              fill=body_bands[0], width=2)
    
    # 2. 腰带 (所有职业)
    draw.rectangle([px-30, py-4, px+30, py+8], fill=body_bands[0])
    draw.rectangle([px-30, py-4, px+30, py-2], fill=body_bands[1])  # 腰带亮边
    # 腰带扣
    draw.ellipse([px-4, py-1, px+4, py+5], fill=accent, outline=None)
    
    # 3. 肩甲接缝 (胸甲板块分割)
    # 从肩向下到腰带的板块缝隙
    for side_x in [tx - 18, tx + 18]:
        draw.line([(side_x, ty + 14), (side_x + 3, mid_y + 20)], 
                  fill=body_bands[0], width=1)
    
    # 4. 职业专属胸甲装饰
    if cls == "barbarian":
        # 野蛮人皮甲: 肩甲铆钉
        for sx in [tx - 26, tx + 26]:
            for sy_off in [6, 14]:
                draw.ellipse([sx-3, ty+sy_off-3, sx+3, ty+sy_off+3], fill=accent)
        # 中央兽骨/獠牙装饰
        draw.polygon([
            (tx, ty+8), (tx-5, ty+18), (tx, ty+28), (tx+5, ty+18)
        ], fill=accent, outline=None)
    elif cls == "sorceress":
        # 女巫布袍: V 形领口 + 符文
        draw.pieslice([tx-40, ty-6, tx+40, ty+20], 0, 180, fill=body_bands[0])
        draw.text((tx-8, ty+8), "❖", fill=accent)
        # 兜帽下的皮肤露出来
        draw.arc([tx-14, ty-4, tx+14, ty+14], 10, 170, fill=(218, 182, 162), width=3)
    elif cls == "amazon":
        # 亚马逊皮甲 + 叶片纹饰
        draw.polygon([
            (tx, ty+4), (tx+14, ty+14), (tx, ty+28), (tx-14, ty+14)
        ], fill=accent)
        # 肩部绑带
        for sx in [tx - 22, tx + 22]:
            draw.line([(sx, ty+8), (sx+2, ty+22)], fill=accent, width=2)
    elif cls == "assassin":
        # 刺客黑衣: 锁链暗纹
        for i in range(4):
            cx_i = tx - 12 + i * 8
            for j in range(2):
                cy_i = ty + 10 + j * 10
                draw.ellipse([cx_i-2, cy_i-2, cx_i+2, cy_i+2], fill=accent)
        # 颈部围巾/面罩
        draw.rectangle([tx-22, ty-4, tx+22, ty+12], fill=body_bands[0])

# ============================================================
# 赛璐璐武器 (金属质感 + 高光条)
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
    
    if cls == "barbarian":
        # 巨剑
        sword_len = 130
        sword_end = (hx + math.cos(rad) * sword_len, hy + math.sin(rad) * sword_len)
        # 剑柄
        draw_cel_capsule(draw, (hx, hy), 
                        (hx + math.cos(rad)*20, hy + math.sin(rad)*20), 
                        5, 4, [(30,18,10),(48,30,18),(68,42,24),(95,62,38),(130,90,60)])
        # 护手 (横向金属条)
        gx = hx + math.cos(rad) * 20; gy = hy + math.sin(rad) * 20
        perp = (rad + math.pi/2)
        guard_p1 = (gx + math.cos(perp)*14, gy + math.sin(perp)*14)
        guard_p2 = (gx - math.cos(perp)*14, gy - math.sin(perp)*14)
        draw_cel_capsule(draw, guard_p1, guard_p2, 5, 5, [metal_edge,metal_dark,metal_mid,metal_light,(250,230,180)])
        # 剑刃 (梯形 + 金属高光)
        bx1 = gx + math.cos(perp)*22; by1 = gy + math.sin(perp)*22
        bx2 = gx - math.cos(perp)*22; by2 = gy - math.sin(perp)*22
        ex = sword_end[0] + math.cos(perp)*5; ey = sword_end[1] + math.sin(perp)*5
        ex2 = sword_end[0] - math.cos(perp)*5; ey2 = sword_end[1] - math.sin(perp)*5
        # 金属主色
        draw.polygon([(bx1,by1),(bx2,by2),(ex2,ey2),(ex,ey)], fill=metal_mid)
        # 刃高光条 (中间亮)
        mid1x = (bx1+bx2)/2; mid1y = (by1+by2)/2
        mid2x = (ex+ex2)/2; mid2y = (ey+ey2)/2
        draw.line([(mid1x,mid1y),(mid2x,mid2y)], fill=metal_light, width=3)
        # 刃暗边 (两侧)
        for side_off in [4, -4]:
            s1x = mid1x + math.cos(perp)*side_off
            s1y = mid1y + math.sin(perp)*side_off
            s2x = mid2x + math.cos(perp)*side_off * 0.5
            s2y = mid2y + math.sin(perp)*side_off * 0.5
            draw.line([(s1x,s1y),(s2x,s2y)], fill=metal_edge, width=1)
        # 剑刃轮廓
        draw.line([(bx1,by1),(ex,ey)], fill=metal_edge, width=2)
        draw.line([(bx2,by2),(ex2,ey2)], fill=metal_edge, width=2)
        draw.line([(ex,ey),(ex2,ey2)], fill=metal_edge, width=2)
        # 剑尖火焰
        for i in range(4):
            fx = sword_end[0] - math.cos(rad)*(8+i*7)
            fy = sword_end[1] - math.sin(rad)*(8+i*7)
            size = max(2, 5 - i)
            c = blend((255, 200, 80), (255, 60, 30), i/3)
            draw.ellipse([fx-size, fy-size, fx+size, fy+size], fill=c)
        # 剑柄缠绕
        for i in range(4):
            px_h = hx + math.cos(rad)*(6+i*4)
            py_h = hy + math.sin(rad)*(6+i*4)
            draw.line([(px_h-3, py_h+3),(px_h+3, py_h-3)], fill=metal_edge, width=1)
    
    elif cls == "sorceress":
        # 法杖
        staff_top = (hx + math.cos(rad)*190, hy + math.sin(rad)*190)
        bottom = (hx - math.cos(rad)*30, hy - math.sin(rad)*30)
        draw_cel_capsule(draw, bottom, staff_top, 4, 3,
                        [(35,22,14),(58,38,22),(82,55,32),(115,78,48),(160,115,75)])
        # 法杖金属环
        ring_positions = [0.2, 0.5, 0.75]
        for rp in ring_positions:
            rx_p = bottom[0] + (staff_top[0]-bottom[0])*rp
            ry_p = bottom[1] + (staff_top[1]-bottom[1])*rp
            perp2 = (rad + math.pi/2)
            draw.line([(rx_p+math.cos(perp2)*6, ry_p+math.sin(perp2)*6),
                      (rx_p-math.cos(perp2)*6, ry_p-math.sin(perp2)*6)],
                     fill=(200,180,100), width=3)
        # 顶部魔法宝石 (发光球)
        gcx, gcy = staff_top
        for i, rad_g in enumerate([16, 12, 8, 4]):
            alpha_colors = [(60, 120, 200), (80, 180, 255), (180, 230, 255), (255, 255, 255)]
            draw.ellipse([gcx-rad_g, gcy-rad_g, gcx+rad_g, gcy+rad_g], fill=alpha_colors[i])
        # 宝石高光
        draw.ellipse([gcx-3, gcy-5, gcx+2, gcy-1], fill=(255,255,255))
        # 法杖底端宝石
        bx_p = bottom[0]; by_p = bottom[1]
        draw.ellipse([bx_p-8, by_p-8, bx_p+8, by_p+8], fill=(80, 180, 255))
        draw.ellipse([bx_p-3, by_p-4, bx_p+2, by_p-1], fill=(255,255,255))
    
    elif cls == "amazon":
        # 长弓
        bow_len = 150
        bx1 = hx + math.cos(rad)*65; by1 = hy + math.sin(rad)*65
        bx2 = hx - math.cos(rad)*85; by2 = hy - math.sin(rad)*85
        perp = (rad + math.pi/2)
        mid_x = (bx1+bx2)/2 + math.cos(perp)*48
        mid_y = (by1+by2)/2 + math.sin(perp)*48
        # 弓身: 画一段圆弧 — 用 polygon 近似厚弧
        steps = 20
        bow_pts = []
        for i in range(steps+1):
            t = i / steps
            cx_arc = (bx1+bx2)/2
            cy_arc = (by1+by2)/2
            # 从 bx1,by1 到 bx2,by2 经过 mid_x,mid_y 的二次贝塞尔
            qx = (1-t)*(1-t)*bx1 + 2*(1-t)*t*mid_x + t*t*bx2
            qy = (1-t)*(1-t)*by1 + 2*(1-t)*t*mid_y + t*t*by2
            bow_pts.append((qx, qy))
        # 弓身 (厚条带)
        offset_outer = [(p[0] + math.cos(perp)*4, p[1] + math.sin(perp)*4) for p in bow_pts]
        offset_inner = [(p[0] - math.cos(perp)*4, p[1] - math.sin(perp)*4) for p in bow_pts]
        bow_body = offset_outer + list(reversed(offset_inner))
        draw.polygon(bow_body, fill=(100, 70, 40), outline=None)
        # 弓身亮边
        draw.line(bow_pts, fill=(140, 100, 60), width=2)
        # 弓身暗边
        rev_bow = list(reversed(bow_pts))
        draw.line(rev_bow, fill=(60, 40, 22), width=2)
        # 弓弦 (亮白细线)
        draw.line([(bx1, by1), (bx2, by2)], fill=(230, 225, 200), width=1)
        draw.line([(bx1, by1), (bx2, by2)], fill=(255, 255, 240), width=1)
        # 弓尖装饰
        draw.ellipse([bx1-3, by1-3, bx1+3, by1+3], fill=accent)
        draw.ellipse([bx2-3, by2-3, bx2+3, by2+3], fill=accent)
    
    elif cls == "assassin":
        # 双匕 — 只画右手那把 (左手藏在背后)
        dagger_len = 55
        tip = (hx + math.cos(rad)*dagger_len, hy + math.sin(rad)*dagger_len)
        # 刀柄
        draw_cel_capsule(draw, (hx, hy), 
                        (hx + math.cos(rad)*16, hy + math.sin(rad)*16),
                        4, 3, [(18,18,24),(32,32,42),(48,48,60),(72,72,86),(100,100,120)])
        # 护手 (金)
        bx_h = hx + math.cos(rad)*16; by_h = hy + math.sin(rad)*16
        perp = (rad + math.pi/2)
        g1 = (bx_h + math.cos(perp)*9, by_h + math.sin(perp)*9)
        g2 = (bx_h - math.cos(perp)*9, by_h - math.sin(perp)*9)
        draw.line([g1, g2], fill=(220, 180, 60), width=4)
        draw.line([g1, g2], fill=(250, 215, 110), width=2)
        # 刀身 (三角 + 高光)
        perp = (rad + math.pi/2)
        tip_off = (math.cos(perp)*9, math.sin(perp)*9)
        blade_pts = [
            (bx_h + tip_off[0], by_h + tip_off[1]),
            (bx_h - tip_off[0], by_h - tip_off[1]),
            tip,
        ]
        draw.polygon(blade_pts, fill=metal_mid)
        # 刀身中央高光线
        draw.line([(bx_h, by_h), tip], fill=metal_light, width=2)
        # 刀身暗边
        draw.line([(bx_h + tip_off[0], by_h + tip_off[1]), tip], fill=metal_edge, width=2)
        draw.line([(bx_h - tip_off[0], by_h - tip_off[1]), tip], fill=metal_edge, width=2)

# ============================================================
# 赛璐璐面部细节
# ============================================================
def draw_face_cel(draw, head_pos, head_rot, cls, pal):
    hx, hy = head_pos
    skin_bands = pal["skin_bands"]
    hair_bands = pal["hair_bands"]
    outline = pal["outline"]
    accent = pal["accent"]
    rim = pal["rim"]
    eye_color = pal["eye_color"]
    
    # 脖子 (先用 skin band 2 画, 后面头会盖住上部)
    torso_pos = None  # 调用方会设置
    return None  # 脖子在主 draw_character 里画
    
def draw_neck_cel(draw, head_pos, torso_pos, skin_bands):
    hx, hy = head_pos
    tx, ty = torso_pos
    # 脖子圆柱 — 赛璐璐
    mid_x = (hx + tx) / 2
    draw.line([(hx-8, hy+18), (tx-6, ty-8)], fill=skin_bands[0], width=8)
    draw.line([(hx-6, hy+18), (tx-4, ty-8)], fill=skin_bands[2], width=5)
    draw.line([(hx+2, hy+18), (tx+4, ty-8)], fill=skin_bands[3], width=3)

def draw_head_cel(draw, head_pos, head_rot, cls, pal):
    hx, hy = head_pos
    skin_bands = pal["skin_bands"]
    hair_bands = pal["hair_bands"]
    outline = pal["outline"]
    rim = pal["rim"]
    eye_color = pal["eye_color"]
    
    # 1. 脸部 (椭圆) — 赛璐璐硬阴影
    draw_cel_ellipse(draw, hx, hy, 22, 24, skin_bands, LIGHT_N, head_rot)
    # 脸部轮廓
    draw.ellipse([hx-22, hy-24, hx+22, hy+22], outline=outline, width=2)
    
    # 2. 发型 (职业差异)
    if cls == "barbarian":
        # 棕色长发 + 胡须
        # 头顶发团
        hair_pts = []
        steps = 32
        for i in range(steps+1):
            a = math.pi * i / steps  # 上半圆 (从左到右)
            r = 24 + math.sin(a*3) * 2  # 略锯齿
            hair_pts.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        # 下方延伸的长发 (两侧+后)
        hair_pts.extend([
            (hx-26, hy+6), (hx-24, hy+18), (hx-18, hy+28),
            (hx+18, hy+28), (hx+24, hy+18), (hx+26, hy+6)
        ])
        draw.polygon(hair_pts, fill=hair_bands[2], outline=None)
        # 发阴影 (内侧)
        shadow_pts = []
        for i in range(steps+1):
            a = math.pi * i / steps
            r = 20 + math.sin(a*3) * 1.5
            shadow_pts.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        draw.polygon(shadow_pts, fill=hair_bands[1], outline=None)
        # 头发 rim light (顶侧)
        rim_pts = []
        for i in range(int(steps*0.6), int(steps*0.9)):
            a = math.pi * i / steps
            r = 24.5
            rim_pts.append((hx - r * math.cos(a), hy - r * math.sin(a)))
        if len(rim_pts) > 2:
            draw.line(rim_pts, fill=hair_bands[4], width=2)
        # 胡须
        beard_pts = []
        for i in range(20):
            t = i / 19
            bx = hx - 16 + t * 32
            by = hy + 10 + abs(math.sin(t*math.pi*2)) * 14 + 6
            beard_pts.append((bx, by))
        beard_pts.extend([(hx+16, hy+10), (hx-16, hy+10)])
        draw.polygon(beard_pts, fill=hair_bands[2], outline=None)
        # 胡须暗部
        for i in range(5):
            bx_b = hx - 12 + i * 6
            draw.line([(bx_b, hy+12), (bx_b + 2, hy+22)], fill=hair_bands[1], width=2)
    
    elif cls == "sorceress":
        # 兜帽 + 银发
        # 兜帽 (大半圆 + 尖顶)
        hood_pts = []
        steps = 40
        for i in range(steps+1):
            a = math.pi * i / steps
            r = 30
            hood_pts.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        hood_pts.extend([(hx-28, hy-2), (hx, hy-40), (hx+28, hy-2)])  # 尖顶闭合
        # 兜帽主体色 = body_bands 的 band 2
        draw.polygon(hood_pts, fill=pal["body_bands"][2], outline=None)
        # 兜帽内侧阴影 (暗部)
        inner_pts = []
        for i in range(steps+1):
            a = math.pi * i / steps
            r = 23
            inner_pts.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        inner_pts.append((hx-23, hy-2))
        inner_pts.append((hx+23, hy-2))
        draw.polygon(inner_pts, fill=pal["body_bands"][0], outline=None)
        # 兜帽 rim light (顶)
        rim_pts = []
        for i in range(int(steps*0.35), int(steps*0.65)):
            a = math.pi * i / steps
            r = 30
            rim_pts.append((hx - r * math.cos(a), hy - 4 - r * math.sin(a)))
        if len(rim_pts) > 2:
            draw.line(rim_pts, fill=pal["rim"], width=2)
        # 兜帽尖
        draw.polygon([(hx, hy-44), (hx-10, hy-10), (hx+10, hy-10)], fill=pal["body_bands"][1])
        # 银发 (从兜帽露出)
        draw.arc([hx-22, hy-18, hx+22, hy+12], 200, 340, fill=hair_bands[3], width=3)
        draw.arc([hx-20, hy-16, hx+20, hy+10], 200, 340, fill=hair_bands[4], width=1)
        # 兜帽轮廓
        draw.arc([hx-30, hy-38, hx+30, hy+10], 180, 360, fill=outline, width=2)
    
    elif cls == "amazon":
        # 高马尾 + 额头束带
        # 头发主体 (侧分)
        hair_pts = []
        steps = 32
        for i in range(steps+1):
            a = math.pi * 0.8 + math.pi * 0.4 * i / steps  # 偏右侧
            r = 23 + math.sin(i*0.6) * 1.5
            hair_pts.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        hair_pts.extend([(hx-22, hy+4), (hx-20, hy-6), (hx+10, hy-12), (hx+14, hy-4), (hx-22, hy+4)])
        draw.polygon(hair_pts, fill=hair_bands[2], outline=None)
        # 头发暗部
        dark_hair = []
        for i in range(steps+1):
            a = math.pi * 0.8 + math.pi * 0.4 * i / steps
            r = 18 + math.sin(i*0.6)
            dark_hair.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        draw.polygon(dark_hair, fill=hair_bands[1], outline=None)
        # 头发 rim (亮)
        rim_pts = []
        for i in range(int(steps*0.2), int(steps*0.5)):
            a = math.pi * 0.8 + math.pi * 0.4 * i / steps
            r = 23.5
            rim_pts.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        if len(rim_pts) > 2:
            draw.line(rim_pts, fill=hair_bands[4], width=2)
        # 束发带 (叶子形)
        draw.polygon([(hx-18, hy-12), (hx+10, hy-16), (hx+12, hy-10), (hx-16, hy-6)], 
                     fill=pal["accent"])
        # 马尾 (向右上延伸)
        plait_p1 = (hx+16, hy-10)
        plait_p2 = (hx+34, hy-22)
        draw_cel_capsule(draw, plait_p1, plait_p2, 6, 4, hair_bands)
        draw.arc([hx+10, hy-20, hx+40, hy-2], 210, 340, fill=hair_bands[0], width=2)
    
    elif cls == "assassin":
        # 头巾 + 面罩 (只露眼睛)
        # 头巾
        turban_pts = []
        steps = 36
        for i in range(steps+1):
            a = math.pi * i / steps
            r = 26 + math.sin(a*4) * 3
            turban_pts.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        turban_pts.extend([(hx-24, hy-4), (hx+24, hy-4)])
        draw.polygon(turban_pts, fill=hair_bands[2], outline=None)
        # 头巾阴影
        shadow_t = []
        for i in range(steps+1):
            a = math.pi * i / steps
            r = 20 + math.sin(a*4) * 2
            shadow_t.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        shadow_t.append((hx-20, hy-4))
        shadow_t.append((hx+20, hy-4))
        draw.polygon(shadow_t, fill=hair_bands[1], outline=None)
        # 头巾 rim
        rim_pts = []
        for i in range(int(steps*0.3), int(steps*0.7)):
            a = math.pi * i / steps
            r = 26.5
            rim_pts.append((hx - r * math.cos(a), hy - 2 - r * math.sin(a)))
        if len(rim_pts) > 2:
            draw.line(rim_pts, fill=pal["rim"], width=2)
        # 头巾尾 (垂在一侧)
        tail_pts = []
        for i in range(10):
            t = i / 9
            tx_t = hx + 20 + t * 14
            ty_t = hy - 4 + t * 18 + math.sin(t*math.pi) * 4
            tail_pts.append((tx_t, ty_t))
        tail_pts.reverse()
        for i in range(10):
            t = i / 9
            tx_t = hx + 24 + t * 14
            ty_t = hy - 4 + t * 18 + math.sin(t*math.pi) * 4 + 4
            tail_pts.append((tx_t, ty_t))
        draw.polygon(tail_pts, fill=hair_bands[2], outline=None)
        # 面罩 (遮住嘴和下巴)
        mask_pts = [
            (hx-22, hy-2), (hx-24, hy+22), (hx-18, hy+26),
            (hx, hy+28), (hx+18, hy+26), (hx+24, hy+22), (hx+22, hy-2)
        ]
        draw.polygon(mask_pts, fill=hair_bands[0], outline=None)
        draw.polygon([(hx-22, hy-2), (hx-24, hy+8), (hx+24, hy+8), (hx+22, hy-2)], 
                    fill=hair_bands[1], outline=None)
    
    # 3. 眼睛 (所有职业 — 瞳孔 + 高光)
    eye_rot = math.radians(head_rot)
    for ex_off, ey_off in [(-8, -2), (8, -2)]:
        epx = hx + ex_off * math.cos(eye_rot) - ey_off * math.sin(eye_rot)
        epy = hy + ex_off * math.sin(eye_rot) + ey_off * math.cos(eye_rot)
        # 眼眶阴影 (细暗线)
        draw.arc([epx-6, epy-4, epx+6, epy+6], 200, 340, fill=skin_bands[0], width=1)
        # 眼白
        draw.ellipse([epx-4, epy-3, epx+4, epy+3], fill=skin_bands[4], outline=None)
        # 瞳孔
        draw.ellipse([epx-2.5, epy-2.5, epx+2.5, epy+2.5], fill=eye_color)
        # 瞳孔中心更深
        draw.ellipse([epx-1.5, epy-1.5, epx+1.5, epy+1.5], fill=(20, 15, 12))
        # 瞳孔高光 (小白点)
        draw.ellipse([epx-0.5, epy-2, epx+1.5, epy-0.5], fill=(255, 255, 255))
    
    # 4. 嘴 (除了 assassin 有面罩)
    if cls != "assassin":
        mouth_cx = hx
        mouth_cy = hy + 10
        # 下唇阴影
        draw.arc([mouth_cx-5, mouth_cy+2, mouth_cx+5, mouth_cy+8], 10, 170, 
                 fill=skin_bands[0], width=2)
        # 上唇 (红色)
        lip_color = (160, 75, 65)
        draw.arc([mouth_cx-5, mouth_cy-2, mouth_cx+5, mouth_cy+4], 10, 170, 
                 fill=lip_color, width=2)
        # 上唇高光
        draw.arc([mouth_cx-4, mouth_cy-2, mouth_cx+4, mouth_cy+2], 30, 150, 
                 fill=(210, 120, 105), width=1)

# ============================================================
# 完整绘制一个赛璐璐角色帧
# ============================================================
def draw_character_cel(draw, bone_transforms, cls, facing=1.0, pose_info=None):
    pal = CLASS_PALETTE[cls]
    body_bands = pal["body_bands"]
    skin_bands = pal["skin_bands"]
    hair_bands = pal["hair_bands"]
    outline = pal["outline"]
    rim = pal["rim"]
    accent = pal["accent"]
    
    def bone_segment(name):
        parent = PARENT[name]
        if parent is None: return bone_transforms[name][1], bone_transforms[name][1]
        return bone_transforms[parent][1], bone_transforms[name][1]
    
    # ---- 绘制顺序: 腿 → 骨盆 → 躯干 → 臂 → 头 → 武器 → 轮廓 ----
    
    # 1. 腿 (赛璐璐硬阴影)
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        draw_cel_capsule(draw, p1, p2, 17, 13, body_bands)
    
    # 2. 骨盆
    px, py = bone_transforms["pelvis"][1]
    draw_cel_ellipse(draw, px, py, 28, 24, body_bands, LIGHT_N, 0)
    
    # 3. 躯干 (赛璐璐胶囊)
    torso_pelvis = bone_transforms["pelvis"][1]
    torso_shoulder = bone_transforms["torso"][1]
    draw_cel_capsule(draw, torso_pelvis, torso_shoulder, 42, 38, body_bands)
    # 躯干褶皱 + 职业胸甲装饰
    draw_torso_folds(draw, torso_pelvis, torso_shoulder, body_bands, accent, cls)
    
    # 4. 肩膀装甲 (赛璐璐椭圆)
    shoulder_pos = bone_transforms["torso"][1]
    for arm_name in ["arm_l", "arm_r"]:
        arm_pos = bone_transforms[arm_name][1]
        sx = (shoulder_pos[0] + arm_pos[0]) / 2
        sy = (shoulder_pos[1] + arm_pos[1]) / 2 - 4
        draw_cel_ellipse(draw, sx, sy, 16, 14, body_bands, LIGHT_N, 0)
        # 肩甲 rim
        draw.arc([sx-17, sy-15, sx+17, sy+15], 190, 350, fill=accent, width=2)
    
    # 5. 手臂
    for arm in ["arm_l", "arm_r"]:
        p1, p2 = bone_segment(arm)
        draw_cel_capsule(draw, p1, p2, 13, 9, body_bands)
        # 护手 (皮肤椭圆)
        hx, hy = p2
        draw_cel_ellipse(draw, hx, hy, 10, 10, skin_bands, LIGHT_N, 0)
    
    # 6. 武器 (画在右手 arm_r)
    arm_r_end = bone_transforms["arm_r"][1]
    arm_r_rot = bone_transforms["arm_r"][0]
    draw_weapon_cel(draw, arm_r_end, arm_r_rot, cls, facing, pal)
    
    # 7. 脖子 (先画, 被头盖住上半)
    head_pos = bone_transforms["head"][1]
    torso_pos = bone_transforms["torso"][1]
    draw_neck_cel(draw, head_pos, torso_pos, skin_bands)
    
    # 8. 头 + 发型 + 面部 (职业差异)
    draw_head_cel(draw, head_pos, bone_transforms["head"][0], cls, pal)
    
    # ---- 轮廓描边 (顶层覆盖, 赛璐璐核心) ----
    # 腿轮廓
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        draw_capsule_outline(draw, p1, p2, 17, 13, outline, 2)
    # 骨盆轮廓
    px, py = bone_transforms["pelvis"][1]
    draw.ellipse([px-28, py-24, px+28, py+24], outline=outline, width=2)
    # 躯干轮廓
    draw_capsule_outline(draw, torso_pelvis, torso_shoulder, 42, 38, outline, 2)
    # 肩甲轮廓
    for arm_name in ["arm_l", "arm_r"]:
        arm_pos = bone_transforms[arm_name][1]
        sx = (shoulder_pos[0] + arm_pos[0]) / 2
        sy = (shoulder_pos[1] + arm_pos[1]) / 2 - 4
        draw.ellipse([sx-16, sy-14, sx+16, sy+14], outline=outline, width=2)
    # 手臂轮廓
    for arm in ["arm_l", "arm_r"]:
        p1, p2 = bone_segment(arm)
        draw_capsule_outline(draw, p1, p2, 13, 9, outline, 2)
    # 头轮廓
    hx, hy = head_pos
    draw.ellipse([hx-22, hy-24, hx+22, hy+22], outline=outline, width=2)
    
    # ---- Rim Light 描边 (职业主题色, 只在光源侧) ----
    # 腿 rim
    for leg in ["leg_l", "leg_r"]:
        p1, p2 = bone_segment(leg)
        x1, y1 = p1; x2, y2 = p2
        angle = math.degrees(math.atan2(y2 - y1, x2 - x1))
        perp = math.radians(angle + 90)
        dot_perp = LIGHT_N[0] * math.cos(perp) + LIGHT_N[1] * math.sin(perp)
        r = 15  # 腿平均半径
        if dot_perp > 0:
            # 光在 +perp 侧, 在那边画 rim
            hx_l = r * math.cos(perp); hy_l = r * math.sin(perp)
            draw.line([(x1+hx_l, y1+hy_l), (x2+hx_l, y2+hy_l)], fill=rim, width=1)
        else:
            hx_l = -r * math.cos(perp); hy_l = -r * math.sin(perp)
            draw.line([(x1+hx_l, y1+hy_l), (x2+hx_l, y2+hy_l)], fill=rim, width=1)
    
    # ---- 地面阴影 (深色椭圆) ----
    px_, py_ = bone_transforms["pelvis"][1]
    foot_y = py_ + 120
    for i, (alpha, dy_s, w_s) in enumerate([(60, 0, 55), (40, 3, 48), (20, 6, 40)]):
        s_a = alpha
        draw.ellipse([px_-w_s, foot_y+dy_s, px_+w_s, foot_y+14+dy_s], 
                    fill=(0, 0, 0))

# ============================================================
# 动作库 (和 v7 相同, 保证动画一致)
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

ACTION_GROUPS = [
    ("待机", "idle",   lambda cls, k: idle_frame(k), "站立呼吸微摆"),
    ("行走", "run",    lambda cls, k: run_frame(cls, k), "行走循环"),
    ("普攻", "attack", None,                              "基础攻击"),
    ("技能", "skill",  None,                              None),
    ("挥手致意", "wave",   lambda cls, k: wave_frame(k),  "日常交互"),
    ("欢呼庆祝", "cheer",  lambda cls, k: cheer_frame(k), "日常交互"),
]

# ============================================================
# 主流程 — 赛璐璐硬阴影绘制 4×24=96 帧
# ============================================================
CANVAS_W, CANVAS_H = 420, 540

def make_bg(w, h, cls):
    """职业主色渐变背景"""
    pal = CLASS_PALETTE[cls]
    dark_c = pal["body_bands"][0]
    base_c = pal["body_bands"][2]
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
    # 地面线
    draw.line([(30, h-50), (w-30, h-50)], fill=(30, 38, 52), width=1)
    # 地面纹理 (小点)
    import random
    rng = random.Random(hash(cls))
    for _ in range(20):
        gx = rng.randint(30, w-30)
        gy = rng.randint(h-48, h-35)
        draw.point((gx, gy), fill=(40, 50, 70))
    return canvas

print("=" * 70)
print("v9 — Cel-Shading 赛璐璐硬阴影 · 程序化 2D 骨架动画")
print("     硬阴影带 + 双轮廓描边 + 衣褶 + 金属高光 + 面部细节")
print("     6 动作 × 4 帧 = 24 帧/职业, 4 职业 = 96 帧")
print("=" * 70)

all_sheets = {}

for cls in CLASS_PALETTE:
    cn = CLASS_PALETTE[cls]["name"]
    skill_cn = CLASS_PALETTE[cls]["weapon_cn"]
    weapon = CLASS_PALETTE[cls]["weapon"]
    print(f"\n{'─'*10} {cls} / {cn} ({weapon}) {'─'*10}")
    
    frames = {}
    
    for gidx, (cn_label, en_pfx, gen_func, desc) in enumerate(ACTION_GROUPS):
        label = skill_cn if cn_label == "技能" else cn_label
        for k in range(4):
            if en_pfx == "attack":
                rots = interp(ATTACK_KFS[cls], ATTACK_KFS[cls][k][0])
            elif en_pfx == "skill":
                rots = interp(SKILL_KFS[cls], SKILL_KFS[cls][k][0])
            else:
                rots = gen_func(cls, k)
            
            bt = fk(rots, facing=1.0, pelvis_pos=(CANVAS_W//2, CANVAS_H-120))
            
            canvas = make_bg(CANVAS_W, CANVAS_H, cls)
            draw = ImageDraw.Draw(canvas)
            
            # 赛璐璐角色绘制
            draw_character_cel(draw, bt, cls, facing=1.0)
            
            fname = f"{en_pfx}_{k+1}"
            frames[fname] = (canvas, label, k+1)
    
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, (frm, _, _) in frames.items():
        frm.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # ---- Contact Sheet ----
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
    
    d.text((MAR+8, MAR+4), 
           f"{cn} ({cls})  ·  武器: {weapon}  ·  技能: {skill_cn}", 
           fill=(230, 210, 150))
    d.text((MAR+8, MAR+20), 
           "▸ Cel-Shading 赛璐璐硬阴影  |  硬阴影带 + 双轮廓 + Rim Light  |  纯程序化", 
           fill=(120, 140, 170))
    
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
sh2 = ROWS2*TH2 + (ROWS2+1)*MAR2 + 120
ov = Image.new("RGB", (sw2, sh2), (6, 8, 16))
d = ImageDraw.Draw(ov)
d.text((MAR2, 22), "⚔ v9 Cel-Shading 赛璐璐硬阴影 · 程序化 2D 骨架动画", fill=(255, 80, 60))
d.text((MAR2, 46), "硬阴影带 (3 档亮度) + 双轮廓描边 + 职业主题色 Rim Light + 金属武器高光", fill=(150, 165, 190))
d.text((MAR2, 64), f"4 职业 × 6 动作 × 4 帧 = 共 {4*6*4} 帧  |  纯 Python/PIL · 每一帧独立绘制 · 不切割无贴图", fill=(100, 115, 140))
d.text((MAR2, 82), "光照: 左上偏上 (LIGHT_N)  |  硬阴影 band: 暗部 / 主色 / 亮色  |  Rim Light: 职业主题色", fill=(80, 95, 120))

for idx, cls in enumerate(CLASS_PALETTE):
    r, c = divmod(idx, COLS2)
    sx = MAR2 + c*(TW2+MAR2); sy = 120 + MAR2 + r*(TH2+MAR2)
    s = all_sheets[cls]
    crop = s.crop((8, 40+8, min(s.size[0], 8+TW2), 40+8+TH2)).resize((TW2, TH2), Image.BILINEAR)
    ov.paste(crop, (sx, sy))
    cn = CLASS_PALETTE[cls]["name"]
    skill = CLASS_PALETTE[cls]["weapon_cn"]
    rim_c = CLASS_PALETTE[cls]["rim"]
    label = f"▸ {cn}  |  武器: {CLASS_PALETTE[cls]['weapon']}  |  技能: {skill}  |  Rim: ({rim_c[0]},{rim_c[1]},{rim_c[2]})"
    d.rectangle([sx, sy-22, sx+TW2, sy+2], fill=(14, 20, 30))
    d.text((sx+8, sy-18), label, fill=(255, 220, 150))
    d.rectangle([sx, sy, sx+TW2, sy+TH2], outline=(200, 70, 70), width=2)

ov.save(f"{OUT}/overview_v9_celshading.jpg", "JPEG", quality=92)
print(f"\n✓ 总览 overview_v9_celshading.jpg: {sw2}×{sh2}")
print(f"\n全部完成! 输出: {OUT}/")
print(f"  4 职业 × 6 动作 × 4 帧 = 96 帧")
print(f"  Cel-Shading: 硬阴影带 + 深色外轮廓 + 职业主题色 Rim Light + 金属武器高光")
print(f"  纯 Python/PIL 程序化绘制 — 不切割, 无贴图")
