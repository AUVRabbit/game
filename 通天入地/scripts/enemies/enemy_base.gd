# ============================================================
# EnemyBase.gd — 敌人基类
# 所有敌人继承此类，定义：属性、AI、掉落
# ============================================================

extends CharacterBody2D
class_name EnemyBase

# ---------- 属性 ----------
@export var enemy_name: String = "怪物"
@export var max_hp: int = 50
var hp: int = 50
@export var attack: int = 8
@export var defense: int = 3
@export var exp_reward: int = 20
@export var gold_reward_min: int = 5
@export var gold_reward_max: int = 15

# ---------- AI 参数 ----------
@export var move_speed: float = 80.0
@export var detect_range: float = 200.0
@export var attack_range: float = 35.0
@export var attack_cooldown_time: float = 1.2

# ---------- 状态机 ----------
enum AIState { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }
var ai_state: AIState = AIState.IDLE

var attack_cooldown: float = 0.0
var detected_player: CharacterBody2D = null

func _ready() -> void:
    groups.add("enemies")
    hp = max_hp

func _physics_process(delta: float) -> void:
    if GameManager and GameManager.is_paused():
        return
    if hp <= 0:
        ai_state = AIState.DEAD
        queue_free()
        return

    attack_cooldown = maxf(0.0, attack_cooldown - delta)

    detected_player = _find_nearest_player()

    match ai_state:
        AIState.IDLE, AIState.PATROL:
            if detected_player and global_position.distance_to(detected_player.global_position) < detect_range:
                ai_state = AIState.CHASE
        AIState.CHASE:
            if detected_player:
                var dist = global_position.distance_to(detected_player.global_position)
                if dist < attack_range:
                    ai_state = AIState.ATTACK
                else:
                    var dir = (detected_player.global_position - global_position).normalized()
                    velocity = dir * move_speed
                    move_and_slide()
            else:
                ai_state = AIState.IDLE
        AIState.ATTACK:
            if detected_player and attack_cooldown <= 0:
                _melee_attack()
                attack_cooldown = attack_cooldown_time
            if detected_player and global_position.distance_to(detected_player.global_position) > attack_range * 1.5:
                ai_state = AIState.CHASE

func _find_nearest_player() -> CharacterBody2D:
    var players = get_tree().get_nodes_in_group("player")
    var nearest: CharacterBody2D = null
    var min_dist := detect_range
    for p in players:
        if p is CharacterBody2D:
            var d = global_position.distance_to(p.global_position)
            if d < min_dist:
                min_dist = d
                nearest = p
    return nearest

func _melee_attack() -> void:
    if detected_player and detected_player.has_method("take_damage"):
        var dmg = maxi(1, attack - 2)
        detected_player.take_damage(dmg, false)
        print("[%s] 对玩家造成 %d 伤害" % [enemy_name, dmg])

# ---------- 被攻击接口 ----------
func take_damage(amount: int, is_magic: bool = false) -> int:
    var defense_val = magic_defense if is_magic else defense
    var final_dmg = maxi(1, amount - defense_val)
    hp = maxi(0, hp - final_dmg)
    if hp <= 0:
        _on_dead()
    return final_dmg

func _on_dead() -> void:
    if EventBus and detected_player:
        EventBus.enemy_died.emit(self, detected_player)
    # 掉落金币（简化）
    var gold = randi(gold_reward_min, gold_reward_max + 1)
    print("[%s] 掉落 %d 金币，获得 %d EXP" % [enemy_name, gold, exp_reward])
    if detected_player and detected_player.get_node_or_null("CharacterData"):
        detected_player.get_node("CharacterData").add_exp(exp_reward)
