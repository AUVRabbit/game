# ============================================================
# SkillTreePanel — 技能树 + 职业专职面板
# 真实素材：技能图标 / 职业立绘 / 特效预览
# ============================================================

extends CanvasLayer
class_name SkillTreePanel

const TIER_NAMES := { 0: "初始", 1: "精通", 2: "进阶", 3: "天赋", 4: "专精", 5: "终极" }
const TIER_COUNT := 6
const KIND_NAMES := {
	"anchor": "初始主动", "mastery": "技能精通", "active": "进阶主动",
	"passive": "分支天赋", "keystone": "分支专精", "capstone": "终极奥义"
}
const SLOT_KEYS := ["1", "2", "3", "R", "F", "G"]
const STAT_NAMES := {
	"attack": "攻击", "defense": "防御", "magic_attack": "法强", "magic_defense": "法防",
	"max_hp": "生命上限", "max_mp": "魔力上限", "move_speed": "移速", "attack_speed": "攻速",
	"crit_rate": "暴击率", "crit_damage": "暴击伤害", "dodge_rate": "闪避率",
	"all_stats_bonus": "全属性"
}
const PERCENT_STATS := ["move_speed", "attack_speed", "crit_rate", "crit_damage", "dodge_rate", "all_stats_bonus"]
const TIER_COL_W := 82
const TIER_COL_GAP := 8
const NODE_ROW_H := 96
const NODE_ROW_GAP := 12
const TIER_HEADER_H := 20
const TREE_W := 6 * TIER_COL_W + 5 * TIER_COL_GAP
const TREE_H := TIER_HEADER_H + 3 * NODE_ROW_H + 2 * NODE_ROW_GAP

var root: Control
var portrait: TextureRect
var title_label: Label
var points_label: Label
var tree_tab: Button
var spec_tab: Button
var tree_box: Control
var spec_box: Control
var tree_root: Control
var tree_links: TreeLinkLayer
var grid: GridContainer
var spec_list: VBoxContainer
var detail_icon: TextureRect
var detail_effect: TextureRect
var detail_name: Label
var detail_meta: Label
var detail_desc: Label
var detail_unlock: Button
var selected_node_id: String = ""
var effect_tween: Tween = null
var node_buttons: Dictionary = {}
var node_edges: Array = []


class TreeLinkLayer extends Control:
	var panel: SkillTreePanel = null

	func _draw() -> void:
		if panel == null:
			return
		var links: Array = panel.node_edges
		for edge in links:
			var from_rect: Rect2 = edge[0]
			var to_rect: Rect2 = edge[1]
			var active: bool = edge[2]
			var a := from_rect.get_center()
			var b := to_rect.get_center()
			var col := Color(0.45, 0.55, 0.75, 0.55)
			var width := 2.0
			if active:
				col = Color(0.95, 0.78, 0.32, 0.95)
				width = 3.0
			var mid_x := (a.x + b.x) * 0.5
			var pts := PackedVector2Array([a, Vector2(mid_x, a.y), Vector2(mid_x, b.y), b])
			draw_polyline(pts, col, width, true)

func _ready() -> void:
	layer = 29
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("skill_tree_panel")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.05, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_build_ui()
	visible = false

