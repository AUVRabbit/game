#!/usr/bin/env python3
"""
RiggedCharacter 样图生成器 — 用 PIL 复刻 RigBuilders + PoseDefs 的程序骨骼
输出: docs/RIGGED_SAMPLES/{class_id}/ 所有姿势帧 + contact sheet
"""
import os, math
from PIL import Image, ImageDraw

# ============================================================
# RigBuilders 复刻 (简化版 — 只输出 warlord 的皮肤 mesh)
# ============================================================

CLASS_COLORS = {
    "warrior":      (0.88, 0.42, 0.32),
    "mage":         (0.40, 0.52, 0.92),
    "runeward":     (0.60, 0.70, 0.95),
    "priest":       (0.96, 0.92, 0.82),
    "necromancer":  (0.48, 0.30, 0.42),
    "bomber":       (0.86, 0.62, 0.32),
    "mech_pilot":   (0.55, 0.55, 0.60),
    "engineer":     (0.72, 0.58, 0.38),
    "bounty_hunter":(0.70, 0.36, 0.25),
    "death_knight": (0.30, 0.28, 0.35),
    "archer":       (0.45, 0.62, 0.42),
    "thief":        (0.22, 0.22, 0.28),
    "qi_adept":     (0.82, 0.75, 0.52),
    "sniper":       (0.35, 0.38, 0.30),
    "cyborg":       (0.38, 0.55, 0.58),
    "hacker":       (0.25, 0.82, 0.72),
}

JOINT_OFFSETS = {
    "pelvis":  ( 0,   0),
    "torso":   ( 0, -16),
    "head":    ( 0, -14),
    "arm_l":   (-10, -4),
    "arm_r":   ( 10, -4),
    "leg_l":   (-5,   0),
    "leg_r":   ( 5,   0),
}

PARENT = {
    "pelvis": None,
    "torso":  "pelvis",
    "head":   "torso",
    "arm_l":  "torso",
    "arm_r":  "torso",
    "leg_l":  "pelvis",
    "leg_r":  "pelvis",
}

# —— 形状工厂 ——
def circle_pts(cx, cy, r, segs=18):
    return [(cx + r*math.cos(2*math.pi*i/segs), cy + r*math.sin(2*math.pi*i/segs)) for i in range(segs)]

def ellipse_pts(cx, cy, rx, ry, segs=20):
    return [(cx + rx*math.cos(2*math.pi*i/segs), cy + ry*math.sin(2*math.pi*i/segs)) for i in range(segs)]

def rounded_rect_pts(cx, cy, w, h, r):
    hw, hh = w/2, h/2
    pts = []
    for i in range(7):  # 左上弧
        a = math.pi - (i/6.0)*math.pi*0.5
        pts.append((cx-hw+r+r*math.cos(a), cy-hh+r+r*math.sin(a)))
    for i in range(7):  # 右上弧
        a = math.pi*0.5 - (i/6.0)*math.pi*0.5
        pts.append((cx+hw-r+r*math.cos(a), cy-hh+r+r*math.sin(a)))
    for i in range(7):  # 右下弧
        a = -(i/6.0)*math.pi*0.5
        pts.append((cx+hw-r+r*math.cos(a), cy+hh-r+r*math.sin(a)))
    for i in range(7):  # 左下弧
        a = math.pi*1.5 - (i/6.0)*math.pi*0.5
        pts.append((cx-hw+r+r*math.cos(a), cy+hh-r+r*math.sin(a)))
    return pts

# ============================================================
# build(type_name) -> skins, weapon, decorations
#   skins: {"torso": [(x,y)...], "head": ..., "arm_l": ..., "arm_r": ..., "leg_l": ..., "leg_r": ...}
#   weapon: {"parent": "arm_r", "verts": [...], "anchor": (x,y), "rotation": deg, "color": RGB}
#   decorations: [{"parent": ..., "verts": [...], "position": (x,y), "rotation": deg, "color": RGB}]
# ============================================================

