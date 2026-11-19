# ============================================================
# DialogueBox — 剧情对话框
# 由 NPC 调用 show_dialogue(title, lines, on_finish)
# ============================================================

extends CanvasLayer
class_name DialogueBox

var root: Control
var panel: PanelContainer
var title_label: Label
var body_label: Label
var hint_label: Label
var lines: Array = []
var line_index: int = 0
var on_finish: Callable = Callable()
var open_cooldown: float = 0.0

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_box")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	panel = PanelContainer.new()
	panel.position = Vector2(120, 360)
	panel.custom_minimum_size = Vector2(720, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.11, 0.94)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.55, 0.45, 0.8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
	vbox.add_child(title_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.custom_minimum_size = Vector2(680, 60)
	vbox.add_child(body_label)
	hint_label = Label.new()
	hint_label.text = "按 E / 空格 继续"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	vbox.add_child(hint_label)
	visible = false

func show_dialogue(speaker: String, dialogue_lines: Array, callback: Callable = Callable()) -> void:
	if dialogue_lines.is_empty():
		return
	lines = dialogue_lines
	line_index = 0
	on_finish = callback
	title_label.text = speaker
	body_label.text = str(lines[0])
	visible = true
	open_cooldown = 0.2
	if GameManager:
		GameManager.open_ui(GameManager.GameState.DIALOG)
	EventBus.dialogue_started.emit(speaker)

func _process(delta: float) -> void:
	if open_cooldown > 0.0:
		open_cooldown = maxf(0.0, open_cooldown - delta)

func _input(event: InputEvent) -> void:
	if not visible or open_cooldown > 0.0:
		return
	var advance := false
	if event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if advance:
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	line_index += 1
	if line_index >= lines.size():
		_close()
		return
	body_label.text = str(lines[line_index])
	AudioManager.play_sfx("dialogue")

func _close() -> void:
	visible = false
	var cb := on_finish
	on_finish = Callable()
	if GameManager:
		GameManager.close_ui()
	EventBus.dialogue_ended.emit(title_label.text)
	if cb.is_valid():
		cb.call()
