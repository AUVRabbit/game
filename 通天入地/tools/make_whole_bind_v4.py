#!/usr/bin/env python3
"""
完整精灵绑定 v4 — 不切图, 自动权重蒙皮 + 骨骼驱动

核心思想:
  1. 完整肖像 → 去背景 → 得到角色 alpha
  2. 网格化: 角色 bbox 切成 M×N 网格 → 每格 = 2 三角形
  3. 自动权重: 每个顶点对 7 个关节的距离高斯衰减 + 归一化 (softmax 风格)
  4. FK: 关节旋转 → world transform (R, t)
  5. 蒙皮: v' = Σ w_i * (R_i * v_local + t_i)
  6. 渲染: 每个网格小四边形 = affine transform 把原图像素贴到变形位置
  
这样得到的是一张"可被骨骼变形的完整图", 没有割裂感。
"""
import os, math, json
from PIL import Image, ImageDraw

PROJ = "/workspace/通天入地"
OUT = f"{PROJ}/docs/RIGGED_V4_SAMPLES_2026-11-25"
os.makedirs(OUT, exist_ok=True)

# ============================================================
# Step 1: 去背景 (更鲁棒)
# ============================================================

def remove_bg(img, thresh=32):
    arr = img.convert("RGBA").load()
    w, h = img.size
    # 找内部 seed
    sx, sy = w//2, h//2
    while sx > 0 and arr[sx,sy][0]+arr[sx,sy][1]+arr[sx,sy][2] < thresh*3:
        sx -= 1
    while sy > 0 and arr[sx,sy][0]+arr[sx,sy][1]+arr[sx,sy][2] < thresh*3:
        sy -= 1
    # flood fill
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
    # alpha
    out = Image.new("RGBA", (w, h), (0,0,0,0))
    oarr = out.load()
    for y in range(h):
        for x in range(w):
            if visited[x][y]:
                oarr[x,y] = arr[x,y]
    return out

# ============================================================
# Step 2: 关节骨架 (与肖像模板对齐)
# ============================================================

# 7 关节 — 世界坐标 (512×512 肖像)
JOINTS = {
    "pelvis": (256, 310, 0),
    "torso":  (256, 165, 0),   # parent: pelvis, local=(0,-145)
    "head":   (256, 100, 0),   # parent: torso,  local=(0,-65)
    "arm_l":  (210, 150, 0),   # parent: torso,  local=(-46,-15)
    "arm_r":  (302, 150, 0),   # parent: torso,  local=(46,-15)
    "leg_l":  (225, 285, 0),   # parent: pelvis, local=(-31,-25)
    "leg_r":  (287, 285, 0),   # parent: pelvis, local=(31,-25)
}
PARENT = {
    "pelvis": None,
    "torso": "pelvis", "head": "torso",
    "arm_l": "torso", "arm_r": "torso",
    "leg_l": "pelvis", "leg_r": "pelvis",
}
BONE_NAMES = ["pelvis","torso","head","arm_l","arm_r","leg_l","leg_r"]

def local_to_parent(joint_name):
    """返回 (dx, dy) 相对 parent 的 anchor"""
    parent = PARENT[joint_name]
    if parent is None: return (0, 0)
    px, py = JOINTS[parent][:2]
    cx, cy = JOINTS[joint_name][:2]
    return (cx - px, cy - py)