def build(type_name):
    c = CLASS_COLORS.get(type_name, (0.6, 0.6, 0.6))
    skins = {
        "torso":  rounded_rect_pts(0, 0, 12, 20, 4),
        "head":   circle_pts(0, 0, 9, 20),
        "arm_l":  ellipse_pts(0, 0, 4, 10, 20),
        "arm_r":  ellipse_pts(0, 0, 4, 10, 20),
        "leg_l":  ellipse_pts(0, 0, 4.5, 12, 20),
        "leg_r":  ellipse_pts(0, 0, 4.5, 12, 20),
    }
    # 颜色调色
    skin_c = (0.92, 0.85, 0.72)
    leg_c  = tuple(x*0.92 for x in c)
    colors = {"torso": c, "head": skin_c, "arm_l": c, "arm_r": c, "leg_l": leg_c, "leg_r": leg_c}

    weapon = None
    decorations = []

    # ==== 职业定制 ====
    if type_name == "warrior":
        # 长剑
        weapon = {
            "parent": "arm_r",
            "verts": [(-4,-18),(4,-18),(6,8),(0,10),(-6,8)],
            "anchor": (12,-2),
            "rotation": -60,
            "color": (0.75, 0.78, 0.82),
        }
        # 胸甲
        decorations.append({
            "parent": "torso", "position": (0,0), "rotation": 0,
            "verts": [(-10,-5),(10,-5),(12,7),(0,10),(-12,7)],
            "color": (0.72, 0.30, 0.24),
        })
    elif type_name == "mage":
        weapon = {
            "parent": "arm_r",
            "verts": [(-2,-14),(2,-14),(2,14),(-2,14), (6,-14),(6,-20),(0,-24),(-6,-20),(-6,-14)],
            "anchor": (8,-6), "rotation": -50,
            "color": (0.55, 0.38, 0.22),
        }
        decorations.append({
            "parent": "head", "position": (0,-4), "rotation": 0,
            "verts": [(-8,2),(8,2),(4,-4),(0,-18),(-4,-4)],
            "color": (0.32, 0.42, 0.82),
        })
    elif type_name == "archer":
        weapon = {
            "parent": "arm_r",
            "verts": [(0,-16),(10,-8),(14,0),(10,8),(0,16),(-2,8),(2,0),(-2,-8)],
            "anchor": (6,-4), "rotation": -30,
            "color": (0.65, 0.42, 0.28),
        }
    elif type_name == "death_knight":
        weapon = {
            "parent": "arm_r",
            "verts": [(-5,-26),(5,-26),(8,10),(-4,12),(-6,10)],
            "anchor": (10,-2), "rotation": -60,
            "color": (0.55, 0.58, 0.65),
        }
        decorations.append({
            "parent": "torso", "position": (0,-6), "rotation": 0,
            "verts": [(-12,-2),(12,-2),(10,4),(-10,4)],
            "color": (0.22, 0.22, 0.28),
        })
        decorations.append({
            "parent": "torso", "position": (-14,2), "rotation": 0,
            "verts": [(-4,-4),(6,-4),(14,18),(2,22),(-12,22)],
            "color": (0.28, 0.18, 0.32),
        })

    return skins, colors, weapon, decorations


# ============================================================
# PoseDefs 复刻 (简化)
# ============================================================

LOOP_POSES = {
    "idle": {"freq": 1.2, "bob": 0.8,
        "rots": [0,-0.5,1,-3,3,0,0],
        "swing": [0,0.2,0.3,0.2,-0.2,0,0]},
    "run":  {"freq": 3.2, "bob": 2.5,
        "rots": [0,2,0,0,0,0,0],
        "swing": [0,0.3,0,0.9,-0.9,1.0,-1.0]},
    "walk": {"freq": 1.8, "bob": 1.2,
        "rots": [0,1,0,0,0,0,0],
        "swing": [0,0.15,0,0.4,-0.4,0.5,-0.5]},
    "celebrate": {"freq": 2.4, "bob": 5.0,
        "rots": [0,-1,0,140,-140,0,0],
        "swing": [0,0.2,0,-0.6,0.6,0,0]},
    "cast_loop": {"freq": 0.9, "bob": 0.6,
        "rots": [0,1,2,120,-120,0,0],
        "swing": [0,0.15,0.2,0.3,-0.3,0,0]},
}

