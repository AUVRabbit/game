# ============================================================
# EntityBase — 角色/敌人/召唤物 共享基类
# 继承自 CharacterBody2D，提供完整的"完整个体"基础设施：
#   • 碰撞体（CollisionShape2D）
#   • 视觉层（Visual/Node2D + z_sort）
#   • 双轨动画（AnimatedSprite2D 帧切换 + SpriteAnim 程序化形变）
#   • 血条实体节点（HPBar/ColorRect，不再走 _draw）
#   • HP / 状态效果（stun/slow/mark/knockback）
#   • 受击反馈链（DamageNumber + Flash + 击退 + 粒子 + HitStop + 震屏）
#   • 元素克制与状态免疫
# 子类: PlayerController / EnemyBase / SummonedMinion
# ============================================================

extends CharacterBody2D
class_name EntityBase

signal hp_changed(current: int, maximum: int)
signal entity_died

# —— 通用属性 ——
@export var entity_name: String = "实体"
@export var max_hp: int = 100
@export var hp: int = 100
@export var body_color: Color = Color.WHITE
@export var body_radius: float = 16.0
@export var is_boss: bool = false

# —— 元素系统（默认 physical）——
@export var primary_element: String = "physical"
@export var status_immune: Array = []

# —— 视觉资源 ——
@export var sheet_id: String = ""        # 如 "player_warrior" / "enemy_slime" / "minion_fire"
@export var frame_w: int = 128
@export var frame_h: int = 128

# —— 状态效果（通用）——
var stun_left: float = 0.0
var slow_left: float = 0.0
var slow_factor: float = 1.0
var mark_left: float = 0.0
var mark_amp: float = 0.0
var flash_timer: float = 0.0

# —— 动画层（统一挂载到 Visual 下）——
var visual: Node2D = null
var frame_anim: AnimatedSprite2D = null
var sprite_anim: SpriteAnim = null
var rigged: RiggedCharacter = null       # 骨骼驱动的实体角色（主角）
var last_attacker: Node = null

# —— 子类可选参数：给 RiggedCharacter 初始化用 ——
@export var rig_entity_id: String = ""   # 如 "player_warrior" / "enemy_slime"
@export var rig_entity_type: String = "" # 如 "warrior" / "slime" / "minion_fire"

# —— 血条节点（实体化，不再 _draw）——
var hp_bar_bg: ColorRect = null
var hp_bar_fg: ColorRect = null
var hp_bar_label: Label = null

func _ready() -> void:
	# 确保在 entities 组
	add_to_group("entities")
	hp = maxi(0, mini(hp, max_hp))
	_build_visual_layers()
	_build_hp_bar()

# ==================== 视觉层 ====================

func _build_visual_layers() -> void:
	# 约定：Visual 是 Node2D 容器，子类 scene 可以预放；没有就动态创建
	visual = get_node_or_null("Visual")
	if visual == null:
		visual = Node2D.new()
		visual.name = "Visual"
		add_child(visual)

	# —— RiggedCharacter（骨骼驱动的实体角色，第一优先级）——
	rigged = get_node_or_null("Visual/Rigged")
	if rigged == null:
		rigged = RiggedCharacter.new()
		rigged.name = "Rigged"
		# 自动推断 entity_id / entity_type（子类可以提前 set rig_entity_id / rig_entity_type）
		var eid: String = rig_entity_id
		var etype: String = rig_entity_type
		if eid == "":
			if sheet_id != "":
				eid = sheet_id
			else:
				eid = "entity_%d" % randi()
		if etype == "":
			etype = _guess_entity_type(eid)
		# RiggedCharacter v2 — 优先尝试 load preset
		rigged.load_preset(etype)
		# 如果 preset 不存在 (骨架类型还是空), 用基础 humanoid 骨架
		if rigged._skeleton.is_empty():
			rigged.setup("humanoid_7", 1.0, body_color)
		visual.add_child(rigged)

	# AnimatedSprite2D 帧动画层（可选，保留作为后备）
	frame_anim = get_node_or_null("Visual/FrameAnim")
	if frame_anim == null and sheet_id != "":
		_attach_frame_anim(sheet_id, frame_w, frame_h)
	if frame_anim:
		frame_anim.visible = false  # 默认隐藏 —— 我们用 Rigged 做主显示

	# SpriteAnim 形变层（状态机仍然保留，用于 AnimState 语义）
	sprite_anim = get_node_or_null("Visual/Anim")
	if sprite_anim == null:
		sprite_anim = SpriteAnim.new()
		sprite_anim.name = "Anim"
		visual.add_child(sprite_anim)
	sprite_anim.setup(visual)
	# sprite_anim.state 变化时桥接到 RiggedCharacter 姿势
	sprite_anim.state_changed.connect(_on_anim_state_changed)

