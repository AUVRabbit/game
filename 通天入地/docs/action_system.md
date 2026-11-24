# 统一动作系统 (Unified Action System)

> 适用版本: Godot 4.7.2  
> 核心思想: **所有有动作的对象（玩家/敌人/召唤物/NPC）共享同一个状态机 + 同一个 Controller**，只是它们的"动作能力集（ActionProfile）"不同。灵魂控制时，只换 Profile + SpriteSheet，Controller 继续跑。

---

## 1. 三层架构总览

```
┌────────────────────────────────────────────────────────────┐
│  ActionController (控制器 — 每个对象挂一个)                │
│  ├─ state: ActionState    # 当前状态（枚举）                │
│  ├─ profile: Dictionary  # 能力集（这个对象能做什么）      │
│  └─ facing: Vector2      # 朝向                           │
│                                                          │
│  SpriteAnim (程序化形变层 — 每个 controller 都有)          │
│  ├─ 呼吸、脚步、旋转、压缩、延迟、蓄力曲线                  │
│  └─ 17 种 AnimState 独立 Tween 曲线                       │
│                                                          │
│  AnimatedSprite2D (帧动画层 — 有 sheet 才挂)              │
│  └─ 用 SpriteFramesBuilder 把 sheet 切成 AtlasTexture      │
└────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────────┐
│  ActionProfileRegistry (注册表 — 全局单例)                │
│  ├─ 67 种 profile: 16 玩家 + 5 敌人 + 8 召唤物 + ...      │
│  └─ 每个 profile 声明 "can_xxx": true/false               │
└────────────────────────────────────────────────────────────┘
```

---

## 2. ActionState 完整枚举（30+ 种）

### 2.1 基础姿态（循环）
| 状态 | 含义 | 帧动画 | SpriteAnim 曲线 |
|---|---|---|---|
| `IDLE` | 站立待命 | idle 4帧循环 | 细腻呼吸 + 微重心摇摆 + 眨眼 |
| `WALK` | 走路 | walk 4帧循环 | 步频摆动 + 上下颠动 |
| `RUN` | 跑步 | walk 4帧快放 | 大步伐 + 明显起伏 + 身体前倾 |

### 2.2 低姿态（战术动作）
| 状态 | 含义 | 视觉 |
|---|---|---|
| `CROUCH` | 蹲下 | 压扁至 78% 高 + 重心下移 6px |
| `WALK_CROUCH` | 蹲着走 | 压扁 + 小步频摆动 |
| `PRONE` | 趴下 | 压扁至 45% 高 + 平躺 + 呼吸 |
| `LURK` | 潜伏 | 半蹲 + 左右探头 + 微抖 + **透明度脉动**（隐形感） |

### 2.3 战斗动作（每种独立曲线）
| 状态 | 适用对象 | 曲线 |
|---|---|---|
| `ATTACK_MELEE` | 战士/刺客/骷髅 | 蓄力(t<0.18) → 过顶劈挥击(0.18~0.42) → 回摆 → 收招 |
| `ATTACK_BOW` | 弓手/狙击手/骷髅弓 | 后拉蓄力(t<0.55) → 放箭反弹 |
| `ATTACK_THROW` | 爆破师/工程师 | 下蹲蓄力 → 上抛弹起 |
| `ATTACK_SPELL` | 法师/牧师/烈焰法师 | 双手上抬 + 快速脉动 |
| `ATTACK_SUMMON` | 亡灵法师 | 下沉 + 放大 + 慢速旋转（法阵仪式感） |
| `ATTACK_CHAIN` | 黑客/雷电精灵 | 手指指向目标 + 身体脉动 |
| `DASH` | 冲刺 | 残影轨迹 + 身体微缩 |
| `BLINK` | 闪现 | 无残影，直接瞬移 |

### 2.4 场景化交互
| 状态 | 触发 | 视觉 |
|---|---|---|
| `DIALOG` | 对话 NPC | 轻微前后摇摆 + 每 2.4s 眨一次眼（缩一下） |
| `FORGE` | 锻造台 | 规律性上下锤（蓄力0~0.35 → 敲击0.35~0.45 → 抬起） |
| `SEARCH` | 开箱/采集 | 身体前倾 + 左右快速张望扫动 |
| `PICK_UP` | 拾取 | 弯腰 + 伸手 |
| `OPEN_DOOR` | 开门 | 侧身 + 伸手推 |

### 2.5 生存
| 状态 | 视觉 |
|---|---|
| `HURT` | 受击闪红 + 方向击退 + 后仰旋转 |
| `DEAD` | 缓慢倒地（旋转 45° + 淡出） |
| `Celebrate` | 击杀庆祝（跳跃 + 举武器） |
| `FALL` | 跌落（身体垂直 + 快速旋转） |