def world_to_local(v, joint_name):
    """把世界坐标 v 变到 joint 的局部坐标 (反向 FK)"""
    # 向上追溯到 root, 累积 R 和 t
    chain = []
    cur = joint_name
    while cur is not None:
        chain.append(cur)
        cur = PARENT[cur]
    # chain = [joint_name, ..., root]
    v_local = list(v)
    for bone_name in chain:
        parent = PARENT[bone_name]
        if parent is None: continue
        parent_local_anchor = local_to_parent(bone_name)
        # 在 parent 的局部坐标系下, bone 的 anchor = parent_local_anchor
        # v_local (bone 空间) → v_parent = R_bone * v_local + parent_local_anchor
        # 所以: v_local = R_bone^-1 * (v_parent - parent_local_anchor)
        # 但 R_bone 是关节旋转 (rest rot + 当前 rot), 在 bind pose 时 = 0
        bind_rot = JOINTS[bone_name][2]
        rad = math.radians(-bind_rot)
        dx, dy = parent_local_anchor
        v_local[0] = v_local[0] - dx
        v_local[1] = v_local[1] - dy
        v_local = [v_local[0]*math.cos(rad) - v_local[1]*math.sin(rad),
                   v_local[0]*math.sin(rad) + v_local[1]*math.cos(rad)]
    return tuple(v_local)

# ============================================================
# Step 3: 网格化 + 自动权重
# ============================================================

def build_mesh(img_with_alpha, grid_nx=28, grid_ny=28):
    """
    把角色区域网格化 (grid_nx × grid_ny 小四边形), 返回:
      vertices: [(x,y), ...] — 世界坐标 (肖像坐标系)
      faces:    [(a,b,c,d), ...] — 四边形顶点索引
      weights:  [(w1,w2,...,w7), ...] — 每个顶点对 7 个关节的权重
      bone_local: {vertex_idx: [(bone_idx, local_x, local_y), ...]} — 蒙皮时用
    """
    arr = img_with_alpha.load()
    w, h = img_with_alpha.size
    
    # 找角色 bbox
    ys = set(); xs = set()
    for y in range(h):
        for x in range(w):
            if arr[x,y][3] > 20:
                ys.add(y); xs.add(x)
    if not xs: return None
    bx1, bx2 = min(xs), max(xs)+1
    by1, by2 = min(ys), max(ys)+1
    
    # 在 bbox 上生成网格
    bw, bh = bx2 - bx1, by2 - by1
    dx = bw / grid_nx
    dy = bh / grid_ny
    
    vertices = []
    for j in range(grid_ny+1):
        for i in range(grid_nx+1):
            vx = bx1 + i * dx
            vy = by1 + j * dy
            vertices.append((vx, vy))
    
    faces = []
    for j in range(grid_ny):
        for i in range(grid_nx):
            a = j*(grid_nx+1) + i
            b = a + 1
            c = a + grid_nx + 2
            d = a + grid_nx + 1
            faces.append((a, b, c, d))
    
    # 权重: 每个顶点 → 到各关节的距离 → 高斯衰减 → 归一化
    sigma = 60.0  # 影响半径, 像素
    weights = []
    for vi, (vx, vy) in enumerate(vertices):
        dists = []
        for bname in BONE_NAMES:
            bx, by, _ = JOINTS[bname]
            d = math.hypot(vx - bx, vy - by)
            # 高斯权重: exp(-d^2 / (2*sigma^2))
            g = math.exp(-d*d / (2*sigma*sigma))
            dists.append(g)
        total = sum(dists)
        if total < 1e-6:
            # 太远, 全给 pelvis
            weights.append([1.0, 0, 0, 0, 0, 0, 0])
        else:
            weights.append([d/total for d in dists])
    
    # 每个顶点在各关节局部坐标系下的位置
    bone_local = {}
    for vi, (vx, vy) in enumerate(vertices):
        bl = []
        for bi, bname in enumerate(BONE_NAMES):
            lx, ly = world_to_local((vx, vy), bname)
            bl.append((bi, lx, ly))
        bone_local[vi] = bl
    
    # alpha mask — 哪些四边形需要画
    face_alpha = []
    for (a,b,c,d) in faces:
        va = vertices[a]; vb = vertices[b]
        vc = vertices[c]; vd = vertices[d]
        cx = (va[0]+vb[0]+vc[0]+vd[0])/4
        cy = (va[1]+vb[1]+vc[1]+vd[1])/4
        try:
            face_alpha.append(arr[int(cx), int(cy)][3] > 20)
        except:
            face_alpha.append(False)
    
    return {
        "vertices": vertices,
        "faces": faces,
        "weights": weights,
        "bone_local": bone_local,
        "face_alpha": face_alpha,
        "bbox": (bx1, by1, bx2, by2),
        "grid_nx": grid_nx, "grid_ny": grid_ny,
    }

