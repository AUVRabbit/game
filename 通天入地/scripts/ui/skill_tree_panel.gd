# ============================================================
# SkillTreePanel — 技能树 + 职业专职面板
# 真实素材：技能图标 / 职业立绘 / 特效预览
# ============================================================

extends CanvasLayer
class_name SkillTreePanel

const TIER_NAMES := { 0: "层一·初阶", 1: "层二·进阶", 2: "层三·专精", 3: "层四·融合" }
const TIER_COUNT := 4
const KIND_NAMES := { "growth": "成长节点" }
const SLOT_KEYS := ["1", "2", "3", "R", "F", "G", "T", "Y", "V", "B"]
const STAT_NAMES := {
	"attack": "攻击", "defense": "防御", "magic_attack": "法强", "magic_defense": "法防",
	"max_hp": "生命上限", "max_mp": "魔力上限", "move_speed": "移速", "attack_speed": "攻速",
	"crit_rate": "暴击率", "crit_damage": "暴击伤害", "dodge_rate": "闪避率",
	"all_stats_bonus": "全属性", "lifesteal": "吸血", "shield_bonus": "护盾强化",
	"heal_bonus": "治疗强化", "burn": "灼烧强化", "execute": "处决", "fortify": "坚韧",
	"haste": "急速", "resonance": "共鸣", "trap_bonus": "布置强化", "summon_bonus": "召唤强化",
	"power": "技能威力", "attack_pct": "攻击", "magic_attack_pct": "法伤",
	"damage_reduction": "减伤"
}
const PERCENT_STATS := ["move_speed", "attack_speed", "crit_rate", "crit_damage", "dodge_rate", "all_stats_bonus",
	"lifesteal", "shield_bonus", "heal_bonus", "burn", "execute", "fortify", "haste", "resonance",
	"trap_bonus", "summon_bonus", "power", "attack_pct", "magic_attack_pct", "damage_reduction"]
const TIER_COL_W := 94
const TIER_COL_GAP := 10
const NODE_ROW_H := 78
const NODE_ROW_GAP := 8
const TIER_HEADER_H := 18
const TREE_W := TIER_COUNT * TIER_COL_W + (TIER_COUNT - 1) * TIER_COL_GAP
const TREE_H := TIER_HEADER_H + TIER_COUNT * NODE_ROW_H + (TIER_COUNT - 1) * NODE_ROW_GAP

