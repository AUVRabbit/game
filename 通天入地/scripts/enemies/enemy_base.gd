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

# ========== 元素克制系统 ==========
# 敌人的主元素（决定伤害倍率和状态免疫）
# 可选值: "water"(水) / "fire"(火) / "thunder"(雷) / "ice"(冰) / "holy"(圣) / "shadow"(幽) / "mech"(机) / "nature"(木) / "physical"(物) / "none"(无)
@export var primary_element: String = "physical"
# 状态免疫：敌人对这些状态完全免疫（即使被施加也不会生效）
# 可选: "stun" / "slow" / "freeze" / "knockback" / "root" / "burn"
@export var status_immune: Array = []
# 自定义元素修正：覆盖默认克制表。例: {"burn": 0.0, "freeze": 2.0}
@export var elemental_mods: Dictionary = {}

var sprite_texture: Texture2D = null
var sprite_content: Rect2i = Rect2i()
var anim: AnimatedSprite2D = null
var _action_frames: SpriteFrames = null
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
	# === 帧动画层（AnimatedSprite2D）===
	var sheet_id := _sheet_asset_id()
	if sheet_id != "":
		_try_attach_animated_sprite(sheet_id, frame_w=96, frame_h=96)
	# === 形变层（SpriteAnim 保留做动态前冲/旋转/呼吸）===
	_anim = SpriteAnim.new()
	_anim.name = "Anim"
	add_child(_anim)
	_anim.setup(self)
	queue_redraw()

func _sheet_asset_id() -> String:
	if is_boss:
		return "enemy_boss"
	match enemy_type:
		"slime":          return "enemy_slime"
		"mech":           return "enemy_mech_spider"
		"wraith":         return "enemy_wraith"
		"skeleton":       return "enemy_skeleton"
		"lava_giant", "fire_elemental": return "enemy_lava_giant"
	return ""

func _try_attach_animated_sprite(sheet_id: String, frame_w: int, frame_h: int) -> void:
	var actions := ["idle", "walk", "attack", "hit"]
	var counts := [4, 4, 3, 2]
	var fps_list := [6, 10, 12, 14]
	var frames := SpriteFramesBuilder.from_asset_id(sheet_id, frame_w, frame_h, actions, counts, fps_list)
	if frames.get_animation_names().size() == 0:
		return
	_action_frames = frames
	anim = AnimatedSprite2D.new()
	anim.name = "FrameAnim"
	anim.sprite_frames = frames
	anim.animation = "idle"
	anim.frame = 0
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# 对齐：让 sprite 的底部锚点落在原点（角色脚踩 ground）
	anim.offset = Vector2(0, float(frame_h) * 0.35)
	add_child(anim)
	# 默认缩放让敌人不会太大/太小
	var fit := float(body_radius * 2.5) / float(maxi(frame_w, frame_h))
	if fit > 0.0:
		anim.scale = Vector2.ONE * fit
	anim.play("idle")

func _set_action(action: String) -> void:
	if anim == null:
		return
	if _action_frames == null or not _action_frames.has_animation(action):
		return
	if anim.animation != action:
		anim.play(action)

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
			"skeleton":
				asset_id = "enemy_skeleton"
			"lava_giant", "fire_elemental":
				asset_id = "enemy_lava_giant"
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
		_set_action("idle")
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = State.ATTACK
		velocity = Vector2.ZERO
		var dir := (player.global_position - global_position).normalized()
		if _anim:
			# 蓄力 → 扑向玩家
			_anim.enter_attack("melee", attack_range * 1.2, 0.4, player.global_position, dir)
		_set_action("attack")
		_try_attack(player)
	elif dist <= detect_range:
		state = State.CHASE
		var dir := (player.global_position - global_position).normalized()
		velocity = dir * move_speed * slow_factor
		move_and_slide()
		_set_action("walk")
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
	_set_action("hit")
	queue_redraw()

	# —— 被击中反馈链（D3 风格）——
	var push_dir := Vector2.ZERO
	if source is Node2D:
		push_dir = (global_position - (source as Node2D).global_position).normalized()
	if push_dir.length() < 0.01:
		push_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	# 1. SpriteAnim 受击
	if _anim:
		var flash_c := Color(1.0, 1.0, 1.0) if is_magic else Color(1.0, 0.6, 0.6)
		_anim.enter_hurt(push_dir, flash_c)

	# 2. 击退（物理层位移）
	if push_dir.length() > 0.01:
		var knock_power := clampf(float(dealt) * 0.12, 4.0, 24.0)
		if not status_immune.has("knockback"):
			global_position += push_dir * knock_power

	# 3. 爆血粒子（敌人中心爆出）
	_spawn_hit_particles(push_dir, is_magic)

	# 4. 震屏（按伤害强度）
	var shake_intensity := clampf(float(dealt) / 30.0, 1.0, 4.0)
	if ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(shake_intensity, 0.06, 40.0)

	# 5. HitStop 命中停顿（越强停越久）
	var stop_dur := clampf(float(dealt) / 300.0, 0.035, 0.09)
	if HitStop and HitStop.has_method("hit"):
		HitStop.hit(stop_dur, shake_intensity)

	if hp <= 0:
		_die()
	return dealt