# ---------- 构建 ----------
func _build_ui() -> void:
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 26
	frame.offset_top = 20
	frame.offset_right = -26
	frame.offset_bottom = -20
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.08, 0.12, 0.96)))
	root.add_child(frame)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 8)
	frame.add_child(main)

	# 顶部
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	main.add_child(header)

	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(portrait)

	var head_text := VBoxContainer.new()
	head_text.add_theme_constant_override("separation", 2)
	header.add_child(head_text)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 20)
	head_text.add_child(title_label)
	points_label = Label.new()
	points_label.add_theme_font_size_override("font_size", 14)
	points_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	head_text.add_child(points_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	tree_tab = _make_button("技能树", header)
	tree_tab.pressed.connect(func() -> void: _show_tab("tree"))
	spec_tab = _make_button("职业专职", header)
	spec_tab.pressed.connect(func() -> void: _show_tab("spec"))
	var reset_btn := _make_button("重置技能树", header)
	reset_btn.pressed.connect(_on_reset_tree)
	var close_btn := _make_button("关闭", header)
	close_btn.pressed.connect(_toggle)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(body)

	# 左侧内容区（技能树 / 专职）
	var left := PanelContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.06, 0.09, 0.9)))
	body.add_child(left)

	tree_box = Control.new()
	left.add_child(tree_box)
	var tree_scroll := ScrollContainer.new()
	tree_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	tree_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tree_box.add_child(tree_scroll)
	tree_root = Control.new()
	tree_root.custom_minimum_size = Vector2(TREE_W, TREE_H)
	tree_scroll.add_child(tree_root)
	tree_links = TreeLinkLayer.new()
	tree_links.panel = self
	tree_links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree_links.set_anchors_preset(Control.PRESET_FULL_RECT)
	tree_root.add_child(tree_links)

	var tree_col := VBoxContainer.new()
	tree_col.add_theme_constant_override("separation", 0)
	tree_root.add_child(tree_col)

	# 层级表头
	var tier_header := HBoxContainer.new()
	tier_header.add_theme_constant_override("separation", TIER_COL_GAP)
	tier_header.custom_minimum_size = Vector2(TREE_W, TIER_HEADER_H)
	tree_col.add_child(tier_header)
	for tier in TIER_COUNT:
		var tier_label := Label.new()
		tier_label.text = str(TIER_NAMES.get(tier, "天赋"))
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tier_label.custom_minimum_size = Vector2(TIER_COL_W, TIER_HEADER_H)
		tier_label.add_theme_font_size_override("font_size", 13)
		tier_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		tier_header.add_child(tier_label)

	grid = GridContainer.new()
	grid.columns = TIER_COUNT
	grid.add_theme_constant_override("h_separation", TIER_COL_GAP)
	grid.add_theme_constant_override("v_separation", NODE_ROW_GAP)
	grid.custom_minimum_size = Vector2(TREE_W, 3 * NODE_ROW_H + 2 * NODE_ROW_GAP)
	tree_col.add_child(grid)

	spec_box = Control.new()
	spec_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	spec_box.visible = false
	left.add_child(spec_box)
	var spec_scroll := ScrollContainer.new()
	spec_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	spec_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	spec_box.add_child(spec_scroll)
	spec_list = VBoxContainer.new()
	spec_list.add_theme_constant_override("separation", 10)
	spec_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spec_scroll.add_child(spec_list)

	# 右侧详情
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(248, 0)
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.07, 0.1, 0.94)))
	body.add_child(right)
	var right_v := VBoxContainer.new()
	right_v.add_theme_constant_override("separation", 6)
	right.add_child(right_v)

	var icon_row := HBoxContainer.new()
	icon_row.add_theme_constant_override("separation", 6)
	right_v.add_child(icon_row)

	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(92, 92)
	detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_row.add_child(detail_icon)

	detail_effect = TextureRect.new()
	detail_effect.custom_minimum_size = Vector2(92, 92)
	detail_effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_effect.pivot_offset = Vector2(46, 46)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	detail_effect.material = mat
	icon_row.add_child(detail_effect)

	detail_name = Label.new()
	detail_name.add_theme_font_size_override("font_size", 18)
	right_v.add_child(detail_name)
	detail_meta = Label.new()
	detail_meta.add_theme_font_size_override("font_size", 13)
	detail_meta.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	detail_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_v.add_child(detail_meta)
	detail_desc = Label.new()
	detail_desc.add_theme_font_size_override("font_size", 13)
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_child(detail_desc)
	detail_unlock = Button.new()
	detail_unlock.text = "解锁"
	detail_unlock.pressed.connect(_on_unlock_pressed)
	right_v.add_child(detail_unlock)

	var footer := Label.new()
	footer.text = "K 打开/关闭技能树 · 升级获得技能点 · 技能树节点提升技能威力与被动属性"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	main.add_child(footer)

func _panel_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _make_button(text: String, parent: Node) -> Button:
	var btn := Button.new()
	btn.text = text
	parent.add_child(btn)
	return btn

