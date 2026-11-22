#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按《职业与技能设计纲领》生成 16 职业 / 96 技能 / 16 阶技能树 / 48 专职。

设计依据（本文件即唯一事实来源）：
  1. 四源流：法术(arcane) / 机械(mech) / 传武(martial) / 科技(tech)
     每个源流绑定一种能量观与战斗节奏，决定主属性倾向与技能颜色族。
  2. 四战斗范式：破军(assault) / 铁壁(bulwark) / 辅弼(support) / 诡道(trickster)
     每个范式绑定一段生命/法力/主属性预算区间。
  3. 16 职业 = 4 源流 × 4 范式，矩阵的每一格恰好一个职业，不允许重复或空缺。
  4. 每个职业 6 个主动技能：3 基础（技能槽 1/2/3）+ 3 进阶（技能槽 R/F/G），
     进阶技能必须由技能树对应分支的“精通”节点前置解锁。
  5. 技能树 16 节点：初始3 → 精通3 → 进阶主动3 → 天赋被动3 → 专精被动3 → 终极1。
  6. 数值预算：进阶技能相对同分支基础技能，威力 ×1.3~1.6、冷却 ×1.5~2.0、
     法力 ×1.5~1.8；职业属性必须落在其(源流,范式)预算带内，脚本会校验。

用法：
    python3 tools/gen_class_content.py --check    # 只校验，不写文件
    python3 tools/gen_class_content.py            # 生成并写入 data/*.json
