# ============================================================
# ElementKeeper — 元素克制表
# 伤害结算时根据敌人 primary_element 和伤害 damage_element 查倍率
# 倍率 0.0 = 完全免疫（显示"免疫!"）
# 倍率 0.5 = 抵抗
# 倍率 1.0 = 普通
# 倍率 1.5 = 克制（显示"克制!"特效）
# 倍率 2.0 = 强克制
# ============================================================

extends RefCounted
class_name ElementKeeper

# 10 种元素
# physical（物理）- 所有常规 melee/弹道
# fire（火）- burn, 火焰吐息, 熔核
# water（水）- 史莱姆, 水弹
# thunder（雷）- chain, stun_wave, 电磁
# ice（冰）- freeze, 霜爆
# nature（木/自然）- root, 荆棘, 植物
# shadow（幽）- 幽魂, 灵魂, 诅咒
# holy（圣）- 圣光, 神圣
# mech（机）- 机械, 金属
# earth（地）- 岩浆/岩石/物理元素生物

# 克制表：key = 敌人 primary_element，value = {伤害元素: 倍率}
# 省略的条目默认 1.0
const TABLE: Dictionary = {
	"water": {
		"thunder": 1.5,   # 水导电 → 雷 +50%
		"fire": 0.3,      # 水克火 → 火对水伤害 -70%
		"ice": 0.5,       # 水抗冰
		"physical": 1.0,
	},
	"fire": {
		"fire": 0.0,      # 火免疫火（岩浆怪不会被火焰吐息烧伤）
		"ice": 1.5,       # 冰克火
		"water": 1.3,     # 水克火（水灭火）
		"thunder": 1.0,
		"physical": 0.8,  # 高温金属/岩石抗物理
		"holy": 0.8,
	},
	"ice": {
		"fire": 1.5,      # 火融冰
		"thunder": 1.3,   # 雷破冰（冰导电）
		"water": 0.5,     # 冰抗水
		"ice": 0.0,       # 冰免疫冰
	},
	"thunder": {
		"thunder": 0.0,   # 雷免疫雷（雷元素生物导电无害）
		"earth": 1.5,     # 雷克地（电不导电体）
		"water": 0.7,     # 水电阻雷（水导电但雷生物本身也导电）
	},
	"nature": {
		"fire": 1.5,      # 火克木
		"ice": 0.7,       # 木抗冰
		"earth": 1.3,     # 根能扎进土里
		"thunder": 0.8,
	},
	"shadow": {
		"holy": 2.0,      # 圣克幽（克制！）
		"physical": 0.5,   # 幽魂 50% 物理减伤
		"fire": 1.3,
		"shadow": 0.0,
	},
	"holy": {
		"shadow": 0.0,    # 圣免疫幽（圣体不被诅咒）
		"fire": 0.7,
	},
	"mech": {
		"thunder": 1.8,   # 电磁干扰机械（克制！短路电路）
		"fire": 1.2,      # 火烤金属
		"physical": 0.8,  # 金属抗物理
		"holy": 0.6,      # 机械对神圣伤害有抗性
		"nature": 0.5,    # 植物对机械伤害低
	},
	"earth": {
		"fire": 0.5,      # 岩石/岩浆抗火
		"physical": 0.6,  # 硬岩石抗物理
		"water": 1.3,     # 水冲土
		"ice": 0.7,
	},
	"physical": {
		# 纯物理元素：无特殊克制（中性）
	},
	"none": {
		# 无元素：全部默认 1.0
	},
}

static func multiplier(enemy_element: String, damage_element: String) -> float:
	enemy_element = enemy_element if enemy_element != "" else "physical"
	damage_element = damage_element if damage_element != "" else "physical"
	if enemy_element == damage_element:
		# 同元素通常免疫（除了 physical vs physical）
		if enemy_element == "physical":
			return 1.0
		if TABLE.has(enemy_element) and TABLE[enemy_element].has(damage_element):
			return float(TABLE[enemy_element][damage_element])
		# 默认同元素免疫
		return 0.2
	if TABLE.has(enemy_element):
		var row: Dictionary = TABLE[enemy_element]
		if row.has(damage_element):
			return float(row[damage_element])
	return 1.0

static func element_name(element_key: String) -> String:
	var names := {
		"physical": "物理",
		"fire": "火",
		"water": "水",
		"thunder": "雷",
		"ice": "冰",
		"nature": "木",
		"shadow": "幽",
		"holy": "圣",
		"mech": "机",
		"earth": "地",
		"none": "无",
	}
	return names.get(str(element_key), str(element_key))

# 把融合服务里的元素 kind 映射到本系统的伤害元素
static func from_fusion_kind(fusion_kind: String) -> String:
	var m := {
		"burn": "fire",
		"freeze": "ice",
		"stun": "thunder",
		"corrosion": "nature",
		"root": "nature",
		"holy": "holy",
		"summon": "shadow",
		"knockback": "physical",
		"mark": "shadow",
	}
	return m.get(str(fusion_kind), "physical")
