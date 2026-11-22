#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按 docs/STYLE_BRANCHES.md 生成四阶进阶数据。

产出：
  data/style_branches.json   48 流派（288 流派技能）/ 144 专精 / 48 流派极致
                             / 16 职业融合 / 16 变身 / 16 超脱 / 4 源流借技
  data/skill_trees.json      16 职业 × 4 层 × 4 节点成长树

设计文档即唯一事实来源：本脚本只做结构化解析，不重写数值。
用法：
    python3 tools/gen_style_branches.py --check
    python3 tools/gen_style_branches.py
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
DOC = os.path.join(ROOT, "docs", "STYLE_BRANCHES.md")

SKILL_TYPES = {
    "melee_aoe", "projectile", "heal", "buff", "shield", "chain", "aoe_zone",
    "dash_strike", "snipe", "deployable", "summon", "blink_strike",
    "root_zone", "heal_zone", "mark", "stun_wave", "pull_zone",
}
CN_NUM = {"双": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8,
          "九": 9, "十": 10, "十二": 12, "十四": 14, "十六": 16}
VFX = {
    "melee_aoe": "melee_slash", "projectile": "fireball", "heal": "heal_spark",
    "buff": "buff_swirl", "shield": "shield_bubble", "chain": "chain_blast",
    "aoe_zone": "explosion", "dash_strike": "dash_streak", "snipe": "arrow",
    "deployable": "explosion", "summon": "void_pulse", "blink_strike": "dash_streak",
    "root_zone": "ice_shard", "heal_zone": "heal_spark", "mark": "rune_glyph",
    "stun_wave": "chain_blast", "pull_zone": "void_pulse",
}
ICON_BY_TYPE = {
    "melee_aoe": "whirlwind", "projectile": "piercing_shot", "heal": "heal",
    "buff": "war_cry", "shield": "shield_wall", "chain": "chain_blast",
    "aoe_zone": "meteor", "dash_strike": "earth_shatter", "snipe": "snipe",
    "deployable": "throw_bomb", "summon": "soul_barrage", "blink_strike": "veil_step",
    "root_zone": "frost_nova", "heal_zone": "sanctuary", "mark": "mark",
    "stun_wave": "seismic_slam", "pull_zone": "void_pulse",
}
ICON_RULES = [
    (r"炎|火|焚|燃|炼狱|焰|灰烬|余烬", "fireball"),
    (r"冰|霜|冻|寒", "frost_nova"),
    (r"奥|秘|法|咒|符|以太", "arcane_surge"),
    (r"圣|光|誓|愈|治疗|医|神谕", "sanctuary"),
    (r"血|死|墓|魂|尸|亡|疫|腐|毒|瘟", "corrupt_bolt"),
    (r"雷|电|磁|震|崩|裂", "chain_blast"),
    (r"爆|炸|雷区|铝热|地雷|炸弹", "throw_bomb"),
    (r"炮|枪|弹幕|机炮|齐射|轨道", "cannon"),
    (r"箭|射|狙|鹰眼|贯穿", "piercing_shot"),
    (r"影|刺|暗|潜|烟", "backstab"),
    (r"风|疾|速|连|弹雨", "rapid_fire"),
    (r"盾|壁|甲|护", "iron_bulwark"),
    (r"召|亡者|尸傀|无人机|图腾", "soul_barrage"),
]
COLOR_RULES = [
    (r"炎|火|焚|燃|炼狱|焰|灰烬|余烬", "#ff7a3c"),
    (r"冰|霜|冻|寒", "#7fd4ff"),
    (r"奥|秘|法|以太", "#b28cff"),
    (r"圣|光|誓|愈|神谕|审判", "#ffe08a"),
    (r"血|死|墓|魂|尸|亡|疫|腐|毒|瘟", "#b45aff"),
    (r"雷|电|磁", "#6fd8ff"),
    (r"箭|射|狙|枪|炮|弹", "#d0e0ff"),
    (r"影|刺|暗|潜", "#9a7bff"),
    (r"风|疾|气", "#8affc8"),
]
BUFF_PATTERNS = [
    (r"法伤\+(\d+)%", "magic_attack_pct", True),
    (r"魔攻\+(\d+)%", "magic_attack_pct", True),
    (r"攻击\+(\d+)%", "attack_pct", True),
    (r"攻击\+(\d+)(?!%)", "attack", False),
    (r"防御\+(\d+)", "defense", False),
    (r"受击减伤(\d+)%", "damage_reduction", True),
    (r"受伤-(\d+)%", "damage_reduction", True),
    (r"减伤(\d+)%", "damage_reduction", True),
    (r"攻速\+(\d+)%", "attack_speed", True),
    (r"移速\+(\d+)%", "move_speed", True),
    (r"暴击\+(\d+)%", "crit_rate", True),
    (r"暴伤\+(\d+)%", "crit_damage", True),
    (r"闪避\+(\d+)%", "dodge_rate", True),
    (r"治疗加成\+(\d+)%", "heal_bonus", True),
    (r"护盾\+(\d+)%", "shield_bonus", True),
    (r"吸血\+(\d+)%", "lifesteal", True),
    (r"召唤物\+(\d+)%", "summon_bonus", True),
    (r"法伤\+(\d+)(?!%)", "magic_attack", False),
]


