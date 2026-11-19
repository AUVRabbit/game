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
                   "skill_1", "skill_2", "skill_3", "dash", "interact",
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
def check_data():
    data_dir = os.path.join(ROOT, "data")
    tables = {}
    for name in ["items", "classes", "recipes", "quests", "dialogue"]:
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

    if len(classes) != 12:
        err("职业数量应为 12，实际 %d" % len(classes))
    for cid, cdef in classes.items():
        if len(cdef.get("skills", [])) < 3:
            err("职业 %s 技能少于 3 个" % cid)
        for skill in cdef.get("skills", []):
            t = skill.get("type", "")
            if t not in ["melee_aoe", "projectile", "heal", "buff", "shield",
                         "chain", "aoe_zone", "dash_strike"]:
                err("职业 %s 技能 %s 使用了未实现的类型 %s" % (cid, skill.get("name"), t))
        color = cdef.get("color", "#000000")
        if not re.match(r"^#[0-9a-fA-F]{6}$", color):
            err("职业 %s 颜色格式错误：%s" % (cid, color))

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
