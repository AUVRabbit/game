# ============================================================
# Projectile — 技能弹道（不同武器/元素 → 不同外观）
#
# 关键属性：
#   projectile_kind  → fireball / icicle / arrow / spear / bullet / rock / lightning / holy / dark / axe / shuriken
#   damage_element   → fire / ice / thunder / physical / holy / shadow / nature / water / mech / earth
# ============================================================

extends Area2D
class_name Projectile

enum Kind { FIREBALL, ICICLE, ARROW, SPEAR, BULLET, ROCK, LIGHTNING, HOLY, DARK, AXE, SHURIKEN, NEEDLE, LASER_BOLT }

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var damage: int = 10
var is_magic: bool = false
var lifetime: float = 1.6
var source: Node = null
var color: Color = Color(0.5, 0.8, 1.0)
var elapsed: float = 0.0
var icon_id: String = ""
var sprite: Sprite2D = null
var pierce: int = 0
var splash_radius: float = 0.0
var is_crit: bool = false
var knockback: float = 0.0
var hit_bodies: Array = []
var arc_amplitude: float = 0.0   # 抛物线摆动幅度（lob 类抛掷物，如炸弹/石头）
var arc_frequency: float = 2.0
var fusion_kw: Dictionary = {}
var fusion_color: Color = Color.WHITE
var projectile_kind: int = Kind.FIREBALL
var damage_element: String = "physical"

var _spawn_y: float = 0.0
var _trail_points: Array = []
var _trail_line: Line2D = null
var _trail_timer: float = 0.0
const TRAIL_MAX := 16

# —— 拖尾颜色配置（按 kind 分）——
func _kind_trail_color() -> Color:
	match projectile_kind:
		Kind.FIREBALL:   return Color(1.0, 0.45, 0.1, 0.85)
		Kind.ICICLE:     return Color(0.45, 0.85, 1.0, 0.7)
		Kind.ARROW:      return Color(0.9, 0.85, 0.7, 0.55)  # 空气流
		Kind.SPEAR:      return Color(0.85, 0.8, 0.7, 0.5)
		Kind.BULLET:     return Color(1.0, 0.85, 0.4, 0.7)
		Kind.ROCK:       return Color(0.45, 0.42, 0.38, 0.4)  # 灰色烟雾
		Kind.LIGHTNING:  return Color(0.75, 0.95, 1.0, 0.9)
		Kind.HOLY:       return Color(1.0, 0.92, 0.55, 0.8)
		Kind.DARK:       return Color(0.45, 0.25, 0.65, 0.75)
		Kind.AXE:        return Color(0.85, 0.8, 0.75, 0.6)
		Kind.SHURIKEN:   return Color(0.7, 0.72, 0.75, 0.6)
		Kind.NEEDLE:     return Color(0.85, 0.85, 0.9, 0.55)
		Kind.LASER_BOLT: return Color(0.35, 1.0, 0.7, 0.8)
		_:               return Color(color.r, color.g, color.b, 0.7)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)
	_spawn_sprite()
	_spawn_trail()
	if arc_amplitude > 0.0:
		_spawn_y = global_position.y
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _spawn_sprite() -> void:
	var tex: Texture2D = null
	if icon_id != "":
		tex = AssetLibrary.texture(icon_id)
	if tex != null:
		sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.modulate = color
		sprite.scale = Vector2.ONE * 0.14
		sprite.rotation = direction.angle()
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = mat
		add_child(sprite)

func _spawn_trail() -> void:
	_trail_line = Line2D.new()
	_trail_line.width = 8.0
	_trail_line.default_color = _kind_trail_color()
	_trail_line.z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_trail_line.material = mat
	add_child(_trail_line)

func _physics_process(delta: float) -> void:
	if arc_amplitude > 0.0:
		var t_norm := elapsed / maxf(lifetime, 0.001)
		global_position += direction * speed * delta
		global_position.y = _spawn_y - direction.y * speed * elapsed + sin(t_norm * PI) * arc_amplitude * sin(elapsed * arc_frequency)
	else:
		global_position += direction * speed * delta
	# 旋转朝向（物理抛掷物也转）
	rotation = direction.angle()
	elapsed += delta

	# 拖尾采样
	_trail_timer += delta
	var sample_dt := 0.016
	if projectile_kind == Kind.LIGHTNING or projectile_kind == Kind.HOLY:
		sample_dt = 0.014  # 魔法拖尾更密
	_trail_timer += delta
	if _trail_timer > sample_dt:
		_trail_points.insert(0, Vector2.ZERO)
		if _trail_points.size() > TRAIL_MAX:
			_trail_points.pop_back()
		_trail_line.points = PackedVector2Array(_trail_points)
		_trail_line.width = 8.0 * (1.0 - 0.03 * _trail_points.size())
		_trail_timer = 0.0

	if elapsed >= lifetime:
		_expire()

