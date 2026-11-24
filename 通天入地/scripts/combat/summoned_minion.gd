# ============================================================
# SummonedMinion — 召唤物（8 种完全不同的外观 + 类型专属能力）
# ============================================================

extends CharacterBody2D
class_name SummonedMinion

enum Type { GHOST, ZOMBIE, FIRE, WATER, THUNDER, MECH, SHADOW, GIANT }

var lifetime: float = 12.0
var damage: int = 10
var is_magic: bool = true
var move_speed: float = 120.0
var attack_range: float = 40.0
var attack_interval: float = 1.0
var detect_range: float = 420.0
var source: Node = null
var color: Color = Color(0.62, 0.45, 0.95)
var body_scale: float = 1.0
var special_ability: String = ""
var minion_type: String = "ghost"

var attack_timer: float = 0.0
var target: Node2D = null
var pulse: float = 0.0
var lifetime_left: float = 0.0
var attack_flash: float = 0.0
var _facing: Vector2 = Vector2.DOWN

func _ready() -> void:
	add_to_group("summons")
	collision_layer = 0
	collision_mask = 0
	z_index = 1
	lifetime_left = lifetime

func _physics_process(delta: float) -> void:
	pulse += delta
	lifetime_left -= delta
	if attack_flash > 0.0:
		attack_flash -= delta
	if lifetime_left <= 0.0:
		_fade_out()
		return
	if attack_timer > 0.0:
		attack_timer = maxf(0.0, attack_timer - delta)
	if target != null and not is_instance_valid(target):
		target = null
	if target == null:
		target = _nearest_enemy()
	if target == null:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var to_target: Vector2 = target.global_position - global_position
	_facing = to_target.normalized()
	var dist := to_target.length()
	var rng := _attack_range()
	if dist > rng:
		velocity = to_target.normalized() * _move_speed()
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			attack_flash = 0.15
			_attack(target)
	queue_redraw()

func _attack_range() -> float:
	if minion_type == "ghost" or minion_type == "fire" or minion_type == "thunder":
		return 180.0
	if minion_type == "water":
		return 120.0
	return attack_range

func _move_speed() -> float:
	if minion_type == "shadow":
		return move_speed * 1.6
	if minion_type == "giant":
		return move_speed * 0.75
	if minion_type == "zombie":
		return move_speed * 0.85
	return move_speed

func _attack(enemy: Node) -> void:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return
	var dmg_mult := 1.0
	var magic := is_magic
	if minion_type == "ghost":
		magic = true; dmg_mult = 1.0
	elif minion_type == "zombie":
		magic = false; dmg_mult = 1.4
	elif minion_type == "fire":
		magic = true; dmg_mult = 1.35
	elif minion_type == "water":
		magic = true; dmg_mult = 1.0
	elif minion_type == "thunder":
		magic = true; dmg_mult = 1.3
	elif minion_type == "mech":
		magic = false; dmg_mult = 1.25
	elif minion_type == "shadow":
		magic = true; dmg_mult = 1.5
	elif minion_type == "giant":
		magic = false; dmg_mult = 2.0
	var dealt: int = enemy.take_damage(int(damage * dmg_mult), magic, source)
	var parent := get_parent()
	if parent == null:
		parent = get_tree().root
	DamageNumber.spawn(parent, enemy.global_position + Vector2(0, -26), dealt, false)
	_spawn_attack_fx(parent, enemy.global_position)

func _spawn_attack_fx(level: Node, pos: Vector2) -> void:
	if minion_type == "thunder":
		var pts := PackedVector2Array([global_position, pos])
		SkillVfx.spawn_chain_lightning(level, pts, color)
	elif minion_type == "fire":
		SkillVfx.spawn_burst(level, pos, 28.0, Color(1.0, 0.45, 0.15), 0.4)
	elif minion_type == "shadow":
		SkillVfx.spawn_burst(level, pos, 20.0, Color(0.35, 0.15, 0.5), 0.3)
	elif minion_type == "giant":
		SkillVfx.spawn_shockwave(level, pos, 60.0, color, 0.4)
	else:
		SkillVfx.spawn_impact(level, pos, "void_pulse", color)

