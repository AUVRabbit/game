# ============================================================
# SkillExecutor — 技能执行器
# 按技能数据中的 type 执行对应效果
# 支持：melee_aoe / projectile / heal / buff / shield / chain / aoe_zone /
#       dash_strike / snipe / deployable / summon / blink_strike /
#       root_zone / heal_zone / mark / stun_wave / pull_zone
# 增强：锁定最近敌人（TargetingReticle + 靶向方向调整），
#       命中反馈（enemy._anim.hurt() + 屏幕震屏），
#       区域技能预警圈（aoe_zone / pull_zone）。
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
	var origin: Vector2 = caster.global_position
	var facing: Vector2 = caster.facing if caster.facing.length() > 0.01 else Vector2.DOWN
	var power := float(skill.get("power", 1.0))
	if data.has_method("get_skill_power_multiplier"):
		power *= float(data.get_skill_power_multiplier(str(skill.get("id", ""))))
	var is_magic := str(skill.get("damage_type", "physical")) == "magic"
	var base_stat: float = float(data.get_magic_attack() if is_magic else data.get_attack())
	var base_damage := maxi(1, int(round(float(base_stat) * power)))
	var color := Color.from_string(str(skill.get("color", "#ffffff")), Color.WHITE)
	var level: Node = caster.get_parent()

	# ===== 靶向锁定 =====
	var target := _lock_target(caster, type_name, skill)
	var dir := facing
	var lock_pos := origin + facing * 60.0
	if target:
		dir = (target.global_position - origin).normalized()
		lock_pos = target.global_position
		# 锁定标记（非友方/非区域类）
		if not (type_name in ["heal", "buff", "shield", "heal_zone", "summon", "deployable"]):
			TargetingReticle.spawn(level, target.global_position, color, 0.32, 20.0)

	SkillVfx.spawn_skill(level, skill, origin, dir)

	match type_name:
		"melee_aoe":
			var pos := origin + dir * 38.0
			if target:
				pos = target.global_position + (pos - origin).normalized() * 20.0
			_melee_aoe(caster, pos, float(skill.get("radius", 80)), base_damage, is_magic, color, level,
				float(skill.get("knockback", 0.0)), float(skill.get("stun", 0.0)))
		"projectile":
			var pellets := maxi(1, int(skill.get("pellets", 1)))
			var spread := float(skill.get("spread", 0.0))
			for i in pellets:
				var off := 0.0
				if pellets > 1:
					off = lerpf(-spread, spread, float(i) / float(pellets - 1))
				_projectile(caster, origin, dir.rotated(off), base_damage, is_magic, float(skill.get("speed", 420)), color,
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
			var buffs: Array = skill.get("buffs", [])
			if not buffs.is_empty():
				for buff in buffs:
					data.add_buff(str(buff.get("stat", "attack")), float(buff.get("value", 5)), float(skill.get("duration", 5)))
			else:
				data.add_buff(str(skill.get("stat", "attack")), float(skill.get("value", 5)), float(skill.get("duration", 5)))
			EffectRing.spawn(level, origin, 44.0, color)
			EventBus.notify("获得增益：%s" % str(skill.get("name", "")))
		"shield":
			var shield_power := float(skill.get("power", 40))
			if data.has_method("get_shield_bonus"):
				shield_power *= 1.0 + float(data.get_shield_bonus())
			data.add_shield(int(shield_power))
			var shield_buffs: Array = skill.get("buffs", [])
			for buff in shield_buffs:
				data.add_buff(str(buff.get("stat", "defense")), float(buff.get("value", 5)), float(skill.get("duration", 5)))
			EffectRing.spawn(level, origin, 50.0, color)
			EventBus.notify("获得护盾：%d" % int(shield_power))
		"chain":
			var chain_origin := lock_pos
			if target:
				chain_origin = target.global_position
			_chain(chain_origin, float(skill.get("radius", 220)), int(skill.get("count", 3)), base_damage, is_magic, color, level)
		"aoe_zone":
			var pos := origin + dir * 100.0
			if target:
				pos = target.global_position
			_aoe_zone(caster, pos, float(skill.get("radius", 90)), base_damage, is_magic, float(skill.get("delay", 0.5)), color, level)
			_apply_extra_shield(caster, data, skill, color, level)
		"dash_strike":
			_dash_strike(caster, dir, float(skill.get("distance", 120)), float(skill.get("radius", 60)), base_damage, is_magic, color, level)
		"snipe":
			var sniping_dir := dir
			var snipe_range := float(skill.get("range", 600))
			if target:
				sniping_dir = dir.normalized()
			_snipe(caster, origin, sniping_dir, snipe_range, float(skill.get("width", 18)),
				base_damage, is_magic, color, level, float(skill.get("lifesteal", 0.0)))
		"deployable":
			var deploy_pos := origin + dir * float(skill.get("offset", 90))
			if target:
				deploy_pos = origin + dir * clampf(origin.distance_to(target.global_position) * 0.8, 30.0, 260.0)
			_deployable(caster, skill, origin, dir, base_damage, is_magic, color, level, deploy_pos)
		"summon":
			_summon(caster, skill, origin, maxi(1, base_damage), is_magic, color, level)
		"blink_strike":
			_blink_strike(caster, float(skill.get("range", 170)), float(skill.get("radius", 55)),
				base_damage, is_magic, color, level)
		"root_zone":
			var pos := origin + dir * 100.0
			if target:
				pos = target.global_position
			_root_zone(caster, pos, float(skill.get("radius", 110)),
				base_damage, is_magic, float(skill.get("root", 1.5)), color, level)
		"heal_zone":
			_apply_extra_shield(caster, data, skill, color, level)
			_heal_zone(caster, origin, float(skill.get("radius", 110)), int(skill.get("heal", 18)),
				float(skill.get("duration", 5.0)), float(skill.get("tick", 1.0)), color, level)
		"mark":
			_mark_skill(origin, float(skill.get("radius", 320)), float(skill.get("duration", 8.0)),
				float(skill.get("amp", 0.25)), color, level, target)
		"stun_wave":
			_stun_wave(caster, origin, float(skill.get("radius", 110)), base_damage, is_magic,
				float(skill.get("stun", 0.8)), float(skill.get("knockback", 100)), color, level)
		"pull_zone":
			var pos := origin + dir * 80.0
			if target:
				pos = target.global_position
			_pull_zone(caster, pos, float(skill.get("radius", 120)), base_damage, is_magic,
				float(skill.get("duration", 0.8)), float(skill.get("pull", 70)), color, level)
		_:
			_melee_aoe(caster, origin + dir * 40.0, float(skill.get("radius", 80)), base_damage, is_magic, color, level)

	EventBus.skill_cast.emit(caster, str(skill.get("id", "")))
	_apply_fusion_keyword(caster, skill, origin, dir, base_damage, is_magic, color, level)
	AudioManager.play_sfx("skill")
	return true


# ---------- 锁定目标（用于靶向技能） ----------
static func _lock_target(caster, type_name: String, skill: Dictionary) -> Node2D:
	if caster == null or not (caster is Node2D):
		return null
	var range_dist := _lock_range(caster, type_name, skill)
	if range_dist <= 0.0:
		return null
	var best: Node2D = null
	var best_d := range_dist
	for enemy in _enemies():
		if not (enemy is Node2D):
			continue
		var d: float = (caster as Node2D).global_position.distance_to((enemy as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = enemy
	return best


static func _lock_range(caster, type_name: String, skill: Dictionary) -> float:
	match type_name:
		"melee_aoe":
			return float(skill.get("radius", 80)) + 60.0
		"projectile":
			var r := float(skill.get("range", 0.0))
			return r if r > 0.0 else 420.0
		"snipe":
			return float(skill.get("range", 600))
		"dash_strike":
			return float(skill.get("distance", 120)) + 40.0
		"blink_strike":
			return float(skill.get("range", 170))
		"chain":
			return float(skill.get("radius", 220))
		"mark":
			return float(skill.get("radius", 320))
		"stun_wave", "pull_zone":
			return float(skill.get("radius", 160))
		_:
			return 0.0


# ---------- 通用：额外护盾 / 融合词条 ----------

static func _apply_extra_shield(caster, data, skill: Dictionary, color: Color, level: Node) -> void:
	var has_shield := skill.has("shield") or str(skill.get("extra_type", "")) == "shield"
	if not has_shield:
		return
	var amount := float(skill.get("shield", 0))
	if amount <= 0.0:
		amount = float(skill.get("power", 60))
	if data.has_method("get_shield_bonus"):
		amount *= 1.0 + float(data.get_shield_bonus())
	data.add_shield(int(amount))
	var pos: Vector2 = caster.global_position if caster is Node2D else Vector2.ZERO
	EffectRing.spawn(level, pos, 50.0, color)


static func _apply_fusion_keyword(caster, skill: Dictionary, origin: Vector2, dir: Vector2, base_damage: int,
		is_magic: bool, color: Color, level: Node) -> void:
	var kw: Dictionary = skill.get("fusion_keyword", {})
	if kw.is_empty():
		return
	var kind := str(kw.get("kind", ""))
	var value := float(kw.get("value", 0.1))
	var center := origin
	if str(skill.get("type", "")) in ["projectile", "snipe", "beam"]:
		center = origin + dir.normalized() * 150.0
	var radius := maxf(130.0, float(skill.get("radius", 0.0)))
	match kind:
		"burn", "corrosion":
			for enemy in _enemies():
				if _dist(enemy, center) <= radius:
					_apply_damage(caster, enemy, maxi(1, int(round(float(base_damage) * value))), is_magic, level)
					if enemy.has_method("apply_mark"):
						enemy.apply_mark(3.0, value)
		"freeze":
			for enemy in _enemies():
				if _dist(enemy, center) <= radius and enemy.has_method("apply_slow"):
					enemy.apply_slow(0.35, 1.5)
		"root":
			for enemy in _enemies():
				if _dist(enemy, center) <= radius and enemy.has_method("apply_slow"):
					enemy.apply_slow(0.08, maxf(0.5, value))
		"stun":
			for enemy in _enemies():
				if _dist(enemy, center) <= radius and enemy.has_method("apply_stun"):
					enemy.apply_stun(maxf(0.3, value))
		"knockback":
			for enemy in _enemies():
				if enemy is Node2D and _dist(enemy, center) <= radius:
					var push: Vector2 = ((enemy as Node2D).global_position - center).normalized()
					if push.length() < 0.01:
						push = Vector2.DOWN
					(enemy as Node2D).global_position += push * maxf(30.0, value)
		"holy":
			var cdata = caster.get("character_data")
			if cdata != null:
				var healed: int = cdata.heal(int(round(float(cdata.get_max_hp()) * value)))
				if healed > 0:
					DamageNumber.spawn(level, origin + Vector2(0, -30), healed, false, true)
		"blink":
			if caster is Node2D:
				(caster as Node2D).global_position += dir.normalized() * maxf(30.0, value)
				EffectRing.spawn(level, (caster as Node2D).global_position, 24.0, color)
		"summon":
			_summon(caster, {"count": 1, "duration": 6.0, "speed": 130.0, "interval": 1.0},
				origin, maxi(1, int(base_damage * 0.5)), is_magic, color, level)
		"mark":
			_mark_skill(origin, 240.0, 6.0, value, color, level, null)


# ---------- 攻击 / 伤害 ----------

static func _melee_aoe(caster, origin: Vector2, radius: float, damage: int, is_magic: bool, color: Color, level: Node,
		knockback: float = 0.0, stun: float = 0.0) -> void:
	EffectRing.spawn(level, origin, radius, color)
	SkillVfx.spawn(level, origin, "melee_slash", color, 1.0, 0.0)
	# 冲击波向外扩散
	SkillVfx.spawn_shockwave(level, origin, radius * 1.3, color, 0.35)
	var any := false
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
			any = true
			if enemy is Node2D:
				var push: Vector2 = ((enemy as Node2D).global_position - origin).normalized()
				if push.length() < 0.01:
					push = Vector2.DOWN
				if knockback > 0.0:
					(enemy as Node2D).global_position += push * knockback
			if stun > 0.0 and enemy.has_method("apply_stun"):
				enemy.apply_stun(stun)
	if any and ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(4.5, 0.16, 45.0)


static func _projectile(caster, origin: Vector2, dir: Vector2, damage: int, is_magic: bool, speed: float, color: Color,
		icon_id: String = "", pierce: int = 0, splash: float = 0.0, range_dist: float = 0.0,
		knockback: float = 0.0, arc_amp: float = 0.0) -> void:
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
	projectile.arc_amplitude = arc_amp
	projectile.lifetime = maxf(0.3, range_dist / maxf(1.0, speed)) if range_dist > 0.0 else 1.6
	level.add_child(projectile)
	projectile.global_position = origin
	# 发射瞬间：枪口闪光
	SkillVfx.spawn_muzzle_flash(level, origin, color, dir.angle())


static func _chain(origin: Vector2, radius: float, count: int, damage: int, is_magic: bool, color: Color, level: Node) -> void:
	EffectRing.spawn(level, origin, radius * 0.6, color, 0.28)
	var targets: Array = []
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			targets.append(enemy)
	if targets.is_empty():
		return
	targets.sort_custom(func(a, b): return _dist(a, origin) < _dist(b, origin))
	var limit := mini(count, targets.size())
	# 链式闪电：起点 origin 依次连接到每个目标
	var flash_points := PackedVector2Array()
	flash_points.append(origin)
	for i in limit:
		var tp := (targets[i] as Node2D).global_position
		flash_points.append(tp)
		_apply_damage(null, targets[i], damage, is_magic, level)
	SkillVfx.spawn_chain_lightning(level, flash_points, color)
	# 每个被连接目标处画一个小爆点
	for i in flash_points.size():
		EffectRing.spawn(level, flash_points[i], 22.0, color, 0.22)


static func _aoe_zone(caster, pos: Vector2, radius: float, damage: int, is_magic: bool, delay: float, color: Color, level: Node) -> void:
	# 预警圈：先画一个较暗的脉冲圈（会随着 time 向外扩展）
	EffectRing.spawn(level, pos, radius, Color(color.r, color.g, color.b, 0.35), delay)
	# 红色预警脉冲（小尺寸快速闪烁提示危险）
	var warn_c := Color(color.r * 1.1 + 0.2, color.g * 0.3, color.b * 0.3, 0.9)
	EffectRing.spawn(level, pos, radius * 0.6, warn_c, delay * 0.7)
	# 落雷预警光束（从天而降一闪而过的闪电）
	var bolt_len := maxf(220.0, radius * 2.2)
	SkillVfx.spawn_lightning_bolt(level, pos, bolt_len, color, maxf(0.12, delay * 0.5))
	var tree: SceneTree = caster.get_tree()
	await tree.create_timer(delay).timeout
	if not is_instance_valid(caster):
		return
	# 爆炸瞬间：落雷 + 冲击波 + 碎片爆点
	SkillVfx.spawn_lightning_bolt(level, pos, bolt_len, color, 0.18)
	SkillVfx.spawn_shockwave(level, pos, radius * 1.35, color, 0.42)
	SkillVfx.spawn_burst(level, pos, radius, color, 0.45)
	EffectRing.spawn(level, pos, radius * 1.15, color)
	var any := false
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
			any = true
	if any and ScreenShake and ScreenShake.has_method("heavy"):
		ScreenShake.heavy()


static func _dash_strike(caster, dir: Vector2, distance: float, radius: float, damage: int, is_magic: bool, color: Color, level: Node) -> void:
	caster.global_position += dir.normalized() * distance
	var pos: Vector2 = caster.global_position
	EffectRing.spawn(level, pos, radius, color)
	SkillVfx.spawn(level, pos, "dash_streak", color, 1.0, dir.angle())
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
	if ScreenShake and ScreenShake.has_method("micro"):
		ScreenShake.micro()


# ---------- 工具 ----------

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
	var scaled := damage
	if caster != null:
		var cdata = caster.get("character_data")
		if cdata != null and cdata.has_method("get_execute_bonus"):
			var execute_bonus := float(cdata.get_execute_bonus())
			if execute_bonus > 0.0:
				var stunned = enemy.get("stun_left")
				var slowed = enemy.get("slow_left")
				var controlled := (stunned != null and float(stunned) > 0.0) or (slowed != null and float(slowed) > 0.0)
				if controlled:
					scaled = int(round(float(scaled) * (1.0 + execute_bonus)))
	var final_damage: int = enemy.take_damage(scaled, is_magic, caster)
	DamageNumber.spawn(level, enemy.global_position + Vector2(0, -26), final_damage, is_crit)
	# 轻微震屏（避免每个命中都抖一下导致画面糊）
	if ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(1.4, 0.06, 80.0)
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
	# 锁定目标（非近战普攻）
	var target := _lock_target(caster, "projectile", profile)
	if target:
		dir = (target.global_position - origin).normalized()
		TargetingReticle.spawn(level, target.global_position, color, 0.28, 14.0)
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
			var bomb_pos := origin + dir * float(profile.get("range", 220))
			if target:
				bomb_pos = target.global_position
			bomb.target_pos = bomb_pos
			bomb.global_position = origin
			level.add_child(bomb)
			EffectRing.spawn(level, origin, 16.0, color, 0.18)


# ---------- 狙击 / 光束 ----------
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
	if total > 0 and ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(2.5, 0.12, 60.0)
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


# ---------- 部署物 ----------
static func _deployable(caster, skill: Dictionary, origin: Vector2, dir: Vector2, damage: int,
		is_magic: bool, color: Color, level: Node, deploy_pos: Vector2 = Vector2.ZERO) -> void:
	var mode := str(skill.get("deploy", "bomb"))
	var count := maxi(1, int(skill.get("count", 1)))
	var offset := float(skill.get("offset", 90))
	var spread := float(skill.get("spread", 0))
	var trap_bonus := 0.0
	var cdata = caster.get("character_data")
	if cdata != null and cdata.has_method("get_trap_bonus"):
		trap_bonus = float(cdata.get_trap_bonus())
	var trap_damage := int(round(float(damage) * (1.0 + trap_bonus)))
	var perp := Vector2(-dir.y, dir.x)
	for i in count:
		var t := 0.0 if count <= 1 else float(i) / float(count - 1) - 0.5
		var pos: Vector2 = deploy_pos
		if pos.length() < 0.01:
			pos = origin + dir.normalized() * offset + perp * t * spread
		var device = preload("res://scripts/combat/deployable.gd").new()
		device.mode = mode
		device.radius = float(skill.get("radius", 80))
		device.damage = trap_damage
		device.is_magic = is_magic
		device.source = caster
		device.color = color
		device.fuse = float(skill.get("fuse", 0.5))
		device.lifetime = float(skill.get("duration", 12.0)) * (1.0 + trap_bonus)
		device.interval = float(skill.get("interval", 1.0))
		device.aim_dir = dir.normalized()
		device.target_pos = pos
		device.global_position = origin
		if level == null:
			push_warning("SkillExecutor._deployable: level is null, caster=%s" % str(caster))
		else:
			level.add_child(device)
		EffectRing.spawn(level, origin, 16.0, color, 0.18)


# ---------- 召唤 ----------
static func _summon(caster, skill: Dictionary, origin: Vector2, damage: int,
		is_magic: bool, color: Color, level: Node) -> void:
	var count := maxi(1, int(skill.get("count", 1)))
	var dur := float(skill.get("duration", 12.0))
	var summon_bonus := 0.0
	var cdata = caster.get("character_data")
	if cdata != null and cdata.has_method("get_summon_bonus"):
		summon_bonus = float(cdata.get_summon_bonus())
	if summon_bonus >= 0.2:
		count += 1
	damage = int(round(float(damage) * (1.0 + summon_bonus)))
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
		if level == null:
			return
		level.add_child(minion)
		var ang := TAU * float(i) / float(count)
		minion.global_position = origin + Vector2(cos(ang), sin(ang)) * 30.0
		EffectRing.spawn(level, minion.global_position, 20.0, color)
	EventBus.notify("召唤亡灵：%d 只" % count)


# ---------- 瞬步突袭 ----------
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


# ---------- 符文禁锢（地刺从地面刺出） ----------
static func _root_zone(caster, pos: Vector2, radius: float, damage: int, is_magic: bool,
		duration: float, color: Color, level: Node) -> void:
	# 预警
	EffectRing.spawn(level, pos, radius, Color(color.r, color.g * 0.6, color.b * 0.5, 0.5), 0.22)
	# 地刺尖刺从地面刺出
	SkillVfx.spawn_ground_spikes(level, pos, radius, maxi(6, int(radius / 18.0)), color, 0.42)
	# 符文圆形底座
	EffectRing.spawn(level, pos, radius * 0.5, Color(color.r * 0.3, color.g * 0.6, color.b * 1.1, 0.8), 0.5)
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.08, duration)


# ---------- 圣光领域 ----------
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


# ---------- 猎杀标记（接受外部 target 覆盖） ----------
static func _mark_skill(origin: Vector2, radius: float, duration: float, amp: float, color: Color, level: Node, target: Node2D = null) -> void:
	var mark_target = target
	if mark_target == null:
		var best := radius
		for enemy in _enemies():
			var d := _dist(enemy, origin)
			if d < best:
				best = d
				mark_target = enemy
	if mark_target == null:
		EventBus.notify("范围内没有可标记的目标")
		return
	if mark_target.has_method("apply_mark"):
		mark_target.apply_mark(duration, amp)
	EffectRing.spawn(level, mark_target.global_position, 30.0, color)
	EventBus.notify("已标记目标：受到伤害 +%d%%" % int(round(amp * 100.0)))


# ---------- 震波（环形冲击波向外扩散） ----------
static func _stun_wave(caster, origin: Vector2, radius: float, damage: int, is_magic: bool,
		stun: float, knockback: float, color: Color, level: Node) -> void:
	EffectRing.spawn(level, origin, radius, color)
	SkillVfx.spawn(level, origin, "void_pulse", color, 1.1, 0.0)
	# 冲击波向外扩散
	SkillVfx.spawn_shockwave(level, origin, radius * 1.3, color, 0.4)
	var any := false
	for enemy in _enemies():
		if _dist(enemy, origin) > radius:
			continue
		_apply_damage(caster, enemy, damage, is_magic, level)
		any = true
		if enemy is Node2D:
			var push: Vector2 = ((enemy as Node2D).global_position - origin).normalized()
			if push.length() < 0.01:
				push = Vector2.DOWN
			(enemy as Node2D).global_position += push * knockback
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun)
	if any and ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(5.0, 0.18, 42.0)


# ---------- 引力场 ----------
static func _pull_zone(caster, origin: Vector2, radius: float, damage: int, is_magic: bool,
		duration: float, pull: float, color: Color, level: Node) -> void:
	# 预警
	EffectRing.spawn(level, origin, radius, Color(color.r, color.g * 0.4, color.b, 0.4), duration)
	var tree: SceneTree = caster.get_tree()
	if tree == null:
		return
	var ticks := 6
	for i in ticks:
		EffectRing.spawn(level, origin, radius * (1.0 - float(i) / float(ticks) * 0.35), color, duration / float(ticks))
		for enemy in _enemies():
			if not (enemy is Node2D) or _dist(enemy, origin) > radius:
				continue
			var to_center: Vector2 = origin - (enemy as Node2D).global_position
			(enemy as Node2D).global_position += to_center.normalized() * (pull / float(ticks))
		await tree.create_timer(duration / float(ticks)).timeout
		if not is_instance_valid(caster):
			return
	var any := false
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius * 0.7:
			_apply_damage(caster, enemy, damage, is_magic, level)
			any = true
	EffectRing.spawn(level, origin, radius * 0.7, color)
	if any and ScreenShake and ScreenShake.has_method("shake"):
		ScreenShake.shake(4.5, 0.16, 40.0)
