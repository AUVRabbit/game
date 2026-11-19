# ============================================================
# CharacterBase.gd — 角色职业基类
# 所有职业（战士/弓箭手/法师...）继承此类
# 定义：属性、技能槽、战斗属性
# ============================================================

extends Node
class_name CharacterBase

# ---------- 职业枚举 ----------
enum ClassType { WARRIOR, ARCHER, MAGE, PRIEST,
                 NECROMANCER, DEATH_KNIGHT, THIEF, SNIPER,
                 BOMBER, HACKER, MECH_PILOT, BOUNTY_HUNTER }

var class_type: ClassType = ClassType.WARRIOR
var class_display_name: String = "战士"

# ---------- 基础属性 ----------
var level: int = 1
var exp: int = 0
var exp_to_next: int = 100
var gold: int = 0

# ---------- 战斗属性 ----------
var max_hp: int = 100
var hp: int = 100
var max_mp: int = 50
var mp: int = 50
var attack: int = 10          # 物理攻击力
var defense: int = 5          # 物理防御力
var magic_attack: int = 5     # 魔法攻击力
var magic_defense: int = 3    # 魔法防御力
var attack_speed: float = 1.0 # 攻击速度倍率
var move_speed: float = 200.0 # 移动速度（像素/秒）
var crit_rate: float = 0.05   # 暴击率
var crit_damage: float = 1.5  # 暴击伤害倍率
var dodge_rate: float = 0.02  # 闪避率

# ---------- 技能槽 ----------
var skill_slots: Array = [null, null, null]  # 3个技能槽，存 Skill 数据

# ---------- Buff/Debuff ----------
var active_buffs: Array = []

func _ready() -> void:
    _init_by_class()

func _init_by_class() -> void:
    """根据职业设置初始属性 — 子类可覆盖"""
    match class_type:
        ClassType.WARRIOR:
            class_display_name = "战士"
            max_hp = 150; attack = 15; defense = 12; move_speed = 180
        ClassType.ARCHER:
            class_display_name = "弓箭手"
            max_hp = 90; attack = 18; defense = 4; move_speed = 220; crit_rate = 0.1
        ClassType.MAGE:
            class_display_name = "法师"
            max_hp = 70; max_mp = 120; magic_attack = 22; defense = 2
        ClassType.PRIEST:
            class_display_name = "牧师"
            max_hp = 85; max_mp = 100; magic_attack = 12; defense = 5
        ClassType.NECROMANCER:
            class_display_name = "亡灵法师"
            max_hp = 75; max_mp = 110; magic_attack = 20
        ClassType.DEATH_KNIGHT:
            class_display_name = "死亡骑士"
            max_hp = 140; attack = 14; defense = 10
        ClassType.THIEF:
            class_display_name = "小偷"
            max_hp = 80; attack = 12; move_speed = 260; dodge_rate = 0.15
        ClassType.SNIPER:
            class_display_name = "狙击手"
            max_hp = 85; attack = 25; crit_rate = 0.2; crit_damage = 2.0
        ClassType.BOMBER:
            class_display_name = "炸弹专家"
            max_hp = 100; attack = 16; move_speed = 190
        ClassType.HACKER:
            class_display_name = "黑客"
            max_hp = 65; max_mp = 130; magic_attack = 18
        ClassType.MECH_PILOT:
            class_display_name = "机甲师"
            max_hp = 180; attack = 13; defense = 15; move_speed = 140
        ClassType.BOUNTY_HUNTER:
            class_display_name = "赏金猎人"
            max_hp = 95; attack = 17; crit_rate = 0.08; dodge_rate = 0.08
    hp = max_hp
    mp = max_mp

# ---------- 战斗接口 ----------
func take_damage(amount: int, is_magic: bool = false) -> int:
    """实际扣除的 HP，返回实际伤害值"""
    var defense_val = magic_defense if is_magic else defense
    var final_dmg = maxi(1, amount - defense_val)
    # 闪避判定
    if randf() < dodge_rate:
        final_dmg = 0
    hp = maxi(0, hp - final_dmg)
    return final_dmg

func heal(amount: int) -> int:
    var actual = mini(amount, max_hp - hp)
    hp += actual
    return actual

func use_mp(cost: int) -> bool:
    if mp >= cost:
        mp -= cost
        return true
    return false

func add_exp(amount: int) -> void:
    exp += amount
    while exp >= exp_to_next:
        exp -= exp_to_next
        level_up()

func level_up() -> void:
    level += 1
    exp_to_next = int(exp_to_next * 1.2)
    max_hp += 10
    max_mp += 5
    attack += 2
    defense += 1
    hp = max_hp
    mp = max_mp
    print("[%s] 升级！Lv.%d" % [class_display_name, level])
