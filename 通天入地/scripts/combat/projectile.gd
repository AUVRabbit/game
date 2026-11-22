# ============================================================
# Projectile — 技能弹道
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
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _spawn_sprite() -> void:
	if icon_id == "":
		return
	var tex: Texture2D = AssetLibrary.texture(icon_id)
	if tex == null:
		return
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.modulate = color
	sprite.scale = Vector2.ONE * 0.14
	sprite.rotation = direction.angle()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	add_child(sprite)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	elapsed += delta
	if sprite:
		sprite.rotation += delta * 6.0
	if elapsed >= lifetime:
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
	if knockback > 0.0 and body is Node2D:
		(body as Node2D).global_position += direction.normalized() * knockback
	if splash_radius > 0.0:
		_splash(level, body)
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
	if sprite:
		return
	draw_circle(Vector2.ZERO, 7.0, color)
	draw_circle(Vector2.ZERO, 3.0, Color(color.r + 0.3, color.g + 0.3, color.b + 0.3, 0.9))
