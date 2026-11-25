# ============================================================
# RigBuilders — 为每种职业/敌人类型生成程序化皮肤 mesh
#
# 返回结构:
#   build(type, element, base_color, is_boss) -> {
#     "torso": PackedVector2Array,
#     "head":  PackedVector2Array,
#     "arm_l":  PackedVector2Array,
#     "arm_r":  PackedVector2Array,
#     "leg_l":  PackedVector2Array,
#     "leg_r":  PackedVector2Array,
#     "colors": { "torso": Color, "head": Color, ... }
#   }
# ============================================================

class_name RigBuilders

# ====== 玩家职业类型 -> 主色 ======
const CLASS_COLORS := {
	"warrior":      Color(0.88, 0.42, 0.32),   # 战士 赤红
	"mage":         Color(0.40, 0.52, 0.92),   # 法师 蓝
	"runeward":     Color(0.60, 0.70, 0.95),   # 咒铠师 淡蓝
	"priest":       Color(0.96, 0.92, 0.82),   # 牧师 米白
	"necromancer":  Color(0.48, 0.30, 0.42),   # 亡灵法师 紫褐
	"bomber":       Color(0.86, 0.62, 0.32),   # 炸弹专家 橙黄
	"mech_pilot":   Color(0.55, 0.55, 0.60),   # 机甲师 银灰
	"engineer":     Color(0.72, 0.58, 0.38),   # 工程师 铜棕
	"bounty_hunter":Color(0.70, 0.36, 0.25),   # 赏金猎人 铁红
	"death_knight": Color(0.30, 0.28, 0.35),   # 死亡骑士 暗紫
	"archer":       Color(0.45, 0.62, 0.42),   # 弓箭手 绿
	"thief":        Color(0.22, 0.22, 0.28),   # 小偷 深灰
	"qi_adept":     Color(0.82, 0.75, 0.52),   # 气宗 金
	"sniper":       Color(0.35, 0.38, 0.30),   # 狙击手 橄榄
	"cyborg":       Color(0.38, 0.55, 0.58),   # 义体卫士 青
	"hacker":       Color(0.25, 0.82, 0.72),   # 黑客 青绿
}

const ENEMY_COLORS := {
	"slime":          Color(0.42, 0.82, 0.55),
	"mech_spider":    Color(0.55, 0.52, 0.55),
	"mech":           Color(0.55, 0.52, 0.55),
	"wraith":         Color(0.58, 0.55, 0.80),
	"skeleton":       Color(0.85, 0.82, 0.75),
	"lava_giant":     Color(0.95, 0.45, 0.12),
	"fire_elemental": Color(0.98, 0.55, 0.15),
	# Minions
	"minion_fire":    Color(0.95, 0.55, 0.25),
	"minion_water":   Color(0.35, 0.65, 0.92),
	"minion_zombie":  Color(0.55, 0.65, 0.42),
	"minion_archer":  Color(0.72, 0.48, 0.30),
	"minion_giant":   Color(0.68, 0.55, 0.42),
	"minion_shadow":  Color(0.32, 0.28, 0.42),
	"minion_thunder": Color(0.90, 0.85, 0.38),
	"minion_mech":    Color(0.58, 0.58, 0.62),
}

# ==================== 公共 mesh 工厂 ====================

