class_name GameEvent
extends Node2D
## A map event: picks the active page from its conditions and renders it.

const TILE := 32

var map_scene: Node = null
var event_id := 0
var data: Dictionary = {}
var pages: Array = []
var page_index := -1
var tile_x := 0
var tile_y := 0
var direction := 2
var pattern := 0
var through := false
var character_name := ""
var tile_id := 0
var running := false

var sprite: Sprite2D
var _texture: Texture2D
var _anim_time := 0.0
var _step_anime := false
var _walk_anime := true


func setup(scene: Node, event_data: Dictionary) -> void:
	map_scene = scene
	data = event_data
	event_id = int(event_data.get("id", 0))
	tile_x = int(event_data.get("x", 0))
	tile_y = int(event_data.get("y", 0))
	pages = event_data.get("pages", [])
	position = Vector2(tile_x * TILE + TILE / 2.0, tile_y * TILE + TILE / 2.0)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.position = Vector2(-TILE / 2.0, -TILE / 2.0)
	add_child(sprite)
	refresh()


func current_page() -> Dictionary:
	if page_index >= 0 and page_index < pages.size():
		return pages[page_index]
	return {}


func trigger() -> int:
	return int(current_page().get("trigger", 0))


func refresh() -> void:
	var old_index := page_index
	page_index = -1
	for i in range(pages.size() - 1, -1, -1):
		if _condition_ok(pages[i].get("condition", {})):
			page_index = i
			break
	if page_index < 0:
		visible = false
		return
	visible = true
	var page: Dictionary = pages[page_index]
	through = bool(page.get("through", false))
	_step_anime = bool(page.get("step_anime", false))
	_walk_anime = bool(page.get("walk_anime", true))
	var g: Dictionary = page.get("graphic", {})
	character_name = str(g.get("character_name", ""))
	tile_id = int(g.get("tile_id", 0))
	direction = int(g.get("direction", 2))
	direction = direction if direction > 0 else 2
	pattern = int(g.get("pattern", 0)) % 4
	sprite.modulate.a = float(g.get("opacity", 255)) / 255.0
	_texture = null
	if not character_name.is_empty():
		_texture = DB.character_texture(character_name)
	elif tile_id > 0:
		var ts: Dictionary = DB.tileset(int(map_scene.map_data.get("tileset_id", 1)))
		_texture = DB.tileset_texture(str(ts.get("tileset_name", "")))
	sprite.texture = _texture
	if _texture == null:
		sprite.visible = false
	elif not character_name.is_empty():
		sprite.region_enabled = true
		sprite.visible = true
		_update_frame()
	elif tile_id > 0:
		sprite.region_enabled = true
		var image_index: int = tile_id if tile_id < 384 else tile_id - 384
		var cols := int(_texture.get_size().x / TILE)
		var row_img := int(image_index / cols)
		sprite.region_rect = Rect2((image_index % cols) * TILE, row_img * TILE, TILE, TILE)
		sprite.visible = true
	else:
		sprite.visible = false
	if old_index != page_index:
		pattern = int(g.get("pattern", 0)) % 4
		_update_frame()


func _condition_ok(cond: Dictionary) -> bool:
	if bool(cond.get("switch1_valid", false)) and not State.switch(int(cond.get("switch1_id", 1))):
		return false
	if bool(cond.get("switch2_valid", false)) and not State.switch(int(cond.get("switch2_id", 1))):
		return false
	if bool(cond.get("variable_valid", false)):
		if State.variable(int(cond.get("variable_id", 1))) < int(cond.get("variable_value", 0)):
			return false
	if bool(cond.get("self_switch_valid", false)):
		if not State.self_switch(State.map_id, event_id, str(cond.get("self_switch_ch", "A"))):
			return false
	return true


func _update_frame() -> void:
	if sprite == null or sprite.texture == null:
		return
	var row := clampi(int(direction / 2) - 1, 0, 3)
	sprite.region_rect = Rect2(pattern * 32, row * 32, 32, 32)


func _process(delta: float) -> void:
	if page_index < 0:
		return
	if _step_anime and not running:
		_anim_time += delta
		if _anim_time >= 0.25:
			_anim_time = 0.0
			pattern = (pattern + 1) % 4
			_update_frame()


func start() -> void:
	if running:
		return
	map_scene.run_event(self)
