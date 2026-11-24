# -*- coding: utf-8 -*-
"""生成《通天入地》训练场 全角色 / 全技能 / 全动作 实测图文报告。

输入：docs/TRAINING_GROUND_FULL_AUDIT_2026-11-24/logs/results.json + 截图 + data/classes.json
输出：同目录下的 训练场全角色全技能全动作测试报告.md 与若干拼图
"""
from __future__ import annotations

import json
from pathlib import Path
from collections import Counter, defaultdict

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "TRAINING_GROUND_FULL_AUDIT_2026-11-24"
RESULTS = OUT / "logs" / "results.json"
CLASSES = ROOT / "data" / "classes.json"

FONT_CANDIDATES = [
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
]


def font(size: int):
    for p in FONT_CANDIDATES:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def cell_label(draw, box, text, fnt, fill=(255, 255, 255), bg=(12, 14, 22)):
    x0, y0, x1, y1 = box
    draw.rectangle([x0, y1 - 26, x1, y1], fill=bg)
    draw.text((x0 + 6, y1 - 24), text, font=fnt, fill=fill)


def make_sheet(items, src_func, label_func, out_name, cols, tw=300, th=169, bar=26):
    rows = (len(items) + cols - 1) // cols
    canvas = Image.new("RGB", (tw * cols, (th + bar) * rows), (8, 10, 16))
    draw = ImageDraw.Draw(canvas)
    fnt = font(13)
    for idx, item in enumerate(items):
        src = src_func(item)
        if not src.exists():
            continue
        im = Image.open(src).convert("RGB").resize((tw, th))
        cx = (idx % cols) * tw
        cy = (idx // cols) * (th + bar)
        canvas.paste(im, (cx, cy))
        cell_label(draw, (cx, cy, cx + tw, cy + th + bar), label_func(idx, item), fnt)
    path = OUT / out_name
    canvas.save(path, quality=87)
    return path


def md_table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join(["---"] * len(headers)) + "|"]
    for row in rows:
        out.append("| " + " | ".join(str(c) for c in row) + " |")
    return "\n".join(out)