var root: Control
var portrait: TextureRect
var title_label: Label
var points_label: Label
var tree_tab: Button
var build_tab: Button
var fusion_tab: Button
var tree_box: Control
var build_box: Control
var fusion_box: Control
var tree_root: Control
var tree_links: TreeLinkLayer
var grid: GridContainer
var build_list: VBoxContainer
var fusion_list: VBoxContainer
var detail_icon: TextureRect
var detail_effect: TextureRect
var detail_name: Label
var detail_meta: Label
var detail_desc: Label
var detail_unlock: Button
var detail_panel: PanelContainer
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

	tree_tab = _make_button("成长树", header)
	tree_tab.pressed.connect(func() -> void: _show_tab("tree"))
	build_tab = _make_button("流派配招", header)
	build_tab.pressed.connect(func() -> void: _show_tab("build"))
	fusion_tab = _make_button("技能融合", header)
	fusion_tab.pressed.connect(func() -> void: _show_tab("fusion"))
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
	grid.custom_minimum_size = Vector2(TREE_W, TIER_COUNT * NODE_ROW_H + (TIER_COUNT - 1) * NODE_ROW_GAP)
	tree_col.add_child(grid)

	build_box = Control.new()
	build_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	build_box.visible = false
	left.add_child(build_box)
	var build_scroll := ScrollContainer.new()
	build_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_box.add_child(build_scroll)
	build_list = VBoxContainer.new()
	build_list.add_theme_constant_override("separation", 8)
	build_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.add_child(build_list)

	fusion_box = Control.new()
	fusion_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	fusion_box.visible = false
	left.add_child(fusion_box)
	var fusion_scroll := ScrollContainer.new()
	fusion_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	fusion_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fusion_box.add_child(fusion_scroll)
	fusion_list = VBoxContainer.new()
	fusion_list.add_theme_constant_override("separation", 8)
	fusion_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fusion_scroll.add_child(fusion_list)

	# 右侧详情
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(248, 0)
	right.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.07, 0.1, 0.94)))
	body.add_child(right)
	detail_panel = right
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
	footer.text = "K 打开/关闭 · 每完成一层（4 节点）解锁 1 个操作栏格 · 每完成 2 层解锁 1 个融合槽 · 营地内可自由配招"
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
	var style: Dictionary = DataManager.get_style(str(data.style_id)) if data.style_id != "" else {}
	var style_name := str(style.get("name", "未选流派"))
	title_label.text = "%s · %s   Lv.%d · %d转" % [str(data.class_display_name), style_name, level, int(data.get_display_stage())]
	points_label.text = "技能点 %d   ·   操作栏 %d/%d   ·   融合槽 %d/%d   ·   金币 %d" % [
		SkillManager.get_points(class_id) if SkillManager else 0,
		int(data.get_slot_count()), int(data.MAX_SKILL_SLOTS),
		int(data.fusions.size()), int(data.get_fusion_slots()), int(GameManager.gold if GameManager else 0)]
	_rebuild_tree(class_id)
	_rebuild_build(class_id, data)
	_rebuild_fusion(class_id, data)
	if selected_node_id != "":
		_select_node(class_id, selected_node_id)
	else:
		_clear_detail()

func _show_tab(tab: String) -> void:
	tree_box.visible = tab == "tree"
	build_box.visible = tab == "build"
	fusion_box.visible = tab == "fusion"
	tree_tab.modulate = Color.WHITE if tab == "tree" else Color(0.7, 0.7, 0.75)
	build_tab.modulate = Color.WHITE if tab == "build" else Color(0.7, 0.7, 0.75)
	fusion_tab.modulate = Color.WHITE if tab == "fusion" else Color(0.7, 0.7, 0.75)
	detail_panel.visible = tab == "tree"
	if tab != "tree":
		_clear_detail()

# ---------- 技能树 ----------
func _rebuild_tree(class_id: String) -> void:
	for child in grid.get_children():
		child.queue_free()
	node_buttons.clear()
	node_edges.clear()
	var nodes: Array = DataManager.get_skill_tree_nodes(class_id)
	# 布局：列 = 层（0 初阶 → 3 融合），行 = 4 个节点
	for row in TIER_COUNT:
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
	btn.custom_minimum_size = Vector2(TIER_COL_W, 48)
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

