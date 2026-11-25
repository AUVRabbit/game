#!/usr/bin/env python3
"""
Diablo v3 — 修复版
核心改进:
  - 背景去除用更鲁棒的颜色阈值 + flood fill
  - 固定比例 bbox 切部件 (所有肖像共享同一模板, 这是确定的)
  - 消除 offset bug
"""
import os, math, json, collections
from PIL import Image, ImageDraw

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/RIGGED_V3_SAMPLES_2026-11-25"
PARTS_OUT = f"{OUT}/parts"
os.makedirs(PARTS_OUT, exist_ok=True)

# ============================================================
# Step 1: 背景去除 — 更鲁棒的方法
# ============================================================

def remove_dark_background(img, bg_threshold=35):
    """
    深色背景 → 角色 alpha mask
    用更宽松的阈值, 然后只保留从图像内部 seed 能到达的非背景像素
    """
    arr = img.convert("RGBA").load()
    w, h = img.size
    
    # 1. 标记所有非背景像素 (R+G+B > threshold)
    is_fg = [[False]*h for _ in range(w)]
    for y in range(h):
        for x in range(w):
            r,g,b,a = arr[x,y]
            if r + g + b >= bg_threshold:
                is_fg[x][y] = True
    
    # 2. flood fill 从四边标记背景 (应该很少, 因为大部分四边是深色)
    # 但为了鲁棒, 从图像四角中心位置找 seed 前景点
    cx, cy = w//2, h//2
    while cx > 0 and not is_fg[cx][cy]:
        cx -= 1
    while cy > 0 and not is_fg[cx][cy]:
        cy -= 1
    
    # 3. 从内部 seed 开始标记所有连通的前景像素
    visited = [[False]*h for _ in range(w)]
    stack = [(cx, cy)]
    while stack:
        x, y = stack.pop()
        if x<0 or y<0 or x>=w or y>=h: continue
        if visited[x][y] or not is_fg[x][y]: continue
        visited[x][y] = True
        stack += [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]
    
    mask = Image.new("L", (w, h), 0)
    marr = mask.load()
    for y in range(h):
        for x in range(w):
            if visited[x][y]:
                marr[x,y] = 255
    
    return mask

# ============================================================
# Step 2: 切部件 — 固定比例模板 (所有肖像共享)
# ============================================================

# 肖像模板: 所有 16 个职业都用这个 (512×512)
# 角色中心在 x=256, 肩 y~130, 胯 y~273, 脚 y~460
# 部件切框 (世界坐标):
PART_TEMPLATES = {
    # name: (x1, y1, x2, y2) — 512×512 世界坐标
    "head":  (180,   0, 332, 170),
    "torso": (172, 135, 340, 300),
    "arm_l": (100, 130, 218, 310),   # 左臂 (画面左侧)
    "arm_r": (294, 130, 412, 310),   # 右臂
    "leg_l": (185, 285, 260, 512),
    "leg_r": (252, 285, 327, 512),
}

# 每个部件的世界锚点 (关节位置, 从模板来)
PART_ANCHORS_WORLD = {
    # 头部挂在脖子上
    "head":  (256, 165),   # 脖子
    "torso": (256, 165),   # 脖子 (parent = pelvis 上方)
    "arm_l": (210, 150),   # 左肩
    "arm_r": (302, 150),   # 右肩
    "leg_l": (225, 285),   # 左胯
    "leg_r": (287, 285),   # 右胯
}

def cut_part(img, mask, part_name, template_bbox, anchor_world):
    """从原始 img + mask 切出一个部件"""
    x1, y1, x2, y2 = template_bbox
    w, h = x2-x1, y2-y1
    
    # 在模板 bbox 内, 只保留 mask 覆盖的像素
    arr = img.convert("RGBA").load()
    marr = mask.load()
    
    result = Image.new("RGBA", (w, h), (0,0,0,0))
    rarr = result.load()
    
    for y in range(y1, y2):
        for x in range(x1, x2):
            if marr[x, y] == 255:
                r, g, b, a = arr[x, y]
                rarr[x-x1, y-y1] = (r, g, b, 255)
    
    # 进一步 trim 掉 bbox 内仍然透明的边缘 — 找最小包围盒
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if rarr[x, y][3] > 10:
                xs.append(x); ys.append(y)
    
    if not xs:
        return None, None, None
    
    bx1, bx2 = min(xs), max(xs)
    by1, by2 = min(ys), max(ys)
    trimmed = result.crop((bx1, by1, bx2+1, by2+1))
    
    # anchor_local = anchor_world - template_x1 - trim_x1
    anchor_local = (
        anchor_world[0] - x1 - bx1,
        anchor_world[1] - y1 - by1,
    )
    
    # anchor 在原始图上的位置 (用于后续关节计算)
    anchor_img = anchor_world
    
    return trimmed, anchor_local, anchor_img

