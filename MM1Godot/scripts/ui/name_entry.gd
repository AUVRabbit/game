class_name NameEntryScene
extends Control
## Scene_NameEntry — rename the leading actor with keyboard input.

const MAX_LEN := 4

var actor: GameActor = null
var text := ""
var skin: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	skin = DB.windowskin_texture(str(DB.system.get("windowskin_name", "DefultSkin")))
	var actors: Array = State.party.member_actors()
	var wanted := int(State.temp.get("name_actor_id", 0))
	for a in actors:
		if a.id == wanted:
			actor = a
	if actor == null and not actors.is_empty():
		actor = actors[0]
	if actor != null:
		text = actor.name
	set_process_unhandled_input(true)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.6))
	var rect := Rect2(80, 140, 480, 200)
	UISkin.draw_window(self, rect, skin, 0.95)
	UISkin.draw_text(self, Vector2(rect.position.x + 24, rect.position.y + 36), "请输入名字", 20)
	var field := Rect2(rect.position.x + 24, rect.position.y + 76, rect.size.x - 48, 52)
	UISkin.draw_window(self, field, skin, 0.98)
	UISkin.draw_text(self, Vector2(field.position.x + 16, field.position.y + 34), text, 22)
	var hint := "Z 确定   X 删除/取消   (%d/%d)" % [text.length(), MAX_LEN]
	UISkin.draw_text_center(self, Rect2(rect.position.x, rect.position.y + rect.size.y - 34, rect.size.x, 28), hint, 14)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		_confirm()
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if text.is_empty():
			Router.close_overlay()
		else:
			text = text.substr(0, text.length() - 1)
			queue_redraw()
		return
	if not (event is InputEventKey) or not event.pressed:
		return
	var key := event as InputEventKey
	var code := key.unicode
	if code >= 32 and code != 127:
		if text.length() < MAX_LEN:
			text += char(code)
			queue_redraw()
		get_viewport().set_input_as_handled()


func _confirm() -> void:
	if text.strip_edges().is_empty():
		Router.close_overlay()
		return
	if actor != null:
		actor.name = text
	Router.close_overlay()
