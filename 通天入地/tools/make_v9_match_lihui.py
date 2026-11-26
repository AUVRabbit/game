#!/usr/bin/env python3
"""
v9 — 立绘一致化动画 (Lihui-Matched Animation)

核心思路:
  1. 用 v8 的立绘增强流程 (去背景 + Blinn-Phong 光影) 处理 assets/portraits/
  2. 自动关节检测 + pelvis 归一化到 (256, 310)
  3. 用 v6 的逆像素级变形 (每像素逆 FK 采样增强立绘)
  4. 输出 6 组动作 × 4 帧 = 24 帧/角色

保证: 动画角色外观 = 立绘卡外观 (同一个增强后的肖像作为源)
"""
import os, math, json, statistics as st
from collections import deque
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/LIHUI_MATCHED_v9"
ENHANCED_DIR = f"{OUT}/enhanced_source"
os.makedirs(OUT, exist_ok=True)
os.makedirs(ENHANCED_DIR, exist_ok=True)

# ============================================================
# 肖像 → 职业映射 (项目 assets/portraits/ 实际文件名)
# ============================================================
PORTRAITS = {
    "barbarian": "warrior",
    "sorceress": "mage",
    "amazon": "archer",
    "assassin": "thief",
}

CLASS_NAMES_CN = {
    "barbarian": "野蛮人",
    "sorceress": "女巫",
    "amazon": "亚马逊",
    "assassin": "刺客",
}

CLASS_SKILL_CN = {
    "barbarian": "旋风斩",
    "sorceress": "陨石术",
    "amazon":    "多重射击",
    "assassin":  "影袭",
}

# ============================================================
# Step 1: 背景去除 (反向 flood fill)
# ============================================================
def remove_bg(img, color_tol=10):
    """从四边向内 BFS, 标记背景像素"""
    arr = img.convert("RGBA").load()
    w, h = img.size
    
    edge_rs, edge_gs, edge_bs = [], [], []
    for x in range(w):
        for y in [0, h-1]:
            edge_rs.append(arr[x,y][0]); edge_gs.append(arr[x,y][1]); edge_bs.append(arr[x,y][2])
    for y in range(1, h-1):
        for x in [0, w-1]:
            edge_rs.append(arr[x,y][0]); edge_gs.append(arr[x,y][1]); edge_bs.append(arr[x,y][2])
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
    return out, bg, is_bg

# ============================================================
# Step 2: Blinn-Phong 光影增强 (v8 版)
# ============================================================
def enhance_lighting(img_rgba, light_dir=(0.25, -0.4), ambient=0.38):
    w, h = img_rgba.size
    arr = img_rgba.load()
    
    # 深度 proxy (亮度)
    depth = np.zeros((w, h), dtype=np.float32)
    for y in range(h):
        for x in range(w):
            r,g,b,a = arr[x,y]
            if a > 30:
                depth[x,y] = (r + g + b) / 3.0 / 255.0
    
    # Sobel 法线
    normal_x = np.zeros((w, h), dtype=np.float32)
    normal_y = np.zeros((w, h), dtype=np.float32)
    normal_x[1:-1, 1:-1] = depth[2:, 1:-1] - depth[:-2, 1:-1]
    normal_y[1:-1, 1:-1] = depth[1:-1, 2:] - depth[1:-1, :-2]
    
    # 光照方向
    lx, ly, lz = light_dir[0], light_dir[1], 1.0
    llen = math.hypot(lx, ly, lz)
    lx /= llen; ly /= llen; lz /= llen
    
    out_img = Image.new("RGBA", (w, h), (0,0,0,0))
    oarr = out_img.load()
    
    for y in range(h):
        for x in range(w):
            r,g,b,a = arr[x,y]
            if a < 20: continue
            
            nx, ny = normal_x[x,y], normal_y[x,y]
            nlen = math.hypot(nx, ny, 1.0) + 0.001
            nx /= nlen; ny /= nlen
            dot = max(0.0, nx*lx + ny*ly + 1.0/nlen * lz)
            
            intensity = ambient + (1 - ambient) * dot
            intensity = 0.4 + intensity * 0.8
            
            spec = max(0.0, dot) ** 20.0 * 0.4
            
            nr = min(255, int(r * intensity + 255 * spec))
            ng = min(255, int(g * intensity + 255 * spec))
            nb = min(255, int(b * intensity + 255 * spec))
            
            oarr[x,y] = (nr, ng, nb, a)
    
    return out_img

