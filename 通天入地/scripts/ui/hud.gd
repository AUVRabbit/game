# ============================================================
# HUD — 战斗信息界面（纯代码构建，无需素材）
# HP/MP/经验/金币/技能冷却/任务追踪/提示/试炼信息
# ============================================================

extends CanvasLayer
class_name HUD

var root: Control
var name_label: Label
var portrait: TextureRect
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var gold_label: Label
var gold_icon: TextureRect
var exp_label: Label
var point_label: Label
var skill_panels: Array = []
var skill_labels: Array = []
var skill_icons: Array = []
var skill_cd_labels: Array = []
var last_class_id: String = ""
var quest_label: Label
var rogue_label: Label
var toast_label: Label
var toast_panel: Panel
var build_hint: Label
var toast_tween: Tween = null
var skill_tree_button: Button = null
var skill_bar: HBoxContainer = null
const SKILL_KEYS := ["1", "2", "3", "R", "F", "G"]
const SKILL_SLOT_COUNT := 6

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
	if skill_tree_button:
		skill_tree_button.mouse_filter = Control.MOUSE_FILTER_STOP
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(58, 58)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	row.add_child(vbox)

	name_label = Label.new()
	name_label.text = "未载入角色"
	name_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(name_label)
	hp_bar = _bar(Color(0.85, 0.25, 0.3))
	vbox.add_child(hp_bar)
	mp_bar = _bar(Color(0.3, 0.5, 0.95))
	vbox.add_child(mp_bar)
	var gold_row := HBoxContainer.new()
	gold_row.add_theme_constant_override("separation", 4)
	vbox.add_child(gold_row)
	gold_icon = TextureRect.new()
	gold_icon.custom_minimum_size = Vector2(18, 18)
	gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_icon.texture = AssetLibrary.texture("item_gold_coin")
	gold_row.add_child(gold_icon)
	gold_label = Label.new()
	gold_label.text = "金币 0"
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	gold_row.add_child(gold_label)
	exp_label = Label.new()
	exp_label.text = "EXP 0/100"
	exp_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(exp_label)
	point_label = Label.new()
	point_label.text = "技能点 0"
	point_label.add_theme_font_size_override("font_size", 12)
	point_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	vbox.add_child(point_label)

func _build_skill_bar() -> void:
	# 6 格技能栏：1/2/3 基础技能，R/F/G 进阶技能（需技能树解锁）
	var bar := HBoxContainer.new()
	bar.position = Vector2(165, 470)
	bar.add_theme_constant_override("separation", 6)
	root.add_child(bar)
	skill_bar = bar
	for i in SKILL_SLOT_COUNT:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(100, 58)
		panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.09, 0.14, 0.88)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		panel.add_child(row)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		skill_icons.append(icon)

		var text_col := VBoxContainer.new()
		text_col.add_theme_constant_override("separation", 1)
		text_col.custom_minimum_size = Vector2(42, 0)
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_col)

		var label := Label.new()
		label.text = "[%s] 技能" % SKILL_KEYS[i]
		label.add_theme_font_size_override("font_size", 10)
		label.clip_text = true
		text_col.add_child(label)
		skill_labels.append(label)

		var cd_label := Label.new()
		cd_label.text = ""
		cd_label.add_theme_font_size_override("font_size", 10)
		cd_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		cd_label.clip_text = true
		text_col.add_child(cd_label)
		skill_cd_labels.append(cd_label)

		bar.add_child(panel)
		skill_panels.append(panel)
	var hint := Label.new()
	hint.position = Vector2(12, 446)
	hint.text = "左键/空格 攻击   Shift 冲刺   E 交互   1/2/3/R/F/G 技能   I 背包   B 建造   Q/P 换职业   K 技能树"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 0.85))
	root.add_child(hint)
	var tree_btn := Button.new()
	tree_btn.text = "技能树 (K)"
	tree_btn.position = Vector2(12, 152)
	tree_btn.custom_minimum_size = Vector2(112, 30)
	tree_btn.add_theme_font_size_override("font_size", 12)
	tree_btn.pressed.connect(_open_skill_tree)
	root.add_child(tree_btn)
	skill_tree_button = tree_btn

