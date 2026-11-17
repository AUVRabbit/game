class_name ShopScene
extends Control
## People / tank equipment & item shop (replaces Scene_Shop).

const LEFT_RECT := Rect2(16, 32, 200, 360)
const LIST_RECT := Rect2(232, 32, 392, 360)
const BOTTOM_RECT := Rect2(16, 404, 608, 60)
const ROW_H := 28.0

var skin: Texture2D
var phase := "command"
var command_index := 0
var target_index := 0
var cursor := 0
var notice := ""
var _notice_time := 0.0
var commands: Array[String] = ["买", "卖", "离开"]
var _goods_cache: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	skin = DB.windowskin_texture(str(DB.system.get("windowskin_name", "DefultSkin")))
	set_process(true)
	Audio.cursor()


func shop_type() -> int:
	return int(State.temp.get("shop_type", 0))


func _is_tank_shop() -> bool:
	var t := shop_type()
	return t == 2 or t == 3


func _targets() -> Array:
	if _is_tank_shop():
		return State.party.member_tanks()
	return State.party.member_actors()


func _target() -> Variant:
	var list := _targets()
	if list.is_empty():
		return null
	target_index = clampi(target_index, 0, list.size() - 1)
	return list[target_index]


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			notice = ""
			queue_redraw()


# ------------------------------------------------------------------ goods
func _table_for(kind: String) -> String:
	match kind:
		"main_cannon": return "main_cannons"
		"sub_cannon": return "sub_cannons"
		"se": return "ses"
		"c_unit": return "c_units"
		"engine": return "engines"
		"underpan": return "underpans"
		"tank_item": return "tank_items"
		"actor_item": return "actor_items"
	return ""


func _make_good(kind: String, id: int) -> Dictionary:
	var item: Dictionary = {}
	if kind == "weapon":
		item = DB.weapon(id)
	elif kind == "armor":
		item = DB.armor(id)
	else:
		item = DB.mm_get(_table_for(kind), id)
	if item.is_empty():
		return {}
	return {"kind": kind, "id": id, "item": item}


func _goods() -> Array:
	if not _goods_cache.is_empty():
		return _goods_cache
	var goods: Array = []
	for g in State.temp.get("shop_goods", []):
		if g is Dictionary and not g.is_empty():
			goods.append(g)
	if goods.is_empty():
		var t := shop_type()
		if t == 0:
			for i in range(1, DB.weapons.size()):
				var w := _make_good("weapon", i)
				if not w.is_empty():
					goods.append(w)
			for i in range(1, DB.armors.size()):
				var a := _make_good("armor", i)
				if not a.is_empty():
					goods.append(a)
		elif t == 1:
			for i in range(1, DB.mm_list("actor_items").size()):
				var it := _make_good("actor_item", i)
				if not it.is_empty():
					goods.append(it)
		elif t == 2:
			for pair in [["main_cannon", "main_cannons"], ["sub_cannon", "sub_cannons"],
					["se", "ses"], ["c_unit", "c_units"], ["engine", "engines"], ["underpan", "underpans"]]:
				var list: Array = DB.mm_list(str(pair[1]))
				for i in range(1, list.size()):
					var eq := _make_good(str(pair[0]), i)
					if not eq.is_empty():
						goods.append(eq)
		else:
			for i in range(1, DB.mm_list("tank_items").size()):
				var ti := _make_good("tank_item", i)
				if not ti.is_empty():
					goods.append(ti)
	_goods_cache = goods
	return goods


func _price(good: Dictionary) -> int:
	return int(good.get("item", {}).get("price", 0))


func _good_name(good: Dictionary) -> String:
	return str(good.get("item", {}).get("name", "?"))


