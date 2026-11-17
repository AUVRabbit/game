class_name MessageWindow
extends Control
## MM-style message / choice window.
# Reference: Window_Message (198_Window_Message.rb).
# MESSAGE_TALK mode (map): x=240, y=300, width=440, height=180.
# 4 rows x 7 CJK chars each at font size 20; auto-scrolls every 4 lines.
# Uses Dialog_Movie.png as full-screen backdrop and Dialog_Wait.png after 4 pages.

const MSG_X := 240
const MSG_Y := 300
const MSG_W := 440
const MSG_H := 180
const ROW_COUNT := 4
const CHARS_PER_ROW := 7
const TEXT_SIZE := 20
const LINE_H := 28.0
const TEXT_X := MSG_X + 30.0
const TEXT_Y0 := MSG_Y + 18.0

var _movie_tex: Texture2D
var _wait_tex: Texture2D
var _cursor_tex: Texture2D

var _char_buf := PackedInt32Array()   # one codepoint per entry, excluding \t/\n
var _glyph_index := 0
var _glyph_row := 0
var _typing := false
var _waiting := false
var _wait_visible := false
var _wait_timer := 0.0
var _fade_in := 0.0
var _mode := "none"
var _choices: Array = []
var _choice_index := 0
var _choice_visible := false
var _select_start_row := 0


func _ready() -> void:
	_load_textures()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	queue_redraw()


func _load_textures() -> void:
	_movie_tex = _load_pic("Dialog_Movie.png")
	_wait_tex = _load_pic("Dialog_Wait.png")
	_cursor_tex = _load_pic("Main_Cursor.png")


func _load_pic(file: String) -> Texture2D:
	var path := "res://assets/graphics/Pictures/" + file
	return load(path) if ResourceLoader.exists(path) else null


func _draw() -> void:
	if _mode == "none":
		return
	# full-screen movie backdrop
	if _movie_tex != null:
		draw_texture_rect(_movie_tex, Rect2(0, 310, 640, 170), false, Color(1, 1, 1, _fade_in))
	else:
		draw_rect(Rect2(MSG_X - 16, MSG_Y - 16, MSG_W + 32, MSG_H + 32), Color(0, 0, 0, 0.75))
	# dialog frame (plain rect)
	var frame_color := Color(0.92, 0.92, 0.92, _fade_in)
	draw_rect(Rect2(MSG_X - 16, MSG_Y - 16, MSG_W + 32, MSG_H + 32), frame_color, false, 2.0)
	draw_rect(Rect2(MSG_X - 14, MSG_Y - 14, MSG_W + 28, MSG_H + 28), Color(0.08, 0.1, 0.14, 0.85))
	# cursor
	if _cursor_tex != null and _choice_visible:
		var cy := MSG_Y - 6 + 18 + _select_start_row * 20 + 10
		draw_texture(_cursor_tex, Vector2(250, cy - _cursor_tex.get_height() / 2),
			Color(1, 1, 1, _fade_in))
	elif _choice_visible:
		var cy := MSG_Y - 6 + 18 + _select_start_row * 20 + 10
		draw_colored_polygon(PackedVector2Array([
			Vector2(246, cy - 5), Vector2(254, cy), Vector2(246, cy + 5)
		]), Color(1, 1, 1, _fade_in))
	# text
	_draw_text()
	# wait indicator
	if _wait_visible and _wait_tex != null:
		draw_texture(_wait_tex, Vector2(380, 440), Color(1, 1, 1, _fade_in))
	# number input
	if _mode == "number":
		var rect := Rect2(200, 300, 240, 110)
		draw_rect(Rect2(rect.position - Vector2(4, 4), rect.size + Vector2(8, 8)), Color(0.9, 0.9, 0.9, _fade_in))
		draw_rect(rect, Color(0.08, 0.1, 0.14, _fade_in))
		var s := str(_number_value).pad_zeros(_digits)
		var char_w := 20.0
		var start_x := rect.position.x + (rect.size.x - char_w * s.length()) * 0.5
		var f := _font()
		for i in range(s.length()):
			draw_string_outline(f, Vector2(start_x + i * char_w, rect.position.y + 58),
				s[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 2, Color(0, 0, 0, 0.8))
			draw_string(f, Vector2(start_x + i * char_w, rect.position.y + 58),
				s[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 1))
		draw_rect(Rect2(start_x + _digit_pos * char_w, rect.position.y + 72, char_w, 3), Color(1, 1, 1, 0.9))


func _draw_text() -> void:
	var f := _font()
	if _choice_visible:
		return
	var start := _glyph_row * ROW_COUNT * CHARS_PER_ROW
	var end := start + ROW_COUNT * CHARS_PER_ROW
	for i in range(start, mini(end, _char_buf.size())):
		var row := (i - start) / CHARS_PER_ROW
		var col := i - start - row * CHARS_PER_ROW
		# find actual position accounting for already-written glyphs
		var text := ""
		if i < _glyph_index:
			text = char(_char_buf[i])
		elif i == _glyph_index and _typing:
			# mid-typing: draw char partially — for simplicity, skip typing anim fully
			pass
		if not text.is_empty():
			var x := TEXT_X + col * TEXT_SIZE
			var y := TEXT_Y0 + row * LINE_H
			draw_string_outline(f, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_SIZE, 2, Color(0, 0, 0, 0.8))
			draw_string(f, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_SIZE, Color(1, 1, 1, 1))


func _font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["PingFang SC", "Heiti SC", "Hiragino Sans GB", "Microsoft YaHei", "sans-serif"])
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return f


