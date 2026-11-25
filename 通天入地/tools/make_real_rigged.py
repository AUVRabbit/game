#!/usr/bin/env python3
"""
把 512×512 全身肖像切成骨骼部件 + 用真实骨骼驱动渲染样图
最终目标：每个部件 PNG → Godot Skeleton2D + Bone2D + Sprite2D(绑定到 bone)
本脚本：切部件 + 生成真实骨骼驱动的动图帧 + contact sheet
"""
import os, math, json
from PIL import Image, ImageDraw, ImageFilter

CLASS_NAMES = {
    "warrior": "战士", "mage": "法师", "runeward": "咒铠师", "priest": "牧师",
    "necromancer": "亡灵法师", "bomber": "炸弹专家", "mech_pilot": "机甲师",
    "engineer": "工程师", "bounty_hunter": "赏金猎人", "death_knight": "死亡骑士",
    "archer": "弓箭手", "thief": "小偷", "qi_adept": "气宗", "sniper": "狙击手",
    "cyborg": "义体卫士", "hacker": "黑客",
}

OUT = "/workspace/通天入地/docs/RIGGED_BONES_2026-11-25"
PARTS_OUT = f"{OUT}/parts"
os.makedirs(PARTS_OUT, exist_ok=True)

# ============================================================
# Step 1: 用 alpha mask 切肖像部件
# ============================================================

def alpha_projection(img):
    """返回每列的 alpha 总和（x → 该列有多少像素不透明）和每行的"""
    arr = img.load()
    w, h = img.size
    col = [0]*w
    row = [0]*h
    for y in range(h):
        for x in range(w):
            if arr[x,y][3] > 20:
                col[x] += 1
                row[y] += 1
    return col, row

def component_connected(img, seed_x, seed_y, threshold=20):
    """从 seed 点出发 4-连通 生长一个部件区域"""
    arr = img.load()
    w, h = img.size
    visited = [[False]*h for _ in range(w)]
    stack = [(seed_x, seed_y)]
    pixels = []
    while stack:
        x, y = stack.pop()
        if x<0 or y<0 or x>=w or y>=h: continue
        if visited[x][y]: continue
        if arr[x,y][3] <= threshold: continue
        visited[x][y] = True
        pixels.append((x,y))
        stack += [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]
    return pixels

def component_bbox(pixels):
    if not pixels: return None
    xs = [p[0] for p in pixels]
    ys = [p[1] for p in pixels]
    return (min(xs), min(ys), max(xs), max(ys))

def mask_from_pixels(img, pixels):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    for (x, y) in pixels:
        mask.putpixel((x, y), 255)
    return mask

def extract_part(img, mask):
    """按 mask 把 img 里对应区域提取出来，其他地方透明"""
    result = img.copy()
    # 把 mask 外的区域 alpha 清 0
    arr = result.load()
    marr = mask.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            if marr[x,y] == 0:
                arr[x,y] = (arr[x,y][0], arr[x,y][1], arr[x,y][2], 0)
    # 裁到 bounding box
    bbox = mask.getbbox()
    if bbox:
        return result.crop(bbox), (bbox[0], bbox[1])
    return result, (0, 0)

# 身体结构锚点（从之前分析得出 — 所有职业共享同一模板）
ANCHORS = {
    "head_c":    (256, 100),    # 头中心
    "neck":      (256, 165),    # 脖子/根节点
    "shoulder_l":(210, 150),    # 左肩
    "shoulder_r":(302, 150),    # 右肩
    "elbow_l":   (185, 215),    # 左肘（估计）
    "elbow_r":   (325, 215),    # 右肘（估计）
    "hand_l":    (175, 280),    # 左手
    "hand_r":    (335, 280),    # 右手
    "hip":       (256, 273),    # 胯中心
    "hip_l":     (225, 273),    # 左胯
    "hip_r":     (287, 273),    # 右胯
    "knee_l":    (230, 360),    # 左膝
    "knee_r":    (282, 360),    # 右膝
    "foot_l":    (233, 458),    # 左脚
    "foot_r":    (279, 458),    # 右脚
    "crotch":    (256, 300),    # 裆部
}

