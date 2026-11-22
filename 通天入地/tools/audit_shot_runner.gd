# ============================================================
# AuditShotRunner — 全功能页面截图（系统测试审计用）
# 仅测试用途：遍历所有功能页面并输出真实渲染截图
# 不修改任何游戏逻辑，只调用既有公开/内部方法驱动界面
# ============================================================

extends Node

var out_dir := ProjectSettings.globalize_path("res://") + "docs/audit_screenshots/"
var shot_count := 0

func _ready() -> void:
	call_deferred("_attach")

func _attach() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var parent := get_parent()
	if parent != null and parent != tree.root:
		parent.remove_child(self)
		tree.root.add_child(self)
	call_deferred("_run")

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	img.save_jpg(out_dir + shot_name + ".jpg", 0.9)
	shot_count += 1
	print("AUDIT_SHOT %02d %s" % [shot_count, shot_name])

func _group_first(group: String) -> Node:
	var nodes := get_tree().get_nodes_in_group(group)
	return nodes[0] if not nodes.is_empty() else null

func _find_by_name(name_str: String) -> Node:
	return get_tree().root.find_child(name_str, true, false)

func _camera() -> Camera2D:
	var world = GameManager.current_world
	if world == null:
		return null
	var cam = world.get_node_or_null("Camera2D")
	if cam is Camera2D:
		return cam
	return null

func _run() -> void:
	await _wait(0.6)

	# ===== 1. 主菜单 =====
	GameManager.enter_main_menu()
	await _wait(1.6)
	await _shot("01_main_menu")

	# ===== 2. 主菜单设置面板 =====
	var menu := _group_first("main_menu")
	if menu == null:
		menu = _find_by_name("MainMenu")
	if menu != null and menu.has_method("_toggle_settings"):
		menu.call("_toggle_settings")
		await _wait(0.5)
		await _shot("02_main_menu_settings")
		menu.call("_toggle_settings")
		await _wait(0.4)
	else:
		print("AUDIT_SKIP 02_main_menu_settings (no menu)")

	# ===== 3. 主世界 + HUD =====
	GameManager.start_new_game()
	await _wait(2.6)
	await _shot("03_world_hud")

	# ===== 4. 世界近景（掉落物 + 立绘 + 地面） =====
	var player = GameManager.active_player
	if player:
		player.global_position = Vector2(0, 0)
	var pickups := [
		{"id": "slime_gel", "pos": Vector2(-60, 20)},
		{"id": "iron_ore", "pos": Vector2(-20, 40)},
		{"id": "mech_core", "pos": Vector2(20, 40)},
		{"id": "ghost_dust", "pos": Vector2(60, 20)},
	]
	for p in pickups:
		var node = load("res://scripts/world/pickup.gd").new()
		node.item_id = str(p["id"])
		node.quantity = 1
		node.position = p["pos"]
		GameManager.current_world.add_child(node)
	await _wait(0.8)
	var cam := _camera()
	if cam:
		cam.zoom = Vector2(2.2, 2.2)
	await _wait(0.8)
	await _shot("04_world_closeup")
	if cam:
		cam.zoom = Vector2(1.0, 1.0)
	await _wait(0.4)

	# ===== 5. 技能特效 =====
	if player and is_instance_valid(player):
		player.facing = Vector2.RIGHT
		for i in 6:
			player.try_skill(i)
			await _wait(0.25)
		await _shot("05_skill_vfx")
		await _wait(0.5)

	# ===== 6. 技能树 =====
	var tree_panel := _group_first("skill_tree_panel")
	if tree_panel:
		tree_panel.call("_toggle")
		await _wait(1.0)
		await _shot("06_skill_tree")
		# 流派配招页签
		if tree_panel.has_method("_show_tab"):
			tree_panel.call("_show_tab", "build")
			await _wait(0.8)
			await _shot("07_skill_build")
			tree_panel.call("_show_tab", "fusion")
			await _wait(0.8)
			await _shot("07b_skill_fusion")
			tree_panel.call("_show_tab", "tree")
		tree_panel.call("_toggle")
		await _wait(0.5)
	else:
		print("AUDIT_SKIP 06/07 skill_tree_panel missing")

	# ===== 7. 背包三页签 =====
	var inv := _group_first("inventory_panel")
	if inv:
		inv.call("open_panel")
		await _wait(0.8)
		await _shot("08_inventory_bag")
		if inv.get("tabs") != null:
			inv.tabs.current_tab = 1
			await _wait(0.6)
			await _shot("09_inventory_craft")
			inv.tabs.current_tab = 2
			await _wait(0.6)
			await _shot("10_inventory_shop")
			inv.tabs.current_tab = 0
		inv.call("close_panel")
		await _wait(0.5)
	else:
		print("AUDIT_SKIP 08/09/10 inventory_panel missing")

	# ===== 8. 朋克改造台 =====
	var punk := _group_first("punk_panel")
	if punk:
		punk.call("_toggle")
		await _wait(0.9)
		await _shot("11_punk_panel")
		punk.call("_toggle")
		await _wait(0.5)
	else:
		print("AUDIT_SKIP 11 punk_panel missing")

	# ===== 9. 暂停菜单 =====
	GameManager.open_pause()
	await _wait(0.6)
	await _shot("12_pause_menu")
	GameManager.close_pause()
	await _wait(0.4)

	# ===== 10. 建造面板 =====
	BuildManager.toggle_build_mode()
	await _wait(0.7)
	await _shot("13_build_mode")
	BuildManager.toggle_build_mode()
	await _wait(0.4)

	# ===== 11. NPC 对话框 =====
	var dlg := _group_first("dialogue_box")
	if dlg:
		dlg.call("show_dialogue", "铁匠 · 铁砧", [
			"这年头，法术朋克和机械朋克在塔里打得不可开交。",
			"想过塔？先把外头的史莱姆清干净，我才有闲工夫给你打铁。",
		])
		await _wait(0.7)
		await _shot("14_dialogue")
		dlg.call("_close")
		await _wait(0.4)
	else:
		print("AUDIT_SKIP 14 dialogue_box missing")

	# ===== 12. 触屏控制（强制显示） =====
	var touch := _find_by_name("TouchControls")
	if touch:
		var prev: bool = bool(touch.get("visible"))
		var prev_mode = InputManager.current_mode
		InputManager.current_mode = InputManager.InputMode.TOUCH
		touch.set("visible", true)
		await _wait(0.6)
		await _shot("15_touch_controls")
		touch.set("visible", prev)
		InputManager.current_mode = prev_mode
	else:
		print("AUDIT_SKIP 15 TouchControls missing")

	# ===== 13. 通天塔第 1 层 =====
	GameManager.enter_tower_floor(1)
	await _wait(2.8)
	await _shot("16_tower_floor")

	# ===== 14. 深渊 -1 层 =====
	GameManager.enter_tower_floor(-1)
	await _wait(2.8)
	await _shot("17_abyss_floor")

	print("AUDIT_DONE shots=%d" % shot_count)
	get_tree().quit(0)