# ------------------------------------------------------- parsing
signal finished(result)


func _process(delta: float) -> void:
	if _mode == "none":
		return
	# fade in
	if _fade_in < 1.0:
		_fade_in = minf(_fade_in + delta * 4.0, 1.0)
		queue_redraw()
	if _typing:
		# type ~20 glyphs / sec (speed similar to original)
		_wait_timer += delta
		if _wait_timer >= 0.06:
			_wait_timer = 0.06
			_glyph_index += 1
			if _glyph_index >= _char_buf.size():
				_typing = false
			queue_redraw()
	elif _wait_visible:
		# noop — wait for user input
		pass


# ------------------------------------------------------- public
func show_message(text: String, face_name: String = "", face_index: int = 0) -> void:
	_mode = "message"
	_fade_in = 0.0
	visible = true
	_parse_text(text)
	_glyph_row = 0
	_glyph_index = 0
	_typing = not _char_buf.is_empty()
	_wait_visible = false
	queue_redraw()
	await finished
	_mode = "none"
	visible = false


func show_choices(options: Array) -> int:
	_mode = "choice"
	_fade_in = 0.0
	visible = true
	_choices = options.duplicate()
	_choice_index = 0
	_select_start_row = 0
	_choice_visible = true
	queue_redraw()
	var result: int = await finished
	_mode = "none"
	visible = false
	_choice_visible = false
	return result


func show_number_input(digits: int, max_value: int) -> int:
	_mode = "number"
	_digits = digits
	_number_max = max_value
	_number_value = 0
	_digit_pos = 0
	_fade_in = 0.0
	visible = true
	queue_redraw()
	var result: int = await finished
	_mode = "none"
	visible = false
	queue_redraw()
	return result


func close() -> void:
	_mode = "none"
	visible = false
	queue_redraw()


# ------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if _mode == "none":
		return
	if event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		match _mode:
			"message":
				if _typing:
					_glyph_index = _char_buf.size()
					_typing = false
					queue_redraw()
				else:
					if _glyph_row + ROW_COUNT * CHARS_PER_ROW < _char_buf.size():
						_glyph_row += ROW_COUNT
						_glyph_index = _glyph_row * ROW_COUNT * CHARS_PER_ROW
						_typing = true
						queue_redraw()
					else:
						finished.emit(0)
			"choice":
				Audio.decision()
				finished.emit(_choice_index)
			"number":
				Audio.decision()
				finished.emit(_number_value)
	elif event.is_action_pressed("cancel"):
		if _mode == "choice" or _mode == "number":
			get_viewport().set_input_as_handled()
			Audio.cancel()
			finished.emit(-1)
	elif _mode == "choice":
		if event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			_choice_index = (_choice_index - 1 + _choices.size()) % _choices.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			_choice_index = (_choice_index + 1) % _choices.size()
			Audio.cursor()
			queue_redraw()
	elif _mode == "number":
		var changed := false
		var delta_n := 1
		for _i in range(maxi(_digits - 1 - _digit_pos, 0)):
			delta_n *= 10
		if event.is_action_pressed("move_up"):
			_number_value = clampi(_number_value + delta_n, 0, _number_max)
			changed = true
		elif event.is_action_pressed("move_down"):
			_number_value = clampi(_number_value - delta_n, 0, _number_max)
			changed = true
		elif event.is_action_pressed("move_left"):
			_digit_pos = maxi(_digit_pos - 1, 0)
			changed = true
		elif event.is_action_pressed("move_right"):
			_digit_pos = mini(_digit_pos + 1, _digits - 1)
			changed = true
		if changed:
			get_viewport().set_input_as_handled()
			Audio.cursor()
			queue_redraw()


var _digits := 4
var _digit_pos := 0
var _number_value := 0
var _number_max := 99999999


# ------------------------------------------------------- text parsing
func _parse_text(text: String) -> void:
	var work: String = text.replace("\\n", "\n")
	# variable substitution
	var regex_v := RegEx.new()
	regex_v.compile("\\\\v\\[(\\d+)\\]")
	for m in regex_v.search_all(work):
		var idx := int(m.get_string(1))
		work = work.replace(m.get_string(0), str(State.variable(idx)))
	work = work.replace("\\$", str(State.party.gold))
	# strip RMXP inline codes (color, wait, etc.)
	var regex_c := RegEx.new()
	regex_c.compile("\\\\c\\[\\d+\\]")
	work = regex_c.sub(work, "", true)
	var regex_clean := RegEx.new()
	regex_clean.compile("\\\\[.\\|\\!\\>\\<]")
	work = regex_clean.sub(work, "", true)
	work = work.replace("\\\\", "\\")
	# flatten into a flat char buffer, honoring newlines as row breaks
	_char_buf.clear()
	var lines := work.split("\n")
	for ln in lines:
		for ch in ln:
			_char_buf.append(ord(ch))
