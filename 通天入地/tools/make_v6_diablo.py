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
        "head":   (253, 52),
        "torso":  (253, 120),
        "pelvis": (253, 314),
        "arm_l":  (42, 138),   # 新图：大剑扛左肩上，左手臂很外扩
        "arm_r":  (367, 138),  # 右手握剑柄
        "leg_l":  (199, 334),
        "leg_r":  (391, 334),
    },
    "sorceress": {
        "head":   (303, 49),
        "torso":  (303, 117),
        "pelvis": (303, 309),
        "arm_l":  (350, 135),  # 角色左臂 (图像右侧) 施法手
        "arm_r":  (145, 135),  # 角色右臂 (图像左侧) 法杖手
        "leg_l":  (181, 329),
        "leg_r":  (312, 329),
    },
    "amazon": {
        "head":   (292, 52),
        "torso":  (292, 120),
        "pelvis": (292, 313),
        "arm_l":  (386, 138),  # 角色左臂 (图像右侧) 拉弦
        "arm_r":  (278, 138),  # 角色右臂 (图像左侧) 持弓
        "leg_l":  (188, 333),
        "leg_r":  (268, 333),
    },
    "assassin": {
        "head":   (267, 80),
        "torso":  (267, 144),
        "pelvis": (267, 326),  # 蹲姿，pelvis Y 较高
        "arm_l":  (311, 162),  # 角色左臂 (图像右侧) 匕首
        "arm_r":  (227, 162),  # 角色右臂 (图像左侧) 匕首
        "leg_l":  (156, 346),
        "leg_r":  (329, 346),
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
    """返回 bone name 在 parent bone 局部坐标系下的位置 (bind pose, portrait 坐标)"""
    parent = PARENT[name]
    if parent is None: return (0, 0)
    px, py = JOINTS[parent][:2]
    cx, cy = JOINTS[name][:2]
    return (cx - px, cy - py)

def fk_portrait(bone_rots, JOINTS, facing=1.0):
    """
    返回 portrait 坐标系下每个 bone 的 (world_rot, world_pos)。
    bind pose: pelvis 在 JOINTS['pelvis'] (256, 310), 所有 rot=0。
    这意味着变形后 world_pos 仍然是 portrait 坐标 — 和原图坐标系一致。
    """
    transforms = {}
    def calc(name):
        if name in transforms: return transforms[name]
        parent = PARENT[name]
        if parent is None:
            # pelvis 是 root, world pos 始终 = bind pos (portrait 坐标)
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

def bone_world_pos_to_canvas(portrait_pos, JOINTS, PELVIS_CANVAS):
    """portrait 坐标 → canvas 坐标 (用于阴影绘制等)"""
    px_bind, py_bind = JOINTS["pelvis"][:2]
    px_canvas, py_canvas = PELVIS_CANVAS
    dx, dy = portrait_pos[0] - px_bind, portrait_pos[1] - py_bind
    return (px_canvas + dx, py_canvas + dy)

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

def deform_pixel(dst_x_portrait, dst_y_portrait, weights_at_v, bone_transforms, facing, JOINTS):
    """
    反向 FK — 给定变形后的 portrait 坐标, 求 bind pose (原图) 坐标。

    原理:
      forward:  local → world_cur = R(brot) · local + world_pos_cur
      reverse:  world_cur → local = R(-brot) · (world_cur - world_pos_cur)
      bind_pose: local → world_bind = R(0) · local + bind_pos = local + bind_pos

    对每个 bone, 把 dst (当前 world_cur portrait 坐标) 变到 local, 再加 bind_pos 得到 src。
    所有 bone 的贡献用 weights_at_v 加权 blend。

    Args:
      dst_x_portrait, dst_y_portrait: 当前姿势下该像素在 portrait 坐标系的位置
      weights_at_v: 7 个 bone 的混合权重
      bone_transforms: fk_portrait 返回的 {bone_name: (rot, world_pos_portrait)}
      facing: 1.0 或 -1.0
      JOINTS: bind pose 下各 bone 的 portrait world pos

    Returns:
      (src_x, src_y): 该像素应该从原图哪里采样
    """
    vx_new, vy_new = 0.0, 0.0
    for bi, bname in enumerate(BONE_NAMES):
        w = weights_at_v[bi]
        if w < 1e-4: continue
        brot, (wx_cur, wy_cur) = bone_transforms[bname]
        # 1. world_cur → local
        inv_rot = math.radians(-brot)
        lx = (dst_x_portrait - wx_cur) * math.cos(inv_rot) - (dst_y_portrait - wy_cur) * math.sin(inv_rot)
        ly = (dst_x_portrait - wx_cur) * math.sin(inv_rot) + (dst_y_portrait - wy_cur) * math.cos(inv_rot)
        # 2. local + bind_pos → world_bind (即 src 坐标)
        bx_bind, by_bind = JOINTS[bname][:2]
        vx_new += w * (lx + bx_bind)
        vy_new += w * (ly + by_bind)
    if facing < 0:
        vx_new = 512 - vx_new
    return (vx_new, vy_new)

def remove_bg_soft(img, color_tol=6):
    """
    反向 flood fill 背景去除 — 利用背景是纯色这一事实。

    Step 1: 统计图像边缘像素的主色 (mode) 作为背景基准色。
    Step 2: 从四边向内 BFS, 标记所有与背景色色差 <= color_tol 的连通像素为背景。
            反向: 剩余像素 = 角色 (包括黑衣服、阴影 — 只要和背景色差 > 6)。

    color_tol: RGB 每个通道的色差容差, 默认 6。
               背景 (14,16,28) 和黑衣服 (如 8,8,12) 各通道差可能 < 6,
               但整体色差 max(|dr|,|dg|,|db|) > 6。
    """
    arr = img.convert("RGBA").load()
    w, h = img.size
    
    # Step 1: 估计背景主色 — 边缘像素取中位数
    import statistics as st
    edge_rs, edge_gs, edge_bs = [], [], []
    for x in range(w):
        for y in [0, h - 1]:
            r, g, b, a = arr[x, y]
            edge_rs.append(r); edge_gs.append(g); edge_bs.append(b)
    for y in range(1, h - 1):
        for x in [0, w - 1]:
            r, g, b, a = arr[x, y]
            edge_rs.append(r); edge_gs.append(g); edge_bs.append(b)
    bg_r = int(st.median(edge_rs))
    bg_g = int(st.median(edge_gs))
    bg_b = int(st.median(edge_bs))
    bg_brightness = (bg_r + bg_g + bg_b) / 3
    
    # 自适应容差: 如果背景很暗 (亮度<20), 用 color_tol; 如果背景稍亮, 用更宽松的
    tol = color_tol if bg_brightness < 20 else color_tol + 4
    
    def is_near_bg(r, g, b):
        """像素 (r,g,b) 是否接近背景色"""
        return (abs(r - bg_r) <= tol and 
                abs(g - bg_g) <= tol and 
                abs(b - bg_b) <= tol)
    
    # Step 2: 从四边 BFS 标记背景
    from collections import deque
    is_bg = [[False] * h for _ in range(w)]
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if is_bg[x][y]: continue
        r, g, b, a = arr[x, y]
        if not is_near_bg(r, g, b): continue  # 不是背景色
        is_bg[x][y] = True
        for dx_, dy_ in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
            nx, ny = x + dx_, y + dy_
            if 0 <= nx < w and 0 <= ny < h and not is_bg[nx][ny]:
                q.append((nx, ny))
    
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    oarr = out.load()
    for y in range(h):
        for x in range(w):
            if not is_bg[x][y]:
                oarr[x, y] = arr[x, y]
    return out

def render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                   bone_transforms_portrait, facing, pelvis_canvas, canvas_w, canvas_h, bbox):
    """
    bone_transforms_portrait 是 fk_portrait 返回的 portrait 坐标系结果。
    本函数把每个 canvas 像素映射到 portrait 坐标, 用反向 FK 求 src 坐标采样原图。
    """
    arr = img_alpha.load()
    w, h = img_alpha.size
    bx1, by1, bx2, by2 = bbox
    
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (14, 18, 28, 255))
    carr = canvas.load()
    
    draw = ImageDraw.Draw(canvas)
    # 阴影: pelvis 在 portrait 坐标系, 转成 canvas 坐标来画
    pel_rot, pel_t_portrait = bone_transforms_portrait["pelvis"]
    pel_t_canvas = bone_world_pos_to_canvas(pel_t_portrait, JOINTS, pelvis_canvas)
    shadow_w = max(40, (bx2 - bx1) * 0.5)
    draw.ellipse([pel_t_canvas[0] - shadow_w/2, pel_t_canvas[1] + 15, 
                  pel_t_canvas[0] + shadow_w/2, pel_t_canvas[1] + 28], 
                 fill=(0, 0, 0, 80))
    
    px_bind, py_bind = JOINTS["pelvis"][:2]
    
    for dy in range(canvas_h):
        for dx in range(canvas_w):
            # canvas 像素 → portrait 坐标
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
            
            # off_x, off_y 已经是 portrait 坐标, 直接传给 deform_pixel
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
                carr[dx, dy] = (r, g, b, 255)
    
    return canvas.convert("RGB")

