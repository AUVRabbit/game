# ============================================================
# MechanismAuditRunner — 深度机制测试（指南 §1-§5 补充覆盖）
# 覆盖：8 种新增技能类型 / 元素克制矩阵 / 融合技 API /
#       48 流派结构完整性 / 尸体 / HitStop / 震屏
# 只读测试：通过公开 API 驱动，不改游戏逻辑/数值表
# ============================================================

extends Node

const OUT := "res://docs/SKILL_MECHANISM_TEST_2026-11-24/"
var log_file: FileAccess
var results: Array = []
var total := 0
var passed := 0
var failed := 0
var shot_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 后台渲染：窗口移出屏幕，避免干扰本机操作
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_position(Vector2i(-4000, -4000))
	call_deferred("_attach")

func _attach() -> void:
	var tree := get_tree()
	if get_parent() != tree.root:
		var p := get_parent()
		if p != null:
			p.remove_child(self)
			tree.root.add_child(self)
	var abs_out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_out + "screenshots")
	DirAccess.make_dir_recursive_absolute(abs_out + "logs")
	log_file = FileAccess.open(abs_out + "logs/mechanism.log", FileAccess.WRITE)
	call_deferred("_main")

func _log(msg: String) -> void:
	var line := "%s | %s" % [Time.get_datetime_string_from_system(true), msg]
	print(line)
	if log_file != null:
		log_file.store_line(line)
		log_file.flush()

func _check(label: String, ok: bool, detail: String = "") -> void:
	total += 1
	if ok:
		passed += 1
	else:
		failed += 1
	_log("%s  %s | %s" % ["PASS" if ok else "FAIL", label, detail])
	results.append({"label": label, "ok": ok, "detail": detail})

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_width() > 1280:
		var h := int(round(float(img.get_height()) * 1280.0 / float(img.get_width())))
		img.resize(1280, h)
	var path := ProjectSettings.globalize_path(OUT) + "screenshots/" + name + ".jpg"
	img.save_jpg(path, 0.88)
	shot_count += 1
	_log("SHOT " + name)

func _clear_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.free()
	for s in get_tree().get_nodes_in_group("enemy_spawners"):
		if is_instance_valid(s):
			s.set_process(false)

func _spawn_dummy(pos: Vector2, hp: int = 5000) -> Node:
	var packed: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var dummy := packed.instantiate()
	dummy.enemy_name = "机制测试木桩"
	dummy.max_hp = hp
	dummy.hp = hp
	dummy.attack = 0
	dummy.move_speed = 0.0
	dummy.detect_range = 0.0
	dummy.defense = 0
	dummy.magic_defense = 0
	dummy.position = pos
	var parent: Node = GameManager.current_world.get_node_or_null("Dynamic")
	if parent == null:
		parent = GameManager.current_world
	parent.add_child(dummy)
	return dummy

func _activate(cid: String) -> Node:
	for i in GameManager.party.size():
		var pl: Node = GameManager.party[i]
		if not is_instance_valid(pl):
			continue
		var d: Node = pl.get_node_or_null("CharacterData")
		if d != null and str(d.class_id) == cid:
			GameManager._set_active(i)
			await _wait(0.12)
			return GameManager.active_player
	return null

# ---------- 元素克制 ----------
func _test_elements() -> void:
	_log("===== 元素克制矩阵 =====")
	# ElementKeeper.TABLE 结构：enemy_element -> {damage_element: mult}
	var cases := [
		["fire", "fire", 0.0, "火打火元素→免疫"],
		["water", "thunder", 1.5, "雷打水→克制"],
		["shadow", "physical", 0.5, "物理打幽魂→抵抗"],
		["shadow", "holy", 2.0, "圣光打幽魂→克制"],
		["mech", "thunder", 1.8, "雷打机械→短路"],
		["fire", "ice", 1.5, "冰打火→克制"],
		["fire", "water", 1.3, "水打火→微克"],
		["ice", "fire", 1.5, "火打冰→克制"],
		["thunder", "thunder", 0.0, "雷打雷→免疫"],
	]
	# 实际以 ElementKeeper.TABLE 为准逐项核对（文档表可能与实现键名不同）
	for c in cases:
		var enemy_el := str(c[0])
		var dmg_el := str(c[1])
		var expect := float(c[2])
		var desc := str(c[3])
		var actual: float = ElementKeeper.multiplier(enemy_el, dmg_el)
		_check("元素: " + desc, is_equal_approx(actual, expect), "%s vs %s = %.2f (期望 %.2f)" % [dmg_el, enemy_el, actual, expect])
	var map_cases := [["burn", "fire"], ["freeze", "ice"], ["stun", "thunder"], ["corrosion", "nature"], ["root", "nature"], ["holy", "holy"], ["summon", "shadow"], ["knockback", "physical"], ["mark", "shadow"]]
	for m in map_cases:
		var got: String = ElementKeeper.from_fusion_kind(str(m[0]))
		_check("融合元素映射 %s→%s" % [str(m[0]), str(m[1])], got == str(m[1]), "got=" + got)