TIMELINE_POSES = {
    "sword_swing": (0.35, [
        [0.0, [0,0,0,-30,140,0,0], [None,None,None,None,(14,-2),None,None], 0.0],
        [0.5, [0,6,2,-60,200,-6,6], [None,None,None,( -14,-6),(26,-6),( -8,2),(8,2)], -3.0],
        [1.0, [0,0,0,-3,3,0,0], [None,None,None,None,None,None,None], 0.0],
    ]),
    "cast": (0.6, [
        [0.0, [0,0,0,-3,3,0,0], [None]*7, 0.0],
        [1.0, [0,2,4,110,-110,-2,2], [None,(0,-2),(2,-14),(-4,-22),(4,-22),None,None], -2.0],
    ]),
    "dash": (0.18, [
        [0.0, [0,10,6,45,-45,-20,20], [(0,0),(6,-14),(6,-14),(0,-10),(12,-6),(-12,6),(12,6)], -4.0],
        [1.0, [0,10,6,45,-45,-20,20], [(0,0),(6,-14),(6,-14),(0,-10),(12,-6),(-12,6),(12,6)], -4.0],
    ]),
    "hurt": (0.25, [
        [0.0, [0,0,0,0,0,0,0], [None]*7, 0.0],
        [1.0, [-6,-10,-8,-15,15,0,0], [( -6,0),( -8,-14),( -6,-12),( -12,-2),(12,-6),None,None], 1.0],
    ]),
    "dead": (0.9, [
        [0.0, [0,0,0,0,0,0,0], [None]*7, 0.0],
        [0.5, [22.5,45,30,30,-20,45,-45], [(4,0),(14,-2),(14,-18),(-6,-10),(12,-4),(2,4),(2,4)], 0.0],
        [1.0, [45,90,60,45,-30,90,-90], [(8,0),(22,10),(22,-10),(-4,-6),(14,0),(0,8),(0,8)], 0.0],
    ]),
    "roll": (0.5, [
        [0.0, [0,0,0,0,0,0,0], [None]*7, 0.0],
        [0.25, [180,0,0,0,0,0,0], [(12,0),(0,0),(0,0),(0,0),(0,0),(0,0),(0,0)], -10.0],
        [0.5, [360,0,0,0,0,0,0], [(24,0),None,None,None,None,None,None], 0.0],
    ]),
    "jump": (0.25, [
        [0.0, [0,0,0,0,0,0,0], [None]*7, 0.0],
        [1.0, [0,-4,0,-20,20,-35,35], [None,None,None,(-8,-8),(12,-4),(-14,8),(14,8)], -2.0],
    ]),
    "block": (0.3, [
        [0.0, [0,0,0,-3,3,0,0], [None]*7, 0.0],
        [1.0, [-2,-4,2,-65,65,0,0], [( -2,0),(-2,-16),None,( -16,-2),(16,-2),None,None], 0.0],
    ]),
    "bow_draw": (0.5, [
        [0.0, [0,-2,0,-20,20,0,0], [None]*7, 0.0],
        [0.45,[-6,6,4,-35,-55,4,-4], [(-2,0),None,None,(-6,-6),(-4,-10),(-8,4),(8,4)], -1.0],
        [1.0, [0,-2,0,-30,-40,0,0], [None]*7, 0.0],
    ]),
    "cast_focus": (1.0, [
        [0.0, [0,0,0,-3,3,0,0], [None]*7, 0.0],
        [1.0, [0,4,6,95,-95,0,0], [(0,-4),(0,-20),None,(-4,-24),(4,-24),None,None], -4.0],
    ]),
}


