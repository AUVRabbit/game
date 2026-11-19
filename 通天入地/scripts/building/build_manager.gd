# ============================================================
# BuildManager.gd — 沙盒自由建造管理
# 等距视角下的方块放置/破坏系统
# ============================================================

extends Node
class_name BuildManager
signal build_mode_changed(active: bool)
signal block_placed(grid_pos: Vector2i, block_id: String)
signal block_broken(grid_pos: Vector2i)

const GRID_SIZE := 32  # 等距格子大小（像素）

var is_build_mode: bool = false
var current_block_id: String = "stone"
var build_grid: Dictionary = {}  # Vector2i -> String(block_id)
var hover_grid_pos: Vector2i = Vector2i(-9999, -9999)

# ---------- 可放置方块列表（占位）----------
var available_blocks: Array = [
    {"id": "grass",   "name": "草地", "sprite": null, "cost": {}},
    {"id": "dirt",    "name": "泥土", "sprite": null, "cost": {}},
    {"id": "stone",   "name": "石头", "sprite": null, "cost": {}},
    {"id": "wood",    "name": "木头", "sprite": null, "cost": {}},
    {"id": "wall",    "name": "石墙", "sprite": null, "cost": {"stone": 2}},
    {"id": "fence",   "name": "栅栏", "sprite": null, "cost": {"wood": 1}},
    {"id": "torch",   "name": "火把", "sprite": null, "cost": {"wood": 1, "stone": 1}},
    {"id": "bed",     "name": "床",   "sprite": null, "cost": {"wood": 4}},
    {"id": "chest",   "name": "箱子", "sprite": null, "cost": {"wood": 3}},
]

func toggle_build_mode() -> void:
    is_build_mode = not is_build_mode
    emit_signal("build_mode_changed", is_build_mode)

func set_current_block(block_id: String) -> void:
    for b in available_blocks:
        if b["id"] == block_id:
            current_block_id = block_id
            return

func _unhandled_input(event: InputEvent) -> void:
    if Input.is_action_just_pressed("open_build"):
        toggle_build_mode()

    if not is_build_mode:
        return

    # 建造模式下：左键放置，右键破坏
    if event is InputEventMouseButton and event.pressed:
        var grid_pos = _screen_to_grid(get_viewport().get_mouse_position())
        if event.button_index == MOUSE_BUTTON_LEFT:
            try_place_block(grid_pos)
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            try_break_block(grid_pos)
    elif event is InputEventMouseMotion:
        hover_grid_pos = _screen_to_grid(event.position)

func try_place_block(grid_pos: Vector2i) -> bool:
    if build_grid.has(grid_pos):
        return false
    # 检查资源（简化，暂时不消耗）
    # TODO: 检查背包中是否有足够材料
    build_grid[grid_pos] = current_block_id
    emit_signal("block_placed", grid_pos, current_block_id)
    if EventBus: EventBus.tile_placed.emit(grid_pos, 0, {"id": current_block_id})
    print("[BuildManager] 放置 %s 于 %s" % [current_block_id, grid_pos])
    return true

func try_break_block(grid_pos: Vector2i) -> bool:
    if not build_grid.has(grid_pos):
        return false
    build_grid.erase(grid_pos)
    emit_signal("block_broken", grid_pos)
    if EventBus: EventBus.tile_broken.emit(grid_pos, 0)
    print("[BuildManager] 破坏于 %s" % grid_pos)
    return true

# ---------- 等距坐标转换 ----------
func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
    """将屏幕像素坐标转换为等距网格坐标"""
    # 等距投影逆变换
    var world_pos = screen_pos - (get_viewport().get_visible_rect().size / 2)
    # 从等距投影反算网格坐标（菱形格子）
    var gx = int(round((world_pos.x / GRID_SIZE + world_pos.y / (GRID_SIZE / 2)) / 2))
    var gy = int(round((world_pos.y / (GRID_SIZE / 2) - world_pos.x / GRID_SIZE) / 2))
    return Vector2i(gx, gy)

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
    """等距网格坐标 -> 世界像素坐标"""
    var x = (grid_pos.x - grid_pos.y) * GRID_SIZE / 2
    var y = (grid_pos.x + grid_pos.y) * GRID_SIZE / 4
    return Vector2(x, y)
