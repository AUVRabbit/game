# 《通天入地》设计方案

> 版本：1.0　|　引擎：Godot **4.7.2-stable**（`config/features="4.7.2"`，`.godot-version` 固定）　|　语言：GDScript
> 对应工程目录：`/workspace/通天入地`

---

## 1. 设计目标

| 目标 | 落地方式 |
| --- | --- |
| 四朋克混搭世界 | 16 个职业覆盖法术 / 机械 / 武道 / 科技四类幻想；技能特效、装备与建筑均数据驱动 |
| 2D 等距开放世界 | 主世界使用等距投影绘制，坐标转换 `grid_to_world / world_to_grid` 统一在 BuildManager |
| 向上通天塔、向下深渊 | 同一套程序化楼层场景，楼层号正数通天、负数入地，0 表示地面 |
| 16 职业自由切换 | 队伍最多 16 人，Q/P 实时切换；职业祭坛消耗金币逐个解锁 |
| 实时动作战斗 | 普攻 + 6 技能 + 冲刺，冷却、法力、暴击、闪避、护盾、增益全部生效 |
| 混合经济 | 资源点采集 → 配方合成 → 商店买卖 → 敌人掉落，四种来源闭环 |
| 沙盒建造 | 等距网格放置 / 拆除建筑，消耗材料、50% 返还、按场景持久化 |
| Roguelike 支线 | 通天塔即 Roguelike 层，每 3 层随机词条，每 5 层 BOSS，死亡结束本轮 |
| 解谜 | 环境采集、职业限定机关、限时机关、任务/对话元解谜 |
| 键鼠 / 手柄 / 触屏 | 输入映射 + InputManager 设备识别 + TouchControls 虚拟摇杆与按钮 |
| 菜单 / 关卡 / 存档 | 主菜单、暂停菜单、JSON 存档、完整状态快照 |
| 真实美术素材 | 角色立绘、敌人精灵、地面平铺贴图、图标、头像、粒子特效全部为 AI 生成的真实 PNG，程序化 `_draw` 仅作缺失兜底 |
| 技能树成长 | 每职业 16 节点 6 阶技能树（初始 / 精通 / 进阶 / 天赋 / 专精 / 终极），技能点解锁、被动生效、可重置 |
| 职业专职 | 每职业 3 条互斥专职路线，等级 + 技能点解锁，提供属性、技能倍率、被动三段加成 |
| 技能展示效果 | 14 张加法混合特效贴图，按技能类型匹配爆点、方向与缩放 |

---

## 2. 工程结构

```
通天入地/
├── project.godot                 # 11 个 Autoload、输入映射、960×540 视口
├── data/                         # 纯 JSON 数据表（可热改）
│   ├── items.json                # 25 件物品
│   ├── classes.json              # 16 职业 + 成长 + 6 主动技能
│   ├── recipes.json              # 15 条配方
│   ├── quests.json               # 3 条任务
│   ├── dialogue.json             # 3 个 NPC 对话
│   ├── punk_parts.json           # 4 风格 20 件朋克部件 + 职业风格绑定
│   ├── skill_trees.json          # 16 职业技能树（每职业 16 节点 6 阶）
│   └── specializations.json      # 16 职业 × 3 条互斥专职
├── scenes/
│   ├── main.tscn                 # 启动入口，仅挂 main.gd
│   ├── player/player.tscn        # CharacterBody2D + CharacterData
│   ├── enemies/enemy.tscn        # 通用敌人
│   ├── world/main_world.tscn     # 开放世界
│   ├── world/tower_floor_1.tscn  # 通天塔/深渊通用楼层
│   └── ui/                       # HUD、背包、建造、暂停、对话、触屏、GameUI 聚合
├── scripts/
│   ├── globals/                  # 11 个 Autoload
│   ├── core/asset_library.gd     # 逻辑 id → 贴图路径索引（带缓存）
│   ├── player/                   # CharacterBase、PlayerController
│   ├── combat/                   # SkillExecutor、Projectile、EffectRing、DamageNumber、SkillVfx
│   ├── enemies/                  # EnemyBase、EnemySpawner
│   ├── economy/inventory.gd      # 40 格背包、合成、商店
│   ├── world/                    # 世界、塔层、NPC、传送门、机关、资源点、祭坛、改造台、建筑块、掉落物
│   └── ui/                       # 全部界面（代码构建，含朋克改造面板、技能树面板）
├── assets/                       # 真实美术素材（AI 生成 + 后处理）
│   ├── ground/                   # 草地 / 塔层地板 512×512 无缝平铺贴图
│   ├── ui/                       # 主菜单背景（通天塔夜景 1920×1080）
│   ├── icons/skill/              # 36 张技能图标
│   ├── icons/item/               # 26 张物品图标
│   ├── icons/passive/            # 6 张天赋图标
│   ├── portraits/                # 12 张职业立绘
│   ├── vfx/                      # 14 张加法混合特效贴图
│   └── sprites/                  # 敌人精灵、world/ 36 张世界物件
├── tools/
│   ├── validate_project.py       # 静态结构校验
│   ├── smoke_test.tscn/.gd       # 无头冒烟测试入口
│   ├── smoke_runner.gd           # 64 项自动化验收
│   ├── shot.tscn / shot_runner.gd# xvfb 真实渲染截图（8 张）
│   ├── gen_manifest.py           # AI 素材清单生成（129 条 prompt）
│   ├── make_ground_tiles.py      # 去水印 + 弱化斑块 + 无缝化 → 地面平铺贴图
│   ├── make_pickup_sprites.py    # 物品图标 → 透明掉落物精灵
│   ├── make_enemy_sprites.py     # 敌人原图 → 反解算抠图透明精灵
│   ├── make_menu_bg.py           # 主菜单原图 → 裁水印 → 16:9 → 压暗
│   ├── clean_magenta.py          # 键色残留清理
│   └── fix_alpha.py              # 半透明底清理
└── docs/
    ├── DESIGN.md                 # 本文
    ├── VERIFICATION.md           # 验证方案
    └── screenshots/              # 真实渲染验收截图（8 张）
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
| 10 | PunkManager | `scripts/globals/punk_manager.gd` | 朋克改造槽位、风格匹配、属性叠加、存档序列化 |
| 11 | SkillManager | `scripts/globals/skill_manager.gd` | 技能点、技能树解锁/重置、被动与技能加成、职业专职、序列化 |

> 约束：Autoload 脚本一律不写 `class_name`，避免全局类名与单例名冲突。
> `SkillManager` 必须排在末位，因为它在 `_ready` 时读取 `DataManager` 加载好的技能树数据。

### 2.2 事件总线

`EventBus.emit_event(signal_name, args)` 内部使用 `emit_signal.callv([signal_name] + args)`，用于动态派发。
已定义信号覆盖：玩家出生/受伤/死亡/升级、切换职业、攻击、施法、敌人死亡、物品掉落/拾取、方块放置/破坏、建筑放置/移除、机关触发、关卡完成、传送、背包/金币变化、合成/出售、对话、任务、提示、存读档、Roguelike 开始/结束。

### 2.3 状态机

`GameManager.GameState`：`MENU / PLAYING / PAUSED / DIALOG / INVENTORY / BUILDING / DEAD`。
`is_input_blocked()` 在非 `PLAYING` 时返回 `true`，玩家与建造输入统一被拦截；界面节点使用 `PROCESS_MODE_ALWAYS` 保证暂停时仍可操作。

### 2.4 素材体系 `scripts/core/asset_library.gd`

所有界面与场景元素不直接写 `res://` 路径，而是用**逻辑 id** 经 `AssetLibrary` 解析为贴图路径；`texture()` 带静态缓存，缺图返回 `null` 由调用方降级为程序化绘制。

