# 通天入地 — 技能/流派/机制 全量测试文档

> 版本要求：Godot 4.7.2.stable  
> 项目路径：`/workspace/通天入地`  
> 冒烟命令：`/tmp/Godot_v4.7.2-stable_linux.x86_64 --headless --path . tools/smoke_test.tscn`

---

## 0. 快速启动与冒烟

### 0.1 一键冒烟（全自动化，≈3 min）

```bash
cd /workspace/通天入地
# 重导入（改了 .gd 必须）
timeout 240 /tmp/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit-after 60
# 跑冒烟
timeout 180 /tmp/Godot_v4.7.2-stable_linux.x86_64 --headless --path . tools/smoke_test.tscn
# 看最终结果
timeout 180 /tmp/Godot_v4.7.2-stable_linux.x86_64 --headless --path . tools/smoke_test.tscn 2>&1 | grep "SMOKE_RESULT"
# 期望：SMOKE_RESULT failures=0
```

### 0.2 手动测试（启动主世界）

```bash
# 有图形环境时
/tmp/Godot_v4.7.2-stable_linux.x86_64 --path . scenes/world/main_world.tscn
# 无图形（xvfb-run 也可以）
xvfb-run -a /tmp/Godot_v4.7.2-stable_linux.x86_64 --path . scenes/world/main_world.tscn
```

### 0.3 测试环境准备（主世界内）

| 操作 | 快捷键 | 目的 |
|---|---|---|
| 切换出战角色 | `Q` / `P` | 轮流测 3 个队员 |
| 打开技能树 | `T` | 选流派 |
| 打开背包 | `I` | 看材料 |
| 冲刺 | `Space` | 位移技能 |
| 技能 1~6 | `1`~`6` | 释放技能 |
| 普攻 | 左键 | 基础攻击 |

### 0.4 测试专用 Debug 模式

在 `tools/smoke_runner.gd` 搜 `DEBUG` 或加一行：

```gdscript
# 强制把所有测试敌人 HP 设成 5，方便 1 招秒
for e in get_tree().get_nodes_in_group("enemies"):
    e.hp = 5
```

---

## 1. 技能类型通用测试（10 种）

所有职业的技能最终都归到这 10 种类型。每种的**最小验证集**：

### 1.1 projectile — 弹道/远程

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| P1 | 发射成功 | 按对应数字键 | 从手上飞出一个发光球体 + Line2D 拖尾 |
| P2 | 有方向 | 朝史莱姆按技能 | 飞行方向和瞄准一致 |
| P3 | 命中伤害 | 飞到敌人身上 | 伤害数字飘出 + 闪白 |
| P4 | 命中停顿 | 命中瞬间 | 整个画面卡 40-80ms（HitStop） |
| P5 | 穿透（若有 pierce） | 对准 2+ 敌人 | 第一个被穿过后继续飞 |
| P6 | 元素克制 | 用火技能打岩浆怪 | 飘字"免疫!"、伤害 0 |
| P7 | 元素克制（雷打史莱姆） | 用 chain 雷打史莱姆 | 伤害 ×1.5、但 stun 飘字"免疫!" |
| P8 | 融合版 | 融合槽点亮后释放 | 双色法阵起手 + 同帧元素爆发 |

**涉及职业**：法师、弓手、刺客（毒刃/爆发）、赏金（连射）、机甲（重炮）、工程师（普攻）

### 1.2 melee_aoe — 近战横扫

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| M1 | 扇形范围 | 按技能 | 身前圆形冲击波扩散 |
| M2 | 击退（若有 knockback） | 敌人贴脸 | 敌人被物理推开 |
| M3 | 震屏 | 命中 | 屏幕抖一下 |
| M4 | 三段动画 | 放技能看角色 | 蓄力（身体后倾）→ 前冲命中 → 收招回弹 |
| M5 | 背刺加成（thief_a） | 从敌人身后按技能 | 伤害数字明显变大（飘字没写但数字 ×1.5） |
| M6 | 破阵击退（warrior_c） | 用战士C打 | 敌人被推出更远 |
| M7 | 神圣冲锋（priest_b） | 贴远敌人 | 自己冲出去到敌人面前 |
| M8 | 狂战士低血（warrior_a） | 先让自己掉到 40% HP 以下 | 伤害 ×1.5、攻速变快 |

