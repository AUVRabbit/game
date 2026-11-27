#!/usr/bin/env python3
"""
像素风 Godot 精灵生成器 v3 - 真实质感版
核心修正:
1. 零黑描边 — 用 shadow 色块当轮廓
2. 3层同色系: highlight / base / shadow
3. rect 像素拼接 — 不是 ellipse
4. 精确像素控制 — 像素密度对齐原图 (~480-580 px/帧)
"""

from PIL import Image, ImageDraw
import os

FRAME = 32
GRID = 4
SHEET = FRAME * GRID  # 128

OUTPUT_DIR = "/workspace/通天入地/assets/sprites/world"

# ================ 色彩系统 — 每层3色 (hi/base/sh) ================
# shadow 色同时也是轮廓 (比 base 深 ~30%)
PAL = {
    "warrior": {
        "skin_hi": "#fce0c0", "skin": "#e8b890", "skin_sh": "#b88860",
        "hair_hi": "#3a3a5a", "hair": "#222240", "hair_sh": "#151528",
        "armor_hi": "#e8ecf4", "armor": "#c0c8d8", "armor_sh": "#6a728a",
        "red_hi": "#ff7060", "red": "#e04040", "red_sh": "#a02020",
        "gold_hi": "#ffe060", "gold": "#f0b820", "gold_sh": "#b08010",
        "steel_hi": "#f0f0f8", "steel": "#c8c8d0", "steel_sh": "#606070",
        "boot": "#3a3a55",
        "hilt": "#6a3a20",
    },
    "mage": {
        "skin_hi": "#fce0c0", "skin": "#e8b890", "skin_sh": "#b88860",
        "hair_hi": "#8c6ad0", "hair": "#6a4fa0", "hair_sh": "#3a2a6a",
        "robe_hi": "#7a3ac0", "robe": "#4a148c", "robe_sh": "#2a0a54",
        "gold_hi": "#ffe060", "gold": "#f0b820", "gold_sh": "#b08010",
        "crystal_hi": "#80f0ff", "crystal": "#00c8ff", "crystal_sh": "#006080",
        "staff": "#8b4513",
        "boot": "#4a3020",
    },
    "archer": {
        "skin_hi": "#fce0c0", "skin": "#e8b890", "skin_sh": "#b88860",
        "hair_hi": "#8c6a3f", "hair": "#5d4037", "hair_sh": "#3a2820",
        "tunic_hi": "#6ac070", "tunic": "#409050", "tunic_sh": "#205030",
        "leather_hi": "#a88850", "leather": "#7a5a3a", "leather_sh": "#4a3020",
        "bow": "#7a5a3a",
        "boot": "#302018",
    },
    "knight": {
        "skin_hi": "#fce0c0", "skin": "#e8b890", "skin_sh": "#b88860",
        "hair_hi": "#3a3a5a", "hair": "#222240", "hair_sh": "#151528",
        "armor_hi": "#f0f4ff", "armor": "#d8e0f4", "armor_sh": "#7a9ac0",
        "blue_hi": "#4080f0", "blue": "#2050c0", "blue_sh": "#103080",
        "gold_hi": "#ffe060", "gold": "#f0b820", "gold_sh": "#b08010",
        "steel_hi": "#f0f0f8", "steel": "#c8c8d0", "steel_sh": "#606070",
        "boot": "#2050c0",
    },
    "slime": {
        "body_hi": "#c8f070", "body": "#7ed957", "body_sh": "#308030",
    },
    "demon": {
        "skin_hi": "#e05050", "skin": "#c02020", "skin_sh": "#701010",
        "horn_hi": "#3a3a5a", "horn": "#222240", "horn_sh": "#151528",
        "eye_hi": "#ffff80", "eye": "#ffff00", "eye_sh": "#a0a000",
    },
    "ghost": {
        "body_hi": "#ffffff", "body": "#e8f4ff", "body_sh": "#90b0c0",
    },
    "skeleton": {
        "bone_hi": "#ffffff", "bone": "#e0e0d8", "bone_sh": "#808078",
        "eye": "#ff1744",
        "cloth": "#404050",
    }
}

def C(pal, key):
    """取色"""
    return pal.get(key, "#222240")

# ================ 基础绘制 (全部无描边!) ================
def r(d, x, y, w, h, color):
    d.rectangle([x, y, x+w-1, y+h-1], fill=color)

def p(d, x, y, color):
    d.point([(x, y)], fill=color)

def line(d, x1, y1, x2, y2, color, w=1):
    d.line([(x1, y1), (x2, y2)], fill=color, width=w)

def poly(d, pts, color):
    d.polygon(pts, fill=color)

# ================ 五官 (无描边, shadow 当轮廓) ================
def face_down(d, pal, cx, cy, expr="neutral"):
    """正视五官 — 像素级精准"""
    sk = C(pal, "skin"); sk_hi = C(pal, "skin_hi"); sk_sh = C(pal, "skin_sh")
    hc = C(pal, "hair_sh")
    
    # 眼睛 (眼白+瞳孔+高光) — 黑色用 hair_sh 色
    # 左眼: x=cx-5, 右眼: x=cx+5
    # 标准眼: 高3, 宽2
    for ex, ey in [(cx-5, cy), (cx+5, cy)]:
        # 眼白 (2x3)
        r(d, ex, ey, 2, 3, "#ffffff")
        # 瞳孔 (2x2) 居中
        r(d, ex, ey+1, 2, 2, hc)
        # 高光点 (白)
        p(d, ex, ey+1, "#ffffff")
        p(d, ex+1, ey+2, "#ffffff")
    
    # 嘴
    if expr == "neutral":
        line(d, cx-2, cy+6, cx+2, cy+6, sk_sh)
    elif expr == "smile":
        line(d, cx-3, cy+5, cx, cy+7, sk_sh)
        line(d, cx, cy+7, cx+3, cy+5, sk_sh)
    elif expr == "big":
        r(d, cx-2, cy+5, 4, 2, sk_sh)
    elif expr == "angry":
        line(d, cx-2, cy+7, cx, cy+5, sk_sh)
        line(d, cx, cy+5, cx+2, cy+7, sk_sh)

