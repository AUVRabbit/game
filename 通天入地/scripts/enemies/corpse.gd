# ============================================================
# Corpse — 尸体残留（亡灵召唤的原材料）
# 8 种完全不同的外观 + 腐化倒计时条
# ============================================================

extends Node2D
class_name Corpse

enum CorpseType { SKELETON, ZOMBIE, ELEMENTAL_FIRE, ELEMENTAL_WATER, MECH, SLIME, GHOST, OGRE }

var corpse_type: int = CorpseType.SKELETON
var corpse_name: String = "骸骨"
var primary_element: String = "earth"
var remaining: float = 30.0
var color: Color = Color(0.85, 0.8, 0.7)
var harvestable: bool = true
var sprite: Sprite2D = null
var _use_sprite: bool = false

func _asset_id_for_type() -> String:
	match corpse_type:
		CorpseType.SKELETON:      return "corpse_skeleton"
		CorpseType.ZOMBIE:       return "corpse_zombie"
		CorpseType.ELEMENTAL_FIRE: return "corpse_fire"
		CorpseType.ELEMENTAL_WATER: return "corpse_water"
		CorpseType.MECH:         return "corpse_mech"
		CorpseType.SLIME:        return "corpse_slime"
		CorpseType.GHOST:        return "corpse_ghost"
		CorpseType.OGRE:         return "corpse_ogre"
	return ""

func _ready() -> void:
	var asset_id := _asset_id_for_type()
	if asset_id != "" and AssetLibrary.has(asset_id):
		var tex := AssetLibrary.texture(asset_id)
		if tex != null:
			sprite = Sprite2D.new()
			sprite.name = "CorpseSprite"
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var fit := 40.0 / float(maxi(tex.get_width(), tex.get_height()))
			sprite.scale = Vector2.ONE * fit
			add_child(sprite)
			_use_sprite = true

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
	var alpha := 1.0 if remaining > 10.0 else clampf(remaining / 10.0, 0.0, 1.0)
	var t := Time.get_ticks_msec() / 1000.0
	# 地面阴影（所有类型共用）
	draw_ellipse(Vector2(0, 4), 18.0, 6.0, Color(0.0, 0.0, 0.0, 0.3 * alpha))
	# 有 sprite 贴图时跳过程序化身体绘制
	if _use_sprite:
		if sprite != null:
			sprite.modulate.a = alpha
	else:
		match corpse_type:
			CorpseType.SKELETON: _draw_skeleton(alpha)
			CorpseType.ZOMBIE: _draw_zombie(alpha)
			CorpseType.ELEMENTAL_FIRE: _draw_fire(alpha, t)
			CorpseType.ELEMENTAL_WATER: _draw_water(alpha, t)
			CorpseType.MECH: _draw_mech(alpha)
			CorpseType.SLIME: _draw_slime(alpha, t)
			CorpseType.GHOST: _draw_ghost(alpha, t)
			CorpseType.OGRE: _draw_ogre(alpha)
			_: draw_circle(Vector2.ZERO, 12.0, Color(color.r, color.g, color.b, alpha * 0.5))
	# 腐化倒计时条（≤20s 显示）
	if remaining <= 20.0:
		var bar_w := 28.0 * (remaining / 30.0)
		draw_rect(Rect2(-14, 14, bar_w, 2.5), Color(1.0, 0.4, 0.3, alpha))
		# 红色闪烁（≤5s）
		if remaining <= 5.0 and sin(t * 8.0) > 0:
			draw_rect(Rect2(-14, 14, bar_w, 2.5), Color.WHITE)

# —— 骸骨：头骨 + 散骨 ——
func _draw_skeleton(a: float) -> void:
	var bone := Color(0.86, 0.84, 0.76, a)
	var dark_bone := Color(0.55, 0.52, 0.45, a)
	# 头骨
	draw_circle(Vector2(0, -6), 7.0, bone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2, -8), Vector2(0, -5), Vector2(2, -8)
	]), dark_bone)  # 眼窝（黑）
	draw_circle(Vector2(-2, -8), 1.2, dark_bone)
	draw_circle(Vector2(2, -8), 1.2, dark_bone)
	draw_line(Vector2(-1, -4), Vector2(1, -4), dark_bone, 1.5)  # 嘴
	# 散骨（斜着摆放的肋骨/脊椎）
	draw_line(Vector2(-10, 4), Vector2(-4, 8), bone, 3.0)  # 脊椎
	draw_line(Vector2(2, 2), Vector2(10, 6), bone, 2.0)   # 肋骨
	draw_line(Vector2(-12, 10), Vector2(-4, 12), bone, 2.5)  # 股骨
	draw_line(Vector2(4, 10), Vector2(14, 8), bone, 2.5)  # 另一根