def interpolate_timeline(pose, progress):
    """返回 (pelvis_bob, [rot_deg × 7], [offset_override × 7])"""
    name = pose
    if name not in TIMELINE_POSES:
        return 0, [0]*7, [None]*7
    dur, kfs = TIMELINE_POSES[name]
    progress = progress * dur if progress <= 1.0 else dur
    # 找到包围 progress 的两个关键帧
    kf_a, kf_b = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        ta, tb = kfs[i][0], kfs[i+1][0]
        if ta <= progress <= tb:
            kf_a, kf_b = kfs[i], kfs[i+1]
            break
    if kf_a == kf_b:
        return kf_a[3], kf_a[1], kf_a[2]
    t = (progress - kf_a[0]) / (kf_b[0] - kf_a[0]) if kf_b[0] != kf_a[0] else 0
    t = 1 - (1-t)**2.5  # ease out
    bob = kf_a[3]*(1-t) + kf_b[3]*t
    rots = [kf_a[1][i]*(1-t) + kf_b[1][i]*t for i in range(7)]
    offsets = []
    for i in range(7):
        oa, ob = kf_a[2][i], kf_b[2][i]
        if oa is None and ob is None:
            offsets.append(None)
        elif oa is None:
            offsets.append(ob)
        elif ob is None:
            offsets.append(oa)
        else:
            offsets.append((oa[0]*(1-t)+ob[0]*t, oa[1]*(1-t)+ob[1]*t))
    return bob, rots, offsets


# ============================================================
# 骨架渲染 — 正向运动学
# ============================================================