**涉及职业**：战士、祭司（神圣新星）、刺客（气劲掌）、义体（液压重拳）、赏金（缴械）、死亡骑士（血斩）、咒铠（符爆）

### 1.3 chain — 链式闪电/连射

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| C1 | 跳跃 | 场上 3 个敌人连起来 | 锯齿状闪电依次弹过去 |
| C2 | 最大跳数 | hacker_a（链神） | 最多跳 6 次（冒烟已验证 count=6） |
| C3 | 每次递增 | hacker_a | 每次命中伤害 +15%（第二次比第一次数字大） |
| C4 | 共生回蓝 | hacker_c（共生） | 每次命中 +20MP（放 1 次加 60MP） |
| C5 | 优先标记 | bounty_hunter_b（连环标记） | 先放 mark 再 chain，目标带标记的优先被跳 |
| C6 | 机械克制 | hacker_a chain 打机械蛛 | 飘字"克制!"、伤害 ×1.8 |
| C7 | 免疫雷元素敌人 | hacker_a chain 打岩浆怪 | 伤害 ×0.5（自定义 elemental_mods） |

**涉及职业**：hacker（全三系）、赏金（连射/弹幕压制）、亡灵（腐魂连矢）

### 1.4 aoe_zone — 预警+范围伤害

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| A1 | 预警圈 | 按陨星术 | 地面先出现红色圆环 + 下落特效 |
| A2 | 延迟爆炸 | 等 delay 秒后 | 陨石砸落冲击波扩散 |
| A3 | 爆炸命中 | 圈内敌人 | 伤害数字 + 震屏 + HitStop |
| A4 | trap_delay（archer_b） | 陷阱师放 AOE | 预警圈持续 +1 秒、伤害 ×1.3 |
| A5 | oppression（bounty_c） | 王者压迫放 AOE | 爆炸后中心再来 50% 冲击波 |
| A6 | plague_spread（necromancer_b） | 疫病蔓延放 AOE | 命中敌人获得瘟疫标记 mark_amp +15% |
| A7 | 元素克制 | 火 AOE 打岩浆怪 | 伤害 ×0.0 免疫 |

**涉及职业**：法师（陨星术）、弓手（箭雨/万箭）、咒铠（符文禁锢）、爆破（燃烧弹/集束）、祭司（圣愈光辉）

### 1.5 deployable — 炸弹/炮塔/地雷（抛物线飞行+落地）

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| D1 | 抛物线飞行 | 朝远处扔炸弹 | 炸弹从手上出发 → 弧线飞行 → 落地 |
| D2 | fuse 倒计时 | 落地后 | 炸弹闪烁火花 |
| D3 | 爆炸 | fuse 到点 | 冲击波扩散 + 碎片粒子 |
| D4 | chain_detonate（bomber_a） | 连环炸 | 第一枚爆完自动再投一枚 |
| D5 | scorched_earth（bomber_b） | 焦土 | AOE 留下 3s 持续燃烧地面（敌人站在上面持续掉血） |
| D6 | thermite_bomb（bomber_c） | 铝热剂 | deployable lifetime ×3、伤害 ×1.3 |
| D7 | turret_master（engineer_a） | 自动火炮 | 炮塔射速 ×2、伤害 +30% |
| D8 | supply_line（engineer_b） | 补给线 | buff 持续时间 ×1.3 |
| D9 | trap_master（sniper_b） | 连环陷阱 | deployable 部署 3 个 |
| D10 | 元素克制 | 炸弹（物）打幽魂 | 飘字"抵抗"、伤害 ×0.5 |

