extends Node2D
## QA 独立验证工具 v2 —— 作者：查无漏 (QA-Performance)
## 带窗口运行（headless 不算通过）：
##   Godot --path /Users/l/game/MM1Godot res://tools/qa_wave_verify2.tscn -- real
##   Godot --path /Users/l/game/MM1Godot res://tools/qa_wave_verify2.tscn -- synth
## 产物写入 /Users/l/game/report-assets/qa_wave2/<timestamp>/，绝不覆盖任何已有图。

const SHOT_DIR := "/Users/l/game/report-assets/qa_wave2"

var _stamp: String = ""
var _dir: String = ""
var _log: Array[String] = []


func _say(s: String) -> void:
	print("[QA2] " + s)
	_log.append(s)


func _ready() -> void:
	_stamp = Time.get_datetime_string_from_system().replace(":", "-")
	_dir = SHOT_DIR + "/" + _stamp
	DirAccess.make_dir_recursive_absolute(_dir)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "real"
	_say("engine=%s renderer=%s vp=%s mode=%s dir=%s" % [
		str(Engine.get_version_info().get("string", "?")),
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")),
		str(get_viewport().get_visible_rect().size), mode, _dir])
	if mode == "synth":
		_run_synth()
	else:
		_run_real()


func _wait(n: int) -> void:
	for j in range(n):
		await RenderingServer.frame_post_draw


func _stats(img: Image) -> Array:
	var black := 0
	var white := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a > 0.9 and c.r < 0.06 and c.g < 0.06 and c.b < 0.06:
				black += 1
			if c.r > 0.88 and c.g > 0.90 and c.b > 0.92:
				white += 1
	return [black, white]


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var tex: Texture2D = get_viewport().get_texture()
	if tex == null:
		_say("CAP %s viewport TEX NULL" % label)
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		_say("CAP %s IMG EMPTY" % label)
		return
	var path := "%s/%s_%s.png" % [_dir, label, _stamp]
	var err: int = img.save_png(path)
	var st: Array = _stats(img)
	_say("CAP %s -> %s black=%d white=%d err=%d" % [label, path.get_file(), st[0], st[1], err])


func _flush() -> void:
	var f := FileAccess.open(_dir + "/qa2_report.txt", FileAccess.WRITE)
	if f != null:
		for line in _log:
			f.store_line(line)
		f.close()


# ---------------------------------------------------------------- real map
func _run_real() -> void:
	_say("map_id=%d" % int(State.get("map_id")))
	var map_scene = load("res://scenes/map.tscn").instantiate()
	add_child(map_scene)
	await _wait(30)
	var wr: Node = null
	for c in map_scene.get_children():
		var s: Script = c.get_script() if c is Node else null
		if s != null and s.resource_path == "res://scripts/core/water_renderer.gd":
			wr = c
			break
	_say("WaterRenderer=%s water_tiles=%d shore_tex=%d" % [
		str(wr != null),
		(wr.get("_water_tiles").size() if wr != null else -1),
		(wr.get("_shore_textures").size() if wr != null else -1)])
	var player = map_scene.get("player")
	# 四处边界：顶横边 / 底横边 / x=12 竖条陆地左右 / 左列 x=0
	for spec in [
		{"n": "real_top", "x": 6, "y": 2},
		{"n": "real_bottom", "x": 6, "y": 23},
		{"n": "real_pillar", "x": 10, "y": 1},
		{"n": "real_left", "x": 1, "y": 10}]:
		if player != null:
			player.tile_x = spec["x"]
			player.tile_y = spec["y"]
			player.position = Vector2(spec["x"] * 32 + 16, spec["y"] * 32 + 16)
		await _wait(24)
		await _capture(spec["n"])
	# 动画 4 帧（顶部边界，间隔 22 帧 > 20 帧切换间隔）
	if player != null:
		player.tile_x = 6
		player.tile_y = 2
		player.position = Vector2(6 * 32 + 16, 2 * 32 + 16)
	await _wait(24)
	for i in range(4):
		await _wait(22)
		await _capture("real_anim_f%d" % i)
	# A/B 黑像素对照：同视角 有浪花 vs 运行时关闭浪花叠加
	await _capture("real_AB_with")
	if wr != null:
		wr.set("_shore_textures", {})
		wr.queue_redraw()
		await _wait(4)
		await _capture("real_AB_without")
	_say("=== REAL DONE ===")
	_flush()
	get_tree().quit()


# ---------------------------------------------------------------- synthetic corners
func _run_synth() -> void:
	# 沙色背景模拟陆地，便于观察浪花是否贴在“水的靠陆地侧”
	var bg := ColorRect.new()
	bg.color = Color(0.96, 0.82, 0.55, 1.0)
	bg.position = Vector2.ZERO
	bg.size = Vector2(640, 480)
	add_child(bg)

	var tex: Texture2D = load("res://assets/graphics/Autotiles/001-G_Water01.png")
	var w := 20
	var h := 15
	var l0: Array = []
	for i in range(w * h):
		l0.append(1)   # 全陆地 tid=1
	var put := func(x: int, y: int, tid: int) -> void:
		if x >= 0 and y >= 0 and x < w and y < h:
			l0[y * w + x] = tid

	# A 顶部横边水块 row1..2, col1..6（四周皆陆 → 四边浪花，含水平边）
	for y in range(1, 3):
		for x in range(1, 7):
			put.call(x, y, 48)
	# B 单格孤立水格 (3,7)：四周皆陆 → 四边浪花应齐全
	put.call(3, 7, 48)
	# C 竖条陆地 col=6 row5..11；col5/col7 为水 → 左右竖浪花
	for y in range(5, 12):
		put.call(6, y, 1)
		put.call(5, y, 48)
		put.call(7, y, 48)
	# D L 形凹角：水块 col9..14 row2..8，挖 L 陆地 (10,4)(10,5)(11,4)
	#    水格 (11,5) 上邻陆 + 左邻陆 → mask=9，左上角浪花须连续不断裂
	for y in range(2, 9):
		for x in range(9, 15):
			put.call(x, y, 48)
	for p in [[10, 4], [10, 5], [11, 4]]:
		put.call(int(p[0]), int(p[1]), 1)
	# F 底部横边水块 row12..13, col1..6
	for y in range(12, 14):
		for x in range(1, 7):
			put.call(x, y, 48)

	var wr_script: Script = load("res://scripts/core/water_renderer.gd")
	var wr = wr_script.new()
	wr.z_index = 1
	add_child(wr)
	wr.configure(tex, w, h, [l0])
	_say("synth water_tiles=%d mask_hist=%s" % [
		wr.get("_water_tiles").size(), str(_mask_hist(wr.get("_water_tiles")))])
	await _wait(20)
	await _capture("synth_all")
	_say("=== SYNTH DONE ===")
	_flush()
	get_tree().quit()


func _mask_hist(tiles: Array) -> Dictionary:
	var d := {}
	for t in tiles:
		var m: int = int(t[3])
		d[m] = int(d.get(m, 0)) + 1
	return d
