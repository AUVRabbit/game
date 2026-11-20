# ============================================================
# SkillManager — 技能树与职业专职管理器
# 负责：技能点、解锁节点、被动加成、技能强化、职业专职选择与存档
# 注意：AutoLoad 脚本不声明 class_name（Godot 4.7 限制）
# ============================================================

extends Node

var points: Dictionary = {}          # class_id -> 可用技能点
var unlocked: Dictionary = {}        # class_id -> 已解锁节点 id 数组
var specialization: Dictionary = {}  # class_id -> 专职 id

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# ---------- 初始化 ----------
func ensure_class(class_id: String) -> void:
	if class_id == "":
		return
	if not points.has(class_id):
		var starting := 1
		if DataManager:
			starting = maxi(0, DataManager.skill_starting_points)
		points[class_id] = starting
	if not unlocked.has(class_id):
		var ids: Array = []
		for node in _nodes(class_id):
			if str(node.get("kind", "")) == "anchor":
				ids.append(str(node.get("id", "")))
		unlocked[class_id] = ids

func _nodes(class_id: String) -> Array:
	if DataManager == null:
		return []
	return DataManager.get_skill_tree_nodes(class_id)

# ---------- 技能点 ----------
func get_points(class_id: String) -> int:
	ensure_class(class_id)
	return int(points.get(class_id, 0))

func grant_level_points(class_id: String, _level: int) -> void:
	ensure_class(class_id)
	var per_level := 1
	if DataManager:
		per_level = maxi(0, DataManager.skill_points_per_level)
	points[class_id] = int(points.get(class_id, 0)) + per_level
	EventBus.notify("%s 获得 %d 点技能点" % [_class_name(class_id), per_level])

# ---------- 节点解锁 ----------
func is_unlocked(class_id: String, node_id: String) -> bool:
	var ids: Array = unlocked.get(class_id, [])
	return ids.has(node_id)

func get_unlocked_nodes(class_id: String) -> Array:
	ensure_class(class_id)
	var result: Array = []
	for node in _nodes(class_id):
		if is_unlocked(class_id, str(node.get("id", ""))):
			result.append(node)
	return result

func can_unlock(class_id: String, node_id: String) -> Dictionary:
	ensure_class(class_id)
	var node: Dictionary = {}
	if DataManager:
		node = DataManager.get_skill_node(class_id, node_id)
	if node.is_empty():
		return { "ok": false, "reason": "节点不存在" }
	if is_unlocked(class_id, node_id):
		return { "ok": false, "reason": "已解锁" }
	for req in node.get("requires", []):
		if not is_unlocked(class_id, str(req)):
			return { "ok": false, "reason": "需先解锁前置节点" }
	var cost := int(node.get("cost", 1))
	if get_points(class_id) < cost:
		return { "ok": false, "reason": "技能点不足（需要 %d）" % cost }
	return { "ok": true, "reason": "" }

func unlock_node(class_id: String, node_id: String) -> bool:
	var check := can_unlock(class_id, node_id)
	if not bool(check.get("ok", false)):
		EventBus.notify("无法解锁：%s" % str(check.get("reason", "")))
		return false
	var node: Dictionary = {}
	if DataManager:
		node = DataManager.get_skill_node(class_id, node_id)
	points[class_id] = int(points.get(class_id, 0)) - int(node.get("cost", 1))
	var ids: Array = unlocked.get(class_id, [])
	ids.append(node_id)
	unlocked[class_id] = ids
	EventBus.notify("已解锁：%s" % str(node.get("name", node_id)))
	EventBus.skill_node_unlocked.emit(class_id, node_id)
	return true

func reset_tree(class_id: String) -> void:
	ensure_class(class_id)
	var refund := 0
	for node in _nodes(class_id):
		if str(node.get("kind", "")) == "anchor":
			continue
		if is_unlocked(class_id, str(node.get("id", ""))):
			refund += int(node.get("cost", 1))
	var ids: Array = []
	for node in _nodes(class_id):
		if str(node.get("kind", "")) == "anchor":
			ids.append(str(node.get("id", "")))
	unlocked[class_id] = ids
	points[class_id] = int(points.get(class_id, 0)) + refund
	EventBus.notify("已重置技能树，返还 %d 点" % refund)
	EventBus.skill_tree_reset.emit(class_id)

