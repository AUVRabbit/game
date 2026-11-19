# ============================================================
# InventoryPanel — 背包 / 合成 / 商店 三合一界面
# 按 I 打开；打开时暂停游戏世界
# ============================================================

extends CanvasLayer
class_name InventoryPanel

const SHOP_STOCK := ["healing_potion", "mana_potion", "iron_ore", "herb", "wood", "stone", "leather"]

var root: Control
var dim: ColorRect
var panel: PanelContainer
var tabs: TabContainer
var grid: GridContainer
var slot_buttons: Array = []
var detail_name: Label
var detail_desc: Label
var detail_stats: Label
var use_button: Button
var equip_button: Button
var sell_button: Button
var equip_rows: VBoxContainer
var craft_list: VBoxContainer
var craft_buttons: Dictionary = {}
var shop_list: VBoxContainer
var selected_index: int = -1

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("inventory_panel")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.05, 0.62)
	root.add_child(dim)

	panel = PanelContainer.new()
	panel.position = Vector2(80, 24)
	panel.custom_minimum_size = Vector2(800, 492)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.97)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.4, 0.45, 0.7)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "行囊与工坊"
	title.add_theme_font_size_override("font_size", 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var gold_label := Label.new()
	gold_label.text = "金币"
	gold_label.name = "GoldLabel"
	header.add_child(gold_label)
	var close_button := Button.new()
	close_button.text = "关闭 (I)"
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)

	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(770, 420)
	vbox.add_child(tabs)

	_build_backpack_tab()
	_build_craft_tab()
	_build_shop_tab()
	visible = false
	if GameManager and GameManager.inventory:
		GameManager.inventory.inventory_changed.connect(_refresh_all)

func _make_tab(tab_name: String) -> Control:
	var margin := MarginContainer.new()
	margin.name = tab_name
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	tabs.add_child(margin)
	return margin

func _build_backpack_tab() -> void:
	var tab := _make_tab("背包")
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	tab.add_child(hbox)

	grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	hbox.add_child(grid)
	for i in Inventory.SLOT_COUNT:
		var button := Button.new()
		button.custom_minimum_size = Vector2(58, 46)
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(_on_slot_pressed.bind(i))
		grid.add_child(button)
		slot_buttons.append(button)

	var detail := VBoxContainer.new()
	detail.custom_minimum_size = Vector2(248, 0)
	detail.add_theme_constant_override("separation", 6)
	hbox.add_child(detail)
	detail_name = Label.new()
	detail_name.add_theme_font_size_override("font_size", 17)
	detail_name.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	detail.add_child(detail_name)
	detail_desc = Label.new()
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.custom_minimum_size = Vector2(240, 50)
	detail.add_child(detail_desc)
	detail_stats = Label.new()
	detail_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_stats.add_theme_font_size_override("font_size", 12)
	detail.add_child(detail_stats)

	use_button = Button.new()
	use_button.text = "使用"
	use_button.pressed.connect(_on_use_pressed)
	detail.add_child(use_button)
	equip_button = Button.new()
	equip_button.text = "装备"
	equip_button.pressed.connect(_on_equip_pressed)
	detail.add_child(equip_button)
	sell_button = Button.new()
	sell_button.text = "出售"
	sell_button.pressed.connect(_on_sell_pressed)
	detail.add_child(sell_button)

	var equip_title := Label.new()
	equip_title.text = "— 已装备 —"
	equip_title.add_theme_font_size_override("font_size", 13)
	detail.add_child(equip_title)
	equip_rows = VBoxContainer.new()
	detail.add_child(equip_rows)

func _build_craft_tab() -> void:
	var tab := _make_tab("合成")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(750, 400)
	tab.add_child(scroll)
	craft_list = VBoxContainer.new()
	craft_list.add_theme_constant_override("separation", 4)
	craft_list.custom_minimum_size = Vector2(740, 0)
	scroll.add_child(craft_list)
	var recipes: Array = DataManager.get_recipes() if DataManager else []
	for recipe in recipes:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(520, 26)
		label.text = _recipe_text(recipe)
		row.add_child(label)
		var button := Button.new()
		button.text = "合成"
		button.pressed.connect(_on_craft_pressed.bind(str(recipe.get("id", ""))))
		row.add_child(button)
		craft_list.add_child(row)
		craft_buttons[str(recipe.get("id", ""))] = button

