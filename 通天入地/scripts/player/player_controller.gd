# ============================================================
# PlayerController — 玩家角色控制器
# 8 方向等距移动 / 普攻 / 10 技能槽 / 冲刺无敌 / 交互 / 切换
# 内置通用动画控制器（sprite_anim.gd），纯 tween 形变实现移动/攻击/施法/受击/冲刺。
# ============================================================

extends CharacterBody2D
class_name PlayerController

enum State { IDLE, MOVE, ATTACK, CAST, DASH, DEAD }

const DASH_SPEED := 620.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 0.9
const ATTACK_RADIUS := 56.0
const INTERACT_RADIUS := 76.0

var character_data = null
var visual: Node2D = null
var attack_point: Marker2D = null
var body_poly: Polygon2D = null
var sprite: Sprite2D = null
var _sprite_class_id: String = ""
var _anim: SpriteAnim = null
var _cached_sprite_offset: Vector2 = Vector2.ZERO
var frame_anim: AnimatedSprite2D = null  # 多帧 sprite sheet 动画层

var state: State = State.IDLE
var facing: Vector2 = Vector2.DOWN
var attack_cooldown: float = 0.0
var dash_cd: float = 0.0
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.DOWN
var skill_cooldowns: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var spawn_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	set_process_unhandled_input(true)
	visual = get_node_or_null("Visual")
	attack_point = get_node_or_null("AttackPoint")
	body_poly = get_node_or_null("Visual/Body")
	character_data = get_node_or_null("CharacterData")
	spawn_point = global_position
	if character_data:
		_apply_class_color()
		character_data.stats_changed.connect(_on_stats_changed)
		character_data.died.connect(_on_died)
		if character_data.hp <= 0:
			character_data.hp = character_data.get_max_hp()
		if character_data.mp < 0:
			character_data.mp = 0
	# 把 SpriteAnim 接到 Visual 上（Visual 持有 sprite / body_poly），驱动位置/缩放/旋转/闪烁
	if visual:
		_anim = SpriteAnim.new()
		_anim.name = "Anim"
		visual.add_child(_anim)
		_anim.setup(visual)

func _apply_class_color() -> void:
	if body_poly and character_data:
		body_poly.color = character_data.class_color
		var outline := PackedVector2Array([
			Vector2(-15, 0), Vector2(0, -22), Vector2(15, 0), Vector2(0, 15)
		])
		body_poly.polygon = outline
	_refresh_class_sprite()

# 按当前职业加载真实角色立绘（贴图缺失时保留 Polygon2D 占位）
func _refresh_class_sprite() -> void:
	if character_data == null or visual == null:
		return
	var class_id := str(character_data.class_id)
	if class_id == _sprite_class_id:
		return
	_sprite_class_id = class_id
	var tex: Texture2D = AssetLibrary.texture("sprite_player_%s" % class_id)
	if tex == null:
		if sprite:
			sprite.visible = false
		if body_poly:
			body_poly.visible = true
		# 调整动画控制器的 base_offset 指向 body_poly（替代 Sprite2D）
		if _anim:
			_anim.target = body_poly
			_anim._base_offset = Vector2.ZERO
		return
	if sprite == null or not is_instance_valid(sprite):
		sprite = Sprite2D.new()
		sprite.name = "ClassSprite"
		visual.add_child(sprite)
	sprite.texture = tex
	sprite.visible = true
	var scale_factor := 0.42
	var half := float(tex.get_width()) * 0.5
	var rect := _content_rect(tex)
	var center_x := half
	var bottom := float(tex.get_height())
	if rect.size.x > 0 and rect.size.y > 0:
		center_x = float(rect.position.x) + float(rect.size.x) * 0.5
		bottom = float(rect.position.y) + float(rect.size.y)
	sprite.scale = Vector2.ONE * scale_factor
	var off := Vector2((half - center_x) * scale_factor, (half - bottom) * scale_factor)
	sprite.position = off
	_cached_sprite_offset = off
	if body_poly:
		body_poly.visible = false
	if _anim:
		_anim.target = sprite
		_anim._base_offset = off
		_anim._base_scale = sprite.scale
	# 多帧 sheet 动画层（和 Sprite2D 同位置叠加，frame anim 驱动帧切换，SpriteAnim 驱动形变）
	_try_attach_frame_anim(class_id, off, sprite.scale)

