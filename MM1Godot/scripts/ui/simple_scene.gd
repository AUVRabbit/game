class_name SimpleScene
extends Control
## Shared keyboard-driven list UI used by the smaller shop / facility scenes.

const RECT := Rect2(40, 32, 560, 416)
const ROW_H := 30.0
const MAX_ROWS := 10

var title := "菜单"
var info := ""
var entries: Array = []
var cursor := 0
var skin: Texture2D
var notice := ""
var _notice_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	skin = DB.windowskin_texture(str(DB.system.get("windowskin_name", "DefultSkin")))
	rebuild()
	set_process(true)


func rebuild() -> void:
	entries = build_entries()
	cursor = clampi(cursor, 0, maxi(entries.size() - 1, 0))
	queue_redraw()


func build_entries() -> Array:
	return []


func on_confirm(_index: int) -> void:
	pass


func on_cancel() -> void:
	Router.close_overlay()


func on_side(_direction: int) -> void:
	pass


func info_text() -> String:
	return info


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			notice = ""
			queue_redraw()


func show_notice(text: String) -> void:
	notice = text
	_notice_time = 1.6
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.55))
	UISkin.draw_window(self, RECT, skin, 0.93)
	UISkin.draw_text(self, Vector2(RECT.position.x + 20, RECT.position.y + 32), title, 20)
	var info_line := info_text()
	if not info_line.is_empty():
		UISkin.draw_text_right(self, Rect2(RECT.position.x, RECT.position.y + 14, RECT.size.x - 20, 24), info_line, 15)
	var start := maxi(0, cursor - MAX_ROWS + 1)
	var y := RECT.position.y + 58
	for i in range(start, mini(start + MAX_ROWS, entries.size())):
		var e: Dictionary = entries[i]
		UISkin.draw_text(self, Vector2(RECT.position.x + 40, y + 20), str(e.get("label", "")), 16)
		var sub := str(e.get("sub", ""))
		if not sub.is_empty():
			UISkin.draw_text_right(self, Rect2(RECT.position.x, y, RECT.size.x - 40, 26), sub, 14)
		if i == cursor:
			UISkin.draw_cursor(self, Rect2(RECT.position.x + 12, y, RECT.size.x - 24, ROW_H), skin)
		y += ROW_H
	if entries.is_empty():
		UISkin.draw_text(self, Vector2(RECT.position.x + 40, y + 20), "什么也没有", 16)
	UISkin.draw_text(self, Vector2(RECT.position.x + 20, RECT.position.y + RECT.size.y - 22),
		"↑↓ 选择   ←→ 切换   Z 确定   X 离开", 13, Color(0.75, 0.75, 0.75))
	if not notice.is_empty():
		var rect := Rect2(160, 388, 320, 42)
		UISkin.draw_window(self, rect, skin, 0.97)
		UISkin.draw_text_center(self, rect, notice, 15)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Audio.cancel()
		on_cancel()
		return
	if event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		on_side(-1)
		queue_redraw()
		return
	if event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		on_side(1)
		queue_redraw()
		return
	if entries.is_empty():
		return
	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		cursor = (cursor - 1 + entries.size()) % entries.size()
		Audio.cursor()
		queue_redraw()
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		cursor = (cursor + 1) % entries.size()
		Audio.cursor()
		queue_redraw()
	elif event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		Audio.decision()
		on_confirm(cursor)
