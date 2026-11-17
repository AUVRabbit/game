class_name GameTank
extends RefCounted
## Runtime tank + equipment, ported from Game_Tank / Game_MainCannon etc.

const EQUIP_NORMAL := 0
const EQUIP_LITTLE_BROKEN := 1
const EQUIP_BIG_BROKEN := 2

const SLOT_KINDS := {
	"main_cannon": "main_cannons",
	"sub_cannon": "sub_cannons",
	"se": "ses",
	"c_unit": "c_units",
	"engine": "engines",
	"underpan": "underpans",
}


class Equipment:
	var id: int = 0
	var kind: String = ""
	var name: String = ""
	var status: int = 0
	var quantity: int = 0
	var quantity_reality: int = 0
	var atk: int = 0
	var pdef: int = 0
	var weight: float = 0.0
	var price: int = 0
	var repair_price_list: Array = []
	var load: float = 0.0
	var data: Dictionary = {}
	var hole: Array = []
	var special_cannonball_capacity: int = 0
	var transform_information: Array = []

	func _init(equip_kind: String, equip_id: int) -> void:
		kind = equip_kind
		_load_data(equip_id)

	func _load_data(equip_id: int) -> void:
		id = equip_id
		var list_name: String = SLOT_KINDS.get(kind, "")
		data = DB.mm_get(list_name, id)
		name = data.get("name", "")
		atk = int(data.get("atk", 0))
		pdef = int(data.get("pdef", 0))
		weight = float(data.get("weight", 0.0))
		price = int(data.get("price", 0))
		load = float(data.get("load", 0.0))
		quantity = int(data.get("quantity", 0))
		quantity_reality = quantity
		repair_price_list = data.get("repair_price", [])
		hole = data.get("hole", []).duplicate()
		special_cannonball_capacity = int(data.get("special_cannonball_capacity", 0))
		var transforms: Dictionary = DB.mm.get("data_enginetransform", {})
		if transforms is Dictionary and transforms.has(str(id)):
			transform_information = transforms[str(id)]
		else:
			transform_information = []

	func transform(new_id: int) -> void:
		_load_data(new_id)
		status = EQUIP_NORMAL

	func hole_opened(position: int) -> bool:
		return position >= 0 and position < hole.size() and bool(hole[position])

	func open_hole(position: int) -> void:
		if position < 0:
			return
		while hole.size() <= position:
			hole.append(false)
		hole[position] = true

	func quantity_add(number: int) -> void:
		quantity_reality = mini(quantity_reality + number, quantity)

	func pdef_change(value: int) -> void:
		pdef = value

	func weight_change(value: float) -> void:
		weight = value

	func special_cannonball_capacity_change(value: int) -> void:
		special_cannonball_capacity = value

	func cannonball_price() -> int:
		var table := {}
		match kind:
			"sub_cannon": table = DB.mm.get("data_sub_cannon_cannonball_price", {})
			"se": table = DB.mm.get("data_se_cannonball_price", {})
		if table is Dictionary and table.has(str(id)):
			return int(table[str(id)])
		return 0

	func is_normal() -> bool:
		return status == EQUIP_NORMAL

	func is_little_broken() -> bool:
		return status == EQUIP_LITTLE_BROKEN

	func is_big_broken() -> bool:
		return status == EQUIP_BIG_BROKEN

	func break_little() -> void:
		if status < EQUIP_LITTLE_BROKEN:
			status = EQUIP_LITTLE_BROKEN

	func break_big() -> void:
		status = EQUIP_BIG_BROKEN

	func repair() -> void:
		status = EQUIP_NORMAL

	func repair_cost() -> int:
		if status == EQUIP_NORMAL:
			return 0
		var idx: int = status - 1
		if idx >= 0 and idx < repair_price_list.size():
			return int(repair_price_list[idx])
		return 0

	func quantity_empty() -> bool:
		return quantity_reality <= 0

	func quantity_full() -> bool:
		return quantity_reality >= quantity

	func quantity_use() -> void:
		quantity_reality = max(quantity_reality - 1, 0)


var id: int = 0
var name: String = ""
var character_name: String = ""
var character_hue: int = 0
var battler_name: String = ""
var driver: GameActor = null
var hp: int = 1
var rent: bool = false
var data: Dictionary = {}

var main_cannon: Equipment = null
var sub_cannon: Equipment = null
var se: Equipment = null
var c_unit: Equipment = null
var engine: Equipment = null
var underpan: Equipment = null

var equipments: Array[Equipment] = []
var items: Array = []
var special_cannonballs: Dictionary = {}   # ball id -> count


func _init(tank_id: int = 0) -> void:
	if tank_id <= 0:
		return
	setup(tank_id)


