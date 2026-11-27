#!/usr/bin/env python3
"""
鸟山明画风 Godot 精灵生成器
规格: 128x128 RGBA, 4x4网格, 每帧 32x32
行=方向(下/左/右/上), 列=行走动画帧

鸟山明画风核心:
- 2头身大头 (ellipse大头, ellipse身体)
- 圆形大眼 + 双高光
- 细黑描边 1px (outline, 外轮廓)
- 纯平涂色块 + 1层阴影
- 尖锐刺猬头/蓬松弧线 (polygon尖角)
- 四肢用细椭圆 (arm-limb, leg-limb)
"""

from PIL import Image, ImageDraw
import os, math

FRAME = 32
GRID = 4
SHEET = FRAME * GRID  # 128

OUTPUT_DIR = "/workspace/通天入地/assets/sprites/world"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ========= 调色板 (鸟山明明快配色) =========
PAL = {
    "warrior": {
        "skin": "#fde1c4", "skin_sh": "#e8b890",
        "hair": "#1a1a2e",
        "eye_w": "#ffffff", "eye": "#1a1a2e", "eye_hi": "#ffffff",
        "armor": "#d4d8e0", "armor_sh": "#9ea3ad",
        "red": "#e74c3c", "gold": "#f1c40f",
        "sword": "#e8e8f0", "hilt": "#8b4513",
        "boot": "#2c3e50",
        "line": "#1a1a2e"   # 鸟山明黑色细描边
    },
    "mage": {
        "skin": "#fde1c4", "skin_sh": "#e8b890",
        "hair": "#6a4fa0",
        "eye_w": "#ffffff", "eye": "#6a1b9a", "eye_hi": "#ffffff",
        "robe": "#4a148c", "robe_sh": "#2d0a54",
        "gold": "#f1c40f",
        "boot": "#5d4037",
        "staff": "#8b4513", "crystal": "#00d4ff",
        "line": "#1a1a2e"
    },
    "archer": {
        "skin": "#fde1c4", "skin_sh": "#e8b890",
        "hair": "#5d4037",
        "eye_w": "#ffffff", "eye": "#1b5e20", "eye_hi": "#ffffff",
        "tunic": "#43a047", "tunic_sh": "#2e7d32",
        "leather": "#8d6e63",
        "boot": "#3e2723",
        "bow": "#8d6e63",
        "line": "#1a1a2e"
    },
    "knight": {
        "skin": "#fde1c4", "skin_sh": "#e8b890",
        "hair": "#1a1a2e",
        "eye_w": "#ffffff", "eye": "#1565c0", "eye_hi": "#ffffff",
        "armor": "#e3f2fd", "armor_sh": "#90caf9",
        "gold": "#f1c40f", "red": "#e74c3c",
        "sword": "#e8e8f0", "hilt": "#8b4513",
        "boot": "#1565c0",
        "line": "#1a1a2e"
    },
    "slime": {
        "body": "#7ed957", "body_sh": "#388e3c",
        "eye_w": "#ffffff", "eye": "#1a1a2e",
        "line": "#1a1a2e"
    },
    "demon": {
        "skin": "#c62828", "skin_sh": "#8e1c1c",
        "horn": "#1a1a2e",
        "eye": "#ffff00",
        "claw": "#ff6b35",
        "line": "#000000"
    },
    "ghost": {
        "body": "#ffffff", "body_sh": "#b3e5fc",
        "eye": "#1a1a2e",
        "line": "#1a1a2e"
    },
    "skeleton": {
        "bone": "#fafafa", "bone_sh": "#9e9e9e",
        "eye": "#ff1744",
        "cloth": "#424242",
        "sword": "#e0e0e0", "hilt": "#8b4513",
        "line": "#000000"
    }
}

def L(pal, *keys, default=None):
    """安全取色"""
    for k in keys:
        if k in pal and pal[k]:
            return pal[k]
    return default or "#1a1a2e"

# ========= 鸟山明风格基础绘制 =========

def draw_thick_ellipse(d, x1, y1, x2, y2, fill, outline, lw=1):
    """画椭圆 + 1px细描边"""
    d.ellipse([x1, y1, x2, y2], fill=fill, outline=outline, width=lw)

def draw_thick_rect(d, x1, y1, x2, y2, fill, outline, lw=1):
    """画矩形 + 描边"""
    d.rectangle([x1, y1, x2, y2], fill=fill, outline=outline, width=lw)

def draw_thick_polygon(d, points, fill, outline, lw=1):
    """画多边形 + 描边"""
    d.polygon(points, fill=fill, outline=outline, width=lw)

# ========= 眼睛绘制 (鸟山明圆眼+双高光) =========
def draw_eyes(d, cx, cy, pal, dir='down'):
    """画鸟山明风格大眼睛
    cx,cy: 两眼中心位置 (两眼间距约8px)
    """
    eye_w = L(pal, "eye_w", default="#fff")
    eye_c = L(pal, "eye", default="#1a1a2e")
    eye_l = L(pal, "line", default="#1a1a2e")
    
    # 左眼
    lx, ly = cx - 4, cy
    rx, ry = cx + 4, cy
    
    if dir == 'left':
        # 朝左看
        draw_thick_ellipse(d, lx-2, ly-3, lx+3, ly+3, eye_w, eye_l, 1)
        draw_thick_ellipse(d, lx-1, ly-2, lx+1, ly+1, eye_c, None)
        draw_thick_ellipse(d, lx, ly-2, lx+1, ly-1, "#fff", None)
        
        draw_thick_ellipse(d, rx-2, ry-3, rx+3, ry+3, eye_w, eye_l, 1)
        draw_thick_ellipse(d, rx-1, ry-2, rx+1, ry+1, eye_c, None)
        draw_thick_ellipse(d, rx, ry-2, rx+1, ry-1, "#fff", None)
    elif dir == 'right':
        # 朝右看
        draw_thick_ellipse(d, lx-2, ly-3, lx+3, ly+3, eye_w, eye_l, 1)
        draw_thick_ellipse(d, lx+1, ly-2, lx+3, ly+1, eye_c, None)
        draw_thick_ellipse(d, lx+1, ly-2, lx+2, ly-1, "#fff", None)
        
        draw_thick_ellipse(d, rx-2, ry-3, rx+3, ry+3, eye_w, eye_l, 1)
        draw_thick_ellipse(d, rx+1, ry-2, rx+3, ry+1, eye_c, None)
        draw_thick_ellipse(d, rx+1, ry-2, rx+2, ry-1, "#fff", None)
    elif dir == 'up':
        # 后脑勺 - 不画眼
        pass
    else:
        # 正视 - 大瞳孔居中 + 双高光
        draw_thick_ellipse(d, lx-3, ly-4, lx+3, ly+4, eye_w, eye_l, 1)
        draw_thick_ellipse(d, lx-2, ly-3, lx+2, ly+3, eye_c, None)
        d.point([(lx-1, ly-2), (lx+1, ly-2)], fill="#fff")  # 双高光
        
        draw_thick_ellipse(d, rx-3, ry-4, rx+3, ry+4, eye_w, eye_l, 1)
        draw_thick_ellipse(d, rx-2, ry-3, rx+2, ry+3, eye_c, None)
        d.point([(rx-1, ry-2), (rx+1, ry-2)], fill="#fff")

