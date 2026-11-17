class_name GameParty
extends RefCounted
## Party state, ported from Game_Party / Game_Tanks.

var actors: Dictionary = {}      # actor_id -> GameActor
var tanks: Dictionary = {}       # tank_id -> GameTank
var members: Array = []          # up to 4: GameActor or GameTank
var gold: int = 0
var steps: int = 0
var actor_items: Dictionary = {} # item_id -> count
var tank_items: Dictionary = {}  # item_id -> count
var trunk: Array = []            # array of {type, id, count}
var rent_tanks: Array[int] = []
var tow_tank: GameTank = null


func setup_starting_members() -> void:
	actors.clear()
	tanks.clear()
	members.clear()
	gold = 0
	steps = 0
	actor_items.clear()
	tank_items.clear()
	trunk.clear()
	for actor_id in DB.system.get("party_members", [1]):
		var actor := GameActor.new(int(actor_id))
		actor.learn_skills()
		actors[int(actor_id)] = actor
		members.append(actor)


func actor(actor_id: int) -> GameActor:
	return actors.get(actor_id, null)


func tank(tank_id: int) -> GameTank:
	if not tanks.has(tank_id):
		tanks[tank_id] = GameTank.new(tank_id)
	return tanks.get(tank_id)


func member_actors() -> Array[GameActor]:
	var out: Array[GameActor] = []
	for m in members:
		if m is GameActor:
			out.append(m)
	return out


func member_tanks() -> Array[GameTank]:
	var out: Array[GameTank] = []
	for m in members:
		if m is GameTank:
			out.append(m)
	return out


func party_tanks() -> Array[GameTank]:
	var out: Array[GameTank] = []
	for t in tanks.values():
		out.append(t)
	return out


func gain_gold(n: int) -> void:
	gold = clampi(gold + n, 0, 9999999)


func lose_gold(n: int) -> void:
	gain_gold(-n)


func increase_steps() -> void:
	steps = mini(steps + 1, 9999999)


func add_actor(actor_id: int) -> void:
	if members.size() >= 4:
		return
	var a: GameActor = actor(actor_id)
	if a == null:
		a = GameActor.new(actor_id)
		a.learn_skills()
		actors[actor_id] = a
	if not members.has(a):
		members.append(a)


func remove_actor(actor_id: int) -> void:
	var a: GameActor = actor(actor_id)
	if a != null:
		members.erase(a)
		actors.erase(actor_id)


func add_tank(index: int, tank_id: int) -> bool:
	if members.size() >= 4:
		return false
	var t: GameTank = tank(tank_id)
	if members.has(t):
		return false
	if index >= 0 and index < members.size():
		members[index] = t
	else:
		members.append(t)
	return true


func remove_tank(index: int, tank_id: int) -> void:
	var t: GameTank = tank(tank_id)
	if t != null:
		members.erase(t)
		if t.driver != null:
			if index >= 0 and index < members.size():
				members[index] = t.driver
			else:
				members.append(t.driver)


func add_tow_tank(tank_id: int) -> void:
	tow_tank = tank(tank_id)


func remove_tow_tank() -> void:
	tow_tank = null


func updown_in_battle(index: int) -> void:
	if index < 0 or index >= members.size():
		return
	var m = members[index]
	if m is GameActor and m.tank != null:
		members[index] = m.tank
	elif m is GameTank and m.driver != null:
		members[index] = m.driver


func gain_item(item_id: int, count: int = 1) -> void:
	actor_items[item_id] = int(actor_items.get(item_id, 0)) + count


func lose_item(item_id: int, count: int = 1) -> void:
	var left: int = int(actor_items.get(item_id, 0)) - count
	if left > 0:
		actor_items[item_id] = left
	else:
		actor_items.erase(item_id)


func item_number(item_id: int) -> int:
	return int(actor_items.get(item_id, 0))


func gain_tank_item(item_id: int, count: int = 1) -> void:
	tank_items[item_id] = int(tank_items.get(item_id, 0)) + count


func lose_tank_item(item_id: int, count: int = 1) -> void:
	var left: int = int(tank_items.get(item_id, 0)) - count
	if left > 0:
		tank_items[item_id] = left
	else:
		tank_items.erase(item_id)


func tank_item_number(item_id: int) -> int:
	return int(tank_items.get(item_id, 0))