func _nearest_enemy():
	var best = null
	var best_d := detect_range
	var tree := get_tree()
	if tree == null:
		return null
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var d: float = global_position.distance_to((e as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _fade_out() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

# ============ 绘制：8 种完全不同的外观 ============

func _draw() -> void:
	var s := body_scale
	var life_ratio := clampf(lifetime_left / maxf(lifetime, 0.01), 0.0, 1.0)
	draw_arc(Vector2(0, 20 * s), 14.0 * s, -PI * 0.5, -PI * 0.5 + TAU * life_ratio,
			24, Color(color.r, color.g, color.b, 0.55), 1.8)
	if attack_flash > 0.0:
		var flash_a := attack_flash / 0.15
		draw_arc(Vector2.ZERO, 40.0 * s, 0, TAU, 32, Color(1, 1, 1, flash_a * 0.4), 3.0)
	if minion_type == "ghost":
		_draw_archer(s)
	elif minion_type == "zombie":
		_draw_tank(s)
	elif minion_type == "fire":
		_draw_fire_spirit(s)
	elif minion_type == "water":
		_draw_water_element(s)
	elif minion_type == "thunder":
		_draw_thunder_spirit(s)
	elif minion_type == "mech":
		_draw_mech_ghost(s)
	elif minion_type == "shadow":
		_draw_shadow_assassin(s)
	elif minion_type == "giant":
		_draw_giant_undead(s)
	else:
		_draw_basic_ghost(s)

# —— 1. 骷髅弓手 ghost ——
func _draw_archer(s: float) -> void:
	var bone := Color(0.86, 0.84, 0.76)
	var dark_eye := Color(0.1, 0.05, 0.12)
	draw_circle(Vector2(0, -18 * s), 7.0 * s, bone)
	draw_circle(Vector2(-3 * s, -19 * s), 2.0 * s, dark_eye)
	draw_circle(Vector2(3 * s, -19 * s), 2.0 * s, dark_eye)
	draw_line(Vector2(0, -11 * s), Vector2(0, 4 * s), bone, 3.0 * s)
	draw_line(Vector2(0, -6 * s), Vector2(-9 * s, 0), bone, 2.0)
	draw_line(Vector2(0, -6 * s), Vector2(9 * s, 0), bone, 2.0)
	draw_line(Vector2(0, 4 * s), Vector2(-6 * s, 12 * s), bone, 2.0)
	draw_line(Vector2(0, 4 * s), Vector2(6 * s, 12 * s), bone, 2.0)
	# 弓 + 箭
	var bx := _facing.x * 8 * s
	var by := _facing.y * 6 * s
	draw_arc(Vector2(bx, by), 10.0 * s, -1.2, 1.2, 12, Color(0.55, 0.35, 0.15), 2.0 * s)
	draw_line(Vector2(bx, by), Vector2(bx + _facing.x * 12 * s, by + _facing.y * 12 * s),
			Color(0.7, 0.5, 0.3), 1.5)

# —— 2. 丧尸坦克 zombie ——
func _draw_tank(s: float) -> void:
	var flesh := Color(0.45, 0.55, 0.35)
	var dark_flesh := Color(0.3, 0.38, 0.25)
	var eye_red := Color(0.9, 0.15, 0.1)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14 * s, -2 * s), Vector2(-10 * s, -16 * s),
		Vector2(10 * s, -16 * s), Vector2(14 * s, -2 * s),
		Vector2(12 * s, 12 * s), Vector2(-12 * s, 12 * s)
	]), flesh)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8 * s, -22 * s), Vector2(8 * s, -22 * s),
		Vector2(7 * s, -14 * s), Vector2(-7 * s, -14 * s)
	]), dark_flesh)
	draw_circle(Vector2(-3 * s, -18 * s), 1.5 * s, eye_red)
	draw_circle(Vector2(3 * s, -18 * s), 1.5 * s, eye_red)
	draw_line(Vector2(-10 * s, 12 * s), Vector2(-4 * s, 20 * s), dark_flesh, 3.0)
	draw_line(Vector2(10 * s, 12 * s), Vector2(4 * s, 20 * s), dark_flesh, 3.0)

