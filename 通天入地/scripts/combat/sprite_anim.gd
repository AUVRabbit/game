# ============================================================
# SpriteAnim — 通用 Node2D 动画控制器（纯 tween 形变 + 呼吸 + 冲刺残影）
# 适配玩家与敌人，不依赖 AnimatedSprite2D / SpriteFrames。
# ============================================================

extends Node2D
class_name SpriteAnim

enum AnimState { IDLE, RUN, ATTACK, CAST, DASH, HURT, DEAD }

var target: Node2D = null
var _is_character_body := false
var state: AnimState = AnimState.IDLE
var facing: Vector2 = Vector2.DOWN
var move_mag: float = 0.0
var _breath_t: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _active_offset: Vector2 = Vector2.ZERO
var _active_rotation: float = 0.0
var _active_scale_mult: float = 1.0
var _ghost_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_total: float = 0.0
var _attack_target_pos: Vector2 = Vector2.ZERO
var _attack_range: float = 0.0
var _attack_kind: String = ""  # "melee" | "projectile"
var _hurt_timer: float = 0.0
var _hurt_push: Vector2 = Vector2.ZERO
var _dead_timer: float = 0.0
var _color_tween: Tween = null
var _mod_flash: float = 0.0
var _flash_color: Color = Color.WHITE
var _ghost_spawn_interval: float = 0.055
var _ghost_last_spawn: float = 0.0
var _ghost_lifetime: float = 0.18

func setup(owner: Node2D) -> void:
	target = owner
	_is_character_body = owner is CharacterBody2D
	if _is_character_body:
		# CharacterBody2D 的 position 由物理系统管理，动画只改 offset
		_base_offset = Vector2.ZERO
	else:
		_base_offset = owner.position
	if owner is Sprite2D:
		_base_scale = owner.scale
	else:
		_base_scale = Vector2.ONE

func _process(delta: float) -> void:
	if target == null:
		return
	_breath_t += delta

	# 伤害闪烁叠加颜色
	var color := Color(1.0, 1.0, 1.0, 1.0)
	if _mod_flash > 0.0:
		_mod_flash -= delta
		var t := clampf(_mod_flash / 0.12, 0.0, 1.0)
		color = Color(_flash_color.r, _flash_color.g, _flash_color.b, 1.0)
		color.r = lerpf(color.r, 1.0, 1.0 - t)
		color.g = lerpf(color.g, 1.0, 1.0 - t)
		color.b = lerpf(color.b, 1.0, 1.0 - t)
	if target.has_method("set_modulate"):
		target.modulate = color

	# 呼吸：idle 时慢，run 时快
	var breath_speed := 2.6 if state == AnimState.RUN else 1.6
	var breath_strength := 2.2 if state == AnimState.RUN else 1.2
	var breath_y := sin(_breath_t * breath_speed) * breath_strength
	var breath_x := cos(_breath_t * breath_speed * 0.5) * breath_strength * 0.3

	# 动作特定的位移/缩放/旋转
	var action_offset := Vector2(breath_x, breath_y)
	var action_scale := 1.0
	var action_rot := 0.0

	match state:
		AnimState.IDLE:
			action_scale = 1.0 + sin(_breath_t * 1.4) * 0.02
		AnimState.RUN:
			var step = sin(_breath_t * 9.0)
			action_offset.y += step * 3.0
			action_offset.x += step * facing.x * 2.0
			action_scale = 1.0 + step * 0.04
		AnimState.ATTACK:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			if _attack_kind == "melee":
				# D3 三段式：蓄力(t<0.2) → 前冲命中(0.2~0.55) → 收招(0.55~1.0)
				var forward = facing * _attack_range
				var kf_mult: float = 0.0
				var scale_k: float = 1.0
				var rot_k: float = 0.0
				if t < 0.22:
					kf_mult = -sin(t / 0.22 * PI) * 0.35
					scale_k = 1.12 - sin(t / 0.22 * PI) * 0.07
					rot_k = -facing.x * 0.18 * (t / 0.22)
				elif t < 0.55:
					var t2 := (t - 0.22) / 0.33
					kf_mult = sin(t2 * PI) * 1.1
					scale_k = 1.08 + sin(t2 * PI) * 0.06
					rot_k = facing.x * 0.28 * sin(t2 * PI)
				else:
					var t3 := (t - 0.55) / 0.45
					kf_mult = 0.35 * sin(PI + t3 * PI * 0.6)
					scale_k = 1.0 + 0.02 * sin(t3 * PI * 2.0)
					rot_k = facing.x * 0.1 * sin(t3 * PI * 0.8)
				action_offset = forward * kf_mult * 0.7 + Vector2(0, sin(_breath_t * 8) * 1.2)
				action_scale = scale_k
				action_rot = rot_k
			else:
				var offset_vec := Vector2.ZERO
				var rot_k: float = 0.0
				var scale_k: float = 1.0
				if t < 0.35:
					var t2 := t / 0.35
					offset_vec = -facing * 4.0 * sin(t2 * PI)
					rot_k = -facing.x * 0.14 * sin(t2 * PI)
					scale_k = 0.93 + 0.07 * t2
				elif t < 0.55:
					var t2 := (t - 0.35) / 0.2
					offset_vec = facing * 3.0 * sin(t2 * PI)
					rot_k = facing.x * 0.22 * sin(t2 * PI)
					scale_k = 1.04
				else:
					var t3 := (t - 0.55) / 0.45
					offset_vec = -facing * 1.0 * sin(t3 * PI * 0.8)
					rot_k = facing.x * 0.06 * sin(t3 * PI)
					scale_k = 1.0
				action_offset = offset_vec + Vector2(0, sin(_breath_t * 6) * 0.6)
				action_rot = rot_k
				action_scale = scale_k
		AnimState.CAST:
			# 施法：上抬 + 双手光环 + 咏唱时身体脉动
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			action_offset = Vector2(0, -2.0 * sin(t * PI * 3))
			action_scale = 1.0 + 0.06 * sin(t * PI * 4)
		AnimState.DASH:
			action_scale = 1.0 + sin(_breath_t * 20) * 0.04
		AnimState.HURT:
			var t := clampf(_hurt_timer / maxf(0.22, 0.001), 0.0, 1.0)
			action_offset = _hurt_push * (1.0 - t) + Vector2(0, sin(_breath_t * 12) * 2.0 * (1.0 - t))
			action_rot = _hurt_push.x * 0.15 * (1.0 - t)
		AnimState.DEAD:
			var t := clampf(_dead_timer / maxf(0.8, 0.001), 0.0, 1.0)
			action_rot = PI * 0.25 * t
			action_scale = 1.0 - 0.2 * t
			color.a = 1.0 - 0.5 * t
			target.modulate = color

	# 冲刺残影
	if state == AnimState.DASH:
		_ghost_last_spawn += delta
		if _ghost_last_spawn >= _ghost_spawn_interval:
			_ghost_last_spawn = 0.0
			_spawn_ghost()

	# 应用组合
	var final_offset := _base_offset + action_offset + _active_offset
	if _is_character_body:
		# CharacterBody2D 的 position 由物理系统管理，通过自定义属性传递视觉偏移
		target.set("visual_offset", final_offset)
	else:
		target.position = final_offset
	target.rotation = _active_rotation + action_rot
	target.scale = _base_scale * _active_scale_mult * action_scale

	# tick 计时器
	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _dead_timer > 0.0:
		_dead_timer -= delta