# 胶囊（身体躯干）— 长轴水平
static func capsule_v(w: float, h: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var segs: int = 12
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	# 右上弧
	for i in range(segs + 1):
		var a: float = PI * 0.5 - (float(i) / segs) * PI
		verts.append(Vector2(hw + cos(a) * hw * 0.4, -hh + sin(a) * hh))
	# 右下弧
	for i in range(segs + 1):
		var a: float = -PI * 0.5 - (float(i) / segs) * PI
		verts.append(Vector2(hw + cos(a) * hw * 0.4, -hh + sin(a) * hh))
	# 下直
	verts.append(Vector2(-hw, hh))
	verts.append(Vector2(-hw, -hh))
	return verts

# 圆形（头）
static func circle_v(r: float, segs: int = 16) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(segs):
		var a: float = float(i) / segs * TAU
		verts.append(Vector2(cos(a) * r, sin(a) * r))
	return verts

# 胶囊（手臂/腿 — 长轴垂直）
static func limb_v(w: float, h: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var segs: int = 10
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	# 上弧
	for i in range(segs + 1):
		var a: float = PI - (float(i) / segs) * PI
		verts.append(Vector2(cos(a) * hw, -hh + sin(a) * hh * 0.3 + hh))
	# 右
	verts.append(Vector2(hw, -hh + 2))
	# 下弧
	for i in range(segs + 1):
		var a: float = -PI - (float(i) / segs) * PI
		verts.append(Vector2(cos(a) * hw, -hh + sin(a) * hh * 0.3 - hh))
	# 左
	verts.append(Vector2(-hw, -hh - 2))
	# 再构造: 简化成长椭圆
	var simple := PackedVector2Array()
	for i in range(segs * 2):
		var a: float = float(i) / (segs * 2) * TAU
		simple.append(Vector2(cos(a) * hw * 0.6, sin(a) * hh))
	return simple

# 简化胶囊（水平 + 椭圆）
static func ellipse_v(rx: float, ry: float, segs: int = 16) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in range(segs):
		var a: float = float(i) / segs * TAU
		verts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return verts

# 矩形圆角
static func rounded_rect_v(w: float, h: float, r: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	# 左上弧
	for i in range(6):
		var a: float = PI - (float(i) / 5.0) * PI * 0.5
		verts.append(Vector2(-hw + r + cos(a) * r, -hh + r + sin(a) * r))
	# 右上弧
	for i in range(6):
		var a: float = PI * 0.5 - (float(i) / 5.0) * PI * 0.5
		verts.append(Vector2(hw - r + cos(a) * r, -hh + r + sin(a) * r))
	# 右下弧
	for i in range(6):
		var a: float = - (float(i) / 5.0) * PI * 0.5
		verts.append(Vector2(hw - r + cos(a) * r, hh - r + sin(a) * r))
	# 左下弧
	for i in range(6):
		var a: float = PI * 1.5 - (float(i) / 5.0) * PI * 0.5
		verts.append(Vector2(-hw + r + cos(a) * r, hh - r + sin(a) * r))
	return verts

# ==================== build() — 主入口 ====================

func build(type_name: String, element: String, base_color: Color, is_boss: bool = false) -> Dictionary:
	var out := {}
	var colors := {}

	# 1. 挑体型
	var body_scale: float = 1.3 if is_boss else 1.0
	var is_humanoid: bool = _is_humanoid_type(type_name)
	var is_slime_like: bool = type_name.begins_with("slime") or type_name.begins_with("minion_water") or type_name.begins_with("wraith")
	var is_skeleton_like: bool = type_name.begins_with("skeleton") or type_name.begins_with("minion_archer")
	var is_blob_like: bool = type_name.begins_with("minion_fire") or type_name.begins_with("minion_shadow") or type_name.begins_with("minion_thunder")
	var is_giant_like: bool = type_name.begins_with("giant") or type_name.begins_with("lava_giant")
	var is_mech_like: bool = type_name.begins_with("mech")

	# 2. 取主色
	var main_c: Color = base_color
	if CLASS_COLORS.has(type_name):
		main_c = CLASS_COLORS[type_name]
	elif ENEMY_COLORS.has(type_name):
		main_c = ENEMY_COLORS[type_name]
	main_c = Color(main_c.r, main_c.g, main_c.b)  # 去掉 alpha 干扰

	# 3. 躯干 — 所有人体角色统一形状，按类型微调大小
	var torso_w: float = 16.0 * body_scale
	var torso_h: float = 20.0 * body_scale
	if is_giant_like:
		torso_w = 22.0 * body_scale
		torso_h = 24.0 * body_scale
	elif is_slime_like:
		torso_w = 22.0 * body_scale
		torso_h = 14.0 * body_scale
	elif is_blob_like:
		torso_w = 18.0 * body_scale
		torso_h = 15.0 * body_scale
	elif is_skeleton_like:
		torso_w = 14.0 * body_scale
		torso_h = 22.0 * body_scale
	elif is_mech_like:
		torso_w = 20.0 * body_scale
		torso_h = 18.0 * body_scale

	if is_slime_like or is_blob_like:
		out["torso"] = ellipse_v(torso_w, torso_h, 20)
	elif is_mech_like:
		out["torso"] = rounded_rect_v(torso_w, torso_h, 4.0)
	elif is_skeleton_like:
		out["torso"] = capsule_v(torso_w * 0.5, torso_h)
	else:
		out["torso"] = capsule_v(torso_w * 0.7, torso_h)
	colors["torso"] = main_c

	# 4. 头（挂在 Torso 下）
	var head_r: float = 9.0 * body_scale
	if is_slime_like or is_blob_like:
		head_r = 11.0 * body_scale
	elif is_skeleton_like:
		head_r = 8.0 * body_scale
	elif is_giant_like:
		head_r = 12.0 * body_scale
	out["head"] = circle_v(head_r)
	# 头色: 肤色/元素色
	var head_c: Color = main_c
	if is_skeleton_like:
		head_c = Color(0.92, 0.90, 0.82)
	elif is_slime_like:
		head_c = main_c.darkened(0.1)
	elif type_name.begins_with("player_") or CLASS_COLORS.has(type_name):
		head_c = Color(0.92, 0.85, 0.72)  # 玩家类统一肤色
	colors["head"] = head_c

	# 5. 手臂（挂在 Torso 下, offset (-10,-4) / (10,-4)）
	var arm_w: float = 4.0 * body_scale
	var arm_h: float = 10.0 * body_scale
	if is_giant_like:
		arm_w = 6.0 * body_scale
		arm_h = 14.0 * body_scale
	elif is_mech_like:
		arm_w = 5.0 * body_scale
		arm_h = 10.0 * body_scale
	elif is_skeleton_like:
		arm_w = 2.5 * body_scale
		arm_h = 11.0 * body_scale
	elif is_slime_like or is_blob_like:
		# 史莱姆类没手臂
		arm_w = 0.0
	if arm_w > 0.0:
		out["arm_l"] = ellipse_v(arm_w, arm_h, 12)
		out["arm_r"] = ellipse_v(arm_w, arm_h, 12)
	else:
		out["arm_l"] = PackedVector2Array()
		out["arm_r"] = PackedVector2Array()
	colors["arm_l"] = main_c
	colors["arm_r"] = main_c

	# 6. 腿（挂在 Pelvis 下, offset (-5,0) / (5,0)）
	var leg_w: float = 4.5 * body_scale
	var leg_h: float = 12.0 * body_scale
	if is_giant_like:
		leg_w = 6.0 * body_scale
		leg_h = 15.0 * body_scale
	elif is_skeleton_like:
		leg_w = 2.8 * body_scale
		leg_h = 13.0 * body_scale
	elif is_mech_like:
		leg_w = 5.0 * body_scale
		leg_h = 11.0 * body_scale
	elif is_slime_like or is_blob_like:
		# 史莱姆类没腿 —— 留一点点做底部
		out["leg_l"] = PackedVector2Array()
		out["leg_r"] = PackedVector2Array()
	else:
		out["leg_l"] = ellipse_v(leg_w, leg_h, 12)
		out["leg_r"] = ellipse_v(leg_w, leg_h, 12)
	colors["leg_l"] = main_c.darkened(0.08)
	colors["leg_r"] = main_c.darkened(0.08)

	out["colors"] = colors
	return out


static func _is_humanoid_type(t: String) -> bool:
	return CLASS_COLORS.has(t)


# ==================== 武器生成 ====================

func weapon_for(entity_type: String) -> Dictionary:
	match entity_type:
		# —— 近战 ——
		"warrior": {
			"verts": _sword_v(),
			"color": Color(0.75, 0.78, 0.82),
			"anchor": Vector2(10, -2),
			"rotation": -60.0,
		}
		"runeward", "death_knight": {
			"verts": _greatsword_v(),
			"color": Color(0.55, 0.58, 0.65),
			"anchor": Vector2(10, -2),
			"rotation": -60.0,
		}
		"qi_adept", "monk": {
			"verts": _empty_v(),
			"color": Color.WHITE,
			"anchor": Vector2.ZERO,
			"rotation": 0.0,
		}
		# —— 远程 ——
		"archer": {
			"verts": _bow_v(),
			"color": Color(0.65, 0.42, 0.28),
			"anchor": Vector2(6, -4),
			"rotation": -30.0,
		}
		"sniper": {
			"verts": _rifle_v(),
			"color": Color(0.28, 0.28, 0.32),
			"anchor": Vector2(8, -3),
			"rotation": -15.0,
		}
		"bounty_hunter": {
			"verts": _revolver_v(),
			"color": Color(0.38, 0.36, 0.34),
			"anchor": Vector2(10, -1),
			"rotation": -10.0,
		}
		# —— 法杖/法术 ——
		"mage", "priest", "necromancer": {
			"verts": _staff_v(),
			"color": Color(0.55, 0.38, 0.22),
			"anchor": Vector2(8, -6),
			"rotation": -50.0,
		}
		# —— 炸弹/科技 ——
		"bomber": {
			"verts": _bomb_v(),
			"color": Color(0.85, 0.82, 0.75),
			"anchor": Vector2(10, -2),
			"rotation": -40.0,
		}
		"engineer": {
			"verts": _wrench_v(),
			"color": Color(0.6, 0.6, 0.64),
			"anchor": Vector2(10, -2),
			"rotation": -60.0,
		}
		# —— 其他 ——
		"mech_pilot": {
			"verts": _gatling_v(),
			"color": Color(0.52, 0.54, 0.58),
			"anchor": Vector2(12, -2),
			"rotation": -20.0,
		}
		"cyborg", "hacker": {
			"verts": _claw_v(),
			"color": Color(0.45, 0.48, 0.52),
			"anchor": Vector2(10, -2),
			"rotation": -30.0,
		}
		"thief": {
			"verts": _dagger_v(),
			"color": Color(0.7, 0.72, 0.75),
			"anchor": Vector2(8, -2),
			"rotation": -30.0,
		}
		# —— 敌人类型一般没武器 ——
		_:
			return {}
	return {}

static func _empty_v() -> PackedVector2Array: return PackedVector2Array()

static func _sword_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(0, -18)); v.append(Vector2(3, -18))
	v.append(Vector2(5, 6)); v.append(Vector2(-2, 8))
	v.append(Vector2(-4, 6)); v.append(Vector2(-3, -18))
	return v

static func _greatsword_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-1, -26)); v.append(Vector2(5, -26))
	v.append(Vector2(8, 10)); v.append(Vector2(-4, 12))
	v.append(Vector2(-6, 10)); v.append(Vector2(-5, -26))
	return v

