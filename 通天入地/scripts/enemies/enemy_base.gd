# ============================================================
# EnemyBase — 敌人基类
# 状态机 AI：巡逻 → 追击 → 攻击；掉落金币/经验/物品
# 内置通用动画控制器（sprite_anim.gd），纯代码形变实现移动/攻击/受击/死亡。
# ============================================================

extends CharacterBody2D
class_name EnemyBase

enum State { PATROL, CHASE, ATTACK, DEAD }

@export var enemy_name: String = "史莱姆"
@export var enemy_type: String = "slime"
@export var max_hp: int = 40
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
@export var is_boss: bool = false
@export var body_color: Color = Color(0.4, 0.8, 0.5)
@export var body_radius: float = 16.0

var sprite_texture: Texture2D = null
var sprite_content: Rect2i = Rect2i()
var hp: int = 40
var state: State = State.PATROL
var attack_timer: float = 0.0
var patrol_target: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var spawn_point: Vector2 = Vector2.ZERO
var last_attacker: Node = null
var flash_timer: float = 0.0
var stun_left: float = 0.0
var slow_left: float = 0.0
var slow_factor: float = 1.0
var mark_left: float = 0.0
var mark_amp: float = 0.0

var _anim: SpriteAnim = null
var _drawn_sprite_rect: Rect2 = Rect2()
var visual_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	spawn_point = global_position
	patrol_target = spawn_point
	if RoguelikeManager and RoguelikeManager.is_active:
		var power := RoguelikeManager.enemy_power()
		attack = int(round(attack * power))
		max_hp = int(round(max_hp * RoguelikeManager.hp_scale()))
	hp = max_hp
	if is_boss:
		body_radius = 28.0
		move_speed *= 0.8
	sprite_texture = _load_sprite()
	# 动画控制器：驱动 Node2D 自身的位置/缩放/旋转（由 _draw 绘制贴图）
	_anim = SpriteAnim.new()
	_anim.name = "Anim"
	add_child(_anim)
	_anim.setup(self)
	queue_redraw()

func _load_sprite() -> Texture2D:
	var asset_id := ""
	if is_boss:
		asset_id = "enemy_boss"
	else:
		match enemy_type:
			"slime":
				asset_id = "enemy_slime"
			"mech":
				asset_id = "enemy_mech_spider"
			"wraith":
				asset_id = "enemy_wraith"
			_:
				asset_id = ""
	if asset_id == "":
		return null
	var tex := AssetLibrary.texture(asset_id)
	if tex == null:
		return null
	sprite_content = _content_rect(tex)
	return tex

# 取贴图里不透明内容的包围盒（用于把角色对齐到地面）
func _content_rect(tex: Texture2D) -> Rect2i:
	var img: Image = tex.get_image()
	if img == null:
		return Rect2i()
	if img.is_compressed():
		if img.decompress() != OK:
			return Rect2i()
	return img.get_used_rect()

func _physics_process(delta: float) -> void:
	if hp <= 0:
		if _anim and _anim.state != SpriteAnim.AnimState.DEAD:
			_anim.enter_dead()
		return
	if GameManager and GameManager.is_input_blocked():
		velocity = Vector2.ZERO
		return
	if attack_timer > 0.0:
		attack_timer = maxf(0.0, attack_timer - delta)
	if flash_timer > 0.0:
		flash_timer = maxf(0.0, flash_timer - delta)
	if stun_left > 0.0:
		stun_left = maxf(0.0, stun_left - delta)
	if slow_left > 0.0:
		slow_left = maxf(0.0, slow_left - delta)
	else:
		slow_factor = 1.0
	if mark_left > 0.0:
		mark_left = maxf(0.0, mark_left - delta)
	else:
		mark_amp = 0.0
	if flash_timer > 0.0 or stun_left > 0.0 or mark_left > 0.0:
		queue_redraw()
	if stun_left > 0.0:
		velocity = Vector2.ZERO
		if _anim:
			_anim.settle_to(SpriteAnim.AnimState.IDLE, Vector2.DOWN)
		return

	var player := _find_player()
	if player == null:
		_do_patrol(delta)
		if _anim:
			_anim.settle_to(SpriteAnim.AnimState.IDLE, Vector2.DOWN)
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = State.ATTACK
		velocity = Vector2.ZERO
		var dir := (player.global_position - global_position).normalized()
		if _anim:
			# 蓄力 → 扑向玩家
			_anim.enter_attack("melee", attack_range * 1.2, 0.4, player.global_position, dir)
		_try_attack(player)
	elif dist <= detect_range:
		state = State.CHASE
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * move_speed * slow_factor
		move_and_slide()
		if _anim:
			_anim.settle_to(SpriteAnim.AnimState.RUN, dir, velocity.length())
	else:
		_do_patrol(delta)
		if _anim:
			_anim.settle_to(SpriteAnim.AnimState.RUN, velocity.normalized(), velocity.length())

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