# ============================================================
# Step 3: 自动关节检测 (在增强立绘上)
# ============================================================
def detect_joints(img_rgba, is_bg=None):
    """在 512x512 RGBA 图上自动检测 7 个关节坐标 (比例法 + 行扫描修正)"""
    w, h = img_rgba.size
    arr = img_rgba.load()
    
    # 如果没有 is_bg mask, 用 alpha 判断
    if is_bg is None:
        is_bg = [[True]*h for _ in range(w)]
        for y in range(h):
            for x in range(w):
                if arr[x,y][3] > 30: is_bg[x][y] = False
    
    # bbox
    xs = [x for x in range(w) for y in range(h) if not is_bg[x][y]]
    ys = [y for x in range(w) for y in range(h) if not is_bg[x][y]]
    if not xs: return None
    bx1, bx2, by1, by2 = min(xs), max(xs), min(ys), max(ys)
    bw, bh = bx2 - bx1, by2 - by1
    cx = (bx1 + bx2) // 2  # 身体中心 X
    
    # 按行统计角色像素的 left/right 边界
    row_left = [w] * h
    row_right = [0] * h
    for y in range(h):
        for x in range(w):
            if not is_bg[x][y]:
                row_left[y] = min(row_left[y], x)
                row_right[y] = max(row_right[y], x)
    
    # 关键 Y 位置 (按 bbox 比例)
    head_y    = by1 + int(bh * 0.10)   # 头顶附近
    face_y    = by1 + int(bh * 0.18)   # 脸部中心
    shoulder_y = by1 + int(bh * 0.32)  # 肩膀
    torso_y   = by1 + int(bh * 0.45)   # 躯干中部
    pelvis_y  = by1 + int(bh * 0.68)   # 骨盆
    leg_y     = by1 + int(bh * 0.88)   # 腿下部
    
    # 手臂根 X 坐标: 在 shoulder_y ~ torso_y 区间, 找身体最左/最右 (即手臂根)
    arm_xs = []
    for y in range(shoulder_y, torso_y + 1):
        if row_left[y] < w and row_right[y] > 0:
            # 身体中心附近的宽度, 用来估算 torso 宽度
            arm_xs.append((row_left[y], row_right[y]))
    
    # 估算 torso 宽度 (pelvis_y 附近的平均宽度)
    torso_width_est = 0
    cnt = 0
    for y in range(pelvis_y - 15, pelvis_y + 15):
        if 0 <= y < h and row_left[y] < w:
            torso_width_est += row_right[y] - row_left[y]
            cnt += 1
    if cnt > 0: torso_width_est /= cnt
    else: torso_width_est = bw * 0.4
    
    # 手臂根: 比 torso 边缘外一点
    if arm_xs:
        # 找 torso 区域 (pelvis 附近) 的左右边界
        torso_left = min(row_left[y] for y in range(pelvis_y-10, min(pelvis_y+10, h)) if row_left[y] < w)
        torso_right = max(row_right[y] for y in range(pelvis_y-10, min(pelvis_y+10, h)) if row_right[y] > 0)
    else:
        torso_left = cx - torso_width_est/2
        torso_right = cx + torso_width_est/2
    
    # 手臂根位置: 在 shoulder 高度, 身体左右边缘各向外一点
    arm_scan_y = shoulder_y + 8
    if arm_scan_y >= h: arm_scan_y = shoulder_y
    
    # 在 arm_scan_y 附近找手臂的最外侧像素
    arm_left_edge = w
    arm_right_edge = 0
    for dy_ in range(-5, 15):
        ay = arm_scan_y + dy_
        if 0 <= ay < h:
            arm_left_edge = min(arm_left_edge, row_left[ay])
            arm_right_edge = max(arm_right_edge, row_right[ay])
    
    # 左臂 = 图像右侧最外像素 (character's left = viewer's right)
    # 右臂 = 图像左侧最外像素
    # 但如果 arm_right_edge 在 torso_right 附近 (说明手臂没伸出去), 就用比例估算
    if arm_right_edge > torso_right - 5:
        # 右臂没明显伸出, 用 torso 左侧偏外
        arm_r_x = int(torso_left - bw * 0.02)
    else:
        arm_r_x = arm_right_edge
    
    if arm_left_edge < torso_left + 5:
        arm_l_x = int(torso_right + bw * 0.02)
    else:
        arm_l_x = arm_left_edge
    
    # 腿: 在 leg_y 附近找最外
    leg_left_edge = w
    leg_right_edge = 0
    for dy_ in range(-5, 10):
        ly = leg_y + dy_
        if 0 <= ly < h:
            leg_left_edge = min(leg_left_edge, row_left[ly])
            leg_right_edge = max(leg_right_edge, row_right[ly])
    
    # 骨盆位置也用 torso 中心
    # pelvis_x: 身体中心
    pelvis_x = cx
    
    return {
        "head":   (cx, face_y),
        "torso":  (cx, torso_y),
        "pelvis": (pelvis_x, pelvis_y),
        "arm_l":  (max(bx1, min(bx2, arm_l_x)), arm_scan_y),
        "arm_r":  (max(bx1, min(bx2, arm_r_x)), arm_scan_y),
        "leg_l":  (max(bx1, min(bx2, leg_right_edge)), leg_y),
        "leg_r":  (max(bx1, min(bx2, leg_left_edge)), leg_y),
        "bbox":   (bx1, by1, bx2, by2),
    }

