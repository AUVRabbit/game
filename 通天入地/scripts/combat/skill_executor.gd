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

	# —— 推断本次伤害的元素类型（用于克制表）——
	var damage_element: String = "physical"
	var fusion_kw_in: Dictionary = skill.get("fusion_keyword", {})
	if not fusion_kw_in.is_empty():
		damage_element = ElementKeeper.from_fusion_kind(str(fusion_kw_in.get("kind", "")))
	elif str(skill.get("damage_type", "physical")) == "magic":
		# 魔法默认按 "fire" 处理（可以后续细分）
		damage_element = "fire"

	# ===== 流派 signature：每个流派独有的机制钩子 =====
	var sig: Dictionary = {}
	if data != null and data.has_method("get_signature"):
		sig = data.get_signature()
	var sig_kind := str(sig.get("kind", ""))

	# —— 全局伤害修正（cast 入口统一处理）——
	match sig_kind:
		"oppression":
			# 王者压迫：不是 flat 加伤！让所有 AOE/chain/stun 类技能中心多释放一次 50% 伤害冲击波（非AOE类加 12%）
			var sk_type := str(skill.get("type", ""))
			if sk_type in ["aoe_zone", "chain", "stun_wave", "root_zone", "pull_zone"]:
				pass  # 在各分支里追加二次冲击
			else:
				base_damage = int(round(float(base_damage) * 1.12))
		"overclock":
			# 超频：不是 flat 加伤！普攻伤害 ×1.5、普攻攻速 +40%（在 character_base.get_attack_speed 里处理攻速，这里只对技能 +8%）
			base_damage = int(round(float(base_damage) * 1.08))
		"backstab":
			# 背刺：不是 flat 加伤！真正的背刺机制：身后目标伤害 ×1.5，正面目标伤害 ×0.7
			# （实现：在各近战/弹道分支里判断相对位置）
			base_damage = int(round(float(base_damage) * 1.0))  # 基础不加，在具体分支里算
		"overload":
			# 过载：每 15s 触发 4s 伤害 ×1.5
			var now_t := Time.get_ticks_msec() / 1000.0
			if float(data.get("_sig_overload_end")) > now_t:
				base_damage = int(round(float(base_damage) * 1.5))
			elif now_t - float(data.get("_sig_last_overload_check", 0.0)) >= 15.0:
				data.set("_sig_overload_end", now_t + float(sig.get("overload_duration", 4.0)))
				data.set("_sig_last_overload_check", now_t)
				base_damage = int(round(float(base_damage) * 1.5))
		"freeze_stacks":
			# 绝对零度：减速/冻结效果持续时间×1.5
			pass  # 在融合元素里处理
		_:
			pass

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

	# ===== 融合技：全新技能，独立起手 + 元素伤害内嵌，而非叠加主/副技能动画 =====
	var is_fusion := str(skill.get("origin", "")) == "fusion"
	var elem_kw: Dictionary = skill.get("fusion_keyword", {}) if is_fusion else {}
	var elem_color := Color.from_string(str(skill.get("fuse_element_color", skill.get("color", "#ffffff"))), Color.WHITE)
	if is_fusion:
		var main_color := Color.from_string(str(skill.get("fuse_main_color", skill.get("color", "#ffffff"))), Color.WHITE)
		SkillVfx.spawn_fusion_release(level, origin, main_color, elem_color, dir)
	else:
		SkillVfx.spawn_skill(level, skill, origin, dir)

	match type_name:
		"melee_aoe":
			var pos := origin + dir * 38.0
			if target:
				pos = target.global_position + (pos - origin).normalized() * 20.0
			var melee_knock := float(skill.get("knockback", 0.0))
			var melee_dmg := base_damage
			var backstab_info: Dictionary = {}
			match sig_kind:
				"formation_breaker":
					melee_knock *= float(sig.get("strong_knockback", 1.8))
				"berserker":
					var hp_ratio := float(data.hp) / float(data.get_max_hp())
					if hp_ratio < float(sig.get("hp_threshold", 0.4)):
						melee_dmg = int(round(float(base_damage) * float(sig.get("low_hp_damage_mult", 1.5))))
				"mortification":
					var hp_ratio := float(data.hp) / float(data.get_max_hp())
					if hp_ratio < 0.5:
						melee_dmg = int(round(float(base_damage) * 1.4))
					elif hp_ratio < 0.3:
						melee_dmg = int(round(float(base_damage) * 1.7))
				"holy_charge":
					if target:
						pos = target.global_position - dir * float(sig.get("auto_dash_range", 160))
					melee_dmg = int(round(float(base_damage) * 1.2))
				"afterimage":
					melee_dmg = int(round(float(base_damage) * 1.5))
				"backstab":
					# 背刺：身后敌人 ×1.5，正面 ×0.7
					backstab_info = {
						"dir": dir,
						"caster_pos": origin,
						"behind_mult": float(sig.get("behind_mult", 1.5)),
						"front_mult": float(sig.get("front_mult", 0.7)),
					}
			_melee_aoe(caster, pos, float(skill.get("radius", 80)), melee_dmg, is_magic, color, level,
				melee_knock, float(skill.get("stun", 0.0)), backstab_info)
		"projectile":
			# ========== 流派 signature 特判 ==========
			var pellets := maxi(1, int(skill.get("pellets", 1)))
			var spread := float(skill.get("spread", 0.0))
			var pierce_v := int(skill.get("pierce", 0))
			var speed_v := float(skill.get("speed", 420))
			var damage_v := base_damage
			match sig_kind:
				"rapid_fire":
					damage_v = int(round(float(base_damage) * float(sig.get("damage_penalty", 0.7))))
					spread = maxf(spread, 0.12)
					pellets = maxi(pellets, 2)
				"sword_pierce":
					pierce_v = maxi(pierce_v, 5)
				"rapid_shot":
					pellets = int(sig.get("shots_per_fire", 2))
					damage_v = int(round(float(base_damage) * float(sig.get("shot_damage_mult", 0.75))))
				"burn_amplify":
					# 燃尽：对已灼烧目标 +30% 伤害（简化为弹道伤害 +15%，命中判定在 projectile.gd）
					damage_v = int(round(float(base_damage) * 1.15))
				"life_siphon":
					# 生命虹吸：弹道伤害 40% 转玩家 MP
					data.restore_mp(int(round(float(base_damage) * float(sig.get("siphon_ratio", 0.40)))))
				_:
					pass
			for i in pellets:
				var off := 0.0
				if pellets > 1:
					off = lerpf(-spread, spread, float(i) / float(pellets - 1))
				_projectile(caster, origin, dir.rotated(off), damage_v, is_magic, speed_v, color,
					str(skill.get("icon", "")), pierce_v, float(skill.get("splash_radius", 0.0)),
					float(skill.get("range", 0.0)), float(skill.get("knockback", 0.0)), 0.0,
					elem_kw, elem_color, skill)
		"heal":
			var heal_power := float(skill.get("power", 30))
			if data.has_method("get_heal_bonus"):
				heal_power *= 1.0 + float(data.get_heal_bonus())
			if sig_kind == "piety_heal":
				heal_power *= float(sig.get("heal_mult", 1.5))
			var healed: int = data.heal(int(heal_power))
			# 血誓：治疗量 30% 转为护盾
			if sig_kind == "blood_oath":
				data.add_shield(int(round(float(healed) * float(sig.get("heal_to_shield", 0.30)))))
			DamageNumber.spawn(level, origin + Vector2(0, -30), healed, false, true)
			# 治疗爆发 + 8 颗绿色星屑向上飞
			SkillVfx.spawn_burst(level, origin, 52.0, Color(0.55, 1.0, 0.7), 0.45)
			for i in 8:
				var ang := -PI / 2 + randf_range(-0.7, 0.7)
				_spawn_particle(level, origin + Vector2(randf_range(-10, 10), -4), Color(0.6, 1.0, 0.7), 3.0, Vector2(cos(ang), sin(ang)) * 50.0, 0.6)
		"buff":
			var buffs: Array = skill.get("buffs", [])
			var buff_dur := float(skill.get("duration", 5))
			if sig_kind == "rune_duration":
				buff_dur *= float(sig.get("buff_mult", 1.8))
			if sig_kind == "supply_line":
				# 补给线：buff 共享给召唤物（难实现），简化为 buff 持续 ×1.3
				buff_dur *= 1.3
			if not buffs.is_empty():
				for buff in buffs:
					data.add_buff(str(buff.get("stat", "attack")), float(buff.get("value", 5)), buff_dur)
			else:
				data.add_buff(str(skill.get("stat", "attack")), float(skill.get("value", 5)), buff_dur)
			EffectRing.spawn(level, origin, 44.0, color)  # 保留光环（buff 需要持续提示）
			SkillVfx.spawn_burst(level, origin, 40.0, color, 0.35)
			EventBus.notify("获得增益：%s" % str(skill.get("name", "")))
		"shield":
			var shield_power := float(skill.get("power", 40))
			if data.has_method("get_shield_bonus"):
				shield_power *= 1.0 + float(data.get_shield_bonus())
			match sig_kind:
				"oath_shield":
					shield_power *= float(sig.get("shield_mult", 1.50))
				"heavy_armor":
					shield_power *= float(sig.get("shield_mult", 2.0))
				"formation_breaker":
					shield_power *= float(sig.get("shield_penalty", 0.8))
			data.add_shield(int(shield_power))
			var shield_buffs: Array = skill.get("buffs", [])
			for buff in shield_buffs:
				data.add_buff(str(buff.get("stat", "defense")), float(buff.get("value", 5)), float(skill.get("duration", 5)))
			EffectRing.spawn(level, origin, 50.0, color)  # 持续护盾光环
			SkillVfx.spawn_burst(level, origin, 48.0, Color(color.r, color.g, color.b * 1.3), 0.5)  # 护盾生成瞬间闪光
			EventBus.notify("获得护盾：%d" % int(shield_power))
		"chain":
			var chain_origin := lock_pos
			if target:
				chain_origin = target.global_position
			var chain_count := int(skill.get("count", 3))
			var chain_radius := float(skill.get("radius", 220))
			var chain_damage := base_damage
			match sig_kind:
				"chain_master":
					chain_count = maxi(chain_count, int(sig.get("max_jumps", 6)))
				"chain_symbiosis":
					data.restore_mp(int(sig.get("mp_per_hit", 20)))
			_chain(chain_origin, chain_radius, chain_count, chain_damage, is_magic, color, level,
				caster, elem_kw, elem_color, sig_kind, sig)
		"aoe_zone":
			var pos := origin + dir * 100.0
			if target:
				pos = target.global_position
			var aoe_delay := float(skill.get("delay", 0.5))
			var aoe_damage := base_damage
			var aoe_sig_kind := sig_kind
			var aoe_sig := sig
			match sig_kind:
				"trap_delay":
					aoe_delay += float(sig.get("delay_bonus", 1.0))
					aoe_damage = int(round(float(base_damage) * float(sig.get("damage_mult", 1.3))))
				"plague_spread":
					# 疫病蔓延：不是 flat 加伤！AOE 爆炸给敌人上瘟疫标记（后续对被标记敌人所有伤害 +15%）
					aoe_damage = int(round(float(base_damage) * 1.05))  # 略微加伤但主要是标记效果
			_aoe_zone(caster, pos, float(skill.get("radius", 90)), aoe_damage, is_magic, aoe_delay, color, level,
				elem_kw, elem_color, aoe_sig_kind, aoe_sig)
			# oppression：AOE 爆炸后中心额外释放一次 50% 伤害冲击波
			if sig_kind == "oppression":
				SkillVfx.spawn_shockwave(level, pos, float(skill.get("radius", 90)) * 1.3, color, 0.45)
				var oppression_dmg := int(round(float(base_damage) * 0.5))
				for e in _enemies():
					if _dist(e, pos) <= float(skill.get("radius", 90)) * 1.3:
						_apply_damage(caster, e, oppression_dmg, is_magic, level)
			# plague_spread：AOE 命中的敌人全部上瘟疫标记（mark_left 设置）
			if sig_kind == "plague_spread":
				for e in _enemies():
					if _dist(e, pos) <= float(skill.get("radius", 90)):
						e.set("mark_left", 8.0)
						e.set("mark_amp", float(sig.get("plague_amp", 0.15)))
			# bombeer_b 焦土：AOE 后留 3s 持续燃烧地面
			if sig_kind == "scorched_earth":
				var tree: SceneTree = caster.get_tree()
				if tree != null:
					var scorch_radius := float(skill.get("radius", 90))
					var scorch_dmg := int(round(float(base_damage) * 0.15))
					var scorch_dur := float(sig.get("ground_duration", 3.0))
					var elapsed := 0.0
					while elapsed < scorch_dur and is_instance_valid(caster):
						await tree.create_timer(0.6).timeout
						elapsed += 0.6
						for e in _enemies():
							if _dist(e, pos) <= scorch_radius:
								_apply_damage(caster, e, scorch_dmg, is_magic, level)
		"dash_strike":
			var dash_dist := float(skill.get("distance", 120))
			var dash_rad := float(skill.get("radius", 60))
			var dash_dmg := base_damage
			if sig_kind == "afterimage":
				dash_dmg = int(round(float(base_damage) * 1.5))
			_dash_strike(caster, dir, dash_dist, dash_rad, dash_dmg, is_magic, color, level)
			# cyborg_a 电磁过载：dash_strike 35% 概率追加 chain 闪电
			if sig_kind == "emp_overload" and randf() < float(sig.get("chain_chance", 0.35)):
				var chain_pos := (caster as Node2D).global_position if caster is Node2D else origin
				_chain(chain_pos, 180.0, 3, int(round(float(base_damage) * 0.5)), is_magic, color, level, caster)
		"snipe":
			var sniping_dir := dir
			var snipe_range := float(skill.get("range", 600))
			var snipe_damage := base_damage
			if target:
				sniping_dir = dir.normalized()
			match sig_kind:
				"precision_shot":
					snipe_range *= float(sig.get("range_mult", 1.5))
				"first_strike":
					if target and target.get("hp") != null and target.get("max_hp") != null and int(target.get("hp")) >= int(target.get("max_hp")):
						snipe_damage = int(round(float(base_damage) * float(sig.get("full_hp_mult", 1.60))))
					else:
						snipe_damage = int(round(float(base_damage) * float(sig.get("not_full_hp_mult", 0.85))))
				"deadly_shot":
					# 致命：snipe 暴击+40%、暴击伤害×2.5（简化为伤害 ×1.4）
					snipe_damage = int(round(float(base_damage) * 1.4))
			_snipe(caster, origin, sniping_dir, snipe_range, float(skill.get("width", 18)),
				snipe_damage, is_magic, color, level, float(skill.get("lifesteal", 0.0)))
		"deployable":
			var deploy_pos := origin + dir * float(skill.get("offset", 90))
			if target:
				deploy_pos = origin + dir * clampf(origin.distance_to(target.global_position) * 0.8, 30.0, 260.0)
			var deploy_skill := skill
			match sig_kind:
				"thermite_bomb":
					var dd := skill.duplicate(true)
					dd["duration"] = float(skill.get("duration", 12.0)) * float(sig.get("lifetime_mult", 3.0))
					dd["power"] = float(skill.get("power", 1.0)) * float(sig.get("damage_mult", 1.3))
					deploy_skill = dd
				"trap_master":
					var dd := skill.duplicate(true)
					dd["count"] = int(sig.get("traps_per_deploy", 3))
					dd["offset"] = maxf(float(skill.get("offset", 90)), 40.0)
					deploy_skill = dd
			_deployable(caster, deploy_skill, origin, dir, base_damage, is_magic, color, level, deploy_pos, elem_kw, elem_color)
			# bombeer_a 连环炸：部署爆炸后再自动投一枚（简化为立即多放一枚）
			if sig_kind == "chain_detonate" and bool(sig.get("extra_bomb", true)):
				var extra_pos := deploy_pos + dir * 80.0 + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
				_deployable(caster, skill, origin, dir, base_damage, is_magic, color, level, extra_pos, elem_kw, elem_color)
		"summon":
			var sum_skill := skill
			match sig_kind:
				"minion_lord":
					var dd := skill.duplicate(true)
					dd["count"] = maxi(int(skill.get("count", 1)), 1) * int(sig.get("count_mult", 2.0))
					sum_skill = dd
				"tomb_guard":
					var dd := skill.duplicate(true)
					dd["count"] = maxi(int(skill.get("count", 1)), 1) + 1
					sum_skill = dd
			var summon_damage := maxi(1, base_damage)
			if sig_kind == "minion_lord":
				summon_damage = int(round(float(summon_damage) * float(sig.get("damage_mult", 1.30))))
			if sig_kind == "turret_master":
				# 自动火炮：炮塔射速 ×2（简化为召唤物伤害 ×1.3）
				summon_damage = int(round(float(summon_damage) * 1.3))
			_summon(caster, sum_skill, origin, summon_damage, is_magic, color, level)
		"blink_strike":
			var blink_range := float(skill.get("range", 170))
			if sig_kind == "ghost_trap":
				blink_range *= 1.3
			var blink_dmg := base_damage
			if sig_kind == "afterimage":
				blink_dmg = int(round(float(base_damage) * 1.5))
			_blink_strike(caster, blink_range, float(skill.get("radius", 55)),
				blink_dmg, is_magic, color, level)
		"root_zone":
			var pos := origin + dir * 100.0
			if target:
				pos = target.global_position
			_root_zone(caster, pos, float(skill.get("radius", 110)),
				base_damage, is_magic, float(skill.get("root", 1.5)), color, level)
		"heal_zone":
			_heal_zone(caster, origin, float(skill.get("radius", 110)), int(skill.get("heal", 18)),
				float(skill.get("duration", 5.0)), float(skill.get("tick", 1.0)), color, level)
		"mark":
			var mark_dur := float(skill.get("duration", 8.0))
			var mark_amp := float(skill.get("amp", 0.25))
			if sig_kind == "mark_bounty":
				mark_dur *= 1.4
				mark_amp *= 1.3
			_mark_skill(origin, float(skill.get("radius", 320)), mark_dur,
				mark_amp, color, level, target)
		"stun_wave":
			var wave_damage := base_damage
			if sig_kind == "stun_wave_shield":
				data.add_shield(int(sig.get("stun_wave_gives_shield", 200)))
			_stun_wave(caster, origin, float(skill.get("radius", 110)), wave_damage, is_magic,
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
	# 融合元素：弹道 / 区域 / 部署 / 链式已在各自命中处内嵌结算，
	# 其余类型在这里与主技能同帧、同中心点结算，形成一次完整的新技能表现。
	if is_fusion and not (type_name in ["projectile", "aoe_zone", "deployable", "chain"]):
		var ec := origin
		var er := maxf(110.0, float(skill.get("radius", 0.0)))
		match type_name:
			"melee_aoe", "dash_strike", "blink_strike":
				ec = target.global_position if target else origin + dir * 40.0
			"root_zone", "pull_zone", "mark", "heal_zone":
				ec = target.global_position if target else origin + dir * 100.0
			"snipe":
				ec = target.global_position if target else origin + dir * float(skill.get("range", 600))
				er = maxf(er, 140.0)
			_:
				ec = origin if type_name in ["stun_wave", "heal", "buff", "shield", "summon"] else origin + dir * 40.0
		_apply_element(caster, elem_kw, elem_color, ec, er, base_damage, is_magic, level)
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
	SkillVfx.spawn_burst(level, pos, 50.0, color, 0.4)


# 融合元素结算：在指定中心点播放一次元素表现并施加对应效果。
# 由融合技的命中瞬间调用（弹道命中点 / 区域爆点 / 施法同步点）。
static func _apply_element(caster, kw: Dictionary, color: Color, center: Vector2, radius: float,
		damage: int, is_magic: bool, level: Node) -> void:
	var kind := str(kw.get("kind", ""))
	if kind == "":
		return
	var value := float(kw.get("value", 0.1))
	SkillVfx.spawn_element(level, center, kind, color, radius)
	match kind:
		"burn", "corrosion":
			for enemy in _enemies():
				if _dist(enemy, center) <= radius:
					_apply_damage(caster, enemy, maxi(1, int(round(float(damage) * value))), is_magic, level)
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
					DamageNumber.spawn(level, center + Vector2(0, -30), healed, false, true)
		"blink":
			if caster is Node2D:
				(caster as Node2D).global_position += (center - (caster as Node2D).global_position).normalized() * maxf(30.0, value)
				SkillVfx.spawn_burst(level, (caster as Node2D).global_position, 26.0, color, 0.3)
		"summon":
			_summon(caster, {"count": 1, "duration": 6.0, "speed": 130.0, "interval": 1.0},
				center, maxi(1, int(damage * 0.5)), is_magic, color, level)
		"mark":
			_mark_skill(center, maxf(180.0, radius), 6.0, value, color, level, null)


# ---------- 攻击 / 伤害 ----------

static func _melee_aoe(caster, origin: Vector2, radius: float, damage: int, is_magic: bool, color: Color, level: Node,
		knockback: float = 0.0, stun: float = 0.0, backstab_info: Dictionary = {}) -> void:
	# 剑气弧 + 冲击波 + 中心闪光（三层！）
	SkillVfx.spawn_sword_arc(level, origin, Vector2.RIGHT, color, radius * 1.2)
	SkillVfx.spawn_shockwave(level, origin, radius * 1.3, color, 0.35)
	SkillVfx.spawn_impact(level, origin, "melee", color)
	var any := false
	var has_backstab := not backstab_info.is_empty()
	var caster_dir: Vector2 = backstab_info.get("dir", Vector2.ZERO) if has_backstab else Vector2.ZERO
	var caster_pos: Vector2 = backstab_info.get("caster_pos", origin) if has_backstab else origin
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			var final_dmg := damage
			if has_backstab and caster_dir.length() > 0.1 and enemy is Node2D:
				var to_enemy: Vector2 = (enemy as Node2D).global_position - caster_pos
				if to_enemy.length() > 0.01:
					var dot_val := caster_dir.normalized().dot(to_enemy.normalized())
					if dot_val < 0.0:  # 敌人在 caster 身后 → 背刺 ×1.5
						final_dmg = int(round(float(damage) * float(backstab_info.get("behind_mult", 1.5))))
					else:  # 正面 → ×0.7（防御姿态）
						final_dmg = int(round(float(damage) * float(backstab_info.get("front_mult", 0.7))))
			_apply_damage(caster, enemy, final_dmg, is_magic, level)
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
		knockback: float = 0.0, arc_amp: float = 0.0,
		fusion_kw: Dictionary = {}, fusion_color: Color = Color.WHITE, skill_dict: Dictionary = {}) -> void:
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
	projectile.fusion_kw = fusion_kw
	projectile.fusion_color = fusion_color
	# —— 推断 projectile_kind（根据 icon / damage_element / 武器风格）——
	var sk_icon := icon_id
	var sk_speed := speed
	if not skill_dict.is_empty():
		sk_icon = str(skill_dict.get("icon", icon_id))
		sk_speed = float(skill_dict.get("speed", speed))
	_infer_projectile_kind(projectile, sk_icon, is_magic, color, arc_amp, sk_speed)
	projectile.lifetime = maxf(0.3, range_dist / maxf(1.0, speed)) if range_dist > 0.0 else 1.6
	level.add_child(projectile)
	projectile.global_position = origin
	SkillVfx.spawn_muzzle_flash(level, origin, color, dir.angle())


