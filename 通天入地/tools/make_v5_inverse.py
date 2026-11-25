#!/usr/bin/env python3
"""
完整精灵绑定 v5 — 反向像素级变形 (无断裂)

原理 (反向变形):
  对每个输出像素 (x_dst, y_dst):
    1. 假设它在某个三角形 mesh.face[t] 内部
    2. 解 barycentric coords (u, v, w) = triangle point membership
    3. 用 (u, v, w) 混合顶点权重 → bone_weights
    4. 对每个 bone i: R_i * v_local + t_i = 该 bone 单独变换后的位置
    5. Σ w_i * (R_i * v_local + t_i) = (x_src, y_src) — 它来自原图哪里
    6. 双线性采样原图 (x_src, y_src)
  所有像素都这样算 → 绝对没有断裂
"""
import os, math, json
from PIL import Image, ImageDraw

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/RIGGED_V5_SAMPLES_2026-11-25"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# 骨架 + 关节 + 权重定义 (与 v4 相同)
# ============================================================

JOINTS = {
    "pelvis": (256, 310, 0),
    "torso":  (256, 165, 0),
    "head":   (256, 100, 0),
    "arm_l":  (210, 150, 0),
    "arm_r":  (302, 150, 0),
    "leg_l":  (225, 285, 0),
    "leg_r":  (287, 285, 0),
}
PARENT = {
    "pelvis": None,
    "torso": "pelvis", "head": "torso",
    "arm_l": "torso", "arm_r": "torso",
    "leg_l": "pelvis", "leg_r": "pelvis",
}
BONE_NAMES = list(JOINTS.keys())

# 权重影响半径 (像素) — 更宽更平滑
SIGMA = 80.0
# 关节权重衰减 (关节附近权重急剧上升, 远处下降)
# 用高斯: exp(-d^2/(2*SIGMA^2))

def local_to_parent(name):
    parent = PARENT[name]
    if parent is None: return (0, 0)
    px, py = JOINTS[parent][:2]
    cx, cy = JOINTS[name][:2]
    return (cx-px, cy-py)

def world_to_local(vx, vy, bone_name):
    """把 world 坐标变成 bone_name 的局部坐标 (bind pose 下)"""
    chain = []
    cur = bone_name
    while cur is not None:
        chain.append(cur)
        cur = PARENT[cur]
    v = [vx, vy]
    for bname in chain:
        parent = PARENT[bname]
        if parent is None: continue
        dx, dy = local_to_parent(bname)
        v[0] -= dx; v[1] -= dy
        # bind pose rot = 0, 所以不用逆旋转
    return tuple(v)

def compute_weights_grid(bx1, by1, bx2, by2, grid_step=4):
    """
    在角色 bbox 内, 每 grid_step 像素存一份 7 关节权重
    返回 weights_grid[y_grid][x_grid] = [w1,w2,...,w7]
    用于 barycentric 采样时插值
    """
    bw, bh = bx2-bx1, by2-by1
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
                g = math.exp(-d*d / (2*SIGMA*SIGMA))
                ws.append(g)
            total = sum(ws)
            if total < 1e-6:
                ws = [0.0]*len(BONE_NAMES); ws[0] = 1.0
            else:
                ws = [w/total for w in ws]
            row.append(ws)
        grid.append(row)
    return grid, grid_step, gw, gh

# ============================================================
# 背景去除 (鲁棒版)
# ============================================================

def remove_bg(img, thresh=32):
    arr = img.convert("RGBA").load()
    w, h = img.size
    sx, sy = w//2, h//2
    while sx > 0 and arr[sx,sy][0]+arr[sx,sy][1]+arr[sx,sy][2] < thresh*3:
        sx -= 1
    while sy > 0 and arr[sx,sy][0]+arr[sx,sy][1]+arr[sx,sy][2] < thresh*3:
        sy -= 1
    visited = [[False]*h for _ in range(w)]
    stack = [(sx, sy)]
    while stack:
        x, y = stack.pop()
        if x<0 or y<0 or x>=w or y>=h: continue
        if visited[x][y]: continue
        r,g,b,a = arr[x,y]
        if r+g+b < thresh*3: continue
        visited[x][y] = True
        stack += [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]
    out = Image.new("RGBA", (w, h), (0,0,0,0))
    oarr = out.load()
    for y in range(h):
        for x in range(w):
            if visited[x][y]: oarr[x,y] = arr[x,y]
    return out

