# ============================================================
# RiggedCharacter v2 — 高度定制化的骨骼驱动实体
#
# 三层架构:
#   L1 骨架 (Skeleton)  — JSON 定义关节树, 可选 humanoid_7 / slime_3 / spider_9 / wraith_5 / giant_7 / giant_skeleton_5
#   L2 本体 (Body)      — 程序化 mesh (胶囊/椭圆/圆角矩形), 由骨架类型决定形状
#   L3 装备 (Equipment) — 可替换的武器/胸甲/头盔/披风, JSON 定义 mesh
#
# 组装方式:
#   var rig = RiggedCharacter.new()
#   rig.load_preset("warrior")      # 从 class_presets.json 读取
#   rig.set_weapon("staff_fire")    # 切换武器
#   rig.set_helmet("pointed_hat")   # 换头盔
#   rig.set_body("slime_mini", "slime")  # 换成史莱姆骨架
#
# 所有 mesh 都是 Polygon2D 挂在对应关节 Bone2D 上
# ============================================================

extends Node2D
class_name RiggedCharacter

signal pose_finished_emitted(pose_name: String)

# —— 骨架定义（运行时缓存）——
var _skeleton: Dictionary = {}       # name -> {parent, anchor, rest_rot, layer, scale}
var _bone_nodes: Dictionary = {}      # name -> Node2D (实际关节节点)
var _skeleton_type: String = ""

# —— 本体层（挂关节上的 Polygon2D）——
var body_meshes: Dictionary = {}      # bone_name -> Polygon2D
var body_tint: Color = Color.WHITE
var body_height_scale: float = 1.0

# —— 装备层（按槽位挂装备 Polygon2D）——
var equipment: Dictionary = {}        # slot_name -> {mesh: Polygon2D, bone: String, anchor: Vector2}

# —— 姿势驱动（和之前一致）——
var current_pose: String = "idle"
var pose_mode: String = "loop"
var pose_time: float = 0.0
var pose_duration: float = 1.0
var bob_amount: float = 0.0
var facing: Vector2 = Vector2.RIGHT

# —— 数据源——
var _data_skeletons: Dictionary = {}
var _data_equipment: Dictionary = {}

func _ready() -> void:
	_load_json_data()

func _load_json_data() -> void:
	var skel_path := "res://data/skeletons.json"
	var eq_path   := "res://data/equipment.json"
	var presets_path := "res://data/class_presets.json"
	var file_skel := FileAccess.open(skel_path, FileAccess.READ)
	if file_skel:
		var content: String = file_skel.get_as_text()
		file_skel.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			_data_skeletons = (parsed as Dictionary).get("skeletons", {})
	var file_eq := FileAccess.open(eq_path, FileAccess.READ)
	if file_eq:
		var content: String = file_eq.get_as_text()
		file_eq.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			_data_equipment = parsed
	# 给一个默认骨架（即使 JSON 加载失败）
	if _data_skeletons.is_empty():
		_data_skeletons = _default_skeletons()
	if _data_equipment.is_empty():
		_data_equipment = _default_equipment()

func _default_skeletons() -> Dictionary:
	return {
		"humanoid_7": {
			"height_px": 48,
			"bones": [
				{"name":"pelvis","parent":-1,"anchor":[0,0],"rot":0,"layer":0},
				{"name":"torso","parent":0,"anchor":[0,-16],"rot":0,"layer":1},
				{"name":"head","parent":1,"anchor":[0,-14],"rot":0,"layer":2},
				{"name":"arm_l","parent":1,"anchor":[-10,-4],"rot":0,"layer":3},
				{"name":"arm_r","parent":1,"anchor":[10,-4],"rot":0,"layer":3},
				{"name":"leg_l","parent":0,"anchor":[-5,0],"rot":0,"layer":0},
				{"name":"leg_r","parent":0,"anchor":[5,0],"rot":0,"layer":0},
			]
		}
	}

func _default_equipment() -> Dictionary:
	return {}

# ==================== 组装骨架 ====================

func setup(skeleton_type: String = "humanoid_7", height_scale: float = 1.0, tint: Color = Color.WHITE) -> void:
	# 清空旧节点
	for c in get_children():
		c.queue_free()
	_skeleton.clear()
	_bone_nodes.clear()
	body_meshes.clear()
	equipment.clear()

	_skeleton_type = skeleton_type
	body_height_scale = height_scale
	body_tint = tint
	_build_skeleton_nodes(skeleton_type)
	_build_body_meshes(skeleton_type)
	_build_shadow()

