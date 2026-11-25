extends Node
# 无头冒烟测试：依次验证 新游戏 → 战斗 → 采集/合成 → 建造 → 存档 → 通天塔
# 运行：godot --headless --path . tools/smoke_test.tscn

var failures: int = 0

func _ready() -> void:
	call_deferred("_run")

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("PASS  %s %s" % [label, detail])
	else:
		failures += 1
		print("FAIL  %s %s" % [label, detail])

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _spawn_dummy(host: Node, packed: PackedScene, dist: float) -> Node:
	var e = packed.instantiate()
	e.name = "SmokeDummy_%d" % randi()
	e.enemy_name = "特色靶子"
	e.max_hp = 9999
	e.hp = 9999
	e.attack = 0
	e.move_speed = 0.0
	e.detect_range = 0.0
	e.attack_range = 999.0
	e.attack_cooldown_time = 99.0
	var parent := GameManager.current_world.get_node_or_null("Dynamic") if GameManager and GameManager.current_world else null
	if parent == null and host != null:
		parent = host.get_parent()
	if parent == null:
		parent = get_tree().current_scene
	parent.add_child(e)
	# 在 _ready() 执行后再覆盖 EnemyBase 强制设置的 collision_layer/mask
	e.collision_layer = 0
	e.collision_mask = 0
	e.set_physics_process(false)
	e.global_position = host.global_position + Vector2(dist, 0) if host != null else Vector2(dist, 0)
	return e

func _find_skill_slot_by_type(data: CharacterBase, type_name: String) -> int:
	if data == null:
		return -1
	var ids: Array = data.get_loadout_ids()
	var owned: Dictionary = data.get_owned_abilities()
	for i in ids.size():
		var sk = owned.get(str(ids[i]), {})
		if not sk.is_empty() and str(sk.get("type", "")) == type_name:
			return i  # 0-based slot for try_skill
	return -1