# ============================================================
# Step 3: 关节定义
# ============================================================

# 所有职业共享的骨架 (因为肖像模板一样)
# 每个关节 = (世界坐标 x, 世界坐标 y, 相对 parent 的 anchor, rest_rot)
JOINTS_WORLD = {
    "pelvis": (256, 310),  # 骨盆 = 胯中心
    "torso":  (256, 165),  # 脖子
    "head":   (256, 100),  # 头中心 (相对脖子 anchor=(0,-65))
    "arm_l":  (210, 150),  # 左肩 (相对脖子 anchor=(-46,-15))
    "arm_r":  (302, 150),  # 右肩 (相对脖子 anchor=(46,-15))
    "leg_l":  (225, 285),  # 左胯 (相对 pelvis anchor=(-31,-25))
    "leg_r":  (287, 285),  # 右胯 (相对 pelvis anchor=(31,-25))
}

def compute_rel_anchors():
    """从世界坐标算相对 anchor"""
    parents = {
        "pelvis": None,
        "torso":  "pelvis",
        "head":   "torso",
        "arm_l":  "torso",
        "arm_r":  "torso",
        "leg_l":  "pelvis",
        "leg_r":  "pelvis",
    }
    rel = {}
    for name, parent in parents.items():
        if parent is None:
            rel[name] = (0, 0)
        else:
            px, py = JOINTS_WORLD[parent]
            cx, cy = JOINTS_WORLD[name]
            rel[name] = (cx - px, cy - py)
    return rel

REL_ANCHORS = compute_rel_anchors()

# ============================================================
# Step 4: 正向运动学 + 渲染 (修复 offset)
# ============================================================

def fk(rel_anchors, bone_rots, facing=1.0, base_pos=None):
    """
    rel_anchors: {name: (dx, dy)} — 相对 parent 的 anchor
    bone_rots:   {name: rot_deg} — 每个关节的当前旋转
    facing:      1.0 或 -1.0 (镜像)
    base_pos:    pelvis 的世界位置 (canvas 坐标)
    """
    parents = {
        "pelvis": None, "torso": "pelvis", "head": "torso",
        "arm_l": "torso", "arm_r": "torso",
        "leg_l": "pelvis", "leg_r": "pelvis",
    }
    if base_pos is None:
        base_pos = (300, 540)  # canvas 下方
    
    world = {}
    def calc(name):
        if name in world: return world[name]
        parent = parents[name]
        if parent is None:
            world[name] = (base_pos[0], base_pos[1], bone_rots.get(name, 0))
        else:
            pw = calc(parent)
            pwx, pwy, pwrot = pw
            local_dx, local_dy = rel_anchors[name]
            # 先应用 facing 到 anchor (让左臂在 facing<0 时变右臂位置)
            local_dx = local_dx * facing
            # 把 local anchor 旋转到 parent 的方向
            rad = math.radians(pwrot)
            wx = pwx + local_dx*math.cos(rad) - local_dy*math.sin(rad)
            wy = pwy + local_dx*math.sin(rad) + local_dy*math.cos(rad)
            wrot = pwrot + bone_rots.get(name, 0)
            world[name] = (wx, wy, wrot)
        return world[name]
    
    for name in rel_anchors:
        calc(name)
    return world

def render_parts(canvas, parts_images, transforms, facing=1.0):
    """把部件贴到 canvas 上"""
    # 画地面阴影
    d = ImageDraw.Draw(canvas)
    if "pelvis" in transforms:
        px, py, _ = transforms["pelvis"]
        d.ellipse([px-35, py+12, px+35, py+20], fill=(0,0,0,80) if canvas.mode=="RGBA" else (30,30,30))
    
    draw_order = ["leg_l", "leg_r", "torso", "arm_l", "arm_r", "head"]
    for name in draw_order:
        if name not in parts_images: continue
        pimg, anchor_local = parts_images[name]
        if pimg is None: continue
        
        wx, wy, wrot = transforms[name]
        
        # 构造扩展画布
        pw, ph = pimg.size
        diag = int(math.hypot(pw, ph)) + 16
        ext = Image.new("RGBA", (diag*2, diag*2), (0,0,0,0))
        # anchor_local = 部件内部 anchor 点 (在部件局部坐标里), 把它放到 ext 中心
        ax, ay = anchor_local
        ext.paste(pimg, (diag - ax, diag - ay), pimg)
        # 旋转
        angle = -wrot if facing == 1 else wrot
        ext = ext.rotate(angle, resample=Image.BILINEAR, expand=False, fillcolor=(0,0,0,0))
        if facing < 0:
            ext = ext.transpose(Image.FLIP_LEFT_RIGHT)
        # 贴到 canvas — world pos 就是 anchor 在 canvas 上的位置
        cx0 = int(wx - diag)
        cy0 = int(wy - diag)
        canvas.alpha_composite(ext, (cx0, cy0))