# —— 腐肉：绿色肉块 + 苍蝇 ——
func _draw_zombie(a: float) -> void:
	var flesh := Color(0.45, 0.65, 0.38, a)
	var wound := Color(0.3, 0.2, 0.2, a)
	# 肉块（不规则椭圆）
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, 2), Vector2(-10, -10), Vector2(4, -12),
		Vector2(14, -6), Vector2(12, 6), Vector2(-8, 10)
	]), flesh)
	# 伤口
	draw_line(Vector2(-8, -2), Vector2(4, 2), wound, 3.0)
	draw_line(Vector2(0, 4), Vector2(10, 8), wound, 2.0)
	# 苍蝇（小黑点）
	var t := Time.get_ticks_msec() / 300.0
	for i in range(3):
		var ang := t + float(i) * 2.0
		var rx := cos(ang) * 18
		var ry := sin(ang * 1.3) * 10 - 14
		draw_circle(Vector2(rx, ry), 1.2, Color(0.2, 0.2, 0.2, a))

# —— 岩浆：暗红 + 亮芯 + 裂纹 + 气泡 ——
func _draw_fire(a: float, t: float) -> void:
	var dark_red := Color(0.5, 0.12, 0.04, a)
	var glow_red := Color(1.0, 0.4, 0.1, a)
	var yellow := Color(1.0, 0.85, 0.3, a)
	# 主岩块
	draw_ellipse(Vector2.ZERO, 16.0, 10.0, dark_red)
	# 发光裂缝
	draw_line(Vector2(-12, -4), Vector2(10, 2), glow_red, 2.5)
	draw_line(Vector2(-12, -4), Vector2(-2, 6), glow_red, 1.8)
	draw_line(Vector2(4, -2), Vector2(14, 8), glow_red, 2.0)
	# 亮芯（脉动）
	var pulse := 0.6 + 0.3 * sin(t * 4.0)
	draw_circle(Vector2(-2, -2), 4.0 * pulse, yellow)
	# 气泡
	for i in range(3):
		var ang := t * 0.5 + float(i) * 2.09
		var r := 8 + sin(t + i) * 3
		draw_circle(Vector2(cos(ang) * r, sin(ang) * r - 6),
				1.5, Color(yellow.r, yellow.g, yellow.b, 0.6 * a))

# —— 水液：蓝色积水 + 波纹 ——
func _draw_water(a: float, t: float) -> void:
	var blue := Color(0.3, 0.6, 0.9, a)
	var light := Color(0.6, 0.85, 1.0, a)
	# 积水（椭圆）
	draw_ellipse(Vector2(0, 2), 16.0, 7.0, blue)
	# 高光
	draw_ellipse(Vector2(-4, -2), 8.0, 2.5, light)
	# 波纹（动态同心圆）
	var wave_t := fmod(t * 1.5, 2.0)
	for i in range(2):
		var r := 4 + (wave_t + float(i)) * 8
		if r > 14:
			continue
		var wave_a := (1.0 - (r - 4) / 10.0) * 0.4 * a
		draw_arc(Vector2(0, 2), r, 0, TAU, 20, light, 1.2)