func _skill_available(class_id: String, skill: Dictionary) -> bool:
	var req = skill.get("requires", "")
	if req == null:
		return true
	if req is String:
		if str(req).is_empty():
			return true
		return SkillManager == null or SkillManager.is_unlocked(class_id, str(req))
	if req is Array:
		if SkillManager == null:
			return true
		for r in req:
			if not SkillManager.is_unlocked(class_id, str(r)):
				return false
	return true

func _open_skill_tree() -> void:
	for node in get_tree().get_nodes_in_group("skill_tree_panel"):
		if node.has_method("_toggle"):
			node._toggle()
			return

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
	# Toast 固定在屏幕中上方，带半透明背板，避免与世界内浮动文字/左上角状态面板重叠
	toast_panel = Panel.new()
	toast_panel.position = Vector2(190, 232)
	toast_panel.size = Vector2(580, 38)
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.09, 0.82)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.45, 0.85, 0.75)
	toast_panel.add_theme_stylebox_override("panel", sb)
	toast_panel.modulate = Color(1, 1, 1, 0)
	root.add_child(toast_panel)

	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_child(toast_label)

func show_toast(text: String) -> void:
	if toast_panel == null:
		return
	toast_label.text = text
	toast_panel.modulate = Color(1, 1, 1, 1)
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(1.6)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.6)

func _on_gold_changed(new_amount: int, _delta: int) -> void:
	if gold_label:
		gold_label.text = "金币 %d" % new_amount

func _process(_delta: float) -> void:
	# 触屏模式下触屏技能键占据右侧，技能栏左移避免遮挡
	if skill_bar:
		skill_bar.position.x = 8.0 if (InputManager and InputManager.is_touch_mode()) else 165.0
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return
	name_label.text = "%s  Lv.%d" % [data.class_display_name, data.level]
	if last_class_id != str(data.class_id):
		last_class_id = str(data.class_id)
		portrait.texture = AssetLibrary.texture("portrait_%s" % last_class_id)
		for i in skill_icons.size():
			skill_icons[i].texture = null
	hp_bar.max_value = data.get_max_hp()
	hp_bar.value = data.hp
	mp_bar.max_value = maxi(1, data.max_mp)
	mp_bar.value = data.mp
	exp_label.text = "EXP %d/%d" % [data.exp, data.exp_to_next]
	gold_label.text = "%d" % GameManager.gold
	if SkillManager:
		point_label.text = "技能点 %d" % SkillManager.get_points(str(data.class_id))

	var class_id := str(data.class_id)
	for i in SKILL_SLOT_COUNT:
		if i >= data.skills.size():
			skill_labels[i].text = "[%s] —" % SKILL_KEYS[i]
			skill_cd_labels[i].text = ""
			skill_icons[i].texture = null
			skill_panels[i].modulate = Color.WHITE
			continue
		var skill: Dictionary = data.skills[i]
		var icon_id := str(skill.get("icon", ""))
		if not icon_id.is_empty() and (skill_icons[i].texture == null or skill_icons[i].get_meta("asset_id", "") != icon_id):
			skill_icons[i].texture = AssetLibrary.texture(icon_id)
			skill_icons[i].set_meta("asset_id", icon_id)
		if not _skill_available(class_id, skill):
			skill_labels[i].text = "[%s] 未解锁" % SKILL_KEYS[i]
			skill_cd_labels[i].text = "技能树"
			skill_panels[i].modulate = Color(0.65, 0.65, 0.72, 0.9)
			continue
		var left: float = player.get_skill_cooldown_left(i) if player.has_method("get_skill_cooldown_left") else 0.0
		if left > 0.01:
			skill_labels[i].text = str(skill.get("name", ""))
			skill_cd_labels[i].text = "CD %.1fs" % left
			skill_panels[i].modulate = Color(1, 1, 1, 0.5)
		else:
			skill_labels[i].text = "[%s] %s" % [SKILL_KEYS[i], str(skill.get("name", ""))]
			skill_cd_labels[i].text = "%dMP" % int(skill.get("mp", 0))
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