# ============================================================
# Step 4: 正向运动学 + 蒙皮变形
# ============================================================

def fk(bone_rots, facing=1.0, pelvis_pos=None):
    """
    计算每个关节的 world transform: (rot_deg, trans)
    bone_rots: {bone_name: rot_deg}
    """
    if pelvis_pos is None:
        pelvis_pos = (0, 0)
    transforms = {}
    
    def calc(name):
        if name in transforms: return transforms[name]
        parent = PARENT[name]
        if parent is None:
            transforms[name] = (bone_rots.get(name, 0), pelvis_pos)
        else:
            parent_rot, parent_t = calc(parent)
            local_anchor = local_to_parent(name)
            # 把 local anchor 旋转到 parent 的方向, 再加上 parent t
            rad = math.radians(parent_rot)
            lx = local_anchor[0] * facing
            ly = local_anchor[1]
            tx = parent_t[0] + lx*math.cos(rad) - ly*math.sin(rad)
            ty = parent_t[1] + lx*math.sin(rad) + ly*math.cos(rad)
            wrot = parent_rot + bone_rots.get(name, 0)
            transforms[name] = (wrot, (tx, ty))
        return transforms[name]
    
    for name in JOINTS:
        calc(name)
    return transforms

def deform_mesh(mesh, bone_rots, facing=1.0, pelvis_pos=None):
    """用蒙皮把 mesh vertices 变到新位置"""
    if pelvis_pos is None:
        pelvis_pos = (0, 0)
    transforms = fk(bone_rots, facing, pelvis_pos)
    
    new_verts = []
    for vi in range(len(mesh["vertices"])):
        ws = mesh["weights"][vi]
        bl_list = mesh["bone_local"][vi]
        vx_new, vy_new = 0.0, 0.0
        for bi, bname in enumerate(BONE_NAMES):
            w = ws[bi]
            if w < 0.001: continue
            _, lx, ly = bl_list[bi]
            brot, (btx, bty) = transforms[bname]
            rad = math.radians(brot)
            # 先应用 facing
            lx_f = lx * facing
            # 旋转 local
            rx = lx_f*math.cos(rad) - ly*math.sin(rad)
            ry = lx_f*math.sin(rad) + ly*math.cos(rad)
            # 平移到 world
            vx_new += w * (rx + btx)
            vy_new += w * (ry + bty)
        new_verts.append((vx_new, vy_new))
    
    return new_verts

# ============================================================
# Step 5: 渲染 — 每个四边形 = affine transform 把原图像素贴到变形位置
# ============================================================