# —— 机械残骸：齿轮 + 弹簧 + 螺丝 ——
func _draw_mech(a: float) -> void:
	var metal := Color(0.55, 0.58, 0.62, a)
	var dark_metal := Color(0.35, 0.38, 0.42, a)
	var copper := Color(0.85, 0.55, 0.25, a)
	# 底板
	draw_rect(Rect2(-14, -2, 28, 10), dark_metal)
	# 齿轮（8 齿）
	var cx := -6
	var cy := -8
	var r := 6.0
	for i in range(8):
		var ang := float(i) / 8.0 * TAU
		var x1 := cx + cos(ang) * r
		var y1 := cy + sin(ang) * r
		var x2 := cx + cos(ang) * (r + 2)
		var y2 := cy + sin(ang) * (r + 2)
		draw_line(Vector2(x1, y1), Vector2(x2, y2), metal, 2.5)
	draw_circle(Vector2(cx, cy), 4.5, metal)
	draw_circle(Vector2(cx, cy), 1.5, dark_metal)
	# 弹簧（右侧卷曲）
	draw_line(Vector2(4, 0), Vector2(8, -6), copper, 2.0)
	draw_line(Vector2(8, -6), Vector2(12, 0), copper, 2.0)
	draw_line(Vector2(12, 0), Vector2(8, 6), copper, 2.0)
	# 螺丝（2 颗）
	draw_circle(Vector2(10, 8), 1.5, dark_metal)
	draw_circle(Vector2(-10, 8), 1.5, dark_metal)
	draw_line(Vector2(9, 8), Vector2(11, 8), Color.BLACK, 1.0)
	draw_line(Vector2(-11, 8), Vector2(-9, 8), Color.BLACK, 1.0)

# —— 粘液：绿色黏液堆 + 滴液 ——
func _draw_slime(a: float, t: float) -> void:
	var slime := Color(0.55, 0.85, 0.55, a * 0.6)
	var dark := Color(0.3, 0.5, 0.35, a)
	# 黏液堆（不规则）
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, 6), Vector2(-10, -4), Vector2(-4, -8),
		Vector2(6, -6), Vector2(12, -2), Vector2(14, 4), Vector2(10, 8)
	]), slime)
	# 高光（更亮更透明）
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -2), Vector2(-2, -6), Vector2(4, -4), Vector2(2, 0)
	]), Color(1.0, 1.0, 0.8, a * 0.4))
	# 滴液（向上飘然后落下）
	for i in range(3):
		var phase := fmod(t * 0.8 + float(i) * 2.09, 1.5)
		var dy := -4 - phase * 12
		draw_circle(Vector2(-6 + float(i) * 5, dy),
				1.8, Color(dark.r, dark.g, dark.b, (1.0 - phase / 1.5) * a))

# —— 幽魂残片：半透明飘动的影团 ——
func _draw_ghost(a: float, t: float) -> void:
	var light := Color(0.6, 0.65, 1.0, a * 0.5)
	var soft := Color(0.35, 0.4, 0.75, a * 0.7)
	# 多个飘动的半透明圆
	for i in range(5):
		var ang := t * 0.3 + float(i) * 1.26
		var r := 8 + float(i) * 1.5
		var px := cos(ang) * r * 0.8
		var py := sin(ang * 1.5) * r - 6
		var sz := 4 + float(i) * 0.8
		draw_circle(Vector2(px, py), sz, soft if i < 3 else light)
	# 中心亮核
	draw_circle(Vector2(0, -4), 3.5 * (0.8 + 0.3 * sin(t * 3.0)), light)

# —— 巨兽残骸：大骨头 + 鳞片 + 角 ——
func _draw_ogre(a: float) -> void:
	var bone := Color(0.75, 0.7, 0.62, a)
	var dark_bone := Color(0.45, 0.4, 0.35, a)
	var scale := Color(0.5, 0.4, 0.35, a)
	# 大颅骨
	draw_circle(Vector2(-6, -8), 10.0, bone)
	draw_circle(Vector2(-6, -8), 7.0, dark_bone)
	# 长牙（2 颗向下）
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -2), Vector2(-9, 4), Vector2(-7, -2)
	]), bone)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -2), Vector2(-3, 5), Vector2(-1, -2)
	]), bone)
	# 大脊骨（水平）
	draw_rect(Rect2(2, -6, 16, 5), bone)
	draw_rect(Rect2(4, -8, 2, 9), dark_bone)  # 骨刺
	draw_rect(Rect2(8, -8, 2, 9), dark_bone)
	draw_rect(Rect2(12, -8, 2, 9), dark_bone)
	# 鳞片堆
	for i in range(4):
		var ang := float(i) / 4.0 * TAU
		var x := cos(ang) * 14 + 6
		var y := sin(ang) * 6 + 4
		draw_arc(Vector2(x, y), 4, PI, TAU, 6, scale, 2.0)
	# 大角
	draw_line(Vector2(-10, -14), Vector2(-16, -22), bone, 4.0)
	draw_line(Vector2(-2, -14), Vector2(4, -22), bone, 4.0)