**涉及职业**：爆破（全三系）、工程师（炮塔）、赏金、狙击手

### 1.6 summon — 召唤物（消耗尸体）

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| S1 | 没尸体召唤 | 场上没敌人死过就按召唤 | 自动降级：召 1-2 只幽魂 + EventBus 提示"附近无尸体" |
| S2 | 消费尸体召唤 | 先杀 1 只史莱姆，再召唤 | 尸体消失动画（淡出）+ 召出水元素 |
| S3 | 骷髅弓手 | 杀机械蛛/骷髅兵 → 召唤 | 远程！射程 160、伤害 ×1.2 |
| S4 | 丧尸坦克 | 杀幽魂/植物怪 → 召唤 | 近战巨痛！伤害 ×1.4 |
| S5 | 火焰精灵 | 杀岩浆怪 → 召唤 | 火球魔法！伤害 ×1.35 |
| S6 | 雷电精灵 | 杀水元素 → 召唤 | chain 闪电！伤害 ×1.3 |
| S7 | 机械幽灵 | 杀机械蛛 boss → 召唤 | chain + 激光！伤害 ×1.25 |
| S8 | 暗影刺客 | 杀幽魂 → 召唤 | 超快 160 速 + 伤害 ×1.5、攻速 0.6s |
| S9 | 巨型亡灵 | 杀巨兽 → 召唤 | AOE + 击退、伤害 ×2.0 |
| S10 | minion_lord（necromancer_c） | 尸傀之王召唤 | 召唤数 ×2 + 伤害 +30% |
| S11 | 尸体腐化 | 等 30 秒 | 尸体自动消失 |
| S12 | 尸体不能重复用 | 召唤过之后 | 尸体消失后不能再召 |

### 1.7 shield — 护盾/吸收

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| SH1 | 吸收伤害 | 先开盾再挨打 | 伤害数字变成盾吸收（HP 不动、shield_hp 减） |
| SH2 | 持续时间 | 开盾后等 8 秒 | 护盾消失 |
| SH3 | reflect_shield（runeward_b） | 盾在的时候挨打 | 敌人也掉血（伤害反弹 40%） |
| SH4 | oath_shield（runeward_c） | 圣誓开盾 | 护盾吸收量 ×1.5（打满前不掉） |
| SH5 | formation_breaker（warrior_c） | 破阵开盾 | 护盾 ×0.8（比别人薄） |
| SH6 | 磁力风暴（cyborg_b） | 磁暴开盾 | 每吸收 100HP 触发环形 stun_wave |
| SH7 | 重甲（mech_pilot_a） | 重甲开盾 | 护盾 ×2、但移速 ×0.8 |

### 1.8 buff — 增益

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| B1 | stat 加成 | 战吼（attack +8）开了看面板 | 攻击力数值 +8 |
| B2 | 持续时间 | 开了之后等 duration | 效果消失、光环消失 |
| B3 | haste（attack_speed） | 气脉流转（attack_speed +18%） | 普攻频率变快 |
| B4 | 移速加成 | 疾风移速 buff | 角色移动明显变快 |
| B5 | dodge_rate | 烟雾弹（dodge +30%） | 挨打概率下降 |
| B6 | rune_duration（runeward_a） | 符阵永续开 buff | 持续时间 ×1.8（8 秒变 14.4 秒） |

### 1.9 heal — 治疗

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| H1 | 治疗 | HP 低时用治疗术 | HP 恢复 + 绿色飘字 "+数字" |
| H2 | piety_heal（priest_a） | 虔诚开治疗 | 治疗量 ×1.5（数字明显更大） |
| H3 | life_siphon（necromancer_a） | 亡灵法师弹道伤害 | 命中自己 +40% MP |
| H4 | heal_on_hit（qi_adept_a） | 以柔克刚近战 | 每次命中回血 = 伤害 ×8% |