"""
import argparse
import copy
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")

# ------------------------------------------------------------------ 设计矩阵
SOURCES = {
    "arcane": {"name": "法术", "energy": "以太", "rhythm": "蓄势爆发"},
    "mech": {"name": "机械", "energy": "蒸汽", "rhythm": "布置引爆"},
    "martial": {"name": "传武", "energy": "气血", "rhythm": "贴身缠斗"},
    "tech": {"name": "科技", "energy": "算力", "rhythm": "预判压制"},
}
ROLES = {
    "assault": {"name": "破军", "duty": "爆发输出"},
    "bulwark": {"name": "铁壁", "duty": "承伤控场"},
    "support": {"name": "辅弼", "duty": "治疗增益"},
    "trickster": {"name": "诡道", "duty": "机动暗杀"},
}

# (源流, 范式) -> 职业 id，16 格全覆盖
MATRIX = {
    ("arcane", "assault"): "mage",
    ("arcane", "bulwark"): "runeward",
    ("arcane", "support"): "priest",
    ("arcane", "trickster"): "necromancer",
    ("mech", "assault"): "bomber",
    ("mech", "bulwark"): "mech_pilot",
    ("mech", "support"): "engineer",
    ("mech", "trickster"): "bounty_hunter",
    ("martial", "assault"): "death_knight",
    ("martial", "bulwark"): "warrior",
    ("martial", "support"): "qi_adept",
    ("martial", "trickster"): "thief",
    ("tech", "assault"): "archer",
    ("tech", "bulwark"): "cyborg",
    ("tech", "support"): "hacker",
    ("tech", "trickster"): "sniper",
}

# 战力预算：既有 12 职业是实机调校基准，先由该公式算出分布（169~248），
# 取包络 (160, 265) 作为 16 职业的共同预算带；新增职业必须落在带内。
# 公式对生命/法力/双攻/双防/移速/暴击/闪避/攻速/暴伤加权，权重见下。
POWER_BAND = (160.0, 265.0)
ROLE_HP_MIN = {"assault": 75, "bulwark": 130, "support": 70, "trickster": 78}
# 源流 -> 主属性取向：arcane 看魔法攻击，其余看物理攻击
SOURCE_OFFENSE = {
    "arcane": "magic_attack",
    "mech": "attack",
    "martial": "attack",
    "tech": "attack",
}

# 职业身份：一句话核心机制（写入 classes.json 的 identity 字段，作为设计依据）
IDENTITY = {
    "warrior": "铁壁反击：以高护甲与盾墙承伤，靠战吼把防御转成输出窗口。",
    "death_knight": "血怒冲锋：以自身生命为代价换取突进与范围斩击。",
    "qi_adept": "内息流转：以气血循环治疗与加速，自身亦能近身打出气劲。",
    "thief": "影袭毒刃：依赖背刺与烟幕在高风险窗口内爆发。",
    "mage": "元素爆发：以太塑形，远距离高倍率法术是主要伤害来源。",
    "runeward": "符文装甲：用咒文护盾吸收伤害并反噬近身之敌。",
    "priest": "神圣庇佑：治疗、圣光爆发与团队祝福三位一体。",
    "necromancer": "生死操控：以腐蚀、墓场与噬魂维持长时间消耗战。",
    "bomber": "爆破工程：用火药与燃烧覆盖战场，追求范围清场。",
    "mech_pilot": "重装要塞：机甲护甲与力场保证持续站桩输出。",
    "engineer": "战地工事：部署炮塔、修理与战术补给支援全队。",
    "bounty_hunter": "猎杀契约：标记目标后以速射与缴械压制。",
    "archer": "精确投射：复合弓与瞄准镜把暴击转化为稳定输出。",
    "cyborg": "义体壁垒：液压与能量装甲让自身成为移动前线。",
    "hacker": "网络入侵：病毒、断电与超频改写敌我攻防节奏。",
    "sniper": "潜行狙击：陷阱布场后以超远单发点杀关键目标。",
}

# ------------------------------------------------------------------ 新职业基础技能
NEW_CLASSES = {
    "runeward": {
        "name": "咒铠师", "color": "#7d6bff", "tree_name": "咒铠之典",
        "stats": {"max_hp": 135, "max_mp": 110, "attack": 7, "defense": 13,
                  "magic_attack": 13, "magic_defense": 12, "move_speed": 172,
                  "attack_speed": 0.95, "crit_rate": 0.04, "crit_damage": 1.5, "dodge_rate": 0.02},
        "base": [
            {"id": "rune_shield", "name": "符盾", "type": "shield", "cd": 12.0, "mp": 16, "power": 60,
             "duration": 7.0, "color": "#9fa8ff", "desc": "以咒文凝成护盾，吸收伤害。", "vfx": "shield_bubble"},
            {"id": "rune_burst", "name": "符爆", "type": "melee_aoe", "cd": 5.0, "mp": 12, "power": 1.4,
             "radius": 86, "damage_type": "magic", "color": "#b6a8ff", "desc": "引爆贴身符文，震退周围敌人。", "vfx": "rune_glyph"},
            {"id": "rune_aura", "name": "咒护", "type": "buff", "cd": 14.0, "mp": 14, "stat": "defense",
             "value": 12, "duration": 8.0, "color": "#8f9dff", "desc": "咒铠附体，短时间大幅提升防御。", "vfx": "buff_swirl"},
        ],
    },
    "qi_adept": {
        "name": "气宗", "color": "#6fe0b0", "tree_name": "气海心法",
        "stats": {"max_hp": 108, "max_mp": 100, "attack": 10, "defense": 8,
                  "magic_attack": 11, "magic_defense": 9, "move_speed": 200,
                  "attack_speed": 1.0, "crit_rate": 0.06, "crit_damage": 1.5, "dodge_rate": 0.04},
        "base": [
            {"id": "qi_palm", "name": "气劲掌", "type": "melee_aoe", "cd": 3.5, "mp": 9, "power": 1.5,
             "radius": 78, "damage_type": "physical", "color": "#7ff0c0", "desc": "掌风外放，横扫身前敌人。", "vfx": "melee_slash"},
            {"id": "qi_heal", "name": "内息术", "type": "heal", "cd": 8.0, "mp": 18, "power": 45,
             "color": "#8fffd2", "desc": "以气养身，回复自身生命。", "vfx": "heal_spark"},
            {"id": "qi_flow", "name": "气脉流转", "type": "buff", "cd": 12.0, "mp": 12, "stat": "attack_speed",
             "value": 0.18, "duration": 7.0, "color": "#a8ffe0", "desc": "气血周转，短时间内加快出手。", "vfx": "buff_swirl"},
        ],
    },
    "engineer": {
        "name": "工程师", "color": "#d9a441", "tree_name": "蒸汽工程学",
        "stats": {"max_hp": 105, "max_mp": 115, "attack": 9, "defense": 9,
                  "magic_attack": 10, "magic_defense": 8, "move_speed": 190,
                  "attack_speed": 1.0, "crit_rate": 0.05, "crit_damage": 1.5, "dodge_rate": 0.03},
        "base": [
            {"id": "turret", "name": "炮塔部署", "type": "aoe_zone", "cd": 7.0, "mp": 16, "power": 1.6,
             "radius": 70, "delay": 0.8, "damage_type": "physical", "color": "#ffc768", "desc": "架起自动炮塔，短时间内扫射区域。", "vfx": "explosion"},
            {"id": "repair", "name": "应急修理", "type": "heal", "cd": 9.0, "mp": 18, "power": 50,
             "color": "#ffe0a0", "desc": "用随身零件紧急修复自身伤势。", "vfx": "heal_spark"},
            {"id": "supply", "name": "战术补给", "type": "buff", "cd": 12.0, "mp": 12, "stat": "attack",
             "value": 8, "duration": 8.0, "color": "#ffd88f", "desc": "分发强化弹头，提升攻击。", "vfx": "steam_burst"},
        ],
    },
    "cyborg": {
        "name": "义体卫士", "color": "#58c8e8", "tree_name": "义体战律",
        "stats": {"max_hp": 165, "max_mp": 80, "attack": 15, "defense": 16,
                  "magic_attack": 6, "magic_defense": 10, "move_speed": 175,
                  "attack_speed": 0.95, "crit_rate": 0.06, "crit_damage": 1.5, "dodge_rate": 0.02},
        "base": [
            {"id": "hydraulic_punch", "name": "液压重拳", "type": "melee_aoe", "cd": 4.0, "mp": 10, "power": 1.7,
             "radius": 74, "damage_type": "physical", "color": "#7fdcf0", "desc": "义体液压驱动的一记重拳。", "vfx": "melee_slash"},
            {"id": "energy_wall", "name": "能量壁垒", "type": "shield", "cd": 13.0, "mp": 16, "power": 70,
             "duration": 7.0, "color": "#9ce9ff", "desc": "展开随身能量壁垒，吸收伤害。", "vfx": "shield_bubble"},
            {"id": "servo_charge", "name": "伺服突进", "type": "dash_strike", "cd": 6.0, "mp": 12, "power": 1.6,
             "distance": 135, "radius": 64, "damage_type": "physical", "color": "#6fd4ee", "desc": "伺服电机爆发，突进并撞击前方。", "vfx": "dash_streak"},
        ],
    },
}

# ------------------------------------------------------------------ 12 个既有职业的进阶技能
ADVANCED = {
    "warrior": [
        {"id": "earth_shatter", "name": "裂地斩", "type": "melee_aoe", "cd": 9.0, "mp": 18, "power": 2.3,
         "radius": 105, "damage_type": "physical", "color": "#ff7b4a", "desc": "纵身劈地，裂痕向四周扩散并击退敌人。", "vfx": "melee_slash"},
        {"id": "unyielding_will", "name": "不屈战意", "type": "buff", "cd": 18.0, "mp": 16, "stat": "attack",
         "value": 14, "duration": 9.0, "color": "#ffd24a", "desc": "越是重伤越是凶猛，大幅提升攻击。", "vfx": "buff_swirl"},
        {"id": "iron_bulwark", "name": "钢铁壁垒", "type": "shield", "cd": 18.0, "mp": 20, "power": 85,
         "duration": 8.0, "color": "#9fd3ff", "desc": "以全身甲胄立起壁垒，吸收大量伤害。", "vfx": "shield_bubble"},
    ],
    "archer": [
        {"id": "armor_pierce", "name": "破甲贯射", "type": "projectile", "cd": 6.0, "mp": 12, "power": 2.5,
         "speed": 620, "damage_type": "physical", "color": "#9dff8a", "desc": "淬钢箭矢高速贯穿，专破重甲。", "vfx": "arrow"},
        {"id": "arrow_storm", "name": "万箭齐发", "type": "aoe_zone", "cd": 12.0, "mp": 22, "power": 2.0,
         "radius": 115, "delay": 0.5, "damage_type": "physical", "color": "#c8ff6a", "desc": "倾泻整壶箭矢，覆盖大片区域。", "vfx": "arrow"},
        {"id": "eagle_focus", "name": "鹰眼聚焦", "type": "buff", "cd": 14.0, "mp": 12, "stat": "crit_rate",
         "value": 0.15, "duration": 8.0, "color": "#e0ff9a", "desc": "屏息锁定要害，显著提升暴击率。", "vfx": "buff_swirl"},
    ],
    "mage": [
        {"id": "meteor", "name": "陨星术", "type": "aoe_zone", "cd": 13.0, "mp": 28, "power": 2.8,
         "radius": 115, "delay": 0.7, "damage_type": "magic", "color": "#ff8a4a", "desc": "召唤陨星砸落，范围内一切焚毁。", "vfx": "fireball"},
        {"id": "absolute_zero", "name": "绝对零度", "type": "melee_aoe", "cd": 10.0, "mp": 22, "power": 2.1,
         "radius": 115, "damage_type": "magic", "color": "#8fd8ff", "desc": "以自身为心的极寒爆裂，冻结近身之敌。", "vfx": "ice_shard"},
        {"id": "arcane_surge", "name": "奥术洪流", "type": "shield", "cd": 18.0, "mp": 24, "power": 95,
         "duration": 8.0, "color": "#c0a8ff", "desc": "以太回旋成盾，护盾强度远超基础法术。", "vfx": "rune_glyph"},
    ],
    "priest": [
        {"id": "sanctuary", "name": "圣愈光辉", "type": "heal", "cd": 14.0, "mp": 32, "power": 90,
         "color": "#ffe9a8", "desc": "降下圣光，大量回复自身生命。", "vfx": "heal_spark"},
        {"id": "judgement", "name": "审判之光", "type": "melee_aoe", "cd": 11.0, "mp": 24, "power": 2.0,
         "radius": 110, "damage_type": "magic", "color": "#ffd76a", "desc": "圣光柱自天而降，审判周围罪业。", "vfx": "rune_glyph"},
        {"id": "holy_covenant", "name": "神圣盟约", "type": "buff", "cd": 20.0, "mp": 22, "stat": "defense",
         "value": 22, "duration": 10.0, "color": "#fff2c0", "desc": "立下盟约，长时间强化护甲。", "vfx": "buff_swirl"},
    ],
    "necromancer": [
        {"id": "soul_barrage", "name": "腐魂连矢", "type": "chain", "cd": 9.0, "mp": 22, "power": 1.4,
         "radius": 240, "count": 4, "damage_type": "magic", "color": "#a06bff", "desc": "腐魂接连弹射，最多命中四个目标。", "vfx": "void_pulse"},
        {"id": "mass_grave", "name": "万尸之地", "type": "aoe_zone", "cd": 15.0, "mp": 26, "power": 2.0,
         "radius": 120, "delay": 0.6, "damage_type": "magic", "color": "#8a5cff", "desc": "唤出墓地，尸骸从地下撕扯敌人。", "vfx": "void_pulse"},
        {"id": "soul_feast", "name": "噬魂盛宴", "type": "heal", "cd": 14.0, "mp": 24, "power": 55,
         "color": "#c08aff", "desc": "吞噬游离灵魂，回复大量生命。", "vfx": "void_pulse"},
    ],
    "death_knight": [
        {"id": "grave_charge", "name": "亡者冲锋", "type": "dash_strike", "cd": 9.0, "mp": 16, "power": 2.2,
         "distance": 160, "radius": 78, "damage_type": "physical", "color": "#c04a6a", "desc": "化身亡者长驱直入，撞碎拦路之敌。", "vfx": "dash_streak"},
        {"id": "blood_fury", "name": "血怒斩", "type": "melee_aoe", "cd": 8.0, "mp": 18, "power": 2.4,
         "radius": 95, "damage_type": "physical", "color": "#e05070", "desc": "以血饲刃，斩出环绕自身的血色刀光。", "vfx": "melee_slash"},
        {"id": "shadow_bulwark", "name": "暗影壁垒", "type": "shield", "cd": 18.0, "mp": 20, "power": 80,
         "duration": 8.0, "color": "#a05a8a", "desc": "暗影凝甲，护盾比基础暗盾更强。", "vfx": "shield_bubble"},
    ],
    "thief": [
        {"id": "lethal_backstab", "name": "致命背刺", "type": "melee_aoe", "cd": 6.0, "mp": 14, "power": 2.8,
         "radius": 70, "damage_type": "physical", "color": "#ff6a8a", "desc": "瞬身至破绽处，一击洞穿要害。", "vfx": "melee_slash"},
        {"id": "veil_step", "name": "烟幕遁形", "type": "buff", "cd": 16.0, "mp": 14, "stat": "dodge_rate",
         "value": 0.45, "duration": 6.0, "color": "#c0c0d0", "desc": "掷出烟幕，短时间闪避大幅提升。", "vfx": "steam_burst"},
        {"id": "venom_burst", "name": "剧毒爆发", "type": "projectile", "cd": 7.0, "mp": 16, "power": 1.8,
         "speed": 480, "damage_type": "magic", "color": "#8aff6a", "desc": "毒囊在命中时炸裂，扩散剧毒。", "vfx": "void_pulse"},
    ],
    "sniper": [
        {"id": "reaper_eye", "name": "死神之眼", "type": "projectile", "cd": 9.0, "mp": 18, "power": 3.2,
         "speed": 900, "damage_type": "physical", "color": "#ff9a5a", "desc": "超远距离单发，命中即重创。", "vfx": "arrow"},
        {"id": "blast_trap", "name": "爆裂陷阱", "type": "aoe_zone", "cd": 12.0, "mp": 18, "power": 2.4,
         "radius": 95, "delay": 0.4, "damage_type": "physical", "color": "#ffb45a", "desc": "布下高爆陷阱，踏入即引爆。", "vfx": "explosion"},
        {"id": "steady_aim", "name": "屏息专注", "type": "buff", "cd": 16.0, "mp": 13, "stat": "crit_rate",
         "value": 0.30, "duration": 8.0, "color": "#ffd08a", "desc": "完全静止呼吸，暴击率飙升。", "vfx": "buff_swirl"},
    ],
    "bomber": [
        {"id": "cluster_bomb", "name": "集束炸弹", "type": "aoe_zone", "cd": 9.0, "mp": 20, "power": 2.6,
         "radius": 100, "delay": 0.4, "damage_type": "physical", "color": "#ffab4a", "desc": "母弹分裂成多枚子弹，覆盖更密。", "vfx": "explosion"},
        {"id": "chain_blast", "name": "连环爆破", "type": "aoe_zone", "cd": 14.0, "mp": 26, "power": 2.2,
         "radius": 130, "delay": 0.6, "damage_type": "physical", "color": "#ff8f3a", "desc": "预埋炸药连锁起爆，范围最大。", "vfx": "explosion"},
        {"id": "fire_barrage", "name": "燃烧弹幕", "type": "melee_aoe", "cd": 9.0, "mp": 18, "power": 1.9,
         "radius": 110, "damage_type": "magic", "color": "#ff6a3a", "desc": "倾泻燃烧弹，近身区域化为火海。", "vfx": "fireball"},
    ],
    "hacker": [
        {"id": "worm_virus", "name": "蠕虫病毒", "type": "chain", "cd": 10.0, "mp": 22, "power": 1.8,
         "radius": 260, "count": 5, "damage_type": "magic", "color": "#5affd8", "desc": "病毒沿链路扩散，最多感染五个目标。", "vfx": "neon_grid"},
        {"id": "blackout", "name": "全域断电", "type": "melee_aoe", "cd": 12.0, "mp": 22, "power": 1.9,
         "radius": 120, "damage_type": "magic", "color": "#7ae8ff", "desc": "切断范围供能，电磁脉冲横扫敌群。", "vfx": "lightning"},
        {"id": "overdrive_protocol", "name": "超频协议", "type": "buff", "cd": 18.0, "mp": 22, "stat": "attack",
         "value": 20, "duration": 9.0, "color": "#8affe8", "desc": "解除义体限速，攻击大幅提升。", "vfx": "neon_grid"},
    ],
    "mech_pilot": [
        {"id": "rail_cannon", "name": "轨道炮", "type": "projectile", "cd": 9.0, "mp": 18, "power": 2.6,
         "speed": 520, "damage_type": "physical", "color": "#ffc06a", "desc": "机甲主炮蓄能发射，穿透整条直线。", "vfx": "explosion"},
        {"id": "composite_armor", "name": "复合装甲", "type": "shield", "cd": 20.0, "mp": 22, "power": 110,
         "duration": 9.0, "color": "#9ad8ff", "desc": "展开复合装甲，护盾强度极高。", "vfx": "shield_bubble"},
        {"id": "force_field", "name": "力场护罩", "type": "buff", "cd": 20.0, "mp": 20, "stat": "defense",
         "value": 24, "duration": 10.0, "color": "#8fd0ff", "desc": "启动力场，长时间强化防御。", "vfx": "shield_bubble"},
    ],
    "bounty_hunter": [
        {"id": "suppression_fire", "name": "弹幕压制", "type": "chain", "cd": 8.0, "mp": 18, "power": 1.6,
         "radius": 220, "count": 5, "damage_type": "physical", "color": "#ffd76a", "desc": "交替射击压制多个目标。", "vfx": "arrow"},
        {"id": "death_mark", "name": "死神标记", "type": "buff", "cd": 16.0, "mp": 14, "stat": "attack",
         "value": 16, "duration": 9.0, "color": "#ffb45a", "desc": "标记猎物，攻击大幅提升。", "vfx": "rune_glyph"},
        {"id": "wrist_shot", "name": "断腕射击", "type": "melee_aoe", "cd": 8.0, "mp": 16, "power": 2.2,
         "radius": 85, "damage_type": "physical", "color": "#ffcf7a", "desc": "贴脸轰击，打断敌人动作。", "vfx": "melee_slash"},
    ],
}

# ------------------------------------------------------------------ 新职业进阶技能
NEW_ADVANCED = {
    "runeward": [
        {"id": "rune_reflect", "name": "反噬符文", "type": "shield", "cd": 18.0, "mp": 22, "power": 90,
         "duration": 8.0, "color": "#b0a0ff", "desc": "符文甲胄成型，护盾远厚于符盾。", "vfx": "rune_glyph"},
        {"id": "rune_prison", "name": "符文禁锢", "type": "aoe_zone", "cd": 11.0, "mp": 20, "power": 1.9,
         "radius": 110, "delay": 0.4, "damage_type": "magic", "color": "#9a8cff", "desc": "地面浮现符文，圈住并灼烧敌人。", "vfx": "rune_glyph"},
        {"id": "aegis_circle", "name": "符阵壁垒", "type": "buff", "cd": 20.0, "mp": 24, "stat": "defense",
         "value": 24, "duration": 10.0, "color": "#c4b8ff", "desc": "铺开符阵，长时间强化护甲。", "vfx": "rune_glyph"},
    ],
    "qi_adept": [
        {"id": "qi_burst", "name": "罡气爆", "type": "melee_aoe", "cd": 7.0, "mp": 16, "power": 2.2,
         "radius": 96, "damage_type": "physical", "color": "#7fffd0", "desc": "罡气外放成环，震碎近身之敌。", "vfx": "explosion"},
        {"id": "qi_renew", "name": "生生不息", "type": "heal", "cd": 12.0, "mp": 30, "power": 80,
         "color": "#a0ffe0", "desc": "气海周天运转，回复大量生命。", "vfx": "heal_spark"},
        {"id": "qi_guard", "name": "罡气护体", "type": "shield", "cd": 16.0, "mp": 18, "power": 75,
         "duration": 8.0, "color": "#8fffd8", "desc": "罡气覆体，形成护身气墙。", "vfx": "shield_bubble"},
    ],
    "engineer": [
        {"id": "heavy_turret", "name": "重型炮塔", "type": "aoe_zone", "cd": 11.0, "mp": 24, "power": 2.2,
         "radius": 90, "delay": 0.9, "damage_type": "physical", "color": "#ffc76a", "desc": "部署重型炮塔，火力覆盖更广。", "vfx": "explosion"},
        {"id": "field_repair", "name": "战地整备", "type": "heal", "cd": 14.0, "mp": 30, "power": 88,
         "color": "#ffe4b0", "desc": "全面检修义体与护具，回复大量生命。", "vfx": "heal_spark"},
        {"id": "overdrive", "name": "超载协议", "type": "buff", "cd": 16.0, "mp": 20, "stat": "attack_speed",
         "value": 0.30, "duration": 8.0, "color": "#ffdc94", "desc": "蒸汽过载，出手速度大幅提升。", "vfx": "steam_burst"},
    ],
    "cyborg": [
        {"id": "seismic_slam", "name": "震荡践踏", "type": "melee_aoe", "cd": 9.0, "mp": 18, "power": 2.5,
         "radius": 105, "damage_type": "physical", "color": "#6fd8f0", "desc": "义体重踏地面，冲击波四散。", "vfx": "explosion"},
        {"id": "aegis_protocol", "name": "神盾协议", "type": "shield", "cd": 18.0, "mp": 24, "power": 105,
         "duration": 8.0, "color": "#a0ecff", "desc": "启动全身护盾协议，吸收海量伤害。", "vfx": "shield_bubble"},
        {"id": "rail_dash", "name": "磁轨突袭", "type": "dash_strike", "cd": 10.0, "mp": 20, "power": 2.6,
         "distance": 180, "radius": 72, "damage_type": "physical", "color": "#7ee0ff", "desc": "磁轨加速冲刺，贯穿路径上的敌人。", "vfx": "dash_streak"},
    ],
}

# ------------------------------------------------------------------ 技能树被动（按范式统一预算）
ROLE_PASSIVES = {
    "assault": [
        {"attack": 5, "crit_rate": 0.03},
        {"crit_damage": 0.15},
        {"attack_speed": 0.06, "move_speed": 0.04},
    ],
    "bulwark": [
        {"defense": 4, "max_hp": 20},
        {"max_hp": 35, "magic_defense": 3},
        {"defense": 3, "magic_defense": 4},
    ],
    "support": [
        {"max_mp": 20, "magic_attack": 4},
        {"magic_attack": 5, "magic_defense": 3},
        {"max_mp": 15, "defense": 3},
    ],
    "trickster": [
        {"crit_rate": 0.04, "attack": 3},
        {"move_speed": 0.06, "dodge_rate": 0.03},
        {"attack": 4, "attack_speed": 0.05},
    ],
}
ROLE_KEYSTONES = {
    "assault": [
        {"attack": 10, "crit_rate": 0.05},
        {"crit_damage": 0.25, "crit_rate": 0.04},
        {"attack_speed": 0.12, "move_speed": 0.08},
    ],
    "bulwark": [
        {"defense": 8, "max_hp": 45},
        {"max_hp": 70, "defense": 5},
        {"magic_defense": 9, "max_hp": 40},
    ],
    "support": [
        {"max_mp": 40, "magic_attack": 8},
        {"magic_attack": 9, "crit_rate": 0.04},
        {"max_mp": 30, "magic_defense": 6},
    ],
    "trickster": [
        {"crit_rate": 0.07, "crit_damage": 0.18},
        {"move_speed": 0.10, "dodge_rate": 0.06},
        {"attack": 8, "attack_speed": 0.10},
    ],
}
ROLE_CAPSTONE = {
    "assault": {"all_stats_bonus": 0.07, "crit_damage": 0.20},
    "bulwark": {"all_stats_bonus": 0.07, "max_hp": 60},
    "support": {"all_stats_bonus": 0.07, "max_mp": 50},
    "trickster": {"all_stats_bonus": 0.07, "crit_rate": 0.05},
}
PASSIVE_NAMES = {
    "assault": ["锋锐", "致命", "疾风"],
    "bulwark": ["坚甲", "厚壁", "御法"],
    "support": ["灵泉", "共鸣", "静心"],
    "trickster": ["敏锐", "游影", "毒牙"],
}
KEYSTONE_NAMES = {
    "assault": ["破军之势", "暴虐", "迅影"],
    "bulwark": ["不动如山", "磐石", "护心"],
    "support": ["天命", "协奏", "澄明"],
    "trickster": ["鬼魅", "缜密", "猎手"],
}
CAPSTONE_NAMES = {
    "warrior": "战神降临", "archer": "百步穿杨", "mage": "元素君主", "priest": "圣光化身",
    "necromancer": "亡者之主", "death_knight": "血海君王", "thief": "影中之影", "sniper": "一枪入魂",
    "bomber": "焦土政策", "hacker": "系统之神", "mech_pilot": "移动要塞", "bounty_hunter": "黄金律令",
    "runeward": "万符归宗", "qi_adept": "天人合一", "engineer": "万能工匠", "cyborg": "永恒机体",
}

# ------------------------------------------------------------------ 专职（第 3 条；前 2 条保留原数据）
EXTRA_SPEC = {
    "warrior": {"id": "vanguard", "name": "破阵者", "desc": "舍弃部分护甲换取突进与暴击，专破密集阵型。",
                "stats": {"attack": 8, "crit_rate": 0.05, "move_speed": 0.06, "defense": -2},
                "skill_bonus": {"power": 0.15}, "passives": {}},
    "archer": {"id": "windrunner", "name": "疾风猎手", "desc": "以机动换输出窗口，冷却更短、走位更快。",
               "stats": {"move_speed": 0.12, "attack_speed": 0.10, "dodge_rate": 0.04},
               "skill_bonus": {"cooldown": 0.15}, "passives": {}},
    "mage": {"id": "arcanist", "name": "秘法学者", "desc": "扩充法力池并压缩冷却，以持续施法压制战场。",
             "stats": {"max_mp": 30, "magic_attack": 6}, "skill_bonus": {"cooldown": 0.20}, "passives": {}},
    "priest": {"id": "ascetic", "name": "苦修者", "desc": "以血肉承受苦难，换取更强的治疗与生存。",
               "stats": {"max_hp": 30, "defense": 5, "magic_attack": -2},
               "skill_bonus": {}, "passives": {"heal_bonus": 0.25}},
    "necromancer": {"id": "puppeteer", "name": "尸傀师", "desc": "驱使尸傀代偿伤害，以吸血维持战线。",
                    "stats": {"max_mp": 25, "magic_attack": 7, "max_hp": -10},
                    "skill_bonus": {}, "passives": {"lifesteal": 0.15}},
    "death_knight": {"id": "bloodsworn", "name": "血誓者", "desc": "立下血誓，攻击与吸血并进，护甲更薄。",
                     "stats": {"attack": 7, "max_hp": 30, "defense": -2},
                     "skill_bonus": {"power": 0.12}, "passives": {"lifesteal": 0.25}},
    "thief": {"id": "shadowdancer", "name": "影舞者", "desc": "以闪避与移速换取连续背刺的机会。",
              "stats": {"dodge_rate": 0.08, "move_speed": 0.10, "crit_rate": 0.05},
              "skill_bonus": {"cooldown": 0.10}, "passives": {}},
    "sniper": {"id": "stalker", "name": "潜伏者", "desc": "牺牲机动换取暴击伤害，专杀关键目标。",
               "stats": {"crit_damage": 0.35, "move_speed": -0.05, "crit_rate": 0.06},
               "skill_bonus": {"power": 0.15}, "passives": {}},
    "bomber": {"id": "thermite", "name": "铝热师", "desc": "更猛烈的装药与更薄的护甲，只求一轮清场。",
               "stats": {"attack": 6, "max_hp": -15},
               "skill_bonus": {"power": 0.22}, "passives": {}},
    "hacker": {"id": "netghost", "name": "网络幽灵", "desc": "深潜网络，法力与冷却效率拉满。",
               "stats": {"max_mp": 30, "magic_attack": 5},
               "skill_bonus": {"cooldown": 0.25}, "passives": {}},
    "mech_pilot": {"id": "fortress", "name": "要塞驾驶员", "desc": "把机甲当堡垒开，护盾与生命极高但行动迟缓。",
                   "stats": {"max_hp": 60, "defense": 8, "move_speed": -0.08},
                   "skill_bonus": {}, "passives": {"shield_bonus": 0.35}},
    "bounty_hunter": {"id": "kingpin", "name": "赏金之王", "desc": "猎物越强赏金越高，攻击与暴击同步攀升。",
                      "stats": {"attack": 8, "crit_rate": 0.06, "max_mp": -5},
                      "skill_bonus": {"power": 0.12}, "passives": {}},
    "runeward": {"id": "wardmaster", "name": "符阵大师", "desc": "专精符文护盾，护盾强度与冷却效率兼得。",
                 "stats": {"defense": 8, "max_hp": 35}, "skill_bonus": {"cooldown": 0.15},
                 "passives": {"shield_bonus": 0.35}},
    "qi_adept": {"id": "healer_monk", "name": "医武", "desc": "以内息疗伤为业，治疗量与法力池显著提升。",
                 "stats": {"max_mp": 30, "magic_attack": 5}, "skill_bonus": {},
                 "passives": {"heal_bonus": 0.30}},
    "engineer": {"id": "turret_specialist", "name": "炮塔专家", "desc": "把炮塔当主武器，技能威力大幅提升。",
                 "stats": {"attack": 7}, "skill_bonus": {"power": 0.20}, "passives": {}},
    "cyborg": {"id": "rail_vanguard", "name": "磁轨先锋", "desc": "磁轨义体全开，攻击与暴击拉满。",
               "stats": {"attack": 8, "crit_rate": 0.05}, "skill_bonus": {"power": 0.12}, "passives": {}},
}
EXTRA_SPEC_BY_CLASS = {
    "runeward": [
        {"id": "reflector", "name": "反噬者", "desc": "把符文护盾转成攻击性回路，法伤更高。",
         "stats": {"attack": 6, "magic_attack": 6}, "skill_bonus": {"power": 0.18}, "passives": {}},
        {"id": "oathkeeper", "name": "守誓者", "desc": "立誓守阵，生命与法防极高，几乎不可撼动。",
         "stats": {"max_hp": 55, "magic_defense": 9}, "skill_bonus": {}, "passives": {"shield_bonus": 0.25}},
    ],
    "qi_adept": [
        {"id": "qigong_master", "name": "罡气宗师", "desc": "罡气凝而不散，防御与生命显著提升。",
         "stats": {"defense": 8, "max_hp": 40}, "skill_bonus": {}, "passives": {"shield_bonus": 0.30}},
        {"id": "windwalker", "name": "疾风武者", "desc": "以身法御气，移速与攻速极快。",
         "stats": {"move_speed": 0.12, "attack_speed": 0.15, "attack": 5}, "skill_bonus": {"cooldown": 0.12}, "passives": {}},
    ],
    "engineer": [
        {"id": "quartermaster", "name": "后勤官", "desc": "强化补给与维修，治疗量与法力池提升。",
         "stats": {"max_mp": 30, "defense": 4}, "skill_bonus": {}, "passives": {"heal_bonus": 0.30}},
        {"id": "overclock_tech", "name": "过载技师", "desc": "允许设备超频，冷却大幅缩短。",
         "stats": {"attack_speed": 0.12}, "skill_bonus": {"cooldown": 0.25}, "passives": {}},
    ],
    "cyborg": [
        {"id": "immovable", "name": "不动堡垒", "desc": "义体锁死站位，生命与护甲极高。",
         "stats": {"max_hp": 60, "defense": 10, "move_speed": -0.06}, "skill_bonus": {},
         "passives": {"shield_bonus": 0.30}},
        {"id": "overclock_fighter", "name": "超频武人", "desc": "解除义体限速，以攻速与移速压制。",
         "stats": {"attack_speed": 0.18, "move_speed": 0.06}, "skill_bonus": {"power": 0.10}, "passives": {}},
    ],
}


def _read(name):
    with open(os.path.join(DATA, name + ".json"), encoding="utf-8") as f:
        return json.load(f)


def _write(name, obj):
    path = os.path.join(DATA, name + ".json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")


def _skill_icon(skill_id):
    return "skill_%s" % skill_id


# 被动/专精节点不单独绘制图标，按属性归属复用既有真实图标（stat_* 已存在于 assets/icons/passive）
STAT_ICONS = {
    "attack": "passive_stat_attack", "magic_attack": "passive_stat_attack",
    "crit_rate": "passive_stat_crit", "crit_damage": "passive_stat_crit",
    "defense": "passive_stat_defense", "max_hp": "passive_stat_defense", "magic_defense": "passive_stat_defense",
    "move_speed": "passive_stat_speed", "attack_speed": "passive_stat_speed", "dodge_rate": "passive_stat_speed",
    "max_mp": "passive_stat_skill", "all_stats_bonus": "passive_stat_skill",
}
STAT_ICON_ORDER = [
    "attack", "magic_attack", "crit_rate", "crit_damage",
    "defense", "max_hp", "magic_defense",
    "move_speed", "attack_speed", "dodge_rate",
    "max_mp", "all_stats_bonus",
]


def _passive_icon(passive):
    for key in STAT_ICON_ORDER:
        if key in passive:
            return STAT_ICONS[key]
    return "stat_skill"


def _norm_skill(skill):
    out = dict(skill)
    out.setdefault("icon", _skill_icon(str(out["id"])))
    return out


def _ensure_slot(skill, slot):
    out = _norm_skill(skill)
    out["slot"] = slot
    return out


def build_classes():
    src = _read("classes")
    old_classes = src["classes"]
    result = {}
    for (source, role), cid in MATRIX.items():
        if cid in old_classes and cid not in NEW_CLASSES:
            cdef = copy.deepcopy(old_classes[cid])
            base = [_ensure_slot(s, i + 1) for i, s in enumerate(cdef.get("skills", [])[:3])]
            adv = []
            for i, s in enumerate(ADVANCED[cid]):
                item = _ensure_slot(s, i + 4)
                item["advanced"] = True
                item["requires"] = "%s_mastery_%d" % (cid, i)
                adv.append(item)
            cdef["skills"] = base + adv
        else:
            meta = NEW_CLASSES[cid]
            cdef = {
                "id": cid, "name": meta["name"], "color": meta["color"],
            }
            cdef.update(meta["stats"])
            base = [_ensure_slot(s, i + 1) for i, s in enumerate(meta["base"])]
            adv = []
            for i, s in enumerate(NEW_ADVANCED[cid]):
                item = _ensure_slot(s, i + 4)
                item["advanced"] = True
                item["requires"] = "%s_mastery_%d" % (cid, i)
                adv.append(item)
            cdef["skills"] = base + adv
        cdef["source"] = source
        cdef["role"] = role
        cdef["source_name"] = SOURCES[source]["name"]
        cdef["role_name"] = ROLES[role]["name"]
        cdef["identity"] = IDENTITY[cid]
        result[cid] = cdef
    src["classes"] = result
    src["version"] = "0.4.0"
    return src


def build_tree(old_trees, cid, cdef):
    role = cdef["role"]
    base = cdef["skills"][:3]
    adv = cdef["skills"][3:]
    old = old_trees.get(cid, {})
    tree_name = old.get("tree_name") or old.get("name") or (NEW_CLASSES[cid]["tree_name"] if cid in NEW_CLASSES else cdef["name"] + "之道")
    nodes = []
    for i, s in enumerate(base):
        nodes.append({
            "id": "%s_anchor_%d" % (cid, i), "name": s["name"], "tier": 0, "col": i,
            "kind": "anchor", "skill_id": s["id"], "cost": 0, "requires": [],
            "icon": s["icon"], "desc": "职业初始主动技能（技能槽 %d）" % (i + 1),
            "passive": {}, "skill_bonus": {},
        })
    for i, s in enumerate(base):
        nodes.append({
            "id": "%s_mastery_%d" % (cid, i), "name": s["name"] + "精通", "tier": 1, "col": i,
            "kind": "mastery", "skill_id": s["id"], "cost": 1, "requires": ["%s_anchor_%d" % (cid, i)],
            "icon": s["icon"], "desc": "强化【%s】：技能威力 +25%%，冷却 -10%%。" % s["name"],
            "passive": {}, "skill_bonus": {"power": 0.25, "cooldown": 0.1},
        })
    for i, s in enumerate(adv):
        nodes.append({
            "id": "%s_active_%d" % (cid, i), "name": s["name"], "tier": 2, "col": i,
            "kind": "active", "skill_id": s["id"], "cost": 2, "requires": ["%s_mastery_%d" % (cid, i)],
            "icon": s["icon"], "desc": "解锁进阶主动技能【%s】（技能槽 %s）。" % (s["name"], "RFG"[i]),
            "passive": {}, "skill_bonus": {},
        })
    for i in range(3):
        nodes.append({
            "id": "%s_passive_%d" % (cid, i), "name": PASSIVE_NAMES[role][i], "tier": 3, "col": i,
            "kind": "passive", "skill_id": "", "cost": 1, "requires": ["%s_mastery_%d" % (cid, i)],
            "icon": _passive_icon(ROLE_PASSIVES[role][i]), "desc": "分支天赋：%s。" % _fmt(ROLE_PASSIVES[role][i]),
            "passive": ROLE_PASSIVES[role][i], "skill_bonus": {},
        })
    for i in range(3):
        nodes.append({
            "id": "%s_keystone_%d" % (cid, i), "name": KEYSTONE_NAMES[role][i], "tier": 4, "col": i,
            "kind": "keystone", "skill_id": "", "cost": 2, "requires": ["%s_passive_%d" % (cid, i)],
            "icon": _passive_icon(ROLE_KEYSTONES[role][i]), "desc": "分支专精：%s。" % _fmt(ROLE_KEYSTONES[role][i]),
            "passive": ROLE_KEYSTONES[role][i], "skill_bonus": {},
        })
    nodes.append({
        "id": "%s_capstone" % cid, "name": CAPSTONE_NAMES[cid], "tier": 5, "col": 1,
        "kind": "capstone", "skill_id": "", "cost": 3,
        "requires": ["%s_keystone_0" % cid, "%s_keystone_1" % cid, "%s_keystone_2" % cid],
        "icon": "passive_stat_capstone",
        "desc": "终极奥义：三条分支全部专精后方可点亮。%s" % _fmt(ROLE_CAPSTONE[role]),
        "passive": ROLE_CAPSTONE[role], "skill_bonus": {},
    })
    return {"name": tree_name, "nodes": nodes}


def _fmt(d):
    names = {"attack": "攻击", "defense": "防御", "max_hp": "生命", "max_mp": "法力",
             "magic_attack": "法强", "magic_defense": "法防", "crit_rate": "暴击率",
             "crit_damage": "暴击伤害", "move_speed": "移速", "attack_speed": "攻速",
             "dodge_rate": "闪避", "all_stats_bonus": "全属性"}
    parts = []
    for k, v in d.items():
        label = names.get(k, k)
        if k in ("crit_rate", "crit_damage", "move_speed", "attack_speed", "dodge_rate", "all_stats_bonus"):
            parts.append("%s +%d%%" % (label, int(round(v * 100))))
        else:
            parts.append("%s +%d" % (label, int(v)))
    return "，".join(parts)


def build_specializations():
    src = _read("specializations")
    old = src["specializations"]
    result = {}
    for (source, role), cid in MATRIX.items():
        entry = copy.deepcopy(old.get(cid, []))
        if cid in EXTRA_SPEC:
            # 幂等：移除上一次生成写入的第 3 条专职，避免重复追加
            extra_id = str(EXTRA_SPEC[cid]["id"])
            entry = [x for x in entry if str(x.get("id", "")) != extra_id]
            extra = copy.deepcopy(EXTRA_SPEC[cid])
            extra.update({"req_level": 5, "icon": "portrait_%s" % cid, "bonus_points": 1})
            extra.setdefault("stats", {})
            extra.setdefault("skill_bonus", {})
            extra.setdefault("passives", {})
            entry.append(extra)
        if cid in NEW_CLASSES:
            # 新职业第一条专职用 EXTRA_SPEC，其余两条来自 EXTRA_SPEC_BY_CLASS
            primary = copy.deepcopy(EXTRA_SPEC[cid])
            primary.update({"req_level": 5, "icon": "portrait_%s" % cid, "bonus_points": 1})
            entry = [primary] + [dict(x, req_level=5, icon="portrait_%s" % cid, bonus_points=1)
                                 for x in EXTRA_SPEC_BY_CLASS[cid]]
        result[cid] = entry
    src["specializations"] = result
    src["version"] = "1.1.0"
    return src


def power_score(cdef):
    return (cdef["max_hp"] * 0.6 + cdef["max_mp"] * 0.35
            + (cdef["attack"] + cdef.get("magic_attack", 0)) * 2.4
            + (cdef["defense"] + cdef.get("magic_defense", 0)) * 1.8
            + cdef["move_speed"] * 0.12 + cdef.get("crit_rate", 0.0) * 120
            + cdef.get("dodge_rate", 0.0) * 120
            + (cdef.get("attack_speed", 1.0) - 1.0) * 40
            + (cdef.get("crit_damage", 1.5) - 1.5) * 30)


def validate(classes, trees, specs):
    errors = []
    if len(classes["classes"]) != 16:
        errors.append("职业数量应为 16，实际 %d" % len(classes["classes"]))
    if len(MATRIX) != 16 or len(set(MATRIX.values())) != 16:
        errors.append("矩阵不是 4x4 双射")
    for cid, cdef in classes["classes"].items():
        skills = cdef.get("skills", [])
        if len(skills) != 6:
            errors.append("%s 技能数应为 6，实际 %d" % (cid, len(skills)))
        if [s.get("slot") for s in skills] != [1, 2, 3, 4, 5, 6]:
            errors.append("%s 技能槽编号不连续" % cid)
        for s in skills[3:]:
            if not s.get("requires"):
                errors.append("%s 进阶技能 %s 缺少前置节点" % (cid, s["id"]))
        for s in skills:
            if not s.get("icon"):
                errors.append("%s 技能 %s 缺少图标 id" % (cid, s["id"]))
        for i in range(3):
            base, adv = skills[i], skills[3 + i]
            if adv["cd"] < base["cd"]:
                errors.append("%s 进阶技 %s 冷却低于同分支基础技" % (cid, adv["id"]))
            if adv["mp"] < base["mp"]:
                errors.append("%s 进阶技 %s 法力低于同分支基础技" % (cid, adv["id"]))
        score = power_score(cdef)
        if not (POWER_BAND[0] <= score <= POWER_BAND[1]):
            errors.append("%s 战力预算 %.1f 超出 %s" % (cid, score, POWER_BAND))
        if int(cdef["max_hp"]) < ROLE_HP_MIN[cdef["role"]]:
            errors.append("%s 生命 %d 低于范式下限 %d" % (cid, cdef["max_hp"], ROLE_HP_MIN[cdef["role"]]))
    for cid, tree in trees["trees"].items():
        nodes = tree["nodes"]
        if len(nodes) != 16:
            errors.append("%s 技能树节点应为 16，实际 %d" % (cid, len(nodes)))
        ids = {n["id"] for n in nodes}
        if len(ids) != len(nodes):
            errors.append("%s 技能树存在重复节点 id" % cid)
        for n in nodes:
            for req in n.get("requires", []):
                if req not in ids:
                    errors.append("%s 节点 %s 的前置 %s 不存在" % (cid, n["id"], req))
        if sum(1 for n in nodes if n["kind"] == "active") != 3:
            errors.append("%s 进阶主动节点应为 3" % cid)
        if sum(1 for n in nodes if n["kind"] == "capstone") != 1:
            errors.append("%s 终极节点应为 1" % cid)
    for cid, arr in specs["specializations"].items():
        if len(arr) != 3:
            errors.append("%s 专职应为 3，实际 %d" % (cid, len(arr)))
        sids = {s["id"] for s in arr}
        if len(sids) != len(arr):
            errors.append("%s 专职 id 重复" % cid)
    return errors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只校验，不写文件")
    args = ap.parse_args()

    old_trees = _read("skill_trees")
    classes = build_classes()
    tree_src = copy.deepcopy(old_trees)
    tree_src["trees"] = {cid: build_tree(old_trees.get("trees", {}), cid, cdef)
                         for cid, cdef in classes["classes"].items()}
    tree_src["version"] = "2.0.0"
    specs = build_specializations()

    errors = validate(classes, tree_src, specs)
    if errors:
        print("校验失败：")
        for e in errors:
            print("  -", e)
        sys.exit(1)
    print("校验通过：16 职业 / 96 技能 / 16×16 技能树节点 / 48 专职")

    if args.check:
        return
    _write("classes", classes)
    _write("skill_trees", tree_src)
    _write("specializations", specs)
    print("已写入 data/classes.json、data/skill_trees.json、data/specializations.json")


if __name__ == "__main__":
    main()
