# ============================================================
# GameManager — 全局游戏管理器
# 负责：流程状态、场景切换、队伍/职业、金币、UI 阻断、死亡处理
# 注意：AutoLoad 脚本不声明 class_name
# ============================================================

extends Node

signal scene_changed(from_scene: String, to_scene: String)
signal game_paused
signal game_resumed
signal active_character_changed(player: Node)
signal roster_changed

enum GameState { MENU, PLAYING, PAUSED, DIALOG, INVENTORY, BUILDING, DEAD, SKILL_TREE }

const SCENE_MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const SCENE_MAIN_WORLD := "res://scenes/world/main_world.tscn"
const SCENE_TOWER := "res://scenes/world/tower_floor_1.tscn"
const SCENE_TRAINING := "res://scenes/world/training_ground.tscn"
const SCENE_PLAYER := "res://scenes/player/player.tscn"

const STARTING_CLASSES := ["warrior", "archer", "mage"]

var current_state: GameState = GameState.MENU
var roster: Array = STARTING_CLASSES.duplicate()
var progress: Dictionary = {}
var party: Array = []
var active_index: int = 0
var active_player: Node = null
var gold: int = 0
var inventory: Node = null
var current_world: Node = null
var level_spawn_point: Vector2 = Vector2.ZERO
var pending_floor: int = 1
var pending_player_pos: Vector2 = Vector2.ZERO
var has_pending_pos: bool = false
var last_scene_path: String = ""
var training_active: bool = false
var _training_backup: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	inventory = preload("res://scripts/economy/inventory.gd").new()
	inventory.name = "Inventory"
	add_child(inventory)
	_install_cjk_theme()
	print("[GameManager] 通天入地 · 启动完成")

func _install_cjk_theme() -> void:
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray([
		"Noto Sans CJK SC", "Noto Sans SC", "Microsoft YaHei",
		"PingFang SC", "WenQuanYi Micro Hei", "Sans-Serif"
	])
	var theme := Theme.new()
	theme.default_font = sys_font
	theme.default_font_size = 16
	get_tree().root.theme = theme

# ---------- 流程 ----------
func is_playing() -> bool:
	return current_state == GameState.PLAYING or current_state == GameState.BUILDING

func is_input_blocked() -> bool:
	if get_tree().paused:
		return true
	return current_state in [GameState.PAUSED, GameState.DIALOG, GameState.INVENTORY, GameState.DEAD, GameState.MENU, GameState.SKILL_TREE]

func is_menu() -> bool:
	return current_state == GameState.MENU

func change_scene(scene_path: String) -> void:
	capture_party()
	if get_tree().current_scene:
		last_scene_path = get_tree().current_scene.scene_file_path
		scene_changed.emit(last_scene_path, scene_path)
	else:
		scene_changed.emit("", scene_path)
	if not ResourceLoader.exists(scene_path):
		push_error("[GameManager] 场景不存在：%s" % scene_path)
		return
	get_tree().change_scene_to_file.call_deferred(scene_path)

func enter_main_menu() -> void:
	close_all_ui()
	training_active = false
	_training_backup = {}
	current_state = GameState.MENU
	party.clear()
	active_player = null
	change_scene(SCENE_MAIN_MENU)

func start_new_game() -> void:
	close_all_ui()
	training_active = false
	_training_backup = {}
	roster = STARTING_CLASSES.duplicate()
	progress.clear()
	active_index = 0
	gold = 120
	inventory.reset()
	_give_starter_items()
	if BuildManager:
		BuildManager.reset()
	if QuestManager:
		QuestManager.reset_all()
	if RoguelikeManager:
		RoguelikeManager.reset()
	current_state = GameState.PLAYING
	enter_main_world()

func _give_starter_items() -> void:
	if inventory == null:
		return
	for entry in [["stone", 8], ["wood", 8], ["herb", 4], ["healing_potion", 2]]:
		inventory.add_item(str(entry[0]), int(entry[1]))

