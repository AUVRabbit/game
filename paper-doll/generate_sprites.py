#!/usr/bin/env python3
"""
Godot 精灵图生成器
输出 128x128 RGBA sprite sheets (4x4 网格, 每帧 32x32)
布局: 行0=下, 行1=左, 行2=右, 行3=上 (每行4帧动画)
"""

from PIL import Image, ImageDraw
import os

# 常量
FRAME = 32        # 每帧像素
GRID = 4          # 网格大小
SHEET = FRAME * GRID  # 128

OUTPUT_DIR = "/workspace/通天入地/assets/sprites/world"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ========== 调色板 ==========
PALETTES = {
    "warrior": {
        "skin": "#f4c2a1", "skin_sh": "#c58d6d",
        "hair": "#4a3728", "hair_hi": "#6b4f38",
        "eye": "#2c3e50",
        "armor": "#8b8fa3", "armor_sh": "#5e6075", "armor_hi": "#b0b4c8",
        "gold": "#d4a017", "red": "#c0392b",
        "boot": "#2d2d2d",
        "sword": "#d0d0d8", "hilt": "#654321",
        "outline": "#1a1a2e"
    },
    "mage": {
        "skin": "#f4c2a1", "skin_sh": "#c58d6d",
        "hair": "#6b3fa0", "hair_hi": "#8a5fc0",
        "eye": "#9400d3",
        "robe": "#4a148c", "robe_sh": "#2d0a54", "robe_hi": "#6a34ac",
        "gold": "#ffd700",
        "boot": "#654321",
        "staff": "#8b4513", "crystal": "#00d4ff",
        "outline": "#1a1a2e"
    },
    "archer": {
        "skin": "#f4c2a1", "skin_sh": "#c58d6d",
        "hair": "#8b4513", "hair_hi": "#a67c4a",
        "eye": "#228b22",
        "tunic": "#2d5a27", "tunic_sh": "#1d3d18", "tunic_hi": "#4d7a47",
        "leather": "#654321", "boot": "#3d2817",
        "bow": "#8b4513",
        "gold": "#b8860b",
        "outline": "#1a1a2e"
    },
    "knight": {
        "skin": "#f4c2a1", "skin_sh": "#c58d6d",
        "hair": "#1a1a2e", "eye": "#1a3a5c",
        "armor": "#5dade2", "armor_sh": "#3a8dbb", "armor_hi": "#9de2f5",
        "metal": "#e8e8f0", "metal_sh": "#a0a0b0", "metal_hi": "#ffffff",
        "blue": "#5dade2", "red": "#c0392b", "gold": "#ffd700",
        "boot": "#2a2a4a",
        "sword": "#e0e0e8", "hilt": "#8b4513",
        "outline": "#1a1a2e"
    },
    "slime": {
        "skin": "#7ccd7c", "skin_sh": "#3c8d3c", "skin_hi": "#a0edc0",
        "eye": "#2c3e50", "eye_white": "#fff",
        "outline": "#1a1a2e"
    },
    "demon": {
        "skin": "#8b0000", "skin_sh": "#5c0000", "skin_hi": "#b03030",
        "horn": "#1a1a1a",
        "eye": "#ffff00",
        "claw": "#ff4400",
        "outline": "#000000"
    },
    "ghost": {
        "skin": "#e0e0ff", "skin_sh": "#a0a0d0", "skin_hi": "#ffffff",
        "eye": "#0000ff",
        "outline": "#404080"
    },
    "skeleton": {
        "bone": "#e8e0d0", "bone_sh": "#a0a090",
        "eye": "#ff0000",
        "cloth": "#404040",
        "sword": "#808080",
        "outline": "#000000"
    }
}

def px(draw, x, y, color, scale=1):
    """画像素点"""
    draw.rectangle([x*scale, y*scale, (x+1)*scale-1, (y+1)*scale-1], fill=color)

def rect(draw, x, y, w, h, color, scale=1):
    draw.rectangle([x*scale, y*scale, (x+w)*scale-1, (y+h)*scale-1], fill=color)

def line(draw, x1, y1, x2, y2, color, scale=1):
    draw.line([(x1*scale, y1*scale), (x2*scale, y2*scale)], fill=color, width=scale)

# ========== 帧绘制函数 ==========
# 每个角色有 4 方向 × 4 行走帧
# 32x32 像素画布，脚在底部 y=28 左右

