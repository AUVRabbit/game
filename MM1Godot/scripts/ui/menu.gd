class_name MenuScene
extends Control
## Main menu overlay: status, items, save, return.

const MAIN_RECT := Rect2(32, 24, 576, 432)
const LEFT_RECT := Rect2(48, 40, 176, 190)
const RIGHT_RECT := Rect2(240, 40, 352, 400)
const ROW_H := 28.0

var skin: Texture2D
var mode := "root"          # root / status / items / save
var cursor := 0
var item_cursor := 0
var save_cursor := 0
var notice := ""
var _notice_time := 0.0
var commands: Array[String] = ["状态", "物品", "存档", "返回"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	skin = DB.windowskin_texture(str(DB.system.get("windowskin_name", "DefultSkin")))
	Audio.cursor()


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			notice = ""
			queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.55))
	UISkin.draw_window(self, MAIN_RECT, skin, 0.92)
	UISkin.draw_text(self, Vector2(MAIN_RECT.position.x + 16, MAIN_RECT.position.y + 26), "菜单", 18)
	UISkin.draw_text_right(self, Rect2(MAIN_RECT.position.x, MAIN_RECT.position.y + 8, MAIN_RECT.size.x - 16, 26),
		"金钱 %d" % State.party.gold, 18)
	match mode:
		"root":
			_draw_root()
		"status":
			_draw_status()
		"items":
			_draw_items()
		"save":
			_draw_save()
	if not notice.is_empty():
		var rect := Rect2(160, 400, 320, 44)
		UISkin.draw_window(self, rect, skin, 0.95)
		UISkin.draw_text_center(self, rect, notice, 16)


func _draw_root() -> void:
	UISkin.draw_window(self, LEFT_RECT, skin, 0.9)
	var y := LEFT_RECT.position.y + 16
	for i in range(commands.size()):
		UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 40, y + 18), commands[i], 18)
		if i == cursor:
			UISkin.draw_cursor(self, Rect2(LEFT_RECT.position.x + 8, y, LEFT_RECT.size.x - 16, ROW_H), skin)
		y += ROW_H
	UISkin.draw_window(self, RIGHT_RECT, skin, 0.9)
	_draw_party_summary()
	UISkin.draw_text(self, Vector2(56, 456), "Z 确定   X 返回", 14, Color(0.8, 0.8, 0.8))


func _draw_party_summary() -> void:
	var x := RIGHT_RECT.position.x + 20
	var y := RIGHT_RECT.position.y + 30
	var actors: Array = State.party.member_actors()
	for a in actors:
		UISkin.draw_text(self, Vector2(x, y), "%s  Lv%d  HP %d/%d" % [a.name, a.level, a.hp, a.maxhp()], 18)
		y += 26
	y += 6
	for t in State.party.member_tanks():
		UISkin.draw_text(self, Vector2(x, y), "%s  装甲 %d/%d" % [t.name, t.hp, t.maxhp()], 18)
		y += 26
	if y < RIGHT_RECT.position.y + 150:
		UISkin.draw_text(self, Vector2(x, y + 12), "持有物品 %d 种" % State.party.actor_items.size(), 16,
			Color(0.8, 0.8, 0.8))


func _draw_status() -> void:
	UISkin.draw_window(self, RIGHT_RECT, skin, 0.9)
	var x := RIGHT_RECT.position.x + 20
	var y := RIGHT_RECT.position.y + 30
	for a in State.party.member_actors():
		UISkin.draw_text(self, Vector2(x, y), "%s  等级 %d" % [a.name, a.level], 18)
		y += 24
		UISkin.draw_text(self, Vector2(x, y), "HP %d/%d   SP %d/%d" % [a.hp, a.maxhp(), a.sp, a.maxsp()], 16)
		y += 24
		UISkin.draw_text(self, Vector2(x, y), "攻击 %d  防御 %d  敏捷 %d" % [a.atk(), a.pdef(), a.agi()], 16)
		y += 34
	for t in State.party.member_tanks():
		UISkin.draw_text(self, Vector2(x, y), "%s  装甲 %d/%d" % [t.name, t.hp, t.maxhp()], 18)
		y += 22
		UISkin.draw_text(self, Vector2(x, y), "主炮 %s  副炮 %s" % [t.display_slot("main_cannon"), t.display_slot("sub_cannon")], 14)
		y += 22
		UISkin.draw_text(self, Vector2(x, y), "SE %s  引擎 %s" % [t.display_slot("se"), t.display_slot("engine")], 14)
		y += 30


func _item_ids() -> Array:
	var ids: Array = State.party.actor_items.keys()
	ids.sort()
	return ids


