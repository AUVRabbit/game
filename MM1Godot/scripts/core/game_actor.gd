class_name GameActor
extends RefCounted
## Runtime actor, ported from Game_Actor (MM system).

const EQUIP_SLOTS := ["weapon", "armor1", "armor2", "armor3", "armor4"]

var id: int = 0
var name: String = ""
var character_name: String = ""
var character_hue: int = 0
var battler_name: String = ""
var class_id: int = 1
var level: int = 1
var exp: int = 0
var hp: int = 1
var sp: int = 0
var states: Array[int] = []
var equipment: Dictionary = {"weapon": 0, "armor1": 0, "armor2": 0, "armor3": 0, "armor4": 0}
var tank: GameTank = null
var items: Array = []
var skills: Array[int] = []
var data: Dictionary = {}

var _exp_list: Array = []


func _init(actor_id: int = 0) -> void:
	if actor_id <= 0:
		return
	id = actor_id
	data = DB.actor(id)
	name = data.get("name", "")
	character_name = data.get("character_name", "")
	character_hue = int(data.get("character_hue", 0))
	battler_name = data.get("battler_name", "")
	class_id = int(data.get("class_id", 1))
	level = int(data.get("initial_level", 1))
	equipment["weapon"] = int(data.get("weapon_id", 0))
	for i in range(1, 5):
		equipment["armor%d" % i] = int(data.get("armor%d_id" % i, 0))
	_refresh_exp_list()
	recover_all()


func _refresh_exp_list() -> void:
	_exp_list = DB.exp_list(data)


func exp_for_level(lv: int) -> int:
	if lv <= 1:
		return 0
	if lv < _exp_list.size():
		return int(_exp_list[lv])
	return 0


func can_level_up() -> bool:
	return level < max_level() and exp >= exp_for_level(level + 1)


func max_level() -> int:
	return int(data.get("final_level", 99))


func maxhp() -> int:
	var value: int = DB.param(data, 0, level)
	for state_id in states:
		var st: Dictionary = DB.state(state_id)
		value = int(value * float(st.get("maxhp_rate", 100)) / 100.0)
	return max(value, 1)


func maxsp() -> int:
	var value: int = DB.param(data, 1, level)
	for state_id in states:
		var st: Dictionary = DB.state(state_id)
		value = int(value * float(st.get("maxsp_rate", 100)) / 100.0)
	return max(value, 0)


func atk() -> int:
	var value: int = DB.param(data, 2, level) + _equip_atk()
	for state_id in states:
		value = int(value * float(DB.state(state_id).get("atk_rate", 100)) / 100.0)
	return max(value, 0)


func pdef() -> int:
	var value: int = DB.param(data, 3, level) + _equip_pdef()
	for state_id in states:
		value = int(value * float(DB.state(state_id).get("pdef_rate", 100)) / 100.0)
	return max(value, 0)


func mdef() -> int:
	var value: int = DB.param(data, 4, level) + _equip_mdef()
	for state_id in states:
		value = int(value * float(DB.state(state_id).get("mdef_rate", 100)) / 100.0)
	return max(value, 0)


func agi() -> int:
	var value: int = DB.param(data, 5, level) + _equip_agi()
	for state_id in states:
		value = int(value * float(DB.state(state_id).get("agi_rate", 100)) / 100.0)
	return max(value, 0)


func hit() -> int:
	return 100


func eva() -> int:
	var value: int = 0
	for slot in EQUIP_SLOTS:
		var armor_id: int = int(equipment[slot])
		if armor_id > 0:
			value += int(DB.armor(armor_id).get("eva", 0))
	return value


func critical_rate() -> int:
	return 4


func _equip_atk() -> int:
	var value := 0
	var wid: int = int(equipment["weapon"])
	if wid > 0:
		value += int(DB.weapon(wid).get("atk", 0))
	for i in range(1, 5):
		var aid: int = int(equipment["armor%d" % i])
		if aid > 0:
			value += int(DB.armor(aid).get("str_plus", 0))
	return value