def render_mesh(img_alpha, mesh, deformed_verts, canvas_w, canvas_h, offset=(0,0)):
    """
    把变形后的网格渲染到 canvas.
    每个四边形: 原图 quad → 变形 quad. 用 3 点 affine 近似.
    """
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (14, 18, 28, 255))
    
    bx1, by1, _, _ = mesh["bbox"]
    nx = mesh["grid_nx"]; ny = mesh["grid_ny"]
    dx, dy = mesh["vertices"][1][0] - mesh["vertices"][0][0], mesh["vertices"][nx+1][1] - mesh["vertices"][0][1]
    
    for fi, (ai, bi, ci, di) in enumerate(mesh["faces"]):
        if not mesh["face_alpha"][fi]:
            continue
        
        # 原四边形世界坐标 → 肖像像素坐标
        wa = mesh["vertices"][ai]
        wb = mesh["vertices"][bi]
        wd = mesh["vertices"][di]
        wc = mesh["vertices"][ci]
        
        # 变形后四边形 → canvas 坐标 (加 offset)
        da = deformed_verts[ai]; db = deformed_verts[bi]
        dc = deformed_verts[ci]; dd = deformed_verts[di]
        
        # 偏移到 canvas 中心
        ox, oy = offset
        da = (da[0] + ox, da[1] + oy)
        db = (db[0] + ox, db[1] + oy)
        dc = (dc[0] + ox, dc[1] + oy)
        dd = (dd[0] + ox, dd[1] + oy)
        
        # 用 3 点确定 affine transform (quad 近似)
        # 先算 src 3 点: (wa, wb, wc) → dst 3 点: (da, db, dc)
        src = [wa[0], wa[1], wb[0], wb[1], wc[0], wc[1]]
        dst = [da[0], da[1], db[0], db[1], dc[0], dc[1]]
        
        try:
            # PIL 的 transform 用 backward mapping: 输出点 → 输入点
            # 我们要: src 3 点的 quad affine 把 src 点送到 dst 点
            # backward = inverse of forward
            # 计算 forward 的 affine matrix
            # dst = M * src → M = dst * src^-1
            # 3x3 系统: dst_i = a*src_i_x + b*src_i_y + c
            # 但用 4 点做 bilinear 更准. PIL 不支持 bilinear, 只能 affine 3 点.
            # 用三角形 abc 近似四边形
            inv = _invert_affine_3(src, dst)
            if inv:
                # 从原图切出该 quad 的 bounding box
                all_x = [wa[0], wb[0], wc[0], wd[0]]
                all_y = [wa[1], wb[1], wc[1], wd[1]]
                qx1, qx2 = int(max(0, min(all_x)-2)), int(min(img_alpha.size[0], max(all_x)+2))
                qy1, qy2 = int(max(0, min(all_y)-2)), int(min(img_alpha.size[1], max(all_y)+2))
                if qx2 <= qx1 or qy2 <= qy1: continue
                quad_img = img_alpha.crop((qx1, qy1, qx2, qy2))
                
                # 做局部 affine — inv 把 canvas 点 (dx, dy) 映射回 quad_img 里的 (sx, sy)
                # 但 inv 是全局的 (wx → dst wx), 我们需要 quad_img 局部坐标
                # 简化: 对 quad_img 的 bbox 范围做 transform
                tw, th = quad_img.size
                target = canvas.crop((
                    int(min(da[0],db[0],dc[0],dd[0])-2),
                    int(min(da[1],db[1],dc[1],dd[1])-2),
                    int(max(da[0],db[0],dc[0],dd[0])+2),
                    int(max(da[1],db[1],dc[1],dd[1])+2),
                ))
                if target.size[0] > 1 and target.size[1] > 1:
                    # 更简单的办法: 用每个像素采样
                    # 但这太慢. 换一个快速近似: 把 quad_img 直接贴到 canvas 的变形 quad 位置
                    # 用一个小 patch: 把 img_alpha 裁剪 quad 区域, 然后用 Image.transform 做 affine
                    
                    # 把 src 3 点从肖像全局坐标 → quad_img 局部坐标
                    local_src = [wa[0]-qx1, wa[1]-qy1, wb[0]-qx1, wb[1]-qy1, wc[0]-qx1, wc[1]-qy1]
                    # dst 3 点保持 canvas 坐标 (PIL transform 的 output coordinate)
                    
                    result = quad_img.transform(
                        (target.size[0] + 4, target.size[1] + 4),
                        Image.AFFINE,
                        list(_invert_affine_3(local_src, [da[0]-target.offset[0], da[1]-target.offset[1],
                                                         db[0]-target.offset[0], db[1]-target.offset[1],
                                                         dc[0]-target.offset[0], dc[1]-target.offset[1]])),
                        Image.BILINEAR,
                        fill=(0,0,0,0),
                    )
                    canvas.alpha_composite(result, (target.offset[0]-2, target.offset[1]-2))
        except Exception as e:
            # 兜底: 直接画三角形
            pass
    
    return canvas.convert("RGB")