| id 前缀 | 解析路径 | 素材量 | 用途 |
| --- | --- | --- | --- |
| `skill_` | `res://assets/icons/skill/<id>.png` | 96 | 技能树节点图标、HUD 六格技能槽 |
| `item_` | `res://assets/icons/item/<id>.png` | 26 | 背包格子、商店货架、掉落提示 |
| `portrait_` | `res://assets/portraits/<id>.png` | 16 | 职业立绘（角色面板、专职页、菜单） |
| `passive_` | `res://assets/icons/passive/<id>.png` | 6 | 天赋节点图标 |
| `vfx_` | `res://assets/vfx/<id>.png` | 14 | 技能特效（加法混合） |
| `enemy_` | `res://assets/sprites/enemy_<type>.png` | 4 | 史莱姆 / 机械蛛 / 幽魂 / BOSS |
| `sprite_` | `res://assets/sprites/world/<id>.png` | 40 | 16 职业世界精灵 + 资源点 + NPC + 建筑块 + 掉落物 |
| `ground_` | `res://assets/ground/<id>.png` | 2 | 草地 / 塔层地板无缝平铺图 |
| `ui_` | `res://assets/ui/<id>.png` | 1 | 主菜单背景（通天塔夜景） |

**接入范式**：贴图存在时用 `Sprite2D` 或 `draw_texture_rect_region()` 渲染，`_draw()` 里的程序化图形仅作兜底（`if sprite: return` 提前返回），保证素材缺失时游戏仍可运行。

**地面平铺 UV 约定**：Godot `draw_polygon` 的 UV 是**归一化坐标**，配合 `texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED` 实现平铺；UV 必须按 `世界坐标 / tile_px` 计算（`tile_px = 512`，与贴图原始分辨率一致），直接传像素值会导致超高频采样、地面呈纯色。

**贴图重复感的抑制**：平铺贴图的大块特征（土斑、砖缝）会让周期规律肉眼可见。`make_ground_tiles.py` 的 `reduce_blob_contrast()` 把褐色像素按全图草地中位色混合 60%，把土斑压成与草地同色系的低对比斑块，显著降低重复辨识度。

**素材后处理工具链**（`tools/`）：