# ---------- 开关 ----------
func _toggle() -> void:
	if visible:
		visible = false
		if GameManager:
			GameManager.close_ui()
	else:
		_refresh()
		visible = true
		if GameManager:
			GameManager.open_ui(GameManager.GameState.SKILL_TREE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_skill_tree"):
		get_viewport().set_input_as_handled()
		_toggle()

# ---------- 刷新 ----------
func _refresh() -> void:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return
	var class_id := str(data.class_id)
	var level := int(data.level)
	portrait.texture = AssetLibrary.texture("portrait_%s" % class_id)
	var spec: Dictionary = SkillManager.get_specialization(class_id) if SkillManager else {}
	if spec.is_empty():
		title_label.text = "%s   Lv.%d" % [str(data.class_display_name), level]
	else:
		title_label.text = "%s · %s   Lv.%d" % [str(data.class_display_name), str(spec.get("name", "")), level]
	points_label.text = "可用技能点：%d" % (SkillManager.get_points(class_id) if SkillManager else 0)
	_rebuild_tree(class_id)
	_rebuild_specs(class_id, level)
	if selected_node_id != "":
		_select_node(class_id, selected_node_id)
	else:
		_clear_detail()

func _show_tab(tab: String) -> void:
	tree_box.visible = tab == "tree"
	spec_box.visible = tab == "spec"
	tree_tab.modulate = Color.WHITE if tab == "tree" else Color(0.7, 0.7, 0.75)
	spec_tab.modulate = Color.WHITE if tab == "spec" else Color(0.7, 0.7, 0.75)
	if tab == "spec":
		_clear_detail()

# ---------- 技能树 ----------
func _rebuild_tree(class_id: String) -> void:
	for child in grid.get_children():
		child.queue_free()
	node_buttons.clear()
	node_edges.clear()
	var nodes: Array = DataManager.get_skill_tree_nodes(class_id)
	# 布局：列 = 层级（0 初始 → 5 终极），行 = 分支位置
	for row in 3:
		for tier in TIER_COUNT:
			var node: Dictionary = {}
			for n in nodes:
				if int(n.get("tier", -1)) == tier and int(n.get("col", -1)) == row:
					node = n
					break
			if node.is_empty():
				grid.add_child(_empty_cell())
			else:
				grid.add_child(_node_cell(class_id, node))
	_update_links.call_deferred()

func _empty_cell() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(TIER_COL_W, NODE_ROW_H)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return holder

func _node_cell(class_id: String, node: Dictionary) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 1)
	cell.custom_minimum_size = Vector2(TIER_COL_W, NODE_ROW_H)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(TIER_COL_W, 58)
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var tex: Texture2D = AssetLibrary.texture(str(node.get("icon", "")))
	if tex:
		btn.icon = tex
	btn.pressed.connect(func() -> void: _select_node(class_id, str(node.get("id", ""))))
	cell.add_child(btn)

	var name_label := Label.new()
	name_label.text = str(node.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.clip_text = true
	cell.add_child(name_label)

	var cost_label := Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 11)
	var unlocked := SkillManager.is_unlocked(class_id, str(node.get("id", "")))
	if unlocked:
		cost_label.text = "已解锁"
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.55))
		btn.modulate = Color(1, 1, 1, 1)
		btn.tooltip_text = "已解锁"
	else:
		cost_label.text = "消耗 %d 点" % int(node.get("cost", 1))
		var check := SkillManager.can_unlock(class_id, str(node.get("id", "")))
		if bool(check.get("ok", false)):
			cost_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
			btn.modulate = Color(1, 1, 1, 0.92)
		else:
			cost_label.add_theme_color_override("font_color", Color(0.75, 0.5, 0.5))
			btn.modulate = Color(0.45, 0.45, 0.5, 0.85)
			btn.tooltip_text = str(check.get("reason", ""))
	cell.add_child(cost_label)
	node_buttons[str(node.get("id", ""))] = btn
	return cell

func _update_links() -> void:
	node_edges.clear()
	if tree_root == null or not is_instance_valid(tree_root):
		return
	var base := tree_root.get_global_rect()
	var nodes: Array = DataManager.get_skill_tree_nodes(_current_class_id())
	for n in nodes:
		var target_id := str(n.get("id", ""))
		if not node_buttons.has(target_id):
			continue
		var target_btn: Button = node_buttons[target_id]
		if not is_instance_valid(target_btn):
			continue
		var target_rect := Rect2(target_btn.get_global_rect())
		target_rect.position -= base.position
		for req_id in n.get("requires", []):
			var req := str(req_id)
			if not node_buttons.has(req):
				continue
			var from_btn: Button = node_buttons[req]
			if not is_instance_valid(from_btn):
				continue
			var from_rect := Rect2(from_btn.get_global_rect())
			from_rect.position -= base.position
			var active := SkillManager.is_unlocked(_current_class_id(), target_id)
			node_edges.append([from_rect, target_rect, active])
	if tree_links:
		tree_links.queue_redraw()