# —— 推断投射物外观 kind ——
static func _infer_projectile_kind(proj, icon: String, is_magic: bool, color: Color, arc_amp: float, speed: float) -> void:
	# 融合元素优先（有 elem_kw 时优先用融合元素色）
	var elem := ""
	if not proj.fusion_kw.is_empty():
		elem = str(proj.fusion_kw.get("kind", ""))
	# 从 icon 名字推断（如 fire_ball.png）
	var icon_lower := icon.to_lower() if icon != "" else ""
	if icon_lower.find("fire") >= 0 or icon_lower.find("flame") >= 0 or elem == "burn":
		proj.projectile_kind = Projectile.Kind.FIREBALL; proj.damage_element = "fire"; proj.color = Color(1.0, 0.5, 0.15)
	elif icon_lower.find("ice") >= 0 or icon_lower.find("cold") >= 0 or elem == "freeze":
		proj.projectile_kind = Projectile.Kind.ICICLE; proj.damage_element = "ice"; proj.color = Color(0.55, 0.85, 1.0)
	elif icon_lower.find("arrow") >= 0 or icon_lower.find("bow") >= 0 or icon_lower.find("bolt") >= 0:
		proj.projectile_kind = Projectile.Kind.ARROW; proj.damage_element = "physical"
	elif icon_lower.find("spear") >= 0 or icon_lower.find("lance") >= 0:
		proj.projectile_kind = Projectile.Kind.SPEAR; proj.damage_element = "physical"
	elif icon_lower.find("gun") >= 0 or icon_lower.find("bullet") >= 0 or icon_lower.find("pistol") >= 0:
		proj.projectile_kind = Projectile.Kind.BULLET; proj.damage_element = "physical"
	elif icon_lower.find("rock") >= 0 or icon_lower.find("bomb") >= 0 or icon_lower.find("stone") >= 0:
		proj.projectile_kind = Projectile.Kind.ROCK; proj.damage_element = "physical"
	elif icon_lower.find("thunder") >= 0 or icon_lower.find("lightning") >= 0 or elem == "stun":
		proj.projectile_kind = Projectile.Kind.LIGHTNING; proj.damage_element = "thunder"; proj.color = Color(0.75, 0.95, 1.0)
	elif icon_lower.find("holy") >= 0 or icon_lower.find("light") >= 0 or elem == "holy":
		proj.projectile_kind = Projectile.Kind.HOLY; proj.damage_element = "holy"; proj.color = Color(1.0, 0.9, 0.5)
	elif icon_lower.find("dark") >= 0 or icon_lower.find("shadow") >= 0 or elem == "summon":
		proj.projectile_kind = Projectile.Kind.DARK; proj.damage_element = "shadow"; proj.color = Color(0.55, 0.3, 0.8)
	elif icon_lower.find("axe") >= 0:
		proj.projectile_kind = Projectile.Kind.AXE; proj.damage_element = "physical"
	elif icon_lower.find("shuriken") >= 0 or icon_lower.find("star") >= 0:
		proj.projectile_kind = Projectile.Kind.SHURIKEN; proj.damage_element = "physical"
	elif icon_lower.find("poison") >= 0 or icon_lower.find("needle") >= 0 or icon_lower.find("corrosion") >= 0 or elem == "corrosion":
		proj.projectile_kind = Projectile.Kind.NEEDLE; proj.damage_element = "nature"; proj.color = Color(0.55, 1.0, 0.5)
	elif icon_lower.find("laser") >= 0 or icon_lower.find("plasma") >= 0 or icon_lower.find("mech") >= 0:
		proj.projectile_kind = Projectile.Kind.LASER_BOLT; proj.damage_element = "mech"; proj.color = Color(0.35, 1.0, 0.7)
	# —— 兜底：按技能属性推断 ——
	elif arc_amp > 0.0:
		# 有抛物线 → 岩石/炸弹
		proj.projectile_kind = Projectile.Kind.ROCK; proj.damage_element = "physical"
	elif is_magic and elem == "":
		# 未指定元素的魔法 → 看颜色推断
		if color.r > color.g and color.r > color.b:
			proj.projectile_kind = Projectile.Kind.FIREBALL; proj.damage_element = "fire"
		elif color.b > color.r and color.b > color.g:
			proj.projectile_kind = Projectile.Kind.ICICLE; proj.damage_element = "ice"
		elif color.g > color.r and color.g > color.b:
			proj.projectile_kind = Projectile.Kind.NEEDLE; proj.damage_element = "nature"
		else:
			proj.projectile_kind = Projectile.Kind.FIREBALL; proj.damage_element = "fire"
	else:
		# 物理弹道 → 按速度推断（快的是子弹/弓箭，慢的是飞斧）
		if speed > 600.0:
			proj.projectile_kind = Projectile.Kind.BULLET; proj.damage_element = "physical"
		elif speed > 400.0:
			proj.projectile_kind = Projectile.Kind.ARROW; proj.damage_element = "physical"
		else:
			proj.projectile_kind = Projectile.Kind.AXE; proj.damage_element = "physical"