static func _bow_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(0, -16)); v.append(Vector2(10, -8))
	v.append(Vector2(14, 0)); v.append(Vector2(10, 8))
	v.append(Vector2(0, 16)); v.append(Vector2(-2, 8))
	v.append(Vector2(2, 0)); v.append(Vector2(-2, -8))
	return v

static func _staff_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-2, -14)); v.append(Vector2(2, -14))
	v.append(Vector2(2, 14)); v.append(Vector2(-2, 14))
	# 法杖顶宝石
	v.append(Vector2(6, -14)); v.append(Vector2(6, -18))
	v.append(Vector2(0, -22)); v.append(Vector2(-6, -18)); v.append(Vector2(-6, -14))
	return v

static func _rifle_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-2, -12)); v.append(Vector2(18, -12))
	v.append(Vector2(20, -8)); v.append(Vector2(20, -4))
	v.append(Vector2(-2, -4)); v.append(Vector2(-2, 2))
	v.append(Vector2(-6, 2)); v.append(Vector2(-6, -4))
	return v

static func _revolver_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-2, -6)); v.append(Vector2(10, -6))
	v.append(Vector2(10, -2)); v.append(Vector2(-2, -2))
	v.append(Vector2(-4, 4)); v.append(Vector2(-2, 4))
	v.append(Vector2(-2, -6))
	return v