---

## 3. ActionProfile 能力集（每种对象的"能做什么"）

### 3.1 Schema（所有 profile 共用）

```gdscript
{
    "id": "player_warrior",        # 唯一 ID
    "kind": "player",              # player / enemy / minion / npc
    "default_sheet": "player_warrior",
    "frame_size": Vector2(128, 128),

    # === 基础姿态 ===
    "can_idle": true,    "can_walk": true,   "can_run": true,
    "can_crouch": true,  "can_prone": false, "can_lurk": false,

    # === 战斗 ===
    "can_attack_melee": true,   "can_attack_bow": false,
    "can_attack_throw": false,  "can_attack_spell": false,
    "can_attack_summon": false, "can_attack_chain": false,
    "can_dash": true,           "can_blink": false,

    # === 交互 ===
    "can_dialog": true, "can_forge": false,
    "can_search": true, "can_pick_up": true, "can_open_door": true,

    # === 物理特性 ===
    "build_height": 1.1,   # 身体挺拔度（战士更高）
    "weight": 1.15,        # 重量（影响击退距离）
}
```

### 3.2 已知 Profile 示例

| ID | kind | 特色 |
|---|---|---|
| `player_warrior` | player | 近战大师：CROUCH+MELEE+DASH，高大挺拔，重 |
| `player_archer` | player | 弓手：BOW+CROUCH+LURK，潜伏偷袭 |
| `player_thief` | player | 刺客：MELEE+CROUCH+PRONE+LURK+BLINK |
| `player_necromancer` | player | 法师+召唤：SPELL+SUMMON |
| `player_engineer` | player | 工程师：THROW+FORGE |
| `enemy_slime` | enemy | 史莱姆：只有 MELEE，不能跑，矮胖 |
| `enemy_wraith` | enemy | 幽魂：SPELL+LURK+PRONE+BLINK，无重量 |
| `enemy_lava_giant` | enemy | 岩浆巨人：MELEE+SPELL，超重量，不能跑 |
| `minion_shadow` | minion | 暗影刺客：MELEE+BLINK+LURK，超轻 |

### 3.3 查询 API

```gdscript
var profiles := ActionProfileRegistry.all_ids()     # ["player_warrior", "enemy_slime", ...]
var count    := ActionProfileRegistry.count()       # 当前总数
var profile  := ActionProfileRegistry.get("player_warrior")
var can_run  := bool(profile.get("can_run", false))
```

---

## 4. 用法

### 4.1 绑定到一个对象

```gdscript
# PlayerController / EnemyBase / SummonedMinion 的 _ready()
var ctrl := ActionController.new()
ctrl.bind(character_body, profile_id="player_warrior", sheet_id="player_warrior")
add_child(ctrl)
```

### 4.2 切换动作

```gdscript
ctrl.play("idle")
ctrl.play("run")
ctrl.play("attack_melee", {"range": 50, "duration": 0.35})
ctrl.play("attack_bow", {"duration": 0.5})
ctrl.play("crouch")
ctrl.play("lurk")
ctrl.play("dialog")
ctrl.play("forge")
ctrl.play("search")
ctrl.play("hurt", {"push_x": -40, "push_y": 20})
ctrl.play("dead")
```

动作切换会**自动**：
1. 检查 profile.can_xxx（不满足会 push_warning 并跳过）
2. 设置 `SpriteAnim.state`（程序化形变曲线）
3. 同步 `AnimatedSprite2D.animation`（帧动画切换）

### 4.3 灵魂控制（SoulBind）

```gdscript
# 玩家变成史莱姆形态（灵魂附着到史莱姆尸体）
ctrl.soul_bind_to(new_profile_id="enemy_slime", new_sheet_id="enemy_slime")

# 1. profile 自动切换 → can_attack_melee=true, can_run=false
# 2. sheet 自动切换 → 帧动画用 enemy_slime 的 sprite
# 3. SpriteAnim flash 紫白光效 → 平滑过渡到 idle
# 4. 原来的 PlayerController 控制逻辑不变，只是动作集变了
```

**关键**：同一个 `ActionController` 实例继续跑，所以玩家不需要重建，只是"换了个身体"。

### 4.4 查询能力

```gdscript
if ctrl.can_do("crouch"):
    ctrl.play("crouch")
var available := ctrl.list_available()
# → ["idle", "walk", "crouch", "attack_melee", ...]
```

---

## 5. 帧动画层（AnimatedSprite2D）

### 5.1 Sheet 生成流程