def utf8(text):
    return text.encode("utf-8").decode("utf-8")


def load_classes():
    with open(os.path.join(DATA, "classes.json"), "r", encoding="utf-8") as f:
        return json.load(f)


def find_num(pattern, text, default=None, cast=float):
    m = re.search(pattern, text)
    if not m:
        return default
    try:
        return cast(m.group(1))
    except (TypeError, ValueError):
        return default


def pick_icon(name, desc, stype):
    for pat, icon in ICON_RULES:
        if re.search(pat, name + desc):
            return "skill_" + icon
    return "skill_" + ICON_BY_TYPE.get(stype, "fireball")


def pick_color(name, desc, fallback):
    for pat, color in COLOR_RULES:
        if re.search(pat, name + desc):
            return color
    return fallback


def parse_passive(text):
    """`burn` 燃烧 +20% / 纯伤害增幅（技能威力 +25%）/ 无"""
    if not text:
        return {}
    key = re.search(r"`([a-z_]+)`", text)
    if key:
        val = re.search(r"([+\-]\d+(?:\.\d+)?)\s*%", text)
        value = abs(float(val.group(1))) / 100.0 if val else 0.0
        result = {key.group(1): round(value, 4)}
        stacks = re.search(r"最多\s*(\d+)\s*层", text)
        if stacks:
            result["stacks"] = int(stacks.group(1))
        return result
    power = re.search(r"技能威力\s*\+(\d+)%", text)
    if power:
        return {"power": int(power.group(1)) / 100.0}
    return {}


def parse_buffs(text):
    buffs = []
    for pat, stat, is_pct in BUFF_PATTERNS:
        m = re.search(pat, text)
        if not m:
            continue
        value = float(m.group(1))
        if is_pct:
            value = round(value / 100.0, 4)
        if any(b["stat"] == stat for b in buffs):
            continue
        buffs.append({"stat": stat, "value": value})
    return buffs


def parse_basic(text, kind, class_color, magic):
    """- 普攻：`projectile` 火弹，speed 480 / range 320 / cd 0.62 / 溅射 46。"""
    basic = {
        "kind": kind,
        "cooldown": find_num(r"cd\s*([\d.]+)", text, 0.6),
        "damage_type": "magic" if magic else "physical",
        "color": pick_color(text, "", class_color),
    }
    if kind == "melee":
        basic["radius"] = int(find_num(r"radius\s*(\d+)", text, 60))
        basic["knockback"] = find_num(r"knockback\s*([\d.]+)", text, 6.0)
    elif kind == "lob":
        basic["range"] = find_num(r"range\s*(\d+)", text, 240.0)
        basic["radius"] = find_num(r"radius\s*(\d+)", text, 70.0)
        basic["fuse"] = find_num(r"fuse\s*([\d.]+)", text, 0.5)
    else:
        basic["speed"] = find_num(r"speed\s*(\d+)", text, 460.0)
        basic["range"] = find_num(r"range\s*(\d+)", text, 320.0)
        basic["width"] = find_num(r"width\s*(\d+)", text, 14.0)
        basic["splash_radius"] = find_num(r"溅射\s*(\d+)", text, 0.0)
        basic["pierce"] = int(find_num(r"穿透\s*(\d+)", text, 0))
        pellets = re.search(r"(双|三|四|五)(?:弹|箭|发)", text)
        if pellets:
            basic["pellets"] = CN_NUM.get(pellets.group(1), 1)
            basic["spread"] = find_num(r"散布\s*([\d.]+)", text, 0.1)
    return basic