static func _bomb_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(0, -8))
	for i in range(12):
		var a: float = float(i) / 12.0 * TAU
		v.append(Vector2(cos(a) * 6, sin(a) * 6 - 2))
	return v

static func _wrench_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-1, -14)); v.append(Vector2(3, -14))
	v.append(Vector2(3, 10)); v.append(Vector2(-1, 10))
	v.append(Vector2(-1, 12)); v.append(Vector2(-5, 12))
	v.append(Vector2(-5, 8)); v.append(Vector2(-1, 8))
	return v

static func _gatling_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-2, -10)); v.append(Vector2(20, -12))
	v.append(Vector2(22, -8)); v.append(Vector2(22, -4))
	v.append(Vector2(20, 0)); v.append(Vector2(-2, 0))
	v.append(Vector2(-4, -4)); v.append(Vector2(-4, -6))
	return v

static func _claw_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(0, -6)); v.append(Vector2(14, -8))
	v.append(Vector2(16, -4)); v.append(Vector2(12, 0))
	v.append(Vector2(10, 4)); v.append(Vector2(4, 2))
	v.append(Vector2(2, -2))
	return v

static func _dagger_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(0, -12)); v.append(Vector2(2, -12))
	v.append(Vector2(4, 6)); v.append(Vector2(0, 8))
	v.append(Vector2(-4, 6)); v.append(Vector2(-2, -12))
	return v