func _build_shop_tab() -> void:
	var tab := _make_tab("商店")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(750, 400)
	tab.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.custom_minimum_size = Vector2(740, 0)
	shop_list.add_theme_constant_override("separation", 4)
	scroll.add_child(shop_list)
	for item_id in SHOP_STOCK:
		var tpl: Dictionary = DataManager.get_item(item_id) if DataManager else {}
		if tpl.is_empty():
			continue
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(520, 26)
		label.text = "%s  ·  %d 金币  ·  %s" % [
			str(tpl.get("name", item_id)), _buy_price(item_id), str(tpl.get("description", ""))
		]
		row.add_child(label)
		var button := Button.new()
		button.text = "购买"
		button.pressed.connect(_on_buy_pressed.bind(item_id))
		row.add_child(button)
		shop_list.add_child(row)
	var tip := Label.new()
	tip.text = "出售：先在「背包」选中物品，再回到本页点击下方按钮。"
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	shop_list.add_child(tip)
	var sell_selected := Button.new()
	sell_selected.text = "出售选中的背包物品"
	sell_selected.pressed.connect(_on_sell_pressed)
	shop_list.add_child(sell_selected)

func _recipe_text(recipe: Dictionary) -> String:
	var output := str(recipe.get("output", ""))
	var tpl: Dictionary = DataManager.get_item(output) if DataManager else {}
	var cost_text := ""
	var cost: Dictionary = recipe.get("cost", {})
	for key in cost.keys():
		var ctpl: Dictionary = DataManager.get_item(str(key)) if DataManager else {}
		cost_text += "%s×%d " % [str(ctpl.get("name", key)), int(cost[key])]
	return "%s ×%d   ←  %s" % [str(tpl.get("name", output)), int(recipe.get("count", 1)), cost_text]

func _buy_price(item_id: String) -> int:
	var tpl: Dictionary = DataManager.get_item(item_id) if DataManager else {}
	var type_name := str(tpl.get("type", "material"))
	match type_name:
		"consumable":
			return 25
		"weapon", "armor", "accessory":
			return 60
		"building":
			return 10
		"key":
			return 120
		_:
			return 8

func _sell_price(item_id: String) -> int:
	return maxi(1, int(round(_buy_price(item_id) * 0.5)))

# ---------- 输入 ----------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		if GameManager == null:
			return
		var st = GameManager.current_state
		if st == GameManager.GameState.PLAYING or st == GameManager.GameState.BUILDING or st == GameManager.GameState.INVENTORY:
			toggle_panel()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		close_panel()
		get_viewport().set_input_as_handled()

func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()

func open_panel() -> void:
	visible = true
	GameManager.open_ui(GameManager.GameState.INVENTORY)
	_refresh_all()
	AudioManager.play_sfx("ui_open")

func close_panel() -> void:
	visible = false
	GameManager.close_ui()
	AudioManager.play_sfx("ui_close")

# ---------- 刷新 ----------
func _refresh_all() -> void:
	if not visible:
		return
	_refresh_grid()
	_refresh_details()
	_refresh_equipment()
	_refresh_craft()
	var gold := root.find_child("GoldLabel", true, false)
	if gold is Label and GameManager:
		gold.text = "金币 %d" % GameManager.gold

func _refresh_grid() -> void:
	if GameManager.inventory == null:
		return
	for i in slot_buttons.size():
		var s: Dictionary = GameManager.inventory.get_slot(i)
		var button: Button = slot_buttons[i]
		if s.is_empty():
			button.text = ""
			button.modulate = Color.WHITE
			continue
		var item_id := str(s.get("id", ""))
		var tpl: Dictionary = DataManager.get_item(item_id) if DataManager else {}
		button.text = "%s\n×%d" % [str(tpl.get("name", item_id)), int(s.get("quantity", 1))]
		button.modulate = Color.from_string(str(tpl.get("color", "#ffffff")), Color.WHITE)
		button.modulate = Color(
			lerpf(1.0, button.modulate.r, 0.35),
			lerpf(1.0, button.modulate.g, 0.35),
			lerpf(1.0, button.modulate.b, 0.35)
		)