# —— 生成尸体残留（亡灵召唤的原材料）——
func _spawn_corpse() -> void:
	var level: Node = get_tree().current_scene if get_tree() else null
	if level == null:
		return
	var corpse := preload("res://scripts/enemies/corpse.gd").new()
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
	# 加一点腐化抖动提示
	var tween := corpse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(corpse, "modulate:a", 0.9, 0.6)

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

func is_immune(status_kind: String) -> bool:
	return status_immune.has(status_kind)

func apply_stun(duration: float) -> void:
	if is_immune("stun"):
		if _anim: _anim.flash(Color(1.0, 1.0, 1.0), 0.10)
		return
	stun_left = maxf(stun_left, duration)
	if _anim:
		_anim.flash(Color(1.0, 0.9, 0.5), 0.15)
	queue_redraw()

func apply_slow(factor: float, duration: float) -> void:
	if is_immune("slow") or is_immune("freeze"):
		if _anim: _anim.flash(Color(1.0, 1.0, 1.0), 0.10)
		return
	slow_factor = minf(slow_factor, clampf(factor, 0.1, 1.0))
	slow_left = maxf(slow_left, duration)
	if _anim:
		_anim.flash(Color(0.6, 0.85, 1.0), 0.12)
	queue_redraw()

func apply_mark(duration: float, amp: float) -> void:
	mark_amp = maxf(mark_amp, amp)
	mark_left = maxf(mark_left, duration)
	queue_redraw()

func apply_knockback(push_dir: Vector2, amount: float) -> void:
	if is_immune("knockback"):
		return
	if push_dir.length() > 0.01:
		global_position += push_dir.normalized() * amount

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

	# —— 死亡反馈链（D3 风格）——
	# 1. 大震屏
	if ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(5.0, 0.25, 100.0)

	# 2. 长 HitStop（死亡是最强命中！）
	if HitStop and HitStop.has_method("hit"):
		HitStop.hit(0.09, 3.0)

	# 3. 爆尸体碎片（10+ 个向外飞的彩色碎片 + 向上抛的血珠）
	_spawn_death_particles()

	# 4. 生成尸体残留（亡灵召唤/爆破师材料源）
	_spawn_corpse()

	hp = 0
	# 让死亡动画播放 0.8s 后再清理
	var tree: SceneTree = get_tree()
	if tree:
		tree.create_timer(0.8).timeout.connect(func (): queue_free())

func _spawn_death_particles() -> void:
	var level: Node = get_tree().current_scene if get_tree() else null
	if level == null:
		return
	# 14 个碎片：向外飞 + 重力下落
	var shard_colors := [
		body_color, Color(1.0, 0.4, 0.3), Color(0.9, 0.85, 0.7), Color(1.0, 0.7, 0.5)
	]
	for i in 14:
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
	# 8 个向上抛的"血珠"（如果是火/机元素则是熔岩/金属屑）
	var drop_color := body_color if primary_element == "fire" or primary_element == "mech" else Color(0.95, 0.25, 0.15)
	for i in 8:
		var ang := randf_range(PI * 0.7, PI * 1.3)  # 向上的扇形
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
		# 按 enemy_type 画不同外观
		var t := Time.get_ticks_msec() / 1000.0
		match enemy_type:
			"slime": _draw_slime(fill, t)
			"mech": _draw_mech(fill, t)
			"wraith": _draw_wraith(fill, t)
			"skeleton": _draw_skeleton(fill)
			_: _draw_default_body(fill)
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

# ========== enemy_type 专属外观（没贴图时的程序化 sprite）==========

func _draw_slime(fill: Color, t: float) -> void:
	var s := body_radius
	# 波动黏液身体（随 t 上下变形）
	var wobble := sin(t * 6.0) * 2.0
	var pts := PackedVector2Array()
	for i in 14:
		var ang := float(i) / 14.0 * TAU
		var deform := 1.0 + sin(t * 3.0 + float(i) * 1.3) * 0.12
		var r := s * deform
		pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.7 + wobble))
	draw_colored_polygon(pts, fill)
	# 高光
	var hi_pts := PackedVector2Array()
	for i in 10:
		var ang := float(i) / 10.0 * TAU
		var r := s * 0.5
		hi_pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.5 - 2 + wobble))
	draw_colored_polygon(hi_pts, Color(1, 1, 1, 0.3))
	# 眼睛（2 个黑点 + 高光）
	draw_circle(Vector2(-s * 0.3, -s * 0.1 + wobble), s * 0.18, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(s * 0.3, -s * 0.1 + wobble), s * 0.18, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(-s * 0.25, -s * 0.18 + wobble), s * 0.06, Color.WHITE)
	draw_circle(Vector2(s * 0.35, -s * 0.18 + wobble), s * 0.06, Color.WHITE)