def draw_warrior(draw, frame, pal):
    """铁血战士 - 铠甲+剑"""
    # frame: 0-3 下方向, 4-7 左方向, 8-11 右方向, 12-15 上方向
    direction = frame // 4  # 0=下, 1=左, 2=右, 3=上
    step = frame % 4
    
    step_off = [0, 1, 0, -1][step]  # 腿上下偏移
    
    o = pal["outline"]
    scale = 1
    
    if direction == 0:  # 面朝下方
        # 头 (y=2~10)
        rect(draw, 11, 2, 10, 8, pal["skin"])
        rect(draw, 11, 2, 10, 1, pal["hair"])  # 头顶发
        # 眼睛
        px(draw, 13, 6, o)
        px(draw, 13, 7, pal["eye"])
        px(draw, 18, 6, o)
        px(draw, 18, 7, pal["eye"])
        # 金属头盔边缘
        rect(draw, 10, 1, 12, 2, pal["armor_sh"])
        rect(draw, 10, 1, 12, 1, pal["armor_hi"])
        # 脖子
        rect(draw, 14, 10, 4, 2, pal["skin_sh"])
        # 身体/铠甲 (y=12~22)
        rect(draw, 8, 12, 16, 10, pal["armor"])
        rect(draw, 8, 12, 16, 1, pal["armor_hi"])
        rect(draw, 8, 21, 16, 1, pal["armor_sh"])
        # 胸甲装饰
        rect(draw, 14, 14, 4, 4, pal["gold"])
        px(draw, 15, 15, pal["red"])
        px(draw, 16, 15, pal["red"])
        # 腰带
        rect(draw, 9, 22, 14, 2, pal["gold"])
        # 腿 (y=24~29) - 行走摆动
        rect(draw, 10, 24-step_off, 5, 5, pal["armor"])
        rect(draw, 17, 24+step_off, 5, 5, pal["armor"])
        rect(draw, 10, 29-step_off, 5, 2, pal["boot"])
        rect(draw, 17, 29+step_off, 5, 2, pal["boot"])
        # 手臂 + 剑
        rect(draw, 5, 13, 4, 8, pal["armor"])  # 左臂持盾
        rect(draw, 23, 13, 4, 8, pal["armor"]) # 右臂持剑
        # 盾牌
        rect(draw, 2, 14, 4, 7, pal["armor_hi"])
        rect(draw, 2, 14, 4, 1, pal["gold"])
        # 剑
        rect(draw, 25, 5, 2, 10, pal["sword"])
        rect(draw, 24, 14, 4, 1, pal["gold"])
        rect(draw, 25, 15, 2, 3, pal["hilt"])
        # 轮廓
        outline_rect(draw, 10, 1, 12, 9, o)
        outline_rect(draw, 8, 12, 16, 12, o)
        outline_rect(draw, 10, 24, 5, 7, o)
        outline_rect(draw, 17, 24, 5, 7, o)
        outline_rect(draw, 5, 13, 4, 8, o)
        outline_rect(draw, 23, 13, 4, 8, o)
        
    elif direction == 1:  # 面朝左
        step_off = [-1, 0, 1, 0][step]
        # 头
        rect(draw, 11, 2, 10, 8, pal["skin"])
        rect(draw, 11, 2, 10, 1, pal["hair"])
        # 眼睛 (朝左)
        px(draw, 13, 6, o)
        px(draw, 13, 7, pal["eye"])
        # 金属盔
        rect(draw, 10, 1, 12, 2, pal["armor_sh"])
        rect(draw, 10, 1, 12, 1, pal["armor_hi"])
        # 身体
        rect(draw, 9, 12, 14, 10, pal["armor"])
        rect(draw, 9, 12, 14, 1, pal["armor_hi"])
        rect(draw, 9, 21, 14, 1, pal["armor_sh"])
        rect(draw, 14, 14, 4, 4, pal["gold"])
        rect(draw, 10, 22, 12, 2, pal["gold"])
        # 腿
        rect(draw, 10, 24+step_off, 5, 5, pal["armor"])
        rect(draw, 16, 24-step_off, 5, 5, pal["armor"])
        rect(draw, 10, 29+step_off, 5, 2, pal["boot"])
        rect(draw, 16, 29-step_off, 5, 2, pal["boot"])
        # 手臂 + 剑 (朝前=朝左)
        rect(draw, 3, 14, 5, 7, pal["armor"])
        rect(draw, 22, 14, 4, 7, pal["armor"])
        # 剑 (朝左伸)
        rect(draw, -2, 15, 8, 2, pal["sword"])
        rect(draw, 4, 14, 2, 4, pal["gold"])
        # 盾
        rect(draw, 25, 15, 4, 7, pal["armor_hi"])
        # 轮廓
        outline_rect(draw, 10, 1, 12, 9, o)
        outline_rect(draw, 9, 12, 14, 12, o)
        outline_rect(draw, 10, 24, 5, 7, o)
        outline_rect(draw, 16, 24, 5, 7, o)
        
    elif direction == 2:  # 面朝右 (镜像左)
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 11, 2, 10, 8, pal["skin"])
        rect(draw, 11, 2, 10, 1, pal["hair"])
        px(draw, 18, 6, o)
        px(draw, 18, 7, pal["eye"])
        rect(draw, 10, 1, 12, 2, pal["armor_sh"])
        rect(draw, 10, 1, 12, 1, pal["armor_hi"])
        rect(draw, 9, 12, 14, 10, pal["armor"])
        rect(draw, 9, 12, 14, 1, pal["armor_hi"])
        rect(draw, 9, 21, 14, 1, pal["armor_sh"])
        rect(draw, 14, 14, 4, 4, pal["gold"])
        rect(draw, 10, 22, 12, 2, pal["gold"])
        rect(draw, 10, 24-step_off, 5, 5, pal["armor"])
        rect(draw, 16, 24+step_off, 5, 5, pal["armor"])
        rect(draw, 10, 29-step_off, 5, 2, pal["boot"])
        rect(draw, 16, 29+step_off, 5, 2, pal["boot"])
        rect(draw, 22, 14, 5, 7, pal["armor"])
        rect(draw, 3, 14, 4, 7, pal["armor"])
        # 剑朝右伸
        rect(draw, 27, 15, 8, 2, pal["sword"])
        rect(draw, 26, 14, 2, 4, pal["gold"])
        rect(draw, 3, 15, 4, 7, pal["armor_hi"])
        # 轮廓
        outline_rect(draw, 10, 1, 12, 9, o)
        outline_rect(draw, 9, 12, 14, 12, o)
        outline_rect(draw, 10, 24, 5, 7, o)
        outline_rect(draw, 16, 24, 5, 7, o)
        
    else:  # 面朝上
        step_off = [0, 1, 0, -1][step]
        rect(draw, 11, 2, 10, 8, pal["skin"])
        rect(draw, 11, 2, 10, 3, pal["hair"])  # 头发盖住头顶
        rect(draw, 11, 3, 10, 1, pal["hair_hi"])
        # 脖子
        rect(draw, 14, 10, 4, 2, pal["skin_sh"])
        # 身体
        rect(draw, 8, 12, 16, 10, pal["armor"])
        rect(draw, 8, 12, 16, 1, pal["armor_hi"])
        rect(draw, 8, 21, 16, 1, pal["armor_sh"])
        rect(draw, 14, 14, 4, 4, pal["gold"])
        rect(draw, 9, 22, 14, 2, pal["gold"])
        rect(draw, 10, 24-step_off, 5, 5, pal["armor"])
        rect(draw, 17, 24+step_off, 5, 5, pal["armor"])
        rect(draw, 10, 29-step_off, 5, 2, pal["boot"])
        rect(draw, 17, 29+step_off, 5, 2, pal["boot"])
        rect(draw, 5, 13, 4, 8, pal["armor"])
        rect(draw, 23, 13, 4, 8, pal["armor"])
        # 剑柄可见
        rect(draw, 25, 12, 2, 4, pal["hilt"])
        rect(draw, 24, 16, 4, 1, pal["gold"])
        # 盾
        rect(draw, 2, 14, 4, 7, pal["armor_hi"])
        # 轮廓
        outline_rect(draw, 10, 1, 12, 9, o)
        outline_rect(draw, 8, 12, 16, 12, o)
        outline_rect(draw, 10, 24, 5, 7, o)
        outline_rect(draw, 17, 24, 5, 7, o)
        outline_rect(draw, 5, 13, 4, 8, o)
        outline_rect(draw, 23, 13, 4, 8, o)


