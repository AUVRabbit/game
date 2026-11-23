# ============================================================
# TargetingReticle — 目标锁定标记
# 敌人/玩家被瞄准/被技能锁定时头顶生成短暂十字光环
# ============================================================

extends Node2D
class_name TargetingReticle

var duration: float = 0.35
var elapsed: float = 0.0
var color: Color = Color(1.0, 0.7, 0.2, 0.9)
var radius: float = 18.0

static func spawn(parent: Node, world_pos: Vector2, color_value: Color = Color(1.0, 0.7, 0.2, 0.9), dur: float = 0.35, r: float = 18.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var tr := TargetingReticle.new()
	tr.color = color_value
	tr.duration = dur
	tr.radius = r
	parent.add_child(tr)
	tr.global_position = world_pos

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		queue_free()

func _draw() -> void:
	var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
	var r := radius * (1.0 + t * 0.4)
	var alpha := 1.0 - t
	var c := Color(color.r, color.g, color.b, color.a * alpha)
	# 外环脉冲
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 16, c, 2.0)
	# 十字准心
	var s := r * 1.2
	draw_line(Vector2(-s, 0), Vector2(-r * 0.45, 0), c, 2.0)
	draw_line(Vector2(r * 0.45, 0), Vector2(s, 0), c, 2.0)
	draw_line(Vector2(0, -s), Vector2(0, -r * 0.45), c, 2.0)
	draw_line(Vector2(0, r * 0.45), Vector2(0, s), c, 2.0)
	# 中心点
	draw_circle(Vector2.ZERO, 2.0, c)