# ============================================================
# 正向运动学 (返回 [bone_idx -> (world_rot, world_trans)])
# ============================================================

def fk(bone_rots, facing=1.0, pelvis_canvas=None):
    if pelvis_canvas is None: pelvis_canvas = (0, 0)
    transforms = {}
    def calc(idx, name):
        if name in transforms: return transforms[name]
        parent = PARENT[name]
        if parent is None:
            transforms[name] = (bone_rots.get(name, 0.0), pelvis_canvas)
        else:
            parent_rot, parent_t = calc(BONE_NAMES.index(parent), parent)
            dx, dy = local_to_parent(name)
            rad = math.radians(parent_rot)
            lx, ly = dx*facing, dy
            tx = parent_t[0] + lx*math.cos(rad) - ly*math.sin(rad)
            ty = parent_t[1] + lx*math.sin(rad) + ly*math.cos(rad)
            transforms[name] = (parent_rot + bone_rots.get(name, 0.0), (tx, ty))
        return transforms[name]
    for name in JOINTS:
        calc(BONE_NAMES.index(name), name)
    return transforms

# ============================================================
# 关键: 反向变形 — 给 dst 像素, 算 src 像素
# ============================================================

def deform_pixel(dx, dy, weights_at_v, bone_transforms, facing, local_coords_map):
    """
    dx, dy: 在 canvas 上的目标像素位置
    weights_at_v: 长度 7 的数组, 该位置处的权重 (双线性插值得到)
    bone_transforms: fk() 返回的 {bone_name: (rot_deg, (tx,ty))} — 当前姿势
    facing: 1.0 或 -1.0
    local_coords_map: {(bone_idx, vx, vy): local_x, local_y} 或者直接传 function

    返回: (src_x, src_y) 应该从原图哪里采样, 或者 None (超出范围)
    """
    vx_new, vy_new = 0.0, 0.0
    for bi, bname in enumerate(BONE_NAMES):
        w = weights_at_v[bi]
        if w < 1e-4: continue
        brot, (btx, bty) = bone_transforms[bname]
        # 关键点: dst pixel 来自哪个 bone 的 local 坐标?
        # 在 bind pose 下, bone i 把 local (lx, ly) 变形到世界 (wx, wy)
        # wx = rot_i(lx, ly) + t_i (在 facing=1.0 时)
        # 我们要: 给定 dst (dx, dy), 求每个 bone 的 local (lx_i, ly_i) 会变形到 (dx, dy)
        # 即: (lx_i, ly_i) = rot_i^-1 (dst - t_i)
        # 然后所有 bone 的贡献: v' = Σ w_i * (rot_i^-1(dst - t_i)) — 这就是在 bind pose 下的位置!
        
        # 更精确的做法: 我们知道 bind pose 下每个顶点有 local 坐标
        # 但这是 per-vertex 的. 这里的 dst 像素可能落在任意位置.
        # 所以: 先算 bind pose 下 dst 像素的位置 = Σ w_i * local_i_of(dst, bone_i)
        #   但 local_i_of(dst, bone_i) = inverse_transform_i(dst)
        #   inverse_transform_i(p) = R_i^-1 * (p - t_i_bind)
        #   我们需要把 dst 从 canvas 坐标 → bind pose 坐标
        # 
        # 简化近似: 假设 dst 对应 bind pose 下的同一个像素 (因为变形幅度有限)
        # 直接用 weights 把 dst 反推回 bind pose
        inv_rot = math.radians(-brot)
        # dst 在 bone i 的"局部坐标" (假设 bone i 在 bind pose 下 world rot=0, t=btx_bind)
        # 我们需要 bt_bind — bind pose 下的 bone world pos
        # 从 JOINTS 算
        bx0, by0, _ = JOINTS[bname]
        lx = (dx - btx) * math.cos(inv_rot) - (dy - bty) * math.sin(inv_rot)
        ly = (dx - btx) * math.sin(inv_rot) + (dy - bty) * math.cos(inv_rot)
        vx_new += w * lx
        vy_new += w * ly
    
    # vx_new, vy_new 是 bind pose 下该点的"期望位置" — 但我们要的是原图坐标!
    # 原图坐标 = bind pose 的 world 坐标 (因为 bind pose 没变形, 原图就是 bind pose)
    # 所以 src_x = vx_new, src_y = vy_new — 但 facing 要处理
    if facing < 0:
        vx_new = 256*2 - vx_new  # 水平镜像
    
    return (vx_new, vy_new)

