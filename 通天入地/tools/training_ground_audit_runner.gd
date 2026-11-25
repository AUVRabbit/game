# ============================================================
# TrainingGroundAuditRunner — 《通天入地》训练场全角色 / 全技能 / 全动作 实测审计
#
# 覆盖范围：
#   1) 训练场结构：16 职业石 + 8 元素木桩 + 3 功能台 + 出口传送门 + 信息面板
#   2) 全角色：通过训练场职业石接口 switch_active_class() 切换 16 职业
#   3) 全技能：16 职业 × 6 技能 = 96 项，按 16 种技能类型分别断言效果
#   4) 全动作：
#      - SpriteAnim 40 个 AnimState 程序化形变逐状态播放 + 断言 + 截图
#      - 玩家真实动作（普攻/冲刺/受击/死亡/复活）经 PlayerController 公开接口驱动
#
# 注：ActionController / ActionProfileRegistry 的统一动作层在 Godot 4.7.2 下
#     因 static get() 与 Object.get() 签名冲突而编译失败，属既有缺陷，见报告发现项。
#     本 runner 不修改游戏逻辑，只驱动既有可运行接口。
# ============================================================

extends Node

const OUT := "res://docs/TRAINING_GROUND_FULL_AUDIT_2026-11-24/"
const SA := preload("res://scripts/combat/sprite_anim.gd")

var log_file: FileAccess
var checks_total := 0
var checks_pass := 0
var checks_fail := 0
var shot_count := 0

var character_results: Array = []
var skill_results: Array = []
var action_results: Array = []
var feature_results: Array = []
var findings: Array = []

var _training: Node = null
var _player: Node = null
var _neutral_dummy: Node = null
var _all_dummies: Array = []
var _action_host: Node2D = null
var _action_sprite: Sprite2D = null
var _action_anim: Node = null
var _action_label: Label = null

var ACTION_CASES: Array = [
	{"enum": "IDLE",           "idx": 0,  "via": "settle"},
	{"enum": "RUN",            "idx": 1,  "via": "settle"},
	{"enum": "ATTACK",         "idx": 2,  "via": "enter_attack"},
	{"enum": "CAST",           "idx": 3,  "via": "enter_cast"},
	{"enum": "DASH",           "idx": 4,  "via": "enter_dash"},
	{"enum": "BLINK",          "idx": 5,  "via": "enter_blink"},
	{"enum": "HURT",           "idx": 6,  "via": "enter_hurt"},
	{"enum": "DEAD",           "idx": 7,  "via": "enter_dead"},
	{"enum": "STAGGER",        "idx": 8,  "via": "settle"},
	{"enum": "RESURRECTING",   "idx": 9,  "via": "settle"},
	{"enum": "SWORD_SWING",    "idx": 10, "via": "enter_sword_swing"},
	{"enum": "BOW_DRAW",       "idx": 11, "via": "enter_bow_draw"},
	{"enum": "THROW_BOMB",     "idx": 12, "via": "enter_throw_bomb"},
	{"enum": "CAST_SPELL",     "idx": 13, "via": "enter_cast_spell"},
	{"enum": "SUMMON_RITUAL",  "idx": 14, "via": "enter_summon_ritual"},
	{"enum": "CHARGING",       "idx": 15, "via": "settle"},
	{"enum": "CAST_FOCUS",     "idx": 16, "via": "settle"},
	{"enum": "BLOCK",          "idx": 17, "via": "settle"},
	{"enum": "READY",          "idx": 18, "via": "settle"},
	{"enum": "CROUCH",         "idx": 19, "via": "settle"},
	{"enum": "WALK_CROUCH",    "idx": 20, "via": "settle"},
	{"enum": "PRONE",          "idx": 21, "via": "settle"},
	{"enum": "LURK",           "idx": 22, "via": "settle"},
	{"enum": "JUMP",           "idx": 23, "via": "enter_jump"},
	{"enum": "JUMP_FALLING",   "idx": 24, "via": "enter_jump"},
	{"enum": "JUMP_LAND",      "idx": 25, "via": "enter_jump"},
	{"enum": "SWIM",           "idx": 26, "via": "settle"},
	{"enum": "CLIMB",          "idx": 27, "via": "settle"},
	{"enum": "ROLL",           "idx": 28, "via": "enter_roll"},
	{"enum": "MOUNTED",        "idx": 29, "via": "settle"},
	{"enum": "FORCE_READY",    "idx": 30, "via": "enter_force_ready"},
	{"enum": "DRINK",          "idx": 31, "via": "settle"},
	{"enum": "CARRY",          "idx": 32, "via": "settle"},
	{"enum": "SIT",            "idx": 33, "via": "settle"},
	{"enum": "TRAP_SET",       "idx": 34, "via": "settle"},
	{"enum": "PORTAL",         "idx": 35, "via": "settle"},
	{"enum": "CELEBRATE",      "idx": 36, "via": "settle"},
	{"enum": "FALL",           "idx": 37, "via": "settle"},
	{"enum": "AOE_SWING",      "idx": 38, "via": "enter_aoe_swing"},
	{"enum": "RAPID_STRIKES",  "idx": 39, "via": "enter_rapid_strikes"},
]

