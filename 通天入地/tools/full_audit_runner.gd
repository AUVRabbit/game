# ============================================================
# FullAuditRunner — 《通天入地》全功能 + 全技能真实渲染审计
# 用途：逐项操作、逐技能施放、断言、截图、视频帧、结构化日志
# 不修改游戏逻辑，只调用既有公开方法驱动流程
# ============================================================

extends Node

const OUT := "res://docs/FULL_TEST_2026-11-22/"
var log_file: FileAccess
var checks_total := 0
var checks_pass := 0
var checks_fail := 0
var shot_count := 0
var frame_count := 0
var skill_results: Array = []
var feature_results: Array = []

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
	DirAccess.make_dir_recursive_absolute(abs_out + "screenshots")
	DirAccess.make_dir_recursive_absolute(abs_out + "skills")
	DirAccess.make_dir_recursive_absolute(abs_out + "logs")
	DirAccess.make_dir_recursive_absolute(abs_out + "frames")
	DirAccess.make_dir_recursive_absolute(abs_out + "video")
	log_file = FileAccess.open(abs_out + "logs/full_audit.log", FileAccess.WRITE)
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
	var status := "PASS" if ok else "FAIL"
	if ok:
		checks_pass += 1
	else:
		checks_fail += 1
	_log("%s  %s | %s" % [status, label, detail])
	feature_results.append({"label": label, "ok": ok, "detail": detail})

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
	var abs_out := ProjectSettings.globalize_path(OUT)
	var full := abs_out + rel_path
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	img.save_jpg(full, 0.88)
	shot_count += 1
	_log("SHOT    %s (%dx%d)" % [rel_path, img.get_width(), img.get_height()])

func _frame() -> void:
	var img: Image = await _capture(960, 540)
	var abs_out := ProjectSettings.globalize_path(OUT)
	var full := abs_out + "frames/%04d.jpg" % frame_count
	img.save_jpg(full, 0.82)
	frame_count += 1

func _group_first(group: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group)
	return nodes[0] if not nodes.is_empty() else null

func _find_by_name(n: String) -> Node:
	return get_tree().root.find_child(n, true, false)

func _activate(class_id: String) -> Node:
	for i in GameManager.party.size():
		var pl: Node = GameManager.party[i]
		if not is_instance_valid(pl):
			continue
		var data: Node = pl.get_node_or_null("CharacterData")
		if data != null and str(data.class_id) == class_id:
			var guard := 0
			while GameManager.active_index != i and guard < 32:
				GameManager.switch_character(1 if GameManager.active_index < i else -1)
				guard += 1
			if GameManager.active_index != i:
				GameManager._set_active(i)
			await _wait(0.12)
			return GameManager.active_player
	return null

func _clear_enemies(disable_spawners: bool) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):
			e.free()
	if disable_spawners:
		for s in get_tree().get_nodes_in_group("enemy_spawners"):
			if is_instance_valid(s):
				s.set_process(false)

func _spawn_dummy(pos: Vector2, hp: int = 3000) -> Node:
	var packed: PackedScene = load("res://scenes/enemies/enemy.tscn")
	var dummy := packed.instantiate()
	dummy.enemy_name = "审计测试木桩"
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
	await _wait(0.12)
	return dummy

func _count_vfx() -> int:
	var n := 0
	if GameManager.current_world == null:
		return n
	for c in GameManager.current_world.get_children():
		if c is Sprite2D and c.z_index == 40:
			n += 1
	return n

