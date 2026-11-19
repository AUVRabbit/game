class_name ScriptBridge
extends RefCounted
## Minimal Ruby script-call bridge for RMXP event commands (codes 355 / 655).
## The original project uses Ruby one-liners to open scenes and manipulate MM
## objects; this class maps those calls onto the Godot runtime.

const MM_CONSTANTS := {
	"MESSAGE_TALK": 0, "MESSAGE_BATTLE": 1, "MESSAGE_MOVIE": 2,
	"SHOPTYPE_PEOPLEEQUIPMENT": 0, "SHOPTYPE_PEOPLEITEM": 1,
	"SHOPTYPE_TANKEQUIPMENT": 2, "SHOPTYPE_TANKITEM": 3,
	"MACHINETYPE_LIFT": 0, "MACHINETYPE_EXP": 1, "MACHINETYPE_SWITCH": 2,
	"MACHINETYPE_PASSWORD": 3
}

var interpreter: Node = null
var locals: Dictionary = {}
var _pending := ""
var _in_comment := false
var _loop_lines: Array[String] = []
var _loop_var := ""
var _loop_from := 0
var _loop_to := 0
var _in_loop := false


func _init(interp: Node = null) -> void:
	interpreter = interp


func reset() -> void:
	locals.clear()
	_pending = ""
	_in_comment = false
	_loop_lines.clear()
	_in_loop = false


func execute(raw_line: String) -> void:
	var line := raw_line.strip_edges()
	if _in_comment:
		if line.begins_with("=end"):
			_in_comment = false
		return
	if line.begins_with("=begin"):
		_in_comment = true
		return
	if line.is_empty() or line.begins_with("#"):
		return
	if not _pending.is_empty():
		line = _pending + " " + line
		_pending = ""
	if line.ends_with("\\") or line.ends_with("=") or line.ends_with("+") or line.ends_with(",") or line.ends_with("&&") or line.ends_with("||"):
		if line.ends_with("\\"):
			line = line.substr(0, line.length() - 1)
		_pending = line
		return
	if _in_loop:
		if line == "end":
			_run_loop()
			return
		_loop_lines.append(line)
		return
	# for i in a...b
	var for_re := RegEx.new()
	for_re.compile("^for\\s+(\\w+)\\s+in\\s+(-?\\d+)\\s*\\.\\.\\.?\\s*(-?\\d+)$")
	var fm := for_re.search(line)
	if fm != null:
		_loop_var = fm.get_string(1)
		_loop_from = int(fm.get_string(2))
		_loop_to = int(fm.get_string(3))
		_loop_lines.clear()
		_in_loop = true
		return
	_execute_line(line)


func _run_loop() -> void:
	var lines := _loop_lines.duplicate()
	var var_name := _loop_var
	var from_i := _loop_from
	var to_i := _loop_to
	_in_loop = false
	_loop_lines.clear()
	var word_re := RegEx.new()
	word_re.compile("\\b%s\\b" % var_name)
	for i in range(from_i, to_i):
		for l in lines:
			var replaced: String = word_re.sub(str(l), str(i), true)
			execute(replaced)