```
base.png (单帧)
    │
    ▼  gen_sheets2.py 程序化变换
    ├─ xxx_idle.png      (4 帧横排, W×4H)
    ├─ xxx_walk.png      (4 帧)
    ├─ xxx_attack.png    (3 帧)
    ├─ xxx_hit.png       (2 帧)
    └─ xxx_sheet.png     (全动作合并)
```

程序化变换：
- **idle**: 呼吸 + 重心摇摆 + 阴影 wiggle
- **walk**: 脚步交替 + 上下颠 + 小旋转
- **attack**: 蓄力(压缩+后移) → 命中帧(前冲+大旋转) → 收招
- **hit**: 闪红 + 后仰压缩 + 闪白回弹

### 5.2 构建 SpriteFrames

```gdscript
# ActionController 内部自动调：
SpriteFramesBuilder.from_asset_id(
    asset_id="player_warrior",
    frame_w=128, frame_h=128,
    actions=["idle", "walk", "attack", "hit"],
    frame_counts=[4, 4, 3, 2],
    fps=[8, 12, 14, 16]
)
# → 返回 SpriteFrames，每帧用 AtlasTexture 切 sheet
```

SpriteFramesBuilder 自动扫描两个路径：
- `res://assets/sprites/{asset_id}_{action}.png`
- `res://assets/sprites/world/{asset_id}_{action}.png`

### 5.3 帧动画 vs 程序化形变（双层叠加）

```
AnimatedSprite2D（帧切换）  →  "身体" 在动
SpriteAnim（程序化形变）    →  "身体的物理感" 在动

两者叠加：
  帧动画: idle 循环 4 帧（身体静态呼吸）
  形变层: 再叠加大呼吸 + 重心摇摆 + 微旋转
  
  → 细腻度 = 帧动画数 × 形变曲线独立变量数
```

**SoulBind 切换时**：两个层都同步换 → 玩家无缝变成怪物。

---

## 6. 扩展指南

### 6.1 加一个新动作

1. `ActionController.ActionState` 枚举加值（比如 `ANGRY`）
2. `SpriteAnim.AnimState` 枚举加对应值
3. `SpriteAnim._process()` 的 match 加分支（写曲线）
4. `ActionController.play()` 和 `_frame_set_from_state()` 加映射
5. 完成 ✅

### 6.2 加一个新对象类型

```gdscript
# 在 ActionProfileRegistry._ensure() 里加：
var p := _base_npc_profile("npc_blacksmith")
p.can_forge = true
p.can_dialog = true
p.can_attack_melee = false
p.default_sheet = "npc_blacksmith"
_profiles[p.id] = p
```

然后 `gen_sheets2.py` 里加 `npc_blacksmith` 的 base 图生成，再跑一次脚本。完成。

### 6.3 加一种新姿态物理

在 `ActionProfileRegistry._base_*_profile` 里加新字段，然后在 `SpriteAnim` 的对应 match 分支里读这个字段调整曲线参数（比如"重"对象的攻击前冲距离减半）。

---

## 7. 文件索引

| 文件 | 职责 |
|---|---|
| `scripts/combat/action_controller.gd` | **核心**：统一动作控制器（绑定/play/soul_bind） |
| `scripts/combat/action_profile_registry.gd` | **数据**：67 种动作能力集注册表 |
| `scripts/combat/sprite_anim.gd` | **执行层**：17 种程序化形变曲线 |
| `scripts/core/sprite_frames_builder.gd` | **帧动画构建**：sheet → SpriteFrames |
| `gen_sheets2.py` (/tmp) | **资产生成**：base png → sheet 系列 |
| `gen_sprites.py` (/tmp) | **资产生成**：单帧 base sprite |

---

## 8. 常见问题

**Q: 为什么不用 AnimatedSprite2D 代替 SpriteAnim？**
A: 帧动画只能做预定义的序列。我们需要：蓄力→释放→收招的曲线是**运行时参数化**的（比如 `attack_range` 影响前冲距离，`duration` 影响节奏）。SpriteAnim 的程序化形变 + 帧动画层的双层叠加才够。

**Q: 为什么不用 AnimationPlayer？**
A: AnimationPlayer 适合**预先录制好**的固定动作。我们需要：同一个 `attack_melee` 状态，对不同敌人类型（史莱姆矮胖 vs 骷髅瘦高 vs 岩浆巨人笨重）**自动调整曲线参数**。程序化形变能做到这点，AnimationPlayer 做不到。

**Q: 灵魂控制后玩家怎么变回自己？**
A: `ctrl.soul_bind_to("player_warrior")` — 一切原路返回。

**Q: 可以同时控制多个对象的动作吗？**
A: 每个对象有独立的 `ActionController`。可以在一个管理器里统一调度，但 Controller 本身不支持"广播"。