func _try_attach_frame_anim(class_id: String, sprite_off: Vector2, sprite_scale: Vector2) -> void:
	if visual == null:
		return
	if frame_anim != null and is_instance_valid(frame_anim):
		return
	var frame_w := 128
	var frame_h := 128
	var asset_id := "player_%s" % class_id
	var actions := ["idle", "walk", "attack", "hit"]
	var counts := [4, 4, 3, 2]
	var fps_list := [8, 12, 14, 16]
	var frames := SpriteFramesBuilder.from_asset_id(asset_id, frame_w, frame_h, actions, counts, fps_list)
	if frames.get_animation_names().size() == 0:
		return
	frame_anim = AnimatedSprite2D.new()
	frame_anim.name = "FrameAnim"
	frame_anim.sprite_frames = frames
	frame_anim.animation = "idle"
	frame_anim.frame = 0
	frame_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame_anim.position = sprite_off
	frame_anim.scale = sprite_scale
	visual.add_child(frame_anim)
	frame_anim.play("idle")

func _frame_set_action(action: String) -> void:
	if frame_anim == null:
		return
	var names := frame_anim.sprite_frames.get_animation_names()
	if action in names:
		frame_anim.play(action)

func _content_rect(tex: Texture2D) -> Rect2i:
	var img: Image = tex.get_image()
	if img == null:
		return Rect2i()
	if img.is_compressed():
		if img.decompress() != OK:
			return Rect2i()
	return img.get_used_rect()

func _on_stats_changed() -> void:
	_apply_class_color()

# ---------- 找敌人 / 目标 ----------

func _find_nearest_enemy(max_dist: float = 300.0) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var d: float = global_position.distance_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	return best


func _physics_process(delta: float) -> void:
	if character_data == null:
		return
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if dash_cd > 0.0:
		dash_cd = maxf(0.0, dash_cd - delta)
	for i in skill_cooldowns.size():
		if float(skill_cooldowns[i]) > 0.0:
			skill_cooldowns[i] = maxf(0.0, float(skill_cooldowns[i]) - delta)

	if GameManager and GameManager.is_input_blocked():
		velocity = Vector2.ZERO
		_anim_snap_to(SpriteAnim.AnimState.IDLE, facing, 0.0)
		return
	if character_data.hp <= 0:
		velocity = Vector2.ZERO
		if _anim:
			_anim.enter_dead()
		return

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		velocity = dash_dir * DASH_SPEED
		if _anim:
			_anim.settle_to(SpriteAnim.AnimState.DASH, dash_dir)
		move_and_slide()
		if dash_timer <= 0.0:
			state = State.IDLE
		return

	var move_vec := Vector2.ZERO
	if InputManager:
		move_vec = InputManager.get_move_vector()
	else:
		move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_vec.length() > 0.05:
		facing = move_vec.normalized()
		velocity = facing * character_data.get_move_speed()
		if state != State.ATTACK and state != State.CAST:
			state = State.MOVE
	else:
		velocity = Vector2.ZERO
		if state == State.MOVE:
			state = State.IDLE
	move_and_slide()
	if visual:
		visual.scale.x = -1.0 if facing.x < -0.05 else 1.0

	# 推进动画状态机
	_anim_snap_to(
		SpriteAnim.AnimState.RUN if move_vec.length() > 0.05 else SpriteAnim.AnimState.IDLE,
		facing, velocity.length())


