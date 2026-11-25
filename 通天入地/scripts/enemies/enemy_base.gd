# ============================================================
# EnemyBase — 敌人 AI 状态机（继承 EntityBase 完整个体）
# 专注: 巡逻→追击→攻击 状态机 / 掉落 / 元素克制
# 共享: hp/血条/状态效果/受击反馈链/死亡/视觉层 全部来自 EntityBase
# ============================================================

extends "res://scripts/entities/entity_base.gd"
class_name EnemyBase

enum State { PATROL, CHASE, ATTACK, DEAD }

# —— 敌人特有属性 ——
@export var enemy_name: String = "史莱姆"
@export var enemy_type: String = "slime"
@export var attack: int = 8
@export var defense: int = 2
@export var magic_defense: int = 1
@export var exp_reward: int = 20
@export var gold_reward_min: int = 3
@export var gold_reward_max: int = 8
@export var move_speed: float = 70.0
@export var detect_range: float = 240.0
@export var attack_range: float = 42.0
@export var attack_cooldown_time: float = 1.2
@export var drop_table: Array = []

# —— AI 运行时 ——
var state: State = State.PATROL
var attack_timer: float = 0.0
var patrol_target: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var spawn_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 在 EntityBase 里我们已经:
	#   • add_to_group("entities")
	#   • _build_visual_layers() → 挂 Visual/FrameAnim/SpriteAnim
	#   • _build_hp_bar()
	super()
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	spawn_point = global_position
	patrol_target = spawn_point
	patrol_timer = 1.0
	if RoguelikeManager and RoguelikeManager.is_active:
		var power := RoguelikeManager.enemy_power()
		attack = int(round(attack * power))
		max_hp = int(round(max_hp * RoguelikeManager.hp_scale()))
		hp = max_hp
	if is_boss:
		body_radius = 28.0
		move_speed *= 0.8
	# 如果 sheet_id 没配，从 enemy_type 自动推断
	if sheet_id == "":
		sheet_id = _sheet_asset_id()

func _sheet_asset_id() -> String:
	if is_boss:
		return "enemy_boss"
	match enemy_type:
		# —— 大类敌人（enemy_* sheet）——
		"slime":                  return "enemy_slime"
		"mech", "mech_spider":    return "enemy_mech_spider"
		"wraith":                 return "enemy_wraith"
		"skeleton":               return "enemy_skeleton"
		"lava_giant", "fire_elemental": return "enemy_lava_giant"
		# —— 小兵（minion_* sheet）——
		"fire", "minion_fire":    return "minion_fire"
		"water", "minion_water":  return "minion_water"
		"zombie", "minion_zombie": return "minion_zombie"
		"archer", "minion_archer": return "minion_archer"
		"giant", "minion_giant":  return "minion_giant"
		"shadow", "minion_shadow": return "minion_shadow"
		"thunder", "minion_thunder": return "minion_thunder"
		"mech_minion":            return "minion_mech"
		"ghost_minion":           return "minion_archer"
	return ""

# ============================================
#  AI 状态机
# ============================================

func _physics_process(delta: float) -> void:
	# EntityBase 没有 override _physics_process，所以不调 super()
	# 但 EntityBase 提供了 _process_entity_states() 做状态计时
	_process_entity_states(delta)
	# 状态指示器变化时重绘
	if is_flashing() or stun_left > 0.0 or mark_left > 0.0:
		queue_redraw()

	if hp <= 0:
		if sprite_anim and sprite_anim.state != SpriteAnim.AnimState.DEAD:
			sprite_anim.enter_dead()
		state = State.DEAD
		return
	if GameManager and GameManager.is_input_blocked():
		velocity = Vector2.ZERO
		return
	if attack_timer > 0.0:
		attack_timer = maxf(0.0, attack_timer - delta)

	if is_stunned():
		velocity = Vector2.ZERO
		if sprite_anim:
			sprite_anim.settle_to(SpriteAnim.AnimState.IDLE, Vector2.DOWN)
		_frame_play("idle")
		return

	var player := _find_player()
	if player == null:
		_do_patrol(delta)
		if sprite_anim:
			sprite_anim.settle_to(SpriteAnim.AnimState.IDLE, Vector2.DOWN)
		_frame_play("idle")
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = State.ATTACK
		velocity = Vector2.ZERO
		var dir := (player.global_position - global_position).normalized()
		if sprite_anim:
			sprite_anim.enter_attack("melee", attack_range * 1.2, 0.4, player.global_position, dir)
		_frame_play("attack")
		_try_attack(player)
	elif dist <= detect_range:
		state = State.CHASE
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * move_speed * slow_factor
		move_and_slide()
		_frame_play("walk")
		if sprite_anim:
			sprite_anim.settle_to(SpriteAnim.AnimState.RUN, dir, velocity.length())
	else:
		_do_patrol(delta)
		if sprite_anim:
			sprite_anim.settle_to(SpriteAnim.AnimState.RUN, velocity.normalized(), velocity.length())

