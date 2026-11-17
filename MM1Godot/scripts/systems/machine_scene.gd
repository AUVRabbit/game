class_name MachineScene
extends SimpleScene


func _ready() -> void:
	title = "电脑"
	super._ready()


func build_entries() -> Array:
	var out: Array = []
	var machine_type := int(State.temp.get("machine_type", 0))
	if machine_type == 1 or machine_type == 2:
		for info in DB.map_infos:
			if info is Dictionary and int(info.get("id", 0)) > 0:
				out.append({"label": str(info.get("name", "楼层")), "sub": "移动",
					"map_id": int(info.get("id", 0))})
		return out
	for a in State.party.member_actors():
		var next_exp := a.exp_for_level(a.level + 1)
		out.append({"label": "%s  Lv%d" % [a.name, a.level],
			"sub": "距离下一级 %d" % maxi(next_exp - a.exp, 0)})
	return out


func info_text() -> String:
	return "经验查询" if int(State.temp.get("machine_type", 0)) == 0 else "楼层移动"


func on_confirm(index: int) -> void:
	if index >= entries.size():
		return
	var map_id := int(entries[index].get("map_id", 0))
	if map_id > 0:
		Router.close_overlay()
		Router.load_map(map_id, 9, 7, 2, true)
		return
	show_notice("需要更多经验才能升级")