func _execute_line(line: String) -> void:
	# item.push <expr> (Ruby without parentheses)
	var push_re := RegEx.new()
	push_re.compile("^(\\w+)\\.push\\s+(.+)$")
	var pm := push_re.search(line)
	if pm != null:
		var arr = locals.get(pm.get_string(1), [])
		if arr is Array:
			arr.append(resolve(pm.get_string(2)))
			locals[pm.get_string(1)] = arr
		return
	# assignment first (handles $game_party.tanks[i].hp = ...)
	var eq := _find_assignment(line)
	if eq > 0:
		var lhs := line.substr(0, eq).strip_edges()
		var rhs := line.substr(eq + 1).strip_edges()
		_assign(lhs, rhs)
		return
	# $game_party.* / $game_map.* / $scene = ...
	if line.begins_with("$game_party.") or line.begins_with("$game_map.") or line.begins_with("$scene"):
		_invoke_target_string(line)
		return
	# object.method(args)
	var call_re := RegEx.new()
	call_re.compile("^(.+?)\\.(\\w+)\\((.*)\\)$")
	var cm := call_re.search(line)
	if cm != null:
		var target = resolve(cm.get_string(1))
		var method := cm.get_string(2)
		var args := _parse_args(cm.get_string(3))
		_invoke(target, method, args)
		return
	# no-parentheses method call, e.g. tank.main_cannon.big_broken
	var path_re := RegEx.new()
	path_re.compile("^(.+)\\.(\\w+)$")
	var path_m := path_re.search(line)
	if path_m != null:
		var base = resolve(path_m.get_string(1))
		if base != null and base is Object and base.has_method(path_m.get_string(2)):
			_invoke(base, path_m.get_string(2), [])
			return
	# property inside MM_System etc. — ignore constants
	if line.begins_with("MM_System::") or line.begins_with("item.") or line.begins_with("$game_temp.shop_goods"):
		return
	_invoke_target_string(line)


func _find_assignment(line: String) -> int:
	var depth := 0
	var quote := ""
	for i in range(line.length()):
		var ch := line[i]
		if quote != "":
			if ch == quote:
				quote = ""
			continue
		if ch == '"' or ch == "'":
			quote = ch
		elif ch == "[" or ch == "(":
			depth += 1
		elif ch == "]" or ch == ")":
			depth -= 1
		elif ch == "=" and depth == 0:
			var next_ch := line[i + 1] if i + 1 < line.length() else ""
			var prev_ch := line[i - 1] if i > 0 else ""
			if next_ch != "=" and prev_ch not in ["=", "!", "<", ">"]:
				return i
	return -1


func _assign(lhs: String, rhs: String) -> void:
	var value = resolve(rhs)
	if lhs == "$scene":
		var scene_re := RegEx.new()
		scene_re.compile("(Scene_\\w+)")
		var sm := scene_re.search(rhs)
		if sm != null:
			Router.open_game_scene(sm.get_string(1))
		return
	if lhs.begins_with("$game_temp."):
		State.temp[lhs.substr(11)] = value
		return
	if lhs.begins_with("$game_switches["):
		var idx := _index(lhs)
		State.set_switch(idx, bool(value))
		return
	if lhs.begins_with("$game_variables["):
		State.set_variable(_index(lhs), int(value))
		return
	# $game_party.tanks[0].hp = ...
	var tank_re := RegEx.new()
	tank_re.compile("^\\$game_party\\.tanks\\[(\\d+)\\]\\.(\\w+)$")
	var tm := tank_re.search(lhs)
	if tm != null:
		var tanks := _party_tanks()
		var ti := int(tm.get_string(1))
		var attr := tm.get_string(2)
		if ti < tanks.size():
			var t: Variant = tanks[ti]
			if t != null:
				match attr:
					"hp": t.hp = int(value)
					"name": t.name = str(value)
		return
	# local object property: actor.hp = 400
	var dot := lhs.find(".")
	if dot > 0 and not lhs.begins_with("$"):
		var base_name := lhs.substr(0, dot)
		if locals.has(base_name):
			_set_property(locals[base_name], lhs.substr(dot + 1), value)
			return
	if locals.has(lhs):
		locals[lhs] = value
		return
	var actor_re := RegEx.new()
	actor_re.compile("^\\$game_party\\.actors\\[(\\d+)\\]\\.(\\w+)$")
	var am := actor_re.search(lhs)
	if am != null:
		var actors: Array = State.party.member_actors()
		var idx2 := int(am.get_string(1))
		if idx2 < actors.size():
			var a = actors[idx2]
			match am.get_string(2):
				"hp": a.hp = int(value)
				"sp": a.sp = int(value)
				"level": a.level = int(value)
				"exp": a.exp = int(value)
		return
	locals[lhs] = value