func _current_class_id() -> String:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return ""
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return ""
	return str(data.class_id)

func _select_node(class_id: String, node_id: String) -> void:
	var node: Dictionary = DataManager.get_skill_node(class_id, node_id)
	if node.is_empty():
		return
	selected_node_id = node_id
	detail_icon.texture = AssetLibrary.texture(str(node.get("icon", "")))
	detail_name.text = str(node.get("name", ""))
	var tier := int(node.get("tier", 0))
	var kind := str(node.get("kind", ""))
	var meta := "层级：%s · 类型：%s · 消耗 %d 点" % [
		str(TIER_NAMES.get(tier, "天赋")), str(KIND_NAMES.get(kind, "节点")), int(node.get("cost", 0))]
	var passive: Dictionary = node.get("passive", {})
	if not passive.is_empty():
		meta += "\n被动：%s" % _format_stats(passive)
	var skill_id := str(node.get("skill_id", ""))
	if skill_id != "":
		meta += "\n关联技能：%s" % _skill_name(class_id, skill_id)
	if kind == "active" and skill_id != "":
		var slot := _skill_slot(class_id, skill_id)
		if slot > 0 and slot <= SLOT_KEYS.size():
			meta += "\n解锁后可在技能栏按 [%s] 施放" % SLOT_KEYS[slot - 1]
	detail_meta.text = meta
	detail_desc.text = str(node.get("desc", ""))
	_play_effect(skill_id)

	if SkillManager.is_unlocked(class_id, node_id):
		detail_unlock.disabled = true
		detail_unlock.text = "已解锁"
	else:
		var check := SkillManager.can_unlock(class_id, node_id)
		detail_unlock.disabled = not bool(check.get("ok", false))
		detail_unlock.text = "解锁（%d 点）" % int(node.get("cost", 1)) if bool(check.get("ok", false)) else str(check.get("reason", "无法解锁"))

func _clear_detail() -> void:
	selected_node_id = ""
	detail_icon.texture = null
	detail_name.text = ""
	detail_meta.text = ""
	detail_desc.text = "选择技能树节点查看详情"
	detail_unlock.disabled = true
	detail_unlock.text = "解锁"
	_stop_effect()

func _on_unlock_pressed() -> void:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player) or selected_node_id == "":
		return
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return
	var class_id := str(data.class_id)
	if SkillManager.unlock_node(class_id, selected_node_id):
		data.refresh_skill_stats()
		_refresh()

func _on_reset_tree() -> void:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return
	SkillManager.reset_tree(str(data.class_id))
	data.refresh_skill_stats()
	_refresh()

# ---------- 特效预览 ----------
func _play_effect(skill_id: String) -> void:
	_stop_effect()
	if skill_id == "":
		return
	var skill: Dictionary = _find_skill(skill_id)
	if skill.is_empty():
		return
	var kind := str(skill.get("vfx", ""))
	var tex: Texture2D = AssetLibrary.texture("vfx_%s" % kind)
	if tex == null:
		return
	detail_effect.texture = tex
	detail_effect.modulate = Color(1, 1, 1, 1)
	detail_effect.scale = Vector2.ONE
	effect_tween = detail_effect.create_tween()
	effect_tween.set_loops()
	effect_tween.tween_property(detail_effect, "scale", Vector2(1.18, 1.18), 0.8).set_trans(Tween.TRANS_SINE)
	effect_tween.tween_property(detail_effect, "scale", Vector2(0.92, 0.92), 0.8).set_trans(Tween.TRANS_SINE)
	effect_tween.tween_property(detail_effect, "rotation", TAU, 2.4).from(0.0)

func _stop_effect() -> void:
	if effect_tween and effect_tween.is_valid():
		effect_tween.kill()
	effect_tween = null
	detail_effect.texture = null
	detail_effect.rotation = 0.0