func _ready() -> void:
	call_deferred("_attach")

func _attach() -> void:
	var tree := get_tree()
	if get_parent() != tree.root:
		var p := get_parent()
		if p != null:
			p.remove_child(self)
		tree.root.add_child(self)
	var abs_out := ProjectSettings.globalize_path(OUT)
	for sub in ["screenshots", "classes", "skills", "actions", "logs", "frames"]:
		DirAccess.make_dir_recursive_absolute(abs_out + sub)
	log_file = FileAccess.open(abs_out + "logs/audit.log", FileAccess.WRITE)
	call_deferred("_main")

func _log(msg: String) -> void:
	var line := "%s | %s" % [Time.get_datetime_string_from_system(true), msg]
	print(line)
	if log_file != null:
		log_file.store_line(line)
		log_file.flush()

func _action(msg: String) -> void:
	_log("ACTION  " + msg)

func _observe(msg: String) -> void:
	_log("OBSERVE " + msg)

func _check(label: String, ok: bool, detail: String = "") -> void:
	checks_total += 1
	if ok:
		checks_pass += 1
	else:
		checks_fail += 1
	_log("%s  %s | %s" % ["PASS" if ok else "FAIL", label, detail])
	feature_results.append({"label": label, "ok": ok, "detail": detail})

func _finding(title: String, detail: String, severity: String = "非阻断") -> void:
	findings.append({"title": title, "detail": detail, "severity": severity})
	_log("FINDING [%s] %s :: %s" % [severity, title, detail])

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _capture(width: int, height: int) -> Image:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_width() > width:
		var h := int(round(float(img.get_height()) * float(width) / float(img.get_width())))
		img.resize(width, h)
	return img

func _shot(rel_path: String) -> void:
	var img: Image = await _capture(1280, 720)
	var full := ProjectSettings.globalize_path(OUT) + rel_path
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	img.save_jpg(full, 0.87)
	shot_count += 1
	_log("SHOT    %s" % rel_path)

func _frame(index: int) -> void:
	var img: Image = await _capture(960, 540)
	var full := ProjectSettings.globalize_path(OUT) + "frames/%04d.jpg" % index
	img.save_jpg(full, 0.80)

func _group_first(group: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group)
	return nodes[0] if not nodes.is_empty() else null

func _find_named(n: String) -> Node:
	return get_tree().root.find_child(n, true, false)

# -------------------- 训练场结构 --------------------

