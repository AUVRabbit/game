#!/usr/bin/env python3
"""
RiggedCharacter v2 样图生成器 — 复刻 Godot 运行时的骨架/本体/装备三层系统
复用 data/skeletons.json + data/equipment.json + data/class_presets.json
"""
import os, json, math
from PIL import Image, ImageDraw

PROJ = "/workspace/通天入地"
SKEL = json.load(open(f"{PROJ}/data/skeletons.json"))["skeletons"]
EQ   = json.load(open(f"{PROJ}/data/equipment.json"))
PRESETS = json.load(open(f"{PROJ}/data/class_presets.json"))["presets"]

OUT = f"{PROJ}/docs/RIGGED_V2_SAMPLES_2026-11-25"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 几何工具 — 和 rigged_character.gd 的静态方法一致
# ============================================================

def circle_pts(r, segs=18):
    return [(r*math.cos(2*math.pi*i/segs), r*math.sin(2*math.pi*i/segs)) for i in range(segs)]

def ellipse_pts(rx, ry, segs=20):
    return [(rx*math.cos(2*math.pi*i/segs), ry*math.sin(2*math.pi*i/segs)) for i in range(segs)]

def capsule_pts(w, h):
    segs = 10; hw, hh = w*0.5, h*0.5; v = []
    for i in range(segs+1):
        a = math.pi*0.5 - i/segs*math.pi
        v.append((hw + math.cos(a)*hw*0.3, -hh + math.sin(a)*hh))
    for i in range(segs+1):
        a = -math.pi*0.5 - i/segs*math.pi
        v.append((hw + math.cos(a)*hw*0.3, -hh + math.sin(a)*hh))
    v.append((-hw, hh)); v.append((-hw, -hh))
    return v

def draw_poly(img, verts, fill_rgb, anchor=None, rotation_deg=0, facing=1, origin=(0,0)):
    """把一组局部坐标 verts (相对 anchor) 旋转+平移+镜像后贴到 img 上"""
    cx, cy = origin
    local = verts[:]
    if anchor:
        local = [(x + anchor[0], y + anchor[1]) for (x,y) in local]
    if rotation_deg != 0:
        rad = math.radians(rotation_deg)
        local = [(x*math.cos(rad) - y*math.sin(rad),
                  x*math.sin(rad) + y*math.cos(rad)) for (x,y) in local]
    if facing < 0:
        local = [(-x, y) for (x,y) in local]
    world = [(cx + x, cy + y) for (x,y) in local]
    d = ImageDraw.Draw(img)
    d.polygon(world, fill=(int(fill_rgb[0]*255), int(fill_rgb[1]*255), int(fill_rgb[2]*255)))

# ============================================================
# 骨架渲染 — 正向运动学
# ============================================================

class Bone:
    def __init__(self, name, parent_idx, anchor, rest_rot, layer, scale):
        self.name = name
        self.parent_idx = parent_idx
        self.anchor = anchor        # 相对父的局部位置
        self.rest_rot = rest_rot    # 相对父的旋转
        self.layer = layer
        self.scale = scale
        self.world_pos = (0, 0)
        self.world_rot = 0

def build_skeleton(skel_name, height_scale=1.0):
    defs = SKEL[skel_name]
    bones = []
    for bd in defs["bones"]:
        b = Bone(bd["name"], bd["parent"],
                 tuple(bd["anchor"]),
                 float(bd["rot"]),
                 int(bd["layer"]),
                 float(bd.get("scale", 1.0)) * height_scale)
        bones.append(b)
    return bones