# ---------- 公共 API ----------

func enter_attack(fkind: String, range: float, duration: float, target_pos: Vector2 = Vector2.ZERO, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.ATTACK
	_attack_kind = fkind
	_attack_range = range
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()
	if target_pos.length() > 0.001:
		_attack_target_pos = target_pos


func enter_cast(duration: float, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.CAST
	_attack_kind = "cast"
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_dash() -> void:
	state = AnimState.DASH
	_ghost_last_spawn = _ghost_spawn_interval
	_spawn_ghost()
	_spawn_ghost()


func enter_hurt(push_dir: Vector2, flash_color: Color = Color(1.0, 0.5, 0.5)) -> void:
	state = AnimState.HURT
	_hurt_push = push_dir * 8.0
	_hurt_timer = 0.22
	flash(flash_color, 0.12)


func enter_dead() -> void:
	state = AnimState.DEAD
	_dead_timer = 0.0


func settle_to(next_state: AnimState, new_facing: Vector2, move_m: float = 0.0) -> void:
	# 只有在非动作状态下才跟随
	if state == AnimState.HURT:
		return
	state = next_state
	if new_facing.length() > 0.01:
		facing = new_facing.normalized()
	move_mag = move_m


func flash(color_value: Color = Color.WHITE, dur: float = 0.12) -> void:
	_flash_color = color_value
	_mod_flash = dur


func _spawn_ghost() -> void:
	if target == null or target.get_parent() == null or not (target is Node2D):
		return
	var ghost := Sprite2D.new()
	var src: Texture2D = null
	if target is Sprite2D:
		src = (target as Sprite2D).texture
	else:
		# 尝试 Visual 子节点
		var vis = target.get_node_or_null("Visual")
		if vis:
			for c in vis.get_children():
				if c is Sprite2D and (c as Sprite2D).texture:
					src = (c as Sprite2D).texture
					break
	if src == null:
		return
	ghost.texture = src
	ghost.global_position = (target as Node2D).global_position
	ghost.rotation = (target as Node2D).rotation
	ghost.scale = target.scale * 0.9
	ghost.z_index = (target.z_index + 1)
	ghost.modulate = Color(0.85, 0.95, 1.0, 0.7)
	ghost.material = CanvasItemMaterial.new()
	ghost.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	target.get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, _ghost_lifetime)
	tween.tween_property(ghost, "scale", ghost.scale * 0.6, _ghost_lifetime)
	tween.chain().tween_callback(ghost.queue_free)
