# ============================================================
# SkillExecutor — 技能执行器
# 按技能数据中的 type 执行对应效果
# 支持：melee_aoe / projectile / heal / buff / shield / chain / aoe_zone /
#       dash_strike / snipe / deployable / summon / blink_strike /
#       root_zone / heal_zone / mark / stun_wave / pull_zone
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
			_melee_aoe(caster, origin, float(skill.get("radius", 80)), base_damage, is_magic, color, level,
				float(skill.get("knockback", 0.0)), float(skill.get("stun", 0.0)))
		"projectile":
			_projectile(caster, origin, dir, base_damage, is_magic, float(skill.get("speed", 420)), color,
				str(skill.get("icon", "")), int(skill.get("pierce", 0)), float(skill.get("splash_radius", 0.0)),
				float(skill.get("range", 0.0)), float(skill.get("knockback", 0.0)))
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
		"snipe":
			_snipe(caster, origin, dir, float(skill.get("range", 600)), float(skill.get("width", 18)),
				base_damage, is_magic, color, level, float(skill.get("lifesteal", 0.0)))
		"deployable":
			_deployable(caster, skill, origin, dir, base_damage, is_magic, color, level)
		"summon":
			_summon(caster, skill, origin, base_damage, is_magic, color, level)
		"blink_strike":
			_blink_strike(caster, float(skill.get("range", 170)), float(skill.get("radius", 55)),
				base_damage, is_magic, color, level)
		"root_zone":
			_root_zone(caster, origin + dir * 70.0, float(skill.get("radius", 110)),
				base_damage, is_magic, float(skill.get("root", 1.5)), color, level)
		"heal_zone":
			_heal_zone(caster, origin, float(skill.get("radius", 110)), int(skill.get("heal", 18)),
				float(skill.get("duration", 5.0)), float(skill.get("tick", 1.0)), color, level)
		"mark":
			_mark(origin, float(skill.get("radius", 320)), float(skill.get("duration", 8.0)),
				float(skill.get("amp", 0.25)), color, level)
		"stun_wave":
			_stun_wave(caster, origin, float(skill.get("radius", 110)), base_damage, is_magic,
				float(skill.get("stun", 0.8)), float(skill.get("knockback", 100)), color, level)
		"pull_zone":
			_pull_zone(caster, origin, float(skill.get("radius", 120)), base_damage, is_magic,
				float(skill.get("duration", 0.8)), float(skill.get("pull", 70)), color, level)
		_:
			_melee_aoe(caster, origin, float(skill.get("radius", 80)), base_damage, is_magic, color, level)

	EventBus.skill_cast.emit(caster, str(skill.get("id", "")))
	AudioManager.play_sfx("skill")
	return true

static func _melee_aoe(caster, origin: Vector2, radius: float, damage: int, is_magic: bool, color: Color, level: Node,
		knockback: float = 0.0, stun: float = 0.0) -> void:
	EffectRing.spawn(level, origin, radius, color)
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
			if enemy is Node2D:
				var push: Vector2 = ((enemy as Node2D).global_position - origin).normalized()
				if push.length() < 0.01:
					push = Vector2.DOWN
				if knockback > 0.0:
					(enemy as Node2D).global_position += push * knockback
			if stun > 0.0 and enemy.has_method("apply_stun"):
				enemy.apply_stun(stun)

static func _projectile(caster, origin: Vector2, dir: Vector2, damage: int, is_magic: bool, speed: float, color: Color,
		icon_id: String = "", pierce: int = 0, splash: float = 0.0, range_dist: float = 0.0,
		knockback: float = 0.0) -> void:
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
	projectile.pierce = pierce
	projectile.splash_radius = splash
	projectile.knockback = knockback
	projectile.lifetime = maxf(0.3, range_dist / maxf(1.0, speed)) if range_dist > 0.0 else 1.6
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

