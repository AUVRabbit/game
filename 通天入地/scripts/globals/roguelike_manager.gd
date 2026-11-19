# ============================================================
# RoguelikeManager — 通天塔试炼（附属 Roguelike 模式）
# 种子化楼层、层间词条、死亡结算与最佳纪录
# ============================================================

extends Node

signal run_state_changed

const MODIFIER_POOL := [
	{ "id": "enemy_power", "text": "敌人攻击 +20%", "enemy_power": 1.2 },
	{ "id": "gold_bonus", "text": "金币掉落 +50%", "gold_bonus": 1.5 },
	{ "id": "low_hp", "text": "最大生命 -15%", "hp_scale": 0.85 },
	{ "id": "extra_elite", "text": "每层多 1 只精英", "extra_elite": 1 }
]

var is_active: bool = false
var run_seed: int = 0
var floor: int = 1
var best_floor: int = 0
var modifiers: Array = []
var rng := RandomNumberGenerator.new()

func start_run(seed_value: int) -> void:
	is_active = true
	run_seed = seed_value
	rng.seed = seed_value
	floor = 1
	modifiers.clear()
	EventBus.roguelite_run_started.emit(run_seed)
	EventBus.notify("通天塔试炼开始 · 种子 %d" % run_seed)
	run_state_changed.emit()

func advance_floor() -> int:
	floor += 1
	if floor % 3 == 0:
		_roll_modifier()
	EventBus.notify("进入通天塔第 %d 层" % floor)
	run_state_changed.emit()
	return floor

func _roll_modifier() -> void:
	var pick: Dictionary = MODIFIER_POOL[rng.randi_range(0, MODIFIER_POOL.size() - 1)]
	modifiers.append(pick)
	EventBus.notify("层间词条：%s" % str(pick.get("text", "")))

func enemy_power() -> float:
	var value := 1.0
	for m in modifiers:
		value *= float(m.get("enemy_power", 1.0))
	return value

func gold_multiplier() -> float:
	var value := 1.0
	for m in modifiers:
		value *= float(m.get("gold_bonus", 1.0))
	return value

func hp_scale() -> float:
	var value := 1.0
	for m in modifiers:
		value *= float(m.get("hp_scale", 1.0))
	return value

func extra_elite() -> int:
	var value := 0
	for m in modifiers:
		value += int(m.get("extra_elite", 0))
	return value

func end_run(success: bool, rewards: Dictionary = {}) -> void:
	if not is_active:
		return
	is_active = false
	best_floor = maxi(best_floor, floor)
	if success:
		var gold_reward := floor * 40
		if GameManager:
			GameManager.add_gold(gold_reward)
		EventBus.notify("试炼完成：抵达第 %d 层，获得 %d 金币" % [floor, gold_reward])
	EventBus.roguelite_run_ended.emit(success, rewards)
	run_state_changed.emit()

func reset() -> void:
	is_active = false
	run_seed = 0
	floor = 1
	modifiers.clear()
	run_state_changed.emit()

func summarize() -> String:
	if not is_active:
		return "试炼未开始"
	return "第 %d 层 · 种子 %d · 词条 %d" % [floor, run_seed, modifiers.size()]

func serialize() -> Dictionary:
	return {
		"is_active": is_active,
		"run_seed": run_seed,
		"floor": floor,
		"best_floor": best_floor,
		"modifiers": modifiers.duplicate(true)
	}

func deserialize(data) -> void:
	if not (data is Dictionary):
		return
	is_active = bool(data.get("is_active", false))
	run_seed = int(data.get("run_seed", 0))
	floor = int(data.get("floor", 1))
	best_floor = int(data.get("best_floor", 0))
	var mods = data.get("modifiers", [])
	modifiers = mods.duplicate(true) if mods is Array else []
	if is_active:
		rng.seed = run_seed
