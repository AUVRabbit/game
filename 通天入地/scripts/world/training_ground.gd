# ============================================================
# TrainingGround — 训练场（全职业试炼）
# 用途：
#   1) 自动化测试：木桩承伤/不死、元素克制、职业切换、流派切换、恢复
#   2) 玩家熟悉：16 块职业石自由换职业，中央三台试玩 48 流派与进阶形态
# 结构：Dynamic（运行时生成） + PlayerSpawn + BuildGrid + Camera2D + GameUI
# ============================================================

extends Node2D

const DUMMY_SCRIPT := preload("res://scripts/world/training_dummy.gd")
const STONE_SCRIPT := preload("res://scripts/world/class_stone.gd")
const STATION_SCRIPT := preload("res://scripts/world/training_station.gd")
const PORTAL_SCRIPT := preload("res://scripts/world/portal.gd")

const ARENA_RADIUS := 520.0
const STONE_RING := 430.0

# 木桩配置：覆盖 7 种元素与不同状态免疫，另加 2 个移动靶
const DUMMY_SPECS: Array = [
	{"label": "木桩 · 中性", "element": "physical", "immune": [], "pos": Vector2(-300, -70), "moving": false},
	{"label": "史莱姆 · 水", "element": "water", "immune": ["stun"], "pos": Vector2(-120, -160), "moving": false},
	{"label": "岩浆怪 · 火", "element": "fire", "immune": ["burn", "slow"], "pos": Vector2(120, -160), "moving": false},
	{"label": "机械蛛 · 机", "element": "mech", "immune": ["root"], "pos": Vector2(300, -70), "moving": false},
	{"label": "幽魂 · 幽", "element": "shadow", "immune": ["root", "slow"], "pos": Vector2(-210, 40), "moving": false},
	{"label": "冰晶 · 冰", "element": "ice", "immune": ["freeze", "slow"], "pos": Vector2(210, 40), "moving": false},
	{"label": "移动靶 · 左", "element": "physical", "immune": [], "pos": Vector2(-300, 250), "moving": true},
	{"label": "移动靶 · 雷", "element": "thunder", "immune": [], "pos": Vector2(300, 250), "moving": true},
]

var dynamic_root: Node2D
var _stones: Array = []
var _dummies: Array = []
var _visited: Dictionary = {}

var _info_label: Label = null
var _panel: PanelContainer = null

func _ready() -> void:
	dynamic_root = get_node_or_null("Dynamic")
	if dynamic_root == null:
		dynamic_root = Node2D.new()
		dynamic_root.name = "Dynamic"
		add_child(dynamic_root)
	GameManager.bind_level(self)
	BuildManager.restore_scene(self)
	_setup_camera()
	_prepare_party()
	_build_dummies()
	_build_class_stones()
	_build_stations()
	_build_exit_portal()
	_build_overlay()
	AudioManager.play_bgm("world")
	EventBus.notify("训练场：靠近职业石按 E 切换职业 · 中央三台：恢复 / 流派 / 进阶 · 木桩显示实时 DPS")
	queue_redraw()

func _setup_camera() -> void:
	var camera := get_node_or_null("Camera2D")
	if camera == null:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	camera.make_current()
	camera.zoom = Vector2(1.0, 1.0)

# ------------------------------------------------------------
# 角色准备：30 级 + 全部流派，保证任何职业都能试到招牌技能
# ------------------------------------------------------------
func _prepare_party() -> void:
	for p in GameManager.party:
		if is_instance_valid(p):
			_empower(p, false)
			var d: Node = p.get_node_or_null("CharacterData")
			if d != null:
				_visited[str(d.class_id)] = true
	_refresh_overlay()

func _empower(p: Node, full: bool) -> void:
	var data: Node = p.get_node_or_null("CharacterData")
	if data == null:
		return
	var cid := str(data.class_id)
	var styles: Array = DataManager.get_class_style_ids(cid)
	data.level = maxi(int(data.level), 30)
	data.recompute()
	for sid in styles:
		var sid_s := str(sid)
		if not data.learned_styles.has(sid_s):
			data.learn_style(sid_s)
	if not styles.is_empty() and not data.learned_styles.has(str(data.style_id)):
		data.select_style(str(styles[0]))
	if full:
		_unlock_full_kit(data, cid, styles)
	data.refresh_skill_stats()
	data.hp = data.get_max_hp()
	data.mp = data.get_max_mp()
	data.shield_hp = 0
	if p.has_method("_on_stats_changed"):
		p._on_stats_changed()