| 工具 | 作用 |
| --- | --- |
| `gen_manifest.py` | 生成 129 条 AI 素材 prompt 清单（`asset_manifest.json`） |
| `make_ground_tiles.py` | 去除水印 → offset 混合法无缝化 → 512×512 平铺贴图 |
| `make_pickup_sprites.py` | 从 256² 物品图标差分抠图 → 128² 透明掉落物精灵 |
| `make_enemy_sprites.py` | 敌人原图 → 去水印 → 键色反解算抠图 → 128² 透明精灵 |
| `make_menu_bg.py` | 主菜单原图 → 裁掉右下角水印条带 → 16:9 裁切 → 中部压暗 |
| `clean_magenta.py` | 清理 NPC / 建筑块残留的洋红键色 |
| `fix_alpha.py` | 清理半透明灰底并补边成正方形 |

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
  "name": "法师",
  "source": "arcane", "role": "assault",
  "source_name": "法术", "role_name": "破军",
  "identity": "元素爆发：以太塑形，远距离高倍率法术是主要伤害来源。",
  "color": "#5a7bff",
  "max_hp": 90, "max_mp": 120,
  "attack": 6, "defense": 3, "magic_attack": 22, "magic_defense": 12,
  "move_speed": 190, "attack_speed": 1.0,
  "crit_rate": 0.06, "crit_damage": 1.5, "dodge_rate": 0.02,
  "skills": [
    { "id": "fireball", "slot": 1, "name": "火球术", "type": "projectile",
      "cd": 1.6, "mp": 10, "power": 1.9, "speed": 420, "color": "#ff8844", "icon": "skill_fireball" },
    { "id": "frost_nova", "slot": 2, "name": "冰霜新星", "type": "melee_aoe",
      "cd": 6.0, "mp": 16, "power": 1.6, "icon": "skill_frost_nova" },
    { "id": "arcane_shield", "slot": 3, "name": "奥术护盾", "type": "shield",
      "cd": 9.0, "mp": 20, "power": 2.4, "icon": "skill_arcane_shield" },
    { "id": "meteor", "slot": 4, "name": "陨星术", "type": "aoe_zone",
      "cd": 12.0, "mp": 30, "power": 2.8, "advanced": true,
      "requires": "mage_mastery_0", "icon": "skill_meteor" }
  ]
}
```

* `source` / `role` 为矩阵坐标，`source_name` / `role_name` / `identity` 为可读身份字段。
* `slot` 1–3 为基础主动，4–6 为进阶主动；进阶必须带 `advanced: true` 与 `requires`（对应精通节点 id）。
* 每个职业固定 6 个技能，槽号必须恰好覆盖 1–6。

全局 `growth` 定义每级成长（生命 +16、法力 +6、攻击 +3、防御 +2、法攻 +3、法防 +1）。

### 3.3 配方 / 任务 / 对话

* 配方：`{ "id", "output", "count", "cost": { "iron_ore": 2, "coal": 1 } }`
* 任务目标类型：`kill`（敌人类型）、`craft`（物品 id）、`reach_floor`（层号字符串）
* 任务奖励：`{ "gold": 80, "items": { "healing_potion": 2 } }`
* 对话：`{ "npc_id": { "name", "lines": [], "quest": "q_slime_hunt" } }`

### 3.4 朋克部件 `data/punk_parts.json`

```json
{
  "styles": [
    { "id": "tech", "name": "科技朋克", "color": "#4ad6ff", "desc": "霓虹闪烁，电路板纹理，光纤导线" }
  ],
  "parts": [
    {
      "id": "tech_quantum_sensor", "name": "量子传感器", "style": "tech", "slot": "helmet",
      "desc": "头盔搭载量子传感器，暴击率 +0.08，狙击手专属",
      "stats": { "crit_rate": 0.08 }, "visual": "quantum_sensor",
      "cost": { "iron_ore": 7, "herb": 3 }, "rarity": "epic",
      "class_bonus": ["sniper"]
    }
  ],
  "class_style_bindings": { "archer": ["tech", "neutral"] },
  "style_bonus_when_matched": 0.15
}
```

| 字段 | 说明 |
| --- | --- |
| `styles` | 4 大风格：`spell / mech / tech / abyss`，含展示名、颜色、描述 |
| `parts[].slot` | `weapon / chest / helmet / back` 四槽位，每职业每槽至多 1 件 |
| `parts[].stats` | 数值加成键与 `CharacterBase` getter 对齐（`attack`、`defense`、`max_hp`、`crit_rate`、`move_speed`、`all_stats_bonus` 等） |
| `parts[].class_bonus` | 职业专属列表；命中的职业额外 +10% 数值 |
| `parts[].tradeoff` | 标记负面换正面的取舍部件（如腐败晶体） |
| `parts[].cost` | 安装材料；卸下退还 50% |
| `class_style_bindings` | 职业主风格绑定，用于风格匹配判定 |
| `style_bonus_when_matched` | 主风格匹配时全数值加成倍率（默认 0.15） |

### 3.5 技能树 `data/skill_trees.json`

16 个职业各一张 16 节点、6 阶的技能树，共 256 个节点（每职业：初始 3 / 精通 3 / 进阶 3 / 天赋 3 / 专精 3 / 终极 1）。

```json
{
  "version": "2.0.0",
  "points_per_level": 1,
  "starting_points": 1,
  "trees": {
    "archer": {
      "name": "弓箭手之道",
      "nodes": [
        { "id": "archer_anchor_0", "name": "穿透射击", "tier": 0, "col": 0,
          "kind": "anchor", "skill_id": "piercing_shot", "cost": 0,
          "requires": [], "icon": "skill_piercing_shot", "desc": "职业初始主动技能（初始技能）",
          "passive": {}, "skill_bonus": {} },
        { "id": "archer_mastery_0", "name": "穿透射击精通", "tier": 1, "col": 0,
          "kind": "mastery", "skill_id": "piercing_shot", "cost": 1,
          "requires": ["archer_anchor_0"], "icon": "skill_piercing_shot",
          "desc": "强化【穿透射击】：技能威力 +25%，冷却 -10%。",
          "passive": {}, "skill_bonus": { "power": 0.25, "cooldown": 0.1 } },
        { "id": "archer_active_0", "name": "贯穿风暴", "tier": 2, "col": 0,
          "kind": "active", "skill_id": "piercing_storm", "cost": 2,
          "requires": ["archer_mastery_0"], "icon": "skill_piercing_storm",
          "desc": "解锁进阶主动【贯穿风暴】，可在技能栏 R 槽施放。",
          "passive": {}, "skill_bonus": {} },
        { "id": "archer_passive_0", "name": "致命弱点", "tier": 3, "col": 0,
          "kind": "passive", "skill_id": "", "cost": 1,
          "requires": ["archer_mastery_0"], "icon": "passive_stat_crit",
          "desc": "暴击率 +5%，暴击伤害 +15%。",
          "passive": { "crit_rate": 0.05, "crit_damage": 0.15 }, "skill_bonus": {} }
      ]
    }
  }
}
```

| 字段 | 说明 |
| --- | --- |
| `kind` | `anchor`（初始技能，cost 0，自动解锁）/ `mastery`（精通）/ `active`（进阶主动，解锁槽 4–6）/ `passive`（天赋）/ `keystone`（专精）/ `capstone`（终极） |
| `tier` / `col` | 面板布局：tier 0–5 为横向六阶，col 0–2 为纵向三分支 |
| `requires` | 前置节点 id 列表，全部解锁才可点该节点 |
| `cost` | 消耗技能点（精通 1 / 进阶 2 / 天赋 1 / 专精 2 / 终极 3） |
| `passive` | 常驻属性加成，键与 `CharacterBase` getter 对齐 |
| `skill_bonus` | 技能强化：`power` 威力百分比、`cooldown` 冷却缩减百分比 |
| `icon` | 传给 `AssetLibrary` 的逻辑 id（`skill_*` 或 `passive_*`） |
| `points_per_level` / `starting_points` | 每级获得技能点数、初始技能点数 |

### 3.6 职业专职 `data/specializations.json`

16 个职业各 3 条互斥专职路线，共 48 条。

```json
{
  "version": "1.1.0",
  "specializations": {
    "archer": [
      { "id": "sharpshooter", "name": "神射手",
        "desc": "远程极限：暴击与射程拉满，箭雨覆盖更广。",
        "req_level": 5, "icon": "portrait_archer",
        "stats": { "crit_rate": 0.07, "crit_damage": 0.25, "move_speed": -0.05 },
        "skill_bonus": { "power": 0.18 },
        "passives": {},
        "bonus_points": 1 },
      { "id": "ranger", "name": "游侠",
        "desc": "灵活作战：移速与闪避大幅提升，技能冷却缩短。",
        "req_level": 5, "icon": "portrait_archer",
        "stats": { "move_speed": 0.18, "dodge_rate": 0.06, "attack": 2 },
        "skill_bonus": { "cooldown": 0.25 },
        "passives": {},
        "bonus_points": 1 }
    ]
  }
}
```

| 字段 | 说明 |
| --- | --- |
| `req_level` | 选择所需等级（默认 5） |
| `stats` | 固定数值加成，键与 `CharacterBase` getter 对齐；负值表示取舍 |
| `skill_bonus` | 该职业全部技能的威力 / 冷却倍率加成 |
| `passives` | 专属被动键：`lifesteal`（吸血）、`shield_bonus`（护盾）、`burn`（灼烧）、`heal_bonus`（治疗）等 |
| `bonus_points` | 选择后额外获得的技能点 |
| 互斥规则 | 同一职业选定一条后不可改选，`SkillManager.choose_specialization()` 直接拒绝第二次选择 |

---

### 3.7 职业与技能设计纲领（v2.0）

每个职业必须能回答五个问题：**源流、战斗范式、机制身份、数值预算、成长路径**。任何职业与技能都由这五项推导，不做无依据的堆叠。本文给出的全部数值由生成器 [gen_class_content.py](file:///workspace/通天入地/tools/gen_class_content.py) 产出并自校验，数据文件是纲领的可执行版本。

#### 3.7.1 四源流 × 四战斗范式 = 16 职业矩阵

| 源流 \ 范式 | 破军（爆发输出） | 铁壁（承伤控场） | 辅弼（治疗增益） | 诡道（机动暗杀） |
| --- | --- | --- | --- | --- |
| 法术（arcane） | 法师 | 咒铠师 | 牧师 | 亡灵法师 |
| 机械（mech） | 炸弹专家 | 机甲师 | 工程师 | 赏金猎人 |
| 武道（martial） | 死亡骑士 | 战士 | 气宗 | 小偷 |
| 科技（tech） | 弓箭手 | 义体卫士 | 黑客 | 狙击手 |

矩阵是**双射**：每格唯一职业，任一职业不得同时占据两格。4 个新增职业恰好补齐原 12 职业的空缺——咒铠师（法术·铁壁）、气宗（武道·辅弼）、工程师（机械·辅弼）、义体卫士（科技·铁壁），因此不存在“为了凑数而新增”的职业。

#### 3.7.2 机制身份（一句话）

| 职业 | 源流·范式 | 核心机制 |
| --- | --- | --- |
| 法师 | 法术·破军 | 元素爆发：以太塑形，远距离高倍率法术是主要伤害来源。 |
| 咒铠师 | 法术·铁壁 | 符文装甲：用咒文护盾吸收伤害并反噬近身之敌。 |
| 牧师 | 法术·辅弼 | 神圣庇佑：治疗、圣光爆发与团队祝福三位一体。 |
| 亡灵法师 | 法术·诡道 | 生死操控：以腐蚀、墓场与噬魂维持长时间消耗战。 |
| 炸弹专家 | 机械·破军 | 爆破工程：用火药与燃烧覆盖战场，追求范围清场。 |
| 机甲师 | 机械·铁壁 | 重装要塞：机甲护甲与力场保证持续站桩输出。 |
| 工程师 | 机械·辅弼 | 战地工事：部署炮塔、修理与战术补给支援全队。 |
| 赏金猎人 | 机械·诡道 | 猎杀契约：标记目标后以速射与缴械压制。 |
| 死亡骑士 | 武道·破军 | 血怒冲锋：以自身生命为代价换取突进与范围斩击。 |
| 战士 | 武道·铁壁 | 铁壁反击：以高护甲与盾墙承伤，靠战吼把防御转成输出窗口。 |
| 气宗 | 武道·辅弼 | 内息流转：以气血循环治疗与加速，自身亦能近身打出气劲。 |
| 小偷 | 武道·诡道 | 影袭毒刃：依赖背刺与烟幕在高风险窗口内爆发。 |
| 弓箭手 | 科技·破军 | 精确投射：复合弓与瞄准镜把暴击转化为稳定输出。 |
| 义体卫士 | 科技·铁壁 | 义体壁垒：液压与能量装甲让自身成为移动前线。 |
| 黑客 | 科技·辅弼 | 网络入侵：病毒、断电与超频改写敌我攻防节奏。 |
| 狙击手 | 科技·诡道 | 潜行狙击：陷阱布场后以超远单发点杀关键目标。 |

#### 3.7.3 技能分级与解锁链

每个职业固定 **6 个主动技能 + 16 节点技能树**：

| 槽位 | 键位 | 层级 | 解锁条件 |
| --- | --- | --- | --- |
| 1 / 2 / 3 | `1` `2` `3` | 基础主动 | 职业自带 |
| 4 / 5 / 6 | `R` `F` `G` | 进阶主动 | 技能树点亮 `<cid>_mastery_0/1/2` |

技能树节点结构与预算：

| 层级 | 节点 | 数量 | 消耗 | 前置 | 效果 |
| --- | --- | --- | --- | --- | --- |
| 0 | anchor 初始 | 3 | 0 | 无 | 初始主动技能锚点（默认解锁） |
| 1 | mastery 精通 | 3 | 1 | `anchor_i` | 关联技能威力 +25%、冷却 -10% |
| 2 | active 进阶 | 3 | 2 | `mastery_i` | 解锁槽 4/5/6 进阶主动 |
| 3 | passive 天赋 | 3 | 1 | `mastery_i` | 按范式统一的属性被动 |
| 4 | keystone 专精 | 3 | 2 | `passive_i` | 分支强化被动 |
| 5 | capstone 终极 | 1 | 3 | 三个 `keystone` | 全分支终极奥义 |

依赖链严格单向：`anchor_i → mastery_i → {active_i, passive_i → keystone_i}`，`capstone` 需要三条分支全部专精。未点亮 mastery 时，进阶技能在 HUD 显示“未解锁/技能树”，释放会被 `PlayerController._skill_unlocked()` 拦截并提示，不存在“跳过前置直接使用”的路径。

#### 3.7.4 数值预算（可审计）

职业强度不按单项直觉拍脑袋，而按统一战力分 `power_score` 校验：

```
power_score = hp×0.6 + mp×0.35 + (atk+matk)×2.4 + (def+mdef)×1.8
            + move_speed×0.12 + crit_rate×120 + dodge_rate×120
            + (attack_speed−1)×40 + (crit_damage−1.5)×30