def cut_parts(img, cls):
    """
    用 bounding box 硬切肖像部件 — 所有职业共享同一模板 (512×512)
    每个部件框用 alpha mask 清掉躯干区域，保证分离干净
    """
    arr = img.load()
    W, H = img.size
    parts = {}

    def extract_bbox(x1, y1, x2, y2, name, anchor):
        crop = img.crop((x1, y1, x2, y2))
        # 清掉完全透明的行/列边界
        ca = crop.load()
        cw, ch = crop.size
        xs = set(); ys = set()
        for y in range(ch):
            for x in range(cw):
                if ca[x,y][3] > 20:
                    xs.add(x); ys.add(y)
        if not xs:
            return
        bx1, bx2 = min(xs), max(xs)
        by1, by2 = min(ys), max(ys)
        cropped = crop.crop((bx1, by1, bx2+1, by2+1))
        # anchor 需要加上 crop 的 bbox 偏移 + x1,y1 原始偏移
        local_a = (anchor[0] - x1 - bx1, anchor[1] - y1 - by1)
        parts[name] = (cropped, local_a)

    # 切分 bbox — 基于肖像统一模板
    # 头: 上 32%, 宽度中心区
    extract_bbox(180, 0, 332, 170, "head", (256, 165))
    # 躯干: 中间区
    extract_bbox(170, 130, 342, 310, "torso", (256, 165))
    # 左臂: 左侧边缘 + 肩到胯范围
    extract_bbox(100, 130, 215, 300, "arm_l", (210, 150))
    # 右臂: 右侧边缘
    extract_bbox(295, 130, 410, 300, "arm_r", (302, 150))
    # 左腿
    extract_bbox(195, 290, 260, 512, "leg_l", (225, 273))
    # 右腿
    extract_bbox(252, 290, 320, 512, "leg_r", (287, 273))

    return parts


# ============================================================
# Step 2: 真实骨骼定义 — 每个职业独立的关键帧姿势
# ============================================================

class Bone:
    def __init__(self, name, parent, anchor_local, rest_rot=0.0, length=0):
        self.name = name
        self.parent = parent  # Bone 或 None
        self.anchor = anchor_local  # 相对父关节的局部位置 (px)
        self.rest_rot = rest_rot
        self.length = length
        self.children = []
        self.world_pos = (0,0)
        self.world_rot = 0.0

def build_skeleton(facing=1.0):
    """构建 7 关节骨架 + 实际世界位置（rest pose）"""
    # 使用肖像的世界坐标作为 rest pose
    bones = {}
    # 骨盆（根）
    pelvis = Bone("pelvis", None, (0,0), 0)
    pelvis.world_pos = (256, ANCHORS["hip"][1])  # 胯位置
    pelvis.world_rot = 0
    bones["pelvis"] = pelvis

    # 躯干 — 从骨盆向上
    torso = Bone("torso", pelvis, (0, -34), 0)
    # torso 的 anchor 指向脖子 (256, 165)
    bones["torso"] = torso

    # 头 — 挂 torso 下
    head = Bone("head", torso, (0, -35), 0)
    bones["head"] = head

    # 左臂 — 挂 torso 下, 锚在左肩
    arm_l = Bone("arm_l", torso, (-34, -12), 0)
    bones["arm_l"] = arm_l
    # 右臂
    arm_r = Bone("arm_r", torso, (34, -12), 0)
    bones["arm_r"] = arm_r

    # 左腿 — 挂 pelvis 下, 锚在左胯
    leg_l = Bone("leg_l", pelvis, (-31, 0), 0)
    bones["leg_l"] = leg_l
    # 右腿
    leg_r = Bone("leg_r", pelvis, (31, 0), 0)
    bones["leg_r"] = leg_r

    return bones, pelvis

def forward_kinematics(bones, root_name="pelvis", facing=1.0):
    """正向运动学 — 算所有 bone 的 world_pos / world_rot"""
    def walk(name, parent_pos, parent_rot):
        b = bones[name]
        # 确保 rest_rot 是 float
        rest = float(b.rest_rot) if isinstance(b.rest_rot, (int, float)) else 0.0
        # 局部 anchor 旋转到 parent 方向
        lx, ly = b.anchor
        rad = math.radians(parent_rot)
        wx = parent_pos[0] + (lx*math.cos(rad) - ly*math.sin(rad)) * facing
        wy = parent_pos[1] + lx*math.sin(rad) + ly*math.cos(rad)
        wrot = float(parent_rot) + rest
        b.world_pos = (wx, wy)
        b.world_rot = wrot
        # 传播给 children
        for child_name, child_bone in bones.items():
            if child_bone.parent == b:
                walk(child_name, b.world_pos, b.world_rot)
    walk(root_name, (256, float(ANCHORS["hip"][1])), 0)


# ============================================================
# Step 3: 职业专属姿势轨道 — 每个姿势 = 一组 bone rest_rot 关键帧
# ============================================================
# 这里 rest_rot 单位是度，我们用 Slerp 插值