# 进阶试炼：70 级 + 2/3/4 阶段跃迁 + 四层技能树全开（10 技能槽）
func _unlock_full_kit(data: Node, cid: String, styles: Array) -> void:
	data.level = maxi(int(data.level), 70)
	data.recompute()
	for sid in styles:
		var sid_s := str(sid)
		if not data.learned_styles.has(sid_s):
			data.learn_style(sid_s)
	data.transition(2)
	data.transition(3)
	data.transition(4)
	if SkillManager:
		SkillManager.ensure_class(cid)
		SkillManager.points[cid] = maxi(int(SkillManager.points.get(cid, 0)), 40)
		for layer in range(4):
			for col in range(4):
				SkillManager.unlock_node(cid, "%s_t%d_%d" % [cid, layer, col])
	data.recompute()
	data.invalidate_abilities()

# ------------------------------------------------------------
# 竞技场内容
# ------------------------------------------------------------
func _build_dummies() -> void:
	for spec in DUMMY_SPECS:
		var dummy = DUMMY_SCRIPT.new()
		dummy.dummy_label = str(spec.get("label", "木桩"))
		dummy.dummy_element = str(spec.get("element", "physical"))
		dummy.dummy_immune = (spec.get("immune", []) as Array).duplicate()
		dummy.is_moving = bool(spec.get("moving", false))
		dummy.move_span = 100.0 if dummy.is_moving else 0.0
		dummy.move_rate = 0.16 + 0.05 * float(_dummies.size() % 3)
		dummy.position = spec.get("pos", Vector2.ZERO)
		dynamic_root.add_child(dummy)
		_dummies.append(dummy)

func _build_class_stones() -> void:
	var ids: Array = DataManager.get_all_class_ids()
	var count: int = maxi(1, ids.size())
	for i in range(count):
		var stone = STONE_SCRIPT.new()
		stone.class_id = str(ids[i])
		var ang := TAU * float(i) / float(count) - PI * 0.5
		stone.position = Vector2(cos(ang) * STONE_RING, sin(ang) * STONE_RING * 0.92 + 30.0)
		stone.class_chosen.connect(_on_class_chosen)
		dynamic_root.add_child(stone)
		_stones.append(stone)

func _build_stations() -> void:
	_add_station("restore", "恢复台", Color(0.45, 0.92, 0.70), Vector2(-200, 150))
	_add_station("style", "流派台", Color(0.55, 0.78, 1.00), Vector2(0, 130))
	_add_station("ascend", "进阶台", Color(1.00, 0.86, 0.45), Vector2(200, 150))

func _add_station(mode: String, label: String, color: Color, pos: Vector2) -> void:
	var station = STATION_SCRIPT.new()
	station.mode = mode
	station.station_label = label
	station.station_color = color
	station.position = pos
	station.activated.connect(_on_station_activated)
	dynamic_root.add_child(station)

func _build_exit_portal() -> void:
	var portal = PORTAL_SCRIPT.new()
	portal.portal_id = "training_exit"
	portal.target_scene = GameManager.SCENE_MAIN_WORLD
	portal.label_text = "离开训练场"
	portal.portal_color = Color(0.55, 0.85, 1.0)
	portal.position = Vector2(0, 560)
	dynamic_root.add_child(portal)

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TrainingUI"
	add_child(layer)
	_panel = PanelContainer.new()
	_panel.position = Vector2(18, 16)
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.06, 0.08, 0.12, 0.82)
	style_box.border_color = Color(0.40, 0.85, 0.78, 0.85)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(6)
	style_box.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style_box)
	layer.add_child(_panel)
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 13)
	_info_label.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	_panel.add_child(_info_label)
	_refresh_overlay()

func _refresh_overlay() -> void:
	if _info_label == null:
		return
	var cur := "无"
	var p: Node = GameManager.active_player
	if p != null and is_instance_valid(p):
		var data: Node = p.get_node_or_null("CharacterData")
		if data != null:
			cur = str(DataManager.get_class_data(str(data.class_id)).get("name", str(data.class_id)))
	var total: int = DataManager.get_all_class_ids().size()
	_info_label.text = "训练场 · 全职业试炼\n当前职业：%s    已体验：%d / %d\nE 靠近职业石切换职业 · 中央：恢复台 / 流派台 / 进阶台\n彩色木桩：元素克制与状态免疫试验 · 下方传送门离开" % [
		cur, _visited.size(), total
	]

# ------------------------------------------------------------
# 交互回调
# ------------------------------------------------------------
func _on_class_chosen(class_id: String) -> void:
	var p: Node = GameManager.active_player
	if p != null and is_instance_valid(p):
		_empower(p, false)
	_visited[class_id] = true
	var class_name_cn := str(DataManager.get_class_data(class_id).get("name", class_id))
	EventBus.notify("已切换职业：%s（全流派已开放）" % class_name_cn)
	_refresh_overlay()

func _on_station_activated(mode: String) -> void:
	var p: Node = GameManager.active_player
	if p == null or not is_instance_valid(p):
		return
	var data: Node = p.get_node_or_null("CharacterData")
	if data == null:
		return
	match mode:
		"restore":
			_restore_player(p, data)
			EventBus.notify("已回满生命/法力，并重置全部技能冷却")
		"style":
			_cycle_style(p, data)
		"ascend":
			var before: int = int(data.get_stage())
			_empower(p, true)
			if before >= 4 and int(data.get_slot_count()) >= 10:
				EventBus.notify("当前职业已是完整进阶形态（10 技能槽）")
			else:
				EventBus.notify("进阶试炼：70 级 · 三阶跃迁 · 四层技能树全开（10 技能槽）")
			_refresh_overlay()