def build_skill(sid, name, stype, type2, params, desc, class_color, magic, origin):
    """把文档一行技能参数转成 SkillExecutor 可执行的数据。"""
    combined = params + " " + desc
    skill = {
        "id": sid,
        "name": name,
        "type": stype if stype in SKILL_TYPES else "projectile",
        "cd": round(find_num(r"cd\s*([\d.]+)", combined, 8.0), 2),
        "mp": int(find_num(r"mp\s*(\d+)", combined, 10)),
        "damage_type": "magic" if magic else "physical",
        "color": pick_color(name, desc, class_color),
        "desc": desc,
        "icon": "",
        "vfx": VFX.get(stype, "explosion"),
        "origin": origin,
    }
    skill["icon"] = pick_icon(name, desc, stype)
    power = find_num(r"pw\s*([\d.]+)", combined, None)
    if power is not None:
        skill["power"] = round(power, 3)
    radius = find_num(r"半径\s*(\d+)", combined, None, int)
    if radius is not None:
        skill["radius"] = radius
    delay = find_num(r"delay\s*([\d.]+)", combined, None)
    if delay is not None:
        skill["delay"] = delay
    duration = find_num(r"持续\s*([\d.]+)\s*s", combined, None)
    root = find_num(r"定身\s*([\d.]+)\s*s", combined, None)
    stun = find_num(r"眩晕\s*([\d.]+)\s*s", combined, None)
    knockback = find_num(r"击退\s*(\d+)", combined, None)
    if root is not None:
        skill["root"] = root
    if stun is not None:
        skill["stun"] = stun
    if knockback is not None:
        skill["knockback"] = knockback
    if duration is not None:
        skill["duration"] = duration
    if type2 and type2 in SKILL_TYPES:
        skill["extra_type"] = type2

    if stype == "projectile":
        skill["speed"] = find_num(r"speed\s*(\d+)", combined, 480.0)
        skill["range"] = find_num(r"range\s*(\d+)", combined, 320.0)
        skill["pierce"] = int(find_num(r"穿透\s*(\d+)", combined, 0))
        skill["splash_radius"] = find_num(r"溅射\s*(\d+)", combined, 0.0)
        if re.search(r"spread|散布", combined) and re.search(r"(双|三|四|五|六|七|八|九|十|十二)(?:连发|连射|发)", combined):
            pellets = re.search(r"(双|三|四|五|六|七|八|九|十|十二)(?:连发|连射|发)", combined)
            skill["pellets"] = CN_NUM.get(pellets.group(1), 2) if pellets else 2
            skill["spread"] = find_num(r"(?:spread|散布)\s*([\d.]+)", combined, 0.1)
        skill.setdefault("power", 1.0)
    elif stype == "aoe_zone":
        skill.setdefault("radius", 100)
        skill.setdefault("power", 1.0)
    elif stype == "melee_aoe":
        skill.setdefault("radius", 80)
        skill.setdefault("power", 1.0)
        if "六连击" in combined or "三段" in combined:
            skill["hits"] = 6 if "六连击" in combined else 3
    elif stype == "heal":
        skill["power"] = int(find_num(r"pw\s*(\d+)", combined, 50))
    elif stype == "heal_zone":
        skill["heal"] = int(find_num(r"每秒\s*(\d+)", combined, 20))
        skill.setdefault("duration", 6.0)
        skill["tick"] = 1.0
        shield = find_num(r"护盾[^0-9]*pw\s*(\d+)", combined, None, int)
        if shield:
            skill["shield"] = shield
    elif stype == "shield":
        skill["power"] = int(find_num(r"pw\s*(\d+)", combined, 50))
        skill.setdefault("duration", 6.0)
        skill["buffs"] = parse_buffs(combined)
        if skill["buffs"]:
            skill["stat"] = skill["buffs"][0]["stat"]
            skill["value"] = skill["buffs"][0]["value"]
    elif stype == "buff":
        skill["buffs"] = parse_buffs(combined)
        skill.setdefault("duration", 8.0)
        if skill["buffs"]:
            skill["stat"] = skill["buffs"][0]["stat"]
            skill["value"] = skill["buffs"][0]["value"]
    elif stype == "chain":
        skill.setdefault("radius", 220)
        skill["count"] = int(find_num(r"目标\s*(\d+)", combined, 3))
        skill.setdefault("power", 1.0)
    elif stype == "dash_strike":
        skill["distance"] = find_num(r"distance\s*(\d+)", combined, 160.0)
        skill.setdefault("radius", 70)
        skill.setdefault("power", 1.0)
    elif stype == "blink_strike":
        skill["range"] = find_num(r"range\s*(\d+)", combined, 200.0)
        skill.setdefault("radius", 70)
        skill.setdefault("power", 1.0)
        skill["buffs"] = parse_buffs(combined)
    elif stype == "snipe":
        skill["range"] = find_num(r"range\s*(\d+)", combined, 400.0)
        skill["width"] = find_num(r"width\s*(\d+)", combined, 18.0)
        steal = find_num(r"吸血\s*(\d+)%", combined, 0.0)
        skill["lifesteal"] = round(steal / 100.0, 4)
        skill.setdefault("power", 1.0)
    elif stype == "deployable":
        mode = "mine" if "mine" in params else ("turret" if "turret" in params else "bomb")
        skill["deploy"] = mode
        skill["count"] = int(find_num(r"(\d+)枚", combined, find_num(r"(\d+)座", combined, 1)))
        skill["spread"] = find_num(r"散布\s*(\d+)", combined, 0.0)
        skill.setdefault("radius", 90)
        skill["fuse"] = find_num(r"fuse\s*([\d.]+)", combined, 0.5)
        skill.setdefault("duration", 18.0)
        skill["interval"] = find_num(r"间隔\s*([\d.]+)", combined, 0.8)
        skill.setdefault("power", 1.0)
    elif stype == "summon":
        skill["count"] = int(find_num(r"(\d+)只", combined, 1))
        skill.setdefault("duration", 10.0)
        skill["speed"] = find_num(r"速度\s*(\d+)", combined, 120.0)
        skill["interval"] = find_num(r"间隔\s*([\d.]+)", combined, 1.0)
        skill.setdefault("power", 1.0)
    elif stype == "root_zone":
        skill.setdefault("radius", 110)
        skill.setdefault("power", 1.0)
        if "root" not in skill:
            skill["root"] = 2.0
    elif stype == "stun_wave":
        skill.setdefault("radius", 90)
        skill.setdefault("power", 1.0)
    elif stype == "mark":
        skill.setdefault("radius", 120)
        skill["duration"] = find_num(r"持续\s*([\d.]+)\s*s", combined, 8.0)
        skill["amp"] = round(find_num(r"易伤\s*(\d+)%", combined, 20.0) / 100.0, 4)
    elif stype == "pull_zone":
        skill.setdefault("radius", 140)
        skill["duration"] = find_num(r"持续\s*([\d.]+)\s*s", combined, 3.0)
        skill["pull"] = 80.0
    if "buffs" not in skill and stype not in ("buff", "shield", "blink_strike"):
        buffs = parse_buffs(combined)
        if buffs:
            skill["buffs"] = buffs
    if origin == "ascension":
        if not re.search(r"cd\s*[\d.]+", combined):
            skill["cd"] = 75.0
        if not re.search(r"mp\s*\d+", combined):
            skill["mp"] = 55
        duration = find_num(r"(\d+(?:\.\d+)?)\s*s", combined, None)
        skill["duration"] = duration if duration is not None else 15.0
    return skill


