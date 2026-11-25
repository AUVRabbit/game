# ============================================================
# RiggedCharacter — 骨骼驱动的实体角色
#
# 挂在 EntityBase.Visual 下，负责:
#   1. 构建 7 关节骨架（Pelvis→Torso→Head/ArmL/ArmR + LegL/LegR）
#   2. 按 entity_type/profession 程序化生成 Polygon2D 皮肤
#   3. 驱动姿势（循环姿势 sin 摆动、一次性姿势 timeline 插值）
#   4. 面向翻转（facing.x < 0 时全部关节 X 轴镜像）
#
# 使用:
#   var rig = RiggedCharacter.new()
#   rig.name = "Rigged"
#   rig.setup("player_warrior", "warrior", "physical")
#   visual.add_child(rig)
#   rig.set_pose("idle")
#   rig.set_facing(Vector2.RIGHT)
#
# 数据层见 pose_defs.gd（所有姿势的关节时间曲线）
# 皮肤构建见 rig_builders.gd（各职业/敌人类型的身体造型）
# ============================================================

extends Node2D
class_name RiggedCharacter

# —— 关节节点（Node2D，控制 rotation + offset）——
var pelvis: Node2D = null
var torso: Node2D = null
var head: Node2D = null
var arm_l: Node2D = null
var arm_r: Node2D = null
var leg_l: Node2D = null
var leg_r: Node2D = null

# —— 皮肤节点（挂在对应关节下的 Polygon2D/ColorRect）——
var skins: Dictionary = {}  # "torso" -> Polygon2D, "head" -> Polygon2D, ...
var weapon_node: Node2D = null
var weapon_mesh: Polygon2D = null
var shadow: ColorRect = null

# —— 当前姿势状态 ——
var current_pose: String = "idle"
var pose_mode: String = "loop"       # "loop" | "timeline"
var pose_time: float = 0.0           # 当前姿势已运行时间
var pose_duration: float = 1.0       # timeline 姿势总时长
var pose_frequency: float = 1.2      # loop 姿势频率
var bob_amount: float = 0.0          # loop 姿势上下浮动
var facing: Vector2 = Vector2.DOWN
var base_color: Color = Color.WHITE
var tint_overlay: Color = Color(1, 1, 1, 0)  # 受击/状态 tint
var flash_time: float = 0.0

# —— entity meta ——
var entity_id: String = "player_warrior"
var entity_type: String = "warrior"
var element: String = "physical"
var is_boss: bool = false

# —— 姿势过渡 ——
var prev_pose: String = ""
var transition_from: String = ""
var transition_t: float = 1.0       # 1.0 = 已完成

func setup(entity_id_: String, entity_type_: String, element_: String = "physical",
           is_boss_: bool = false, color: Color = Color.WHITE) -> void:
	entity_id = entity_id_
	entity_type = entity_type_
	element = element_
	is_boss = is_boss_
	base_color = color
	_build_skeleton()
	_build_skin()
	_build_weapon()
	_build_shadow()
	_build_decorations()
	set_pose("idle")

# ==================== 构建骨架 ====================

func _build_skeleton() -> void:
	pelvis = Node2D.new(); pelvis.name = "Pelvis"; add_child(pelvis)
	torso  = Node2D.new(); torso.name = "Torso"; pelvis.add_child(torso)
	head   = Node2D.new(); head.name = "Head"; torso.add_child(head)
	arm_l  = Node2D.new(); arm_l.name = "ArmL"; torso.add_child(arm_l)
	arm_r  = Node2D.new(); arm_r.name = "ArmR"; torso.add_child(arm_r)
	leg_l  = Node2D.new(); leg_l.name = "LegL"; pelvis.add_child(leg_l)
	leg_r  = Node2D.new(); leg_r.name = "LegR"; pelvis.add_child(leg_r)
	# 隐藏骨架节点自身（我们只关心它们的变换，皮肤是单独的 Polygon2D）
	# 但让它们 visible 方便调试 —— 实际皮肤是挂在同一层级的

func _joint(i: int) -> Node2D:
	match i:
		0: return pelvis
		1: return torso
		2: return head
		3: return arm_l
		4: return arm_r
		5: return leg_l
		6: return leg_r
	return pelvis

# ==================== 构建皮肤 ====================

