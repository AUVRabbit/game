# ============================================================
# EnemySpawner — 刷怪器
# 在半径内维持指定数量的敌人，死亡后按冷却补刷
# ============================================================

extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene = null
@export var enemy_config: Dictionary = {}
@export var max_alive: int = 4
@export var initial_count: int = 2
@export var spawn_radius: float = 150.0
@export var respawn_time: float = 7.0

var spawn_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy_spawners")
	for i in initial_count:
		spawn_one()
	spawn_timer = respawn_time

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	spawn_timer = respawn_time
	if _alive_count() < max_alive:
		spawn_one()

func _alive_count() -> int:
	var count := 0
	for child in get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			count += 1
	return count

func spawn_one() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	for key in enemy_config.keys():
		if key in enemy:
			enemy.set(key, enemy_config[key])
	var angle := randf() * TAU
	var dist := randf_range(spawn_radius * 0.35, spawn_radius)
	var offset := Vector2(cos(angle), sin(angle) * 0.7) * dist
	enemy.position = offset
	add_child(enemy)
