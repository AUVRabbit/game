# ============================================================
# TowerFloor — 通天塔程序化楼层
# 开关解谜 → 开门 → 传送门进入下一层
# 第 2 层包含职业限定机关；每 5 层出现精英/BOSS
# ============================================================

extends Node2D

const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"
const SPAWNER_SCRIPT := preload("res://scripts/enemies/enemy_spawner.gd")
const SWITCH_SCRIPT := preload("res://scripts/world/puzzle_switch.gd")
const PORTAL_SCRIPT := preload("res://scripts/world/portal.gd")

var floor_num: int = 1
var switches_total: int = 2
var switches_done: int = 0
var door: StaticBody2D = null
var portal: Node = null
var dynamic_root: Node2D = null
var switch_nodes: Array = []
var puzzle_time_limit: float = 25.0
var puzzle_time_left: float = 0.0
var puzzle_running: bool = false
var puzzle_label: Label = null

func _ready() -> void:
	floor_num = GameManager.pending_floor if GameManager else 1
	dynamic_root = Node2D.new()
	dynamic_root.name = "Dynamic"
	add_child(dynamic_root)
	GameManager.bind_level(self)
	BuildManager.restore_scene(self)
	_setup_camera()
	_build_floor()
	AudioManager.play_bgm("tower")
	EventBus.notify("通天塔第 %d 层：激活全部机关以开启传送门" % floor_num)
	queue_redraw()

func _setup_camera() -> void:
	var camera := get_node_or_null("Camera2D")
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	camera.make_current()
	camera.zoom = Vector2(1.0, 1.0)

