# ============================================================
# TrainingDummy — 训练木桩
# 继承 EnemyBase，复用受击反馈链（闪白/爆血/震屏/HitStop），
# 但永不死、永不攻击，并实时统计 DPS / 总伤害 / 命中次数。
# 可按元素与状态免疫配置，用于验证元素克制与状态免疫。
# ============================================================

extends EnemyBase
class_name TrainingDummy

@export var dummy_label: String = "训练木桩"
@export var dummy_element: String = "physical"
@export var dummy_immune: Array = []
@export var is_moving: bool = false
@export var move_span: float = 120.0
@export var move_rate: float = 0.35

const ELEMENT_COLORS := {
	"physical": Color(0.72, 0.60, 0.42),
	"water": Color(0.36, 0.76, 0.96),
	"fire": Color(1.00, 0.46, 0.16),
	"mech": Color(0.66, 0.72, 0.80),
	"shadow": Color(0.62, 0.46, 0.88),
	"ice": Color(0.62, 0.90, 1.00),
	"earth": Color(0.72, 0.56, 0.36),
	"holy": Color(1.00, 0.92, 0.60),
	"nature": Color(0.52, 0.86, 0.52),
	"thunder": Color(0.92, 0.86, 0.36),
}

const STATUS_CN := {
	"stun": "晕",
	"slow": "缓",
	"freeze": "冻",
	"burn": "燃",
	"knockback": "退",
	"root": "缚",
}

var total_damage: int = 0
var hit_count: int = 0
var last_hit_damage: int = 0

var _dps_window: int = 0
var _dps_timer: float = 0.0
var _dps_value: float = 0.0
var _time: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _label: Label = null

func _ready() -> void:
	enemy_name = dummy_label
	enemy_type = "training_dummy"
	primary_element = dummy_element
	var immune: Array = dummy_immune.duplicate()
	if not immune.has("knockback"):
		immune.append("knockback")
	status_immune = immune
	max_hp = 999999
	attack = 0
	defense = 0
	magic_defense = 0
	move_speed = 0.0
	detect_range = 0.0
	attack_range = 0.0
	attack_cooldown_time = 999.0
	exp_reward = 0
	gold_reward_min = 0
	gold_reward_max = 0
	body_radius = 24.0
	body_color = _element_color()
	is_boss = false
	super._ready()
	hp = max_hp
	_origin = global_position
	add_to_group("training_dummies")
	_build_label()

# 木桩没有 AI：只负责移动（可选）与 DPS 结算
func _physics_process(delta: float) -> void:
	_time += delta
	if is_moving:
		global_position = _origin + Vector2(sin(_time * move_rate * TAU) * move_span, 0.0)
	_dps_timer += delta
	if _dps_timer >= 1.0:
		_dps_value = float(_dps_window) / _dps_timer
		_dps_window = 0
		_dps_timer = 0.0
		_refresh_label()

func take_damage(amount: int, is_magic: bool = false, source: Node = null) -> int:
	var dealt: int = super.take_damage(amount, is_magic, source)
	if dealt > 0:
		total_damage += dealt
		_dps_window += dealt
		hit_count += 1
		last_hit_damage = dealt
		_refresh_label()
	hp = max_hp
	return dealt

# 木桩永远不死
func _die() -> void:
	hp = max_hp

func apply_knockback(_push_dir: Vector2, _amount: float) -> void:
	pass

func reset_stats() -> void:
	total_damage = 0
	hit_count = 0
	last_hit_damage = 0
	_dps_window = 0
	_dps_value = 0.0
	_dps_timer = 0.0
	hp = max_hp
	_refresh_label()

func _element_color() -> Color:
	return ELEMENT_COLORS.get(dummy_element, Color(0.70, 0.70, 0.75))

func _build_label() -> void:
	_label = Label.new()
	_label.position = Vector2(-100, -86)
	_label.size = Vector2(200, 46)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(0.93, 0.96, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	var elem_name := ElementKeeper.element_name(dummy_element)
	var parts: Array = []
	for k in dummy_immune:
		parts.append(str(STATUS_CN.get(str(k), str(k))))
	var imm := ""
	if not parts.is_empty():
		imm = " · 免疫 " + ", ".join(PackedStringArray(parts))
	_label.text = "%s [%s]%s\nDPS %.0f · 总伤害 %d · 命中 %d" % [
		dummy_label, elem_name, imm, _dps_value, total_damage, hit_count
	]

func _draw() -> void:
	var col: Color = _element_color()
	if flash_timer > 0.0:
		col = col.lightened(0.6)
	var r := body_radius
	draw_circle(Vector2(0, 7), r * 1.08, Color(0, 0, 0, 0.28))
	draw_circle(Vector2.ZERO, r, col.darkened(0.30))
	draw_circle(Vector2.ZERO, r * 0.78, col)
	draw_circle(Vector2.ZERO, r * 0.50, col.lightened(0.22))
	draw_arc(Vector2.ZERO, r + 4.0, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.55), 2.0, true)
	_draw_element_mark(col, r)

func _draw_element_mark(col: Color, r: float) -> void:
	var ink := Color(0.06, 0.08, 0.12, 0.85)
	match dummy_element:
		"fire":
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 0.55), Vector2(r * 0.30, r * 0.05),
				Vector2(0, r * 0.40), Vector2(-r * 0.30, r * 0.05)
			]), Color(1.0, 0.78, 0.32, 0.95))
		"water":
			draw_circle(Vector2(0, r * 0.08), r * 0.22, Color(0.62, 0.88, 1.0, 0.95))
			draw_circle(Vector2(-r * 0.08, r * 0.02), r * 0.07, Color(1, 1, 1, 0.9))
		"ice":
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -r * 0.45), Vector2(r * 0.22, 0), Vector2(0, r * 0.45), Vector2(-r * 0.22, 0)
			]), Color(0.85, 0.97, 1.0, 0.95))
		"mech":
			var hex := PackedVector2Array()
			for i in range(6):
				var a := TAU * float(i) / 6.0
				hex.append(Vector2(cos(a), sin(a)) * r * 0.34)
			draw_colored_polygon(hex, Color(0.16, 0.20, 0.26, 0.9))
			draw_circle(Vector2(0, 0), r * 0.12, Color(1.0, 0.32, 0.22, 0.95))
		"shadow":
			draw_arc(Vector2.ZERO, r * 0.34, 0.4, TAU - 0.4, 18, ink, 3.0, true)
			draw_arc(Vector2.ZERO, r * 0.20, PI, TAU + PI * 0.2, 14, Color(0.85, 0.62, 1.0, 0.9), 2.0, true)
		"thunder":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.10, -r * 0.45), Vector2(r * 0.16, -r * 0.05),
				Vector2(r * 0.02, -r * 0.02), Vector2(r * 0.16, r * 0.45),
				Vector2(-r * 0.16, r * 0.02), Vector2(0, -r * 0.02)
			]), Color(1.0, 0.95, 0.35, 0.95))
		_:
			draw_line(Vector2(-r * 0.30, 0), Vector2(r * 0.30, 0), ink, 3.5)
			draw_line(Vector2(0, -r * 0.30), Vector2(0, r * 0.30), ink, 3.5)