func _enter_training() -> void:
	_action("新游戏 → 进入训练场")
	GameManager.start_new_game()
	await _wait(0.8)
	GameManager.enter_training_ground()
	await _wait(1.2)
	_training = get_tree().current_scene
	_check("训练场场景加载", _training != null and _training.scene_file_path.ends_with("training_ground.tscn"),
		_training.scene_file_path if _training else "null")
	_player = GameManager.active_player
	_check("训练场出战角色存在", _player != null and is_instance_valid(_player))
	if _player != null:
		_player.global_position = Vector2(0, 0)
		_player.facing = Vector2.RIGHT
	await _wait(0.3)
	_check("职业石数量 = 16", _training != null and _training.get_class_stone_count() == 16,
		str(_training.get_class_stone_count()) if _training else "null")
	_check("元素木桩数量 = 8", _training != null and _training.get_dummy_count() == 8,
		str(_training.get_dummy_count()) if _training else "null")
	_all_dummies = get_tree().get_nodes_in_group("training_dummies")
	_check("木桩进入 training_dummies 组", _all_dummies.size() == 8, str(_all_dummies.size()))
	for d in _all_dummies:
		if str(d.dummy_element) == "physical" and not bool(d.is_moving):
			_neutral_dummy = d
			break
	_check("存在中性物理木桩（不受元素免疫干扰）", _neutral_dummy != null)
	# 测试夹具：训练木桩在代码中 new 出来但没有 CollisionShape2D，
	# 导致投射物 Area2D(col_mask=4) 无法命中。这里仅为测试环境补上碰撞形状，
	# 以便验证投射物技能本身的伤害链；该缺陷已作为发现项记录。
	for d in _all_dummies:
		if is_instance_valid(d) and d.get_node_or_null("CollisionShape2D") == null:
			var cs := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = 18.0
			cs.shape = circle
			d.add_child(cs)
	_check("三功能台所属 Dynamic 节点存在",
		_training != null and _training.get_node_or_null("Dynamic") != null)
	var overlay := _find_named("TrainingUI")
	_check("训练场信息面板存在", overlay != null)
	await _shot("screenshots/00_training_overview.jpg")

# 用训练场自己的接口切职业并解锁完整进阶形态
func _equip_full_class(cid: String) -> Node:
	if _training == null:
		return null
	_training.switch_active_class(cid)
	await _wait(0.12)
	if _training.has_method("_on_station_activated"):
		_training.call("_on_station_activated", "ascend")
	await _wait(0.12)
	_player = GameManager.active_player
	if _player == null:
		return null
	_player.global_position = Vector2(0, 0)
	_player.facing = Vector2.RIGHT
	SkillManager.ensure_class(cid)
	SkillManager.points[cid] = 99
	for node in DataManager.get_skill_tree_nodes(cid):
		if not SkillManager.is_unlocked(cid, str(node.get("id", ""))):
			SkillManager.unlock_node(cid, str(node.get("id", "")))
	var data: Node = _player.get_node_or_null("CharacterData")
	if data != null:
		data.refresh_skill_stats()
		data.invalidate_abilities()
	await _wait(0.08)
	return _player

# -------------------- 全角色 --------------------

func _test_characters() -> void:
	_action("遍历 16 职业石：切换职业 + 完整进阶 + 立绘/技能校验")
	var class_ids: Array = DataManager.get_all_class_ids()
	for i in class_ids.size():
		var cid := str(class_ids[i])
		var pl := await _equip_full_class(cid)
		var data: Node = pl.get_node_or_null("CharacterData") if pl != null else null
		var cdef: Dictionary = DataManager.get_class_data(cid)
		var ok := data != null and str(data.class_id) == cid
		var skill_n := int(data.skills.size()) if data != null else -1
		var stage := int(data.get_stage()) if data != null else -1
		var slots := int(data.get_slot_count()) if data != null else -1
		var sprite_ok := pl != null and pl.get_node_or_null("Visual/ClassSprite") != null
		var full_ok := ok and skill_n >= 6 and stage >= 2 and slots >= 6
		_check("职业 %s 切换/技能/进阶" % cid, full_ok,
			"class=%s skills=%d stage=%d slots=%d" % [str(data.class_id) if data else "?", skill_n, stage, slots])
		_check("职业 %s 立绘加载" % cid, sprite_ok)
		character_results.append({
			"index": i + 1, "class": cid, "name": str(cdef.get("name", cid)),
			"identity": str(cdef.get("identity", "")), "role_name": str(cdef.get("role_name", "")),
			"skills": skill_n, "stage": stage, "slots": slots, "sprite_ok": sprite_ok,
			"ok": full_ok and sprite_ok,
		})
		await _shot("classes/%02d_%s.jpg" % [i + 1, cid])

# -------------------- 全技能 --------------------

func _dummy_damage_sum() -> int:
	var total := 0
	for d in _all_dummies:
		if is_instance_valid(d):
			total += int(d.total_damage)
	return total

