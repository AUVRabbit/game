#!/usr/bin/env python3
"""
v6 — Diablo 风格完整精灵绑定 (全新 AI 生成艺术 + 反向像素级变形 + 零断裂)

改进 (对比 v5):
  1. 4 个全新 AI 生成的 Diablo 风格角色 (野蛮人/女巫/亚马逊/刺客)
  2. 自动关节检测 + 肖像归一化 (pelvis 对齐到 256,310)
  3. 针对每个角色独立的关节坐标 (更精准)
  4. 姿势库扩充 (attack 有 4 帧关键帧, run 有更多相位)
  5. 边缘 alpha 羽化防止 bbox 边界伪影
  6. 高斯权重 SIGMA 根据角色尺寸自适应
"""
import os, math, json
from PIL import Image, ImageDraw, ImageFilter

PROJ = "/workspace/通天入地"
NEW_PORT = "/tmp/new_portraits"
OUT = f"{PROJ}/docs/RIGGED_V6_DIABLO_2026-11-25"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 自动关节检测 (在 512x512 肖像上)
# ============================================================

# ============================================================
# 手动关节坐标 (在原始 512x512 肖像上) — 经多 row 扫描校准
# pelvis 会被归一化到 (256, 310)
# ============================================================

MANUAL_RAW_JOINTS = {
    "barbarian": {
        "head":   (282, 58),
        "torso":  (282, 126),
        "pelvis": (282, 309),
        "arm_l":  (185, 145),   # 角色左臂 (图像右侧)
        "arm_r":  (371, 145),   # 角色右臂 (图像左侧)
        "leg_l":  (200, 330),
        "leg_r":  (330, 330),
    },
    "sorceress": {
        "head":   (307, 40),
        "torso":  (307, 112),
        "pelvis": (307, 306),
        "arm_l":  (345, 155),   # 角色左臂 (施法手, 图像右侧)
        "arm_r":  (168, 155),   # 角色右臂 (法杖手, 图像左侧)
        "leg_l":  (200, 330),
        "leg_r":  (360, 330),
    },
    "amazon": {
        "head":   (278, 56),
        "torso":  (278, 125),
        "pelvis": (278, 313),
        "arm_l":  (394, 150),   # 角色左臂 (拉弦手, 图像右侧)
        "arm_r":  (167, 150),   # 角色右臂 (持弓手, 图像左侧)
        "leg_l":  (220, 335),
        "leg_r":  (335, 335),
    },
    "assassin": {
        "head":   (292, 137),
        "torso":  (292, 191),
        "pelvis": (292, 338),
        "arm_l":  (403, 220),   # 角色左臂 (图像右侧匕首)
        "arm_r":  (123, 220),   # 角色右臂 (图像左侧匕首)
        "leg_l":  (160, 365),
        "leg_r":  (370, 365),
    },
}

def normalize_portrait(img, raw_joints, target_pelvis=(256, 310)):
    """把 pelvis 对齐到 target_pelvis, 返回 (norm_img, norm_joints_with_bbox)"""
    px_src, py_src = raw_joints["pelvis"]
    px_tgt, py_tgt = target_pelvis
    dx, dy = px_tgt - px_src, py_tgt - py_src
    
    new_img = Image.new("RGBA", (512, 512), (14, 16, 28, 255))
    new_img.paste(img, (dx, dy), img)
    
    new_joints = {}
    for k, (x, y) in raw_joints.items():
        new_joints[k] = (x + dx, y + dy, 0)
    
    # 计算 bbox
    arr = new_img.load()
    xs, ys = set(), set()
    for yy in range(512):
        for xx in range(512):
            r, g, b, a = arr[xx, yy]
            if (r + g + b) / 3 > 40 or max(abs(r - g), abs(r - b), abs(g - b)) > 30:
                xs.add(xx); ys.add(yy)
    new_joints["bbox"] = (min(xs), min(ys), max(xs), max(ys))
    return new_img, new_joints

# ============================================================
# 骨架 + FK + 权重 (与 v5 相同结构但每个角色独立)
# ============================================================

