# ============================================================
# SummonedMinion — 召唤物（亡灵）
# 自动寻找最近敌人、贴近攻击，存活时间到后消散
# 纯代码绘制骨骼形体，与敌人占位形体同一视觉语言
# ============================================================

extends CharacterBody2D
class_name SummonedMinion

var lifetime: float = 12.0
var damage: int = 10
var is_magic: bool = true
var move_speed: float = 120.0
var attack_range: float = 40.0
var attack_interval: float = 1.0
var detect_range: float = 420.0
var source: Node = null
var color: Color = Color(0.62, 0.45, 0.95)
var body_scale: float = 1.0
var special_ability: String = ""
var minion_type: String = "ghost"

var attack_timer: float = 0.0
var target: Node2D = null
var pulse: float = 0.0
var lifetime_left: float = 0.0

func _ready() -> void:
	add_to_group("summons")
	collision_layer = 0
	collision_mask = 0
	z_index = 1
	lifetime_left = lifetime

func _physics_process(delta: float) -> void:
	pulse += delta
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		_fade_out()
		return
	if attack_timer > 0.0:
		attack_timer = maxf(0.0, attack_timer - delta)
	if target != null and not is_instance_valid(target):
		target = null
	if target == null:
		target = _nearest_enemy()
	if target == null:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	if dist > attack_range:
		velocity = to_target.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			attack_timer = attack_interval
			_attack(target)
	queue_redraw()

func _attack(enemy: Node) -> void:
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return
	var dealt: int = enemy.take_damage(damage, is_magic, source)
	DamageNumber.spawn(get_parent(), enemy.global_position + Vector2(0, -26), dealt, false)
	SkillVfx.spawn_impact(get_parent(), enemy.global_position, "void_pulse", color)

func _nearest_enemy():
	var best = null
	var best_d := detect_range
	var tree := get_tree()
	if tree == null:
		return null
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var d: float = global_position.distance_to((e as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _fade_out() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var s := body_scale
	# 骨骼躯干 + 头骨 + 双爪
	draw_circle(Vector2(0, -18 * s), 7.0 * s, Color(0.86, 0.84, 0.76))
	draw_circle(Vector2(-3 * s, -19 * s), 2.0 * s, Color(0.1, 0.05, 0.12))
	draw_circle(Vector2(3 * s, -19 * s), 2.0 * s, Color(0.1, 0.05, 0.12))
	draw_line(Vector2(0, -11 * s), Vector2(0, 4 * s), Color(0.8, 0.78, 0.7), 3.0 * s)
	draw_line(Vector2(0, -6 * s), Vector2(-9 * s, 0), Color(0.8, 0.78, 0.7), 2.0)
	draw_line(Vector2(0, -6 * s), Vector2(9 * s, 0), Color(0.8, 0.78, 0.7), 2.0)
	draw_line(Vector2(0, 4 * s), Vector2(-6 * s, 12 * s), Color(0.8, 0.78, 0.7), 2.0)
	draw_line(Vector2(0, 4 * s), Vector2(6 * s, 12 * s), Color(0.8, 0.78, 0.7), 2.0)
	var glow := (sin(pulse * 4.0) + 1.0) * 0.5
	draw_arc(Vector2.ZERO, 16.0 * s, 0, TAU, 18, Color(color.r, color.g, color.b, 0.18 + glow * 0.18), 1.5)
