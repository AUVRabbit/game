#!/usr/bin/env python3
"""
v8 — 角色立绘卡 (Character Illustration Card)

用项目现有肖像图 + PIL 立绘化后期处理:
  1. 背景去除 (反向 flood fill)
  2. 动态光影增强 (顶光 + 侧光 + 环境光)
  3. 角色卡外框 (金属边框 + 内阴影)
  4. 标签区 (职业名/武器/技能/属性条)
  5. 底部光晕 + 粒子点缀
"""
import os, math, colorsys
from PIL import Image, ImageDraw, ImageFilter

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/CHARACTER_ILLUSTRATION_v8"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 背景去除 (反向 flood fill, 和 v6 相同逻辑)
# ============================================================
def remove_bg(img, color_tol=6):
    from collections import deque
    arr = img.convert("RGBA").load()
    w, h = img.size
    
    # 估计背景色
    edge_rs, edge_gs, edge_bs = [], [], []
    for x in range(w):
        for y in [0, h-1]:
            edge_rs.append(arr[x,y][0]); edge_gs.append(arr[x,y][1]); edge_bs.append(arr[x,y][2])
    for y in range(1, h-1):
        for x in [0, w-1]:
            edge_rs.append(arr[x,y][0]); edge_gs.append(arr[x,y][1]); edge_bs.append(arr[x,y][2])
    import statistics as st
    bg = (int(st.median(edge_rs)), int(st.median(edge_gs)), int(st.median(edge_bs)))
    
    is_bg = [[False]*h for _ in range(w)]
    q = deque()
    for x in range(w): q.append((x,0)); q.append((x,h-1))
    for y in range(h): q.append((0,y)); q.append((w-1,y))
    while q:
        x, y = q.popleft()
        if is_bg[x][y]: continue
        r,g,b,a = arr[x,y]
        if (abs(r-bg[0])<=color_tol and abs(g-bg[1])<=color_tol and abs(b-bg[2])<=color_tol):
            is_bg[x][y] = True
            for dx2,dy2 in [(1,0),(-1,0),(0,1),(0,-1)]:
                nx,ny = x+dx2, y+dy2
                if 0<=nx<w and 0<=ny<h and not is_bg[nx][ny]: q.append((nx,ny))
    
    out = Image.new("RGBA", (w, h), (0,0,0,0))
    oarr = out.load()
    for y in range(h):
        for x in range(w):
            if not is_bg[x][y]:
                oarr[x,y] = arr[x,y]
    return out, bg

# ============================================================
# 光影增强
# ============================================================
def enhance_lighting(img_rgba, light_dir=(0.3, -0.5), ambient=0.35):
    """
    模拟 Diablo 风格硬阴影 + 高光
    light_dir: 光照方向 (dx,dy), 相对角色中心
    ambient: 环境光强度 0-1
    """
    w, h = img_rgba.size
    arr = img_rgba.load()
    
    # 1. 计算深度 (简化: 非背景像素的亮度作为深度 proxy)
    depth = [[0.0]*h for _ in range(w)]
    for y in range(h):
        for x in range(w):
            r,g,b,a = arr[x,y]
            if a > 30:
                depth[x][y] = (r + g + b) / 3.0 / 255.0
    
    # 2. 法线近似 (Sobel-like)
    normal_x = [[0.0]*h for _ in range(w)]
    normal_y = [[0.0]*h for _ in range(w)]
    for y in range(1, h-1):
        for x in range(1, w-1):
            normal_x[x][y] = depth[x+1][y] - depth[x-1][y]
            normal_y[x][y] = depth[x][y+1] - depth[x][y-1]
    
    # 3. Blinn-Phong 光照
    out_img = Image.new("RGBA", (w, h), (0,0,0,0))
    oarr = out_img.load()
    
    lx, ly, lz = light_dir[0], light_dir[1], 1.0
    llen = math.hypot(lx, ly, lz)
    lx /= llen; ly /= llen; lz /= llen
    
    for y in range(h):
        for x in range(w):
            r,g,b,a = arr[x,y]
            if a < 20: continue
            
            # 光照强度
            nx = normal_x[x][y]
            ny = normal_y[x][y]
            nlen = math.hypot(nx, ny, 1.0) + 0.001
            nx /= nlen; ny /= nlen
            dot = max(0.0, nx*lx + ny*ly + 1.0*lz / nlen)
            
            # 环境光 + 漫反射
            intensity = ambient + (1 - ambient) * dot
            intensity = 0.4 + intensity * 0.8  # 压缩范围
            
            # 高光
            spec = max(0.0, dot) ** 20.0 * 0.4
            
            nr = min(255, int(r * intensity + 255 * spec))
            ng = min(255, int(g * intensity + 255 * spec))
            nb = min(255, int(b * intensity + 255 * spec))
            
            oarr[x,y] = (nr, ng, nb, a)
    
    return out_img

