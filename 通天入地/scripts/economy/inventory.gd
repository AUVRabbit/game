# ============================================================
# Inventory.gd — 背包/物品系统
# 负责：存储、装备、使用、合成
# ============================================================

extends Node
class_name Inventory
signal item_added(item_data: Dictionary, slot_idx: int)
signal item_removed(item_data: Dictionary, slot_idx: int)
signal inventory_full

const MAX_SLOTS := 40

var items: Array = []  # Dictionary: {id, name, type, quantity, ...}
var equipped_items: Dictionary = {}  # slot_name -> item_data

# ---------- 物品类型 ----------
enum ItemType { MATERIAL, CONSUMABLE, WEAPON, ARMOR, ACCESSORY, KEY_ITEM, BUILDING }

func _ready() -> void:
    items.resize(MAX_SLOTS)

# ---------- 添加物品 ----------
func add_item(item_id: String, quantity: int = 1) -> bool:
    var existing = _find_item_slot(item_id)
    if existing >= 0:
        items[existing]["quantity"] += quantity
        emit_signal("item_added", items[existing], existing)
        if EventBus: EventBus.item_picked_up.emit(items[existing])
        return true
    var empty = _find_empty_slot()
    if empty < 0:
        emit_signal("inventory_full")
        return false
    var item_data = _get_item_template(item_id)
    item_data["quantity"] = quantity
    items[empty] = item_data
    emit_signal("item_added", item_data, empty)
    if EventBus: EventBus.item_picked_up.emit(item_data)
    return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
    var slot = _find_item_slot(item_id)
    if slot < 0:
        return false
    var remaining = items[slot]["quantity"] - quantity
    if remaining <= 0:
        items[slot] = null
    else:
        items[slot]["quantity"] = remaining
    emit_signal("item_removed", {"id": item_id, "quantity": quantity}, slot)
    return true

func has_item(item_id: String, quantity: int = 1) -> bool:
    var slot = _find_item_slot(item_id)
    return slot >= 0 and items[slot]["quantity"] >= quantity

func _find_item_slot(item_id: String) -> int:
    for i in items.size():
        if items[i] and items[i].get("id") == item_id:
            return i
    return -1

func _find_empty_slot() -> int:
    for i in items.size():
        if items[i] == null:
            return i
    return -1

func _get_item_template(item_id: String) -> Dictionary:
    # TODO: 从 data/items.json 加载实际数据
    return {
        "id": item_id,
        "name": item_id,
        "type": ItemType.MATERIAL,
        "description": "一个 %s" % item_id,
    }

# ---------- 装备 ----------
func equip(item_data: Dictionary) -> bool:
    var valid_slots = {"weapon", "armor", "accessory"}
    if not valid_slots.has(item_data.get("slot", "")):
        return false
    equipped_items[item_data["slot"]] = item_data
    return true

# ---------- 使用消耗品 ----------
func use_consumable(slot_idx: int) -> void:
    var item = items[slot_idx]
    if not item or item.get("type") != ItemType.CONSUMABLE:
        return
    # TODO: 执行实际效果（回血/回蓝/buff）
    remove_item(item["id"], 1)

# ---------- 查询 ----------
func get_item_count(item_id: String) -> int:
    var slot = _find_item_slot(item_id)
    if slot < 0:
        return 0
    return items[slot]["quantity"]

func get_all_items() -> Array:
    var result: Array = []
    for it in items:
        if it:
            result.append(it)
    return result
