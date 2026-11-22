class_name FusionService
extends RefCounted
# 技能融合：主技能保留原形态，副技能只贡献 1 个词条。
#
# 规则（见 docs/STYLE_BRANCHES.md 8.4）：
# - 威力 = 主 × 1.15，冷却 = 主 × 1.25，法力 = 主 + 副 × 0.5
# - 终极 / 变身 / 超脱 / 借技不可作为副技能
# - 同一技能只能参与一次融合
# - id 形如 {主id}__{副id}，与 2 转的 fusion_id 区分

const POWER_MULT := 1.15
const CD_MULT := 1.25


static func split_id(fusion_id: String) -> Array:
	var parts := fusion_id.split("__")
	if parts.size() != 2:
		return []
	return [str(parts[0]), str(parts[1])]


static func keyword_of(sub: Dictionary) -> Dictionary:
	var stype := str(sub.get("type", ""))
	match stype:
		"summon":
			return {"kind": "summon", "value": 1}
		"root_zone":
			return {"kind": "root", "value": 0.5}
		"stun_wave":
			return {"kind": "stun", "value": 0.3}
		"dash_strike", "blink_strike":
			return {"kind": "blink", "value": 40.0}
		"heal", "heal_zone", "buff", "shield":
			return {"kind": "holy", "value": 0.08}
		"mark":
			return {"kind": "mark", "value": 0.1}
		"pull_zone":
			return {"kind": "knockback", "value": 45.0}
	var text := str(sub.get("name", "")) + str(sub.get("desc", ""))
	if text.contains("毒") or text.contains("腐") or text.contains("疫"):
		return {"kind": "corrosion", "value": 0.15}
	if text.contains("冰") or text.contains("霜") or text.contains("冻"):
		return {"kind": "freeze", "value": 0.35}
	if text.contains("圣") or text.contains("光") or text.contains("愈"):
		return {"kind": "holy", "value": 0.08}
	if text.contains("雷") or text.contains("电") or text.contains("震"):
		return {"kind": "stun", "value": 0.3}
	if stype == "melee_aoe" or stype == "aoe_zone" or stype == "deployable":
		return {"kind": "burn", "value": 0.15}
	return {"kind": "burn", "value": 0.15}


static func build(data, main_id: String, sub_id: String, owned: Dictionary = {}) -> Dictionary:
	if data == null:
		return {}
	var pool: Dictionary = owned
	if pool.is_empty():
		pool = data.get_owned_abilities()
	if not pool.has(main_id) or not pool.has(sub_id):
		return {}
	var main: Dictionary = pool[main_id]
	var sub: Dictionary = pool[sub_id]
	var result: Dictionary = main.duplicate(true)
	result["id"] = "%s__%s" % [main_id, sub_id]
	result["name"] = "%s·%s" % [str(main.get("name", "")), str(sub.get("name", ""))]
	result["cd"] = snappedf(float(main.get("cd", 8.0)) * CD_MULT, 0.01)
	result["mp"] = int(main.get("mp", 10)) + int(round(float(sub.get("mp", 10)) * 0.5))
	if main.has("power"):
		result["power"] = snappedf(float(main["power"]) * POWER_MULT, 0.001)
	result["fusion_keyword"] = keyword_of(sub)
	result["fuse_main_id"] = main_id
	result["fuse_sub_id"] = sub_id
	result["origin"] = "fusion"
	result["desc"] = "%s｜融合词条：%s" % [str(main.get("desc", "")), str(result["fusion_keyword"].get("kind", ""))]
	return result


static func build_from_id(data, fusion_id: String, owned: Dictionary = {}) -> Dictionary:
	var parts := split_id(fusion_id)
	if parts.is_empty():
		return {}
	return build(data, str(parts[0]), str(parts[1]), owned)


static func can_fuse(data, main_id: String, sub_id: String) -> Dictionary:
	if data == null:
		return {"ok": false, "reason": "数据未就绪"}
	if main_id == "" or sub_id == "":
		return {"ok": false, "reason": "请选择主技能与副技能"}
	if main_id == sub_id:
		return {"ok": false, "reason": "主副技能不能相同"}
	if main_id.contains("__") or sub_id.contains("__"):
		return {"ok": false, "reason": "融合技能不可再次参与"}
	if data.fusions.size() >= data.get_fusion_slots():
		return {"ok": false, "reason": "融合槽不足（%d/%d）" % [data.fusions.size(), data.get_fusion_slots()]}
	var owned: Dictionary = data.get_owned_abilities()
	if not owned.has(main_id):
		return {"ok": false, "reason": "未掌握主技能"}
	if not owned.has(sub_id):
		return {"ok": false, "reason": "未掌握副技能"}
	var sub: Dictionary = owned[sub_id]
	if bool(sub.get("fuse_no_sub", false)):
		return {"ok": false, "reason": "终极 / 变身 / 超脱 / 借技不可作副技能"}
	for fid in data.fusions:
		var parts := split_id(str(fid))
		if parts.is_empty():
			continue
		if parts[0] == main_id or parts[1] == main_id or parts[0] == sub_id or parts[1] == sub_id:
			return {"ok": false, "reason": "同一技能只能参与一次融合"}
	return {"ok": true, "reason": ""}


static func add_fusion(data, main_id: String, sub_id: String) -> Dictionary:
	var check := can_fuse(data, main_id, sub_id)
	if not bool(check.get("ok", false)):
		return check
	data.fusions.append("%s__%s" % [main_id, sub_id])
	data.invalidate_abilities()
	return {"ok": true, "reason": ""}


static func remove_fusion(data, fusion_id: String) -> bool:
	if not data.fusions.has(fusion_id):
		return false
	data.fusions.erase(fusion_id)
	data.invalidate_abilities()
	return true
