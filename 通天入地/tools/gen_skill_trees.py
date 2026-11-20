#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 data/skill_trees.json 与 data/specializations.json

技能树结构（每个职业 8 个节点）：
  tier0 × 3  初始技能锚点（自动解锁，代表该职业三个主动技能）
  tier1 × 3  技能精通（消耗 1 点，提升对应技能威力与冷却）
  tier2 × 2  被动天赋（消耗 2 点，需两处精通）
  tier3 × 1  终极天赋（消耗 3 点，需两处被动）
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 每个职业：passive_a / passive_b / capstone 的中文文案与数值
CLASS_TREE = {
    "warrior": {
        "a": ("破军", "攻击 +6，暴击率 +3%", {"attack": 6, "crit_rate": 0.03}),
        "b": ("铁壁", "防御 +5，生命上限 +25", {"defense": 5, "max_hp": 25}),
        "c": ("战神降临", "全属性 +6%，攻速 +10%", {"all_stats_bonus": 0.06, "attack_speed": 0.10}),
    },
    "archer": {
        "a": ("鹰眼校准", "暴击率 +5%，暴击伤害 +15%", {"crit_rate": 0.05, "crit_damage": 0.15}),
        "b": ("轻甲", "移动速度 +12%，闪避率 +4%", {"move_speed": 0.12, "dodge_rate": 0.04}),
        "c": ("百步穿杨", "全属性 +6%，暴击伤害 +25%", {"all_stats_bonus": 0.06, "crit_damage": 0.25}),
    },
    "mage": {
        "a": ("魔力灌注", "魔法攻击 +6，魔力上限 +20", {"magic_attack": 6, "max_mp": 20}),
        "b": ("奥术屏障", "魔法防御 +5，闪避率 +3%", {"magic_defense": 5, "dodge_rate": 0.03}),
        "c": ("元素宗师", "全属性 +6%，魔法攻击 +10", {"all_stats_bonus": 0.06, "magic_attack": 10}),
    },
    "priest": {
        "a": ("圣光涌流", "魔力上限 +25，魔法防御 +4", {"max_mp": 25, "magic_defense": 4}),
        "b": ("慈悯", "生命上限 +30，防御 +4", {"max_hp": 30, "defense": 4}),
        "c": ("神佑", "全属性 +6%，生命上限 +50", {"all_stats_bonus": 0.06, "max_hp": 50}),
    },
    "necromancer": {
        "a": ("亡魂契约", "魔法攻击 +6，魔力上限 +18", {"magic_attack": 6, "max_mp": 18}),
        "b": ("腐化", "攻击 +5，暴击率 +3%", {"attack": 5, "crit_rate": 0.03}),
        "c": ("死灵统御", "全属性 +6%，魔法防御 +8", {"all_stats_bonus": 0.06, "magic_defense": 8}),
    },
    "death_knight": {
        "a": ("血之渴望", "攻击 +7，生命上限 -15", {"attack": 7, "max_hp": -15}),
        "b": ("亡者壁垒", "防御 +6，闪避率 +3%", {"defense": 6, "dodge_rate": 0.03}),
        "c": ("不朽骑士", "全属性 +7%，生命上限 +60", {"all_stats_bonus": 0.07, "max_hp": 60}),
    },
    "thief": {
        "a": ("暗影步", "移动速度 +15%，闪避率 +5%", {"move_speed": 0.15, "dodge_rate": 0.05}),
        "b": ("淬毒", "攻击 +5，暴击率 +4%", {"attack": 5, "crit_rate": 0.04}),
        "c": ("千面", "全属性 +6%，暴击伤害 +20%", {"all_stats_bonus": 0.06, "crit_damage": 0.20}),
    },
    "sniper": {
        "a": ("致命瞄准", "暴击率 +6%，暴击伤害 +20%", {"crit_rate": 0.06, "crit_damage": 0.20}),
        "b": ("稳固据守", "防御 +5，攻击速度 +10%", {"defense": 5, "attack_speed": 0.10}),
        "c": ("死神凝视", "全属性 +6%，暴击率 +8%", {"all_stats_bonus": 0.06, "crit_rate": 0.08}),
    },
    "bomber": {
        "a": ("烈性装药", "攻击 +6，暴击率 +3%", {"attack": 6, "crit_rate": 0.03}),
        "b": ("厚甲工装", "防御 +6，生命上限 +30", {"defense": 6, "max_hp": 30}),
        "c": ("连环爆破", "全属性 +6%，攻速 +12%", {"all_stats_bonus": 0.06, "attack_speed": 0.12}),
    },
    "hacker": {
        "a": ("神经超频", "攻速 +12%，移动速度 +10%", {"attack_speed": 0.12, "move_speed": 0.10}),
        "b": ("数据护盾", "防御 +5，闪避率 +4%", {"defense": 5, "dodge_rate": 0.04}),
        "c": ("量子掌控", "全属性 +6%，魔法攻击 +8", {"all_stats_bonus": 0.06, "magic_attack": 8}),
    },
    "mech_pilot": {
        "a": ("重装弹链", "攻击 +6，暴击率 +3%", {"attack": 6, "crit_rate": 0.03}),
        "b": ("装甲协议", "防御 +6，生命上限 +35", {"defense": 6, "max_hp": 35}),
        "c": ("泰坦协议", "全属性 +7%，生命上限 +70", {"all_stats_bonus": 0.07, "max_hp": 70}),
    },
    "bounty_hunter": {
        "a": ("赏金直觉", "攻击 +6，暴击率 +4%", {"attack": 6, "crit_rate": 0.04}),
        "b": ("战术机动", "移动速度 +12%，闪避率 +4%", {"move_speed": 0.12, "dodge_rate": 0.04}),
        "c": ("死亡凝视", "全属性 +6%，暴击伤害 +25%", {"all_stats_bonus": 0.06, "crit_damage": 0.25}),
    },
}