### 1.10 dash_strike / blink_strike — 突进/闪现

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| D1 | 位移距离 | 伺服突进 | 瞬间跨过 135+ 像素 |
| D2 | 命中 | 路径上有敌人 | 撞到伤害数字 |
| D3 | ghost_trap（hacker_b） | 幽灵闪现 | blink 后目标位置生成嘲讽假身（或距离 ×1.3） |
| D4 | emp_overload（cyborg_a） | 电磁过载突进 | 35% 概率追加 chain 闪电 |
| D5 | afterimage（thief_c） | 残影 dash | 留下残影攻击 + melee 伤害 ×1.5 |
| D6 | holy_charge（priest_b） | 神圣冲锋近战 | 自动冲到目标面前 |

---

## 2. Signature 机制专属测试（16 职业 × 3 流派 = 48）

### 2.1 战士 Warrior

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| warrior_a 狂战士 | berserker | 让 HP 掉到 40% 以下，用旋风斩 | 伤害 ×1.5、普攻攻速 ×1.3（面板看） |
| warrior_b 剑圣 | sword_pierce | 用穿透射击（projectile/snipe） | pierce ≥5（多穿几个） |
| warrior_c 破阵者 | formation_breaker | 用旋风斩打敌人 | 击退 ×1.8、开盾时吸收 ×0.8（盾薄） |

### 2.2 咒铠师 Runeward

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| runeward_a 符阵永续 | rune_duration | 开战吼/祝福 | buff 持续时间 ×1.8（数秒数） |
| runeward_b 反噬 | reflect_shield | 开盾挨打 | 敌人被反弹 40% 伤害（敌人 HP 减） |
| runeward_c 圣誓 | oath_shield | 开盾 | 护盾吸收 ×1.5（比战士盾厚） |

### 2.3 祭司 Priest

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| priest_a 虔诚 | piety_heal | 用治疗术 | 治疗量 ×1.5 |
| priest_b 神圣冲锋 | holy_charge | 贴远敌人按近战 | 自己冲出去到敌人面前、伤害 ×1.2 |
| priest_c 苦修 | mortification | HP 掉到 50% 以下用技能 | 伤害 ×1.4；30% 以下 ×1.7 |

### 2.4 亡灵法师 Necromancer（核心：**尸体消耗召唤**）

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| necromancer_a 生命虹吸 | life_siphon | 用腐蚀箭打敌人 | 自己 +40% 伤害的 MP |
| necromancer_b 疫病蔓延 | plague_spread | 用亡者领域打敌人 | 命中敌人获得瘟疫标记（mark_left > 0）、后续所有伤害 +15% |
| necromancer_c 尸傀之王 | minion_lord | 有尸体时召唤 | 召数 ×2、伤害 +30%（冒烟验证召唤数 = 5 = 3+2） |

### 2.5 爆破专家 Bomber

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| bomber_a 连环炸 | chain_detonate | 放炸弹 | 第一枚爆完自动再投一枚 |
| bomber_b 焦土 | scorched_earth | 放 AOE | 原地留下 3s 燃烧地面（站在上面持续掉血） |
| bomber_c 铝热剂 | thermite_bomb | 放 deployable | 持续时间 ×3、伤害 ×1.3 |

### 2.6 机甲师 Mech Pilot

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| mech_pilot_a 重甲 | heavy_armor | 开盾 | 护盾 ×2、但移速 ×0.8 |
| mech_pilot_b 速射 | rapid_fire | 普攻弹道 | 每次 2 发、单发 ×0.7 |
| mech_pilot_c 要塞 | fortress | 看 CD | 技能 CD ×0.85、不能冲刺（Dash 键无反应） |

### 2.7 工程师 Engineer

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| engineer_a 自动火炮 | turret_master | 放炮塔 | 炮塔射速 ×2、召唤物伤害 +30% |
| engineer_b 补给线 | supply_line | 开 buff | buff 持续时间 ×1.3 |
| engineer_c 过载 | overload | 等 15 秒后 | 触发 4 秒伤害 ×1.5（有特效光环） |