func _build_skeleton_nodes(skel_name: String) -> void:
	var def: Dictionary = _data_skeletons.get(skel_name, _data_skeletons.get("humanoid_7", {}))
	var bones: Array = def.get("bones", [])
	for bdef in bones:
		var bname: String = bdef.get("name", "")
		var bone := Node2D.new()
		bone.name = "Bone_" + bname
		var parent_idx: int = int(bdef.get("parent", -1))
		var anchor: Array = bdef.get("anchor", [0,0])
		var scale: float = float(bdef.get("scale", 1.0)) * body_height_scale
		var parent_node: Node2D = self
		if parent_idx >= 0 and parent_idx < bones.size():
			var pname: String = bones[parent_idx].get("name", "")
			if _bone_nodes.has(pname):
				parent_node = _bone_nodes[pname]
		parent_node.add_child(bone)
		bone.position = Vector2(anchor[0], anchor[1]) * scale
		_skeleton[bname] = {
			"parent": parent_idx,
			"anchor": Vector2(anchor[0], anchor[1]) * scale,
			"rot": float(bdef.get("rot", 0)),
			"layer": int(bdef.get("layer", 0)),
			"scale": scale,
		}
		_bone_nodes[bname] = bone

func _build_body_meshes(skel_name: String) -> void:
	# 程序化 mesh — 每种骨架类型有不同的身体
	match skel_name:
		"humanoid_7", "giant_7", "giant_skeleton_5":
			_build_humanoid_body(body_tint)
		"slime_3":
			_build_slime_body(body_tint)
		"spider_9":
			_build_spider_body(body_tint)
		"wraith_5":
			_build_wraith_body(body_tint)

func _build_humanoid_body(tint: Color) -> void:
	# torso 胶囊
	_attach_mesh("torso", _capsule_pts(12, 20), tint)
	_attach_mesh("head", _circle_pts(9), tint.darkened(0.1))
	_attach_mesh("arm_l", _ellipse_pts(4, 10), tint)
	_attach_mesh("arm_r", _ellipse_pts(4, 10), tint)
	_attach_mesh("leg_l", _ellipse_pts(4.5, 12), tint.darkened(0.08))
	_attach_mesh("leg_r", _ellipse_pts(4.5, 12), tint.darkened(0.08))

func _build_slime_body(tint: Color) -> void:
	_attach_mesh("core", _ellipse_pts(14, 10), tint)
	_attach_mesh("bounce_top", _ellipse_pts(10, 6), tint.lightened(0.1))
	_attach_mesh("bounce_bot", _ellipse_pts(12, 4), tint.darkened(0.15))

func _build_spider_body(tint: Color) -> void:
	_attach_mesh("body", _ellipse_pts(10, 6), tint)
	_attach_mesh("head", _circle_pts(4), tint.darkened(0.1))
	for leg_name in ["leg_fl","leg_fr","leg_ml","leg_mr","leg_rl","leg_rr"]:
		_attach_mesh(leg_name, _ellipse_pts(1.5, 8), tint.darkened(0.2))
	_attach_mesh("tail", _ellipse_pts(2, 4), tint)

func _build_wraith_body(tint: Color) -> void:
	_attach_mesh("core", _ellipse_pts(10, 16), tint)
	_attach_mesh("head", _circle_pts(7), tint.lightened(0.15))
	_attach_mesh("tendril_l", _ellipse_pts(2, 10), tint.darkened(0.15))
	_attach_mesh("tendril_r", _ellipse_pts(2, 10), tint.darkened(0.15))
	_attach_mesh("tail", _ellipse_pts(3, 12), tint.darkened(0.2))

func _attach_mesh(bone_name: String, verts: PackedVector2Array, tint: Color) -> void:
	if not _bone_nodes.has(bone_name):
		return
	var mesh := Polygon2D.new()
	mesh.name = "Body_" + bone_name
	mesh.polygon = verts
	mesh.color = tint
	_bone_nodes[bone_name].add_child(mesh)
	body_meshes[bone_name] = mesh

func _build_shadow() -> void:
	# 挂在 root bone
	var root_name: String = "pelvis" if _bone_nodes.has("pelvis") else "core" if _bone_nodes.has("core") else "body" if _bone_nodes.has("body") else ""
	if root_name == "":
		return
	var shadow := ColorRect.new()
	shadow.name = "Shadow"
	shadow.color = Color(0, 0, 0, 0.28)
	shadow.size = Vector2(40, 7)
	shadow.position = Vector2(-20, 22)
	_bone_nodes[root_name].add_child(shadow)

# ==================== 装备系统 ====================