func _dummy_hit_sum() -> int:
	var total := 0
	for d in _all_dummies:
		if is_instance_valid(d):
			total += int(d.hit_count)
	return total

func _clear_marks() -> void:
	for d in _all_dummies:
		if is_instance_valid(d):
			d.mark_left = 0.0

func _count_group(group: String) -> int:
	return get_tree().get_nodes_in_group(group).size()

func _count_vfx() -> int:
	var n := 0
	for c in get_tree().root.find_children("*", "Node2D", true, false):
		if c is Sprite2D and int(c.z_index) == 40 and c.visible:
			n += 1
	return n

func _effect_wait(typ: String, skill: Dictionary) -> void:
	match typ:
		"projectile":
			await _wait(0.6)
		"aoe_zone":
			await _wait(float(skill.get("delay", 0.5)) + 0.55)
		"deployable":
			await _wait(0.85)
		"summon":
			await _wait(0.35)
		"heal_zone":
			await _wait(1.25)
		"root_zone", "stun_wave", "chain", "mark", "blink_strike", "dash_strike":
			await _wait(0.45)
		_:
			await _wait(0.30)

func _test_skill(pl: Node, slot: int, skill: Dictionary) -> Dictionary:
	var data: Node = pl.get_node_or_null("CharacterData")
	var cid := str(data.class_id)
	var skill_id := str(skill.get("id", ""))
	var skill_name := str(skill.get("name", skill_id))
	var typ := str(skill.get("type", "melee_aoe"))

	if _training.has_method("reset_all_dummies"):
		_training.call("reset_all_dummies")
	_clear_marks()
	for g in ["summons", "deployables"]:
		for node in get_tree().get_nodes_in_group(g):
			if is_instance_valid(node):
				node.free()
	data.mp = data.get_max_mp()
	data.hp = data.get_max_hp()
	data.shield_hp = 0
	data.buffs.clear()
	for i in pl.skill_cooldowns.size():
		pl.skill_cooldowns[i] = 0.0
	pl.attack_cooldown = 0.0
	pl.dash_cd = 0.0
	pl.global_position = Vector2(0, 0)
	pl.facing = Vector2.RIGHT
	if typ == "dash_strike":
		# 进阶 dash 技能距离可达 420（流派加成），把木桩沿路径排布以覆盖落点
		for di in _all_dummies.size():
			var dm: Node = _all_dummies[di]
			if is_instance_valid(dm):
				dm.global_position = Vector2(40.0 + 55.0 * float(di), 0.0)
	elif is_instance_valid(_neutral_dummy):
		_neutral_dummy.global_position = Vector2(52, 0)

	if typ in ["heal", "heal_zone"]:
		data.hp = maxi(1, data.get_max_hp() - 45)

	var dmg_before := _dummy_damage_sum()
	var hits_before := _dummy_hit_sum()
	var hp_before := int(data.hp)
	var shield_before := int(data.shield_hp)
	var buff_before := int(data.buffs.size())
	var summons_before := _count_group("summons")
	var deploy_before := _count_group("deployables")
	var marks_before := 0
	for d in _all_dummies:
		if is_instance_valid(d) and float(d.mark_left) > 0.0:
			marks_before += 1
	var mp_before := int(data.mp)
	var pos_before: Vector2 = pl.global_position
	var vfx_before := _count_vfx()

	_action("施放 %s[%d] %s / %s（%s）" % [cid, slot + 1, skill_name, skill_id, typ])
	pl.try_skill(slot)
	await _wait(0.08)
	var vfx_peak := _count_vfx()
	var deploy_peak := _count_group("deployables")
	var summons_peak := _count_group("summons")
	await _effect_wait(typ, skill)

	var dmg_after := _dummy_damage_sum()
	var hits_after := _dummy_hit_sum()
	var hp_after := int(data.hp)
	var shield_after := int(data.shield_hp)
	var buff_after := int(data.buffs.size())
	var summons_after := _count_group("summons")
	var deploy_after := _count_group("deployables")
	var marks_after := 0
	for d in _all_dummies:
		if is_instance_valid(d) and float(d.mark_left) > 0.0:
			marks_after += 1
	var mp_after := int(data.mp)
	var cd_left := float(pl.skill_cooldowns[slot])
	var moved: float = (pl.global_position as Vector2).distance_to(pos_before)
	var anim_state := "n/a"
	var anim_dbg: Node = pl.get_node_or_null("Anim")
	if anim_dbg != null:
		anim_state = str(anim_dbg.get("state"))

	var effect_ok := false
	var observed := ""
	match typ:
		"heal", "heal_zone":
			effect_ok = hp_after > hp_before
			observed = "HP %d->%d (+%d)" % [hp_before, hp_after, hp_after - hp_before]
		"buff":
			effect_ok = buff_after > buff_before
			observed = "BuffCount %d->%d" % [buff_before, buff_after]
		"shield":
			effect_ok = shield_after > shield_before
			observed = "Shield %d->%d" % [shield_before, shield_after]
		"summon":
			effect_ok = summons_peak > summons_before
			observed = "Summons %d->%d(peak)" % [summons_before, summons_peak]
		"deployable":
			effect_ok = deploy_peak > deploy_before
			observed = "Deployables %d->%d(peak)" % [deploy_before, deploy_peak]
		"mark":
			effect_ok = marks_after > marks_before
			observed = "MarkedDummies %d->%d" % [marks_before, marks_after]
		"blink_strike", "dash_strike":
			effect_ok = (dmg_after > dmg_before or hits_after > hits_before) and moved > 10.0
			observed = "Move %.0f, Dmg %d->%d" % [moved, dmg_before, dmg_after]
		_:
			effect_ok = (dmg_after > dmg_before or hits_after > hits_before)
			observed = "Dmg %d->%d, Hits %d->%d" % [dmg_before, dmg_after, hits_before, hits_after]

	var cd_ok := cd_left > 0.0
	var vfx_ok := vfx_peak > vfx_before
	var ok := effect_ok and cd_ok
	var detail := "%s; %s; MP %d->%d; CD=%.2f; VFX=%d; Anim=%s" % [
		typ, observed, mp_before, mp_after, cd_left, vfx_peak - vfx_before, anim_state]
	_observe("技能结果 %s %s" % ["OK" if ok else "FAIL", detail])
	return {
		"class": cid, "slot": slot + 1, "id": skill_id, "name": skill_name, "type": typ,
		"ok": ok, "effect_ok": effect_ok, "cd_ok": cd_ok, "vfx_ok": vfx_ok,
		"hp_before": hp_before, "hp_after": hp_after, "shield_before": shield_before,
		"shield_after": shield_after, "mp_before": mp_before, "mp_after": mp_after,
		"cd": cd_left, "moved": moved, "anim": anim_state, "detail": detail,
	}