func _anim_snap_to(desired: SpriteAnim.AnimState, dir: Vector2, move_m: float) -> void:
	if _anim == null:
		return
	if _anim.state == SpriteAnim.AnimState.HURT or _anim.state == SpriteAnim.AnimState.ATTACK or \
		_anim.state == SpriteAnim.AnimState.CAST or _anim.state == SpriteAnim.AnimState.DASH or \
		_anim.state == SpriteAnim.AnimState.SWORD_SWING or _anim.state == SpriteAnim.AnimState.BOW_DRAW or \
		_anim.state == SpriteAnim.AnimState.THROW_BOMB or _anim.state == SpriteAnim.AnimState.CAST_SPELL or \
		_anim.state == SpriteAnim.AnimState.SUMMON_RITUAL or _anim.state == SpriteAnim.AnimState.FORCE_READY:
		return
	if _anim.state == SpriteAnim.AnimState.DEAD:
		return
	_anim.settle_to(desired, dir, move_m)
	# 同步帧动画层
	if frame_anim:
		if desired == SpriteAnim.AnimState.RUN:
			frame_anim.play("walk")
		else:
			frame_anim.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if GameManager and GameManager.is_input_blocked():
		return
	if character_data == null or character_data.hp <= 0:
		return
	if BuildManager and BuildManager.is_build_mode:
		if event.is_action_pressed("character_switch_next"):
			GameManager.switch_character(1)
		elif event.is_action_pressed("character_switch_prev"):
			GameManager.switch_character(-1)
		return
	if event.is_action_pressed("attack"):
		try_attack()
	elif event.is_action_pressed("dash"):
		try_dash()
	elif event.is_action_pressed("interact"):
		try_interact()
	else:
		for i in range(10):
			if event.is_action_pressed("skill_%d" % (i + 1)):
				try_skill(i)
				return
	var switch_dir := 0
	if event.is_action_pressed("character_switch_next"):
		switch_dir = 1
	elif event.is_action_pressed("character_switch_prev"):
		switch_dir = -1
	if switch_dir != 0:
		GameManager.switch_character(switch_dir)

func try_attack() -> void:
	if attack_cooldown > 0.0:
		return
	var profile: Dictionary = character_data.get_basic_attack()
	var kind := str(profile.get("kind", "melee"))
	attack_cooldown = float(profile.get("cooldown", 0.42)) / maxf(0.3, character_data.get_attack_speed())
	state = State.ATTACK
	var is_magic := bool(profile.get("magic", false))
	var base_stat: int = character_data.get_magic_attack() if is_magic else character_data.get_attack()
	var damage: int = base_stat + randi_range(-2, 3)
	var is_crit: bool = randf() < character_data.get_crit_rate()
	if is_crit:
		damage = int(round(damage * character_data.crit_damage))

	# 锁定最近敌人作为攻击目标
	var target := _find_nearest_enemy(280.0 if kind != "melee" else 120.0)
	var target_pos: Vector2 = global_position + facing * 24.0
	if target:
		target_pos = target.global_position
		# 显示锁定标记
		TargetingReticle.spawn(get_parent(), target.global_position,
			Color.from_string(str(profile.get("color", "#ffd966")), Color(1.0, 0.85, 0.4, 0.9)), 0.3, 16.0)

	# 朝向目标
	if target:
		facing = (target.global_position - global_position).normalized()
		if visual:
			visual.scale.x = -1.0 if facing.x < -0.05 else 1.0

	# ============ 精细动作路由：每种武器专属动作 ============
	var anim_range := float(profile.get("radius", ATTACK_RADIUS)) if kind == "melee" else 22.0
	var anim_dur := 0.28
	route_basic_attack_kind(kind, profile, anim_range, anim_dur, facing)
	if frame_anim:
		frame_anim.play("attack")

	# 远程/射线/抛掷类普攻交给技能执行器，近战保留贴身判定
	if kind != "melee":
		SkillExecutor.cast_basic(self, profile, damage, is_crit)
		AudioManager.play_sfx("skill")
		EventBus.attack_performed.emit(self, null)
		await get_tree().create_timer(anim_dur).timeout
		if state == State.ATTACK:
			state = State.IDLE
		return
	var radius := float(profile.get("radius", ATTACK_RADIUS))
	var knockback := float(profile.get("knockback", 0.0))
	var origin := global_position
	if attack_point:
		origin = attack_point.global_position
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if origin.distance_to(enemy.global_position) > radius:
			continue
		var dealt: int = enemy.take_damage(damage, is_magic, self)
		DamageNumber.spawn(get_parent(), enemy.global_position + Vector2(0, -26), dealt, is_crit)
		EventBus.attack_performed.emit(self, enemy)
		if knockback > 0.0 and enemy is Node2D:
			var push: Vector2 = (enemy.global_position - global_position).normalized()
			if push.length() < 0.01:
				push = facing
			enemy.global_position += push * knockback
		hit_any = true
		var lifesteal: float = character_data.get_lifesteal()
		if lifesteal > 0.0 and dealt > 0:
			character_data.heal(int(round(float(dealt) * lifesteal)))
	if hit_any:
		AudioManager.play_sfx("hit")
		if ScreenShake and ScreenShake.has_method("micro"):
			ScreenShake.micro()
	var ring_color := Color.from_string(str(profile.get("color", "#ffd966")), Color(1.0, 0.85, 0.4, 0.9))
	EffectRing.spawn(get_parent(), origin, radius, ring_color)
	# 近战挥砍弧形 vfx
	SkillVfx.spawn(get_parent(), origin, "melee_slash", ring_color, 0.9, facing.angle())
	EventBus.attack_performed.emit(self, null)
	await get_tree().create_timer(anim_dur).timeout
	if state == State.ATTACK:
		state = State.IDLE