func equip(slot: String, item_id: String) -> void:
	"""挂装备 — slot 可以是 right_hand/left_hand/torso/head/back/feet"""
	# 先清旧装备
	unequip(slot)

	# 从 JSON 查找装备数据
	var eq_def: Dictionary = _find_equipment(item_id)
	if eq_def.is_empty():
		push_warning("RiggedCharacter: 找不到装备 " + item_id)
		return

	var parent_bone: String = eq_def.get("parent_bone", "arm_r")
	if not _bone_nodes.has(parent_bone):
		push_warning("RiggedCharacter: 骨架里没有关节 " + parent_bone)
		return

	var anchor_arr: Array = eq_def.get("anchor", [0,0])
	var rest_rot: float = float(eq_def.get("rest_rot", 0))
	var color_arr: Array = eq_def.get("color", [1,1,1])
	var color := Color(color_arr[0], color_arr[1], color_arr[2])
	var verts_arr: Array = eq_def.get("verts", [])
	var verts := PackedVector2Array()
	for i in range(0, verts_arr.size()-1, 2):
		verts.append(Vector2(float(verts_arr[i]), float(verts_arr[i+1])))

	# 创建节点
	var equip_node := Node2D.new()
	equip_node.name = "Eq_" + slot + "_" + item_id
	equip_node.position = Vector2(float(anchor_arr[0]), float(anchor_arr[1]))
	equip_node.rotation_degrees = rest_rot
	_bone_nodes[parent_bone].add_child(equip_node)

	var mesh := Polygon2D.new()
	mesh.name = item_id
	mesh.polygon = verts
	mesh.color = color
	equip_node.add_child(mesh)

	equipment[slot] = {
		"node": equip_node,
		"mesh": mesh,
		"bone": parent_bone,
		"item_id": item_id,
	}

func unequip(slot: String) -> void:
	if not equipment.has(slot):
		return
	var rec: Dictionary = equipment[slot]
	if rec.has("node") and is_instance_valid(rec["node"]):
		rec["node"].queue_free()
	equipment.erase(slot)

func set_weapon(item_id: String) -> void:
	equip("right_hand", item_id)

func set_torso_armor(item_id: String) -> void:
	equip("torso", item_id)

func set_helmet(item_id: String) -> void:
	equip("head", item_id)

func set_cape(item_id: String) -> void:
	equip("back", item_id)

func _find_equipment(item_id: String) -> Dictionary:
	for category in _data_equipment.keys():
		var cat: Dictionary = _data_equipment[category]
		if cat.has(item_id):
			return cat[item_id]
	return {}

# ==================== Preset ====================

func load_preset(preset_id: String) -> void:
	var path := "res://data/class_presets.json"
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	var presets: Dictionary = (parsed as Dictionary).get("presets", {}) if parsed is Dictionary else {}
	if not presets.has(preset_id):
		return
	var p: Dictionary = presets[preset_id]
	var skel: String = str(p.get("skeleton", "humanoid_7"))
	var scale: float = float(p.get("height_scale", 1.0))
	var tint_arr: Array = p.get("body_tint", [0.88, 0.42, 0.32])
	var tint := Color(float(tint_arr[0]), float(tint_arr[1]), float(tint_arr[2]))
	setup(skel, scale, tint)
	# 挂装备
	var eqs: Dictionary = p.get("equipment", {})
	for slot in eqs.keys():
		equip(str(slot), str(eqs[slot]))

# ==================== 姿势驱动 ====================

func _process(delta: float) -> void:
	if pose_mode == "loop":
		pose_time += delta
		_apply_loop_pose(pose_time)
	else:
		pose_time = minf(pose_duration, pose_time + delta)
		_apply_timeline_pose(pose_time / pose_duration)
		if pose_time >= pose_duration:
			_on_pose_timeline_complete()

func set_pose(name: String) -> void:
	current_pose = name
	pose_time = 0.0
	if PoseDefs.IS_LOOP_POSE(name):
		pose_mode = "loop"
		var d: Dictionary = PoseDefs.LOOP_POSES().get(name, {})
		bob_amount = float(d.get("bob", 0.0))
	else:
		pose_mode = "timeline"
		var d: Dictionary = PoseDefs.TIMELINE_POSES().get(name, {})
		pose_duration = float(d.get("duration", 0.3))
		bob_amount = 0.0