func _draw_items() -> void:
	UISkin.draw_window(self, LEFT_RECT, skin, 0.9)
	var ids := _item_ids()
	if ids.is_empty():
		UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 16, LEFT_RECT.position.y + 40), "没有物品", 16)
		return
	var start := maxi(0, item_cursor - 5)
	var y := LEFT_RECT.position.y + 12
	for i in range(start, min(start + 6, ids.size())):
		var item: Dictionary = DB.mm_get("actor_items", int(ids[i]))
		var count := int(State.party.actor_items[ids[i]])
		UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 40, y + 18), "%s x%d" % [str(item.get("name", "?")), count], 16)
		if i == item_cursor:
			UISkin.draw_cursor(self, Rect2(LEFT_RECT.position.x + 8, y, LEFT_RECT.size.x - 16, ROW_H), skin)
		y += ROW_H
	UISkin.draw_window(self, RIGHT_RECT, skin, 0.9)
	if item_cursor < ids.size():
		var item2: Dictionary = DB.mm_get("actor_items", int(ids[item_cursor]))
		UISkin.draw_text(self, Vector2(RIGHT_RECT.position.x + 20, RIGHT_RECT.position.y + 40),
			str(item2.get("name", "")), 20)
		UISkin.draw_text(self, Vector2(RIGHT_RECT.position.x + 20, RIGHT_RECT.position.y + 78),
			"价格 %d" % int(item2.get("price", 0)), 16)
		UISkin.draw_text(self, Vector2(RIGHT_RECT.position.x + 20, RIGHT_RECT.position.y + 106),
			"HP回复 %d" % int(item2.get("hp_effect", 0)), 16)


func _draw_save() -> void:
	UISkin.draw_window(self, LEFT_RECT, skin, 0.9)
	var y := LEFT_RECT.position.y + 12
	for i in range(1, 5):
		var info: Dictionary = Saver.slot_info(i)
		var label := "存档 %d  空" % i
		if not info.is_empty():
			label = "存档 %d  %s  %s" % [i, str(info.get("map_name", "")), Saver.playtime_text(float(info.get("playtime", 0.0)))]
		UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 40, y + 18), label, 15)
		if i - 1 == save_cursor:
			UISkin.draw_cursor(self, Rect2(LEFT_RECT.position.x + 8, y, LEFT_RECT.size.x - 16, ROW_H), skin)
		y += ROW_H
	UISkin.draw_window(self, RIGHT_RECT, skin, 0.9)
	UISkin.draw_text(self, Vector2(RIGHT_RECT.position.x + 20, RIGHT_RECT.position.y + 40), "选择存档位并按 Z 保存", 16)


# --------------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if mode == "root":
			close()
		else:
			mode = "root"
			cursor = 0
			queue_redraw()
		return
	if mode == "root":
		if event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			cursor = (cursor - 1 + commands.size()) % commands.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			cursor = (cursor + 1) % commands.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("action"):
			get_viewport().set_input_as_handled()
			Audio.decision()
			match cursor:
				0: mode = "status"
				1: mode = "items"
				2: mode = "save"
				3: close()
			queue_redraw()
	elif mode == "items":
		_handle_list_input(event, _item_ids().size(), true)
	elif mode == "save":
		if event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			save_cursor = (save_cursor - 1 + 4) % 4
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			save_cursor = (save_cursor + 1) % 4
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("action"):
			get_viewport().set_input_as_handled()
			Audio.decision()
			Saver.save_game(save_cursor + 1)
			_show_notice("已保存到存档 %d" % (save_cursor + 1))
	elif mode == "status":
		pass


func _handle_list_input(event: InputEvent, count: int, usable: bool) -> void:
	if count <= 0:
		return
	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		item_cursor = (item_cursor - 1 + count) % count
		Audio.cursor()
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		item_cursor = (item_cursor + 1) % count
		Audio.cursor()
		queue_redraw()
	elif event.is_action_pressed("action") and usable:
		get_viewport().set_input_as_handled()
		_use_item()


func _use_item() -> void:
	var ids := _item_ids()
	if item_cursor >= ids.size():
		return
	var item_id := int(ids[item_cursor])
	var item: Dictionary = DB.mm_get("actor_items", item_id)
	var actors: Array = State.party.member_actors()
	if actors.is_empty():
		return
	var target = actors[0]
	var heal := int(item.get("hp_effect", 0))
	if heal <= 0:
		_show_notice("现在无法使用")
		return
	target.hp = mini(target.hp + heal, target.maxhp())
	State.party.lose_item(item_id, 1)
	Audio.decision()
	_show_notice("%s 回复了 %d HP" % [target.name, heal])
	queue_redraw()


func _show_notice(text: String) -> void:
	notice = text
	_notice_time = 1.6
	queue_redraw()


func close() -> void:
	Router.close_overlay()