func enter_main_world() -> void:
	current_state = GameState.PLAYING
	change_scene(SCENE_MAIN_WORLD)

func enter_tower_floor(floor_num: int) -> void:
	pending_floor = clampi(floor_num, -99, 99)
	if pending_floor == 0:
		pending_floor = 1
	current_state = GameState.PLAYING
	change_scene(SCENE_TOWER)
	if QuestManager:
		QuestManager.notify_reach_floor(pending_floor)

func start_tower_run() -> void:
	close_all_ui()
	training_active = false
	_training_backup = {}
	roster = STARTING_CLASSES.duplicate()
	progress.clear()
	gold = maxi(gold, 100)
	inventory.reset()
	_give_starter_items()
	if BuildManager:
		BuildManager.reset()
	if QuestManager:
		QuestManager.reset_all()
	if RoguelikeManager:
		RoguelikeManager.start_run(randi())
	enter_tower_floor(1)

# ---------- 训练场 ----------
# 进入训练场：备份当前队伍/进度，生成单职业试炼角色（不污染正式存档）
func enter_training_ground() -> void:
	close_all_ui()
	var from_menu := current_state == GameState.MENU
	capture_party()
	var focus_class := "warrior"
	if is_instance_valid(active_player):
		var d := active_player.get_node_or_null("CharacterData")
		if d:
			focus_class = str(d.class_id)
	elif not roster.is_empty():
		focus_class = str(roster[0])
	var return_scene := SCENE_MAIN_WORLD
	if not from_menu and get_tree().current_scene and get_tree().current_scene.scene_file_path != "":
		return_scene = get_tree().current_scene.scene_file_path
	_training_backup = {
		"roster": roster.duplicate(),
		"progress": progress.duplicate(true),
		"active_index": active_index,
		"return_scene": SCENE_MAIN_MENU if from_menu else return_scene,
		"from_menu": from_menu,
	}
	training_active = true
	roster = [focus_class]
	progress = {}
	active_index = 0
	has_pending_pos = false
	current_state = GameState.PLAYING
	_goto_scene_no_capture(SCENE_TRAINING)

# 离开训练场：还原备份的队伍与进度，回到进入前的场景
func exit_training_ground() -> void:
	if not training_active:
		enter_main_world()
		return
	training_active = false
	var backup: Dictionary = _training_backup.duplicate()
	_training_backup = {}
	roster = backup.get("roster", STARTING_CLASSES.duplicate())
	progress = backup.get("progress", {})
	active_index = int(backup.get("active_index", 0))
	has_pending_pos = false
	if bool(backup.get("from_menu", false)):
		party.clear()
		active_player = null
		current_state = GameState.MENU
		_goto_scene_no_capture(SCENE_MAIN_MENU)
		return
	var scene := str(backup.get("return_scene", SCENE_MAIN_WORLD))
	if scene == "" or not ResourceLoader.exists(scene):
		scene = SCENE_MAIN_WORLD
	current_state = GameState.PLAYING
	_goto_scene_no_capture(scene)

# 切场景但不 capture_party（训练场进出不写回正式进度）
func _goto_scene_no_capture(scene_path: String) -> void:
	if get_tree().current_scene:
		last_scene_path = get_tree().current_scene.scene_file_path
		scene_changed.emit(last_scene_path, scene_path)
	else:
		scene_changed.emit("", scene_path)
	if not ResourceLoader.exists(scene_path):
		push_error("[GameManager] 场景不存在：%s" % scene_path)
		return
	get_tree().change_scene_to_file.call_deferred(scene_path)

# ---------- 关卡绑定 ----------
func bind_level(level_node: Node) -> void:
	current_world = level_node
	var spawn := level_node.get_node_or_null("PlayerSpawn")
	level_spawn_point = (spawn as Node2D).position if spawn is Node2D else Vector2.ZERO
	spawn_party(level_node)