def draw_mage(draw, frame, pal):
    """奥术法师 - 长袍+法杖"""
    direction = frame // 4
    step = frame % 4
    step_off = [0, 1, 0, -1][step]
    o = pal["outline"]
    
    if direction == 0:  # 下
        # 帽子
        rect(draw, 10, 0, 12, 3, pal["robe_sh"])
        rect(draw, 12, -4, 8, 4, pal["robe"])  # 尖顶
        rect(draw, 15, -6, 2, 2, pal["gold"])  # 尖
        # 脸
        rect(draw, 12, 3, 8, 7, pal["skin"])
        px(draw, 13, 6, o); px(draw, 14, 7, pal["eye"])
        px(draw, 17, 6, o); px(draw, 18, 7, pal["eye"])
        px(draw, 15, 9, o)  # 嘴
        # 身体长袍 (宽大)
        rect(draw, 7, 10, 18, 18, pal["robe"])
        rect(draw, 7, 10, 18, 1, pal["robe_hi"])
        rect(draw, 7, 27, 18, 1, pal["robe_sh"])
        # 腰带
        rect(draw, 10, 18, 12, 2, pal["gold"])
        # 领口V形
        rect(draw, 14, 10, 4, 4, pal["skin_sh"])
        # 手臂
        rect(draw, 4, 11, 4, 10, pal["robe"])
        rect(draw, 24, 11, 4, 10, pal["robe"])
        rect(draw, 4, 21, 4, 3, pal["skin"])
        rect(draw, 24, 21, 4, 3, pal["skin"])
        # 法杖 (右边)
        rect(draw, 27, 2, 2, 22, pal["staff"])
        rect(draw, 26, 0, 4, 4, pal["crystal"])
        px(draw, 27, 1, "#ffffff")
        # 脚
        rect(draw, 11, 27+step_off, 4, 3, pal["boot"])
        rect(draw, 17, 27-step_off, 4, 3, pal["boot"])
        
    elif direction == 1:  # 左
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 10, 0, 12, 3, pal["robe_sh"])
        rect(draw, 12, -4, 8, 4, pal["robe"])
        rect(draw, 15, -6, 2, 2, pal["gold"])
        rect(draw, 12, 3, 8, 7, pal["skin"])
        px(draw, 13, 6, o); px(draw, 13, 7, pal["eye"])
        rect(draw, 8, 10, 16, 18, pal["robe"])
        rect(draw, 8, 10, 16, 1, pal["robe_hi"])
        rect(draw, 8, 27, 16, 1, pal["robe_sh"])
        rect(draw, 10, 18, 12, 2, pal["gold"])
        rect(draw, 4, 11, 4, 10, pal["robe"])
        rect(draw, 24, 11, 4, 10, pal["robe"])
        rect(draw, 11, 27-step_off, 4, 3, pal["boot"])
        rect(draw, 17, 27+step_off, 4, 3, pal["boot"])
        # 法杖朝左
        rect(draw, -1, 8, 2, 16, pal["staff"])
        rect(draw, -2, 6, 4, 4, pal["crystal"])
        
    elif direction == 2:  # 右
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 10, 0, 12, 3, pal["robe_sh"])
        rect(draw, 12, -4, 8, 4, pal["robe"])
        rect(draw, 15, -6, 2, 2, pal["gold"])
        rect(draw, 12, 3, 8, 7, pal["skin"])
        px(draw, 18, 6, o); px(draw, 18, 7, pal["eye"])
        rect(draw, 8, 10, 16, 18, pal["robe"])
        rect(draw, 8, 10, 16, 1, pal["robe_hi"])
        rect(draw, 8, 27, 16, 1, pal["robe_sh"])
        rect(draw, 10, 18, 12, 2, pal["gold"])
        rect(draw, 4, 11, 4, 10, pal["robe"])
        rect(draw, 24, 11, 4, 10, pal["robe"])
        rect(draw, 11, 27+step_off, 4, 3, pal["boot"])
        rect(draw, 17, 27-step_off, 4, 3, pal["boot"])
        # 法杖朝右
        rect(draw, 29, 8, 2, 16, pal["staff"])
        rect(draw, 28, 6, 4, 4, pal["crystal"])
        
    else:  # 上
        step_off = [0, 1, 0, -1][step]
        rect(draw, 10, 0, 12, 3, pal["robe_sh"])
        rect(draw, 12, -4, 8, 4, pal["robe"])
        rect(draw, 15, -6, 2, 2, pal["gold"])
        rect(draw, 12, 3, 8, 7, pal["skin"])
        rect(draw, 8, 10, 16, 18, pal["robe"])
        rect(draw, 8, 10, 16, 1, pal["robe_hi"])
        rect(draw, 8, 27, 16, 1, pal["robe_sh"])
        rect(draw, 10, 18, 12, 2, pal["gold"])
        rect(draw, 4, 11, 4, 10, pal["robe"])
        rect(draw, 24, 11, 4, 10, pal["robe"])
        rect(draw, 11, 27-step_off, 4, 3, pal["boot"])
        rect(draw, 17, 27+step_off, 4, 3, pal["boot"])
        rect(draw, 27, 2, 2, 22, pal["staff"])
        rect(draw, 26, 0, 4, 4, pal["crystal"])


