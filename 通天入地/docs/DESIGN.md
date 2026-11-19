# 《通天入地》设计方案

> 版本：1.0　|　引擎：Godot **4.7.2-stable**（`config/features="4.7.2"`，`.godot-version` 固定）　|　语言：GDScript
> 对应工程目录：`/workspace/通天入地`

---

## 1. 设计目标

| 目标 | 落地方式 |
| --- | --- |
| 四朋克混搭世界 | 12 个职业覆盖法术 / 机械 / 武道 / 科技四类幻想；技能特效、装备与建筑均数据驱动 |
| 2D 等距开放世界 | 主世界使用等距投影绘制，坐标转换 `grid_to_world / world_to_grid` 统一在 BuildManager |
| 向上通天塔、向下深渊 | 同一套程序化楼层场景，楼层号正数通天、负数入地，0 表示地面 |
| 12 职业自由切换 | 队伍最多 12 人，Q/P 实时切换；职业祭坛消耗金币逐个解锁 |
| 实时动作战斗 | 普攻 + 3 技能 + 冲刺，冷却、法力、暴击、闪避、护盾、增益全部生效 |
| 混合经济 | 资源点采集 → 配方合成 → 商店买卖 → 敌人掉落，四种来源闭环 |
| 沙盒建造 | 等距网格放置 / 拆除建筑，消耗材料、50% 返还、按场景持久化 |
| Roguelike 支线 | 通天塔即 Roguelike 层，每 3 层随机词条，每 5 层 BOSS，死亡结束本轮 |
| 解谜 | 环境采集、职业限定机关、限时机关、任务/对话元解谜 |
| 键鼠 / 手柄 / 触屏 | 输入映射 + InputManager 设备识别 + TouchControls 虚拟摇杆与按钮 |
| 菜单 / 关卡 / 存档 | 主菜单、暂停菜单、JSON 存档、完整状态快照 |
| 像素占位美术 | 全部角色、敌人、建筑、特效使用 Polygon2D / `_draw` 程序化占位，无需外部素材 |

---

## 2. 工程结构

```
通天入地/
├── project.godot                 # 9 个 Autoload、输入映射、960×540 视口
├── data/                         # 纯 JSON 数据表（可热改）
│   ├── items.json                # 25 件物品
│   ├── classes.json              # 12 职业 + 成长
│   ├── recipes.json              # 15 条配方
│   ├── quests.json               # 3 条任务
│   └── dialogue.json             # 2 个 NPC 对话
├── scenes/
│   ├── main.tscn                 # 启动入口，仅挂 main.gd
│   ├── player/player.tscn        # CharacterBody2D + CharacterData
│   ├── enemies/enemy.tscn        # 通用敌人
│   ├── world/main_world.tscn     # 开放世界
│   ├── world/tower_floor_1.tscn  # 通天塔/深渊通用楼层
│   └── ui/                       # HUD、背包、建造、暂停、对话、触屏、GameUI 聚合
├── scripts/
│   ├── globals/                  # 9 个 Autoload
│   ├── player/                   # CharacterBase、PlayerController
│   ├── combat/                   # SkillExecutor、Projectile、EffectRing、DamageNumber
│   ├── enemies/                  # EnemyBase、EnemySpawner
│   ├── economy/inventory.gd      # 40 格背包、合成、商店
│   ├── world/                    # 世界、塔层、NPC、传送门、机关、资源点、祭坛、建筑块
│   └── ui/                       # 全部界面（代码构建）
├── tools/
│   ├── validate_project.py       # 静态结构校验
│   ├── smoke_test.tscn/.gd       # 无头冒烟测试入口
│   └── smoke_runner.gd           # 27 项自动化验收
└── docs/
    ├── DESIGN.md                 # 本文
    └── VERIFICATION.md           # 验证方案
```

### 2.1 Autoload 职责

