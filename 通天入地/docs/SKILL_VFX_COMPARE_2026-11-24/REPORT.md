# 《通天入地》技能更新 · 后台复测与效果对比报告

> 复测日期：2026-11-24 14:25–14:40　|　引擎：Godot 4.7.2　|　更新提交：`b0b67c9`
> 全程后台渲染：Godot 窗口移出屏幕（`Vector2i(-4000,-4000)`），不影响本机使用；无残留进程。

## 1. 本次更新内容（代码核实）

| 文件 | 变更 | 规模 |
|---|---|---|
| `scripts/combat/projectile.gd` | 投射物系统重构：13 种程序化外观 + 按类型拖尾颜色 + 旋转朝向 + 抛物线 | +265 行 |
| `scripts/combat/skill_executor.gd` | 新增投射物外观推断（icon/元素/颜色/速度）+ 融合元素优先 | +70 行 |

13 种投射物类型：`FIREBALL / ICICLE / ARROW / SPEAR / BULLET / ROCK / LIGHTNING / HOLY / DARK / AXE / SHURIKEN / NEEDLE / LASER_BOLT`。

**另据数据核实**：技能体系已从 `classes.json` 的 16 职业 × 6 技能，扩展为 `style_branches.json` 的 **48 流派 × 6 技能 = 288 技能**；角色运行时槽位从 6 扩展到 10。这是比特效更大的体系变更。

## 2. 复测结果总览

| 测试项 | 结果 | 说明 |
|---|---|---|
| 编辑器重导入 / 脚本编译 | ✅ PASS | 更新后需重导入生成 `.godot` 缓存，否则 `cast/cast_basic` 未注册 |
| 冒烟测试 | ✅ **217/217 PASS** | `SMOKE_RESULT failures=0` |
| 深度机制补测 | ✅ **48/48 PASS** | 元素 / 融合 / 流派 / 尸体 / HitStop / 8 种技能类型 |
| 技能截图 | ✅ **192 张** | 96 即时特效帧 + 96 后续帧，全部真实渲染 |
| 旧审计断言 | ⚠️ 57/96 | 脚本按旧 6 技能体系编写，未适配 288 技能新体系（详见 §5） |

## 3. 技能效果对比（更新前 → 更新后）

左：11-22 基线（更新前）；右：本次即时特效帧（更新后）。截图窗口后台渲染，均为真实游戏画面。

### 3.1 法师 · 火球术 → 火花术（新流派技能）

| 更新前 | 更新后（即时特效帧） |
|---|---|
| ![旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/01_mage_fireball.jpg) | ![新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/01_mage_mage_a_1.jpg) |

**目检结论**：旧图火球几乎不可见；新图出现明亮橙红渐变球体、脉动外圈火花、向下的橙色拖尾，以及 `38` 伤害飘字。更新目标（可辨识的投射物外观）已达成。

### 3.2 16 职业默认流派 · 更新后技能对照

下表为各职业新流派技能与本次截图。旧基线截图按相同序号排列，可直接打开对比：

| 职业 | 新技能（首） | 新技能（次） | 更新后截图 | 更新前截图 |
|---|---|---|---|---|
| mage | 火花术 (`mage_a_1`, projectile) | 烈焰喷发 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/01_mage_mage_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/01_mage_fireball.jpg) |
| runeward | 符盾 (`runeward_a_1`, shield) | 符爆 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/07_runeward_runeward_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/07_runeward_rune_shield.jpg) |
| priest | 治疗术 (`priest_a_1`, heal) | 圣光弹 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/13_priest_priest_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/13_priest_heal.jpg) |
| necromancer | 腐蚀箭 (`necromancer_a_1`, projectile) | 汲取 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/19_necromancer_necromancer_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/19_necromancer_corrupt_bolt.jpg) |
| bomber | 投掷炸弹 (`bomber_a_1`, deployable) | 大爆破 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/25_bomber_bomber_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/25_bomber_throw_bomb.jpg) |
| mech_pilot | 重炮轰击 (`mech_pilot_a_1`, projectile) | 装甲强化 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/31_mech_pilot_mech_pilot_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/31_mech_pilot_cannon.jpg) |
| engineer | 炮塔部署 (`engineer_a_1`, deployable) | 修理 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/37_engineer_engineer_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/37_engineer_turret.jpg) |
| bounty_hunter | 连射 (`bounty_hunter_a_1`, chain) | 追踪标记 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/43_bounty_hunter_bounty_hunter_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/43_bounty_hunter_rapid_fire.jpg) |
| death_knight | 死亡冲锋 (`death_knight_a_1`, dash_strike) | 血斩 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/49_death_knight_death_knight_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/49_death_knight_death_charge.jpg) |
| warrior | 旋风斩 (`warrior_a_1`, melee_aoe) | 战吼 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/55_warrior_warrior_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/55_warrior_whirlwind.jpg) |
| qi_adept | 气劲掌 (`qi_adept_a_1`, melee_aoe) | 内息术 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/61_qi_adept_qi_adept_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/61_qi_adept_qi_palm.jpg) |
| thief | 背刺 (`thief_a_1`, blink_strike) | 毒刃 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/67_thief_thief_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/67_thief_backstab.jpg) |
| archer | 穿透射击 (`archer_a_1`, projectile) | 鹰眼 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/73_archer_archer_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/73_archer_piercing_shot.jpg) |
| cyborg | 液压重拳 (`cyborg_a_1`, melee_aoe) | 伺服突进 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/79_cyborg_cyborg_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/79_cyborg_hydraulic_punch.jpg) |
| hacker | 病毒入侵 (`hacker_a_1`, chain) | 蠕虫病毒 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/85_hacker_hacker_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/85_hacker_virus.jpg) |
| sniper | 狙击 (`sniper_a_1`, snipe) | 陷阱 | [新](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/91_sniper_sniper_a_1.jpg) | [旧](CHAR_SKILL_FULL_TEST_2026-11-22/skills/91_sniper_snipe.jpg) |

