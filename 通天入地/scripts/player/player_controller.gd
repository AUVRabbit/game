# ============================================================
# PlayerController.gd — 角色控制器
# 挂载在 CharacterBody2D 上
# 负责：移动、攻击、技能释放、动画切换
# ============================================================

extends CharacterBody2D
class_name PlayerController

# ---------- 依赖 ----------
@onready var character_data: CharacterBase = get_node_or_null("CharacterData")
@onready var visual_node: Node2D = get_node_or_null("Visual")
@onready var camera_anchor: Marker2D = get_node_or_null("CameraAnchor")
@onready var attack_point: Marker2D = get_node_or_null("AttackPoint")
@onready var sprite: Sprite2D = get_node_or_null("Visual/Sprite2D")

# ---------- 移动参数 ----------
var move_speed: float = 200.0
var current_direction: Vector2 = Vector2.DOWN

# ---------- 状态 ----------
enum State { IDLE, MOVE, ATTACK, CAST_SKILL, DASH, HURT, DEAD }
var state: State = State.IDLE

# ---------- 攻击/技能冷却 ----------
var attack_cooldown: float = 0.0
const ATTACK_COOLDOWN_TIME := 0.5
var skill_cooldowns: Array = [0.0, 0.0, 0.0]
const SKILL_COOLDOWN_TIMES := [3.0, 5.0, 8.0]  # 每个技能槽的 CD

# ---------- Dash ----------
var dash_timer: float = 0.0
const DASH_DURATION := 0.2
const DASH_SPEED := 500.0
const DASH_COOLDOWN_TIME := 1.5
var dash_cooldown: float = 0.0

# ---------- 引用全局输入管理器 ----------
var input_mgr: Node = null

func _ready() -> void:
    groups.add("player")
    # 自动查找或创建全局引用
    input_mgr = get_tree().get_root().get_node_or_null("Main/InputManager")
    # 应用职业速度
    if character_data:
        move_speed = character_data.move_speed

func _physics_process(delta: float) -> void:
    if GameManager and GameManager.is_paused():
        return

    # 冷却递减
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    for i in skill_cooldowns.size():
        skill_cooldowns[i] = maxf(0.0, skill_cooldowns[i] - delta)

    # 死亡后不做任何事
    if character_data and character_data.hp <= 0:
        state = State.DEAD
        return

    # Dash 处理
    if dash_timer > 0:
        dash_timer -= delta
        velocity = current_direction * DASH_SPEED
        move_and_slide()
        return

    # 获取输入（从 InputManager）
    var move_vec := Vector2.ZERO
    if input_mgr:
        move_vec = input_mgr.get_move_vector()
    else:
        move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")

    # 处理 Dash 触发
    if (Input.is_action_pressed("dash") or (input_mgr and input_mgr.is_dash_pressed())) \
            and dash_cooldown <= 0 and move_vec.length() > 0:
        _start_dash(move_vec.normalized())
        return

    # 移动
    if move_vec.length() > 0:
        current_direction = move_vec.normalized()
        state = State.MOVE
    elif state == State.MOVE:
        state = State.IDLE

    velocity = current_direction * move_speed
    move_and_slide()

    # 翻转朝向（左右）
    if sprite:
        sprite.flip_h = current_direction.x < 0

func _unhandled_input(event: InputEvent) -> void:
    if GameManager and GameManager.is_paused():
        return

    if event is InputEventKey and event.pressed and not event.echo:
        _handle_action_pressed(event)
    elif event is InputEventJoypadButton and event.pressed:
        _handle_action_pressed(event)

func _handle_action_pressed(event: InputEvent) -> void:
    # 普攻
    if Input.is_action_just_pressed("attack") and attack_cooldown <= 0 and state != State.ATTACK:
        _perform_attack()

    # 技能
    for i in 3:
        if Input.is_action_just_pressed("skill_%d" % (i + 1)) and skill_cooldowns[i] <= 0:
            _cast_skill(i)

    # 角色切换
    var switch_dir = InputManager.is_switch_character_pressed() if input_mgr else 0
    if switch_dir != 0 and GameManager:
        GameManager.switch_character(switch_dir)

    # 暂停
    if Input.is_action_just_pressed("pause") and GameManager:
        GameManager.toggle_pause()

func _start_dash(direction: Vector2) -> void:
    dash_timer = DASH_DURATION
    dash_cooldown = DASH_COOLDOWN_TIME
    state = State.DASH
    current_direction = direction
    # Dash 期间无敌（简化版）
    collision_layer = 2  # 只有自己的层
    get_tree().create_timer(DASH_DURATION + 0.05).timeout.connect(_on_dash_end)

func _on_dash_end() -> void:
    collision_layer = 2  # 恢复

func _perform_attack() -> void:
    attack_cooldown = ATTACK_COOLDOWN_TIME
    state = State.ATTACK
    # 攻击检测区域（简化）
    var attack_range := 40.0
    if attack_point:
        var enemies = get_tree().get_nodes_in_group("enemies")
        for enemy in enemies:
            if enemy is Node2D:
                var dist = attack_point.global_position.distance_to(enemy.global_position)
                if dist < attack_range:
                    _damage_enemy(enemy)
    # 动画结束后回到 IDLE/MOVE
    get_tree().create_timer(0.3).timeout.connect(func(): state = State.IDLE)

func _damage_enemy(enemy: Node) -> void:
    if character_data:
        var dmg = character_data.attack + randi(-2, 3)
        if randf() < character_data.crit_rate:
            dmg = int(dmg * character_data.crit_damage)
            print("[暴击!] 伤害 %d" % dmg)
        if enemy.has_method("take_damage"):
            enemy.take_damage(dmg, false)
        if EventBus:
            EventBus.attack_performed.emit(self, enemy)

func _cast_skill(slot_idx: int) -> void:
    skill_cooldowns[slot_idx] = SKILL_COOLDOWN_TIMES[slot_idx]
    state = State.CAST_SKILL
    # TODO: 根据 CharacterData.skill_slots 里的实际 Skill 数据执行逻辑
    print("[PlayerController] 释放技能槽 %d" % (slot_idx + 1))
    if EventBus:
        EventBus.skill_cast.emit(self, "skill_%d" % (slot_idx + 1))
    get_tree().create_timer(0.4).timeout.connect(func(): state = State.IDLE)
