# ============================================================
# SaveManager — 多槽位 JSON 存档
# ============================================================

extends Node

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(reason: String)

const SAVE_DIR := "user://saves/"
const SAVE_FILE := "save_%d.json"
const AUTO_SLOT := 0

var current_slot: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var user_dir := DirAccess.open("user://")
	if user_dir and not user_dir.dir_exists("saves"):
		user_dir.make_dir_recursive("saves")

func save_game(slot: int = AUTO_SLOT) -> bool:
	var data := GameManager.collect_state()
	var path := SAVE_DIR + (SAVE_FILE % slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		save_failed.emit("无法写入存档文件")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	current_slot = slot
	save_completed.emit(slot)
	EventBus.save_completed.emit(slot)
	EventBus.notify("存档成功（槽位 %d）" % slot)
	print("[SaveManager] 存档成功 -> slot %d" % slot)
	return true

func load_game(slot: int = AUTO_SLOT) -> bool:
	var path := SAVE_DIR + (SAVE_FILE % slot)
	if not FileAccess.file_exists(path):
		save_failed.emit("存档文件不存在")
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		save_failed.emit("无法读取存档")
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		save_failed.emit("存档解析失败：%s" % json.get_error_message())
		return false
	if typeof(json.data) != TYPE_DICTIONARY:
		save_failed.emit("存档格式错误")
		return false
	var data: Dictionary = json.data
	current_slot = slot
	GameManager.apply_state(data)
	load_completed.emit(slot)
	EventBus.load_completed.emit(slot)
	print("[SaveManager] 读档成功 <- slot %d" % slot)
	return true

func has_save(slot: int = AUTO_SLOT) -> bool:
	return FileAccess.file_exists(SAVE_DIR + (SAVE_FILE % slot))

func get_save_list() -> Array:
	var result: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if filename.begins_with("save_") and filename.ends_with(".json"):
			var slot := filename.replace("save_", "").replace(".json", "").to_int()
			result.append({
				"slot": slot,
				"time": FileAccess.get_modified_time(SAVE_DIR + filename),
				"file": filename
			})
		filename = dir.get_next()
	dir.list_dir_end()
	return result

func delete_save(slot: int) -> bool:
	var path := SAVE_DIR + (SAVE_FILE % slot)
	if not FileAccess.file_exists(path):
		return false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true
