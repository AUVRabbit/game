# ============================================================
# CharacterBase — 角色职业基类（数据驱动 12 职业）
# 挂载在 Player 的 CharacterData 节点上
# ============================================================

extends Node
class_name CharacterBase

signal stats_changed
signal leveled_up(new_level: int)
signal died

const DEFAULT_CLASS := {
	"id": "warrior", "name": "战士", "color": "#e0533d",
	"max_hp": 150, "max_mp": 50, "attack": 15, "defense": 12,
	"magic_attack": 4, "magic_defense": 6, "move_speed": 180,
	"attack_speed": 1.0, "crit_rate": 0.05, "crit_damage": 1.5, "dodge_rate": 0.02,
	"skills": []
}

var class_id: String = "warrior"
var class_display_name: String = "战士"
var class_color: Color = Color(0.88, 0.33, 0.24)

var level: int = 1
var exp: int = 0
var exp_to_next: int = 100

var max_hp: int = 100
var hp: int = 100
var max_mp: int = 50
var mp: int = 50
var attack: int = 10
var defense: int = 5
var magic_attack: int = 5
var magic_defense: int = 3
var move_speed: float = 200.0
var attack_speed: float = 1.0
var crit_rate: float = 0.05
var crit_damage: float = 1.5
var dodge_rate: float = 0.02

var base_stats: Dictionary = {}
var growth: Dictionary = {}
var skills: Array = []
var equipment: Dictionary = {}
var buffs: Array = []
var punk_stats: Dictionary = {}
var shield_hp: int = 0
var initialized: bool = false

func _ready() -> void:
	if not initialized:
		initialize()

func initialize() -> void:
	if initialized:
		return
	initialized = true
	var def: Dictionary = {}
	if DataManager:
		def = DataManager.get_class_data(class_id)
	if def.is_empty():
		def = DEFAULT_CLASS.duplicate(true)
	class_display_name = str(def.get("name", class_id))
	class_color = Color.from_string(str(def.get("color", "#cccccc")), Color.WHITE)
	base_stats = def.duplicate(true)
	growth = def.get("growth", {})
	if growth.is_empty() and DataManager:
		growth = DataManager.get_class_growth()
	var raw_skills = def.get("skills", [])
	skills = raw_skills.duplicate(true) if raw_skills is Array else []
	if SkillManager:
		SkillManager.ensure_class(class_id)
	_apply_specialization_name()
	recompute()
	hp = max_hp
	mp = max_mp

func _apply_specialization_name() -> void:
	if SkillManager == null:
		return
	var spec: Dictionary = SkillManager.get_specialization(class_id)
	if spec.is_empty():
		return
	var spec_name := str(spec.get("name", ""))
	if spec_name != "":
		class_display_name = spec_name

func setup_class(new_class_id: String) -> void:
	class_id = new_class_id
	initialized = false
	initialize()

func recompute() -> void:
	max_hp = int(base_stats.get("max_hp", 100)) + int(growth.get("max_hp", 0)) * (level - 1)
	max_mp = int(base_stats.get("max_mp", 50)) + int(growth.get("max_mp", 0)) * (level - 1)
	attack = int(base_stats.get("attack", 10)) + int(growth.get("attack", 0)) * (level - 1)
	defense = int(base_stats.get("defense", 5)) + int(growth.get("defense", 0)) * (level - 1)
	magic_attack = int(base_stats.get("magic_attack", 5)) + int(growth.get("magic_attack", 0)) * (level - 1)
	magic_defense = int(base_stats.get("magic_defense", 3)) + int(growth.get("magic_defense", 0)) * (level - 1)
	move_speed = float(base_stats.get("move_speed", 200))
	attack_speed = float(base_stats.get("attack_speed", 1.0))
	crit_rate = float(base_stats.get("crit_rate", 0.05))
	crit_damage = float(base_stats.get("crit_damage", 1.5))
	dodge_rate = float(base_stats.get("dodge_rate", 0.02))
	hp = mini(hp, max_hp)
	mp = mini(mp, max_mp)

# ---------- 装备 / Buff / 朋克加成 ----------
func _equip_bonus(stat_name: String) -> float:
	var total := 0.0
	for slot in equipment.keys():
		var item: Dictionary = equipment[slot]
		var stats: Dictionary = item.get("stats", {})
		total += float(stats.get(stat_name, 0.0))
	return total

func _buff_value(stat_name: String) -> float:
	var total := 0.0
	for b in buffs:
		if str(b.get("stat", "")) == stat_name:
			total += float(b.get("value", 0.0))
	return total