def forward_kinematics(bones, rot_overrides=None, facing=1.0):
    """rot_overrides: {bone_idx: rot_deg} 覆盖 rest_rot"""
    # 从 root 开始按 parent 索引 BFS
    order = []
    remaining = set(range(len(bones)))
    while remaining:
        for i in list(remaining):
            p = bones[i].parent_idx
            if p < 0 or p not in remaining:
                order.append(i)
                remaining.remove(i)
    for idx in order:
        b = bones[idx]
        parent_pos = (0, 0); parent_rot = 0
        if b.parent_idx >= 0:
            parent_pos = bones[b.parent_idx].world_pos
            parent_rot = bones[b.parent_idx].world_rot
        rot = b.rest_rot
        if rot_overrides and idx in rot_overrides:
            rot = rot_overrides[idx]
        rad = math.radians(parent_rot)
        ax, ay = b.anchor
        ax *= b.scale; ay *= b.scale
        wx = parent_pos[0] + (ax*math.cos(rad) - ay*math.sin(rad)) * facing
        wy = parent_pos[1] + ax*math.sin(rad) + ay*math.cos(rad)
        b.world_pos = (wx, wy)
        b.world_rot = parent_rot + rot
    return bones

# ============================================================
# 本体 mesh 生成
# ============================================================

def body_meshes_for(skel_name, tint):
    """返回 {bone_name: (verts, color)}"""
    t = tuple(tint) if not isinstance(tint, tuple) else tint
    meshes = {}
    if skel_name in ("humanoid_7", "giant_7", "giant_skeleton_5"):
        meshes = {
            "torso":  (capsule_pts(12, 20), t),
            "head":   (circle_pts(9), t),
            "arm_l":  (ellipse_pts(4, 10), t),
            "arm_r":  (ellipse_pts(4, 10), t),
            "leg_l":  (ellipse_pts(4.5, 12), t),
            "leg_r":  (ellipse_pts(4.5, 12), t),
        }
    elif skel_name == "slime_3":
        meshes = {
            "core":  (ellipse_pts(14, 10), t),
            "bounce_top": (ellipse_pts(10, 6), t),
            "bounce_bot": (ellipse_pts(12, 4), (t[0]*0.85, t[1]*0.85, t[2]*0.85)),
        }
    elif skel_name == "spider_9":
        meshes = {
            "body": (ellipse_pts(10, 6), t),
            "head": (circle_pts(4), t),
            "leg_fl": (ellipse_pts(1.5, 8), (t[0]*0.7, t[1]*0.7, t[2]*0.7)),
            "leg_fr": (ellipse_pts(1.5, 8), (t[0]*0.7, t[1]*0.7, t[2]*0.7)),
            "leg_ml": (ellipse_pts(1.5, 8), (t[0]*0.7, t[1]*0.7, t[2]*0.7)),
            "leg_mr": (ellipse_pts(1.5, 8), (t[0]*0.7, t[1]*0.7, t[2]*0.7)),
            "leg_rl": (ellipse_pts(1.5, 8), (t[0]*0.7, t[1]*0.7, t[2]*0.7)),
            "leg_rr": (ellipse_pts(1.5, 8), (t[0]*0.7, t[1]*0.7, t[2]*0.7)),
            "tail":  (ellipse_pts(2, 4), t),
        }
    elif skel_name == "wraith_5":
        meshes = {
            "core": (ellipse_pts(10, 16), t),
            "head": (circle_pts(7), (t[0]*1.15, t[1]*1.15, t[2]*1.15)),
            "tendril_l": (ellipse_pts(2, 10), (t[0]*0.85, t[1]*0.85, t[2]*0.85)),
            "tendril_r": (ellipse_pts(2, 10), (t[0]*0.85, t[1]*0.85, t[2]*0.85)),
            "tail": (ellipse_pts(3, 12), (t[0]*0.8, t[1]*0.8, t[2]*0.8)),
        }
    # 归一化颜色（0-255）
    out = {}
    for k, (v, c) in meshes.items():
        out[k] = (v, (max(0, min(1, c[0])), max(0, min(1, c[1])), max(0, min(1, c[2]))))
    return out

def eq_mesh(item_id):
    """从 equipment.json 拿装备 mesh"""
    for cat_name, cat in EQ.items():
        if item_id in cat:
            e = cat[item_id]
            verts = [(e["verts"][i], e["verts"][i+1]) for i in range(0, len(e["verts"]), 2)]
            return verts, tuple(e["anchor"]), float(e["rest_rot"]), tuple(e["color"])
    return None