def draw_archer(draw, frame, pal):
    """森林游侠 - 短袍+弓"""
    direction = frame // 4
    step = frame % 4
    step_off = [0, 1, 0, -1][step]
    o = pal["outline"]
    
    if direction == 0:
        # 马尾
        rect(draw, 19, 1, 5, 6, pal["hair"])
        rect(draw, 19, 1, 5, 2, pal["hair_hi"])
        # 头
        rect(draw, 11, 2, 10, 8, pal["skin"])
        px(draw, 13, 6, o); px(draw, 13, 7, pal["eye"])
        px(draw, 18, 6, o); px(draw, 18, 7, pal["eye"])
        # 身体
        rect(draw, 9, 10, 14, 11, pal["tunic"])
        rect(draw, 9, 10, 14, 1, pal["tunic_hi"])
        rect(draw, 9, 20, 14, 1, pal["tunic_sh"])
        # 腰带
        rect(draw, 10, 19, 12, 2, pal["leather"])
        rect(draw, 15, 18, 2, 3, pal["gold"])
        # 腿
        rect(draw, 11, 22-step_off, 4, 6, pal["leather"])
        rect(draw, 17, 22+step_off, 4, 6, pal["leather"])
        rect(draw, 10, 28-step_off, 5, 2, pal["boot"])
        rect(draw, 17, 28+step_off, 5, 2, pal["boot"])
        # 手
        rect(draw, 6, 12, 3, 8, pal["tunic"])
        rect(draw, 23, 12, 3, 8, pal["tunic"])
        rect(draw, 6, 19, 3, 3, pal["skin"])
        rect(draw, 23, 19, 3, 3, pal["skin"])
        # 弓 (右边)
        line(draw, 29, 10, 30, 22, pal["bow"])
        rect(draw, 28, 15, 4, 1, "#ccc")  # 弦
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 19, 1, 5, 6, pal["hair"])
        rect(draw, 11, 2, 10, 8, pal["skin"])
        px(draw, 13, 6, o); px(draw, 13, 7, pal["eye"])
        rect(draw, 9, 10, 14, 11, pal["tunic"])
        rect(draw, 9, 10, 14, 1, pal["tunic_hi"])
        rect(draw, 10, 19, 12, 2, pal["leather"])
        rect(draw, 11, 22+step_off, 4, 6, pal["leather"])
        rect(draw, 17, 22-step_off, 4, 6, pal["leather"])
        rect(draw, 10, 28+step_off, 5, 2, pal["boot"])
        rect(draw, 17, 28-step_off, 5, 2, pal["boot"])
        rect(draw, 4, 13, 4, 8, pal["skin"])  # 左手握弓
        rect(draw, 24, 13, 3, 8, pal["skin"])
        # 弓朝前 (朝左)
        line(draw, -1, 12, 0, 22, pal["bow"])
        rect(draw, -1, 16, 2, 1, "#ccc")
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 19, 1, 5, 6, pal["hair"])
        rect(draw, 11, 2, 10, 8, pal["skin"])
        px(draw, 18, 6, o); px(draw, 18, 7, pal["eye"])
        rect(draw, 9, 10, 14, 11, pal["tunic"])
        rect(draw, 9, 10, 14, 1, pal["tunic_hi"])
        rect(draw, 10, 19, 12, 2, pal["leather"])
        rect(draw, 11, 22-step_off, 4, 6, pal["leather"])
        rect(draw, 17, 22+step_off, 4, 6, pal["leather"])
        rect(draw, 10, 28-step_off, 5, 2, pal["boot"])
        rect(draw, 17, 28+step_off, 5, 2, pal["boot"])
        rect(draw, 4, 13, 3, 8, pal["skin"])
        rect(draw, 24, 13, 4, 8, pal["skin"])
        line(draw, 30, 12, 31, 22, pal["bow"])
        rect(draw, 29, 16, 2, 1, "#ccc")
        
    else:  # 上
        step_off = [0, 1, 0, -1][step]
        rect(draw, 11, 0, 10, 4, pal["hair"])  # 头发盖住
        rect(draw, 11, 4, 10, 6, pal["skin"])
        rect(draw, 9, 10, 14, 11, pal["tunic"])
        rect(draw, 10, 19, 12, 2, pal["leather"])
        rect(draw, 11, 22-step_off, 4, 6, pal["leather"])
        rect(draw, 17, 22+step_off, 4, 6, pal["leather"])
        rect(draw, 10, 28-step_off, 5, 2, pal["boot"])
        rect(draw, 17, 28+step_off, 5, 2, pal["boot"])
        rect(draw, 6, 12, 3, 8, pal["tunic"])
        rect(draw, 23, 12, 3, 8, pal["tunic"])
        # 弓垂在身后可见顶部
        line(draw, 29, 10, 30, 18, pal["bow"])


