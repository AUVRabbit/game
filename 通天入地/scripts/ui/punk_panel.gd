# ============================================================
# PunkPanel — 朋克改造面板 UI
# 从 PunkForge 或快捷键打开，显示 4 槽位、可选部件、效果预览
# ============================================================

extends CanvasLayer
class_name PunkPanel

var root: Control = null
var visible_panel: bool = false
var active_class_id: String = ""
var slot_labels: Dictionary = {}  # slot → Label（显示当前部件）
var style_labels: Dictionary = {}  # slot → Label（显示风格颜色）
var part_list_vb: VBoxContainer = null
var part_count_label: Label = null
var active_style_label: Label = null

func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("punk_panel")
	_build_ui()
	EventBus.punk_applied.connect(_on_punk_changed)
	EventBus.punk_removed.connect(_on_punk_changed)
	EventBus.punk_style_changed.connect(_on_style_changed)
	visible = false

func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# 背景遮罩
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# 主面板容器
	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280
	panel.offset_top = -240
	panel.offset_right = 280
	panel.offset_bottom = 240
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.12, 0.08, 0.18, 0.96), Color(0.8, 0.4, 1.0)))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	# 标题
	var title := Label.new()
	title.text = "🔧 朋克改造台"
	title.position = Vector2(20, 12)
	title.size = Vector2(300, 32)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	panel.add_child(title)

	# 关闭按钮
	var close := Button.new()
	close.text = "✕"
	close.position = Vector2(520, 12)
	close.size = Vector2(36, 30)
	close.pressed.connect(_toggle)
	panel.add_child(close)

	# 当前主风格
	active_style_label = Label.new()
	active_style_label.position = Vector2(20, 48)
	active_style_label.size = Vector2(480, 20)
	active_style_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(active_style_label)

	# 4 槽位面板（左侧）
	var slots_vb := VBoxContainer.new()
	slots_vb.position = Vector2(20, 80)
	slots_vb.size = Vector2(260, 380)
	slots_vb.add_theme_constant_override("separation", 10)
	panel.add_child(slots_vb)

	var slot_names: Array = ["weapon", "helmet", "chest", "back"]
	var slot_cn: Array = ["武器槽", "头盔槽", "胸甲槽", "背槽"]
	for i in 4:
		var slot_name: String = slot_names[i]
		var frame := Panel.new()
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame.custom_minimum_size = Vector2(260, 80)
		frame.add_theme_stylebox_override("panel", _make_style(Color(0.08, 0.05, 0.14, 0.9), Color(0.3, 0.2, 0.5)))
		slots_vb.add_child(frame)

		var slot_title := Label.new()
		slot_title.text = slot_cn[i]
		slot_title.position = Vector2(10, 4)
		slot_title.add_theme_font_size_override("font_size", 14)
		slot_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
		frame.add_child(slot_title)

		var part_label := Label.new()
		part_label.text = "（空）"
		part_label.position = Vector2(10, 22)
		part_label.size = Vector2(240, 20)
		part_label.add_theme_font_size_override("font_size", 13)
		frame.add_child(part_label)
		slot_labels[slot_name] = part_label

		var style_label := Label.new()
		style_label.text = ""
		style_label.position = Vector2(10, 44)
		style_label.size = Vector2(240, 16)
		style_label.add_theme_font_size_override("font_size", 11)
		frame.add_child(style_label)
		style_labels[slot_name] = style_label

		# 卸下按钮
		var remove_btn := Button.new()
		remove_btn.text = "卸下"
		remove_btn.position = Vector2(210, 4)
		remove_btn.size = Vector2(48, 22)
		remove_btn.add_theme_font_size_override("font_size", 11)
		remove_btn.pressed.connect(_remove_punk.bind(slot_name))
		frame.add_child(remove_btn)

	# 部件列表（右侧）
	var list_title := Label.new()
	list_title.text = "可选部件（点击安装）"
	list_title.position = Vector2(300, 80)
	list_title.size = Vector2(240, 20)
	list_title.add_theme_font_size_override("font_size", 14)
	list_title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
	panel.add_child(list_title)

	var list_container := ScrollContainer.new()
	list_container.position = Vector2(300, 104)
	list_container.size = Vector2(240, 320)
	panel.add_child(list_container)

	part_list_vb = VBoxContainer.new()
	part_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	part_list_vb.add_theme_constant_override("separation", 6)
	list_container.add_child(part_list_vb)

	part_count_label = Label.new()
	part_count_label.position = Vector2(300, 428)
	part_count_label.size = Vector2(240, 16)
	part_count_label.add_theme_font_size_override("font_size", 11)
	part_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	panel.add_child(part_count_label)

