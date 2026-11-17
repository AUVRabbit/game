class_name UIWindow
extends Control
## Base class for a window drawn with the original RMXP windowskin.

var skin_name: String = "DefultSkin"
var skin: Texture2D = null
var window_alpha: float = 0.86
var draw_frame: bool = true


func _ready() -> void:
	skin = DB.windowskin_texture(skin_name)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)


func setup(pos: Vector2, sz: Vector2) -> void:
	position = pos
	size = sz
	queue_redraw()


func _draw() -> void:
	if draw_frame:
		UISkin.draw_window(self, Rect2(Vector2.ZERO, size), skin, window_alpha)


func line_height(text_size: int = 20) -> float:
	return float(text_size) + 8.0


func draw_label(pos: Vector2, text: String, text_size: int = 20,
		color: Color = Color(1, 1, 1)) -> void:
	UISkin.draw_text(self, pos + Vector2(0, text_size * 0.9), text, text_size, color)


func draw_label_center(rect: Rect2, text: String, text_size: int = 20,
		color: Color = Color(1, 1, 1)) -> void:
	UISkin.draw_text_center(self, rect, text, text_size, color)


func draw_label_right(rect: Rect2, text: String, text_size: int = 20,
		color: Color = Color(1, 1, 1)) -> void:
	UISkin.draw_text_right(self, rect, text, text_size, color)
