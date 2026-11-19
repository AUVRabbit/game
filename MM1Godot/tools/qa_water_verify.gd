extends Node2D
## 独立 QA 验证场景脚本（作者：查无漏 / QA-Performance）
## 目的：画面级 + 像素级独立验证水文修复，不依赖架构师结论。
## 运行：Godot --path /Users/l/game/MM1Godot res://tools/qa_water_verify.tscn （带窗口）
## 输出到新路径 /Users/l/game/report-assets/qa_verify，绝不覆盖已有截图。

const SHOT_DIR := "/Users/l/game/report-assets/qa_verify"
const TILE := 32
const SUB := 16

var map_scene: Node = null
var wr: Node = null
var _log: Array[String] = []


func _say(s: String) -> void:
	print("[QA] " + s)
	_log.append(s)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	_say("QA ready. viewport=%s renderer=%s" % [
		str(get_viewport().get_visible_rect().size),
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "?")])
	# 实例化真实地图场景，走完整管线（below/water/above + 角色 + 相机）
	var packed: PackedScene = load("res://scenes/map.tscn")
	map_scene = packed.instantiate()
	add_child(map_scene)
	# 找到 WaterRenderer（通过脚本路径识别）
	for c in map_scene.get_children():
		var s: Script = c.get_script() if c is Node else null
		if s != null and s.resource_path == "res://scripts/core/water_renderer.gd":
			wr = c
			break
	_say("map_scene instantiated. WaterRenderer found=%s" % str(wr != null))
	_run()


func _wait_frames(n: int) -> void:
	for j in range(n):
		await RenderingServer.frame_post_draw


func _run() -> void:
	# 等待地图 + 预渲染稳定
	await _wait_frames(30)

	# --- 画面级：连续 4 次截帧，覆盖 4 个动画 frame（每 20 帧切换）---
	# 出生点视角（架构师同款），玩家 (9,7)
	for i in range(4):
		await _wait_frames(22)
		await _capture("qa_spawn_f%d" % i)

	# --- 画面级：把相机移到两处 bug tile 附近再各截一张 ---
	if map_scene != null and map_scene.get("player") != null:
		var player = map_scene.get("player")
		for spec in [{"n": "tile0_3", "x": 2, "y": 4}, {"n": "tile0_22", "x": 2, "y": 23}]:
			player.tile_x = spec["x"]
			player.tile_y = spec["y"]
			player.position = Vector2(spec["x"] * TILE + 16, spec["y"] * TILE + 16)
			await _wait_frames(24)
			await _capture("qa_%s" % spec["n"])

	# --- 像素级确定性探针 ---
	_probe_source_alpha()
	_probe_cache_quadrants()
	_reproduce_unfixed()

	_say("=== QA DONE ===")
	var f = FileAccess.open(SHOT_DIR + "/qa_report.txt", FileAccess.WRITE)
	if f != null:
		for line in _log:
			f.store_line(line)
		f.close()
	get_tree().quit()


func _capture(label: String) -> void:
	# 与 router.gd 一致：等整帧 GPU 绘制完成，避免半帧假象
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null:
		_say("CAPTURE %s: viewport texture NULL" % label)
		return
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		_say("CAPTURE %s: image empty" % label)
		return
	var ts := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s_%s.png" % [SHOT_DIR, label, ts]
	var err := img.save_png(path)
	# 黑像素统计（近纯黑且不透明）
	var w := img.get_width()
	var h := img.get_height()
	var black := 0
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a > 0.9 and c.r < 0.06 and c.g < 0.06 and c.b < 0.06:
				black += 1
	_say("CAPTURE %s -> %s (%dx%d) blackpx=%d (%.3f%%) err=%d" % [
		label, path.get_file(), w, h, black, 100.0 * float(black) / float(w * h), err])


