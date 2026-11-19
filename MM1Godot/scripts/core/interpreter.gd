class_name Interpreter
extends Node
## Event command interpreter (RMXP event command subset used by this project).

signal finished

const _BRIDGE_SCRIPT := preload("res://scripts/core/script_bridge.gd")

var map_scene: Node = null
var event_node = null
var bridge = null
var commands: Array = []
var index := 0
var running := false

var _loop_stack: Array[int] = []


func _ready() -> void:
	bridge = _BRIDGE_SCRIPT.new(self)


func setup(list: Array, event = null) -> void:
	commands = list.duplicate(true)
	event_node = event
	index = 0
	if bridge == null:
		bridge = _BRIDGE_SCRIPT.new(self)
	else:
		bridge.reset()


func run() -> void:
	if running:
		return
	running = true
	State.interpreter = self
	await _run_list()
	running = false
	State.interpreter = null
	finished.emit()


func _run_list() -> void:
	while index < commands.size():
		var cmd = commands[index]
		var code := 0
		var params: Array = []
		if cmd is Array:
			code = int(cmd[0])
			params = cmd[2] if cmd.size() > 2 else []
		elif cmd is Dictionary:
			code = int(cmd.get("code", 0))
			params = cmd.get("parameters", [])
		index += 1
		match code:
			0:
				break
			101:
				await _cmd_show_text(params)
			102:
				await _cmd_show_choices(params)
			106:
				var frames := int(params[0]) if params.size() > 0 else 10
				await get_tree().create_timer(frames / 20.0).timeout
			108:
				await _cmd_comment(params)
			111:
				if not _eval_condition(params):
					_jump_after_else()
			112:
				_loop_stack.append(index)
			113:
				_jump_after_loop()
			115:
				index = commands.size()
			116:
				pass
			117:
				await _cmd_common_event(params)
			121:
				_cmd_switch(params)
			122:
				_cmd_variable(params)
			123:
				_cmd_self_switch(params)
			125:
				_cmd_gold(params)
			201:
				await _cmd_transfer(params)
			241:
				_cmd_bgm(params)
			247:
				_cmd_se(params)
			248:
				Audio.stop_se()
			301:
				await _cmd_battle(params)
			355, 655:
				_cmd_script(params)
				await _after_overlay()
			411:
				# reached else body of a taken true branch: skip it
				_jump_after_else_end()
			412:
				pass
			413:
				if not _loop_stack.is_empty():
					index = _loop_stack.back()
					await get_tree().process_frame
			601:
				_battle_branch(0)
			602:
				_battle_branch(1)
			603:
				_battle_branch(2)
			604:
				pass
			_:
				pass


func _cmd_show_text(params: Array) -> void:
	if map_scene == null:
		return
	var text := str(params[0]) if params.size() > 0 else ""
	await map_scene.show_message(text)


func _cmd_show_choices(params: Array) -> void:
	if map_scene == null:
		return
	var options: Array = params[0] if params.size() > 0 else []
	var result: int = await map_scene.show_choices(options)
	State.temp["choice"] = result
	# skip branches: 402/403 when-branches, 404 end
	var depth := 0
	while index < commands.size():
		var c := _code_at(index)
		index += 1
		if c == 102:
			depth += 1
		elif c == 404:
			if depth == 0:
				return
			depth -= 1


func _cmd_comment(params: Array) -> void:
	var lines: Array[String] = []
	if not params.is_empty():
		lines.append(str(params[0]))
	while index < commands.size():
		if _code_at(index) != 408:
			break
		var cont = commands[index]
		if cont is Array:
			lines.append(str(cont[2][0]))
		elif cont is Dictionary:
			lines.append(str(cont.get("parameters", [""])[0]))
		index += 1
	_parse_comment("\n".join(lines))