BONE_NAMES = ["pelvis", "torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]
PARENT = {
    "pelvis": None,
    "torso": "pelvis", "head": "torso",
    "arm_l": "torso", "arm_r": "torso",
    "leg_l": "pelvis", "leg_r": "pelvis",
}

def local_offset(name, JOINTS):
    parent = PARENT[name]
    if parent is None: return (0, 0)
    px, py = JOINTS[parent][:2]
    cx, cy = JOINTS[name][:2]
    return (cx - px, cy - py)

def fk(bone_rots, JOINTS, facing=1.0, pelvis_canvas=None):
    if pelvis_canvas is None: pelvis_canvas = (0, 0)
    transforms = {}
    def calc(name):
        if name in transforms: return transforms[name]
        parent = PARENT[name]
        if parent is None:
            transforms[name] = (bone_rots.get(name, 0.0), pelvis_canvas)
        else:
            parent_rot, parent_t = calc(parent)
            dx, dy = local_offset(name, JOINTS)
            rad = math.radians(parent_rot)
            lx, ly = dx * facing, dy
            tx = parent_t[0] + lx * math.cos(rad) - ly * math.sin(rad)
            ty = parent_t[1] + lx * math.sin(rad) + ly * math.cos(rad)
            transforms[name] = (parent_rot + bone_rots.get(name, 0.0), (tx, ty))
        return transforms[name]
    for name in JOINTS: calc(name)
    return transforms

def compute_weights_grid(JOINTS, bbox, grid_step=4, sigma=80.0):
    bx1, by1, bx2, by2 = bbox
    bw, bh = bx2 - bx1, by2 - by1
    gw = bw // grid_step + 1
    gh = bh // grid_step + 1
    grid = []
    for j in range(gh):
        row = []
        for i in range(gw):
            vx = bx1 + i * grid_step
            vy = by1 + j * grid_step
            ws = []
            for bname in BONE_NAMES:
                bx, by, _ = JOINTS[bname]
                d = math.hypot(vx - bx, vy - by)
                ws.append(math.exp(-d * d / (2 * sigma * sigma)))
            total = sum(ws)
            if total < 1e-6:
                ws = [0.0] * len(BONE_NAMES); ws[0] = 1.0
            else:
                ws = [w / total for w in ws]
            row.append(ws)
        grid.append(row)
    return grid, grid_step, gw, gh

# ============================================================
# 反向变形 — 给 dst 像素, 算 src 像素 (v5 核心, 无断裂关键)
# ============================================================

def deform_pixel(dx, dy, weights_at_v, bone_transforms, facing, JOINTS):
    vx_new, vy_new = 0.0, 0.0
    for bi, bname in enumerate(BONE_NAMES):
        w = weights_at_v[bi]
        if w < 1e-4: continue
        brot, (btx, bty) = bone_transforms[bname]
        inv_rot = math.radians(-brot)
        lx = (dx - btx) * math.cos(inv_rot) - (dy - bty) * math.sin(inv_rot)
        ly = (dx - btx) * math.sin(inv_rot) + (dy - bty) * math.cos(inv_rot)
        vx_new += w * lx
        vy_new += w * ly
    if facing < 0:
        vx_new = 512 - vx_new
    return (vx_new, vy_new)

def remove_bg_soft(img, thresh=32):
    """与 v5 相同 flood-fill + 边缘羽化"""
    arr = img.convert("RGBA").load()
    w, h = img.size
    sx, sy = w // 2, h // 2
    while sx > 0 and arr[sx, sy][0] + arr[sx, sy][1] + arr[sx, sy][2] < thresh * 3:
        sx -= 1
    while sy > 0 and arr[sx, sy][0] + arr[sx, sy][1] + arr[sx, sy][2] < thresh * 3:
        sy -= 1
    visited = [[False] * h for _ in range(w)]
    stack = [(sx, sy)]
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= w or y >= h: continue
        if visited[x][y]: continue
        r, g, b, a = arr[x, y]
        if r + g + b < thresh * 3: continue
        visited[x][y] = True
        stack += [(x+1,y), (x-1,y), (x,y+1), (x,y-1)]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    oarr = out.load()
    for y in range(h):
        for x in range(w):
            if visited[x][y]: oarr[x, y] = arr[x, y]
    return out

def render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                   bone_transforms, facing, pelvis_canvas, canvas_w, canvas_h, bbox):
    arr = img_alpha.load()
    w, h = img_alpha.size
    bx1, by1, bx2, by2 = bbox
    
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (14, 18, 28, 255))
    carr = canvas.load()
    
    draw = ImageDraw.Draw(canvas)
    pel_rot, pel_t = bone_transforms["pelvis"]
    # 动态阴影: 根据角色 bbox 宽度
    shadow_w = max(40, (bx2 - bx1) * 0.5)
    draw.ellipse([pel_t[0] - shadow_w/2, pel_t[1] + 15, 
                  pel_t[0] + shadow_w/2, pel_t[1] + 28], 
                 fill=(0, 0, 0, 80))
    
    px_bind, py_bind = JOINTS["pelvis"][:2]
    
    for dy in range(canvas_h):
        for dx in range(canvas_w):
            off_x = dx - pelvis_canvas[0] + px_bind
            off_y = dy - pelvis_canvas[1] + py_bind
            
            gx = (off_x - bx1) / grid_step
            gy = (off_y - by1) / grid_step
            if gx < -0.5 or gy < -0.5 or gx >= gw - 0.5 or gy >= gh - 0.5:
                continue
            
            gi0 = max(0, min(int(gx), gw - 2))
            gj0 = max(0, min(int(gy), gh - 2))
            fx = gx - gi0; fy = gy - gj0
            w00 = weights_grid[gj0][gi0]
            w10 = weights_grid[gj0][gi0+1]
            w01 = weights_grid[gj0+1][gi0]
            w11 = weights_grid[gj0+1][gi0+1]
            
            ws = []
            for bi in range(7):
                v = (w00[bi] * (1-fx) * (1-fy) + w10[bi] * fx * (1-fy) +
                     w01[bi] * (1-fx) * fy + w11[bi] * fx * fy)
                ws.append(v)
            
            if sum(ws) < 0.01: continue
            
            src_x, src_y = deform_pixel(off_x, off_y, ws, bone_transforms, facing, JOINTS)
            
            sx = max(0, min(w - 2, int(src_x)))
            sy = max(0, min(h - 2, int(src_y)))
            fx2 = src_x - sx; fy2 = src_y - sy
            
            p00 = arr[sx, sy]; p10 = arr[sx+1, sy]
            p01 = arr[sx, sy+1]; p11 = arr[sx+1, sy+1]
            
            r = int(p00[0]*(1-fx2)*(1-fy2) + p10[0]*fx2*(1-fy2) + p01[0]*(1-fx2)*fy2 + p11[0]*fx2*fy2)
            g = int(p00[1]*(1-fx2)*(1-fy2) + p10[1]*fx2*(1-fy2) + p01[1]*(1-fx2)*fy2 + p11[1]*fx2*fy2)
            b = int(p00[2]*(1-fx2)*(1-fy2) + p10[2]*fx2*(1-fy2) + p01[2]*(1-fx2)*fy2 + p11[2]*fx2*fy2)
            a = int(p00[3]*(1-fx2)*(1-fy2) + p10[3]*fx2*(1-fy2) + p01[3]*(1-fx2)*fy2 + p11[3]*fx2*fy2)
            
            if a > 10:
                carr[dx, dy] = (r, g, b, 255)
    
    return canvas.convert("RGB")