func take_damage(amount: int, is_magic: bool = false, source: Node = null) -> int:
	if hp <= 0:
		return 0
	if source:
		last_attacker = source
	var def := magic_defense if is_magic else defense
	var dealt := maxi(1, amount - def)
	if mark_left > 0.0 and mark_amp > 0.0:
		dealt = int(round(float(dealt) * (1.0 + mark_amp)))
	hp = maxi(0, hp - dealt)
	flash_timer = 0.12
	queue_redraw()
	# 被击中动画反馈
	if _anim:
		var push_dir := Vector2.ZERO
		if source is Node2D:
			push_dir = (global_position - (source as Node2D).global_position).normalized()
		if push_dir.length() < 0.01:
			push_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var flash_c := Color(1.0, 1.0, 1.0) if is_magic else Color(1.0, 0.6, 0.6)
		_anim.enter_hurt(push_dir, flash_c)
	if ScreenShake and ScreenShake.has_method("micro"):
		ScreenShake.micro()
	if hp <= 0:
		_die()
	return dealt

func apply_stun(duration: float) -> void:
	stun_left = maxf(stun_left, duration)
	if _anim:
		_anim.flash(Color(1.0, 0.9, 0.5), 0.15)
	queue_redraw()

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = minf(slow_factor, clampf(factor, 0.1, 1.0))
	slow_left = maxf(slow_left, duration)
	if _anim:
		_anim.flash(Color(0.6, 0.85, 1.0), 0.12)
	queue_redraw()

func apply_mark(duration: float, amp: float) -> void:
	mark_amp = maxf(mark_amp, amp)
	mark_left = maxf(mark_left, duration)
	queue_redraw()

func _die() -> void:
	state = State.DEAD
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
	EventBus.enemy_died.emit(self, killer)
	if ScreenShake and ScreenShake.has_method("micro"):
		ScreenShake.micro()
	hp = 0
	# 让死亡动画播放 0.8s 后再清理
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

func _draw() -> void:
	if visual_offset != Vector2.ZERO:
		draw_set_transform(visual_offset, 0.0, Vector2.ONE)
	var fill := body_color
	if flash_timer > 0.0:
		fill = Color(1.0, 1.0, 1.0)
	if sprite_texture:
		var tint := Color(1, 1, 1, 1)
		if flash_timer > 0.0:
			tint = Color(1.6, 1.6, 1.6, 1)
		var src := sprite_content
		if src.size.x <= 0 or src.size.y <= 0:
			src = Rect2i(Vector2i.ZERO, sprite_texture.get_size())
		var fit := body_radius * 2.6
		var factor: float = fit / float(maxi(src.size.x, src.size.y))
		var dest_size := Vector2(src.size) * factor
		var dest := Rect2(-dest_size.x * 0.5, -dest_size.y + body_radius * 0.6, dest_size.x, dest_size.y)
		_drawn_sprite_rect = dest
		draw_texture_rect_region(sprite_texture, dest, src, tint)
	else:
		if is_boss:
			draw_circle(Vector2.ZERO, body_radius + 6.0, Color(fill.r, fill.g, fill.b, 0.25))
		var points := PackedVector2Array()
		var sides := 10
		for i in sides:
			var a := TAU * float(i) / float(sides)
			points.append(Vector2(cos(a), sin(a) * 0.85) * body_radius)
		draw_colored_polygon(points, fill)
	# 状态指示：眩晕（黄环）/ 标记（红环）
	if stun_left > 0.0:
		draw_arc(Vector2.ZERO, body_radius + 9.0, 0.0, TAU, 22, Color(1.0, 0.85, 0.3, 0.9), 2.0)
	if mark_left > 0.0:
		draw_arc(Vector2.ZERO, body_radius + 5.0, 0.0, TAU, 22, Color(1.0, 0.3, 0.35, 0.95), 2.5)
	# 血条
	var bar_w := body_radius * 2.4
	var bar_pos := Vector2(-bar_w * 0.5, -body_radius - 14.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, 5.0)), Color(0.1, 0.1, 0.12, 0.85))
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, 5.0)), Color(0.9, 0.25, 0.25))
