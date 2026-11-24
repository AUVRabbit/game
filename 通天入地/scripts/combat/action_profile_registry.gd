# ============================================================
# ActionProfileRegistry — 每种对象类型的动作能力集注册表
#
# 统一注册表：player_*, enemy_*, minion_*, npc_*
# 灵魂控制时查这个表 → 知道目标形态能做什么。
# ============================================================

extends RefCounted
class_name ActionProfileRegistry

# profile 模板（所有对象共用这个 schema）:
#   {
#     "id": "player_warrior",
#     "kind": "player" | "enemy" | "minion" | "npc",
#     "default_sheet": "player_warrior",
#     "frame_size": Vector2(128, 128),
#     # 动作能力（true=能做, false=不能做/禁用）
#     "can_idle": true, "can_walk": true, "can_run": true,
#     "can_crouch": true, "can_prone": false, "can_lurk": false,
#     "can_attack_melee": true, "can_attack_bow": false,
#     "can_attack_throw": false, "can_attack_spell": false,
#     "can_attack_summon": false, "can_attack_chain": false,
#     "can_dash": true, "can_blink": false,
#     "can_dialog": true, "can_forge": false, "can_search": true,
#     "can_pick_up": true, "can_open_door": true,
#     "can_dead": true,
#     # 姿态特性（影响 SpriteAnim 的物理感）
#     "build_height": 1.0,   # 身体"高度"系数（越大越挺拔）
#     "weight": 1.0,         # 重量系数（影响受击击退距离）
#   }

static var _profiles := {}

# -------------------- 初始化（首次调用时填充）--------------------
static func _ensure() -> void:
	if not _profiles.is_empty():
		return
	# ==== Player 16 职业 ====
	for class_id in ["warrior", "archer", "mage", "bomber", "sniper", "hacker",
		"necromancer", "priest", "engineer", "thief", "qi_adept",
		"runeward", "death_knight", "cyborg", "mech_pilot", "bounty_hunter"]:
		var p := _base_player_profile("player_" + class_id)
		match class_id:
			"warrior", "death_knight":
				p.can_attack_melee = true; p.can_attack_bow = false; p.can_attack_spell = false
				p.can_dash = true; p.build_height = 1.1; p.weight = 1.15
			"archer", "sniper", "bounty_hunter":
				p.can_attack_melee = false; p.can_attack_bow = true; p.can_crouch = true
				p.can_lurk = true; p.build_height = 1.0; p.weight = 0.9
			"mage", "qi_adept":
				p.can_attack_melee = false; p.can_attack_spell = true
				p.build_height = 1.05; p.weight = 0.95
			"bomber", "hacker":
				p.can_attack_melee = false; p.can_attack_throw = true
				p.can_attack_bow = false
			"necromancer":
				p.can_attack_melee = false; p.can_attack_spell = true; p.can_attack_summon = true
				p.build_height = 1.0; p.weight = 0.95
			"priest", "runeward":
				p.can_attack_melee = false; p.can_attack_spell = true
				p.can_forge = true
			"engineer", "mech_pilot":
				p.can_attack_melee = false; p.can_attack_throw = true; p.can_forge = true
				p.build_height = 1.0; p.weight = 1.2
			"thief", "cyborg":
				p.can_attack_melee = true; p.can_crouch = true; p.can_prone = true; p.can_lurk = true
				p.can_blink = true; p.can_dash = true; p.weight = 0.85
		_profiles[p.id] = p
	# ==== Enemy 5 类型 ====
	for etype in ["slime", "mech_spider", "wraith", "skeleton", "lava_giant"]:
		var p := _base_enemy_profile("enemy_" + etype)
		match etype:
			"slime":
				p.can_attack_melee = true; p.can_run = false; p.can_crouch = false
				p.build_height = 0.6; p.weight = 0.7
			"mech_spider":
				p.can_attack_melee = true; p.can_attack_chain = true
				p.can_run = true; p.can_crouch = false; p.build_height = 0.8; p.weight = 1.3
			"wraith":
				p.can_attack_spell = true; p.can_run = true; p.can_lurk = true; p.can_prone = true
				p.can_blink = true; p.build_height = 1.0; p.weight = 0.0
			"skeleton":
				p.can_attack_melee = true; p.can_attack_bow = true
				p.build_height = 1.0; p.weight = 0.9
			"lava_giant":
				p.can_attack_melee = true; p.can_attack_spell = true; p.weight = 1.8
				p.can_run = false; p.build_height = 1.3
		_profiles[p.id] = p
	# ==== Minion 8 种 ====
	for mt in ["archer", "zombie", "fire", "water", "thunder", "mech", "shadow", "giant"]:
		var p := _base_minion_profile("minion_" + mt)
		match mt:
			"archer":   p.can_attack_bow = true; p.can_attack_melee = false
			"zombie":   p.can_attack_melee = true; p.weight = 1.2
			"fire":     p.can_attack_spell = true; p.can_attack_melee = false
			"water":    p.can_attack_spell = true; p.can_attack_melee = false
			"thunder":  p.can_attack_chain = true; p.can_attack_spell = true
			"mech":     p.can_attack_chain = true; p.weight = 1.25
			"shadow":   p.can_attack_melee = true; p.can_blink = true; p.can_lurk = true; p.weight = 0.7
			"giant":    p.can_attack_melee = true; p.weight = 2.0; p.build_height = 1.4
		_profiles[p.id] = p

