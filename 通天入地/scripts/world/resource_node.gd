# ============================================================
# ResourceNode — 可采集资源点（木头 / 石头 / 草药 / 铁矿 / 皮革）
# 靠近后按 E 采集，耗尽后按冷却重新生长
# ============================================================

extends Area2D
class_name ResourceNode

@export var resource_id: String = "wood"
@export var display_name: String = ""
@export var quantity: int = 2
@export var respawn_time: float = 8.0
@export var node_color: Color = Color(0.45, 0.72, 0.4)
@export var required_class: String = ""

var available: bool = true
var timer: float = 0.0
var label: Label = null

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	add_child(shape)
	if display_name == "":
		var tpl: Dictionary = DataManager.get_item(resource_id) if DataManager else {}
		display_name = str(tpl.get("name", resource_id))
		if tpl.has("color"):
			node_color = Color.from_string(str(tpl.get("color", "#7fbf6a")), node_color)
	label = Label.new()
	label.position = Vector2(-60, -52)
	label.size = Vector2(120, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	_refresh_label()
	queue_redraw()

func interact(_player: Node) -> void:
	if not available:
		EventBus.notify("%s 尚未重新生长" % display_name)
		return
	if required_class != "":
		var data = _player.get_node_or_null("CharacterData") if _player else null
		if data == null or str(data.class_id) != required_class:
			EventBus.notify("采集此资源需要「%s」职业" % required_class)
			return
	if GameManager == null or GameManager.inventory == null:
		return
	if not GameManager.inventory.add_item(resource_id, quantity):
		return
	EventBus.notify("采集：%s ×%d" % [display_name, quantity])
	AudioManager.play_sfx("gather")
	available = false
	timer = respawn_time
	modulate = Color(1, 1, 1, 0.35)
	_refresh_label()
	queue_redraw()

func _process(delta: float) -> void:
	if available:
		return
	timer -= delta
	if timer <= 0.0:
		available = true
		modulate = Color.WHITE
		_refresh_label()
		queue_redraw()

func _refresh_label() -> void:
	if label == null:
		return
	if available:
		label.text = "采集 %s" % display_name
	else:
		label.text = "%s（%.0fs）" % [display_name, maxf(timer, 0.0)]

func _draw() -> void:
	var alpha := 0.9 if available else 0.25
	draw_circle(Vector2.ZERO, 22.0, Color(node_color.r, node_color.g, node_color.b, 0.18))
	var pts := PackedVector2Array([
		Vector2(0, -20), Vector2(14, -4), Vector2(8, 16), Vector2(-8, 16), Vector2(-14, -4)
	])
	draw_colored_polygon(pts, Color(node_color.r, node_color.g, node_color.b, alpha))
	draw_polyline(PackedVector2Array([
		Vector2(0, -20), Vector2(14, -4), Vector2(8, 16), Vector2(-8, 16), Vector2(-14, -4), Vector2(0, -20)
	]), Color(1, 1, 1, 0.35 * alpha), 1.5)