func _parse_comment(text: String) -> void:
	var goods: Array = State.temp.get("shop_goods", [])
	if not (goods is Array):
		goods = []
	for raw in text.split("\n"):
		for segment in raw.split(";"):
			var s := segment.strip_edges()
			if s.is_empty():
				continue
			var eq := s.find("=")
			var key := s.substr(0, eq).strip_edges() if eq > 0 else s
			var ids: Array = _parse_id_list(s.substr(eq + 1)) if eq > 0 else []
			match key:
				"清空列表", "ClearList":
					goods.clear()
				"人类武器", "Weapon":
					_push_goods(goods, "weapon", ids)
				"人类防具", "Armor":
					_push_goods(goods, "armor", ids)
				"人类道具", "PeopleItem", "ActorItem":
					_push_goods(goods, "actor_item", ids)
				"战车道具", "TankItem":
					_push_goods(goods, "tank_item", ids)
				"主炮", "MainCannon":
					_push_goods(goods, "main_cannon", ids)
				"副炮", "SubCannon":
					_push_goods(goods, "sub_cannon", ids)
				"SE", "Se":
					_push_goods(goods, "se", ids)
				"C装置", "CUnit":
					_push_goods(goods, "c_unit", ids)
				"引擎", "Engine":
					_push_goods(goods, "engine", ids)
				"底盘", "Underpan":
					_push_goods(goods, "underpan", ids)
				"出租战车", "RentTank":
					State.temp["rent_tanks_id"] = ids[0] if not ids.is_empty() else 0
				"通缉犯", "WantedPerson":
					State.temp["wanted_list"] = ids
	State.temp["shop_goods"] = goods


func _push_goods(goods: Array, kind: String, ids: Array) -> void:
	var table := ""
	match kind:
		"main_cannon": table = "main_cannons"
		"sub_cannon": table = "sub_cannons"
		"se": table = "ses"
		"c_unit": table = "c_units"
		"engine": table = "engines"
		"underpan": table = "underpans"
		"actor_item": table = "actor_items"
		"tank_item": table = "tank_items"
	for i in ids:
		var item: Dictionary = {}
		if kind == "weapon":
			item = DB.weapon(int(i))
		elif kind == "armor":
			item = DB.armor(int(i))
		else:
			item = DB.mm_get(table, int(i))
		if not item.is_empty():
			goods.append({"kind": kind, "id": int(i), "item": item})


func _parse_id_list(text: String) -> Array:
	var out: Array = []
	var cleaned := text.replace("[", " ").replace("]", " ").replace(";", " ")
	for token in cleaned.split(","):
		var t := token.strip_edges()
		if t.is_valid_int():
			out.append(int(t))
	return out


func _cmd_common_event(params: Array) -> void:
	var id := int(params[0]) if params.size() > 0 else 0
	var ce: Dictionary = DB.common_event(id)
	if ce.is_empty():
		return
	var saved := commands
	var saved_index := index
	commands = ce.get("list", [])
	index = 0
	await _run_list()
	commands = saved
	index = saved_index
	await _after_overlay()


func _cmd_switch(params: Array) -> void:
	if params.size() < 2:
		return
	# RMXP: [switch_id, value] where value 0 = ON, 1 = OFF
	State.set_switch(int(params[0]), int(params[1]) == 0)


func _cmd_variable(params: Array) -> void:
	if params.size() < 4:
		return
	# RMXP: [variable_id, operation, operand_type, operand]
	var var_id := int(params[0])
	var op := int(params[1])
	var operand_type := int(params[2])
	var value := int(params[3])
	if operand_type == 1:
		value = State.variable(value)
	var current := State.variable(var_id)
	match op:
		0:
			current = value
		1:
			current += value
		2:
			current -= value
		3:
			current *= value
		4:
			current = int(current / max(value, 1))
		5:
			current = current % max(value, 1)
	State.set_variable(var_id, current)


func _cmd_self_switch(params: Array) -> void:
	if params.size() < 2 or event_node == null:
		return
	var key := str(params[0])
	# RMXP: 0 = ON, 1 = OFF
	var on := int(params[1]) == 0
	State.set_self_switch(State.map_id, event_node.event_id, key, on)
	event_node.refresh()


