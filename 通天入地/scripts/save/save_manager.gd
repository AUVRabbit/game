# ============================================================
# SaveManager.gd — 存档系统
# 支持多槽保存、JSON序列化
# ============================================================

extends Node
class_name SaveManager
signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(reason: String)

const SAVE_DIR := "user://saves/"
const SAVE_FILE := "save_%d.json"

var current_slot: int = -1

func _ready() -> void:
    # 确保存档目录存在
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int = 0) -> bool:
    current_slot = slot
    var data = _collect_save_data()
    var json_str = JSON.stringify(data, "\t")
    var path = SAVE_DIR + (SAVE_FILE % slot)
    var file = FileAccess.open(path, FileAccess.WRITE)
    if not file:
        emit_signal("save_failed", "无法写入存档文件")
        return false
    file.store_string(json_str)
    file.close()
    emit_signal("save_completed", slot)
    print("[SaveManager] 存档成功 -> slot %d" % slot)
    return true

func load_game(slot: int = 0) -> bool:
    var path = SAVE_DIR + (SAVE_FILE % slot)
    if not FileAccess.file_exists(path):
        emit_signal("save_failed", "存档文件不存在")
        return false
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        emit_signal("save_failed", "无法读取存档")
        return false
    var json_str = file.get_as_text()
    file.close()
    var json = JSON.new()
    var err = json.parse(json_str)
    if err != OK:
        emit_signal("save_failed", "存档解析失败")
        return false
    var data = json.data
    _apply_save_data(data)
    current_slot = slot
    emit_signal("load_completed", slot)
    print("[SaveManager] 读档成功 <- slot %d" % slot)
    return true

func has_save(slot: int) -> bool:
    return FileAccess.file_exists(SAVE_DIR + (SAVE_FILE % slot))

func get_save_list() -> Array:
    var result: Array = []
    var dir = DirAccess.open(SAVE_DIR)
    if dir:
        dir.list_dir_begin()
        var filename = dir.get_next()
        while filename != "":
            if filename.begins_with("save_") and filename.ends_with(".json"):
                var slot = filename.replace("save_", "").replace(".json", "").to_int()
                var modified_time = FileAccess.get_modified_time(SAVE_DIR + filename)
                result.append({"slot": slot, "time": modified_time, "file": filename})
            filename = dir.get_next()
        dir.list_dir_end()
    return result

# ---------- 收集/应用存档数据 ----------
func _collect_save_data() -> Dictionary:
    var data := {
        "version": "0.1.0",
        "game_name": "通天入地",
        "timestamp": Time.get_unix_time_from_system(),
        "player": {},
        "world": {},
        "inventory": [],
        "builds": {},
    }
    # 玩家数据
    if GameManager and GameManager.active_player:
        var p = GameManager.active_player.get_node_or_null("CharacterData")
        if p:
            data["player"] = {
                "class": p.class_type,
                "level": p.level,
                "exp": p.exp,
                "hp": p.hp,
                "mp": p.mp,
                "pos": GameManager.active_player.global_position,
            }
    return data

func _apply_save_data(data: Dictionary) -> void:
    # TODO: 根据存档数据恢复玩家位置、属性、世界状态等
    print("[SaveManager] 应用存档数据 (v%s)" % data.get("version", "?"))