def face_left(d, pal, cx, cy):
    """侧视五官 (单眼可见)"""
    sk = C(pal, "skin"); hc = C(pal, "hair_sh")
    
    # 左眼朝左看
    r(d, cx-3, cy, 2, 3, "#ffffff")
    r(d, cx-3, cy+1, 2, 2, hc)
    p(d, cx-3, cy+1, "#ffffff")
    p(d, cx-2, cy+2, "#ffffff")
    # 鼻 (小点)
    p(d, cx-6, cy+2, sk)
    # 嘴 (短)
    line(d, cx-5, cy+6, cx-3, cy+6, C(pal, "skin_sh"))

# ================ 角色绘制 ================

def _walk_offsets(step, dir_idx):
    """行走偏移 — 腿前后摆动, 手臂相对摆动"""
    leg = [0, 1, 0, -1][step]
    arm = [0, -1, 0, 1][step]
    if dir_idx in [1, 2]:  # 左右方向, 手臂主要在前
        arm = [-1, 0, 1, 0][step]
    return leg, arm

def draw_warrior(d, frame, pal):
    """铁血战士 — 铠甲+大剑, 比例正常 (不是大头)"""
    dir_idx = frame // 4
    step = frame % 4
    sk = C(pal, "skin"); sk_hi = C(pal, "skin_hi"); sk_sh = C(pal, "skin_sh")
    hr = C(pal, "hair"); hr_hi = C(pal, "hair_hi"); hr_sh = C(pal, "hair_sh")
    ar = C(pal, "armor"); ar_hi = C(pal, "armor_hi"); ar_sh = C(pal, "armor_sh")
    rd = C(pal, "red"); rd_hi = C(pal, "red_hi"); rd_sh = C(pal, "red_sh")
    gd = C(pal, "gold"); gd_hi = C(pal, "gold_hi"); gd_sh = C(pal, "gold_sh")
    st = C(pal, "steel"); st_hi = C(pal, "steel_hi"); st_sh = C(pal, "steel_sh")
    bt = C(pal, "boot")
    hi = C(pal, "hilt")
    
    leg_off, arm_off = _walk_offsets(step, dir_idx)
    
    if dir_idx == 0:  # 下
        # 头发 (顶 + 两侧)
        r(d, 10, 2, 12, 3, hr)      # 顶
        r(d, 9, 5, 2, 3, hr)        # 左耳前
        r(d, 21, 5, 2, 3, hr)       # 右耳前
        # 头发高光
        r(d, 11, 2, 3, 1, hr_hi)
        r(d, 16, 2, 3, 1, hr_hi)
        
        # 脸 (14x13, 中心y=8)
        r(d, 10, 5, 12, 11, sk)
        # 脸阴影 (下巴)
        r(d, 10, 15, 12, 1, sk_sh)
        # 脸高光
        r(d, 11, 6, 3, 1, sk_hi)
        # 眼鼻口
        face_down(d, pal, 16, 9, "neutral")
        # 耳朵
        r(d, 9, 10, 1, 3, sk)
        r(d, 22, 10, 1, 3, sk)
        
        # 颈
        r(d, 14, 16, 4, 2, sk_sh)
        
        # 胸甲 (14x10)
        r(d, 9, 18, 14, 8, ar)
        # 胸甲阴影 (右下)
        r(d, 21, 19, 2, 7, ar_sh)
        r(d, 9, 25, 14, 1, ar_sh)
        # 胸甲高光 (左上)
        r(d, 10, 19, 3, 1, ar_hi)
        r(d, 10, 20, 1, 2, ar_hi)
        # V型金色装饰 (正中心)
        poly(d, [(16, 19), (13, 24), (16, 27), (19, 24)], gd)
        # 红宝石
        p(d, 16, 23, rd)
        p(d, 15, 22, rd_hi)
        
        # 腰带
        r(d, 9, 26, 14, 2, gd_sh)
        r(d, 15, 26, 2, 2, gd)  # 金扣
        
        # 手臂 (左前右后) — 金属护甲
        # 左臂
        r(d, 5, 19, 4, 9, ar)
        r(d, 5, 19, 1, 9, ar_sh)  # 左阴影
        r(d, 8, 19, 1, 4, ar_hi)  # 右高光
        # 护手
        r(d, 5, 27, 4, 2, ar_sh)
        # 手
        r(d, 6, 29, 2, 2, sk)
        
        # 右臂 (持剑)
        r(d, 23, 19, 4, 9, ar)
        r(d, 23, 19, 1, 9, ar_sh)
        r(d, 26, 19, 1, 4, ar_hi)
        r(d, 23, 27, 4, 2, ar_sh)
        r(d, 24, 29, 2, 2, sk)
        
        # 腿
        r(d, 11, 28+leg_off, 4, 6, ar)
        r(d, 11, 28+leg_off, 1, 6, ar_sh)
        r(d, 17, 28-leg_off, 4, 6, ar)
        r(d, 20, 28-leg_off, 1, 6, ar_sh)
        
        # 靴子
        r(d, 10, 34+leg_off, 5, 2, bt)
        r(d, 17, 34-leg_off, 5, 2, bt)
        
        # 大剑 (右手边)
        # 剑刃 (银钢)
        r(d, 28, 2, 2, 16, st)
        r(d, 28, 2, 1, 16, st_sh)
        r(d, 29, 2, 1, 16, st_hi)
        # 剑尖 (尖)
        p(d, 29, 1, st_hi)
        # 护手 (金)
        r(d, 26, 18, 6, 2, gd)
        r(d, 26, 18, 6, 1, gd_hi)
        # 剑柄
        r(d, 28, 20, 2, 4, hi)
        r(d, 28, 24, 2, 1, gd)  # 剑柄尾
        
    elif dir_idx == 1:  # 左
        leg_off, arm_off = -arm_off, leg_off
        # 头发 (正面+后脑勺)
        r(d, 10, 2, 13, 3, hr)
        r(d, 9, 5, 2, 4, hr)
        r(d, 22, 5, 1, 3, hr)  # 后脑勺头发
        # 脸
        r(d, 11, 5, 12, 11, sk)
        r(d, 11, 15, 12, 1, sk_sh)
        r(d, 12, 6, 3, 1, sk_hi)
        # 左侧面眼
        r(d, 12, 9, 2, 3, "#ffffff")
        r(d, 12, 10, 2, 2, hr_sh)
        p(d, 12, 10, "#ffffff")
        p(d, 13, 11, "#ffffff")
        # 鼻(点)
        p(d, 10, 11, sk)
        # 嘴
        line(d, 10, 14, 12, 14, sk_sh)
        # 右耳 (后脑勺方向看得到)
        r(d, 22, 10, 1, 3, sk)
        
        # 胸甲
        r(d, 10, 18, 14, 8, ar)
        r(d, 22, 19, 2, 7, ar_sh)
        r(d, 10, 25, 14, 1, ar_sh)
        r(d, 11, 19, 3, 1, ar_hi)
        poly(d, [(17, 19), (14, 24), (17, 27), (20, 24)], gd)
        p(d, 17, 23, rd)
        r(d, 10, 26, 14, 2, gd_sh)
        
        # 前手臂 (朝前左)
        r(d, 2, 21+arm_off, 4, 8, ar)
        r(d, 2, 21+arm_off, 1, 8, ar_sh)
        r(d, 2, 29+arm_off, 4, 2, ar_sh)
        # 剑刃朝前伸
        r(d, 0, 21, 2, 10, st)
        r(d, 0, 21, 1, 10, st_sh)
        r(d, 32, 21, 1, 10, st_hi)  # 剑尖
        # 护手
        r(d, 2, 21, 5, 2, gd)
        
        # 后手臂 (朝后右)
        r(d, 24, 22-arm_off, 4, 8, ar)
        r(d, 24, 22-arm_off, 1, 8, ar_sh)
        
        # 腿
        r(d, 11, 28-leg_off, 4, 6, ar)
        r(d, 18, 28+leg_off, 4, 6, ar)
        r(d, 10, 34-leg_off, 5, 2, bt)
        r(d, 17, 34+leg_off, 5, 2, bt)
        
    elif dir_idx == 2:  # 右 (镜像左)
        leg_off, arm_off = arm_off, leg_off
        r(d, 9, 2, 13, 3, hr)
        r(d, 8, 5, 1, 3, hr)
        r(d, 21, 5, 2, 4, hr)
        
        r(d, 9, 5, 12, 11, sk)
        r(d, 9, 15, 12, 1, sk_sh)
        r(d, 10, 6, 3, 1, sk_hi)
        # 右眼朝右看
        r(d, 18, 9, 2, 3, "#ffffff")
        r(d, 18, 10, 2, 2, hr_sh)
        p(d, 18, 10, "#ffffff")
        p(d, 19, 11, "#ffffff")
        p(d, 22, 11, sk)  # 鼻
        line(d, 22, 14, 24, 14, sk_sh)
        r(d, 8, 10, 1, 3, sk)  # 左耳
        
        r(d, 8, 18, 14, 8, ar)
        r(d, 8, 19, 2, 7, ar_sh)
        r(d, 8, 25, 14, 1, ar_sh)
        r(d, 9, 19, 3, 1, ar_hi)
        poly(d, [(15, 19), (12, 24), (15, 27), (18, 24)], gd)
        p(d, 15, 23, rd)
        r(d, 8, 26, 14, 2, gd_sh)
        
        # 前手臂 (朝前右) + 剑
        r(d, 26, 21+arm_off, 4, 8, ar)
        r(d, 26, 21+arm_off, 1, 8, ar_sh)
        r(d, 30, 21+arm_off, 1, 4, ar_hi)
        r(d, 26, 29+arm_off, 4, 2, ar_sh)
        # 剑朝右伸
        r(d, 31, 21, 1, 10, st)
        r(d, 27, 21, 4, 2, gd)
        
        r(d, 4, 22-arm_off, 4, 8, ar)
        r(d, 4, 22-arm_off, 1, 8, ar_sh)
        
        r(d, 10, 28+leg_off, 4, 6, ar)
        r(d, 17, 28-leg_off, 4, 6, ar)
        r(d, 9, 34+leg_off, 5, 2, bt)
        r(d, 16, 34-leg_off, 5, 2, bt)
        
    else:  # 上 (后脑勺)
        leg_off, arm_off = 0, 0  # 上方向手臂不动
        
        # 后脑勺头发 (更厚)
        r(d, 9, 1, 14, 15, hr)
        # 头发高光
        r(d, 10, 2, 3, 1, hr_hi)
        r(d, 18, 2, 3, 1, hr_hi)
        r(d, 14, 3, 4, 1, hr_hi)
        # 头发阴影 (底部)
        r(d, 9, 15, 14, 2, hr_sh)
        
        # 耳 (只看得到轮廓)
        r(d, 8, 10, 1, 3, sk)
        r(d, 23, 10, 1, 3, sk)
        
        # 后脑颈部
        r(d, 14, 16, 4, 2, sk_sh)
        
        # 胸甲 (后背)
        r(d, 8, 18, 16, 10, ar)
        r(d, 8, 19, 1, 9, ar_sh)   # 左阴影
        r(d, 23, 19, 1, 9, ar_sh)  # 右阴影
        r(d, 8, 27, 16, 1, ar_sh)  # 下阴影
        r(d, 9, 19, 3, 1, ar_hi)   # 高光
        # 背部装饰 (小十字)
        p(d, 16, 22, gd)
        p(d, 15, 22, gd_sh)
        p(d, 17, 22, gd_sh)
        p(d, 16, 21, gd_sh)
        p(d, 16, 23, gd_sh)
        
        # 腰带
        r(d, 8, 28, 16, 2, gd_sh)
        
        # 手臂 (对称)
        r(d, 4, 20, 4, 9, ar)
        r(d, 4, 20, 1, 9, ar_sh)
        r(d, 5, 29, 3, 1, ar_sh)
        
        r(d, 24, 20, 4, 9, ar)
        r(d, 24, 20, 1, 9, ar_sh)
        r(d, 25, 29, 3, 1, ar_sh)
        
        # 腿
        r(d, 10, 30-leg_off, 4, 5, ar)
        r(d, 18, 30+leg_off, 4, 5, ar)
        r(d, 9, 35-leg_off, 6, 2, bt)
        r(d, 17, 35+leg_off, 6, 2, bt)
        
        # 剑 (背后)
        r(d, 28, 14, 2, 14, st)
        r(d, 28, 14, 1, 14, st_sh)
        r(d, 29, 14, 1, 14, st_hi)
        r(d, 26, 27, 6, 2, gd)
        r(d, 28, 29, 2, 4, hi)