func try_skill(slot: int) -> void:
	if character_data == null or slot < 0 or slot >= 10:
		return
	if slot < skill_cooldowns.size() and float(skill_cooldowns[slot]) > 0.0:
		return
	if character_data.hp <= 0:
		return
	if slot >= character_data.get_slot_count():
		EventBus.notify("该操作栏格位尚未解锁：完成技能树层数可获得更多格位")
		return
	var skill: Dictionary = character_data.get_skill(slot + 1)
	if skill.is_empty():
		EventBus.notify("该格位尚未装配技能")
		return
	if not _skill_unlocked(skill):
		EventBus.notify("【%s】尚未解锁：请在技能树点亮前置节点" % str(skill.get("name", "")))
		return

	# 先锁定目标（远程/近战技能），决定施法朝向
	var range := _range_for(skill)
	var target := _find_nearest_enemy(range) if range > 0.0 else null
	var type_name := str(skill.get("type", ""))
	if target and _skill_is_targeted(type_name):
		facing = (target.global_position - global_position).normalized()
		if visual:
			visual.scale.x = -1.0 if facing.x < -0.05 else 1.0
		TargetingReticle.spawn(get_parent(), target.global_position,
			Color.from_string(str(skill.get("color", "#ffffff")), Color.WHITE), 0.35, 20.0)

	# 施法动画（每种技能类型专属动作）
	if _anim:
		var dur := 0.3
		var radius2 := float(skill.get("radius", 60))
		route_skill_type(type_name, radius2, dur, facing)
		if frame_anim:
			if type_name in ["melee_aoe", "dash_strike", "blink_strike"]:
				frame_anim.play("attack")
			else:
				frame_anim.play("attack")

	state = State.CAST
	var ok: bool = await SkillExecutor.cast(self, skill)
	if slot < skill_cooldowns.size():
		var cd_mult: float = character_data.get_skill_cooldown_multiplier(str(skill.get("id", "")))
		# mech_pilot_c 要塞：所有技能 CD ×0.85
		var sig_kind2 := str(character_data.get_signature().get("kind", "")) if character_data != null and character_data.has_method("get_signature") else ""
		if sig_kind2 == "fortress":
			cd_mult *= 0.85
		skill_cooldowns[slot] = float(skill.get("cd", 3.0)) * cd_mult
	var post_dur := 0.16 if ok else 0.0
	await get_tree().create_timer(post_dur).timeout
	if state == State.CAST:
		state = State.IDLE