static func _chain(origin: Vector2, radius: float, count: int, damage: int, is_magic: bool, color: Color, level: Node,
		caster = null, fusion_kw: Dictionary = {}, fusion_color: Color = Color.WHITE,
		sig_kind: String = "", sig: Dictionary = {}) -> void:
	SkillVfx.spawn_lightning_bolt(level, origin - Vector2(0, 140), 140.0, color, 0.28)
	var targets: Array = []
	for enemy in _enemies():
		if _dist(enemy, origin) <= radius:
			targets.append(enemy)
	if targets.is_empty():
		return
	# bounty_hunter_b 连环标记：chain 优先选有 mark 的目标（按距离再按标记时间倒序）
	if sig_kind == "chain_mark_jump":
		targets.sort_custom(func(a, b):
			var ma := float(a.get("mark_left") or 0.0)
			var mb := float(b.get("mark_left") or 0.0)
			if ma > 0.0 and mb <= 0.0: return true
			if ma <= 0.0 and mb > 0.0: return false
			return _dist(a, origin) < _dist(b, origin)
		)
	else:
		targets.sort_custom(func(a, b): return _dist(a, origin) < _dist(b, origin))
	var cap_count := count
	if sig_kind == "chain_master":
		cap_count = mini(count + 2, int(sig.get("max_jumps", 6)))
	var limit := mini(cap_count, targets.size())
	# 链式闪电：起点 origin 依次连接到每个目标
	var flash_points := PackedVector2Array()
	flash_points.append(origin)
	var cdata = caster.get("character_data") if caster != null else null
	var dmg_per_jump := float(sig.get("damage_per_jump", 0.0))
	if sig_kind == "chain_master":
		dmg_per_jump = float(sig.get("damage_per_jump", 0.15))
	for i in limit:
		var tp := (targets[i] as Node2D).global_position
		flash_points.append(tp)
		var dmg_mult := 1.0 + float(i) * dmg_per_jump
		_apply_damage(caster, targets[i], int(round(float(damage) * dmg_mult)), is_magic, level)
		# hacker_c 共生：chain 每次命中 +20MP
		if sig_kind == "chain_symbiosis" and cdata != null:
			cdata.restore_mp(int(sig.get("mp_per_hit", 20)))
	SkillVfx.spawn_chain_lightning(level, flash_points, color)
	# 每个被连接目标处画一个小爆点；融合技在链末端追加元素爆发
	for i in flash_points.size():
		SkillVfx.spawn_impact(level, flash_points[i], "chain", color)
	if not fusion_kw.is_empty():
		_apply_element(caster, fusion_kw, fusion_color, flash_points[flash_points.size() - 1],
			maxf(110.0, radius * 0.6), damage, is_magic, level)