# ---------- 流派与配招 ----------
func _add_section(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	parent.add_child(label)

func _format_passive(passive: Dictionary) -> String:
	if passive.is_empty():
		return "无"
	var parts: Array = []
	for key in passive.keys():
		if str(key) == "stacks":
			parts.append("最多 %d 层" % int(passive[key]))
			continue
		var value := float(passive[key])
		var label := str(STAT_NAMES.get(str(key), str(key)))
		if PERCENT_STATS.has(str(key)):
			parts.append("%s +%d%%" % [label, int(round(value * 100.0))])
		else:
			parts.append("%s +%d" % [label, int(value)])
	return " · ".join(parts)

func _rebuild_build(class_id: String, data) -> void:
	for child in build_list.get_children():
		child.queue_free()
	data.sync_loadout()
	var head := Label.new()
	head.text = "1转·流派全精通　2转·万流归宗　3转·生命跃迁　4转·超脱"
	head.add_theme_font_size_override("font_size", 16)
	head.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	build_list.add_child(head)

	_add_section(build_list, "流派选择（1转 Lv.10；修习其他流派 120 金）")
	for sid in data.get_class_style_options():
		build_list.add_child(_style_card(data, str(sid)))

	_add_section(build_list, "专精（3 条专精主动全部可用，选择 1 条被动生效）")
	var spec_row := HBoxContainer.new()
	spec_row.add_theme_constant_override("separation", 8)
	var specs: Array = data.get_specs()
	for spec in specs:
		var spec_key := str(spec.get("id", ""))
		var btn := Button.new()
		btn.text = "%s · %s\n%s" % [str(spec.get("name", "")), str(spec.get("active", {}).get("name", "")), _format_passive(spec.get("passive", {}))]
		btn.toggle_mode = true
		btn.button_pressed = spec_key == str(data.spec_id)
		btn.pressed.connect(func() -> void:
			data.select_spec(spec_key)
			_refresh())
		spec_row.add_child(btn)
	if specs.is_empty():
		var none := Label.new()
		none.text = "尚未选择流派"
		spec_row.add_child(none)
	build_list.add_child(spec_row)

	_add_section(build_list, "阶位进阶")
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 8)
	var stage_names := { 2: "2转·万流归宗", 3: "3转·生命跃迁", 4: "4转·超脱" }
	for stage in [2, 3, 4]:
		var check: Dictionary = data.can_transition(stage)
		var btn := Button.new()
		btn.text = str(stage_names[stage])
		if int(data.get_stage()) >= stage:
			btn.text += "（已完成）"
			btn.disabled = true
		elif bool(check.get("ok", false)):
			btn.pressed.connect(func() -> void:
				var result: Dictionary = data.transition(stage)
				if bool(result.get("ok", false)):
					EventBus.notify("进阶成功：%s" % str(stage_names[stage]))
				_refresh())
		else:
			btn.disabled = true
			btn.tooltip_text = str(check.get("reason", ""))
			btn.text += "（%s）" % str(check.get("reason", "未满足"))
		stage_row.add_child(btn)
	build_list.add_child(stage_row)

	if int(data.get_stage()) >= 4:
		build_list.add_child(_borrow_row(data))

	_add_section(build_list, "自由配招（%d/%d 格 · 流派技能 %d/6）" % [
		int(data.loadout.size()), int(data.get_slot_count()),
		int(data.count_style_skills_in(data.loadout))])
	var arrange := Label.new()
	var parts: Array = []
	for i in data.loadout.size():
		var sk: Dictionary = data.get_skill(i + 1)
		if sk.is_empty():
			continue
		parts.append("%s:%s" % [SLOT_KEYS[i], str(sk.get("name", ""))])
	arrange.text = "当前排列：" + ("　".join(parts) if not parts.is_empty() else "（空）")
	arrange.add_theme_font_size_override("font_size", 12)
	arrange.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	arrange.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_list.add_child(arrange)

	var default_btn := Button.new()
	default_btn.text = "恢复默认配招"
	default_btn.pressed.connect(func() -> void:
		data.loadout = []
		data._loadout_initialized = false
		data.invalidate_abilities()
		_refresh())
	build_list.add_child(default_btn)

	var owned: Dictionary = data.get_owned_abilities()
	var ids: Array = owned.keys()
	ids.sort_custom(func(a, b) -> bool:
		return str(owned[a].get("name", "")) < str(owned[b].get("name", "")))
	for aid in ids:
		build_list.add_child(_ability_row(data, str(aid), owned[aid]))

