#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""为 data/classes.json 的每个技能补充 desc / icon / vfx 字段"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

META = {
    "whirlwind": ("大范围横扫周身敌人，附带击退。", "melee_slash"),
    "war_cry": ("怒吼提升攻击，短时间内的致命一击。", "buff_swirl"),
    "shield_wall": ("凝聚护盾吸收伤害，持续数秒。", "shield_bubble"),
    "piercing_shot": ("贯穿箭矢，无视路径上的首个敌人。", "arrow"),
    "arrow_rain": ("召唤箭雨覆盖前方区域。", "arrow"),
    "hawk_eye": ("进入鹰眼状态，提升暴击与攻速。", "buff_swirl"),
    "fireball": ("凝聚烈焰火球，命中后爆燃。", "fireball"),
    "frost_nova": ("以自身为中心炸开冰霜，冻结范围内的敌人。", "ice_shard"),
    "arcane_shield": ("展开奥术护盾，吸收魔法伤害。", "shield_bubble"),
    "heal": ("治疗自身或友军，恢复生命。", "heal_spark"),
    "holy_nova": ("释放神圣光芒，驱散周围邪祟。", "rune_glyph"),
    "blessing": ("祝福队伍，提升全属性。", "buff_swirl"),
    "corrupt_bolt": ("射出腐蚀能量，造成持续伤害。", "void_pulse"),
    "grave_field": ("召唤亡者领域，迟滞与侵蚀敌人。", "rune_glyph"),
    "drain": ("吸取敌人生命回复自身。", "void_pulse"),
    "death_charge": ("化身死亡冲锋，撞飞沿途敌人。", "dash_streak"),
    "blood_slash": ("以血为刃的致命横斩。", "melee_slash"),
    "dark_shield": ("黑暗护盾成型，大幅吸收伤害。", "shield_bubble"),
    "backstab": ("自背后突袭，造成极高暴击伤害。", "melee_slash"),
    "smoke_bomb": ("投掷烟雾弹，短暂提升闪避与移速。", "steam_burst"),
    "poison_blade": ("淬毒飞刃，命中后持续掉血。", "void_pulse"),
    "snipe": ("远距精准射击，暴击伤害极高。", "arrow"),
    "trap": ("布设陷阱，触发时造成范围伤害。", "explosion"),
    "focus": ("凝神专注，提升暴击率与暴击伤害。", "buff_swirl"),
    "throw_bomb": ("投掷炸弹，落地爆炸。", "explosion"),
    "blast_zone": ("制造持续爆破的危险区域。", "explosion"),
    "incendiary": ("燃烧弹引燃区域，持续灼烧。", "fireball"),
    "virus": ("病毒在敌人体内连锁扩散。", "neon_grid"),
    "emp_pulse": ("释放电磁脉冲，瘫痪周围敌人。", "lightning"),
    "overclock": ("系统过载，攻速大幅提升。", "neon_grid"),
    "cannon": ("重炮轰击，造成巨额范围伤害。", "explosion"),
    "armor_up": ("装甲强化，吸收大量伤害。", "shield_bubble"),
    "energy_field": ("展开能量护盾，持续保护自身。", "shield_bubble"),
    "rapid_fire": ("连射扫射，弹道密集打击多个目标。", "arrow"),
    "mark": ("标记猎物，被标记目标承受额外伤害。", "rune_glyph"),
    "disarm": ("缴械突袭，破坏敌人武器并造成伤害。", "melee_slash"),
}


def main() -> None:
    path = os.path.join(ROOT, "data/classes.json")
    data = json.load(open(path, encoding="utf-8"))
    patched = 0
    for cid, cv in data["classes"].items():
        for s in cv.get("skills", []):
            sid = str(s.get("id", ""))
            desc, vfx = META.get(sid, (str(s.get("name", "")) + "。", "melee_slash"))
            s["desc"] = desc
            s["icon"] = "skill_%s" % sid
            s["vfx"] = vfx
            patched += 1
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print("skills patched =", patched)


if __name__ == "__main__":
    main()
