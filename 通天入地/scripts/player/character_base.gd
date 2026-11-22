# ============================================================
# CharacterBase — 角色职业基类（数据驱动 16 职业）
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
	"skills": [],
	"basic_attack": {"kind": "melee", "radius": 56, "cooldown": 0.42}
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
var basic_attack: Dictionary = {}
var equipment: Dictionary = {}
var buffs: Array = []
var punk_stats: Dictionary = {}
var shield_hp: int = 0
var initialized: bool = false

# ---------- 四阶进阶 ----------
const STYLE_UNLOCK_LEVEL := 10
const FUSION_UNLOCK_LEVEL := 30
const ASCENSION_UNLOCK_LEVEL := 50
const TRANSCEND_UNLOCK_LEVEL := 70
const STYLE_LEARN_COST := 120
const MAX_SKILL_SLOTS := 10
const BASE_SKILL_SLOTS := 6

var style_id: String = ""
var learned_styles: Array = []
var spec_id: String = ""
var apex_id: String = ""
var fusion_id: String = ""
var ascension_id: String = ""
var transcend_id: String = ""
var borrowed_skill: String = ""
var loadout: Array = []
var _loadout_initialized: bool = false
var fusions: Array = []
var _owned_cache: Dictionary = {}
var _owned_dirty: bool = true

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
	var raw_basic = def.get("basic_attack", {})
	basic_attack = raw_basic.duplicate(true) if raw_basic is Dictionary else {}
	if basic_attack.is_empty():
		basic_attack = DEFAULT_CLASS["basic_attack"].duplicate(true)
	if SkillManager:
		SkillManager.ensure_class(class_id)
	_ensure_starting_style()
	_validate_progression()
	sync_loadout()
	refresh_skills()
	if EventBus and not EventBus.skill_node_unlocked.is_connected(_on_tree_changed):
		EventBus.skill_node_unlocked.connect(_on_tree_changed)
	recompute()
	hp = max_hp
	mp = max_mp

func _ensure_starting_style() -> void:
	if DataManager == null:
		return
	var style_ids: Array = DataManager.get_class_style_ids(class_id)
	if style_ids.is_empty():
		return
	if not learned_styles.has(str(style_ids[0])):
		learned_styles.append(str(style_ids[0]))
	if style_id == "" or not learned_styles.has(style_id):
		style_id = str(style_ids[0])
	_sync_style_members()

func _sync_style_members() -> void:
	if DataManager == null or style_id == "":
		return
	var style: Dictionary = DataManager.get_style(style_id)
	if style.is_empty():
		return
	var apex: Dictionary = DataManager.get_style_apex(style_id)
	apex_id = str(apex.get("id", "")) if not apex.is_empty() else ""
	var specs: Array = DataManager.get_style_specs_at(style_id)
	var valid_spec := false
	for spec in specs:
		if str(spec.get("id", "")) == spec_id:
			valid_spec = true
			break
	if not valid_spec and not specs.is_empty():
		spec_id = str(specs[0].get("id", ""))

func _validate_progression() -> void:
	if DataManager == null:
		return
	if style_id != "" and not learned_styles.has(style_id):
		style_id = ""
	if fusion_id != "" and DataManager.get_class_fusion(class_id).is_empty():
		fusion_id = ""
	if ascension_id != "" and DataManager.get_class_ascension(class_id).is_empty():
		ascension_id = ""
	if transcend_id != "" and DataManager.get_class_transcend(class_id).is_empty():
		transcend_id = ""
	if borrowed_skill != "" and DataManager.get_ability(borrowed_skill).is_empty():
		borrowed_skill = ""
	var clean: Array = []
	for sid in learned_styles:
		if not DataManager.get_style(str(sid)).is_empty():
			clean.append(str(sid))
	learned_styles = clean

