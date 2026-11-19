# ============================================================
# HUD — 战斗信息界面（纯代码构建，无需素材）
# HP/MP/经验/金币/技能冷却/任务追踪/提示/试炼信息
# ============================================================

extends CanvasLayer
class_name HUD

var root: Control
var name_label: Label
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var gold_label: Label
var exp_label: Label
var skill_panels: Array = []
var skill_labels: Array = []
var quest_label: Label
var rogue_label: Label
var toast_label: Label
var build_hint: Label
var toast_tween: Tween = null

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_PAUSABLE
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_status_panel()
	_build_skill_bar()
	_build_side_panels()
	_build_toast()
	_set_ignore_mouse(root)
	EventBus.toast_requested.connect(show_toast)
	EventBus.gold_changed.connect(_on_gold_changed)

func _set_ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_set_ignore_mouse(child)

func _panel_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(250, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.8)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _build_status_panel() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.07, 0.1, 0.82)))
	panel.position = Vector2(12, 12)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = "未载入角色"
	name_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(name_label)
	hp_bar = _bar(Color(0.85, 0.25, 0.3))
	vbox.add_child(hp_bar)
	mp_bar = _bar(Color(0.3, 0.5, 0.95))
	vbox.add_child(mp_bar)
	gold_label = Label.new()
	gold_label.text = "金币 0"
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	vbox.add_child(gold_label)
	exp_label = Label.new()
	exp_label.text = "EXP 0/100"
	exp_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(exp_label)

func _build_skill_bar() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(300, 470)
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)
	for i in 3:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(104, 54)
		panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.09, 0.14, 0.86)))
		var label := Label.new()
		label.text = "技能 %d" % (i + 1)
		label.add_theme_font_size_override("font_size", 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(label)
		bar.add_child(panel)
		skill_panels.append(panel)
		skill_labels.append(label)
	var hint := Label.new()
	hint.position = Vector2(300, 448)
	hint.text = "左键/空格 攻击    Shift 冲刺    E 交互    I 背包    B 建造    Q/P 换职业"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 0.85))
	root.add_child(hint)

func _build_side_panels() -> void:
	quest_label = Label.new()
	quest_label.position = Vector2(660, 12)
	quest_label.size = Vector2(288, 120)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.add_theme_font_size_override("font_size", 13)
	quest_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	root.add_child(quest_label)

	rogue_label = Label.new()
	rogue_label.position = Vector2(660, 140)
	rogue_label.size = Vector2(288, 80)
	rogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rogue_label.add_theme_font_size_override("font_size", 12)
	rogue_label.add_theme_color_override("font_color", Color(0.75, 0.8, 1.0))
	root.add_child(rogue_label)

	build_hint = Label.new()
	build_hint.position = Vector2(12, 400)
	build_hint.size = Vector2(280, 26)
	build_hint.text = ""
	build_hint.add_theme_font_size_override("font_size", 13)
	build_hint.add_theme_color_override("font_color", Color(0.7, 1.0, 0.75))
	root.add_child(build_hint)

func _build_toast() -> void:
	toast_label = Label.new()
	toast_label.position = Vector2(230, 400)
	toast_label.size = Vector2(500, 34)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 16)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	toast_label.modulate = Color(1, 1, 1, 0)
	root.add_child(toast_label)

func show_toast(text: String) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.modulate = Color(1, 1, 1, 1)
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func _on_gold_changed(new_amount: int, _delta: int) -> void:
	if gold_label:
		gold_label.text = "金币 %d" % new_amount

func _process(_delta: float) -> void:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return
	name_label.text = "%s  Lv.%d" % [data.class_display_name, data.level]
	hp_bar.max_value = data.get_max_hp()
	hp_bar.value = data.hp
	mp_bar.max_value = maxi(1, data.max_mp)
	mp_bar.value = data.mp
	exp_label.text = "EXP %d/%d" % [data.exp, data.exp_to_next]
	gold_label.text = "金币 %d" % GameManager.gold

	for i in 3:
		if i >= data.skills.size():
			skill_labels[i].text = "—"
			continue
		var skill: Dictionary = data.skills[i]
		var left: float = player.get_skill_cooldown_left(i) if player.has_method("get_skill_cooldown_left") else 0.0
		if left > 0.01:
			skill_labels[i].text = "%s\nCD %.1fs" % [str(skill.get("name", "")), left]
			skill_panels[i].modulate = Color(1, 1, 1, 0.5)
		else:
			skill_labels[i].text = "%s\n[%d] %dMP" % [str(skill.get("name", "")), i + 1, int(skill.get("mp", 0))]
			skill_panels[i].modulate = Color.WHITE

	var quest := QuestManager.get_tracked_quest() if QuestManager else {}
	if quest.is_empty():
		quest_label.text = "当前没有进行中的任务"
	else:
		var lines: Array = quest.get("lines", [])
		var quest_text := ""
		for line in lines:
			quest_text += str(line) + "\n"
		quest_label.text = "【%s】\n%s" % [str(quest.get("name", "")), quest_text.strip_edges()]

	if RoguelikeManager and RoguelikeManager.is_active:
		rogue_label.text = "通天塔试炼\n%s" % RoguelikeManager.summarize()
	else:
		rogue_label.text = ""

	if BuildManager and BuildManager.is_build_mode:
		var block := BuildManager._find_block(BuildManager.current_block_id)
		build_hint.text = "建造模式：%s（左键放置 / 右键拆除）" % str(block.get("name", ""))
	else:
		build_hint.text = ""
