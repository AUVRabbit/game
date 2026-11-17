class_name GameoverScene
extends Control
## Scene_Gameover — black screen with GAME OVER, any confirm returns to the title.

signal closed


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 1))
	UISkin.draw_text_center(self, Rect2(0, 180, 640, 60), "GAME OVER", 40, Color(0.85, 0.2, 0.2))
	UISkin.draw_text_center(self, Rect2(0, 280, 640, 30), "按 Z 返回标题画面", 16, Color(0.7, 0.7, 0.7))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