# 每个职业两个专职分支
SPECIALIZATIONS = {
    "warrior": [
        {"id": "berserker", "name": "狂战士", "desc": "以血换命：攻击大幅提升但承受更重的伤害，技能威力更强。",
         "stats": {"attack": 10, "crit_rate": 0.05, "max_hp": -30, "defense": -3},
         "skill_bonus": {"power": 0.20, "cooldown": 0.05}, "passives": {"lifesteal": 0.20}},
        {"id": "swordsman", "name": "剑圣", "desc": "攻防一体：护盾更厚、技能冷却更短，依靠格挡取胜。",
         "stats": {"defense": 8, "max_hp": 40, "attack_speed": 0.10},
         "skill_bonus": {"power": 0.10, "cooldown": 0.20}, "passives": {"shield_bonus": 0.30}},
    ],
    "archer": [
        {"id": "sharpshooter", "name": "神射手", "desc": "远程极限：暴击与射程拉满，箭雨覆盖更广。",
         "stats": {"crit_rate": 0.07, "crit_damage": 0.25, "move_speed": -0.05},
         "skill_bonus": {"power": 0.18}, "passives": {}},
        {"id": "ranger", "name": "游侠", "desc": "灵活作战：移速与闪避大幅提升，技能冷却缩短。",
         "stats": {"move_speed": 0.18, "dodge_rate": 0.06, "attack": 2},
         "skill_bonus": {"cooldown": 0.25}, "passives": {}},
    ],
    "mage": [
        {"id": "pyromancer", "name": "炎术士", "desc": "焚尽一切：魔法攻击极高，火球命中后引发灼烧。",
         "stats": {"magic_attack": 12, "max_mp": -10},
         "skill_bonus": {"power": 0.25}, "passives": {"burn": 0.20}},
        {"id": "cryomancer", "name": "霜法师", "desc": "寒冰掌控：冰霜新星范围更大，护盾更厚。",
         "stats": {"magic_defense": 8, "max_mp": 20},
         "skill_bonus": {"power": 0.10, "cooldown": 0.15}, "passives": {"shield_bonus": 0.25}},
    ],
    "priest": [
        {"id": "oracle", "name": "神谕者", "desc": "神谕之力：治疗与法强提升，魔力池更深。",
         "stats": {"magic_attack": 8, "max_mp": 30},
         "skill_bonus": {"power": 0.15, "cooldown": 0.10}, "passives": {"heal_bonus": 0.20}},
        {"id": "templar", "name": "圣殿骑士", "desc": "以盾卫道：防御与生命提升，护盾效果更强。",
         "stats": {"defense": 8, "max_hp": 45},
         "skill_bonus": {"power": 0.05}, "passives": {"shield_bonus": 0.35}},
    ],
    "necromancer": [
        {"id": "reaper", "name": "收割者", "desc": "收割灵魂：伤害提升并通过汲取回血。",
         "stats": {"magic_attack": 9, "max_hp": -10},
         "skill_bonus": {"power": 0.20}, "passives": {"lifesteal": 0.18}},
        {"id": "plague", "name": "瘟疫术士", "desc": "疫病蔓延：持续伤害更强，魔力上限提升。",
         "stats": {"magic_attack": 6, "max_mp": 30},
         "skill_bonus": {"power": 0.12, "cooldown": 0.15}, "passives": {}},
    ],
    "death_knight": [
        {"id": "bloodknight", "name": "血骑", "desc": "饮血而生：攻击极高，技能吸血。",
         "stats": {"attack": 12, "max_hp": -20},
         "skill_bonus": {"power": 0.22}, "passives": {"lifesteal": 0.22}},
        {"id": "tombguard", "name": "墓卫", "desc": "死亡壁垒：极高防御与生命，冷却更短。",
         "stats": {"defense": 10, "max_hp": 60},
         "skill_bonus": {"cooldown": 0.20}, "passives": {"shield_bonus": 0.30}},
    ],
    "thief": [
        {"id": "assassin", "name": "刺客", "desc": "一击致命：暴击率与暴击伤害极高。",
         "stats": {"crit_rate": 0.08, "crit_damage": 0.3, "attack": 4},
         "skill_bonus": {"power": 0.15}, "passives": {}},
        {"id": "shadow", "name": "影行者", "desc": "无处可寻：移速与闪避拉满，冷却大幅缩短。",
         "stats": {"move_speed": 0.20, "dodge_rate": 0.07},
         "skill_bonus": {"cooldown": 0.25}, "passives": {}},
    ],
    "sniper": [
        {"id": "marksman", "name": "狙击手", "desc": "一击必杀：暴击与射程达到极限。",
         "stats": {"crit_rate": 0.09, "crit_damage": 0.35, "move_speed": -0.05},
         "skill_bonus": {"power": 0.22}, "passives": {}},
        {"id": "trapmaster", "name": "陷阱大师", "desc": "工程布防：防御提升，陷阱伤害更高、冷却更短。",
         "stats": {"defense": 6, "max_hp": 25},
         "skill_bonus": {"power": 0.12, "cooldown": 0.25}, "passives": {}},
    ],
    "bomber": [
        {"id": "demolitionist", "name": "爆破专家", "desc": "极端火力：攻击极高，装药伤害翻倍。",
         "stats": {"attack": 12, "max_hp": -15},
         "skill_bonus": {"power": 0.25}, "passives": {}},
        {"id": "firefighter", "name": "纵火者", "desc": "持续灼烧：范围更大，冷却更短，自带护甲。",
         "stats": {"defense": 7, "max_hp": 35},
         "skill_bonus": {"power": 0.12, "cooldown": 0.20}, "passives": {}},
    ],
    "hacker": [
        {"id": "netrunner", "name": "网络行者", "desc": "入侵一切：法强与攻速提升，病毒蔓延更快。",
         "stats": {"magic_attack": 9, "attack_speed": 0.15},
         "skill_bonus": {"power": 0.18, "cooldown": 0.10}, "passives": {}},
        {"id": "ghost", "name": "幽灵", "desc": "无影无踪：闪避与移速极高，机动性拉满。",
         "stats": {"dodge_rate": 0.08, "move_speed": 0.18},
         "skill_bonus": {"cooldown": 0.25}, "passives": {}},
    ],
    "mech_pilot": [
        {"id": "juggernaut", "name": "重装机兵", "desc": "碾压：生命与防御极高，近战推进无惧。",
         "stats": {"max_hp": 80, "defense": 10, "move_speed": -0.08},
         "skill_bonus": {"power": 0.15}, "passives": {"shield_bonus": 0.30}},
        {"id": "gunslinger", "name": "速射炮手", "desc": "弹幕压制：攻速与暴击提升，冷却大幅缩短。",
         "stats": {"attack_speed": 0.20, "crit_rate": 0.06, "move_speed": 0.08},
         "skill_bonus": {"cooldown": 0.28}, "passives": {}},
    ],
    "bounty_hunter": [
        {"id": "collector", "name": "赏金猎人", "desc": "高效处决：攻击与暴击提升，缴械伤害翻倍。",
         "stats": {"attack": 10, "crit_rate": 0.06},
         "skill_bonus": {"power": 0.18}, "passives": {}},
        {"id": "tracer", "name": "追迹者", "desc": "锁定猎物：移速与攻速提升，连射更密集。",
         "stats": {"move_speed": 0.16, "attack_speed": 0.18},
         "skill_bonus": {"cooldown": 0.25}, "passives": {}},
    ],
}