# ============================================================
# Step 4: 归一化 pelvis 到 (256, 310)
# ============================================================
def normalize_to_pelvis(img_rgba, joints, target=(256, 310)):
    px_src, py_src = joints["pelvis"]
    dx, dy = target[0] - px_src, target[1] - py_src
    
    w, h = img_rgba.size
    bg = (14, 16, 28, 0)
    new_img = Image.new("RGBA", (w, h), bg)
    new_img.paste(img_rgba, (dx, dy), img_rgba)
    
    new_joints = {}
    for k, v in joints.items():
        if k == "bbox":
            bx1, by1, bx2, by2 = v
            new_joints[k] = (bx1 + dx, by1 + dy, bx2 + dx, by2 + dy)
        else:
            new_joints[k] = (v[0] + dx, v[1] + dy, 0)
    
    # 重新计算 bbox
    arr = new_img.load()
    xs = set(); ys = set()
    for y in range(h):
        for x in range(w):
            if arr[x,y][3] > 30:
                xs.add(x); ys.add(y)
    if xs:
        new_joints["bbox"] = (min(xs), min(ys), max(xs), max(ys))
    
    return new_img, new_joints

# ============================================================
# 骨架 + FK + 权重
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

def fk_portrait(bone_rots, JOINTS, facing=1.0):
    transforms = {}
    def calc(name):
        if name in transforms: return transforms[name]
        parent = PARENT[name]
        if parent is None:
            transforms[name] = (bone_rots.get(name, 0.0), JOINTS[name][:2])
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