def draw_mage(d, frame, pal):
    """法师 — 尖帽+长袍+法杖"""
    dir_idx = frame // 4
    step = frame % 4
    sk = C(pal, "skin"); sk_hi = C(pal, "skin_hi"); sk_sh = C(pal, "skin_sh")
    hr = C(pal, "hair"); hr_hi = C(pal, "hair_hi"); hr_sh = C(pal, "hair_sh")
    rb = C(pal, "robe"); rb_hi = C(pal, "robe_hi"); rb_sh = C(pal, "robe_sh")
    gd = C(pal, "gold"); gd_hi = C(pal, "gold_hi"); gd_sh = C(pal, "gold_sh")
    cr = C(pal, "crystal"); cr_hi = C(pal, "crystal_hi"); cr_sh = C(pal, "crystal_sh")
    sf = C(pal, "staff")
    bt = C(pal, "boot")
    
    leg_off, arm_off = _walk_offsets(step, dir_idx)
    
    if dir_idx == 0:
        # 尖帽 (大三角)
        # 左斜边: (13, 15) -> (16, 0)
        for y in range(0, 16):
            w = y // 2 + 3
            r(d, 16-w, y, w*2, 1, rb)
        # 帽顶尖
        r(d, 15, 0, 2, 1, rb)
        # 帽高光
        for y in range(4, 14, 2):
            p(d, 16-1, y, rb_hi)
        # 帽檐 (横条)
        r(d, 7, 14, 18, 2, gd)
        r(d, 7, 14, 18, 1, gd_hi)
        # 帽尖水晶球
        r(d, 14, -3, 4, 4, cr)
        r(d, 14, -3, 2, 1, cr_hi)
        
        # 脸 (在帽檐下)
        r(d, 11, 16, 12, 10, sk)
        r(d, 11, 25, 12, 1, sk_sh)
        r(d, 12, 17, 3, 1, sk_hi)
        face_down(d, pal, 17, 20, "smile")
        r(d, 10, 19, 1, 3, sk)  # 左耳
        r(d, 22, 19, 1, 3, sk)  # 右耳
        
        # 长袍 (钟形, 从领口往下展开)
        # 上半身
        r(d, 10, 26, 12, 4, rb)
        r(d, 10, 29, 12, 1, rb_sh)
        # 腰部
        r(d, 9, 30, 14, 2, rb)
        # 下摆 (宽)
        r(d, 6, 32, 20, 4, rb)
        r(d, 6, 32, 20, 1, rb_sh)
        # 长袍高光
        r(d, 11, 27, 3, 1, rb_hi)
        r(d, 8, 32, 2, 1, rb_hi)
        # 腰带 (金)
        r(d, 9, 29, 14, 1, gd_sh)
        
        # 露鞋 (长袍下摆下)
        r(d, 10, 35, 5, 1, bt)
        r(d, 17, 35, 5, 1, bt)
        
        # 法杖 (右手边, 竖直)
        r(d, 28, 8, 2, 22, sf)
        # 水晶球
        r(d, 25, 3, 8, 8, cr)
        r(d, 26, 4, 4, 2, cr_hi)
        p(d, 27, 5, cr_hi)  # 高光点
        
    elif dir_idx == 1:
        leg_off, arm_off = -arm_off, leg_off
        # 尖帽 (左视)
        for y in range(0, 16):
            w = y // 2 + 3
            r(d, 18-w, y, w*2, 1, rb)
        r(d, 8, 14, 18, 2, gd)
        r(d, 15, -3, 4, 4, cr)
        
        # 脸
        r(d, 12, 16, 13, 10, sk)
        r(d, 12, 25, 13, 1, sk_sh)
        r(d, 13, 17, 3, 1, sk_hi)
        # 侧眼
        r(d, 13, 19, 2, 3, "#ffffff")
        r(d, 13, 20, 2, 2, hr_sh)
        p(d, 13, 20, "#ffffff")
        p(d, 14, 21, "#ffffff")
        p(d, 11, 21, sk)  # 鼻
        line(d, 11, 24, 13, 24, sk_sh)
        r(d, 24, 19, 1, 3, sk)  # 后耳
        
        # 长袍
        r(d, 11, 26, 14, 4, rb)
        r(d, 10, 30, 16, 2, rb)
        r(d, 7, 32, 21, 4, rb)
        r(d, 7, 32, 21, 1, rb_sh)
        r(d, 10, 29, 16, 1, gd_sh)
        
        # 法杖朝左前伸
        r(d, 0, 18, 2, 14, sf)
        r(d, 0, 15, 6, 6, cr)
        r(d, 1, 16, 3, 2, cr_hi)
        
        # 后手臂 (被长袍遮一点)
        r(d, 25, 27, 4, 6, rb)
        r(d, 25, 27, 1, 6, rb_sh)
        
        # 鞋
        r(d, 10, 35+leg_off, 5, 1, bt)
        r(d, 17, 35-leg_off, 5, 1, bt)
        
    elif dir_idx == 2:
        leg_off, arm_off = arm_off, leg_off
        for y in range(0, 16):
            w = y // 2 + 3
            r(d, 14-w, y, w*2, 1, rb)
        r(d, 8, 14, 18, 2, gd)
        r(d, 15, -3, 4, 4, cr)
        
        r(d, 9, 16, 13, 10, sk)
        r(d, 9, 25, 13, 1, sk_sh)
        r(d, 10, 17, 3, 1, sk_hi)
        r(d, 17, 19, 2, 3, "#ffffff")
        r(d, 17, 20, 2, 2, hr_sh)
        p(d, 17, 20, "#ffffff")
        p(d, 18, 21, "#ffffff")
        p(d, 23, 21, sk)
        line(d, 23, 24, 25, 24, sk_sh)
        r(d, 8, 19, 1, 3, sk)
        
        r(d, 8, 26, 14, 4, rb)
        r(d, 8, 29, 14, 1, rb_sh)
        r(d, 7, 30, 16, 2, rb)
        r(d, 6, 32, 21, 4, rb)
        r(d, 6, 32, 21, 1, rb_sh)
        r(d, 8, 29, 14, 1, gd_sh)
        
        # 法杖朝右
        r(d, 31, 8, 2, 22, sf)
        r(d, 28, 3, 8, 8, cr)
        r(d, 29, 4, 4, 2, cr_hi)
        
        r(d, 26, 27, 4, 6, rb)
        r(d, 26, 27, 1, 6, rb_sh)
        
        r(d, 10, 35-leg_off, 5, 1, bt)
        r(d, 17, 35+leg_off, 5, 1, bt)
        
    else:  # 上
        # 帽顶 (背后看帽顶)
        for y in range(0, 16):
            w = y // 2 + 3
            r(d, 16-w, y, w*2, 1, rb)
        r(d, 7, 14, 18, 2, gd)
        
        # 后脑头发从帽檐漏
        r(d, 11, 16, 12, 4, hr)
        
        # 颈+长袍后背
        r(d, 14, 20, 4, 2, sk_sh)
        r(d, 9, 22, 14, 4, rb)
        r(d, 8, 26, 16, 3, rb)
        r(d, 6, 29, 20, 7, rb)
        r(d, 6, 35, 20, 1, rb_sh)
        
        # 法杖 + 水晶球 (背后也可见)
        r(d, 28, 8, 2, 22, sf)
        r(d, 25, 3, 8, 8, cr)
        r(d, 26, 4, 4, 2, cr_hi)
        
        r(d, 10, 35+leg_off, 5, 1, bt)
        r(d, 17, 35-leg_off, 5, 1, bt)