def build_trees(classes: dict) -> dict:
    trees = {}
    for cid, cv in classes.items():
        skills = cv.get("skills", [])
        nodes = []
        for i, s in enumerate(skills):
            nodes.append({
                "id": "%s_anchor_%d" % (cid, i),
                "name": str(s.get("name", "")),
                "tier": 0,
                "col": i,
                "kind": "anchor",
                "skill_id": str(s.get("id", "")),
                "cost": 0,
                "requires": [],
                "icon": "skill_%s" % str(s.get("id", "")),
                "desc": "%s（初始技能）" % str(s.get("desc", "职业初始主动技能")),
                "passive": {},
                "skill_bonus": {},
            })
        for i, s in enumerate(skills):
            nodes.append({
                "id": "%s_mastery_%d" % (cid, i),
                "name": "%s精通" % str(s.get("name", "")),
                "tier": 1,
                "col": i,
                "kind": "mastery",
                "skill_id": str(s.get("id", "")),
                "cost": 1,
                "requires": ["%s_anchor_%d" % (cid, i)],
                "icon": "skill_%s" % str(s.get("id", "")),
                "desc": "强化【%s】：技能威力 +25%%，冷却 -10%%。" % str(s.get("name", "")),
                "passive": {},
                "skill_bonus": {"power": 0.25, "cooldown": 0.10},
            })
        cfg = CLASS_TREE[cid]
        a_name, a_desc, a_stats = cfg["a"]
        b_name, b_desc, b_stats = cfg["b"]
        c_name, c_desc, c_stats = cfg["c"]
        nodes.append({
            "id": "%s_passive_a" % cid,
            "name": a_name,
            "tier": 2,
            "col": 0,
            "kind": "passive",
            "skill_id": "",
            "cost": 2,
            "requires": ["%s_mastery_0" % cid, "%s_mastery_1" % cid],
            "icon": "passive_stat_attack",
            "desc": a_desc,
            "passive": a_stats,
            "skill_bonus": {},
        })
        nodes.append({
            "id": "%s_passive_b" % cid,
            "name": b_name,
            "tier": 2,
            "col": 2,
            "kind": "passive",
            "skill_id": "",
            "cost": 2,
            "requires": ["%s_mastery_1" % cid, "%s_mastery_2" % cid],
            "icon": "passive_stat_defense",
            "desc": b_desc,
            "passive": b_stats,
            "skill_bonus": {},
        })
        nodes.append({
            "id": "%s_capstone" % cid,
            "name": c_name,
            "tier": 3,
            "col": 1,
            "kind": "capstone",
            "skill_id": "",
            "cost": 3,
            "requires": ["%s_passive_a" % cid, "%s_passive_b" % cid],
            "icon": "passive_stat_capstone",
            "desc": c_desc,
            "passive": c_stats,
            "skill_bonus": {},
        })
        trees[cid] = {
            "name": "%s之道" % str(cv.get("name", cid)),
            "nodes": nodes,
        }
    return trees