func _skill_is_targeted(type_name: String) -> bool:
	match type_name:
		"heal", "buff", "shield", "summon", "deployable", "aoe_zone", "root_zone", "heal_zone", "pull_zone":
			return false
		_:
			return true


func _range_for(skill: Dictionary) -> float:
	var type_name := str(skill.get("type", ""))
	match type_name:
		"melee_aoe":
			return float(skill.get("radius", 120))
		"projectile":
			return float(skill.get("range", 420))
		"dash_strike":
			return float(skill.get("radius", 160))
		"chain":
			return float(skill.get("radius", 300))
		"snipe":
			return float(skill.get("range", 640))
		"blink_strike":
			return float(skill.get("radius", 260))
		"aoe_zone", "root_zone", "pull_zone", "heal_zone":
			return float(skill.get("radius", 160))
		_:
			return 0.0


# 进阶主动技能需先在技能树点亮对应的精通节点
func _skill_unlocked(skill: Dictionary) -> bool:
	var req = skill.get("requires", "")
	if req == null:
		return true
	if req is String and str(req).is_empty():
		return true
	if SkillManager == null or character_data == null:
		return true
	var class_id := str(character_data.class_id)
	if req is Array:
		for r in req:
			if not SkillManager.is_unlocked(class_id, str(r)):
				return false
		return true
	return SkillManager.is_unlocked(class_id, str(req))

func try_dash() -> void:
	var sig_kind := str(character_data.get_signature().get("kind", "")) if character_data != null and character_data.has_method("get_signature") else ""
	if sig_kind == "fortress":
		# mech_pilot_c 要塞：无法冲刺
		EventBus.notify("要塞姿态：无法冲刺")
		return
	if dash_cd > 0.0 or dash_timer > 0.0:
		return
	dash_timer = DASH_DURATION
	dash_dir = facing if facing.length() > 0.01 else Vector2.DOWN
	if sig_kind != "wind_sprint":
		# qi_adept_c 疾风：冲刺不耗 CD
		dash_cd = DASH_COOLDOWN
	if _anim:
		_anim.enter_dash()
	state = State.DASH
	AudioManager.play_sfx("dash")
	EffectRing.spawn(get_parent(), global_position, 30.0, Color(0.7, 0.9, 1.0, 0.8))