# —— 3. 火焰精灵 fire ——
func _draw_fire_spirit(s: float) -> void:
	var orange := Color(1.0, 0.45, 0.15)
	var yellow := Color(1.0, 0.85, 0.2)
	var t := pulse * 8.0
	draw_arc(Vector2.ZERO, 18 * s + sin(t) * 2, 0, TAU, 24,
			Color(orange.r, orange.g, orange.b, 0.25), 8 * s)
	draw_arc(Vector2.ZERO, 12 * s, 0, TAU, 20,
			Color(orange.r, orange.g, orange.b, 0.5), 6 * s)
	draw_circle(Vector2.ZERO, 5 * s + sin(t * 2) * 0.5, Color(1.0, 0.95, 0.7))
	var dir := -_facing
	for i in range(3):
		var perp := Vector2(-dir.y, dir.x).rotated(randf_range(-0.3, 0.3))
		var length := 14 * s + sin(t + i * 2) * 3
		draw_line(Vector2.ZERO, dir * length + perp * 6 * s * sin(t + i), yellow, 2.5 * s)

# —— 4. 水元素 water ——
func _draw_water_element(s: float) -> void:
	var blue := Color(0.35, 0.65, 0.95)
	var light_blue := Color(0.6, 0.82, 1.0)
	var t := pulse * 4.0
	var pts := PackedVector2Array()
	for i in range(16):
		var ang := float(i) / 16.0 * TAU
		var wobble := sin(t + float(i) * 1.5) * 2.0
		var r := 14 * s + wobble
		pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.7 - 4 * s))
	draw_colored_polygon(pts, blue)
	var pts2 := PackedVector2Array()
	for i in range(12):
		var ang := float(i) / 12.0 * TAU
		var r := 10 * s + sin(t + float(i)) * 1.5
		pts2.append(Vector2(cos(ang) * r, sin(ang) * r * 0.6 - 5 * s))
	draw_colored_polygon(pts2, light_blue)
	draw_circle(Vector2(-4 * s, -4 * s), 2.5 * s, Color(0.15, 0.25, 0.4))
	draw_circle(Vector2(4 * s, -4 * s), 2.5 * s, Color(0.15, 0.25, 0.4))

# —— 5. 雷电精灵 thunder ——
func _draw_thunder_spirit(s: float) -> void:
	var white := Color(0.95, 0.98, 1.0)
	var blue := Color(0.6, 0.8, 1.0)
	var t := pulse * 18.0
	var flash := 1.0 if sin(t) > 0 else 0.6
	draw_circle(Vector2.ZERO, 6 * s * flash, white)
	draw_circle(Vector2.ZERO, 10 * s, Color(blue.r, blue.g, blue.b, 0.4 * flash))
	for branch in range(3):
		var ang := float(branch) / 3.0 * TAU + t * 0.05
		var p2 := Vector2(cos(ang) * 18 * s, sin(ang) * 18 * s)
		var perp := Vector2(-p2.y, p2.x).normalized()
		var zigzag := PackedVector2Array([Vector2.ZERO])
		for i in range(4):
			var frac := float(i + 1) / 4.0
			var jitter := perp * sin(t + float(branch) * 2 + float(i)) * 3 * s
			zigzag.append(Vector2.ZERO.lerp(p2, frac) + jitter)
		for i in range(zigzag.size() - 1):
			draw_line(zigzag[i], zigzag[i + 1],
					Color(white.r, white.g, white.b, 0.9), 2.5 * s)
	draw_arc(Vector2.ZERO, 14 * s + sin(t * 0.3) * 4, 0, TAU, 20,
			Color(blue.r, blue.g, blue.b, 0.15), 4 * s)

# —— 6. 机械幽灵 mech ——
func _draw_mech_ghost(s: float) -> void:
	var metal := Color(0.55, 0.58, 0.62)
	var dark_metal := Color(0.35, 0.38, 0.42)
	var glow_green := Color(0.3, 1.0, 0.55)
	var t := pulse * 5.0
	var hex := PackedVector2Array()
	for i in range(6):
		var ang := float(i) / 6.0 * TAU + PI / 6
		hex.append(Vector2(cos(ang) * 12 * s, sin(ang) * 12 * s - 6 * s))
	draw_colored_polygon(hex, metal)
	var hex2 := PackedVector2Array()
	for i in range(6):
		var ang := float(i) / 6.0 * TAU + PI / 6
		hex2.append(Vector2(cos(ang) * 8 * s, sin(ang) * 8 * s - 6 * s))
	draw_colored_polygon(hex2, dark_metal)
	draw_circle(Vector2(0, -6 * s), 4 * s + sin(t * 2) * 0.5, glow_green)
	for i in range(4):
		var base_ang := float(i) / 4.0 * TAU
		var p0 := Vector2(cos(base_ang) * 8 * s, sin(base_ang) * 8 * s - 6 * s)
		var p1 := Vector2(cos(base_ang) * 18 * s, sin(base_ang) * 16 * s - 6 * s)
		var p2 := Vector2(cos(base_ang) * 22 * s, sin(base_ang) * 22 * s - 2 * s)
		draw_line(p0, p1, metal, 2.0 * s)
		draw_line(p1, p2, dark_metal, 1.5 * s)

