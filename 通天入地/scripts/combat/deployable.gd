# ============================================================
# Deployable — 可部署物（炸弹 / 地雷 / 炮塔）
# 炸弹：引信到期后范围爆炸
# 地雷：短暂布防后，敌人踏入即引爆
# 炮塔：在持续时间内自动射击最近敌人
# 纯代码绘制，与敌人占位形体保持同一视觉语言
# ============================================================

extends Node2D
class_name Deployable

var mode: String = "bomb"      # bomb / mine / turret
var radius: float = 80.0
var damage: int = 20
var is_magic: bool = false
var source: Node = null
var color: Color = Color(1.0, 0.6, 0.2)
var fuse: float = 0.5
var lifetime: float = 10.0
var interval: float = 1.0
var aim_dir: Vector2 = Vector2.DOWN

var elapsed: float = 0.0
var shoot_timer: float = 0.0
var armed: bool = false
var consumed: bool = false
var pulse: float = 0.0

func _ready() -> void:
	add_to_group("deployables")
	z_index = 1
	shoot_timer = interval * 0.5

func _process(delta: float) -> void:
	if consumed:
		return
	elapsed += delta
	pulse += delta
	queue_redraw()
	match mode:
		"bomb":
			if elapsed >= fuse:
				_explode()
		"mine":
			if elapsed >= 0.6:
				armed = true
			if armed and _nearest_enemy(radius * 0.65) != null:
				_explode()
			if elapsed >= lifetime:
				queue_free()
		"turret":
			if elapsed >= lifetime:
				queue_free()
				return
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				shoot_timer = interval
				_shoot()
		_:
			if elapsed >= fuse:
				_explode()

func _explode() -> void:
	if consumed:
		return
	consumed = true
	for enemy in _enemies():
		if _dist(enemy) <= radius:
			var dealt: int = enemy.take_damage(damage, is_magic, source)
			DamageNumber.spawn(get_parent(), enemy.global_position + Vector2(0, -26), dealt, false)
	EffectRing.spawn(get_parent(), global_position, radius, color)
	SkillVfx.spawn_impact(get_parent(), global_position, "explosion", color)
	AudioManager.play_sfx("hit")
	queue_free()

func _shoot() -> void:
	var target := _nearest_enemy(380.0)
	if target == null:
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	aim_dir = dir
	var projectile = preload("res://scripts/combat/projectile.gd").new()
	projectile.direction = dir
	projectile.speed = 520.0
	projectile.damage = damage
	projectile.is_magic = is_magic
	projectile.color = color
	projectile.source = source
	projectile.lifetime = 0.9
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	SkillVfx.spawn_impact(get_parent(), global_position + dir * 14.0, "steam_burst", color)

func _enemies() -> Array:
	var result: Array = []
	var tree := get_tree()
	if tree == null:
		return result
	for e in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			result.append(e)
	return result

func _nearest_enemy(max_dist: float):
	var best = null
	var best_d := max_dist
	for e in _enemies():
		var d := _dist(e)
		if d <= best_d:
			best_d = d
			best = e
	return best

func _dist(node) -> float:
	if node is Node2D:
		return global_position.distance_to((node as Node2D).global_position)
	return 99999.0

func _draw() -> void:
	match mode:
		"bomb":
			var t := clampf(elapsed / maxf(0.01, fuse), 0.0, 1.0)
			var blink := (sin(pulse * (8.0 + t * 18.0)) + 1.0) * 0.5
			draw_circle(Vector2.ZERO, 11.0, Color(0.12, 0.1, 0.1))
			draw_circle(Vector2.ZERO, 8.0, Color(0.3, 0.25, 0.22))
			draw_circle(Vector2(0, -12), 3.5, Color(1.0, 0.55 + blink * 0.4, 0.2, 0.95))
			draw_arc(Vector2.ZERO, 15.0, 0, TAU, 20, Color(color.r, color.g, color.b, 0.35 + blink * 0.4), 2.0)
		"mine":
			draw_circle(Vector2.ZERO, 10.0, Color(0.16, 0.14, 0.12))
			draw_circle(Vector2.ZERO, 6.0, Color(0.32, 0.28, 0.2))
			var glow := 0.4 if armed else 0.15
			draw_circle(Vector2.ZERO, 3.2, Color(color.r, color.g, color.b, glow + 0.2))
			draw_arc(Vector2.ZERO, 13.0, 0, TAU, 16, Color(color.r, color.g, color.b, glow), 1.5)
		"turret":
			draw_circle(Vector2(0, 6), 12.0, Color(0.18, 0.18, 0.2))
			draw_rect(Rect2(-7, -6, 14, 12), Color(0.3, 0.3, 0.34))
			var barrel_end := aim_dir.normalized() * 18.0
			draw_line(Vector2.ZERO, barrel_end, Color(0.55, 0.55, 0.6), 4.0)
			draw_circle(Vector2.ZERO, 4.0, color)
			draw_arc(Vector2.ZERO, 20.0, 0, TAU, 20, Color(color.r, color.g, color.b, 0.22), 1.0)