func _punk_bonus(stat_name: String) -> float:
	if PunkManager == null or punk_stats.is_empty():
		punk_stats = PunkManager._compute_punk_stats(class_id, {}) if PunkManager else {}
	return float(punk_stats.get(stat_name, 0.0))

# ---------- 技能树 / 职业专职加成 ----------
func _skill_bonus(stat_name: String) -> float:
	if SkillManager == null:
		return 0.0
	var passive: Dictionary = SkillManager.get_passive_bonus(class_id)
	var spec: Dictionary = SkillManager.get_spec_stats(class_id)
	return float(passive.get(stat_name, 0.0)) + float(spec.get(stat_name, 0.0))

func refresh_skill_stats() -> void:
	recompute()
	stats_changed.emit()

func get_skill_power_multiplier(skill_id: String) -> float:
	var mult := 1.0
	if SkillManager:
		var tree_bonus: Dictionary = SkillManager.get_skill_bonus(class_id, skill_id)
		mult += float(tree_bonus.get("power", 0.0))
		var spec_bonus: Dictionary = SkillManager.get_spec_skill_bonus(class_id)
		mult += float(spec_bonus.get("power", 0.0))
	return maxf(0.1, mult)

func get_skill_cooldown_multiplier(skill_id: String) -> float:
	var mult := 1.0
	if SkillManager:
		var tree_bonus: Dictionary = SkillManager.get_skill_bonus(class_id, skill_id)
		mult -= float(tree_bonus.get("cooldown", 0.0))
		var spec_bonus: Dictionary = SkillManager.get_spec_skill_bonus(class_id)
		mult -= float(spec_bonus.get("cooldown", 0.0))
	return clampf(mult, 0.3, 2.0)

func _spec_passive(key: String) -> float:
	if SkillManager == null:
		return 0.0
	var passives: Dictionary = SkillManager.get_spec_passives(class_id)
	return float(passives.get(key, 0.0))

func get_lifesteal() -> float:
	return _spec_passive("lifesteal")

func get_shield_bonus() -> float:
	return _spec_passive("shield_bonus")

func get_heal_bonus() -> float:
	return _spec_passive("heal_bonus")

func get_burn_bonus() -> float:
	return _spec_passive("burn")

func refresh_punk_stats() -> void:
	if PunkManager == null:
		return
	punk_stats = PunkManager._compute_punk_stats(class_id, {})
	stats_changed.emit()

func get_attack() -> int:
	var base: float = attack + _equip_bonus("attack") + _buff_value("attack") + _punk_bonus("attack") + _skill_bonus("attack")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(1, int(round(base * all_mult)))

func get_defense() -> int:
	var base: float = defense + _equip_bonus("defense") + _buff_value("defense") + _punk_bonus("defense") + _skill_bonus("defense")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(0, int(round(base * all_mult)))

func get_magic_attack() -> int:
	var base: float = magic_attack + _equip_bonus("magic_attack") + _buff_value("magic_attack") + _punk_bonus("magic_attack") + _skill_bonus("magic_attack")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(1, int(round(base * all_mult)))

func get_magic_defense() -> int:
	var base: float = magic_defense + _equip_bonus("magic_defense") + _buff_value("magic_defense") + _punk_bonus("magic_defense") + _skill_bonus("magic_defense")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(0, int(round(base * all_mult)))

func get_move_speed() -> float:
	var flat: float = move_speed + _equip_bonus("move_speed") + _buff_value("move_speed")
	var pct: float = _punk_bonus("move_speed") + _punk_bonus("all_stats_bonus") + _skill_bonus("move_speed")
	return maxf(20.0, flat * (1.0 + pct))

func get_attack_speed() -> float:
	var flat: float = attack_speed + _equip_bonus("attack_speed") + _buff_value("attack_speed")
	var pct: float = _punk_bonus("attack_speed") + _punk_bonus("all_stats_bonus") + _skill_bonus("attack_speed")
	return maxf(0.2, flat * (1.0 + pct))

func get_crit_rate() -> float:
	return clampf(crit_rate + _equip_bonus("crit_rate") + _buff_value("crit_rate") + _punk_bonus("crit_rate") + _skill_bonus("crit_rate"), 0.0, 0.95)

func get_crit_damage() -> float:
	return clampf(crit_damage + _equip_bonus("crit_damage") + _buff_value("crit_damage") + _punk_bonus("crit_damage") + _skill_bonus("crit_damage"), 1.0, 3.0)

func get_dodge_rate() -> float:
	return clampf(dodge_rate + _equip_bonus("dodge_rate") + _buff_value("dodge_rate") + _punk_bonus("dodge_rate") + _skill_bonus("dodge_rate"), 0.0, 0.9)

