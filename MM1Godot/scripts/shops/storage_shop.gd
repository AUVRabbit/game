class_name StorageShopScene
extends SimpleScene

var mode := "deposit"


func _ready() -> void:
	title = "仓库"
	super._ready()


func on_side(direction: int) -> void:
	if direction < 0:
		mode = "deposit"
	elif direction > 0:
		mode = "withdraw"
	cursor = 0
	rebuild()


func build_entries() -> Array:
	var out: Array = []
	if mode == "deposit":
		for id in State.party.actor_items.keys():
			var item: Dictionary = DB.mm_get("actor_items", int(id))
			out.append({"label": str(item.get("name", "?")), "sub": "x%d" % int(State.party.actor_items[id]),
				"kind": "actor_item", "id": int(id)})
		for id2 in State.party.tank_items.keys():
			var item2: Dictionary = DB.mm_get("tank_items", int(id2))
			out.append({"label": str(item2.get("name", "?")), "sub": "x%d" % int(State.party.tank_items[id2]),
				"kind": "tank_item", "id": int(id2)})
	else:
		for entry in State.party.trunk:
			var table := "actor_items" if str(entry.get("type", "")) == "actor_item" else "tank_items"
			var item3: Dictionary = DB.mm_get(table, int(entry.get("id", 0)))
			out.append({"label": str(item3.get("name", "?")), "sub": "x%d" % int(entry.get("count", 0)),
				"kind": str(entry.get("type", "actor_item")), "id": int(entry.get("id", 0))})
	return out


func info_text() -> String:
	return "存入" if mode == "deposit" else "取出"


func on_confirm(index: int) -> void:
	if index >= entries.size():
		return
	var e: Dictionary = entries[index]
	var kind := str(e.get("kind", "actor_item"))
	var item_id := int(e.get("id", 0))
	if mode == "deposit":
		if kind == "actor_item":
			State.party.lose_item(item_id, 1)
		else:
			State.party.lose_tank_item(item_id, 1)
		State.party.trunk_add(kind, item_id, 1)
		show_notice("存入了 %s" % str(e.get("label", "")))
	else:
		var found := -1
		for i in range(State.party.trunk.size()):
			var entry: Dictionary = State.party.trunk[i]
			if str(entry.get("type", "")) == kind and int(entry.get("id", 0)) == item_id:
				found = i
				break
		if found < 0:
			return
		var entry2: Dictionary = State.party.trunk[found]
		entry2["count"] = int(entry2.get("count", 1)) - 1
		if int(entry2["count"]) <= 0:
			State.party.trunk.remove_at(found)
		if kind == "actor_item":
			State.party.gain_item(item_id, 1)
		else:
			State.party.gain_tank_item(item_id, 1)
		show_notice("取出了 %s" % str(e.get("label", "")))
	rebuild()
