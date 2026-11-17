extends Node
## JSON save system (replaces RPG Maker XP save files).

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 4


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func slot_path(slot: int) -> String:
	return SAVE_DIR + "save%02d.json" % slot


func save_game(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	State.save_slot = slot
	var data := State.to_save_dict()
	data["map_name"] = DB.map_info(State.map_id).get("name", "Map %d" % State.map_id)
	var text := JSON.stringify(data, "\t")
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("Cannot write save file: " + slot_path(slot))
		return false
	f.store_string(text)
	f.close()
	return true


func load_game(slot: int) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Corrupt save file: " + path)
		return false
	State.load_save_dict(json.data)
	State.save_slot = slot
	return true


func exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func slot_info(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var text := FileAccess.get_file_as_string(slot_path(slot))
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var d: Dictionary = json.data
	return {
		"slot": slot,
		"map_name": d.get("map_name", ""),
		"saved_at": d.get("saved_at", ""),
		"playtime": float(d.get("playtime", 0.0)),
		"map_id": int(d.get("map_id", 1))
	}


func latest_slot() -> int:
	var best := -1
	var best_time := ""
	for i in range(1, SLOT_COUNT + 1):
		var info := slot_info(i)
		if info.is_empty():
			continue
		if str(info["saved_at"]) > best_time:
			best_time = str(info["saved_at"])
			best = i
	return best


func playtime_text(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
