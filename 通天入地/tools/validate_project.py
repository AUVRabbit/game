#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通天入地 · 静态校验器
在无 Godot 可执行文件的环境中，对项目做结构与语法级检查。

用法：
    python3 tools/validate_project.py
返回码 0 表示全部通过，1 表示存在错误。
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ERRORS = []
WARNINGS = []


def err(msg):
    ERRORS.append(msg)


def warn(msg):
    WARNINGS.append(msg)


def read(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


# ---------------------------------------------------------------- project.godot
def check_project():
    path = os.path.join(ROOT, "project.godot")
    if not os.path.isfile(path):
        err("缺少 project.godot")
        return "", ""
    text = read(path)

    m = re.search(r'run/main_scene="([^"]+)"', text)
    if not m:
        err("project.godot 未配置 run/main_scene")
    else:
        p = os.path.join(ROOT, m.group(1).replace("res://", ""))
        if not os.path.isfile(p):
            err("main_scene 不存在：%s" % m.group(1))

    autoloads = dict(re.findall(r'^(\w+)="\*?(res://[^"]+)"', text, re.M))
    if not autoloads:
        err("project.godot 未配置任何 autoload")
    for name, res in autoloads.items():
        p = os.path.join(ROOT, res.replace("res://", ""))
        if not os.path.isfile(p):
            err("autoload %s 指向不存在的脚本 %s" % (name, res))
            continue
        src = read(p)
        if re.search(r'^class_name\s+', src, re.M):
            err("autoload %s 不应声明 class_name（%s）" % (name, res))
        if not re.search(r'^extends\s+', src, re.M):
            err("autoload %s 缺少 extends 声明" % name)

    input_actions = set(re.findall(r'^(\w+)=\{', text, re.M))
    for action in ["move_left", "move_right", "move_up", "move_down", "attack",
                   "skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "skill_6",
                   "skill_7", "skill_8", "skill_9", "skill_10",
                   "dash", "interact",
                   "character_switch_next", "character_switch_prev",
                   "open_inventory", "open_build", "pause"]:
        if action not in input_actions:
            err("project.godot 缺少输入动作：%s" % action)

    return text, "\n".join(sorted(autoloads))


def check_gd(autoload_names):
    gd_files = []
    for base, _dirs, files in os.walk(ROOT):
        if ".git" in base or "/tools" in base.replace(os.sep, "/"):
            continue
        for f in files:
            if f.endswith(".gd"):
                gd_files.append(os.path.join(base, f))

    class_names = {}
    for path in gd_files:
        rel = os.path.relpath(path, ROOT)
        src = read(path)
        lines = src.split("\n")

        class_m = re.search(r'^class_name\s+(\w+)', src, re.M)
        if class_m:
            cname = class_m.group(1)
            if cname in class_names:
                err("class_name 重复：%s（%s 与 %s）" % (cname, class_names[cname], rel))
            class_names[cname] = rel

        for i, line in enumerate(lines, 1):
            stripped = line.lstrip(" \t")
            if not stripped:
                continue
            if line.startswith(" ") and not line.startswith("\t"):
                err("%s:%d 使用空格缩进（GDScript 需 Tab）" % (rel, i))
                break
            code = line.split("#", 1)[0]
            if ";" in code and not ("\"" in code or "'" in code):
                warn("%s:%d 出现分号，可能误用 C 风格注释" % (rel, i))

        if re.search(r"\bemit_signalv\s*\(", src):
            err("%s 使用了不存在的 emit_signalv()" % rel)
        if re.search(r"\brandi\s*\(\s*[-0-9]", src):
            err("%s 使用了 randi(a,b)，应为 randi_range()" % rel)
        if re.search(r"\.groups\.add\s*\(", src):
            err("%s 使用了 groups.add()，应为 add_to_group()" % rel)
        if re.search(r"^\s*var\s+offset\b", src, re.M) and "Camera2D" in src:
            err("%s 在 Camera2D 脚本中声明 offset（与内置属性冲突）" % rel)
        if re.search(r'\\\s*\n', src):
            warn("%s 使用了反斜杠续行，建议改用括号" % rel)

        # 检查动态信号调用形式
        for m in re.finditer(r"emit_signal\.callv\s*\(([^)]*)\)", src):
            args = m.group(1)
            if "," in args.split("+")[0] and not args.strip().startswith("[") and not args.strip().startswith("call_args"):
                warn("%s emit_signal.callv 参数形式需确认：%s" % (rel, args.strip()))

    return gd_files


# ---------------------------------------------------------------- .tscn
def check_tscn():
    scene_files = []
    for base, _dirs, files in os.walk(ROOT):
        if ".git" in base:
            continue
        for f in files:
            if f.endswith(".tscn"):
                scene_files.append(os.path.join(base, f))

    for path in scene_files:
        rel = os.path.relpath(path, ROOT)
        text = read(path)
        ext = {}
        for m in re.finditer(r'\[ext_resource\b([^\]]*)\]', text):
            attrs = m.group(1)
            id_m = re.search(r'id="([^"]+)"', attrs)
            path_m = re.search(r'path="([^"]+)"', attrs)
            if id_m and path_m:
                ext[id_m.group(1)] = path_m.group(1)
        subs = set(re.findall(r'\[sub_resource[^\]]*id="([^"]+)"\]', text))
        for used in set(re.findall(r'ExtResource\("([^"]+)"\)', text)):
            if used not in ext:
                err("%s 引用了未声明的 ExtResource(%s)" % (rel, used))
        for used in set(re.findall(r'SubResource\("([^"]+)"\)', text)):
            if used not in subs:
                err("%s 引用了未声明的 SubResource(%s)" % (rel, used))
        for eid, res in ext.items():
            if res.startswith("res://"):
                p = os.path.join(ROOT, res.replace("res://", ""))
                if not os.path.isfile(p):
                    err("%s 的 ext_resource 路径不存在：%s" % (rel, res))
        if "[node" not in text:
            err("%s 不包含任何节点" % rel)
        # load_steps 与实际资源数一致性（仅在存在 ext/sub 时检查）
        m = re.search(r'load_steps=(\d+)', text)
        declared = int(m.group(1)) if m else None
        actual = len(ext) + len(subs) + 1
        if declared is not None and declared < actual:
            err("%s load_steps=%d 小于实际资源数 %d" % (rel, declared, actual))

    return scene_files


# ---------------------------------------------------------------- 数据表
SKILL_TYPES = ["melee_aoe", "projectile", "heal", "buff", "shield",
               "chain", "aoe_zone", "dash_strike",
               "snipe", "deployable", "summon", "blink_strike",
               "root_zone", "heal_zone", "mark", "stun_wave", "pull_zone"]
BASIC_KINDS = ["melee", "projectile", "beam", "lob"]


def asset_path(icon):
    if icon.startswith("skill_"):
        return os.path.join(ROOT, "assets", "icons", "skill", icon[6:] + ".png")
    if icon.startswith("passive_"):
        return os.path.join(ROOT, "assets", "icons", "passive", icon[8:] + ".png")
    if icon.startswith("portrait_"):
        return os.path.join(ROOT, "assets", "portraits", icon[9:] + ".png")
    return None


def check_data():
    data_dir = os.path.join(ROOT, "data")
    tables = {}
    for name in ["items", "classes", "recipes", "quests", "dialogue",
                 "skill_trees", "specializations"]:
        path = os.path.join(data_dir, name + ".json")
        if not os.path.isfile(path):
            err("缺少数据文件 data/%s.json" % name)
            continue
        try:
            tables[name] = json.loads(read(path))
        except Exception as e:
            err("data/%s.json 解析失败：%s" % (name, e))

    items = tables.get("items", {}).get("items", {})
    classes = tables.get("classes", {}).get("classes", {})
    recipes = tables.get("recipes", {}).get("recipes", [])
    quests = tables.get("quests", {}).get("quests", {})
    trees = tables.get("skill_trees", {}).get("trees", {})
    specs = tables.get("specializations", {}).get("specializations", {})

    if len(classes) != 16:
        err("职业数量应为 16，实际 %d" % len(classes))

    for cid, cdef in classes.items():
        skills = cdef.get("skills", [])
        if len(skills) != 6:
            err("职业 %s 技能应为 6 个，实际 %d" % (cid, len(skills)))
        slots = sorted(int(s.get("slot", 0)) for s in skills)
        if slots != [1, 2, 3, 4, 5, 6]:
            err("职业 %s 技能槽号应为 1..6，实际 %s" % (cid, slots))
        for skill in skills:
            t = skill.get("type", "")
            if t not in SKILL_TYPES:
                err("职业 %s 技能 %s 使用了未实现的类型 %s" % (cid, skill.get("name"), t))
            if not skill.get("desc"):
                err("职业 %s 技能 %s 缺少机制描述" % (cid, skill.get("name")))
            icon = str(skill.get("icon", ""))
            p = asset_path(icon)
            if p and not os.path.isfile(p):
                err("职业 %s 技能 %s 缺少图标素材：%s" % (cid, skill.get("id"), icon))
        ba = cdef.get("basic_attack", {})
        kind = str(ba.get("kind", ""))
        if kind not in BASIC_KINDS:
            err("职业 %s basic_attack.kind 非法：%s" % (cid, kind))
        elif kind == "melee" and not ba.get("radius"):
            err("职业 %s 近战普攻缺少 radius" % cid)
        elif kind == "projectile" and (not ba.get("speed") or not ba.get("range")):
            err("职业 %s 弹丸普攻缺少 speed/range" % cid)
        elif kind == "beam" and (not ba.get("range") or not ba.get("width")):
            err("职业 %s 射线普攻缺少 range/width" % cid)
        elif kind == "lob" and (not ba.get("range") or not ba.get("radius")):
            err("职业 %s 抛掷普攻缺少 range/radius" % cid)
        for key in ["source", "role", "source_name", "role_name", "identity"]:
            if not cdef.get(key):
                err("职业 %s 缺少设计字段 %s" % (cid, key))
        color = cdef.get("color", "#000000")
        if not re.match(r"^#[0-9a-fA-F]{6}$", color):
            err("职业 %s 颜色格式错误：%s" % (cid, color))

    if len(trees) != 16:
        err("技能树应为 16 套，实际 %d" % len(trees))
    tree_def = tables.get("skill_trees", {})
    layout = tree_def.get("layout", {})
    if int(layout.get("layers", 0)) != 4 or int(layout.get("nodes_per_layer", 0)) != 4:
        err("技能树布局应为 4 层×4 节点，实际 %s" % layout)
    fusion_slots = tree_def.get("fusion_slots", {})
    if int(fusion_slots.get("per_layers", 0)) != 2 or int(fusion_slots.get("max", 0)) != 2:
        err("融合槽规则应每 2 层 1 个、最多 2 个，实际 %s" % fusion_slots)
    for cid in classes:
        nodes = trees.get(cid, {}).get("nodes", [])
        if len(nodes) != 16:
            err("职业 %s 技能树节点应为 16，实际 %d" % (cid, len(nodes)))
        ids = {str(n.get("id", "")) for n in nodes}
        per_tier = {}
        for node in nodes:
            if str(node.get("kind", "")) != "growth":
                err("职业 %s 节点 %s 类型应为 growth，实际 %s" % (cid, node.get("id"), node.get("kind")))
            tier = int(node.get("tier", -1))
            col = int(node.get("col", -1))
            if tier not in range(4) or col not in range(4):
                err("职业 %s 节点 %s 坐标非法：tier=%d col=%d" % (cid, node.get("id"), tier, col))
                continue
            per_tier[tier] = per_tier.get(tier, 0) + 1
            expect_id = "%s_t%d_%d" % (cid, tier, col)
            if str(node.get("id", "")) != expect_id:
                err("职业 %s 节点 id 应为 %s，实际 %s" % (cid, expect_id, node.get("id")))
            reqs = [str(r) for r in node.get("requires", [])]
            if tier == 0:
                if reqs:
                    err("职业 %s 首层节点 %s 不应有前置" % (cid, node.get("id")))
            else:
                expect_req = "%s_t%d_%d" % (cid, tier - 1, col)
                if reqs != [expect_req]:
                    err("职业 %s 节点 %s 前置应为 %s，实际 %s" % (cid, node.get("id"), expect_req, reqs))
            for req in reqs:
                if req not in ids:
                    err("职业 %s 节点 %s 的前置不存在：%s" % (cid, node.get("id"), req))
            p = asset_path(str(node.get("icon", "")))
            if p and not os.path.isfile(p):
                err("职业 %s 技能树节点 %s 缺少图标素材：%s" % (cid, node.get("id"), node.get("icon")))
        for tier in range(4):
            if per_tier.get(tier, 0) != 4:
                err("职业 %s 第 %d 层节点应为 4，实际 %d" % (cid, tier, per_tier.get(tier, 0)))

    if len(specs) != 16:
        err("专职数据应为 16 个职业，实际 %d" % len(specs))
    for cid in classes:
        entry = specs.get(cid, [])
        if len(entry) != 3:
            err("职业 %s 专职应为 3 条，实际 %d" % (cid, len(entry)))
        sids = [str(s.get("id", "")) for s in entry]
        if len(sids) != len(set(sids)):
            err("职业 %s 专职 id 重复：%s" % (cid, sids))

    for rid, rdef in [(r.get("id"), r) for r in recipes]:
        if rdef.get("output") not in items:
            err("配方 %s 产出物不存在：%s" % (rid, rdef.get("output")))
        for cost_id in rdef.get("cost", {}):
            if cost_id not in items:
                err("配方 %s 材料不存在：%s" % (rid, cost_id))

    for qid, qdef in quests.items():
        for item_id in qdef.get("rewards", {}).get("items", {}):
            if item_id not in items:
                err("任务 %s 奖励物品不存在：%s" % (qid, item_id))

    for item_id, item in items.items():
        if item.get("type") == "building":
            for cost_id in item.get("craft_cost", {}):
                if cost_id not in items:
                    err("建筑 %s 材料不存在：%s" % (item_id, cost_id))

    return items


# ---------------------------------------------------------------- 流派进阶
DAMAGE_TYPES = {"melee_aoe", "projectile", "chain", "aoe_zone", "dash_strike",
                "snipe", "blink_strike", "root_zone", "stun_wave", "pull_zone"}


def check_ability(tag, skill):
    if not isinstance(skill, dict) or not skill:
        err("%s 技能定义为空" % tag)
        return
    t = str(skill.get("type", ""))
    if t not in SKILL_TYPES:
        err("%s 使用了未实现的类型 %s" % (tag, t))
    try:
        cd = float(skill.get("cd", 0))
        mp = float(skill.get("mp", 0))
        power = float(skill.get("power", 0))
    except (TypeError, ValueError):
        err("%s 的 cd/mp/power 不是数字" % tag)
        return
    if cd <= 0 or cd > 180:
        err("%s 冷却越界：%s" % (tag, cd))
    if mp < 0 or mp > 300:
        err("%s 魔力消耗越界：%s" % (tag, mp))
    if t in DAMAGE_TYPES and power <= 0:
        err("%s 伤害技能缺少威力" % tag)
    if t in ("aoe_zone", "root_zone", "heal_zone", "pull_zone", "stun_wave") and float(skill.get("radius", 0)) <= 0:
        err("%s 区域技能缺少半径" % tag)
    icon = str(skill.get("icon", ""))
    p = asset_path(icon)
    if not icon:
        err("%s 缺少图标" % tag)
    elif p and not os.path.isfile(p):
        err("%s 图标素材不存在：%s" % (tag, icon))


def check_style_branches():
    path = os.path.join(ROOT, "data", "style_branches.json")
    if not os.path.isfile(path):
        err("缺少数据文件 data/style_branches.json")
        return
    try:
        data = json.loads(read(path))
    except Exception as e:
        err("data/style_branches.json 解析失败：%s" % e)
        return
    styles = data.get("styles", {})
    class_styles = data.get("class_styles", {})
    specs = data.get("specs", {})
    apexes = data.get("apexes", {})
    fusions = data.get("class_fusions", {})
    ascensions = data.get("ascensions", {})
    transcends = data.get("transcends", {})
    borrow_pool = data.get("borrow_pool", {})

    expect = [("流派", styles, 48), ("职业流派映射", class_styles, 16),
              ("专精组", specs, 48), ("流派极致", apexes, 48),
              ("职业融合", fusions, 16), ("生命跃迁", ascensions, 16),
              ("超脱", transcends, 16), ("借技池", borrow_pool, 4)]
    for label, table, count in expect:
        if len(table) != count:
            err("%s数量应为 %d，实际 %d" % (label, count, len(table)))

    ability_ids = set()
    for style_id, style in styles.items():
        cid = str(style.get("class_id", ""))
        if not cid:
            err("流派 %s 缺少 class_id" % style_id)
        elif class_styles.get(cid) and style_id not in class_styles[cid]:
            err("流派 %s 未被职业 %s 的流派映射引用" % (style_id, cid))
        ba = style.get("basic_attack", {})
        kind = str(ba.get("kind", ""))
        if kind not in BASIC_KINDS:
            err("流派 %s 普攻类型非法：%s" % (style_id, kind))
        elif kind == "melee" and not ba.get("radius"):
            err("流派 %s 近战普攻缺少 radius" % style_id)
        elif kind == "projectile" and (not ba.get("speed") or not ba.get("range")):
            err("流派 %s 远程普攻缺少 speed/range" % style_id)
        elif kind == "lob" and (not ba.get("range") or not ba.get("radius")):
            err("流派 %s 抛掷普攻缺少 range/radius" % style_id)
        elif kind == "beam" and (not ba.get("range") or not ba.get("width")):
            err("流派 %s 射线普攻缺少 range/width" % style_id)
        skills = style.get("skills", [])
        if len(skills) != 6:
            err("流派 %s 技能应为 6 个，实际 %d" % (style_id, len(skills)))
        for skill in skills:
            sid = str(skill.get("id", ""))
            if sid in ability_ids:
                err("技能 id 重复：%s" % sid)
            ability_ids.add(sid)
            if not sid.startswith(style_id + "_"):
                err("流派 %s 技能 id 前缀错误：%s" % (style_id, sid))
            check_ability("流派 %s 技能 %s" % (style_id, sid), skill)

    for cid, ids in class_styles.items():
        if len(ids) != 3:
            err("职业 %s 流派应为 3 条，实际 %d" % (cid, len(ids)))
        for sid in ids:
            if sid not in styles:
                err("职业 %s 引用了不存在的流派 %s" % (cid, sid))

    for style_id, group in specs.items():
        if style_id not in styles:
            err("专精组 %s 对应的流派不存在" % style_id)
        if len(group) != 3:
            err("流派 %s 专精应为 3 条，实际 %d" % (style_id, len(group)))
        for spec in group:
            sid = str(spec.get("id", ""))
            if sid in ability_ids:
                err("专精 id 重复：%s" % sid)
            ability_ids.add(sid)
            active = spec.get("active", {})
            check_ability("专精 %s" % sid, active)
            if str(active.get("id", "")) != sid:
                err("专精 %s 的主动技能 id 不一致：%s" % (sid, active.get("id")))
            if bool(active.get("fuse_no_sub", False)):
                err("专精 %s 不应标记 fuse_no_sub" % sid)
            if not spec.get("passive"):
                err("专精 %s 缺少被动" % sid)

    for style_id, apex in apexes.items():
        sid = str(apex.get("id", ""))
        if sid in ability_ids:
            err("极致 id 重复：%s" % sid)
        ability_ids.add(sid)
        active = apex.get("active", {})
        check_ability("极致 %s" % sid, active)
        if not bool(active.get("fuse_no_sub", False)):
            err("极致 %s 必须标记 fuse_no_sub" % sid)
        if not apex.get("title") or not apex.get("passive"):
            err("极致 %s 缺少称号或被动" % sid)

    for cid, fusion in fusions.items():
        sid = str(fusion.get("id", ""))
        if sid in ability_ids:
            err("职业融合 id 重复：%s" % sid)
        ability_ids.add(sid)
        active = fusion.get("active", {})
        check_ability("职业融合 %s" % sid, active)
        if not bool(active.get("fuse_no_sub", False)):
            err("职业融合 %s 必须标记 fuse_no_sub" % sid)
        if not fusion.get("passive"):
            err("职业融合 %s 缺少被动" % sid)

    for cid, asc in ascensions.items():
        sid = str(asc.get("id", ""))
        if sid in ability_ids:
            err("变身 id 重复：%s" % sid)
        ability_ids.add(sid)
        active = asc.get("active", {})
        check_ability("变身 %s" % sid, active)
        if not bool(active.get("fuse_no_sub", False)):
            err("变身 %s 必须标记 fuse_no_sub" % sid)
        life = asc.get("life_bonus", {})
        hp = float(life.get("hp", 0))
        mp = float(life.get("mp", 0))
        if not (0.2 <= hp <= 0.5):
            err("变身 %s 生命上限加成越界：%s" % (sid, hp))
        if not (0.1 <= mp <= 0.4):
            err("变身 %s 魔力上限加成越界：%s" % (sid, mp))

    for cid, trans in transcends.items():
        sid = str(trans.get("id", ""))
        if sid in ability_ids:
            err("超脱 id 重复：%s" % sid)
        ability_ids.add(sid)
        active = trans.get("active", {})
        check_ability("超脱 %s" % sid, active)
        if not bool(active.get("fuse_no_sub", False)):
            err("超脱 %s 必须标记 fuse_no_sub" % sid)
        if not trans.get("title") or not trans.get("passive"):
            err("超脱 %s 缺少称号或被动" % sid)

    sources = set()
    for key, borrow in borrow_pool.items():
        sid = str(borrow.get("id", ""))
        if sid in ability_ids:
            err("借技 id 重复：%s" % sid)
        ability_ids.add(sid)
        source = str(borrow.get("source", ""))
        if source in sources:
            err("借技源流重复：%s" % source)
        sources.add(source)
        active = borrow.get("active", {})
        check_ability("借技 %s" % sid, active)
        if not bool(active.get("fuse_no_sub", False)):
            err("借技 %s 必须标记 fuse_no_sub" % sid)


def check_progression_rules():
    path = os.path.join(ROOT, "scripts", "player", "character_base.gd")
    if not os.path.isfile(path):
        err("缺少 scripts/player/character_base.gd")
        return
    src = read(path)
    for const, value in [("MAX_SKILL_SLOTS", 10), ("BASE_SKILL_SLOTS", 6)]:
        m = re.search(r"const\s+%s\s*:=\s*(\d+)" % const, src)
        if not m or int(m.group(1)) != value:
            err("CharacterBase.%s 应为 %d" % (const, value))
    path = os.path.join(ROOT, "scripts", "combat", "fusion_service.gd")
    if not os.path.isfile(path):
        err("缺少 scripts/combat/fusion_service.gd")
        return
    src = read(path)
    for const, value in [("POWER_MULT", "1.15"), ("CD_MULT", "1.25")]:
        if not re.search(r"const\s+%s\s*:=\s*%s" % (const, re.escape(value)), src):
            err("FusionService.%s 应为 %s" % (const, value))


# ---------------------------------------------------------------- 脚本内路径
def check_res_paths():
    pattern = re.compile(r'"(res://[^"]+)"')
    for base, _dirs, files in os.walk(ROOT):
        if ".git" in base:
            continue
        for f in files:
            if not f.endswith(".gd"):
                continue
            path = os.path.join(base, f)
            rel = os.path.relpath(path, ROOT)
            for res in set(pattern.findall(read(path))):
                if res.endswith("/"):
                    continue
                if "%" in res:
                    continue  # 动态拼接的资源路径（如 assets/%s.png），运行时按 id 解析
                target = os.path.join(ROOT, res.replace("res://", ""))
                if not os.path.isfile(target):
                    warn("%s 引用的资源不存在：%s（运行时应优雅降级）" % (rel, res))


def main():
    _text, _auto = check_project()
    check_gd([])
    check_tscn()
    check_data()
    check_style_branches()
    check_progression_rules()
    check_res_paths()

    print("=" * 60)
    print("通天入地 · 静态校验")
    print("=" * 60)
    if WARNINGS:
        print("\n[警告] %d 条" % len(WARNINGS))
        for w in WARNINGS:
            print("  - " + w)
    if ERRORS:
        print("\n[错误] %d 条" % len(ERRORS))
        for e in ERRORS:
            print("  - " + e)
        print("\n结果：FAIL")
        return 1
    print("\n结果：PASS（0 错误，%d 警告）" % len(WARNINGS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