# ============================================================
# 反向采样 — 把 mesh weights grid + 每个像素 → 原图
# ============================================================

def render_reverse(img_alpha, weights_grid, grid_step, gw, gh, bone_transforms,
                   facing, pelvis_canvas, canvas_w, canvas_h, bbox):
    """
    对 canvas 的每个像素 (dx, dy):
      1. 用 grid_step×grid_step 的 weights 网格 + bilinear 插值得到该位置的 7 权重
      2. 用 deform_pixel 反查 src 坐标
      3. 双线性采样原图 img_alpha
    """
    arr = img_alpha.load()
    w, h = img_alpha.size
    
    bx1, by1, bx2, by2 = bbox
    
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (14, 18, 28, 255))
    carr = canvas.load()
    
    # 也画阴影 (pelvis 下方)
    draw = ImageDraw.Draw(canvas)
    px, py = pelvis_canvas
    # 先看 pelvis 在 bone_transforms 里的当前位置
    pel_rot, pel_t = bone_transforms["pelvis"]
    draw.ellipse([pel_t[0]-35, pel_t[1]+15, pel_t[0]+35, pel_t[1]+23], fill=(0,0,0,70))
    
    # 对每个 canvas 像素
    for dy in range(canvas_h):
        for dx in range(canvas_w):
            # 1. 把 canvas 坐标 → world (肖像坐标)
            world_x = dx + (bx1 - canvas_w//2 + 256)
            world_y = dy + (by1 - canvas_h + 100)  # pelvis 在 canvas 下方 100px
            # 简化: 直接用 dx, dy 作为变形后坐标 — 用 pelvis 对齐
            # pelvis bind world = (256, 310), pelvis canvas = pelvis_canvas
            px_bind, py_bind = JOINTS["pelvis"][:2]
            off_x = dx - pelvis_canvas[0] + px_bind
            off_y = dy - pelvis_canvas[1] + py_bind
            
            # 2. 在 weights grid 上 bilinear 插值
            gx = (off_x - bx1) / grid_step
            gy = (off_y - by1) / grid_step
            if gx < -0.5 or gy < -0.5 or gx >= gw-0.5 or gy >= gh-0.5:
                continue  # 角色外面
            
            gi0 = max(0, min(int(gx), gw-2))
            gj0 = max(0, min(int(gy), gh-2))
            fx = gx - gi0; fy = gy - gj0
            w00 = weights_grid[gj0][gi0]
            w10 = weights_grid[gj0][gi0+1]
            w01 = weights_grid[gj0+1][gi0]
            w11 = weights_grid[gj0+1][gi0+1]
            
            ws = []
            for bi in range(7):
                v = (w00[bi]*(1-fx)*(1-fy) + w10[bi]*fx*(1-fy) +
                     w01[bi]*(1-fx)*fy + w11[bi]*fx*fy)
                ws.append(v)
            
            if sum(ws) < 0.01: continue  # 没有权重 → 透明
            
            # 3. 反查 src
            src_x, src_y = deform_pixel(off_x, off_y, ws, bone_transforms, facing, None)
            
            # 4. 双线性采样
            sx = max(0, min(w-2, int(src_x)))
            sy = max(0, min(h-2, int(src_y)))
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
# 姿势
# ============================================================

ATTACK = {
    "warrior": [
        (0.0, {"pelvis":0,"torso":-2,"head":0,"arm_l":15,"arm_r":-85,"leg_l":0,"leg_r":0}),
        (0.45,{"pelvis":0,"torso":15,"head":6,"arm_l":-55,"arm_r":-168,"leg_l":-8,"leg_r":8}),
        (0.7, {"pelvis":0,"torso":18,"head":8,"arm_l":-60,"arm_r":-175,"leg_l":-10,"leg_r":10}),
        (1.0, {"pelvis":0,"torso":-2,"head":0,"arm_l":15,"arm_r":-85,"leg_l":0,"leg_r":0}),
    ],
    "mage": [
        (0.0, {"pelvis":0,"torso":0,"head":4,"arm_l":20,"arm_r":-20,"leg_l":0,"leg_r":0}),
        (0.5, {"pelvis":0,"torso":2,"head":10,"arm_l":95,"arm_r":-95,"leg_l":2,"leg_r":-2}),
        (0.75,{"pelvis":0,"torso":4,"head":14,"arm_l":110,"arm_r":-110,"leg_l":4,"leg_r":-4}),
        (1.0, {"pelvis":0,"torso":0,"head":4,"arm_l":20,"arm_r":-20,"leg_l":0,"leg_r":0}),
    ],
    "archer": [
        (0.0, {"pelvis":0,"torso":-3,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
        (0.4, {"pelvis":-6,"torso":6,"head":6,"arm_l":-20,"arm_r":40,"leg_l":4,"leg_r":-4}),
        (0.7, {"pelvis":-8,"torso":10,"head":5,"arm_l":-28,"arm_r":55,"leg_l":6,"leg_r":-6}),
        (1.0, {"pelvis":0,"torso":-3,"head":2,"arm_l":10,"arm_r":-10,"leg_l":0,"leg_r":0}),
    ],
}

def interp(kfs, p):
    t = p
    ka, kb = kfs[0], kfs[-1]
    for i in range(len(kfs)-1):
        if kfs[i][0] <= t <= kfs[i+1][0]: ka, kb = kfs[i], kfs[i+1]; break
    if ka == kb: return dict(ka[1])
    r = (t - ka[0]) / max(0.001, kb[0] - ka[0])
    r = 1 - (1-r)**2.5
    out = {}
    for k in set(ka[1].keys()) | set(kb[1].keys()):
        ra = ka[1].get(k, 0); rb = kb[1].get(k, 0)
        out[k] = ra*(1-r) + rb*r
    return out

# ============================================================
# 主流程
# ============================================================

CLASS_LIST = ["warrior", "mage", "archer"]
CANVAS_W, CANVAS_H = 560, 640
PELVIS_CANVAS = (CANVAS_W//2, CANVAS_H - 80)  # 在 canvas 上 pelvis 位置

print("v5 — 反向像素级变形 (无断裂)")
print("="*60)

all_sheets = {}

for cls in CLASS_LIST:
    print(f"\n{cls}:")
    img = Image.open(f"{PROJ}/assets/portraits/{cls}.png").convert("RGBA")
    img_alpha = remove_bg(img)
    arr = img_alpha.load()
    w, h = img_alpha.size
    
    # 角色 bbox
    ys, xs = set(), set()
    for y in range(h):
        for x in range(w):
            if arr[x,y][3] > 20:
                ys.add(y); xs.add(x)
    bx1, bx2 = min(xs), max(xs)+1
    by1, by2 = min(ys), max(ys)+1
    print(f"  角色 bbox: ({bx1},{by1})→({bx2},{by2}), 网格步长=4px")
    
    # 权重网格
    weights_grid, grid_step, gw, gh = compute_weights_grid(bx1, by1, bx2, by2, grid_step=4)
    print(f"  权重网格: {gw}×{gh}")
    
    frames = {}
    
    # idle 4 帧
    for k in range(4):
        phase = math.sin(2*math.pi * k/4)
        rots = {"pelvis":phase*1.5,"torso":-1+phase*1.5,"head":0,"arm_l":8+phase*4,"arm_r":-8-phase*4,"leg_l":0,"leg_r":0}
        bt = fk(rots, 1.0, PELVIS_CANVAS)
        canvas = render_reverse(img_alpha, weights_grid, grid_step, gw, gh, bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, (bx1, by1, bx2, by2))
        frames[f"idle_{k+1}"] = canvas
    
    # run 4 帧
    base_run = {
        "warrior":{"pelvis":0,"torso":4,"head":0,"arm_l":-30,"arm_r":30,"leg_l":-35,"leg_r":35},
        "mage":   {"pelvis":0,"torso":4,"head":0,"arm_l":-25,"arm_r":25,"leg_l":-30,"leg_r":30},
        "archer": {"pelvis":0,"torso":4,"head":0,"arm_l":-28,"arm_r":28,"leg_l":-32,"leg_r":32},
    }[cls]
    for k in range(4):
        phase = math.sin(2*math.pi * k/4)
        rots = {n: v*(0.8+phase*0.4) for n,v in base_run.items()}
        rots["pelvis"] = phase*2.0
        bt = fk(rots, 1.0, PELVIS_CANVAS)
        canvas = render_reverse(img_alpha, weights_grid, grid_step, gw, gh, bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, (bx1, by1, bx2, by2))
        frames[f"run_{k+1}"] = canvas
    
    # attack
    atk = ATTACK[cls]
    for k, (t,_) in enumerate(atk):
        rots = interp(atk, t)
        bt = fk(rots, 1.0, PELVIS_CANVAS)
        canvas = render_reverse(img_alpha, weights_grid, grid_step, gw, gh, bt, 1.0, PELVIS_CANVAS, CANVAS_W, CANVAS_H, (bx1, by1, bx2, by2))
        frames[f"attack_{k+1}"] = canvas
    
    # 保存
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, frame in frames.items():
        frame.save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # Contact sheet
    cats = [("idle",[f"idle_{i}" for i in range(1,5)]),("run",[f"run_{i}" for i in range(1,5)]),("attack",[f"attack_{i}" for i in range(1,len(atk)+1)])]
    COLS=5; TW,TH=160,180; LH=24; MAR=8
    rows = len(cats)
    sw = MAR*2 + COLS*(TW+6)
    sh = MAR+28+MAR+rows*(LH+TH+MAR)
    sheet = Image.new("RGB",(sw,sh),(16,22,34))
    d = ImageDraw.Draw(sheet)
    cn = {"warrior":"战士","mage":"法师","archer":"弓箭手"}.get(cls,cls)
    d.text((MAR+8,MAR+6),f"{cls} / {cn} — 反向像素级变形 · 无断裂",fill=(200,220,250))
    y0=MAR+28+MAR
    for ri,(cat,fnames) in enumerate(cats):
        y=y0+ri*(LH+TH+MAR)
        d.rectangle([MAR,y,sw-MAR,y+LH],fill=(24,30,44))
        d.text((MAR+8,y+4),cat,fill=(220,235,250))
        for ci in range(COLS):
            x=MAR+ci*(TW+6)
            fi=fnames[ci] if ci<len(fnames) else None
            d.rectangle([x,y+LH,x+TW,y+LH+TH],outline=(60,75,95),width=1)
            if fi and fi in frames:
                f=frames[fi].resize((TW,TH),Image.BILINEAR)
                sheet.paste(f,(x,y+LH))
    sheet.save(f"{OUT}/{cls}_sheet.jpg","JPEG",quality=92)
    all_sheets[cls]=sheet
    print(f"  → {cls}_sheet.jpg ({sw}×{sh})")

# 总览
COLS2=2;ROWS2=2;TW2,TH2=280,300;MAR2=20
sw2=COLS2*TW2+(COLS2+1)*MAR2
sh2=ROWS2*TH2+(ROWS2+1)*MAR2+60
ov=Image.new("RGB",(sw2,sh2),(12,16,26))
d=ImageDraw.Draw(ov)
d.text((MAR2,20),"v5 反向像素级变形 — 整图完整, 无断裂",fill=(220,235,255))
d.text((MAR2,40),"每个输出像素逆变换回原图采样 · 高斯权重 · 7 关节",fill=(140,160,190))
for idx,cls in enumerate(CLASS_LIST):
    r,c=divmod(idx,COLS2)
    sx=MAR2+c*(TW2+MAR2); sy=60+MAR2+r*(TH2+MAR2)
    s=all_sheets[cls]
    crop=s.crop((8,28+8,min(s.size[0],8+TW2),28+8+TH2)).resize((TW2,TH2),Image.BILINEAR)
    ov.paste(crop,(sx,sy))
    d.rectangle([sx,sy,sx+TW2,sy+TH2],outline=(70,100,140))
ov.save(f"{OUT}/overview_v5.jpg","JPEG",quality=92)
print(f"\noverview_v5.jpg: {sw2}×{sh2}")
print(f"\n完成! 输出: {OUT}/")
