class_name SupplyShopScene
extends SimpleScene


func _ready() -> void:
	title = "补给店"
	super._ready()


func build_entries() -> Array:
	var out: Array = []
	for t in State.party.member_tanks():
		var missing := t.ammo_missing()
		out.append({"label": "%s  弹药不足 %d" % [t.name, missing],
			"sub": "补给费 %dG" % (missing * 2), "tank": t})
	return out


func info_text() -> String:
	return "金钱 %dG" % State.party.gold


func on_confirm(index: int) -> void:
	var t: GameTank = entries[index].get("tank")
	if t == null:
		return
	var missing := t.ammo_missing()
	if missing <= 0:
		show_notice("弹药已满")
		return
	var cost := missing * 2
	if State.party.gold < cost:
		show_notice("金钱不足")
		return
	State.party.gain_gold(-cost)
	t.full_ammo()
	rebuild()
	show_notice("补给完成（-%dG）" % cost)
