class_name BattleScene
extends Control
## Simplified but complete turn-based battle using the original enemy/troop data.

signal finished(result)   # 0 = win, 1 = escape, 2 = defeat

const PANEL_PARTY := Rect2(8, 24, 304, 200)
const PANEL_ENEMY := Rect2(328, 24, 304, 200)
const PANEL_LOG := Rect2(8, 232, 624, 168)
const PANEL_CMD := Rect2(8, 406, 624, 66)

var troop_id := 1
var can_escape := true
var troop: Dictionary = {}
var enemies: Array = []      # {name, hp, maxhp, data, alive}
var units: Array = []        # GameActor / GameTank
var actions: Array = []
var action_index := 0
var current: Variant = null
var commands: Array[String] = []
var command_index := 0
var target_index := 0
var phase := "intro"
var log_lines: Array[String] = []
var skin: Texture2D
var round_no := 1
var _finished := false
var defending: Array = []


func _init(p_troop_id: int = 1, p_can_escape: bool = true) -> void:
	troop_id = p_troop_id
	can_escape = p_can_escape


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	skin = DB.windowskin_texture(str(DB.system.get("windowskin_name", "DefultSkin")))
	troop = DB.troop(troop_id)
	for m in troop.get("members", []):
		var e: Dictionary = DB.enemy(int(m.get("enemy_id", 1)))
		if e.is_empty():
			continue
		enemies.append({
			"name": str(e.get("name", "敌人")),
			"hp": int(e.get("maxhp", 1)),
			"maxhp": int(e.get("maxhp", 1)),
			"data": e,
			"alive": true,
		})
	units.clear()
	for m in State.party.members:
		units.append(m)
	_log("敌人出现了！")
	Audio.play_bgm("2、Battle", 100)
	phase = "intro"
	queue_redraw()
	await get_tree().create_timer(0.6).timeout
	_begin_round()


# ------------------------------------------------------------------ turn flow
func _alive_units() -> Array:
	var out: Array = []
	for u in units:
		if _unit_alive(u):
			out.append(u)
	return out


func _unit_alive(u: Variant) -> bool:
	if u is GameActor:
		return u.hp > 0
	if u is GameTank:
		return u.exists() and u.hp > 0
	return false


func _alive_enemies() -> Array:
	var out: Array = []
	for i in range(enemies.size()):
		if enemies[i]["alive"]:
			out.append(i)
	return out


func _begin_round() -> void:
	if _finished:
		return
	actions.clear()
	defending.clear()
	action_index = 0
	_log("—— 第 %d 回合 ——" % round_no)
	_next_command()


func _next_command() -> void:
	var alive := _alive_units()
	if action_index >= alive.size():
		_resolve_round()
		return
	current = alive[action_index]
	command_index = 0
	target_index = 0
	commands = _commands_for(current)
	phase = "command"
	queue_redraw()


func _commands_for(u: Variant) -> Array[String]:
	var out: Array[String] = []
	if u is GameTank:
		if u.main_cannon_usable():
			out.append("主炮")
		if u.sub_cannon_usable():
			out.append("副炮")
		if u.se_usable():
			out.append("SE")
		if not u.special_cannonballs.is_empty():
			out.append("特殊弹")
		out.append("防御")
		out.append("逃跑")
	else:
		out.append("攻击")
		if not u.skills.is_empty():
			out.append("技能")
		out.append("防御")
		out.append("逃跑")
	return out


func _confirm_command() -> void:
	var cmd := commands[command_index]
	if cmd == "逃跑":
		if can_escape and randf() < 0.6:
			_log("成功逃跑了！")
			_finish(1)
		else:
			_log("逃跑失败！")
			action_index += 1
			_next_command()
		return
	if cmd == "防御":
		actions.append({"unit": current, "kind": "防御"})
		action_index += 1
		_next_command()
		return
	phase = "target"
	var alive := _alive_enemies()
	target_index = alive[0] if not alive.is_empty() else 0
	queue_redraw()


func _confirm_target() -> void:
	actions.append({"unit": current, "kind": commands[command_index], "target": target_index})
	action_index += 1
	_next_command()


func _resolve_round() -> void:
	phase = "resolve"
	queue_redraw()
	for action in actions:
		if _finished:
			return
		if not _alive_enemies().is_empty():
			await _do_action(action)
	if _alive_enemies().is_empty():
		_victory()
		return
	await _enemy_phase()
	if _finished:
		return
	if _all_party_dead():
		_defeat()
		return
	round_no += 1
	_begin_round()


