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
        node_ids = {str(n.get("id", "")) for n in trees.get(cid, {}).get("nodes", [])}
        for skill in skills:
            t = skill.get("type", "")
            if t not in SKILL_TYPES:
                err("职业 %s 技能 %s 使用了未实现的类型 %s" % (cid, skill.get("name"), t))
            if not skill.get("desc"):
                err("职业 %s 技能 %s 缺少机制描述" % (cid, skill.get("name")))
            req = skill.get("requires", "")
            if req:
                if str(req) not in node_ids:
                    err("职业 %s 进阶技能 %s 的前置节点不存在：%s" % (cid, skill.get("id"), req))
                if not skill.get("advanced"):
                    err("职业 %s 技能 %s 有前置却未标记 advanced" % (cid, skill.get("id")))
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
    for cid in classes:
        nodes = trees.get(cid, {}).get("nodes", [])
        if len(nodes) != 16:
            err("职业 %s 技能树节点应为 16，实际 %d" % (cid, len(nodes)))
        ids = {str(n.get("id", "")) for n in nodes}
        active = 0
        for node in nodes:
            for req in node.get("requires", []):
                if str(req) not in ids:
                    err("职业 %s 节点 %s 的前置不存在：%s" % (cid, node.get("id"), req))
            if str(node.get("kind", "")) == "active":
                active += 1
            p = asset_path(str(node.get("icon", "")))
            if p and not os.path.isfile(p):
                err("职业 %s 技能树节点 %s 缺少图标素材：%s" % (cid, node.get("id"), node.get("icon")))
        if active != 3:
            err("职业 %s 进阶主动节点应为 3，实际 %d" % (cid, active))
        tiers = {int(n.get("tier", -1)) for n in nodes}
        if tiers != {0, 1, 2, 3, 4, 5}:
            err("职业 %s 技能树层级应覆盖 0..5，实际 %s" % (cid, sorted(tiers)))
        if not any(str(n.get("kind", "")) == "capstone" for n in nodes):
            err("职业 %s 技能树缺少终极节点" % cid)

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
