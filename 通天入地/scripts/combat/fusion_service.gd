class_name FusionService
extends RefCounted
# 技能融合：两个技能合成一个「全新技能」——
# 不是把副技能动画叠在主技能上，而是以副技能提炼出的元素，
# 重新染色、重新命名、并在命中瞬间与主技能融合成一次完整表现。
#
# 规则（见 docs/STYLE_BRANCHES.md 8.4）：
# - 威力 = 主 × 1.15，冷却 = 主 × 1.25，法力 = 主 + 副 × 0.5
# - 终极 / 变身 / 超脱 / 借技不可作为副技能
# - 同一技能只能参与一次融合
# - id 形如 {主id}__{副id}，与 2 转的 fusion_id 区分

const POWER_MULT := 1.15
const CD_MULT := 1.25

# 融合元素：由副技能提炼，决定新技能的名称前缀、染色与命中爆发形态
const ELEMENTS := {
	"burn": {"cn": "炎", "color": "#ff6a2a", "verb": "灼烧爆裂"},
	"corrosion": {"cn": "蚀", "color": "#8bd450", "verb": "腐蚀扩散"},
	"freeze": {"cn": "霜", "color": "#7ec8ff", "verb": "霜爆新星"},
	"stun": {"cn": "雷", "color": "#ffe066", "verb": "雷震迸发"},
	"root": {"cn": "棘", "color": "#5fd18a", "verb": "荆棘丛生"},
	"knockback": {"cn": "斥", "color": "#ff9a5a", "verb": "冲击震荡"},
	"holy": {"cn": "圣", "color": "#ffe9a8", "verb": "圣光回响"},
	"summon": {"cn": "魂", "color": "#b58cff", "verb": "亡魂共鸣"},
	"mark": {"cn": "印", "color": "#ff7ab6", "verb": "印记烙刻"},
	"blink": {"cn": "影", "color": "#9aa7ff", "verb": "残影突袭"},
	"none": {"cn": "融", "color": "#ffffff", "verb": "融合爆发"},
}


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
	var kw: Dictionary = keyword_of(sub)
	var elem: Dictionary = ELEMENTS.get(str(kw.get("kind", "")), ELEMENTS["none"])
	var main_color := Color.from_string(str(main.get("color", "#ffffff")), Color.WHITE)
	var elem_color := Color.from_string(str(elem.get("color", "#ffffff")), Color.WHITE)
	# 新技能使用两色混合后的独有色，而不是沿用主技能配色
	var fuse_color := main_color.lerp(elem_color, 0.45)
	var result: Dictionary = main.duplicate(true)
	result["id"] = "%s__%s" % [main_id, sub_id]
	result["name"] = "融·%s%s" % [str(elem.get("cn", "")), str(main.get("name", ""))]
	result["color"] = "#" + fuse_color.to_html(false)
	result["cd"] = snappedf(float(main.get("cd", 8.0)) * CD_MULT, 0.01)
	result["mp"] = int(main.get("mp", 10)) + int(round(float(sub.get("mp", 10)) * 0.5))
	if main.has("power"):
		result["power"] = snappedf(float(main["power"]) * POWER_MULT, 0.001)
	result["fusion_keyword"] = kw
	result["fuse_main_id"] = main_id
	result["fuse_sub_id"] = sub_id
	result["fuse_element"] = str(kw.get("kind", ""))
	result["fuse_element_cn"] = str(elem.get("cn", ""))
	result["fuse_element_color"] = str(elem.get("color", "#ffffff"))
	result["fuse_verb"] = str(elem.get("verb", ""))
	result["fuse_main_color"] = str(main.get("color", "#ffffff"))
	result["origin"] = "fusion"
	result["desc"] = "融合技：%s × %s → %s属性「%s」。命中时引发%s，独立于原技能的完整表现。" % [
		str(main.get("name", "")), str(sub.get("name", "")),
		str(elem.get("cn", "")), str(elem.get("verb", "")), str(elem.get("verb", ""))]
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