static func _base_player_profile(id: String) -> Dictionary:
	return {
		# 基础循环
		"can_idle": true, "can_walk": true, "can_run": true,
		# 低姿态
		"can_crouch": false, "can_prone": false, "can_lurk": false,
		# 移动特殊
		"can_jump": true, "can_jump_falling": true, "can_jump_land": true,
		"can_swim": false, "can_climb": false, "can_roll": false,
		"can_mounted": false,
		# 战斗动作
		"can_attack_melee": false, "can_attack_bow": false,
		"can_attack_throw": false, "can_attack_spell": false,
		"can_attack_summon": false, "can_attack_chain": false,
		"can_attack_unarmed": false, "can_attack_rapid": false,
		"can_attack_aoe": false,
		# 蓄力/专注
		"can_charging": false, "can_cast_focus": false,
		# 防御
		"can_block": false, "can_ready": true,
		# 冲刺/闪现
		"can_dash": false, "can_blink": false,
		# 生存
		"can_hurt": true, "can_stagger": true,
		"can_dead": true, "can_resurrecting": false,
		# 交互场景化
		"can_dialog": true, "can_forge": false, "can_search": true,
		"can_pick_up": true, "can_open_door": true,
		"can_drink": true, "can_carry": true, "can_sit": true,
		"can_trap_set": false, "can_portal": false,
		# 胜利
		"can_celebrate": true, "can_fall": true,
		# 元数据
		"id": id, "kind": "player", "default_sheet": id,
		"frame_size": Vector2(128, 128),
		"build_height": 1.0, "weight": 1.0,
	}

static func _base_enemy_profile(id: String) -> Dictionary:
	var d := _base_player_profile(id)
	d.kind = "enemy"
	d.can_dialog = false; d.can_forge = false; d.can_pick_up = false
	d.can_open_door = false; d.can_search = false
	return d

static func _base_minion_profile(id: String) -> Dictionary:
	var d := _base_enemy_profile(id)
	d.kind = "minion"
	d.default_sheet = id
	return d

# -------------------- 公共 API --------------------
static func get(id: String) -> Dictionary:
	_ensure()
	if _profiles.has(id):
		return _profiles[id].duplicate(true)
	push_warning("[ActionProfileRegistry] unknown profile: " + id)
	return _base_player_profile(id)

static func has(id: String) -> bool:
	_ensure()
	return _profiles.has(id)

static func all_ids() -> Array[String]:
	_ensure()
	var out: Array[String] = []
	for k in _profiles.keys():
		out.append(k)
	return out

static func count() -> int:
	_ensure()
	return _profiles.size()
