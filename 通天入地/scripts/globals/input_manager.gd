; ============================================================
; InputManager.gd — 多平台输入统一管理（单例）
; 支持：键鼠 / 手柄 / 触屏虚拟按键
; 封装 Input.get_vector() 和手势检测
; ============================================================

extends Node
class_name InputManager
signal input_mode_changed(mode: String)  # "keyboard" / "gamepad" / "touch"
signal tap_gesture
signal swipe_gesture(direction: Vector2)

enum InputMode { KEYBOARD, GAMEPAD, TOUCH }
var current_mode: InputMode = InputMode.KEYBOARD

# ---------- 输入死区 ----------
const JOY_DEADZONE := 0.3
var last_input_time: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    detect_input_mode()

func detect_input_mode() -> void:
    """自动检测当前输入设备"""
    if OS.has_feature("mobile"):
        current_mode = InputMode.TOUCH
    elif Input.get_connected_joypads().size() > 0:
        current_mode = InputMode.GAMEPAD
    else:
        current_mode = InputMode.KEYBOARD
    emit_signal("input_mode_changed", mode_name())

func mode_name() -> String:
    match current_mode:
        InputMode.KEYBOARD: return "keyboard"
        InputMode.GAMEPAD: return "gamepad"
        InputMode.TOUCH: return "touch"

# ---------- 等距视角移动向量 ----------
func get_move_vector() -> Vector2:
    """返回等距视角下的归一化移动向量"""
    var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    # 等距视角需要旋转坐标
    var isometric := Vector2(
        raw.x - raw.y,
        (raw.x + raw.y) * 0.5
    )
    if isometric.length() > 0:
        isometric = isometric.normalized()
    return isometric

func get_raw_move_vector() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")

# ---------- 攻击/技能查询 ----------
func is_attack_pressed() -> bool:
    return Input.is_action_just_pressed("attack")

func is_skill_pressed(slot: int) -> bool:
    match slot:
        1: return Input.is_action_just_pressed("skill_1")
        2: return Input.is_action_just_pressed("skill_2")
        3: return Input.is_action_just_pressed("skill_3")
    return false

func is_dash_pressed() -> bool:
    return Input.is_action_just_pressed("dash")

func is_interact_pressed() -> bool:
    return Input.is_action_just_pressed("interact")

func is_switch_character_pressed() -> int:
    """返回方向：1 下一个, -1 上一个, 0 无"""
    if Input.is_action_just_pressed("character_switch_next"):
        return 1
    elif Input.is_action_just_pressed("character_switch_prev"):
        return -1
    return 0

func is_pause_pressed() -> bool:
    return Input.is_action_just_pressed("pause")

# ---------- 触屏手势（基础版）----------
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0
const TAP_MAX_DIST := 10.0
const SWIPE_MIN_DIST := 50.0
const TAP_MAX_TIME := 0.3

func _input(event: InputEvent) -> void:
    # 检测输入模式切换
    if event is InputEventKey or event is InputEventMouseButton:
        if current_mode != InputMode.KEYBOARD:
            current_mode = InputMode.KEYBOARD
            emit_signal("input_mode_changed", "keyboard")
    elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
        if current_mode != InputMode.GAMEPAD:
            current_mode = InputMode.GAMEPAD
            emit_signal("input_mode_changed", "gamepad")

    # 触屏手势
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_start_pos = event.position
            touch_start_time = Time.get_ticks_msec() / 1000.0
        else:
            var delta_pos = event.position - touch_start_pos
            var delta_time = Time.get_ticks_msec() / 1000.0 - touch_start_time
            if delta_pos.length() < TAP_MAX_DIST and delta_time < TAP_MAX_TIME:
                emit_signal("tap_gesture")
            elif delta_pos.length() > SWIPE_MIN_DIST:
                emit_signal("swipe_gesture", delta_pos.normalized())
