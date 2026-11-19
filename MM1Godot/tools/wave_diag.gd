extends Node2D
## 架构师专用：边界水花诊断截图（修复前/后对比）
## 带窗口运行，定位到 map001 的水陆边界，逐点截图。
## 所有产物写入新时间戳目录，绝不覆盖 QA / report-assets 已有文件。

const SHOT_DIR := "/Users/l/game/report-assets/wave_diag"

var map_scene: Node = null
var _log: Array[String] = []
var _stamp: String = ""

func _say(s: String) -> void:
	print("[WAVEDIAG] " + s)
	_log.append(s)

func _ready() -> void:
	_stamp = Time.get_datetime_string_from_system().replace(":", "-")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var packed: PackedScene = load("res://scenes/map.tscn")
	map_scene = packed.instantiate()
	add_child(map_scene)
	_run()

func _wait(n: int) -> void:
	for j in range(n):
		await RenderingServer.frame_post_draw

func _run() -> void:
	await _wait(30)
	var player = map_scene.get("player") if map_scene != null else null
	_say("player=%s" % str(player != null))
	# 边界取样点：
	#  A) 顶部水域下沿 y=3, x=1..14 (v28/v38 纯水边界) —— 玩家放 y=2 让边界入镜
	#  B) 底部水域上沿 y=22, x=1..14 (v20/v36/v34)
	#  C) 竖条陆地 x=12, y=1..3 (左右两侧水夹陆地)
	var specs = [
		{"n": "TOP_shore_y3", "x": 6, "y": 2},
		{"n": "BOT_shore_y22", "x": 6, "y": 23},
		{"n": "PILLAR_x12", "x": 10, "y": 1},
		{"n": "LEFT_col_x0", "x": 1, "y": 10},
	]
	for spec in specs:
		if player != null:
			player.tile_x = spec["x"]
			player.tile_y = spec["y"]
			player.position = Vector2(spec["x"] * 32 + 16, spec["y"] * 32 + 16)
		await _wait(26)  # 覆盖至少1个动画周期，落在某个稳定帧
		await _capture(spec["n"])
	_say("=== DONE ===")
	var f = FileAccess.open("%s/wavediag_%s.txt" % [SHOT_DIR, _stamp], FileAccess.WRITE)
	if f != null:
		for line in _log: f.store_line(line)
		f.close()
	get_tree().quit()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		_say("CAP %s: viewport tex null" % label); return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		_say("CAP %s: empty" % label); return
	var path := "%s/%s_%s.png" % [SHOT_DIR, label, _stamp]
	var err := img.save_png(path)
	_say("CAP %s -> %s err=%d" % [label, path.get_file(), err])
