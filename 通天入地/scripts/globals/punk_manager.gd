# ============================================================
# PunkManager — 朋克改造核心
# 每个职业有独立的 4 槽位改造（weapon/chest/helmet/back）
# 风格匹配时额外加成 15%（可在 punk_parts.json 调整）
# ============================================================

extends Node

const SLOTS := ["weapon", "chest", "helmet", "back"]
const STYLE_SPELL := "spell"
const STYLE_MECH := "mech"
const STYLE_TECH := "tech"
const STYLE_ABYSS := "abyss"
const STYLE_NEUTRAL := "neutral"

signal punk_applied(class_id: String, slot: String, part_id: String)
signal punk_removed(class_id: String, slot: String, part_id: String)
signal punk_style_changed(class_id: String, primary_style: String)

# class_id → {slot: part_id}
var equipped_parts: Dictionary = {}
# 当前活动职业的主风格
var active_primary_style: String = STYLE_NEUTRAL

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GameManager:
		GameManager.active_character_changed.connect(_on_character_switched)
		GameManager.game_paused.connect(_on_state_paused)
		GameManager.game_resumed.connect(_on_state_resumed)

func _on_state_paused() -> void:
	pass

func _on_state_resumed() -> void:
	_update_primary_style()

# ---------- 查询 ----------
func get_equipped(class_id: String) -> Dictionary:
	return equipped_parts.get(class_id, {}).duplicate()

func get_part_in_slot(class_id: String, slot: String) -> String:
	var c_dict: Dictionary = equipped_parts.get(class_id, {})
	return str(c_dict.get(slot, ""))

func get_slot_count() -> int:
	return SLOTS.size()

func get_all_parts_for_class(class_id: String) -> Array:
	var allowed_styles: Array = DataManager.get_class_allowed_styles(class_id) if DataManager else []
	var result: Array = []
	for p in DataManager.get_all_punk_parts():
		var style: String = str(p.get("style", STYLE_NEUTRAL))
		if allowed_styles.is_empty() or style == STYLE_NEUTRAL or allowed_styles.has(style):
			result.append(p)
	return result

func get_primary_style(class_id: String) -> String:
	var counts: Dictionary = {}
	var c_dict: Dictionary = equipped_parts.get(class_id, {})
	for slot in SLOTS:
		var part_id: String = str(c_dict.get(slot, ""))
		if part_id == "":
			continue
		var part: Dictionary = DataManager.get_punk_part(part_id)
		if part.is_empty():
			continue
		var style: String = str(part.get("style", STYLE_NEUTRAL))
		if style != STYLE_NEUTRAL:
			counts[style] = int(counts.get(style, 0)) + 1
	if counts.is_empty():
		return STYLE_NEUTRAL
	var best_style: String = STYLE_NEUTRAL
	var best_count: int = 0
	for style in counts.keys():
		if int(counts[style]) > best_count:
			best_count = int(counts[style])
			best_style = str(style)
	return best_style

# ---------- 应用 / 移除 ----------
func apply_punk(class_id: String, slot: String, part_id: String) -> bool:
	if slot not in SLOTS:
		push_warning("[PunkManager] 无效槽位 %s" % slot)
		return false
	var part: Dictionary = DataManager.get_punk_part(part_id)
	if part.is_empty():
		push_warning("[PunkManager] 部件不存在 %s" % part_id)
		return false
	var cost: Dictionary = part.get("cost", {})
	if not _can_afford(cost):
		EventBus.notify("材料不足，无法安装 %s" % str(part.get("name", part_id)))
		return false
	_consume_cost(cost)
	if not equipped_parts.has(class_id):
		equipped_parts[class_id] = {}
	var old_part_id: String = str(equipped_parts[class_id].get(slot, ""))
	if old_part_id != "":
		_refund_part(old_part_id)
	equipped_parts[class_id][slot] = part_id
	punk_applied.emit(class_id, slot, part_id)
	EventBus.notify("安装朋克改造：%s（%s）" % [str(part.get("name", part_id)), str(DataManager.get_punk_style_color(str(part.get("style", ""))).to_html())])
	_apply_to_character(class_id)
	_update_primary_style()
	return true

