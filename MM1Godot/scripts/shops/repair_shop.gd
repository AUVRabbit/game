class_name RepairShopScene
extends SimpleScene


func _ready() -> void:
	title = "修理店"
	super._ready()


func build_entries() -> Array:
	var out: Array = []
	for t in State.party.member_tanks():
		out.append({"label": "%s  装甲 %d/%d" % [t.name, t.hp, t.maxhp()],
			"sub": "修理费 %dG" % t.repair_cost_all(), "tank": t})
	return out


func info_text() -> String:
	return "金钱 %dG" % State.party.gold


func on_confirm(index: int) -> void:
	var t: GameTank = entries[index].get("tank")
	if t == null:
		return
	var cost := t.repair_cost_all()
	if cost <= 0:
		show_notice("没有需要修理的部件")
		return
	if State.party.gold < cost:
		show_notice("金钱不足")
		return
	State.party.gain_gold(-cost)
	t.repair_all()
	t.hp = maxi(t.hp, 1)
	rebuild()
	show_notice("修理完成（-%dG）" % cost)
