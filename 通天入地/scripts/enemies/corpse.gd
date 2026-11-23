# ============================================================
# Corpse — 尸体残留（亡灵召唤的原材料）
# 敌人死亡后在原地生成，带 corpse_type 决定能召唤什么
# 30 秒后自动腐化消失。
# ============================================================

extends Node2D
class_name Corpse

enum CorpseType { SKELETON, ZOMBIE, ELEMENTAL_FIRE, ELEMENTAL_WATER, MECH, SLIME, GHOST, OGRE }

var corpse_type: int = CorpseType.SKELETON
var corpse_name: String = "骸骨"
var primary_element: String = "earth"
var remaining: float = 30.0
var color: Color = Color(0.85, 0.8, 0.7)
var harvestable: bool = true  # 可以被亡灵召唤/爆破师收集

func setup(type: int, element: String, col: Color) -> void:
	corpse_type = type
	primary_element = element
	color = col
	corpse_name = _type_name(type)

func _type_name(t: int) -> String:
	match t:
		CorpseType.SKELETON: return "骸骨"
		CorpseType.ZOMBIE: return "腐肉"
		CorpseType.ELEMENTAL_FIRE: return "岩浆"
		CorpseType.ELEMENTAL_WATER: return "水液"
		CorpseType.MECH: return "机械残骸"
		CorpseType.SLIME: return "粘液"
		CorpseType.GHOST: return "幽魂残片"
		CorpseType.OGRE: return "巨兽残骸"
	return "未知残骸"

func _process(delta: float) -> void:
	remaining -= delta
	queue_redraw()
	if remaining <= 0.0:
		queue_free()

func _draw() -> void:
	var t := clampf(remaining / 30.0, 0.0, 1.0)
	var alpha := 1.0 if remaining > 10.0 else clampf(remaining / 10.0, 0.0, 1.0)
	# 地面阴影
	draw_ellipse(Vector2(0, 2), 16.0, 6.0, Color(0.0, 0.0, 0.0, 0.28 * alpha))
	# 身体（根据 corpse_type 画不同图形）
	match corpse_type:
		CorpseType.SKELETON:
			# 骨头：白色长方形 + 十字
			draw_rect(Rect2(-12, -8, 24, 10), Color(color.r, color.g, color.b, alpha))
			draw_rect(Rect2(-2, -16, 4, 18), Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, alpha))
			draw_circle(Vector2(0, -18), 5.0, Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, alpha))
		CorpseType.ZOMBIE:
			draw_rect(Rect2(-10, -10, 20, 16), Color(0.35, 0.6, 0.3, alpha))
			draw_circle(Vector2(0, -14), 7.0, Color(0.4, 0.65, 0.35, alpha))
		CorpseType.ELEMENTAL_FIRE:
			# 岩浆：暗红 + 亮芯 + 脉动
			draw_circle(Vector2(0, 0), 14.0, Color(0.6, 0.15, 0.05, alpha * 0.7))
			draw_circle(Vector2(0, -3), 8.0, Color(1.0, 0.55, 0.15, alpha * (0.5 + 0.3 * sin(Time.get_ticks_msec() / 120.0))))
		CorpseType.ELEMENTAL_WATER:
			draw_circle(Vector2(0, 0), 14.0, Color(0.25, 0.55, 0.85, alpha * 0.55))
			draw_circle(Vector2(0, 0), 8.0, Color(0.5, 0.8, 1.0, alpha * 0.6))
		CorpseType.MECH:
			draw_rect(Rect2(-12, -10, 24, 20), Color(0.45, 0.45, 0.5, alpha))
			draw_rect(Rect2(-8, -6, 16, 12), Color(0.7, 0.7, 0.75, alpha))
			draw_circle(Vector2(0, 0), 3.0, Color(1.0, 0.8, 0.3, alpha))
		CorpseType.SLIME:
			draw_circle(Vector2(0, 0), 14.0, Color(0.5, 0.85, 0.55, alpha * 0.6))
			draw_circle(Vector2(0, 2), 10.0, Color(0.75, 1.0, 0.75, alpha * 0.4))
		CorpseType.GHOST:
			# 半透明飘影
			draw_circle(Vector2(0, -2), 12.0, Color(0.5, 0.5, 1.0, alpha * 0.35))
			draw_circle(Vector2(0, -2), 6.0, Color(0.8, 0.8, 1.0, alpha * 0.4))
		CorpseType.OGRE:
			draw_rect(Rect2(-18, -14, 36, 24), Color(0.55, 0.35, 0.25, alpha))
			draw_rect(Rect2(-14, -20, 28, 10), Color(0.5, 0.3, 0.2, alpha))
		_:
			draw_circle(Vector2(0, 0), 12.0, Color(color.r, color.g, color.b, alpha * 0.5))
	# 底部显示腐化倒计时（≤20s 才显示）
	if remaining <= 20.0:
		var bar_w := 24.0 * (remaining / 30.0)
		draw_rect(Rect2(-12, 12, bar_w, 2.5), Color(1.0, 0.4, 0.3, alpha))

func is_valid() -> bool:
	return is_inside_tree() and harvestable