# ============================================================
# 渲染角色 = 骨架 + 本体 + 装备
# ============================================================

def render_character(canvas, bones, body_meshes, equipment, facing, anchor_xy):
    """canvas: PIL RGB Image; bones after FK; body_meshes + equipment dicts"""
    # 先画影子
    cx, cy = anchor_xy
    d = ImageDraw.Draw(canvas)
    d.ellipse([cx-18, cy-4, cx+18, cy+4], fill=(0,0,0,60) if canvas.mode=="RGBA" else (0,0,0))
    # 按 layer 排序画所有部件
    items = []  # (layer, draw_order, kind, ...)
    for b in bones:
        layer = b.layer
        # body
        if b.name in body_meshes:
            verts, color = body_meshes[b.name]
            items.append((layer, 0, "body", b.world_pos, verts, color, b.world_rot))
        # equipment (multiple items per bone possible)
        for slot, (item_id, eqdef) in equipment.items():
            if eqdef["parent_bone"] == b.name:
                eqv, anc, rrot, ecol = eqdef["mesh"]
                items.append((layer+1, 1+hash(slot)%10, "eq", b.world_pos, eqv, ecol, b.world_rot + rrot, anc))
    # 排序 — layer 先, 同级 body 先于 eq
    items.sort(key=lambda x: (x[0], x[1]))
    for it in items:
        if it[2] == "body":
            _, _, _, pos, verts, color, wrot = it
            draw_poly(canvas, verts, color, None, wrot, facing, (cx + pos[0]*facing, cy + pos[1]))
        elif it[2] == "eq":
            _, _, _, pos, verts, color, wrot, anc = it
            draw_poly(canvas, verts, color, anc, wrot, facing, (cx + pos[0]*facing, cy + pos[1]))

# ============================================================
# 姿势预设 — 每职业 1 个循环姿势 + 1 个 attack timeline
#   每个姿势 = bone_idx -> 关节旋转 override
# ============================================================

POSES = {
    "warrior_attack": [
        (0.0, [0,0,0,-30,140,0,0]),
        (0.45, [0,12,6,-55,-170,-6,6]),
        (0.7, [0,15,8,-60,-175,-8,8]),
        (1.0, [0,0,0,-30,140,0,0]),
    ],
    "mage_attack": [
        (0.0, [0,0,4,20,-20,0,0]),
        (0.5, [0,2,10,95,-95,2,-2]),
        (0.75, [0,4,14,110,-110,4,-4]),
        (1.0, [0,0,4,20,-20,0,0]),
    ],
    "archer_attack": [
        (0.0, [0,-3,2,10,-10,0,0]),
        (0.4, [-6,6,6,-20,40,4,-4]),
        (0.7, [-8,10,5,-28,55,6,-6]),
        (1.0, [0,-3,2,10,-10,0,0]),
    ],
    "thief_attack": [
        (0.0, [0,0,0,-15,15,0,0]),
        (0.4, [-2,4,4,-40,-160,4,-4]),
        (0.6, [-4,8,6,-50,-170,6,-6]),
        (1.0, [0,0,0,-15,15,0,0]),
    ],
    "slime_bounce": [
        (0.0, [0,0,0]),
        (0.3, [0,-30,-20]),
        (0.5, [0,-50,-30]),
        (0.8, [0,-10,-10]),
        (1.0, [0,0,0]),
    ],
    "spider_wave": [
        (0.0, [0,0, 0,0,0,0,0,0,0]),
        (0.5, [0,5, -15,20,-15,20,-15,20,-20]),
        (1.0, [0,0, 0,0,0,0,0,0,0]),
    ],
    "wraith_float": [
        (0.0, [0,0, 0,0,0]),
        (0.5, [0,5, 15,-15,-10]),
        (1.0, [0,0, 0,0,0]),
    ],
    "giant_swing": [
        (0.0, [0,0,0,-20,120,0,0]),
        (0.5, [0,12,8,-60,-170,-10,10]),
        (1.0, [0,0,0,-20,120,0,0]),
    ],
}