func remove_punk(class_id: String, slot: String) -> bool:
	var c_dict: Dictionary = equipped_parts.get(class_id, {})
	var part_id: String = str(c_dict.get(slot, ""))
	if part_id == "":
		return false
	_refund_part(part_id)
	c_dict.erase(slot)
	punk_removed.emit(class_id, slot, part_id)
	var part: Dictionary = DataManager.get_punk_part(part_id)
	EventBus.notify("卸下朋克改造：%s（退还 50% 材料）" % str(part.get("name", part_id)))
	_apply_to_character(class_id)
	_update_primary_style()
	return true

func _can_afford(cost: Dictionary) -> bool:
	if cost.is_empty():
		return true
	if GameManager == null or GameManager.inventory == null:
		return false
	for item_id in cost.keys():
		var need: int = int(cost[item_id])
		if GameManager.inventory.count_item(item_id) < need:
			return false
	return true

func _consume_cost(cost: Dictionary) -> void:
	if GameManager == null or GameManager.inventory == null:
		return
	for item_id in cost.keys():
		GameManager.inventory.remove_item(item_id, int(cost[item_id]))

func _refund_part(part_id: String) -> void:
	var part: Dictionary = DataManager.get_punk_part(part_id)
	var cost: Dictionary = part.get("cost", {})
	if cost.is_empty():
		return
	for item_id in cost.keys():
		var amount: int = maxi(1, int(cost[item_id]) / 2)
		GameManager.inventory.add_item(item_id, amount)

# ---------- 角色属性应用 ----------
func _apply_to_character(class_id: String) -> void:
	if GameManager == null or not GameManager.roster.has(class_id):
		return
	var data_node: Node = GameManager.active_player.get_node_or_null("CharacterData") if is_instance_valid(GameManager.active_player) else null
	if data_node == null or str(data_node.class_id) != class_id:
		return
	var data: CharacterBase = data_node if data_node is CharacterBase else null
	if data == null:
		return
	data.recompute()
	data.stats_changed.emit()

func _compute_punk_stats(class_id: String, base_stats: Dictionary) -> Dictionary:
	var style: String = get_primary_style(class_id)
	var allowed: Array = DataManager.get_class_allowed_styles(class_id) if DataManager else []
	var style_match: bool = (style != STYLE_NEUTRAL and allowed.is_empty()) or allowed.has(style)
	var bonus_rate: float = DataManager.get_style_bonus_match() if (DataManager and style_match) else 0.0
	var result: Dictionary = {}
	var c_dict: Dictionary = equipped_parts.get(class_id, {})
	for slot in SLOTS:
		var part_id: String = str(c_dict.get(slot, ""))
		if part_id == "":
			continue
		var part: Dictionary = DataManager.get_punk_part(part_id)
		if part.is_empty():
			continue
		var part_stats: Dictionary = part.get("stats", {})
		var class_bonus: Array = part.get("class_bonus", [])
		var is_class_match: bool = (typeof(class_bonus) == TYPE_ARRAY and class_bonus.has(class_id))
		var mult: float = 1.0 + bonus_rate + (0.10 if is_class_match else 0.0)
		for stat_key in part_stats.keys():
			var raw: Variant = part_stats[stat_key]
			if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
				var value: float = float(raw)
				if stat_key in result:
					result[stat_key] = float(result[stat_key]) + value * mult
				else:
					result[stat_key] = value * mult
	return result

# ---------- 事件监听 ----------
func _on_character_switched(new_char: Node) -> void:
	var data: Node = new_char.get_node_or_null("CharacterData") if is_instance_valid(new_char) else null
	if data == null:
		return
	var cid: String = str(data.class_id)
	_apply_to_character(cid)
	_update_primary_style()

func _on_state_changed(new_state: int) -> void:
	if new_state == GameManager.GameState.PLAYING:
		_update_primary_style()

func _update_primary_style() -> void:
	if GameManager == null or not is_instance_valid(GameManager.active_player):
		return
	var data: Node = GameManager.active_player.get_node_or_null("CharacterData")
	if data == null:
		return
	var new_style: String = get_primary_style(str(data.class_id))
	if new_style != active_primary_style:
		active_primary_style = new_style
		punk_style_changed.emit(str(data.class_id), new_style)

# ---------- 存档 ----------
func serialize() -> Dictionary:
	return {"equipped": equipped_parts.duplicate(true)}

func apply_state(data: Dictionary) -> void:
	equipped_parts = data.get("equipped", {}).duplicate(true)

func reset() -> void:
	equipped_parts.clear()
	active_primary_style = STYLE_NEUTRAL
