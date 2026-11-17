class_name UISkin
extends RefCounted
## Drawing helpers for RMXP windowskins and text.

static var _font: Font = null


static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["PingFang SC", "Heiti SC", "Hiragino Sans GB",
			"Microsoft YaHei", "Noto Sans CJK SC", "WenQuanYi Micro Hei", "sans-serif"])
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_font = f
	return _font


static func draw_window(ci: CanvasItem, rect: Rect2, skin: Texture2D, alpha: float = 0.86) -> void:
	if skin == null:
		ci.draw_rect(rect, Color(0.05, 0.07, 0.12, 0.92))
		ci.draw_rect(rect, Color(0.85, 0.85, 0.9, 0.9), false, 1.0)
		return
	var m := 16.0
	var src := Rect2(0, 0, 64, 64)
	var xs := [0.0, m, 64.0 - m]
	var ys := [0.0, m, 64.0 - m]
	var ws := [m, 64.0 - m * 2.0, m]
	for ix in range(3):
		for iy in range(3):
			if ws[ix] <= 0 or ws[iy] <= 0:
				continue
			var s := Rect2(src.position + Vector2(xs[ix], ys[iy]), Vector2(ws[ix], ws[iy]))
			var d := Rect2(rect.position + Vector2(xs[ix], ys[iy]), Vector2(ws[ix], ws[iy]))
			ci.draw_texture_rect_region(skin, d, s, Color(1, 1, 1, alpha))
	# frame
	var frame_src := Rect2(64, 0, 64, 64)
	for ix in range(3):
		for iy in range(3):
			if ws[ix] <= 0 or ws[iy] <= 0:
				continue
			var s := Rect2(frame_src.position + Vector2(xs[ix], ys[iy]), Vector2(ws[ix], ws[iy]))
			var d := Rect2(rect.position + Vector2(xs[ix], ys[iy]), Vector2(ws[ix], ws[iy]))
			ci.draw_texture_rect_region(skin, d, s, Color(1, 1, 1, 0.95))


static func draw_cursor(ci: CanvasItem, rect: Rect2, skin: Texture2D) -> void:
	if skin != null:
		ci.draw_texture_rect_region(skin, rect, Rect2(0, 64, 64, 64), Color(1, 1, 1, 0.75))
	else:
		ci.draw_rect(rect, Color(1, 1, 1, 0.18))
	ci.draw_rect(rect, Color(1, 1, 1, 0.35), false, 1.0)
	ci.draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(4, rect.size.y * 0.5 - 5),
		rect.position + Vector2(11, rect.size.y * 0.5),
		rect.position + Vector2(4, rect.size.y * 0.5 + 5)
	]), Color(1, 1, 1, 0.9))


static func draw_text(ci: CanvasItem, pos: Vector2, text: String, size: int = 20,
		color: Color = Color(1, 1, 1), outline: bool = true) -> void:
	var f := font()
	if outline:
		ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(0, 0, 0, 0.9))
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func draw_text_center(ci: CanvasItem, rect: Rect2, text: String, size: int = 20,
		color: Color = Color(1, 1, 1)) -> void:
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(rect.position.x + (rect.size.x - w) * 0.5, rect.position.y + rect.size.y * 0.5 + size * 0.35)
	draw_text(ci, pos, text, size, color)


static func draw_text_right(ci: CanvasItem, rect: Rect2, text: String, size: int = 20,
		color: Color = Color(1, 1, 1)) -> void:
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(rect.position.x + rect.size.x - w, rect.position.y + rect.size.y * 0.5 + size * 0.35)
	draw_text(ci, pos, text, size, color)


static func text_size(text: String, size: int = 20) -> Vector2:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)


static func wrap_text(text: String, size: int, max_width: float) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for ch in text:
		var trial := line + ch
		if text_size(trial, size).x > max_width and not line.is_empty():
			out.append(line)
			line = ch
		else:
			line = trial
	if not line.is_empty():
		out.append(line)
	return out