```

* **预算带 (160, 265)**：取自既有 12 职业的实机调校分布 169~248，向上留出终极成长余量。
* **范式生命下限**：破军 75 / 铁壁 130 / 辅弼 70 / 诡道 78，保证铁壁确实更耐打。
* **既有 12 职业属性保持不变**：它们是实机调校基准，改动会破坏已验收的战斗手感；新增 4 职业、全部进阶技能与专职由公式生成。
* **进阶技能约束**：冷却与法力消耗不得低于同分支基础技能，威力必须更高。
* **校验兜底**：生成器自校验 + [validate_project.py](file:///workspace/通天入地/tools/validate_project.py) 双重检查（16 职业 / 96 技能 / 槽号 1..6 / 前置存在 / 16×16 树节点 / 3 专职 / 素材存在）。

#### 3.7.5 专职路线

每个职业 3 条互斥专职（既有 12 职业保留 2 条原始路线并新增 1 条；4 个新职业各 3 条），统一 `req_level = 5`、`bonus_points = 1`。专职通过 `stats`（固定值）与 `skill_bonus`（威力/冷却倍率）表达取舍，负值代表明确代价，例如“破阵者”以防御换突进与暴击。

#### 3.7.6 素材与图标规则

* 新职业立绘 512×512、世界精灵 128×128 透明底、技能图标 256×256。
* **进阶技能图标 = 同分支基础图标 + 阶位符印框**（槽 4 金 / 槽 5 青 / 槽 6 紫，右上角菱形数 1/2/3 表示阶位），由 [gen_advanced_icons.py](file:///workspace/通天入地/tools/gen_advanced_icons.py) 确定性合成，保证同一分支视觉谱系一致，避免 48 张独立生成造成的风格漂移。
* **被动/专精/终极节点**按属性归属复用既有真实图标 `passive_stat_attack / crit / defense / speed / skill / capstone`，不绘制占位图。
* 素材存在性由校验器强制：任何技能或节点图标缺失即 FAIL，不允许以空白或占位图上线。

---

## 4. 模块设计

### M1 角色与职业

* **关键文件**：`character_base.gd`、`player_controller.gd`、`data/classes.json`、`class_altar.gd`
* **属性计算**：`基础值 + 等级成长 + 装备加成 + Buff 加成`，由 `recompute()` 统一重算。
* **16 职业**：四源流 × 四战斗范式的完整矩阵、每职业 6 主动技能与机制身份见 [3.7 职业与技能设计纲领](#37-职业与技能设计纲领v20)。
* **切换**：`Q` 下一位 / `P` 上一位，切换时保留各自血量、法力、等级与装备；未出战角色隐藏并关闭碰撞。
* **解锁**：初始 3 人（战士/弓箭手/法师）；主世界职业祭坛每次 150 金币解锁下一位，直至 16 人。
* **升级**：经验满后循环升级，`exp_to_next *= 1.25`，升级回满血蓝并广播 `player_leveled_up`。
* **立绘**：`PlayerController._refresh_class_sprite()` 按 `class_id` 加载 `assets/sprites/world/player_<class_id>.png`（16 职业一一对应），用 `get_used_rect()` 求不透明包围盒做脚底对齐；贴图存在时隐藏 `Visual/Body` 的 Polygon2D 兜底。运行时切换职业会同步刷新立绘（`setup_class()` 末尾补发 `stats_changed`）。

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

* **冷却/法力**：每个技能独立冷却，HUD 六格技能槽实时显示剩余秒数；法力不足提示且不进入冷却。
* **进阶前置**：槽 4/5/6 的进阶技能带 `requires`，未点亮对应精通节点时不可施放，HUD 显示“未解锁/技能树”。
* **伤害公式**：`max(1, 攻击或法攻 × 技能倍率 × (1 + Buff) - 防御 × 0.5)`；暴击 ×1.5；闪避则 0 伤害。
* **死亡**：非 Roguelike 场景 1.2 秒后在出生点复活并恢复 50% 生命；Roguelike 中死亡结束本轮并回到主菜单。
* **表现**：`DamageNumber` 上浮淡出、`EffectRing` 扩散圆环、角色受击闪白；技能释放额外播放 `SkillVfx` 加法混合特效贴图（详见 M14）。

### M3 敌人与刷怪

* **EnemyBase**：巡逻 → 侦测（`detect_range`）→ 追击 → 进入 `attack_range` 后按 `attack_cooldown_time` 攻击。
* **数值**：导出属性支持刷怪点按字典覆盖（生命、攻击、防御、法防、经验、金币、颜色、体型、掉落表、BOSS 标记）。
* **掉落**：按 `drop_table` 概率生成 `pickup.gd`，玩家接触后自动入包；掉落物挂到世界根节点，不占用刷怪点存活计数。掉落物带真实精灵（资源点用 `sprite_res_*`，战利品用 `sprite_item_*`），上下浮动 3px 呼吸，地面保留半透明光圈。
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

* **主世界**：真实草地平铺贴图（`ground_grass`，512² 无缝）+ 等距网格线；3 个刷怪点（史莱姆 / 机械蛛 / 幽魂）、3 个 NPC、8 个资源点、职业祭坛、通天塔传送门；资源点、NPC、建筑块、祭坛、改造台、传送门均使用 `assets/sprites/world/` 下的真实精灵。
* **通天塔 / 深渊**：`tower_floor.gd` 用 `floor_num` 生成：
  * `depth = |floor_num|`，层数越高/越深，机关更多、敌人更强；
  * 环形分布 2–4 个机关，全部激活前门锁住、上层传送门禁用；
  * 正数层显示「通天塔 · 第 N 层」，负数层显示「深渊 · 第 N 层」；
  * 每层都有向下传送门：1 层向下进入深渊 -1 层，其余层向下 `floor_num - 1`；向上 `floor_num + 1`，到 0 即返回地面；
  * 每 5 层生成 BOSS（生命/攻击/掉落大幅提升）。
  * 地面使用塔层专用紫调石砖平铺贴图（`ground_tower`），与主世界草地区分。
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

* **HUD**：角色名、血条、蓝条、金币、经验、6 技能槽（含未解锁态）与冷却、任务追踪、Roguelike 摘要、建造提示、Toast。
* **背包**：`I` 打开，三页签「背包 / 合成 / 商店」，40 格按钮 + 详情 + 使用/装备/出售。
* **建造面板**：`B` 打开，列出方块与造价，高亮当前选择。
* **暂停菜单**：`Esc`，继续 / 保存 / 返回主菜单 / 退出，显示职业、金币、队伍。
* **对话**：`E` 与 NPC 交互，逐行推进，结束后触发任务。
* **触屏**：左下虚拟摇杆，右下普攻/技能/冲刺/交互/背包/建造按钮；直接调用角色方法，兼容无键盘设备。
* **输入映射**：WASD/方向键、LMB/空格普攻、1/2/3/R/F/G 技能、Shift 冲刺、E 交互、Q/P 换人、I 背包、B 建造、K 技能树、Esc 暂停；手柄 A 普攻、X/Y/RB 技能、LB 冲刺、B 交互、左/右摇杆按下换人、Back 背包、Guide 技能树、Start 暂停。触屏提供虚拟摇杆与 R/F/G 进阶技能按钮。
* **输入拦截**：暂停、对话、背包、建造、技能树、死亡时角色与建造输入被统一阻断。

### M10 存档

* 路径：`user://saves/save_0.json`（支持多槽位）。
* 快照内容：阵容、各职业进度、出战序号、金币、背包、装备、当前场景、层数、玩家坐标、建造记录、任务、Roguelike 状态、朋克改造（`punk.equipped`）、时间戳。
* 读档：`SaveManager.load_game()` → `GameManager.apply_state()` → 延迟切换场景 → `bind_level()` 重生队伍并恢复坐标。

