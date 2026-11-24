# ============================================================
# TrainingStation — 训练场功能台
# mode: restore（回满/重置CD）/ style（循环流派）/ ascend（进阶试炼）
# 只负责转发交互事件，具体逻辑由 TrainingGround 处理
# ============================================================

extends Area2D
class_name TrainingStation

signal activated(mode: String)

@export var mode: String = "restore"
@export var station_label: String = "恢复台"
@export var station_color: Color = Color(0.45, 0.90, 0.70)

var pulse: float = 0.0

var _label: Label = null

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	add_child(shape)
	_label = Label.new()
	_label.text = station_label
	_label.position = Vector2(-56, -66)
	_label.size = Vector2(112, 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", station_color.lightened(0.40))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func interact(_player: Node) -> void:
	activated.emit(mode)

func _draw() -> void:
	var glow := 0.55 + 0.30 * sin(pulse * 2.4)
	draw_circle(Vector2(0, 6), 34.0, Color(0, 0, 0, 0.28))
	draw_circle(Vector2.ZERO, 30.0, Color(station_color.r * 0.24, station_color.g * 0.24, station_color.b * 0.28, 0.95))
	draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 32, Color(station_color.r, station_color.g, station_color.b, glow), 2.5, true)
	draw_circle(Vector2.ZERO, 12.0, Color(station_color.r, station_color.g, station_color.b, 0.35))
	match mode:
		"restore":
			# 十字
			draw_line(Vector2(-8, 0), Vector2(8, 0), Color(1, 1, 1, 0.92), 3.5)
			draw_line(Vector2(0, -8), Vector2(0, 8), Color(1, 1, 1, 0.92), 3.5)
		"style":
			# 三个流派环
			for i in range(3):
				var a := TAU * float(i) / 3.0 - PI * 0.5
				draw_circle(Vector2(cos(a), sin(a)) * 8.0, 3.2, Color(1, 1, 1, 0.92))
		"ascend":
			# 向上箭头 + 星
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -11), Vector2(8, 0), Vector2(3, 0), Vector2(3, 9),
				Vector2(-3, 9), Vector2(-3, 0), Vector2(-8, 0)
			]), Color(1, 0.95, 0.65, 0.95))
		_:
			draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, 0.9))