func spawn_party(parent_node: Node) -> void:
	party.clear()
	active_player = null
	var spawn_pos := level_spawn_point
	if has_pending_pos:
		spawn_pos = pending_player_pos
		has_pending_pos = false
	var packed: PackedScene = load(SCENE_PLAYER)
	if packed == null:
		push_error("[GameManager] 玩家场景加载失败")
		return
	for i in roster.size():
		var class_id: String = str(roster[i])
		var p := packed.instantiate()
		var data := p.get_node_or_null("CharacterData")
		if data:
			data.class_id = class_id
		p.position = spawn_pos + Vector2(i * 26, i * 12)
		parent_node.add_child(p)
		if progress.has(class_id) and data:
			data.apply_state(progress[class_id])
		party.append(p)
		if data:
			data.died.connect(_on_character_died.bind(p))
		EventBus.player_spawned.emit(p)
	active_index = clampi(active_index, 0, maxi(0, party.size() - 1))
	_set_active(active_index)
	refresh_roster_signal()

func capture_party() -> void:
	for p in party:
		if is_instance_valid(p):
			var data: Node = p.get_node_or_null("CharacterData")
			if data:
				progress[data.class_id] = data.serialize()

func _set_active(index: int) -> void:
	if party.is_empty():
		return
	active_index = clampi(index, 0, party.size() - 1)
	for i in party.size():
		var p: Node = party[i]
		if not is_instance_valid(p):
			continue
		var enabled: bool = i == active_index
		p.visible = enabled
		p.set_physics_process(enabled)
		p.set_process_unhandled_input(enabled)
		p.collision_layer = 2 if enabled else 0
		if enabled:
			p.add_to_group("player")
		else:
			p.remove_from_group("player")
	active_player = party[active_index]
	active_character_changed.emit(active_player)

func switch_character(direction: int) -> void:
	if party.size() < 2:
		return
	var old := active_player
	var new_index := posmod(active_index + direction, party.size())
	var old_pos := Vector2.ZERO
	if is_instance_valid(active_player):
		old_pos = active_player.global_position
	_set_active(new_index)
	if is_instance_valid(active_player) and old_pos != Vector2.ZERO:
		active_player.global_position = old_pos
	EventBus.character_switched.emit(active_player, old)
	EventBus.notify("切换职业：%s" % _active_class_name())

func _active_class_name() -> String:
	if active_player:
		var d := active_player.get_node_or_null("CharacterData")
		if d:
			return d.class_display_name
	return "?"

func add_to_roster(class_id: String) -> void:
	if not roster.has(class_id):
		roster.append(class_id)
		refresh_roster_signal()

func add_class_member(class_id: String) -> bool:
	if roster.has(class_id) or current_world == null:
		return false
	var packed: PackedScene = load(SCENE_PLAYER)
	if packed == null:
		return false
	var p := packed.instantiate()
	var data := p.get_node_or_null("CharacterData")
	if data == null:
		p.free()
		return false
	data.class_id = class_id
	var base_pos := level_spawn_point
	if is_instance_valid(active_player):
		base_pos = active_player.global_position
	p.position = base_pos + Vector2(30, 0)
	p.visible = false
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.collision_layer = 0
	current_world.add_child(p)
	if progress.has(class_id):
		data.apply_state(progress[class_id])
	data.died.connect(_on_character_died.bind(p))
	party.append(p)
	roster.append(class_id)
	refresh_roster_signal()
	EventBus.player_spawned.emit(p)
	return true

func refresh_roster_signal() -> void:
	roster_changed.emit()

# ---------- 金币 ----------
func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	EventBus.gold_changed.emit(gold, amount)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold, -amount)
	return true

# ---------- 暂停 / UI ----------
func open_pause() -> void:
	if current_state != GameState.PLAYING and current_state != GameState.BUILDING:
		return
	current_state = GameState.PAUSED
	get_tree().paused = true
	game_paused.emit()

func close_pause() -> void:
	if current_state != GameState.PAUSED:
		return
	get_tree().paused = false
	current_state = GameState.PLAYING
	game_resumed.emit()

func open_ui(state: GameState) -> void:
	if current_state != GameState.PLAYING and current_state != GameState.BUILDING:
		return
	current_state = state
	get_tree().paused = true