func _build_skin() -> void:
	var b := RigBuilders.new()
	var out: Dictionary = b.build(entity_type, element, base_color, is_boss)
	for key in ["torso", "head", "arm_l", "arm_r", "leg_l", "leg_r"]:
		var verts: PackedVector2Array = out.get(key, PackedVector2Array())
		if verts.size() == 0:
			continue
		var mesh := Polygon2D.new()
		mesh.name = "Skin_%s" % key
		mesh.polygon = verts
		var c: Color = out.get("colors", {}).get(key, base_color)
		mesh.color = c
		var j: Node2D = _joint(_joint_index(key))
		j.add_child(mesh)
		skins[key] = mesh

func _joint_index(key: String) -> int:
	return {
		"pelvis": 0, "torso": 1, "head": 2,
		"arm_l": 3, "arm_r": 4, "leg_l": 5, "leg_r": 6,
	}.get(key, 1)

func _build_weapon() -> void:
	var b := RigBuilders.new()
	var wdata: Dictionary = b.weapon_for(entity_type)
	if wdata.is_empty():
		return
	weapon_node = Node2D.new()
	weapon_node.name = "Weapon"
	arm_r.add_child(weapon_node)
	weapon_mesh = Polygon2D.new()
	weapon_mesh.name = "WeaponMesh"
	weapon_mesh.polygon = wdata.get("verts", PackedVector2Array())
	weapon_mesh.color = wdata.get("color", Color(0.85, 0.85, 0.9))
	weapon_mesh.position = wdata.get("anchor", Vector2(12, -2))
	weapon_mesh.rotation = wdata.get("rotation", 0.0)
	weapon_node.add_child(weapon_mesh)

func _build_shadow() -> void:
	shadow = ColorRect.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.0, 0.0, 0.0, 0.28)
	shadow.size = Vector2(32, 6)
	shadow.position = Vector2(-16, 20)
	pelvis.add_child(shadow)

func _build_decorations() -> void:
	var b := RigBuilders.new()
	var decos: Array = b.decorations_for(entity_type)
	for deco in decos:
		var mesh := Polygon2D.new()
		mesh.name = deco.get("name", "Deco")
		mesh.polygon = deco.get("verts", PackedVector2Array())
		mesh.color = deco.get("color", Color.WHITE)
		mesh.position = deco.get("position", Vector2.ZERO)
		mesh.rotation = deco.get("rotation", 0.0)
		var parent_key: String = deco.get("parent", "torso")
		var j: Node2D = _joint(_joint_index(parent_key))
		j.add_child(mesh)

# ==================== 姿势驱动 ====================

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time = maxf(0.0, flash_time - delta)
	# 过渡
	if transition_t < 1.0:
		transition_t = minf(1.0, transition_t + delta * 4.0)
	# 当前姿势推进时间
	if pose_mode == "loop":
		pose_time += delta
		_apply_loop_pose(pose_time)
	else:
		pose_time = minf(pose_duration, pose_time + delta)
		_apply_timeline_pose(pose_time / pose_duration)
		if pose_time >= pose_duration:
			pose_finished()
	# shadow 随身体上下浮动
	if shadow and bob_amount > 0.0 and pose_mode == "loop":
		shadow.position.y = 20 + bob_amount * 0.5 * sin(pose_time * pose_frequency * TAU)

func pose_finished() -> void:
	# 子类可以 override —— 默认回到 idle（除非是一次性姿势要 loop）
	if current_pose in ["hurt", "roll", "jump", "dash", "sword_swing", "bow_draw", "cast",
						"throw_bomb", "summon_ritual", "cast_focus", "block", "dead", "crouch"]:
		# 回到 idle
		set_pose("idle")

func set_pose(name: String) -> void:
	prev_pose = current_pose
	current_pose = name
	pose_time = 0.0
	transition_from = prev_pose
	transition_t = 0.0
	# 先设置初始 offset（来自 loops/timeline）
	if PoseDefs.IS_LOOP_POSE(name):
		pose_mode = "loop"
		var data: Dictionary = PoseDefs.LOOP_POSES().get(name, {})
		pose_frequency = float(data.get("frequency", 1.2))
		bob_amount = float(data.get("bob", 0.0))
	elif PoseDefs.IS_TIMELINE_POSE(name):
		pose_mode = "timeline"
		var data: Dictionary = PoseDefs.TIMELINE_POSES().get(name, {})
		pose_duration = float(data.get("duration", 0.3))
		bob_amount = 0.0
	else:
		pose_mode = "loop"
		bob_amount = 0.0