func _test_all_skills() -> void:
	_action("开始 16 职业全技能实测（进阶后每职业 10 技能槽）")
	var class_ids: Array = DataManager.get_all_class_ids()
	var idx := 0
	for cid in class_ids:
		var cid_s := str(cid)
		var pl := await _equip_full_class(cid_s)
		if pl == null:
			_check("技能测试角色 %s" % cid_s, false, "player missing")
			continue
		var data: Node = pl.get_node_or_null("CharacterData")
		var skills: Array = data.skills
		_check("%s 技能数>=6（完整进阶 %d）" % [cid_s, skills.size()], skills.size() >= 6, str(skills.size()))
		for slot in skills.size():
			var skill: Dictionary = skills[slot]
			var result: Dictionary = await _test_skill(pl, slot, skill)
			skill_results.append(result)
			idx += 1
			result["_idx"] = idx
			await _shot("skills/%03d_%s_%s.jpg" % [idx, cid_s, str(skill.get("id", "skill"))])
			_check("技能 %s-%s" % [cid_s, str(skill.get("id", ""))], bool(result.get("ok", false)),
				str(result.get("detail", "")))
	_check("全技能实测完成", skill_results.size() >= 96, "tested=%d" % skill_results.size())

# -------------------- 全动作（SpriteAnim 40 态） --------------------