func _guess_entity_type(sheet_name: String) -> String:
	# player_warrior_sheet -> warrior
	# enemy_slime -> slime
	# minion_fire_sheet -> fire
	var n: String = sheet_name.replace("_sheet", "")
	if n.begins_with("player_"):
		return n.substr(7)
	if n.begins_with("enemy_"):
		return n.substr(6)
	if n.begins_with("minion_"):
		return n.substr(7)
	return n

func _on_anim_state_changed(new_state: int) -> void:
	if rigged == null:
		return
	var state_name: String = SpriteAnim.state_name_from_int(new_state)
	var pose: String = PoseDefs.STATE_TO_POSE(state_name)
	if pose != "":
		rigged.set_pose(pose)

# —— 暴露给 PlayerController 的快捷 API ——
func set_rigged_facing(dir: Vector2) -> void:
	if rigged:
		rigged.set_facing(dir)
func rigged_flash(col: Color, dur: float = 0.15) -> void:
	if rigged:
		rigged.flash(col, dur)
func rigged_set_pose(name: String) -> void:
	if rigged:
		rigged.set_pose(name)

func _attach_frame_anim(asset_id: String, fw: int, fh: int) -> void:
	var actions := ["idle", "walk", "attack", "hit"]
	var counts := [4, 4, 3, 2]
	var fps_list := [6, 10, 12, 14]
	var frames := SpriteFramesBuilder.from_asset_id(asset_id, fw, fh, actions, counts, fps_list)
	if frames.get_animation_names().size() == 0:
		return
	frame_anim = AnimatedSprite2D.new()
	frame_anim.name = "FrameAnim"
	frame_anim.sprite_frames = frames
	frame_anim.animation = "idle"
	frame_anim.frame = 0
	frame_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 对齐：底部锚点落在原点（角色脚踩 ground）
	frame_anim.offset = Vector2(0, float(fh) * 0.35)
	# 默认缩放让角色大小一致
	var fit := float(body_radius * 2.5) / float(maxi(fw, fh))
	if fit > 0.0:
		frame_anim.scale = Vector2.ONE * fit
	visual.add_child(frame_anim)
	frame_anim.play("idle")

func _frame_play(action: String) -> void:
	if frame_anim == null:
		return
	var names := frame_anim.sprite_frames.get_animation_names()
	if action in names and frame_anim.animation != action:
		frame_anim.play(action)

# ==================== 血条（实体节点）====================

func _build_hp_bar() -> void:
	hp_bar_bg = get_node_or_null("HPBarBG")
	hp_bar_fg = get_node_or_null("HPBarFG")
	if hp_bar_bg != null and hp_bar_fg != null:
		_refresh_hp_bar()
		return
	# 动态创建血条容器
	var container := CanvasLayer.new()
	container.name = "HPBar"
	container.layer = 100
	add_child(container)

	hp_bar_bg = ColorRect.new()
	hp_bar_bg.name = "BG"
	hp_bar_bg.color = Color(0.12, 0.12, 0.14, 0.9)
	container.add_child(hp_bar_bg)

	hp_bar_fg = ColorRect.new()
	hp_bar_fg.name = "FG"
	hp_bar_fg.color = Color(0.92, 0.28, 0.28, 1.0)
	container.add_child(hp_bar_fg)

	_refresh_hp_bar()