static func _aoe_zone(caster, pos: Vector2, radius: float, damage: int, is_magic: bool, delay: float, color: Color, level: Node,
		fusion_kw: Dictionary = {}, fusion_color: Color = Color.WHITE,
		sig_kind: String = "", sig: Dictionary = {}) -> void:
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
	var any := false
	for enemy in _enemies():
		if _dist(enemy, pos) <= radius:
			_apply_damage(caster, enemy, damage, is_magic, level)
			any = true
	if not fusion_kw.is_empty():
		_apply_element(caster, fusion_kw, fusion_color, pos, radius, damage, is_magic, level)
	if any and ScreenShake and ScreenShake.has_method("heavy"):
		ScreenShake.heavy()


static func _dash_strike(caster, dir: Vector2, distance: float, radius: float, damage: int, is_magic: bool, color: Color, level: Node) -> void:
	caster.global_position += dir.normalized() * distance
	var pos: Vector2 = caster.global_position
	SkillVfx.spawn_sword_arc(level, pos, dir, color, radius * 1.4)
	SkillVfx.spawn_shockwave(level, pos, radius * 0.8, color, 0.25)
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

# —— 辅助：飞粒子（起点/颜色/大小/目标位移/存活秒）——
static func _spawn_particle(level: Node, from: Vector2, col: Color, size: float, delta: Vector2, life: float) -> void:
	if level == null:
		return
	var p := ColorRect.new()
	p.color = col
	p.size = Vector2(size, size)
	p.global_position = from
	p.z_index = 60
	level.add_child(p)
	var target := from + delta
	var tw := p.create_tween()
	tw.set_parallel(true)
	tw.tween_property(p, "global_position", target, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "modulate:a", 0.0, life * 0.6).set_delay(life * 0.3)
	tw.chain().tween_callback(p.queue_free)


