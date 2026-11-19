class_name MapScene
extends Node2D
## Native map scene: draws the tileset layers, player, events and runs events.

const TILE := 32

var _msg_script: Script = null
var _battle_script: Script = null
var _menu_script: Script = null


func _scripts() -> void:
	if _msg_script == null:
		_msg_script = load("res://scripts/ui/message_window.gd")
		_battle_script = load("res://scripts/battle/battle_scene.gd")
		_menu_script = load("res://scripts/ui/menu.gd")

var map_data: Dictionary = {}
var info: Dictionary = {}
var width := 0
var height := 0
var tileset: Dictionary = {}
var passages: Array = []
var priorities: Array = []
var layers: Array = []
var events: Dictionary = {}
var map_name := ""

var player = null
var message = null
var ui_layer: CanvasLayer
var interpreter = null
var character_layer: Node2D

var wanted: Dictionary = {}
var _starting_event := false


func _ready() -> void:
	map_data = DB.map_data(State.map_id)
	if map_data.is_empty():
		push_error("Missing map data for id %d" % State.map_id)
		return
	width = int(map_data.get("width", 0))
	height = int(map_data.get("height", 0))
	layers = map_data.get("layers", [])
	info = map_data.get("info", {})
	map_name = str(info.get("name", ""))
	var tileset_id := int(map_data.get("tileset_id", 1))
	tileset = DB.tileset(tileset_id)
	passages = tileset.get("passages", {}).get("data", [])
	priorities = tileset.get("priorities", {}).get("data", [])
	_build_tiles()
	_build_characters()
	_build_ui()
	State.current_map = self


func _build_tiles() -> void:
	# 加载 tileset 主图
	var tex: Texture2D = DB.tileset_texture(str(tileset.get("tileset_name", "")))
	# 加载最多 7 张 autotile 图片
	var autotile_names: Array = tileset.get("autotile_names", [])
	var autos: Array = []
	for i in range(7):
		var name: String = autotile_names[i] if i < autotile_names.size() else ""
		name = name.replace("'", "").replace('"', '').strip_edges()
		if name.is_empty():
			autos.append(null)
		else:
			var atex: Texture2D = DB.autotile_texture(name)
			autos.append(atex)
	var _tl_script: Script = load("res://scripts/core/tile_layer.gd")
	var below: Variant = _tl_script.new()
	below.z_index = -10
	add_child(below)
	below.configure(tex, autos, width, height, layers, [0, 1, 2], priorities, -1)
	var above: Variant = _tl_script.new()
	above.z_index = 10
	add_child(above)
	above.configure(tex, autos, width, height, layers, [2], priorities, 1)
	# WaterRenderer —— 专用水渲染，覆盖 tile_layer 的水 tile
	# 取第一张 autotile 图 (通常是 water01.png)
	var water_tex: Texture2D = autos[0] if autos.size() > 0 else null
	if water_tex != null:
		var _wr_script: Script = load("res://scripts/core/water_renderer.gd")
		var water_rend: Variant = _wr_script.new()
		water_rend.z_index = 0   # 在 below 之上、above 之下
		add_child(water_rend)
		water_rend.configure(water_tex, width, height, layers)


func _build_characters() -> void:
	character_layer = Node2D.new()
	character_layer.y_sort_enabled = true
	add_child(character_layer)

	player = load("res://scripts/core/game_player.gd").new()
	character_layer.add_child(player)
	player.setup(self, State.player_x, State.player_y, State.player_direction)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = false
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = width * TILE
	cam.limit_bottom = height * TILE
	player.add_child(cam)
	cam.make_current()

	var event_list: Dictionary = map_data.get("events", {})
	var _ev_script: Script = load("res://scripts/core/game_event.gd")
	for key in event_list:
		var ev_data: Dictionary = event_list[key]
		var ev: Variant = _ev_script.new()
		character_layer.add_child(ev)
		ev.setup(self, ev_data)
		events[int(ev_data.get("id", key))] = ev


func _build_ui() -> void:
	_scripts()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	message = _msg_script.new()
	ui_layer.add_child(message)

	interpreter = load("res://scripts/core/interpreter.gd").new()
	interpreter.map_scene = self
	add_child(interpreter)


# ------------------------------------------------------------------ interaction
func can_player_input() -> bool:
	if message != null and message.visible:
		return false
	if interpreter != null and interpreter.running:
		return false
	if Router.has_overlay():
		return false
	return not State.in_battle


# ------------------------------------------------------------------ passability
func can_move_from(x: int, y: int, d: int) -> bool:
	"""Game_Character#passable? — full 3-step check for the player.
	Can the player step off tile (x,y) in direction d? Validates:
	  1. (x,y) has opening in direction d.
	  2. target (new_x,new_y) has opening from opposite direction (10-d).
	  3. No non-through character event at (new_x,new_y).
	"""
	if d <= 0 or d == 10:
		return false
	var dx := 1 if d == 6 else -1 if d == 4 else 0
	var dy := 1 if d == 2 else -1 if d == 8 else 0
	var nx := x + dx
	var ny := y + dy
	if nx < 0 or nx >= width or ny < 0 or ny >= height:
		return false
	# step 1: current tile exit
	if not _tile_passable(x, y, d):
		return false
	# step 2: target tile entrance (opposite direction)
	if not _tile_passable(nx, ny, 10 - d):
		return false
	# step 3: blocking character event at target
	for ev in events.values():
		if ev.tile_x == nx and ev.tile_y == ny and ev.visible:
			if ev.through:
				continue
			if not ev.character_name.is_empty():
				return false
	return true