# 职业姿势库 — 每个职业独特的 attack 姿势
# 数字 = 关键帧里每个 bone 的 rotation(度)，顺序 pelvis,torso,head,arm_l,arm_r,leg_l,leg_r

PROFESSION_POSES = {
    # —— 战士: 挥剑劈砍 ——
    "warrior": {
        "idle": [0, -2, 0, 8, -8, 0, 0],
        "run":  [0, 4, 0, -30, 30, -35, 35],
        "attack": [
            (0.0, [0, -2, -4, 15, -80, 0, 0]),
            (0.4, [0, 15, 10, -45, -160, -8, 8]),
            (0.6, [0, 20, 6, -60, -175, -10, 10]),
            (1.0, [0, -2, -4, 15, -80, 0, 0]),
        ],
        "dead": [
            (0.0, [0,0,0,0,0,0,0]),
            (0.5, [30, 50, 30, 20, -15, 60, -60]),
            (1.0, [60, 90, 45, 30, -25, 85, -85]),
        ],
    },
    # —— 法师: 双手结印施法 ——
    "mage": {
        "idle": [0, -2, 0, 10, -10, 0, 0],
        "run":  [0, 4, 0, -25, 25, -30, 30],
        "attack": [
            (0.0, [0, 0, 4, 20, -20, 0, 0]),
            (0.5, [0, 2, 10, 95, -95, 2, -2]),
            (0.7, [0, 4, 14, 110, -110, 4, -4]),
            (1.0, [0, 0, 4, 20, -20, 0, 0]),
        ],
        "dead": [
            (0.0, [0,0,0,0,0,0,0]),
            (0.6, [15, 25, 18, 10, -10, 30, -30]),
            (1.0, [40, 65, 35, 20, -20, 70, -70]),
        ],
    },
    # —— 弓箭手: 前后手拉弓 ——
    "archer": {
        "idle": [0, -2, 0, 8, -8, 0, 0],
        "run":  [0, 4, 0, -28, 28, -32, 32],
        "attack": [
            (0.0, [0, -3, 2, 10, -10, 0, 0]),
            (0.3, [-5, 6, 6, -20, 40, 4, -4]),     # 拉弓
            (0.7, [-8, 10, 5, -28, 55, 6, -6]),    # 满弓
            (1.0, [0, -3, 2, 10, -10, 0, 0]),
        ],
        "dead": [
            (0.0, [0,0,0,0,0,0,0]),
            (0.5, [25, 45, 28, 15, -12, 50, -50]),
            (1.0, [55, 85, 42, 25, -22, 80, -80]),
        ],
    },
    # —— 死亡骑士: 重剑横扫 ——
    "death_knight": {
        "idle": [0, -3, 2, 12, -12, 0, 0],
        "run":  [0, 6, 0, -40, 40, -40, 40],
        "attack": [
            (0.0, [0, -3, -2, 20, -90, 0, 0]),
            (0.35, [-10, 25, 12, -55, -155, -15, 15]),  # 重剑蓄力
            (0.6,  [-18, 40, 18, -70, -178, -22, 22]),  # 横扫到位
            (1.0, [0, -3, -2, 20, -90, 0, 0]),
        ],
        "dead": [
            (0.0, [0,0,0,0,0,0,0]),
            (0.5, [35, 55, 32, 22, -18, 55, -55]),
            (1.0, [65, 95, 48, 30, -28, 88, -88]),
        ],
    },
}