func _do_action(action: Dictionary) -> void:
	var u: Variant = action["unit"]
	if not _unit_alive(u):
		return
	var kind: String = str(action.get("kind", "攻击"))
	if kind == "防御":
		action["defending"] = true
		if not defending.has(u):
			defending.append(u)
		_log("%s 进入防御。" % _unit_name(u))
		await get_tree().create_timer(0.2).timeout
		return
	var ti := int(action.get("target", 0))
	if ti >= enemies.size() or not enemies[ti]["alive"]:
		var alive := _alive_enemies()
		if alive.is_empty():
			return
		ti = alive[0]
	if u is GameTank:
		await _tank_attack(u, ti, kind)
	elif kind == "技能" and _actor_skill(u):
		await get_tree().create_timer(0.3).timeout
	else:
		await _actor_attack(u, ti)


func _unit_name(u: Variant) -> String:
	if u is GameTank:
		return u.name
	return u.name


func _actor_skill(a: GameActor) -> bool:
	var chosen: Dictionary = {}
	for sid in a.skills:
		var s: Dictionary = DB.skill(int(sid))
		if s.is_empty():
			continue
		if int(s.get("sp_cost", 0)) <= a.sp:
			chosen = s
			break
	if chosen.is_empty():
		return false
	a.sp -= int(chosen.get("sp_cost", 0))
	var power := int(chosen.get("power", 0))
	if power < 0:
		var heal := -power + int(int(chosen.get("int_f", 0)) * a.mdef() / 100.0)
		var best: GameActor = null
		for m in State.party.member_actors():
			if m.hp > 0 and (best == null or m.hp < best.hp):
				best = m
		if best != null:
			best.hp = mini(best.hp + heal, best.maxhp())
			_log("%s 使用 %s！%s 回复了 %d HP。" % [a.name, chosen.get("name", "技能"), best.name, heal])
		return true
	var alive := _alive_enemies()
	if alive.is_empty():
		return true
	var ti: int = alive[0]
	var dmg := maxi(power + int(int(chosen.get("int_f", 0)) * a.mdef() / 100.0)
		- int(enemies[ti]["data"].get("mdef", 0)), 1)
	_damage_enemy(ti, dmg)
	_log("%s 使用 %s！%s 受到 %d 伤害。" % [a.name, chosen.get("name", "技能"), enemies[ti]["name"], dmg])
	return true


func _actor_attack(a: GameActor, ti: int) -> void:
	var dmg := maxi(a.atk() * 2 - int(enemies[ti]["data"].get("pdef", 0)), 1)
	dmg = int(dmg * randf_range(0.9, 1.1))
	_damage_enemy(ti, dmg)
	_log("%s 攻击！%s 受到 %d 伤害。" % [a.name, enemies[ti]["name"], dmg])
	await get_tree().create_timer(0.35).timeout


func _tank_attack(t: GameTank, ti: int, kind: String) -> void:
	var atk := 0
	var label := kind
	var driver_bonus := 0
	if t.driver != null:
		driver_bonus = t.driver.level
	if kind == "主炮" and t.main_cannon != null:
		atk = t.main_cannon.atk
		t.main_cannon.quantity_use()
	elif kind == "副炮" and t.sub_cannon != null:
		atk = t.sub_cannon.atk
		t.sub_cannon.quantity_use()
	elif kind == "SE" and t.se != null:
		atk = t.se.atk
	elif kind == "特殊弹" and not t.special_cannonballs.is_empty():
		var ball_id: int = int(t.special_cannonballs.keys()[0])
		var ball: Dictionary = DB.mm_get("special_cannonballs", ball_id)
		atk = int(ball.get("atk", 0)) + 40
		label = str(ball.get("name", "特殊弹"))
		t.use_special_ball(ball_id)
	var dmg := maxi(int((atk + driver_bonus * 2) * 2.0 - int(enemies[ti]["data"].get("pdef", 0))), 1)
	dmg = int(dmg * randf_range(0.9, 1.1))
	_damage_enemy(ti, dmg)
	_log("%s 发射%s！%s 受到 %d 伤害。" % [t.name, label, enemies[ti]["name"], dmg])
	await get_tree().create_timer(0.35).timeout


func _damage_enemy(ti: int, dmg: int) -> void:
	enemies[ti]["hp"] = maxi(int(enemies[ti]["hp"]) - dmg, 0)
	if int(enemies[ti]["hp"]) <= 0:
		enemies[ti]["alive"] = false
	queue_redraw()


