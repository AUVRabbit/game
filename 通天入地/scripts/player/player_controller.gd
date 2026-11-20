# ============================================================
# PlayerController — 玩家角色控制器
# 8 方向等距移动 / 普攻 / 3 技能槽 / 冲刺无敌 / 交互 / 切换
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

var state: State = State.IDLE
var facing: Vector2 = Vector2.DOWN
var attack_cooldown: float = 0.0
var dash_cd: float = 0.0
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.DOWN
var skill_cooldowns: Array = [0.0, 0.0, 0.0]
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
	sprite.position = Vector2((half - center_x) * scale_factor, (half - bottom) * scale_factor)
	if body_poly:
		body_poly.visible = false

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
		return
	if character_data.hp <= 0:
		velocity = Vector2.ZERO
		return

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		velocity = dash_dir * DASH_SPEED
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
		for i in 3:
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
	attack_cooldown = 0.42 / maxf(0.3, character_data.attack_speed)
	state = State.ATTACK
	var origin := global_position
	if attack_point:
		origin = attack_point.global_position
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if origin.distance_to(enemy.global_position) > ATTACK_RADIUS:
			continue
		var damage: int = character_data.get_attack() + randi_range(-2, 3)
		var is_crit: bool = randf() < character_data.get_crit_rate()
		if is_crit:
			damage = int(round(damage * character_data.crit_damage))
		var dealt: int = enemy.take_damage(damage, false, self)
		DamageNumber.spawn(get_parent(), enemy.global_position + Vector2(0, -26), dealt, is_crit)
		EventBus.attack_performed.emit(self, enemy)
		hit_any = true
		var lifesteal: float = character_data.get_lifesteal()
		if lifesteal > 0.0 and dealt > 0:
			character_data.heal(int(round(float(dealt) * lifesteal)))
	if hit_any:
		AudioManager.play_sfx("hit")
	EffectRing.spawn(get_parent(), origin, ATTACK_RADIUS, Color(1.0, 0.85, 0.4, 0.9))
	EventBus.attack_performed.emit(self, null)
	await get_tree().create_timer(0.2).timeout
	if state == State.ATTACK:
		state = State.IDLE

func try_skill(slot: int) -> void:
	if slot < 0 or slot >= character_data.skills.size():
		return
	if slot < skill_cooldowns.size() and float(skill_cooldowns[slot]) > 0.0:
		return
	if character_data.hp <= 0:
		return
	var skill: Dictionary = character_data.skills[slot]
	if SkillExecutor.cast(self, skill):
		state = State.CAST
		if slot < skill_cooldowns.size():
			var cd_mult: float = character_data.get_skill_cooldown_multiplier(str(skill.get("id", "")))
			skill_cooldowns[slot] = float(skill.get("cd", 3.0)) * cd_mult
		await get_tree().create_timer(0.15).timeout
		if state == State.CAST:
			state = State.IDLE

func try_dash() -> void:
	if dash_cd > 0.0 or dash_timer > 0.0:
		return
	dash_cd = DASH_COOLDOWN
	dash_timer = DASH_DURATION
	dash_dir = facing if facing.length() > 0.01 else Vector2.DOWN
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
	if nearest and nearest.has_method("interact"):
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
		_flash()
	return dealt

func _flash() -> void:
	if visual == null:
		return
	visual.modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.18)

func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	if visual:
		visual.modulate = Color(0.4, 0.4, 0.4, 0.7)

func revive() -> void:
	state = State.IDLE
	if visual:
		visual.modulate = Color.WHITE
	dash_timer = 0.0

func get_skill_cooldown_ratio(slot: int) -> float:
	if slot < 0 or slot >= skill_cooldowns.size() or character_data == null:
		return 0.0
	if slot >= character_data.skills.size():
		return 0.0
	var skill: Dictionary = character_data.skills[slot]
	var total_cd := maxf(0.01, float(skill.get("cd", 1.0)))
	return clampf(float(skill_cooldowns[slot]) / total_cd, 0.0, 1.0)

func get_skill_cooldown_left(slot: int) -> float:
	if slot < 0 or slot >= skill_cooldowns.size():
		return 0.0
	return float(skill_cooldowns[slot])