static func _apply_damage(caster, enemy, damage: int, is_magic: bool, level: Node,
		is_crit: bool = false, damage_element: String = "physical") -> int:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return 0
	var scaled := damage
	# ========== 元素克制：per-enemy 计算 ==========
	var enemy_element: String = ""
	var element_mult := 1.0
	var mods_v: Variant = enemy.get("elemental_mods")
	var mods: Dictionary = {}
	if mods_v != null and mods_v is Dictionary:
		mods = mods_v
	var pe_v: Variant = enemy.get("primary_element")
	if pe_v != null:
		enemy_element = str(pe_v)
	if enemy_element != "" and enemy_element != "none":
		if mods.has(damage_element):
			element_mult = float(mods[damage_element])
		else:
			element_mult = ElementKeeper.multiplier(enemy_element, damage_element)
	# 同元素物理 vs 物理 特殊处理（物理生物对物理伤害没有额外免疫）
	if enemy_element == "physical" and damage_element == "physical":
		element_mult = 1.0
	scaled = int(round(float(scaled) * element_mult))
	# ========== 克制反馈文字 ==========
	var feedback_text: String = ""
	var feedback_color: Color = Color.WHITE
	if element_mult <= 0.01:
		feedback_text = "免疫!"
		feedback_color = Color(0.6, 0.6, 0.8)
	elif element_mult <= 0.5:
		feedback_text = "抵抗"
		feedback_color = Color(0.5, 0.85, 1.0)
	elif element_mult >= 1.5:
		feedback_text = "克制!"
		feedback_color = Color(1.0, 0.85, 0.3)
	elif element_mult >= 1.3:
		feedback_text = "微克"
		feedback_color = Color(1.0, 0.7, 0.3)
	if feedback_text != "" and level != null and enemy is Node2D:
		DamageNumber.spawn(level, (enemy as Node2D).global_position + Vector2(0, -44), 0, false, false, feedback_text, feedback_color)
	if element_mult <= 0.01:
		# 完全免疫：不往下走了
		DamageNumber.spawn(level, (enemy as Node2D).global_position + Vector2(0, -26), 0, false)
		return 0
	# ========== signature 命中修正（被克制后再叠一层）==========
	if caster != null:
		var cdata = caster.get("character_data")
		if cdata != null and cdata.has_method("get_execute_bonus"):
			var execute_bonus := float(cdata.get_execute_bonus())
			if execute_bonus > 0.0:
				var stunned: Variant = enemy.get("stun_left")
				var slowed: Variant = enemy.get("slow_left")
				var controlled := (stunned != null and float(stunned) > 0.0) or (slowed != null and float(slowed) > 0.0)
				if controlled:
					scaled = int(round(float(scaled) * (1.0 + execute_bonus)))
		# —— signature 命中修正 ——
		if cdata != null and cdata.has_method("get_signature"):
			var sig: Dictionary = cdata.get_signature()
			var sk := str(sig.get("kind", ""))
			# mage_a 燃尽：对已被标记（灼烧/中毒）目标 +30% 伤害
			if sk == "burn_amplify":
				var mark_l: Variant = enemy.get("mark_left")
				if mark_l != null and float(mark_l) > 0.0:
					scaled = int(round(float(scaled) * float(sig.get("multiplier", 1.30))))
	var final_damage: int = enemy.take_damage(maxi(1, scaled), is_magic, caster)
	# —— signature 命中后效果 ——
	if caster != null:
		var cdata2 = caster.get("character_data")
		if cdata2 != null and cdata2.has_method("get_signature"):
			var sig2: Dictionary = cdata2.get_signature()
			var sk2 := str(sig2.get("kind", ""))
			# death_knight_a 饮血：伤害 15% 吸血
			if sk2 == "blood_drain":
				cdata2.heal(int(round(float(final_damage) * float(sig2.get("lifesteal_ratio", 0.15)))))
			# qi_adept_a 以柔克刚：攻击同时回血 = 伤害 ×8%
			if sk2 == "heal_on_hit":
				cdata2.heal(int(round(float(final_damage) * float(sig2.get("heal_per_hit", 0.08)))))
			# sniper_a 致命一击：暴击 +40%、暴击伤害 ×2.5（如果这次是暴击，再额外加）
			if sk2 == "deadly_shot" and is_crit:
				# 简化：sniper 已经在 cast 里 +1.4，如果这里也触发会叠加太多。跳过。
				pass
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
			SkillVfx.spawn_muzzle_flash(level, origin, color, 0.0)
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
			SkillVfx.spawn_muzzle_flash(level, origin, color, 0.0)


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
		is_magic: bool, color: Color, level: Node, deploy_pos: Vector2 = Vector2.ZERO,
		fusion_kw: Dictionary = {}, fusion_color: Color = Color.WHITE) -> void:
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
		device.fusion_kw = fusion_kw
		device.fusion_color = fusion_color
		device.global_position = origin
		if level == null:
			push_warning("SkillExecutor._deployable: level is null, caster=%s" % str(caster))
		else:
			level.add_child(device)
		SkillVfx.spawn_impact(level, origin, "deploy", color)