func setup_class(new_class_id: String) -> void:
	class_id = new_class_id
	style_id = ""
	learned_styles = []
	spec_id = ""
	apex_id = ""
	fusion_id = ""
	ascension_id = ""
	transcend_id = ""
	borrowed_skill = ""
	loadout = []
	_loadout_initialized = false
	fusions = []
	_owned_cache.clear()
	_owned_dirty = true
	initialized = false
	initialize()
	stats_changed.emit()

func recompute() -> void:
	max_hp = int(base_stats.get("max_hp", 100)) + int(growth.get("max_hp", 0)) * (level - 1)
	max_mp = int(base_stats.get("max_mp", 50)) + int(growth.get("max_mp", 0)) * (level - 1)
	var life := _life_bonus()
	max_hp = int(round(float(max_hp) * (1.0 + float(life.get("hp", 0.0)))))
	max_mp = int(round(float(max_mp) * (1.0 + float(life.get("mp", 0.0)))))
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
	var spec: Dictionary = SkillManager.get_spec_stats(class_id)
	return float(spec.get(stat_name, 0.0)) + _progression_bonus(stat_name)

func _progression_bonus(stat_name: String) -> float:
	return get_passive_value(stat_name)

func _life_bonus() -> Dictionary:
	if DataManager == null or ascension_id == "":
		return {"hp": 0.0, "mp": 0.0}
	var asc: Dictionary = DataManager.get_class_ascension(class_id)
	return asc.get("life_bonus", {"hp": 0.0, "mp": 0.0})

func refresh_skill_stats() -> void:
	recompute()
	stats_changed.emit()

# 普攻配置：由流派数据驱动，未选流派时回退职业默认（melee / projectile / beam / lob）
func get_basic_attack() -> Dictionary:
	var result: Dictionary = basic_attack.duplicate(true)
	if DataManager != null and style_id != "":
		var style: Dictionary = DataManager.get_style(style_id)
		var style_basic: Dictionary = style.get("basic_attack", {})
		for key in style_basic.keys():
			result[key] = style_basic[key]
	if result.is_empty():
		result = DEFAULT_CLASS["basic_attack"].duplicate(true)
	if result.has("damage_type"):
		result["magic"] = str(result.get("damage_type", "")) == "magic"
	return result

func get_skill_power_multiplier(skill_id: String) -> float:
	var mult := 1.0
	if SkillManager:
		var tree_bonus: Dictionary = SkillManager.get_skill_bonus(class_id, skill_id)
		mult += float(tree_bonus.get("power", 0.0))
		var spec_bonus: Dictionary = SkillManager.get_spec_skill_bonus(class_id)
		mult += float(spec_bonus.get("power", 0.0))
	mult += get_passive_value("power")
	mult += minf(0.5, get_passive_value("resonance") * 5.0)
	return maxf(0.1, mult)

func get_skill_cooldown_multiplier(skill_id: String) -> float:
	var mult := 1.0
	if SkillManager:
		var tree_bonus: Dictionary = SkillManager.get_skill_bonus(class_id, skill_id)
		mult -= float(tree_bonus.get("cooldown", 0.0))
		var spec_bonus: Dictionary = SkillManager.get_spec_skill_bonus(class_id)
		mult -= float(spec_bonus.get("cooldown", 0.0))
	return clampf(mult, 0.3, 2.0)