def parse_style_kits(doc, classes):
    """解析第四~七章的 48 条流派。"""
    start = doc.find("## 四、")
    end = doc.find("## 八、")
    if start >= 0 and end > start:
        doc = doc[start:end]
    styles = {}
    class_styles = {}
    order = [c["id"] for c in classes["classes"].values()] if "classes" in classes and isinstance(classes.get("classes"), dict) else []
    class_iter = list(classes["classes"].keys())
    current_class = None
    current_style = None
    style_seq = 0
    for raw in doc.splitlines():
        line = raw.strip()
        m = re.match(r"^###\s+(.+?)\s+\[([a-z_]+)\]", line)
        if m:
            current_class = m.group(2)
            current_style = None
            continue
        m = re.match(r"^\*\*流派\s+([ABC])[：:]\s*(.+?)(?:（(.+?)）)?\*\*$", line)
        if m and current_class:
            idx = "abc"["ABC".index(m.group(1))]
            style_seq += 1
            sid = "%s_%s" % (current_class, idx)
            cdef = classes["classes"].get(current_class, {})
            current_style = {
                "id": sid,
                "class_id": current_class,
                "index": idx,
                "name": m.group(2).strip(),
                "tag": (m.group(3) or "").strip(),
                "basic_attack": {},
                "passive": {},
                "skills": [],
                "color": cdef.get("color", "#ffffff"),
            }
            styles[sid] = current_style
            class_styles.setdefault(current_class, []).append(sid)
            continue
        if current_style is None:
            continue
        if line.startswith("- 普攻：") or line.startswith("- 普攻:"):
            text = line.split("：", 1)[-1] if "：" in line else line.split(":", 1)[-1]
            kind_m = re.search(r"`([a-z_]+)`", text)
            kind = kind_m.group(1) if kind_m else "projectile"
            cdef = classes["classes"].get(current_class, {})
            magic = ("魔法" in text) or cdef.get("source") == "arcane"
            current_style["basic_attack"] = parse_basic(text, kind, current_style["color"], magic)
            continue
        if line.startswith("- 被动：") or line.startswith("- 被动:"):
            text = line.split("：", 1)[-1] if "：" in line else line.split(":", 1)[-1]
            current_style["passive"] = parse_passive(text)
            continue
        m = re.match(r"^-\s*([1-6])\s+(.+?)｜(.+)$", line)
        if m:
            slot = int(m.group(1))
            name = m.group(2).strip()
            parts = m.group(3).split("｜")
            type_seg = parts[0]
            types = re.findall(r"`([a-z_]+)`", type_seg)
            stype = types[0] if types else "projectile"
            type2 = types[1] if len(types) > 1 else ""
            params = " ".join(parts[1:-1]) if len(parts) > 2 else (parts[1] if len(parts) > 1 else "")
            params = type_seg + " " + params
            desc = parts[-1].strip() if len(parts) > 1 else ""
            sid = "%s_%d" % (current_style["id"], slot)
            cdef = classes["classes"].get(current_class, {})
            magic = cdef.get("source") == "arcane"
            skill = build_skill(sid, name, stype, type2, params, desc,
                                current_style["color"], magic, "style")
            skill["slot"] = slot
            current_style["skills"].append(skill)
    return styles, class_styles