# —— 7. 暗影刺客 shadow ——
func _draw_shadow_assassin(s: float) -> void:
	var shadow := Color(0.1, 0.05, 0.15)
	var edge := Color(0.3, 0.15, 0.4)
	var red_eye := Color(1.0, 0.15, 0.2)
	var t := pulse * 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -24 * s), Vector2(10 * s, -8 * s), Vector2(12 * s, 12 * s),
		Vector2(-12 * s, 12 * s), Vector2(-10 * s, -8 * s)
	]), shadow)
	draw_circle(Vector2(-3 * s, -16 * s), 1.8 * s + sin(t) * 0.3, red_eye)
	draw_circle(Vector2(3 * s, -16 * s), 1.8 * s + sin(t) * 0.3, red_eye)
	draw_line(Vector2(6 * s, 0), Vector2(14 * s + _facing.x * 4, -8 * s + _facing.y * 4),
			Color(0.85, 0.85, 0.9), 2.0 * s)
	draw_line(Vector2(-6 * s, 0), Vector2(-14 * s + _facing.x * 4, 8 * s + _facing.y * 4),
			Color(0.85, 0.85, 0.9), 2.0 * s)

# —— 8. 巨型亡灵 giant ——
func _draw_giant_undead(s: float) -> void:
	var bone := Color(0.78, 0.75, 0.68)
	var dark_bone := Color(0.5, 0.46, 0.4)
	var green_glow := Color(0.3, 0.95, 0.5)
	var t := pulse * 3.0
	var head_y := -28 * s
	draw_circle(Vector2(0, head_y), 14 * s, bone)
	draw_circle(Vector2(0, head_y), 12 * s, dark_bone)
	draw_circle(Vector2(-5 * s, head_y - 2 * s), 3.5 * s, green_glow)
	draw_circle(Vector2(5 * s, head_y - 2 * s), 3.5 * s, green_glow)
	draw_line(Vector2(0, head_y + 14 * s), Vector2(0, 8 * s), bone, 5.0 * s)
	draw_line(Vector2(-18 * s, head_y + 22 * s), Vector2(18 * s, head_y + 22 * s), bone, 3.0 * s)
	draw_line(Vector2(-16 * s, head_y + 28 * s), Vector2(16 * s, head_y + 28 * s), bone, 2.5 * s)
	for i in range(6):
		var ang := float(i) / 6.0 * TAU + t * 0.2
		var p1 := Vector2(cos(ang) * (28 * s + sin(t * 2) * 3),
			sin(ang) * (28 * s + sin(t * 2) * 3) - 6 * s)
		var p2 := Vector2(cos(ang) * (36 * s + sin(t * 2) * 3),
			sin(ang) * (36 * s + sin(t * 2) * 3) - 6 * s)
		draw_line(p1, p2, Color(green_glow.r, green_glow.g, green_glow.b, 0.3), 2.0 * s)

# —— fallback ghost ——
func _draw_basic_ghost(s: float) -> void:
	var bone := Color(0.86, 0.84, 0.76)
	draw_circle(Vector2(0, -18 * s), 7.0 * s, bone)
	draw_line(Vector2(0, -11 * s), Vector2(0, 4 * s), bone, 3.0 * s)
	var glow := (sin(pulse * 4.0) + 1.0) * 0.5
	draw_arc(Vector2.ZERO, 16.0 * s, 0, TAU, 18,
			Color(color.r, color.g, color.b, 0.18 + glow * 0.18), 1.5)