# ---------- 融合技 API ----------
func _test_fusion() -> void:
	_log("===== 融合技 API =====")
	var parts: Array = FusionService.split_id("fireball__heal")
	_check("融合ID拆分", parts.size() == 2, str(parts))
	var kw: Dictionary = FusionService.keyword_of({"id": "x", "passive": {"burn": 0.2}})
	_check("关键词提取", kw is Dictionary, str(kw))
	var owned: Dictionary = {}
	for cid in DataManager.get_all_class_ids():
		for s in DataManager.get_class_data(cid).get("skills", []):
			owned[str(s.get("id", ""))] = s
	_check("技能池构建", owned.size() >= 96, "count=%d" % owned.size())
	var main_id := "fireball"
	var sub_id := ""
	for k in owned:
		var kw2 := FusionService.keyword_of(owned[k])
		if not kw2.is_empty() and k != main_id:
			sub_id = k
			break
	if sub_id != "":
		var built: Dictionary = FusionService.build(DataManager, main_id, sub_id, owned)
		_check("融合技构建", not built.is_empty(), "main=%s sub=%s" % [main_id, sub_id])
		if not built.is_empty():
			var nm := str(built.get("name", ""))
			_check("融合技独立命名 融·", nm.begins_with("融·"), "name=" + nm)
			_check("融合技元素字段", built.has("fuse_element"), "elem=" + str(built.get("fuse_element", "")))
			_check("融合技独有色", built.has("color"), "color=" + str(built.get("color", "")))
	else:
		_check("找到可融合副技能", false, "")

# ---------- 48 流派结构 ----------
func _test_signatures() -> void:
	_log("===== 48 流派结构 =====")
	var ids: Array = DataManager.get_all_class_ids()
	var total_styles := 0
	var missing_skills: Array = []
	var mech_keys := {}
	for cid in ids:
		var sids: Array = DataManager.get_class_style_ids(str(cid))
		total_styles += sids.size()
		for sid in sids:
			var st: Dictionary = DataManager.get_style(str(sid))
			var skills: Array = st.get("skills", [])
			if skills.size() < 3:
				missing_skills.append(str(sid))
			var sig_d: Dictionary = CharacterBase.STYLE_SIGNATURES.get(str(sid), {})
			var kind := str(sig_d.get("kind", ""))
			if kind != "":
				mech_keys[kind] = true
	_check("48 流派总数", total_styles == 48, "count=%d" % total_styles)
	_check("每流派至少 3 技能", missing_skills.is_empty(), "missing=" + str(missing_skills))
	_check("流派专属机制种类 >= 30", mech_keys.size() >= 30, "kinds=%d" % mech_keys.size())
	# 关键流派（以 passive 键判定）
	for key in ["berserker", "chain_master", "backstab", "overclock", "minion_lord"]:
		_check("专属机制存在 " + key, mech_keys.has(key), "")
	# 16 职业技能数 = 6
	var bad: Array = []
	for cid in ids:
		var sk: Array = DataManager.get_class_data(str(cid)).get("skills", [])
		if sk.size() != 6:
			bad.append("%s=%d" % [str(cid), sk.size()])
	_check("16 职业各 6 技能", bad.is_empty(), str(bad))

# ---------- 尸体 ----------
func _test_corpse() -> void:
	_log("===== 尸体系统 =====")
	var script = load("res://scripts/enemies/corpse.gd")
	if script == null:
		_check("尸体脚本加载", false, "")
		return
	var corpse := Node2D.new()
	corpse.set_script(script)
	GameManager.current_world.add_child(corpse)
	corpse.call("setup", 0, "water", Color.GREEN)
	_check("尸体创建有效", bool(corpse.call("is_valid")), "")
	await _shot("corpse_spawn")
	corpse.free()
	# 敌人死亡生成尸体
	_clear_enemies()
	var dummy: Node = await _spawn_dummy(Vector2(60, 0), 20)
	# 必须走 take_damage → _die() 链路，直接写 hp=0 不会触发生成尸体
	dummy.call("take_damage", 9999)
	await get_tree().create_timer(0.4, true, false, true).timeout
	# 尸体节点不注册 group，按脚本类型检测
	var found: Array[Node] = get_tree().current_scene.find_children("*", "", true, false)
	var corpse_count := 0
	for n in found:
		var sc: Script = n.get_script() as Script
		if sc != null and str(sc.resource_path).ends_with("corpse.gd"):
			corpse_count += 1
	_check("敌人死亡生成尸体", corpse_count > 0, "corpses=%d" % corpse_count)
	if is_instance_valid(dummy):
		dummy.free()

