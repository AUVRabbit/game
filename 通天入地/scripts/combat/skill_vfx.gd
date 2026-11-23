# ============================================================
# SkillVfx — 技能视觉表现（程序化绘制 + 真实素材贴图）
# ============================================================

extends RefCounted
class_name SkillVfx

# ------- 通用：加载 vfx_xxx 贴图并播放 scale+fade -------
static func spawn(level: Node, pos: Vector2, kind: String, color: Color = Color.WHITE, scale_mult: float = 1.0, angle: float = 0.0) -> Node:
	if level == null or kind == "":
		return null
	var tex: Texture2D = AssetLibrary.texture("vfx_%s" % kind)
	if tex == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = pos
	sprite.rotation = angle
	sprite.z_index = 40
	sprite.modulate = color
	sprite.scale = Vector2.ONE * (0.35 * scale_mult)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	level.add_child(sprite)
	var target := Vector2.ONE * (1.0 * scale_mult)
	var tween := sprite.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", target, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.42).set_delay(0.1)
	tween.chain().tween_callback(sprite.queue_free)
	return sprite

# ------- 按技能类型自动匹配特效 -------
static func spawn_skill(level: Node, skill: Dictionary, origin: Vector2, dir: Vector2) -> void:
	if level == null or skill.is_empty():
		return
	var kind := str(skill.get("vfx", ""))
	var color := Color.from_string(str(skill.get("color", "#ffffff")), Color.WHITE)
	var type_name := str(skill.get("type", ""))
	var angle := dir.angle() if dir.length() > 0.01 else 0.0
	match type_name:
		"melee_aoe":
			# 剑气弧：弧形半透明 Line2D + 挥砍方向提示
			spawn_sword_arc(level, origin + dir.normalized() * 40.0, dir, color, float(skill.get("radius", 80)))
		"projectile":
			# 发射瞬间：枪口闪光
			spawn_muzzle_flash(level, origin + dir.normalized() * 14.0, color, angle)
		"heal", "buff", "shield":
			spawn(level, origin, kind if kind != "" else "explosion", color, 0.6)
		"aoe_zone":
			# 预警标记已在 SkillExecutor 里通过 EffectRing 画了
			pass
		"chain":
			# 链式闪电在 _chain 内部调用 spawn_chain_lightning
			pass
		"dash_strike":
			spawn(level, origin, kind if kind != "" else "dash_streak", color, 0.9, angle)
		"deployable":
			pass
		"summon":
			pass
		_:
			if kind != "":
				spawn(level, origin, kind, color, 0.8)

static func spawn_impact(level: Node, pos: Vector2, kind: String, color: Color = Color.WHITE) -> void:
	spawn(level, pos, kind if kind != "" else "explosion", color, 0.9)


# ============================================================
# 以下是自定义程序化特效（无需素材，_draw 驱动）
# ============================================================

# ------- 1. 剑气弧：挥砍弧线（弧形 Line2D + 白色内芯 + 渐隐） -------
static func spawn_sword_arc(level: Node, center: Vector2, dir: Vector2, color: Color, radius: float = 80.0) -> void:
	if level == null:
		return
	var arc := _SwordArcVisual.new()
	arc.color = color
	arc.radius = radius
	arc.direction = dir.normalized()
	arc.duration = 0.28
	level.add_child(arc)
	arc.global_position = center

# ------- 2. 枪口闪光：小爆炸 + 白色外发光 -------
static func spawn_muzzle_flash(level: Node, pos: Vector2, color: Color, angle: float = 0.0) -> void:
	if level == null:
		return
	var fx := _MuzzleFlashVisual.new()
	fx.color = color
	fx.angle = angle
	fx.duration = 0.18
	level.add_child(fx)
	fx.global_position = pos

# ------- 3. 链式闪电：在多个节点之间画锯齿形闪电 -------
static func spawn_chain_lightning(level: Node, points: PackedVector2Array, color: Color) -> void:
	if level == null or points.size() < 2:
		return
	var flash := _ChainLightningVisual.new()
	flash.color = color
	flash.points = points
	flash.duration = 0.18
	level.add_child(flash)

# ------- 4. 冲击波：环形向外扩散 + 缩放 -------
static func spawn_shockwave(level: Node, pos: Vector2, radius: float, color: Color, duration: float = 0.35) -> void:
	if level == null:
		return
	var wave := _ShockwaveVisual.new()
	wave.color = color
	wave.max_radius = radius
	wave.duration = duration
	level.add_child(wave)
	wave.global_position = pos