func _probe_source_alpha() -> void:
	if wr == null:
		_say("PROBE src: no WaterRenderer, skip")
		return
	var tex: Texture2D = wr.get("_autotile_texture")
	if tex == null:
		_say("PROBE src: no texture")
		return
	var img: Image = tex.get_image()
	for f in range(4):
		var parts := []
		for idx_v in [2, 3, 6, 7, 18]:
			var idx: int = int(idx_v)
			var col: int = idx % 4
			var row: int = idx / 4
			var sx: int = col * SUB + f * 96
			var sy: int = row * SUB
			var sub: Image = img.get_region(Rect2i(sx, sy, SUB, SUB))
			var a_min: int = 255
			var a_max: int = 0
			for yy in range(SUB):
				for xx in range(SUB):
					var a: int = sub.get_pixel(xx, yy).a8
					if a < a_min: a_min = a
					if a > a_max: a_max = a
			parts.append("idx%d[a%d..%d]" % [idx, a_min, a_max])
		_say("SRC frame%d: %s" % [f, ", ".join(parts)])


func _quad_transparent_count(img: Image) -> int:
	# 返回 32x32 tile 中“整块 16x16 全透明”的象限数（=黑洞块数）
	var cnt := 0
	for q in range(4):
		var ox := (q % 2) * SUB
		var oy := (q / 2) * SUB
		var all_transparent := true
		for yy in range(SUB):
			for xx in range(SUB):
				if img.get_pixel(ox + xx, oy + yy).a > 0.05:
					all_transparent = false
					break
			if not all_transparent:
				break
		if all_transparent:
			cnt += 1
	return cnt


func _probe_cache_quadrants() -> void:
	if wr == null:
		_say("PROBE cache: no WaterRenderer, skip")
		return
	var cache: Dictionary = wr.get("_tile_cache")
	var bad: Array[String] = []
	for v in range(48):
		for f in range(4):
			var key := "%d_%d" % [v, f]
			if not cache.has(key):
				continue
			var tex2: Texture2D = cache[key]
			var im: Image = tex2.get_image()
			var tq := _quad_transparent_count(im)
			if tq > 0:
				bad.append("%s:%d" % [key, tq])
	_say("CACHE quadrants: total_checked=%d bad_tiles=%d bad_list=%s" % [
		cache.size(), bad.size(), str(bad)])
	# 两个已知 bug variant 的逐帧细查
	for v in [2, 4]:
		var line := []
		for f in range(4):
			var key := "%d_%d" % [v, f]
			var tq := -1
			if cache.has(key):
				tq = _quad_transparent_count((cache[key] as Texture2D).get_image())
			line.append("f%d=%d" % [f, tq])
		_say("CACHE variant%d transparent_quads(0=clean): %s" % [v, ", ".join(line)])


func _reproduce_unfixed() -> void:
	# 用原始 AUTOTILE_PARTS（无回退）重建 variant2/4，确认能复现黑洞块
	if wr == null:
		return
	var tex: Texture2D = wr.get("_autotile_texture")
	var parts: PackedInt32Array = wr.get("AUTOTILE_PARTS")
	var src: Image = tex.get_image()
	for v in [2, 4]:
		var line := []
		for f in range(4):
			var img: Image = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var base: int = int(v) * 4
			for i in range(4):
				var idx: int = int(parts[base + i])  # 故意不回退
				var col: int = idx % 4
				var row: int = idx / 4
				var sx: int = col * SUB + f * 96
				var sy: int = row * SUB
				var sub: Image = src.get_region(Rect2i(sx, sy, SUB, SUB))
				var qx: int = (i % 2) * SUB
				var qy: int = (i / 2) * SUB
				img.blit_rect(sub, Rect2i(0, 0, SUB, SUB), Vector2i(qx, qy))
			line.append("f%d=%d" % [f, _quad_transparent_count(img)])
		_say("UNFIXED(repro) variant%d transparent_quads(>=1=bug reproduced): %s" % [v, ", ".join(line)])