def draw_slime(draw, frame, pal):
    """果冻史莱姆 - Q弹怪物"""
    direction = frame // 4
    step = frame % 4
    # 史莱姆上下弹跳效果
    squish = [0, -1, 0, 1][step]  # 弹跳节奏
    o = pal["outline"]
    
    # 史莱姆身体 (下方向为主，四方向差不多)
    base_y = 20 + squish
    # 身体 (椭圆形)
    rect(draw, 8, base_y-5, 16, 10, pal["skin"])
    rect(draw, 7, base_y-3, 18, 8, pal["skin"])
    rect(draw, 6, base_y, 20, 6, pal["skin"])
    # 高光
    rect(draw, 10, base_y-4, 4, 3, pal["skin_hi"])
    rect(draw, 12, base_y-5, 2, 2, pal["skin_hi"])
    # 阴影 (底部)
    rect(draw, 8, base_y+5, 16, 1, pal["skin_sh"])
    rect(draw, 9, base_y+6, 14, 1, pal["skin_sh"])
    
    if direction == 0:  # 下 - 正脸
        # 眼睛 (大圆眼)
        rect(draw, 11, base_y-1, 3, 4, "#fff")
        rect(draw, 18, base_y-1, 3, 4, "#fff")
        rect(draw, 12, base_y, 2, 3, pal["eye"])
        rect(draw, 19, base_y, 2, 3, pal["eye"])
        rect(draw, 12, base_y-1, 1, 1, "#fff")
        rect(draw, 19, base_y-1, 1, 1, "#fff")
        # 嘴巴 (微笑)
        rect(draw, 14, base_y+5, 4, 1, o)
        rect(draw, 15, base_y+6, 2, 1, o)
        
    elif direction == 1:  # 左
        rect(draw, 10, base_y-1, 3, 4, "#fff")
        rect(draw, 11, base_y, 2, 3, pal["eye"])
        rect(draw, 11, base_y-1, 1, 1, "#fff")
        rect(draw, 14, base_y+5, 3, 1, o)
        
    elif direction == 2:  # 右
        rect(draw, 19, base_y-1, 3, 4, "#fff")
        rect(draw, 20, base_y, 2, 3, pal["eye"])
        rect(draw, 20, base_y-1, 1, 1, "#fff")
        rect(draw, 15, base_y+5, 3, 1, o)
        
    else:  # 上 - 后脑勺
        # 看不到眼睛，只有身体顶部 + 一个小点
        rect(draw, 15, base_y-2, 2, 1, pal["skin_sh"])
    
    # 外轮廓
    outline_ellipse(draw, 10, base_y-5, 12, 8, o)