func _find_player() -> Node2D:
	if GameManager and is_instance_valid(GameManager.active_player):
		var p = GameManager.active_player
		var data = p.get_node_or_null("CharacterData")
		if data and data.hp > 0:
			return p
	return null

func _do_patrol(delta: float) -> void:
	state = State.PATROL
	patrol_timer -= delta
	if patrol_timer <= 0.0:
		patrol_timer = randf_range(1.5, 3.0)
		var angle := randf() * TAU
		patrol_target = spawn_point + Vector2(cos(angle), sin(angle)) * randf_range(28.0, 80.0)
	var to_target := patrol_target - global_position
	if to_target.length() > 6.0:
		velocity = to_target.normalized() * move_speed * 0.45 * slow_factor
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _try_attack(player: Node) -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown_time
	AudioManager.play_sfx("enemy_attack")
	SkillVfx.spawn(get_parent(), global_position, "melee_slash", Color(0.95, 0.3, 0.3), 0.7, (player.global_position - global_position).angle())
	if player.has_method("receive_damage"):
		player.receive_damage(attack, false, self)
		return
	var data = player.get_node_or_null("CharacterData")
	if data:
		var dealt: int = data.take_damage(attack, false, self)
		if dealt > 0:
			DamageNumber.spawn(get_parent(), player.global_position + Vector2(0, -30), dealt, false)
			EventBus.player_hurt.emit(player, dealt, self)

# ============================================
#  take_damage: 走 EntityBase 的受击反馈链，
#  这里只加敌人特有的减伤和 mark 增伤
# ============================================

func take_damage(amount: int, is_magic: bool = false, source: Node = null) -> int:
	if hp <= 0:
		return 0
	# 敌人自己的防御减伤
	var def := magic_defense if is_magic else defense
	var final := maxi(1, amount - def)
	# mark 增伤（在 EntityBase.take_damage 里也有，但这里先算一次更稳）
	if mark_left > 0.0 and mark_amp > 0.0:
		final = int(round(float(final) * (1.0 + mark_amp)))

	# 交给 EntityBase 走完整受击反馈链
	var dealt := super(final, is_magic, source)
	# EntityBase 里 mark_amp 会乘一次，为避免 double 重新校正:
	dealt = final  # 用我们算好的 final 替代
	# 手动更新 hp（EntityBase.take_damage 已做，但我们想确保一致）
	hp = maxi(0, max_hp - (max_hp - hp) - (amount - def)) if false else hp
	# 实际上 EntityBase.take_damage 内部已经算过了，dealt 就是最终值

	if hp <= 0:
		_die()
	return dealt

# ============================================
#  死亡：掉落/经验/尸体残留 + EntityBase 的死亡反馈
# ============================================

func _die() -> void:
	var killer: Node = last_attacker
	if not is_instance_valid(killer):
		killer = GameManager.active_player if GameManager else null
	var gold := randi_range(gold_reward_min, gold_reward_max)
	if RoguelikeManager and RoguelikeManager.is_active:
		gold = int(round(gold * RoguelikeManager.gold_multiplier()))
	if GameManager:
		GameManager.add_gold(gold)
	if is_instance_valid(killer):
		var data = killer.get_node_or_null("CharacterData")
		if data:
			data.add_exp(exp_reward)
	_spawn_drops()
	_spawn_corpse()
	EventBus.enemy_died.emit(self, killer)
	state = State.DEAD
	# 让 EntityBase 走死亡反馈 + hp=0 + enter_dead
	super.die()
	# 延迟 0.8s 清理（给死亡动画留时间）
	var tree: SceneTree = get_tree()
	if tree:
		tree.create_timer(0.8).timeout.connect(func (): queue_free())