func close_ui() -> void:
	if current_state != GameState.DIALOG and current_state != GameState.INVENTORY and current_state != GameState.SKILL_TREE:
		return
	get_tree().paused = false
	current_state = GameState.PLAYING

func close_all_ui() -> void:
	get_tree().paused = false

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING or current_state == GameState.BUILDING:
			open_pause()
			get_viewport().set_input_as_handled()
		elif current_state == GameState.PAUSED:
			close_pause()
			get_viewport().set_input_as_handled()

# ---------- 死亡 ----------
func _on_character_died(player: Node) -> void:
	EventBus.player_died.emit(player)
	if RoguelikeManager and RoguelikeManager.is_active:
		RoguelikeManager.end_run(false, {})
		await get_tree().create_timer(1.2).timeout
		enter_main_menu()
		return
	current_state = GameState.DEAD
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(player):
		return
	var data := player.get_node_or_null("CharacterData")
	if data:
		data.hp = maxi(1, int(data.max_hp * 0.5))
		data.mp = data.max_mp
	if player is Node2D:
		player.global_position = level_spawn_point
	if player.has_method("revive"):
		player.revive()
	current_state = GameState.PLAYING
	EventBus.notify("你在营地醒来（恢复 50% HP）")

# ---------- 存档快照 ----------
func collect_state() -> Dictionary:
	capture_party()
	var scene_path := SCENE_MAIN_WORLD
	if get_tree().current_scene and get_tree().current_scene.scene_file_path != "":
		scene_path = get_tree().current_scene.scene_file_path
	return {
		"version": "1.0.0",
		"game_name": "通天入地",
		"timestamp": Time.get_unix_time_from_system(),
		"scene": scene_path,
		"gold": gold,
		"roster": roster.duplicate(),
		"progress": progress.duplicate(true),
		"active_index": active_index,
		"floor": pending_floor,
		"inventory": inventory.serialize() if inventory else [],
		"builds": BuildManager.serialize() if BuildManager else {},
		"quests": QuestManager.serialize() if QuestManager else {},
		"roguelike": RoguelikeManager.serialize() if RoguelikeManager else {},
		"punk": PunkManager.serialize() if PunkManager else {},
		"skills": SkillManager.serialize() if SkillManager else {},
		"player_pos": active_player.global_position if is_instance_valid(active_player) else Vector2.ZERO
	}

func apply_state(data: Dictionary) -> void:
	close_all_ui()
	training_active = false
	_training_backup = {}
	roster = data.get("roster", STARTING_CLASSES.duplicate())
	progress = data.get("progress", {})
	active_index = int(data.get("active_index", 0))
	pending_floor = clampi(int(data.get("floor", 1)), -99, 99)
	if pending_floor == 0:
		pending_floor = 1
	gold = int(data.get("gold", 0))
	if inventory:
		inventory.deserialize(data.get("inventory", []))
	if BuildManager:
		BuildManager.deserialize(data.get("builds", {}))
	if QuestManager:
		QuestManager.deserialize(data.get("quests", {}))
	if RoguelikeManager:
		RoguelikeManager.deserialize(data.get("roguelike", {}))
	if PunkManager:
		PunkManager.apply_state(data.get("punk", {}))
	if SkillManager:
		SkillManager.apply_state(data.get("skills", {}))
	pending_player_pos = _to_vector2(data.get("player_pos", Vector2.ZERO))
	has_pending_pos = true
	current_state = GameState.PLAYING
	var scene_path: String = str(data.get("scene", SCENE_MAIN_WORLD))
	if scene_path == "":
		scene_path = SCENE_MAIN_WORLD
	change_scene(scene_path)

func _to_vector2(value) -> Vector2:
	if value is Vector2:
		return value
	if value is String:
		var parts: PackedStringArray = value.trim_prefix("(").trim_suffix(")").split(",")
		if parts.size() >= 2:
			return Vector2(float(parts[0]), float(parts[1]))
	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	return Vector2.ZERO