def draw_demon(draw, frame, pal):
    """深渊恶魔 - 犄角+爪"""
    direction = frame // 4
    step = frame % 4
    step_off = [0, 1, 0, -1][step]
    o = pal["outline"]
    
    if direction == 0:
        # 犄角 (头上方)
        rect(draw, 10, -2, 2, 4, pal["horn"])
        rect(draw, 9, -6, 2, 6, pal["horn"])
        rect(draw, 20, -2, 2, 4, pal["horn"])
        rect(draw, 21, -6, 2, 6, pal["horn"])
        # 头
        rect(draw, 11, 2, 10, 9, pal["skin"])
        # 眼睛 (黄竖瞳)
        px(draw, 13, 5, o); px(draw, 14, 5, pal["eye"]); px(draw, 14, 6, pal["eye"]); px(draw, 14, 7, pal["eye"]); px(draw, 14, 8, pal["eye"])
        px(draw, 18, 5, o); px(draw, 17, 5, pal["eye"]); px(draw, 17, 6, pal["eye"]); px(draw, 17, 7, pal["eye"]); px(draw, 17, 8, pal["eye"])
        # 獠牙嘴
        rect(draw, 12, 9, 8, 2, o)
        px(draw, 13, 9, "#fff")  # 獠牙
        px(draw, 18, 9, "#fff")
        # 身体 (肌肉)
        rect(draw, 8, 11, 16, 13, pal["skin"])
        rect(draw, 8, 11, 16, 1, pal["skin_hi"])
        rect(draw, 8, 22, 16, 1, pal["skin_sh"])
        # 腹部阴影
        rect(draw, 11, 14, 10, 8, pal["skin_sh"])
        # 手臂 + 爪
        rect(draw, 3, 12, 5, 10, pal["skin"])
        rect(draw, 24, 12, 5, 10, pal["skin"])
        # 爪子
        px(draw, 3, 21, pal["claw"]); px(draw, 5, 22, pal["claw"]); px(draw, 7, 21, pal["claw"])
        px(draw, 24, 21, pal["claw"]); px(draw, 26, 22, pal["claw"]); px(draw, 28, 21, pal["claw"])
        # 腿
        rect(draw, 10, 24-step_off, 5, 5, pal["skin"])
        rect(draw, 17, 24+step_off, 5, 5, pal["skin"])
        rect(draw, 9, 29-step_off, 7, 2, o)
        rect(draw, 16, 29+step_off, 7, 2, o)
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 10, -2, 2, 4, pal["horn"])
        rect(draw, 9, -6, 2, 6, pal["horn"])
        rect(draw, 20, -2, 2, 4, pal["horn"])
        rect(draw, 21, -6, 2, 6, pal["horn"])
        rect(draw, 11, 2, 10, 9, pal["skin"])
        px(draw, 13, 5, o); px(draw, 14, 5, pal["eye"]); px(draw, 14, 6, pal["eye"]); px(draw, 14, 7, pal["eye"]); px(draw, 14, 8, pal["eye"])
        rect(draw, 8, 11, 16, 13, pal["skin"])
        rect(draw, 11, 14, 10, 8, pal["skin_sh"])
        rect(draw, 3, 12, 5, 10, pal["skin"])
        rect(draw, 24, 12, 5, 10, pal["skin"])
        px(draw, 3, 21, pal["claw"]); px(draw, 5, 22, pal["claw"])
        rect(draw, 10, 24+step_off, 5, 5, pal["skin"])
        rect(draw, 17, 24-step_off, 5, 5, pal["skin"])
        rect(draw, 9, 29+step_off, 7, 2, o)
        rect(draw, 16, 29-step_off, 7, 2, o)
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 10, -2, 2, 4, pal["horn"])
        rect(draw, 9, -6, 2, 6, pal["horn"])
        rect(draw, 20, -2, 2, 4, pal["horn"])
        rect(draw, 21, -6, 2, 6, pal["horn"])
        rect(draw, 11, 2, 10, 9, pal["skin"])
        px(draw, 18, 5, o); px(draw, 17, 5, pal["eye"]); px(draw, 17, 6, pal["eye"]); px(draw, 17, 7, pal["eye"]); px(draw, 17, 8, pal["eye"])
        rect(draw, 8, 11, 16, 13, pal["skin"])
        rect(draw, 11, 14, 10, 8, pal["skin_sh"])
        rect(draw, 3, 12, 5, 10, pal["skin"])
        rect(draw, 24, 12, 5, 10, pal["skin"])
        px(draw, 28, 21, pal["claw"]); px(draw, 26, 22, pal["claw"])
        rect(draw, 10, 24-step_off, 5, 5, pal["skin"])
        rect(draw, 17, 24+step_off, 5, 5, pal["skin"])
        rect(draw, 9, 29-step_off, 7, 2, o)
        rect(draw, 16, 29+step_off, 7, 2, o)
        
    else:  # 上
        step_off = [0, 1, 0, -1][step]
        rect(draw, 10, -2, 2, 4, pal["horn"])
        rect(draw, 9, -6, 2, 6, pal["horn"])
        rect(draw, 20, -2, 2, 4, pal["horn"])
        rect(draw, 21, -6, 2, 6, pal["horn"])
        rect(draw, 11, 2, 10, 8, pal["skin"])
        rect(draw, 11, 4, 10, 3, pal["skin_sh"])
        rect(draw, 8, 11, 16, 13, pal["skin"])
        rect(draw, 8, 11, 16, 1, pal["skin_hi"])
        rect(draw, 3, 12, 5, 10, pal["skin"])
        rect(draw, 24, 12, 5, 10, pal["skin"])
        rect(draw, 10, 24-step_off, 5, 5, pal["skin"])
        rect(draw, 17, 24+step_off, 5, 5, pal["skin"])