func _enemy_phase() -> void:
	_log("敌人开始行动……")
	await get_tree().create_timer(0.25).timeout
	for i in range(enemies.size()):
		if _all_party_dead():
			return
		if not enemies[i]["alive"]:
			continue
		var targets := _alive_units()
		if targets.is_empty():
			return
		var target: Variant = targets[randi() % targets.size()]
		var e: Dictionary = enemies[i]["data"]
		var pdef := 0
		if target is GameActor:
			pdef = target.pdef()
		else:
			pdef = target.pdef()
		var dmg := maxi(int(e.get("atk", 1)) * 2 - pdef, 1)
		dmg = int(dmg * randf_range(0.85, 1.1))
		if defending.has(target):
			dmg = maxi(int(dmg / 2.0), 1)
		if target is GameActor:
			target.hp = maxi(target.hp - dmg, 0)
			_log("%s 的攻击！%s 受到 %d 伤害。" % [enemies[i]["name"], target.name, dmg])
			if target.hp <= 0:
				_log("%s 倒下了！" % target.name)
		else:
			target.hp = maxi(target.hp - dmg, 0)
			_log("%s 的攻击！%s 装甲减少 %d。" % [enemies[i]["name"], target.name, dmg])
			if target.hp <= 0:
				_log("%s 大破！" % target.name)
		queue_redraw()
		await get_tree().create_timer(0.4).timeout
	if _all_party_dead():
		return


func _all_party_dead() -> bool:
	for u in units:
		if _unit_alive(u):
			return false
	return true


# ------------------------------------------------------------------ results
func _victory() -> void:
	_log("战斗胜利！")
	var exp_total := 0
	var gold_total := 0
	var boss_ids: Dictionary = DB.mm.get("data_enemy_boss", {})
	var wanted_struck := false
	for e in enemies:
		exp_total += int(e["data"].get("exp", 0))
		gold_total += int(e["data"].get("gold", 0))
		var enemy_id := int(e["data"].get("id", 0))
		if boss_ids is Dictionary and boss_ids.has(str(enemy_id)):
			wanted_struck = true
			if State.current_map != null and State.current_map.has_method("wanted_person_strike"):
				var leader: Array = State.party.member_actors()
				var lv: int = leader[0].level if not leader.is_empty() else 1
				State.current_map.wanted_person_strike(enemy_id, lv)
	Audio.play_me("wanted-brock" if wanted_struck else "battle-finish")
	State.party.gain_gold(gold_total)
	_log("获得 %d 经验和 %d G。" % [exp_total, gold_total])
	for a in State.party.member_actors():
		if a.hp > 0:
			a.gain_exp(exp_total)
	# item drops
	for e in enemies:
		var item_id := int(e["data"].get("item_id", 0))
		var prob := int(e["data"].get("treasure_prob", 0))
		if item_id > 0 and randi() % 100 < prob:
			State.party.gain_item(item_id, 1)
			var item: Dictionary = DB.mm_get("actor_items", item_id)
			if item.is_empty():
				item = DB.item(item_id)
			_log("得到了 %s。" % str(item.get("name", "物品")))
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	_finish(0)


func _defeat() -> void:
	_log("全员无法战斗……")
	queue_redraw()
	await get_tree().create_timer(1.0).timeout
	_finish(2)


func _finish(result: int) -> void:
	if _finished:
		return
	_finished = true
	phase = "result"
	queue_redraw()
	await get_tree().create_timer(0.5).timeout
	finished.emit(result)


# ------------------------------------------------------------------ logging
func _log(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 6:
		log_lines.pop_front()
	queue_redraw()


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.03, 0.04, 0.08))
	draw_rect(Rect2(0, 0, 640, 220), Color(0.08, 0.12, 0.2))
	UISkin.draw_window(self, PANEL_PARTY, skin, 0.85)
	UISkin.draw_window(self, PANEL_ENEMY, skin, 0.85)
	UISkin.draw_window(self, PANEL_LOG, skin, 0.85)
	UISkin.draw_window(self, PANEL_CMD, skin, 0.85)
	_draw_party()
	_draw_enemies()
	_draw_log()
	_draw_commands()
	UISkin.draw_text(self, Vector2(16, 14), "第 %d 回合" % round_no, 16)
	UISkin.draw_text_right(self, Rect2(400, 8, 224, 20), "金钱 %dG" % State.party.gold, 16)


