# ============================================================
# BuildPalette — 建造方块选择栏
# B 键进入建造模式后显示；点击方块切换当前放置物
# ============================================================

extends CanvasLayer
class_name BuildPalette

var root: Control
var panel: PanelContainer
var list: VBoxContainer
var title: Label

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_PAUSABLE
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = PanelContainer.new()
	panel.position = Vector2(12, 240)
	panel.custom_minimum_size = Vector2(220, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.1, 0.88)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.4, 0.75, 0.5)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	panel.add_child(list)
	title = Label.new()
	title.text = "建造方块"
	title.add_theme_font_size_override("font_size", 15)
	list.add_child(title)

	visible = false
	if BuildManager:
		BuildManager.build_mode_changed.connect(_on_build_mode_changed)

func _on_build_mode_changed(active: bool) -> void:
	visible = active
	if active:
		_rebuild()

func _rebuild() -> void:
	for child in list.get_children():
		if child != title:
			child.queue_free()
	for block in BuildManager.available_blocks:
		var block_id := str(block.get("id", ""))
		var cost: Dictionary = block.get("craft_cost", {})
		var cost_text := ""
		for key in cost.keys():
			cost_text += "%s×%d " % [str(key), int(cost[key])]
		var button := Button.new()
		button.text = "%s  (%s)" % [str(block.get("name", block_id)), cost_text.strip_edges()]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_block_selected.bind(block_id))
		list.add_child(button)
	_refresh_highlight()

func _on_block_selected(block_id: String) -> void:
	BuildManager.set_current_block(block_id)
	_refresh_highlight()

func _refresh_highlight() -> void:
	var index := 0
	for child in list.get_children():
		if child == title or not (child is Button):
			continue
		var block: Dictionary = BuildManager.available_blocks[index] if index < BuildManager.available_blocks.size() else {}
		var is_current := str(block.get("id", "")) == BuildManager.current_block_id
		child.modulate = Color(1.0, 1.0, 0.6) if is_current else Color.WHITE
		index += 1