func trunk_add(type: String, item_id: int, count: int = 1) -> void:
	for entry in trunk:
		if entry.get("type", "") == type and int(entry.get("id", 0)) == item_id:
			entry["count"] = int(entry.get("count", 1)) + count
			return
	trunk.append({"type": type, "id": item_id, "count": count})


func all_dead() -> bool:
	if members.is_empty():
		return false
	for a in member_actors():
		if a.hp > 0:
			return false
	return true


func inputable() -> bool:
	for m in members:
		if m is GameTank:
			if m.inputable():
				return true
		elif m.inputable():
			return true
	return false


func max_level() -> int:
	var lv := 0
	for a in member_actors():
		lv = maxi(lv, a.level)
	return lv


func total_weight() -> float:
	var value := 0.0
	for t in member_tanks():
		value += t.load_reality()
	return value


func to_save_dict() -> Dictionary:
	var actor_data := {}
	for id in actors:
		var a: GameActor = actors[id]
		actor_data[str(id)] = {
			"level": a.level, "exp": a.exp, "hp": a.hp, "sp": a.sp,
			"states": a.states, "equipment": a.equipment, "skills": a.skills
		}
	var tank_data := {}
	for id in tanks:
		var t: GameTank = tanks[id]
		var slots := {}
		for key in ["main_cannon", "sub_cannon", "se", "c_unit", "engine", "underpan"]:
			var e: GameTank.Equipment = t.slot_equipment(key)
			if e != null:
				slots[key] = {"id": e.id, "status": e.status, "ammo": e.quantity_reality}
			else:
				slots[key] = null
		tank_data[str(id)] = {"hp": t.hp, "slots": slots, "rent": t.rent}
	var member_ids := []
	for m in members:
		if m is GameActor:
			member_ids.append("a%d" % m.id)
		elif m is GameTank:
			member_ids.append("t%d" % m.id)
	return {
		"gold": gold, "steps": steps,
		"actor_items": actor_items, "tank_items": tank_items, "trunk": trunk,
		"actors": actor_data, "tanks": tank_data, "members": member_ids,
		"rent_tanks": rent_tanks
	}


func load_save_dict(d: Dictionary) -> void:
	setup_starting_members()
	gold = int(d.get("gold", 0))
	steps = int(d.get("steps", 0))
	actor_items = d.get("actor_items", {})
	tank_items = d.get("tank_items", {})
	trunk = d.get("trunk", [])
	rent_tanks = d.get("rent_tanks", [])
	var ad: Dictionary = d.get("actors", {})
	for key in ad:
		var a: GameActor = actors.get(int(key), null)
		if a == null:
			a = GameActor.new(int(key))
			a.learn_skills()
			actors[int(key)] = a
		var e: Dictionary = ad[key]
		a.level = int(e.get("level", 1))
		a.exp = int(e.get("exp", 0))
		a.states.assign(e.get("states", []))
		a.skills.assign(e.get("skills", []))
		var eq: Dictionary = e.get("equipment", {})
		for slot in eq:
			a.equipment[slot] = int(eq[slot])
		a._refresh_exp_list()
		a.hp = int(e.get("hp", a.maxhp()))
		a.sp = int(e.get("sp", a.maxsp()))
	var td: Dictionary = d.get("tanks", {})
	for key in td:
		var t: GameTank = tank(int(key))
		var e: Dictionary = td[key]
		t.hp = int(e.get("hp", t.maxhp()))
		t.rent = bool(e.get("rent", false))
		var slots: Dictionary = e.get("slots", {})
		for key2 in slots:
			var s = slots[key2]
			if s == null:
				t.equip_slot(key2, 0)
			else:
				t.equip_slot(key2, int(s.get("id", 0)))
				var eqe: GameTank.Equipment = t.slot_equipment(key2)
				if eqe != null:
					eqe.status = int(s.get("status", 0))
					eqe.quantity_reality = int(s.get("ammo", eqe.quantity))
	var ids: Array = d.get("members", [])
	if not ids.is_empty():
		members.clear()
		for mid in ids:
			var sid: String = str(mid)
			if sid.begins_with("a"):
				var a2: GameActor = actors.get(int(sid.substr(1)), null)
				if a2 != null:
					members.append(a2)
			elif sid.begins_with("t"):
				members.append(tank(int(sid.substr(1))))