def build_specializations(classes: dict) -> dict:
    out = {}
    for cid, specs in SPECIALIZATIONS.items():
        out[cid] = []
        for sp in specs:
            out[cid].append({
                "id": sp["id"],
                "name": sp["name"],
                "desc": sp["desc"],
                "req_level": 5,
                "icon": "portrait_%s" % cid,
                "stats": sp["stats"],
                "skill_bonus": sp["skill_bonus"],
                "passives": sp["passives"],
                "bonus_points": 1,
            })
    return out


def main() -> None:
    classes = json.load(open(os.path.join(ROOT, "data/classes.json"), encoding="utf-8"))["classes"]
    trees = build_trees(classes)
    specs = build_specializations(classes)
    with open(os.path.join(ROOT, "data/skill_trees.json"), "w", encoding="utf-8") as f:
        json.dump({
            "version": "1.0.0",
            "points_per_level": 1,
            "starting_points": 1,
            "trees": trees,
        }, f, ensure_ascii=False, indent=1)
    with open(os.path.join(ROOT, "data/specializations.json"), "w", encoding="utf-8") as f:
        json.dump({
            "version": "1.0.0",
            "specializations": specs,
        }, f, ensure_ascii=False, indent=1)
    print("trees=%d specs=%d" % (len(trees), len(specs)))


if __name__ == "__main__":
    main()