def parse_specs_and_apexes(doc, styles, classes):
    """解析第九章：144 专精 + 48 极致。"""
    specs = {}
    apexes = {}
    current_class = None
    current_style = None
    for raw in doc.splitlines():
        line = raw.strip()
        m = re.match(r"^####\s+(.+?)\s+\[([a-z_]+)\]", line)
        if m:
            current_class = m.group(2)
            current_style = None
            continue
        m = re.match(r"^\*\*流派\s+([ABC])[：:]\s*(.+?)\*\*$", line)
        if m and current_class:
            sid = "%s_%s" % (current_class, "abc"["ABC".index(m.group(1))])
            current_style = styles.get(sid)
            continue
        if current_style is None:
            continue
        m = re.match(r"^-\s*(专精[一二三]|极致)「(.+?)」｜【(.+?)】(.+)$", line)
        if not m:
            continue
        kind, title, active_name, rest = m.group(1), m.group(2), m.group(3), m.group(4)
        passive_text = ""
        if "｜被动" in rest:
            rest, passive_text = rest.split("｜被动", 1)
        types = re.findall(r"`([a-z_]+)`", rest)
        stype = types[0] if types else "projectile"
        type2 = types[1] if len(types) > 1 else ""
        params = rest
        desc = title if kind.startswith("专精") else (title + " · 流派极致")
        sid = current_style["id"]
        class_id = current_style["class_id"]
        cdef = classes["classes"].get(class_id, {})
        magic = cdef.get("source") == "arcane"
        skill = build_skill("", active_name, stype, type2, params, desc,
                            current_style["color"], magic, "spec" if kind.startswith("专精") else "apex")
        if kind.startswith("专精"):
            idx = "abc"["一二三".index(kind[-1])]
            skill["id"] = "%s_spec_%s" % (sid, idx)
            skill["fuse_no_sub"] = False
            entry = {
                "id": skill["id"],
                "style_id": sid,
                "class_id": class_id,
                "index": idx,
                "name": title,
                "active": skill,
                "passive": parse_passive(passive_text),
            }
            specs.setdefault(sid, []).append(entry)
        else:
            skill["id"] = "%s_apex" % sid
            skill["fuse_no_sub"] = True
            apexes[sid] = {
                "id": skill["id"],
                "style_id": sid,
                "class_id": class_id,
                "title": title,
                "active": skill,
                "passive": parse_passive(passive_text),
            }
    return specs, apexes