# ============================================================
# Step 5: 姿势定义
# ============================================================

ATTACK_POSES = {
    "warrior": [
        (0.0, {"pelvis":0, "torso":-2, "head":0, "arm_l":15, "arm_r":-85, "leg_l":0, "leg_r":0}),
        (0.45, {"pelvis":0, "torso":15, "head":6, "arm_l":-55, "arm_r":-168, "leg_l":-8, "leg_r":8}),
        (0.7,  {"pelvis":0, "torso":18, "head":8, "arm_l":-60, "arm_r":-175, "leg_l":-10, "leg_r":10}),
        (1.0,  {"pelvis":0, "torso":-2, "head":0, "arm_l":15, "arm_r":-85, "leg_l":0, "leg_r":0}),
    ],
    "mage": [
        (0.0, {"pelvis":0, "torso":0, "head":4, "arm_l":20, "arm_r":-20, "leg_l":0, "leg_r":0}),
        (0.5, {"pelvis":0, "torso":2, "head":10, "arm_l":95, "arm_r":-95, "leg_l":2, "leg_r":-2}),
        (0.75,{"pelvis":0, "torso":4, "head":14, "arm_l":110, "arm_r":-110, "leg_l":4, "leg_r":-4}),
        (1.0, {"pelvis":0, "torso":0, "head":4, "arm_l":20, "arm_r":-20, "leg_l":0, "leg_r":0}),
    ],
    "archer": [
        (0.0, {"pelvis":0, "torso":-3, "head":2, "arm_l":10, "arm_r":-10, "leg_l":0, "leg_r":0}),
        (0.4, {"pelvis":-6, "torso":6, "head":6, "arm_l":-20, "arm_r":40, "leg_l":4, "leg_r":-4}),
        (0.7, {"pelvis":-8, "torso":10, "head":5, "arm_l":-28, "arm_r":55, "leg_l":6, "leg_r":-6}),
        (1.0, {"pelvis":0, "torso":-3, "head":2, "arm_l":10, "arm_r":-10, "leg_l":0, "leg_r":0}),
    ],
    "death_knight": [
        (0.0, {"pelvis":0, "torso":-3, "head":-2, "arm_l":20, "arm_r":-90, "leg_l":0, "leg_r":0}),
        (0.4, {"pelvis":-10, "torso":25, "head":12, "arm_l":-55, "arm_r":-155, "leg_l":-15, "leg_r":15}),
        (0.65,{"pelvis":-18, "torso":40, "head":18, "arm_l":-70, "arm_r":-178, "leg_l":-22, "leg_r":22}),
        (1.0, {"pelvis":0, "torso":-3, "head":-2, "arm_l":20, "arm_r":-90, "leg_l":0, "leg_r":0}),
    ],
    "thief": [
        (0.0, {"pelvis":0, "torso":0, "head":0, "arm_l":-15, "arm_r":15, "leg_l":0, "leg_r":0}),
        (0.4, {"pelvis":-2, "torso":4, "head":4, "arm_l":-40, "arm_r":-160, "leg_l":4, "leg_r":-4}),
        (0.6, {"pelvis":-4, "torso":8, "head":6, "arm_l":-50, "arm_r":-170, "leg_l":6, "leg_r":-6}),
        (1.0, {"pelvis":0, "torso":0, "head":0, "arm_l":-15, "arm_r":15, "leg_l":0, "leg_r":0}),
    ],
}

