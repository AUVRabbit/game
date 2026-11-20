# ============================================================
# SkillExecutor — 技能执行器
# 按技能数据中的 type 执行对应效果
# 支持：melee_aoe / projectile / heal / buff / shield /
#       chain / aoe_zone / dash_strike
# ============================================================

extends RefCounted
class_name SkillExecutor

static func cast(caster, skill: Dictionary) -> bool:
	if caster == null or skill.is_empty():
		return false
	var data = caster.get("character_data")
	if data == null:
		return false
	var cost := int(skill.get("mp", 0))
	if not data.use_mp(cost):
		EventBus.notify("MP 不足")
		return false

	var type_name := str(skill.get("type", "melee_aoe"))
	var dir: Vector2 = caster.facing if caster.facing.length() > 0.01 else Vector2.DOWN
	var origin: Vector2 = caster.global_position
	var power := float(skill.get("power", 1.0))
	if data.has_method("get_skill_power_multiplier"):
		power *= float(data.get_skill_power_multiplier(str(skill.get("id", ""))))
	var is_magic := str(skill.get("damage_type", "physical")) == "magic"
	var base_stat: float = float(data.get_magic_attack() if is_magic else data.get_attack())
	var base_damage := maxi(1, int(round(float(base_stat) * power)))
	var color := Color.from_string(str(skill.get("color", "#ffffff")), Color.WHITE)
	var level: Node = caster.get_parent()

	SkillVfx.spawn_skill(level, skill, origin, dir)

	match type_name:
		"melee_aoe":
			_melee_aoe(caster, origin, float(skill.get("radius", 80)), base_damage, is_magic, color, level)
		"projectile":
			_projectile(caster, origin, dir, base_damage, is_magic, float(skill.get("speed", 420)), color, str(skill.get("icon", "")))
		"heal":
			var heal_power := float(skill.get("power", 30))
			if data.has_method("get_heal_bonus"):
				heal_power *= 1.0 + float(data.get_heal_bonus())
			var healed: int = data.heal(int(heal_power))
			DamageNumber.spawn(level, origin + Vector2(0, -30), healed, false, true)
			EffectRing.spawn(level, origin, 46.0, color)
		"buff":
			data.add_buff(str(skill.get("stat", "attack")), float(skill.get("value", 5)), float(skill.get("duration", 5)))
			EffectRing.spawn(level, origin, 44.0, color)
			EventBus.notify("获得增益：%s" % str(skill.get("name", "")))
		"shield":
			var shield_power := float(skill.get("power", 40))
			if data.has_method("get_shield_bonus"):
				shield_power *= 1.0 + float(data.get_shield_bonus())
			data.add_shield(int(shield_power))
			EffectRing.spawn(level, origin, 50.0, color)
			EventBus.notify("获得护盾：%d" % int(shield_power))
		"chain":
			_chain(origin, float(skill.get("radius", 220)), int(skill.get("count", 3)), base_damage, is_magic, color, level)
		"aoe_zone":
			_aoe_zone(caster, origin + dir * 70.0, float(skill.get("radius", 90)), base_damage, is_magic, float(skill.get("delay", 0.5)), color, level)
		"dash_strike":
			_dash_strike(caster, dir, float(skill.get("distance", 120)), float(skill.get("radius", 60)), base_damage, is_magic, color, level)
		_:
			_melee_aoe(caster, origin, float(skill.get("radius", 80)), base_damage, is_magic, color, level)

	EventBus.skill_cast.emit(caster, str(skill.get("id", "")))
	AudioManager.play_sfx("skill")
	return true

static func _melee_aoe(caster, origin: Vector2, radius: float, damage: int, is_magic: bool, color: Color, level: Node) -> void:
	EffectRing.spawn(level, origin, radius, color)
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)

static func _projectile(caster, origin: Vector2, dir: Vector2, damage: int, is_magic: bool, speed: float, color: Color, icon_id: String = "") -> void:
	var level: Node = caster.get_parent()
	if level == null:
		return
	var projectile = preload("res://scripts/combat/projectile.gd").new()
	projectile.direction = dir.normalized()
	projectile.speed = speed
	projectile.damage = damage
	projectile.is_magic = is_magic
	projectile.color = color
	projectile.icon_id = icon_id
	projectile.source = caster
	level.add_child(projectile)
	projectile.global_position = origin

static func _chain(origin: Vector2, radius: float, count: int, damage: int, is_magic: bool, color: Color, level: Node) -> void:
	EffectRing.spawn(level, origin, radius, color)
	var targets: Array = []
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			targets.append(enemy)
	if targets.is_empty():
		return
	targets.sort_custom(func(a, b): return _dist(a, origin) < _dist(b, origin))
	var limit := mini(count, targets.size())
	for i in limit:
		_apply_damage(null, targets[i], damage, is_magic, level)

static func _aoe_zone(caster, pos: Vector2, radius: float, damage: int, is_magic: bool, delay: float, color: Color, level: Node) -> void:
	EffectRing.spawn(level, pos, radius, color)
	var tree: SceneTree = caster.get_tree()
	await tree.create_timer(delay).timeout
	if not is_instance_valid(caster):
		return
	EffectRing.spawn(level, pos, radius * 1.1, color)
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)

static func _dash_strike(caster, dir: Vector2, distance: float, radius: float, damage: int, is_magic: bool, color: Color, level: Node) -> void:
	caster.global_position += dir.normalized() * distance
	var pos: Vector2 = caster.global_position
	EffectRing.spawn(level, pos, radius, color)
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)

static func _enemies() -> Array:
	var result: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return result
	for e in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			result.append(e)
	return result

static func _dist(node, pos: Vector2) -> float:
	if node is Node2D:
		return (node as Node2D).global_position.distance_to(pos)
	return 999999.0

static func _apply_damage(caster, enemy, damage: int, is_magic: bool, level: Node) -> void:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return
	var final_damage: int = enemy.take_damage(damage, is_magic, caster)
	DamageNumber.spawn(level, enemy.global_position + Vector2(0, -26), final_damage, false)