def read_tables(doc):
    """返回 {章节关键词: [row cells...]}，表格单元格已去空白。"""
    tables = {}
    current = None
    rows = []
    for raw in doc.splitlines():
        line = raw.strip()
        if line.startswith("###"):
            if current and rows:
                tables[current] = rows
            current = line
            rows = []
            continue
        if line.startswith("|") and line.endswith("|"):
            if re.match(r"^\|[\s\-:|]+\|$", line):
                continue
            cells = [c.strip() for c in line.strip("|").split("|")]
            if cells and cells[0] in ("职业", "源流", "项目"):
                continue
            rows.append(cells)
    if current and rows:
        tables[current] = rows
    return tables


def class_name_map(classes):
    return {str(v.get("name")): k for k, v in classes["classes"].items()}


def source_map():
    return {"法术": "arcane", "机械": "mech", "传武": "martial", "科技": "tech"}


def parse_advanced(doc, classes, styles):
    """解析第十章：16 融合 / 16 变身 / 16 超脱 / 4 借技。"""
    names = class_name_map(classes)
    tables = read_tables(doc)
    fusions, ascensions, transcends = {}, {}, {}
    borrows = {}
    for heading, rows in tables.items():
        if "10.1" in heading:
            for cells in rows:
                if len(cells) < 4:
                    continue
                cid = names.get(cells[0])
                if not cid:
                    continue
                cdef = classes["classes"][cid]
                magic = cdef.get("source") == "arcane"
                types = re.findall(r"`([a-z_]+)`", cells[2])
                stype = types[0] if types else "aoe_zone"
                skill = build_skill("%s_fusion" % cid, cells[1], stype, "", cells[2],
                                    cells[1], cdef.get("color", "#ffffff"), magic, "class_fusion")
                skill["fuse_no_sub"] = True
                fusions[cid] = {
                    "id": skill["id"], "class_id": cid, "name": cells[1],
                    "active": skill, "passive": parse_passive(cells[3]),
                }
        elif "10.2" in heading:
            for cells in rows:
                if len(cells) < 5:
                    continue
                cid = names.get(cells[0])
                if not cid:
                    continue
                cdef = classes["classes"][cid]
                magic = cdef.get("source") == "arcane"
                types = re.findall(r"`([a-z_]+)`", cells[2])
                stype = types[0] if types else "buff"
                skill = build_skill("%s_ascension" % cid, cells[1], stype, "", cells[2],
                                    "生命层次跃迁，短时间化身。", cdef.get("color", "#ffffff"), magic, "ascension")
                skill["fuse_no_sub"] = True
                ascensions[cid] = {
                    "id": skill["id"], "class_id": cid, "name": cells[1],
                    "active": skill, "passive": parse_passive(cells[3]),
                    "life_bonus": {
                        "hp": round(find_num(r"HP\s*\+\s*(\d+)%", cells[4], 0.0) / 100.0, 4),
                        "mp": round(find_num(r"MP\s*\+\s*(\d+)%", cells[4], 0.0) / 100.0, 4),
                    },
                }
        elif "10.3" in heading:
            for cells in rows:
                if len(cells) == 3 and cells[0] in source_map():
                    src = source_map()[cells[0]]
                    types = re.findall(r"`([a-z_]+)`", cells[2])
                    stype = types[0] if types else "aoe_zone"
                    skill = build_skill("%s_borrow" % src, cells[1], stype, "", cells[2],
                                        cells[1], "#d8d8ff", src == "arcane", "borrow")
                    skill["fuse_no_sub"] = True
                    borrows[src] = {
                        "id": skill["id"], "source": src, "name": cells[1], "active": skill,
                    }
                    continue
                if len(cells) < 4:
                    continue
                cid = names.get(cells[0])
                if not cid:
                    continue
                cdef = classes["classes"][cid]
                magic = cdef.get("source") == "arcane"
                types = re.findall(r"`([a-z_]+)`", cells[2])
                stype = types[0] if types else "aoe_zone"
                skill = build_skill("%s_transcend" % cid, cells[1], stype, "", cells[2],
                                    cells[1], cdef.get("color", "#ffffff"), magic, "transcend")
                skill["fuse_no_sub"] = True
                transcends[cid] = {
                    "id": skill["id"], "class_id": cid, "title": cells[1],
                    "active": skill, "passive": parse_passive(cells[3]),
                }
        elif "借技" in heading or "11" in heading:
            for cells in rows:
                if len(cells) < 3:
                    continue
                src = source_map().get(cells[0])
                if not src:
                    continue
                types = re.findall(r"`([a-z_]+)`", cells[2])
                stype = types[0] if types else "aoe_zone"
                skill = build_skill("%s_borrow" % src, cells[1], stype, "", cells[2],
                                    cells[1], "#d8d8ff", src == "arcane", "borrow")
                skill["fuse_no_sub"] = True
                borrows[src] = {
                    "id": skill["id"], "source": src, "name": cells[1], "active": skill,
                }
    return fusions, ascensions, transcends, borrows