RUN_POSES = {
    "warrior": {"pelvis":0, "torso":4, "head":0, "arm_l":-30, "arm_r":30, "leg_l":-35, "leg_r":35},
    "mage":    {"pelvis":0, "torso":4, "head":0, "arm_l":-25, "arm_r":25, "leg_l":-30, "leg_r":30},
    "archer":  {"pelvis":0, "torso":4, "head":0, "arm_l":-28, "arm_r":28, "leg_l":-32, "leg_r":32},
    "death_knight": {"pelvis":0, "torso":6, "head":0, "arm_l":-40, "arm_r":40, "leg_l":-40, "leg_r":40},
    "thief":   {"pelvis":0, "torso":6, "head":0, "arm_l":-35, "arm_r":35, "leg_l":-40, "leg_r":40},
}

def interp(kfs, progress):
    t = progress
    ka, kb = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        if kfs[i][0] <= t <= kfs[i+1][0]:
            ka, kb = kfs[i], kfs[i+1]; break
    if ka == kb: return dict(ka[1])
    r = (t - ka[0]) / max(0.001, kb[0] - ka[0])
    r = 1 - (1-r)**2.5
    out = {}
    keys = set(ka[1].keys()) | set(kb[1].keys())
    for k in keys:
        ra = ka[1].get(k, 0); rb = kb[1].get(k, 0)
        out[k] = ra*(1-r) + rb*r
    return out

# ============================================================
# Step 6: 主流程
# ============================================================

CLASS_LIST = ["warrior", "mage", "archer", "death_knight", "thief"]

print("切部件 + 渲染...")
all_sheets = {}

for cls in CLASS_LIST:
    print(f"\n处理 {cls}...")
    img = Image.open(f"{PROJ}/assets/portraits/{cls}.png").convert("RGBA")
    mask = remove_dark_background(img)
    
    # 切 6 个部件
    parts = {}
    for pname in ["head", "torso", "arm_l", "arm_r", "leg_l", "leg_r"]:
        box = PART_TEMPLATES[pname]
        anc = PART_ANCHORS_WORLD[pname]
        result = cut_part(img, mask, pname, box, anc)
        if result[0] is not None:
            pimg, anchor_local, anchor_world = result
            parts[pname] = (pimg, anchor_local)
    
    if len(parts) < 4:
        print(f"  警告: 只有 {len(parts)} 个部件, 跳过")
        continue
    
    # 保存部件
    cls_parts_dir = f"{PARTS_OUT}/{cls}"
    os.makedirs(cls_parts_dir, exist_ok=True)
    for pname, (pimg, anc) in parts.items():
        pimg.save(f"{cls_parts_dir}/{pname}.png")
    
    # 渲染各种帧
    CANVAS_W, CANVAS_H = 560, 620
    
    # pelvis 在 canvas 上的位置 (画布中心偏下)
    pelvis_base = (CANVAS_W//2, CANVAS_H - 80)
    
    frames = {}
    
    # idle 4 帧
    for k in range(4):
        phase = math.sin(2*math.pi * k/4)
        rots = {
            "pelvis": phase * 1.5,
            "torso": -1 + phase * 1.5,
            "head": 0,
            "arm_l": 8 + phase * 4,
            "arm_r": -8 - phase * 4,
            "leg_l": 0, "leg_r": 0,
        }
        transforms = fk(REL_ANCHORS, rots, 1.0, pelvis_base)
        c = Image.new("RGBA", (CANVAS_W, CANVAS_H), (14,18,28,255))
        render_parts(c, parts, transforms, 1.0)
        frames[f"idle_{k+1}"] = c.convert("RGB")
    
    # run 4 帧
    run_pose = RUN_POSES.get(cls, RUN_POSES["warrior"])
    for k in range(4):
        phase = math.sin(2*math.pi * k/4)
        rots = {}
        for name, val in run_pose.items():
            rots[name] = val * (0.8 + phase*0.4)
        rots["pelvis"] = phase * 2.0
        transforms = fk(REL_ANCHORS, rots, 1.0, pelvis_base)
        c = Image.new("RGBA", (CANVAS_W, CANVAS_H), (14,18,28,255))
        render_parts(c, parts, transforms, 1.0)
        frames[f"run_{k+1}"] = c.convert("RGB")
    
    # attack 关键帧
    atk_pose = ATTACK_POSES.get(cls, ATTACK_POSES["warrior"])
    for k, (t, _) in enumerate(atk_pose):
        rots = interp(atk_pose, t)
        transforms = fk(REL_ANCHORS, rots, 1.0, pelvis_base)
        c = Image.new("RGBA", (CANVAS_W, CANVAS_H), (14,18,28,255))
        render_parts(c, parts, transforms, 1.0)
        frames[f"attack_{k+1}"] = c.convert("RGB")
    
    # 保存帧
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, frame in frames.items():
        frame.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # 生成 contact sheet
    cats = [
        ("idle 呼吸", [f"idle_{i}" for i in range(1,5)]),
        ("run 奔跑",  [f"run_{i}" for i in range(1,5)]),
        ("attack 攻击", [f"attack_{i}" for i in range(1, len(atk_pose)+1)]),
    ]
    COLS = 5; TW, TH = 180, 220; LH = 28; MAR = 8
    rows = len(cats)
    sw = MAR*2 + COLS*(TW+6)
    sh = MAR + 28 + MAR + rows*(LH + TH + MAR)
    sheet = Image.new("RGB", (sw, sh), (16, 22, 34))
    d = ImageDraw.Draw(sheet)
    cn_map = {"warrior":"战士","mage":"法师","archer":"弓箭手","death_knight":"死亡骑士","thief":"盗贼"}
    d.text((MAR+8, MAR+6), f"{cls} / {cn_map.get(cls,cls)} — 真实肖像切割 + 关节驱动", fill=(200,220,250))
    
    y0 = MAR + 28 + MAR
    for ri, (cat, fnames) in enumerate(cats):
        y = y0 + ri*(LH+TH+MAR)
        d.rectangle([MAR, y, sw-MAR, y+LH], fill=(24, 30, 44))
        d.text((MAR+8, y+6), cat, fill=(220, 235, 250))
        for ci in range(COLS):
            x = MAR + ci*(TW+6)
            fi = fnames[ci] if ci < len(fnames) else None
            d.rectangle([x, y+LH, x+TW, y+LH+TH], outline=(60,75,95), width=1)
            if fi and fi in frames:
                # 裁中心区域再放进去
                f = frames[fi].resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, y+LH))
    sheet.save(f"{OUT}/{cls}_sheet.jpg", "JPEG", quality=92)
    all_sheets[cls] = sheet
    print(f"  → {cls}_sheet.jpg ({sw}×{sh})")