func _build_floor() -> void:
	var depth: int = maxi(1, absi(floor_num))
	switches_total = clampi(1 + depth, 2, 4)
	switches_done = 0
	var center := Vector2(0, -20)
	var radius := clampf(170.0 + float(depth) * 4.0, 170.0, 240.0)

	for i in switches_total:
		var angle := TAU * float(i) / float(switches_total) - PI * 0.5
		var sw = SWITCH_SCRIPT.new()
		sw.switch_id = "switch_%d" % i
		sw.switch_color = Color(0.95, 0.35 + 0.15 * i, 0.35)
		if floor_num == 2 and i == 0:
			sw.required_class = "mage"
		sw.position = center + Vector2(cos(angle), sin(angle) * 0.55) * radius
		sw.switch_activated.connect(_on_switch_activated)
		dynamic_root.add_child(sw)
		switch_nodes.append(sw)

	# 门
	door = StaticBody2D.new()
	door.name = "LockedDoor"
	door.collision_layer = 1
	door.collision_mask = 0
	door.position = Vector2(0, -280)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(150, 34)
	shape.shape = rect
	door.add_child(shape)
	var door_color := ColorRect.new()
	door_color.color = Color(0.45, 0.3, 0.55, 0.85)
	door_color.position = Vector2(-75, -20)
	door_color.size = Vector2(150, 40)
	door.add_child(door_color)
	dynamic_root.add_child(door)

	# 传送门（下层 / 上层）
	var up_target: int = floor_num + 1
	portal = PORTAL_SCRIPT.new()
	portal.portal_id = "tower_floor_%d_portal" % floor_num
	portal.target_floor = up_target
	portal.label_text = "返回地面" if up_target <= 0 else "第 %d 层" % up_target
	portal.position = Vector2(0, -360)
	dynamic_root.add_child(portal)
	portal.set_enabled(false)

	if depth < 99:
		var down_portal = PORTAL_SCRIPT.new()
		var down_target: int = -1 if floor_num == 1 else floor_num - 1
		down_portal.portal_id = "tower_floor_%d_down" % floor_num
		down_portal.target_floor = down_target
		down_portal.portal_color = Color(0.35, 0.7, 0.95)
		if down_target < 0:
			down_portal.label_text = "深渊 · 第 %d 层" % maxi(1, absi(down_target))
		else:
			down_portal.label_text = "第 %d 层" % down_target
		down_portal.position = Vector2(0, 340)
		dynamic_root.add_child(down_portal)
		down_portal.set_enabled(true)

	_spawn_enemies()

	var label := Label.new()
	if floor_num > 0:
		label.text = "通天塔 · 第 %d 层" % floor_num
	else:
		label.text = "深渊 · 第 %d 层" % depth
	label.position = Vector2(-110, -300)
	label.size = Vector2(220, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	dynamic_root.add_child(label)

	puzzle_label = Label.new()
	puzzle_label.position = Vector2(-110, -338)
	puzzle_label.size = Vector2(220, 24)
	puzzle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	puzzle_label.add_theme_font_size_override("font_size", 14)
	puzzle_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	puzzle_label.text = "第一个机关激活后开始 %d 秒倒计时" % int(puzzle_time_limit)
	dynamic_root.add_child(puzzle_label)

func _spawn_enemies() -> void:
	var enemy_packed: PackedScene = load(ENEMY_SCENE)
	if enemy_packed == null:
		return
	var depth: int = maxi(1, absi(floor_num))
	var is_boss_floor := depth % 5 == 0
	var extra := 0
	if RoguelikeManager and RoguelikeManager.is_active:
		extra = RoguelikeManager.extra_elite()
	var spawner = SPAWNER_SCRIPT.new()
	spawner.enemy_scene = enemy_packed
	spawner.position = Vector2(0, 80)
	spawner.spawn_radius = 210.0
	spawner.respawn_time = 9.0
	if is_boss_floor:
		spawner.max_alive = 1 + extra
		spawner.initial_count = 1
		spawner.enemy_config = {
			"enemy_name": "塔卫 · BOSS", "enemy_type": "boss",
			"max_hp": 220 + depth * 45, "attack": 14 + depth * 2,
			"defense": 8, "magic_defense": 6, "exp_reward": 120 + depth * 20,
			"gold_reward_min": 40, "gold_reward_max": 70, "move_speed": 62.0,
			"is_boss": true, "body_radius": 28.0,
			"body_color": Color(0.85, 0.3, 0.35),
			"drop_table": [
				{ "id": "mech_core", "chance": 0.9, "min": 1, "max": 2 },
				{ "id": "ghost_dust", "chance": 0.7, "min": 1, "max": 2 }
			]
		}
	else:
		spawner.max_alive = 2 + mini(3, depth) + extra
		spawner.initial_count = 2 + extra
		spawner.enemy_config = {
			"enemy_name": "塔中构装体", "enemy_type": "tower_guard",
			"max_hp": 45 + depth * 14, "attack": 7 + depth * 2,
			"defense": 2 + depth, "magic_defense": 1 + depth,
			"exp_reward": 16 + depth * 6,
			"gold_reward_min": 3 + depth, "gold_reward_max": 8 + depth * 2,
			"move_speed": 72.0 + depth * 2.0,
			"body_color": Color(0.4 + 0.04 * depth, 0.45, 0.85 - 0.03 * depth),
			"body_radius": 16.0,
			"drop_table": [
				{ "id": "iron_ore", "chance": 0.45, "min": 1, "max": 2 },
				{ "id": "ghost_dust", "chance": 0.35, "min": 1, "max": 2 }
			]
		}
	dynamic_root.add_child(spawner)

func _on_switch_activated(_switch_id: String) -> void:
	switches_done += 1
	EventBus.notify("机关 %d/%d 已激活" % [switches_done, switches_total])
	if not puzzle_running and switches_done < switches_total:
		puzzle_running = true
		puzzle_time_left = puzzle_time_limit
	if switches_done < switches_total:
		return
	puzzle_running = false
	if puzzle_label:
		puzzle_label.text = "机关全部激活"
	if door and is_instance_valid(door):
		EffectRing.spawn(self, door.position, 90.0, Color(0.7, 0.5, 1.0, 0.9))
		door.queue_free()
		door = null
	if portal and portal.has_method("set_enabled"):
		portal.set_enabled(true)
	AudioManager.play_sfx("unlock")
	EventBus.puzzle_triggered.emit("floor_%d" % floor_num, true)
	if GameManager:
		GameManager.add_gold(10 + floor_num * 5)
	EventBus.notify("机关全部激活！传送门已开启，前往下一层")

func _process(delta: float) -> void:
	if not puzzle_running:
		return
	puzzle_time_left = maxf(0.0, puzzle_time_left - delta)
	if puzzle_label:
		puzzle_label.text = "限时机关：%.1f 秒" % puzzle_time_left
	if puzzle_time_left <= 0.0:
		_reset_puzzle()

func _reset_puzzle() -> void:
	puzzle_running = false
	switches_done = 0
	for sw in switch_nodes:
		if is_instance_valid(sw) and sw.has_method("reset_switch"):
			sw.reset_switch()
	if puzzle_label:
		puzzle_label.text = "超时！机关已重置（%d 秒）" % int(puzzle_time_limit)
	EventBus.notify("限时解谜失败：机关已全部重置")
	AudioManager.play_sfx("hurt")

func _draw() -> void:
	var extent := 1100.0
	var corners := PackedVector2Array([
		Vector2(0, -extent * 0.5), Vector2(extent, 0),
		Vector2(0, extent * 0.5), Vector2(-extent, 0)
	])
	draw_ground_texture(corners, "ground_tower", 512.0)
	for i in range(-6, 7):
		var a := Vector2(i * 64.0, -i * 32.0 - 420.0)
		draw_line(a, a + Vector2(420.0, 210.0), Color(1, 1, 1, 0.04), 1.0)
	draw_arc(Vector2(0, -20), 320.0, 0.0, TAU, 64, Color(0.7, 0.5, 1.0, 0.3), 2.0)

# 用真实地面贴图铺满区域（贴图缺失时回退纯色）
func draw_ground_texture(corners: PackedVector2Array, asset_id: String, tile_px: float) -> void:
	var tex: Texture2D = AssetLibrary.texture(asset_id)
	if tex == null:
		draw_colored_polygon(corners, Color(0.14, 0.11, 0.2))
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for point in corners:
		uvs.append(point / maxf(1.0, tile_px))
		colors.append(Color.WHITE)
	draw_polygon(corners, colors, uvs, tex)
