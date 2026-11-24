# ============================================================
# TrainingClassStone — 训练场职业石
# 靠近按 E 即可把当前出战角色切换为该职业（无需解锁、不消耗金币）
# ============================================================

extends Area2D
class_name TrainingClassStone

signal class_chosen(class_id: String)

@export var class_id: String = "warrior"

var class_name_cn: String = ""
var class_color: Color = Color(0.8, 0.8, 0.8)
var pulse: float = 0.0

var _label: Label = null

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var def: Dictionary = DataManager.get_class_data(class_id) if DataManager else {}
	class_name_cn = str(def.get("name", class_id))
	class_color = Color.from_string(str(def.get("color", "#cccccc")), Color.WHITE)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	add_child(shape)
	_label = Label.new()
	_label.text = class_name_cn
	_label.position = Vector2(-48, -70)
	_label.size = Vector2(96, 20)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", class_color.lightened(0.35))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func interact(player: Node) -> void:
	var target: Node = player
	if target == null or not is_instance_valid(target):
		target = GameManager.active_player if GameManager else null
	if target == null:
		return
	var data: Node = target.get_node_or_null("CharacterData")
	if data == null:
		return
	if str(data.class_id) == class_id:
		EventBus.notify("当前已是 %s" % class_name_cn)
		return
	data.setup_class(class_id)
	AudioManager.play_sfx("unlock")
	class_chosen.emit(class_id)

func _draw() -> void:
	var glow := 0.55 + 0.30 * sin(pulse * 2.2)
	draw_circle(Vector2(0, 6), 32.0, Color(0, 0, 0, 0.28))
	var pts := PackedVector2Array()
	for i in range(6):
		var a := TAU * float(i) / 6.0 - PI * 0.5
		pts.append(Vector2(cos(a), sin(a)) * 27.0)
	var base := Color(class_color.r * 0.30, class_color.g * 0.30, class_color.b * 0.34, 0.95)
	draw_colored_polygon(pts, base)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, Color(class_color.r, class_color.g, class_color.b, glow), 2.5, true)
	draw_circle(Vector2.ZERO, 9.0, class_color)
	draw_circle(Vector2(-2, -2), 3.0, Color(1, 1, 1, 0.85))