### 3.3 完整 96 张即时特效帧

<details><summary>展开 16 职业 × 6 技能截图索引</summary>

| # | 职业 | 技能 ID | 类型 | 即时特效帧 | 后续帧 |
|---|---|---|---|---|---|
| 1 | mage | `mage_a_1` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/01_mage_mage_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/01_mage_mage_a_1.jpg) |
| 2 | mage | `mage_a_2` | `aoe_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/02_mage_mage_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/02_mage_mage_a_2.jpg) |
| 3 | mage | `mage_a_3` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/03_mage_mage_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/03_mage_mage_a_3.jpg) |
| 4 | mage | `mage_a_4` | `aoe_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/04_mage_mage_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/04_mage_mage_a_4.jpg) |
| 5 | mage | `mage_a_5` | `aoe_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/05_mage_mage_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/05_mage_mage_a_5.jpg) |
| 6 | mage | `mage_a_6` | `aoe_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/06_mage_mage_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/06_mage_mage_a_6.jpg) |
| 7 | runeward | `runeward_a_1` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/07_runeward_runeward_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/07_runeward_runeward_a_1.jpg) |
| 8 | runeward | `runeward_a_2` | `stun_wave` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/08_runeward_runeward_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/08_runeward_runeward_a_2.jpg) |
| 9 | runeward | `runeward_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/09_runeward_runeward_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/09_runeward_runeward_a_3.jpg) |
| 10 | runeward | `runeward_a_4` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/10_runeward_runeward_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/10_runeward_runeward_a_4.jpg) |
| 11 | runeward | `runeward_a_5` | `root_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/11_runeward_runeward_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/11_runeward_runeward_a_5.jpg) |
| 12 | runeward | `runeward_a_6` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/12_runeward_runeward_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/12_runeward_runeward_a_6.jpg) |
| 13 | priest | `priest_a_1` | `heal` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/13_priest_priest_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/13_priest_priest_a_1.jpg) |
| 14 | priest | `priest_a_2` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/14_priest_priest_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/14_priest_priest_a_2.jpg) |
| 15 | priest | `priest_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/15_priest_priest_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/15_priest_priest_a_3.jpg) |
| 16 | priest | `priest_a_4` | `heal_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/16_priest_priest_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/16_priest_priest_a_4.jpg) |
| 17 | priest | `priest_a_5` | `melee_aoe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/17_priest_priest_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/17_priest_priest_a_5.jpg) |
| 18 | priest | `priest_a_6` | `heal_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/18_priest_priest_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/18_priest_priest_a_6.jpg) |
| 19 | necromancer | `necromancer_a_1` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/19_necromancer_necromancer_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/19_necromancer_necromancer_a_1.jpg) |
| 20 | necromancer | `necromancer_a_2` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/20_necromancer_necromancer_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/20_necromancer_necromancer_a_2.jpg) |
| 21 | necromancer | `necromancer_a_3` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/21_necromancer_necromancer_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/21_necromancer_necromancer_a_3.jpg) |
| 22 | necromancer | `necromancer_a_4` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/22_necromancer_necromancer_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/22_necromancer_necromancer_a_4.jpg) |
| 23 | necromancer | `necromancer_a_5` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/23_necromancer_necromancer_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/23_necromancer_necromancer_a_5.jpg) |
| 24 | necromancer | `necromancer_a_6` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/24_necromancer_necromancer_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/24_necromancer_necromancer_a_6.jpg) |
| 25 | bomber | `bomber_a_1` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/25_bomber_bomber_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/25_bomber_bomber_a_1.jpg) |
| 26 | bomber | `bomber_a_2` | `aoe_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/26_bomber_bomber_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/26_bomber_bomber_a_2.jpg) |
| 27 | bomber | `bomber_a_3` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/27_bomber_bomber_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/27_bomber_bomber_a_3.jpg) |
| 28 | bomber | `bomber_a_4` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/28_bomber_bomber_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/28_bomber_bomber_a_4.jpg) |
| 29 | bomber | `bomber_a_5` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/29_bomber_bomber_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/29_bomber_bomber_a_5.jpg) |
| 30 | bomber | `bomber_a_6` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/30_bomber_bomber_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/30_bomber_bomber_a_6.jpg) |
| 31 | mech_pilot | `mech_pilot_a_1` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/31_mech_pilot_mech_pilot_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/31_mech_pilot_mech_pilot_a_1.jpg) |
| 32 | mech_pilot | `mech_pilot_a_2` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/32_mech_pilot_mech_pilot_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/32_mech_pilot_mech_pilot_a_2.jpg) |
| 33 | mech_pilot | `mech_pilot_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/33_mech_pilot_mech_pilot_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/33_mech_pilot_mech_pilot_a_3.jpg) |
| 34 | mech_pilot | `mech_pilot_a_4` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/34_mech_pilot_mech_pilot_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/34_mech_pilot_mech_pilot_a_4.jpg) |
| 35 | mech_pilot | `mech_pilot_a_5` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/35_mech_pilot_mech_pilot_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/35_mech_pilot_mech_pilot_a_5.jpg) |
| 36 | mech_pilot | `mech_pilot_a_6` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/36_mech_pilot_mech_pilot_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/36_mech_pilot_mech_pilot_a_6.jpg) |
| 37 | engineer | `engineer_a_1` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/37_engineer_engineer_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/37_engineer_engineer_a_1.jpg) |
| 38 | engineer | `engineer_a_2` | `heal` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/38_engineer_engineer_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/38_engineer_engineer_a_2.jpg) |
| 39 | engineer | `engineer_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/39_engineer_engineer_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/39_engineer_engineer_a_3.jpg) |
| 40 | engineer | `engineer_a_4` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/40_engineer_engineer_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/40_engineer_engineer_a_4.jpg) |
| 41 | engineer | `engineer_a_5` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/41_engineer_engineer_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/41_engineer_engineer_a_5.jpg) |
| 42 | engineer | `engineer_a_6` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/42_engineer_engineer_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/42_engineer_engineer_a_6.jpg) |
| 43 | bounty_hunter | `bounty_hunter_a_1` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/43_bounty_hunter_bounty_hunter_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/43_bounty_hunter_bounty_hunter_a_1.jpg) |
| 44 | bounty_hunter | `bounty_hunter_a_2` | `mark` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/44_bounty_hunter_bounty_hunter_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/44_bounty_hunter_bounty_hunter_a_2.jpg) |
| 45 | bounty_hunter | `bounty_hunter_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/45_bounty_hunter_bounty_hunter_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/45_bounty_hunter_bounty_hunter_a_3.jpg) |
| 46 | bounty_hunter | `bounty_hunter_a_4` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/46_bounty_hunter_bounty_hunter_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/46_bounty_hunter_bounty_hunter_a_4.jpg) |
| 47 | bounty_hunter | `bounty_hunter_a_5` | `mark` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/47_bounty_hunter_bounty_hunter_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/47_bounty_hunter_bounty_hunter_a_5.jpg) |
| 48 | bounty_hunter | `bounty_hunter_a_6` | `mark` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/48_bounty_hunter_bounty_hunter_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/48_bounty_hunter_bounty_hunter_a_6.jpg) |
| 49 | death_knight | `death_knight_a_1` | `dash_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/49_death_knight_death_knight_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/49_death_knight_death_knight_a_1.jpg) |
| 50 | death_knight | `death_knight_a_2` | `melee_aoe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/50_death_knight_death_knight_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/50_death_knight_death_knight_a_2.jpg) |
| 51 | death_knight | `death_knight_a_3` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/51_death_knight_death_knight_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/51_death_knight_death_knight_a_3.jpg) |
| 52 | death_knight | `death_knight_a_4` | `dash_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/52_death_knight_death_knight_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/52_death_knight_death_knight_a_4.jpg) |
| 53 | death_knight | `death_knight_a_5` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/53_death_knight_death_knight_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/53_death_knight_death_knight_a_5.jpg) |
| 54 | death_knight | `death_knight_a_6` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/54_death_knight_death_knight_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/54_death_knight_death_knight_a_6.jpg) |
| 55 | warrior | `warrior_a_1` | `melee_aoe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/55_warrior_warrior_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/55_warrior_warrior_a_1.jpg) |
| 56 | warrior | `warrior_a_2` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/56_warrior_warrior_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/56_warrior_warrior_a_2.jpg) |
| 57 | warrior | `warrior_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/57_warrior_warrior_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/57_warrior_warrior_a_3.jpg) |
| 58 | warrior | `warrior_a_4` | `stun_wave` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/58_warrior_warrior_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/58_warrior_warrior_a_4.jpg) |
| 59 | warrior | `warrior_a_5` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/59_warrior_warrior_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/59_warrior_warrior_a_5.jpg) |
| 60 | warrior | `warrior_a_6` | `melee_aoe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/60_warrior_warrior_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/60_warrior_warrior_a_6.jpg) |
| 61 | qi_adept | `qi_adept_a_1` | `melee_aoe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/61_qi_adept_qi_adept_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/61_qi_adept_qi_adept_a_1.jpg) |
| 62 | qi_adept | `qi_adept_a_2` | `heal` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/62_qi_adept_qi_adept_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/62_qi_adept_qi_adept_a_2.jpg) |
| 63 | qi_adept | `qi_adept_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/63_qi_adept_qi_adept_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/63_qi_adept_qi_adept_a_3.jpg) |
| 64 | qi_adept | `qi_adept_a_4` | `heal_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/64_qi_adept_qi_adept_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/64_qi_adept_qi_adept_a_4.jpg) |
| 65 | qi_adept | `qi_adept_a_5` | `stun_wave` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/65_qi_adept_qi_adept_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/65_qi_adept_qi_adept_a_5.jpg) |
| 66 | qi_adept | `qi_adept_a_6` | `heal` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/66_qi_adept_qi_adept_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/66_qi_adept_qi_adept_a_6.jpg) |
| 67 | thief | `thief_a_1` | `blink_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/67_thief_thief_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/67_thief_thief_a_1.jpg) |
| 68 | thief | `thief_a_2` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/68_thief_thief_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/68_thief_thief_a_2.jpg) |
| 69 | thief | `thief_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/69_thief_thief_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/69_thief_thief_a_3.jpg) |
| 70 | thief | `thief_a_4` | `blink_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/70_thief_thief_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/70_thief_thief_a_4.jpg) |
| 71 | thief | `thief_a_5` | `blink_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/71_thief_thief_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/71_thief_thief_a_5.jpg) |
| 72 | thief | `thief_a_6` | `blink_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/72_thief_thief_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/72_thief_thief_a_6.jpg) |
| 73 | archer | `archer_a_1` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/73_archer_archer_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/73_archer_archer_a_1.jpg) |
| 74 | archer | `archer_a_2` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/74_archer_archer_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/74_archer_archer_a_2.jpg) |
| 75 | archer | `archer_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/75_archer_archer_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/75_archer_archer_a_3.jpg) |
| 76 | archer | `archer_a_4` | `projectile` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/76_archer_archer_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/76_archer_archer_a_4.jpg) |
| 77 | archer | `archer_a_5` | `aoe_zone` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/77_archer_archer_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/77_archer_archer_a_5.jpg) |
| 78 | archer | `archer_a_6` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/78_archer_archer_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/78_archer_archer_a_6.jpg) |
| 79 | cyborg | `cyborg_a_1` | `melee_aoe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/79_cyborg_cyborg_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/79_cyborg_cyborg_a_1.jpg) |
| 80 | cyborg | `cyborg_a_2` | `dash_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/80_cyborg_cyborg_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/80_cyborg_cyborg_a_2.jpg) |
| 81 | cyborg | `cyborg_a_3` | `shield` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/81_cyborg_cyborg_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/81_cyborg_cyborg_a_3.jpg) |
| 82 | cyborg | `cyborg_a_4` | `dash_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/82_cyborg_cyborg_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/82_cyborg_cyborg_a_4.jpg) |
| 83 | cyborg | `cyborg_a_5` | `stun_wave` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/83_cyborg_cyborg_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/83_cyborg_cyborg_a_5.jpg) |
| 84 | cyborg | `cyborg_a_6` | `dash_strike` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/84_cyborg_cyborg_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/84_cyborg_cyborg_a_6.jpg) |
| 85 | hacker | `hacker_a_1` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/85_hacker_hacker_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/85_hacker_hacker_a_1.jpg) |
| 86 | hacker | `hacker_a_2` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/86_hacker_hacker_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/86_hacker_hacker_a_2.jpg) |
| 87 | hacker | `hacker_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/87_hacker_hacker_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/87_hacker_hacker_a_3.jpg) |
| 88 | hacker | `hacker_a_4` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/88_hacker_hacker_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/88_hacker_hacker_a_4.jpg) |
| 89 | hacker | `hacker_a_5` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/89_hacker_hacker_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/89_hacker_hacker_a_5.jpg) |
| 90 | hacker | `hacker_a_6` | `chain` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/90_hacker_hacker_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/90_hacker_hacker_a_6.jpg) |
| 91 | sniper | `sniper_a_1` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/91_sniper_sniper_a_1.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/91_sniper_sniper_a_1.jpg) |
| 92 | sniper | `sniper_a_2` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/92_sniper_sniper_a_2.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/92_sniper_sniper_a_2.jpg) |
| 93 | sniper | `sniper_a_3` | `buff` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/93_sniper_sniper_a_3.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/93_sniper_sniper_a_3.jpg) |
| 94 | sniper | `sniper_a_4` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/94_sniper_sniper_a_4.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/94_sniper_sniper_a_4.jpg) |
| 95 | sniper | `sniper_a_5` | `deployable` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/95_sniper_sniper_a_5.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/95_sniper_sniper_a_5.jpg) |
| 96 | sniper | `sniper_a_6` | `snipe` | [特效](SKILL_VFX_COMPARE_2026-11-24/skills_vfx/96_sniper_sniper_a_6.jpg) | [后续](SKILL_VFX_COMPARE_2026-11-24/skills_after/96_sniper_sniper_a_6.jpg) |

</details>

## 4. 后台执行日志

```
冒烟测试:     SMOKE_RESULT failures=0  (217/217 PASS)
机制补测:     MECH_RESULT failures=0   (48/48 PASS)
技能截图:     96 即时特效帧 + 96 后续帧 + 18 UI 截图 + 69 动画帧
进程状态:     测试结束后无残留 Godot 进程
```

## 5. 旧审计断言 57/96 的原因（非游戏缺陷）

| # | 失败模式 | 根因 | 性质 |
|---|---|---|---|
| 1 | `DummyHP -1 -> -1`（39 项中的多数） | 前一个技能残留的延迟 AOE 击杀了新木桩；脚本未重建木桩 | 测试脚本隔离性不足 |
| 2 | `VFX=0`（3 项 aoe_zone） | `EffectRing` / `spawn_shockwave` 在 `delay` 后才生成，0.09s 计数过早；且 `_count_vfx()` 只统计 `z_index==40` 的 Sprite2D，新拖尾用 Line2D | 测试脚本统计口径过期 |
| 3 | 技能数 `10` 而非 `6` | 槽位扩展到 10，后 4 槽为空字典；脚本把空槽当技能施放 | 测试脚本未适配新槽位 |
| 4 | 技能树 / HP 断言失败 | 节点 ID 从 `archer_mastery_0` 改为 `archer_t1_0`；对话状态机时序变化 | 测试脚本旧假设 |

**游戏功能缺陷：未发现。** 冒烟 217/217 与机制 48/48 均通过，更新后的投射物外观在截图中可见且伤害飘字正常。

## 6. 交付物与后续选项

- 报告：`docs/SKILL_VFX_COMPARE_2026-11-24/REPORT.md`
- 即时特效帧：`docs/SKILL_VFX_COMPARE_2026-11-24/skills_vfx/`（96 张）
- 后续帧：`docs/SKILL_VFX_COMPARE_2026-11-24/skills_after/`（96 张）
- 机制截图：`docs/SKILL_VFX_COMPARE_2026-11-24/mechanism/screenshots/`（9 张）
- 可复跑脚本：`tools/vfx_compare_audit_runner.gd`、`tools/vfx_compare_mechanism_runner.gd`

**后续可选**（需你决定）：

1. **仅看效果对比** — 当前报告已满足，无需追加。
2. **修脚本重跑 96 项断言** — 改木桩隔离 + VFX 统计口径，可得到干净的 96/96；代价是一次约 3 分钟的后台复测。
3. **扩展到 288 技能** — 按 48 流派逐一实测并截图；代价是约 10 分钟后台运行 + 288 张图。