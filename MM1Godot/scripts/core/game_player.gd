class_name GamePlayer
extends Node2D
## Grid-based player character (RMXP 4-direction movement, 32px tiles).

const TILE := 32
const MOVE_TIME := 0.13

var map_scene: Node = null
var tile_x := 0
var tile_y := 0
var direction := 2
var moving := false
var pattern := 0
var _anim_time := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _move_t := 0.0

var sprite: Sprite2D
var _texture: Texture2D


func setup(scene: Node, x: int, y: int, dir: int = 2) -> void:
	map_scene = scene
	tile_x = x
	tile_y = y
	direction = dir if dir > 0 else 2
	position = _tile_center(tile_x, tile_y)
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.position = Vector2(-TILE / 2.0, -TILE / 2.0)
	add_child(sprite)
	_update_texture()
	_update_frame()


func _tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)


func _update_texture() -> void:
	var name := "主角"
	var actors: Array = State.party.member_actors()
	if not actors.is_empty():
		var a: GameActor = actors[0]
		if not a.character_name.is_empty():
			name = a.character_name
	_texture = DB.character_texture(name)
	if _texture == null:
		_texture = DB.character_texture("主角")
	sprite.texture = _texture
	sprite.region_enabled = true


func _update_frame() -> void:
	if sprite == null:
		return
	var row := int(direction / 2) - 1
	row = clampi(row, 0, 3)
	sprite.region_rect = Rect2(pattern * 32, row * 32, 32, 32)


func _process(delta: float) -> void:
	if map_scene == null:
		return
	if moving:
		_move_t += delta / MOVE_TIME
		position = _from.lerp(_to, minf(_move_t, 1.0))
		_anim_time += delta
		if _anim_time >= 0.11:
			_anim_time = 0.0
			pattern = (pattern + 1) % 4
			_update_frame()
		if _move_t >= 1.0:
			_finish_move()
		return
	if not map_scene.can_player_input():
		pattern = 0
		_update_frame()
		return
	if Input.is_action_just_pressed("action"):
		map_scene.player_action()
		return
	if Input.is_action_just_pressed("menu"):
		map_scene.open_menu()
		return
	var d := _input_direction()
	if d > 0:
		direction = d
		_update_frame()
		if map_scene.can_move_from(tile_x, tile_y, d):
			_start_move(d)
	else:
		pattern = 0
		_update_frame()


func _input_direction() -> int:
	if Input.is_action_pressed("move_up"):
		return 8
	if Input.is_action_pressed("move_down"):
		return 2
	if Input.is_action_pressed("move_left"):
		return 4
	if Input.is_action_pressed("move_right"):
		return 6
	return 0


func _start_move(d: int) -> void:
	moving = true
	_move_t = 0.0
	_anim_time = 0.0
	_from = position
	var nx := tile_x + (1 if d == 6 else -1 if d == 4 else 0)
	var ny := tile_y + (1 if d == 2 else -1 if d == 8 else 0)
	tile_x = nx
	tile_y = ny
	_to = _tile_center(nx, ny)


func _finish_move() -> void:
	moving = false
	position = _to
	pattern = 0
	_update_frame()
	State.steps += 1
	State.party.increase_steps()
	map_scene.on_player_step(tile_x, tile_y)


func front_tile() -> Vector2i:
	var dx := 1 if direction == 6 else -1 if direction == 4 else 0
	var dy := 1 if direction == 2 else -1 if direction == 8 else 0
	return Vector2i(tile_x + dx, tile_y + dy)
