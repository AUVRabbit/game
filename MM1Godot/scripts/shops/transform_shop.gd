class_name TransformShopScene
extends SimpleScene
## Scene_TransformShop — underpan upgrades: magazine, defense, open cannon holes.

const STAGE_TANK := 0
const STAGE_COMMAND := 1

var stage := STAGE_TANK
var tank: GameTank = null


func _ready() -> void:
	title = "改造店"
	super._ready()


func _tanks() -> Array:
	return State.party.party_tanks()


func build_entries() -> Array:
	var out: Array = []
	if stage == STAGE_TANK:
		for t in _tanks():
			out.append({"label": t.name, "sub": "底盘 %s" % t.display_slot("underpan"), "tank": t})
		return out
	if tank == null:
		return out
	var underpan: GameTank.Equipment = tank.underpan
	if underpan == null:
		return out
	out.append({"label": "弹仓扩大", "sub": "容量 %d" % underpan.special_cannonball_capacity,
		"action": "magazine"})
	out.append({"label": "防御改造", "sub": "防御 %d" % underpan.pdef, "action": "defense"})
	for i in range(3):
		var label: String = ["主炮打洞", "副炮打洞", "SE 打洞"][i]
		out.append({"label": label, "sub": "已开" if underpan.hole_opened(i) else "5000G",
			"action": "hole%d" % i})
	return out


func info_text() -> String:
	if stage == STAGE_TANK:
		return "金钱 %dG" % State.party.gold
	return "%s   金钱 %dG" % [tank.name if tank != null else "", State.party.gold]


func on_cancel() -> void:
	if stage == STAGE_COMMAND:
		stage = STAGE_TANK
		tank = null
		cursor = 0
		rebuild()
		return
	Router.close_overlay()


func on_confirm(index: int) -> void:
	if index >= entries.size():
		return
	if stage == STAGE_TANK:
		tank = entries[index].get("tank", null)
		stage = STAGE_COMMAND
		cursor = 0
		rebuild()
		return
	_apply(str(entries[index].get("action", "")))


func _free_space() -> float:
	if tank == null:
		return 0.0
	return tank.load_max() - tank.load_reality()


func _apply(action: String) -> void:
	if tank == null or tank.underpan == null:
		return
	var underpan: GameTank.Equipment = tank.underpan
	match action:
		"magazine":
			if underpan.special_cannonball_capacity >= 128:
				show_notice("弹仓已经改装过了")
				return
			var price := underpan.special_cannonball_capacity * 8
			if not _pay(price):
				return
			if _free_space() < 0.1:
				show_notice("超重了，需要更大的车型")
				State.party.gain_gold(price)
				return
			underpan.weight_change(underpan.weight + 0.1)
			underpan.special_cannonball_capacity_change(underpan.special_cannonball_capacity * 2)
			show_notice("弹仓扩大到 %d" % underpan.special_cannonball_capacity)
		"defense":
			if underpan.pdef >= 400:
				show_notice("防御已经改装过了")
				return
			var price2 := 200
			if not _pay(price2):
				return
			if _free_space() < 0.1:
				show_notice("超重了，需要更大的车型")
				State.party.gain_gold(price2)
				return
			underpan.weight_change(underpan.weight + 0.1)
			underpan.pdef_change(underpan.pdef + 10)
			show_notice("防御增加到 %d" % underpan.pdef)
		_:
			if not action.begins_with("hole"):
				return
			var pos := int(action.substr(4))
			if underpan.hole_opened(pos):
				show_notice("这个部位已经打过洞了")
				return
			var price3 := 5000
			if not _pay(price3):
				return
			if _free_space() < 0.5:
				show_notice("超重了，需要更大的车型")
				State.party.gain_gold(price3)
				return
			underpan.weight_change(underpan.weight + 0.5)
			underpan.open_hole(pos)
			show_notice("打洞完成")
	rebuild()


func _pay(price: int) -> bool:
	if State.party.gold < price:
		show_notice("金钱不足")
		return false
	State.party.gain_gold(-price)
	return true