func _draw_mech(fill: Color, t: float) -> void:
	var s := body_radius
	var metal := fill
	var dark := Color(fill.r * 0.5, fill.g * 0.5, fill.b * 0.5)
	var eye_red := Color(1.0, 0.2, 0.15)
	# 身体（六边形装甲）
	var hex := PackedVector2Array()
	for i in 6:
		var ang := float(i) / 6.0 * TAU + PI / 6
		hex.append(Vector2(cos(ang) * s, sin(ang) * s - 2))
	draw_colored_polygon(hex, metal)
	# 内层 darker
	var hex2 := PackedVector2Array()
	for i in 6:
		var ang := float(i) / 6.0 * TAU + PI / 6
		hex2.append(Vector2(cos(ang) * s * 0.65, sin(ang) * s * 0.65 - 2))
	draw_colored_polygon(hex2, dark)
	# 发光眼（2 个红色圆）
	draw_circle(Vector2(-s * 0.25, -s * 0.15 - 2), s * 0.15 * (1.0 + 0.2 * sin(t * 12.0)), eye_red)
	draw_circle(Vector2(s * 0.25, -s * 0.15 - 2), s * 0.15 * (1.0 + 0.2 * sin(t * 12.0)), eye_red)
	# 8 条蜘蛛腿（每条 2 段，动态）
	for i in 8:
		var base_ang := float(i) / 8.0 * TAU + sin(t * 4.0 + float(i) * 0.8) * 0.15
		var p0 := Vector2(cos(base_ang) * s * 0.8, sin(base_ang) * s * 0.8 - 2)
		var p1 := Vector2(cos(base_ang) * (s + 8), sin(base_ang) * (s + 8) - 2)
		var p2 := Vector2(cos(base_ang) * (s + 14), sin(base_ang) * (s + 14) + 4)
		draw_line(p0, p1, metal, 2.0)
		draw_line(p1, p2, dark, 1.5)

func _draw_wraith(fill: Color, t: float) -> void:
	var s := body_radius
	# 半透明飘动影团（多层叠加 + 波浪摆动）
	var float_y := sin(t * 2.0) * 3.0
	# 外层
	draw_circle(Vector2(0, float_y), s * 1.3, Color(fill.r, fill.g, fill.b, 0.18))
	# 中层
	draw_circle(Vector2(0, float_y - 2), s, Color(fill.r, fill.g, fill.b, 0.35))
	# 内核
	draw_circle(Vector2(0, float_y - 3), s * 0.6, Color(fill.r, fill.g, fill.b, 0.6))
	# 红眼
	var pulse := 1.0 + 0.3 * sin(t * 6.0)
	draw_circle(Vector2(-s * 0.25, float_y - 4), s * 0.15 * pulse, Color(1.0, 0.15, 0.2))
	draw_circle(Vector2(s * 0.25, float_y - 4), s * 0.15 * pulse, Color(1.0, 0.15, 0.2))
	# 飘带（3 条半透明尾巴向下飘）
	for i in 3:
		var ang := float(i - 1) * 0.5 + sin(t * 2.5 + float(i)) * 0.3
		var tail_start := Vector2(cos(ang) * s * 0.5, float_y + s * 0.3)
		var tail_end := tail_start + Vector2(cos(ang) * 6, s * 1.2 + sin(t + float(i)) * 3)
		draw_line(tail_start, tail_end, Color(fill.r, fill.g, fill.b, 0.25), s * 0.3)

func _draw_skeleton(fill: Color) -> void:
	var s := body_radius
	var bone := fill
	var dark := Color(fill.r * 0.5, fill.g * 0.5, fill.b * 0.5)
	# 头骨
	draw_circle(Vector2(0, -s * 0.6), s * 0.6, bone)
	draw_circle(Vector2(-s * 0.22, -s * 0.65), s * 0.14, dark)  # 左眼窝
	draw_circle(Vector2(s * 0.22, -s * 0.65), s * 0.14, dark)   # 右眼窝
	draw_line(Vector2(-s * 0.2, -s * 0.35), Vector2(s * 0.2, -s * 0.35), dark, s * 0.1)  # 嘴
	# 脊椎
	draw_line(Vector2(0, -s * 0.1), Vector2(0, s * 0.8), bone, s * 0.18)
	# 肋骨
	draw_line(Vector2(-s * 0.7, s * 0.1), Vector2(s * 0.7, s * 0.1), bone, s * 0.1)
	draw_line(Vector2(-s * 0.55, s * 0.35), Vector2(s * 0.55, s * 0.35), bone, s * 0.08)
	# 腿
	draw_line(Vector2(0, s * 0.8), Vector2(-s * 0.5, s * 1.3), bone, s * 0.14)
	draw_line(Vector2(0, s * 0.8), Vector2(s * 0.5, s * 1.3), bone, s * 0.14)

func _draw_default_body(fill: Color) -> void:
	var s := body_radius
	# 10 边多边形兜底（但加个内部 ring 让它不那么单调）
	var points := PackedVector2Array()
	for i in 10:
		var a := TAU * float(i) / 10.0
		points.append(Vector2(cos(a), sin(a) * 0.85) * s)
	draw_colored_polygon(points, fill)
	# 内部 ring（让它看起来不那么平）
	draw_arc(Vector2.ZERO, s * 0.5, 0, TAU, 18, Color(fill.r * 0.6, fill.g * 0.6, fill.b * 0.6), 2.0)