func resolve(expr: String) -> Variant:
	var e := expr.strip_edges()
	if e.is_empty():
		return null
	var strm := RegEx.new()
	strm.compile("^\"(.*)\"$")
	var sm := strm.search(e)
	if sm != null:
		return sm.get_string(1)
	if e == "true":
		return true
	if e == "false":
		return false
	if e == "nil":
		return null
	if e.is_valid_int():
		return int(e)
	if e.is_valid_float():
		return float(e)
	if e == "[]":
		return []
	if e.begins_with("MM_System::"):
		return MM_CONSTANTS.get(e.substr(11), 0)
	if e.ends_with(".clone"):
		return resolve(e.substr(0, e.length() - 6))
	if e == "$game_party.gold":
		return State.party.gold
	if e == "$game_party.tanks.size":
		return _party_tanks().size()
	if e == "$game_party.actors.size":
		return State.party.member_actors().size()
	if locals.has(e):
		return locals[e]
	# local object property, e.g. tank.main_cannon / m.quantity
	var dot := e.find(".")
	if dot > 0 and not e.begins_with("$"):
		var base = locals.get(e.substr(0, dot), null)
		if base != null:
			return _property(base, e.substr(dot + 1))
	# $game_party.tanks[i]
	var tank_re := RegEx.new()
	tank_re.compile("^\\$game_party\\.tanks\\[(\\d+)\\]$")
	var tm := tank_re.search(e)
	if tm != null:
		var ts := _party_tanks()
		var i := int(tm.get_string(1))
		return ts[i] if i < ts.size() else null
	# $game_party.tanks[i].slot
	var slot_re := RegEx.new()
	slot_re.compile("^\\$game_party\\.tanks\\[(\\d+)\\]\\.(\\w+)$")
	var sm2 := slot_re.search(e)
	if sm2 != null:
		var ts2 := _party_tanks()
		var i2 := int(sm2.get_string(1))
		if i2 >= ts2.size():
			return null
		var t2 = ts2[i2]
		var slot := sm2.get_string(2)
		if slot == "main_cannon" or slot == "sub_cannon" or slot == "se" or slot == "c_unit" or slot == "engine" or slot == "underpan":
			return t2.slot_equipment(slot)
		if slot == "hp":
			return t2.hp
		if slot == "maxhp":
			return t2.maxhp()
		if slot == "name":
			return t2.name
	# $game_party.actors[i]
	var actor_re := RegEx.new()
	actor_re.compile("^\\$game_party\\.actors\\[(\\d+)\\]$")
	var am := actor_re.search(e)
	if am != null:
		var actors: Array = State.party.member_actors()
		var i3 := int(am.get_string(1))
		return actors[i3] if i3 < actors.size() else null
	# data arrays
	var data_re := RegEx.new()
	data_re.compile("^\\$(data_\\w+)\\[(\\d+)\\]$")
	var dm := data_re.search(e)
	if dm != null:
		return _data_array(dm.get_string(1), int(dm.get_string(2)))
	# $game_temp.key
	if e.begins_with("$game_temp."):
		return State.temp.get(e.substr(11), null)
	# $game_switches[n]
	if e.begins_with("$game_switches["):
		return State.switch(_index(e))
	if e.begins_with("$game_variables["):
		return State.variable(_index(e))
	return e


func _data_array(name: String, id: int) -> Variant:
	match name:
		"data_actor_items": return DB.mm_get("actor_items", id)
		"data_tank_items": return DB.mm_get("tank_items", id)
		"data_weapons": return DB.mm_get("actor_weapons", id)
		"data_armors": return DB.mm_get("actor_armors", id)
		"data_items": return DB.item(id)
		"data_specialcannonballs": return DB.mm_get("special_cannonballs", id)
		"data_tanks": return DB.mm_get("tanks", id)
		"data_main_cannons": return DB.mm_get("main_cannons", id)
		"data_sub_cannons": return DB.mm_get("sub_cannons", id)
		"data_ses": return DB.mm_get("ses", id)
		"data_engines": return DB.mm_get("engines", id)
		"data_c_units": return DB.mm_get("c_units", id)
		"data_underpans": return DB.mm_get("underpans", id)
		"data_skills": return DB.skill(id)
		"data_enemies": return DB.enemy(id)
		"data_troops": return DB.troop(id)
		"data_states": return DB.state(id)
	return {}