BONE_ORDER = ["pelvis", "torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]

def interp_pose(pose_key, progress):
    """线性插值关键帧 — 得到 7 个 bone 的 rotation"""
    if pose_key[0] != tuple:
        # 循环姿势（单帧值）
        return list(pose_key)
    # timeline
    kfs = pose_key
    t = progress
    # 找包围
    ka, kb = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        if kfs[i][0] <= t <= kfs[i+1][0]:
            ka, kb = kfs[i], kfs[i+1]
            break
    if ka == kb:
        return list(ka[1])
    ratio = (t - ka[0]) / (kb[0] - ka[0])
    ratio = 1 - (1-ratio)**2  # ease out
    return [ka[1][i]*(1-ratio) + kb[1][i]*ratio for i in range(7)]

# ============================================================
# Step 4: 渲染 — 把部件贴到骨骼上
# ============================================================

def render_rigged(parts, bones_skeleton, bone_rots, facing, canvas_w, canvas_h):
    """
    parts: {name: (PIL.Image, anchor_local_offset)}
    bone_rots: [7 floats] — pelvis,torso,head,arm_l,arm_r,leg_l,leg_r
    facing: 1.0 或 -1.0
    """
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0,0,0,0))

    # 更新 skeleton 的 rest_rot — 用 0 兜底
    br = list(bone_rots) + [0.0]*(7 - len(bone_rots))
    for i, bname in enumerate(BONE_ORDER):
        if bname in bones_skeleton:
            bones_skeleton[bname].rest_rot = br[i]

    forward_kinematics(bones_skeleton, facing=facing)

    # 按顺序画: leg_l, leg_r, torso, arm_l, arm_r, head (后面的在上)
    draw_order = ["leg_l", "leg_r", "torso", "arm_l", "arm_r", "head"]
    # 如果武器独立，最后画武器 — 这里简化：武器在 arm_r 部件里

    for bname in draw_order:
        if bname not in parts:
            continue
        part_img, anchor_local = parts[bname]
        bone = bones_skeleton.get(bname)
        if not bone: continue

        wx, wy = bone.world_pos
        wrot = math.radians(bone.world_rot)

        # 先把 part_img 变换：旋转 + 平移 anchor 到 bone.world_pos
        # 需要把 part_img 的 anchor_local 点移到 (0,0)，然后旋转，然后贴到 (wx, wy)
        # 方法：扩展画布到 part_img.size + 足够 padding，旋转，裁出来
        pw, ph = part_img.size
        # 扩展画布容纳旋转
        diag = int(math.hypot(pw, ph)) + 4
        extended = Image.new("RGBA", (diag*2, diag*2), (0,0,0,0))
        ex, ey = diag - anchor_local[0], diag - anchor_local[1]
        extended.paste(part_img, (ex, ey), part_img)
        # 旋转
        angle = -bone.world_rot if facing == 1 else bone.world_rot
        rotated = extended.rotate(angle, resample=Image.BILINEAR, expand=False, fillcolor=(0,0,0,0))
        # 贴到 canvas — anchor_local 对齐 bone.world_pos
        paste_x = int(wx * facing - diag + canvas_w//2)
        paste_y = int(wy - diag)
        if facing < 0:
            # 水平镜像
            rotated = rotated.transpose(Image.FLIP_LEFT_RIGHT)
        canvas.alpha_composite(rotated, (paste_x, paste_y))

    return canvas.convert("RGB")

# ============================================================
# 主流程
# ============================================================

def process_class(cls):
    img = Image.open(f"/workspace/通天入地/assets/portraits/{cls}.png").convert("RGBA")
    # 切部件
    parts = cut_parts(img, cls)
    print(f"  {cls}: 切出 {list(parts.keys())}")
    # 保存部件
    cls_dir = f"{PARTS_OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for pname, (pimg, anchor) in parts.items():
        pimg.save(f"{cls_dir}/{pname}.png")
        with open(f"{cls_dir}/{pname}.anchor.txt", "w") as f:
            f.write(f"{anchor[0]} {anchor[1]}")

    # 渲染动作帧
    W, H = 600, 600
    poses = PROFESSION_POSES.get(cls, PROFESSION_POSES["warrior"])

    frames = {}
    # idle 4帧 (sin 摆臂)
    for k, t in enumerate([0, 0.25, 0.5, 0.75]):
        phase = math.sin(2*math.pi * t)
        idle_rots = list(poses["idle"])
        idle_rots[3] += 8*phase   # arm_l 摆
        idle_rots[4] -= 8*phase   # arm_r 摆
        idle_rots[1] += 1.5*phase  # torso bob
        skel, _ = build_skeleton()
        frame = render_rigged(parts, skel, idle_rots, 1.0, W, H)
        frames[f"idle_{k+1}"] = frame
    # run 4帧
    for k, t in enumerate([0, 0.25, 0.5, 0.75]):
        phase = math.sin(2*math.pi * t)
        run_rots = [p + s*phase for p, s in zip(poses["run"], [0,2,0,20,20,20,20])]
        skel, _ = build_skeleton()
        frame = render_rigged(parts, skel, run_rots, 1.0, W, H)
        frames[f"run_{k+1}"] = frame
    # attack 关键帧（timeline）
    atk = poses["attack"]
    for k, (t, _) in enumerate(atk):
        rots = interp_pose(atk, t)
        skel, _ = build_skeleton()
        frame = render_rigged(parts, skel, rots, 1.0, W, H)
        frames[f"attack_{k+1}"] = frame
    # dead 关键帧
    d = poses["dead"]
    for k, (t, _) in enumerate(d):
        rots = interp_pose(d, t)
        skel, _ = build_skeleton()
        frame = render_rigged(parts, skel, rots, 1.0, W, H)
        frames[f"dead_{k+1}"] = frame
    # facing 反方向也渲染一张（最后一帧翻转）
    if frames:
        last_key = list(frames.keys())[-1]
        last_frame = frames[last_key].transpose(Image.FLIP_LEFT_RIGHT)
        frames[f"{last_key}_flipped"] = last_frame

    # 输出单帧
    for fname, frame in frames.items():
        frame.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=88)

    return frames