# ============================================================
# 总览图 — 5 职业并排
# ============================================================

print("\n生成总览...")
COLS2 = 3; ROWS2 = 2; TW2, TH2 = 340, 400; MAR2 = 20
sheet_w = COLS2 * TW2 + (COLS2+1) * MAR2
sheet_h = ROWS2 * TH2 + (ROWS2+1) * MAR2 + 60
overview = Image.new("RGB", (sheet_w, sheet_h), (12, 16, 26))
d = ImageDraw.Draw(overview)
d.text((MAR2, 20), "Diablo 风格 v3 — 真实肖像部件 + 关节驱动", fill=(220, 235, 255))
d.text((MAR2, 40), "每个部件 = 从原始立绘精确切出, 贴到对应骨骼关节, 质心作为 anchor (消除偏移)", fill=(140, 160, 190))

for idx, cls in enumerate(CLASS_LIST):
    if cls not in all_sheets: continue
    r, c = divmod(idx, COLS2)
    sx = MAR2 + c*(TW2+MAR2)
    sy = 60 + MAR2 + r*(TH2+MAR2)
    # 从 sheet 里取 attack 中间帧
    sheet_img = all_sheets[cls]
    mid_col = 2
    frame_x = MAR + mid_col*(180+6)
    frame_y = MAR + 28 + MAR + 2*(28+220+8)
    crop = sheet_img.crop((frame_x, frame_y, frame_x+180, frame_y+220)).resize((TW2, TH2), Image.BILINEAR)
    overview.paste(crop, (sx, sy))
    d.rectangle([sx, sy, sx+TW2, sy+TH2], outline=(70, 100, 140))
    cn = {"warrior":"战士","mage":"法师","archer":"弓箭手","death_knight":"死亡骑士","thief":"盗贼"}.get(cls,cls)
    d.text((sx+6, sy+6), cn, fill=(240, 250, 255))

overview.save(f"{OUT}/overview_diablo_style.jpg", "JPEG", quality=92)
print(f"overview_diablo_style.jpg: {sheet_w}×{sheet_h}")

print(f"\n=== 全部完成 ===")
print(f"输出: {OUT}/")
print(f"部件: {PARTS_OUT}/")
for cls in CLASS_LIST:
    if os.path.isdir(f"{OUT}/{cls}"):
        cnt = len([f for f in os.listdir(f"{OUT}/{cls}") if f.endswith(".jpg")])
        print(f"  {cls}: {cnt} 帧 + sheet")
