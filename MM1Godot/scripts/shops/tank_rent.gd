class_name TankRentScene
extends SimpleScene

const RENT_COST := 200


func _ready() -> void:
	title = "战车出租"
	super._ready()


func _rent_ids() -> Array:
	var list_id := int(State.temp.get("rent_tanks_id", 0))
	var ids = DB.mm_get("data_rent_tank_list", list_id if list_id > 0 else 1)
	if not (ids is Array):
		return []
	return ids


func build_entries() -> Array:
	var out: Array = []
	for id in _rent_ids():
		var data: Dictionary = DB.mm_get("tanks", int(id))
		if data.is_empty():
			continue
		out.append({"label": str(data.get("name", "战车")), "sub": "%dG" % RENT_COST,
			"tank_id": int(id)})
	return out


func info_text() -> String:
	return "金钱 %dG" % State.party.gold


func on_confirm(index: int) -> void:
	var tank_id := int(entries[index].get("tank_id", 0))
	if tank_id <= 0:
		return
	for t in State.party.party_tanks():
		if t.id == tank_id:
			show_notice("已经拥有这辆战车")
			return
	if State.party.gold < RENT_COST:
		show_notice("金钱不足")
		return
	State.party.gain_gold(-RENT_COST)
	State.party.add_tank(tank_id)
	show_notice("租借了 %s" % DB.mm_get("tanks", tank_id).get("name", "战车"))
	await get_tree().create_timer(0.6).timeout
	Router.close_overlay()
