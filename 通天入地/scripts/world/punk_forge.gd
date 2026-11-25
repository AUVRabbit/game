# ============================================================
# PunkForge — 朋克改造台
# 主世界交互点，打开改造面板，消费材料安装/卸下朋克部件
# ============================================================

extends Area2D
class_name PunkForge

var label: Label = null
var sparkle: float = 0.0
var sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_load_sprite()

	# 标签
	label = Label.new()
	label.position = Vector2(-70, -70)
	label.size = Vector2(140, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	add_child(label)
	queue_redraw()

func _load_sprite() -> void:
	var tex: Texture2D = AssetLibrary.texture("sprite_forge")
	if tex == null:
		return
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * 0.52
	sprite.position = Vector2(0, -8)
	add_child(sprite)

func _process(delta: float) -> void:
	sparkle += delta * 2.5
	var in_range := false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			in_range = true
			break
	if in_range:
		label.text = "E · 朋克改造台"
	else:
		label.text = "朋克改造台（靠近）"
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		EventBus.notify("按 E 打开朋克改造台")

func _on_body_exited(_body: Node) -> void:
	pass

func interact(_player: Node) -> void:
	if GameManager == null or not is_instance_valid(GameManager.active_player):
		return
	var panel: Node = _get_panel()
	if panel == null:
		EventBus.notify("改造面板加载中…")
		return
	panel._toggle()

func _get_panel() -> Node:
	for node in get_tree().get_nodes_in_group("punk_panel"):
		return node
	return null

func _draw() -> void:
	# 底座：四色齿轮
	var style_colors: Array = [
		Color(0.53, 0.42, 0.75, 0.2),  # spell
		Color(0.78, 0.48, 0.23, 0.2),  # mech
		Color(0.29, 0.84, 1.0, 0.2),   # tech
		Color(0.48, 0.18, 0.25, 0.2),  # abyss
	]
	var cx: float = 0.0
	var cy: float = 0.0
	for i in range(4):
		var angle: float = sparkle + TAU * i / 4.0
		var x: float = cx + cos(angle) * 18.0
		var y: float = cy + sin(angle) * 10.0  # 等距压缩
		draw_circle(Vector2(x, y), 10.0, style_colors[i])

	if sprite:
		return

	# 中央核心
	draw_circle(Vector2(0, -4), 12.0, Color(0.9, 0.7, 0.25, 0.9))
	draw_arc(Vector2(0, -4), 14.0, 0.0, TAU, 32, Color(1.0, 1.0, 0.6, 0.8), 2.0)
	# 十字改造标记
	draw_line(Vector2(-10, -4), Vector2(10, -4), Color(0.2, 0.2, 0.4, 0.9), 2.0)
	draw_line(Vector2(0, -14), Vector2(0, 6), Color(0.2, 0.2, 0.4, 0.9), 2.0)