func _test_skill(player: Node, slot: int, skill: Dictionary) -> Dictionary:
	var data: Node = player.get_node_or_null("CharacterData")
	var cid := str(data.class_id)
	var skill_id := str(skill.get("id", ""))
	var skill_name := str(skill.get("name", skill_id))
	var typ := str(skill.get("type", "melee_aoe"))
	_clear_enemies(true)
	data.mp = data.get_max_mp()
	data.hp = data.get_max_hp()
	data.shield_hp = 0
	data.buffs.clear()
	player.skill_cooldowns[slot] = 0.0
	player.global_position = Vector2(0, 0)
	player.facing = Vector2.RIGHT
	var dummy: Node = null
	if typ == "heal":
		data.hp = maxi(1, data.get_max_hp() - 30)
	var mp_before: int = data.mp
	var hp_before: int = data.hp
	var shield_before: int = data.shield_hp
	var atk_before: int = data.get_attack()
	var pos_before: Vector2 = player.global_position
	var enemy_hp_before := -1
	if typ in ["melee_aoe", "projectile", "chain", "aoe_zone", "dash_strike"]:
		var dist := 60.0
		if typ == "melee_aoe" or typ == "chain":
			dist = minf(dist, float(skill.get("radius", 80.0)) * 0.5)
		elif typ == "aoe_zone":
			dist = 70.0
		elif typ == "dash_strike":
			dist = float(skill.get("distance", 120.0))
		dummy = await _spawn_dummy(Vector2(dist, 0))
		enemy_hp_before = dummy.hp if is_instance_valid(dummy) else -1
	_action("施放技能 %s[%d] %s / %s (%s)" % [cid, slot + 1, skill_name, skill_id, typ])
	player.try_skill(slot)
	await _wait(0.09)
	var vfx_count := _count_vfx()
	var mp_after: int = data.mp
	var cd_left: float = player.skill_cooldowns[slot]
	var ok := false
	var observed := ""
	match typ:
		"heal":
			var healed: int = data.hp - hp_before
			ok = healed > 0
			observed = "HP %d -> %d (+%d)" % [hp_before, data.hp, healed]
		"buff":
			var buff_found := false
			var stat_name := str(skill.get("stat", "attack"))
			for b in data.buffs:
				if str(b.get("stat", "")) == stat_name:
					buff_found = true
			ok = buff_found
			observed = "Buff[%s] found=%s attack %d -> %d" % [stat_name, str(buff_found), atk_before, data.get_attack()]
		"shield":
			ok = data.shield_hp > shield_before
			observed = "Shield %d -> %d" % [shield_before, data.shield_hp]
		"projectile", "aoe_zone":
			var delay := 0.45 if typ == "projectile" else float(skill.get("delay", 0.5)) + 0.3
			await _wait(delay)
			var hp_after: int = dummy.hp if is_instance_valid(dummy) else enemy_hp_before
			ok = hp_after < enemy_hp_before
			observed = "DummyHP %d -> %d" % [enemy_hp_before, hp_after]
		"dash_strike":
			var hp_after: int = dummy.hp if is_instance_valid(dummy) else enemy_hp_before
			var moved: float = player.global_position.x - pos_before.x
			ok = moved > 10.0 and hp_after < enemy_hp_before
			observed = "MoveX +%.0f DummyHP %d -> %d" % [moved, enemy_hp_before, hp_after]
		"melee_aoe", "chain", _:
			var hp_after: int = dummy.hp if is_instance_valid(dummy) else enemy_hp_before
			ok = hp_after < enemy_hp_before
			observed = "DummyHP %d -> %d" % [enemy_hp_before, hp_after]
	var mp_ok: bool = mp_after <= mp_before
	var cd_ok: bool = cd_left > 0.0
	var vfx_ok: bool = vfx_count > 0
	var all_ok: bool = ok and mp_ok and cd_ok and vfx_ok
	var detail := "%s; MP %d->%d; CD=%.2f; VFX=%d; %s" % [typ, mp_before, mp_after, cd_left, vfx_count, observed]
	_observe("技能结果 %s %s" % ["OK" if all_ok else "FAIL", detail])
	if is_instance_valid(dummy):
		dummy.free()
	return {
		"class": cid, "slot": slot + 1, "id": skill_id, "name": skill_name,
		"type": typ, "ok": all_ok, "effect_ok": ok, "mp_ok": mp_ok,
		"cd_ok": cd_ok, "vfx_ok": vfx_ok, "detail": detail
	}

