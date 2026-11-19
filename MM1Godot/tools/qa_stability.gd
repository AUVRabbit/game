extends Node2D
## QA 稳定性专测：验证 router.gd frame_post_draw 修复机制 + 动画帧无黑洞
## 作者：查无漏 (QA-Performance)

const TILE := 32
var _log: Array[String] = []

func _say(s: String) -> void:
	print("[STAB] " + s)
	_log.append(s)

func _ready() -> void:
	var packed: PackedScene = load("res://scenes/map.tscn")
	add_child(packed.instantiate())
	_run()

func _black(img: Image) -> int:
	var n := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a > 0.9 and c.r < 0.06 and c.g < 0.06 and c.b < 0.06:
				n += 1
	return n

func _raw_img() -> Image:
	var tex := get_viewport().get_texture()
	return tex.get_image()

func _run() -> void:
	for j in range(30):
		await RenderingServer.frame_post_draw

	# A) 不等待，立即读（复现半帧假象的旧写法）
	var img_raw: Image = _raw_img()
	_say("A raw-immediate blackpx=%d (半帧假象对照)" % _black(img_raw))

	# B) fix 写法：2x frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img_fix1: Image = _raw_img()
	_say("B fixed(2x post_draw) #1 blackpx=%d" % _black(img_fix1))

	# C) 再连续截一张，逐像素比对是否与 B 完全一致
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img_fix2: Image = _raw_img()
	var diff := 0
	for y in range(img_fix2.get_height()):
		for x in range(img_fix2.get_width()):
			if img_fix1.get_pixel(x, y) != img_fix2.get_pixel(x, y):
				diff += 1
	_say("C fixed #2 blackpx=%d ; pixel-diff(B vs C)=%d (0=完全稳定)" % [
		_black(img_fix2), diff])

	# D) 跨越多个动画周期(每20帧切frame)，每25帧记录黑像素，检查是否出现黑洞
	var prev: Image = img_fix2
	for k in range(6):
		for jj in range(25):
			await RenderingServer.frame_post_draw
		var cur: Image = _raw_img()
		var changed := 0
		for y in range(cur.get_height()):
			for x in range(cur.get_width()):
				if cur.get_pixel(x, y) != prev.get_pixel(x, y):
					changed += 1
		_say("D tick%d blackpx=%d changed_vs_prev=%d (波纹应变化,黑洞不应出现)" % [
			k, _black(cur), changed])
		prev = cur

	_say("=== STABILITY DONE ===")
	var f := FileAccess.open("/Users/l/game/report-assets/qa_verify/qa_stability_report.txt", FileAccess.WRITE)
	if f != null:
		for line in _log:
			f.store_line(line)
		f.close()
	get_tree().quit()