| 顺序 | 名称 | 文件 | 职责 |
| --- | --- | --- | --- |
| 1 | DataManager | `scripts/globals/data_manager.gd` | 启动加载全部 JSON，提供只读查询 |
| 2 | EventBus | `scripts/globals/event_bus.gd` | 全局信号与提示（toast） |
| 3 | AudioManager | `scripts/globals/audio_manager.gd` | BGM/SFX，缺素材时静默降级 |
| 4 | GameManager | `scripts/globals/game_manager.gd` | 状态机、队伍、金币、场景切换、存档快照 |
| 5 | InputManager | `scripts/globals/input_manager.gd` | 键鼠/手柄/触屏识别、虚拟摇杆、等距移动向量 |
| 6 | SaveManager | `scripts/globals/save_manager.gd` | `user://saves/save_N.json` 读写 |
| 7 | BuildManager | `scripts/globals/build_manager.gd` | 等距网格坐标、放置/拆除、按场景持久化 |
| 8 | QuestManager | `scripts/globals/quest_manager.gd` | 任务接取/计数/完成/奖励 |
| 9 | RoguelikeManager | `scripts/globals/roguelike_manager.gd` | 轮次种子、层数、随机词条、结算 |

> 约束：Autoload 脚本一律不写 `class_name`，避免全局类名与单例名冲突。

### 2.2 事件总线

`EventBus.emit_event(signal_name, args)` 内部使用 `emit_signal.callv([signal_name] + args)`，用于动态派发。
已定义信号覆盖：玩家出生/受伤/死亡/升级、切换职业、攻击、施法、敌人死亡、物品掉落/拾取、方块放置/破坏、建筑放置/移除、机关触发、关卡完成、传送、背包/金币变化、合成/出售、对话、任务、提示、存读档、Roguelike 开始/结束。

### 2.3 状态机

`GameManager.GameState`：`MENU / PLAYING / PAUSED / DIALOG / INVENTORY / BUILDING / DEAD`。
`is_input_blocked()` 在非 `PLAYING` 时返回 `true`，玩家与建造输入统一被拦截；界面节点使用 `PROCESS_MODE_ALWAYS` 保证暂停时仍可操作。

---

## 3. 数据层设计

### 3.1 物品 `data/items.json`

```json
{
  "id": "healing_potion",
  "name": "治疗药水",
  "type": "consumable",
  "description": "恢复 40 点生命",
  "stackable": true,
  "max_stack": 20,
  "color": "#e05353",
  "effect": { "hp": 40 }
}
```

| 字段 | 说明 |
| --- | --- |
| `type` | `material / consumable / building / weapon / armor / accessory / key` |
| `stackable` / `max_stack` | 堆叠规则 |
| `effect` | 消耗品效果：`hp` / `mp` |
| `craft_cost` | 建筑造价；同时用于建造面板显示 |
| `slot` / `stats` | 装备槽位与属性加成（`attack`、`defense`、`max_hp` 等） |

### 3.2 职业 `data/classes.json`

```json
{
  "id": "mage",
  "name": "法师",
  "color": "#5a7bff",
  "max_hp": 90, "max_mp": 120,
  "attack": 6, "defense": 3, "magic_attack": 22, "magic_defense": 12,
  "move_speed": 190, "attack_speed": 1.0,
  "crit_rate": 0.06, "crit_damage": 1.5, "dodge_rate": 0.02,
  "skills": [
    { "id": "fireball", "name": "火球术", "type": "projectile",
      "cd": 1.6, "mp": 10, "power": 1.9, "speed": 420, "color": "#ff8844" }
  ]
}
```

全局 `growth` 定义每级成长（生命 +16、法力 +6、攻击 +3、防御 +2、法攻 +3、法防 +1）。

### 3.3 配方 / 任务 / 对话

* 配方：`{ "id", "output", "count", "cost": { "iron_ore": 2, "coal": 1 } }`
* 任务目标类型：`kill`（敌人类型）、`craft`（物品 id）、`reach_floor`（层号字符串）
* 任务奖励：`{ "gold": 80, "items": { "healing_potion": 2 } }`
* 对话：`{ "npc_id": { "name", "lines": [], "quest": "q_slime_hunt" } }`

---

## 4. 模块设计

### M1 角色与职业

* **关键文件**：`character_base.gd`、`player_controller.gd`、`data/classes.json`、`class_altar.gd`
* **属性计算**：`基础值 + 等级成长 + 装备加成 + Buff 加成`，由 `recompute()` 统一重算。
* **12 职业**：

