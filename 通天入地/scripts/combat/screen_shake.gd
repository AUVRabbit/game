# ============================================================
# ScreenShake — 屏幕震动工具
# 全局单例，给 Camera2D 做抖动偏移
# ============================================================

extends Node

var _camera: Camera2D = null
var _active: bool = false
var _elapsed: float = 0.0
var _duration: float = 0.0
var _intensity: float = 0.0
var _freq: float = 40.0
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("screen_shake")
	set_process(true)

func register_camera(cam: Camera2D) -> void:
	_camera = cam
	if cam:
		_origin = Vector2(cam.offset.x, cam.offset.y)

func shake(intensity: float = 4.0, duration: float = 0.18, freq: float = 40.0) -> void:
	if _camera == null:
		_camera = _find_camera()
		if _camera == null:
			return
		_origin = Vector2(_camera.offset.x, _camera.offset.y)
	_intensity = maxf(_intensity, intensity)
	_duration = maxf(_duration, duration)
	_freq = freq
	_elapsed = 0.0
	_active = true

func micro() -> void:
	shake(2.2, 0.08, 60.0)

func heavy() -> void:
	shake(6.0, 0.28, 32.0)

func _find_camera() -> Camera2D:
	if get_tree() == null:
		return null
	for node in get_tree().get_nodes_in_group("camera"):
		if node is Camera2D:
			return node
	var main := get_tree().current_scene
	if main:
		var cam := main.get_node_or_null("Camera2D")
		if cam is Camera2D:
			return cam
	if GameManager and GameManager.current_world:
		var w := GameManager.current_world
		if w:
			var c := w.get_node_or_null("Camera2D")
			if c is Camera2D:
				return c
	return null

func _process(delta: float) -> void:
	if not _active or _camera == null:
		return
	_elapsed += delta
	var t := clampf(_elapsed / maxf(_duration, 0.001), 0.0, 1.0)
	var amp := _intensity * (1.0 - t)
	var angle := _elapsed * _freq * TAU * randf_range(0.9, 1.1)
	var off := Vector2(cos(angle), sin(angle * 1.3)) * amp
	_camera.offset = _origin + off
	if t >= 1.0:
		_active = false
		_camera.offset = _origin
