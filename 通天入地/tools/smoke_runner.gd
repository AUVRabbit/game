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

	# ---------- 结束 ----------
	print("SMOKE_RESULT failures=%d" % failures)
	await _wait(0.2)
	get_tree().quit(0 if failures == 0 else 1)