# ------- 5. 地刺：从地面刺出尖刺 -------
static func spawn_ground_spikes(level: Node, pos: Vector2, radius: float, count: int, color: Color, duration: float = 0.35) -> void:
	if level == null:
		return
	var spikes := _SpikeClusterVisual.new()
	spikes.color = color
	spikes.radius = radius
	spikes.count = count
	spikes.duration = duration
	level.add_child(spikes)
	spikes.global_position = pos

# ------- 6. 落雷：从天而降的闪电光束 -------
static func spawn_lightning_bolt(level: Node, pos: Vector2, length: float, color: Color, duration: float = 0.22) -> void:
	if level == null:
		return
	var bolt := _LightningBoltVisual.new()
	bolt.color = color
	bolt.length = length
	bolt.duration = duration
	level.add_child(bolt)
	bolt.global_position = pos

# ------- 7. 爆炸动画：多层环形 + 碎片 -------
static func spawn_burst(level: Node, pos: Vector2, radius: float, color: Color, duration: float = 0.4) -> void:
	if level == null:
		return
	var burst := _BurstVisual.new()
	burst.color = color
	burst.radius = radius
	burst.duration = duration
	level.add_child(burst)
	burst.global_position = pos


# ============================================================
# 以下是内部 Visual Node2D 类（程序化绘制）
# 它们是私有辅助类，不暴露 class_name
# ============================================================

class _SwordArcVisual extends Node2D:
	var color: Color = Color.WHITE
	var direction: Vector2 = Vector2.RIGHT
	var radius: float = 80.0
	var duration: float = 0.3
	var elapsed: float = 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		# 挥砍：弧从 -80°~+80° 围绕 direction
		var base_angle := direction.angle()
		var half_span := PI * 0.45
		var inner_r := radius * 0.45
		var outer_r := radius
		var alpha := (1.0 - t) * 0.95
		# 外层宽弧（柔化）
		draw_arc(Vector2.ZERO, outer_r, base_angle - half_span, base_angle + half_span, 28,
			Color(color.r, color.g, color.b, alpha * 0.35), 8.0)
		# 核心窄弧（亮）
		draw_arc(Vector2.ZERO, (inner_r + outer_r) * 0.5, base_angle - half_span, base_angle + half_span, 24,
			Color(color.r, color.g, color.b, alpha), 3.0)
		# 白色高光
		draw_arc(Vector2.ZERO, (inner_r + outer_r) * 0.5, base_angle - half_span * 0.75, base_angle + half_span * 0.75, 18,
			Color(1.0, 1.0, 1.0, alpha * 0.9), 1.2)
		# 末端剑气小爆点
		var tip := direction * outer_r
		draw_circle(tip, 5.0, Color(color.r, color.g, color.b, alpha * 0.6))
		draw_circle(tip, 2.0, Color(1.0, 1.0, 1.0, alpha))


class _MuzzleFlashVisual extends Node2D:
	var color: Color = Color.WHITE
	var angle: float = 0.0
	var duration: float = 0.2
	var elapsed: float = 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		var r := 18.0 * (0.6 + 0.4 * sin(t * PI))
		var alpha := 1.0 - t
		var offset := Vector2(14.0 * cos(angle), 14.0 * sin(angle))
		draw_circle(offset, r * 1.5, Color(color.r, color.g, color.b, alpha * 0.2))
		draw_circle(offset, r, Color(color.r, color.g, color.b, alpha * 0.6))
		draw_circle(offset, r * 0.45, Color(1.0, 1.0, 1.0, alpha * 0.95))


class _ChainLightningVisual extends Node2D:
	var color: Color = Color(0.5, 0.8, 1.0)
	var points: PackedVector2Array = PackedVector2Array()
	var duration: float = 0.2
	var elapsed: float = 0.0
	var _zigzag: PackedVector2Array = PackedVector2Array()

	func _ready() -> void:
		# 预生成锯齿形
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var seg := b - a
			var len := seg.length()
			var count := maxi(2, int(len / 18.0))
			var perp := Vector2(-seg.y, seg.x).normalized()
			for k in count - 1:
				var tt := float(k + 1) / float(count)
				var mid := a + seg * tt + perp * (randf_range(-6.0, 6.0))
				_zigzag.append(mid)
		# 先清空 points（被当作绝对坐标了），改成局部相对
		var absolute := PackedVector2Array(points)
		points.clear()
		points.append(Vector2.ZERO)
		for p in absolute.slice(1):
			points.append(p - global_position)
		var abs_zig := PackedVector2Array(_zigzag)
		_zigzag.clear()
		for z in abs_zig:
			_zigzag.append(z - global_position)

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var alpha := 1.0 - clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		# 外发光
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			draw_line(a, b, Color(color.r, color.g, color.b, alpha * 0.4), 6.0)
		# 内亮
		var path := PackedVector2Array()
		path.append(points[0])
		for z in _zigzag:
			path.append(z)
		path.append(points[points.size() - 1])
		for i in path.size() - 1:
			draw_line(path[i], path[i + 1], Color(1.0, 1.0, 1.0, alpha), 2.0)