# ---------- 职业专职 ----------
func _rebuild_specs(class_id: String, level: int) -> void:
	for child in spec_list.get_children():
		child.queue_free()
	var specs: Array = DataManager.get_specializations(class_id)
	var current: Dictionary = SkillManager.get_specialization(class_id) if SkillManager else {}
	var title := Label.new()
	title.text = "职业专职：%s（等级 %d 解锁，只能选择一次）" % [str(DataManager.get_class_data(class_id).get("name", class_id)), level]
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	spec_list.add_child(title)
	if current.is_empty() and specs.is_empty():
		var none := Label.new()
		none.text = "该职业暂未开放专职"
		spec_list.add_child(none)
		return
	for spec in specs:
		spec_list.add_child(_spec_card(class_id, spec, level, str(current.get("id", ""))))

func _spec_card(class_id: String, spec: Dictionary, level: int, current_id: String) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.09, 0.13, 0.92)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = AssetLibrary.texture(str(spec.get("icon", "")))
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = str(spec.get("name", ""))
	name_label.add_theme_font_size_override("font_size", 17)
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = str(spec.get("desc", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(300, 0)
	info.add_child(desc_label)

	var stats_label := Label.new()
	stats_label.text = _format_stats(spec.get("stats", {}))
	stats_label.add_theme_font_size_override("font_size", 13)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	info.add_child(stats_label)

	var bonus_label := Label.new()
	var sb: Dictionary = spec.get("skill_bonus", {})
	var sp: Dictionary = spec.get("passives", {})
	var parts: Array = []
	if not sb.is_empty():
		parts.append("技能威力 +%d%% / 冷却 -%d%%" % [int(float(sb.get("power", 0.0)) * 100.0), int(float(sb.get("cooldown", 0.0)) * 100.0)])
	if not sp.is_empty():
		for key in sp.keys():
			parts.append("%s +%d%%" % [_passive_name(str(key)), int(float(sp[key]) * 100.0)])
	bonus_label.text = " · ".join(parts)
	bonus_label.add_theme_font_size_override("font_size", 13)
	bonus_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	info.add_child(bonus_label)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 34)
	var spec_id := str(spec.get("id", ""))
	if spec_id == current_id:
		btn.text = "已转职"
		btn.disabled = true
	else:
		var check := SkillManager.can_choose_specialization(class_id, spec_id, level)
		if bool(check.get("ok", false)):
			btn.text = "选择"
			btn.pressed.connect(func() -> void: _choose_spec(class_id, spec_id))
		else:
			btn.text = str(check.get("reason", "不可选"))
			btn.disabled = true
	row.add_child(btn)
	return card

func _choose_spec(class_id: String, spec_id: String) -> void:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return
	if SkillManager.choose_specialization(class_id, spec_id, int(data.level)):
		data.refresh_skill_stats()
		data._apply_specialization_name()
		_refresh()

# ---------- 工具 ----------
func _find_skill(skill_id: String) -> Dictionary:
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return {}
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return {}
	for s in data.skills:
		if str(s.get("id", "")) == skill_id:
			return s
	return {}

func _skill_slot(class_id: String, skill_id: String) -> int:
	var def: Dictionary = DataManager.get_class_data(class_id)
	for s in def.get("skills", []):
		if str(s.get("id", "")) == skill_id:
			return int(s.get("slot", 0))
	return 0

func _skill_name(class_id: String, skill_id: String) -> String:
	var def: Dictionary = DataManager.get_class_data(class_id)
	for s in def.get("skills", []):
		if str(s.get("id", "")) == skill_id:
			return str(s.get("name", skill_id))
	return skill_id

func _format_stats(stats: Dictionary) -> String:
	var parts: Array = []
	for key in stats.keys():
		var value := float(stats[key])
		var label := str(STAT_NAMES.get(str(key), str(key)))
		if PERCENT_STATS.has(str(key)):
			parts.append("%s %+.0f%%" % [label, value * 100.0])
		else:
			parts.append("%s %+d" % [label, int(value)])
	return " · ".join(parts)

func _passive_name(key: String) -> String:
	match key:
		"lifesteal":
			return "吸血"
		"shield_bonus":
			return "护盾强化"
		"heal_bonus":
			return "治疗强化"
		"burn":
			return "灼烧强化"
		_:
			return key