# ============================================================
# 立绘卡组装
# ============================================================

# 肖像 → 职业映射 (项目 assets/portraits/ 实际文件名)
PORTRAITS = {
    "barbarian": "warrior",
    "sorceress": "mage", 
    "amazon": "archer",
    "assassin": "thief",
}

# 职业配置
CLASS_CARD = {
    "barbarian": {
        "cn": "野蛮人", "weapon": "巨剑", "skill": "旋风斩",
        "title": "征服之王",
        "theme_bg": (60, 18, 18),    # 暗红渐变顶
        "theme_mid": (30, 12, 14),
        "theme_bot": (18, 10, 12),
        "theme_accent": (230, 50, 50),
        "theme_gold": (200, 140, 40),
        "stats": {"生命": 95, "攻击": 92, "防御": 78, "速度": 55},
        "desc": "挥舞巨剑横扫战场的狂战士, 每一次劈砍都带着毁天灭地的怒火。",
        "icon": "⚔",
    },
    "sorceress": {
        "cn": "女巫", "weapon": "法杖", "skill": "陨石术",
        "title": "秘法之主",
        "theme_bg": (18, 22, 60),
        "theme_mid": (12, 14, 40),
        "theme_bot": (8, 10, 28),
        "theme_accent": (80, 180, 255),
        "theme_gold": (180, 200, 255),
        "stats": {"法力": 98, "法术": 95, "防御": 42, "速度": 68},
        "desc": "召唤陨石从天而降的奥术大师, 法杖顶端的蓝宝石蕴含着远古力量。",
        "icon": "🔮",
    },
    "amazon": {
        "cn": "亚马逊", "weapon": "长弓", "skill": "多重射击",
        "title": "森林守卫",
        "theme_bg": (28, 50, 22),
        "theme_mid": (16, 30, 14),
        "theme_bot": (10, 18, 10),
        "theme_accent": (180, 220, 100),
        "theme_gold": (200, 180, 100),
        "stats": {"生命": 72, "攻击": 80, "防御": 55, "速度": 85},
        "desc": "百步穿杨的神射手, 一箭可同时贯穿数名敌人, 箭无虚发。",
        "icon": "🏹",
    },
    "assassin": {
        "cn": "刺客", "weapon": "双匕", "skill": "影袭",
        "title": "暗影行者",
        "theme_bg": (22, 20, 28),
        "theme_mid": (14, 12, 18),
        "theme_bot": (8, 8, 12),
        "theme_accent": (200, 170, 60),
        "theme_gold": (220, 190, 70),
        "stats": {"生命": 58, "攻击": 88, "防御": 38, "速度": 95},
        "desc": "来无影去无踪的暗影杀手, 双匕划过敌人咽喉时对方才察觉死亡临近。",
        "icon": "🗡",
    },
}