# ==================== 装饰生成 ====================

func decorations_for(entity_type: String) -> Array:
	var decos: Array = []
	match entity_type:
		# 战士：胸口护心甲
		"warrior":
			decos.append({
				"name": "Chest",
				"parent": "torso",
				"position": Vector2(0, 0),
				"rotation": 0.0,
				"color": Color(0.72, 0.30, 0.24),
				"verts": _chest_plate_v(),
			})
		# 法师：尖顶帽
		"mage":
			decos.append({
				"name": "Hat",
				"parent": "head",
				"position": Vector2(0, -4),
				"rotation": 0.0,
				"color": Color(0.32, 0.42, 0.82),
				"verts": _pointed_hat_v(),
			})
		# 弓箭手：帽子
		"archer":
			decos.append({
				"name": "Cowl",
				"parent": "head",
				"position": Vector2(0, -2),
				"rotation": 0.0,
				"color": Color(0.35, 0.50, 0.35),
				"verts": _cowl_v(),
			})
		# 盗贼：面罩
		"thief":
			decos.append({
				"name": "Mask",
				"parent": "head",
				"position": Vector2(0, -2),
				"rotation": 0.0,
				"color": Color(0.15, 0.15, 0.20),
				"verts": _mask_v(),
			})
		# 机甲师：头盔
		"mech_pilot":
			decos.append({
				"name": "Helmet",
				"parent": "head",
				"position": Vector2(0, 0),
				"rotation": 0.0,
				"color": Color(0.38, 0.40, 0.44),
				"verts": _helmet_v(),
			})
		# 死亡骑士：肩甲 + 披风
		"death_knight":
			decos.append({
				"name": "Pauldron",
				"parent": "torso",
				"position": Vector2(0, -6),
				"rotation": 0.0,
				"color": Color(0.22, 0.22, 0.28),
				"verts": _pauldron_v(),
			})
			decos.append({
				"name": "Cloak",
				"parent": "torso",
				"position": Vector2(-14, 2),
				"rotation": 0.0,
				"color": Color(0.28, 0.18, 0.32),
				"verts": _cloak_v(),
			})
		# 气宗：头带
		"qi_adept":
			decos.append({
				"name": "Headband",
				"parent": "head",
				"position": Vector2(0, -2),
				"rotation": 0.0,
				"color": Color(0.92, 0.72, 0.22),
				"verts": _headband_v(),
			})
	return decos

static func _chest_plate_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-8, -4)); v.append(Vector2(8, -4))
	v.append(Vector2(10, 6)); v.append(Vector2(0, 10))
	v.append(Vector2(-10, 6))
	return v

static func _pointed_hat_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-8, 2)); v.append(Vector2(8, 2))
	v.append(Vector2(4, -4)); v.append(Vector2(0, -18)); v.append(Vector2(-4, -4))
	return v

static func _cowl_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-7, 2)); v.append(Vector2(7, 2))
	v.append(Vector2(7, -6)); v.append(Vector2(4, -12))
	v.append(Vector2(0, -14)); v.append(Vector2(-4, -12)); v.append(Vector2(-7, -6))
	return v

static func _mask_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-8, 2)); v.append(Vector2(8, 2))
	v.append(Vector2(8, -2)); v.append(Vector2(-8, -2))
	return v

static func _helmet_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	for i in range(14):
		var a: float = float(i) / 14.0 * TAU
		v.append(Vector2(cos(a) * 9, sin(a) * 9 - 1))
	return v

static func _pauldron_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-12, -2)); v.append(Vector2(12, -2))
	v.append(Vector2(10, 4)); v.append(Vector2(-10, 4))
	return v

static func _cloak_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-4, -4)); v.append(Vector2(6, -4))
	v.append(Vector2(14, 18)); v.append(Vector2(2, 22)); v.append(Vector2(-12, 22))
	return v

static func _headband_v() -> PackedVector2Array:
	var v := PackedVector2Array()
	v.append(Vector2(-10, -2)); v.append(Vector2(10, -2))
	v.append(Vector2(10, 2)); v.append(Vector2(-10, 2))
	return v
