# ============================================================
# DamageNumber — 飘字伤害/治疗数字
# ============================================================

extends Label
class_name DamageNumber

static func spawn(parent: Node, world_pos: Vector2, amount: int, is_crit: bool = false, is_heal: bool = false) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var label := DamageNumber.new()
	if is_heal:
		label.text = "+%d" % amount
		label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	elif is_crit:
		label.text = "%d!" % amount
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		label.text = str(amount)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	label.add_theme_font_size_override("font_size", 22 if is_crit else 16)
	label.z_index = 100
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	label.global_position = world_pos + Vector2(-12, -18)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 34.0, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(label.queue_free)