func _sell_entries() -> Array:
	var out: Array = []
	var target = _target()
	if target == null:
		return out
	if target is GameTank:
		for slot in ["main_cannon", "sub_cannon", "se", "c_unit", "engine", "underpan"]:
			var eq: GameTank.Equipment = target.slot_equipment(slot)
			if eq != null:
				out.append({"kind": slot, "id": eq.id, "item": DB.mm_get(_table_for(slot), eq.id), "slot": slot})
		for id in State.party.tank_items.keys():
			var item: Dictionary = DB.mm_get("tank_items", int(id))
			out.append({"kind": "tank_item", "id": int(id), "item": item, "count": int(State.party.tank_items[id])})
	else:
		var wid := int(target.equipment.get("weapon", 0))
		if wid > 0:
			out.append({"kind": "weapon", "id": wid, "item": DB.weapon(wid), "slot_index": 0})
		for i in range(1, 5):
			var aid := int(target.equipment.get("armor%d" % i, 0))
			if aid > 0:
				out.append({"kind": "armor", "id": aid, "item": DB.armor(aid), "slot_index": i})
		for id2 in State.party.actor_items.keys():
			var it2: Dictionary = DB.mm_get("actor_items", int(id2))
			out.append({"kind": "actor_item", "id": int(id2), "item": it2, "count": int(State.party.actor_items[id2])})
	return out


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.55))
	UISkin.draw_window(self, LEFT_RECT, skin, 0.92)
	UISkin.draw_window(self, LIST_RECT, skin, 0.92)
	UISkin.draw_window(self, BOTTOM_RECT, skin, 0.92)
	UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 14, LEFT_RECT.position.y + 26),
		"战车" if _is_tank_shop() else "人物", 16)
	_draw_targets()
	_draw_list()
	_draw_bottom()
	if not notice.is_empty():
		var rect := Rect2(160, 356, 320, 42)
		UISkin.draw_window(self, rect, skin, 0.96)
		UISkin.draw_text_center(self, rect, notice, 15)


func _draw_targets() -> void:
	var list := _targets()
	var y := LEFT_RECT.position.y + 56
	if list.is_empty():
		UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 16, y), "没有战车" if _is_tank_shop() else "没有成员", 15)
		return
	for i in range(list.size()):
		var t = list[i]
		var label := ""
		if t is GameTank:
			label = "%s 装甲%d" % [t.name, t.hp]
		else:
			label = "%s HP%d" % [t.name, t.hp]
		UISkin.draw_text(self, Vector2(LEFT_RECT.position.x + 28, y + 18), label, 15)
		if i == target_index:
			UISkin.draw_cursor(self, Rect2(LEFT_RECT.position.x + 6, y, LEFT_RECT.size.x - 12, ROW_H), skin)
		y += ROW_H


func _draw_list() -> void:
	var items: Array = _goods() if phase != "sell" else _sell_entries()
	UISkin.draw_text(self, Vector2(LIST_RECT.position.x + 14, LIST_RECT.position.y + 26),
		"商品" if phase != "sell" else "持有品", 16)
	var start := maxi(0, cursor - 8)
	var y := LIST_RECT.position.y + 46
	for i in range(start, mini(start + 9, items.size())):
		var it: Dictionary = items[i]
		var name := str(it.get("item", {}).get("name", "?"))
		var price := int(it.get("item", {}).get("price", 0))
		var count := int(it.get("count", 0))
		var label := name
		if count > 0:
			label += " x%d" % count
		if phase == "sell":
			label += "  %dG" % int(price / 2)
		else:
			label += "  %dG" % price
		UISkin.draw_text(self, Vector2(LIST_RECT.position.x + 30, y + 18), label, 15)
		if i == cursor:
			UISkin.draw_cursor(self, Rect2(LIST_RECT.position.x + 6, y, LIST_RECT.size.x - 12, ROW_H), skin)
		y += ROW_H
	if items.is_empty():
		UISkin.draw_text(self, Vector2(LIST_RECT.position.x + 30, y + 18), "什么也没有", 15)