func _parse_args(text: String) -> Array:
	var args := []
	var current := ""
	var depth := 0
	var quote := ""
	for i in range(text.length()):
		var ch := text[i]
		if quote != "":
			current += ch
			if ch == quote:
				quote = ""
			continue
		if ch == '"' or ch == "'":
			quote = ch
			current += ch
		elif ch == "(" or ch == "[" or ch == "{":
			depth += 1
			current += ch
		elif ch == ")" or ch == "]" or ch == "}":
			depth -= 1
			current += ch
		elif ch == "," and depth == 0:
			args.append(resolve(current))
			current = ""
		else:
			current += ch
	if not current.strip_edges().is_empty():
		args.append(resolve(current))
	return args


func _index(expr: String) -> int:
	var re := RegEx.new()
	re.compile("\\[(\\d+)\\]")
	var m := re.search(expr)
	return int(m.get_string(1)) if m != null else 0


func _party_tanks() -> Array:
	return State.party.party_tanks()


func _set_property(base: Variant, path: String, value: Variant) -> void:
	if base is GameActor:
		match path:
			"hp": base.hp = int(value)
			"sp": base.sp = int(value)
			"name": base.name = str(value)
			"level": base.level = int(value)
	elif base is GameTank:
		match path:
			"hp": base.hp = int(value)
			"name": base.name = str(value)
	elif base is GameTank.Equipment:
		match path:
			"quantity": base.quantity = int(value)
			"quantity_reality": base.quantity_reality = int(value)


func _property(base: Variant, path: String) -> Variant:
	if base is GameTank:
		match path:
			"main_cannon": return base.main_cannon
			"sub_cannon": return base.sub_cannon
			"se": return base.se
			"c_unit": return base.c_unit
			"engine": return base.engine
			"underpan": return base.underpan
			"hp": return base.hp
			"maxhp": return base.maxhp()
			"name": return base.name
		return null
	if base is GameTank.Equipment:
		match path:
			"quantity": return base.quantity
			"quantity_reality": return base.quantity_reality
			"name": return base.name
			"status": return base.status
			"atk": return base.atk
			"pdef": return base.pdef
			"weight": return base.weight
			"price": return base.price
		return null
	if base is GameActor:
		match path:
			"hp": return base.hp
			"sp": return base.sp
			"level": return base.level
			"exp": return base.exp
			"name": return base.name
			"tank": return base.tank
			"maxhp": return base.maxhp()
			"maxsp": return base.maxsp()
		return null
	if base is Dictionary:
		return base.get(path, null)
	if base is Object:
		return base.get(path)
	return null


func eval_condition(expr: String) -> bool:
	var text := expr.strip_edges()
	while text.begins_with("(") and text.ends_with(")"):
		text = text.substr(1, text.length() - 2).strip_edges()
	for op in ["==", "!=", ">=", "<=", ">", "<"]:
		var pos := text.find(op)
		if pos > 0:
			var lhs = resolve(text.substr(0, pos).strip_edges())
			var rhs = resolve(text.substr(pos + op.length()).strip_edges())
			var a := float(lhs) if lhs is int or lhs is float else 0.0
			var b := float(rhs) if rhs is int or rhs is float else 0.0
			match op:
				"==": return str(lhs) == str(rhs)
				"!=": return str(lhs) != str(rhs)
				">=": return a >= b
				"<=": return a <= b
				">": return a > b
				"<": return a < b
	var value = resolve(text)
	if value is bool:
		return value
	if value is int or value is float:
		return float(value) != 0.0
	return value != null