### 2.8 赏金猎人 Bounty Hunter

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| bounty_hunter_a 悬赏 | mark_bounty | 放 mark | 标记持续 ×1.4、增伤 +30% |
| bounty_hunter_b 连环标记 | chain_mark_jump | 先 mark 再 chain | chain 优先跳跃到有 mark 的目标 |
| bounty_hunter_c 王者压迫 | oppression | 放 AOE | 爆炸后中心追加 50% 冲击波；非 AOE 技能 +12% |

### 2.9 死亡骑士 Death Knight

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| death_knight_a 饮血 | blood_drain | 打敌人 | 每次命中吸血 15% |
| death_knight_b 墓卫 | tomb_guard | 召唤物 | 召唤物数量 +1 |
| death_knight_c 血誓 | blood_oath | 治疗 | 治疗量的 30% 转为护盾 |

### 2.10 战士 Warrior（已在 2.1）

### 2.11 气宗 Qi Adept

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| qi_adept_a 以柔克刚 | heal_on_hit | 近战命中 | 回血 = 伤害 ×8% |
| qi_adept_b 罡气护体 | stun_wave_shield | 放 stun_wave | 获得 200HP 气盾 |
| qi_adept_c 疾风 | wind_sprint | 冲刺 | 不耗 CD，连续冲刺无停顿 |

### 2.12 小偷 Thief

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| thief_a 背刺 | backstab | 从敌人身后用近战/闪现 | 身后伤害 ×1.5、正面 ×0.7（飘字可能没写但数字明显不同） |
| thief_b 影遁 | shadow_walk | buff 后 | 移速 ×1.4 |
| thief_c 残影 | afterimage | dash/blink/melee | 伤害 ×1.5（冒烟已验证 melee_aoe） |

### 2.13 弓箭手 Archer

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| archer_a 精确 | precision_shot | 用 sniper/远距 | 射程 ×1.5 |
| archer_b 陷阱 | trap_delay | 放 AOE | 预警时间 +1s、伤害 ×1.3 |
| archer_c 连射 | rapid_shot | 每次 projectile | 放 2 发、单发 ×0.75 |

### 2.14 义体卫士 Cyborg

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| cyborg_a 电磁过载 | emp_overload | 用 dash_strike | 35% 概率追加 chain 闪电 |
| cyborg_b 磁暴 | magnetic_storm | 开盾挨打 | 每吸收 100HP 触发环形 stun_wave |
| cyborg_c 超频 | overclock | 普攻 + 技能 | 普攻攻速 ×1.4（character_base 里 get_attack_speed）、技能伤害 +8% |

### 2.15 Hacker

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| hacker_a 链神 | chain_master | 用 chain | 最多跳 6 次、每跳 +15% 伤害 |
| hacker_b 幽灵 | ghost_trap | 用 blink_strike | 距离 ×1.3（或生成嘲讽假身） |
| hacker_c 共生 | chain_symbiosis | 用 chain | 每次命中 +20MP |

### 2.16 狙击手 Sniper

| 流派 | kind | 测试操作 | 期望 |
|---|---|---|---|
| sniper_a 致命 | deadly_shot | 用 sniper | 伤害 ×1.4 |
| sniper_b 连环陷阱 | trap_master | 用 deployable | 部署 3 个 |
| sniper_c 致命一击 | first_strike | 满血敌人 vs 残血敌人 | 满血 ×1.6、非满血 ×0.85 |

---

## 3. 元素克制系统测试

### 3.1 克制表核心条目

**伤害元素来源**：普通技能 → `fire`（魔法）/ `physical`（物理），融合技 → 按元素 kind 映射

**关键预期（飘字提示）**：