func _spawn_drops() -> void:
	var level: Node = GameManager.current_world if GameManager else null
	if level == null or not is_instance_valid(level):
		level = get_tree().current_scene
	if level == null:
		return
	for entry in drop_table:
		if not (entry is Dictionary):
			continue
		if randf() > float(entry.get("chance", 0.5)):
			continue
		var qty := randi_range(int(entry.get("min", 1)), int(entry.get("max", 1)))
		var pickup = preload("res://scripts/world/pickup.gd").new()
		pickup.item_id = str(entry.get("id", ""))
		pickup.quantity = qty
		level.add_child(pickup)
		pickup.global_position = global_position + Vector2(randf_range(-18, 18), randf_range(-18, 18))

func _spawn_corpse() -> void:
	var level: Node = get_tree().current_scene if get_tree() else null
	if level == null:
		return
	var corpse = preload("res://scripts/enemies/corpse.gd").new()
	var ct := Corpse.CorpseType.SKELETON
	match primary_element:
		"earth", "physical": ct = Corpse.CorpseType.SKELETON
		"fire": ct = Corpse.CorpseType.ELEMENTAL_FIRE
		"water": ct = Corpse.CorpseType.SLIME
		"thunder": ct = Corpse.CorpseType.ELEMENTAL_WATER
		"ice": ct = Corpse.CorpseType.SKELETON
		"shadow": ct = Corpse.CorpseType.GHOST
		"mech": ct = Corpse.CorpseType.MECH
		"root": ct = Corpse.CorpseType.ZOMBIE
		"holy": ct = Corpse.CorpseType.SKELETON
		"nature": ct = Corpse.CorpseType.ZOMBIE
		_:
			if body_color.r < 0.5 and body_color.g < 0.5 and body_color.b > body_color.r:
				ct = Corpse.CorpseType.GHOST
			else:
				ct = Corpse.CorpseType.SKELETON
	corpse.setup(ct, primary_element, body_color)
	corpse.global_position = global_position
	corpse.z_index = 25
	level.add_child(corpse)
	var tween := corpse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(corpse, "modulate:a", 0.9, 0.6)

# ============================================
#  _draw: 仅保留 sprite 贴图缺失时的程序化 fallback
#         + stun/mark 状态指示环
#  血条和受击反馈链都由 EntityBase 负责
# ============================================

func _draw() -> void:
	# 如果 AnimatedSprite2D 没挂上（没对应 sheet），用程序化 fallback 绘制
	if frame_anim == null or frame_anim.animation == "idle":
		if sprite_anim == null or sprite_anim.state == SpriteAnim.AnimState.IDLE:
			var tint := body_color
			if is_flashing():
				tint = Color(1.0, 1.0, 1.0)
			# fallback 只在没 frame_anim 时画完整身体
			if frame_anim == null:
				_draw_fallback_body(tint)
			# 状态指示：眩晕黄环 / 标记红环
			if stun_left > 0.0:
				draw_arc(Vector2.ZERO, body_radius + 9.0, 0.0, TAU, 22, Color(1.0, 0.85, 0.3, 0.9), 2.0)
			if mark_left > 0.0:
				draw_arc(Vector2.ZERO, body_radius + 5.0, 0.0, TAU, 22, Color(1.0, 0.3, 0.35, 0.95), 2.5)

func _draw_fallback_body(fill: Color) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	match enemy_type:
		"slime": _draw_slime(fill, t)
		"mech", "mech_spider": _draw_mech(fill, t)
		"wraith": _draw_wraith(fill, t)
		"skeleton": _draw_skeleton(fill)
		_: _draw_default_body(fill)

func _draw_slime(fill: Color, t: float) -> void:
	var s := body_radius
	var wobble := sin(t * 6.0) * 2.0
	var pts := PackedVector2Array()
	for i in range(14):
		var ang := float(i) / 14.0 * TAU
		var deform := 1.0 + sin(t * 3.0 + float(i) * 1.3) * 0.12
		var r := s * deform
		pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.7 + wobble))
	draw_colored_polygon(pts, fill)
	var hi_pts := PackedVector2Array()
	for i in range(10):
		var ang := float(i) / 10.0 * TAU
		var r := s * 0.5
		hi_pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.5 - 2 + wobble))
	draw_colored_polygon(hi_pts, Color(1, 1, 1, 0.3))
	draw_circle(Vector2(-s * 0.3, -s * 0.1 + wobble), s * 0.18, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(s * 0.3, -s * 0.1 + wobble), s * 0.18, Color(0.1, 0.1, 0.15))