func set_facing(dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	facing = dir.normalized()
	var root_name := "pelvis" if _bone_nodes.has("pelvis") else "core" if _bone_nodes.has("core") else "body" if _bone_nodes.has("body") else ""
	if root_name != "" and _bone_nodes.has(root_name):
		_bone_nodes[root_name].scale.x = -1.0 if facing.x < -0.05 else 1.0

func _on_pose_timeline_complete() -> void:
	pose_finished_emitted.emit(current_pose)

func _apply_loop_pose(t: float) -> void:
	var d: Dictionary = PoseDefs.LOOP_POSES().get(current_pose, PoseDefs.LOOP_POSES().get("idle"))
	if d.is_empty():
		return
	var phase: float = sin(t * float(d.get("frequency", 1.2)) * TAU)
	var bob: float = float(d.get("bob", 0.0)) * phase
	var rots: Array = d.get("rotations", [])
	var swings: Array = d.get("swing", [])
	# 先统一重置所有关节 rot 到 0
	for bname in _skeleton.keys():
		if _bone_nodes.has(bname):
			_bone_nodes[bname].rotation_degrees = 0
	# 按 PoseDefs 的 bone 索引应用 (假设 humanoid_7 有 7 个关键 bone)
	var key_bones: Array = ["pelvis", "torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]
	var bone_names: Array = _skeleton.keys()
	for i in range(min(rots.size(), bone_names.size())):
		var bname: String = bone_names[i]
		if not _bone_nodes.has(bname):
			continue
		var swing_v: float = float(swings[i]) if i < swings.size() else 0.0
		var base_rot: float = float(rots[i]) if i < rots.size() else 0.0
		var rot: float = base_rot + swing_v * phase * 30.0
		_bone_nodes[bname].rotation_degrees = rot
	# bob
	if _bone_nodes.has("pelvis"):
		_bone_nodes["pelvis"].position.y = bob * 0.5

func _apply_timeline_pose(progress: float) -> void:
	var d: Dictionary = PoseDefs.TIMELINE_POSES().get(current_pose, {})
	if d.is_empty():
		return
	var kfs: Array = d.get("keyframes", [])
	if kfs.size() == 0:
		return
	# 找到包围的关键帧
	var ka: Array = kfs[0]
	var kb: Array = kfs[kfs.size()-1]
	for i in range(kfs.size()-1):
		var ta: float = float(kfs[i][0])
		var tb: float = float(kfs[i+1][0])
		if progress >= ta and progress <= tb:
			ka = kfs[i]
			kb = kfs[i+1]
			break
	if ka == kb:
		_apply_rot_array(ka[1])
		return
	var tr: float = (progress - float(ka[0])) / maxf(0.001, float(kb[0]) - float(ka[0]))
	tr = 1.0 - pow(1.0 - tr, 2.5)
	var rots_a: Array = ka[1]
	var rots_b: Array = kb[1]
	var rots_interp: Array = []
	for i in range(max(rots_a.size(), rots_b.size())):
		var ra: float = float(rots_a[i]) if i < rots_a.size() else 0.0
		var rb: float = float(rots_b[i]) if i < rots_b.size() else 0.0
		rots_interp.append(lerp(ra, rb, tr))
	_apply_rot_array(rots_interp)
	# bob
	var bob_a: float = float(ka[3]) if ka.size() > 3 else 0.0
	var bob_b: float = float(kb[3]) if kb.size() > 3 else bob_a
	var bob: float = lerp(bob_a, bob_b, tr)
	if _bone_nodes.has("pelvis"):
		_bone_nodes["pelvis"].position.y = bob * 0.5

func _apply_rot_array(rots: Array) -> void:
	var bone_names: Array = _skeleton.keys()
	for i in range(min(rots.size(), bone_names.size())):
		var bname: String = bone_names[i]
		if _bone_nodes.has(bname):
			_bone_nodes[bname].rotation_degrees = float(rots[i])

# ==================== 几何工具 ====================

static func _circle_pts(r: float, segs: int = 18) -> PackedVector2Array:
	var v := PackedVector2Array()
	for i in range(segs):
		var a: float = float(i) / segs * TAU
		v.append(Vector2(cos(a)*r, sin(a)*r))
	return v

static func _ellipse_pts(rx: float, ry: float, segs: int = 20) -> PackedVector2Array:
	var v := PackedVector2Array()
	for i in range(segs):
		var a: float = float(i) / segs * TAU
		v.append(Vector2(cos(a)*rx, sin(a)*ry))
	return v

static func _capsule_pts(w: float, h: float) -> PackedVector2Array:
	var v := PackedVector2Array()
	var segs := 10
	var hw := w * 0.5
	var hh := h * 0.5
	for i in range(segs + 1):
		var a: float = PI * 0.5 - (float(i)/segs) * PI
		v.append(Vector2(hw + cos(a)*hw*0.3, -hh + sin(a)*hh))
	for i in range(segs + 1):
		var a: float = -PI * 0.5 - (float(i)/segs) * PI
		v.append(Vector2(hw + cos(a)*hw*0.3, -hh + sin(a)*hh))
	v.append(Vector2(-hw, hh))
	v.append(Vector2(-hw, -hh))
	return v
