extends Node
## Scene / overlay routing, fades and a few global helpers.

signal overlay_closed

const TITLE_SCENE := "res://scenes/title.tscn"
const MAP_SCENE := "res://scenes/map.tscn"

const OVERLAY_SCENES := {
	"Scene_Menu": "res://scripts/ui/menu.gd",
	"Scene_Shop": "res://scripts/shops/shop_scene.gd",
	"Scene_CannonBallShop": "res://scripts/shops/cannonball_shop.gd",
	"Scene_RepairShop": "res://scripts/shops/repair_shop.gd",
	"Scene_SupplyShop": "res://scripts/shops/supply_shop.gd",
	"Scene_TankRent": "res://scripts/shops/tank_rent.gd",
	"Scene_TransformShop": "res://scripts/shops/transform_shop.gd",
	"Scene_EngineTransformShop": "res://scripts/shops/engine_transform_shop.gd",
	"Scene_StorageShop": "res://scripts/shops/storage_shop.gd",
	"Scene_WantedOffice": "res://scripts/shops/wanted_office.gd",
	"Scene_Machine": "res://scripts/systems/machine_scene.gd",
	"Scene_MusicBox": "res://scripts/systems/music_box.gd",
	"Scene_Save": "res://scripts/systems/save_scene.gd",
	"Scene_NameEntry": "res://scripts/ui/name_entry.gd",
}

var ui_layer: CanvasLayer
var overlay: Control = null
var fade_rect: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fl := CanvasLayer.new()
	fl.layer = 100
	add_child(fl)
	fl.add_child(fade_rect)


func _setup_input() -> void:
	_action("move_up", [KEY_UP, KEY_W])
	_action("move_down", [KEY_DOWN, KEY_S])
	_action("move_left", [KEY_LEFT, KEY_A])
	_action("move_right", [KEY_RIGHT, KEY_D])
	_action("action", [KEY_Z, KEY_ENTER, KEY_SPACE, KEY_KP_ENTER])
	_action("cancel", [KEY_X, KEY_ESCAPE, KEY_BACKSPACE])
	_action("menu", [KEY_C, KEY_TAB, KEY_SHIFT])
	_action("debug", [KEY_F9])


func _action(action_name: String, keys: Array) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputMap.add_action(action_name)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action_name, ev)


# -------------------------------------------------------------------- screenshot
const SHOT_DIR := "/Users/l/game/report-assets/screenshots"
var _shot_count := 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			take_screenshot("manual_%d" % _shot_count)

func take_screenshot(label: String = "shot") -> void:
	"""从 Godot viewport 内部截帧，保存 PNG。只捕获游戏画面，不包含桌面其他窗口。"""
	# GL Compatibility 下必须等整帧 GPU 绘制完成, 否则 get_image() 会读到
	# 半帧 (表现为只剩最左一列 water tile、其余全黑 —— 见 godot_vs_expected.png)。
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dir := DirAccess.open(SHOT_DIR)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var tex := get_viewport().get_texture()
	if tex == null:
		push_warning("take_screenshot: viewport texture is null")
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		push_warning("take_screenshot: image is empty (ViewportTexture may need one frame)")
		return
	_shot_count += 1
	var ts := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s_%s.png" % [SHOT_DIR, label, ts]
	var err := img.save_png(path)
	if err == OK:
		print("[SCREENSHOT] Saved viewport shot -> %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	else:
		push_error("[SCREENSHOT] Failed to save: %s" % path)


# ------------------------------------------------------------------ transitions
func start() -> void:
	await fade_in(0.3)
	go_title()


func go_title() -> void:
	close_overlay()
	get_tree().paused = false
	await fade_out(0.25)
	get_tree().change_scene_to_file(TITLE_SCENE)
	await get_tree().process_frame
	await fade_in(0.35)


func new_game() -> void:
	State.new_game()
	await load_map(State.map_id, State.player_x, State.player_y, State.player_direction)


func load_saved_game(slot: int) -> bool:
	if not Saver.load_game(slot):
		return false
	await load_map(State.map_id, State.player_x, State.player_y, State.player_direction, false)
	return true


func load_map(map_id: int, x: int, y: int, direction: int = 2, fade: bool = true) -> void:
	State.map_id = map_id
	State.player_x = x
	State.player_y = y
	State.player_direction = direction
	close_overlay()
	get_tree().paused = false
	if fade:
		await fade_out(0.25)
	var err := get_tree().change_scene_to_file(MAP_SCENE)
	if err != OK:
		push_error("Failed to load map scene: %d" % err)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if fade:
		await fade_in(0.3)
	# 地图加载完成后等待动画渲染再截图（等 1.5s 覆盖至少 1 个完整动画周期）
	await get_tree().create_timer(1.5).timeout
	await take_screenshot("map001_water")
	# 截图后不自动退出，方便手动验证动画
	# await get_tree().create_timer(0.5).timeout
	get_tree().quit()
	# get_tree().quit()


func refresh_map() -> void:
	get_tree().reload_current_scene()


# -------------------------------------------------------------------- overlays
func open_overlay(node: Node) -> void:
	close_overlay()
	overlay = node as Control if node is Control else null
	ui_layer.add_child(node)
	if node is Control:
		(node as Control).set_anchors_preset(Control.PRESET_FULL_RECT)


func close_overlay() -> void:
	var had := overlay != null and is_instance_valid(overlay)
	if had:
		overlay.queue_free()
	overlay = null
	if had:
		overlay_closed.emit()


func has_overlay() -> bool:
	return overlay != null and is_instance_valid(overlay)


func show_gameover() -> void:
	Audio.stop_bgm()
	Audio.play_me("all_dead")
	var go_script: Script = load("res://scripts/ui/gameover.gd")
	var gameover: Variant = go_script.new()
	open_overlay(gameover)
	await gameover.closed
	close_overlay()
	go_title()


# ------------------------------------------------------------ RPG Maker scenes
func open_game_scene(scene_name: String) -> void:
	match scene_name:
		"Scene_Title":
			go_title()
			return
		"Scene_Map":
			return
		"Scene_Gameover":
			show_gameover()
			return
	if OVERLAY_SCENES.has(scene_name):
		var path: String = OVERLAY_SCENES[scene_name]
		if ResourceLoader.exists(path):
			var script: Script = load(path)
			var node = script.new()
			if node is Control:
				open_overlay(node)
				return
			node.queue_free()
	var ph_script: Script = load("res://scripts/ui/placeholder_scene.gd")
	var ph: Variant = ph_script.new(scene_name)
	open_overlay(ph)


# ----------------------------------------------------------------------- fades
func fade_out(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished


func fade_in(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished


func transition_black(duration: float = 0.2) -> void:
	await fade_out(duration)


func transition_clear(duration: float = 0.2) -> void:
	await fade_in(duration)


# ------------------------------------------------------------------ utilities
func map_scene() -> Node:
	return get_tree().current_scene


func flash(color: Color = Color(1, 1, 1, 0.6), duration: float = 0.2) -> void:
	fade_rect.color = color
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