def draw_mouth(d, cx, cy, pal, expr='smile'):
    """鸟山明风格嘴"""
    line = L(pal, "line")
    if expr == 'smile':
        # 微笑弧线
        d.arc([cx-3, cy-1, cx+3, cy+4], 0, 180, fill=line, width=1)
    elif expr == 'open':
        # 张嘴 (圆)
        d.ellipse([cx-2, cy-1, cx+2, cy+3], fill="#c44569", outline=line, width=1)
        d.point([(cx, cy)], fill="#fff")  # 舌头亮点
    elif expr == 'angry':
        # 倒v
        d.line([(cx-3, cy+2), (cx, cy-1), (cx+3, cy+2)], fill=line, width=1)
    elif expr == 'big_smile':
        # 大笑 (大圆)
        d.ellipse([cx-4, cy, cx+4, cy+5], fill="#c44569", outline=line, width=1)
        d.line([(cx-4, cy), (cx+4, cy)], fill="#fff", width=1)  # 上唇线

def draw_blush(d, cx, cy):
    """腮红"""
    d.ellipse([cx-7, cy, cx-3, cy+2], fill="#ff8fab", outline=None)
    d.ellipse([cx+3, cy, cx+7, cy+2], fill="#ff8fab", outline=None)

def draw_fury_mark(d, x, y, pal):
    """青筋标记 (愤怒)"""
    line = L(pal, "line")
    d.line([(x, y), (x-2, y-2)], fill=line, width=1)
    d.line([(x+1, y+1), (x-1, y+3)], fill=line, width=1)

# ========= 绘制角色主函数 =========