func _refresh_hp_bar() -> void:
	if hp_bar_bg == null or hp_bar_fg == null:
		return
	var bar_w := body_radius * 2.6
	var bar_h := 5.0
	var pos_top := Vector2(-bar_w * 0.5, -body_radius - 14.0)
	hp_bar_bg.size = Vector2(bar_w, bar_h)
	hp_bar_bg.position = pos_top
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	hp_bar_fg.size = Vector2(bar_w * ratio, bar_h)
	hp_bar_fg.position = pos_top
	hp_bar_fg.color = Color(0.92, 0.28, 0.28) if ratio > 0.3 else Color(0.95, 0.55, 0.15)

# ==================== 状态效果 ====================

func _process_entity_states(delta: float) -> void:
	if stun_left > 0.0:
		stun_left = maxf(0.0, stun_left - delta)
	if slow_left > 0.0:
		slow_left = maxf(0.0, slow_left - delta)
		if slow_left <= 0.0:
			slow_factor = 1.0
	if mark_left > 0.0:
		mark_left = maxf(0.0, mark_left - delta)
		if mark_left <= 0.0:
			mark_amp = 0.0
	if flash_timer > 0.0:
		flash_timer = maxf(0.0, flash_timer - delta)

func is_flashing() -> bool:
	return flash_timer > 0.0

func is_stunned() -> bool:
	return stun_left > 0.0
func is_immune(status_kind: String) -> bool:
	return status_immune.has(status_kind)

func apply_stun(duration: float) -> void:
	if is_immune("stun"):
		if sprite_anim: sprite_anim.flash(Color(1.0, 1.0, 1.0), 0.10)
		return
	stun_left = maxf(stun_left, duration)
	if sprite_anim: sprite_anim.flash(Color(1.0, 0.9, 0.5), 0.15)

func apply_slow(factor: float, duration: float) -> void:
	if is_immune("slow") or is_immune("freeze"):
		if sprite_anim: sprite_anim.flash(Color(1.0, 1.0, 1.0), 0.10)
		return
	slow_factor = minf(slow_factor, clampf(factor, 0.1, 1.0))
	slow_left = maxf(slow_left, duration)
	if sprite_anim: sprite_anim.flash(Color(0.6, 0.85, 1.0), 0.12)

func apply_mark(duration: float, amp: float) -> void:
	mark_amp = maxf(mark_amp, amp)
	mark_left = maxf(mark_left, duration)

func apply_knockback(push_dir: Vector2, amount: float) -> void:
	if is_immune("knockback"):
		return
	if push_dir.length() > 0.01:
		global_position += push_dir.normalized() * amount

# ==================== 受击反馈链 ====================

func _on_hit_feedback(push_dir: Vector2, is_magic: bool, dealt: int) -> void:
	# 1. SpriteAnim 受击
	if sprite_anim:
		var flash_c := Color(1.0, 1.0, 1.0) if is_magic else Color(1.0, 0.6, 0.6)
		sprite_anim.enter_hurt(push_dir, flash_c)
		sprite_anim.flash(flash_c, 0.12)
	# EntityBase 自己维护一份 flash_timer（避免子类依赖 SpriteAnim 内部实现）
	flash_timer = 0.12

	# 2. 帧动画层闪 hit
	_frame_play("hit")

	# 3. 击退
	if push_dir.length() > 0.01:
		var knock_power := clampf(float(dealt) * 0.12, 4.0, 24.0)
		apply_knockback(push_dir, knock_power)

	# 4. 爆血粒子
	_spawn_hit_particles(push_dir, is_magic)

	# 5. 震屏
	var shake_intensity := clampf(float(dealt) / 30.0, 1.0, 4.0)
	if ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(shake_intensity, 0.06, 40.0)

	# 6. HitStop
	var stop_dur := clampf(float(dealt) / 300.0, 0.035, 0.09)
	if HitStop and HitStop.has_method("hit"):
		HitStop.hit(stop_dur, shake_intensity)