| 职业 | 流派 | 定位 | 技能（类型） |
| --- | --- | --- | --- |
| 战士 | 武道 | 近战坦克 | 旋风斩（范围）、战吼（增益）、盾墙（护盾） |
| 弓箭手 | 武道/科技 | 远程持续 | 穿透射击（弹道）、箭雨（区域）、鹰眼（增益） |
| 法师 | 法术 | 法术爆发 | 火球术（弹道）、冰霜新星（范围）、奥术护盾（护盾） |
| 牧师 | 法术 | 治疗辅助 | 治疗术（治疗）、神圣新星（范围）、祝福（增益） |
| 亡灵法师 | 法术 | 持续伤害 | 腐蚀箭（弹道）、亡者领域（区域）、汲取（治疗） |
| 死亡骑士 | 法术/武道 | 突进战士 | 死亡冲锋（突进）、血斩（范围）、黑暗护盾（护盾） |
| 小偷 | 武道 | 高闪避爆发 | 背刺（范围）、烟雾弹（增益）、毒刃（弹道） |
| 狙击手 | 科技 | 超远单体 | 狙击（弹道）、陷阱（区域）、精准（增益） |
| 炸弹专家 | 机械 | 范围爆破 | 投掷炸弹（区域）、爆破领域（区域）、燃烧弹（范围） |
| 黑客 | 科技 | 连锁控制 | 病毒入侵（连锁）、EMP 脉冲（范围）、系统过载（增益） |
| 机甲师 | 机械 | 重装炮台 | 重炮轰击（弹道）、装甲强化（护盾）、能量护盾（增益） |
| 赏金猎人 | 混合 | 机动连击 | 连射（连锁）、追踪标记（增益）、缴械（范围） |

* **切换**：`Q` 下一位 / `P` 上一位，切换时保留各自血量、法力、等级与装备；未出战角色隐藏并关闭碰撞。
* **解锁**：初始 3 人（战士/弓箭手/法师）；主世界职业祭坛每次 150 金币解锁下一位，直至 12 人。
* **升级**：经验满后循环升级，`exp_to_next *= 1.25`，升级回满血蓝并广播 `player_leveled_up`。

### M2 战斗

* **普攻**：以角色为圆心 56 半径范围判定，受攻击力、暴击率、暴击伤害影响。
* **技能**：`SkillExecutor.cast()` 校验法力后按 `type` 分派：

| 类型 | 实现 |
| --- | --- |
| `melee_aoe` | 以角色为中心的圆形范围伤害 + 特效环 |
| `projectile` | 生成 `projectile.gd`，直线飞行，命中敌人层（layer 4） |
| `heal` | 恢复自身生命，飘绿字 |
| `buff` | 限时属性增益（攻击/移速等） |
| `shield` | 增加临时护盾值，优先吸收伤害 |
| `chain` | 依次跳跃至最近敌人，逐次衰减 |
| `aoe_zone` | 在目标点生成持续区域，延迟后结算多段伤害 |
| `dash_strike` | 向朝向瞬移并造成路径伤害 |

* **冷却/法力**：每个技能独立冷却，HUD 三个技能槽实时显示剩余秒数；法力不足提示且不进入冷却。
* **伤害公式**：`max(1, 攻击或法攻 × 技能倍率 × (1 + Buff) - 防御 × 0.5)`；暴击 ×1.5；闪避则 0 伤害。
* **死亡**：非 Roguelike 场景 1.2 秒后在出生点复活并恢复 50% 生命；Roguelike 中死亡结束本轮并回到主菜单。
* **表现**：`DamageNumber` 上浮淡出、`EffectRing` 扩散圆环、角色受击闪白。

### M3 敌人与刷怪

* **EnemyBase**：巡逻 → 侦测（`detect_range`）→ 追击 → 进入 `attack_range` 后按 `attack_cooldown_time` 攻击。
* **数值**：导出属性支持刷怪点按字典覆盖（生命、攻击、防御、法防、经验、金币、颜色、体型、掉落表、BOSS 标记）。
* **掉落**：按 `drop_table` 概率生成 `pickup.gd`，玩家接触后自动入包；掉落物挂到世界根节点，不占用刷怪点存活计数。
* **刷怪点**：上限 `max_alive`、初始数量、半径随机刷新、`respawn_time` 复活。
* **Roguelike 缩放**：`EnemyBase` 读取 `enemy_power()`、`hp_scale()`；`EnemySpawner` 读取额外精英数量。

### M4 经济