| 攻击 | 敌人 | 预期倍率 | 飘字 |
|---|---|---|---|
| 火焰吐息 | 岩浆怪 | **×0.0** | 免疫! |
| 雷 chain | 史莱姆（水） | ×1.5 | 克制! + stun 免疫 |
| 物理攻击 | 幽魂 | ×0.5 | 抵抗 |
| 圣光 | 幽魂 | ×2.0 | 克制! |
| 雷 chain | 机械蛛 | ×1.8 | 克制!（短路） |
| 冰 | 岩浆怪 | ×1.5 | 克制!（冰克火） |
| 水弹 | 岩浆怪 | ×1.3 | 微克 |
| 火焰 | 冰元素 | ×1.5 | 克制! |
| 雷 | 雷元素 | ×0.0 | 免疫! |
| 同元素物理 vs 物理 | 物理 | 1.0 | 无飘字 |

### 3.2 状态免疫表

| 敌人 | 免疫 | 测试方法 |
|---|---|---|
| 史莱姆 | stun, knockback | 雷 chain 命中 → 伤害有、stun 飘字"免疫!" |
| 幽魂 | knockback, root | stun_wave 打 → 能 stun 但推不动 |
| 机械蛛 | （无） | 所有状态生效 |
| 岩浆怪 | slow, burn | 燃烧弹命中 → 伤害有、持续灼烧无效 |
| 骷髅兵 | （无） | 所有状态生效 |

### 3.3 自定义 elemental_mods（特殊覆盖默认克制）

岩浆怪有 `elemental_mods: {"fire": 0.0, "thunder": 0.5}` → **完全免疫火焰、雷伤减半**

---

## 4. 融合技测试（全新技能）

### 4.1 融合技必须满足

- ✅ 独立命名：`融·{元素}{主技能名}` （如 `融·炎穿透射击`）
- ✅ 独立染色：主色与元素色 lerp(0.45)
- ✅ 同帧元素爆发：命中瞬间在命中点触发元素效果
- ✅ 不是主+副叠加：删除了旧的 `_apply_fusion_keyword`

### 4.2 10 种融合元素效果（同帧触发）

| 元素 kind | 爆发形态 | 测试方法 | 期望 |
|---|---|---|---|
| burn | 火焰爆炸 | 融·炎火球打敌人 | 命中点爆火焰圈 |
| freeze | 冰刺爆发 | 融·冰新星 | 命中点冰刺 + 减速 |
| stun | 闪电链爆 | 融·雷 chain | 命中点锯齿闪电外扩 |
| corrosion | 腐蚀云 | 融·腐蚀箭 | 命中点绿色毒云 |
| root | 荆棘缠绕 | 融·藤 root_zone | 命中点荆棘圈 |
| holy | 圣光爆发 | 融·圣 melee | 命中点金色光环 |
| summon | 召唤爆发 | 融·幽 summon | 命中点召唤小亡灵 |
| knockback | 击退爆发 | 融·震近战 | 命中点冲击波外扩 |
| mark | 印记爆发 | 融·痕弹道 | 命中点红圈标记 |

### 4.3 融合的技能类型 + 融合元素映射（ElementKeeper）

| 融合 kind | → 伤害元素 |
|---|---|
| burn → fire | freeze → ice |
| stun → thunder | corrosion → nature |
| root → nature | holy → holy |
| summon → shadow | knockback → physical |
| mark → shadow |

---

## 5. 战斗手感测试（HitStop/震屏/动画）

### 5.1 HitStop 命中停顿

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| HS1 | 小伤害停顿 | 普攻命中 | 画面停 35-50ms（肉眼可见卡一下） |
| HS2 | 大伤害停顿 | 技能暴击命中 | 画面停 60-80ms |
| HS3 | 死亡长停 | 击杀敌人 | 画面停 90ms（最长的停） |
| HS4 | 连续命中叠加 | chain 打一群人 | 停顿总时长叠加，上限 140ms |
| HS5 | 停顿结束震屏 | 任何停顿结束 | 画面自动抖一下（延续手感） |

### 5.2 震屏（按伤害强度 1.0-5.0 倍）