def draw_archer(d, frame, pal):
    """游侠 — 绿袍+马尾+弓"""
    dir_idx = frame // 4
    step = frame % 4
    sk = C(pal, "skin"); sk_hi = C(pal, "skin_hi"); sk_sh = C(pal, "skin_sh")
    hr = C(pal, "hair"); hr_hi = C(pal, "hair_hi"); hr_sh = C(pal, "hair_sh")
    tn = C(pal, "tunic"); tn_hi = C(pal, "tunic_hi"); tn_sh = C(pal, "tunic_sh")
    lt = C(pal, "leather"); lt_hi = C(pal, "leather_hi"); lt_sh = C(pal, "leather_sh")
    bw = C(pal, "bow")
    bt = C(pal, "boot")
    
    leg_off, arm_off = _walk_offsets(step, dir_idx)
    
    if dir_idx == 0:
        # 头发 (刘海 + 马尾)
        r(d, 10, 2, 12, 3, hr)
        r(d, 9, 4, 2, 3, hr)   # 侧
        r(d, 21, 4, 2, 3, hr)
        # 刘海锯齿
        r(d, 10, 5, 12, 1, hr_sh)
        # 马尾 (背后)
        r(d, 24, 8, 3, 10, hr)
        r(d, 24, 8, 2, 10, hr_sh)
        
        # 脸
        r(d, 10, 6, 12, 10, sk)
        r(d, 10, 15, 12, 1, sk_sh)
        r(d, 11, 7, 3, 1, sk_hi)
        face_down(d, pal, 16, 10, "big")
        # 笑脸红晕
        p(d, 13, 13, "#ff8090")
        p(d, 19, 13, "#ff8090")
        r(d, 9, 10, 1, 3, sk)
        r(d, 22, 10, 1, 3, sk)
        
        # 短袍上身
        r(d, 10, 17, 12, 8, tn)
        r(d, 10, 24, 12, 1, tn_sh)
        r(d, 21, 18, 1, 7, tn_sh)
        r(d, 11, 18, 3, 1, tn_hi)
        # V领 (开口)
        p(d, 16, 18, sk)
        p(d, 15, 19, sk)
        p(d, 17, 19, sk)
        # 腰带
        r(d, 10, 25, 12, 1, lt)
        
        # 手臂 (露臂)
        r(d, 6, 18, 3, 8, sk)
        r(d, 6, 18, 1, 8, sk_sh)
        r(d, 7, 18, 1, 3, sk_hi)
        # 手
        r(d, 6, 26, 3, 2, sk)
        
        r(d, 23, 18, 3, 8, sk)
        r(d, 23, 18, 1, 8, sk_sh)
        r(d, 25, 26, 3, 2, sk)
        
        # 皮裤
        r(d, 11, 26+leg_off, 4, 6, lt)
        r(d, 11, 26+leg_off, 1, 6, lt_sh)
        r(d, 17, 26-leg_off, 4, 6, lt)
        r(d, 20, 26-leg_off, 1, 6, lt_sh)
        
        # 靴子
        r(d, 10, 32+leg_off, 5, 3, bt)
        r(d, 17, 32-leg_off, 5, 3, bt)
        
        # 弓 (背后)
        r(d, 27, 14, 1, 16, bw)
        r(d, 28, 14, 1, 16, bw)
        
    elif dir_idx == 1:
        leg_off, arm_off = -arm_off, leg_off
        r(d, 11, 2, 13, 3, hr)
        r(d, 10, 4, 2, 3, hr)
        r(d, 23, 5, 2, 15, hr)  # 马尾侧视
        
        r(d, 12, 6, 13, 10, sk)
        r(d, 12, 15, 13, 1, sk_sh)
        r(d, 13, 7, 3, 1, sk_hi)
        r(d, 13, 10, 2, 3, "#ffffff")
        r(d, 13, 11, 2, 2, hr_sh)
        p(d, 13, 11, "#ffffff")
        p(d, 14, 12, "#ffffff")
        p(d, 11, 12, sk)
        line(d, 11, 15, 13, 15, sk_sh)
        p(d, 14, 14, "#ff8090")
        r(d, 24, 10, 1, 3, sk)
        
        r(d, 11, 17, 14, 8, tn)
        r(d, 11, 24, 14, 1, tn_sh)
        r(d, 12, 18, 3, 1, tn_hi)
        r(d, 11, 25, 14, 1, lt)
        
        # 前手臂 + 持弓
        r(d, 1, 21+arm_off, 3, 9, sk)
        r(d, 1, 21+arm_off, 1, 9, sk_sh)
        # 弓朝前
        r(d, 0, 17, 1, 14, bw)
        r(d, 3, 17, 1, 14, bw)
        # 弓弦
        line(d, 1, 17, 1, 31, "#aaa")
        # 箭
        line(d, 1, 23, 14, 23, "#c0a080")
        
        r(d, 24, 22-arm_off, 3, 8, sk)
        r(d, 24, 22-arm_off, 1, 8, sk_sh)
        
        r(d, 12, 26-leg_off, 4, 6, lt)
        r(d, 19, 26+leg_off, 4, 6, lt)
        r(d, 11, 32-leg_off, 5, 3, bt)
        r(d, 18, 32+leg_off, 5, 3, bt)
        
    elif dir_idx == 2:
        leg_off, arm_off = arm_off, leg_off
        r(d, 8, 2, 13, 3, hr)
        r(d, 8, 4, 2, 3, hr)
        r(d, 8, 5, 2, 15, hr)
        
        r(d, 8, 6, 13, 10, sk)
        r(d, 8, 15, 13, 1, sk_sh)
        r(d, 9, 7, 3, 1, sk_hi)
        r(d, 17, 10, 2, 3, "#ffffff")
        r(d, 17, 11, 2, 2, hr_sh)
        p(d, 17, 11, "#ffffff")
        p(d, 18, 12, "#ffffff")
        p(d, 23, 12, sk)
        line(d, 22, 15, 24, 15, sk_sh)
        p(d, 16, 14, "#ff8090")
        r(d, 7, 10, 1, 3, sk)
        
        r(d, 8, 17, 14, 8, tn)
        r(d, 8, 24, 14, 1, tn_sh)
        r(d, 9, 18, 3, 1, tn_hi)
        r(d, 8, 25, 14, 1, lt)
        
        r(d, 27, 21+arm_off, 3, 9, sk)
        r(d, 27, 21+arm_off, 1, 9, sk_sh)
        r(d, 28, 26+arm_off, 3, 2, sk)
        
        # 弓朝右
        r(d, 28, 17, 1, 14, bw)
        r(d, 31, 17, 1, 14, bw)
        line(d, 30, 17, 30, 31, "#aaa")
        line(d, 18, 23, 30, 23, "#c0a080")
        
        r(d, 3, 22-arm_off, 3, 8, sk)
        r(d, 3, 22-arm_off, 1, 8, sk_sh)
        
        r(d, 9, 26+leg_off, 4, 6, lt)
        r(d, 16, 26-leg_off, 4, 6, lt)
        r(d, 8, 32+leg_off, 5, 3, bt)
        r(d, 15, 32-leg_off, 5, 3, bt)
        
    else:  # 上
        # 后脑勺头发 + 马尾
        r(d, 9, 1, 14, 15, hr)
        r(d, 9, 15, 14, 1, hr_sh)
        r(d, 23, 10, 3, 15, hr)
        r(d, 23, 10, 2, 15, hr_sh)
        
        r(d, 8, 17, 16, 8, tn)
        r(d, 8, 24, 16, 1, tn_sh)
        r(d, 8, 25, 16, 1, lt)
        
        r(d, 4, 19, 3, 8, sk)
        r(d, 25, 19, 3, 8, sk)
        
        r(d, 10, 26-leg_off, 4, 6, lt)
        r(d, 18, 26+leg_off, 4, 6, lt)
        r(d, 9, 32-leg_off, 5, 3, bt)
        r(d, 17, 32+leg_off, 5, 3, bt)