func _style_card(data, sid: String) -> Control:
	var style: Dictionary = DataManager.get_style(sid)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.09, 0.13, 0.92)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = "%s · %s（%s）" % [str(style.get("index", "")).to_upper(), str(style.get("name", "")), str(style.get("tag", ""))]
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)
	var meta := Label.new()
	meta.text = "被动：%s　｜　普攻：%s" % [
		_format_passive(style.get("passive", {})), str(style.get("basic_attack", {}).get("kind", ""))]
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(meta)
	var skill_names: Array = []
	for sk in style.get("skills", []):
		skill_names.append(str(sk.get("name", "")))
	var skills_label := Label.new()
	skills_label.text = "6 技能：" + " / ".join(skill_names)
	skills_label.add_theme_font_size_override("font_size", 12)
	skills_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(skills_label)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(108, 34)
	var learned: bool = data.is_style_learned(sid)
	if str(data.style_id) == sid:
		btn.text = "当前流派"
		btn.disabled = true
	elif learned:
		btn.text = "启用"
		btn.pressed.connect(func() -> void:
			data.select_style(sid)
			_refresh())
	else:
		var check: Dictionary = data.can_learn_style(sid)
		btn.text = "修习（%d金）" % int(data.STYLE_LEARN_COST)
		if not bool(check.get("ok", false)):
			btn.disabled = true
			btn.tooltip_text = str(check.get("reason", ""))
		elif GameManager and int(GameManager.gold) < int(data.STYLE_LEARN_COST):
			btn.disabled = true
			btn.tooltip_text = "金币不足"
		else:
			btn.pressed.connect(func() -> void:
				if GameManager and GameManager.spend_gold(int(data.STYLE_LEARN_COST)):
					data.learn_style(sid)
					data.select_style(sid)
					_refresh())
	row.add_child(btn)
	return card

func _source_name(source_id: String) -> String:
	match source_id:
		"arcane":
			return "法术"
		"mech":
			return "机械"
		"martial":
			return "传武"
		"tech":
			return "科技"
	return source_id

func _borrow_row(data) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.09, 0.13, 0.92)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var label := Label.new()
	label.text = "4转借技（4 选 1，不得借本源流）："
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)
	var opt := OptionButton.new()
	var options: Array = data.get_borrow_options()
	var selected := -1
	for i in options.size():
		var b: Dictionary = options[i]
		opt.add_item("%s · %s" % [_source_name(str(b.get("source", ""))), str(b.get("name", ""))])
		opt.set_item_metadata(i, str(b.get("id", "")))
		if str(b.get("id", "")) == str(data.borrowed_skill):
			selected = i
	if selected >= 0:
		opt.select(selected)
	row.add_child(opt)
	var btn := Button.new()
	btn.text = "借用"
	btn.pressed.connect(func() -> void:
		var idx := opt.get_selected()
		if idx < 0:
			return
		var result: Dictionary = data.apply_borrow(str(opt.get_item_metadata(idx)))
		if not bool(result.get("ok", false)):
			EventBus.notify(str(result.get("reason", "无法借用")))
		_refresh())
	row.add_child(btn)
	return panel

func _ability_row(data, ability_id: String, ability: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = "%s　[%s]　CD %.1fs · %dMP" % [
		str(ability.get("name", ability_id)), str(ability.get("type", "")),
		float(ability.get("cd", 0.0)), int(ability.get("mp", 0))]
	label.add_theme_font_size_override("font_size", 12)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 26)
	if data.loadout.has(ability_id):
		btn.text = "移出"
		btn.pressed.connect(func() -> void:
			data.loadout.erase(ability_id)
			data.refresh_skills()
			_refresh())
	else:
		btn.text = "装配"
		btn.pressed.connect(func() -> void:
			if data.loadout.size() >= data.get_slot_count():
				EventBus.notify("操作栏格位已满：完成技能树层数可解锁更多格位")
				return
			if data.is_style_skill(ability_id) and data.count_style_skills_in(data.loadout) >= 6:
				EventBus.notify("流派技能最多装配 6 格")
				return
			if not data.loadout.has(ability_id):
				data.loadout.append(ability_id)
				data.refresh_skills()
			_refresh())
	row.add_child(btn)
	return row

