# ============================================================
# Porta l — 传送门（世界 ↔ 通天塔 / 塔层之间）
# ============================================================

extends Area2D
class_name Portal

@export var portal_id: String = "tower_entrance"
@export var target_floor: int = 1
@export var target_scene: String = ""
@export var portal_color: Color = Color(0.55, 0.35, 1.0)
@export var label_text: String = "通天塔"

var enabled: bool = true
var pulse: float = 0.0
var sprite: Sprite2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	add_child(shape)
	_load_sprite()
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(-30, -52)
	label.size = Vector2(60, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	add_child(label)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _load_sprite() -> void:
	var tex: Texture2D = AssetLibrary.texture("sprite_portal")
	if tex == null:
		return
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * 0.46
	sprite.position = Vector2(0, -8)
	add_child(sprite)

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func set_enabled(value: bool) -> void:
	enabled = value
	monitoring = value
	modulate = Color.WHITE if value else Color(1, 1, 1, 0.3)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if not enabled or not body.is_in_group("player"):
		return
	if GameManager == null:
		return
	EventBus.portal_entered.emit(portal_id, str(target_floor))
	if target_scene != "":
		if target_scene == GameManager.SCENE_TRAINING:
			GameManager.enter_training_ground()
		elif GameManager.training_active:
			GameManager.exit_training_ground()
		else:
			GameManager.current_state = GameManager.GameState.PLAYING
			GameManager.change_scene(target_scene)
		return
	if target_floor <= 0:
		GameManager.enter_main_world()
		return
	if RoguelikeManager and not RoguelikeManager.is_active:
		RoguelikeManager.start_run(randi())
	elif RoguelikeManager and RoguelikeManager.is_active and target_floor > 1:
		RoguelikeManager.advance_floor()
	GameManager.enter_tower_floor(target_floor)

func _draw() -> void:
	var glow := 0.55 + 0.25 * sin(pulse * 3.0)
	draw_circle(Vector2.ZERO, 26.0, Color(portal_color.r, portal_color.g, portal_color.b, 0.15 * glow))
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(portal_color.r, portal_color.g, portal_color.b, glow), 3.0, true)
	draw_arc(Vector2.ZERO, 16.0, pulse, TAU + pulse, 24, Color(1, 1, 1, 0.6 * glow), 2.0, true)
	if sprite:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -20), Vector2(12, 0), Vector2(0, 20), Vector2(-12, 0)
	]), Color(portal_color.r, portal_color.g, portal_color.b, 0.8))
