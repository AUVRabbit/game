extends Node
## Global database access. Loads all JSON exported from the original RPG Maker XP project.

const DATA_DIR := "res://data/"

var system: Dictionary = {}
var actors: Array = []
var classes: Array = []
var skills: Array = []
var items: Array = []
var weapons: Array = []
var armors: Array = []
var enemies: Array = []
var troops: Array = []
var states: Array = []
var animations: Array = []
var tilesets: Array = []
var common_events: Array = []
var map_infos: Array = []
var mm: Dictionary = {}

var _maps: Dictionary = {}
var _tileset_image_cache: Dictionary = {}


func _ready() -> void:
	_load("system", "system")
	for entry in ["actors", "classes", "skills", "items", "weapons", "armors",
			"enemies", "troops", "states", "animations", "tilesets",
			"common_events", "map_infos"]:
		_load(entry, entry)
	mm = _read_json(DATA_DIR + "mm/database.json")


func _load(file: String, key: String) -> void:
	var value = _read_json(DATA_DIR + file + ".json")
	set(key, value)


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("JSON parse failed %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data


# ------------------------------------------------------------------ databases
func actor(id: int) -> Dictionary:
	return _at(actors, id)


func klass(id: int) -> Dictionary:
	return _at(classes, id)


func skill(id: int) -> Dictionary:
	return _at(skills, id)


func item(id: int) -> Dictionary:
	return _at(items, id)


func weapon(id: int) -> Dictionary:
	return _at(weapons, id)


func armor(id: int) -> Dictionary:
	return _at(armors, id)


func enemy(id: int) -> Dictionary:
	return _at(enemies, id)


func troop(id: int) -> Dictionary:
	return _at(troops, id)


func state(id: int) -> Dictionary:
	return _at(states, id)


func common_event(id: int) -> Dictionary:
	return _at(common_events, id)


func tileset(id: int) -> Dictionary:
	return _at(tilesets, id)


func mm_list(name: String) -> Array:
	var raw = mm.get(name, [])
	return raw as Array if raw is Array else []


func mm_get(name: String, id: int) -> Dictionary:
	var raw = mm.get(name, [])
	if raw is Dictionary:
		var value = raw.get(str(id), raw.get(id, {}))
		return value if value is Dictionary else {}
	return _at(raw as Array, id)


func _at(list: Array, id: int) -> Dictionary:
	if id >= 0 and id < list.size() and list[id] is Dictionary:
		return list[id]
	return {}


# ----------------------------------------------------------------------- maps
func map_data(id: int) -> Dictionary:
	if _maps.has(id):
		return _maps[id]
	var path := DATA_DIR + "maps/map%03d.json" % id
	var data = _read_json(path)
	_maps[id] = data
	return data


func map_info(id: int) -> Dictionary:
	return _at(map_infos, id)


# ------------------------------------------------------------ actor parameters
func param(actor_data: Dictionary, param_id: int, level: int) -> int:
	var table: Dictionary = actor_data.get("parameters", {})
	var data: Array = table.get("data", [])
	var idx: int = level * 6 + param_id
	if idx >= 0 and idx < data.size():
		return int(data[idx])
	return 0


func exp_list(actor_data: Dictionary) -> Array:
	"""Cumulative EXP required per level (index 1..100), ported from Game_Actor."""
	var list := [0, 0]
	var basis: float = float(actor_data.get("exp_basis", 30))
	var inflation: float = float(actor_data.get("exp_inflation", 30))
	var final_level: int = int(actor_data.get("final_level", 99))
	var pow_i: float = 2.4 + inflation / 100.0
	for i in range(2, 101):
		if i > final_level:
			list.append(0)
		else:
			var n: float = basis * pow(float(i + 3), pow_i) / pow(5.0, pow_i)
			list.append(int(list[i - 1] + int(n)))
	return list


# -------------------------------------------------------------------- graphics
func character_texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	var path := "res://assets/graphics/Characters/%s.png" % name
	if ResourceLoader.exists(path):
		return load(path)
	return null


func battler_texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	for dir in ["Battlers", "Characters"]:
		var path := "res://assets/graphics/%s/%s" % [dir, name]
		if not path.ends_with(".png"):
			path += ".png"
		if ResourceLoader.exists(path):
			return load(path)
	return null


func picture_texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	var path := "res://assets/graphics/Pictures/%s" % name
	if not path.ends_with(".png") and not path.ends_with(".jpg"):
		path += ".png"
	if ResourceLoader.exists(path):
		return load(path)
	return null


func tileset_texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	if _tileset_image_cache.has(name):
		return _tileset_image_cache[name]
	var path := "res://assets/graphics/Tilesets/%s.png" % name
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tileset_image_cache[name] = tex
	return tex


func autotile_texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	if _tileset_image_cache.has(name):
		return _tileset_image_cache[name]
	var path := "res://assets/graphics/Autotiles/%s.png" % name
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if tex == null:
		# 部分 MM1 扩展把 autotile 放在 Tilesets 目录
		path = "res://assets/graphics/Tilesets/%s.png" % name
		tex = load(path) if ResourceLoader.exists(path) else null
	_tileset_image_cache[name] = tex
	return tex


func windowskin_texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	var path := "res://assets/graphics/Windowskins/%s.png" % name
	if ResourceLoader.exists(path):
		return load(path)
	return null