# ---------- 召唤（材料消耗：尸体/残骸） ----------
static func _summon(caster, skill: Dictionary, origin: Vector2, damage: int,
		is_magic: bool, color: Color, level: Node) -> void:
	var summon_bonus := 0.0
	var cdata = caster.get("character_data")
	if cdata != null and cdata.has_method("get_summon_bonus"):
		summon_bonus = float(cdata.get_summon_bonus())

	# —— 材料系统：尝试消耗附近的尸体，不同尸体→不同召唤物 ——
	var corpses_nearby: Array = []
	var corpse_search_radius := 220.0
	if level != null and caster is Node2D:
		for node in level.get_children():
			if node.has_method("is_valid") and node.get("corpse_type") != null and node.get("harvestable"):
				var d := (caster as Node2D).global_position.distance_to((node as Node2D).global_position)
				if d <= corpse_search_radius:
					corpses_nearby.append(node)

	var base_count := maxi(1, int(skill.get("count", 1)))
	damage = int(round(float(damage) * (1.0 + summon_bonus)))

	# 没有尸体 → 只能召唤最弱的"魂灵"（1 只普通亡灵）
	if corpses_nearby.is_empty():
		var default_count := 1 if summon_bonus < 0.2 else 2
		for i in default_count:
			_create_minion(caster, skill, origin, damage, is_magic, color, level, i, "ghost")
		EventBus.notify("附近无尸体，召唤 %d 只幽魂" % default_count)
		return

	# 有尸体 → 按尸体数量+类型召唤（每消耗 1 具尸体召唤 1 个专属亡灵）
	var summon_total := mini(base_count + corpses_nearby.size() / 2, corpses_nearby.size())
	var consumed := 0
	var idx := 0
	for corpse in corpses_nearby:
		if consumed >= summon_total:
			break
		var ct: int = int(corpse.get("corpse_type"))
		_create_minion(caster, skill, origin, damage, is_magic, color, level, idx, ct)
		corpse.harvestable = false
		var tw: Tween = corpse.create_tween()
		tw.tween_property(corpse, "modulate:a", 0.0, 0.3).set_delay(0.05)
		tw.tween_callback(corpse.queue_free)
		idx += 1
		consumed += 1

	EventBus.notify("消耗 %d 具尸体，召唤 %d 只亡灵" % [consumed, consumed])