func _invoke(target: Variant, method: String, args: Array) -> void:
	if target == null:
		return
	if target is GameTank:
		match method:
			"get_speciall_cannonball", "get_special_cannonball":
				if args.size() >= 2:
					target.add_special_ball(int(args[0].get("id", 0)) if args[0] is Dictionary else int(args[0]), int(args[1]))
				return
		if target.has_method(method):
			target.callv(method, args)
		return
	if target is GameTank.Equipment:
		match method:
			"quantity_throw":
				target.quantity_reality = maxi(target.quantity_reality - int(args[0]), 0)
				return
			"big_broken":
				target.break_big()
				return
			"little_broken":
				target.break_little()
				return
		if target.has_method(method):
			target.callv(method, args)
		return
	if target is GameActor:
		match method:
			"gain_item":
				if args.size() >= 1 and args[0] is Dictionary:
					State.party.gain_item(int(args[0].get("id", 0)), 1)
				return
			"lose_item":
				if args.size() >= 1 and args[0] is Dictionary:
					State.party.lose_item(int(args[0].get("id", 0)), 1)
				return
		if target.has_method(method):
			target.callv(method, args)
		return
	if target is GameParty:
		match method:
			"gain_gold":
				State.party.gain_gold(int(args[0]))
				return
			"lose_gold":
				State.party.lose_gold(int(args[0]))
				return
			"trunk_add_item":
				if args.size() >= 1 and args[0] is Dictionary:
					State.party.trunk_add("actor_item", int(args[0].get("id", 0)), 1)
				return
		if target.has_method(method):
			target.callv(method, args)
		return
	# $game_map.wanted_person_strike(...)
	if target is Node and target.has_method(method):
		target.callv(method, args)
		return
	if target is Object and target.has_method(method):
		target.callv(method, args)


func _invoke_target_string(line: String) -> void:
	# $scene = Scene_X.new
	var scene_re := RegEx.new()
	scene_re.compile("^\\$scene\\s*=\\s*(Scene_\\w+)\\.new$")
	var sm := scene_re.search(line)
	if sm != null:
		Router.open_game_scene(sm.get_string(1))
		return
	# $game_party.tanks[0].get_speciall_cannonball(ball, n)
	var tank_call := RegEx.new()
	tank_call.compile("^\\$game_party\\.tanks\\[(\\d+)\\]\\.(\\w+)\\((.*)\\)$")
	var tkm := tank_call.search(line)
	if tkm != null:
		var tanks := _party_tanks()
		var ti := int(tkm.get_string(1))
		if ti < tanks.size():
			_invoke(tanks[ti], tkm.get_string(2), _parse_args(tkm.get_string(3)))
		return
	# $game_party.actors[0].gain_item(item)
	var actor_call := RegEx.new()
	actor_call.compile("^\\$game_party\\.actors\\[(\\d+)\\]\\.(\\w+)\\((.*)\\)$")
	var acm := actor_call.search(line)
	if acm != null:
		var actors: Array = State.party.member_actors()
		var idx := int(acm.get_string(1))
		if idx < actors.size():
			_invoke(actors[idx], acm.get_string(2), _parse_args(acm.get_string(3)))
		return
	# $game_party.gain_gold(...)
	var party_call := RegEx.new()
	party_call.compile("^\\$game_party\\.(\\w+)\\((.*)\\)$")
	var pcm := party_call.search(line)
	if pcm != null:
		_invoke(State.party, pcm.get_string(1), _parse_args(pcm.get_string(2)))
		return
	# $game_party.trunk_add_item(item)
	var trunk_call := RegEx.new()
	trunk_call.compile("^\\$game_party\\.trunk_add_item\\((.*)\\)$")
	var tcm := trunk_call.search(line)
	if tcm != null:
		_invoke(State.party, "trunk_add_item", _parse_args(tcm.get_string(1)))
		return
	# $game_temp.shop_goods.clear
	if line.ends_with(".clear"):
		var base := line.substr(0, line.length() - 6)
		var arr = resolve(base)
		if arr is Array:
			arr.clear()
			if base.begins_with("$game_temp."):
				State.temp[base.substr(11)] = arr
		return
	# $game_map.xxx(args)
	var map_re := RegEx.new()
	map_re.compile("^\\$game_map\\.(\\w+)\\((.*)\\)$")
	var mmm := map_re.search(line)
	if mmm != null and State.current_map != null and State.current_map.has_method(mmm.get_string(1)):
		State.current_map.callv(mmm.get_string(1), _parse_args(mmm.get_string(2)))
