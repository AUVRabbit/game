; ============================================================
; CameraController.gd — 相机跟随
; 挂载在 Camera2D 上
; 功能：平滑跟随玩家、等距边界限制、缩放支持
; ============================================================

extends Camera2D
class_name CameraController

@export var follow_target: Node2D = null
@export var smooth_speed: float = 5.0
@export var offset: Vector2 = Vector2(0, -10)
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
    position_smoothing_enabled = true
    position_smoothing_speed = smooth_speed

func _process(_delta: float) -> void:
    # 自动查找 GameManager 中的活跃玩家
    if not follow_target:
        if GameManager and GameManager.active_player:
            follow_target = GameManager.active_player.get_node_or_null("CameraAnchor") \
                           or GameManager.active_player

    if follow_target:
        var target_pos = follow_target.global_position + offset
        global_position = global_position.lerp(target_pos, smooth_speed * get_process_delta_time())

func _unhandled_input(event: InputEvent) -> void:
    # 鼠标滚轮缩放
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom = Vector2(
                clampf(zoom.x * 1.1, min_zoom, max_zoom),
                clampf(zoom.y * 1.1, min_zoom, max_zoom)
            )
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom = Vector2(
                clampf(zoom.x / 1.1, min_zoom, max_zoom),
                clampf(zoom.y / 1.1, min_zoom, max_zoom)
            )