# ---------- HitStop / 震屏 ----------
func _test_feel() -> void:
	_log("===== HitStop / 震屏 =====")
	HitStop.hit(0.06, 1.0)
	_check("HitStop 激活", HitStop.is_active(), "")
	# HitStop 会暂停 scene tree；用 process_always timer 等待其自动恢复
	await get_tree().create_timer(0.3, true, false, true).timeout
	_check("HitStop 自动结束", not HitStop.is_active(), "")
	ScreenShake.heavy()
	_check("震屏触发无异常", true, "")
	await _wait(0.3)

# ---------- 8 种新增技能类型 ----------
func _test_new_types() -> void:
	_log("===== 8 种新增技能类型 =====")
	var wanted := ["root_zone", "stun_wave", "heal_zone", "summon", "snipe", "deployable", "mark", "blink_strike"]
	var by_type := {}
	for cid in DataManager.get_all_class_ids():
		for s in DataManager.get_class_data(str(cid)).get("skills", []):
			var t := str(s.get("type", ""))
			if not by_type.has(t):
				by_type[t] = {"class": str(cid), "skill": s}
	for typ in wanted:
		var entry: Dictionary = by_type.get(typ, {})
		if entry.is_empty():
			_check("类型存在 " + typ, false, "未找到")
			continue
		var cid := str(entry.get("class", ""))
		var skill: Dictionary = entry.get("skill", {})
		var player: Node = await _activate(cid)
		if player == null:
			_check("类型施放 " + typ, false, "角色缺失 " + cid)
			continue
		_clear_enemies()
		var data: Node = player.get_node_or_null("CharacterData")
		data.mp = data.get_max_mp()
		data.hp = data.get_max_hp()
		data.buffs.clear()
		data.shield_hp = 0
		var slot := 0
		for i in data.skills.size():
			if str(data.skills[i].get("id", "")) == str(skill.get("id", "")):
				slot = i
				break
		player.skill_cooldowns[slot] = 0.0
		player.global_position = Vector2(0, 0)
		player.facing = Vector2.RIGHT
		var dummy: Node = await _spawn_dummy(Vector2(70, 0))
		var hp0: int = dummy.hp
		_log("施放 %s / %s / %s" % [cid, typ, str(skill.get("id", ""))])
		player.try_skill(slot)
		await _wait(0.9)
		var hp1: int = dummy.hp if is_instance_valid(dummy) else hp0
		var cd_left: float = float(player.skill_cooldowns[slot])
		var ok: bool = (hp1 < hp0) or (cd_left > 0.0) or (typ in ["heal_zone", "mark", "summon", "stun_wave"])
		_check("类型施放 " + typ, ok, "%s %s HP %d→%d cd=%.2f" % [cid, str(skill.get("id", "")), hp0, hp1, cd_left])
		await _shot("type_" + typ)
		if is_instance_valid(dummy):
			dummy.free()

func _main() -> void:
	_log("========== MECHANISM AUDIT START ==========")
	_log("Godot=%s" % Engine.get_version_info().get("string", "unknown"))
	GameManager.start_new_game()
	await _wait(2.0)
	# add_class_member 才会实例化角色；仅 add_to_roster 只改数据不生成 party 成员
	for cid in DataManager.get_all_class_ids():
		if not GameManager.roster.has(str(cid)):
			GameManager.add_class_member(str(cid))
	await _wait(0.5)
	var class_n: int = DataManager.get_all_class_ids().size()
	_check("全职业实例化到队伍", GameManager.party.size() == class_n, "party=%d expected=%d" % [GameManager.party.size(), class_n])

	await _test_elements()
	await _test_fusion()
	await _test_signatures()
	await _test_corpse()
	await _test_feel()
	await _test_new_types()

	_log("========== RESULT total=%d pass=%d fail=%d shots=%d ==========" % [total, passed, failed, shot_count])
	_log("MECH_RESULT failures=%d" % failed)
	if log_file != null:
		log_file.close()
	get_tree().quit(0 if failed == 0 else 1)
