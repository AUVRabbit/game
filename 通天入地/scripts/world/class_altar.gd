# ============================================================
# ClassAltar — 职业祭坛
# 消耗金币解锁一名新职业，解锁后可随时用 Q / P 切换
# 最多可解锁 data/classes.json 中的全部 12 个职业
# ============================================================

extends Area2D
class_name ClassAltar

@export var unlock_cost: int = 150
@export var altar_color: Color = Color(0.62, 0.45, 1.0)

var label: Label = null
var pulse: float = 0.0
var sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 26.0
	shape.shape = circle
	add_child(shape)
	_load_sprite()
	label = Label.new()
	label.position = Vector2(-80, -58)
	label.size = Vector2(160, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	_refresh_label()
	queue_redraw()

func _load_sprite() -> void:
	var tex: Texture2D = AssetLibrary.texture("sprite_altar")
	if tex == null:
		return
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * 0.5
	sprite.position = Vector2(0, -8)
	add_child(sprite)

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _next_locked_class() -> String:
	if DataManager == null or GameManager == null:
		return ""
	for class_id in DataManager.get_all_class_ids():
		if not GameManager.roster.has(str(class_id)):
			return str(class_id)
	return ""

func interact(_player: Node) -> void:
	if GameManager == null:
		return
	var next_id := _next_locked_class()
	if next_id == "":
		EventBus.notify("全部 12 个职业均已解锁")
		return
	if GameManager.gold < unlock_cost:
		EventBus.notify("解锁新职业需要 %d 金币" % unlock_cost)
		return
	var class_def: Dictionary = DataManager.get_class_data(next_id) if DataManager else {}
	if not GameManager.spend_gold(unlock_cost):
		return
	if GameManager.add_class_member(next_id):
		EventBus.notify("解锁新职业：%s（Q/P 切换）" % str(class_def.get("name", next_id)))
		AudioManager.play_sfx("unlock")
		_refresh_label()
	else:
		GameManager.add_gold(unlock_cost)
		EventBus.notify("解锁失败，金币已退还")

func _refresh_label() -> void:
	if label == null:
		return
	var next_id := _next_locked_class()
	if next_id == "":
		label.text = "职业祭坛 · 已全解锁"
	else:
		var class_def: Dictionary = DataManager.get_class_data(next_id) if DataManager else {}
		label.text = "解锁 %s（%d 金币）" % [str(class_def.get("name", next_id)), unlock_cost]

func _draw() -> void:
	var glow := 0.5 + 0.3 * sin(pulse * 2.2)
	draw_circle(Vector2.ZERO, 30.0, Color(altar_color.r, altar_color.g, altar_color.b, 0.18))
	draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 28, Color(altar_color.r, altar_color.g, altar_color.b, glow), 3.0, true)
	if sprite:
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -18), Vector2(16, 0), Vector2(0, 18), Vector2(-16, 0)
	]), Color(altar_color.r, altar_color.g, altar_color.b, 0.85))
	draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, 0.85))