| # | 测试 | 操作 | 期望 |
|---|---|---|---|
| SH1 | 小震屏 | 普攻命中 | ScreenShake.shake 4.5 级（微抖） |
| SH2 | 大震屏 | 陨星术爆 | 8-10 级（明显抖） |
| SH3 | 死亡震屏 | 击杀敌人 | 5.0 级（死亡最大震） |

### 5.3 SpriteAnim 三段式攻击动画

| 阶段 | 时间占比 | 效果 |
|---|---|---|
| **蓄力** | t < 0.22 | 身体后倾 + 缩小 + 旋转（弹簧效应） |
| **前冲命中** | 0.22 < t < 0.55 | 快速冲出去 + 伸展 + 大幅旋转（打击感核心帧！） |
| **收招** | t > 0.55 | 回到原位 + 惯性回弹 |

**测试方法**：按数字键放近战技能，盯着角色身体曲线看——
- 蓄力阶段应该"往回缩"
- 命中帧应该"猛地打出去"
- 收招应该有"回弹"的感觉

远程/法术动画是"拉弓蓄力 → 发射后坐 → 收招"，观察身体后倾/前倾。

### 5.4 受击反馈链（敌人被打时）

| 层 | 效果 | 测试 |
|---|---|---|
| ① HitStop | 画面停 | 见 5.1 |
| ② 震屏 | 屏幕抖 | 见 5.2 |
| ③ 击退 | 敌人物理位移 | 见 M2 |
| ④ 爆血粒子 | 6 片向外飞 | 敌人身上爆出彩色碎片 |
| ⑤ 闪白 | 敌人白色 | flash_timer = 0.12s |

### 5.5 死亡反馈链

| 层 | 效果 | 测试 |
|---|---|---|
| ① 大震屏 | 100 强度 | 击杀瞬间屏幕抖得很厉害 |
| ② 长 HitStop | 90ms | 击杀瞬间画面卡一下 |
| ③ 14 片尸体碎片 | 向外飞 + 重力 + 旋转 | 尸体爆开 → 飞散 → 下落 |
| ④ 8 个向上抛的血珠 | 重力下落 | 向上抛的小球 |
| ⑤ 生成尸体残留 | 30s 腐化 | 原地有 Corpse Node2D |

### 5.6 元素克制飘字反馈

命中瞬间飘在敌人头上：

| 飘字 | 条件 | 颜色 |
|---|---|---|
| **免疫!** | element_mult ≤ 0.01 | 暗蓝 (0.6, 0.6, 0.8) |
| 抵抗 | 0.01 < mult ≤ 0.5 | 浅蓝 (0.5, 0.85, 1.0) |
| （无飘字） | 0.5 < mult < 1.3 | - |
| 微克 | 1.3 ≤ mult < 1.5 | 橙黄 (1.0, 0.7, 0.3) |
| **克制!** | mult ≥ 1.5 | 金橙 (1.0, 0.85, 0.3) |

---

## 6. 冒烟脚本测试（全自动）

### 6.1 已覆盖的 smoke_runner.gd 检查

| 检查项 | 验证什么 | 期望 |
|---|---|---|
| 存在 48 种 signature | 每个流派有 kind | PASS |
| 16 职业 × 3 流派 机制各不相同 | 没有重复 kind | PASS |
| 总机制种类 ≥ 30 | 防止千篇一律 | PASS（当前 48 种）|
| 亡灵法师召唤有尸体 | minion_lord 消费尸体 | PASS |
| 弹道技能命中 | projectile 类型生效 | PASS |
| 护盾生效 | shield 类型生效 | PASS |
| 融合技为全新技能 | 不是主+副叠加 | PASS |
| 元素克制倍率 | multiplier(water, thunder) = 1.5 | PASS |
| HitStop Manager | autoload 注册 + hit() 可用 | PASS |
| 尸体生成 | 敌人死了有 Corpse Node2D | PASS |

### 6.2 冒烟的结构