def _invert_affine_3(src_pts, dst_pts):
    """
    src_pts: 6 floats (3 个 (x,y)) — 原三角形
    dst_pts: 6 floats — 变形后三角形
    返回 inverse affine 的 6 floats (PIL 格式)
    """
    sx1,sy1 = src_pts[0], src_pts[1]
    sx2,sy2 = src_pts[2], src_pts[3]
    sx3,sy3 = src_pts[4], src_pts[5]
    dx1,dy1 = dst_pts[0], dst_pts[1]
    dx2,dy2 = dst_pts[2], dst_pts[3]
    dx3,dy3 = dst_pts[4], dst_pts[5]
    
    # M * src = dst → 解线性方程求 M 的 6 个参数 (a,b,c,d,e,f)
    # [a b c] [sx_i]   [dx_i]
    # [d e f] [sy_i] = [dy_i]
    #          [1  ]
    det = (sx2-sx1)*(sy3-sy1) - (sx3-sx1)*(sy2-sy1)
    if abs(det) < 1e-6: return None
    a = ((dx2-dx1)*(sy3-sy1) - (dx3-dx1)*(sy2-sy1)) / det
    b = ((sx3-sx1)*(dx2-dx1) - (sx2-sx1)*(dx3-dx1)) / det
    c = dx1 - a*sx1 - b*sy1
    d = ((dy2-dy1)*(sy3-sy1) - (dy3-dy1)*(sy2-sy1)) / det
    e = ((sx3-sx1)*(dy2-dy1) - (sx2-sx1)*(dy3-dy1)) / det
    f = dy1 - d*sx1 - e*sy1
    
    # 求逆矩阵 (把 dst 点映回 src)
    det2 = a*e - b*d
    if abs(det2) < 1e-6: return None
    ia =  e / det2
    ib = -b / det2
    ic = (b*f - c*e) / det2
    id2 = -d / det2
    ie =  a / det2
    if2 = (c*d - a*f) / det2
    
    return [ia, ib, ic, id2, ie, if2]

# ============================================================
# Step 6: 姿势 + 渲染
# ============================================================

ATTACK_POSES = {
    "warrior": [
        (0.0, {"pelvis":0, "torso":-2, "head":0, "arm_l":15, "arm_r":-85, "leg_l":0, "leg_r":0}),
        (0.45, {"pelvis":0, "torso":15, "head":6, "arm_l":-55, "arm_r":-168, "leg_l":-8, "leg_r":8}),
        (0.7, {"pelvis":0, "torso":18, "head":8, "arm_l":-60, "arm_r":-175, "leg_l":-10, "leg_r":10}),
        (1.0, {"pelvis":0, "torso":-2, "head":0, "arm_l":15, "arm_r":-85, "leg_l":0, "leg_r":0}),
    ],
    "mage": [
        (0.0, {"pelvis":0, "torso":0, "head":4, "arm_l":20, "arm_r":-20, "leg_l":0, "leg_r":0}),
        (0.5, {"pelvis":0, "torso":2, "head":10, "arm_l":95, "arm_r":-95, "leg_l":2, "leg_r":-2}),
        (0.75, {"pelvis":0, "torso":4, "head":14, "arm_l":110, "arm_r":-110, "leg_l":4, "leg_r":-4}),
        (1.0, {"pelvis":0, "torso":0, "head":4, "arm_l":20, "arm_r":-20, "leg_l":0, "leg_r":0}),
    ],
    "archer": [
        (0.0, {"pelvis":0, "torso":-3, "head":2, "arm_l":10, "arm_r":-10, "leg_l":0, "leg_r":0}),
        (0.4, {"pelvis":-6, "torso":6, "head":6, "arm_l":-20, "arm_r":40, "leg_l":4, "leg_r":-4}),
        (0.7, {"pelvis":-8, "torso":10, "head":5, "arm_l":-28, "arm_r":55, "leg_l":6, "leg_r":-6}),
        (1.0, {"pelvis":0, "torso":-3, "head":2, "arm_l":10, "arm_r":-10, "leg_l":0, "leg_r":0}),
    ],
}

