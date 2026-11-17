extends Node
## Global runtime state (replaces $game_switches / $game_variables / $game_party ...).

var party = null
var _party_script: Script = null
var switches: Array[bool] = []
var variables: Array[int] = []
var self_switches: Dictionary = {}

var map_id: int = 1
var player_x: int = 0
var player_y: int = 0
var player_direction: int = 2
var playtime: float = 0.0
var steps: int = 0

var message_text: String = ""
var message_face_name: String = ""
var message_face_index: int = 0
var in_battle: bool = false
var gameover: bool = false

var tanks_position: Dictionary = {}  # tank_id -> [x, y, map_id, character_name]
var temp: Dictionary = {}
var system_flags: Dictionary = {}

var current_map: Node = null
var interpreter: Node = null

var save_slot: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_party_script = load("res://scripts/core/party.gd")
	new_game()


func new_game() -> void:
	party = _party_script.new()
	party.setup_starting_members()
	switches.clear()
	switches.resize(5000)
	switches.fill(false)
	variables.clear()
	variables.resize(5000)
	variables.fill(0)
	self_switches.clear()
	tanks_position.clear()
	system_flags.clear()
	temp.clear()
	temp = {
		"shop_goods": [],
		"shop_type": 0,
		"wanted_list": [],
		"rent_tanks_id": 0,
		"machine_type": 0,
		"music_id": 0,
		"battle_result": 0,
	}
	playtime = 0.0
	steps = 0
	gameover = false
	in_battle = false
	message_text = ""
	map_id = int(DB.system.get("start_map_id", 1))
	player_x = int(DB.system.get("start_x", 0))
	player_y = int(DB.system.get("start_y", 0))
	player_direction = 2
	save_slot = 1


func switch(id: int) -> bool:
	return id >= 0 and id < switches.size() and switches[id]


func set_switch(id: int, value: bool) -> void:
	if id >= 0 and id < switches.size():
		switches[id] = value


func variable(id: int) -> int:
	return variables[id] if id >= 0 and id < variables.size() else 0


func set_variable(id: int, value: int) -> void:
	if id >= 0 and id < variables.size():
		variables[id] = value


func self_switch(map: int, event_id: int, key: String) -> bool:
	return bool(self_switches.get("%d/%d/%s" % [map, event_id, key], false))


func set_self_switch(map: int, event_id: int, key: String, value: bool) -> void:
	self_switches["%d/%d/%s" % [map, event_id, key]] = value


func gain_gold(n: int) -> void:
	party.gain_gold(n)


func gain_item(id: int, n: int = 1) -> void:
	party.gain_item(id, n)


func to_save_dict() -> Dictionary:
	return {
		"version": 1,
		"map_id": map_id,
		"x": player_x,
		"y": player_y,
		"direction": player_direction,
		"playtime": playtime,
		"steps": steps,
		"switches": switches,
		"variables": variables,
		"self_switches": self_switches,
		"tanks_position": tanks_position,
		"party": party.to_save_dict(),
		"system_flags": system_flags,
		"saved_at": Time.get_datetime_string_from_system()
	}


func load_save_dict(d: Dictionary) -> void:
	new_game()
	map_id = int(d.get("map_id", 1))
	player_x = int(d.get("x", 0))
	player_y = int(d.get("y", 0))
	player_direction = int(d.get("direction", 2))
	playtime = float(d.get("playtime", 0.0))
	steps = int(d.get("steps", 0))
	var sw: Array = d.get("switches", [])
	for i in range(min(sw.size(), switches.size())):
		switches[i] = bool(sw[i])
	var va: Array = d.get("variables", [])
	for i in range(min(va.size(), variables.size())):
		variables[i] = int(va[i])
	self_switches = d.get("self_switches", {})
	tanks_position = d.get("tanks_position", {})
	system_flags = d.get("system_flags", {})
	party.load_save_dict(d.get("party", {}))


func _process(delta: float) -> void:
	if not in_battle and not get_tree().paused:
		playtime += delta


func playtime_text() -> String:
	var total := int(playtime)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