def draw_slime(d, frame, pal):
    """史莱姆 — Q弹椭圆+大眼, 无描边"""
    dir_idx = frame // 4
    step = frame % 4
    bd = C(pal, "body"); bd_hi = C(pal, "body_hi"); bd_sh = C(pal, "body_sh")
    
    # 弹跳挤压
    squish = [0, 2, 0, -1][step]
    
    # 主体 (椭圆) — 用矩形逐行拼出椭圆
    cx, cy = 16, 22 + squish
    # 简单办法: 直接画一椭圆区域的 rect
    body_pixels = [
        (10, 16+squish, 12, 2),
        (8, 18+squish, 16, 2),
        (7, 20+squish, 18, 2),
        (6, 22+squish, 20, 3),
        (6, 25+squish, 20, 3),
        (7, 28+squish, 18, 2),
        (9, 30+squish, 14, 1),
    ]
    for x, y, w, h in body_pixels:
        r(d, x, y, w, h, bd)
    
    # 高光 (左上)
    for x, y, w, h in [
        (9, 17+squish, 3, 1),
        (8, 19+squish, 2, 1),
        (8, 21+squish, 2, 1),
    ]:
        r(d, x, y, w, h, bd_hi)
    
    # 阴影 (右下)
    for x, y, w, h in [
        (20, 26+squish, 6, 1),
        (21, 27+squish, 5, 1),
        (22, 28+squish, 4, 1),
    ]:
        r(d, x, y, w, h, bd_sh)
    
    # 眼睛 (大眼)
    eye_y = 22 + squish
    if dir_idx == 0:  # 正视
        ex1, ex2 = 13, 19
    elif dir_idx == 1:
        ex1, ex2 = 11, 17  # 眼偏左
    elif dir_idx == 2:
        ex1, ex2 = 15, 21
    else:
        # 后脑勺: 画小背眼 (装饰小点)
        p(d, 14, 25+squish, bd_sh)
        p(d, 18, 25+squish, bd_sh)
        return
    
    # 眼白
    r(d, ex1-1, eye_y, 3, 4, "#ffffff")
    r(d, ex2-1, eye_y, 3, 4, "#ffffff")
    # 瞳孔 (深黑)
    r(d, ex1, eye_y+1, 2, 2, "#1a1a2e")
    r(d, ex2, eye_y+1, 2, 2, "#1a1a2e")
    # 高光 (白)
    p(d, ex1, eye_y+1, "#ffffff")
    p(d, ex1+1, eye_y+2, "#ffffff")
    p(d, ex2, eye_y+1, "#ffffff")
    p(d, ex2+1, eye_y+2, "#ffffff")
    
    # 嘴 (小弧)
    line(d, ex1+2, eye_y+5, ex2-2, eye_y+5, "#205020")
    # 弧中间低
    p(d, 16, eye_y+6, "#205020")