def interp(kfs, progress):
    t = progress
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

CANVAS_W, CANVAS_H = 600, 680

def render_one(mesh, bone_rots, facing, pelvis_canvas):
    """渲染一帧"""
    deformed = deform_mesh(mesh, bone_rots, facing, pelvis_canvas)
    offset_x = CANVAS_W//2 - pelvis_canvas[0]
    offset_y = CANVAS_H - 100 - pelvis_canvas[1]
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (14, 18, 28, 255))
    # 先画阴影
    from PIL import ImageDraw
    draw = ImageDraw.Draw(canvas)
    draw.ellipse([pelvis_canvas[0]+offset_x-35, pelvis_canvas[1]+offset_y+15,
                  pelvis_canvas[0]+offset_x+35, pelvis_canvas[1]+offset_y+23],
                 fill=(0,0,0,70))
    return render_mesh_full(mesh, deformed, canvas, (offset_x, offset_y))

def render_mesh_full(mesh, deformed_verts, canvas, offset):
    """更高效的渲染 — 每个四边形用双线性近似"""
    img_alpha = mesh["_img_alpha"]
    ox, oy = offset
    
    # 先把 alpha 区域裁剪出来 — 避免背景干扰
    bx1, by1, bx2, by2 = mesh["bbox"]
    
    for fi, (ai, bi, ci, di) in enumerate(mesh["faces"]):
        if not mesh["face_alpha"][fi]: continue
        
        wa = mesh["vertices"][ai]; wb = mesh["vertices"][bi]
        wc = mesh["vertices"][ci]; wd = mesh["vertices"][di]
        da = deformed_verts[ai]; db = deformed_verts[bi]
        dc = deformed_verts[ci]; dd = deformed_verts[di]
        
        dxp = min(da[0],db[0],dc[0],dd[0])+ox
        dyp = min(da[1],db[1],dc[1],dd[1])+oy
        dx2 = max(da[0],db[0],dc[0],dd[0])+ox+2
        dy2 = max(da[1],db[1],dc[1],dd[1])+oy+2
        tw, th = int(max(1,dx2-dxp)), int(max(1,dy2-dyp))
        
        if tw < 2 or th < 2: continue
        
        # 把变形 quad 的 4 点映射到局部
        da_l = (da[0]+ox - dxp, da[1]+oy - dyp)
        db_l = (db[0]+ox - dxp, db[1]+oy - dyp)
        dc_l = (dc[0]+ox - dxp, dc[1]+oy - dyp)
        dd_l = (dd[0]+ox - dxp, dd[1]+oy - dyp)
        
        # 源 4 点 (肖像坐标)
        sa = wa; sb = wb; sc = wc; sd = wd
        
        # 用 2 个三角形分别处理, 这样更准
        # 三角形 1: a, b, c
        for tri_src, tri_dst in [
            [(sa,sb,sc), (da_l,db_l,dc_l)],
            [(sa,sc,sd), (da_l,dc_l,dd_l)],
        ]:
            src = [tri_src[0][0],tri_src[0][1], tri_src[1][0],tri_src[1][1], tri_src[2][0],tri_src[2][1]]
            dst = [tri_dst[0][0],tri_dst[0][1], tri_dst[1][0],tri_dst[1][1], tri_dst[2][0],tri_dst[2][1]]
            inv = _invert_affine_3(src, dst)
            if inv is None: continue
            
            # 从肖像里裁 src 附近的区域
            sx1 = max(0, int(min(tri_src[0][0],tri_src[1][0],tri_src[2][0])-2))
            sx2 = min(img_alpha.size[0], int(max(tri_src[0][0],tri_src[1][0],tri_src[2][0])+2))
            sy1 = max(0, int(min(tri_src[0][1],tri_src[1][1],tri_src[2][1])-2))
            sy2 = min(img_alpha.size[1], int(max(tri_src[0][1],tri_src[1][1],tri_src[2][1])+2))
            if sx2<=sx1 or sy2<=sy1: continue
            sub = img_alpha.crop((sx1, sy1, sx2, sy2))
            
            # 把 inv 的 src 点从肖像全局 → sub 局部
            local_src = [tri_src[0][0]-sx1, tri_src[0][1]-sy1,
                        tri_src[1][0]-sx1, tri_src[1][1]-sy1,
                        tri_src[2][0]-sx1, tri_src[2][1]-sy1]
            inv2 = _invert_affine_3(local_src, dst)
            if inv2 is None: continue
            
            try:
                resized = sub.transform((tw, th), Image.AFFINE, inv2, Image.BILINEAR, fill=(0,0,0,0))
                # 只贴三角 dst 内部的像素
                mask = Image.new("L", (tw, th), 0)
                mdraw = ImageDraw.Draw(mask)
                pts = [(int(tri_dst[0][0]), int(tri_dst[0][1])),
                      (int(tri_dst[1][0]), int(tri_dst[1][1])),
                      (int(tri_dst[2][0]), int(tri_dst[2][1]))]
                mdraw.polygon(pts, fill=255)
                # 应用 mask
                rgba_resized = resized.convert("RGBA")
                rarr = rgba_resized.load(); marr = mask.load()
                for py in range(th):
                    for px in range(tw):
                        if marr[px,py] == 0:
                            rarr[px,py] = (0,0,0,0)
                canvas.alpha_composite(rgba_resized, (dxp, dyp))
            except Exception:
                pass
    
    return canvas