func _draw_party() -> void:
	var y := PANEL_PARTY.position.y + 14
	UISkin.draw_text(self, Vector2(PANEL_PARTY.position.x + 14, y), "我方", 16)
	y += 26
	for u in units:
		if u is GameTank:
			var ratio := 0.0
			if u.maxhp() > 0:
				ratio = float(u.hp) / float(u.maxhp())
			UISkin.draw_text(self, Vector2(PANEL_PARTY.position.x + 16, y), u.name, 15)
			_draw_bar(Rect2(PANEL_PARTY.position.x + 96, y + 4, 120, 12), ratio, Color(0.3, 0.75, 1.0))
			UISkin.draw_text(self, Vector2(PANEL_PARTY.position.x + 224, y), "%d/%d" % [u.hp, u.maxhp()], 13)
		else:
			var ratio2 := 0.0
			if u.maxhp() > 0:
				ratio2 = float(u.hp) / float(u.maxhp())
			UISkin.draw_text(self, Vector2(PANEL_PARTY.position.x + 16, y), u.name, 15)
			_draw_bar(Rect2(PANEL_PARTY.position.x + 96, y + 4, 120, 12), ratio2, Color(0.3, 0.9, 0.4))
			UISkin.draw_text(self, Vector2(PANEL_PARTY.position.x + 224, y), "%d/%d" % [u.hp, u.maxhp()], 13)
		if u == current and (phase == "command" or phase == "target"):
			draw_rect(Rect2(PANEL_PARTY.position.x + 8, y - 2, 288, 24), Color(1, 1, 0.4, 0.18))
		y += 26


func _draw_enemies() -> void:
	var y := PANEL_ENEMY.position.y + 14
	UISkin.draw_text(self, Vector2(PANEL_ENEMY.position.x + 14, y), "敌人", 16)
	y += 26
	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		var ratio := float(e["hp"]) / float(maxi(int(e["maxhp"]), 1))
		UISkin.draw_text(self, Vector2(PANEL_ENEMY.position.x + 16, y), str(e["name"]), 15)
		_draw_bar(Rect2(PANEL_ENEMY.position.x + 96, y + 4, 120, 12), ratio, Color(0.9, 0.35, 0.35))
		UISkin.draw_text(self, Vector2(PANEL_ENEMY.position.x + 224, y), "%d/%d" % [e["hp"], e["maxhp"]], 13)
		if i == target_index and phase == "target":
			draw_rect(Rect2(PANEL_ENEMY.position.x + 8, y - 2, 288, 24), Color(1, 1, 0.4, 0.2))
		y += 26


func _draw_bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect, Color(0, 0, 0, 0.6))
	var r := rect
	r.size.x = rect.size.x * clampf(ratio, 0.0, 1.0)
	draw_rect(r, color)


func _draw_log() -> void:
	var y := PANEL_LOG.position.y + 12
	for line in log_lines:
		UISkin.draw_text(self, Vector2(PANEL_LOG.position.x + 14, y), line, 15)
		y += 24


func _draw_commands() -> void:
	match phase:
		"command":
			var x := PANEL_CMD.position.x + 16
			for i in range(commands.size()):
				UISkin.draw_text(self, Vector2(x, PANEL_CMD.position.y + 24), commands[i], 17)
				if i == command_index:
					UISkin.draw_cursor(self, Rect2(x - 8, PANEL_CMD.position.y + 4, 90, 30), skin)
				x += 100
			UISkin.draw_text(self, Vector2(PANEL_CMD.position.x + 16, PANEL_CMD.position.y + 52),
				"Z 确定   X 返回", 13, Color(0.75, 0.75, 0.75))
		"target":
			UISkin.draw_text(self, Vector2(PANEL_CMD.position.x + 16, PANEL_CMD.position.y + 24),
				"选择目标：← → 切换   Z 确定", 17)
		"resolve":
			UISkin.draw_text(self, Vector2(PANEL_CMD.position.x + 16, PANEL_CMD.position.y + 24), "行动中……", 17)
		"intro", "result":
			UISkin.draw_text(self, Vector2(PANEL_CMD.position.x + 16, PANEL_CMD.position.y + 24), "……", 17)


# ------------------------------------------------------------------ input
func _unhandled_input(event: InputEvent) -> void:
	if phase == "command":
		if event.is_action_pressed("move_left"):
			get_viewport().set_input_as_handled()
			command_index = (command_index - 1 + commands.size()) % commands.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			command_index = (command_index + 1) % commands.size()
			Audio.cursor()
			queue_redraw()
		elif event.is_action_pressed("action"):
			get_viewport().set_input_as_handled()
			Audio.decision()
			_confirm_command()
	elif phase == "target":
		var alive := _alive_enemies()
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			_cycle_target(-1, alive)
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			_cycle_target(1, alive)
		elif event.is_action_pressed("action"):
			get_viewport().set_input_as_handled()
			Audio.decision()
			_confirm_target()
		elif event.is_action_pressed("cancel"):
			get_viewport().set_input_as_handled()
			phase = "command"
			queue_redraw()


func _cycle_target(delta: int, alive: Array) -> void:
	if alive.is_empty():
		return
	var pos := alive.find(target_index)
	if pos < 0:
		pos = 0
	pos = (pos + delta + alive.size()) % alive.size()
	target_index = int(alive[pos])
	Audio.cursor()
	queue_redraw()