def draw_demon(d, frame, pal):
    """恶魔 — 犄角+竖瞳+獠牙"""
    dir_idx = frame // 4
    step = frame % 4
    sk = C(pal, "skin"); sk_hi = C(pal, "skin_hi"); sk_sh = C(pal, "skin_sh")
    hn = C(pal, "horn"); hn_hi = C(pal, "horn_hi"); hn_sh = C(pal, "horn_sh")
    ey = C(pal, "eye"); ey_hi = C(pal, "eye_hi"); ey_sh = C(pal, "eye_sh")
    
    leg_off = [0, 1, 0, -1][step]
    
    if dir_idx == 0:
        # 犄角 (左上, 右上)
        poly(d, [(10, 7), (6, -2), (12, 5), (11, 7)], hn)
        poly(d, [(22, 7), (26, -2), (20, 5), (21, 7)], hn)
        # 犄角高光
        r(d, 8, 3, 1, 3, hn_hi)
        r(d, 23, 3, 1, 3, hn_hi)
        
        # 头 (多边形, 略尖)
        head_pts = [(10, 7), (8, 13), (10, 20), (16, 23), (22, 20), (24, 13), (22, 7)]
        poly(d, head_pts, sk)
        # 头阴影 (下+两侧)
        r(d, 8, 13, 2, 10, sk_sh)
        r(d, 22, 13, 2, 10, sk_sh)
        r(d, 10, 22, 12, 1, sk_sh)
        # 头高光
        r(d, 11, 8, 3, 1, sk_hi)
        
        # 眼睛 (竖瞳)
        r(d, 12, 11, 3, 5, "#ffffff")
        r(d, 13, 12, 2, 4, ey)
        p(d, 13, 12, ey_hi)
        r(d, 18, 11, 3, 5, "#ffffff")
        r(d, 19, 12, 2, 4, ey)
        p(d, 19, 12, ey_hi)
        
        # 獠牙嘴 (大嘴 + 牙)
        r(d, 11, 18, 10, 3, "#1a1a1a")
        # 獠牙
        poly(d, [(13, 18), (14, 22), (15, 18)], "#ffffff")
        poly(d, [(17, 18), (18, 22), (19, 18)], "#ffffff")
        
        # 身体 (肌肉)
        r(d, 7, 22, 18, 8, sk)
        r(d, 22, 23, 3, 7, sk_sh)
        r(d, 7, 29, 18, 1, sk_sh)
        # 肌肉高光
        r(d, 10, 23, 3, 1, sk_hi)
        r(d, 10, 26, 3, 1, sk_hi)
        r(d, 17, 23, 3, 1, sk_hi)
        r(d, 17, 26, 3, 1, sk_hi)
        
        # 手臂
        r(d, 3, 22, 5, 10, sk)
        r(d, 3, 22, 1, 10, sk_sh)
        r(d, 4, 23, 1, 4, sk_hi)
        
        r(d, 24, 22, 5, 10, sk)
        r(d, 28, 22, 1, 10, sk_sh)
        r(d, 25, 23, 1, 4, sk_hi)
        
        # 腿
        r(d, 10, 30+leg_off, 5, 5, sk)
        r(d, 10, 30+leg_off, 1, 5, sk_sh)
        r(d, 17, 30-leg_off, 5, 5, sk)
        r(d, 21, 30-leg_off, 1, 5, sk_sh)
        
        # 爪 (脚)
        r(d, 10, 35+leg_off, 6, 2, sk)
        r(d, 17, 35-leg_off, 6, 2, sk)
        p(d, 9, 36+leg_off, "#1a1a1a")
        p(d, 16, 36+leg_off, "#1a1a1a")
        p(d, 23, 36-leg_off, "#1a1a1a")
        p(d, 10, 36-leg_off, "#1a1a1a")
        
    elif dir_idx == 1:
        # 简化侧视
        poly(d, [(11, 7), (7, -2), (13, 5)], hn)
        poly(d, [(22, 7), (26, -2), (21, 5)], hn)
        poly(d, [(10, 7), (9, 13), (11, 20), (16, 23), (22, 20), (23, 13), (21, 7)], sk)
        
        r(d, 13, 11, 3, 5, "#ffffff")
        r(d, 14, 12, 2, 4, ey)
        p(d, 14, 12, ey_hi)
        
        r(d, 11, 18, 7, 3, "#1a1a1a")
        poly(d, [(13, 18), (14, 21), (15, 18)], "#ffffff")
        
        r(d, 6, 22, 18, 8, sk)
        r(d, 1, 23, 6, 10, sk)  # 前手臂
        r(d, 24, 23, 4, 10, sk)
        
        r(d, 10, 30, 5, 5, sk)
        r(d, 18, 30, 5, 5, sk)
        
    elif dir_idx == 2:
        poly(d, [(10, 7), (6, -2), (12, 5)], hn)
        poly(d, [(23, 7), (27, -2), (22, 5)], hn)
        poly(d, [(9, 7), (8, 13), (10, 20), (16, 23), (22, 20), (24, 13), (23, 7)], sk)
        
        r(d, 16, 11, 3, 5, "#ffffff")
        r(d, 17, 12, 2, 4, ey)
        p(d, 17, 12, ey_hi)
        
        r(d, 14, 18, 7, 3, "#1a1a1a")
        poly(d, [(16, 18), (17, 21), (18, 18)], "#ffffff")
        
        r(d, 8, 22, 18, 8, sk)
        r(d, 25, 23, 6, 10, sk)
        r(d, 3, 23, 4, 10, sk)
        
        r(d, 10, 30, 5, 5, sk)
        r(d, 18, 30, 5, 5, sk)
        
    else:  # 上
        poly(d, [(10, 7), (6, -2), (12, 5)], hn)
        poly(d, [(22, 7), (26, -2), (21, 5)], hn)
        # 后脑 (更凸)
        poly(d, [(10, 7), (8, 13), (8, 22), (16, 25), (24, 22), (24, 13), (22, 7)], sk)
        r(d, 8, 22, 16, 1, sk_sh)
        
        r(d, 7, 25, 18, 7, sk)
        r(d, 3, 24, 5, 10, sk)
        r(d, 24, 24, 5, 10, sk)
        r(d, 10, 32, 5, 5, sk)
        r(d, 17, 32, 5, 5, sk)


