class_name CannonBallShopScene
extends SimpleScene
## Scene_CannonBallShop — buy normal ammo for cannons / special cannonballs, sell special balls.

const MODE_BUY := 0
const MODE_SELL := 1
const SLOT_LABELS := {"main_cannon": "主炮", "sub_cannon": "副炮", "se": "SE"}

var mode := MODE_BUY
var _last_tank_index := 0


func _ready() -> void:
	title = "炮弹店"
	super._ready()


func _tank_list() -> Array:
	return State.party.party_tanks()


func build_entries() -> Array:
	var out: Array = []
	var tanks := _tank_list()
	if mode == MODE_BUY:
		for ti in range(tanks.size()):
			var tank: GameTank = tanks[ti]
			for slot in ["main_cannon", "sub_cannon", "se"]:
				var e: GameTank.Equipment = tank.slot_equipment(slot)
				if e == null or e.quantity <= 0 or e.quantity_reality >= e.quantity:
					continue
				out.append({
					"label": "%s %s %s" % [tank.name, SLOT_LABELS[slot], e.name],
					"sub": "%d/%d  %dG" % [e.quantity_reality, e.quantity, _ammo_price(e)],
					"kind": "ammo", "tank": tank, "slot": slot,
				})
		for data in DB.mm_list("special_cannonballs"):
			if data is not Dictionary or int(data.get("id", 0)) <= 0:
				continue
			for tank in tanks:
				if _special_space(tank) <= 0:
					continue
				out.append({
					"label": "%s 特殊弹 %s" % [tank.name, str(data.get("name", ""))],
					"sub": "%dG  弹仓 %d/%d" % [int(data.get("price", 0)), _special_used(tank),
						tank.underpan.special_cannonball_capacity if tank.underpan != null else 0],
					"kind": "special", "tank": tank, "ball_id": int(data.get("id", 0)),
				})
	else:
		for tank in tanks:
			for key in tank.special_cannonballs.keys():
				var count := int(tank.special_cannonballs[key])
				if count <= 0:
					continue
				var data: Dictionary = DB.mm_get("special_cannonballs", int(key))
				out.append({
					"label": "%s 的 %s ×%d" % [tank.name, str(data.get("name", "")), count],
					"sub": "%dG" % (int(data.get("price", 0)) / 2),
					"kind": "sell", "tank": tank, "ball_id": int(key),
				})
	return out


func _ammo_price(e: GameTank.Equipment) -> int:
	var p := e.cannonball_price()
	return p if p > 0 else 5


func _special_used(tank: GameTank) -> int:
	var used := 0
	for key in tank.special_cannonballs:
		used += int(tank.special_cannonballs[key])
	return used


func _special_space(tank: GameTank) -> int:
	if tank.underpan == null:
		return 0
	return tank.underpan.special_cannonball_capacity - _special_used(tank)


func info_text() -> String:
	var label := "购买" if mode == MODE_BUY else "出售"
	return "%s   金钱 %dG" % [label, State.party.gold]


func on_side(_direction: int) -> void:
	mode = MODE_SELL if mode == MODE_BUY else MODE_BUY
	cursor = 0
	rebuild()


func on_confirm(index: int) -> void:
	if index >= entries.size():
		return
	var e: Dictionary = entries[index]
	match str(e.get("kind", "")):
		"ammo":
			var equip: GameTank.Equipment = e["tank"].slot_equipment(e["slot"])
			var price := _ammo_price(equip)
			if State.party.gold < price:
				show_notice("金钱不足")
				return
			State.party.gain_gold(-price)
			equip.quantity_add(1)
			show_notice("补充了 1 发炮弹")
		"special":
			var data: Dictionary = DB.mm_get("special_cannonballs", int(e["ball_id"]))
			var price2 := int(data.get("price", 0))
			if State.party.gold < price2:
				show_notice("金钱不足")
				return
			if _special_space(e["tank"]) <= 0:
				show_notice("弹仓已满")
				return
			State.party.gain_gold(-price2)
			e["tank"].add_special_ball(int(e["ball_id"]), 1)
			show_notice("补充了 1 枚特殊弹")
		"sell":
			var price3 := int(DB.mm_get("special_cannonballs", int(e["ball_id"])).get("price", 0)) / 2
			e["tank"].use_special_ball(int(e["ball_id"]))
			State.party.gain_gold(price3)
			show_notice("卖掉了 1 枚，得到 %dG" % price3)
	rebuild()