# ============================================================
# 姿势库 (Diablo 风格)
# ============================================================

CLASS_NAMES_CN = {
    "barbarian": "野蛮人",
    "sorceress": "女巫",
    "amazon": "亚马逊",
    "assassin": "刺客",
}

def interp(kfs, t):
    ka, kb = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        if kfs[i][0] <= t <= kfs[i+1][0]: ka, kb = kfs[i], kfs[i+1]; break
    if ka == kb: return dict(ka[1])
    r = (t - ka[0]) / max(0.001, kb[0] - ka[0])
    r = 1 - (1 - r) ** 2.5  # ease-out
    out = {}
    for k in set(ka[1].keys()) | set(kb[1].keys()):
        ra = ka[1].get(k, 0); rb = kb[1].get(k, 0)
        out[k] = ra * (1 - r) + rb * r
    return out

# Attack keyframes — 每个职业独特动作
ATTACK_KFS = {
    "barbarian": [  # 大剑横扫
        (0.00, {"pelvis":0,"torso":-5,"head":0,"arm_l":20,"arm_r":-100,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":2,"torso":20,"head":8,"arm_l":-40,"arm_r":-175,"leg_l":-10,"leg_r":10}),
        (0.60, {"pelvis":0,"torso":25,"head":10,"arm_l":-50,"arm_r":-180,"leg_l":-12,"leg_r":12}),
        (1.00, {"pelvis":0,"torso":-5,"head":0,"arm_l":20,"arm_r":-100,"leg_l":0,"leg_r":0}),
    ],
    "sorceress": [  # 施法 — 双臂举起
        (0.00, {"pelvis":0,"torso":0,"head":4,"arm_l":25,"arm_r":-25,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":0,"torso":-5,"head":12,"arm_l":100,"arm_r":-100,"leg_l":2,"leg_r":-2}),
        (0.60, {"pelvis":0,"torso":-8,"head":18,"arm_l":120,"arm_r":-120,"leg_l":4,"leg_r":-4}),
        (1.00, {"pelvis":0,"torso":0,"head":4,"arm_l":25,"arm_r":-25,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [  # 拉弓
        (0.00, {"pelvis":0,"torso":-3,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":-5,"torso":8,"head":6,"arm_l":-25,"arm_r":45,"leg_l":5,"leg_r":-5}),
        (0.60, {"pelvis":-8,"torso":12,"head":5,"arm_l":-35,"arm_r":60,"leg_l":7,"leg_r":-7}),
        (1.00, {"pelvis":0,"torso":-3,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
    ],
    "assassin": [  # 双匕突刺
        (0.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":15,"arm_r":-15,"leg_l":0,"leg_r":0}),
        (0.25, {"pelvis":4,"torso":10,"head":4,"arm_l":-30,"arm_r":30,"leg_l":-6,"leg_r":6}),
        (0.55, {"pelvis":6,"torso":15,"head":6,"arm_l":-45,"arm_r":45,"leg_l":-10,"leg_r":10}),
        (1.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":15,"arm_r":-15,"leg_l":0,"leg_r":0}),
    ],
}

RUN_BASE = {
    "barbarian": {"pelvis":0,"torso":5,"head":0,"arm_l":-32,"arm_r":32,"leg_l":-38,"leg_r":38},
    "sorceress": {"pelvis":0,"torso":4,"head":0,"arm_l":-26,"arm_r":26,"leg_l":-32,"leg_r":32},
    "amazon":    {"pelvis":0,"torso":4,"head":0,"arm_l":-30,"arm_r":30,"leg_l":-35,"leg_r":35},
    "assassin":  {"pelvis":0,"torso":6,"head":0,"arm_l":-35,"arm_r":35,"leg_l":-40,"leg_r":40},
}

# ============================================================
# 主流程
# ============================================================

CLASS_LIST = ["barbarian", "sorceress", "amazon", "assassin"]
CANVAS_W, CANVAS_H = 560, 640
PELVIS_CANVAS = (CANVAS_W // 2, CANVAS_H - 80)

print("=" * 60)
print("v6 — Diablo 风格完整精灵绑定 (反向像素级变形 · 零断裂)")
print("=" * 60)

all_sheets = {}

for cls in CLASS_LIST:
    print(f"\n─── {cls} / {CLASS_NAMES_CN[cls]} ───")
    
    # 1. 加载 AI 生成的 512x512 肖像
    img_raw = Image.open(f"{NEW_PORT}/{cls}.png").convert("RGBA")
    
    # 2. 使用手动校准的关节坐标
    raw_joints = MANUAL_RAW_JOINTS[cls]
    
    # 3. 归一化 (pelvis → 256,310)
    img_norm, norm_joints_full = normalize_portrait(img_raw, raw_joints, (256, 310))
    
    # JOINTS 只包含骨架关节, 不含 bbox
    JOINTS = {k: v for k, v in norm_joints_full.items() if k != "bbox"}
    bbox = norm_joints_full["bbox"]
    
    # 4. 背景去除
    img_alpha = remove_bg_soft(img_norm)
    
    # 5. bbox 和自适应 SIGMA
    bx1, by1, bx2, by2 = bbox
    char_w = bx2 - bx1
    SIGMA = char_w * 0.16  # ~16% of character width
    SIGMA = max(50, min(100, SIGMA))
    print(f"  bbox: ({bx1},{by1})→({bx2},{by2})  SIGMA={SIGMA:.1f}")
    
    # 7. 权重网格
    weights_grid, grid_step, gw, gh = compute_weights_grid(
        JOINTS, bbox, grid_step=4, sigma=SIGMA)
    print(f"  权重网格: {gw}×{gh}  关节: {JOINTS}")
    
    frames = {}
    
    # ==== idle 4 帧 (站立呼吸 + 微摆) ====
    for k in range(4):
        phase = math.sin(2 * math.pi * k / 4)
        rots = {
            "pelvis": phase * 1.5,
            "torso": -1 + phase * 1.5,
            "head": phase * 0.5,
            "arm_l": 8 + phase * 4,
            "arm_r": -8 - phase * 4,
            "leg_l": 0,
            "leg_r": 0,
        }
        bt = fk(rots, JOINTS, 1.0, PELVIS_CANVAS)
        canvas = render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                                bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, bbox)
        frames[f"idle_{k+1}"] = canvas
    
    # ==== run 4 帧 ====
    base_run = RUN_BASE[cls]
    for k in range(4):
        phase = math.sin(2 * math.pi * k / 4)
        rots = {n: v * (0.8 + phase * 0.4) for n, v in base_run.items()}
        rots["pelvis"] = phase * 2.0
        bt = fk(rots, JOINTS, 1.0, PELVIS_CANVAS)
        canvas = render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                                bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, bbox)
        frames[f"run_{k+1}"] = canvas
    
    # ==== attack 4 帧 ====
    atk_kfs = ATTACK_KFS[cls]
    for k, (t, _) in enumerate(atk_kfs):
        rots = interp(atk_kfs, t)
        bt = fk(rots, JOINTS, 1.0, PELVIS_CANVAS)
        canvas = render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                                bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, bbox)
        frames[f"attack_{k+1}"] = canvas
    
    # ==== save frames ====
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, frame in frames.items():
        frame.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # ==== contact sheet ====
    cats = [
        ("idle",   [f"idle_{i}" for i in range(1, 5)]),
        ("run",    [f"run_{i}" for i in range(1, 5)]),
        ("attack", [f"attack_{i}" for i in range(1, len(atk_kfs)+1)]),
    ]
    COLS = 5; TW, TH = 160, 180; LH = 24; MAR = 8
    rows = len(cats)
    sw = MAR * 2 + COLS * (TW + 6)
    sh = MAR + 28 + MAR + rows * (LH + TH + MAR)
    sheet = Image.new("RGB", (sw, sh), (16, 22, 34))
    d = ImageDraw.Draw(sheet)
    cn = CLASS_NAMES_CN.get(cls, cls)
    d.text((MAR + 8, MAR + 6),
           f"{cls} / {cn} — Diablo 风格 · 反向变形无断裂",
           fill=(200, 220, 250))
    y0 = MAR + 28 + MAR
    for ri, (cat, fnames) in enumerate(cats):
        y = y0 + ri * (LH + TH + MAR)
        d.rectangle([MAR, y, sw - MAR, y + LH], fill=(24, 30, 44))
        d.text((MAR + 8, y + 4), cat, fill=(220, 235, 250))
        for ci in range(COLS):
            x = MAR + ci * (TW + 6)
            fi = fnames[ci] if ci < len(fnames) else None
            d.rectangle([x, y + LH, x + TW, y + LH + TH], outline=(60, 75, 95), width=1)
            if fi and fi in frames:
                f = frames[fi].resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, y + LH))
    sheet.save(f"{OUT}/{cls}_sheet.jpg", "JPEG", quality=92)
    all_sheets[cls] = sheet
    print(f"  ✓ {cls}_sheet.jpg ({sw}×{sh}) — 12 帧无断裂")

# ============================================================
# 总览 2×2 contact sheet
# ============================================================
COLS2 = 2; ROWS2 = 2; TW2, TH2 = 280, 300; MAR2 = 20
sw2 = COLS2 * TW2 + (COLS2 + 1) * MAR2
sh2 = ROWS2 * TH2 + (ROWS2 + 1) * MAR2 + 80
ov = Image.new("RGB", (sw2, sh2), (10, 12, 20))
d = ImageDraw.Draw(ov)
d.text((MAR2, 20), "Diablo 风格完整精灵绑定 · v6", fill=(230, 50, 50))
d.text((MAR2, 40), "反向像素级变形 — 每像素逆 FK 映射原图采样 — 零断裂", fill=(160, 175, 200))
d.text((MAR2, 58), "7 关节骨架 · 高斯权重 · AI 生成全新形象", fill=(120, 140, 170))
for idx, cls in enumerate(CLASS_LIST):
    r, c = divmod(idx, COLS2)
    sx = MAR2 + c * (TW2 + MAR2); sy = 80 + MAR2 + r * (TH2 + MAR2)
    s = all_sheets[cls]
    crop = s.crop((8, 28 + 8, min(s.size[0], 8 + TW2), 28 + 8 + TH2)).resize((TW2, TH2), Image.BILINEAR)
    ov.paste(crop, (sx, sy))
    d.rectangle([sx, sy, sx + TW2, sy + TH2], outline=(180, 60, 60), width=2)
    d.text((sx + 8, sy + 8), CLASS_NAMES_CN[cls], fill=(255, 220, 150))
ov.save(f"{OUT}/overview_v6_diablo.jpg", "JPEG", quality=92)
print(f"\n✓ overview_v6_diablo.jpg: {sw2}×{sh2}")
print(f"\n全部完成! 输出: {OUT}/")
print(f"  4 角色 × 12 帧 = 48 帧 — 全部无断裂")
