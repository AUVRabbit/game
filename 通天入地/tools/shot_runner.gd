extends Node

const OUT := "/workspace/通天入地/tmp_shots/"

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
	DirAccess.make_dir_recursive_absolute(OUT)
	img.save_png(OUT + shot_name + ".png")
	print("SHOT ", shot_name)

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

	# ---------- 技能树 ----------
	for node in get_tree().get_nodes_in_group("skill_tree_panel"):
		node._toggle()
	await _wait(1.0)
	await _shot("03_skill_tree")
	for node in get_tree().get_nodes_in_group("skill_tree_panel"):
		node._toggle()
	await _wait(0.5)

	# ---------- 背包 ----------
	GameManager.open_ui(GameManager.GameState.INVENTORY)
	await _wait(0.8)
	await _shot("04_inventory")
	GameManager.close_ui()
	await _wait(0.5)

	# ---------- 改造台 ----------
	for node in get_tree().get_nodes_in_group("punk_panel"):
		node._toggle()
	await _wait(0.8)
	await _shot("05_punk_panel")
	for node in get_tree().get_nodes_in_group("punk_panel"):
		node._toggle()
	await _wait(0.5)

	# ---------- 技能特效 ----------
	var player = GameManager.active_player
	if player:
		player.facing = Vector2.RIGHT
		for i in 3:
			player.try_skill(i)
			await _wait(0.3)
		await _shot("06_skill_vfx")

	print("SHOT_DONE")
	get_tree().quit(0)