func _refresh_details() -> void:
	var s: Dictionary = GameManager.inventory.get_slot(selected_index) if GameManager.inventory else {}
	if s.is_empty():
		detail_name.text = "未选择物品"
		detail_desc.text = ""
		detail_stats.text = ""
		use_button.disabled = true
		equip_button.disabled = true
		sell_button.disabled = true
		return
	var item_id := str(s.get("id", ""))
	var tpl: Dictionary = DataManager.get_item(item_id) if DataManager else {}
	detail_name.text = str(tpl.get("name", item_id))
	detail_desc.text = str(tpl.get("description", ""))
	var type_name := str(tpl.get("type", ""))
	var stat_text := "类型：%s" % type_name
	var stats: Dictionary = tpl.get("stats", {})
	for key in stats.keys():
		stat_text += "\n%s +%s" % [str(key), str(stats[key])]
	var effect: Dictionary = tpl.get("effect", {})
	for key in effect.keys():
		stat_text += "\n恢复 %s +%s" % [str(key), str(effect[key])]
	detail_stats.text = stat_text
	use_button.disabled = type_name != "consumable"
	equip_button.disabled = not (type_name in ["weapon", "armor", "accessory"])
	sell_button.disabled = false

func _refresh_equipment() -> void:
	if equip_rows == null:
		return
	for child in equip_rows.get_children():
		child.queue_free()
	var player = GameManager.active_player
	var data = player.get_node_or_null("CharacterData") if player else null
	if data == null:
		return
	for slot_name in ["weapon", "armor", "accessory"]:
		var item: Dictionary = data.get_equipped(slot_name)
		var row := HBoxContainer.new()
		var label := Label.new()
		label.custom_minimum_size = Vector2(150, 24)
		label.add_theme_font_size_override("font_size", 12)
		label.text = "%s：%s" % [slot_name, str(item.get("name", "空"))]
		row.add_child(label)
		if not item.is_empty():
			var button := Button.new()
			button.text = "卸下"
			button.pressed.connect(_on_unequip_pressed.bind(slot_name))
			row.add_child(button)
		equip_rows.add_child(row)

func _refresh_craft() -> void:
	for recipe_id in craft_buttons.keys():
		var button: Button = craft_buttons[recipe_id]
		button.disabled = not GameManager.inventory.can_craft(str(recipe_id))

# ---------- 动作 ----------
func _on_slot_pressed(index: int) -> void:
	selected_index = index
	_refresh_details()

func _on_use_pressed() -> void:
	var player = GameManager.active_player
	var data = player.get_node_or_null("CharacterData") if player else null
	if data and GameManager.inventory.use_slot(selected_index, data):
		_refresh_all()

func _on_equip_pressed() -> void:
	var player = GameManager.active_player
	var data = player.get_node_or_null("CharacterData") if player else null
	if data and GameManager.inventory.equip_slot(selected_index, data):
		_refresh_all()

func _on_unequip_pressed(slot_name: String) -> void:
	var player = GameManager.active_player
	var data = player.get_node_or_null("CharacterData") if player else null
	if data and GameManager.inventory.unequip_slot(slot_name, data):
		_refresh_all()

func _on_sell_pressed() -> void:
	var s: Dictionary = GameManager.inventory.get_slot(selected_index)
	if s.is_empty():
		return
	GameManager.inventory.sell_slot(selected_index, _sell_price(str(s.get("id", ""))))
	_refresh_all()

func _on_craft_pressed(recipe_id: String) -> void:
	GameManager.inventory.craft(recipe_id)
	_refresh_all()

func _on_buy_pressed(item_id: String) -> void:
	GameManager.inventory.buy_item(item_id, _buy_price(item_id))
	_refresh_all()