func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	return s

func _toggle() -> void:
	visible_panel = not visible_panel
	if visible_panel:
		_refresh()
		if GameManager:
			GameManager.open_ui(GameManager.GameState.DIALOG)  # 复用暂停锁
	else:
		if GameManager:
			GameManager.close_ui()
	visible = visible_panel
	root.visible = visible_panel

func _refresh() -> void:
	if GameManager == null or not is_instance_valid(GameManager.active_player):
		return
	var data: Node = GameManager.active_player.get_node_or_null("CharacterData")
	if data == null:
		return
	active_class_id = str(data.class_id)
	# 槽位
	for slot in PunkManager.SLOTS:
		var part_id: String = str(PunkManager.get_part_in_slot(active_class_id, slot))
		var label: Label = slot_labels.get(slot)
		var style_label: Label = style_labels.get(slot)
		if part_id == "":
			if label:
				label.text = "（空）"
				label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
			if style_label:
				style_label.text = ""
		else:
			var part: Dictionary = DataManager.get_punk_part(part_id) if DataManager else {}
			if label:
				label.text = str(part.get("name", part_id))
				label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			if style_label:
				var style: String = str(part.get("style", "neutral"))
				var sname: String = style
				for s in DataManager.get_punk_styles() if DataManager else []:
					if str(s.get("id", "")) == style:
						sname = str(s.get("name", style))
						break
				style_label.text = "风格：%s" % sname
				style_label.add_theme_color_override("font_color", DataManager.get_punk_style_color(style) if DataManager else Color.WHITE)

	# 主风格
	var primary: String = PunkManager.get_primary_style(active_class_id)
	var style_cn: String = "无"
	var style_color: Color = Color.GRAY
	for s in DataManager.get_punk_styles() if DataManager else []:
		if str(s.get("id", "")) == primary:
			style_cn = str(s.get("name", ""))
			style_color = Color.from_string(str(s.get("color", "#ffffff")), Color.WHITE)
			break
	if primary == "neutral" or primary == "":
		style_cn = "中性"
	active_style_label.text = "当前主风格：%s" % style_cn
	active_style_label.add_theme_color_override("font_color", style_color)

	# 部件列表
	for child in part_list_vb.get_children():
		child.queue_free()
	var parts: Array = PunkManager.get_all_parts_for_class(active_class_id)
	for part in parts:
		_add_part_button(part)
	if part_count_label:
		part_count_label.text = "共 %d 件可选部件" % parts.size()

func _add_part_button(part: Dictionary) -> void:
	var btn := Button.new()
	var pname: String = str(part.get("name", ""))
	var style_id: String = str(part.get("style", "neutral"))
	var slot_id: String = str(part.get("slot", "weapon"))
	var cost: Dictionary = part.get("cost", {})
	var cost_str: String = ""
	for cid in cost.keys():
		cost_str += "%s×%d " % [str(cid), int(cost[cid])]
	btn.text = "【%s】%s · %s · 需 %s" % [
		slot_id, pname, _style_cn(style_id), cost_str.strip_edges()
	]
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style_color: Color = DataManager.get_punk_style_color(style_id) if DataManager else Color.WHITE
	btn.add_theme_color_override("font_color", style_color)
	btn.pressed.connect(_install_punk.bind(str(part.get("id", ""))))
	part_list_vb.add_child(btn)

func _style_cn(style_id: String) -> String:
	if style_id == "neutral":
		return "通用"
	for s in DataManager.get_punk_styles() if DataManager else []:
		if str(s.get("id", "")) == style_id:
			return str(s.get("name", style_id))
	return style_id

func _install_punk(part_id: String) -> void:
	var part: Dictionary = DataManager.get_punk_part(part_id) if DataManager else {}
	var slot: String = str(part.get("slot", ""))
	if slot == "" or slot not in PunkManager.SLOTS:
		return
	if PunkManager.apply_punk(active_class_id, slot, part_id):
		_refresh()

func _remove_punk(slot: String) -> void:
	if PunkManager.remove_punk(active_class_id, slot):
		_refresh()

func _on_punk_changed(_cid: String, _slot: String, _part_id: String) -> void:
	if visible_panel:
		_refresh()

func _on_style_changed(_cid: String, _style_id: String) -> void:
	if visible_panel:
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not visible_panel:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		_toggle()
		get_viewport().set_input_as_handled()