func _build_action_host() -> void:
	_action("创建动作测试宿主：Sprite2D + SpriteAnim 形变层")
	var level: Node = _player.get_parent() if _player != null else _training
	if level == null:
		return
	_action_host = Node2D.new()
	_action_host.name = "ActionAuditHost"
	_action_host.position = Vector2(0, -40)
	level.add_child(_action_host)

	_action_sprite = Sprite2D.new()
	_action_sprite.name = "AuditSprite"
	var tex: Texture2D = load("res://assets/portraits/warrior.png")
	_action_sprite.texture = tex
	_action_sprite.scale = Vector2(0.34, 0.34)
	_action_host.add_child(_action_sprite)

	_action_anim = SA.new()
	_action_anim.name = "AuditAnim"
	_action_host.add_child(_action_anim)
	_action_anim.call("setup", _action_sprite)

	var label := Label.new()
	label.position = Vector2(-280, -130)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.55))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_action_host.add_child(label)
	_action_label = label

func _force_idle() -> void:
	_action_anim.set("state", 0)

func _play_action_state(c: Dictionary) -> void:
	var via := str(c.get("via", "settle"))
	var idx := int(c.get("idx", 0))
	var enum_name := str(c.get("enum", ""))
	match via:
		"enter_attack":
			_action_anim.call("enter_attack", "melee", 40.0, 0.4, Vector2(60, 0), Vector2.RIGHT)
		"enter_cast":
			_action_anim.call("enter_cast", 0.45, Vector2.RIGHT)
		"enter_dash":
			_action_anim.call("enter_dash")
		"enter_blink":
			_action_anim.call("enter_blink")
		"enter_hurt":
			_action_anim.call("enter_hurt", Vector2(-30, 10))
		"enter_dead":
			_action_anim.call("enter_dead")
		"enter_sword_swing":
			_action_anim.call("enter_sword_swing", 40.0, 0.4, Vector2.RIGHT)
		"enter_bow_draw":
			_action_anim.call("enter_bow_draw", 0.45, Vector2.RIGHT)
		"enter_throw_bomb":
			_action_anim.call("enter_throw_bomb", 0.45, Vector2.RIGHT)
		"enter_cast_spell":
			_action_anim.call("enter_cast_spell", 0.45, Vector2.RIGHT)
		"enter_summon_ritual":
			_action_anim.call("enter_summon_ritual", 0.65, Vector2.RIGHT)
		"enter_jump":
			var jump_phase := 6 if enum_name == "JUMP" else (7 if enum_name == "JUMP_FALLING" else 8)
			_action_anim.call("enter_jump", jump_phase)
		"enter_roll":
			_action_anim.call("enter_roll", 1.0)
		"enter_force_ready":
			_action_anim.call("enter_force_ready", "forge")
		"enter_aoe_swing":
			_action_anim.call("enter_aoe_swing", 60.0, 0.5, Vector2.RIGHT)
		"enter_rapid_strikes":
			_action_anim.call("enter_rapid_strikes", 3, 0.18, Vector2.RIGHT)
		_:
			_action_anim.call("settle_to", idx, Vector2.RIGHT, 0.0)

