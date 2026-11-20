# ============================================================
# Inventory — 背包 / 装备 / 消耗品 / 合成 / 买卖
# 物品模板来自 DataManager（data/items.json）
# ============================================================

extends Node
class_name Inventory

signal inventory_changed
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal inventory_full

const SLOT_COUNT := 40

var slots: Array = []

func _ready() -> void:
	if slots.is_empty():
		reset()

func reset() -> void:
	slots.clear()
	slots.resize(SLOT_COUNT)
	for i in SLOT_COUNT:
		slots[i] = {}
	inventory_changed.emit()

func _template(item_id: String) -> Dictionary:
	if DataManager == null:
		return {}
	return DataManager.get_item(item_id)

func _empty_slot_index() -> int:
	for i in slots.size():
		var s = slots[i]
		if not (s is Dictionary) or s.is_empty():
			return i
	return -1

func add_item(item_id: String, quantity: int = 1) -> bool:
	var tpl := _template(item_id)
	if tpl.is_empty():
		push_warning("[Inventory] 未知物品：%s" % item_id)
		return false
	var remaining := maxi(1, quantity)
	var max_stack := int(tpl.get("max_stack", 1))
	if not bool(tpl.get("stackable", false)):
		max_stack = 1

	# 先填充已有堆叠
	if max_stack > 1:
		for i in slots.size():
			if remaining <= 0:
				break
			var s = slots[i]
			if s is Dictionary and str(s.get("id", "")) == item_id:
				var q := int(s.get("quantity", 0))
				if q < max_stack:
					var add := mini(remaining, max_stack - q)
					s["quantity"] = q + add
					remaining -= add
	# 再占用空槽
	while remaining > 0:
		var idx := _empty_slot_index()
		if idx < 0:
			inventory_full.emit()
			EventBus.notify("背包已满")
			break
		var add := mini(remaining, max_stack)
		slots[idx] = { "id": item_id, "quantity": add }
		remaining -= add

	var added := maxi(0, quantity - remaining)
	if added > 0:
		item_added.emit(item_id, added)
		inventory_changed.emit()
		EventBus.inventory_changed.emit()
	return added > 0

func count_item(item_id: String) -> int:
	var total := 0
	for s in slots:
		if s is Dictionary and not s.is_empty() and str(s.get("id", "")) == item_id:
			total += int(s.get("quantity", 0))
	return total

func has_item(item_id: String, quantity: int = 1) -> bool:
	return count_item(item_id) >= quantity

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity):
		return false
	var remaining := quantity
	for i in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var s = slots[i]
		if not (s is Dictionary) or s.is_empty() or str(s.get("id", "")) != item_id:
			continue
		var q := int(s.get("quantity", 0))
		var take := mini(q, remaining)
		q -= take
		remaining -= take
		if q <= 0:
			slots[i] = {}
		else:
			s["quantity"] = q
	item_removed.emit(item_id, quantity)
	inventory_changed.emit()
	EventBus.inventory_changed.emit()
	return true

func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	var s = slots[index]
	return s if s is Dictionary else {}

func get_item_id_at(index: int) -> String:
	var s := get_slot(index)
	return str(s.get("id", "")) if not s.is_empty() else ""

# ---------- 消耗品 / 装备 ----------
func use_slot(index: int, character) -> bool:
	var s := get_slot(index)
	if s.is_empty() or character == null:
		return false
	var tpl := _template(str(s.get("id", "")))
	if tpl.is_empty() or str(tpl.get("type", "")) != "consumable":
		return false
	var effect: Dictionary = tpl.get("effect", {})
	if effect.has("hp"):
		var healed: int = character.heal(int(effect["hp"]))
		EventBus.notify("恢复 %d HP" % healed)
	if effect.has("mp"):
		var restored: int = character.restore_mp(int(effect["mp"]))
		EventBus.notify("恢复 %d MP" % restored)
	remove_item(str(s.get("id", "")), 1)
	return true

func equip_slot(index: int, character) -> bool:
	var s := get_slot(index)
	if s.is_empty() or character == null:
		return false
	var tpl := _template(str(s.get("id", "")))
	if tpl.is_empty():
		return false
	var slot_name := str(tpl.get("slot", ""))
	if slot_name == "":
		return false
	# 卸下已有装备（需要有空间）
	var old: Dictionary = character.get_equipped(slot_name)
	if not old.is_empty():
		if _empty_slot_index() < 0:
			EventBus.notify("背包已满，无法卸下装备")
			return false
	remove_item(str(s.get("id", "")), 1)
	character.equip_item(tpl)
	if not old.is_empty():
		add_item(str(old.get("id", "")), 1)
	EventBus.notify("装备：%s" % str(tpl.get("name", "")))
	return true

func unequip_slot(slot_name: String, character) -> bool:
	if character == null:
		return false
	var old: Dictionary = character.unequip_item(slot_name)
	if old.is_empty():
		return false
	if _empty_slot_index() < 0:
		character.equip_item(old)
		EventBus.notify("背包已满")
		return false
	add_item(str(old.get("id", "")), 1)
	return true

# ---------- 合成 ----------
func can_craft(recipe_id: String) -> bool:
	var r := DataManager.get_recipe(recipe_id) if DataManager else {}
	if r.is_empty():
		return false
	var cost: Dictionary = r.get("cost", {})
	for item_id in cost.keys():
		if not has_item(str(item_id), int(cost[item_id])):
			return false
	return true

func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		EventBus.notify("材料不足")
		return false
	var r := DataManager.get_recipe(recipe_id)
	var cost: Dictionary = r.get("cost", {})
	for item_id in cost.keys():
		remove_item(str(item_id), int(cost[item_id]))
	var output := str(r.get("output", ""))
	var count := int(r.get("count", 1))
	add_item(output, count)
	EventBus.item_crafted.emit({ "id": output, "quantity": count })
	EventBus.notify("合成成功：%s ×%d" % [str(_template(output).get("name", output)), count])
	return true

# ---------- 商店 ----------
func buy_item(item_id: String, price: int) -> bool:
	if GameManager == null or not GameManager.spend_gold(price):
		EventBus.notify("金币不足")
		return false
	if not add_item(item_id, 1):
		GameManager.add_gold(price)
		return false
	EventBus.notify("购买：%s" % str(_template(item_id).get("name", item_id)))
	return true

func sell_slot(index: int, price: int) -> bool:
	var s := get_slot(index)
	if s.is_empty():
		return false
	remove_item(str(s.get("id", "")), 1)
	if GameManager:
		GameManager.add_gold(price)
	EventBus.item_sold.emit(s, price)
	EventBus.notify("出售获得 %d 金币" % price)
	return true

# ---------- 存档 ----------
func serialize() -> Array:
	var result: Array = []
	for s in slots:
		if s is Dictionary and not s.is_empty():
			result.append({ "id": str(s.get("id", "")), "quantity": int(s.get("quantity", 1)) })
		else:
			result.append(null)
	return result

func deserialize(data) -> void:
	reset()
	if not (data is Array):
		return
	for i in mini(data.size(), slots.size()):
		var s = data[i]
		if s is Dictionary and not s.is_empty():
			slots[i] = { "id": str(s.get("id", "")), "quantity": int(s.get("quantity", 1)) }
	inventory_changed.emit()
	EventBus.inventory_changed.emit()