# —— 创建具体类型的召唤物（不同尸体 → 不同属性）——
static func _create_minion(caster, skill: Dictionary, origin: Vector2, base_damage: int,
		is_magic: bool, color: Color, level: Node, idx: int, corpse_type) -> void:
	if level == null:
		return
	var ct := int(corpse_type) if not (corpse_type is String) else -1
	var minion = preload("res://scripts/combat/summoned_minion.gd").new()

	# 默认值（魂灵）
	var minion_color := color
	var move_speed := float(skill.get("speed", 120.0))
	var attack_range := float(skill.get("attack_range", 42.0))
	var minion_damage := base_damage
	var special_tag: String = ""
	var tag_name: String = "魂灵"

	match ct:
		# —— 骸骨 → 骷髅弓手（远程、穿透箭）——
		Corpse.CorpseType.SKELETON:
			minion_color = Color(0.9, 0.85, 0.75)
			move_speed = 130.0
			attack_range = 160.0
			minion_damage = int(round(float(base_damage) * 1.2))
			special_tag = "skeleton_archer"
			tag_name = "骷髅弓手"
		# —— 腐肉 → 丧尸（近战坦克、慢速、厚血）——
		Corpse.CorpseType.ZOMBIE:
			minion_color = Color(0.5, 0.7, 0.4)
			move_speed = 70.0
			attack_range = 36.0
			minion_damage = int(round(float(base_damage) * 1.4))
			special_tag = "zombie_tank"
			tag_name = "丧尸坦克"
		# —— 岩浆 → 火焰精灵（远程火球、自爆）——
		Corpse.CorpseType.ELEMENTAL_FIRE:
			minion_color = Color(1.0, 0.4, 0.15)
			move_speed = 100.0
			attack_range = 180.0
			minion_damage = int(round(float(base_damage) * 1.35))
			special_tag = "fire_sprite"
			tag_name = "火焰精灵"
			is_magic = true
		# —— 粘液 → 水元素（减速+范围伤害）——
		Corpse.CorpseType.SLIME:
			minion_color = Color(0.5, 0.9, 0.6)
			move_speed = 90.0
			attack_range = 80.0
			minion_damage = int(round(float(base_damage) * 1.0))
			special_tag = "water_slime"
			tag_name = "水元素"
		# —— 水元素 → 雷电精灵（chain 闪电）——
		Corpse.CorpseType.ELEMENTAL_WATER:
			minion_color = Color(0.6, 0.85, 1.0)
			move_speed = 110.0
			attack_range = 200.0
			minion_damage = int(round(float(base_damage) * 1.3))
			special_tag = "thunder_sprite"
			tag_name = "雷电精灵"
			is_magic = true
		# —— 机械残骸 → 机械幽灵（chain 闪电 + 远程激光）——
		Corpse.CorpseType.MECH:
			minion_color = Color(0.65, 0.65, 0.75)
			move_speed = 120.0
			attack_range = 220.0
			minion_damage = int(round(float(base_damage) * 1.25))
			special_tag = "mech_ghost"
			tag_name = "机械幽灵"
			is_magic = true
		# —— 幽魂残片 → 暗影刺客（隐身+暴击高）——
		Corpse.CorpseType.GHOST:
			minion_color = Color(0.7, 0.7, 1.0)
			move_speed = 160.0
			attack_range = 34.0
			minion_damage = int(round(float(base_damage) * 1.5))
			special_tag = "shadow_assassin"
			tag_name = "暗影刺客"
		# —— 巨兽残骸 → 巨型亡灵（AOE、击退）——
		Corpse.CorpseType.OGRE:
			minion_color = Color(0.7, 0.45, 0.3)
			move_speed = 80.0
			attack_range = 56.0
			minion_damage = int(round(float(base_damage) * 2.0))
			special_tag = "ogre_bone"
			tag_name = "巨型亡灵"
		_:
			pass

	var base_pos: Vector2 = origin + Vector2(cos(TAU * float(idx) / 4.0), sin(TAU * float(idx) / 4.0)) * 30.0

	var default_interval := float(skill.get("interval")) if skill.has("interval") else 1.0
	if special_tag == "shadow_assassin":
		default_interval = 0.6

	minion.lifetime = float(skill.get("duration", 12.0))
	minion.damage = minion_damage
	minion.is_magic = is_magic
	minion.move_speed = move_speed
	minion.attack_range = attack_range
	minion.attack_interval = default_interval
	minion.detect_range = float(skill.get("detect_range", 420.0))
	minion.source = caster
	minion.color = minion_color
	minion.body_scale = float(skill.get("scale", 1.0))
	minion.special_ability = special_tag
	level.add_child(minion)
	minion.global_position = base_pos
	SkillVfx.spawn_fusion_release(level, minion.global_position, minion_color, Color.WHITE, Vector2.RIGHT)


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
	SkillVfx.spawn_burst(level, mark_target.global_position, 36.0, color, 0.45)
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