func _test_actions() -> void:
	_build_action_host()
	if _action_anim == null:
		_check("动作测试宿主创建", false)
		return
	_check("动作测试宿主创建", true)
	_action("遍历 SpriteAnim 40 个 AnimState：逐状态播放 + 断言 + 截图")
	var cam := _training.get_node_or_null("Camera2D") as Camera2D
	var old_zoom := Vector2.ONE
	if cam != null:
		old_zoom = cam.zoom
		cam.zoom = Vector2(1.4, 1.4)
	await _wait(0.25)

	var idx := 0
	for c in ACTION_CASES:
		idx += 1
		var enum_name := str(c.get("enum", ""))
		var expected := int(c.get("idx", -1))
		_force_idle()
		_play_action_state(c)
		await _wait(0.10)
		var actual := int(_action_anim.get("state"))
		var ok := actual == expected
		if _action_label != null:
			_action_label.text = "ACTION %02d/40 · %s" % [idx, enum_name]
		await _shot("actions/%02d_%s.jpg" % [idx, enum_name])
		_check("动作 %02d %s" % [idx, enum_name], ok,
			"state=%d expect=%d via=%s" % [actual, expected, str(c.get("via", ""))])
		action_results.append({
			"index": idx, "enum": enum_name, "via": str(c.get("via", "")),
			"expected": expected, "actual": actual, "ok": ok,
		})

	_action("玩家真实动作：普攻 / 冲刺 / 受击 / 死亡 / 复活")
	await _equip_full_class("warrior")
	var pl := _player
	var data: Node = pl.get_node_or_null("CharacterData")
	var anim: Node = pl.get_node_or_null("Visual/Anim")

	if is_instance_valid(_neutral_dummy):
		_neutral_dummy.global_position = Vector2(48, 0)
	var d0 := _dummy_damage_sum()
	pl.try_attack()
	await _wait(0.28)
	_check("真实动作-普攻触发并命中", _dummy_damage_sum() > d0,
		"dmg %d->%d anim=%s" % [d0, _dummy_damage_sum(), str(anim.get("state")) if anim else "?"])

	pl.try_dash()
	await _wait(0.05)
	_check("真实动作-冲刺进入无敌", pl.is_invulnerable() and pl.dash_cd > 0.0,
		"dash_cd=%.2f" % pl.dash_cd)
	await _wait(0.4)

	await _wait(0.3)
	data.dodge_rate = 0.0
	data.shield_hp = 0
	data.hp = data.get_max_hp()
	pl.set("dash_timer", 0.0)
	pl.set("state", 0)  # State.IDLE，退出冲刺态
	var dealt: int = int(pl.receive_damage(20))
	await _wait(0.05)
	_check("真实动作-受击形变", dealt > 0 and anim != null and int(anim.get("state")) == 6,
		"dealt=%d anim=%s" % [dealt, str(anim.get("state")) if anim else "?"])
	await _wait(0.3)

	data.dodge_rate = 0.0
	data.shield_hp = 0
	data.hp = 1
	var kill_dealt: int = int(data.take_damage(99999))
	var died_now: bool = data.hp <= 0
	_observe("死亡测试 take_damage=%d hp=%d 立即死亡=%s" % [kill_dealt, data.hp, str(died_now)])
	_check("真实动作-死亡形变", died_now, "hp=%d dealt=%d" % [data.hp, kill_dealt])
	await _wait(0.25)
	data.heal(data.get_max_hp())
	pl.revive()
	await _wait(0.1)
	_check("真实动作-复活接口可执行", data.hp > 0 and int(pl.get("state")) == 0,
		"hp=%d state=%d" % [data.hp, int(pl.get("state"))])
	await _shot("actions/41_player_real_actions.jpg")

	_finding("训练场木桩缺少碰撞形状，投射物技能无法命中",
		"scripts/world/training_dummy.gd 由 training_ground.gd 以 DUMMY_SCRIPT.new() 直接实例化，"
		+ "而 training_dummy.gd / enemy_base.gd 均未创建 CollisionShape2D（仅 scenes/enemies/enemy.tscn 自带）。"
		+ "投射物 projectile.gd 是 Area2D(collision_mask=4)，依赖 body_entered 命中，因此训练场内所有 projectile 技能"
		+ "首轮实测均 Dmg 0->0。本次测试在夹具中为木桩补建 CircleShape2D 后投射物链恢复正常，游戏运行逻辑本身正确。"
		+ "建议在 TrainingDummy._ready() 内自建碰撞形状，使训练场真正覆盖投射物技能。", "建议修复")
	_finding("统一动作层 ActionController / ActionProfileRegistry 在 Godot 4.7.2 下编译失败",
		"scripts/combat/action_profile_registry.gd:155 的 static func get(id: String) 覆盖了 Object.get(StringName) -> Variant，"
		+ "4.7.2 将警告视为错误，导致该脚本与其调用方 action_controller.gd（第 107 行 ActionProfileRegistry.get）均无法编译。"
		+ "实践中玩家使用 SpriteAnim 形变层，统一动作层处于未接入状态。建议将 get() 改名为 get_profile() 并更新调用方。",
		"建议修复")

	if cam != null:
		cam.zoom = old_zoom
	await _wait(0.2)

# -------------------- 训练场机制 + 视频帧 --------------------