# ============================================================
# 主流程
# ============================================================

CLASS_LIST = ["warrior", "mage", "archer"]

print("完整精灵绑定 v4 — 自动权重蒙皮")
print("="*60)

all_sheets = {}

for cls in CLASS_LIST:
    print(f"\n=== {cls} ===")
    img = Image.open(f"{PROJ}/assets/portraits/{cls}.png").convert("RGBA")
    img_alpha = remove_bg(img)
    
    # 网格化
    mesh = build_mesh(img_alpha, grid_nx=24, grid_ny=24)
    mesh["_img_alpha"] = img_alpha
    print(f"  网格: {mesh['grid_nx']}×{mesh['grid_ny']} = {len(mesh['vertices'])} 顶点, {len(mesh['faces'])} 四边形")
    
    # pelvis 在肖像里的位置 (世界坐标)
    pelvis_pos = JOINTS["pelvis"][:2]
    
    frames = {}
    
    # idle 4 帧
    for k in range(4):
        phase = math.sin(2*math.pi * k/4)
        rots = {
            "pelvis": phase*1.5,
            "torso": -1 + phase*1.5,
            "head": 0,
            "arm_l": 8 + phase*4,
            "arm_r": -8 - phase*4,
            "leg_l": 0, "leg_r": 0,
        }
        canvas = render_one(mesh, rots, 1.0, pelvis_pos)
        frames[f"idle_{k+1}"] = canvas
    
    # run 4 帧
    run_rots = {
        "warrior": {"pelvis":0,"torso":4,"head":0,"arm_l":-30,"arm_r":30,"leg_l":-35,"leg_r":35},
        "mage":    {"pelvis":0,"torso":4,"head":0,"arm_l":-25,"arm_r":25,"leg_l":-30,"leg_r":30},
        "archer":  {"pelvis":0,"torso":4,"head":0,"arm_l":-28,"arm_r":28,"leg_l":-32,"leg_r":32},
    }[cls]
    for k in range(4):
        phase = math.sin(2*math.pi * k/4)
        rots = {n: v*(0.8+phase*0.4) for n,v in run_rots.items()}
        rots["pelvis"] = phase*2.0
        canvas = render_one(mesh, rots, 1.0, pelvis_pos)
        frames[f"run_{k+1}"] = canvas
    
    # attack
    atk = ATTACK_POSES.get(cls, ATTACK_POSES["warrior"])
    for k, (t, _) in enumerate(atk):
        rots = interp(atk, t)
        canvas = render_one(mesh, rots, 1.0, pelvis_pos)
        frames[f"attack_{k+1}"] = canvas
    
    # 保存帧
    cls_dir = f"{OUT}/{cls}"
    os.makedirs(cls_dir, exist_ok=True)
    for fname, frame in frames.items():
        frame.convert("RGB").save(f"{cls_dir}/{fname}.jpg", "JPEG", quality=92)
    
    # Contact sheet
    cats = [
        ("idle", [f"idle_{i}" for i in range(1,5)]),
        ("run",  [f"run_{i}" for i in range(1,5)]),
        ("attack", [f"attack_{i}" for i in range(1, len(atk)+1)]),
    ]
    COLS = 5; TW, TH = 180, 200; LH = 24; MAR = 8
    rows = len(cats)
    sw = MAR*2 + COLS*(TW+6)
    sh = MAR + 28 + MAR + rows*(LH+TH+MAR)
    sheet = Image.new("RGB", (sw, sh), (16, 22, 34))
    d = ImageDraw.Draw(sheet)
    cn = {"warrior":"战士","mage":"法师","archer":"弓箭手"}.get(cls,cls)
    d.text((MAR+8, MAR+6), f"{cls} / {cn} — 完整肖像 + 自动权重蒙皮", fill=(200,220,250))
    
    y0 = MAR+28+MAR
    for ri, (cat, fnames) in enumerate(cats):
        y = y0 + ri*(LH+TH+MAR)
        d.rectangle([MAR, y, sw-MAR, y+LH], fill=(24,30,44))
        d.text((MAR+8, y+4), cat, fill=(220,235,250))
        for ci in range(COLS):
            x = MAR + ci*(TW+6)
            fi = fnames[ci] if ci < len(fnames) else None
            d.rectangle([x, y+LH, x+TW, y+LH+TH], outline=(60,75,95), width=1)
            if fi and fi in frames:
                f = frames[fi].resize((TW, TH), Image.BILINEAR)
                sheet.paste(f, (x, y+LH))
    sheet.save(f"{OUT}/{cls}_sheet.jpg", "JPEG", quality=92)
    all_sheets[cls] = sheet
    print(f"  → {cls}_sheet.jpg")

