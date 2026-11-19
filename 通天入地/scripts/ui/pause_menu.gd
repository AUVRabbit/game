# ============================================================
# PauseMenu — 暂停菜单（继续 / 保存 / 返回主菜单 / 退出）
# ============================================================

extends CanvasLayer
class_name PauseMenu

var root: Control
var info_label: Label

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.72)
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(340, 110)
	panel.custom_minimum_size = Vector2(280, 320)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.13, 0.98)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.5, 0.8)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "已暂停"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)

	var resume := Button.new()
	resume.text = "继续游戏 (Esc)"
	resume.pressed.connect(_on_resume)
	vbox.add_child(resume)
	var save_button := Button.new()
	save_button.text = "保存游戏"
	save_button.pressed.connect(_on_save)
	vbox.add_child(save_button)
	var menu_button := Button.new()
	menu_button.text = "返回主菜单"
	menu_button.pressed.connect(_on_main_menu)
	vbox.add_child(menu_button)
	var quit_button := Button.new()
	quit_button.text = "退出游戏"
	quit_button.pressed.connect(_on_quit)
	vbox.add_child(quit_button)

	visible = false
	EventBus.toast_requested.connect(_on_toast)
	if GameManager:
		GameManager.game_paused.connect(_on_paused)
		GameManager.game_resumed.connect(_on_resumed)

func _on_paused() -> void:
	visible = true
	_refresh_info()

func _on_resumed() -> void:
	visible = false

func _refresh_info() -> void:
	if GameManager == null:
		return
	var class_text := "?"
	if GameManager.active_player:
		var data = GameManager.active_player.get_node_or_null("CharacterData")
		if data:
			class_text = "%s Lv.%d" % [data.class_display_name, data.level]
	info_label.text = "职业 %s\n金币 %d · 队伍 %d 人" % [class_text, GameManager.gold, GameManager.party.size()]

func _on_resume() -> void:
	GameManager.close_pause()

func _on_save() -> void:
	SaveManager.save_game(0)

func _on_main_menu() -> void:
	SaveManager.save_game(0)
	GameManager.enter_main_menu()

func _on_quit() -> void:
	SaveManager.save_game(0)
	get_tree().quit()

func _on_toast(text: String) -> void:
	if visible and info_label:
		info_label.text = text
