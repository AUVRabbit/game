extends Control
## MM-style title screen: fades the big header picture, waits for Z.

var black_tex: Texture2D
var ct_tex: Texture2D
var back_tex: Texture2D
var title_tex: Texture2D
var push_tex: Texture2D

var alpha_ct := 0.0
var alpha_title := 0.0
var title_y := 480.0
var alpha_push := 0.0
var push_bob := 0.0
var fade_in := 0.0
var fade_out := 1.0
var stage := "ct_fade_in"   # ct_fade_in / ct_hold / ct_fade_out / wait / title_slide / title_hold / back_fade / done / idle
var _skip := false
var _counter := 0
var _finished := false


func _ready() -> void:
	black_tex = _load_pic("Game_Header_Black_Back.PNG")
	ct_tex = _load_pic("Game_Header_CT.png")
	back_tex = _load_pic("Game_Header_Back.PNG")
	title_tex = _load_pic("Game_Header_Title.png")
	push_tex = _load_pic("Game_Header_Push.png")
	Audio.play_bgm(str(DB.system.get("title_bgm", {}).get("name", "")), 100)


func _load_pic(file: String) -> Texture2D:
	var path := "res://assets/graphics/Pictures/" + file
	return load(path) if ResourceLoader.exists(path) else null


func _process(delta: float) -> void:
	push_bob += delta
	match stage:
		"ct_fade_in":
			alpha_ct = minf(alpha_ct + delta * 2.55, 1.0)  # ~30 frames
			if alpha_ct >= 1.0:
				stage = "ct_hold"
				_counter = 0
		"ct_hold":
			_counter += delta
			if _counter >= 0.5:   # ~30 frames
				stage = "ct_fade_out"
				_counter = 0
		"ct_fade_out":
			alpha_ct = maxf(alpha_ct - delta * 2.55, 0.0)
			if alpha_ct <= 0.0:
				stage = "wait"
				_counter = 0
		"wait":
			_counter += delta
			if _counter >= 2.67:  # ~80 frames
				stage = "title_slide"
				_counter = 0
		"title_slide":
			alpha_title = minf(alpha_title + delta * 1.275, 1.0)  # fade in 60 frames
			title_y -= delta * 60.0   # move up ~180 px over 3 seconds
			if alpha_title >= 1.0 and title_y <= 120.0:
				title_y = 120.0
				stage = "title_hold"
				_counter = 0
		"title_hold":
			_counter += delta
			if _counter >= 0.67:
				stage = "back_fade"
				_counter = 0
		"back_fade":
			fade_out = maxf(fade_out - delta * 1.7, 0.0)
			alpha_push = minf(alpha_push + delta * 2.55, 1.0)
			if fade_out <= 0.0 and alpha_push >= 1.0:
				stage = "idle"
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color.BLACK)
	if back_tex != null:
		draw_texture_rect(back_tex, Rect2(0, 0, 640, 480), false)
	if black_tex != null and (stage == "ct_fade_out" or stage == "wait"):
		draw_texture_rect(black_tex, Rect2(0, 0, 640, 480), false)
	if ct_tex != null and stage in ["ct_fade_in", "ct_hold", "ct_fade_out"]:
		draw_texture_rect(ct_tex, Rect2(0, 0, 640, 480), false, Color(1, 1, 1, alpha_ct))
	if title_tex != null and stage in ["title_slide", "title_hold", "back_fade", "idle"]:
		draw_texture_rect(title_tex, Rect2(72, title_y, 480, 80), false, Color(1, 1, 1, alpha_title))
	if push_tex != null and stage in ["back_fade", "idle"]:
		var bob := fmod(push_bob * 3.0, 1.0)
		var a := alpha_push * (0.65 + 0.35 * sin(push_bob * 3.0))
		draw_texture_rect(push_tex, Rect2(155, 320 + bob * 2, 322, 120), false, Color(1, 1, 1, a))
	draw_text("Z 开始", Vector2(16, 462), 14, Color(0.85, 0.85, 0.85))


func draw_text(t: String, p: Vector2, size: int, c: Color) -> void:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["PingFang SC", "Heiti SC", "sans-serif"])
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	draw_string_outline(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(0, 0, 0, 0.7))
	draw_string(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		# skip intro if still animating
		if stage != "idle":
			if stage == "ct_fade_in" or stage == "ct_hold" or stage == "ct_fade_out":
				alpha_ct = 1.0
				stage = "wait"
				_counter = 0
			elif stage == "wait":
				stage = "title_slide"
			elif stage == "title_slide":
				alpha_title = 1.0
				title_y = 120.0
				stage = "back_fade"
			elif stage == "title_hold":
				stage = "back_fade"
			return
		Audio.decision()
		_start_new_or_load()


func _start_new_or_load() -> void:
	if Saver.latest_slot() > 0:
		Router.load_saved_game(Saver.latest_slot())
	else:
		Router.new_game()
