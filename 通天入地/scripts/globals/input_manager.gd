# ============================================================
# InputManager — 多平台输入统一管理
# 键鼠 / 手柄 / 触屏自动识别；触屏虚拟摇杆与按键注入
# ============================================================

extends Node

signal input_mode_changed(mode: String)
signal tap_gesture
signal swipe_gesture(direction: Vector2)

enum InputMode { KEYBOARD, GAMEPAD, TOUCH }

const JOY_DEADZONE := 0.3
const TAP_MAX_DIST := 12.0
const SWIPE_MIN_DIST := 50.0
const TAP_MAX_TIME := 0.3

var current_mode: InputMode = InputMode.KEYBOARD
var virtual_move: Vector2 = Vector2.ZERO

var touch_start_pos: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	detect_input_mode()

func detect_input_mode() -> void:
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		current_mode = InputMode.TOUCH
	elif Input.get_connected_joypads().size() > 0:
		current_mode = InputMode.GAMEPAD
	else:
		current_mode = InputMode.KEYBOARD
	emit_signal("input_mode_changed", mode_name())

func mode_name() -> String:
	match current_mode:
		InputMode.KEYBOARD:
			return "keyboard"
		InputMode.GAMEPAD:
			return "gamepad"
		InputMode.TOUCH:
			return "touch"
		_:
			return "keyboard"

func is_touch_mode() -> bool:
	return current_mode == InputMode.TOUCH

# ---------- 移动 ----------
func set_virtual_move(vec: Vector2) -> void:
	virtual_move = vec

func get_move_vector() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if virtual_move.length() > 0.01:
		raw += virtual_move
	raw = raw.limit_length(1.0)
	# 等距投影：屏幕方向 → 世界菱形方向
	var isometric := Vector2(
		raw.x - raw.y,
		(raw.x + raw.y) * 0.5
	)
	if isometric.length() > 0.001:
		isometric = isometric.normalized() * minf(raw.length(), 1.0)
	return isometric

func get_raw_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

# ---------- 动作查询 ----------
func is_attack_pressed() -> bool:
	return Input.is_action_just_pressed("attack")

func is_skill_pressed(slot: int) -> bool:
	match slot:
		1: return Input.is_action_just_pressed("skill_1")
		2: return Input.is_action_just_pressed("skill_2")
		3: return Input.is_action_just_pressed("skill_3")
		_: return false

func is_dash_pressed() -> bool:
	return Input.is_action_just_pressed("dash")

func is_interact_pressed() -> bool:
	return Input.is_action_just_pressed("interact")

func is_switch_character_pressed() -> int:
	if Input.is_action_just_pressed("character_switch_next"):
		return 1
	elif Input.is_action_just_pressed("character_switch_prev"):
		return -1
	return 0

func is_inventory_pressed() -> bool:
	return Input.is_action_just_pressed("open_inventory")

func is_build_pressed() -> bool:
	return Input.is_action_just_pressed("open_build")

func is_pause_pressed() -> bool:
	return Input.is_action_just_pressed("pause")

# ---------- 设备切换 + 触屏手势 ----------
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if current_mode != InputMode.KEYBOARD and not (event is InputEventScreenTouch):
			current_mode = InputMode.KEYBOARD
			emit_signal("input_mode_changed", "keyboard")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_mode != InputMode.GAMEPAD:
			current_mode = InputMode.GAMEPAD
			emit_signal("input_mode_changed", "gamepad")
	elif event is InputEventScreenTouch:
		if current_mode != InputMode.TOUCH:
			current_mode = InputMode.TOUCH
			emit_signal("input_mode_changed", "touch")
		if event.pressed:
			touch_start_pos = event.position
			touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			var delta_pos: Vector2 = event.position - touch_start_pos
			var delta_time: float = Time.get_ticks_msec() / 1000.0 - touch_start_time
			if delta_pos.length() < TAP_MAX_DIST and delta_time < TAP_MAX_TIME:
				emit_signal("tap_gesture")
			elif delta_pos.length() > SWIPE_MIN_DIST:
				emit_signal("swipe_gesture", delta_pos.normalized())