func set_facing(dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	facing = dir.normalized()
	var flip_x: float = -1.0 if facing.x < -0.05 else 1.0
	pelvis.scale.x = flip_x

# ==================== Loop 姿势应用 ====================

func _apply_loop_pose(t: float) -> void:
	var data: Dictionary = PoseDefs.LOOP_POSES().get(current_pose, PoseDefs.LOOP_POSES().get("idle"))
	var base_rots: Array = data.get("rotations", [0, 0, 0, 0, 0, 0, 0])
	var swings: Array = data.get("swing", [0, 0, 0, 0, 0, 0, 0])
	var offsets: Array = data.get("offsets", [])
	var freq: float = float(data.get("frequency", 1.2))
	var bob: float = float(data.get("bob", 0.0))
	var phase: float = sin(t * freq * TAU)
	# 身体整体 bob
	pelvis.position.y = bob * phase
	for i in range(7):
		var j: Node2D = _joint(i)
		if j == null:
			continue
		var swing_v: float = float(swings[i]) if i < swings.size() else 0.0
		var base_rot: float = float(base_rots[i]) if i < base_rots.size() else 0.0
		var rot: float = base_rot + swing_v * phase * 30.0
		j.rotation_degrees = rot
		if offsets.size() > i:
			j.position = offsets[i]

# ==================== Timeline 姿势应用 ====================

func _apply_timeline_pose(progress: float) -> void:
	var data: Dictionary = PoseDefs.TIMELINE_POSES().get(current_pose, {})
	var kfs: Array = data.get("keyframes", [])
	if kfs.size() == 0:
		return
	# 找两个包围 progress 的关键帧
	var kf_a = kfs[0]
	var kf_b = kfs[kfs.size() - 1]
	for i in range(kfs.size() - 1):
		var t_a: float = float(kfs[i][0])
		var t_b: float = float(kfs[i + 1][0])
		if progress >= t_a and progress <= t_b:
			kf_a = kfs[i]
			kf_b = kfs[i + 1]
			break
	var local_t: float = 1.0 if kf_a == kf_b else clampf((progress - float(kf_a[0])) / (float(kf_b[0]) - float(kf_a[0])), 0.0, 1.0)
	local_t = _ease_out(local_t)

	# 插值 rotation + offsets
	var rots_a: Array = kf_a[1]
	var rots_b: Array = kf_b[1]
	var offs_a: Array = kf_a[2]
	var offs_b: Array = kf_b[2]
	var bob_a: float = float(kf_a[3])
	var bob_b: float = float(kf_b[3])
	var bob_t = lerp(bob_a, bob_b, local_t)
	pelvis.position.y = bob_t
	for i in range(7):
		var j: Node2D = _joint(i)
		if j == null:
			continue
		var ra: float = float(rots_a[i]) if i < rots_a.size() else 0.0
		var rb: float = float(rots_b[i]) if i < rots_b.size() else 0.0
		j.rotation_degrees = lerp(ra, rb, local_t)
		var oa: Vector2 = offs_a[i] if i < offs_a.size() else Vector2.ZERO
		var ob: Vector2 = offs_b[i] if i < offs_b.size() else Vector2.ZERO
		j.position = oa.lerp(ob, local_t)

func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 2.5)

# ==================== Flash / Tint ====================

func flash(col: Color, dur: float = 0.15) -> void:
	flash_time = dur
	tint_overlay = col
	# 闪白所有皮肤
	for key in skins.keys():
		var mesh: Polygon2D = skins[key]
		_original_colors[key] = mesh.color
		mesh.color = col
	if weapon_mesh:
		weapon_mesh.color = col

var _original_colors: Dictionary = {}

func _apply_flash_fade(delta: float) -> void:
	if flash_time <= 0.0:
		return
	var fade_speed: float = flash_time  # 刚好在 flash_time 内恢复
	flash_time = maxf(0.0, flash_time - delta)
	if flash_time <= 0.0:
		# 恢复原色
		for key in skins.keys():
			if _original_colors.has(key):
				skins[key].color = _original_colors[key]
				_original_colors.erase(key)
		if weapon_mesh and _original_colors.has("weapon"):
			weapon_mesh.color = _original_colors["weapon"]

# ==================== 工具 ====================

func set_body_color(c: Color) -> void:
	base_color = c
	for key in skins.keys():
		var mesh: Polygon2D = skins[key]
		# 只影响 base 颜色，不覆盖 flash
		if flash_time <= 0.0:
			var tint: Color = mesh.color
			mesh.color = Color(
				c.r * 0.75 + 0.25 * tint.r,
				c.g * 0.75 + 0.25 * tint.g,
				c.b * 0.75 + 0.25 * tint.b,
				tint.a
			)

func total_height() -> float:
	# 从 pelvis 脚底到头顶的像素高度
	return 40.0 if is_boss else 32.0