static func _apply_damage(caster, enemy, damage: int, is_magic: bool, level: Node, is_crit: bool = false) -> int:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return 0
	var final_damage: int = enemy.take_damage(damage, is_magic, caster)
	DamageNumber.spawn(level, enemy.global_position + Vector2(0, -26), final_damage, is_crit)
	return final_damage

static func _body_radius(enemy) -> float:
	if enemy != null and "body_radius" in enemy:
		return float(enemy.body_radius)
	return 14.0

# ---------- 普攻（按职业 basic_attack 配置执行非近战普攻） ----------
static func cast_basic(caster, profile: Dictionary, damage: int, is_crit: bool) -> void:
	if caster == null or profile.is_empty():
		return
	var kind := str(profile.get("kind", "melee"))
	var dir: Vector2 = caster.facing if caster.facing.length() > 0.01 else Vector2.DOWN
	dir = dir.normalized()
	var origin: Vector2 = caster.global_position + dir * 22.0
	var color := Color.from_string(str(profile.get("color", "#ffffff")), Color.WHITE)
	var is_magic := bool(profile.get("magic", false))
	var level: Node = caster.get_parent()
	if level == null:
		return
	match kind:
		"projectile":
			var pellets := maxi(1, int(profile.get("pellets", 1)))
			var spread := float(profile.get("spread", 0.0))
			for i in pellets:
				var off := 0.0
				if pellets > 1:
					off = lerpf(-spread, spread, float(i) / float(pellets - 1))
				var projectile = preload("res://scripts/combat/projectile.gd").new()
				projectile.direction = dir.rotated(off)
				projectile.speed = float(profile.get("speed", 520.0))
				projectile.damage = damage
				projectile.is_magic = is_magic
				projectile.color = color
				projectile.source = caster
				projectile.is_crit = is_crit
				projectile.pierce = int(profile.get("pierce", 0))
				projectile.splash_radius = float(profile.get("splash_radius", 0.0))
				projectile.knockback = float(profile.get("knockback", 0.0))
				var rng := float(profile.get("range", 340.0))
				projectile.lifetime = maxf(0.25, rng / maxf(1.0, projectile.speed))
				level.add_child(projectile)
				projectile.global_position = origin
			EffectRing.spawn(level, origin, 16.0, color)
		"beam":
			_snipe(caster, origin, dir, float(profile.get("range", 600)), float(profile.get("width", 14)),
				damage, is_magic, color, level, 0.0, is_crit)
		"lob":
			var bomb = preload("res://scripts/combat/deployable.gd").new()
			bomb.mode = "bomb"
			bomb.radius = float(profile.get("radius", 60))
			bomb.damage = damage
			bomb.is_magic = is_magic
			bomb.source = caster
			bomb.color = color
			bomb.fuse = float(profile.get("fuse", 0.4))
			bomb.lifetime = 3.0
			level.add_child(bomb)
			bomb.global_position = caster.global_position + dir * float(profile.get("range", 220))
			EffectRing.spawn(level, bomb.global_position, bomb.radius * 0.5, color)

# ---------- 狙击：超远距离穿透射线 ----------
static func _snipe(caster, origin: Vector2, dir: Vector2, range_dist: float, width: float, damage: int,
		is_magic: bool, color: Color, level: Node, lifesteal: float = 0.0, is_crit: bool = false) -> void:
	var d := dir.normalized()
	var total := 0
	for enemy in _enemies():
		if not (enemy is Node2D):
			continue
		var rel: Vector2 = (enemy as Node2D).global_position - origin
		var t: float = rel.dot(d)
		if t < 0.0 or t > range_dist:
			continue
		var perp := absf(rel.dot(Vector2(-d.y, d.x)))
		if perp <= width * 0.5 + _body_radius(enemy):
			total += _apply_damage(caster, enemy, damage, is_magic, level, is_crit)
	_beam_visual(level, origin, origin + d * range_dist, color)
	if lifesteal > 0.0 and total > 0 and caster != null:
		var cdata = caster.get("character_data")
		if cdata != null:
			cdata.heal(int(round(float(total) * lifesteal)))