func _restore_player(p: Node, data: Node) -> void:
	data.hp = data.get_max_hp()
	data.mp = data.get_max_mp()
	data.shield_hp = 0
	if p is PlayerController:
		for i in range(p.skill_cooldowns.size()):
			p.skill_cooldowns[i] = 0.0
		p.attack_cooldown = 0.0
		p.dash_cd = 0.0

func _cycle_style(p: Node, data: Node) -> void:
	var styles: Array = DataManager.get_class_style_ids(str(data.class_id))
	if styles.is_empty():
		return
	var idx := 0
	for i in range(styles.size()):
		if str(styles[i]) == str(data.style_id):
			idx = i
	var next_id := str(styles[(idx + 1) % styles.size()])
	if not data.learned_styles.has(next_id):
		data.learn_style(next_id)
	data.select_style(next_id)
	data.recompute()
	_restore_player(p, data)
	var style_def: Dictionary = DataManager.styles.get(next_id, {})
	EventBus.notify("流派：%s · %s" % [
		str(style_def.get("name", next_id)),
		str(data.get_signature_desc())
	])
	_refresh_overlay()

# ------------------------------------------------------------
# 对外查询（供冒烟测试 / 外部系统）
# ------------------------------------------------------------
func get_class_stone_count() -> int:
	return _stones.size()

func get_dummy_count() -> int:
	return _dummies.size()

func switch_active_class(class_id: String) -> bool:
	var p: Node = GameManager.active_player
	if p == null or not is_instance_valid(p):
		return false
	var data: Node = p.get_node_or_null("CharacterData")
	if data == null:
		return false
	data.setup_class(class_id)
	_on_class_chosen(class_id)
	return true

func reset_all_dummies() -> void:
	for d in _dummies:
		if is_instance_valid(d):
			d.reset_stats()

# ------------------------------------------------------------
# 场景绘制：训练场石台 + 参照环
# ------------------------------------------------------------
func _draw() -> void:
	var ground_corners := PackedVector2Array([
		Vector2(-2800.0, -2000.0), Vector2(2800.0, -2000.0),
		Vector2(2800.0, 2000.0), Vector2(-2800.0, 2000.0)
	])
	draw_ground_texture(ground_corners, "ground_grass", 512.0)
	draw_ground_texture(ground_corners, "ground_grass", 512.0, Color(0.34, 0.42, 0.50, 0.42))
	# 竞技场石台
	draw_circle(Vector2(0, 30), ARENA_RADIUS, Color(0.13, 0.16, 0.21, 0.62))
	draw_arc(Vector2(0, 30), ARENA_RADIUS, 0.0, TAU, 96, Color(0.45, 0.92, 0.84, 0.75), 4.0, true)
	draw_arc(Vector2(0, 30), ARENA_RADIUS - 14.0, 0.0, TAU, 96, Color(0.10, 0.15, 0.18, 0.65), 2.0, true)
	# 职业石环 / 木桩环参照
	draw_arc(Vector2(0, 30), STONE_RING, 0.0, TAU, 96, Color(0.55, 0.95, 0.90, 0.18), 2.0, true)
	draw_arc(Vector2(0, 30), 250.0, 0.0, TAU, 72, Color(1, 1, 1, 0.10), 2.0, true)
	# 十字基准线
	draw_line(Vector2(-ARENA_RADIUS + 30, 30), Vector2(ARENA_RADIUS - 30, 30), Color(1, 1, 1, 0.06), 2.0)
	draw_line(Vector2(0, 30 - ARENA_RADIUS + 30), Vector2(0, 30 + ARENA_RADIUS - 30), Color(1, 1, 1, 0.06), 2.0)
	# 四个方向刻度
	for i in range(4):
		var a := TAU * float(i) / 4.0
		var inner := Vector2(0, 30) + Vector2(cos(a), sin(a)) * (ARENA_RADIUS - 10.0)
		var outer := Vector2(0, 30) + Vector2(cos(a), sin(a)) * (ARENA_RADIUS + 8.0)
		draw_line(inner, outer, Color(0.55, 0.95, 0.90, 0.55), 4.0)

func draw_ground_texture(corners: PackedVector2Array, asset_id: String, tile_px: float, tint: Color = Color.WHITE) -> void:
	var tex: Texture2D = AssetLibrary.texture(asset_id)
	if tex == null:
		draw_colored_polygon(corners, Color(0.16, 0.20, 0.24))
		return
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for point in corners:
		uvs.append(point / maxf(1.0, tile_px))
		colors.append(tint)
	draw_polygon(corners, colors, uvs, tex)