# ---------- 四阶进阶：流派 / 专精 / 极致 / 融合 / 变身 / 超脱 ----------
func get_passive_value(key: String) -> float:
	if DataManager == null:
		return 0.0
	var total := 0.0
	var active_styles: Array = learned_styles if get_stage() >= 2 else [style_id]
	for raw_sid in active_styles:
		var sid := str(raw_sid)
		if sid == "":
			continue
		var style: Dictionary = DataManager.get_style(sid)
		total += float(style.get("passive", {}).get(key, 0.0))
		total += float(DataManager.get_style_apex(sid).get("passive", {}).get(key, 0.0))
		if sid != style_id:
			continue
		for spec in DataManager.get_style_specs_at(sid):
			if str(spec.get("id", "")) == spec_id:
				total += float(spec.get("passive", {}).get(key, 0.0))
				break
	if fusion_id != "":
		total += float(DataManager.get_class_fusion(class_id).get("passive", {}).get(key, 0.0))
	if ascension_id != "":
		total += float(DataManager.get_class_ascension(class_id).get("passive", {}).get(key, 0.0))
	if transcend_id != "":
		total += float(DataManager.get_class_transcend(class_id).get("passive", {}).get(key, 0.0))
	if SkillManager != null:
		total += float(SkillManager.get_passive_bonus(class_id).get(key, 0.0))
	var caps := {
		"burn": 0.8, "lifesteal": 1.0, "shield_bonus": 0.8, "heal_bonus": 0.8,
		"fortify": 0.5, "haste": 1.5, "execute": 1.0, "resonance": 0.5,
		"trap_bonus": 0.8, "summon_bonus": 0.8, "damage_reduction": 0.6
	}
	if caps.has(key):
		total = minf(total, float(caps[key]))
	return total

func get_lifesteal() -> float:
	return get_passive_value("lifesteal")

func get_shield_bonus() -> float:
	return get_passive_value("shield_bonus")

func get_heal_bonus() -> float:
	return get_passive_value("heal_bonus")

func get_burn_bonus() -> float:
	return get_passive_value("burn")

func get_execute_bonus() -> float:
	return get_passive_value("execute")

func get_fortify() -> float:
	return get_passive_value("fortify")

func get_haste() -> float:
	return get_passive_value("haste")

func get_trap_bonus() -> float:
	return get_passive_value("trap_bonus")

func get_summon_bonus() -> float:
	return get_passive_value("summon_bonus")

func get_damage_reduction() -> float:
	return get_passive_value("damage_reduction")

func get_completed_tree_layers() -> int:
	if SkillManager == null or DataManager == null:
		return 0
	var nodes: Array = DataManager.get_skill_tree_nodes(class_id)
	var layers := int(DataManager.get_tree_layout().get("layers", 4))
	var completed := 0
	for layer in range(layers):
		var any_node := false
		var all_unlocked := true
		for node in nodes:
			if int(node.get("tier", -1)) != layer:
				continue
			any_node = true
			if not SkillManager.is_unlocked(class_id, str(node.get("id", ""))):
				all_unlocked = false
		if any_node and all_unlocked:
			completed += 1
		else:
			break
	return completed

func get_slot_count() -> int:
	return mini(MAX_SKILL_SLOTS, BASE_SKILL_SLOTS + get_completed_tree_layers())

func get_fusion_slots() -> int:
	var rules: Dictionary = DataManager.get_fusion_slot_rules() if DataManager else {}
	var per := int(rules.get("per_layers", 2))
	var max_slots := int(rules.get("max", 2))
	if per <= 0:
		return 0
	return mini(max_slots, int(get_completed_tree_layers() / per))

func get_stage() -> int:
	if transcend_id != "":
		return 4
	if ascension_id != "":
		return 3
	if fusion_id != "":
		return 2
	return 1

func get_display_stage() -> int:
	var stage := get_stage()
	if stage == 1 and level < STYLE_UNLOCK_LEVEL:
		return 0
	return stage