# ---------- 加成汇总 ----------
func get_passive_bonus(class_id: String) -> Dictionary:
	var total: Dictionary = {}
	for node in get_unlocked_nodes(class_id):
		var passive: Dictionary = node.get("passive", {})
		for key in passive.keys():
			total[key] = float(total.get(key, 0.0)) + float(passive[key])
	return total

func get_skill_bonus(class_id: String, skill_id: String) -> Dictionary:
	var result := { "power": 0.0, "cooldown": 0.0 }
	for node in get_unlocked_nodes(class_id):
		if str(node.get("skill_id", "")) != skill_id:
			continue
		var bonus: Dictionary = node.get("skill_bonus", {})
		for key in bonus.keys():
			result[key] = float(result.get(key, 0.0)) + float(bonus[key])
	return result

# ---------- 职业专职 ----------
func get_specialization(class_id: String) -> Dictionary:
	var spec_id := str(specialization.get(class_id, ""))
	if spec_id == "" or DataManager == null:
		return {}
	return DataManager.get_specialization_data(class_id, spec_id)

func has_specialization(class_id: String) -> bool:
	return not str(specialization.get(class_id, "")).is_empty()

func can_choose_specialization(class_id: String, spec_id: String, level: int) -> Dictionary:
	if has_specialization(class_id):
		return { "ok": false, "reason": "已确定专职" }
	if DataManager == null:
		return { "ok": false, "reason": "数据未就绪" }
	var spec: Dictionary = DataManager.get_specialization_data(class_id, spec_id)
	if spec.is_empty():
		return { "ok": false, "reason": "专职不存在" }
	var req := int(spec.get("req_level", 5))
	if level < req:
		return { "ok": false, "reason": "需要等级 %d" % req }
	return { "ok": true, "reason": "" }

func choose_specialization(class_id: String, spec_id: String, level: int) -> bool:
	var check := can_choose_specialization(class_id, spec_id, level)
	if not bool(check.get("ok", false)):
		EventBus.notify("无法转职：%s" % str(check.get("reason", "")))
		return false
	specialization[class_id] = spec_id
	ensure_class(class_id)
	points[class_id] = int(points.get(class_id, 0)) + int(DataManager.get_specialization_data(class_id, spec_id).get("bonus_points", 0))
	EventBus.notify("职业专职：%s" % str(DataManager.get_specialization_data(class_id, spec_id).get("name", spec_id)))
	EventBus.specialization_chosen.emit(class_id, spec_id)
	return true

func get_spec_stats(class_id: String) -> Dictionary:
	var spec := get_specialization(class_id)
	return spec.get("stats", {}) if spec.has("stats") else {}

func get_spec_skill_bonus(class_id: String) -> Dictionary:
	var spec := get_specialization(class_id)
	return spec.get("skill_bonus", {}) if spec.has("skill_bonus") else {}

func get_spec_passives(class_id: String) -> Dictionary:
	var spec := get_specialization(class_id)
	return spec.get("passives", {}) if spec.has("passives") else {}

# ---------- 存档 ----------
func serialize() -> Dictionary:
	return {
		"points": points.duplicate(true),
		"unlocked": unlocked.duplicate(true),
		"specialization": specialization.duplicate(true)
	}

func apply_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	var p = data.get("points", {})
	points = p.duplicate(true) if p is Dictionary else {}
	var u = data.get("unlocked", {})
	unlocked = u.duplicate(true) if u is Dictionary else {}
	var s = data.get("specialization", {})
	specialization = s.duplicate(true) if s is Dictionary else {}

func reset() -> void:
	points.clear()
	unlocked.clear()
	specialization.clear()

func _class_name(class_id: String) -> String:
	if DataManager == null:
		return class_id
	var def: Dictionary = DataManager.get_class_data(class_id)
	return str(def.get("name", class_id))
