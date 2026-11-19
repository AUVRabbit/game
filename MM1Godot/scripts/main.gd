extends Node
## Entry point: defers to the router which owns scene transitions.

const HEADLESS_TEST := false  # Set true for automated headless testing
const SHOT_DIR := "/Users/l/game/report-assets/screenshots"

var _shot_count := 0

const AUTO_QUIT_AFTER_SHOT := true

func _ready() -> void:
	if HEADLESS_TEST:
		call_deferred("_headless_test")
	else:
		await get_tree().process_frame
		# State autoload already called new_game() in its _ready
		Router.load_map(State.map_id, State.player_x, State.player_y, State.player_direction, false)
		# change_scene_to_file 会把 main.gd 从 scene tree 移除，
		# 所以截图逻辑移到 Router.load_map() 内部

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F12:
			take_screenshot("manual_%d" % _shot_count)
		elif event.keycode == KEY_F11:
			# F11 连续截 5 张不同位置
			_auto_screenshot_sequence()

func take_screenshot(label: String = "shot") -> void:
	"""从 Godot viewport 内部截帧，保存 PNG。只捕获游戏画面，不包含桌面其他窗口。"""
	var dir := DirAccess.open(SHOT_DIR)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var tex := get_viewport().get_texture()   # ViewportTexture (继承 Texture2D)
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
		print("[SCREENSHOT] Saved viewport shot -> %s (%dx%d)" % [path, img.width, img.height])
	else:
		push_error("[SCREENSHOT] Failed to save: %s" % path)

func _auto_screenshot_sequence() -> void:
	"""移动玩家到几个位置分别截图，方便对比全地图。"""
	var ms := State.current_map
	if ms == null:
		return
	var positions := [
		{"x": 2,  "y": 15, "name": "center"},
		{"x": 0,  "y": 0,  "name": "top_left"},
		{"x": 19, "y": 0,  "name": "top_right"},
		{"x": 0,  "y": 29, "name": "bot_left"},
		{"x": 19, "y": 29, "name": "bot_right"},
	]
	for p in positions:
		var px: int = p["x"]
		var py: int = p["y"]
		var pname: String = p["name"]
		ms.player.tile_x = px
		ms.player.tile_y = py
		ms.player.position = Vector2(px * 32 + 16, py * 32 + 16)
		# 让相机跟随
		var cam: Camera2D = ms.player.get_node_or_null("Camera2D")
		if cam:
			cam.make_current()
		await get_tree().create_timer(0.3).timeout
		call_deferred("take_screenshot", "seq_%s_%02dx%02d" % [pname, px, py])
		await get_tree().process_frame

func _headless_test() -> void:
	_p("=== New game ===")
	State.new_game()
	_p("map_id=%d player=(%d,%d)" % [State.map_id, State.player_x, State.player_y])

	var ms_script: Script = load("res://scripts/core/map_scene.gd")
	var ms: Variant = ms_script.new()
	add_child(ms)
	call_deferred("_check_ev2", ms, 0)

func _check_ev2(ms: Variant, frame: int) -> void:
	if frame > 60:
		_p("TIMEOUT - EV2 not triggered after 60 frames")
		_p("EV2 page=%d trigger=%d interp_running=%s message_visible=%s bgm=%s" % [
			ms.events[2].page_index, ms.events[2].trigger(),
			ms.interpreter.running, ms.message.visible,
			get_node("/root/Audio")._current_bgm])
		get_tree().quit()
		return
	var ev2 = ms.events.get(2)
	if ev2 == null:
		_p("EV2 not found! Keys: %s" % ms.events.keys())
		get_tree().quit()
		return
	var pidx = ev2.page_index
	var trig = ev2.trigger()
	var interp = ms.interpreter.running
	var selfA = State.self_switch(1, 2, "A")
	var bgm = get_node("/root/Audio")._current_bgm
	_p("f=%d EV2 page=%d trig=%d interp=%s selfA=%s bgm=%s" % [frame, pidx, trig, interp, selfA, bgm])
	if pidx == 1 and selfA and not interp:
		_p("\n=== EV2 autorun OK! ===")
		_p("BGM playing: %s" % bgm)
		_p("Now testing EV12...")
		# Setup player in front of EV12 (9,4)
		ms.player.tile_x = 9
		ms.player.tile_y = 5
		ms.player.direction = 8  # up (facing EV12 at y=4)
		ms.player.position = Vector2(9 * 32 + 16, 5 * 32 + 16)
		call_deferred("_test_ev12", ms, 0)
		return
	call_deferred("_check_ev2", ms, frame + 1)

func _test_ev12(ms: Variant, step: int) -> void:
	if step < 15:
		call_deferred("_test_ev12", ms, step + 1)
		return
	_p("\n=== EV12 message test ===")
	_p("Before player_action: message_visible=%s interp=%s" % [ms.message.visible, ms.interpreter.running])
	ms.player_action()
	call_deferred("_check_ev12_msg", ms, 0)

func _check_ev12_msg(ms: Variant, step: int) -> void:
	if step < 20:
		call_deferred("_check_ev12_msg", ms, step + 1)
		return
	_p("After action: visible=%s mode=%s chars=%d interp=%s" % [
		ms.message.visible, ms.message._mode, ms.message._char_buf.size(), ms.interpreter.running])
	if ms.message._mode != "none":
		ms.message.finished.emit(0)
		_p("(closed message)")
	call_deferred("_test_ev14", ms, 0)

func _test_ev14(ms: Variant, step: int) -> void:
	if step < 5:
		call_deferred("_test_ev14", ms, step + 1)
		return
	_p("\n=== EV14 shop test ===")
	ms.player.tile_x = 10
	ms.player.tile_y = 11
	ms.player.direction = 8
	ms.player.position = Vector2(10 * 32 + 16, 11 * 32 + 16)
	ms.player_action()
	call_deferred("_check_ev14_result", ms, 0)

func _check_ev14_result(ms: Variant, step: int) -> void:
	if step < 20:
		call_deferred("_check_ev14_result", ms, step + 1)
		return
	_p("overlay=%s shop_type=%s goods=%d interp=%s" % [
		Router.has_overlay(), State.temp.get("shop_type"),
		len(State.temp.get("shop_goods", [])), ms.interpreter.running])
	if Router.has_overlay():
		Router.close_overlay()
	call_deferred("_test_ev15", ms, 0)

func _test_ev15(ms: Variant, step: int) -> void:
	if step < 5:
		call_deferred("_test_ev15", ms, step + 1)
		return
	_p("\n=== EV15 battle test ===")
	ms.player.tile_x = 11
	ms.player.tile_y = 11
	ms.player.direction = 8
	ms.player.position = Vector2(11 * 32 + 16, 11 * 32 + 16)
	ms.player_action()
	call_deferred("_check_ev15_result", ms, 0)

func _check_ev15_result(ms: Variant, step: int) -> void:
	if step < 20:
		call_deferred("_check_ev15_result", ms, step + 1)
		return
	_p("overlay=%s in_battle=%s interp=%s" % [
		Router.has_overlay(), State.in_battle, ms.interpreter.running])
	if Router.has_overlay():
		Router.close_overlay()
	_p("\n=== ALL TESTS DONE ===")
	get_tree().quit()

func _p(msg: String) -> void:
	print(msg)