# ============================================================
# 姿势库 (Diablo 风格, 全中文分类标签)
# ============================================================

CLASS_NAMES_CN = {
    "barbarian": "野蛮人",
    "sorceress": "女巫",
    "amazon": "亚马逊",
    "assassin": "刺客",
}

CLASS_SKILL_CN = {
    "barbarian": "旋风斩",     # Whirlwind
    "sorceress": "陨石术",     # Meteor
    "amazon":    "多重射击",   # Multishot
    "assassin":  "影袭",       # Shadow Strike
}

# 每个动作分类 (中文 label, 英文 id, 帧数, 循环? )
# (中文标签, 英文前缀, 帧数, 描述)

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

# ============================================================
# 6 组姿势 (每组 4 帧)
# ============================================================

# ① 站立待机 (呼吸微摆, 循环)
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

# ② 行走循环
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

# ③ 普攻 (挥砍/拉弓)
ATTACK_KFS = {
    "barbarian": [  # 大剑横扫
        (0.00, {"pelvis":0,"torso":-5,"head":0,"arm_l":20,"arm_r":-100,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":2,"torso":20,"head":8,"arm_l":-40,"arm_r":-175,"leg_l":-10,"leg_r":10}),
        (0.60, {"pelvis":0,"torso":25,"head":10,"arm_l":-50,"arm_r":-180,"leg_l":-12,"leg_r":12}),
        (1.00, {"pelvis":0,"torso":-5,"head":0,"arm_l":20,"arm_r":-100,"leg_l":0,"leg_r":0}),
    ],
    "sorceress": [  # 施法蓄力
        (0.00, {"pelvis":0,"torso":0,"head":4,"arm_l":25,"arm_r":-25,"leg_l":0,"leg_r":0}),
        (0.30, {"pelvis":0,"torso":-5,"head":12,"arm_l":100,"arm_r":-100,"leg_l":2,"leg_r":-2}),
        (0.60, {"pelvis":0,"torso":-8,"head":18,"arm_l":120,"arm_r":-120,"leg_l":4,"leg_r":-4}),
        (1.00, {"pelvis":0,"torso":0,"head":4,"arm_l":25,"arm_r":-25,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [  # 拉弓放箭
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

# ④ 技能释放 (每职业独特大招蓄力)
SKILL_KFS = {
    "barbarian": [  # 旋风斩 — 身体旋转蓄力
        (0.00, {"pelvis":0,"torso":-10,"head":-5,"arm_l":60,"arm_r":-120,"leg_l":8,"leg_r":-8}),
        (0.25, {"pelvis":0,"torso":-25,"head":-12,"arm_l":120,"arm_r":-150,"leg_l":15,"leg_r":-15}),
        (0.50, {"pelvis":0,"torso":-40,"head":-20,"arm_l":170,"arm_r":-170,"leg_l":22,"leg_r":-22}),
        (1.00, {"pelvis":0,"torso":-10,"head":-5,"arm_l":60,"arm_r":-120,"leg_l":8,"leg_r":-8}),
    ],
    "sorceress": [  # 陨石术 — 双臂高举蓄力
        (0.00, {"pelvis":0,"torso":-5,"head":10,"arm_l":90,"arm_r":-90,"leg_l":0,"leg_r":0}),
        (0.25, {"pelvis":-3,"torso":-10,"head":20,"arm_l":130,"arm_r":-130,"leg_l":3,"leg_r":-3}),
        (0.50, {"pelvis":-5,"torso":-15,"head":28,"arm_l":160,"arm_r":-160,"leg_l":5,"leg_r":-5}),
        (1.00, {"pelvis":0,"torso":-5,"head":10,"arm_l":90,"arm_r":-90,"leg_l":0,"leg_r":0}),
    ],
    "amazon": [  # 多重射击 — 双手拉满弓
        (0.00, {"pelvis":-5,"torso":10,"head":8,"arm_l":-50,"arm_r":80,"leg_l":10,"leg_r":-10}),
        (0.25, {"pelvis":-10,"torso":18,"head":10,"arm_l":-70,"arm_r":100,"leg_l":14,"leg_r":-14}),
        (0.50, {"pelvis":-12,"torso":22,"head":12,"arm_l":-85,"arm_r":115,"leg_l":16,"leg_r":-16}),
        (1.00, {"pelvis":-5,"torso":10,"head":8,"arm_l":-50,"arm_r":80,"leg_l":10,"leg_r":-10}),
    ],
    "assassin": [  # 影袭 — 身体下蹲蓄力
        (0.00, {"pelvis":-2,"torso":5,"head":2,"arm_l":20,"arm_r":-20,"leg_l":-15,"leg_r":15}),
        (0.25, {"pelvis":-4,"torso":15,"head":5,"arm_l":-20,"arm_r":20,"leg_l":-25,"leg_r":25}),
        (0.50, {"pelvis":-6,"torso":25,"head":8,"arm_l":-35,"arm_r":35,"leg_l":-32,"leg_r":32}),
        (1.00, {"pelvis":-2,"torso":5,"head":2,"arm_l":20,"arm_r":-20,"leg_l":-15,"leg_r":15}),
    ],
}

# ⑤ 挥手致意 (日常交互)
def wave_frame(k):
    phase = math.sin(2 * math.pi * k / 4)
    return {
        "pelvis": 0,
        "torso": phase * -3,
        "head": phase * -2,
        "arm_l": 10 + phase * 8,
        "arm_r": -140 - phase * 25,  # 右手举起挥舞
        "leg_l": 0,
        "leg_r": 0,
    }

# ⑥ 欢呼庆祝 (日常交互)
def cheer_frame(k):
    # 0: 双手举起欢呼, 1: 双手高举, 2: 保持, 3: 回到微举
    phases = [0.0, 1.0, 1.0, 0.3]
    p = phases[k]
    return {
        "pelvis": 0,
        "torso": -2 - p * 4,
        "head": 2 + p * 6,
        "arm_l": 60 + p * 100,   # 左手举起
        "arm_r": -60 - p * 100,  # 右手举起
        "leg_l": p * -3,
        "leg_r": p * 3,
    }

# ============================================================
# 主流程 — 6 组动作 × 4 帧 = 24 帧/角色
# ============================================================

CLASS_LIST = ["barbarian", "sorceress", "amazon", "assassin"]
CANVAS_W, CANVAS_H = 560, 640
PELVIS_CANVAS = (CANVAS_W // 2, CANVAS_H - 80)

# 6 个动作组定义: (中文标签, 英文前缀, 生成函数_or_keyframes_dict)
ACTION_GROUPS = [
    ("待机", "idle",   lambda cls, k: idle_frame(k),      "站立呼吸微摆"),
    ("行走", "run",    lambda cls, k: run_frame(cls, k),   "行走循环"),
    ("普攻", "attack", None,                                "基础攻击"),   # 用 ATTACK_KFS
    ("技能释放", "skill", None,                             None),          # 用 SKILL_KFS, CN label 按职业变
    ("挥手致意", "wave",   lambda cls, k: wave_frame(k),   "日常交互 · 挥手"),
    ("欢呼庆祝", "cheer",  lambda cls, k: cheer_frame(k),  "日常交互 · 欢呼"),
]

print("=" * 60)
print("v6 — Diablo 风格完整精灵绑定 (反向像素级变形 · 零断裂)")
print("     6 组动作 × 4 帧 = 24 帧/角色 — 全中文标注")
print("=" * 60)

all_sheets = {}

for cls in CLASS_LIST:
    print(f"\n{'─'*10} {CLASS_NAMES_CN[cls]} {'─'*10}")
    
    # --- 初始化 ---
    img_raw = Image.open(f"{NEW_PORT}/{cls}.png").convert("RGBA")
    raw_joints = MANUAL_RAW_JOINTS[cls]
    img_norm, norm_joints_full = normalize_portrait(img_raw, raw_joints, (256, 310))
    JOINTS = {k: v for k, v in norm_joints_full.items() if k != "bbox"}
    bbox = norm_joints_full["bbox"]
    img_alpha = remove_bg_soft(img_norm)
    bx1, by1, bx2, by2 = bbox
    char_w = bx2 - bx1
    SIGMA = max(50, min(100, char_w * 0.16))
    weights_grid, grid_step, gw, gh = compute_weights_grid(JOINTS, bbox, grid_step=4, sigma=SIGMA)
    
    frames = {}
    
    # --- 生成 6 × 4 = 24 帧 ---
    for gidx, (cn_label, en_prefix, gen_func, desc) in enumerate(ACTION_GROUPS):
        # 技能释放的中文标签按职业变
        if cn_label == "技能释放":
            cn_label_show = CLASS_SKILL_CN[cls]
        else:
            cn_label_show = cn_label
        
        for k in range(4):
            # 计算该帧的关节旋转
            if en_prefix == "attack":
                rots = interp(ATTACK_KFS[cls], ATTACK_KFS[cls][k][0])
            elif en_prefix == "skill":
                rots = interp(SKILL_KFS[cls], SKILL_KFS[cls][k][0])
            else:
                rots = gen_func(cls, k)
            
            bt = fk_portrait(rots, JOINTS, 1.0)
            canvas = render_reverse(img_alpha, JOINTS, weights_grid, grid_step, gw, gh,
                                    bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, bbox)
            frame_key = f"{en_prefix}_{k+1}"
            frames[frame_key] = (canvas, cn_label_show, k + 1)
    
    # --- 保存各帧 ---
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, (frame, _, _) in frames.items():
        frame.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # --- Contact Sheet (全中文) ---
    cats = []
    for cn_label, en_prefix, gen_func, desc in ACTION_GROUPS:
        if cn_label == "技能释放":
            label = CLASS_SKILL_CN[cls]
        else:
            label = cn_label
        fnames = [f"{en_prefix}_{k}" for k in range(1, 5)]
        cats.append((label, fnames))
    
    COLS = 4; TW, TH = 140, 160; LH = 26; MAR = 8
    rows = len(cats)
    sw = MAR * 2 + COLS * (TW + 8)
    sh = MAR + 30 + MAR + rows * (LH + TH + MAR)
    sheet = Image.new("RGB", (sw, sh), (12, 16, 24))
    d = ImageDraw.Draw(sheet)
    cn = CLASS_NAMES_CN[cls]
    
    # 标题
    title = f"{cn} ({cls})  —  Diablo 风格精灵绑定 · 反向变形无断裂 · 24 帧"
    d.text((MAR + 8, MAR + 6), title, fill=(220, 200, 140))
    d.text((MAR + 8, MAR + 22), "▸ 6 组动作 × 4 帧  |  7 关节骨架 · 高斯权重", fill=(120, 140, 170))
    
    y0 = MAR + 42 + MAR
    for ri, (label, fnames) in enumerate(cats):
        y = y0 + ri * (LH + TH + MAR)
        # 行标题背景
        d.rectangle([MAR, y, sw - MAR, y + LH], fill=(24, 32, 46))
        d.rectangle([MAR, y, MAR + 4, y + LH], fill=(220, 60, 60))  # 左侧红色装饰条
        d.text((MAR + 12, y + 5), label, fill=(230, 210, 150))
        d.text((MAR + 120, y + 5), f"{4} 帧循环", fill=(100, 120, 150))
        
        for ci in range(COLS):
            x = MAR + ci * (TW + 8)
            fi = fnames[ci] if ci < len(fnames) else None
            d.rectangle([x, y + LH, x + TW, y + LH + TH], outline=(50, 65, 90), width=1)
            if fi and fi in frames:
                frame_img, _, _ = frames[fi]
                f = frame_img.resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, y + LH))
                # 帧号 (底部小字)
                d.text((x + 4, y + LH + TH - 12), f"帧 {ci+1}", fill=(100, 115, 140))
    
    sheet.save(f"{OUT}/{cls}_sheet.jpg", "JPEG", quality=92)
    all_sheets[cls] = sheet
    total_frames = len([f for f in frames])
    print(f"  ✓ {cls}_sheet.jpg ({sw}×{sh}) — {total_frames} 帧")

# ============================================================
# 总览 Contact Sheet (全中文)
# ============================================================
COLS2 = 2; ROWS2 = 2; TW2, TH2 = 340, 360; MAR2 = 24
sw2 = COLS2 * TW2 + (COLS2 + 1) * MAR2
sh2 = ROWS2 * TH2 + (ROWS2 + 1) * MAR2 + 100
ov = Image.new("RGB", (sw2, sh2), (8, 10, 18))
d = ImageDraw.Draw(ov)

d.text((MAR2, 22), "⚔ Diablo 风格完整精灵绑定 · v6", fill=(230, 60, 60))
d.text((MAR2, 46), "反向像素级变形 — 每像素逆 FK 映射原图采样 — 零断裂", fill=(170, 180, 200))
d.text((MAR2, 64), f"4 角色 × 6 组动作 × 4 帧 = 共 {4*6*4} 帧  |  7 关节骨架 · 高斯权重 · AI 生成", fill=(120, 135, 160))

for idx, cls in enumerate(CLASS_LIST):
    r, c = divmod(idx, COLS2)
    sx = MAR2 + c * (TW2 + MAR2); sy = 100 + MAR2 + r * (TH2 + MAR2)
    s = all_sheets[cls]
    crop = s.crop((8, 42 + 8, min(s.size[0], 8 + TW2), 42 + 8 + TH2)).resize((TW2, TH2), Image.BILINEAR)
    ov.paste(crop, (sx, sy))
    # 角色名 + 中文标签
    cn = CLASS_NAMES_CN[cls]
    skill = CLASS_SKILL_CN[cls]
    label_line = f"▸ {cn}  |  技能: {skill}"
    d.rectangle([sx, sy - 22, sx + TW2, sy + 2], fill=(18, 24, 36))
    d.text((sx + 8, sy - 18), label_line, fill=(255, 220, 150))
    d.rectangle([sx, sy, sx + TW2, sy + TH2], outline=(200, 70, 70), width=2)

ov.save(f"{OUT}/overview_v6_diablo.jpg", "JPEG", quality=92)
print(f"\n✓ 总览 overview_v6_diablo.jpg: {sw2}×{sh2}")
print(f"\n全部完成! 输出: {OUT}/")
print(f"  4 角色 × 6 动作 × 4 帧 = 96 帧 — 全部无断裂, 全中文标注")
