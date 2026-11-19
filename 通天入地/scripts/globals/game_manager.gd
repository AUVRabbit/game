; ============================================================
; GameManager.gd — 游戏全局管理器（单例）
; 负责：场景切换、游戏状态、全局数据、存档入口
; ============================================================

extends Node
class_name GameManager
signal scene_changed(from_scene: String, to_scene: String)
signal game_paused
signal game_resumed

# ---------- 游戏状态 ----------
enum GameState { MENU, PLAYING, PAUSED, DIALOG, BUILDING }
var current_state: GameState = GameState.MENU

# ---------- 场景路径常量 ----------
const SCENE_MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const SCENE_MAIN_WORLD := "res://scenes/world/main_world.tscn"
const SCENE_TOWER_FLOOR_1 := "res://scenes/world/tower_floor_1.tscn"
const SCENE_PLAYER := "res://scenes/player/player.tscn"

# ---------- 角色管理 ----------
var active_player: CharacterBody2D = null
var party: Array = []  # 队伍中的所有角色实例

# ---------- 单例初始化 ----------
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    print("[GameManager] 通天入地 · GameManager 已启动")

# ---------- 场景切换 ----------
func change_scene(scene_path: String) -> void:
    emit_signal("scene_changed", get_tree().current_scene.name if get_tree().current_scene else "", scene_path)
    var packed := load(scene_path)
    if packed:
        get_tree().change_scene_to_packed(packed)
    else:
        push_warning("[GameManager] 场景加载失败：%s" % scene_path)

func enter_main_menu() -> void:
    current_state = GameState.MENU
    change_scene(SCENE_MAIN_MENU)

func enter_main_world() -> void:
    current_state = GameState.PLAYING
    change_scene(SCENE_MAIN_WORLD)

func enter_tower_floor(floor_num: int) -> void:
    current_state = GameState.PLAYING
    # TODO: 根据层数动态加载
    change_scene(SCENE_TOWER_FLOOR_1)

# ---------- 暂停 ----------
func toggle_pause() -> void:
    if current_state == GameState.PLAYING:
        get_tree().paused = true
        current_state = GameState.PAUSED
        emit_signal("game_paused")
    elif current_state == GameState.PAUSED:
        get_tree().paused = false
        current_state = GameState.PLAYING
        emit_signal("game_resumed")

func is_paused() -> bool:
    return current_state == GameState.PAUSED

# ---------- 角色切换 ----------
func switch_character(direction: int) -> void:
    """direction: 1 = 下一个, -1 = 上一个"""
    if party.size() < 2:
        return
    var current_idx = party.find(active_player)
    if current_idx == -1:
        return
    # 先让当前角色退场
    var next_idx = (current_idx + direction) % party.size()
    var next_player = party[next_idx]
    _activate_character(next_player)

func _activate_character(new_player: CharacterBody2D) -> void:
    if active_player:
        active_player.set_process(false)
        active_player.visible = false
    active_player = new_player
    active_player.set_process(true)
    active_player.visible = true
    print("[GameManager] 切换到角色: %s" % active_player.name)

# ---------- 快捷存取 ----------
func add_player_to_party(player: CharacterBody2D) -> void:
    party.append(player)

func get_active_player() -> CharacterBody2D:
    return active_player