def draw_ghost(draw, frame, pal):
    """幽灵 - 飘浮"""
    direction = frame // 4
    step = frame % 4
    float_y = [0, -1, 0, 1][step]  # 上下飘浮
    o = pal["outline"]
    
    # 幽灵身体 (钟形)
    base_y = 12 + float_y
    # 上半 (圆形头)
    rect(draw, 10, base_y, 12, 10, pal["skin"])
    rect(draw, 9, base_y+2, 14, 8, pal["skin"])
    rect(draw, 8, base_y+4, 16, 6, pal["skin"])
    # 下半 (波浪边)
    for i in range(4):
        bob_y = base_y + 14 + (step % 2) * 2
        rect(draw, 8+i*4, bob_y, 3, 4, pal["skin"])
    
    # 眼睛 (空洞)
    rect(draw, 12, base_y+4, 2, 3, pal["eye"])
    rect(draw, 18, base_y+4, 2, 3, pal["eye"])
    rect(draw, 12, base_y+4, 2, 1, "#a0a0ff")
    rect(draw, 18, base_y+4, 2, 1, "#a0a0ff")
    
    # 嘴 (小O)
    rect(draw, 14, base_y+9, 4, 2, pal["eye"])
    rect(draw, 15, base_y+10, 2, 1, pal["skin"])
    
    # 高光
    rect(draw, 11, base_y+1, 3, 2, pal["skin_hi"])
    rect(draw, 13, base_y, 1, 1, pal["skin_hi"])
    
    # 透明度边缘效果 (淡色)
    rect(draw, 7, base_y+6, 1, 10, pal["skin_sh"])
    rect(draw, 24, base_y+6, 1, 10, pal["skin_sh"])


def draw_skeleton(draw, frame, pal):
    """骷髅战士"""
    direction = frame // 4
    step = frame % 4
    step_off = [0, 1, 0, -1][step]
    o = pal["outline"]
    
    if direction == 0:
        # 头骨
        rect(draw, 11, 2, 10, 9, pal["bone"])
        rect(draw, 12, 3, 8, 1, pal["bone_sh"])
        # 眼眶 (黑)
        rect(draw, 12, 5, 3, 3, o)
        rect(draw, 17, 5, 3, 3, o)
        # 红眼
        px(draw, 13, 6, pal["eye"])
        px(draw, 18, 6, pal["eye"])
        # 牙齿
        rect(draw, 12, 8, 8, 3, o)
        for i in range(4):
            px(draw, 13+i*2, 8, pal["bone"])
            px(draw, 13+i*2, 9, pal["bone"])
        # 空洞鼻子
        px(draw, 15, 6, o)
        px(draw, 16, 6, o)
        # 身体裹布
        rect(draw, 9, 11, 14, 11, pal["cloth"])
        rect(draw, 9, 11, 14, 1, pal["bone_sh"])
        # 剑带
        rect(draw, 11, 20, 10, 2, "#654321")
        # 肋骨可见
        rect(draw, 11, 13, 10, 1, pal["bone_sh"])
        rect(draw, 12, 15, 8, 1, pal["bone_sh"])
        rect(draw, 11, 17, 10, 1, pal["bone_sh"])
        # 手臂 (骨头)
        rect(draw, 5, 12, 4, 9, pal["bone"])
        rect(draw, 23, 12, 4, 9, pal["bone"])
        rect(draw, 5, 12, 4, 1, pal["bone_sh"])
        rect(draw, 23, 12, 4, 1, pal["bone_sh"])
        # 剑
        rect(draw, 26, 2, 2, 12, pal["sword"])
        rect(draw, 25, 14, 4, 1, "#654321")
        rect(draw, 26, 15, 2, 3, "#654321")
        # 腿
        rect(draw, 11, 22-step_off, 4, 7, pal["bone"])
        rect(draw, 17, 22+step_off, 4, 7, pal["bone"])
        rect(draw, 9, 29-step_off, 6, 2, pal["bone"])
        rect(draw, 17, 29+step_off, 6, 2, pal["bone"])
        
    elif direction == 1:
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 11, 2, 10, 9, pal["bone"])
        rect(draw, 13, 5, 3, 3, o)
        px(draw, 14, 6, pal["eye"])
        rect(draw, 12, 8, 6, 3, o)
        for i in range(3):
            px(draw, 13+i*2, 8, pal["bone"])
        rect(draw, 9, 11, 14, 11, pal["cloth"])
        rect(draw, 11, 13, 10, 1, pal["bone_sh"])
        rect(draw, 11, 17, 10, 1, pal["bone_sh"])
        rect(draw, 11, 20, 10, 2, "#654321")
        rect(draw, 4, 13, 5, 8, pal["bone"])
        rect(draw, 23, 13, 4, 8, pal["bone"])
        # 剑朝前
        rect(draw, -2, 14, 8, 2, pal["sword"])
        rect(draw, 4, 13, 2, 4, "#654321")
        rect(draw, 11, 22+step_off, 4, 7, pal["bone"])
        rect(draw, 17, 22-step_off, 4, 7, pal["bone"])
        rect(draw, 9, 29+step_off, 6, 2, pal["bone"])
        rect(draw, 17, 29-step_off, 6, 2, pal["bone"])
        
    elif direction == 2:
        step_off = [-1, 0, 1, 0][step]
        rect(draw, 11, 2, 10, 9, pal["bone"])
        rect(draw, 16, 5, 3, 3, o)
        px(draw, 17, 6, pal["eye"])
        rect(draw, 14, 8, 6, 3, o)
        for i in range(3):
            px(draw, 15+i*2, 8, pal["bone"])
        rect(draw, 9, 11, 14, 11, pal["cloth"])
        rect(draw, 11, 13, 10, 1, pal["bone_sh"])
        rect(draw, 11, 17, 10, 1, pal["bone_sh"])
        rect(draw, 11, 20, 10, 2, "#654321")
        rect(draw, 4, 13, 4, 8, pal["bone"])
        rect(draw, 23, 13, 5, 8, pal["bone"])
        rect(draw, 26, 14, 8, 2, pal["sword"])
        rect(draw, 26, 13, 2, 4, "#654321")
        rect(draw, 11, 22-step_off, 4, 7, pal["bone"])
        rect(draw, 17, 22+step_off, 4, 7, pal["bone"])
        rect(draw, 9, 29-step_off, 6, 2, pal["bone"])
        rect(draw, 17, 29+step_off, 6, 2, pal["bone"])
        
    else:  # 上
        step_off = [0, 1, 0, -1][step]
        rect(draw, 11, 2, 10, 9, pal["bone"])
        rect(draw, 9, 11, 14, 11, pal["cloth"])
        rect(draw, 11, 20, 10, 2, "#654321")
        rect(draw, 5, 12, 4, 9, pal["bone"])
        rect(draw, 23, 12, 4, 9, pal["bone"])
        rect(draw, 26, 2, 2, 10, pal["sword"])
        rect(draw, 11, 22-step_off, 4, 7, pal["bone"])
        rect(draw, 17, 22+step_off, 4, 7, pal["bone"])


