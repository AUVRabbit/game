# ============================================================
# MainMenu — 主菜单（新游戏 / 继续 / 通天塔试炼 / 设置 / 退出）
# 纯代码构建，含存档检测与设置持久化
# ============================================================

extends Control
class_name MainMenu

const SETTINGS_PATH := "user://settings.cfg"

var root: Control
var continue_button: Button
var save_info: Label
var settings_panel: PanelContainer
var volume_slider: HSlider
var fullscreen_check: CheckButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_title()
	_build_buttons()
	_build_settings()
	_build_footer()
	_load_settings()
	_refresh_save_info()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.11)
	add_child(bg)
	# 真实主菜单背景（通天塔夜景）
	var bg_tex: Texture2D = _load_menu_background()
	if bg_tex:
		var texture_rect := TextureRect.new()
		texture_rect.texture = bg_tex
		texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(texture_rect)
	var accent := ColorRect.new()
	accent.position = Vector2(0, 380)
	accent.size = Vector2(960, 160)
	accent.color = Color(0.12, 0.08, 0.22, 0.45)
	add_child(accent)
	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(960, 6)
	top.color = Color(0.55, 0.4, 0.95)
	add_child(top)

func _load_menu_background() -> Texture2D:
	return AssetLibrary.texture("ui_menu_bg")

func _build_title() -> void:
	var title := Label.new()
	title.text = "通天入地"
	title.position = Vector2(0, 70)
	title.size = Vector2(960, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.5))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "TOWER OF FOUR PUNKS · 法术 / 机械 / 传武 / 科技"
	subtitle.position = Vector2(0, 160)
	subtitle.size = Vector2(960, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	add_child(subtitle)

func _build_buttons() -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(350, 205)
	vbox.custom_minimum_size = Vector2(260, 0)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	var new_button := Button.new()
	new_button.text = "新游戏"
	new_button.custom_minimum_size = Vector2(260, 42)
	new_button.pressed.connect(_on_new_game)
	vbox.add_child(new_button)

	continue_button = Button.new()
	continue_button.text = "继续游戏"
	continue_button.custom_minimum_size = Vector2(260, 42)
	continue_button.pressed.connect(_on_continue)
	vbox.add_child(continue_button)

	var tower_button := Button.new()
	tower_button.text = "通天塔试炼（Roguelike）"
	tower_button.custom_minimum_size = Vector2(260, 42)
	tower_button.pressed.connect(_on_tower)
	vbox.add_child(tower_button)

	var settings_button := Button.new()
	settings_button.text = "设置"
	settings_button.custom_minimum_size = Vector2(260, 42)
	settings_button.pressed.connect(_toggle_settings)
	vbox.add_child(settings_button)

	var quit_button := Button.new()
	quit_button.text = "退出"
	quit_button.custom_minimum_size = Vector2(260, 42)
	quit_button.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_button)

	save_info = Label.new()
	save_info.position = Vector2(130, 505)
	save_info.size = Vector2(700, 22)
	save_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_info.add_theme_font_size_override("font_size", 13)
	save_info.add_theme_color_override("font_color", Color(0.72, 0.76, 0.9))
	save_info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	save_info.add_theme_constant_override("shadow_offset_x", 1)
	save_info.add_theme_constant_override("shadow_offset_y", 1)
	add_child(save_info)

func _build_settings() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(330, 180)
	settings_panel.custom_minimum_size = Vector2(300, 230)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.15, 0.98)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.5, 0.8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	settings_panel.add_theme_stylebox_override("panel", sb)
	add_child(settings_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	settings_panel.add_child(vbox)
	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_label("主音量"))
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = 0.8
	volume_slider.value_changed.connect(_on_volume_changed)
	vbox.add_child(volume_slider)

	fullscreen_check = CheckButton.new()
	fullscreen_check.text = "全屏显示"
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fullscreen_check)

	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(_toggle_settings)
	vbox.add_child(close)
	settings_panel.visible = false

func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	return label

func _build_footer() -> void:
	var hint := Label.new()
	hint.text = "WASD 移动 · 左键/空格 攻击 · 1/2/3 技能 · Shift 冲刺 · I 背包 · B 建造 · K 技能树 · Esc 暂停"
	hint.position = Vector2(0, 470)
	hint.size = Vector2(960, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.78, 0.82, 0.95))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	add_child(hint)

	var version := Label.new()
	version.text = "v0.3.0 · Godot 4.7.2"
	version.position = Vector2(820, 512)
	version.size = Vector2(130, 20)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58))
	add_child(version)

func _refresh_save_info() -> void:
	var has_save := SaveManager.has_save(0)
	continue_button.disabled = not has_save
	if has_save:
		save_info.text = "检测到存档（槽位 0），可继续上次的旅程"
	else:
		save_info.text = "暂无存档，开始一段新的旅途吧"

func _on_new_game() -> void:
	GameManager.start_new_game()

func _on_continue() -> void:
	if not SaveManager.load_game(0):
		EventBus.notify("读取存档失败")

func _on_tower() -> void:
	GameManager.start_tower_run()

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_volume_changed(value: float) -> void:
	if AudioManager:
		AudioManager.set_master_volume(value)
	_save_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_save_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var volume := float(config.get_value("audio", "volume", 0.8))
	var fullscreen := bool(config.get_value("video", "fullscreen", false))
	if volume_slider:
		volume_slider.set_value_no_signal(volume)
	if AudioManager:
		AudioManager.set_master_volume(volume)
	_fullscreen_apply(fullscreen)
	if fullscreen_check:
		fullscreen_check.set_pressed_no_signal(fullscreen)

func _fullscreen_apply(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _save_settings() -> void:
	var config := ConfigFile.new()
	if volume_slider:
		config.set_value("audio", "volume", volume_slider.value)
	if fullscreen_check:
		config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.save(SETTINGS_PATH)