def draw_warrior_akira(d, frame, pal):
    """鸟山明铁血战士 - 2头身, 铠甲+大剑"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    skin = L(pal, "skin")
    skin_sh = L(pal, "skin_sh")
    armor = L(pal, "armor")
    armor_sh = L(pal, "armor_sh")
    gold = L(pal, "gold")
    red = L(pal, "red")
    sword = L(pal, "sword")
    hilt = L(pal, "hilt")
    boot = L(pal, "boot")
    
    step_off = [0, 1, 0, -1][step]
    
    if direction == 0:  # 下
        # 头 (大圆) - 2头身, 头大
        draw_thick_ellipse(d, 8, 1, 24, 18, skin, o, 1)
        # 头发 (短发)
        draw_thick_polygon(d, [(8, 8), (9, 2), (12, 0), (16, 1), (20, 0), (23, 2), (24, 8), (24, 10), (8, 10)], L(pal, "hair"), o, 1)
        # 眼睛 (正脸)
        draw_eyes(d, 16, 9, pal, 'down')
        # 嘴
        draw_mouth(d, 16, 14, pal, 'smile')
        # 耳朵
        d.ellipse([7, 7, 9, 12], fill=skin, outline=o, width=1)
        d.ellipse([23, 7, 25, 12], fill=skin, outline=o, width=1)
        
        # 脖子
        draw_thick_rect(d, 13, 18, 19, 21, skin_sh, o, 1)
        
        # 身体 (铠甲 上半部)
        draw_thick_ellipse(d, 7, 20, 25, 29, armor, o, 1)
        # 胸甲装饰 (鸟山明常用的V或菱形)
        draw_thick_polygon(d, [(16, 21), (12, 26), (16, 30), (20, 26)], gold, o, 1)
        draw_thick_polygon(d, [(14, 24), (16, 27), (18, 24), (16, 22)], red, o, 0)  # 红宝石
        # 铠甲下半 (腰)
        draw_thick_rect(d, 9, 28, 23, 31, armor_sh, o, 1)
        
        # 手臂 (细长椭圆)
        draw_thick_ellipse(d, 4, 22, 9, 29, armor, o, 1)  # 左
        draw_thick_ellipse(d, 23, 22, 28, 29, armor, o, 1)  # 右
        # 护手
        d.ellipse([4, 29, 9, 32], fill=armor_sh, outline=o, width=1)
        d.ellipse([23, 29, 28, 32], fill=armor_sh, outline=o, width=1)
        
        # 腿
        draw_thick_ellipse(d, 9, 30-step_off, 14, 35, armor, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 23, 35, armor, o, 1)
        # 靴子 (脚)
        d.ellipse([8, 34-step_off, 15, 37-step_off], fill=boot, outline=o, width=1)
        d.ellipse([17, 34+step_off, 24, 37+step_off], fill=boot, outline=o, width=1)
        
        # 大剑 (右手)
        d.rectangle([27, 0, 28, 18], fill=sword, outline=o, width=1)  # 剑刃
        d.rectangle([25, 18, 30, 19], fill=gold, outline=o, width=1)    # 护手
        d.rectangle([27, 19, 28, 24], fill=hilt, outline=o, width=1)    # 剑柄
        
    elif direction == 1:  # 左
        step_off = [-1, 0, 1, 0][step]
        draw_thick_ellipse(d, 9, 1, 25, 18, skin, o, 1)
        draw_thick_polygon(d, [(9, 8), (10, 2), (14, 0), (18, 1), (22, 0), (24, 2), (25, 8), (25, 10), (9, 10)], L(pal, "hair"), o, 1)
        # 眼睛朝左 (单眼可见)
        draw_thick_ellipse(d, 11, 7, 16, 12, L(pal, "eye_w"), o, 1)
        draw_thick_ellipse(d, 13, 8, 15, 11, L(pal, "eye"), None)
        d.point([(14, 8), (13, 9)], fill="#fff")
        draw_mouth(d, 14, 15, pal, 'smile')
        # 耳朵
        d.ellipse([24, 7, 26, 12], fill=skin, outline=o, width=1)
        
        draw_thick_ellipse(d, 8, 20, 24, 29, armor, o, 1)
        draw_thick_polygon(d, [(16, 21), (13, 26), (16, 30), (19, 26)], gold, o, 1)
        draw_thick_rect(d, 10, 28, 22, 31, armor_sh, o, 1)
        
        # 手臂 (前面朝左)
        draw_thick_ellipse(d, 2, 22, 8, 31, skin, o, 1)  # 左前
        draw_thick_ellipse(d, 24, 23, 28, 30, armor, o, 1)  # 右后
        
        # 腿
        draw_thick_ellipse(d, 10, 30+step_off, 15, 35, armor, o, 1)
        draw_thick_ellipse(d, 17, 30-step_off, 22, 35, armor, o, 1)
        d.ellipse([9, 34+step_off, 16, 37+step_off], fill=boot, outline=o, width=1)
        d.ellipse([16, 34-step_off, 23, 37-step_off], fill=boot, outline=o, width=1)
        
        # 剑朝左伸
        d.rectangle([-1, 23, 1, 28], fill=sword, outline=o, width=1)  # 剑刃伸出去
        d.rectangle([1, 24, 5, 26], fill=gold, outline=o, width=1)
        
    elif direction == 2:  # 右 (镜像左)
        step_off = [-1, 0, 1, 0][step]
        draw_thick_ellipse(d, 7, 1, 23, 18, skin, o, 1)
        draw_thick_polygon(d, [(7, 8), (8, 2), (12, 0), (16, 1), (20, 0), (22, 2), (23, 8), (23, 10), (7, 10)], L(pal, "hair"), o, 1)
        draw_thick_ellipse(d, 16, 7, 21, 12, L(pal, "eye_w"), o, 1)
        draw_thick_ellipse(d, 17, 8, 19, 11, L(pal, "eye"), None)
        d.point([(18, 8), (19, 9)], fill="#fff")
        draw_mouth(d, 18, 15, pal, 'smile')
        d.ellipse([6, 7, 8, 12], fill=skin, outline=o, width=1)
        
        draw_thick_ellipse(d, 8, 20, 24, 29, armor, o, 1)
        draw_thick_polygon(d, [(16, 21), (13, 26), (16, 30), (19, 26)], gold, o, 1)
        draw_thick_rect(d, 10, 28, 22, 31, armor_sh, o, 1)
        
        draw_thick_ellipse(d, 24, 22, 30, 31, skin, o, 1)  # 右前
        draw_thick_ellipse(d, 4, 23, 8, 30, armor, o, 1)   # 左后
        
        draw_thick_ellipse(d, 10, 30-step_off, 15, 35, armor, o, 1)
        draw_thick_ellipse(d, 17, 30+step_off, 22, 35, armor, o, 1)
        d.ellipse([9, 34-step_off, 16, 37-step_off], fill=boot, outline=o, width=1)
        d.ellipse([16, 34+step_off, 23, 37+step_off], fill=boot, outline=o, width=1)
        
        # 剑朝右伸
        d.rectangle([32, 23, 34, 28], fill=sword, outline=o, width=1)
        d.rectangle([28, 24, 32, 26], fill=gold, outline=o, width=1)
        
    else:  # 上 (后脑勺)
        step_off = [0, 1, 0, -1][step]
        draw_thick_ellipse(d, 8, 1, 24, 18, skin, o, 1)
        # 后脑勺头发 (蓬松)
        draw_thick_polygon(d, [(8, 8), (9, 1), (12, -1), (16, 0), (20, -1), (23, 1), (24, 8), (24, 16), (20, 18), (16, 17), (12, 18), (8, 16)], L(pal, "hair"), o, 1)
        
        draw_thick_ellipse(d, 8, 20, 24, 29, armor, o, 1)
        draw_thick_rect(d, 9, 28, 23, 31, armor_sh, o, 1)
        
        draw_thick_ellipse(d, 4, 22, 9, 29, armor, o, 1)
        draw_thick_ellipse(d, 23, 22, 28, 29, armor, o, 1)
        
        draw_thick_ellipse(d, 9, 30-step_off, 14, 35, armor, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 23, 35, armor, o, 1)
        d.ellipse([8, 34-step_off, 15, 37-step_off], fill=boot, outline=o, width=1)
        d.ellipse([17, 34+step_off, 24, 37+step_off], fill=boot, outline=o, width=1)


def draw_mage_akira(d, frame, pal):
    """鸟山明法师 - 尖帽+长袍+法杖"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    skin = L(pal, "skin")
    skin_sh = L(pal, "skin_sh")
    robe = L(pal, "robe")
    robe_sh = L(pal, "robe_sh")
    gold = L(pal, "gold")
    staff = L(pal, "staff")
    crystal = L(pal, "crystal")
    boot = L(pal, "boot")
    hair = L(pal, "hair")
    
    step_off = [0, 1, 0, -1][step]
    
    if direction == 0:
        # 尖顶法师帽 (超大)
        draw_thick_polygon(d, [(7, 16), (16, -8), (25, 16)], robe, o, 1)
        draw_thick_polygon(d, [(9, 12), (16, 0), (23, 12)], robe_sh, None)
        # 帽子边
        draw_thick_rect(d, 6, 14, 26, 17, gold, o, 1)
        # 帽尖装饰球
        d.ellipse([14, -9, 18, -5], fill=gold, outline=o, width=1)
        d.ellipse([15, -10, 17, -8], fill="#fff", outline=None)
        
        # 脸
        draw_thick_ellipse(d, 9, 12, 23, 23, skin, o, 1)
        draw_eyes(d, 16, 17, pal, 'down')
        draw_mouth(d, 16, 22, pal, 'smile')
        d.ellipse([8, 16, 10, 20], fill=skin, outline=o, width=1)
        d.ellipse([22, 16, 24, 20], fill=skin, outline=o, width=1)
        # 头发从帽檐露出
        draw_thick_polygon(d, [(9, 15), (10, 12), (16, 11), (22, 12), (23, 15), (23, 17), (9, 17)], hair, o, 1)
        
        # 身体 (长袍钟形)
        draw_thick_polygon(d, [(8, 23), (6, 36), (26, 36), (24, 23), (16, 22)], robe, o, 1)
        draw_thick_polygon(d, [(8, 24), (6, 36), (26, 36), (24, 24)], robe_sh, None)
        # 腰带
        draw_thick_rect(d, 10, 28, 22, 30, gold, o, 1)
        # 领口
        d.ellipse([13, 22, 19, 25], fill=skin_sh, outline=o, width=1)
        
        # 脚 (露出)
        d.ellipse([10, 35-step_off, 15, 38-step_off], fill=boot, outline=o, width=1)
        d.ellipse([17, 35+step_off, 22, 38+step_off], fill=boot, outline=o, width=1)
        
        # 法杖 (右手)
        d.rectangle([27, 10, 29, 36], fill=staff, outline=o, width=1)
        # 水晶球
        draw_thick_ellipse(d, 24, 3, 32, 11, crystal, o, 1)
        d.ellipse([25, 4, 27, 6], fill="#ffffff", outline=None)  # 高光
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_polygon(d, [(8, 16), (16, -8), (24, 16)], robe, o, 1)
        draw_thick_polygon(d, [(10, 12), (16, 0), (22, 12)], robe_sh, None)
        draw_thick_rect(d, 7, 14, 25, 17, gold, o, 1)
        d.ellipse([14, -9, 18, -5], fill=gold, outline=o, width=1)
        
        draw_thick_ellipse(d, 10, 12, 24, 23, skin, o, 1)
        draw_thick_ellipse(d, 11, 16, 16, 21, L(pal, "eye_w"), o, 1)
        draw_thick_ellipse(d, 13, 17, 15, 20, L(pal, "eye"), None)
        d.point([(14, 17), (13, 18)], fill="#fff")
        draw_mouth(d, 14, 22, pal, 'smile')
        
        draw_thick_polygon(d, [(9, 23), (7, 36), (25, 36), (23, 23), (16, 22)], robe, o, 1)
        draw_thick_rect(d, 11, 28, 21, 30, gold, o, 1)
        
        d.ellipse([11, 35+step_off, 16, 38+step_off], fill=boot, outline=o, width=1)
        d.ellipse([16, 35-step_off, 21, 38-step_off], fill=boot, outline=o, width=1)
        
        # 法杖朝左前
        d.rectangle([-1, 20, 1, 35], fill=staff, outline=o, width=1)
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_polygon(d, [(8, 16), (16, -8), (24, 16)], robe, o, 1)
        draw_thick_rect(d, 7, 14, 25, 17, gold, o, 1)
        d.ellipse([14, -9, 18, -5], fill=gold, outline=o, width=1)
        
        draw_thick_ellipse(d, 8, 12, 22, 23, skin, o, 1)
        draw_thick_ellipse(d, 16, 16, 21, 21, L(pal, "eye_w"), o, 1)
        draw_thick_ellipse(d, 17, 17, 19, 20, L(pal, "eye"), None)
        d.point([(18, 17), (19, 18)], fill="#fff")
        draw_mouth(d, 18, 22, pal, 'smile')
        
        draw_thick_polygon(d, [(9, 23), (7, 36), (25, 36), (23, 23), (16, 22)], robe, o, 1)
        draw_thick_rect(d, 11, 28, 21, 30, gold, o, 1)
        
        d.ellipse([11, 35-step_off, 16, 38-step_off], fill=boot, outline=o, width=1)
        d.ellipse([16, 35+step_off, 21, 38+step_off], fill=boot, outline=o, width=1)
        
        d.rectangle([32, 10, 34, 35], fill=staff, outline=o, width=1)
        draw_thick_ellipse(d, 30, 3, 36, 11, crystal, o, 1)
        
    else:
        step_off = [0, 1, 0, -1][step]
        draw_thick_polygon(d, [(8, 16), (16, -8), (24, 16)], robe, o, 1)
        draw_thick_rect(d, 7, 14, 25, 17, gold, o, 1)
        d.ellipse([14, -9, 18, -5], fill=gold, outline=o, width=1)
        
        draw_thick_ellipse(d, 9, 12, 23, 23, skin, o, 1)
        # 后脑勺头发
        draw_thick_polygon(d, [(9, 16), (8, 18), (8, 23), (16, 24), (24, 23), (24, 18), (23, 16), (16, 15)], hair, o, 1)
        
        draw_thick_polygon(d, [(8, 23), (6, 36), (26, 36), (24, 23), (16, 22)], robe, o, 1)
        draw_thick_rect(d, 10, 28, 22, 30, gold, o, 1)
        
        d.ellipse([10, 35-step_off, 15, 38-step_off], fill=boot, outline=o, width=1)
        d.ellipse([17, 35+step_off, 22, 38+step_off], fill=boot, outline=o, width=1)
        
        d.rectangle([27, 10, 29, 36], fill=staff, outline=o, width=1)
        draw_thick_ellipse(d, 24, 3, 32, 11, crystal, o, 1)