def build_trees(classes):
    layers = [
        [
            ("攻击强化", "attack", 3, "passive_stat_attack"),
            ("防御强化", "defense", 2, "passive_stat_defense"),
            ("生命强化", "max_hp", 8, "passive_stat_defense"),
            ("魔力强化", "max_mp", 6, "passive_stat_skill"),
        ],
        [
            ("致命洞察", "crit_rate", 0.02, "passive_stat_crit"),
            ("迅捷出手", "attack_speed", 0.03, "passive_stat_speed"),
            ("身法轻灵", "move_speed", 0.02, "passive_stat_speed"),
            ("全属性淬炼", "all_stats_bonus", 0.02, "passive_stat_capstone"),
        ],
        [
            ("汲血", "lifesteal", 0.03, "passive_stat_attack"),
            ("护盾强化", "shield_bonus", 0.04, "passive_stat_defense"),
            ("治疗强化", "heal_bonus", 0.04, "passive_stat_skill"),
            ("灼烧精通", "burn", 0.04, "passive_stat_crit"),
        ],
        [
            ("处决", "execute", 0.05, "passive_stat_crit"),
            ("坚韧", "fortify", 0.03, "passive_stat_defense"),
            ("急速", "haste", 0.04, "passive_stat_speed"),
            ("共鸣", "resonance", 0.03, "passive_stat_capstone"),
        ],
    ]
    layer_names = ["初阶", "进阶", "专精", "融合"]
    trees = {}
    for cid in classes["classes"].keys():
        nodes = []
        for layer, entries in enumerate(layers):
            for col, (name, stat, value, icon) in enumerate(entries):
                node = {
                    "id": "%s_t%d_%d" % (cid, layer, col),
                    "name": name,
                    "kind": "growth",
                    "tier": layer,
                    "col": col,
                    "cost": 1,
                    "icon": icon,
                    "desc": "成长节点：%s +%s" % (name, value),
                    "passive": {stat: value},
                    "requires": [],
                }
                if layer > 0:
                    node["requires"] = ["%s_t%d_%d" % (cid, layer - 1, col)]
                nodes.append(node)
        trees[cid] = {
            "class_id": cid,
            "layer_names": layer_names,
            "nodes": nodes,
        }
    return {
        "version": "2.0.0",
        "layout": {"layers": 4, "nodes_per_layer": 4},
        "fusion_slots": {"per_layers": 2, "max": 2},
        "points_per_level": 1,
        "starting_points": 1,
        "trees": trees,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只解析校验，不写文件")
    args = ap.parse_args()

    with open(DOC, "r", encoding="utf-8") as f:
        doc = f.read()
    classes = load_classes()
    styles, class_styles = parse_style_kits(doc, classes)
    specs, apexes = parse_specs_and_apexes(doc, styles, classes)
    fusions, ascensions, transcends, borrows = parse_advanced(doc, classes, styles)
    trees = build_trees(classes)

    problems = []

    def need(cond, msg):
        if not cond:
            problems.append(msg)

    need(len(styles) == 48, "流派数量 %d != 48" % len(styles))
    need(len(specs) == 48, "专精流派数 %d != 48" % len(specs))
    need(sum(len(v) for v in specs.values()) == 144, "专精数量 %d != 144" % sum(len(v) for v in specs.values()))
    need(len(apexes) == 48, "极致数量 %d != 48" % len(apexes))
    need(len(fusions) == 16, "职业融合 %d != 16" % len(fusions))
    need(len(ascensions) == 16, "变身 %d != 16" % len(ascensions))
    need(len(transcends) == 16, "超脱 %d != 16" % len(transcends))
    need(len(borrows) == 4, "借技 %d != 4" % len(borrows))
    need(len(class_styles) == 16, "职业流派覆盖 %d != 16" % len(class_styles))
    for cid, sids in class_styles.items():
        need(len(sids) == 3, "%s 流派数 %d != 3" % (cid, len(sids)))
    for sid, st in styles.items():
        need(len(st["skills"]) == 6, "%s 技能数 %d != 6" % (sid, len(st["skills"])))
        for sk in st["skills"]:
            need(sk["type"] in SKILL_TYPES, "%s 非法技能类型 %s" % (sk["id"], sk["type"]))
        need(bool(st["basic_attack"]), "%s 缺少普攻" % sid)
    for sid, entries in specs.items():
        need(len(entries) == 3, "%s 专精数 %d != 3" % (sid, len(entries)))
        for e in entries:
            need(e["active"]["type"] in SKILL_TYPES, "%s 非法类型 %s" % (e["id"], e["active"]["type"]))
    for sid, a in apexes.items():
        need(a["active"]["type"] in SKILL_TYPES, "%s 非法类型 %s" % (a["id"], a["active"]["type"]))
        need(a["active"].get("fuse_no_sub"), "%s 极致未标记不可融合" % a["id"])
    for cid, f in fusions.items():
        need(f["active"]["type"] in SKILL_TYPES, "%s 融合非法类型" % cid)
    for cid, a in ascensions.items():
        need(a["active"]["type"] in SKILL_TYPES, "%s 变身非法类型" % cid)
    for cid, t in transcends.items():
        need(t["active"]["type"] in SKILL_TYPES, "%s 超脱非法类型" % cid)

    if problems:
        print("生成校验失败：")
        for p in problems:
            print("  -", p)
        return 1

    payload = {
        "version": "2.0.0",
        "source": "docs/STYLE_BRANCHES.md",
        "styles": styles,
        "class_styles": class_styles,
        "specs": specs,
        "apexes": apexes,
        "class_fusions": fusions,
        "ascensions": ascensions,
        "transcends": transcends,
        "borrow_pool": borrows,
    }
    print("解析完成：流派 %d / 流派技能 %d / 专精 %d / 极致 %d / 融合 %d / 变身 %d / 超脱 %d / 借技 %d" % (
        len(styles), sum(len(s["skills"]) for s in styles.values()),
        sum(len(v) for v in specs.values()), len(apexes),
        len(fusions), len(ascensions), len(transcends), len(borrows)))
    if args.check:
        return 0
    with open(os.path.join(DATA, "style_branches.json"), "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    with open(os.path.join(DATA, "skill_trees.json"), "w", encoding="utf-8") as f:
        json.dump(trees, f, ensure_ascii=False, indent=1)
    print("已写入 data/style_branches.json 与 data/skill_trees.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