def draw_card(cls_key, portrait_path, out_path):
    """给一个职业画一张立绘卡"""
    cfg = CLASS_CARD[cls_key]
    
    # 画布: 720 × 960
    CW, CH = 720, 960
    canvas = Image.new("RGB", (CW, CH), cfg["theme_bot"])
    draw = ImageDraw.Draw(canvas)
    
    # === 1. 背景渐变 + 纹理 ===
    for y in range(CH):
        t = y / CH
        r = int(cfg["theme_bg"][0]*(1-t) + cfg["theme_bot"][0]*t)
        g = int(cfg["theme_bg"][1]*(1-t) + cfg["theme_bot"][1]*t)
        b = int(cfg["theme_bg"][2]*(1-t) + cfg["theme_bot"][2]*t)
        draw.line([(0, y), (CW, y)], fill=(r, g, b))
    
    # 暗角 vignette
    vignette = Image.new("L", (CW, CH), 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse([-100, -100, CW+100, CH+100], fill=255)
    vignette = vignette.filter(ImageFilter.GaussianBlur(radius=60))
    import numpy as np
    vig_arr = np.array(vignette) / 255.0 * 0.3
    can_arr = np.array(canvas).astype(float)
    for c in range(3):
        can_arr[:,:,c] *= (1.0 - vig_arr)
    canvas = Image.fromarray(can_arr.clip(0,255).astype(np.uint8))
    draw = ImageDraw.Draw(canvas)
    
    # === 2. 顶部标题栏 ===
    draw.rectangle([0, 0, CW, 72], fill=(0,0,0))
    draw.rectangle([0, 68, CW, 72], fill=cfg["theme_accent"])
    # 标题文字
    draw.text((24, 16), f"DIABLO · {cfg['icon']}  {cfg['cn']}", fill=(240,235,220))
    draw.text((24, 46), cfg["title"], fill=cfg["theme_gold"])
    # 右上角等级牌
    draw.rectangle([CW-120, 12, CW-20, 60], outline=cfg["theme_gold"], width=2)
    draw.text((CW-108, 20), "LV. 30", fill=(255,255,255))
    draw.text((CW-108, 38), "精英", fill=cfg["theme_accent"])
    
    # === 3. 角色立绘区 (居中, 宽 480) ===
    PORTRAIT_W, PORTRAIT_H = 480, 540
    px0 = (CW - PORTRAIT_W) // 2
    py0 = 88
    
    # 角色区外框
    draw.rectangle([px0-4, py0-4, px0+PORTRAIT_W+4, py0+PORTRAIT_H+4],
                   outline=cfg["theme_gold"], width=3)
    
    # 加载肖像, 抠背景
    portrait = Image.open(portrait_path).convert("RGBA")
    portrait_alpha, _ = remove_bg(portrait)
    
    # 光影增强
    portrait_enhanced = enhance_lighting(portrait_alpha, light_dir=(0.25, -0.4), ambient=0.38)
    
    # 缩放到 portrait 区
    pa = portrait_enhanced.resize((PORTRAIT_W, PORTRAIT_H), Image.LANCZOS)
    
    # 角色区背景 (深色渐变)
    role_bg = Image.new("RGB", (PORTRAIT_W, PORTRAIT_H), cfg["theme_bot"])
    rb = ImageDraw.Draw(role_bg)
    for y in range(PORTRAIT_H):
        t = y / PORTRAIT_H
        r = int(cfg["theme_mid"][0]*(1-t) + cfg["theme_bot"][0]*t)
        g = int(cfg["theme_mid"][1]*(1-t) + cfg["theme_bot"][1]*t)
        b = int(cfg["theme_mid"][2]*(1-t) + cfg["theme_bot"][2]*t)
        rb.line([(0, y), (PORTRAIT_W, y)], fill=(r, g, b))
    
    # 光晕
    from PIL import ImageFilter as IF
    glow_layer = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (0,0,0,0))
    gd = ImageDraw.Draw(glow_layer)
    # 从肖像 alpha 提取整体轮廓
    glow_arr = pa.split()[3]  # alpha channel
    glow_arr = glow_arr.point(lambda x: 255 if x > 30 else 0)
    glow_arr = glow_arr.filter(ImageFilter.GaussianBlur(radius=25))
    glow_rgba = Image.new("RGBA", (PORTRAIT_W, PORTRAIT_H), (*cfg["theme_accent"], 0))
    glow_rgba.putalpha(glow_arr.point(lambda x: min(200, x)))
    
    role_bg.paste(glow_rgba, (0, 0), glow_rgba)
    role_bg.paste(pa, (0, 0), pa)
    
    canvas.paste(role_bg, (px0, py0))
    
    # 地面阴影
    ground_y = py0 + PORTRAIT_H - 20
    shadow_img = Image.new("RGBA", (PORTRAIT_W, 40), (0,0,0,0))
    sd = ImageDraw.Draw(shadow_img)
    sd.ellipse([30, 0, PORTRAIT_W-30, 36], fill=(0,0,0,100))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=12))
    canvas.paste(shadow_img, (px0, ground_y-20), shadow_img)
    
    # === 4. 信息区 ===
    INFO_Y = py0 + PORTRAIT_H + 24
    INFO_H = CH - INFO_Y - 24
    
    # 技能卡
    skill_x = 24
    skill_y = INFO_Y
    draw.rectangle([skill_x, skill_y, skill_x+320, skill_y+70], 
                   outline=cfg["theme_gold"], width=2)
    draw.rectangle([skill_x, skill_y, skill_x+64, skill_y+70], fill=cfg["theme_accent"])
    # 技能图标 (简单几何)
    sd2 = ImageDraw.Draw(canvas)
    if cls_key == "barbarian":
        # 旋转剑
        sd2.arc([skill_x+14, skill_y+14, skill_x+50, skill_y+50], 0, 360, fill=(255,255,255), width=3)
        sd2.line([(skill_x+32, skill_y+18), (skill_x+48, skill_y+52)], fill=(255,255,255), width=3)
    elif cls_key == "sorceress":
        # 火焰
        sd2.ellipse([skill_x+20, skill_y+22, skill_x+44, skill_y+50], fill=(255,200,50))
        sd2.polygon([(skill_x+22, skill_y+50),(skill_x+32, skill_y+14),(skill_x+42, skill_y+50)], fill=(255,120,30))
    elif cls_key == "amazon":
        # 弓
        sd2.arc([skill_x+10, skill_y+18, skill_x+54, skill_y+56], 220, 320, fill=(255,255,255), width=3)
        sd2.line([(skill_x+12, skill_y+24), (skill_x+52, skill_y+50)], fill=(255,255,255))
    elif cls_key == "assassin":
        # 匕
        sd2.polygon([(skill_x+18, skill_y+50),(skill_x+32, skill_y+14),(skill_x+46, skill_y+50)], fill=(200,200,210), outline=(100,100,120))
    
    draw.text((skill_x+76, skill_y+10), cfg["skill"], fill=cfg["theme_gold"])
    draw.text((skill_x+76, skill_y+32), f"{cfg['weapon']}  ·  主动技能", fill=(180,185,200))
    draw.text((skill_x+76, skill_y+52), "冷却 12s  ·  范围 360°", fill=(130,135,150))
    
    # 属性条 (右侧)
    stat_x = CW - 24 - 320
    stat_y = INFO_Y
    draw.text((stat_x, stat_y), "属性面板", fill=cfg["theme_gold"])
    
    for i, (stat_name, val) in enumerate(cfg["stats"].items()):
        sy = stat_y + 24 + i * 34
        draw.text((stat_x, sy), stat_name, fill=(200,205,215))
        draw.rectangle([stat_x+60, sy+4, stat_x+60+200, sy+18], fill=(20,22,32))
        w = int(val * 2.0)
        draw.rectangle([stat_x+60, sy+4, stat_x+60+w, sy+18], 
                       fill=cfg["theme_accent"])
        draw.text((stat_x+60+w+6, sy+2), str(val), fill=(200,205,215))
    
    # === 5. 底部描述 ===
    desc_y = CH - 90
    draw.rectangle([24, desc_y-8, CW-24, desc_y+60], fill=(0,0,0))
    draw.rectangle([24, desc_y-8, CW-24, desc_y-6], fill=cfg["theme_accent"])
    draw.text((36, desc_y), cfg["title"], fill=cfg["theme_gold"])
    # 描述自动换行
    desc = cfg["desc"]
    max_chars = 48
    lines = [desc[i:i+max_chars] for i in range(0, len(desc), max_chars)]
    for li, line in enumerate(lines):
        draw.text((36, desc_y + 20 + li*18), line, fill=(160,165,180))
    
    canvas.save(out_path, "JPEG", quality=92)
    return canvas