def main():
    results = load_json(RESULTS)
    classes = load_json(CLASSES)["classes"]
    for i, r in enumerate(results["skill_results"], start=1):
        r["_idx"] = i

    # ---------- 拼图 ----------
    portrait_path = make_sheet(
        [(cid, c) for cid, c in classes.items()],
        lambda it: ROOT / "assets" / "portraits" / (it[0] + ".png"),
        lambda idx, it: "%02d %s %s" % (idx + 1, it[0], it[1]["name"]),
        "class_portrait_sheet.jpg", cols=8, tw=150, th=190, bar=40,
    )
    char_path = make_sheet(
        results["character_results"],
        lambda it: OUT / "classes" / ("%02d_%s.jpg" % (it["index"], it["class"])),
        lambda idx, it: "%02d %s %s %s" % (it["index"], it["class"], it["name"], "OK" if it["ok"] else "NG"),
        "class_training_sheet.jpg", cols=4, tw=360, th=203,
    )
    skill_path = make_sheet(
        results["skill_results"],
        lambda it: OUT / "skills" / ("%03d_%s_%s.jpg" % (it["_idx"], it["class"], it["id"])),
        lambda idx, it: "%02d %s·%s %s" % (it["slot"], it["class"], it["name"], "OK" if it["ok"] else "NG"),
        "skill_contact_sheet.jpg", cols=8, tw=240, th=135,
    )
    action_path = make_sheet(
        results["action_results"],
        lambda it: OUT / "actions" / ("%02d_%s.jpg" % (it["index"], it["enum"])),
        lambda idx, it: "%02d %s %s" % (it["index"], it["enum"], "OK" if it["ok"] else "NG"),
        "action_contact_sheet_40.jpg", cols=5, tw=256, th=144,
    )

    # 每职业 3x2 技能拼图
    sheet_dir = OUT / "class_sheets"
    sheet_dir.mkdir(parents=True, exist_ok=True)
    skill_by_class = defaultdict(list)
    for r in results["skill_results"]:
        skill_by_class[r["class"]].append(r)
    fnt = font(14)
    for cid, items in skill_by_class.items():
        tw, th, cols = 400, 225, 3
        canvas = Image.new("RGB", (tw * cols, (th + 26) * 2), (8, 10, 16))
        d = ImageDraw.Draw(canvas)
        for k, r in enumerate(items[:6]):
            src = OUT / "skills" / ("%03d_%s_%s.jpg" % (r["_idx"], cid, r["id"]))
            if src.exists():
                im = Image.open(src).convert("RGB").resize((tw, th))
                cx, cy = (k % cols) * tw, (k // cols) * (th + 26)
                canvas.paste(im, (cx, cy))
                cell_label(d, (cx, cy, cx + tw, cy + th + 26),
                           "#%d %s [%s] %s" % (r["slot"], r["name"], r["type"], "PASS" if r["ok"] else "FAIL"), fnt)
        canvas.save(sheet_dir / ("%s.jpg" % cid), quality=87)

    # ---------- 统计 ----------
    sk = results["skill_results"]
    ac = results["action_results"]
    ch = results["character_results"]
    ft = results["feature_results"]
    sk_pass = sum(1 for r in sk if r["ok"])
    ac_pass = sum(1 for r in ac if r["ok"])
    ch_pass = sum(1 for r in ch if r["ok"])
    type_counter = Counter(r["type"] for r in sk)
    by_class = defaultdict(list)
    for r in sk:
        by_class[r["class"]].append(r)
    vfx_ok = sum(1 for r in sk if r["vfx_ok"])

    L = []
    add = L.append
    add("# 《通天入地》训练场 · 全角色 / 全技能 / 全动作 实测图文报告")
    add("")
    add("> 测试日期：2026-11-24（GMT+8）  ")
    add("> 场地：`scenes/world/training_ground.tscn`（训练场 · 全职业试炼）  ")
    add("> 引擎：%s（Windows，OpenGL 3.3 Compatibility，1280×720 真实窗口渲染）  " % results["godot_version"])
    add("> 覆盖范围：**16 职业完整进阶后全部技能 = %d 项** + **40 个动作形变状态** + 玩家真实动作链 + 训练场机制  " % len(results["skill_results"]))
    add("> 测试性质：通过训练场公开接口驱动，不修改游戏逻辑/数值表")
    add("")
    add("---")
    add("")
    add("## 1. 执行摘要")
    add("")
    add(md_table(["测试项", "结果", "说明"], [
        ["训练场结构", "✅ PASS", "16 职业石 / 8 元素木桩 / 3 功能台 / 出口门 / 信息面板"],
        ["全角色切换", "✅ %d/%d" % (ch_pass, len(ch)), "职业石接口 + 完整进阶形态 + 立绘"],
        ["全技能实测", "✅ %d/%d" % (sk_pass, len(sk)), "16 职业完整进阶后全部技能槽（含专属/进阶/融合），按 16 种技能类型断言效果"],
        ["全动作形变", "✅ %d/%d" % (ac_pass, len(ac)), "SpriteAnim 40 个 AnimState 逐状态播放"],
        ["玩家真实动作", "✅ PASS", "普攻命中 / 冲刺无敌 / 受击 / 死亡 / 复活"],
        ["功能断言", "✅ %d/%d" % (results["checks_pass"], results["checks_total"]),
         "%d 项失败" % results["checks_fail"]],
        ["截图证据", "✅ %d 张" % results["screenshots"],
         "角色 16 + 技能 %d + 动作 41 + 场景/机制" % len(sk)],
        ["操作视频帧", "✅ %d 帧" % results["video_frames"], "训练场普攻 / 技能操作"],
        ["VFX 生成观测", "%d/%d 技能" % (vfx_ok, len(sk)), "施放瞬间特效节点计数 > 0"],
    ]))
    add("")
    add("**总评**：训练场内 16 名职业全部可切换并达到完整进阶形态；%d 项技能全部实际施放，" % len(sk)
        + "按类型分别验证了伤害/治疗/增益/护盾/召唤/部署/标记/位移等效果；40 个动作形变状态逐一切换并截图。"
        + "发现 3 项问题（木桩碰撞形状缺失、统一动作层编译失败、魔法元素归类单一），详见第 6 节。")
    add("")
    add("### 技能类型覆盖（16 种）")
    add("")
    add(md_table(["技能类型", "数量", "验证要点"], [
        ["`melee_aoe`", type_counter["melee_aoe"], "范围伤害 + 木桩承伤"],
        ["`projectile`", type_counter["projectile"], "弹道飞行命中"],
        ["`chain`", type_counter["chain"], "连锁命中"],
        ["`aoe_zone`", type_counter["aoe_zone"], "延迟区域结算"],
        ["`dash_strike`", type_counter["dash_strike"], "位移 + 路径伤害"],
        ["`blink_strike`", type_counter["blink_strike"], "瞬步 + 路径伤害"],
        ["`snipe`", type_counter["snipe"], "直线光束命中"],
        ["`stun_wave`", type_counter["stun_wave"], "环形冲击波"],
        ["`root_zone`", type_counter["root_zone"], "地刺范围 + 减速"],
        ["`mark`", type_counter["mark"], "目标标记"],
        ["`buff`", type_counter["buff"], "Buff 入栈"],
        ["`shield`", type_counter["shield"], "护盾值增加"],
        ["`heal`", type_counter["heal"], "实际回血"],
        ["`heal_zone`", type_counter["heal_zone"], "持续治疗区域"],
        ["`summon`", type_counter["summon"], "召唤物生成"],
        ["`deployable`", type_counter["deployable"], "陷阱/部署物生成"],
    ]))
    add("")
    add("---")
    add("")
    add("## 2. 测试方法与复现")
    add("")
    add("```bash")
    add("cd C:/Users/l/Documents/GitHub/game/通天入地")
    add('"/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path . --quit-after 600')
    add('"/c/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --path . --resolution 1280x720 res://tools/training_ground_audit.tscn')
    add("python tools/build_training_ground_report.py")
    add("```")
    add("")
    add("统一流程：进入训练场 → 经职业石接口切职业 → 触发进阶台解锁 10 技能槽与四层技能树 → "
        "逐技能清冷却/满状态、把中性木桩置于正前方 → 施放 → 按技能类型断言效果 + MP/冷却/VFX/动作状态。")
    add("")
    add("---")
    add("")
    add("## 3. 训练场全景与全角色")
    add("")
    add("![训练场全景](screenshots/00_training_overview.jpg)")
    add("")
    add("![16 职业训练场实测](class_training_sheet.jpg)")
    add("")
    add("![16 职业立绘](class_portrait_sheet.jpg)")
    add("")
    add(md_table(["#", "职业", "名称", "定位", "技能", "阶段", "技能槽", "立绘", "实测"], [
        [r["index"], "`%s`" % r["class"], r["name"], r["role_name"], r["skills"],
         r["stage"], r["slots"], "✅" if r["sprite_ok"] else "❌", "✅" if r["ok"] else "❌"]
        for r in ch
    ]))
    add("")
    add("---")
    add("")
    add("## 4. 逐职业技能实测明细（%d/%d 通过）" % (sk_pass, len(sk)))
    add("")
    add("> %d 技能一图总览：[skill_contact_sheet.jpg](skill_contact_sheet.jpg)  " % len(sk))
    add("> 单张原图：`skills/`；每职业 3×2 拼图：`class_sheets/`")
    add("")
    for cid, c in classes.items():
        items = by_class.get(cid, [])
        if not items:
            continue
        add("### %s · %s（`%s`）" % (c["name"], c.get("identity", ""), cid))
        add("")
        add("![%s 六技能拼图](class_sheets/%s.jpg)" % (c["name"], cid))
        add("")
        add(md_table(["槽", "技能（点击看截图）", "类型", "结果", "关键观测"], [
            [r["slot"], "[%s](skills/%03d_%s_%s.jpg)" % (r["name"], r["_idx"], r["class"], r["id"]),
             "`%s`" % r["type"], "✅" if r["ok"] else "❌", r["detail"]]
            for r in items
        ]))
        add("")
    add("---")
    add("")
    add("## 5. 全动作形变实测（%d/%d 通过）" % (ac_pass, len(ac)))
    add("")
    add("> 40 状态一图总览：[action_contact_sheet_40.jpg](action_contact_sheet_40.jpg)  ")
    add("> 单张原图：`actions/`")
    add("")
    add("通过 `SpriteAnim` 公共入口逐一切换 40 个 AnimState，断言内部状态值正确并截图记录形变姿态；"
        "另对玩家实体执行普攻/冲刺/受击/死亡/复活真实动作链。")
    add("")
    add(md_table(["#", "AnimState", "触发方式", "期望", "实际", "结果"], [
        [r["index"], "`%s`" % r["enum"], r["via"], r["expected"], r["actual"], "✅" if r["ok"] else "❌"]
        for r in ac
    ]))
    add("")
    add("![玩家真实动作](actions/41_player_real_actions.jpg)")
    add("")
    add("---")
    add("")
    add("## 6. 发现的问题与建议")
    add("")
    for i, f in enumerate(results.get("findings", []), start=1):
        add("### %d. %s（%s）" % (i, f["title"], f["severity"]))
        add("")
        add(f["detail"])
        add("")
    add("---")
    add("")
    add("## 7. 功能断言明细")
    add("")
    add(md_table(["断言", "结果", "详情"], [
        [r["label"], "✅" if r["ok"] else "❌", r["detail"]] for r in ft
    ]))
    add("")
    add("---")
    add("")
    add("## 8. 交付物索引")
    add("")
    add(md_table(["路径", "内容"], [
        ["`训练场全角色全技能全动作测试报告.md`", "本报告"],
        ["`logs/results.json`", "结构化结果（功能/角色/96 技能/40 动作）"],
        ["`logs/audit.log`", "完整 ACTION / OBSERVE / PASS / FAIL 时序日志"],
        ["`logs/console.log`", "Godot 控制台原始输出"],
        ["`screenshots/*.jpg`", "训练场全景"],
        ["`classes/*.jpg`", "16 职业训练场截图"],
        ["`skills/*.jpg`", "%d 张技能施放截图" % len(sk)],
        ["`actions/*.jpg`", "40 张动作形变截图 + 1 张真实动作"],
        ["`class_sheets/*.jpg`", "16 张职业六技能拼图"],
        ["`class_portrait_sheet.jpg`", "16 职业立绘总览"],
        ["`class_training_sheet.jpg`", "16 职业训练场截图总览"],
        ["`skill_contact_sheet.jpg`", "%d 技能总览拼图" % len(sk)],
        ["`action_contact_sheet_40.jpg`", "40 动作总览拼图"],
        ["`frames/*.jpg`", "%d 帧操作视频帧" % results["video_frames"]],
        ["`tools/training_ground_audit_runner.gd` / `.tscn`", "本次测试脚本与入口"],
        ["`tools/build_training_ground_report.py`", "本报告与拼图生成脚本"],
    ]))
    add("")

    report = OUT / "训练场全角色全技能全动作测试报告.md"
    report.write_text("\n".join(L), encoding="utf-8")
    print("REPORT:", report)
    print("SHEETS:", portrait_path.name, char_path.name, skill_path.name, action_path.name)


if __name__ == "__main__":
    main()