JOINT_NAMES = ["pelvis", "torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]

def compute_joint_transforms(pose_name, t, loop_phase):
    """返回: {joint_name: (world_pos_x, world_pos_y, world_rotation_deg)}"""
    global JOINT_OFFSETS, PARENT, JOINT_NAMES

    transforms = {}
    base_offsets = {k: v for k, v in JOINT_OFFSETS.items()}

    if pose_name in LOOP_POSES:
        d = LOOP_POSES[pose_name]
        phase = math.sin(2*math.pi * d["freq"] * t)
        bob = d["bob"] * phase
        rots = [d["rots"][i] + d["swing"][i] * phase * 30.0 for i in range(7)]
        offsets = [None]*7
    elif pose_name in TIMELINE_POSES:
        bob, rots, offsets = interpolate_timeline(pose_name, loop_phase)
    else:
        bob, rots, offsets = 0, [0]*7, [None]*7

    # pelvis 有 bob + 垂直偏移
    transforms["pelvis"] = (0, bob, rots[0])
    for jidx in range(1, 7):
        jname = JOINT_NAMES[jidx]
        parent = PARENT[jname]
        parent_pos = transforms[parent][:2]
        parent_rot = math.radians(transforms[parent][2])
        # 基础局部偏移（从 PoseDefs）
        local = base_offsets[jname]
        # timeline 里有没有 override
        ov = offsets[jidx] if offsets[jidx] else None
        if ov:
            local = ov
        # 把 local 旋转到 parent 的世界方向
        lx, ly = local[0], local[1]
        wx = parent_pos[0] + lx*math.cos(parent_rot) - ly*math.sin(parent_rot)
        wy = parent_pos[1] + lx*math.sin(parent_rot) + ly*math.cos(parent_rot)
        wrot = math.degrees(parent_rot) + rots[jidx]
        transforms[jname] = (wx, wy, wrot)

    return transforms


def render_frame(class_id, pose_name, t, progress_f, facing=1.0):
    """PIL Image 渲染单个姿势帧"""
    skins, colors, weapon, decorations = build(class_id)
    transforms = compute_joint_transforms(pose_name, t, progress_f)

    W, H = 256, 256
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = W//2, H - 40  # 脚底在底部

    def draw_poly(pts_local, joint_name, fill_rgb, parent_offset=(0,0), parent_rot_deg=0, scale=facing):
        j = transforms[joint_name]
        jx, jy, jrot = j
        jrot_rad = math.radians(jrot + parent_rot_deg)
        final_pts = []
        for (lx, ly) in pts_local:
            # 先应用 weapon 的 parent_offset
            x = lx + parent_offset[0]
            y = ly + parent_offset[1]
            # 旋转
            rx = x*math.cos(jrot_rad) - y*math.sin(jrot_rad)
            ry = x*math.sin(jrot_rad) + y*math.cos(jrot_rad)
            # 镜像
            rx *= scale
            # 世界位置
            wx = cx + jx*scale + rx
            wy = cy + jy + ry
            final_pts.append((wx, wy))
        # 填充
        r, g, b = fill_rgb
        draw.polygon(final_pts, fill=(int(r*255), int(g*255), int(b*255), 255), outline=(20, 20, 30, 180))

    # shadow（pelvis 下）
    sx, sy = transforms["pelvis"][:2]
    sh_w, sh_h = 36, 7
    draw.ellipse([cx+sx*facing-sh_w//2, cy+sy+18-sh_h//2,
                  cx+sx*facing+sh_w//2, cy+sy+18+sh_h//2],
                 fill=(0,0,0,80))

    # 画身体各部件（注意顺序：脚/腿/躯干/手臂/头/装饰/武器）
    order = ["leg_l", "leg_r", "torso", "arm_l", "arm_r", "head"]
    for jname in order:
        if jname not in skins or len(skins[jname]) == 0:
            continue
        draw_poly(skins[jname], jname, colors[jname])

    # 装饰
    for deco in decorations:
        draw_poly(deco["verts"], deco["parent"], deco["color"],
                  parent_offset=deco.get("position", (0,0)),
                  parent_rot_deg=deco.get("rotation", 0))

    # 武器（挂 arm_r 上）
    if weapon:
        draw_poly(weapon["verts"], weapon["parent"], weapon["color"],
                  parent_offset=weapon.get("anchor", (0,0)),
                  parent_rot_deg=weapon.get("rotation", 0))

    return img.convert("RGB")


# ============================================================
# 主生成流程
# ============================================================

def generate_class(class_id, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    # 准备要渲染的姿势列表
    pose_list = []
    # 循环姿势：取 0, 0.25, 0.5, 0.75 四个时间点
    for pname in ["idle", "run", "cast_loop", "celebrate"]:
        if pname in LOOP_POSES:
            for k, phase in enumerate([0, 0.25, 0.5, 0.75]):
                pose_list.append((pname, phase * 4.0 / LOOP_POSES[pname]["freq"], phase, f"{pname}_{k+1}"))
    # Timeline 姿势：各取 3 个进度点 (0.0, 0.5, 1.0)
    for pname in ["sword_swing", "cast", "dash", "hurt", "dead", "roll", "jump", "block", "bow_draw", "cast_focus"]:
        if pname in TIMELINE_POSES:
            dur = TIMELINE_POSES[pname][0]
            for k, prog in enumerate([0.0, 0.5, 1.0]):
                pose_list.append((pname, prog * dur, prog, f"{pname}_{k+1}"))

    # 渲染所有姿势帧
    frames = {}
    for pname, t, prog, fname in pose_list:
        img = render_frame(class_id, pname, t, prog)
        p = os.path.join(out_dir, f"{fname}.png")
        img.save(p, "PNG", optimize=True)
        frames[fname] = img

    # 生成 contact sheet — 按类别分组
    # 行: 类别, 列: 每类 3-4 帧
    categories = [
        ("idle", ["idle_1", "idle_2", "idle_3", "idle_4"]),
        ("run",  ["run_1", "run_2", "run_3", "run_4"]),
        ("attack\n(sword_swing)", ["sword_swing_1", "sword_swing_2", "sword_swing_3"]),
        ("cast", ["cast_1", "cast_2", "cast_3"]),
        ("cast_loop", ["cast_loop_1", "cast_loop_2", "cast_loop_3", "cast_loop_4"]),
        ("celebrate", ["celebrate_1", "celebrate_2", "celebrate_3", "celebrate_4"]),
        ("dash", ["dash_1", "dash_2", "dash_3"]),
        ("hurt", ["hurt_1", "hurt_2", "hurt_3"]),
        ("dead", ["dead_1", "dead_2", "dead_3"]),
        ("roll", ["roll_1", "roll_2", "roll_3"]),
        ("jump", ["jump_1", "jump_2", "jump_3"]),
        ("block", ["block_1", "block_2", "block_3"]),
        ("bow_draw", ["bow_draw_1", "bow_draw_2", "bow_draw_3"]),
        ("cast_focus", ["cast_focus_1", "cast_focus_2", "cast_focus_3"]),
    ]

    COLS = 4
    TILE_W, TILE_H = 200, 200
    LABEL_H = 44
    COL_HEADER_H = 28
    MARGIN = 8
    PAD = 4

    rows = len(categories)
    sheet_w = MARGIN*2 + COLS*(TILE_W + PAD) - PAD
    sheet_h = MARGIN + COL_HEADER_H + MARGIN + rows*(LABEL_H + TILE_H + MARGIN) - MARGIN

    sheet = Image.new("RGB", (sheet_w, sheet_h), (18, 22, 32))
    d = ImageDraw.Draw(sheet)

    # 列头
    d.rectangle([MARGIN, MARGIN, sheet_w-MARGIN, MARGIN+COL_HEADER_H], fill=(26, 32, 42))
    d.text((MARGIN+8, MARGIN+6), f"{class_id.upper()} — 骨骼驱动样图 | {rows} 类姿势", fill=(180, 210, 240))

    y0 = MARGIN + COL_HEADER_H + MARGIN
    for row_idx, (cat_name, fnames) in enumerate(categories):
        y_row = y0 + row_idx*(LABEL_H + TILE_H + MARGIN)
        # 类别标签
        d.rectangle([MARGIN, y_row, sheet_w-MARGIN, y_row+LABEL_H], fill=(26, 32, 42))
        d.text((MARGIN+8, y_row+10), cat_name, fill=(220, 230, 245))

        for col_idx in range(COLS):
            x = MARGIN + col_idx*(TILE_W + PAD)
            tile_y = y_row + LABEL_H
            fkey = fnames[col_idx] if col_idx < len(fnames) else None
            d.rectangle([x, tile_y, x+TILE_W, tile_y+TILE_H], outline=(60, 72, 90), width=1)
            if fkey and fkey in frames:
                fimg = frames[fkey].resize((TILE_W, TILE_H), Image.BILINEAR)
                sheet.paste(fimg, (x, tile_y))

    sheet_path = os.path.join(out_dir, f"{class_id}_rigged_contact_sheet.png")
    sheet.save(sheet_path, "PNG", optimize=True)
    return sheet_path


if __name__ == "__main__":
    out_root = "/workspace/通天入地/docs/RIGGED_SAMPLES_2026-11-25"
    os.makedirs(out_root, exist_ok=True)

    # 选 4 个代表性职业
    picks = ["warrior", "mage", "death_knight", "archer"]
    sheets = []
    for cid in picks:
        print(f"生成 {cid} ...")
        sheet = generate_class(cid, os.path.join(out_root, cid))
        sheets.append((cid, sheet))

    # 汇总总表 (4 职业并排)
    tw, th = 600, 660
    cols = 2
    rows = 2
    W = cols*tw + (cols+1)*20
    H = rows*th + (rows+1)*20 + 50
    summary = Image.new("RGB", (W, H), (14, 18, 28))
    d = ImageDraw.Draw(summary)
    d.text((20, 15), "RiggedCharacter 骨骼驱动实体 — 职业样图总览", fill=(200, 220, 250))

    for i, (cid, sheet_path) in enumerate(sheets):
        r, c = divmod(i, cols)
        sx = 20 + c*(tw+20)
        sy = 50 + r*(th+20)
        big = Image.open(sheet_path)
        # 裁剪中间部分并缩
        bw, bh = big.size
        cx0, cy0 = bw//2 - 300, bh//2 - 330
        big_sub = big.crop((cx0, cy0, cx0+600, cy0+660))
        big_sub.save(os.path.join(out_root, f"{cid}_preview.jpg"), "JPEG", quality=85)
        summary.paste(big_sub, (sx, sy))
        d.rectangle([sx, sy, sx+tw, sy+th], outline=(80, 100, 130))
        col = tuple(int(x*255) for x in CLASS_COLORS.get(cid, (1,1,1)))
        d.text((sx+6, sy+6), cid.upper(), fill=col)

    summary_path = os.path.join(out_root, "all_classes_overview.jpg")
    summary.save(summary_path, "JPEG", quality=88)
    print(f"\n=== 完成 ===")
    print(f"输出目录: {out_root}")
    print(f"总览: {summary_path}")
    for cid, p in sheets:
        print(f"  {cid}: {p}")