func get_owned_abilities() -> Dictionary:
	if not _owned_dirty and not _owned_cache.is_empty():
		return _owned_cache
	var result: Dictionary = {}
	if DataManager == null:
		return result
	for sid in learned_styles:
		var style: Dictionary = DataManager.get_style(str(sid))
		for sk in style.get("skills", []):
			result[str(sk.get("id", ""))] = sk
		for spec in DataManager.get_style_specs_at(str(sid)):
			result[str(spec.get("id", ""))] = spec.get("active", {})
		var apex: Dictionary = DataManager.get_style_apex(str(sid))
		if not apex.is_empty():
			result[str(apex.get("id", ""))] = apex.get("active", {})
	if fusion_id != "":
		var cf: Dictionary = DataManager.get_class_fusion(class_id)
		if not cf.is_empty():
			result[fusion_id] = cf.get("active", {})
	if ascension_id != "":
		var asc: Dictionary = DataManager.get_class_ascension(class_id)
		if not asc.is_empty():
			result[ascension_id] = asc.get("active", {})
	if transcend_id != "":
		var tr: Dictionary = DataManager.get_class_transcend(class_id)
		if not tr.is_empty():
			result[transcend_id] = tr.get("active", {})
	if borrowed_skill != "":
		var b: Dictionary = DataManager.get_ability(borrowed_skill)
		if not b.is_empty():
			result[borrowed_skill] = b
	for fid in fusions:
		var fused: Dictionary = FusionService.build_from_id(self, str(fid), result)
		if not fused.is_empty():
			result[str(fid)] = fused
	_owned_cache = result
	_owned_dirty = false
	return result

func _default_ability_order(owned: Dictionary) -> Array:
	var order: Array = []
	if style_id != "":
		var style: Dictionary = DataManager.get_style(style_id)
		for sk in style.get("skills", []):
			order.append(str(sk.get("id", "")))
	for aid in [fusion_id, ascension_id, transcend_id, borrowed_skill, spec_id, apex_id]:
		if str(aid) != "" and owned.has(str(aid)):
			order.append(str(aid))
	for sid in learned_styles:
		for spec in DataManager.get_style_specs_at(str(sid)):
			var spec_skill_id := str(spec.get("id", ""))
			if owned.has(spec_skill_id) and not order.has(spec_skill_id):
				order.append(spec_skill_id)
	return order

func sync_loadout() -> Array:
	var owned: Dictionary = get_owned_abilities()
	var clean: Array = []
	for raw_id in loadout:
		var aid := str(raw_id)
		if owned.has(aid) and not clean.has(aid):
			clean.append(aid)
	var cap := get_slot_count()
	if not _loadout_initialized:
		var order := _default_ability_order(owned)
		for aid in order:
			if clean.size() >= cap:
				break
			if not clean.has(str(aid)):
				clean.append(str(aid))
		for aid in owned.keys():
			if clean.size() >= cap:
				break
			if not clean.has(str(aid)):
				clean.append(str(aid))
		_loadout_initialized = true
	while clean.size() > cap:
		clean.pop_back()
	loadout = clean
	return loadout

func get_loadout_ids() -> Array:
	return sync_loadout()

func get_skill(slot: int) -> Dictionary:
	var ids := get_loadout_ids()
	if slot < 1 or slot > ids.size():
		return {}
	var owned := get_owned_abilities()
	return owned.get(str(ids[slot - 1]), {})

func refresh_skills() -> void:
	_owned_dirty = true
	var arr: Array = []
	for i in MAX_SKILL_SLOTS:
		arr.append({})
	for i in get_slot_count():
		arr[i] = get_skill(i + 1)
	skills = arr
	stats_changed.emit()

func invalidate_abilities() -> void:
	_owned_dirty = true
	sync_loadout()
	refresh_skills()

func is_style_skill(ability_id: String) -> bool:
	var ability: Dictionary = DataManager.get_ability(ability_id) if DataManager else {}
	return str(ability.get("origin", "")) == "style" and not ability_id.contains("__")

func count_style_skills_in(a_ids: Array) -> int:
	var total := 0
	for aid in a_ids:
		if is_style_skill(str(aid)):
			total += 1
	return total

func get_class_style_options() -> Array:
	return DataManager.get_class_style_ids(class_id) if DataManager else []

func is_style_learned(sid: String) -> bool:
	return learned_styles.has(sid)