func setup(tank_id: int) -> void:
	id = tank_id
	data = DB.mm_get("tanks", tank_id)
	name = data.get("name", "")
	character_name = data.get("character_name", "Tank_1")
	character_hue = int(data.get("character_hue", 0))
	battler_name = data.get("battler_name", "Tank1.png")
	rent = bool(data.get("rent", false))
	main_cannon = _make_equip("main_cannon", int(data.get("main_cannon_id", 0)))
	sub_cannon = _make_equip("sub_cannon", int(data.get("sub_cannon_id", 0)))
	se = _make_equip("se", int(data.get("se_id", 0)))
	c_unit = _make_equip("c_unit", int(data.get("c_unit_id", 0)))
	engine = _make_equip("engine", int(data.get("engine_id", 0)))
	underpan = _make_equip("underpan", int(data.get("underpan_id", 0)))
	_rebuild_equipments()
	if underpan != null:
		var balls = underpan.data.get("special_cannonball", {})
		if balls is Dictionary:
			for key in balls:
				special_cannonballs[int(key)] = int(balls[key])
	hp = maxhp()


func _make_equip(kind: String, equip_id: int) -> Equipment:
	return Equipment.new(kind, equip_id) if equip_id > 0 else null


func _rebuild_equipments() -> void:
	equipments.clear()
	for e in [main_cannon, sub_cannon, se, c_unit, engine, underpan]:
		if e != null:
			equipments.append(e)


func equipment_list() -> Array[Equipment]:
	return equipments


func set_driver(actor: GameActor) -> void:
	driver = actor


func tank_id() -> int:
	return id


func maxhp() -> int:
	var weight := 0.0
	for e in equipments:
		weight += e.weight
	if engine == null:
		return 0
	return max(int((engine.load - weight) * 100.0), 0)


func load_max() -> float:
	return engine.load if engine != null else 0.0


func load_reality() -> float:
	var value := 0.0
	for e in equipments:
		value += e.weight
	value += hp / 100.0
	return value


func overload() -> bool:
	return load_max() < load_reality()


func pdef() -> int:
	var value := 0
	for e in equipments:
		value += e.pdef
	return value


func atk() -> int:
	return 0


func agi() -> int:
	return 30


func hit() -> int:
	return 100


func eva() -> int:
	return 0


func exists() -> bool:
	return underpan != null and not underpan.is_big_broken()


func is_dead() -> bool:
	return underpan != null and underpan.is_big_broken()


func is_hp0() -> bool:
	return hp <= 0


func inputable() -> bool:
	return exists()


func main_cannon_usable() -> bool:
	return main_cannon != null and main_cannon.is_normal() and not main_cannon.quantity_empty()


func sub_cannon_usable() -> bool:
	return sub_cannon != null and sub_cannon.is_normal() and not sub_cannon.quantity_empty()


func se_usable() -> bool:
	return se != null and se.is_normal()


func slots() -> Dictionary:
	return {
		"main_cannon": main_cannon,
		"sub_cannon": sub_cannon,
		"se": se,
		"c_unit": c_unit,
		"engine": engine,
		"underpan": underpan,
	}


func slot_equipment(slot: String) -> Equipment:
	return slots().get(slot, null)


func equip_slot(slot: String, equip_id: int) -> void:
	var old: Equipment = slot_equipment(slot)
	if old != null:
		equipments.erase(old)
	var new_equip: Equipment = _make_equip(slot, equip_id)
	match slot:
		"main_cannon": main_cannon = new_equip
		"sub_cannon": sub_cannon = new_equip
		"se": se = new_equip
		"c_unit": c_unit = new_equip
		"engine": engine = new_equip
		"underpan": underpan = new_equip
	if new_equip != null:
		equipments.append(new_equip)
	hp = min(hp, maxhp())


func display_slot(slot: String) -> String:
	var e: Equipment = slot_equipment(slot)
	return e.name if e != null else "无"


func repair_all() -> int:
	var cost := 0
	for e in equipments:
		cost += e.repair_cost()
		e.repair()
	if underpan != null:
		underpan.repair()
	return cost


func repair_cost_all() -> int:
	var cost := 0
	for e in equipments:
		cost += e.repair_cost()
	return cost


func ammo_missing() -> int:
	var missing := 0
	for e in equipments:
		if e.quantity > 0:
			missing += maxi(e.quantity - e.quantity_reality, 0)
	return missing


func broken_equipment_names() -> Array[String]:
	var out: Array[String] = []
	for e in equipments:
		if not e.is_normal():
			out.append(e.name)
	return out


func full_ammo() -> void:
	for e in equipments:
		if e.quantity > 0:
			e.quantity_reality = e.quantity


func add_special_ball(ball_id: int, count: int = 1) -> void:
	if ball_id <= 0:
		return
	special_cannonballs[ball_id] = int(special_cannonballs.get(ball_id, 0)) + count


func special_ball_number(ball_id: int) -> int:
	return int(special_cannonballs.get(ball_id, 0))


func use_special_ball(ball_id: int) -> void:
	var left := special_ball_number(ball_id) - 1
	if left > 0:
		special_cannonballs[ball_id] = left
	else:
		special_cannonballs.erase(ball_id)