# 总览
COLS2=2; ROWS2=2; TW2,TH2=280,320; MAR2=20
sw2=COLS2*TW2+(COLS2+1)*MAR2
sh2=ROWS2*TH2+(ROWS2+1)*MAR2+60
ov = Image.new("RGB",(sw2,sh2),(12,16,26))
d = ImageDraw.Draw(ov)
d.text((MAR2,20),"v4 完整肖像绑定 — 自动权重蒙皮",fill=(220,235,255))
d.text((MAR2,40),"不切图 | 28×28 网格 | 高斯权重 | 骨骼驱动",fill=(140,160,190))
for idx, cls in enumerate(CLASS_LIST):
    r,c = divmod(idx, COLS2)
    sx = MAR2 + c*(TW2+MAR2)
    sy = 60+MAR2+r*(TH2+MAR2)
    s = all_sheets[cls]
    crop = s.crop((8, 28+8, min(s.size[0], 8+TW2), 28+8+TH2)).resize((TW2,TH2), Image.BILINEAR)
    ov.paste(crop, (sx, sy))
    d.rectangle([sx,sy,sx+TW2,sy+TH2], outline=(70,100,140))
ov.save(f"{OUT}/overview_whole_bind.jpg","JPEG",quality=92)
print(f"\noverview_whole_bind.jpg: {sw2}×{sh2}")
print(f"\n完成! 输出: {OUT}/")