func _tile_passable(x: int, y: int, d: int) -> bool:
	"""Game_Map#passable? — can any character walk on tile (x,y) facing direction d?
	Uses combined passage bits across layers 2→1→0.
	"""
	if x < 0 or x >= width or y < 0 or y >= height:
		return false
	if d <= 0 or d == 10:
		return false
	var bit := (1 << (int(d / 2) - 1)) & 0x0f
	for z in [2, 1, 0]:
		var row: Array = layers[z]
		var idx := y * width + x
		if idx >= row.size():
			continue
		var tid := int(row[idx])
		if tid <= 0 or tid >= passages.size():
			continue
		var pas := int(passages[tid])
		if pas & bit != 0:
			return false
		if pas & 0x0f == 0x0f:
			return false
		var prio := int(priorities[tid]) if tid < priorities.size() else 0
		if prio == 0:
			return true
	return true


func is_passable(x: int, y: int, d: int, self_event: Variant = null) -> bool:
	"""Legacy wrapper — used by tile/event debug only. Do not call for player movement."""
	return can_move_from(x, y, d)


func event_at(x: int, y: int) -> Variant:
	for ev in events.values():
		if ev.visible and ev.tile_x == x and ev.tile_y == y:
			return ev
	return null


func player_action() -> void:
	if not can_player_input():
		return
	var front: Variant = player.front_tile()
	var ev: Variant = event_at(front.x, front.y)
	if ev != null and ev.trigger() == 0:
		run_event(ev)


func on_player_step(x: int, y: int) -> void:
	for ev in events.values():
		if ev.visible and ev.tile_x == x and ev.tile_y == y and ev.trigger() == 1:
			run_event(ev)
			return


func run_event(ev: Variant) -> void:
	if ev == null or interpreter == null or interpreter.running:
		return
	var page: Variant = ev.current_page()
	if page.is_empty():
		return
	ev.running = true
	interpreter.setup(page.get("list", []), ev)
	await interpreter.run()
	ev.running = false
	ev.refresh()


var _process_frame := 0
var _autorun_debug_shown := false

func _process(_delta: float) -> void:
	_process_frame += 1
	if not _autorun_debug_shown and _process_frame <= 5:
		print("[MapScene._process] frame=%d interp=%s running=%s start=%s msg_vis=%s events=%d" % [
			_process_frame, interpreter != null,
			interpreter.running if interpreter != null else "null",
			_starting_event,
			message.visible if message != null else "null",
			events.size()])
		for k in events.keys():
			var evv: Variant = events[k]
			print("  EV key=%s id=%d visible=%s page=%d trig=%d" % [
				k, evv.event_id, evv.visible, evv.page_index, evv.trigger()])
		_autorun_debug_shown = true
	if interpreter == null or interpreter.running or _starting_event:
		return
	if message != null and message.visible:
		return
	for ev in events.values():
		if ev.visible and ev.trigger() == 3:
			print("[MapScene] autorun TRIGGERED for EV id=%d page=%d" % [ev.event_id, ev.page_index])
			_starting_event = true
			run_event(ev)
			_starting_event = false
			return


# ------------------------------------------------------------------ messages
func show_message(text: String, face_name: String = "", face_index: int = 0) -> void:
	if message == null:
		return
	await message.show_message(text, face_name, face_index)


func show_choices(options: Array) -> int:
	if message == null:
		return 0
	return await message.show_choices(options)


# ------------------------------------------------------------------ transfer
func transfer(map_id: int, x: int, y: int, direction: int = 2) -> void:
	Router.load_map(map_id, x, y, direction, true)


# ------------------------------------------------------------------ battle
func start_battle(troop_id: int, can_escape: bool = true) -> int:
	State.in_battle = true
	var battle: Variant = _battle_script.new(troop_id, can_escape)
	Router.open_overlay(battle)
	var result: int = await battle.finished
	Router.close_overlay()
	State.in_battle = false
	if result == 2:
		await Router.show_gameover()
	return result


# ------------------------------------------------------------------ wanted
func wanted_person_strike(wanted_id: int, level: int) -> void:
	wanted[wanted_id] = {"struck": true, "level": level}
	State.system_flags["wanted_%d" % wanted_id] = {"struck": true, "level": level}


func wanted_person_award(wanted_id: int) -> void:
	State.system_flags["wanted_award_%d" % wanted_id] = true


# ------------------------------------------------------------------ menu
func open_menu() -> void:
	if not can_player_input():
		return
	Router.open_overlay(_menu_script.new())