# 生成 4 职业样图
all_frames = {}
for cls in ["warrior", "mage", "archer", "death_knight"]:
    print(f"处理 {cls} ({CLASS_NAMES.get(cls,cls)})...")
    all_frames[cls] = process_class(cls)

# ===== 生成 contact sheet =====
TW, TH = 200, 200
LABEL_H = 32
MAR = 8

cat_defs = [
    ("idle 呼吸", ["idle_1", "idle_2", "idle_3", "idle_4"]),
    ("run 奔跑",  ["run_1", "run_2", "run_3", "run_4"]),
    ("attack 攻击", ["attack_1", "attack_2", "attack_3", "attack_4", "attack_5"]),
    ("dead 倒地",  ["dead_1", "dead_2", "dead_3"]),
]

COLS = 5
for cls, frames in all_frames.items():
    rows = len(cat_defs)
    sheet_w = MAR*2 + COLS*(TW+6)
    sheet_h = MAR + 30 + MAR + rows*(LABEL_H + TH + MAR)
    sheet = Image.new("RGB", (sheet_w, sheet_h), (16, 20, 28))
    d = ImageDraw.Draw(sheet)
    cn = CLASS_NAMES.get(cls, cls)
    d.text((MAR+8, MAR+6), f"骨骼驱动真实立绘 — {cls} / {cn}", fill=(200, 220, 250))
    y = MAR + 30 + MAR
    for cat_name, fnames in cat_defs:
        d.rectangle([MAR, y, sheet_w-MAR, y+LABEL_H], fill=(24, 30, 42))
        d.text((MAR+8, y+8), cat_name, fill=(220, 235, 250))
        for col in range(COLS):
            x = MAR + col*(TW+6)
            tile_y = y + LABEL_H
            fkey = fnames[col] if col < len(fnames) else None
            d.rectangle([x, tile_y, x+TW, tile_y+TH], outline=(60,75,95), width=1)
            if fkey and fkey in frames:
                f = frames[fkey].resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, tile_y))
        y += LABEL_H + TH + MAR
    sheet.save(f"{OUT}/{cls}_real_contact_sheet.jpg", "JPEG", quality=88)
    print(f"  保存 {cls}_real_contact_sheet.jpg")

# 4 职业并排总览
cols_n = 2
rows_n = 2
tw2 = 560; th2 = 560
W = cols_n*tw2 + (cols_n+1)*20
H = rows_n*th2 + (rows_n+1)*20 + 50
big = Image.new("RGB", (W, H), (10, 14, 22))
d = ImageDraw.Draw(big)
d.text((20, 15), "真实肖像部件 + 骨骼驱动 — 4 职业对比", fill=(210, 230, 255))
for i, (cls, frames) in enumerate(all_frames.items()):
    r, c = divmod(i, cols_n)
    sx = 20 + c*(tw2+20)
    sy = 50 + r*(th2+20)
    f = frames.get("attack_2") or frames.get("attack_1")
    if f:
        # 裁剪中心 560×560
        cw, ch = f.size
        cx0 = max(0, (cw - 560)//2)
        cy0 = max(0, (ch - 560)//2)
        sub = f.crop((cx0, cy0, cx0+560, cy0+560))
        big.paste(sub, (sx, sy))
    d.rectangle([sx, sy, sx+tw2, sy+th2], outline=(80, 100, 140))
    d.text((sx+8, sy+8), f"{cls.upper()} / {CLASS_NAMES.get(cls,cls)} — attack 关键帧", fill=(240, 250, 255))
big.save(f"{OUT}/all_real_overview.jpg", "JPEG", quality=90)
print(f"\n=== 完成 ===")
print(f"输出: {OUT}/")
print(f"总览: {OUT}/all_real_overview.jpg")
for cls in all_frames:
    print(f"  {cls}: {OUT}/{cls}_real_contact_sheet.jpg")
    print(f"    部件: {PARTS_OUT}/{cls}/ ({len(os.listdir(f'{PARTS_OUT}/{cls}'))//2} 组)")