func _cmd_gold(params: Array) -> void:
	if params.size() < 3:
		return
	var op := int(params[0])
	var operand_type := int(params[1])
	var value := int(params[2])
	if operand_type == 1:
		value = State.variable(value)
	if op == 0:
		State.party.gain_gold(value)
	else:
		State.party.lose_gold(value)


func _cmd_transfer(params: Array) -> void:
	if params.size() < 5:
		return
	var map_id := int(params[1])
	var x := int(params[2])
	var y := int(params[3])
	var dir := int(params[4])
	dir = dir if dir > 0 else 2
	index = commands.size()
	Router.load_map(map_id, x, y, dir, true)


func _cmd_bgm(params: Array) -> void:
	if params.is_empty():
		return
	var a: Dictionary = params[0] if params[0] is Dictionary else {}
	Audio.play_bgm(str(a.get("name", "")), int(a.get("volume", 100)))


func _cmd_se(params: Array) -> void:
	if params.is_empty():
		return
	var a: Dictionary = params[0] if params[0] is Dictionary else {}
	Audio.play_se(str(a.get("name", "")), int(a.get("volume", 100)))


func _cmd_script(params: Array) -> void:
	if params.is_empty() or bridge == null:
		return
	bridge.execute(str(params[0]))


func _cmd_battle(params: Array) -> void:
	var troop_id := int(params[0]) if params.size() > 0 else 1
	var can_escape := bool(params[1]) if params.size() > 1 else true
	var result := 0
	if map_scene != null:
		result = await map_scene.start_battle(troop_id, can_escape)
	State.temp["battle_result"] = result


func _battle_branch(kind: int) -> void:
	var result := int(State.temp.get("battle_result", 0))
	if result == kind:
		return
	# skip to matching 604
	var depth := 0
	while index < commands.size():
		var c := _code_at(index)
		index += 1
		if c == 601 or c == 602 or c == 603:
			depth += 1
		elif c == 604:
			if depth == 0:
				return
			depth -= 1


func _code_at(i: int) -> int:
	var cmd = commands[i]
	if cmd is Array:
		return int(cmd[0])
	elif cmd is Dictionary:
		return int(cmd.get("code", 0))
	return 0


func _eval_condition(params: Array) -> bool:
	if params.is_empty():
		return true
	var kind := int(params[0])
	match kind:
		0:
			# switch
			return State.switch(int(params[1]))
		1:
			# variable compared with value
			var value := State.variable(int(params[1]))
			var target := int(params[2])
			var compare := int(params[3]) if params.size() > 3 else 0
			match compare:
				0: return value == target
				1: return value >= target
				2: return value <= target
				3: return value > target
				4: return value < target
				5: return value != target
			return false
		2:
			# self switch
			if event_node == null:
				return false
			var letter := str(params[1])
			var expected := bool(params[2]) if params.size() > 2 else true
			return State.self_switch(State.map_id, event_node.event_id, letter) == expected
		12:
			return bridge.eval_condition(str(params[1]))
	return true


func _jump_after_else() -> void:
	# false branch: jump to else body (after 411) or after whole branch
	var depth := 1
	while index < commands.size():
		var c := _code_at(index)
		index += 1
		if c == 111:
			depth += 1
		elif c == 411:
			if depth == 1:
				return
		elif c == 412:
			depth -= 1
			if depth == 0:
				return


func _jump_after_else_end() -> void:
	# skip else body after a true branch
	var depth := 0
	while index < commands.size():
		var c := _code_at(index)
		index += 1
		if c == 111:
			depth += 1
		elif c == 412:
			if depth == 0:
				return
			depth -= 1


func _jump_after_loop() -> void:
	var depth := 0
	while index < commands.size():
		var c := _code_at(index)
		index += 1
		if c == 112:
			depth += 1
		elif c == 413:
			if depth == 0:
				_loop_stack.pop_back()
				return
			depth -= 1


func _after_overlay() -> void:
	if Router.has_overlay():
		await Router.overlay_closed