# ========== 辅助函数 ==========

def outline_rect(draw, x, y, w, h, color):
    """画矩形轮廓 (深色描边)"""
    rect(draw, x, y, w, 1, color)
    rect(draw, x, y+h-1, w, 1, color)
    rect(draw, x, y, 1, h, color)
    rect(draw, x+w-1, y, 1, h, color)

def outline_ellipse(draw, cx, cy, rx, ry, color):
    """简单椭圆轮廓"""
    points = []
    for i in range(360):
        import math
        x = int(cx + rx * math.cos(i * math.pi / 180))
        y = int(cy + ry * math.sin(i * math.pi / 180))
        points.append((x, y))
    draw.point(points, fill=color)


# ========== 主生成 ==========

CHARACTERS = {
    "player_warrior": (draw_warrior, PALETTES["warrior"]),
    "player_mage": (draw_mage, PALETTES["mage"]),
    "player_archer": (draw_archer, PALETTES["archer"]),
    "player_knight": (draw_warrior, PALETTES["knight"]),  # 复用战士绘制 + 白金配色
    "enemy_slime": (draw_slime, PALETTES["slime"]),
    "enemy_demon": (draw_demon, PALETTES["demon"]),
    "enemy_ghost": (draw_ghost, PALETTES["ghost"]),
    "enemy_skeleton": (draw_skeleton, PALETTES["skeleton"])
}

for name, (draw_func, pal) in CHARACTERS.items():
    sheet = Image.new('RGBA', (SHEET, SHEET), (0, 0, 0, 0))
    
    # 补全调色板缺失的键 (使用 warrior 作为默认基底)
    defaults = PALETTES["warrior"]
    for k, v in defaults.items():
        pal.setdefault(k, v)
    pal.setdefault("tunic", pal.get("body", pal["skin"]))
    pal.setdefault("tunic_sh", pal.get("armor_sh", "#555"))
    pal.setdefault("tunic_hi", pal.get("armor_hi", "#999"))
    pal.setdefault("leather", "#654321")
    pal.setdefault("bow", "#8b4513")
    pal.setdefault("crystal", "#00d4ff")
    pal.setdefault("horn", pal.get("hair", "#1a1a1a"))
    pal.setdefault("claw", "#ff4400")
    pal.setdefault("bone_sh", "#a0a090")
    pal.setdefault("cloth", "#404040")
    pal.setdefault("sword", "#808080")
    pal.setdefault("hilt", "#654321")
    pal.setdefault("boot", "#2d2d2d")
    pal.setdefault("staff", "#8b4513")
    
    for frame in range(16):
        col = frame % GRID
        row = frame // GRID
        
        # 创建单帧画布
        frame_img = Image.new('RGBA', (FRAME, FRAME), (0, 0, 0, 0))
        frame_draw = ImageDraw.Draw(frame_img)
        
        # 绘制
        draw_func(frame_draw, frame, pal)
        
        # 粘贴到 sheet
        sheet.paste(frame_img, (col * FRAME, row * FRAME), frame_img)
    
    out_path = os.path.join(OUTPUT_DIR, f"{name}.png")
    sheet.save(out_path)
    print(f"✅ {name}.png  ({SHEET}x{SHEET}, 4x4网格, 16帧)")

print(f"\n全部完成! 输出目录: {OUTPUT_DIR}")
