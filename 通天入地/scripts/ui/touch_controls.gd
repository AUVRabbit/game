# ============================================================
# TouchControls — 触屏虚拟摇杆 + 动作按钮
# 仅在检测到触屏设备时显示
# ============================================================

extends CanvasLayer
class_name TouchControls

const JOYSTICK_RADIUS := 62.0

var root: Control
var joystick_area: Control
var knob: Panel
var stick_center: Vector2 = Vector2.ZERO
var active_touch: int = -1

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	joystick_area = Control.new()
	joystick_area.position = Vector2(28, 340)
	joystick_area.size = Vector2(150, 150)
	joystick_area.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(joystick_area)
	var base := Panel.new()
	base.size = Vector2(138, 138)
	base.position = Vector2(6, 6)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(1, 1, 1, 0.10)
	base_style.set_corner_radius_all(69)
	base_style.set_border_width_all(2)
	base_style.border_color = Color(1, 1, 1, 0.25)
	base.add_theme_stylebox_override("panel", base_style)
	joystick_area.add_child(base)

	knob = Panel.new()
	knob.size = Vector2(54, 54)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.6, 0.8, 1.0, 0.55)
	knob_style.set_corner_radius_all(27)
	knob.add_theme_stylebox_override("panel", knob_style)
	joystick_area.add_child(knob)
	stick_center = Vector2(75, 75)
	knob.position = stick_center - knob.size * 0.5

	_build_action_buttons()
	joystick_area.gui_input.connect(_on_joystick_input)
	InputManager.input_mode_changed.connect(_on_mode_changed)
	visible = InputManager.is_touch_mode()

func _build_action_buttons() -> void:
	_add_action_button("攻击", "attack", Vector2(830, 440), Vector2(92, 60))
	_add_action_button("1", "skill_1", Vector2(730, 452), Vector2(56, 56))
	_add_action_button("2", "skill_2", Vector2(786, 382), Vector2(56, 56))
	_add_action_button("3", "skill_3", Vector2(872, 372), Vector2(56, 56))
	_add_action_button("冲刺", "dash", Vector2(730, 372), Vector2(56, 56))
	_add_action_button("交互", "interact", Vector2(862, 300), Vector2(60, 44))
	_add_action_button("背包", "open_inventory", Vector2(642, 400), Vector2(64, 40))
	_add_action_button("建造", "open_build", Vector2(642, 350), Vector2(64, 40))
	# 进阶技能（需技能树解锁）
	_add_action_button("R", "skill_4", Vector2(642, 302), Vector2(44, 36))
	_add_action_button("F", "skill_5", Vector2(690, 302), Vector2(44, 36))
	_add_action_button("G", "skill_6", Vector2(738, 302), Vector2(44, 36))

func _add_action_button(text: String, action: String, pos: Vector2, size: Vector2) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(_trigger.bind(action))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.10, 0.72)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.45, 0.55, 0.85, 0.85)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", sb)
	var sb_hover := sb.duplicate()
	sb_hover.bg_color = Color(0.10, 0.10, 0.18, 0.80)
	sb_hover.border_color = Color(0.70, 0.78, 1.0, 1.0)
	button.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb.duplicate()
	sb_pressed.bg_color = Color(0.18, 0.15, 0.28, 0.88)
	sb_pressed.border_color = Color(0.95, 0.85, 1.0, 1.0)
	button.add_theme_stylebox_override("pressed", sb_pressed)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.55))
	root.add_child(button)

func _trigger(action: String) -> void:
	var player = _active_player()
	match action:
		"attack":
			if player and player.has_method("try_attack"):
				player.try_attack()
		"skill_1":
			if player and player.has_method("try_skill"):
				player.try_skill(0)
		"skill_2":
			if player and player.has_method("try_skill"):
				player.try_skill(1)
		"skill_3":
			if player and player.has_method("try_skill"):
				player.try_skill(2)
		"skill_4":
			if player and player.has_method("try_skill"):
				player.try_skill(3)
		"skill_5":
			if player and player.has_method("try_skill"):
				player.try_skill(4)
		"skill_6":
			if player and player.has_method("try_skill"):
				player.try_skill(5)
		"dash":
			if player and player.has_method("try_dash"):
				player.try_dash()
		"interact":
			if player and player.has_method("try_interact"):
				player.try_interact()
		"open_inventory":
			var panels := get_tree().get_nodes_in_group("inventory_panel")
			if not panels.is_empty() and panels[0].has_method("toggle_panel"):
				panels[0].toggle_panel()
		"open_build":
			if BuildManager:
				BuildManager.toggle_build_mode()
		_:
			pass

func _active_player() -> Node:
	if GameManager and is_instance_valid(GameManager.active_player):
		return GameManager.active_player
	return null

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touch = event.index
			_update_stick(event.position)
		elif event.index == active_touch:
			active_touch = -1
			_reset_stick()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_update_stick(event.position)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			active_touch = -2
			_update_stick(event.position)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and active_touch == -2:
			active_touch = -1
			_reset_stick()
	elif event is InputEventMouseMotion and active_touch == -2:
		_update_stick(event.position)

func _update_stick(local_pos: Vector2) -> void:
	var offset := local_pos - stick_center
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	knob.position = stick_center + offset - knob.size * 0.5
	InputManager.set_virtual_move(offset / JOYSTICK_RADIUS)

func _reset_stick() -> void:
	knob.position = stick_center - knob.size * 0.5
	InputManager.set_virtual_move(Vector2.ZERO)

func _on_mode_changed(mode: String) -> void:
	visible = mode == "touch"
	if not visible:
		_reset_stick()
