# ============================================================
# CameraController — 相机跟随
# 平滑跟随当前出战角色，支持滚轮缩放
# ============================================================

extends Camera2D
class_name CameraController

@export var follow_offset: Vector2 = Vector2(0, -12)
@export var smooth_speed: float = 6.0
@export var min_zoom: float = 0.6
@export var max_zoom: float = 1.8

var follow_target: Node2D = null

func _ready() -> void:
	position_smoothing_enabled = false
	zoom = Vector2(1.0, 1.0)

func _process(delta: float) -> void:
	var player = GameManager.active_player if GameManager else null
	if is_instance_valid(player):
		var anchor = player.get_node_or_null("CameraAnchor")
		follow_target = anchor if anchor is Node2D else player
	if not is_instance_valid(follow_target):
		follow_target = null
		return
	var target_pos: Vector2 = follow_target.global_position + follow_offset
	var weight: float = clampf(smooth_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target_pos, weight)

func _unhandled_input(event: InputEvent) -> void:
	if GameManager and GameManager.is_input_blocked():
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		var z: float = clampf(zoom.x * 1.1, min_zoom, max_zoom)
		zoom = Vector2(z, z)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		var z2: float = clampf(zoom.x / 1.1, min_zoom, max_zoom)
		zoom = Vector2(z2, z2)