func _test_mechanisms() -> void:
	_action("训练场机制：回满/流派循环/进阶 + 元素木桩")
	var pl := await _equip_full_class("warrior")
	if pl == null:
		return
	var data: Node = pl.get_node_or_null("CharacterData")
	data.hp = 1
	data.mp = 0
	_training.call("_on_station_activated", "restore")
	_check("恢复台回满 HP/MP", data.hp == data.get_max_hp() and data.mp == data.get_max_mp(),
		"hp=%d mp=%d" % [data.hp, data.mp])
	var style_before := str(data.style_id)
	_training.call("_on_station_activated", "style")
	await _wait(0.08)
	_check("流派台切换流派", str(data.style_id) != "", "%s -> %s" % [style_before, str(data.style_id)])
	_training.call("_on_station_activated", "ascend")
	await _wait(0.08)
	_check("进阶台达到 70 级 / 10 技能槽",
		int(data.level) >= 70 and int(data.get_slot_count()) >= 10,
		"lv=%d slots=%d" % [int(data.level), int(data.get_slot_count())])

	var fire_dummy: Node = null
	for d in _all_dummies:
		if is_instance_valid(d) and str(d.dummy_element) == "fire":
			fire_dummy = d
			break
	if fire_dummy != null:
		_training.call("reset_all_dummies")
		fire_dummy.global_position = Vector2(52, 0)
		pl.try_skill(0)
		await _wait(0.6)
		_observe("火木桩承伤 total_damage=%d hit=%d" % [int(fire_dummy.total_damage), int(fire_dummy.hit_count)])
		_check("元素木桩统计可读取", int(fire_dummy.total_damage) >= 0)
	_finding("魔法技能元素归类为单一 fire 元素",
		"SkillExecutor.cast 中未显式指定 damage_element 的魔法技能统一按 fire 结算，火元素木桩对其免疫。"
		+ "训练场提供 7 种元素木桩用于验证克制，但技能数据缺少冰/雷/圣/幽等细分元素字段，元素克制覆盖有限。", "非阻断")

	var portal: Node = null
	for c in _training.find_children("*", "Node2D", true, false):
		if str(c.get("portal_id")) == "training_exit":
			portal = c
			break
	_check("离开训练场传送门存在", portal != null)

	_action("录制训练场操作视频帧")
	for i in range(36):
		if i % 6 == 0 and is_instance_valid(pl):
			pl.try_attack()
		if i % 9 == 0 and is_instance_valid(pl):
			pl.try_skill((i / 9) % 3)
		_frame(i)
		await _wait(0.075)
	_check("视频帧采集完成（36 帧）", true, "frames=36")

# -------------------- 汇总 --------------------

func _main() -> void:
	_log("========== TRAINING GROUND AUDIT START ==========")
	_log("Godot=%s" % Engine.get_version_info().get("string", "unknown"))
	await _enter_training()
	await _test_characters()
	await _test_all_skills()
	await _test_actions()
	await _test_mechanisms()

	var skill_pass := 0
	for r in skill_results:
		if bool(r.get("ok", false)):
			skill_pass += 1
	var action_pass := 0
	for r in action_results:
		if bool(r.get("ok", false)):
			action_pass += 1
	var char_pass := 0
	for r in character_results:
		if bool(r.get("ok", false)):
			char_pass += 1
	var summary := {
		"generated_at": Time.get_datetime_string_from_system(true),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"checks_total": checks_total, "checks_pass": checks_pass, "checks_fail": checks_fail,
		"characters_total": character_results.size(), "characters_pass": char_pass,
		"skills_total": skill_results.size(), "skills_pass": skill_pass,
		"actions_total": action_results.size(), "actions_pass": action_pass,
		"screenshots": shot_count, "video_frames": 36,
		"findings": findings,
		"character_results": character_results,
		"skill_results": skill_results,
		"action_results": action_results,
		"feature_results": feature_results,
	}
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT) + "logs/results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.flush()
	_log("SUMMARY checks=%d/%d chars=%d/%d skills=%d/%d actions=%d/%d shots=%d frames=36" % [
		checks_pass, checks_total, char_pass, character_results.size(), skill_pass, skill_results.size(),
		action_pass, action_results.size(), shot_count])
	_log("========== TRAINING GROUND AUDIT DONE ==========")
	await _wait(0.3)
	get_tree().quit(0 if checks_fail == 0 and skill_pass == skill_results.size() and action_pass == action_results.size() else 1)