def deform_pixel(dst_x_portrait, dst_y_portrait, weights_at_v, bone_transforms, facing, JOINTS):
    vx_new, vy_new = 0.0, 0.0
    for bi, bname in enumerate(BONE_NAMES):
        w = weights_at_v[bi]
        if w < 1e-4: continue
        brot, (wx_cur, wy_cur) = bone_transforms[bname]
        inv_rot = math.radians(-brot)
        lx = (dst_x_portrait - wx_cur) * math.cos(inv_rot) - (dst_y_portrait - wy_cur) * math.sin(inv_rot)
        ly = (dst_x_portrait - wx_cur) * math.sin(inv_rot) + (dst_y_portrait - wy_cur) * math.cos(inv_rot)
        bx_bind, by_bind = JOINTS[bname][:2]
        vx_new += w * (lx + bx_bind)
        vy_new += w * (ly + by_bind)
    if facing < 0:
        vx_new = 512 - vx_new
    return (vx_new, vy_new)

# ============================================================
# 反向渲染 (v6 核心)
# ============================================================
def render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                   bone_transforms_portrait, facing, pelvis_canvas, canvas_w, canvas_h, bbox):
    arr = img_alpha.load()
    w, h = img_alpha.size
    bx1, by1, bx2, by2 = bbox
    
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (14, 18, 28, 255))
    carr = canvas.load()
    
    draw = ImageDraw.Draw(canvas)
    pel_rot, pel_t_portrait = bone_transforms_portrait["pelvis"]
    px_bind, py_bind = JOINTS["pelvis"][:2]
    pel_t_canvas = (pelvis_canvas[0], pelvis_canvas[1])  # 已经对齐
    
    shadow_w = max(40, (bx2 - bx1) * 0.5)
    draw.ellipse([pel_t_canvas[0] - shadow_w/2, pel_t_canvas[1] + 15, 
                  pel_t_canvas[0] + shadow_w/2, pel_t_canvas[1] + 28], 
                 fill=(0, 0, 0, 80))
    
    for dy_ in range(canvas_h):
        for dx in range(canvas_w):
            off_x = dx - pelvis_canvas[0] + px_bind
            off_y = dy_ - pelvis_canvas[1] + py_bind
            
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
            
            src_x, src_y = deform_pixel(off_x, off_y, ws, bone_transforms_portrait, facing, JOINTS)
            
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
                carr[dx, dy_] = (r, g, b, 255)
    
    return canvas

# ============================================================
# 姿势库 (和 v6 相同)
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
        "arm_l": 8 + phase * 4,
        "arm_r": -8 - phase * 4,
        "leg_l": 0,
        "leg_r": 0,
    }

RUN_BASE = {
    "barbarian": {"pelvis":0,"torso":5,"head":0,"arm_l":-32,"arm_r":32,"leg_l":-38,"leg_r":38},
    "sorceress": {"pelvis":0,"torso":4,"head":0,"arm_l":-26,"arm_r":26,"leg_l":-32,"leg_r":32},
    "amazon":    {"pelvis":0,"torso":4,"head":0,"arm_l":-30,"arm_r":30,"leg_l":-35,"leg_r":35},
    "assassin":  {"pelvis":0,"torso":6,"head":0,"arm_l":-35,"arm_r":35,"leg_l":-40,"leg_r":40},
}
def run_frame(cls, k):
    phase = math.sin(2 * math.pi * k / 4)
    base = RUN_BASE[cls]
    rots = {n: v * (0.8 + phase * 0.4) for n, v in base.items()}
    rots["pelvis"] = phase * 2.0
    return rots