static func _beam_visual(level: Node, origin: Vector2, end: Vector2, color: Color) -> void:
	if level == null:
		return
	var line := Line2D.new()
	line.width = 9.0
	line.default_color = Color(color.r, color.g, color.b, 0.55)
	line.add_point(Vector2.ZERO)
	line.add_point(end - origin)
	line.z_index = 2
	level.add_child(line)
	line.global_position = origin
	var core := Line2D.new()
	core.width = 3.0
	core.default_color = Color(1.0, 1.0, 1.0, 0.95)
	core.add_point(Vector2.ZERO)
	core.add_point(end - origin)
	core.z_index = 3
	level.add_child(core)
	core.global_position = origin
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.25)
	tw.tween_callback(line.queue_free)
	var tw2 := core.create_tween()
	tw2.tween_property(core, "modulate:a", 0.0, 0.25)
	tw2.tween_callback(core.queue_free)

# ---------- 部署物：炸弹 / 地雷 / 炮塔 ----------
static func _deployable(caster, skill: Dictionary, origin: Vector2, dir: Vector2, damage: int,
		is_magic: bool, color: Color, level: Node) -> void:
	var mode := str(skill.get("deploy", "bomb"))
	var count := maxi(1, int(skill.get("count", 1)))
	var offset := float(skill.get("offset", 90))
	var spread := float(skill.get("spread", 0))
	var perp := Vector2(-dir.y, dir.x)
	for i in count:
		var t := 0.0 if count <= 1 else float(i) / float(count - 1) - 0.5
		var pos: Vector2 = origin + dir.normalized() * offset + perp * t * spread
		var device = preload("res://scripts/combat/deployable.gd").new()
		device.mode = mode
		device.radius = float(skill.get("radius", 80))
		device.damage = damage
		device.is_magic = is_magic
		device.source = caster
		device.color = color
		device.fuse = float(skill.get("fuse", 0.5))
		device.lifetime = float(skill.get("duration", 12.0))
		device.interval = float(skill.get("interval", 1.0))
		device.aim_dir = dir.normalized()
		level.add_child(device)
		device.global_position = pos
		EffectRing.spawn(level, pos, 26.0, color)

# ---------- 召唤：亡灵随从 ----------
static func _summon(caster, skill: Dictionary, origin: Vector2, damage: int,
		is_magic: bool, color: Color, level: Node) -> void:
	var count := maxi(1, int(skill.get("count", 1)))
	var dur := float(skill.get("duration", 12.0))
	for i in count:
		var minion = preload("res://scripts/combat/summoned_minion.gd").new()
		minion.lifetime = dur
		minion.damage = damage
		minion.is_magic = is_magic
		minion.move_speed = float(skill.get("speed", 120.0))
		minion.attack_range = float(skill.get("attack_range", 42.0))
		minion.attack_interval = float(skill.get("interval", 1.0))
		minion.detect_range = float(skill.get("detect_range", 420.0))
		minion.source = caster
		minion.color = color
		minion.body_scale = float(skill.get("scale", 1.0))
		level.add_child(minion)
		var ang := TAU * float(i) / float(count)
		minion.global_position = origin + Vector2(cos(ang), sin(ang)) * 30.0
		EffectRing.spawn(level, minion.global_position, 20.0, color)
	EventBus.notify("召唤亡灵：%d 只" % count)