* **背包**：40 格，支持堆叠、空格查找、使用、装备/卸下、合成、买卖；所有变更广播 `inventory_changed`。
* **采集**：主世界 8 个资源点（木头、石头、草药、铁矿、皮革），按 `E` 采集，8 秒重生，消耗品/材料可叠加。
* **合成**：`recipes.json` 15 条配方，材料不足时按钮禁用；成功后触发 `item_crafted`，可推进任务。
* **商店**：背包面板第三页，固定货架（药水、基础材料等），按物品价值买卖，金币不足/背包满均有提示。
* **装备**：武器/护甲/饰品按槽位替换，属性即时生效，旧装备退回背包。

### M5 建造

* **网格**：等距菱形，`grid_to_world(Vector2i) = ((x-y)*32, (x+y)*16)`，反向 `world_to_grid` 四舍五入。
* **进入**：`B` 切换建造模式，打开建造面板，滚轮/按钮切换当前方块。
* **放置**：左键点击地面，检查材料与占位，扣除 `craft_cost`，生成 `build_block.gd`（菱形 + 顶部高光，可碰撞方块附带 `StaticBody2D`）。
* **拆除**：右键点击，返还 50% 材料，从存档记录移除。
* **持久化**：`builds` 以场景路径为键；`restore_scene(level)` 在关卡 `_ready` 时重建；新游戏 / Roguelike 开始时清空。
* **UI 防误触**：鼠标位于任何 GUI 控件上时不执行放置/拆除。

### M6 世界与关卡

* **主世界**：程序化菱形地面 + 网格线；3 个刷怪点（史莱姆 / 机械蛛 / 幽魂）、2 个 NPC、8 个资源点、职业祭坛、通天塔传送门。
* **通天塔 / 深渊**：`tower_floor.gd` 用 `floor_num` 生成：
  * `depth = |floor_num|`，层数越高/越深，机关更多、敌人更强；
  * 环形分布 2–4 个机关，全部激活前门锁住、上层传送门禁用；
  * 正数层显示「通天塔 · 第 N 层」，负数层显示「深渊 · 第 N 层」；
  * 每层都有向下传送门：1 层向下进入深渊 -1 层，其余层向下 `floor_num - 1`；向上 `floor_num + 1`，到 0 即返回地面；
  * 每 5 层生成 BOSS（生命/攻击/掉落大幅提升）。
* **场景流转**：`main → main_menu → main_world ⇄ tower_floor_1`；`GameManager.change_scene()` 使用延迟切换，避免在 `_ready` 中移除场景导致崩溃。

### M7 解谜

| 类型 | 实现 |
| --- | --- |
| 环境解谜 | 资源点采集、建筑拆除、地形机关门 |
| 职业限定 | 塔层 2 的 0 号机关必须由法师（`class_id == "mage"`）踩下，否则提示切换 |
| 限时解谜 | 第一个机关激活后 25 秒倒计时；超时全部机关重置，可重试 |
| 元解谜 | NPC 对话触发任务；任务目标覆盖击杀、合成、抵达层数 |

### M8 Roguelike

* 地面传送门进入第 1 层时自动 `start_run(seed)`。
* 每推进 3 层抽取 1 条词条（敌人强化、金币加成、生命缩放、额外精英），HUD 显示本轮摘要。
* 死亡结束本轮，`best_floor` 记录最高层，返回主菜单。
* 每 5 层 BOSS；层数越深，敌人生命/攻击/掉落越高。

### M9 UI 与输入

* **HUD**：角色名、血条、蓝条、金币、经验、3 技能槽与冷却、任务追踪、Roguelike 摘要、建造提示、Toast。
* **背包**：`I` 打开，三页签「背包 / 合成 / 商店」，40 格按钮 + 详情 + 使用/装备/出售。
* **建造面板**：`B` 打开，列出方块与造价，高亮当前选择。
* **暂停菜单**：`Esc`，继续 / 保存 / 返回主菜单 / 退出，显示职业、金币、队伍。
* **对话**：`E` 与 NPC 交互，逐行推进，结束后触发任务。
* **触屏**：左下虚拟摇杆，右下普攻/技能/冲刺/交互/背包/建造按钮；直接调用角色方法，兼容无键盘设备。
* **输入映射**：WASD/方向键、LMB/空格普攻、1/2/3 技能、Shift 冲刺、E 交互、Q/P 换人、I 背包、B 建造、Esc 暂停；手柄 A 普攻、X/Y/RB 技能、LB 冲刺、B 交互、左/右摇杆按下换人、Back 背包、Start 暂停。
* **输入拦截**：暂停、对话、背包、建造、死亡时角色与建造输入被统一阻断。