def draw_archer_akira(d, frame, pal):
    """鸟山明游侠 - 绿色+马尾+弓"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    skin = L(pal, "skin")
    skin_sh = L(pal, "skin_sh")
    tunic = L(pal, "tunic")
    tunic_sh = L(pal, "tunic_sh")
    leather = L(pal, "leather")
    boot = L(pal, "boot")
    bow = L(pal, "bow")
    hair = L(pal, "hair")
    
    step_off = [0, 1, 0, -1][step]
    
    if direction == 0:
        # 头
        draw_thick_ellipse(d, 8, 1, 24, 18, skin, o, 1)
        # 刘海
        draw_thick_polygon(d, [(8, 10), (9, 4), (12, 1), (16, 2), (20, 1), (23, 4), (24, 10), (22, 12), (16, 10), (10, 12)], hair, o, 1)
        # 马尾 (背后)
        draw_thick_polygon(d, [(22, 8), (28, 12), (29, 20), (27, 24), (25, 20), (22, 14)], hair, o, 1)
        draw_eyes(d, 16, 9, pal, 'down')
        draw_mouth(d, 16, 14, pal, 'big_smile')  # 开朗大笑
        draw_blush(d, 16, 16)
        d.ellipse([7, 7, 9, 12], fill=skin, outline=o, width=1)
        d.ellipse([23, 7, 25, 12], fill=skin, outline=o, width=1)
        
        draw_thick_ellipse(d, 13, 18, 19, 21, skin_sh, o, 1)
        
        # 身体 (短袍)
        draw_thick_ellipse(d, 8, 20, 24, 29, tunic, o, 1)
        draw_thick_ellipse(d, 9, 27, 23, 31, tunic_sh, o, 1)
        # 腰带
        draw_thick_rect(d, 10, 28, 22, 30, leather, o, 1)
        
        # 手臂 (露臂游侠风)
        draw_thick_ellipse(d, 4, 22, 9, 30, skin, o, 1)
        draw_thick_ellipse(d, 23, 22, 28, 30, skin, o, 1)
        
        # 腿
        draw_thick_ellipse(d, 9, 30-step_off, 14, 35, leather, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 23, 35, leather, o, 1)
        d.ellipse([8, 34-step_off, 15, 37-step_off], fill=boot, outline=o, width=1)
        d.ellipse([17, 34+step_off, 24, 37+step_off], fill=boot, outline=o, width=1)
        
        # 弓 (背后可见一小段)
        d.arc([25, 18, 31, 26], 0, 180, fill=bow, width=2)
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_ellipse(d, 9, 1, 25, 18, skin, o, 1)
        draw_thick_polygon(d, [(9, 10), (10, 4), (14, 1), (18, 2), (22, 1), (24, 4), (25, 10), (23, 12), (16, 10), (10, 12)], hair, o, 1)
        draw_thick_polygon(d, [(24, 10), (28, 14), (28, 20), (26, 22)], hair, o, 1)
        draw_thick_ellipse(d, 11, 7, 16, 12, L(pal, "eye_w"), o, 1)
        draw_thick_ellipse(d, 13, 8, 15, 11, L(pal, "eye"), None)
        d.point([(14, 8), (13, 9)], fill="#fff")
        draw_mouth(d, 14, 15, pal, 'big_smile')
        draw_blush(d, 14, 16)
        d.ellipse([24, 7, 26, 12], fill=skin, outline=o, width=1)
        
        draw_thick_ellipse(d, 8, 20, 24, 29, tunic, o, 1)
        draw_thick_rect(d, 10, 28, 22, 30, leather, o, 1)
        
        draw_thick_ellipse(d, 2, 22, 8, 31, skin, o, 1)  # 前手 (握弓)
        draw_thick_ellipse(d, 24, 23, 28, 30, skin, o, 1)
        
        draw_thick_ellipse(d, 10, 30+step_off, 15, 35, leather, o, 1)
        draw_thick_ellipse(d, 17, 30-step_off, 22, 35, leather, o, 1)
        d.ellipse([9, 34+step_off, 16, 37+step_off], fill=boot, outline=o, width=1)
        d.ellipse([16, 34-step_off, 23, 37-step_off], fill=boot, outline=o, width=1)
        
        # 弓朝前
        d.arc([-2, 18, 6, 26], 0, 180, fill=bow, width=2)
        d.line([(2, 18), (2, 26)], fill="#ccc", width=1)
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_ellipse(d, 7, 1, 23, 18, skin, o, 1)
        draw_thick_polygon(d, [(7, 10), (8, 4), (12, 1), (16, 2), (20, 1), (22, 4), (23, 10), (21, 12), (16, 10), (10, 12)], hair, o, 1)
        draw_thick_polygon(d, [(23, 10), (27, 14), (27, 20), (25, 22)], hair, o, 1)
        draw_thick_ellipse(d, 16, 7, 21, 12, L(pal, "eye_w"), o, 1)
        draw_thick_ellipse(d, 17, 8, 19, 11, L(pal, "eye"), None)
        d.point([(18, 8), (19, 9)], fill="#fff")
        draw_mouth(d, 18, 15, pal, 'big_smile')
        draw_blush(d, 18, 16)
        
        draw_thick_ellipse(d, 8, 20, 24, 29, tunic, o, 1)
        draw_thick_rect(d, 10, 28, 22, 30, leather, o, 1)
        
        draw_thick_ellipse(d, 24, 22, 30, 31, skin, o, 1)
        draw_thick_ellipse(d, 4, 23, 8, 30, skin, o, 1)
        
        draw_thick_ellipse(d, 10, 30-step_off, 15, 35, leather, o, 1)
        draw_thick_ellipse(d, 17, 30+step_off, 22, 35, leather, o, 1)
        d.ellipse([9, 34-step_off, 16, 37-step_off], fill=boot, outline=o, width=1)
        d.ellipse([16, 34+step_off, 23, 37+step_off], fill=boot, outline=o, width=1)
        
        d.arc([26, 18, 34, 26], 0, 180, fill=bow, width=2)
        d.line([(30, 18), (30, 26)], fill="#ccc", width=1)
        
    else:
        step_off = [0, 1, 0, -1][step]
        draw_thick_ellipse(d, 8, 1, 24, 18, skin, o, 1)
        # 后脑勺头发 + 马尾
        draw_thick_polygon(d, [(8, 10), (8, 16), (16, 18), (24, 16), (24, 10), (22, 18), (16, 19), (10, 18)], hair, o, 1)
        draw_thick_polygon(d, [(24, 14), (28, 18), (28, 26), (26, 28), (25, 22)], hair, o, 1)
        
        draw_thick_ellipse(d, 8, 20, 24, 29, tunic, o, 1)
        draw_thick_rect(d, 10, 28, 22, 30, leather, o, 1)
        
        draw_thick_ellipse(d, 4, 22, 9, 30, skin, o, 1)
        draw_thick_ellipse(d, 23, 22, 28, 30, skin, o, 1)
        
        draw_thick_ellipse(d, 9, 30-step_off, 14, 35, leather, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 23, 35, leather, o, 1)
        d.ellipse([8, 34-step_off, 15, 37-step_off], fill=boot, outline=o, width=1)
        d.ellipse([17, 34+step_off, 24, 37+step_off], fill=boot, outline=o, width=1)


def draw_slime_akira(d, frame, pal):
    """鸟山明史莱姆 - Q弹圆滚滚"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    body = L(pal, "body")
    body_sh = L(pal, "body_sh")
    
    # 弹跳挤压
    squish = step  # 0,1,2,3 -> 正常,压扁,正常,压扁
    height_off = [0, 2, 0, -1][step]
    
    # 身体 (圆/椭圆)
    bx1, by1 = 6, 12 + height_off
    bx2, by2 = 26, 32 + height_off
    rx = (bx2 - bx1) // 2
    ry = (by2 - by1) // 2
    
    draw_thick_ellipse(d, bx1, by1, bx2, by2, body, o, 1)
    # 底部阴影 (半椭圆)
    d.ellipse([bx1+2, by1+ry-2, bx2-2, by2+ry-1], fill=body_sh, outline=None)
    # 高光
    hi_img = Image.new('RGBA', (FRAME, FRAME), (0,0,0,0))
    hi_d = ImageDraw.Draw(hi_img)
    hi_d.ellipse([bx1+4, by1+4, bx1+9, by1+ry//2], fill=(255,255,255,180))
    frame_img.alpha_composite(hi_img)
    
    # 眼睛 (大眼)
    eye_cx = 13
    if direction == 1: eye_cx = 11
    if direction == 2: eye_cx = 15
    
    draw_thick_ellipse(d, eye_cx-2, 18+height_off, eye_cx+3, 23+height_off, "#fff", o, 1)
    draw_thick_ellipse(d, eye_cx-1, 19+height_off, eye_cx+1, 22+height_off, L(pal, "eye"), None)
    d.point([(eye_cx, 19+height_off), (eye_cx+1, 20+height_off)], fill="#fff")
    
    eye_cx2 = 19 if direction == 0 else 17 if direction == 1 else 21
    draw_thick_ellipse(d, eye_cx2-2, 18+height_off, eye_cx2+3, 23+height_off, "#fff", o, 1)
    draw_thick_ellipse(d, eye_cx2-1, 19+height_off, eye_cx2+1, 22+height_off, L(pal, "eye"), None)
    d.point([(eye_cx2, 19+height_off), (eye_cx2+1, 20+height_off)], fill="#fff")
    
    # 微笑嘴
    if direction != 3:  # 不是后脑勺
        d.arc([13, 24+height_off, 19, 29+height_off], 0, 180, fill=o, width=1)


def draw_demon_akira(d, frame, pal):
    """鸟山明恶魔 - 犄角+红皮+尖牙"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    skin = L(pal, "skin")
    skin_sh = L(pal, "skin_sh")
    horn = L(pal, "horn")
    eye = L(pal, "eye")
    claw = L(pal, "claw")
    
    step_off = [0, 1, 0, -1][step]
    
    if direction == 0:
        # 犄角 (头上双尖角)
        draw_thick_polygon(d, [(9, 8), (6, -2), (11, 6)], horn, o, 1)
        draw_thick_polygon(d, [(23, 8), (26, -2), (21, 6)], horn, o, 1)
        
        # 头 (略尖)
        draw_thick_polygon(d, [(8, 8), (7, 14), (9, 20), (16, 23), (23, 20), (25, 14), (24, 8)], skin, o, 1)
        
        # 眼睛 (竖瞳 黄)
        draw_thick_ellipse(d, 10, 11, 14, 16, "#fff", o, 1)
        d.ellipse([12, 11, 13, 16], fill=eye, outline=None)  # 竖瞳
        d.point([(12, 12), (13, 13)], fill="#fff")
        
        draw_thick_ellipse(d, 18, 11, 22, 16, "#fff", o, 1)
        d.ellipse([19, 11, 20, 16], fill=eye, outline=None)
        d.point([(19, 12), (20, 13)], fill="#fff")
        
        # 獠牙嘴
        draw_thick_polygon(d, [(10, 17), (16, 22), (22, 17), (22, 19), (18, 21), (16, 22), (14, 21), (10, 19)], "#1a1a1a", o, 1)
        d.polygon([(13, 17), (14, 21), (15, 17)], fill="#fff", outline=o)  # 左獠牙
        d.polygon([(17, 17), (18, 21), (19, 17)], fill="#fff", outline=o)  # 右獠牙
        
        # 身体 (肌肉)
        draw_thick_ellipse(d, 6, 22, 26, 32, skin, o, 1)
        draw_thick_ellipse(d, 10, 25, 22, 30, skin_sh, None)  # 腹部阴影
        
        # 手臂 (粗)
        draw_thick_ellipse(d, 2, 23, 8, 32, skin, o, 1)
        draw_thick_ellipse(d, 24, 23, 30, 32, skin, o, 1)
        # 爪子
        d.line([(4, 32), (2, 36)], fill=o, width=1)
        d.line([(6, 32), (5, 37)], fill=o, width=1)
        d.line([(8, 32), (10, 36)], fill=o, width=1)
        d.line([(26, 32), (24, 36)], fill=o, width=1)
        d.line([(28, 32), (27, 37)], fill=o, width=1)
        d.line([(30, 32), (32, 36)], fill=o, width=1)
        
        # 腿
        draw_thick_ellipse(d, 9, 31-step_off, 14, 36, skin, o, 1)
        draw_thick_ellipse(d, 18, 31+step_off, 23, 36, skin, o, 1)
        d.line([(8, 36), (6, 38)], fill=o, width=1)
        d.line([(10, 36), (11, 38)], fill=o, width=1)
        d.line([(21, 36), (22, 38)], fill=o, width=1)
        d.line([(24, 36), (26, 38)], fill=o, width=1)
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_polygon(d, [(10, 8), (7, -2), (12, 6)], horn, o, 1)
        draw_thick_polygon(d, [(23, 8), (26, -2), (21, 6)], horn, o, 1)
        draw_thick_polygon(d, [(9, 8), (8, 14), (10, 20), (16, 23), (22, 20), (24, 14), (23, 8)], skin, o, 1)
        draw_thick_ellipse(d, 11, 11, 15, 16, "#fff", o, 1)
        d.ellipse([13, 11, 14, 16], fill=eye, outline=None)
        draw_thick_polygon(d, [(11, 17), (14, 21), (17, 17), (17, 19), (14, 20), (11, 19)], "#1a1a1a", o, 1)
        
        draw_thick_ellipse(d, 6, 22, 26, 32, skin, o, 1)
        draw_thick_ellipse(d, 1, 23, 9, 32, skin, o, 1)  # 前臂
        d.line([(3, 32), (1, 36)], fill=o, width=1)
        d.line([(5, 32), (4, 37)], fill=o, width=1)
        
        draw_thick_ellipse(d, 8, 31+step_off, 13, 36, skin, o, 1)
        draw_thick_ellipse(d, 18, 31-step_off, 23, 36, skin, o, 1)
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_polygon(d, [(9, 8), (6, -2), (11, 6)], horn, o, 1)
        draw_thick_polygon(d, [(22, 8), (25, -2), (20, 6)], horn, o, 1)
        draw_thick_polygon(d, [(8, 8), (7, 14), (9, 20), (16, 23), (23, 20), (25, 14), (24, 8)], skin, o, 1)
        draw_thick_ellipse(d, 17, 11, 21, 16, "#fff", o, 1)
        d.ellipse([18, 11, 19, 16], fill=eye, outline=None)
        draw_thick_polygon(d, [(15, 17), (18, 21), (21, 17), (21, 19), (18, 20), (15, 19)], "#1a1a1a", o, 1)
        
        draw_thick_ellipse(d, 6, 22, 26, 32, skin, o, 1)
        draw_thick_ellipse(d, 23, 23, 31, 32, skin, o, 1)
        d.line([(25, 32), (23, 36)], fill=o, width=1)
        d.line([(27, 32), (26, 37)], fill=o, width=1)
        
        draw_thick_ellipse(d, 8, 31-step_off, 13, 36, skin, o, 1)
        draw_thick_ellipse(d, 18, 31+step_off, 23, 36, skin, o, 1)
        
    else:
        step_off = [0, 1, 0, -1][step]
        draw_thick_polygon(d, [(9, 8), (6, -2), (11, 6)], horn, o, 1)
        draw_thick_polygon(d, [(23, 8), (26, -2), (21, 6)], horn, o, 1)
        draw_thick_polygon(d, [(8, 8), (7, 14), (9, 22), (16, 24), (23, 22), (25, 14), (24, 8)], skin, o, 1)
        
        draw_thick_ellipse(d, 6, 22, 26, 32, skin, o, 1)
        draw_thick_ellipse(d, 2, 23, 8, 32, skin, o, 1)
        draw_thick_ellipse(d, 24, 23, 30, 32, skin, o, 1)
        
        draw_thick_ellipse(d, 9, 31-step_off, 14, 36, skin, o, 1)
        draw_thick_ellipse(d, 18, 31+step_off, 23, 36, skin, o, 1)


def draw_ghost_akira(d, frame, pal):
    """鸟山明幽灵 - 飘浮+空洞"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    body = L(pal, "body")
    
    float_y = [0, -1, 0, 1][step]
    
    # 钟形身体
    draw_thick_ellipse(d, 6, 10+float_y, 26, 30+float_y, body, o, 1)
    # 波浪下摆
    for i in range(4):
        d.ellipse([6+i*5, 28+float_y, 11+i*5, 32+float_y], fill=body, outline=o, width=1)
    
    # 眼睛 (空洞+黑色描边)
    if direction != 3:
        d.ellipse([11, 15+float_y, 14, 20+float_y], fill=o, outline=o)
        d.ellipse([18, 15+float_y, 21, 20+float_y], fill=o, outline=o)
        # 小白点反光
        d.point([(12, 16+float_y), (19, 16+float_y)], fill="#fff")
    
    # 小嘴 (圆O)
    if direction != 3:
        d.ellipse([15, 22+float_y, 17, 25+float_y], fill=o, outline=o)


def draw_skeleton_akira(d, frame, pal):
    """鸟山明骷髅 - 骨头+红眼"""
    direction = frame // 4
    step = frame % 4
    o = L(pal, "line")
    bone = L(pal, "bone")
    bone_sh = L(pal, "bone_sh")
    cloth = L(pal, "cloth")
    eye = L(pal, "eye")
    sword = L(pal, "sword")
    hilt = L(pal, "hilt")
    
    step_off = [0, 1, 0, -1][step]
    
    if direction == 0:
        # 头骨
        draw_thick_ellipse(d, 8, 1, 24, 18, bone, o, 1)
        # 头骨顶部阴影
        d.ellipse([9, 1, 23, 5], fill=bone_sh, outline=None)
        # 眼眶 (黑洞)
        d.ellipse([11, 6, 15, 11], fill=o, outline=o)
        d.ellipse([17, 6, 21, 11], fill=o, outline=o)
        # 红眼发光
        d.ellipse([12, 8, 14, 10], fill=eye, outline=None)
        d.ellipse([18, 8, 20, 10], fill=eye, outline=None)
        d.point([(13, 8), (19, 8)], fill="#fff")
        # 牙齿
        for i in range(5):
            d.rectangle([12+i*2, 14, 13+i*2, 16], fill=bone, outline=o, width=1)
        # 空洞鼻子
        d.ellipse([15, 11, 17, 14], fill=o, outline=o)
        
        # 身体 (裹布)
        draw_thick_ellipse(d, 8, 20, 24, 30, cloth, o, 1)
        # 骨头透出
        d.line([(10, 22), (22, 22)], fill=bone, width=1)
        d.line([(11, 25), (21, 25)], fill=bone, width=1)
        d.line([(12, 28), (20, 28)], fill=bone, width=1)
        
        # 手臂 (骨头形状)
        draw_thick_ellipse(d, 4, 22, 8, 32, bone, o, 1)
        draw_thick_ellipse(d, 24, 22, 28, 32, bone, o, 1)
        
        # 腿
        draw_thick_ellipse(d, 10, 30-step_off, 14, 36, bone, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 22, 36, bone, o, 1)
        d.ellipse([8, 35-step_off, 15, 37-step_off], fill=bone, outline=o, width=1)
        d.ellipse([17, 35+step_off, 24, 37+step_off], fill=bone, outline=o, width=1)
        
        # 剑
        d.rectangle([27, 3, 28, 19], fill=sword, outline=o, width=1)
        d.rectangle([25, 19, 30, 20], fill="#f1c40f", outline=o, width=1)
        d.rectangle([27, 20, 28, 25], fill=hilt, outline=o, width=1)
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_ellipse(d, 9, 1, 25, 18, bone, o, 1)
        d.ellipse([12, 6, 16, 11], fill=o, outline=o)
        d.ellipse([13, 8, 15, 10], fill=eye, outline=None)
        for i in range(4):
            d.rectangle([11+i*2, 14, 12+i*2, 16], fill=bone, outline=o, width=1)
        
        draw_thick_ellipse(d, 8, 20, 24, 30, cloth, o, 1)
        draw_thick_ellipse(d, 2, 23, 8, 33, bone, o, 1)
        draw_thick_ellipse(d, 24, 23, 28, 32, bone, o, 1)
        
        draw_thick_ellipse(d, 10, 30+step_off, 14, 36, bone, o, 1)
        draw_thick_ellipse(d, 18, 30-step_off, 22, 36, bone, o, 1)
        d.ellipse([8, 35+step_off, 15, 37+step_off], fill=bone, outline=o, width=1)
        d.ellipse([17, 35-step_off, 24, 37-step_off], fill=bone, outline=o, width=1)
        
        d.rectangle([-1, 24, 1, 29], fill=sword, outline=o, width=1)
        d.rectangle([1, 25, 5, 27], fill="#f1c40f", outline=o, width=1)
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        draw_thick_ellipse(d, 7, 1, 23, 18, bone, o, 1)
        d.ellipse([16, 6, 20, 11], fill=o, outline=o)
        d.ellipse([17, 8, 19, 10], fill=eye, outline=None)
        for i in range(4):
            d.rectangle([10+i*2, 14, 11+i*2, 16], fill=bone, outline=o, width=1)
        
        draw_thick_ellipse(d, 8, 20, 24, 30, cloth, o, 1)
        draw_thick_ellipse(d, 24, 22, 30, 33, bone, o, 1)
        draw_thick_ellipse(d, 4, 23, 8, 32, bone, o, 1)
        
        draw_thick_ellipse(d, 10, 30-step_off, 14, 36, bone, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 22, 36, bone, o, 1)
        d.ellipse([8, 35-step_off, 15, 37-step_off], fill=bone, outline=o, width=1)
        d.ellipse([17, 35+step_off, 24, 37+step_off], fill=bone, outline=o, width=1)
        
        d.rectangle([31, 24, 33, 29], fill=sword, outline=o, width=1)
        d.rectangle([29, 25, 33, 27], fill="#f1c40f", outline=o, width=1)
        
    else:
        step_off = [0, 1, 0, -1][step]
        draw_thick_ellipse(d, 8, 1, 24, 18, bone, o, 1)
        
        draw_thick_ellipse(d, 8, 20, 24, 30, cloth, o, 1)
        draw_thick_ellipse(d, 4, 22, 8, 33, bone, o, 1)
        draw_thick_ellipse(d, 24, 22, 28, 33, bone, o, 1)
        
        draw_thick_ellipse(d, 10, 30-step_off, 14, 36, bone, o, 1)
        draw_thick_ellipse(d, 18, 30+step_off, 22, 36, bone, o, 1)
        d.ellipse([8, 35-step_off, 15, 37-step_off], fill=bone, outline=o, width=1)
        d.ellipse([17, 35+step_off, 24, 37+step_off], fill=bone, outline=o, width=1)
        
        d.rectangle([27, 3, 28, 19], fill=sword, outline=o, width=1)


# ========= 生成入口 =========

CHARACTERS = {
    "player_warrior": draw_warrior_akira,
    "player_mage": draw_mage_akira,
    "player_archer": draw_archer_akira,
    "player_knight": draw_warrior_akira,  # 复用战士 + 骑士配色
    "enemy_slime": draw_slime_akira,
    "enemy_demon": draw_demon_akira,
    "enemy_ghost": draw_ghost_akira,
    "enemy_skeleton": draw_skeleton_akira
}

CHAR_PALS = {
    "player_warrior": PAL["warrior"],
    "player_mage": PAL["mage"],
    "player_archer": PAL["archer"],
    "player_knight": PAL["knight"],
    "enemy_slime": PAL["slime"],
    "enemy_demon": PAL["demon"],
    "enemy_ghost": PAL["ghost"],
    "enemy_skeleton": PAL["skeleton"]
}

for name, draw_func in CHARACTERS.items():
    sheet = Image.new('RGBA', (SHEET, SHEET), (0, 0, 0, 0))
    pal = CHAR_PALS[name]
    
    for frame in range(16):
        col = frame % GRID
        row = frame // GRID
        
        frame_img = Image.new('RGBA', (FRAME, FRAME), (0, 0, 0, 0))
        d = ImageDraw.Draw(frame_img)
        
        draw_func(d, frame, pal)
        
        sheet.paste(frame_img, (col * FRAME, row * FRAME), frame_img)
    
    out_path = os.path.join(OUTPUT_DIR, f"{name}.png")
    sheet.save(out_path)
    print(f"✅ {name}.png")

print(f"\n鸟山明画风精灵已生成! → {OUTPUT_DIR}")
