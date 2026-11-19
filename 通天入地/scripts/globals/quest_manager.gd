# ============================================================
# QuestManager — 任务系统
# 监听击杀 / 合成 / 抵达楼层，推进目标并发放奖励
# ============================================================

extends Node

signal quest_progress_changed(quest_id: String)

var active: Dictionary = {}     # quest_id -> { progress: Array[int], done: bool }
var completed: Array = []

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.item_crafted.connect(_on_item_crafted)

func reset_all() -> void:
	active.clear()
	completed.clear()

func start_quest(quest_id: String) -> bool:
	if active.has(quest_id) or completed.has(quest_id):
		return false
	var def := DataManager.get_quest(quest_id)
	if def.is_empty():
		return false
	var objectives: Array = def.get("objectives", [])
	var progress: Array = []
	for i in objectives.size():
		progress.append(0)
	active[quest_id] = { "progress": progress, "done": false }
	EventBus.quest_accepted.emit(quest_id)
	EventBus.notify("接受任务：%s" % str(def.get("name", quest_id)))
	quest_progress_changed.emit(quest_id)
	return true

func _on_enemy_died(enemy: Node, _killer: Node) -> void:
	var enemy_type := "enemy"
	if enemy and "enemy_type" in enemy:
		enemy_type = str(enemy.enemy_type)
	_notify("kill", enemy_type, 1)

func _on_item_crafted(result_item: Dictionary) -> void:
	if result_item.is_empty():
		return
	_notify("craft", str(result_item.get("id", "")), int(result_item.get("quantity", 1)))

func notify_reach_floor(floor_num: int) -> void:
	_notify("reach_floor", str(floor_num), 1)

func _notify(type_name: String, target: String, amount: int) -> void:
	for quest_id in active.keys():
		var state: Dictionary = active[quest_id]
		if bool(state.get("done", false)):
			continue
		var def := DataManager.get_quest(str(quest_id))
		if def.is_empty():
			continue
		var objectives: Array = def.get("objectives", [])
		var progress: Array = state["progress"]
		var changed := false
		for i in objectives.size():
			if i >= progress.size():
				continue
			var obj: Dictionary = objectives[i]
			if str(obj.get("type", "")) != type_name:
				continue
			if str(obj.get("target", "")) != target:
				continue
			var need := int(obj.get("count", 1))
			if int(progress[i]) >= need:
				continue
			progress[i] = mini(need, int(progress[i]) + amount)
			changed = true
		if changed:
			state["progress"] = progress
			active[quest_id] = state
			quest_progress_changed.emit(str(quest_id))
			EventBus.quest_updated.emit(str(quest_id))
			_check_complete(str(quest_id), def, progress)

func _check_complete(quest_id: String, def: Dictionary, progress: Array) -> void:
	var objectives: Array = def.get("objectives", [])
	for i in objectives.size():
		if i >= progress.size():
			return
		if int(progress[i]) < int(objectives[i].get("count", 1)):
			return
	var state: Dictionary = active[quest_id]
	state["done"] = true
	active[quest_id] = state
	completed.append(quest_id)
	var rewards: Dictionary = def.get("rewards", {})
	if rewards.has("gold") and GameManager:
		GameManager.add_gold(int(rewards["gold"]))
	var items: Dictionary = rewards.get("items", {})
	for item_id in items.keys():
		if GameManager and GameManager.inventory:
			GameManager.inventory.add_item(str(item_id), int(items[item_id]))
	EventBus.quest_completed.emit(quest_id)
	EventBus.notify("任务完成：%s" % str(def.get("name", quest_id)))

func get_tracked_quest() -> Dictionary:
	for quest_id in active.keys():
		var state: Dictionary = active[quest_id]
		if bool(state.get("done", false)):
			continue
		var def := DataManager.get_quest(str(quest_id))
		if def.is_empty():
			continue
		var objectives: Array = def.get("objectives", [])
		var progress: Array = state.get("progress", [])
		var text_lines: Array = []
		for i in objectives.size():
			var obj: Dictionary = objectives[i]
			var cur := int(progress[i]) if i < progress.size() else 0
			text_lines.append("%s %d/%d" % [str(obj.get("text", "目标")), cur, int(obj.get("count", 1))])
		return {
			"id": str(quest_id),
			"name": str(def.get("name", quest_id)),
			"lines": text_lines,
			"done": false
		}
	return {}

func serialize() -> Dictionary:
	return { "active": active.duplicate(true), "completed": completed.duplicate() }

func deserialize(data) -> void:
	active.clear()
	completed.clear()
	if data is Dictionary:
		active = data.get("active", {}).duplicate(true)
		var c = data.get("completed", [])
		if c is Array:
			completed = c.duplicate()