### M11 朋克改造

* **关键文件**：`data/punk_parts.json`、`scripts/globals/punk_manager.gd`、`scripts/player/character_base.gd`、`scripts/world/punk_forge.gd`、`scripts/ui/punk_panel.gd`。
* **四大风格**：法术 `spell`（符文/奥术）、机械 `mech`（齿轮/蒸汽/铆钉）、科技 `tech`（霓虹/电路/光纤）、深渊 `abyss`（阴影/腐败/虚无），另有通用 `neutral`。
* **槽位**：每职业 `weapon / chest / helmet / back` 四槽，每槽至多 1 件；`PunkManager.SLOTS` 为唯一来源。
* **风格匹配**：`class_style_bindings` 定义职业主风格；装备部件中与主风格一致的占比最高者即当前主风格。主风格命中绑定列表时，全部朋克数值 ×(1 + 15%)；部件 `class_bonus` 命中当前职业时再 ×1.10。
* **属性叠加**：`PunkManager._compute_punk_stats()` 汇总四槽 `stats` 并计算倍率，写入 `CharacterBase.punk_stats`；所有战斗 getter（攻击/防御/法攻/法防/生命/法力/移速/攻速/暴击率/暴伤/闪避）统一叠加，`all_stats_bonus` 以百分比二次放大。
* **取舍设计**：部分深渊部件带负属性（如生命 -10 换攻击 +12），`tradeoff: true` 标记，保证「一切都有可能」的构筑多样性。
* **改造台**：世界坐标 `(-360, 0)` 生成 `PunkForge`（`interactables` 组，交互半径内按 E），打开 `PunkPanel`（`punk_panel` 组，layer 28），复用 `GameManager.open_ui(DIALOG)` 暂停锁。
* **面板交互**：左列四槽位实时展示已装部件与风格色；右侧列出该职业可用部件（槽位、名称、风格、材料），点击安装；已装槽位可一键卸下并退还 50% 材料。
* **事件**：`EventBus.punk_applied / punk_removed / punk_style_changed`，供 HUD 或外部系统监听。