# ---------- 瞬步突袭：闪现至目标身后 ----------
static func _blink_strike(caster, range_dist: float, radius: float, damage: int, is_magic: bool,
		color: Color, level: Node) -> void:
	var target = null
	var best := range_dist
	for enemy in _enemies():
		var d := _dist(enemy, caster.global_position)
		if d < best:
			best = d
			target = enemy
	if target == null:
		EventBus.notify("范围内没有可突袭的目标")
		return
	var dirv: Vector2 = (target.global_position - caster.global_position).normalized()
	caster.global_position = target.global_position + dirv * 30.0
	EffectRing.spawn(level, caster.global_position, 24.0, color)
	EffectRing.spawn(level, target.global_position, radius, color)
	for enemy in _enemies():
		if _dist(enemy, target.global_position) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)

# ---------- 符文禁锢：范围定身 ----------
static func _root_zone(caster, pos: Vector2, radius: float, damage: int, is_magic: bool,
		duration: float, color: Color, level: Node) -> void:
	EffectRing.spawn(level, pos, radius, color)
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.08, duration)

# ---------- 圣光领域：持续治疗 ----------
static func _heal_zone(caster, origin: Vector2, radius: float, heal: int, duration: float,
		tick: float, color: Color, level: Node) -> void:
	var tree: SceneTree = caster.get_tree()
	if tree == null:
		return
	var elapsed := 0.0
	while elapsed < duration:
		EffectRing.spawn(level, origin, radius, color)
		if is_instance_valid(caster) and caster.global_position.distance_to(origin) <= radius:
			var cdata = caster.get("character_data")
			if cdata != null:
				var healed: int = cdata.heal(heal)
				if healed > 0:
					DamageNumber.spawn(level, caster.global_position + Vector2(0, -30), healed, false, true)
		await tree.create_timer(tick).timeout
		if not is_instance_valid(caster):
			return
		elapsed += tick

# ---------- 猎杀标记：目标受到额外伤害 ----------
static func _mark(origin: Vector2, radius: float, duration: float, amp: float, color: Color, level: Node) -> void:
	var target = null
	var best := radius
	for enemy in _enemies():
		var d := _dist(enemy, origin)
		if d < best:
			best = d
			target = enemy
	if target == null:
		EventBus.notify("范围内没有可标记的目标")
		return
	if target.has_method("apply_mark"):
		target.apply_mark(duration, amp)
	EffectRing.spawn(level, target.global_position, 30.0, color)
	EventBus.notify("已标记目标：受到伤害 +%d%%" % int(round(amp * 100.0)))

# ---------- 震波：范围击退 + 眩晕 ----------
static func _stun_wave(caster, origin: Vector2, radius: float, damage: int, is_magic: bool,
		stun: float, knockback: float, color: Color, level: Node) -> void:
	EffectRing.spawn(level, origin, radius, color)
	for enemy in _enemies():
		if _dist(enemy, origin) > radius:
			continue
		_apply_damage(caster, enemy, damage, is_magic, level)
		if enemy is Node2D:
			var push: Vector2 = ((enemy as Node2D).global_position - origin).normalized()
			if push.length() < 0.01:
				push = Vector2.DOWN
			(enemy as Node2D).global_position += push * knockback
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun)

# ---------- 引力场：持续牵引 + 收束伤害 ----------
static func _pull_zone(caster, origin: Vector2, radius: float, damage: int, is_magic: bool,
		duration: float, pull: float, color: Color, level: Node) -> void:
	var tree: SceneTree = caster.get_tree()
	if tree == null:
		return
	var ticks := 6
	for i in ticks:
		EffectRing.spawn(level, origin, radius * (1.0 - float(i) / float(ticks) * 0.35), color)
		for enemy in _enemies():
			if not (enemy is Node2D) or _dist(enemy, origin) > radius:
				continue
			var to_center: Vector2 = origin - (enemy as Node2D).global_position
			(enemy as Node2D).global_position += to_center.normalized() * (pull / float(ticks))
		await tree.create_timer(duration / float(ticks)).timeout
		if not is_instance_valid(caster):
			return
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius * 0.7:
			_apply_damage(caster, enemy, damage, is_magic, level)
	EffectRing.spawn(level, origin, radius * 0.7, color)