func _spawn_hit_particles(push_dir: Vector2, is_magic: bool) -> void:
	var level: Node = get_tree().current_scene if get_tree() else null
	if level == null:
		return
	var blood_color := Color(1.0, 0.35, 0.25) if not is_magic else Color(0.7, 0.5, 1.0)
	var count := 6
	for i in count:
		var ang := push_dir.angle() + randf_range(-0.6, 0.6)
		var spd := randf_range(40.0, 120.0)
		var dist := spd * 0.22
		var p := ColorRect.new()
		p.color = blood_color
		p.size = Vector2(3.0, 3.0)
		p.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-10, -2))
		p.z_index = 50
		level.add_child(p)
		var tween := p.create_tween()
		var target_pos := p.global_position + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, 14)
		tween.tween_property(p, "global_position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(p, "modulate:a", 0.0, 0.28).set_delay(0.08)
		tween.chain().tween_callback(p.queue_free)

func _on_death_feedback() -> void:
	# 大震屏
	if ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(5.0, 0.25, 100.0)
	# HitStop 死亡停顿
	if HitStop and HitStop.has_method("hit"):
		HitStop.hit(0.09, 3.0)
	# 死亡粒子
	_spawn_death_particles()

func _spawn_death_particles() -> void:
	var level: Node = get_tree().current_scene if get_tree() else null
	if level == null:
		return
	var shard_colors := [
		body_color, Color(1.0, 0.4, 0.3), Color(0.9, 0.85, 0.7), Color(1.0, 0.7, 0.5)
	]
	for i in range(14):
		var ang := TAU * (float(i) / 14.0) + randf_range(-0.15, 0.15)
		var spd := randf_range(80.0, 180.0)
		var dist := spd * 0.35
		var col: Color = shard_colors[randi() % shard_colors.size()]
		var size := randf_range(4.0, 8.0)
		var p := ColorRect.new()
		p.color = col
		p.size = Vector2(size, size)
		p.global_position = global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		p.z_index = 50
		level.add_child(p)
		var tween := p.create_tween()
		var target_pos := p.global_position + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, 50)
		tween.set_parallel(true)
		tween.tween_property(p, "global_position", target_pos, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.55).set_delay(0.2)
		tween.tween_property(p, "rotation", randf_range(-1.5, 1.5), 0.45)
		tween.chain().tween_callback(p.queue_free)
	# 8 血珠
	var drop_color := Color(0.95, 0.25, 0.15)
	for i in range(8):
		var ang := randf_range(PI * 0.7, PI * 1.3)
		var spd := randf_range(80.0, 140.0)
		var dist := spd * 0.38
		var p := ColorRect.new()
		p.color = drop_color
		p.size = Vector2(3.0, 3.0)
		p.global_position = global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		p.z_index = 50
		level.add_child(p)
		var tween := p.create_tween()
		var target_pos := p.global_position + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, 60)
		tween.set_parallel(true)
		tween.tween_property(p, "global_position", target_pos, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.75).set_delay(0.4)
		tween.chain().tween_callback(p.queue_free)

# ==================== 通用 take_damage / heal / die ====================

func take_damage(amount: int, is_magic: bool = false, source: Node = null) -> int:
	if hp <= 0:
		return 0
	if source:
		last_attacker = source
	var dealt := maxi(1, amount)  # 实际减免由子类 override 更精细
	# mark 增伤
	if mark_left > 0.0 and mark_amp > 0.0:
		dealt = int(round(float(dealt) * (1.0 + mark_amp)))
	hp = maxi(0, hp - dealt)
	_refresh_hp_bar()
	hp_changed.emit(hp, max_hp)

	var push_dir := Vector2.ZERO
	if source is Node2D:
		push_dir = (global_position - (source as Node2D).global_position).normalized()
	if push_dir.length() < 0.01:
		push_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	_on_hit_feedback(push_dir, is_magic, dealt)

	if hp <= 0:
		die()
	return dealt

func die() -> void:
	if hp <= 0:
		# 防重入
		pass
	_on_death_feedback()
	if sprite_anim:
		sprite_anim.enter_dead()
	entity_died.emit()

func heal(amount: int) -> int:
	var actual := mini(amount, max_hp - hp)
	hp += actual
	_refresh_hp_bar()
	hp_changed.emit(hp, max_hp)
	return actual