### M12 技能树

* **关键文件**：`data/skill_trees.json`、`scripts/globals/skill_manager.gd`、`scripts/ui/skill_tree_panel.gd`、`scripts/player/character_base.gd`。
* **结构**：16 职业 × 16 节点 × 6 阶（初始 / 精通 / 进阶 / 天赋 / 专精 / 终极），共 256 节点；横向 6 列 × 纵向 3 分支布局，由 `TreeLinkLayer` 绘制前置连线。
* **技能点**：`points_per_level = 1`，每级升级自动发放；初始 1 点；`SkillManager.grant_level_points()` 在角色升级事件里调用。
* **解锁校验**：`can_unlock()` 返回 `{ ok, reason }`，依次检查等级、技能点、前置节点、是否已解锁；`unlock_node()` 成功后扣点并广播 `stats_changed`。
* **加成落地**：被动经 `CharacterBase.get_skill_power_multiplier(skill_id)` / `get_skill_cooldown_multiplier(skill_id)` 统一叠加；`skill_bonus.power` 提高威力，`skill_bonus.cooldown` 缩短冷却。
* **面板**：`K` 键开关（`skill_tree_panel` 组，layer 29）；左列职业立绘 + 名称 + 剩余技能点；中部节点网格（真实图标 `AssetLibrary.texture(node.icon)`、阶位色带、已解锁高亮、前置未满足置灰）；右侧详情区显示节点名称、描述、属性明细与特效预览（`vfx_*` 贴图循环 Tween 播放）；底部提供「重置技能树」按钮全额返还技能点。
* **重置**：`SkillManager.reset_tree(class_id)` 清空该职业全部非初始节点并返还技能点；存档保留解锁状态。
* **存档**：随 `GameManager.collect_state()` 写入快照的 `skills` 字段（内含 `points` / `unlocked` / `specialization`），读档经 `SkillManager.apply_state()` 完整恢复。