# ---------- 技能融合 ----------
func _rebuild_fusion(class_id: String, data) -> void:
	for child in fusion_list.get_children():
		child.queue_free()
	_add_section(fusion_list, "融合槽 %d/%d（每完成 2 层技能树解锁 1 个）" % [
		int(data.fusions.size()), int(data.get_fusion_slots())])
	var rule := Label.new()
	rule.text = "融合 = 全新技能：以主技能为骨架、副技能为元素，重新命名并重新染色，命中时元素与主技能同帧爆发（不是两段动画叠加）。威力 ×1.15，冷却 ×1.25，法力 = 主 + 副 × 0.5。终极 / 变身 / 超脱 / 借技不可作副技能，同一技能只能参与一次。"
	rule.add_theme_font_size_override("font_size", 12)
	rule.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fusion_list.add_child(rule)

	if data.fusions.is_empty():
		var none := Label.new()
		none.text = "尚未创建融合技能"
		none.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
		fusion_list.add_child(none)
	for fid in data.fusions:
		var fused: Dictionary = FusionService.build_from_id(data, str(fid))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = "%s　（CD %.1fs · %dMP · %s）" % [
			str(fused.get("name", fid)), float(fused.get("cd", 0.0)), int(fused.get("mp", 0)),
			str(fused.get("fuse_verb", fused.get("fusion_keyword", {}).get("kind", "")))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)
		var btn := Button.new()
		btn.text = "撤销"
		var fusion_key := str(fid)
		btn.pressed.connect(func() -> void:
			FusionService.remove_fusion(data, fusion_key)
			_refresh())
		row.add_child(btn)
		fusion_list.add_child(row)

	if data.fusions.size() >= data.get_fusion_slots():
		return
	var owned: Dictionary = data.get_owned_abilities()
	var used := {}
	for fid in data.fusions:
		for part in FusionService.split_id(str(fid)):
			used[str(part)] = true
	var main_ids: Array = []
	var sub_ids: Array = []
	for aid in owned.keys():
		var key := str(aid)
		if key.contains("__") or used.has(key):
			continue
		main_ids.append(key)
		if not bool(owned[key].get("fuse_no_sub", false)):
			sub_ids.append(key)
	if main_ids.is_empty() or sub_ids.is_empty():
		return
	var create_row := HBoxContainer.new()
	create_row.add_theme_constant_override("separation", 6)
	var main_opt := OptionButton.new()
	for aid in main_ids:
		main_opt.add_item(str(owned[aid].get("name", aid)))
		main_opt.set_item_metadata(main_opt.item_count - 1, str(aid))
	create_row.add_child(main_opt)
	var plus := Label.new()
	plus.text = "＋"
	create_row.add_child(plus)
	var sub_opt := OptionButton.new()
	for aid in sub_ids:
		sub_opt.add_item(str(owned[aid].get("name", aid)))
		sub_opt.set_item_metadata(sub_opt.item_count - 1, str(aid))
	create_row.add_child(sub_opt)
	var fuse_btn := Button.new()
	fuse_btn.text = "融合"
	fuse_btn.pressed.connect(func() -> void:
		if main_opt.get_selected() < 0 or sub_opt.get_selected() < 0:
			return
		var main_id := str(main_opt.get_item_metadata(main_opt.get_selected()))
		var sub_id := str(sub_opt.get_item_metadata(sub_opt.get_selected()))
		var result: Dictionary = FusionService.add_fusion(data, main_id, sub_id)
		if not bool(result.get("ok", false)):
			EventBus.notify(str(result.get("reason", "无法融合")))
		_refresh())
	create_row.add_child(fuse_btn)
	fusion_list.add_child(create_row)

# ---------- 工具 ----------
func _find_skill(skill_id: String) -> Dictionary:
	if skill_id == "" or DataManager == null:
		return {}
	var ability: Dictionary = DataManager.get_ability(skill_id)
	if not ability.is_empty():
		return ability
	var player = GameManager.active_player if GameManager else null
	if player == null or not is_instance_valid(player):
		return {}
	var data = player.get_node_or_null("CharacterData")
	if data == null:
		return {}
	return data.get_owned_abilities().get(skill_id, {})

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
