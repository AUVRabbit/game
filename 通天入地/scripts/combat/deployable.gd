# ============================================================
# Deployable — 可部署物（炸弹 / 地雷 / 炮塔）
# bomb / mine: 抛物线飞行 → 落地 fuse/等待 → 爆炸
# turret: 直接部署，持续射击
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
var target_pos: Vector2 = Vector2.ZERO       # 抛物线飞行终点
var fly_speed: float = 320.0
var fly_arc: float = 60.0                    # 抛物线最大高度
var fusion_kw: Dictionary = {}               # 融合技元素（命中时一并爆发）
var fusion_color: Color = Color.WHITE

var elapsed: float = 0.0
var shoot_timer: float = 0.0
var armed: bool = false
var consumed: bool = false
var pulse: float = 0.0

var _flying: bool = false
var _fly_elapsed: float = 0.0
var _fly_duration: float = 0.0
var _fly_start: Vector2 = Vector2.ZERO
var _fly_trajectory_y: float = 0.0

func _ready() -> void:
	add_to_group("deployables")
	z_index = 1
	shoot_timer = interval * 0.5
	# bomb/mine 有抛物线飞行，turret 直接落地
	if mode in ["bomb", "mine"] and target_pos.length() > 0.01:
		_flying = true
		_fly_start = global_position
		var dist := _fly_start.distance_to(target_pos)
		_fly_duration = maxf(0.25, dist / maxf(80.0, fly_speed))
		_fly_trajectory_y = fly_arc * clampf(dist / 200.0, 0.5, 2.5)
	else:
		global_position = target_pos

func _process(delta: float) -> void:
	if consumed:
		return
	elapsed += delta
	pulse += delta

	# 抛物线飞行阶段
	if _flying:
		_fly_elapsed += delta
		var t_norm := clampf(_fly_elapsed / _fly_duration, 0.0, 1.0)
		global_position = _fly_start.lerp(target_pos, t_norm)
		global_position.y -= _fly_trajectory_y * sin(t_norm * PI)   # 弧形上抛
		# 飞行过程中的视觉闪烁
		if t_norm >= 1.0:
			_flying = false
			# 落地小爆点
			EffectRing.spawn(get_parent(), global_position, 20.0, color, 0.18)
		queue_redraw()
		return

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
	SkillVfx.spawn_shockwave(get_parent(), global_position, radius * 1.3, color, 0.42)
	SkillVfx.spawn_burst(get_parent(), global_position, radius, color, 0.5)
	EffectRing.spawn(get_parent(), global_position, radius, color)
	SkillVfx.spawn_impact(get_parent(), global_position, "explosion", color)
	# 融合技：爆炸同时引发元素爆发，形成一次完整的新技能表现
	if not fusion_kw.is_empty():
		SkillExecutor._apply_element(source, fusion_kw, fusion_color, global_position, radius, damage, is_magic, get_parent())
	AudioManager.play_sfx("hit")
	if ScreenShake and ScreenShake.has_method("heavy"):
		ScreenShake.heavy()
	queue_free()

func _shoot() -> void:
	var target: Node2D = _nearest_enemy(380.0)
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
	SkillVfx.spawn_muzzle_flash(get_parent(), global_position + dir * 14.0, color, dir.angle())

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
	# 飞行中：画飞行中的炸弹（稍透明 + 拖影）
	if _flying:
		var t_norm := clampf(_fly_elapsed / maxf(_fly_duration, 0.001), 0.0, 1.0)
		var alpha := 1.0 - t_norm * 0.3
		var trail_points := PackedVector2Array()
		for k in 6:
			var kk := float(k) / float(6)
			var tp := _fly_start.lerp(target_pos, t_norm - kk * 0.12)
			tp.y -= _fly_trajectory_y * sin(clampf(t_norm - kk * 0.12, 0.0, 1.0) * PI)
			trail_points.append(tp - global_position)
		for i in trail_points.size() - 1:
			var a := (1.0 - float(i) / float(trail_points.size())) * alpha * 0.4
			draw_line(trail_points[i], trail_points[i + 1], Color(color.r, color.g, color.b, a), 3.0 - float(i) * 0.4)
		# 炸弹本体
		draw_circle(Vector2.ZERO, 11.0, Color(0.12, 0.1, 0.1, alpha))
		draw_circle(Vector2.ZERO, 8.0, Color(0.3, 0.25, 0.22, alpha))
		# 引线火花
		var spark_a := 0.7 + sin(pulse * 30.0) * 0.3
		draw_circle(Vector2(0, -12), 3.5, Color(1.0, 0.6, 0.2, spark_a))
		return

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