class _ShockwaveVisual extends Node2D:
	var color: Color = Color.WHITE
	var max_radius: float = 120.0
	var duration: float = 0.35
	var elapsed: float = 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		var r := max_radius * (0.15 + 0.85 * t)
		var alpha := 1.0 - t
		# 外层柔化
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(color.r, color.g, color.b, alpha * 0.25), 12.0)
		# 中层亮环
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(color.r, color.g, color.b, alpha * 0.8), 3.0)
		# 内层白芯
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, alpha * 0.9), 1.0)


class _SpikeClusterVisual extends Node2D:
	var color: Color = Color(0.4, 0.9, 0.5)
	var radius: float = 100.0
	var count: int = 8
	var duration: float = 0.4
	var elapsed: float = 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		var alpha := 1.0 - t
		# 尖刺从地面刺出：先出现底座，然后向上长出，最后消失
		for i in count:
			var ang := TAU * float(i) / float(count)
			var base := Vector2(cos(ang), sin(ang)) * radius * (0.3 + 0.5 * (i % 2))
			var spike_h := 22.0 * sin(t * PI)   # 刺出高度（sin 曲线：0→max→0）
			var tip := base + Vector2(cos(ang), sin(ang)) * spike_h * 0.5 + Vector2(0, -spike_h)
			# 底座（半圆）
			draw_circle(base, 6.0, Color(color.r * 0.4, color.g * 0.6, color.b * 0.3, alpha))
			# 尖刺三角形
			var p2 := base + Vector2(0, -4.0)
			var p3 := tip
			draw_colored_polygon(PackedVector2Array([base, p2, p3]), Color(color.r, color.g, color.b, alpha))
			# 白色高光
			draw_line(p2, tip, Color(1.0, 1.0, 1.0, alpha * 0.6), 1.0)


class _LightningBoltVisual extends Node2D:
	var color: Color = Color(0.6, 0.9, 1.0)
	var length: float = 260.0
	var duration: float = 0.25
	var elapsed: float = 0.0
	var _segments := PackedVector2Array()

	func _ready() -> void:
		# 从上方 length 位置画到原点（落雷从天而降）
		var count := 10
		_segments.clear()
		for i in count + 1:
			var y := -length * float(i) / float(count)
			var x_off: float = randf_range(-14.0, 14.0) * (1.0 - abs(float(i) / float(count) - 0.5) * 0.8)
			_segments.append(Vector2(x_off, y))

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var alpha := 1.0 - clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		# 外发光（蓝色柔化）
		for i in _segments.size() - 1:
			draw_line(_segments[i], _segments[i + 1], Color(0.3, 0.6, 1.0, alpha * 0.4), 12.0)
		# 彩色中芯
		for i in _segments.size() - 1:
			draw_line(_segments[i], _segments[i + 1], Color(color.r, color.g, color.b, alpha * 0.9), 4.0)
		# 白色亮芯
		for i in _segments.size() - 1:
			draw_line(_segments[i], _segments[i + 1], Color(1.0, 1.0, 1.0, alpha), 1.5)
		# 落地点爆点
		draw_circle(Vector2.ZERO, 14.0, Color(color.r, color.g, color.b, alpha * 0.3))
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 1.0, 1.0, alpha * 0.9))


class _BurstVisual extends Node2D:
	var color: Color = Color.WHITE
	var radius: float = 80.0
	var duration: float = 0.4
	var elapsed: float = 0.0
	var _shards := PackedVector2Array()

	func _ready() -> void:
		for i in 12:
			_shards.append(Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)))

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= duration:
			queue_free()

	func _draw() -> void:
		var t := clampf(elapsed / maxf(duration, 0.001), 0.0, 1.0)
		var alpha := 1.0 - t
		# 内圈脉冲
		var r0 := radius * (0.3 + 0.7 * t)
		draw_circle(Vector2.ZERO, r0, Color(color.r, color.g, color.b, alpha * 0.25))
		draw_circle(Vector2.ZERO, r0 * 0.5, Color(color.r, color.g, color.b, alpha * 0.6))
		draw_circle(Vector2.ZERO, r0 * 0.2, Color(1.0, 1.0, 1.0, alpha * 0.9))
		# 碎片向外飞
		for s in _shards:
			var dist := radius * (0.2 + 0.9 * t)
			var pos := s.normalized() * dist
			draw_circle(pos, 3.0 * (1.0 - t * 0.5), Color(color.r, color.g, color.b, alpha))
