extends Node

var out_dir := ProjectSettings.globalize_path("res://") + "docs/screenshots/"

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
	img.save_jpg(out_dir + shot_name + ".jpg", 0.86)
	print("SHOT ", shot_name)

func _camera() -> Camera2D:
	var world = GameManager.current_world
	if world == null:
		return null
	var cam = world.get_node_or_null("Camera2D")
	if cam is Camera2D:
		return cam
	return _find_camera(world)

func _find_camera(node: Node) -> Camera2D:
	for child in node.get_children():
		if child is Camera2D:
			return child
		var found := _find_camera(child)
		if found != null:
			return found
	return null

func _run() -> void:
	await _wait(0.5)

	# ---------- 主菜单 ----------
	GameManager.enter_main_menu()
	await _wait(1.5)
	await _shot("01_main_menu")

	# ---------- 世界 HUD ----------
	GameManager.start_new_game()
	await _wait(2.5)
	print("STEP world-loaded")
	await _shot("02_world_hud")

	# ---------- 世界近景（真实地面 + 角色立绘 + 掉落物） ----------
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
	await _shot("03_world_closeup")
	if cam:
		cam.zoom = Vector2(1.0, 1.0)

	# ---------- 技能树 ----------
	for node in get_tree().get_nodes_in_group("skill_tree_panel"):
		node._toggle()
	await _wait(1.0)
	await _shot("04_skill_tree")
	for node in get_tree().get_nodes_in_group("skill_tree_panel"):
		node._toggle()
	await _wait(0.5)

	# ---------- 背包 ----------
	for node in get_tree().get_nodes_in_group("inventory_panel"):
		node.toggle_panel()
	await _wait(0.8)
	await _shot("05_inventory")
	for node in get_tree().get_nodes_in_group("inventory_panel"):
		node.close_panel()
	await _wait(0.5)

	# ---------- 改造台 ----------
	for node in get_tree().get_nodes_in_group("punk_panel"):
		node._toggle()
	await _wait(0.8)
	await _shot("06_punk_panel")
	for node in get_tree().get_nodes_in_group("punk_panel"):
		node._toggle()
	await _wait(0.5)

	# ---------- 技能特效 ----------
	var p2 = GameManager.active_player
	if p2:
		p2.facing = Vector2.RIGHT
		for i in 3:
			p2.try_skill(i)
			await _wait(0.3)
		await _shot("07_skill_vfx")

	# ---------- 通天塔地面 ----------
	GameManager.enter_tower_floor(1)
	await _wait(2.5)
	await _shot("08_tower_floor")

	print("SHOT_DONE")
	get_tree().quit(0)