def kf_interp(kfs, progress):
    t = progress
    ka, kb = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        if kfs[i][0] <= t <= kfs[i+1][0]:
            ka, kb = kfs[i], kfs[i+1]
            break
    if ka == kb:
        return list(ka[1])
    r = (t - ka[0]) / max(0.001, kb[0] - ka[0])
    r = 1 - (1-r)**2.5
    return [ka[1][i]*(1-r) + kb[1][i]*r for i in range(max(len(ka[1]), len(kb[1])))]

# ============================================================
# 主流程
# ============================================================

def render_preset_frames(preset_id, pose_key, facing=1.0):
    p = PRESETS.get(preset_id)
    if not p:
        return []
    skel_name = p["skeleton"]
    tint = tuple(p["body_tint"])
    scale = p.get("height_scale", 1.0)

    bones = build_skeleton(skel_name, scale)
    bm = body_meshes_for(skel_name, tint)

    # equipment dict: slot -> (item_id, mesh_tuple)
    equipment = {}
    for slot, item_id in p.get("equipment", {}).items():
        m = eq_mesh(item_id)
        if m:
            eq_def = {"parent_bone": _eq_parent_bone_for_slot(slot), "mesh": m}
            equipment[slot] = (item_id, eq_def)

    frames = []
    kfs = POSES.get(pose_key)
    if kfs:
        canvas_w, canvas_h = 500, 500
        for k, (t, _) in enumerate(kfs):
            rots = kf_interp(kfs, t)
            bone_rots = {i: float(rots[i]) for i in range(min(len(rots), len(bones)))}
            forward_kinematics(bones, bone_rots, facing)
            frame = Image.new("RGB", (canvas_w, canvas_h), (22, 28, 38))
            render_character(frame, bones, bm, equipment, facing, (canvas_w//2, canvas_h - 50))
            frames.append((f"f{k+1}_{pose_key}", frame))
    return frames

def _eq_parent_bone_for_slot(slot):
    m = {
        "right_hand": "arm_r", "left_hand": "arm_l",
        "torso": "torso", "head": "head",
        "back": "torso", "feet": "leg_l",
    }
    return m.get(slot, "arm_r")

# ============================================================
# 场景 A: 战士换武器对比 — 同一 humanoid 骨架, 换装备
# ============================================================

print("=== 场景 A: 战士换武器 ===")
weapon_presets = [
    ("warrior",        "iron_sword",  "铁剑"),
    ("warrior_greatsword", "greatsword", "巨剑"),
    ("warrior",        "staff_fire",  "火法杖"),
    ("warrior",        "dagger",      "匕首"),
    ("warrior",        "bow_short",   "弓"),
    ("warrior",        "rifle",       "步枪"),
    ("warrior",        "gatling",     "加特林"),
    ("warrior",        "wrench",      "扳手"),
]

cols = 4
rows = 2
tw, th = 220, 260
sheet_w = cols * (tw + 20) + 20
sheet_h = rows * (th + 60) + 60
sheet = Image.new("RGB", (sheet_w, sheet_h), (16, 22, 34))
d = ImageDraw.Draw(sheet)
d.text((20, 15), "场景 A: 换武器 — 同一 humanoid 骨架, 武器/胸甲/头盔全部可替换", fill=(210, 230, 255))

frame_key = "warrior_attack" if "warrior_attack" in POSES else list(POSES.keys())[0]
focus_frames = render_preset_frames("warrior", frame_key)
mid_idx = len(focus_frames) // 2 if focus_frames else 0

for idx, (base_preset, weapon_id, label) in enumerate(weapon_presets):
    r, c = divmod(idx, cols)
    x = 20 + c * (tw + 20)
    y = 50 + r * (th + 60)
    cell = Image.new("RGB", (tw, th), (26, 34, 48))
    d2 = ImageDraw.Draw(cell)

    # 从基础 preset 开始, 换武器
    p = dict(PRESETS[base_preset])
    p["equipment"] = dict(p.get("equipment", {}))
    p["equipment"]["right_hand"] = weapon_id
    PRESETS[base_preset + "_weapon_" + weapon_id] = p  # 临时注册
    frames = render_preset_frames(base_preset + "_weapon_" + weapon_id, frame_key)
    if frames:
        mid_frame = frames[mid_idx][1]
        cell.paste(mid_frame.crop((100, 50, 400, 450)).resize((tw, th), Image.BILINEAR), (0,0))
    d2.rectangle([0, 0, tw-1, th-1], outline=(70, 90, 120))
    sheet.paste(cell, (x, y))
    d.text((x+4, y+th+6), f"{label}", fill=(230, 240, 255))
    d.text((x+4, y+th+22), f"{weapon_id}", fill=(130, 150, 180))

sheet.save(f"{OUT}/A_swap_weapons.jpg", "JPEG", quality=90)
print(f"  -> A_swap_weapons.jpg {sheet_w}×{sheet_h}")

# ============================================================
# 场景 B: 非人类骨架 — 6 种骨架, 每种一个代表性动作
# ============================================================

print("=== 场景 B: 非人类骨架 ===")
nonhuman = [
    ("slime_minion",    "slime_bounce",   "史莱姆 — 压缩弹跳"),
    ("slime_boss",      "slime_bounce",   "BOSS 史莱姆 (2x 放大)"),
    ("spider_mech",     "spider_wave",    "机械蜘蛛 — 八腿独立摆动"),
    ("wraith_enemy",    "wraith_float",   "幽魂 — 飘带浮动"),
    ("giant_enemy",     "giant_swing",    "熔岩巨人 — 大体型挥拳"),
    ("skeleton_warrior","giant_swing",    "骷髅战士 — 5 关节骨架 (无肉)"),
]

cols2 = 3
rows2 = 2
tw2, th2 = 250, 300
sheet_w2 = cols2 * (tw2 + 20) + 20
sheet_h2 = rows2 * (th2 + 60) + 60
sheet2 = Image.new("RGB", (sheet_w2, sheet_h2), (16, 22, 34))
d2 = ImageDraw.Draw(sheet2)
d2.text((20, 15), "场景 B: 非人类骨架 — 6 种不同 skeleton JSON, 动作随骨架而变", fill=(210, 230, 255))

for idx, (preset_id, pose_key, label) in enumerate(nonhuman):
    r, c = divmod(idx, cols2)
    x = 20 + c * (tw2 + 20)
    y = 50 + r * (th2 + 60)
    cell = Image.new("RGB", (tw2, th2), (26, 34, 48))
    dd = ImageDraw.Draw(cell)
    frames = render_preset_frames(preset_id, pose_key)
    if frames:
        # 找中间关键帧
        mid = len(frames)//2
        cell.paste(frames[mid][1].crop((100, 50, 400, 450)).resize((tw2, th2), Image.BILINEAR), (0,0))
    dd.rectangle([0, 0, tw2-1, th2-1], outline=(70, 90, 120))
    sheet2.paste(cell, (x, y))
    d2.text((x+4, y+th2+6), label, fill=(230, 240, 255))
    d2.text((x+4, y+th2+22), PRESETS[preset_id]["skeleton"], fill=(130, 150, 180))

sheet2.save(f"{OUT}/B_nonhuman_skeletons.jpg", "JPEG", quality=90)
print(f"  -> B_nonhuman_skeletons.jpg {sheet_w2}×{sheet_h2}")

# ============================================================
# 场景 C: 同一骨架换全身装备套装 — 4 职业换衣服
# ============================================================

print("=== 场景 C: 同一骨架换装备套装 ===")
outfits = [
    ("warrior",      "战士",      "humanoid_7", (0.88, 0.42, 0.32), {"right_hand":"iron_sword","torso":"plate","head":"plate","back":"red_cape"}),
    ("mage",         "法师",      "humanoid_7", (0.40, 0.52, 0.92), {"right_hand":"staff_arcane","torso":"robe_blue","head":"pointed_hat"}),
    ("thief",        "盗贼",      "humanoid_7", (0.22, 0.22, 0.28), {"right_hand":"dagger","torso":"leather","head":"hood"}),
    ("archer",       "弓箭手",    "humanoid_7", (0.45, 0.62, 0.42), {"right_hand":"bow_short","torso":"leather","head":"cowl"}),
]

cols3 = 4; rows3 = 2
tw3, th3 = 280, 340
sheet_w3 = cols3 * (tw3 + 20) + 20
sheet_h3 = rows3 * (th3 + 60) + 60
sheet3 = Image.new("RGB", (sheet_w3, sheet_h3), (16, 22, 34))
d3 = ImageDraw.Draw(sheet3)
d3.text((20, 15), "场景 C: 同一 humanoid_7 骨架, 换身体 tint + 衣服 + 头盔 + 武器", fill=(210, 230, 255))

pose_keys = ["warrior_attack", "mage_attack", "thief_attack", "archer_attack"]
for idx, (pid, cn, skel, tint, eqs) in enumerate(outfits):
    PRESETS[pid + "_scenario"] = {"skeleton": skel, "body_tint": tint, "equipment": eqs}
    pkey = pose_keys[idx]
    frames = render_preset_frames(pid + "_scenario", pkey)
    r, c = divmod(idx, cols3)
    x = 20 + c * (tw3 + 20)
    y = 50 + r * (th3 + 60)
    cell = Image.new("RGB", (tw3, th3), (26, 34, 48))
    dd = ImageDraw.Draw(cell)
    if frames:
        cell.paste(frames[0][1].crop((100, 50, 400, 450)).resize((tw3, th3), Image.BILINEAR), (0,0))
    dd.rectangle([0, 0, tw3-1, th3-1], outline=(70, 90, 120))
    sheet3.paste(cell, (x, y))
    d3.text((x+4, y+th3+6), cn, fill=(230, 240, 255))
    d3.text((x+4, y+th3+22), f"骨架={skel}", fill=(130, 150, 180))
    d3.text((x+4, y+th3+38), f"装备: {', '.join(eqs.values())}", fill=(100, 115, 140))

sheet3.save(f"{OUT}/C_swap_outfits.jpg", "JPEG", quality=90)
print(f"  -> C_swap_outfits.jpg {sheet_w3}×{sheet_h3}")

# ============================================================
# 总览
# ============================================================

overview_w = 1280
overview_h = 60 + sheet_h + 20 + sheet_h2 + 20 + sheet_h3 + 20
overview = Image.new("RGB", (overview_w, overview_h), (10, 14, 22))
do = ImageDraw.Draw(overview)
do.text((20, 15), "RiggedCharacter v2 — 高度定制化骨骼系统", fill=(230, 245, 255))
do.text((20, 36), "骨架可替换 (6+ 种) | 装备可插拔 (武器/胸甲/头盔/披风/鞋子) | 本体可换色/换体型", fill=(150, 170, 200))

y0 = 60
overview.paste(sheet, (0, y0))
y1 = y0 + sheet_h + 20
overview.paste(sheet2, (0, y1))
y2 = y1 + sheet_h2 + 20
overview.paste(sheet3, (0, y2))

overview.save(f"{OUT}/overview_combined.jpg", "JPEG", quality=92)
print(f"\n=== 总览 ===")
print(f"  overview_combined.jpg {overview_w}×{overview_h}")
print(f"\n全部输出在: {OUT}/")
for f in sorted(os.listdir(OUT)):
    p = os.path.join(OUT, f)
    size = os.path.getsize(p)
    if size > 1024*1024:
        size_str = f"{size/1024/1024:.1f}M"
    else:
        size_str = f"{size//1024}K"
    print(f"  {f}: {size_str}")