func _expire() -> void:
	if sprite:
		var tw := sprite.create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == source or hit_bodies.has(body):
		return
	if not body.has_method("take_damage"):
		return
	hit_bodies.append(body)
	var dealt: int = body.take_damage(damage, is_magic, source)
	var level := get_parent()
	if level:
		DamageNumber.spawn(level, body.global_position + Vector2(0, -24), dealt, is_crit)
		SkillVfx.spawn_impact(level, body.global_position, "explosion", color)
		EffectRing.spawn(level, body.global_position, 26.0, color, 0.22)
		if not fusion_kw.is_empty():
			var radius := splash_radius if splash_radius > 0.0 else 110.0
			SkillExecutor._apply_element(source, fusion_kw, fusion_color, body.global_position, radius, damage, is_magic, level)
	if ScreenShake and ScreenShake.has_method("shake"):
		var intensity := 1.8 if splash_radius > 0.0 else 1.2
		ScreenShake.shake(intensity, 0.06, 90.0)
	if knockback > 0.0 and body is Node2D:
		(body as Node2D).global_position += direction.normalized() * knockback
	if splash_radius > 0.0:
		_splash(level, body)
		EffectRing.spawn(level, global_position, splash_radius, color, 0.38)
		if ScreenShake and ScreenShake.has_method("shake"):
			ScreenShake.shake(3.5, 0.14, 55.0)
	if pierce > 0:
		pierce -= 1
	else:
		queue_free()

func _splash(level: Node, primary: Node) -> void:
	if level == null:
		return
	for e in level.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e == primary or not (e is Node2D):
			continue
		if (e as Node2D).global_position.distance_to(global_position) > splash_radius:
			continue
		var dealt: int = e.take_damage(int(round(damage * 0.6)), is_magic, source)
		DamageNumber.spawn(level, e.global_position + Vector2(0, -24), dealt, is_crit)


