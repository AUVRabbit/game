# ============================================================
# Projectile — 技能弹道（带飞行轨迹、拖尾、朝向、命中动画）
# ============================================================

extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var damage: int = 10
var is_magic: bool = false
var lifetime: float = 1.6
var source: Node = null
var color: Color = Color(0.5, 0.8, 1.0)
var elapsed: float = 0.0
var icon_id: String = ""
var sprite: Sprite2D = null
var pierce: int = 0
var splash_radius: float = 0.0
var is_crit: bool = false
var knockback: float = 0.0
var hit_bodies: Array = []
var arc_amplitude: float = 0.0   # 抛物线摆动幅度（lob 类抛掷物）
var arc_frequency: float = 2.0
var fusion_kw: Dictionary = {}   # 融合技元素：命中瞬间在此弹道上爆发
var fusion_color: Color = Color.WHITE

var _spawn_y: float = 0.0
var _trail_points: Array = []
var _trail_line: Line2D = null
var _trail_timer: float = 0.0
const TRAIL_MAX := 14

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)
	_spawn_sprite()
	_spawn_trail()
	if arc_amplitude > 0.0:
		_spawn_y = global_position.y
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _spawn_sprite() -> void:
	var tex: Texture2D = null
	if icon_id != "":
		tex = AssetLibrary.texture(icon_id)
	if tex != null:
		sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.modulate = color
		sprite.scale = Vector2.ONE * 0.14
		sprite.rotation = direction.angle()
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = mat
		add_child(sprite)

func _spawn_trail() -> void:
	# 拖尾：Line2D + 采样点（Trail2D 在 headless 环境有时不可用）
	_trail_line = Line2D.new()
	_trail_line.width = 9.0
	_trail_line.default_color = Color(color.r, color.g, color.b, 0.75)
	_trail_line.z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_trail_line.material = mat
	add_child(_trail_line)

func _physics_process(delta: float) -> void:
	if arc_amplitude > 0.0:
		var t_norm := elapsed / maxf(lifetime, 0.001)
		global_position += direction * speed * delta
		global_position.y = _spawn_y - direction.y * speed * elapsed + sin(t_norm * PI) * arc_amplitude * sin(elapsed * arc_frequency)
	else:
		global_position += direction * speed * delta
	elapsed += delta

	# 拖尾采样
	_trail_timer += delta
	if _trail_timer > 0.018:
		_trail_points.insert(0, Vector2.ZERO)
		if _trail_points.size() > TRAIL_MAX:
			_trail_points.pop_back()
		_trail_line.points = PackedVector2Array(_trail_points)
		_trail_timer = 0.0

	if elapsed >= lifetime:
		_expire()

func _expire() -> void:
	if sprite:
		var tw := sprite.create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == source or hit_bodies.has(body):
		return
	if not body.has_method("take_damage"):
		return
	hit_bodies.append(body)
	var dealt: int = body.take_damage(damage, is_magic, source)
	var level := get_parent()
	if level:
		DamageNumber.spawn(level, body.global_position + Vector2(0, -24), dealt, is_crit)
		SkillVfx.spawn_impact(level, body.global_position, "explosion", color)
		EffectRing.spawn(level, body.global_position, 26.0, color, 0.22)
		# 融合技：元素在弹道命中点爆发，属于同一发技能
		if not fusion_kw.is_empty():
			var radius := splash_radius if splash_radius > 0.0 else 110.0
			SkillExecutor._apply_element(source, fusion_kw, fusion_color, body.global_position, radius, damage, is_magic, level)
	if ScreenShake and ScreenShake.has_method("shake"):
		var intensity := 1.8 if splash_radius > 0.0 else 1.2
		ScreenShake.shake(intensity, 0.06, 90.0)
	if knockback > 0.0 and body is Node2D:
		(body as Node2D).global_position += direction.normalized() * knockback
	if splash_radius > 0.0:
		_splash(level, body)
		EffectRing.spawn(level, global_position, splash_radius, color, 0.38)
		if ScreenShake and ScreenShake.has_method("shake"):
			ScreenShake.shake(3.5, 0.14, 55.0)
	if pierce > 0:
		pierce -= 1
	else:
		queue_free()

func _splash(level: Node, primary: Node) -> void:
	if level == null:
		return
	for e in level.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e == primary or not (e is Node2D):
			continue
		if (e as Node2D).global_position.distance_to(global_position) > splash_radius:
			continue
		var dealt: int = e.take_damage(int(round(damage * 0.6)), is_magic, source)
		DamageNumber.spawn(level, e.global_position + Vector2(0, -24), dealt, is_crit)

func _draw() -> void:
	if sprite and sprite.texture != null:
		return
	var core_r := 6.0
	var halo_r := 14.0
	draw_circle(Vector2.ZERO, halo_r, Color(color.r, color.g, color.b, 0.15))
	draw_circle(Vector2.ZERO, core_r + 2.0, Color(color.r, color.g, color.b, 0.35))
	draw_circle(Vector2.ZERO, core_r, color)
	draw_circle(Vector2.ZERO, core_r * 0.55, Color(1.0, 1.0, 1.0, 0.85))
	var len := 12.0
	var perp := Vector2(-direction.y, direction.x)
	var tip := direction.normalized() * len
	var p2 := perp * 3.0
	var p3 := -perp * 3.0
	draw_colored_polygon(PackedVector2Array([tip, p2, p3]), color)