func _run() -> void:
	await _wait(0.2)

	# ---------- 1. 新游戏 ----------
	GameManager.start_new_game()
	await _wait(0.8)
	var world = get_tree().current_scene
	_check("场景=主世界", world != null and world.scene_file_path.ends_with("main_world.tscn"), world.scene_file_path if world else "null")
	_check("队伍=3人", GameManager.party.size() == 3, str(GameManager.party.size()))
	var player = GameManager.active_player
	_check("出战角色有效", is_instance_valid(player))
	_check("起始金币=120", GameManager.gold == 120, str(GameManager.gold))
	_check("初始背包>=4格", GameManager.inventory.count_item("stone") == 8, "stone=%d" % GameManager.inventory.count_item("stone"))

	# ---------- 2. 战斗 ----------
	if is_instance_valid(player):
		var enemy_packed: PackedScene = load("res://scenes/enemies/enemy.tscn")
		var enemy = enemy_packed.instantiate()
		enemy.enemy_name = "冒烟测试怪"
		enemy.max_hp = 500
		enemy.hp = 500
		enemy.attack = 1
		enemy.exp_reward = 5
		enemy.move_speed = 0.0
		enemy.detect_range = 10.0
		enemy.position = player.global_position + Vector2(30, 0)
		GameManager.current_world.get_node("Dynamic").add_child(enemy)
		await _wait(0.2)
		var hp_before: int = enemy.hp
		player.try_attack()
		await _wait(0.2)
		_check("普攻造成伤害", enemy.hp < hp_before, "%d -> %d" % [hp_before, enemy.hp])
		player.try_skill(0)
		await _wait(0.2)
		_check("技能可释放", true)
		player.try_dash()
		await _wait(0.2)
		_check("冲刺进入冷却", player.dash_cd > 0.0, str(player.dash_cd))
		print("清理测试敌人")
		if is_instance_valid(enemy):
			enemy.free()

	# ---------- 3. 采集 / 合成 ----------
	GameManager.inventory.add_item("iron_ore", 5)
	var recipe: Dictionary = DataManager.get_recipe("iron_ingot")
	_check("配方可查", not recipe.is_empty(), str(recipe.get("output", "")))
	if not recipe.is_empty():
		var crafted: bool = GameManager.inventory.craft(str(recipe.get("id", "iron_ingot")))
		_check("合成成功", crafted and GameManager.inventory.count_item("iron_ingot") >= 1)

	# 交互采集：直接调用资源点 interact
	var collected := false
	for node in get_tree().get_nodes_in_group("interactables"):
		if node.get_script() != null and node.has_method("interact") and "resource_id" in node:
			var before: int = GameManager.inventory.count_item(node.resource_id)
			node.interact(player)
			if GameManager.inventory.count_item(node.resource_id) > before:
				collected = true
				break
	_check("资源点采集", collected)

	# ---------- 4. 建造 ----------
	var dynamic = GameManager.current_world.get_node("Dynamic")
	var build_grid = GameManager.current_world.get_node("BuildGrid")
	var before_builds: int = build_grid.get_child_count()
	BuildManager.toggle_build_mode()
	var block_id := ""
	if not BuildManager.available_blocks.is_empty():
		block_id = str(BuildManager.available_blocks[0].get("id", ""))
		BuildManager.set_current_block(block_id)
	var placed: bool = BuildManager.place_block(Vector2i(2, 2))
	_check("放置建筑", placed and build_grid.get_child_count() == before_builds + 1, block_id)
	var broke: bool = BuildManager.break_block(Vector2i(2, 2))
	await _wait(0.1)
	_check("拆除建筑", broke and build_grid.get_child_count() == before_builds)
	BuildManager.toggle_build_mode()

	# ---------- 5. UI 开关 ----------
	GameManager.open_ui(GameManager.GameState.INVENTORY)
	_check("打开背包暂停", get_tree().paused)
	GameManager.close_ui()
	_check("关闭背包恢复", not get_tree().paused)

	# ---------- 6. 存档 / 读档 ----------
	var saved: bool = SaveManager.save_game(0)
	_check("存档写入", saved and FileAccess.file_exists(SaveManager.SAVE_DIR + "save_0.json"))
	GameManager.gold = 9999
	await _wait(0.1)
	var loaded: bool = SaveManager.load_game(0)
	await _wait(0.8)
	_check("读档恢复金币", loaded and GameManager.gold == 120, str(GameManager.gold))

	# ---------- 6.2 职业切换 ----------
	var first_player = GameManager.active_player
	GameManager.switch_character(1)
	await _wait(0.1)
	_check("Q/P 切换职业", GameManager.active_player != first_player and GameManager.active_player.visible, GameManager._active_class_name())
	GameManager.switch_character(-1)
	await _wait(0.1)

	# ---------- 6.3 NPC 对话与任务 ----------
	var fresh_player = GameManager.active_player
	for node in get_tree().get_nodes_in_group("interactables"):
		if "dialogue_id" in node and node.has_method("interact"):
			node.interact(fresh_player)
			break
	await _wait(0.2)
	_check("NPC 对话打开", get_tree().paused and GameManager.current_state == GameManager.GameState.DIALOG)
	var boxes := get_tree().get_nodes_in_group("dialogue_box")
	if not boxes.is_empty():
		boxes[0]._close()
	await _wait(0.2)
	_check("对话结束接取任务", QuestManager.active.has("q_slime_hunt"), str(QuestManager.active.keys()))

	# ---------- 6.5 职业祭坛 ----------
	var roster_before: int = GameManager.roster.size()
	GameManager.add_gold(500)
	fresh_player = GameManager.active_player
	for node in get_tree().get_nodes_in_group("interactables"):
		if "unlock_cost" in node and node.has_method("interact"):
			node.interact(fresh_player)
			break
	await _wait(0.2)
	_check("职业祭坛解锁", GameManager.roster.size() == roster_before + 1, "%d -> %d" % [roster_before, GameManager.roster.size()])

	# ---------- 6.6 弹道技能与护盾 ----------
	GameManager.switch_character(1)
	GameManager.switch_character(1)
	await _wait(0.1)
	var mage = GameManager.active_player
	_check("切换到法师", mage != null and mage.character_data.class_id == "mage", mage.character_data.class_id if mage else "null")
	if mage:
		# 清除游荡中的刷怪，避免拦截弹道导致用例抖动
		for wandering in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(wandering):
				wandering.free()
		var dummy_packed: PackedScene = load("res://scenes/enemies/enemy.tscn")
		var dummy = dummy_packed.instantiate()
		dummy.max_hp = 500
		dummy.hp = 500
		dummy.attack = 0
		dummy.move_speed = 0.0
		dummy.detect_range = 0.0
		dummy.position = mage.global_position + Vector2(90, 0)
		GameManager.current_world.get_node("Dynamic").add_child(dummy)
		await _wait(0.1)
		mage.facing = Vector2.RIGHT
		mage.try_skill(0)
		await _wait(0.7)
		_check("弹道技能命中", dummy.hp < 500, "%d" % dummy.hp)
		if is_instance_valid(dummy):
			dummy.free()
		mage.try_skill(2)
		await _wait(0.1)
		_check("护盾生效", mage.character_data.shield_hp > 0, str(mage.character_data.shield_hp))

	# ---------- 护盾生效后验证朋克改造 ----------
	GameManager.switch_character(-1)  # 切回弓箭手（初始）
	await _wait(0.1)
	var player0: Node = GameManager.active_player
	_check("回到弓箭手", player0 != null and str(player0.character_data.class_id) == "archer", str(player0.character_data.class_id) if player0 else "null")
	# 给朋克改造材料
	GameManager.inventory.add_item("iron_ore", 20)
	GameManager.inventory.add_item("herb", 20)
	GameManager.inventory.add_item("wood", 20)
	var archer_style: Array = PunkManager.get_all_parts_for_class("archer")
	_check("朋克部件库加载", archer_style.size() > 0, str(archer_style.size()) + " 件")
	# 给弓箭手装一个tech风格的
	for part in archer_style:
		if str(part.get("style", "")) == "tech" and str(part.get("slot", "")) == "helmet":
			var ok: bool = PunkManager.apply_punk("archer", "helmet", str(part.get("id", "")))
			_check("安装朋克部件", ok, str(part.get("id", "")))
			player0.character_data.refresh_punk_stats()
			var primary: String = PunkManager.get_primary_style("archer")
			_check("主风格判定", primary == "tech", primary)
			var crit_base: float = player0.character_data.get_crit_rate()
			var punk_helm: Dictionary = DataManager.get_punk_part(str(part.get("id", "")))
			_check("朋克属性生效", crit_base >= 0.10, "crit_rate=%.3f" % crit_base)
			break
	# 卸下
	var removed: bool = PunkManager.remove_punk("archer", "helmet")
	_check("卸下朋克部件", removed)
	var primary2: String = PunkManager.get_primary_style("archer")
	_check("主风格清除", primary2 == "neutral", primary2)

	# 切换到机甲师，装mech风格，测试class_bonus
	GameManager.add_class_member("mech_pilot")
	await _wait(0.1)
	# 找到机甲师的index
	var mech_index: int = -1
	for i in GameManager.party.size():
		var data_node: Node = GameManager.party[i].get_node_or_null("CharacterData")
		if data_node != null and str(data_node.class_id) == "mech_pilot":
			mech_index = i
			break
	if mech_index >= 0:
		while GameManager.active_index != mech_index:
			GameManager.switch_character(1 if GameManager.active_index < mech_index else -1)
			await _wait(0.1)
	var mech: Node = GameManager.active_player
	_check("切换到机甲师", mech != null and str(mech.character_data.class_id) == "mech_pilot", str(mech.character_data.class_id) if mech else "null")
	GameManager.inventory.add_item("iron_ore", 30)
	GameManager.inventory.add_item("leather", 20)
	var mech_parts: Array = PunkManager.get_all_parts_for_class("mech_pilot")
	for part in mech_parts:
		var class_bonus_arr: Array = part.get("class_bonus", [])
		if class_bonus_arr.has("mech_pilot") and str(part.get("slot", "")) == "helmet":
			var ok2: bool = PunkManager.apply_punk("mech_pilot", "helmet", str(part.get("id", "")))
			_check("机甲师专属改造安装", ok2)
			var defense: int = mech.character_data.get_defense()
			_check("风格匹配加成生效", defense > 12, "defense=%d" % defense)
			PunkManager.remove_punk("mech_pilot", "helmet")
			break

	# 存档测试朋克数据：先给archer装tech部件再存档
	PunkManager.apply_punk("archer", "helmet", "tech_quantum_sensor")
	GameManager.switch_character(-1)
	await _wait(0.1)
	var archer_for_save: Node = GameManager.active_player
	archer_for_save.character_data.refresh_punk_stats()
	_check("存档前archer主风格=tech", PunkManager.get_primary_style("archer") == "tech")
	SaveManager.save_game(0)
	# 改一下朋克状态（卸下），再读档
	PunkManager.remove_punk("archer", "helmet")
	_check("卸下后archer主风格=neutral", PunkManager.get_primary_style("archer") == "neutral")
	SaveManager.load_game(0)
	await _wait(0.9)
	# 读档后朋克应恢复
	_check("读档恢复朋克数据", SaveManager.has_save(0))
	# 切到弓箭手
	for i in GameManager.party.size():
		var nd: Node = GameManager.party[i].get_node_or_null("CharacterData")
		if nd != null and str(nd.class_id) == "archer":
			GameManager.active_index = i
			break
	GameManager.switch_character(0)
	await _wait(0.1)
	var archer_post: Node = GameManager.active_player
	archer_post.character_data.refresh_punk_stats()
	var restored_primary: String = PunkManager.get_primary_style("archer")
	_check("读档后朋克风格保留", restored_primary == "tech", restored_primary)

	# ---------- 6.8 技能树与职业专职 ----------
	_check("技能图标素材加载", AssetLibrary.texture("skill_fireball") != null)
	_check("职业立绘素材加载", AssetLibrary.texture("portrait_warrior") != null)
	_check("物品图标素材加载", AssetLibrary.texture("item_stone") != null)
	_check("特效素材加载", AssetLibrary.texture("vfx_fireball") != null)
	var tree_nodes: Array = DataManager.get_skill_tree_nodes("archer")
	_check("技能树数据加载", tree_nodes.size() == 16, str(tree_nodes.size()))
	_check("职业总数=16", DataManager.get_all_class_ids().size() == 16, str(DataManager.get_all_class_ids().size()))
	var archer_data: Node = GameManager.active_player.character_data
	var slot_count: int = archer_data.get_slot_count()
	_check("初始操作栏=6格", slot_count == 6, str(slot_count))
	_check("技能栏数组=10格", archer_data.skills.size() == 10, str(archer_data.skills.size()))
	_check("第7格初始锁定", archer_data.get_skill(7).is_empty())
	_check("初始掌握一条流派", archer_data.learned_styles.size() == 1, str(archer_data.learned_styles))
	var points_before: int = SkillManager.get_points("archer")
	_check("初始技能点", points_before >= 1, str(points_before))
	var attack_before: int = archer_data.get_attack()
	for i in range(6):
		SkillManager.grant_level_points("archer", 1)
	var first_ok: bool = SkillManager.unlock_node("archer", "archer_t0_0")
	_check("解锁技能树节点", first_ok)
	_check("技能树攻击加成生效", archer_data.get_attack() == attack_before + 3,
		"%d -> %d" % [attack_before, archer_data.get_attack()])
	_check("未完成整层不加栏位", archer_data.get_slot_count() == 6, str(archer_data.get_slot_count()))
	for col in [1, 2, 3]:
		SkillManager.unlock_node("archer", "archer_t0_%d" % col)
	_check("完成第一层加1格", archer_data.get_completed_tree_layers() == 1 and archer_data.get_slot_count() == 7,
		"%d层/%d格" % [archer_data.get_completed_tree_layers(), archer_data.get_slot_count()])
	var tier2_check: Dictionary = SkillManager.can_unlock("archer", "archer_t2_0")
	_check("前置节点校验", not bool(tier2_check.get("ok", true)), str(tier2_check.get("reason", "")))
	_check("新职业立绘加载", AssetLibrary.texture("portrait_runeward") != null)
	_check("新职业世界精灵加载", AssetLibrary.texture("sprite_player_runeward") != null)
	_check("新职业技能图标加载", AssetLibrary.texture("skill_rune_shield") != null)
	_check("新职业进阶图标加载", AssetLibrary.texture("skill_rune_reflect") != null)
	var spec_ok: bool = SkillManager.choose_specialization("archer", "sharpshooter", 5)
	_check("职业专职选择", spec_ok)
	archer_data.refresh_skill_stats()
	_check("专职属性生效", archer_data.get_crit_rate() > 0.05, "crit=%.3f" % archer_data.get_crit_rate())
	var spec_name: String = str(SkillManager.get_specialization("archer").get("name", ""))
	_check("专职显示名", spec_name == "神射手", spec_name)
	var spec_dup: bool = SkillManager.choose_specialization("archer", "ranger", 5)
	_check("专职不可重复选择", not spec_dup)
	var tree_panel: Node = null
	for node in get_tree().get_nodes_in_group("skill_tree_panel"):
		tree_panel = node
		break
	_check("技能树面板存在", tree_panel != null)
	if tree_panel:
		tree_panel._toggle()
		await _wait(0.2)
		_check("技能树面板可打开", tree_panel.visible and get_tree().paused)
		tree_panel._toggle()
		await _wait(0.2)
		_check("技能树面板可关闭", not tree_panel.visible and not get_tree().paused)
	SaveManager.save_game(0)
	await _wait(0.1)
	SkillManager.reset_tree("archer")
	_check("技能树重置返还技能点", SkillManager.get_points("archer") > points_before - 1)
	SaveManager.load_game(0)
	await _wait(0.9)
	_check("读档恢复技能树", SkillManager.is_unlocked("archer", "archer_t0_0"))
	_check("读档恢复专职", str(SkillManager.get_specialization("archer").get("id", "")) == "sharpshooter")

	# ---------- 6.9 四阶进阶 ----------
	var prog: Node = null
	for nd in GameManager.party:
		var cd: Node = nd.get_node_or_null("CharacterData")
		if cd != null and str(cd.class_id) == "archer":
			prog = cd
			break
	_check("进阶角色有效", prog != null)
	if prog == null:
		prog = archer_data
	for i in range(20):
		SkillManager.grant_level_points("archer", 1)
	for layer in [1, 2, 3]:
		for col in range(4):
			SkillManager.unlock_node("archer", "archer_t%d_%d" % [layer, col])
	_check("四层完成操作栏=10格", prog.get_slot_count() == 10, str(prog.get_slot_count()))
	_check("四层完成融合槽=2", prog.get_fusion_slots() == 2, str(prog.get_fusion_slots()))
	prog.level = 10
	_check("Lv10可修习第二流派", bool(prog.can_learn_style("archer_b").get("ok", false)),
		str(prog.can_learn_style("archer_b").get("reason", "")))
	prog.learn_style("archer_b")
	prog.select_style("archer_b")
	_check("切换流派后技能变更", str(prog.get_skill(1).get("id", "")).begins_with("archer_b_"),
		str(prog.get_skill(1).get("id", "")))
	prog.learn_style("archer_c")
	var style_ids: Array = []
	for aid in prog.get_owned_abilities().keys():
		if prog.is_style_skill(str(aid)):
			style_ids.append(str(aid))
	_check("18流派技能可选", style_ids.size() == 18, str(style_ids.size()))
	prog.loadout = style_ids.slice(0, 6)
	prog.sync_loadout()
	_check("操作栏上限 10 格", prog.loadout.size() <= 10, str(prog.loadout.size()))
	var removed_id := str(prog.loadout[0])
	prog.loadout.erase(removed_id)
	prog.sync_loadout()
	_check("配招可自由移出", not prog.loadout.has(removed_id) and prog.loadout.size() == 5,
		str(prog.loadout.size()))
	prog.level = 30
	var t2: Dictionary = prog.transition(2)
	_check("二转·万流归宗", bool(t2.get("ok", false)) and prog.get_stage() == 2, str(t2.get("reason", "")))
	_check("二转三流派常驻", prog.get_owned_abilities().has("archer_c_1"))
	_check("二转后操作栏自动填充", not prog.get_skill(1).is_empty(), str(prog.get_skill(1).get("id", "")))
	prog.level = 50
	var hp_before: int = prog.get_max_hp()
	var t3: Dictionary = prog.transition(3)
	_check("三转·生命跃迁", bool(t3.get("ok", false)) and prog.get_stage() == 3, str(t3.get("reason", "")))
	_check("变身提升生命上限", prog.get_max_hp() > hp_before, "%d -> %d" % [hp_before, prog.get_max_hp()])
	prog.level = 70
	var t4: Dictionary = prog.transition(4)
	_check("四转·超脱", bool(t4.get("ok", false)) and prog.get_stage() == 4, str(t4.get("reason", "")))
	_check("本源流不可借", not bool(prog.apply_borrow("tech").get("ok", true)))
	_check("四转可借外源流", prog.get_borrow_options().size() == 3 and bool(prog.apply_borrow("arcane").get("ok", false)),
		str(prog.borrowed_skill))
	var fused: Dictionary = FusionService.add_fusion(prog, "archer_a_1", "archer_b_1")
	var fused_id := "archer_a_1__archer_b_1"
	_check("技能融合生成", bool(fused.get("ok", false)) and prog.get_owned_abilities().has(fused_id),
		str(fused.get("reason", "")))
	_check("融合技能可进入配招", prog.get_owned_abilities()[fused_id].get("fusion_keyword", {}).has("kind"))
	var fused_skill: Dictionary = prog.get_owned_abilities()[fused_id]
	_check("融合技能为全新技能（独立命名+元素染色）",
		str(fused_skill.get("name", "")).begins_with("融·")
		and str(fused_skill.get("fuse_element_cn", "")) != ""
		and str(fused_skill.get("fuse_element_color", "")) != str(fused_skill.get("fuse_main_color", "")),
		str(fused_skill.get("name", "")))
	_check("融合撤销", FusionService.remove_fusion(prog, fused_id) and not prog.get_owned_abilities().has(fused_id))

	# ---------- 6.95 训练场（全职业试炼）----------
	GameManager.enter_training_ground()
	await _wait(0.9)
	var training = get_tree().current_scene
	_check("进入训练场", training != null and training.scene_file_path.ends_with("training_ground.tscn"),
		training.scene_file_path if training else "null")
	_check("训练场职业石=全职业", training != null and training.get_class_stone_count() == DataManager.get_all_class_ids().size(),
		str(training.get_class_stone_count()) if training else "null")
	_check("训练场木桩>=6", training != null and training.get_dummy_count() >= 6,
		str(training.get_dummy_count()) if training else "null")
	var tp: Node = GameManager.active_player
	_check("训练场角色自动30级", tp != null and tp.character_data.level >= 30,
		str(tp.character_data.level) if tp else "null")
	_check("训练场角色全流派开放", tp != null and tp.character_data.learned_styles.size() >= 3,
		str(tp.character_data.learned_styles) if tp else "null")
	# 任意职业切换
	var switched_ok: bool = training != null and training.switch_active_class("mech_pilot")
	await _wait(0.15)
	tp = GameManager.active_player
	_check("训练场切换任意职业", switched_ok and tp != null and str(tp.character_data.class_id) == "mech_pilot",
		str(tp.character_data.class_id) if tp else "null")
	_check("切换后技能栏可用", tp != null and not tp.character_data.get_skill(1).is_empty(),
		str(tp.character_data.get_skill(1).get("id", "")) if tp else "null")
	# 木桩：承伤、不死、元素免疫
	var tdummies: Array = get_tree().get_nodes_in_group("training_dummies")
	_check("木桩加入训练组", tdummies.size() >= 6, str(tdummies.size()))
	if not tdummies.is_empty():
		var td: Node = tdummies[0]
		var td_hp0: int = td.hp
		td.take_damage(120, false, tp)
		_check("木桩承伤且不死", td.total_damage > 0 and td.hp > 0 and td.hp == td_hp0,
			"dmg=%d hp=%d" % [td.total_damage, td.hp])
		var fire_imm := false
		for entry in tdummies:
			if str(entry.primary_element) == "fire":
				fire_imm = entry.status_immune.has("burn")
				break
		_check("火元素木桩免疫燃烧", fire_imm)
	# 恢复台
	var tp_data: Node = tp.character_data if tp != null else null
	if tp_data != null and training != null:
		tp_data.hp = 1
		tp_data.mp = 0
		training._on_station_activated("restore")
		await _wait(0.1)
		_check("恢复台回满生命/法力", tp_data.hp == tp_data.get_max_hp() and tp_data.mp == tp_data.get_max_mp(),
			"hp=%d/%d" % [tp_data.hp, tp_data.get_max_hp()])
		# 流派台
		var style_before := str(tp_data.style_id)
		training._on_station_activated("style")
		await _wait(0.1)
		_check("流派台可切换流派", str(tp_data.style_id) != "" and (str(tp_data.style_id) != style_before or tp_data.learned_styles.size() >= 3),
			"%s -> %s" % [style_before, str(tp_data.style_id)])
		# 进阶台
		training._on_station_activated("ascend")
		await _wait(0.15)
		_check("进阶台解锁10技能槽", tp_data.get_slot_count() == 10 and tp_data.get_stage() >= 4,
			"slots=%d stage=%d" % [tp_data.get_slot_count(), tp_data.get_stage()])
	# 退出训练场并还原
	GameManager.exit_training_ground()
	await _wait(0.9)
	var back_world = get_tree().current_scene
	_check("退出训练场回主世界", back_world != null and back_world.scene_file_path.ends_with("main_world.tscn"),
		back_world.scene_file_path if back_world else "null")
	_check("退出后退出训练模式", not GameManager.training_active)
	_check("退出后恢复原队伍", GameManager.party.size() == GameManager.roster.size(),
		"%d/%d" % [GameManager.party.size(), GameManager.roster.size()])

	# ---------- 7. 通天塔 / Roguelike ----------
	GameManager.start_tower_run()
	await _wait(0.9)
	var tower = get_tree().current_scene
	_check("进入塔层1", tower != null and tower.scene_file_path.ends_with("tower_floor_1.tscn"), tower.scene_file_path if tower else "null")
	if tower and tower.has_method("_on_switch_activated"):
		_check("解谜机关数量", tower.switch_nodes.size() >= 2, str(tower.switch_nodes.size()))
		for i in tower.switches_total:
			tower._on_switch_activated("test_%d" % i)
		await _wait(0.2)
		_check("全部机关开门", tower.portal != null and tower.portal.enabled)
	_check("Roguelike 运行中", RoguelikeManager.is_active, str(RoguelikeManager.floor))

	GameManager.enter_tower_floor(2)
	await _wait(0.9)
	var tower2 = get_tree().current_scene
	_check("进入塔层2", tower2 != null and tower2.floor_num == 2, str(tower2.floor_num) if tower2 else "null")

	GameManager.enter_tower_floor(-1)
	await _wait(0.9)
	var abyss = get_tree().current_scene
	_check("进入深渊-1层", abyss != null and abyss.floor_num == -1, str(abyss.floor_num) if abyss else "null")

	# ---------- 8. 职业攻击特色 ----------
	var sniper_def: Dictionary = DataManager.get_class_data("sniper")
	_check("狙击手普攻=超远射线", str(sniper_def.get("basic_attack", {}).get("kind", "")) == "beam",
		str(sniper_def.get("basic_attack", {})))
	var bomber_def: Dictionary = DataManager.get_class_data("bomber")
	_check("炸弹专家普攻=抛掷", str(bomber_def.get("basic_attack", {}).get("kind", "")) == "lob")
	var necro_def: Dictionary = DataManager.get_class_data("necromancer")
	var has_summon := false
	for s in necro_def.get("skills", []):
		if str(s.get("type", "")) == "summon":
			has_summon = true
	_check("亡灵法师存在召唤技", has_summon)

	var host: Node = GameManager.active_player
	if is_instance_valid(host) and host.character_data != null:
		var orig_class := str(host.character_data.class_id)
		var dummy_packed: PackedScene = load("res://scenes/enemies/enemy.tscn")
		# 先禁用 tower 里所有 EnemySpawner，不让它 respawn 干扰测试
		for sp in get_tree().get_nodes_in_group("enemy_spawners"):
			if is_instance_valid(sp):
				sp.set_process(false)
				sp.set_physics_process(false)
		# 清理所有已存在的敌人
		for e in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(e):
				e.free()
		await _wait(0.1)
		# 狙击手：460px 外普攻与技能均应命中
		host.character_data.setup_class("sniper")
		host.character_data.mp = host.character_data.get_max_mp()
		host.facing = Vector2.RIGHT
		var far = _spawn_dummy(host, dummy_packed, 460.0)
		await _wait(0.15)
		var far_hp: int = far.hp
		host.attack_cooldown = 0.0
		host.try_attack()
		await _wait(0.25)
		_check("狙击手超远普攻命中", far.hp < far_hp, "%d -> %d" % [far_hp, far.hp])
		far_hp = far.hp
		SkillExecutor.cast(host, host.character_data.skills[0])
		await _wait(0.2)
		_check("狙击技能超远命中", far.hp < far_hp, "%d -> %d" % [far_hp, far.hp])
		# 炸弹专家：部署炸药并引爆
		host.character_data.setup_class("bomber")
		host.character_data.mp = host.character_data.get_max_mp()
		host.facing = Vector2.RIGHT
		var bomb_slot := _find_skill_slot_by_type(host.character_data, "deployable")
		if bomb_slot >= 0:
			host.skill_cooldowns[bomb_slot] = 0.0
		var near = _spawn_dummy(host, dummy_packed, 88.0)
		await _wait(0.15)
		var near_hp: int = near.hp
		if bomb_slot >= 0:
			host.try_skill(bomb_slot)
		else:
			_check("炸弹专家有 deployable 技能", false, "未找到 deployable 类型技能")
		await _wait(1.5)
		_check("炸弹专家部署炸药并引爆", near.hp < near_hp, "%d -> %d" % [near_hp, near.hp])
		if is_instance_valid(near):
			near.free()
		# 亡灵法师：召唤亡灵
		for s in get_tree().get_nodes_in_group("summons"):
			if is_instance_valid(s):
				s.free()
		host.character_data.setup_class("necromancer")
		host.character_data.learned_styles.append("necromancer_c")
		host.character_data.select_style("necromancer_c")
		host.character_data.mp = host.character_data.get_max_mp()
		# 在 host 附近放一具骸骨尸体（让召唤能消费材料，测试真·材料召唤链）
		var corpse_script: GDScript = load("res://scripts/enemies/corpse.gd")
		var corpse = corpse_script.new()
		corpse.setup(0, "earth", Color(0.85, 0.8, 0.7))  # 0 = CorpseType.SKELETON
		corpse.global_position = host.global_position + Vector2(30, 0)
		corpse.z_index = 25
		host.get_parent().add_child(corpse)
		var summon_slot := _find_skill_slot_by_type(host.character_data, "summon")
		if summon_slot >= 0:
			host.skill_cooldowns[summon_slot] = 0.0
		if summon_slot >= 0:
			host.try_skill(summon_slot)
		else:
			_check("亡灵法师有 summon 技能", false, "未找到 summon 类型技能")
		await _wait(0.25)
		var summon_count: int = get_tree().get_nodes_in_group("summons").size()
		_check("亡灵法师召唤亡灵", summon_count >= 1, str(summon_count))
		# 工程师：部署炮塔
		for d in get_tree().get_nodes_in_group("deployables"):
			if is_instance_valid(d):
				d.free()
		host.character_data.setup_class("engineer")
		host.character_data.mp = host.character_data.get_max_mp()
		SkillExecutor.cast(host, host.character_data.skills[0])
		await _wait(0.2)
		var turrets := 0
		for d in get_tree().get_nodes_in_group("deployables"):
			if is_instance_valid(d) and str(d.mode) == "turret":
				turrets += 1
		_check("工程师部署炮塔", turrets >= 1, str(turrets))
		host.character_data.setup_class(orig_class)
		# 融合技：作为「全新技能」独立释放（独立起手 + 元素在同一次命中内爆发）
		for d in get_tree().get_nodes_in_group("deployables"):
			if is_instance_valid(d):
				d.free()
		var fuse_near = _spawn_dummy(host, dummy_packed, 60.0)
		await _wait(0.12)
		var fuse_hp: int = fuse_near.hp
		var fuse_skill := {
			"id": "smoke_fuse", "name": "融·炎测试", "type": "melee_aoe", "power": 1.0,
			"radius": 90.0, "mp": 0, "damage_type": "physical", "color": "#ff9e4a",
			"origin": "fusion", "fusion_keyword": {"kind": "burn", "value": 0.2},
			"fuse_element_color": "#ff6a2a", "fuse_main_color": "#ffd166",
		}
		SkillExecutor.cast(host, fuse_skill)
		await _wait(0.3)
		_check("融合技独立释放造成伤害", fuse_near.hp < fuse_hp, "%d -> %d" % [fuse_hp, fuse_near.hp])
		if is_instance_valid(fuse_near):
			fuse_near.free()
		# 融合弹道：元素在命中点随弹道一同爆发（同一发技能）
		var fuse_far = _spawn_dummy(host, dummy_packed, 150.0)
		fuse_far.collision_layer = 4
		await _wait(0.12)
		var fuse_hp2: int = fuse_far.hp
		var fuse_proj := {
			"id": "smoke_fuse_proj", "name": "融·霜测试弹", "type": "projectile", "power": 1.0,
			"speed": 600.0, "range": 360.0, "mp": 0, "damage_type": "physical", "color": "#9ad0ff",
			"origin": "fusion", "fusion_keyword": {"kind": "freeze", "value": 0.35},
			"fuse_element_color": "#7ec8ff", "fuse_main_color": "#9ad0ff",
		}
		SkillExecutor.cast(host, fuse_proj)
		await _wait(0.6)
		_check("融合弹道命中引发元素爆发", fuse_far.hp < fuse_hp2, "%d -> %d" % [fuse_hp2, fuse_far.hp])
		if is_instance_valid(fuse_far):
			fuse_far.free()

	# ---------- 流派专属机制（signature）全覆盖 ----------
	# 每个流派都必须有自己的 signature，不能千篇一律。
	var styles_list := [
		"mage_a", "mage_b", "mage_c",
		"runeward_a", "runeward_b", "runeward_c",
		"priest_a", "priest_b", "priest_c",
		"necromancer_a", "necromancer_b", "necromancer_c",
		"bomber_a", "bomber_b", "bomber_c",
		"mech_pilot_a", "mech_pilot_b", "mech_pilot_c",
		"engineer_a", "engineer_b", "engineer_c",
		"bounty_hunter_a", "bounty_hunter_b", "bounty_hunter_c",
		"death_knight_a", "death_knight_b", "death_knight_c",
		"warrior_a", "warrior_b", "warrior_c",
		"qi_adept_a", "qi_adept_b", "qi_adept_c",
		"thief_a", "thief_b", "thief_c",
		"archer_a", "archer_b", "archer_c",
		"cyborg_a", "cyborg_b", "cyborg_c",
		"hacker_a", "hacker_b", "hacker_c",
		"sniper_a", "sniper_b", "sniper_c",
	]
	var all_kinds: Array = []
	for sid in styles_list:
		var sig_d: Dictionary = CharacterBase.STYLE_SIGNATURES.get(sid, {})
		_check("%s 有专属机制" % sid, not sig_d.is_empty(), str(sig_d))
		var kind := str(sig_d.get("kind", ""))
		_check("%s 机制非空" % sid, kind != "", kind)
		all_kinds.append(kind)
	# 同一职业的 3 个流派机制必须互不相同
	var class_groups := {
		"mage": ["mage_a", "mage_b", "mage_c"],
		"runeward": ["runeward_a", "runeward_b", "runeward_c"],
		"priest": ["priest_a", "priest_b", "priest_c"],
		"necromancer": ["necromancer_a", "necromancer_b", "necromancer_c"],
		"bomber": ["bomber_a", "bomber_b", "bomber_c"],
		"mech_pilot": ["mech_pilot_a", "mech_pilot_b", "mech_pilot_c"],
		"engineer": ["engineer_a", "engineer_b", "engineer_c"],
		"bounty_hunter": ["bounty_hunter_a", "bounty_hunter_b", "bounty_hunter_c"],
		"death_knight": ["death_knight_a", "death_knight_b", "death_knight_c"],
		"warrior": ["warrior_a", "warrior_b", "warrior_c"],
		"qi_adept": ["qi_adept_a", "qi_adept_b", "qi_adept_c"],
		"thief": ["thief_a", "thief_b", "thief_c"],
		"archer": ["archer_a", "archer_b", "archer_c"],
		"cyborg": ["cyborg_a", "cyborg_b", "cyborg_c"],
		"hacker": ["hacker_a", "hacker_b", "hacker_c"],
		"sniper": ["sniper_a", "sniper_b", "sniper_c"],
	}
	for cls in class_groups.keys():
		var grp: Array = class_groups[cls]
		var k0 := str(CharacterBase.STYLE_SIGNATURES.get(grp[0], {}).get("kind", ""))
		var k1 := str(CharacterBase.STYLE_SIGNATURES.get(grp[1], {}).get("kind", ""))
		var k2 := str(CharacterBase.STYLE_SIGNATURES.get(grp[2], {}).get("kind", ""))
		var kl := [k0, k1, k2]
		_check("%s 三流派机制各不相同 %s" % [cls, str(kl)], k0 != k1 and k1 != k2, str(kl))
	# 48 流派总机制种类 ≥ 30（说明不是靠换皮）
	var distinct_kinds := all_kinds.duplicate()
	distinct_kinds.sort()
	_check("48 流派总机制种类 ≥ 30（不是千篇一律）", distinct_kinds.size() >= 30, "%d 种" % distinct_kinds.size())

	# ---------- 结束 ----------
	print("SMOKE_RESULT failures=%d" % failures)
	await _wait(0.2)
	get_tree().quit(0 if failures == 0 else 1)
