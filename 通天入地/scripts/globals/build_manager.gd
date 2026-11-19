# ============================================================
# BuildManager — 等距沙盒建造
# 网格放置 / 拆除 / 材料消耗 / 按场景持久化
# 注意：AutoLoad 脚本不声明 class_name
# ============================================================

extends Node

signal build_mode_changed(active: bool)
signal block_placed(grid_pos: Vector2i, block_id: String)
signal block_broken(grid_pos: Vector2i)

const GRID_SIZE := 64.0
const GRID_HALF := 32.0
const GRID_QUARTER := 16.0
const BUILD_BLOCK_SCRIPT := preload("res://scripts/world/build_block.gd")

var is_build_mode: bool = false
var current_block_id: String = "stone_block"
var available_blocks: Array = []
var builds: Dictionary = {}
var hover_grid_pos: Vector2i = Vector2i(999999, 999999)

func _ready() -> void:
	set_process_unhandled_input(true)
	_reload_blocks()

func _reload_blocks() -> void:
	available_blocks.clear()
	if DataManager:
		for item in DataManager.get_items_by_type("building"):
			var cost: Dictionary = item.get("craft_cost", {})
			if not cost.is_empty():
				available_blocks.append(item)
	if available_blocks.is_empty():
		available_blocks.append({
			"id": "stone_block", "name": "石砖", "color": "#7d7d85",
			"craft_cost": { "stone": 2 }, "collidable": true
		})
	if current_block_id == "" or _find_block(current_block_id).is_empty():
		current_block_id = str(available_blocks[0].get("id", "stone_block"))

func _find_block(block_id: String) -> Dictionary:
	for b in available_blocks:
		if str(b.get("id", "")) == block_id:
			return b
	return {}

func toggle_build_mode() -> void:
	is_build_mode = not is_build_mode
	build_mode_changed.emit(is_build_mode)
	if is_build_mode:
		EventBus.notify("建造模式：左键放置 / 右键拆除 / B 退出")
	else:
		hover_grid_pos = Vector2i(999999, 999999)

func set_current_block(block_id: String) -> void:
	if not _find_block(block_id).is_empty():
		current_block_id = block_id

func cycle_block(direction: int) -> void:
	if available_blocks.is_empty():
		return
	var idx := 0
	for i in available_blocks.size():
		if str(available_blocks[i].get("id", "")) == current_block_id:
			idx = i
			break
	idx = posmod(idx + direction, available_blocks.size())
	current_block_id = str(available_blocks[idx].get("id", ""))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_build"):
		if GameManager and (GameManager.is_menu() or GameManager.is_input_blocked()):
			return
		toggle_build_mode()
		get_viewport().set_input_as_handled()
		return
	if not is_build_mode:
		return
	if GameManager and GameManager.is_input_blocked():
		return
	if event is InputEventMouseMotion:
		hover_grid_pos = screen_to_grid(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if get_viewport().gui_get_hovered_control() != null:
			return
		var grid_pos := screen_to_grid(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_block(grid_pos)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			break_block(grid_pos)
			get_viewport().set_input_as_handled()

# ---------- 放置 / 拆除 ----------
func can_afford(block_id: String) -> bool:
	var block := _find_block(block_id)
	if block.is_empty() or GameManager == null or GameManager.inventory == null:
		return false
	var cost: Dictionary = block.get("craft_cost", {})
	for item_id in cost.keys():
		if not GameManager.inventory.has_item(str(item_id), int(cost[item_id])):
			return false
	return true

func place_block(grid_pos: Vector2i) -> bool:
	if builds_scene().has(_grid_key(grid_pos)):
		return false
	if not can_afford(current_block_id):
		EventBus.notify("材料不足：%s" % current_block_id)
		return false
	var block := _find_block(current_block_id)
	var cost: Dictionary = block.get("craft_cost", {})
	for item_id in cost.keys():
		GameManager.inventory.remove_item(str(item_id), int(cost[item_id]))
	var scene_builds := builds_scene()
	scene_builds[_grid_key(grid_pos)] = current_block_id
	_spawn_block(grid_pos, current_block_id)
	block_placed.emit(grid_pos, current_block_id)
	EventBus.tile_placed.emit(grid_pos, 2, {"id": current_block_id})
	return true

func break_block(grid_pos: Vector2i) -> bool:
	var scene_builds := builds_scene()
	var key := _grid_key(grid_pos)
	if not scene_builds.has(key):
		return false
	var block_id: String = str(scene_builds[key])
	scene_builds.erase(key)
	var block := _find_block(block_id)
	var cost: Dictionary = block.get("craft_cost", {})
	for item_id in cost.keys():
		var refund := int(floor(int(cost[item_id]) * 0.5))
		if refund > 0 and GameManager.inventory:
			GameManager.inventory.add_item(str(item_id), refund)
	_remove_block_node(grid_pos)
	block_broken.emit(grid_pos)
	EventBus.tile_broken.emit(grid_pos, 2)
	return true

func _spawn_block(grid_pos: Vector2i, block_id: String) -> void:
	var root := _get_build_root()
	if root == null:
		return
	var block := BUILD_BLOCK_SCRIPT.new()
	block.name = "Block_%d_%d" % [grid_pos.x, grid_pos.y]
	block.block_id = block_id
	block.grid_pos = grid_pos
	block.position = grid_to_world(grid_pos)
	block.setup(block_id, hover_grid_pos == grid_pos)
	root.add_child(block)

func _remove_block_node(grid_pos: Vector2i) -> void:
	var root := _get_build_root()
	if root == null:
		return
	var node := root.get_node_or_null("Block_%d_%d" % [grid_pos.x, grid_pos.y])
	if node:
		node.queue_free()

func _get_build_root() -> Node:
	if GameManager and GameManager.current_world:
		var root := GameManager.current_world.get_node_or_null("BuildGrid")
		if root:
			return root
	return GameManager.current_world if GameManager else null

# ---------- 坐标转换 ----------
func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var world_pos := get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	return world_to_grid(world_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var gx := int(round((world_pos.x / GRID_HALF + world_pos.y / GRID_QUARTER) / 2.0))
	var gy := int(round((world_pos.y / GRID_QUARTER - world_pos.x / GRID_HALF) / 2.0))
	return Vector2i(gx, gy)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * GRID_HALF,
		(grid_pos.x + grid_pos.y) * GRID_QUARTER
	)

# ---------- 持久化 ----------
func _scene_key() -> String:
	if get_tree().current_scene and get_tree().current_scene.scene_file_path != "":
		return get_tree().current_scene.scene_file_path
	return "world"

func builds_scene() -> Dictionary:
	var key := _scene_key()
	if not builds.has(key):
		builds[key] = {}
	return builds[key]

func _grid_key(grid_pos: Vector2i) -> String:
	return "%d,%d" % [grid_pos.x, grid_pos.y]

func _parse_grid_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

func restore_scene(level: Node) -> void:
	var key := _scene_key()
	if level and level.scene_file_path != "":
		key = level.scene_file_path
	if not builds.has(key):
		builds[key] = {}
	var scene_builds: Dictionary = builds[key]
	for grid_key in scene_builds.keys():
		_spawn_block(_parse_grid_key(str(grid_key)), str(scene_builds[grid_key]))

func serialize() -> Dictionary:
	return builds.duplicate(true)

func deserialize(data) -> void:
	builds.clear()
	if data is Dictionary:
		builds = data.duplicate(true)

func reset() -> void:
	builds.clear()
	is_build_mode = false
	build_mode_changed.emit(false)
