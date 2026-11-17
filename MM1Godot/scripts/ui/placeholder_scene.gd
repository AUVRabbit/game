class_name PlaceholderScene
extends Control
## Temporary overlay for scenes that have not been ported yet.

var scene_name := ""


func _init(name: String = "") -> void:
	scene_name = name


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var skin := DB.windowskin_texture(str(DB.system.get("windowskin_name", "DefultSkin")))
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.55))
	var rect := Rect2(120, 180, 400, 120)
	UISkin.draw_window(self, rect, skin, 0.94)
	UISkin.draw_text_center(self, Rect2(rect.position, Vector2(rect.size.x, 60)), "场景尚未移植", 20)
	UISkin.draw_text_center(self, Rect2(rect.position + Vector2(0, 60), Vector2(rect.size.x, 40)), scene_name, 16)
	UISkin.draw_text_center(self, Rect2(rect.position + Vector2(0, 92), Vector2(rect.size.x, 24)), "按 Z 返回", 14)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Router.close_overlay()