func get_max_hp() -> int:
	var flat: float = max_hp + _equip_bonus("max_hp") + _punk_bonus("max_hp") + _skill_bonus("max_hp")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(1, int(round(flat * all_mult)))

func get_max_mp() -> int:
	var flat: float = max_mp + _equip_bonus("max_mp") + _punk_bonus("max_mp") + _skill_bonus("max_mp")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(1, int(round(flat * all_mult)))

# ---------- Buff ----------
func add_buff(stat_name: String, value: float, duration: float) -> void:
	for b in buffs:
		if str(b.get("stat", "")) == stat_name:
			b["value"] = value
			b["remaining"] = duration
			stats_changed.emit()
			return
	buffs.append({ "stat": stat_name, "value": value, "remaining": duration })
	stats_changed.emit()

func add_shield(amount: int) -> void:
	shield_hp = maxi(shield_hp, amount)
	stats_changed.emit()

func _process(delta: float) -> void:
	if buffs.is_empty():
		return
	var changed := false
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i]["remaining"] = float(buffs[i]["remaining"]) - delta
		if float(buffs[i]["remaining"]) <= 0.0:
			buffs.remove_at(i)
			changed = true
	if changed:
		stats_changed.emit()

# ---------- 战斗 ----------
func take_damage(amount: int, is_magic: bool = false, _source: Node = null) -> int:
	if hp <= 0:
		return 0
	if randf() < get_dodge_rate():
		return 0
	var def := get_magic_defense() if is_magic else get_defense()
	var final_dmg := maxi(1, amount - def)
	if shield_hp > 0:
		var absorbed := mini(shield_hp, final_dmg)
		shield_hp -= absorbed
		final_dmg -= absorbed
	hp = maxi(0, hp - final_dmg)
	stats_changed.emit()
	if hp <= 0:
		died.emit()
	return final_dmg

func heal(amount: int) -> int:
	var actual := mini(amount, get_max_hp() - hp)
	hp += actual
	stats_changed.emit()
	return actual

func restore_mp(amount: int) -> int:
	var actual := mini(amount, max_mp - mp)
	mp += actual
	stats_changed.emit()
	return actual

func use_mp(cost: int) -> bool:
	if mp < cost:
		return false
	mp -= cost
	stats_changed.emit()
	return true

func add_exp(amount: int) -> void:
	exp += amount
	while exp >= exp_to_next:
		exp -= exp_to_next
		level += 1
		exp_to_next = int(exp_to_next * 1.25)
		recompute()
		hp = get_max_hp()
		mp = max_mp
		shield_hp = 0
		leveled_up.emit(level)
		if SkillManager:
			SkillManager.grant_level_points(class_id, level)
			refresh_skill_stats()
		if EventBus:
			EventBus.player_leveled_up.emit(get_parent(), level)
		EventBus.notify("升级！%s Lv.%d" % [class_display_name, level])
	stats_changed.emit()

# ---------- 装备 ----------
func equip_item(item: Dictionary) -> void:
	var slot := str(item.get("slot", ""))
	if slot == "":
		return
	equipment[slot] = item.duplicate(true)
	recompute()
	stats_changed.emit()

func unequip_item(slot: String) -> Dictionary:
	if not equipment.has(slot):
		return {}
	var item: Dictionary = equipment[slot]
	equipment.erase(slot)
	recompute()
	stats_changed.emit()
	return item

func get_equipped(slot: String) -> Dictionary:
	return equipment.get(slot, {})

# ---------- 存档 ----------
func serialize() -> Dictionary:
	return {
		"class_id": class_id,
		"level": level,
		"exp": exp,
		"exp_to_next": exp_to_next,
		"hp": hp,
		"mp": mp,
		"equipment": equipment.duplicate(true)
	}

func apply_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	if data.has("class_id"):
		class_id = str(data["class_id"])
	level = maxi(1, int(data.get("level", level)))
	exp = int(data.get("exp", 0))
	exp_to_next = int(data.get("exp_to_next", 100))
	var eq = data.get("equipment", {})
	equipment = eq.duplicate(true) if eq is Dictionary else {}
	initialized = false
	initialize()
	level = maxi(1, int(data.get("level", 1)))
	exp = int(data.get("exp", 0))
	exp_to_next = int(data.get("exp_to_next", 100))
	recompute()
	hp = clampi(int(data.get("hp", get_max_hp())), 0, get_max_hp())
	mp = clampi(int(data.get("mp", max_mp)), 0, max_mp)
	stats_changed.emit()