# ============================================================
# 主流程
# ============================================================

PORTRAIT_DIR = f"{PROJ}/assets/portraits"

print("=" * 60)
print("v8 — 角色立绘卡 (Character Illustration Card)")
print("     每职业 1 张完整立绘 + AI 光影增强 + 信息卡")
print("=" * 60)

cards = {}

for cls_key, portrait_file in PORTRAITS.items():
    cfg = CLASS_CARD[cls_key]
    pp = f"{PORTRAIT_DIR}/{portrait_file}.png"
    if not os.path.exists(pp):
        print(f"⚠ {cls_key} 肖像 ({pp}) 不存在, 跳过")
        continue
    
    print(f"\n─── {cfg['cn']} / {cfg['weapon']} ───")
    card = draw_card(cls_key, pp, f"{OUT}/{cls_key}_card.jpg")
    cards[cls_key] = card
    print(f"  ✓ {cls_key}_card.jpg 完成")

# === 2×2 总览 ===
COLS, ROWS = 2, 2
TW, TH = 360, 480
MAR = 24
sw = COLS*TW + (COLS+1)*MAR
sh = ROWS*TH + (ROWS+1)*MAR + 60
ov = Image.new("RGB", (sw, sh), (5, 6, 12))
d = ImageDraw.Draw(ov)
d.text((MAR, 20), "⚔ Diablo 风格角色立绘卡 · Character Illustration Cards", fill=(230, 60, 60))
d.text((MAR, 42), "AI 光影增强 · 反向 flood fill 抠图 · 金属边框 · 属性面板", fill=(120, 140, 170))

for idx, cls_key in enumerate(cards):
    r, c = divmod(idx, COLS)
    sx = MAR + c*(TW+MAR)
    sy = 60 + MAR + r*(TH+MAR)
    src = cards[cls_key]
    crop = src.crop((0, 0, src.size[0], src.size[1]))
    # 缩放到卡片格
    cw, ch = crop.size
    scale = min(TW/cw, TH/ch) * 0.95
    new_size = (int(cw*scale), int(ch*scale))
    crop = crop.resize(new_size, Image.BILINEAR)
    cx = sx + (TW - new_size[0])//2
    cy = sy + (TH - new_size[1])//2
    ov.paste(crop, (cx, cy))
    d.rectangle([sx, sy, sx+TW, sy+TH], outline=(80,90,110), width=1)

ov.save(f"{OUT}/overview_lihui.jpg", "JPEG", quality=92)
print(f"\n✓ 总览 overview_lihui.jpg: {sw}×{sh}")
print(f"\n全部完成! 输出: {OUT}/")