### M10 存档

* 路径：`user://saves/save_0.json`（支持多槽位）。
* 快照内容：阵容、各职业进度、出战序号、金币、背包、装备、当前场景、层数、玩家坐标、建造记录、任务、Roguelike 状态、时间戳。
* 读档：`SaveManager.load_game()` → `GameManager.apply_state()` → 延迟切换场景 → `bind_level()` 重生队伍并恢复坐标。

---

## 5. 核心流程

### 5.1 新游戏

```
main.tscn → GameManager.enter_main_menu()
主菜单「开始新游戏」→ start_new_game()
  → 重置阵容/进度/金币/背包/建造/任务/Roguelike
  → 发放初始物资（石头×8、木头×8、草药×4、治疗药水×2）
  → enter_main_world() → bind_level() → spawn_party() → 激活第 0 位
```

### 5.2 战斗循环

```
玩家输入 → PlayerController.try_attack / try_skill / try_dash
  → 冷却与法力校验 → 范围/弹道判定 → CharacterBase.take_damage
  → 闪避/护盾/暴击结算 → DamageNumber + EffectRing + SFX
  → 敌人死亡 → 金币/经验/掉落 → EventBus.enemy_died → 任务计数
```

### 5.3 塔 / 深渊推进

```
主世界传送门 → 若未开始则 start_run → enter_tower_floor(1)
楼层激活全部机关 → 解谜倒计时停止 → 开门 + 启用上层传送门 + 金币奖励
上层传送门 → floor_num + 1；向下传送门 → 1 层去 -1，其余 -1
到达 0 → enter_main_world()；死亡 → end_run() → 主菜单
```

### 5.4 存档 / 读档

```
暂停菜单保存 → SaveManager.save_game(0)
  → GameManager.collect_state()（先 capture_party）
  → JSON.stringify → user://saves/save_0.json
主菜单继续 → load_game(0) → apply_state() → 延迟切换场景 → 恢复坐标与建造
```

---

## 6. 扩展指南

| 需求 | 修改点 |
| --- | --- |
| 新增职业 | 在 `classes.json` 增加条目（必须 3 个技能、颜色 `#RRGGBB`），祭坛会自动解锁 |
| 新增技能类型 | 在 `SkillExecutor.cast()` 的 `match` 增加分支，并在 `classes.json` 使用新 `type` |
| 新增物品/配方 | 编辑 `items.json`、`recipes.json`；`Inventory.craft` 自动支持 |
| 新增任务 | 编辑 `quests.json`；目标类型支持 `kill / craft / reach_floor` |
| 新增 NPC | 复制 `npc.gd` 节点，配置 `dialogue_id`，在 `dialogue.json` 增加对白 |
| 新增建筑 | 在 `items.json` 中 `type: building` 且带非空 `craft_cost`，建造面板自动出现 |
| 替换美术 | 将 `player.tscn` 的 `Visual/Body` 换成 AnimatedSprite2D，按状态播放动画即可 |
| 替换音频 | 放置 `audio/bgm/*.ogg` 与 `audio/sfx/*.ogg`，AudioManager 会自动加载 |

---

## 7. 操作速查

| 操作 | 键鼠 | 手柄 | 触屏 |
| --- | --- | --- | --- |
| 移动 | WASD / 方向键 | 左摇杆 / 十字键 | 虚拟摇杆 |
| 普攻 | 左键 / 空格 | A | 普攻按钮 |
| 技能 1/2/3 | 1 / 2 / 3 | X / Y / RB | 技能按钮 |
| 冲刺 | Shift | LB | 冲刺按钮 |
| 交互 / 采集 | E | B | 交互按钮 |
| 切换职业 | Q / P | 左摇杆按下 / 右摇杆按下 | — |
| 背包 | I | Back/Select | 背包按钮 |
| 建造 | B | — | 建造按钮 |
| 暂停 | Esc | Start | — |

> 完整验证步骤见 `docs/VERIFICATION.md`。