def draw_ghost(d, frame, pal):
    """幽灵 — 飘浮空+圆空洞眼"""
    dir_idx = frame // 4
    step = frame % 4
    bd = C(pal, "body"); bd_hi = C(pal, "body_hi"); bd_sh = C(pal, "body_sh")
    
    float_y = [0, -1, 0, 1][step]
    
    # 钟形身体
    body_rows = [
        (9, 9+float_y, 14, 2),
        (8, 11+float_y, 16, 2),
        (7, 13+float_y, 18, 2),
        (7, 15+float_y, 18, 3),
        (7, 18+float_y, 18, 4),
        (7, 22+float_y, 18, 4),
        # 波浪下摆
        (7, 26+float_y, 5, 3),
        (12, 26+float_y, 4, 3),
        (16, 26+float_y, 4, 3),
        (20, 26+float_y, 5, 3),
    ]
    for x, y, w, h in body_rows:
        r(d, x, y, w, h, bd)
    
    # 高光
    for x, y, w, h in [(9, 11+float_y, 3, 1), (8, 13+float_y, 2, 1), (9, 14+float_y, 2, 1)]:
        r(d, x, y, w, h, bd_hi)
    
    # 阴影
    for x, y, w, h in [(22, 18+float_y, 3, 4), (23, 22+float_y, 2, 3)]:
        r(d, x, y, w, h, bd_sh)
    
    if dir_idx != 3:  # 不是后脑勺
        # 空洞眼 (黑色椭圆, 不用黑描边, 用深灰)
        r(d, 11, 16+float_y, 4, 5, "#1a1a2e")
        r(d, 18, 16+float_y, 4, 5, "#1a1a2e")
        # 空洞内小亮点 (反光)
        p(d, 13, 17+float_y, "#ffffff")
        p(d, 20, 17+float_y, "#ffffff")
        # 小嘴 (小圆O)
        r(d, 15, 23+float_y, 4, 3, "#1a1a2e")