func _equip_pdef() -> int:
	var value := 0
	var wid: int = int(equipment["weapon"])
	if wid > 0:
		value += int(DB.weapon(wid).get("pdef", 0))
	for i in range(1, 5):
		var aid: int = int(equipment["armor%d" % i])
		if aid > 0:
			value += int(DB.armor(aid).get("pdef", 0))
	return value


func _equip_mdef() -> int:
	var value := 0
	var wid: int = int(equipment["weapon"])
	if wid > 0:
		value += int(DB.weapon(wid).get("mdef", 0))
	for i in range(1, 5):
		var aid: int = int(equipment["armor%d" % i])
		if aid > 0:
			value += int(DB.armor(aid).get("mdef", 0))
	return value


func _equip_agi() -> int:
	var value := 0
	var wid: int = int(equipment["weapon"])
	if wid > 0:
		value += int(DB.weapon(wid).get("agi_plus", 0))
	for i in range(1, 5):
		var aid: int = int(equipment["armor%d" % i])
		if aid > 0:
			value += int(DB.armor(aid).get("agi_plus", 0))
	return value


func weapon_item() -> Dictionary:
	var wid: int = int(equipment["weapon"])
	return DB.weapon(wid) if wid > 0 else {}


func armor_item(slot: int) -> Dictionary:
	var aid: int = int(equipment.get("armor%d" % slot, 0))
	return DB.armor(aid) if aid > 0 else {}


func equip(slot_index: int, equipment_id: int) -> int:
	"""Returns the id of the item that was replaced."""
	var key: String = EQUIP_SLOTS[slot_index]
	if equipment_id <= 0:
		var old: int = int(equipment[key])
		equipment[key] = 0
		return old
	if int(equipment[key]) == equipment_id:
		return -1
	var old_id: int = int(equipment[key])
	equipment[key] = equipment_id
	return old_id


func equippable(item: Dictionary, is_weapon: bool) -> bool:
	var list: Array = item.get("can_equip_actors", [])
	return list.is_empty() or list.has(id)


func learn_skills() -> void:
	skills.clear()
	var cls: Dictionary = DB.klass(class_id)
	for learning in cls.get("learnings", []):
		if int(learning.get("level", 1)) <= level:
			var sid: int = int(learning.get("skill_id", 0))
			if sid > 0 and not skills.has(sid):
				skills.append(sid)


func recover_all() -> void:
	hp = maxhp()
	sp = maxsp()
	states.clear()


func exists() -> bool:
	return true


func is_dead() -> bool:
	return hp <= 0


func is_hp0() -> bool:
	return hp <= 0


func inputable() -> bool:
	return exists() and not is_dead()


func get_on(t: GameTank) -> void:
	tank = t
	t.driver = self


func get_off() -> void:
	if tank != null:
		tank.driver = null
	tank = null


func gain_exp(amount: int) -> bool:
	if amount <= 0 or level >= max_level():
		return false
	exp = min(exp + amount, 9999999)
	var leveled := false
	while level < max_level() and exp >= exp_for_level(level + 1):
		level += 1
		leveled = true
		learn_skills()
	if leveled:
		hp = maxhp()
		sp = maxsp()
	return leveled


func add_state(state_id: int) -> void:
	if not states.has(state_id):
		states.append(state_id)


func remove_state(state_id: int) -> void:
	states.erase(state_id)


func state_rate(state_id: int) -> int:
	var ranks: Dictionary = DB.klass(class_id).get("state_ranks", {})
	var data: Array = ranks.get("data", [])
	if state_id >= 0 and state_id < data.size():
		return int(data[state_id])
	return 3


func display_equipment(slot_index: int) -> String:
	if slot_index == 0:
		var w: Dictionary = weapon_item()
		return w.get("name", "无") if not w.is_empty() else "无"
	var armor_id: int = int(equipment.get("armor%d" % slot_index, 0))
	if armor_id > 0:
		return DB.armor(armor_id).get("name", "无")
	return "无"


func hp_text() -> String:
	return "%d/%d" % [hp, maxhp()]
