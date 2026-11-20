# ============================================================
# PuzzleSwitch — 解谜开关（可要求特定职业激活）
# ============================================================

extends Area2D
class_name PuzzleSwitch

signal switch_activated(switch_id: String)

@export var switch_id: String = "switch_a"
@export var required_class: String = ""
@export var switch_color: Color = Color(0.9, 0.3, 0.3)

var is_on: bool = false
var hint_label: Label = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	add_child(shape)
	hint_label = Label.new()
	hint_label.position = Vector2(-44, -46)
	hint_label.size = Vector2(88, 20)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	if required_class != "":
		hint_label.text = "需要 %s" % required_class
	else:
		hint_label.text = "踩上去"
	add_child(hint_label)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if is_on or not body.is_in_group("player"):
		return
	if required_class != "":
		var data = body.get_node_or_null("CharacterData")
		if data == null or str(data.class_id) != required_class:
			EventBus.notify("此机关需要「%s」职业（Q/P 切换）" % required_class)
			return
	is_on = true
	AudioManager.play_sfx("switch")
	queue_redraw()
	EventBus.puzzle_triggered.emit(switch_id, true)
	switch_activated.emit(switch_id)

func reset_switch() -> void:
	if not is_on:
		return
	is_on = false
	queue_redraw()

func _draw() -> void:
	var fill := switch_color if not is_on else Color(0.4, 1.0, 0.5)
	var alpha := 0.9 if is_on else 0.45
	draw_circle(Vector2.ZERO, 20.0, Color(fill.r, fill.g, fill.b, 0.2))
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(fill.r, fill.g, fill.b, alpha), 3.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -12), Vector2(12, 0), Vector2(0, 12), Vector2(-12, 0)
	]), Color(fill.r, fill.g, fill.b, alpha))