```
smoke_runner.gd
├── 场景初始化 (main_world.tscn)
├── 队伍准备 (3 人)
├── 普攻验证 (dummy 掉血)
├── 技能释放验证 (各类型至少一个)
├── 护盾/治疗验证
├── 融合技验证
├── 流派机制验证
│   └── 48 流派 signature 逐一检查 kind 非空 + 三流派各不相同
├── 元素克制验证
│   └── ElementKeeper.multiplier 矩阵
├── 召唤尸体验证
└── 资源检查 (Inventory/Recipe/Quest/NPC 对话)
```

### 6.3 新增测试的写法

在 `tools/smoke_runner.gd` 末尾 `_check` 系列后面加：

```gdscript
# === 自定义测试区 ===
func _my_custom_test() -> void:
    _check("标题文字", condition, "详情")
    # ...
```

然后在 `_run()` 末尾调用 `_my_custom_test()`。

---

## 7. 测试 Checklist（回归测试打勾）

### 7.1 通用（每次改动必须过）

- [ ] `/tmp/Godot_v4.7.2-stable_linux.x86_64 --headless --path . tools/smoke_test.tscn` → `failures=0`
- [ ] headless editor reimport 无 Parse Error
- [ ] 所有技能类型至少一个可释放

### 7.2 元素克制回归

- [ ] 岩浆怪火焰吐息 → 0 伤害、飘字"免疫!"
- [ ] 雷打史莱姆 → 伤害 ×1.5、stun 飘字"免疫!"
- [ ] 圣光打幽魂 → 飘字"克制!"、伤害 ×2.0
- [ ] 物理打幽魂 → 飘字"抵抗"、伤害 ×0.5

### 7.3 召唤系统回归

- [ ] 没尸体 → 召幽魂
- [ ] 有尸体 → 尸体消失 + 召指定类型
- [ ] Corpse 30s 后消失
- [ ] 同一尸体只能用一次

### 7.4 Signature 回归

- [ ] 16 职业 × 3 流派 = 48 种机制互不相同
- [ ] signature desc 诚实反映代码实际行为（无夸大）
- [ ] oppression = AOE 追加 50% 冲击波
- [ ] backstab = 身后 ×1.5 / 正面 ×0.7（点积判断 caster 朝向）
- [ ] overclock = 普攻攻速 ×1.4（character_base.get_attack_speed）

### 7.5 战斗手感回归

- [ ] HitStop 命中停顿存在（画面肉眼可见的卡一下）
- [ ] 死亡 = 大震屏 + 长 HitStop + 爆粒子 + 尸体残留
- [ ] 近战攻击动画 = 蓄力前摇 → 前冲命中帧 → 收招回弹
- [ ] 敌人被打 = HitStop + 震屏 + 击退 + 爆粒子 + 闪白

### 7.6 冒烟自动覆盖

- [ ] `SMOKE_RESULT failures=0`

---

## 8. 常见问题排查

| 现象 | 原因 | 解决 |
|---|---|---|
| 冒烟输出 `Parse Error: Identifier X not declared` | .gd 改了没 reimport | `--editor --quit-after 60` |
| 冒烟输出 `SMOKE_RESULT failures=0` 但实际有问题 | 冒烟只覆盖核心路径 | 加手动测试 + 看 Verbose log |
| 技能放不出来（0 伤害） | 尸体找不到 or damage_element 推断 | 加 print 看 `corpses_nearby.size()` 和 `damage_element` |
| HitStop 没感觉 | paused 后 scene_tree 没恢复 | 检查 HitStop._process |
| 元素克制飘字没显示 | DamageNumber override 参数顺序 | 检查第 6/7 个参数（is_heal / override_text） |
| 尸体生成但召不出来 | 距离 220 搜不到 | 调 corpse_search_radius 或把尸体放更近 |

---

**文档版本**：v1.0（基于 commit ：全量 signature + 元素克制 + 尸体消耗召唤 + D3 战斗手感）
**最后更新**：2026-11-24
