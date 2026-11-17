class_name SaveScene
extends SimpleScene
## Scene_Save — save the game into one of the four slots.


func _ready() -> void:
	title = "存档"
	super._ready()


func build_entries() -> Array:
	var out: Array = []
	for i in range(1, Saver.SLOT_COUNT + 1):
		var info := Saver.slot_info(i)
		if info.is_empty():
			out.append({"label": "存档 %d" % i, "sub": "空", "slot": i})
		else:
			out.append({
				"label": "存档 %d  %s" % [i, str(info.get("map_name", ""))],
				"sub": "%s  %s" % [Saver.playtime_text(float(info.get("playtime", 0.0))),
					str(info.get("saved_at", "")).replace("T", " ")],
				"slot": i,
			})
	return out


func info_text() -> String:
	return "选择存档位置"


func on_confirm(index: int) -> void:
	if index >= entries.size():
		return
	var slot := int(entries[index].get("slot", index + 1))
	if Saver.save_game(slot):
		show_notice("存档完成")
		rebuild()
		await get_tree().create_timer(0.8).timeout
		Router.close_overlay()
	else:
		show_notice("存档失败")