# ============================================================
# _draw — 按 projectile_kind 画不同外观（纯代码程序化绘制）
# ============================================================
func _draw() -> void:
	# 有素材直接用
	if sprite and sprite.texture != null:
		return
	# 按 kind 画专属图形
	var tip := direction.normalized()
	var perp := Vector2(-tip.y, tip.x)
	var t_msf := Time.get_ticks_msec() / 1000.0
	match projectile_kind:
		# —— 🔥 火球 —— 中心亮白 → 橙红渐变球 + 火花 + 尾焰 ——
		Kind.FIREBALL:
			var r := 10.0
			# 外圈热浪（脉动）
			var pulse := 1.0 + 0.15 * sin(t_msf * 18.0)
			draw_circle(Vector2.ZERO, r * pulse + 6.0, Color(1.0, 0.3, 0.0, 0.15))
			draw_circle(Vector2.ZERO, r * pulse + 3.0, Color(1.0, 0.5, 0.1, 0.25))
			# 主火球（径向渐变）
			draw_circle(Vector2.ZERO, r * pulse, Color(1.0, 0.55, 0.15, 0.95))
			draw_circle(Vector2.ZERO, r * pulse * 0.65, Color(1.0, 0.8, 0.35, 0.95))
			draw_circle(Vector2.ZERO, r * pulse * 0.35, Color(1.0, 1.0, 0.9, 0.95))
			# 表面火花（3 颗小白点 + 闪烁）
			for i in range(3):
				var sp := sin(t_msf * 30.0 + float(i) * 2.1) * (r + 2.0)
				var spark_pos := tip * sp * 0.3 + perp * sin(t_msf * 22.0 + i) * 2.0
				draw_circle(spark_pos, 1.6, Color(1.0, 1.0, 0.8, 0.9))

		# —— ❄️ 冰锥 —— 三角尖刺（前尖后粗）——
		Kind.ICICLE:
			var L := 22.0
			var w := 8.0
			var tip_pt := tip * L
			var base_l := -tip * 6.0
			var p1 := base_l + perp * w
			var p2 := base_l - perp * w
			var inner_color := Color(0.85, 0.95, 1.0, 0.95)
			var outer_color := Color(0.55, 0.8, 1.0, 0.95)
			draw_colored_polygon(PackedVector2Array([tip_pt, p1, p2]), outer_color)
			# 内部高光（更小三角）
			var tip_i := tip * (L * 0.75)
			var p1i := base_l + perp * (w * 0.55)
			var p2i := base_l - perp * (w * 0.55)
			draw_colored_polygon(PackedVector2Array([tip_i, p1i, p2i]), inner_color)
			# 边缘白线
			draw_line(tip_pt, p1, Color(1.0, 1.0, 1.0, 0.7), 1.2)
			draw_line(tip_pt, p2, Color(1.0, 1.0, 1.0, 0.7), 1.2)
			draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.5), 1.2)
			# 外层寒气光环
			draw_circle(Vector2.ZERO, 14.0, Color(0.7, 0.9, 1.0, 0.18))

		# —— 🏹 箭矢 —— 细长杆 + 箭头三角 + 尾羽 ——
		Kind.ARROW:
			var L := 24.0
			var tail := -tip * (L * 0.7)   # 杆尾
			var shaft_start := -tip * (L * 0.4)
			var arrow_head := tip * (L * 0.6)
			# 箭杆（深棕色细长）
			draw_line(arrow_head - tip * 4.0, tail, Color(0.55, 0.35, 0.2, 0.9), 2.0)
			# 箭头（金属灰三角）
			var htip := arrow_head + tip * 4.0
			var hbase := arrow_head - tip * 4.0
			var htip1 := hbase + perp * 2.5
			var htip2 := hbase - perp * 2.5
			draw_colored_polygon(PackedVector2Array([htip, htip1, htip2]), Color(0.78, 0.78, 0.82, 0.95))
			draw_line(htip, htip1, Color(0.95, 0.95, 1.0, 0.7), 0.8)
			# 尾羽（3 片扇形）
			var feather_color := Color(0.9, 0.7, 0.45, 0.85)
			var fwd := -tip
			for a in [-0.3, 0.0, 0.3]:
				var fe := tail + Vector2(cos(a), sin(a)) * 5.0 * fwd.length()
				var fe_side := perp * 3.0 * sin(a * 3.0)
				draw_line(tail + fe_side, tail + fe + tip * 4.0, feather_color, 1.4)

		# —— 🔱 长矛 —— 更长 + 更尖 + 木杆 ——
		Kind.SPEAR:
			var L := 30.0
			var tail_p := -tip * L
			var head_base := tip * (L * 0.65)
			var head_tip := tip * (L * 0.65 + 7.0)
			# 木杆
			draw_line(head_base - tip * 12.0, tail_p, Color(0.55, 0.38, 0.2, 0.9), 2.5)
			# 金属尖（长条三角）
			var hp1 := head_base + perp * 3.5
			var hp2 := head_base - perp * 3.5
			draw_colored_polygon(PackedVector2Array([head_tip, hp1, hp2]), Color(0.82, 0.82, 0.88, 0.95))
			draw_line(head_tip, hp1, Color(0.95, 0.95, 1.0, 0.8), 0.8)
			draw_line(head_tip, hp2, Color(0.95, 0.95, 1.0, 0.8), 0.8)
			# 金属环（头和杆交界处）
			draw_circle(head_base - tip * 1.0, 2.5, Color(0.9, 0.85, 0.5, 0.85))

		# —— 🔫 子弹 —— 黄铜圆球 + 白芯 ——
		Kind.BULLET:
			var r := 4.0
			draw_circle(Vector2.ZERO, r + 3.0, Color(1.0, 0.8, 0.3, 0.25))
			draw_circle(Vector2.ZERO, r + 1.0, Color(1.0, 0.75, 0.3, 0.45))
			draw_circle(Vector2.ZERO, r, Color(0.9, 0.7, 0.3, 0.95))
			draw_circle(Vector2.ZERO, r * 0.45, Color(1.0, 1.0, 0.85, 0.95))

		# —— 🪨 岩石（抛物线）—— 不规则多边形 ——
		Kind.ROCK:
			var pts: PackedVector2Array = PackedVector2Array()
			var seed_val := hash("rock_" + str(int(_spawn_y)))
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_val & 0x7FFFFFFF
			for i in range(7):
				var ang := TAU * float(i) / 7.0
				var rr := 8.0 + rng.randf_range(-1.5, 1.5)
				pts.append(Vector2(cos(ang), sin(ang)) * rr)
			draw_colored_polygon(pts, Color(0.5, 0.45, 0.4, 0.95))
			# 高光
			draw_circle(Vector2(-1.5, -1.5), 2.0, Color(0.7, 0.65, 0.6, 0.7))

		# —— ⚡ 雷电球 —— 锯齿椭圆 + 闪烁白芯 ——
		Kind.LIGHTNING:
			var r := 8.0
			var flash := (sin(t_msf * 60.0) * 0.5 + 0.5)
			draw_circle(Vector2.ZERO, r + 5.0, Color(0.5, 0.8, 1.0, 0.25 + flash * 0.2))
			draw_circle(Vector2.ZERO, r + 2.0, Color(0.7, 0.9, 1.0, 0.45))
			draw_circle(Vector2.ZERO, r, Color(0.85, 0.95, 1.0, 0.75))
			# 闪电分支（3 条锯齿线）
			for b in range(3):
				var bang := tip.angle() + sin(t_msf * 10.0 + float(b)) * 0.8
				var p := Vector2(0, 0)
				for seg in range(4):
					p += Vector2(cos(bang), sin(bang)) * 3.0
					bang += sin(t_msf * 15.0 + float(seg) * 2.0 + float(b)) * 0.8
					draw_circle(p, 1.2, Color(0.9, 0.98, 1.0, flash * 0.8 + 0.3))

		# —— ✨ 圣光弹 —— 金色五角星 + 光晕 ——
		Kind.HOLY:
			draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.9, 0.4, 0.25))
			draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.95, 0.6, 0.45))
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 0.9, 0.95))
			# 4 条光束
			for i in range(4):
				var ang := float(i) * PI / 2.0 + t_msf * 1.5
				var be := Vector2(cos(ang), sin(ang)) * 14.0
				draw_line(Vector2.ZERO, be, Color(1.0, 0.95, 0.55, 0.85), 1.6)

		# —— 🌑 暗影弹 —— 紫色漩涡 ——
		Kind.DARK:
			draw_circle(Vector2.ZERO, 11.0, Color(0.3, 0.15, 0.5, 0.35))
			draw_circle(Vector2.ZERO, 7.0, Color(0.5, 0.2, 0.7, 0.55))
			draw_circle(Vector2.ZERO, 4.0, Color(0.7, 0.4, 0.9, 0.8))
			draw_circle(Vector2.ZERO, 1.5, Color(0.9, 0.8, 1.0, 0.95))

		# —— 🪓 飞斧 —— 旋转斧头 ——
		Kind.AXE:
			var blade_rot := t_msf * 12.0
			var fwd := Vector2(cos(blade_rot), sin(blade_rot))
			var bp := Vector2(-fwd.y, fwd.x)
			# 斧柄
			draw_line(Vector2.ZERO, -fwd * 10.0, Color(0.55, 0.38, 0.2, 0.9), 2.2)
			# 斧刃（长条）
			var b1 := fwd * 8.0 + bp * 6.0
			var b2 := fwd * 8.0 - bp * 6.0
			var b3 := -fwd * 2.0 + bp * 7.0
			var b4 := -fwd * 2.0 - bp * 7.0
			draw_colored_polygon(PackedVector2Array([b1, b2, b3, b4]), Color(0.82, 0.82, 0.88, 0.95))

		# —— 🌟 飞镖 —— 四角星 ——
		Kind.SHURIKEN:
			var spin := t_msf * 18.0
			var fwd := Vector2(cos(spin), sin(spin))
			var bp := Vector2(-fwd.y, fwd.x)
			var arm_len := 8.0
			# 4 臂
			var pts: PackedVector2Array = PackedVector2Array()
			for ang in [0, PI / 2, PI, PI * 1.5]:
				var dir_a := Vector2(cos(ang + spin), sin(ang + spin))
				pts.append(dir_a * arm_len)
				pts.append(dir_a * arm_len * 0.4 + dir_a.rotated(PI / 4.0) * 2.0)
			draw_colored_polygon(pts, Color(0.75, 0.75, 0.78, 0.95))

		# —— 🧪 毒针 —— 细长针（比箭细）——
		Kind.NEEDLE:
			var L := 18.0
			var tip_p := tip * L
			var base_p := -tip * (L * 0.3)
			draw_line(base_p, tip_p - tip * 3.0, Color(0.55, 0.75, 0.55, 0.9), 1.2)
			var nt := tip_p
			var nb := tip_p - tip * 3.0
			var np1 := nb + perp * 1.0
			var np2 := nb - perp * 1.0
			draw_colored_polygon(PackedVector2Array([nt, np1, np2]), Color(0.75, 1.0, 0.7, 0.95))

		# —— 🔆 激光弹（内部有流动感）——
		Kind.LASER_BOLT:
			var r := 7.0
			var core_pulse := 1.0 + 0.3 * sin(t_msf * 20.0)
			draw_circle(Vector2.ZERO, r + 5.0, Color(0.4, 1.0, 0.65, 0.2))
			draw_circle(Vector2.ZERO, r + 2.0, Color(0.4, 1.0, 0.65, 0.4))
			draw_circle(Vector2.ZERO, r * core_pulse, Color(0.7, 1.0, 0.85, 0.95))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 1.0, 0.95))

		# 通用 fallback（保留老版发光球+方向三角）
		_:
			draw_circle(Vector2.ZERO, 14.0, Color(color.r, color.g, color.b, 0.15))
			draw_circle(Vector2.ZERO, 8.0, color)
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 1.0, 0.85))
			var l := 12.0
			var pp := Vector2(-direction.y, direction.x)
			var tp := direction.normalized() * l
			draw_colored_polygon(PackedVector2Array([tp, pp * 3.0, -pp * 3.0]), color)