### M13 职业专职

* **关键文件**：`data/specializations.json`、`scripts/globals/skill_manager.gd`、`scripts/ui/skill_tree_panel.gd`（专职页签）。
* **数据**：每职业 2 条路线，共 24 条；`req_level` 默认 5 级，额外要求 1 点技能点。
* **三段加成**：`stats`（固定数值）→ `skill_bonus`（威力 / 冷却）→ `passives`（吸血 / 护盾 / 灼烧 / 治疗等专属被动），全部在 `CharacterBase.refresh_skill_stats()` 里重算。
* **互斥**：`choose_specialization()` 拒绝同职业二次选择；选定后显示名切换为「职业名 · 专职名」。
* **交互**：技能树面板第二页签「职业专职」列出该职业两条路线（立绘图标 + 名称 + 描述 + 加成明细），等级与技能点不足时按钮禁用并给出原因。
* **存档**：专职 id 随快照保存，读档后仍生效。

### M14 技能特效与真实素材渲染

* **关键文件**：`scripts/combat/skill_vfx.gd`、`scripts/core/asset_library.gd`、`assets/vfx/`、`assets/ground/`、`assets/sprites/`。
* **特效贴图**：14 张纯黑底发光贴图（`fireball / ice_shard / explosion / melee_slash / arrow / heal_spark / buff_swirl / shield_dome / lightning / neon_grid / dash_streak` 等），运行时用 `CanvasItemMaterial.BLEND_MODE_ADD` 加法混合，叠加在黑底上呈现高对比发光。
* **按类型匹配**：`spawn_skill()` 依据技能 `type` 选择爆点位置、朝向与缩放——近战切向旋转、弹道沿飞行方向前移 18px、治疗/增益/护盾在角色原地、区域/连锁原地展开、突进沿冲刺方向。
* **命中爆点**：`spawn_impact()` 在弹道与近战命中处再叠一层小尺寸爆点。
* **角色与敌人**：`PlayerController._refresh_class_sprite()` 按 `class_id` 加载 `sprite_player_<class>` 并用 `get_used_rect()` 做脚底对齐；`EnemyBase._draw()` 用 `draw_texture_rect_region()` 绘制敌人精灵并保留受击闪白。
* **地面**：`world.gd` / `tower_floor.gd` 用 `draw_ground_texture()` 平铺 512×512 无缝贴图，UV 按 `point / 320` 归一化。
* **兜底策略**：所有 `_draw()` 在贴图存在时提前返回，缺素材自动退回程序化图形，不影响可玩性。

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
| 新增朋克部件 | 在 `punk_parts.json` 的 `parts` 增加条目（`style`/`slot`/`stats`/`cost`），改造面板自动列出；风格数值改 `style_bonus_when_matched` |
| 新增朋克风格 | 在 `punk_parts.json` 的 `styles` 增加条目，并在 `class_style_bindings` 绑定职业，`PunkManager` 无需改动 |
| 新增技能树节点 | 在 `skill_trees.json` 对应职业的 `nodes` 增加条目（`tier`/`col`/`kind`/`requires`/`cost`），面板自动重排；`icon` 用 `skill_*` 或 `passive_*` 前缀 |
| 新增专职路线 | 在 `specializations.json` 对应职业数组增加条目（`req_level`/`stats`/`skill_bonus`/`passives`），专职页签自动列出 |
| 替换美术 | 放入对应目录的 PNG 即可（`assets/icons/skill|item|passive/`、`assets/portraits/`、`assets/vfx/`、`assets/sprites/`、`assets/ground/`），按 id 前缀规则命名后自动生效；缺图自动退回程序化绘制 |
| 重新生成素材 | `python3 tools/gen_manifest.py` 产出 prompt 清单 → AI 生成原图 → `make_ground_tiles.py` / `make_pickup_sprites.py` / `make_enemy_sprites.py` / `clean_magenta.py` 后处理 |
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
| 改造台 | 走到 `(-360, 0)` 按 E | B | 交互按钮 |
| 切换职业 | Q / P | 左摇杆按下 / 右摇杆按下 | — |
| 背包 | I | Back/Select | 背包按钮 |
| 建造 | B | — | 建造按钮 |
| 技能树 / 职业专职 | K | Guide（Home） | — |
| 暂停 | Esc | Start | — |

> 完整验证步骤见 `docs/VERIFICATION.md`。
