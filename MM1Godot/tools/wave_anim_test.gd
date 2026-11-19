extends Node2D
## 动画帧稳定性测试：同一边界点连续截帧，验证浪花边恒定 + 水波纹在变化。
const SHOT_DIR := "/Users/l/game/report-assets/wave_diag"
var map_scene: Node = null
var _stamp: String = ""

func _ready() -> void:
	_stamp = Time.get_datetime_string_from_system().replace(":", "-")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	map_scene = load("res://scenes/map.tscn").instantiate()
	add_child(map_scene)
	_run()

func _wait(n: int) -> void:
	for j in range(n):
		await RenderingServer.frame_post_draw

func _run() -> void:
	await _wait(30)
	var player = map_scene.get("player")
	# 定位到顶部水域边界
	player.tile_x = 6
	player.tile_y = 2
	player.position = Vector2(6 * 32 + 16, 2 * 32 + 16)
	await _wait(24)
	# 每22帧(>20帧间隔)截一张，覆盖4个动画帧
	for i in range(4):
		await _wait(22)
		await _capture("anim_shore_f%d" % i)
	print("[WAVEANIM] DONE stamp=%s" % _stamp)
	get_tree().quit()

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	if tex == null: return
	var img: Image = tex.get_image()
	if img == null or img.is_empty(): return
	var p := "%s/%s_%s.png" % [SHOT_DIR, label, _stamp]
	var err := img.save_png(p)
	# 统计边界带(y=118..134)白像素列数 + 水域内部(y=40..100)像素签名
	var shore := 0
	var inner := 0
	for x in range(img.get_width()):
		var wc := 0
		for y in range(118, 134):
			var c := img.get_pixel(x, y)
			if c.r > 0.78 and c.g > 0.78 and c.b > 0.78: wc += 1
		if wc >= 2: shore += 1
		var ic := img.get_pixel(x, 60)
		inner += int(ic.r * 255) + int(ic.g * 255) * 3
	print("[WAVEANIM] %s shore_cols=%d inner_sig=%d err=%d" % [label, shore, inner, err])