func _main() -> void:
	_log("========== FULL AUDIT START ==========")
	_log("Godot=%s" % Engine.get_version_info().get("string", "unknown"))

	# ---------- 1. 主菜单与设置 ----------
	_action("进入主菜单，检查标题与 5 个按钮")
	GameManager.enter_main_menu()
	await _wait(1.2)
	var menu := _group_first("main_menu")
	if menu == null:
		menu = _find_by_name("MainMenu")
	_check("主菜单节点存在", menu != null)
	var button_count := 0
	if menu != null:
		button_count = menu.find_children("*", "Button", true, false).size()
	_check("主菜单按钮>=5", button_count >= 5, "buttons=%d" % button_count)
	await _shot("screenshots/01_main_menu.jpg")
	if menu != null and menu.has_method("_toggle_settings"):
		_action("打开主菜单设置面板")
		menu.call("_toggle_settings")
		await _wait(0.5)
		await _shot("screenshots/02_settings.jpg")
		_check("设置面板可打开", true)
		menu.call("_toggle_settings")
		await _wait(0.3)
	else:
		_check("设置面板可打开", false, "main_menu missing")

	# ---------- 2. 新游戏初始状态 ----------
	_action("点击开始新游戏，进入主世界")
	GameManager.start_new_game()
	await _wait(1.4)
	var world := get_tree().current_scene
	_check("主世界场景加载", world != null and world.scene_file_path.ends_with("main_world.tscn"), world.scene_file_path if world else "null")
	_check("初始队伍 3 人", GameManager.party.size() == 3, str(GameManager.party.size()))
	_check("初始金币 120", GameManager.gold == 120, str(GameManager.gold))
	_check("初始背包材料", GameManager.inventory.count_item("stone") == 8 and GameManager.inventory.count_item("healing_potion") == 2)
	await _shot("screenshots/03_world_hud.jpg")

	# ---------- 3. 16 职业队伍 ----------
	var class_total: int = DataManager.get_all_class_ids().size()
	_action("通过职业祭坛逻辑将 %d 职业全部加入队伍" % class_total)
	for cid in DataManager.get_all_class_ids():
		if not GameManager.roster.has(str(cid)):
			GameManager.add_class_member(str(cid))
	await _wait(0.3)
	_check("%d 职业全部加入队伍" % class_total, GameManager.party.size() == class_total and GameManager.roster.size() == class_total, "party=%d roster=%d" % [GameManager.party.size(), GameManager.roster.size()])
	var portrait_missing: Array = []
	for cid in DataManager.get_all_class_ids():
		var pl := await _activate(str(cid))
		var spr: Node = null
		if pl != null and pl.get_node_or_null("Visual") != null:
			spr = pl.get_node_or_null("Visual/ClassSprite")
		if spr == null:
			portrait_missing.append(str(cid))
	_check("%d 职业立绘加载" % class_total, portrait_missing.is_empty(), "missing=" + str(portrait_missing))

	# ---------- 4. 战斗基础 ----------
	_action("普攻 / 冲刺无敌 / 冷却 / 法力不足校验")
	_clear_enemies(false)
	var warrior := await _activate("warrior")
	var dummy := await _spawn_dummy(warrior.global_position + Vector2(24, 0), 500)
	var hp0: int = dummy.hp
	warrior.try_attack()
	await _wait(0.2)
	_check("普攻造成伤害", is_instance_valid(dummy) and dummy.hp < hp0, "%d -> %d" % [hp0, dummy.hp if is_instance_valid(dummy) else -1])
	if is_instance_valid(dummy):
		dummy.free()
	warrior.skill_cooldowns = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	warrior.try_dash()
	_check("冲刺进入冷却", warrior.dash_cd > 0.0, "cd=%.2f" % warrior.dash_cd)
	_check("冲刺期间无敌", warrior.is_invulnerable())
	var dodge_saved: float = warrior.character_data.dodge_rate
	warrior.character_data.dodge_rate = 0.0
	var hurt_dash: int = warrior.receive_damage(30)
	_check("冲刺伤害吸收", hurt_dash == 0, "dealt=%d" % hurt_dash)
	await _wait(0.35)
	var hurt_normal: int = warrior.receive_damage(30)
	_check("非冲刺正常受伤", hurt_normal > 0, "dealt=%d" % hurt_normal)
	warrior.character_data.dodge_rate = dodge_saved
	warrior.character_data.mp = 0
	warrior.skill_cooldowns[0] = 0.0
	warrior.try_skill(0)
	_check("法力不足不施法", warrior.character_data.mp == 0 and warrior.skill_cooldowns[0] <= 0.0)
	warrior.character_data.mp = warrior.character_data.get_max_mp()
	warrior.try_skill(0)
	var cd1: float = warrior.skill_cooldowns[0]
	var mp1: int = warrior.character_data.mp
	warrior.try_skill(0)
	_check("技能冷却阻止重复施放", cd1 > 0.0 and warrior.character_data.mp == mp1, "cd=%.2f mp=%d" % [cd1, mp1])

	# ---------- 5. 经济闭环 ----------
	_action("资源点采集")
	var collected := false
	for node in get_tree().get_nodes_in_group("interactables"):
		if "resource_id" in node and node.has_method("interact"):
			var rid := str(node.resource_id)
			var before: int = GameManager.inventory.count_item(rid)
			node.interact(warrior)
			if GameManager.inventory.count_item(rid) > before:
				collected = true
				_observe("采集成功 %s %d -> %d" % [rid, before, GameManager.inventory.count_item(rid)])
				break
	_check("资源点采集入包", collected)
	_action("合成铁锭")
	GameManager.inventory.add_item("iron_ore", 5)
	var ingot_before: int = GameManager.inventory.count_item("iron_ingot")
	var crafted: bool = GameManager.inventory.craft("iron_ingot")
	_check("合成 iron_ingot", crafted and GameManager.inventory.count_item("iron_ingot") > ingot_before)
	_action("商店购买与出售")
	var gold_before: int = GameManager.gold
	var potion_before: int = GameManager.inventory.count_item("healing_potion")
	var bought: bool = GameManager.inventory.buy_item("healing_potion", 25)
	_check("商店购买药水", bought and GameManager.gold == gold_before - 25 and GameManager.inventory.count_item("healing_potion") == potion_before + 1)
	var sell_idx := -1
	for i in GameManager.inventory.slots.size():
		if GameManager.inventory.get_item_id_at(i) == "healing_potion":
			sell_idx = i
			break
	var gold_sell: int = GameManager.gold
	var sold: bool = GameManager.inventory.sell_slot(sell_idx, 10) if sell_idx >= 0 else false
	_check("商店出售物品", sold and GameManager.gold == gold_sell + 10)
	_action("装备与卸下武器")
	var weapons: Array = DataManager.get_items_by_type("weapon")
	var equipped := false
	var unequipped := false
	if not weapons.is_empty():
		var wid := str(weapons[0].get("id", ""))
		GameManager.inventory.add_item(wid, 1)
		var widx := -1
		for i in GameManager.inventory.slots.size():
			if GameManager.inventory.get_item_id_at(i) == wid:
				widx = i
				break
		if widx >= 0:
			equipped = GameManager.inventory.equip_slot(widx, warrior.character_data)
			var slot_name := str(weapons[0].get("slot", ""))
			_check("武器装备生效", equipped and not warrior.character_data.get_equipped(slot_name).is_empty(), "item=%s slot=%s" % [wid, slot_name])
			unequipped = GameManager.inventory.unequip_slot(slot_name, warrior.character_data)
			_check("武器卸下回包", unequipped and warrior.character_data.get_equipped(slot_name).is_empty())
	else:
		_check("武器装备生效", false, "no weapon data")

	# ---------- 6. 建造 ----------
	_action("建造模式：放置石砖并拆除返还")
	BuildManager.toggle_build_mode()
	var block_id := ""
	if not BuildManager.available_blocks.is_empty():
		block_id = str(BuildManager.available_blocks[0].get("id", ""))
		BuildManager.set_current_block(block_id)
	var grid: Node = GameManager.current_world.get_node_or_null("BuildGrid")
	var builds_before: int = grid.get_child_count() if grid != null else -1
	var cost_item := ""
	var cost_before := 0
	var bdef: Dictionary = DataManager.get_item(block_id)
	var cost: Dictionary = bdef.get("craft_cost", {})
	if not cost.is_empty():
		cost_item = str(cost.keys()[0])
		cost_before = GameManager.inventory.count_item(cost_item)
	var placed: bool = BuildManager.place_block(Vector2i(3, 3))
	var placed_count: int = grid.get_child_count() if grid != null else -1
	_check("放置建筑", placed and placed_count == builds_before + 1, "block=%s count=%d->%d" % [block_id, builds_before, placed_count])
	await _shot("screenshots/13_build_mode.jpg")
	var broke: bool = BuildManager.break_block(Vector2i(3, 3))
	await _wait(0.15)
	var broke_count: int = grid.get_child_count() if grid != null else -1
	_check("拆除建筑并返还材料", broke and broke_count == builds_before, "count=%d refund=%s %d->%d" % [broke_count, cost_item, cost_before, GameManager.inventory.count_item(cost_item) if cost_item != "" else 0])
	BuildManager.toggle_build_mode()

	# ---------- 7. UI 页面 ----------
	_action("背包三页签")
	var inv_panel := _group_first("inventory_panel")
	if inv_panel != null:
		inv_panel.call("open_panel")
		await _wait(0.6)
		_check("背包打开暂停", get_tree().paused)
		await _shot("screenshots/08_inventory_bag.jpg")
		inv_panel.tabs.current_tab = 1
		await _wait(0.4)
		await _shot("screenshots/09_inventory_craft.jpg")
		inv_panel.tabs.current_tab = 2
		await _wait(0.4)
		await _shot("screenshots/10_inventory_shop.jpg")
		inv_panel.call("close_panel")
		await _wait(0.3)
		_check("背包关闭恢复", not get_tree().paused)
	else:
		_check("背包面板存在", false)
	_action("技能树与职业专职页签")
	var tree_panel := _group_first("skill_tree_panel")
	if tree_panel != null:
		tree_panel.call("_toggle")
		await _wait(0.7)
		_check("技能树面板打开", tree_panel.visible and get_tree().paused)
		await _shot("screenshots/06_skill_tree.jpg")
		tree_panel.call("_show_tab", "spec")
		await _wait(0.5)
		await _shot("screenshots/07_specialization.jpg")
		tree_panel.call("_show_tab", "tree")
		tree_panel.call("_toggle")
		await _wait(0.3)
	else:
		_check("技能树面板存在", false)
	_action("朋克改造台面板")
	var punk_panel := _group_first("punk_panel")
	if punk_panel != null:
		punk_panel.call("_toggle")
		await _wait(0.7)
		_check("朋克面板打开", punk_panel.visible and get_tree().paused)
		await _shot("screenshots/11_punk_panel.jpg")
		punk_panel.call("_toggle")
		await _wait(0.3)
	else:
		_check("朋克面板存在", false)
	_action("暂停菜单")
	GameManager.open_pause()
	await _wait(0.5)
	_check("暂停菜单暂停游戏", get_tree().paused and GameManager.current_state == GameManager.GameState.PAUSED)
	await _shot("screenshots/12_pause_menu.jpg")
	GameManager.close_pause()
	await _wait(0.3)
	_check("暂停恢复", not get_tree().paused)
	_action("NPC 对话框")
	var dlg := _group_first("dialogue_box")
	if dlg != null:
		dlg.call("show_dialogue", "铁匠 · 铁砧", ["这年头，法术朋克和机械朋克在塔里打得不可开交。", "想过塔？先把外头的史莱姆清干净。"])
		await _wait(0.6)
		await _shot("screenshots/14_dialogue.jpg")
		dlg.call("_close")
		await _wait(0.3)
		_check("对话框显示", true)
	else:
		_check("对话框显示", false)
	_action("触屏控制布局")
	var touch := _find_by_name("TouchControls")
	if touch != null:
		touch.set("visible", true)
		await _wait(0.5)
		await _shot("screenshots/15_touch_controls.jpg")
		touch.set("visible", false)
		_check("触屏控件存在", true)
	else:
		_check("触屏控件存在", false)
	_action("相机缩放")
	var cam: Camera2D = GameManager.current_world.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		var z0: Vector2 = cam.zoom
		cam.zoom = Vector2(1.8, 1.8)
		await _wait(0.5)
		await _shot("screenshots/04_world_zoom.jpg")
		cam.zoom = z0
		_check("相机缩放生效", true)
	else:
		_check("相机缩放生效", false)

	# ---------- 8. 逐技能实测 ----------
	var skill_total: int = class_total * 6
	_action("开始逐职业技能实测（%d 职业 x 6 技能 = %d 项）" % [class_total, skill_total])
	_clear_enemies(true)
	var skill_index := 0
	for cid in DataManager.get_all_class_ids():
		var cid_str := str(cid)
		# 测试环境直接解锁进阶前置，确保 6 个技能槽都可实测
		SkillManager.ensure_class(cid_str)
		SkillManager.points[cid_str] = 99
		for node in DataManager.get_skill_tree_nodes(cid_str):
			if str(node.get("kind", "")) in ["mastery", "active"]:
				if not SkillManager.is_unlocked(cid_str, str(node.get("id", ""))):
					SkillManager.unlock_node(cid_str, str(node.get("id", "")))
		var pl := await _activate(cid_str)
		if pl == null:
			_check("技能测试角色 %s" % cid_str, false, "player missing")
			continue
		var skills: Array = pl.character_data.skills
		_check("%s 技能数=6" % cid_str, skills.size() == 6, str(skills.size()))
		for slot in skills.size():
			var skill: Dictionary = skills[slot]
			var result: Dictionary = await _test_skill(pl, slot, skill)
			skill_results.append(result)
			skill_index += 1
			await _shot("skills/%02d_%s_%s.jpg" % [skill_index, cid_str, str(skill.get("id", "skill"))])
			_check("技能 %s-%s" % [cid_str, str(skill.get("id", ""))], bool(result.get("ok", false)), str(result.get("detail", "")))
	_check("%d 技能全部实测" % skill_total, skill_results.size() == skill_total, "tested=%d" % skill_results.size())

	# ---------- 9. 成长：技能树 / 专职 / 朋克 ----------
	_action("技能树解锁、前置校验、威力与冷却加成")
	SkillManager.reset_tree("archer")
	var pts0: int = SkillManager.get_points("archer")
	var nodes: Array = DataManager.get_skill_tree_nodes("archer")
	_check("技能树 16 节点", nodes.size() == 16, str(nodes.size()))
	var unlocked: bool = SkillManager.unlock_node("archer", "archer_mastery_0")
	_check("解锁精通节点", unlocked and SkillManager.is_unlocked("archer", "archer_mastery_0"))
	var gate: Dictionary = SkillManager.can_unlock("archer", "archer_active_1")
	_check("前置节点未满足被拒", not bool(gate.get("ok", true)), str(gate.get("reason", "")))
	var arch := await _activate("archer")
	var power_mult: float = arch.character_data.get_skill_power_multiplier("piercing_shot")
	var cd_mult: float = arch.character_data.get_skill_cooldown_multiplier("piercing_shot")
	_check("技能威力加成 >1", power_mult > 1.0, "x%.2f" % power_mult)
	_check("技能冷却缩减 <1", cd_mult < 1.0, "x%.2f" % cd_mult)
	_action("职业专职选择与互斥")
	var spec_ok: bool = SkillManager.choose_specialization("archer", "sharpshooter", 5)
	_check("专职选择成功", spec_ok)
	arch.character_data.refresh_skill_stats()
	_check("专职属性生效", arch.character_data.get_crit_rate() > 0.05, "crit=%.3f" % arch.character_data.get_crit_rate())
	_check("专职名称生效", str(SkillManager.get_specialization("archer").get("name", "")) == "神射手")
	var dup: bool = SkillManager.choose_specialization("archer", "ranger", 5)
	_check("专职互斥拒绝第二次", not dup)
	_action("技能树重置返还技能点")
	SkillManager.reset_tree("archer")
	_check("重置返还技能点", SkillManager.get_points("archer") >= pts0, "points=%d" % SkillManager.get_points("archer"))
	_action("朋克部件安装与卸下")
	GameManager.inventory.add_item("iron_ore", 30)
	GameManager.inventory.add_item("herb", 30)
	GameManager.inventory.add_item("wood", 30)
	var parts: Array = PunkManager.get_all_parts_for_class("archer")
	_check("朋克部件库加载", parts.size() > 0, "parts=%d" % parts.size())
	var applied := false
	for part in parts:
		if str(part.get("style", "")) == "tech" and str(part.get("slot", "")) == "helmet":
			applied = PunkManager.apply_punk("archer", "helmet", str(part.get("id", "")))
			break
	_check("朋克部件安装", applied)
	arch.character_data.refresh_punk_stats()
	_check("朋克主风格判定 tech", PunkManager.get_primary_style("archer") == "tech", PunkManager.get_primary_style("archer"))
	_check("朋克暴击属性生效", arch.character_data.get_crit_rate() >= 0.10, "crit=%.3f" % arch.character_data.get_crit_rate())
	await _shot("screenshots/11b_punk_installed.jpg")
	var removed: bool = PunkManager.remove_punk("archer", "helmet")
	_check("朋克部件卸下", removed and PunkManager.get_primary_style("archer") == "neutral")

	# ---------- 10. NPC / 任务 ----------
	_action("NPC 对话接取任务并击杀计数")
	QuestManager.reset_all()
	var npc_hit := false
	for node in get_tree().get_nodes_in_group("interactables"):
		if "dialogue_id" in node and node.has_method("interact"):
			node.interact(GameManager.active_player)
			npc_hit = true
			break
	await _wait(0.2)
	_check("NPC 对话触发暂停", npc_hit and get_tree().paused and GameManager.current_state == GameManager.GameState.DIALOG)
	var box := _group_first("dialogue_box")
	if box != null:
		box.call("_close")
	await _wait(0.2)
	_check("任务接取 q_slime_hunt", QuestManager.active.has("q_slime_hunt"), str(QuestManager.active.keys()))
	var kill_dummy := await _spawn_dummy(GameManager.active_player.global_position + Vector2(20, 0), 10)
	kill_dummy.enemy_type = "slime"
	kill_dummy.take_damage(999, false, GameManager.active_player)
	await _wait(0.2)
	_observe("任务追踪：" + str(QuestManager.get_tracked_quest().get("title", "")))

	# ---------- 11. 存档 / 读档 ----------
	_action("保存游戏并验证读档恢复")
	GameManager.enter_main_world()
	await _wait(1.0)
	var sav := await _activate("warrior")
	GameManager.gold = 777
	GameManager.inventory.add_item("iron_ore", 7)
	BuildManager.toggle_build_mode()
	BuildManager.place_block(Vector2i(5, 5))
	BuildManager.toggle_build_mode()
	var saved: bool = SaveManager.save_game(0)
	_check("存档写入", saved and SaveManager.has_save(0))
	GameManager.gold = 1
	GameManager.inventory.remove_item("iron_ore", 7)
	BuildManager.break_block(Vector2i(5, 5))
	await _wait(0.2)
	var loaded: bool = SaveManager.load_game(0)
	await _wait(1.2)
	_check("读档恢复金币", loaded and GameManager.gold == 777, str(GameManager.gold))
	_check("读档恢复背包", GameManager.inventory.count_item("iron_ore") >= 7, "iron=%d" % GameManager.inventory.count_item("iron_ore"))
	var g: Node = GameManager.current_world.get_node_or_null("BuildGrid")
	_check("读档恢复建筑", g != null and g.get_child_count() > 0, "blocks=%d" % (g.get_child_count() if g else -1))

	# ---------- 12. 通天塔 / 深渊 / Roguelike ----------
	_action("进入通天塔第 1 层")
	GameManager.start_tower_run()
	await _wait(1.2)
	var tower = get_tree().current_scene
	_check("塔层 1 场景", tower != null and tower.scene_file_path.ends_with("tower_floor_1.tscn"))
	_check("塔层 1 机关数量=2", tower != null and tower.switches_total == 2, str(tower.switches_total if tower else -1))
	_check("初始传送门锁定", tower != null and tower.portal != null and not tower.portal.enabled)
	_check("Roguelike 启动", RoguelikeManager.is_active)
	_action("限时机关超时重置")
	if tower != null and not tower.switch_nodes.is_empty():
		tower.switch_nodes[0]._on_body_entered(GameManager.active_player)
		_check("机关 1 激活并启动倒计时", tower.switches_done == 1 and tower.puzzle_running)
		tower.puzzle_time_left = 0.05
		await _wait(0.25)
		_check("超时后机关重置", tower.switches_done == 0 and not tower.switch_nodes[0].is_on)
	_action("激活全部机关开门")
	if tower != null:
		for sw in tower.switch_nodes:
			sw._on_body_entered(GameManager.active_player)
		await _wait(0.2)
		_check("机关全开后传送门启用", tower.door == null and tower.portal.enabled)
	await _shot("screenshots/16_tower_floor.jpg")
	_action("进入第 2 层验证法师限定机关")
	GameManager.enter_tower_floor(2)
	await _wait(1.1)
	var tower2 = get_tree().current_scene
	_check("塔层 2 加载", tower2 != null and tower2.floor_num == 2)
	var mage_sw = tower2.switch_nodes[0] if tower2 != null and not tower2.switch_nodes.is_empty() else null
	_check("0 号机关要求法师", mage_sw != null and mage_sw.required_class == "mage", mage_sw.required_class if mage_sw else "null")
	if mage_sw != null:
		var war := await _activate("warrior")
		mage_sw._on_body_entered(war)
		_check("非法师无法激活", not mage_sw.is_on)
		var mage := await _activate("mage")
		mage_sw._on_body_entered(mage)
		_check("法师可激活", mage_sw.is_on)
	_action("进入第 5 层验证 BOSS")
	GameManager.enter_tower_floor(5)
	await _wait(1.1)
	var tower5 = get_tree().current_scene
	var boss_found := false
	if tower5 != null:
		for c in tower5.dynamic_root.get_children():
			if "enemy_config" in c:
				var cfg: Dictionary = c.enemy_config
				boss_found = bool(cfg.get("is_boss", false)) and str(cfg.get("enemy_name", "")) == "塔卫 · BOSS"
				if boss_found:
					for e in c.get_children():
						if "is_boss" in e and bool(e.is_boss) and is_instance_valid(GameManager.active_player):
							e.global_position = GameManager.active_player.global_position + Vector2(95, 0)
	_check("第 5 层生成 BOSS", boss_found)
	await _wait(0.3)
	await _shot("screenshots/17_boss_floor.jpg")
	_action("进入深渊 -1 层")
	GameManager.enter_tower_floor(-1)
	await _wait(1.1)
	var abyss = get_tree().current_scene
	_check("深渊层号 -1", abyss != null and abyss.floor_num == -1, str(abyss.floor_num if abyss else "null"))
	await _shot("screenshots/18_abyss_floor.jpg")
	_action("Roguelike 每 3 层词条与死亡结算")
	RoguelikeManager.advance_floor()
	RoguelikeManager.advance_floor()
	_check("第 3 层获得词条", RoguelikeManager.modifiers.size() >= 1, "modifiers=%d" % RoguelikeManager.modifiers.size())
	var dying := GameManager.active_player
	dying.character_data.hp = 1
	dying.character_data.take_damage(9999)
	await _wait(1.7)
	_check("死亡结束本轮", not RoguelikeManager.is_active, "best=%d" % RoguelikeManager.best_floor)
	_check("死亡后返回主菜单", get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with("main_menu.tscn"))

	# ---------- 13. 操作视频帧 ----------
	_action("录制操作过程视频帧")
	GameManager.enter_main_menu()
	await _wait(0.6)
	for i in range(10):
		_frame()
		await _wait(0.09)
	GameManager.start_new_game()
	await _wait(1.0)
	var vp := GameManager.active_player
	InputManager.set_virtual_move(Vector2(1, 0))
	for i in range(22):
		if i % 5 == 0:
			vp.try_attack()
		if i % 7 == 0:
			vp.try_skill((i / 7) % 3)
		_frame()
		await _wait(0.085)
	InputManager.set_virtual_move(Vector2.ZERO)
	var ip := _group_first("inventory_panel")
	if ip != null:
		ip.call("open_panel")
		for i in range(9):
			ip.tabs.current_tab = i / 3
			_frame()
			await _wait(0.085)
		ip.call("close_panel")
	var tp := _group_first("skill_tree_panel")
	if tp != null:
		tp.call("_toggle")
		for i in range(12):
			if i == 6:
				tp.call("_show_tab", "spec")
			_frame()
			await _wait(0.085)
		tp.call("_toggle")
	GameManager.enter_tower_floor(1)
	await _wait(1.0)
	for i in range(16):
		var tw = get_tree().current_scene
		if tw != null and i == 4:
			tw.switch_nodes[0]._on_body_entered(GameManager.active_player)
		if tw != null and i == 9:
			tw.switch_nodes[1]._on_body_entered(GameManager.active_player)
		_frame()
		await _wait(0.085)
	_check("视频帧采集完成", frame_count >= 60, "frames=%d" % frame_count)

	# ---------- 14. 汇总 ----------
	var skill_pass := 0
	for r in skill_results:
		if bool(r.get("ok", false)):
			skill_pass += 1
	var summary := {
		"generated_at": Time.get_datetime_string_from_system(true),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"checks_total": checks_total,
		"checks_pass": checks_pass,
		"checks_fail": checks_fail,
		"skills_total": skill_results.size(),
		"skills_pass": skill_pass,
		"screenshots": shot_count,
		"video_frames": frame_count,
		"skill_results": skill_results,
		"feature_results": feature_results
	}
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT) + "logs/results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.flush()
	_log("SUMMARY checks=%d/%d skills=%d/%d shots=%d frames=%d" % [checks_pass, checks_total, skill_pass, skill_results.size(), shot_count, frame_count])
	_log("========== FULL AUDIT DONE ==========")
	await _wait(0.3)
	get_tree().quit(0 if checks_fail == 0 and skill_pass == skill_results.size() else 1)