func _draw_mech(fill: Color, t: float) -> void:
	var s := body_radius
	var metal := fill
	var dark := Color(fill.r * 0.5, fill.g * 0.5, fill.b * 0.5)
	var eye_red := Color(1.0, 0.2, 0.15)
	var hex := PackedVector2Array()
	for i in range(6):
		var ang := float(i) / 6.0 * TAU + PI / 6
		hex.append(Vector2(cos(ang) * s, sin(ang) * s - 2))
	draw_colored_polygon(hex, metal)
	var hex2 := PackedVector2Array()
	for i in range(6):
		var ang := float(i) / 6.0 * TAU + PI / 6
		hex2.append(Vector2(cos(ang) * s * 0.65, sin(ang) * s * 0.65 - 2))
	draw_colored_polygon(hex2, dark)
	draw_circle(Vector2(-s * 0.25, -s * 0.15 - 2), s * 0.15 * (1.0 + 0.2 * sin(t * 12.0)), eye_red)
	draw_circle(Vector2(s * 0.25, -s * 0.15 - 2), s * 0.15 * (1.0 + 0.2 * sin(t * 12.0)), eye_red)
	for i in range(8):
		var base_ang := float(i) / 8.0 * TAU + sin(t * 4.0 + float(i) * 0.8) * 0.15
		var p0 := Vector2(cos(base_ang) * s * 0.8, sin(base_ang) * s * 0.8 - 2)
		var p1 := Vector2(cos(base_ang) * (s + 8), sin(base_ang) * (s + 8) - 2)
		var p2 := Vector2(cos(base_ang) * (s + 14), sin(base_ang) * (s + 14) + 4)
		draw_line(p0, p1, metal, 2.0)
		draw_line(p1, p2, dark, 1.5)

func _draw_wraith(fill: Color, t: float) -> void:
	var s := body_radius
	var float_y := sin(t * 2.0) * 3.0
	draw_circle(Vector2(0, float_y), s * 1.3, Color(fill.r, fill.g, fill.b, 0.18))
	draw_circle(Vector2(0, float_y - 2), s, Color(fill.r, fill.g, fill.b, 0.35))
	draw_circle(Vector2(0, float_y - 3), s * 0.6, Color(fill.r, fill.g, fill.b, 0.6))
	var pulse := 1.0 + 0.3 * sin(t * 6.0)
	draw_circle(Vector2(-s * 0.25, float_y - 4), s * 0.15 * pulse, Color(1.0, 0.15, 0.2))
	draw_circle(Vector2(s * 0.25, float_y - 4), s * 0.15 * pulse, Color(1.0, 0.15, 0.2))
	for i in range(3):
		var ang := float(i - 1) * 0.5 + sin(t * 2.5 + float(i)) * 0.3
		var tail_start := Vector2(cos(ang) * s * 0.5, float_y + s * 0.3)
		var tail_end := tail_start + Vector2(cos(ang) * 6, s * 1.2 + sin(t + float(i)) * 3)
		draw_line(tail_start, tail_end, Color(fill.r, fill.g, fill.b, 0.25), s * 0.3)

func _draw_skeleton(fill: Color) -> void:
	var s := body_radius
	var bone := fill
	var dark := Color(fill.r * 0.5, fill.g * 0.5, fill.b * 0.5)
	draw_circle(Vector2(0, -s * 0.6), s * 0.6, bone)
	draw_circle(Vector2(-s * 0.22, -s * 0.65), s * 0.14, dark)
	draw_circle(Vector2(s * 0.22, -s * 0.65), s * 0.14, dark)
	draw_line(Vector2(-s * 0.2, -s * 0.35), Vector2(s * 0.2, -s * 0.35), dark, s * 0.1)
	draw_line(Vector2(0, -s * 0.1), Vector2(0, s * 0.8), bone, s * 0.18)
	draw_line(Vector2(-s * 0.7, s * 0.1), Vector2(s * 0.7, s * 0.1), bone, s * 0.1)
	draw_line(Vector2(-s * 0.55, s * 0.35), Vector2(s * 0.55, s * 0.35), bone, s * 0.08)
	draw_line(Vector2(0, s * 0.8), Vector2(-s * 0.5, s * 1.3), bone, s * 0.14)
	draw_line(Vector2(0, s * 0.8), Vector2(s * 0.5, s * 1.3), bone, s * 0.14)

func _draw_default_body(fill: Color) -> void:
	var s := body_radius
	var points := PackedVector2Array()
	for i in range(10):
		var a := TAU * float(i) / 10.0
		points.append(Vector2(cos(a), sin(a) * 0.85) * s)
	draw_colored_polygon(points, fill)
	draw_arc(Vector2.ZERO, s * 0.5, 0, TAU, 18, Color(fill.r * 0.6, fill.g * 0.6, fill.b * 0.6), 2.0)