ATTACK_KFS = {
    "barbarian": [
        (0.00, {"pelvis":0,"torso":-5,"head":0,"arm_l":20,"arm_r":-100,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":2,"torso":20,"head":8,"arm_l":-40,"arm_r":-175,"leg_l":-10,"leg_r":10}),
        (0.60, {"pelvis":0,"torso":25,"head":10,"arm_l":-50,"arm_r":-180,"leg_l":-12,"leg_r":12}),
        (1.00, {"pelvis":0,"torso":-5,"head":0,"arm_l":20,"arm_r":-100,"leg_l":0,"leg_r":0}),
    ],
    "sorceress": [
        (0.00, {"pelvis":0,"torso":0,"head":4,"arm_l":25,"arm_r":-25,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":0,"torso":-5,"head":12,"arm_l":100,"arm_r":-100,"leg_l":2,"leg_r":-2}),
        (0.60, {"pelvis":0,"torso":-8,"head":18,"arm_l":120,"arm_r":-120,"leg_l":4,"leg_r":-4}),
        (1.00, {"pelvis":0,"torso":0,"head":4,"arm_l":25,"arm_r":-25,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [
        (0.00, {"pelvis":0,"torso":-3,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":-5,"torso":8,"head":6,"arm_l":-25,"arm_r":45,"leg_l":5,"leg_r":-5}),
        (0.60, {"pelvis":-8,"torso":12,"head":5,"arm_l":-35,"arm_r":60,"leg_l":7,"leg_r":-7}),
        (1.00, {"pelvis":0,"torso":-3,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
    ],
    "assassin": [
        (0.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":15,"arm_r":-15,"leg_l":0,"leg_r":0}),
        (0.25, {"pelvis":4,"torso":10,"head":4,"arm_l":-30,"arm_r":30,"leg_l":-6,"leg_r":6}),
        (0.55, {"pelvis":6,"torso":15,"head":6,"arm_l":-45,"arm_r":45,"leg_l":-10,"leg_r":10}),
        (1.00, {"pelvis":0,"torso":-2,"head":0,"arm_l":15,"arm_r":-15,"leg_l":0,"leg_r":0}),
    ],
}

SKILL_KFS = {
    "barbarian": [
        (0.00, {"pelvis":0,"torso":-10,"head":-5,"arm_l":60,"arm_r":-120,"leg_l":8,"leg_r":-8}),
        (0.25, {"pelvis":0,"torso":-25,"head":-12,"arm_l":120,"arm_r":-150,"leg_l":15,"leg_r":-15}),
        (0.50, {"pelvis":0,"torso":-40,"head":-20,"arm_l":170,"arm_r":-170,"leg_l":22,"leg_r":-22}),
        (1.00, {"pelvis":0,"torso":-10,"head":-5,"arm_l":60,"arm_r":-120,"leg_l":8,"leg_r":-8}),
    ],
    "sorceress": [
        (0.00, {"pelvis":0,"torso":-5,"head":10,"arm_l":90,"arm_r":-90,"leg_l":0,"leg_r":0}),
        (0.25, {"pelvis":-3,"torso":-10,"head":20,"arm_l":130,"arm_r":-130,"leg_l":3,"leg_r":-3}),
        (0.50, {"pelvis":-5,"torso":-15,"head":28,"arm_l":160,"arm_r":-160,"leg_l":5,"leg_r":-5}),
        (1.00, {"pelvis":0,"torso":-5,"head":10,"arm_l":90,"arm_r":-90,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [
        (0.00, {"pelvis":-5,"torso":10,"head":8,"arm_l":-50,"arm_r":80,"leg_l":10,"leg_r":-10}),
        (0.25, {"pelvis":-10,"torso":18,"head":10,"arm_l":-70,"arm_r":100,"leg_l":14,"leg_r":-14}),
        (0.50, {"pelvis":-12,"torso":22,"head":12,"arm_l":-85,"arm_r":115,"leg_l":16,"leg_r":-16}),
        (1.00, {"pelvis":-5,"torso":10,"head":8,"arm_l":-50,"arm_r":80,"leg_l":10,"leg_r":-10}),
    ],
    "assassin": [
        (0.00, {"pelvis":-2,"torso":5,"head":2,"arm_l":20,"arm_r":-20,"leg_l":-15,"leg_r":15}),
        (0.25, {"pelvis":-4,"torso":15,"head":5,"arm_l":-20,"arm_r":20,"leg_l":-25,"leg_r":25}),
        (0.50, {"pelvis":-6,"torso":25,"head":8,"arm_l":-35,"arm_r":35,"leg_l":-32,"leg_r":32}),
        (1.00, {"pelvis":-2,"torso":5,"head":2,"arm_l":20,"arm_r":-20,"leg_l":-15,"leg_r":15}),
    ],
}

def wave_frame(k):
    phase = math.sin(2 * math.pi * k / 4)
    return {
        "pelvis": 0,
        "torso": phase * -3,
        "head": phase * -2,
        "arm_l": 10 + phase * 8,
        "arm_r": -140 - phase * 25,
        "leg_l": 0,
        "leg_r": 0,
    }

def cheer_frame(k):
    phases = [0.0, 1.0, 1.0, 0.3]
    p = phases[k]
    return {
        "pelvis": 0,
        "torso": -2 - p * 4,
        "head": 2 + p * 6,
        "arm_l": 60 + p * 100,
        "arm_r": -60 - p * 100,
        "leg_l": p * -3,
        "leg_r": p * 3,
    }

# ============================================================
# 主流程
# ============================================================
CLASS_LIST = ["barbarian", "sorceress", "amazon", "assassin"]
CANVAS_W, CANVAS_H = 560, 640
PELVIS_CANVAS = (CANVAS_W // 2, CANVAS_H - 80)

ACTION_GROUPS = [
    ("待机", "idle",   lambda cls, k: idle_frame(k),      "站立呼吸微摆"),
    ("行走", "run",    lambda cls, k: run_frame(cls, k),   "行走循环"),
    ("普攻", "attack", None,                                "基础攻击"),
    ("技能释放", "skill", None,                             None),
    ("挥手致意", "wave",   lambda cls, k: wave_frame(k),   "日常交互 · 挥手"),
    ("欢呼庆祝", "cheer",  lambda cls, k: cheer_frame(k),  "日常交互 · 欢呼"),
]

print("=" * 70)
print("v9 — 立绘一致化动画 (Lihui-Matched Animation)")
print("     v8 立绘增强 + v6 逆像素变形 → 动画外观 = 立绘外观")
print("     6 组动作 × 4 帧 = 24 帧/角色")
print("=" * 70)

all_sheets = {}
enhanced_portraits = {}

for cls in CLASS_LIST:
    portrait_file = PORTRAITS[cls]
    portrait_path = f"{PROJ}/assets/portraits/{portrait_file}.png"
    
    print(f"\n{'─'*12} {CLASS_NAMES_CN[cls]} ({cls}) ← {portrait_file}.png {'─'*12}")
    
    # === Step 1: 加载 + 去背景 + 光影增强 ===
    img_raw = Image.open(portrait_path).convert("RGBA")
    img_alpha, bg_color, is_bg = remove_bg(img_raw, color_tol=15)
    img_enhanced = enhance_lighting(img_alpha, light_dir=(0.25, -0.4), ambient=0.38)
    
    # 保存增强立绘源
    img_enhanced.save(f"{ENHANCED_DIR}/{cls}_enhanced.png", "PNG")
    enhanced_portraits[cls] = img_enhanced
    print(f"  ✓ 立绘增强: 去背景 + Blinn-Phong 光影")
    
    # === Step 2: 关节检测 (在增强立绘上) ===
    raw_joints = detect_joints(img_enhanced, is_bg)
    if raw_joints is None:
        print(f"  ⚠ 无法检测关节, 跳过")
        continue
    
    bx1, by1, bx2, by2 = raw_joints["bbox"]
    char_h = by2 - by1
    char_w = bx2 - bx1
    print(f"  关节检测: bbox=({bx1},{by1})-({bx2},{by2}) 尺寸={char_w}×{char_h}")
    for k in ["head", "torso", "pelvis", "arm_l", "arm_r", "leg_l", "leg_r"]:
        print(f"    {k:8s}: {raw_joints[k]}")
    
    # === Step 3: 归一化 pelvis → (256, 310) ===
    img_norm, norm_joints = normalize_to_pelvis(img_enhanced, raw_joints, (256, 310))
    JOINTS = {k: v for k, v in norm_joints.items() if k != "bbox"}
    bbox = norm_joints["bbox"]
    
    # === Step 4: 权重网格 ===
    bx1, by1, bx2, by2 = bbox
    char_w = bx2 - bx1
    SIGMA = max(50, min(100, char_w * 0.16))
    weights_grid, grid_step, gw, gh = compute_weights_grid(JOINTS, bbox, grid_step=4, sigma=SIGMA)
    print(f"  权重网格: {gw}×{gh}  sigma={SIGMA:.1f}  bbox={bbox}")
    
    # === Step 5: 生成 6 × 4 = 24 帧 ===
    frames = {}
    
    for gidx, (cn_label, en_prefix, gen_func, desc) in enumerate(ACTION_GROUPS):
        cn_label_show = CLASS_SKILL_CN[cls] if cn_label == "技能释放" else cn_label
        
        for k in range(4):
            if en_prefix == "attack":
                rots = interp(ATTACK_KFS[cls], ATTACK_KFS[cls][k][0])
            elif en_prefix == "skill":
                rots = interp(SKILL_KFS[cls], SKILL_KFS[cls][k][0])
            else:
                rots = gen_func(cls, k)
            
            bt = fk_portrait(rots, JOINTS, 1.0)
            canvas = render_reverse(img_norm, JOINTS, weights_grid, grid_step, gw, gh,
                                    bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, bbox)
            frame_key = f"{en_prefix}_{k+1}"
            frames[frame_key] = (canvas, cn_label_show, k + 1)
    
    # === Step 6: 保存各帧 ===
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, (frame, _, _) in frames.items():
        # RGBA → RGB (深色底)
        rgb = Image.new("RGB", frame.size, (14, 18, 28))
        rgb.paste(frame, (0, 0), frame)
        rgb.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # === Step 7: Contact Sheet (全中文) ===
    cats = []
    for cn_label, en_prefix, gen_func, desc in ACTION_GROUPS:
        label = CLASS_SKILL_CN[cls] if cn_label == "技能释放" else cn_label
        fnames = [f"{en_prefix}_{k}" for k in range(1, 5)]
        cats.append((label, fnames))
    
    COLS = 4; TW, TH = 140, 160; LH = 26; MAR = 8
    rows = len(cats)
    sw = MAR * 2 + COLS * (TW + 8)
    sh = MAR + 30 + MAR + rows * (LH + TH + MAR)
    sheet = Image.new("RGB", (sw, sh), (12, 16, 24))
    d = ImageDraw.Draw(sheet)
    cn = CLASS_NAMES_CN[cls]
    
    title = f"{cn} ({cls})  —  v9 立绘一致化动画 · 24 帧"
    d.text((MAR + 8, MAR + 6), title, fill=(220, 200, 140))
    d.text((MAR + 8, MAR + 22), "▸ 6 组动作 × 4 帧  |  外观 = v8 立绘 · 逆像素变形", fill=(120, 140, 170))
    
    y0 = MAR + 42 + MAR
    for ri, (label, fnames) in enumerate(cats):
        y = y0 + ri * (LH + TH + MAR)
        d.rectangle([MAR, y, sw - MAR, y + LH], fill=(24, 32, 46))
        d.rectangle([MAR, y, MAR + 4, y + LH], fill=(220, 60, 60))
        d.text((MAR + 12, y + 5), label, fill=(230, 210, 150))
        d.text((MAR + 120, y + 5), "4 帧循环", fill=(100, 120, 150))
        
        for ci in range(COLS):
            x = MAR + ci * (TW + 8)
            fi = fnames[ci] if ci < len(fnames) else None
            d.rectangle([x, y + LH, x + TW, y + LH + TH], outline=(50, 65, 90), width=1)
            if fi and fi in frames:
                frame_img, _, _ = frames[fi]
                f = frame_img.resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, y + LH))
                d.text((x + 4, y + LH + TH - 12), f"帧 {ci+1}", fill=(100, 115, 140))
    
    sheet.save(f"{OUT}/{cls}_sheet.jpg", "JPEG", quality=92)
    all_sheets[cls] = sheet
    print(f"  ✓ {cls}_sheet.jpg ({sw}×{sh}) — {len(frames)} 帧")

# ============================================================
# 总览 Contact Sheet
# ============================================================
COLS2 = 2; ROWS2 = 2; TW2, TH2 = 340, 360; MAR2 = 24
sw2 = COLS2 * TW2 + (COLS2 + 1) * MAR2
sh2 = ROWS2 * TH2 + (ROWS2 + 1) * MAR2 + 100
ov = Image.new("RGB", (sw2, sh2), (8, 10, 18))
d = ImageDraw.Draw(ov)

d.text((MAR2, 22), "⚔ v9 立绘一致化动画 · Lihui-Matched", fill=(230, 60, 60))
d.text((MAR2, 46), "每帧从 v8 增强立绘逆像素采样 — 动画外观 = 立绘外观 — 零断裂", fill=(170, 180, 200))
d.text((MAR2, 64), f"4 角色 × 6 组动作 × 4 帧 = 共 {4*6*4} 帧  |  7 关节骨架 · 高斯权重", fill=(120, 135, 160))

for idx, cls in enumerate(CLASS_LIST):
    if cls not in all_sheets: continue
    r, c = divmod(idx, COLS2)
    sx = MAR2 + c * (TW2 + MAR2); sy = 100 + MAR2 + r * (TH2 + MAR2)
    s = all_sheets[cls]
    crop = s.crop((8, 42 + 8, min(s.size[0], 8 + TW2), 42 + 8 + TH2)).resize((TW2, TH2), Image.BILINEAR)
    ov.paste(crop, (sx, sy))
    cn = CLASS_NAMES_CN[cls]
    skill = CLASS_SKILL_CN[cls]
    label_line = f"▸ {cn}  |  技能: {skill}"
    d.rectangle([sx, sy - 22, sx + TW2, sy + 2], fill=(18, 24, 36))
    d.text((sx + 8, sy - 18), label_line, fill=(255, 220, 150))
    d.rectangle([sx, sy, sx + TW2, sy + TH2], outline=(200, 70, 70), width=2)

ov.save(f"{OUT}/overview_v9_lihui_matched.jpg", "JPEG", quality=92)
print(f"\n✓ 总览 overview_v9_lihui_matched.jpg: {sw2}×{sh2}")

# === 增强立绘预览 ===
ep_cols = 4; ep_rows = 1; ep_w, ep_h = 256, 256; ep_mar = 20
ep_sw = ep_cols * ep_w + (ep_cols + 1) * ep_mar
ep_sh = ep_h + ep_mar * 2 + 40
ep_ov = Image.new("RGB", (ep_sw, ep_sh), (10, 12, 20))
ep_d = ImageDraw.Draw(ep_ov)
ep_d.text((ep_mar, 14), "v8 增强立绘 · 去背景 + Blinn-Phong 光影 (v9 动画的源图)", fill=(200, 190, 130))

for idx, cls in enumerate(CLASS_LIST):
    if cls not in enhanced_portraits: continue
    ep = enhanced_portraits[cls].resize((ep_w, ep_h), Image.BILINEAR)
    px = ep_mar + idx * (ep_w + ep_mar)
    py = 40 + ep_mar // 2
    ep_ov.paste(ep, (px, py), ep)
    ep_d.text((px, py + ep_h + 4), CLASS_NAMES_CN[cls], fill=(230, 210, 150))

ep_ov.save(f"{OUT}/enhanced_source/overview_enhanced_portraits.jpg", "JPEG", quality=92)
print(f"✓ 增强立绘预览: {OUT}/enhanced_source/overview_enhanced_portraits.jpg")

print(f"\n{'='*70}")
print(f"全部完成! 输出目录: {OUT}/")
print(f"  4 角色 × 6 动作 × 4 帧 = 96 帧")
print(f"  立绘源图: {ENHANCED_DIR}/")
print(f"{'='*70}")