def draw_skeleton(d, frame, pal):
    """骷髅 — 骨头+红眼"""
    dir_idx = frame // 4
    step = frame % 4
    bn = C(pal, "bone"); bn_hi = C(pal, "bone_hi"); bn_sh = C(pal, "bone_sh")
    ey = C(pal, "eye")
    cl = C(pal, "cloth")
    
    leg_off = [0, 1, 0, -1][step]
    
    if dir_idx == 0:
        # 头骨
        r(d, 9, 2, 14, 13, bn)
        r(d, 9, 2, 14, 1, bn_sh)  # 顶阴影
        r(d, 10, 3, 3, 1, bn_hi)  # 高光
        
        # 眼眶 (黑洞)
        r(d, 11, 6, 4, 5, "#1a1a2e")
        r(d, 17, 6, 4, 5, "#1a1a2e")
        # 红眼 (发光)
        r(d, 12, 8, 2, 2, ey)
        r(d, 18, 8, 2, 2, ey)
        p(d, 12, 8, "#ffffff")  # 高光
        p(d, 18, 8, "#ffffff")
        
        # 空洞鼻子
        r(d, 15, 10, 2, 3, "#1a1a2e")
        
        # 牙齿
        for i in range(5):
            r(d, 11+i*2, 13, 1, 2, bn)
        
        # 肋骨/裹布
        r(d, 9, 17, 14, 12, cl)
        # 骨头透出
        line(d, 11, 19, 21, 19, bn, 1)
        line(d, 12, 22, 20, 22, bn, 1)
        line(d, 13, 25, 19, 25, bn, 1)
        # 高光
        r(d, 10, 18, 3, 1, "#5a5a70")
        
        # 手臂 (骨头)
        r(d, 5, 18, 3, 11, bn)
        r(d, 5, 18, 1, 11, bn_sh)
        r(d, 6, 18, 1, 4, bn_hi)
        # 手指 (小骨)
        r(d, 5, 28, 1, 2, bn)
        r(d, 7, 28, 1, 2, bn)
        r(d, 6, 28, 1, 2, bn)
        
        r(d, 24, 18, 3, 11, bn)
        r(d, 26, 18, 1, 11, bn_sh)
        r(d, 25, 18, 1, 4, bn_hi)
        r(d, 24, 28, 1, 2, bn)
        r(d, 26, 28, 1, 2, bn)
        
        # 腿 (骨头)
        r(d, 11, 29+leg_off, 4, 6, bn)
        r(d, 11, 29+leg_off, 1, 6, bn_sh)
        r(d, 17, 29-leg_off, 4, 6, bn)
        r(d, 20, 29-leg_off, 1, 6, bn_sh)
        
        # 脚骨
        r(d, 10, 35+leg_off, 5, 2, bn)
        r(d, 17, 35-leg_off, 5, 2, bn)
        
    else:
        # 侧视/后视简化处理
        if dir_idx == 1:
            r(d, 10, 2, 14, 13, bn)
            r(d, 13, 6, 4, 5, "#1a1a2e")
            r(d, 14, 8, 2, 2, ey)
            for i in range(4):
                r(d, 12+i*2, 13, 1, 2, bn)
            r(d, 9, 17, 14, 12, cl)
            r(d, 2, 21, 4, 10, bn)  # 前臂
            r(d, 24, 22, 3, 10, bn)
            r(d, 11, 29, 4, 6, bn)
            r(d, 18, 29, 4, 6, bn)
        elif dir_idx == 2:
            r(d, 8, 2, 14, 13, bn)
            r(d, 17, 6, 4, 5, "#1a1a2e")
            r(d, 18, 8, 2, 2, ey)
            for i in range(4):
                r(d, 10+i*2, 13, 1, 2, bn)
            r(d, 8, 17, 14, 12, cl)
            r(d, 26, 21, 4, 10, bn)
            r(d, 4, 22, 3, 10, bn)
            r(d, 10, 29, 4, 6, bn)
            r(d, 17, 29, 4, 6, bn)
        else:
            r(d, 9, 2, 14, 14, bn)
            r(d, 9, 17, 14, 12, cl)
            r(d, 5, 18, 3, 12, bn)
            r(d, 24, 18, 3, 12, bn)
            r(d, 10, 29, 4, 6, bn)
            r(d, 18, 29, 4, 6, bn)


# ================ 生成入口 ================
CHARACTERS = {
    "player_warrior": draw_warrior,
    "player_mage": draw_mage,
    "player_archer": draw_archer,
    "player_knight": draw_warrior,
    "enemy_slime": draw_slime,
    "enemy_demon": draw_demon,
    "enemy_ghost": draw_ghost,
    "enemy_skeleton": draw_skeleton
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

print(f"\n✅ 精灵已生成! → {OUTPUT_DIR}")