func _draw_bottom() -> void:
	UISkin.draw_text(self, Vector2(BOTTOM_RECT.position.x + 18, BOTTOM_RECT.position.y + 24),
		"金钱 %dG" % State.party.gold, 17)
	if phase == "command":
		var x := BOTTOM_RECT.position.x + 200
		for i in range(commands.size()):
			UISkin.draw_text(self, Vector2(x, BOTTOM_RECT.position.y + 24), commands[i], 17)
			if i == command_index:
				UISkin.draw_cursor(self, Rect2(x - 10, BOTTOM_RECT.position.y + 4, 72, 32), skin)
			x += 90
		UISkin.draw_text(self, Vector2(BOTTOM_RECT.position.x + 18, BOTTOM_RECT.position.y + 50),
			"← → 选择对象   Z 确定   X 离开", 12, Color(0.75, 0.75, 0.75))
	else:
		UISkin.draw_text(self, Vector2(BOTTOM_RECT.position.x + 200, BOTTOM_RECT.position.y + 24),
			"↑↓ 选择   Z 确定   X 返回", 14)
		UISkin.draw_text_right(self, Rect2(BOTTOM_RECT.position.x, BOTTOM_RECT.position.y + 8, BOTTOM_RECT.size.x - 18, 24),
			"", 14)


# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if phase == "command":
			Router.close_overlay()
		else:
			phase = "command"
			cursor = 0
			queue_redraw()
		return
	if phase == "command":
		if event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			command_index = (command_index - 1 + commands.size()) % commands.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			command_index = (command_index + 1) % commands.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			var list := _targets()
			if not list.is_empty():
				var d := -1 if event.is_action_pressed("move_left") else 1
				target_index = (target_index + d + list.size()) % list.size()
				Audio.cursor()
				queue_redraw()
		elif event.is_action_pressed("action"):
			get_viewport().set_input_as_handled()
			Audio.decision()
			match command_index:
				0: phase = "buy"; cursor = 0; queue_redraw()
				1: phase = "sell"; cursor = 0; queue_redraw()
				2: Router.close_overlay()
		return
	var items: Array = _goods() if phase == "buy" else _sell_entries()
	if items.is_empty():
		return
	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		cursor = (cursor - 1 + items.size()) % items.size()
		Audio.cursor()
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		cursor = (cursor + 1) % items.size()
		Audio.cursor()
		queue_redraw()
	elif event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		Audio.decision()
		if phase == "buy":
			_buy(items[cursor])
		else:
			_sell(items[cursor])
		queue_redraw()


# ------------------------------------------------------------------ transactions
func _buy(good: Dictionary) -> void:
	var price := _price(good)
	if price <= 0:
		_show_notice("这个不能买")
		return
	if State.party.gold < price:
		_show_notice("金钱不足")
		return
	var target = _target()
	if _is_tank_shop() and target == null:
		_show_notice("没有战车")
		return
	var kind := str(good.get("kind", ""))
	var id := int(good.get("id", 0))
	State.party.gain_gold(-price)
	match kind:
		"weapon":
			if target is GameActor:
				target.equip(0, id)
		"armor":
			if target is GameActor:
				target.equip(1, id)
		"actor_item":
			State.party.gain_item(id, 1)
		"tank_item":
			State.party.gain_tank_item(id, 1)
		_:
			if target is GameTank:
				target.equip_slot(kind, id)
	_show_notice("买下了 %s" % _good_name(good))


func _sell(entry: Dictionary) -> void:
	var price := int(int(entry.get("item", {}).get("price", 0)) / 2)
	var target = _target()
	if price <= 0:
		_show_notice("这个不能卖")
		return
	var kind := str(entry.get("kind", ""))
	var id := int(entry.get("id", 0))
	State.party.gain_gold(price)
	match kind:
		"weapon", "armor":
			if target is GameActor:
				target.equip(int(entry.get("slot_index", 0)), 0)
		"actor_item":
			State.party.lose_item(id, 1)
		"tank_item":
			State.party.lose_tank_item(id, 1)
		_:
			if target is GameTank:
				target.equip_slot(kind, 0)
	_show_notice("卖掉了 %s（+%dG）" % [str(entry.get("item", {}).get("name", "?")), price])
	if cursor >= _sell_entries().size():
		cursor = maxi(0, _sell_entries().size() - 1)


func _show_notice(text: String) -> void:
	notice = text
	_notice_time = 1.6
	queue_redraw()