func can_learn_style(sid: String) -> Dictionary:
	if DataManager == null:
		return {"ok": false, "reason": "数据未就绪"}
	if DataManager.get_style(sid).is_empty():
		return {"ok": false, "reason": "流派不存在"}
	if str(DataManager.get_style(sid).get("class_id", "")) != class_id:
		return {"ok": false, "reason": "并非本职业流派"}
	if learned_styles.has(sid):
		return {"ok": false, "reason": "已掌握该流派"}
	if level < STYLE_UNLOCK_LEVEL:
		return {"ok": false, "reason": "需达到 Lv.%d" % STYLE_UNLOCK_LEVEL}
	return {"ok": true, "reason": ""}

func learn_style(sid: String) -> Dictionary:
	var check := can_learn_style(sid)
	if not bool(check.get("ok", false)):
		return check
	learned_styles.append(sid)
	_owned_dirty = true
	refresh_skills()
	return {"ok": true, "reason": ""}

func select_style(sid: String) -> Dictionary:
	if not learned_styles.has(sid):
		return {"ok": false, "reason": "尚未掌握该流派"}
	style_id = sid
	spec_id = ""
	_sync_style_members()
	loadout = []
	_loadout_initialized = false
	invalidate_abilities()
	recompute()
	return {"ok": true, "reason": ""}

func get_specs() -> Array:
	if DataManager == null or style_id == "":
		return []
	return DataManager.get_style_specs_at(style_id)

func select_spec(new_spec_id: String) -> bool:
	for spec in get_specs():
		if str(spec.get("id", "")) == new_spec_id:
			spec_id = new_spec_id
			invalidate_abilities()
			return true
	return false

func can_transition(stage: int) -> Dictionary:
	var level_need := 0
	match stage:
		2: level_need = FUSION_UNLOCK_LEVEL
		3: level_need = ASCENSION_UNLOCK_LEVEL
		4: level_need = TRANSCEND_UNLOCK_LEVEL
		_: return {"ok": false, "reason": "阶位不存在"}
	if level < level_need:
		return {"ok": false, "reason": "需达到 Lv.%d" % level_need}
	if stage == 2:
		for sid in get_class_style_options():
			if not learned_styles.has(str(sid)):
				return {"ok": false, "reason": "需先掌握全部三条流派"}
	if stage == 3 and fusion_id == "":
		return {"ok": false, "reason": "需先完成二转"}
	if stage == 4 and ascension_id == "":
		return {"ok": false, "reason": "需先完成三转"}
	if get_stage() >= stage:
		return {"ok": false, "reason": "已完成该阶位"}
	return {"ok": true, "reason": ""}

func transition(stage: int) -> Dictionary:
	var check := can_transition(stage)
	if not bool(check.get("ok", false)):
		return check
	match stage:
		2:
			var cf: Dictionary = DataManager.get_class_fusion(class_id)
			fusion_id = str(cf.get("id", ""))
			for sid in get_class_style_options():
				if not learned_styles.has(str(sid)):
					learned_styles.append(str(sid))
			loadout = []
			_loadout_initialized = false
		3:
			var asc: Dictionary = DataManager.get_class_ascension(class_id)
			ascension_id = str(asc.get("id", ""))
		4:
			var tr: Dictionary = DataManager.get_class_transcend(class_id)
			transcend_id = str(tr.get("id", ""))
	invalidate_abilities()
	recompute()
	return {"ok": true, "reason": ""}

func get_borrow_options() -> Array:
	if DataManager == null:
		return []
	var own_source := DataManager.get_class_source(class_id)
	var result: Array = []
	for src in DataManager.get_borrow_pool().keys():
		if str(src) == own_source:
			continue
		result.append(DataManager.get_borrow_pool()[src])
	return result

func apply_borrow(source_id: String) -> Dictionary:
	if get_stage() < 4:
		return {"ok": false, "reason": "需先完成四转"}
	if source_id == str(DataManager.get_class_source(class_id)):
		return {"ok": false, "reason": "不得借用本源流"}
	var b: Dictionary = DataManager.get_borrow(source_id)
	if b.is_empty():
		return {"ok": false, "reason": "借技不存在"}
	borrowed_skill = str(b.get("id", ""))
	invalidate_abilities()
	return {"ok": true, "reason": ""}

