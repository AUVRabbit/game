# ============================================================
# World — 开放世界关卡脚本
# 负责：玩家队伍生成、刷怪器、NPC、传送门、建造恢复
# ============================================================

extends Node2D

const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"
const SPAWNER_SCRIPT := preload("res://scripts/enemies/enemy_spawner.gd")
const NPC_SCRIPT := preload("res://scripts/world/npc.gd")
const PORTAL_SCRIPT := preload("res://scripts/world/portal.gd")
const RESOURCE_SCRIPT := preload("res://scripts/world/resource_node.gd")
const ALTAR_SCRIPT := preload("res://scripts/world/class_altar.gd")

var dynamic_root: Node2D

func _ready() -> void:
	dynamic_root = get_node_or_null("Dynamic")
	if dynamic_root == null:
		dynamic_root = Node2D.new()
		dynamic_root.name = "Dynamic"
		add_child(dynamic_root)
	GameManager.bind_level(self)
	BuildManager.restore_scene(self)
	_setup_camera()
	_setup_spawners()
	_setup_npcs()
	_setup_resources()
	_setup_altar()
	_setup_portals()
	AudioManager.play_bgm("world")
	EventBus.notify("WASD 移动 · 左键/空格攻击 · 1/2/3 技能 · Shift 冲刺 · E 交互/采集 · I 背包 · B 建造 · Q/P 换职业")
	queue_redraw()

func _setup_camera() -> void:
	var camera := get_node_or_null("Camera2D")
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	camera.make_current()
	camera.zoom = Vector2(1.0, 1.0)

func _setup_spawners() -> void:
	var enemy_packed: PackedScene = load(ENEMY_SCENE)
	if enemy_packed == null:
		push_error("[World] 敌人场景缺失")
		return
	_add_spawner(Vector2(430, 70), enemy_packed, {
		"enemy_name": "史莱姆", "enemy_type": "slime", "max_hp": 42, "attack": 8,
		"defense": 2, "magic_defense": 1, "exp_reward": 18,
		"gold_reward_min": 3, "gold_reward_max": 8, "move_speed": 68.0,
		"body_color": Color(0.35, 0.85, 0.5), "body_radius": 15.0,
		"drop_table": [{ "id": "slime_gel", "chance": 0.7, "min": 1, "max": 2 }]
	}, 4)
	_add_spawner(Vector2(-430, 130), enemy_packed, {
		"enemy_name": "机械蛛", "enemy_type": "mech", "max_hp": 85, "attack": 12,
		"defense": 7, "magic_defense": 3, "exp_reward": 36,
		"gold_reward_min": 8, "gold_reward_max": 15, "move_speed": 60.0,
		"body_color": Color(0.65, 0.65, 0.72), "body_radius": 20.0,
		"drop_table": [
			{ "id": "iron_ore", "chance": 0.55, "min": 1, "max": 2 },
			{ "id": "mech_core", "chance": 0.25, "min": 1, "max": 1 }
		]
	}, 3)
	_add_spawner(Vector2(60, 220), enemy_packed, {
		"enemy_name": "幽魂", "enemy_type": "wraith", "max_hp": 55, "attack": 14,
		"defense": 3, "magic_defense": 8, "exp_reward": 32,
		"gold_reward_min": 6, "gold_reward_max": 12, "move_speed": 96.0,
		"body_color": Color(0.55, 0.65, 1.0), "body_radius": 15.0,
		"drop_table": [{ "id": "ghost_dust", "chance": 0.6, "min": 1, "max": 2 }]
	}, 3)

func _add_spawner(pos: Vector2, enemy_scene: PackedScene, config: Dictionary, max_alive: int) -> void:
	var spawner = SPAWNER_SCRIPT.new()
	spawner.enemy_scene = enemy_scene
	spawner.enemy_config = config
	spawner.max_alive = max_alive
	spawner.initial_count = mini(2, max_alive)
	spawner.spawn_radius = 150.0
	spawner.position = pos
	dynamic_root.add_child(spawner)

func _setup_npcs() -> void:
	_add_npc(Vector2(170, 130), "铁匠 · 铁砧", "npc_blacksmith", "q_slime_hunt", Color(0.9, 0.55, 0.3))
	_add_npc(Vector2(-170, 130), "学者 · 塔语", "npc_scholar", "q_tower_2", Color(0.55, 0.7, 0.95))
	_add_npc(Vector2(0, 60), "工匠 · 铆钉", "npc_artisan", "q_craft_iron", Color(0.85, 0.75, 0.35))

func _add_npc(pos: Vector2, npc_name: String, dialogue_id: String, quest_id: String, color: Color) -> void:
	var npc = NPC_SCRIPT.new()
	npc.npc_name = npc_name
	npc.dialogue_id = dialogue_id
	npc.quest_id = quest_id
	npc.npc_color = color
	npc.position = pos
	dynamic_root.add_child(npc)

func _setup_portals() -> void:
	var portal = PORTAL_SCRIPT.new()
	portal.portal_id = "tower_entrance"
	portal.target_floor = 1
	portal.label_text = "通天塔"
	portal.position = Vector2(470, 0)
	dynamic_root.add_child(portal)

func _setup_resources() -> void:
	_add_resource(Vector2(-300, 120), "wood", 3)
	_add_resource(Vector2(-420, 40), "wood", 2)
	_add_resource(Vector2(300, 120), "stone", 3)
	_add_resource(Vector2(420, 40), "stone", 2)
	_add_resource(Vector2(-200, -60), "herb", 2)
	_add_resource(Vector2(200, -60), "herb", 2)
	_add_resource(Vector2(0, 200), "iron_ore", 1)
	_add_resource(Vector2(100, 220), "leather", 1)

func _add_resource(pos: Vector2, resource_id: String, quantity: int) -> void:
	var node = RESOURCE_SCRIPT.new()
	node.resource_id = resource_id
	node.quantity = quantity
	node.position = pos
	dynamic_root.add_child(node)

func _setup_altar() -> void:
	var altar = ALTAR_SCRIPT.new()
	altar.position = Vector2(-360, -90)
	dynamic_root.add_child(altar)

func _draw() -> void:
	var bm := BuildManager
	var corners := PackedVector2Array([
		bm.grid_to_world(Vector2i(-18, -18)),
		bm.grid_to_world(Vector2i(18, -18)),
		bm.grid_to_world(Vector2i(18, 18)),
		bm.grid_to_world(Vector2i(-18, 18))
	])
	draw_colored_polygon(corners, Color(0.16, 0.26, 0.18))
	var step := 3
	for i in range(-18, 19, step):
		var a := bm.grid_to_world(Vector2i(i, -18))
		var b := bm.grid_to_world(Vector2i(i, 18))
		draw_line(a, b, Color(1, 1, 1, 0.05), 1.0)
		var c := bm.grid_to_world(Vector2i(-18, i))
		var d := bm.grid_to_world(Vector2i(18, i))
		draw_line(c, d, Color(1, 1, 1, 0.05), 1.0)
	draw_circle(Vector2.ZERO, 120.0, Color(0.2, 0.32, 0.22, 0.55))
