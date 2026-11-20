# ============================================================
# EffectRing — 技能/攻击的范围特效（程序化绘制，无需素材）
# ============================================================

extends Node2D
class_name EffectRing

var radius: float = 48.0
var color: Color = Color(1.0, 0.7, 0.2, 0.85)
var duration: float = 0.35
var elapsed: float = 0.0

static func spawn(parent: Node, world_pos: Vector2, radius_value: float, color_value: Color, duration_value: float = 0.35) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var ring := EffectRing.new()
	ring.radius = radius_value
	ring.color = color_value
	ring.duration = duration_value
	parent.add_child(ring)
	ring.global_position = world_pos

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		queue_free()

func _draw() -> void:
	var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
	var r := radius * (0.55 + 0.45 * t)
	var alpha := 1.0 - t
	draw_circle(Vector2.ZERO, r * 0.92, Color(color.r, color.g, color.b, 0.12 * alpha))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(color.r, color.g, color.b, color.a * alpha), 2.5, true)