func _on_tree_changed(cid: String, _node_id: String) -> void:
	if cid == class_id:
		invalidate_abilities()
		recompute()

func refresh_punk_stats() -> void:
	if PunkManager == null:
		return
	punk_stats = PunkManager._compute_punk_stats(class_id, {})
	stats_changed.emit()

func get_attack() -> int:
	var base: float = attack + _equip_bonus("attack") + _buff_value("attack") + _punk_bonus("attack") + _skill_bonus("attack")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(1, int(round(base * all_mult * (1.0 + _buff_value("attack_pct")))))

func get_defense() -> int:
	var base: float = defense + _equip_bonus("defense") + _buff_value("defense") + _punk_bonus("defense") + _skill_bonus("defense")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(0, int(round(base * all_mult)))

func get_magic_attack() -> int:
	var base: float = magic_attack + _equip_bonus("magic_attack") + _buff_value("magic_attack") + _punk_bonus("magic_attack") + _skill_bonus("magic_attack")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(1, int(round(base * all_mult * (1.0 + _buff_value("magic_attack_pct")))))

func get_magic_defense() -> int:
	var base: float = magic_defense + _equip_bonus("magic_defense") + _buff_value("magic_defense") + _punk_bonus("magic_defense") + _skill_bonus("magic_defense")
	var all_mult: float = 1.0 + _punk_bonus("all_stats_bonus") + _skill_bonus("all_stats_bonus")
	return maxi(0, int(round(base * all_mult)))

func get_move_speed() -> float:
	var flat: float = move_speed + _equip_bonus("move_speed")
	var pct: float = _punk_bonus("move_speed") + _punk_bonus("all_stats_bonus") + _skill_bonus("move_speed") + _buff_value("move_speed")
	return maxf(20.0, flat * (1.0 + pct))

func get_attack_speed() -> float:
	var flat: float = attack_speed + _equip_bonus("attack_speed") + _buff_value("attack_speed")
	var pct: float = _punk_bonus("attack_speed") + _punk_bonus("all_stats_bonus") + _skill_bonus("attack_speed") + get_haste()
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
	var reduction := clampf(get_fortify() + get_damage_reduction(), 0.0, 0.7)
	final_dmg = maxi(1, int(round(float(final_dmg) * (1.0 - reduction))))
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
		"equipment": equipment.duplicate(true),
		"style_id": style_id,
		"learned_styles": learned_styles.duplicate(),
		"spec_id": spec_id,
		"apex_id": apex_id,
		"fusion_id": fusion_id,
		"ascension_id": ascension_id,
		"transcend_id": transcend_id,
		"borrowed_skill": borrowed_skill,
		"loadout": loadout.duplicate(),
		"fusions": fusions.duplicate()
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
	style_id = str(data.get("style_id", ""))
	var ls = data.get("learned_styles", [])
	learned_styles = ls.duplicate() if ls is Array else []
	spec_id = str(data.get("spec_id", ""))
	apex_id = str(data.get("apex_id", ""))
	fusion_id = str(data.get("fusion_id", ""))
	ascension_id = str(data.get("ascension_id", ""))
	transcend_id = str(data.get("transcend_id", ""))
	borrowed_skill = str(data.get("borrowed_skill", ""))
	var lo = data.get("loadout", [])
	loadout = lo.duplicate() if lo is Array else []
	_loadout_initialized = not loadout.is_empty()
	var fu = data.get("fusions", [])
	fusions = fu.duplicate() if fu is Array else []
	_owned_cache.clear()
	_owned_dirty = true
	initialized = false
	initialize()
	level = maxi(1, int(data.get("level", 1)))
	exp = int(data.get("exp", 0))
	exp_to_next = int(data.get("exp_to_next", 100))
	recompute()
	hp = clampi(int(data.get("hp", get_max_hp())), 0, get_max_hp())
	mp = clampi(int(data.get("mp", max_mp)), 0, max_mp)
	stats_changed.emit()