func try_interact() -> void:
	var nearest: Node = null
	var best_dist := INTERACT_RADIUS
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var d: float = global_position.distance_to((node as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			nearest = node
	if nearest:
		# 根据可交互对象类型选择 FORCE_READY 子状态
		var sub := "dialog"
		if nearest.is_in_group("forges") or nearest.is_in_group("craft_stations"):
			sub = "forge"
		elif nearest.is_in_group("chests") or nearest.is_in_group("resources"):
			sub = "search"
		if _anim:
			_anim.enter_force_ready(sub)
		if nearest.has_method("interact"):
			nearest.interact(self)

func is_invulnerable() -> bool:
	return dash_timer > 0.0

func receive_damage(amount: int, is_magic: bool = false, source: Node = null) -> int:
	if character_data == null or character_data.hp <= 0:
		return 0
	if is_invulnerable():
		return 0
	var dealt: int = character_data.take_damage(amount, is_magic, source)
	if dealt > 0:
		DamageNumber.spawn(get_parent(), global_position + Vector2(0, -32), dealt, false)
		EventBus.player_hurt.emit(self, dealt, source)
		AudioManager.play_sfx("hurt")
		_flash_and_poke(source)
	return dealt

func _flash_and_poke(source: Node) -> void:
	# 颜色闪烁
	if _anim:
		_anim.flash(Color(1.0, 0.55, 0.55), 0.12)
		var dir := Vector2.ZERO
		if source is Node2D:
			dir = (global_position - (source as Node2D).global_position).normalized()
		if dir.length() < 0.01:
			dir = -facing
		_anim.enter_hurt(dir, Color(1.0, 0.55, 0.55))
	# 帧动画层：受击闪红 2 帧
	if frame_anim:
		frame_anim.play("hit")
	if ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(3.2, 0.14, 55.0)


func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	if _anim:
		_anim.enter_dead()
	elif visual:
		visual.modulate = Color(0.4, 0.4, 0.4, 0.7)

func revive() -> void:
	state = State.IDLE
	if _anim:
		_anim.state = SpriteAnim.AnimState.IDLE
		_anim._mod_flash = 0.0
	if visual:
		visual.modulate = Color.WHITE
	if frame_anim:
		frame_anim.play("idle")
	dash_timer = 0.0

# ============ 动作路由函数：每种武器/技能类型→专属 SpriteAnim ============

func route_basic_attack_kind(kind: String, profile: Dictionary, range: float, dur: float, dir: Vector2) -> void:
	"""按普攻武器类型选动作（近战→剑挥，远程→弓拉，投掷→炸弹抛）"""
	if _anim == null:
		return
	var icon_name := str(profile.get("icon", ""))
	var color_str := str(profile.get("color", "#ffffff"))
	var color := Color.from_string(color_str, Color.WHITE)
	if kind == "melee":
		_anim.enter_sword_swing(range, dur, dir)
	elif kind == "projectile":
		# 红色/橙色 + icon 含 bomb/blast → 炸弹投掷动作
		var bomb_keywords := ["bomb", "blast", "grenade", "explosive", "bomber", "aluminum"]
		var is_bomb := icon_name.to_lower().contains("bomb") or color.r > 0.85 and color.g < 0.55
		if is_bomb:
			_anim.enter_throw_bomb(dur * 1.4, dir)
		else:
			_anim.enter_bow_draw(dur * 1.5, dir)
	else:
		_anim.enter_cast_spell(dur * 1.6, dir)

func route_skill_type(type_name: String, radius: float, dur: float, dir: Vector2) -> void:
	"""按技能 type 字段选最匹配的专属动作"""
	if _anim == null:
		return
	match type_name:
		# 近战系：剑/斧挥砍（大幅前冲 + 过顶劈）
		"melee_aoe", "dash_strike", "blink_strike":
			_anim.enter_sword_swing(radius, dur * 1.1, dir)
		# 远程系：弓拉弦蓄力（后拉 + body 压缩）
		"projectile", "snipe", "mark", "pull_zone":
			_anim.enter_bow_draw(dur * 1.5, dir)
		# 投掷系：手榴弹上抛（下蹲 + 上抛）
		"deployable":
			_anim.enter_throw_bomb(dur * 1.6, dir)
		# 召唤：法阵仪式（下沉 + 放大 + 旋转）
		"summon":
			_anim.enter_summon_ritual(dur * 2.0, dir)
		# 治疗/增益：法术双手上抬
		"heal", "buff", "shield", "heal_zone":
			_anim.enter_cast_spell(dur * 1.5, dir)
		# 链式/区域/状态类：标准法术咏唱
		"chain", "aoe_zone", "root_zone", "stun_wave":
			_anim.enter_cast_spell(dur * 1.3, dir)
		_:
			# fallback
			_anim.enter_cast(dur, dir)

func get_skill_cooldown_ratio(slot: int) -> float:
	if slot < 0 or slot >= skill_cooldowns.size() or character_data == null:
		return 0.0
	if slot >= character_data.get_slot_count():
		return 0.0
	var skill: Dictionary = character_data.get_skill(slot + 1)
	if skill.is_empty():
		return 0.0
	var total_cd := maxf(0.01, float(skill.get("cd", 1.0)))
	return clampf(float(skill_cooldowns[slot]) / total_cd, 0.0, 1.0)

func get_skill_cooldown_left(slot: int) -> float:
	if slot < 0 or slot >= skill_cooldowns.size():
		return 0.0
	return float(skill_cooldowns[slot])
