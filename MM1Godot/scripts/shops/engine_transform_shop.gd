class_name EngineTransformShopScene
extends SimpleScene
## Scene_EngineTransformShop — upgrade tank engines using the transform table.


func _ready() -> void:
	title = "发动机改造"
	super._ready()


func build_entries() -> Array:
	var out: Array = []
	for tank in State.party.party_tanks():
		var engine: GameTank.Equipment = tank.engine
		if engine == null:
			continue
		var info: Array = engine.transform_information
		if info.size() < 2:
			continue
		var next: Dictionary = DB.mm_get("engines", int(info[0]))
		out.append({
			"label": "%s  %s" % [tank.name, engine.name],
			"sub": "%s  %dG" % [str(next.get("name", "")), int(info[1])],
			"tank": tank,
		})
	return out


func info_text() -> String:
	return "金钱 %dG" % State.party.gold


func on_confirm(index: int) -> void:
	if index >= entries.size():
		return
	var tank: GameTank = entries[index].get("tank", null)
	if tank == null or tank.engine == null:
		return
	if not tank.engine.is_normal():
		show_notice("发动机坏了，修好再来吧")
		return
	var info: Array = tank.engine.transform_information
	if info.size() < 2:
		show_notice("功率不能再提高了")
		return
	var price := int(info[1])
	if State.party.gold < price:
		show_notice("金钱不足")
		return
	State.party.gain_gold(-price)
	tank.engine.transform(int(info[0]))
	tank.hp = mini(tank.hp, tank.maxhp())
	show_notice("发动机改成了 %s" % tank.engine.name)
	rebuild()
