# ============================================================
# SkillVfx — 技能视觉表现
# 使用 assets/vfx 下的真实特效贴图（纯黑底 + 加法混合），
# 并保留 EffectRing 作为范围提示。
# ============================================================

extends RefCounted
class_name SkillVfx

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

static func spawn_skill(level: Node, skill: Dictionary, origin: Vector2, dir: Vector2) -> void:
	if level == null or skill.is_empty():
		return
	var kind := str(skill.get("vfx", ""))
	if kind == "":
		return
	var color := Color.from_string(str(skill.get("color", "#ffffff")), Color.WHITE)
	var type_name := str(skill.get("type", ""))
	var angle := dir.angle() if dir.length() > 0.01 else 0.0
	match type_name:
		"melee_aoe":
			spawn(level, origin, kind, color, 1.2, angle + PI * 0.5)
		"projectile":
			spawn(level, origin + dir * 18.0, kind, color, 0.8, angle)
		"heal", "buff", "shield":
			spawn(level, origin, kind, color, 1.1)
		"aoe_zone":
			spawn(level, origin, kind, color, 1.4)
		"chain":
			spawn(level, origin, kind, color, 1.0)
		"dash_strike":
			spawn(level, origin, kind, color, 1.2, angle)
		_:
			spawn(level, origin, kind, color, 1.0)

static func spawn_impact(level: Node, pos: Vector2, kind: String, color: Color = Color.WHITE) -> void:
	spawn(level, pos, kind, color, 0.9)
