# 职业流派设计文档（草案 · 待确认）

> 目标：16 职业，每职业 3 条流派，每条流派拥有一整套独立 6 技能 + 独立普攻 + 独立被动。
> 本文档为设计契约，确认后由 `tools/gen_class_content.py` 生成数据、由 `SkillExecutor` 执行。

---

## 一、设计原则

1. **流派 = 一整套玩法**，不是数值皮肤。切换流派后，普攻手感、6 个技能、被动全部变化。
2. **每条流派有唯一战术轴**：同一职业的 3 条流派分别对应“爆发 / 控场或生存 / 机动或功能”，互不替代。
3. **每套 6 技能结构固定**：1/2/3 为基础技能，4/5/6 为进阶技能；4/5/6 分别是 1/2/3 的强化或变体。
4. **数值预算沿用现有规则**：进阶相对同分支基础，威力 ×1.3~1.6、冷却 ×1.5~2.0、法力 ×1.5~1.8。
5. **普攻必须体现职业身份**：近战 / 弹丸 / 超远射线 / 抛掷四类，允许流派内参数分化。
6. **机制全部数据驱动**：`basic_attack` + `skill_overrides` + `skills`，不写死职业分支逻辑。

## 二、流派结构规范

每条流派包含：

| 字段 | 说明 |
| --- | --- |
| `style_name` | 流派名（沿用现有 48 条专职名） |
| `basic_attack` | 普攻形态：`kind`(melee/projectile/beam/lob) + 参数 |
| `passive` | 流派被动（沿用 burn / lifesteal / heal_bonus / shield_bonus，必要时新增） |
| `skills[6]` | 槽位 1/2/3 + 4/5/6，完整替换 |
| `stats` | 轻量数值偏移，仅作流派内微调 |

**技能类型白名单**：`melee_aoe / projectile / beam(经 snipe) / heal / buff / shield / chain / aoe_zone / dash_strike / snipe / deployable / summon / blink_strike / root_zone / heal_zone / mark / stun_wave / pull_zone`。

## 三、与现有系统的关系

1. **技能树不改结构**：仍为 16 节点；R/F/G 三个进阶槽的解锁条件按“槽位”判定，不再绑定具体技能 id。
2. **技能树 UI 显示当前流派技能名**：同一节点在三条流派下显示不同技能名，解锁状态共享。
3. **专职（specialization）即流派载体**：玩家在角色界面切换流派，存档只记录 `style_id`，技能与普攻由数据推导。
4. **图标复用策略**：按“元素 × 形态”复用现有 96 张图标；每条流派仅招牌技能新增 1 张，新增图标控制在 48 张以内。
5. **平衡基线**：同职业三条流派的 `power_score` 必须落在同一带宽内，避免“唯一解”。

---

## 四、法术系（以太 · 蓄势爆发）

### 法师 [mage] — 元素爆发

**流派 A：炎术士（范围爆发）**
- 普攻：`projectile` 火弹，speed 480 / range 320 / cd 0.62 / 溅射 46。
- 被动：`burn` 燃烧 +20%。
- 1 火花术｜`projectile`｜pw1.5 cd1.4 mp8｜speed460 溅射30｜直射火星，命中点燃。
- 2 烈焰喷发｜`aoe_zone`｜pw1.4 cd6 mp16｜半径100 delay0.4｜前方铺开火海。
- 3 熔岩护甲｜`shield`｜pw55 cd12 mp18｜持续7s｜火焰护体，吸收伤害。
- 4 陨星术｜`aoe_zone`｜pw2.6 cd12 mp26｜半径150 delay0.7｜大范围陨星轰击。
- 5 烈焰风暴｜`aoe_zone`｜pw2.0 cd10 mp22｜半径130 delay0.5｜连续火海封锁。
- 6 焚天｜`aoe_zone`｜pw3.2 cd18 mp34｜半径180 delay0.9｜终极清场。

**流派 B：霜法师（控场冻结）**
- 普攻：`projectile` 冰弹，speed 430 / range 300 / cd 0.60 / 溅射 34。
- 被动：`shield_bonus` 护盾 +25%。
- 1 冰锥｜`projectile`｜pw1.4 cd1.5 mp8｜speed440 穿透1｜穿透冰锥。
- 2 冰霜新星｜`root_zone`｜pw1.3 cd7 mp18｜半径110 定身2.2s｜冻结近身敌人。
- 3 寒冰护盾｜`shield`｜pw60 cd12 mp18｜持续8s｜冰盾承伤。
- 4 绝对零度｜`root_zone`｜pw1.8 cd11 mp24｜半径120 定身3.0s｜大范围冻结。
- 5 冰墓｜`chain`｜pw1.6 cd9 mp20｜半径240 目标4｜连锁冰爆。
- 6 永冻领域｜`root_zone`｜pw2.4 cd16 mp30｜半径150 定身3.5s｜终极控场。

**流派 C：秘法学者（高频穿透）**
- 普攻：`projectile` 奥术弹，speed 500 / range 340 / cd 0.42 / 穿透1。
- 被动：无（纯频率流）。
- 1 奥术飞弹｜`projectile`｜pw1.2 cd1.0 mp6｜speed520 穿透2｜高频穿透。
- 2 奥能涌动｜`buff`｜cd10 mp14｜攻速+25% 持续6s｜加速施法。
- 3 法力护盾｜`shield`｜pw45 cd10 mp14｜持续6s｜小盾自保。
- 4 奥术洪流｜`snipe`｜pw1.8 cd8 mp18｜range360 width14｜直线贯穿。
- 5 飞弹风暴｜`projectile`｜pw1.5 cd6 mp16｜三连发 spread0.12｜扇形弹幕。
- 6 时间加速｜`buff`｜cd16 mp26｜攻速+50% 持续8s｜终极频率。

### 咒铠师 [runeward] — 符文装甲

**流派 A：符阵大师（护盾反击）**
- 普攻：`melee` 魔法，radius 60 / knockback 8 / cd 0.46。
- 被动：`shield_bonus` 护盾 +35%。
- 1 符盾｜`shield`｜pw60 cd12 mp16｜持续7s｜基础承伤。
- 2 符爆｜`stun_wave`｜pw1.4 cd5 mp12｜半径86 眩晕0.9s 击退60｜贴身反打。
- 3 咒护｜`buff`｜cd14 mp14｜防御+12 持续8s｜强化护甲。
- 4 反噬符文｜`shield`｜pw95 cd18 mp22｜持续9s｜厚盾。
- 5 符文禁锢｜`root_zone`｜pw1.9 cd11 mp20｜半径110 定身2.5s｜锁住敌人。
- 6 符阵壁垒｜`buff`｜cd20 mp24｜防御+26 持续10s｜终极减伤。

**流派 B：反噬者（震退反打）**
- 普攻：`melee` 魔法，radius 58 / knockback 14 / cd 0.44。
- 被动：`shield_bonus` 护盾 +20%。
- 1 反冲符｜`melee_aoe`｜pw1.3 cd4 mp10｜半径80 击退100｜震开近身之敌。
- 2 震符｜`stun_wave`｜pw1.2 cd7 mp14｜半径90 眩晕0.7s 击退120｜范围震退。
- 3 血符｜`shield`｜pw50 cd11 mp16｜持续6s｜以血换盾。
- 4 反噬环｜`stun_wave`｜pw1.9 cd10 mp20｜半径110 眩晕0.8s 击退160｜强力反打。
- 5 符链｜`chain`｜pw1.5 cd9 mp18｜半径220 目标4｜符文弹射。
- 6 万符归宗｜`stun_wave`｜pw2.6 cd16 mp28｜半径150 眩晕1.2s 击退200｜终极反制。

**流派 C：守誓者（铁壁站场）**
- 普攻：`melee` 魔法，radius 70 / knockback 4 / cd 0.55。
- 被动：`shield_bonus` 护盾 +30%。
- 1 誓约盾｜`shield`｜pw75 cd13 mp18｜持续8s｜高额基础盾。
- 2 符能重击｜`melee_aoe`｜pw1.5 cd6 mp14｜半径90 击退40｜稳站场输出。
- 3 坚壁｜`buff`｜cd16 mp18｜防御+18 持续10s｜长时减伤。
- 4 不朽壁垒｜`shield`｜pw120 cd20 mp26｜持续10s｜超厚护盾。
- 5 大地符阵｜`root_zone`｜pw1.5 cd12 mp22｜半径130 定身3.0s｜区域封锁。
- 6 誓约圣所｜`heal_zone`｜cd20 mp30｜半径140 每秒24 持续6s｜领域自愈。

### 牧师 [priest] — 神圣庇佑

**流派 A：神谕者（领域治疗）**
- 普攻：`projectile` 圣光弹，speed 430 / range 300 / cd 0.55 / 溅射 40 / 魔法。
- 被动：`heal_bonus` 治疗 +20%。
- 1 治疗术｜`heal`｜pw45 cd4 mp14｜立即回复自身生命。
- 2 圣光弹｜`projectile`｜pw1.2 cd3 mp10｜speed460 溅射30｜远程补伤。
- 3 祝福｜`buff`｜cd14 mp16｜防御+10 持续8s｜团队减伤。
- 4 圣愈光辉｜`heal_zone`｜cd14 mp32｜半径140 每秒28 持续6s｜持续治疗领域。
- 5 圣光新星｜`melee_aoe`｜pw1.8 cd9 mp22｜半径110｜近身圣光爆发。
- 6 神谕降临｜`heal_zone`｜cd20 mp38｜半径160 每秒40 持续8s｜终极治疗领域。

**流派 B：圣殿骑士（近战圣光）**
- 普攻：`melee` 魔法，radius 62 / knockback 8 / cd 0.48。
- 被动：`shield_bonus` 护盾 +35%。
- 1 圣光斩｜`melee_aoe`｜pw1.6 cd3.5 mp10｜半径80｜近身圣光横斩。
- 2 神圣新星｜`melee_aoe`｜pw1.4 cd7 mp18｜半径100｜范围净化。
- 3 圣盾｜`shield`｜pw60 cd12 mp16｜持续7s｜格挡承伤。
- 4 审判之光｜`stun_wave`｜pw2.0 cd11 mp24｜半径110 眩晕1.0s 击退50｜审判控场。
- 5 圣殿冲锋｜`dash_strike`｜pw1.9 cd9 mp18｜distance180 半径70｜突进开团。
- 6 神圣裁决｜`snipe`｜pw2.6 cd15 mp28｜range300 width24 吸血20%｜直线裁决。

**流派 C：苦修者（血盾自疗）**
- 普攻：`melee` 魔法，radius 58 / knockback 4 / cd 0.50。
- 被动：`heal_bonus` 治疗 +25%。
- 1 苦修｜`heal`｜pw35 cd6 mp12｜低耗自疗。
- 2 鞭笞｜`melee_aoe`｜pw1.5 cd3 mp8｜半径75｜以痛楚换取伤害。
- 3 忏悔护盾｜`shield`｜pw45 cd10 mp14｜持续6s｜苦修者的护体。
- 4 血誓｜`heal_zone`｜cd12 mp24｜半径120 每秒26 持续6s｜血誓领域。
- 5 神圣惩戒｜`stun_wave`｜pw1.8 cd10 mp20｜半径100 眩晕0.6s 击退70｜惩戒控场。
- 6 殉道｜`heal`｜pw120 cd20 mp30｜以殉道之姿大量回复。

### 亡灵法师 [necromancer] — 生死操控

**流派 A：收割者（吸血单点）**
- 普攻：`projectile` 魂矢，speed 400 / range 320 / cd 0.55 / 穿透1 / 魔法。
- 被动：`lifesteal` 吸血 +18%。
- 1 腐蚀箭｜`projectile`｜pw1.6 cd1.8 mp16｜speed400 穿透1｜腐蚀穿透。
- 2 汲取｜`snipe`｜pw1.5 cd8 mp14｜range300 width14 吸血50%｜噬魂射线。
- 3 黑暗护盾｜`shield`｜pw50 cd12 mp16｜持续7s｜以魂护体。
- 4 噬魂｜`snipe`｜pw2.2 cd9 mp20｜range360 width18 吸血60%｜强化吸血。
- 5 灵魂虹吸｜`snipe`｜pw1.8 cd9 mp20｜range380 width16 吸血70%｜远距汲取。
- 6 死神收割｜`snipe`｜pw3.0 cd16 mp30｜range460 width24 吸血80%｜终极收割。

**流派 B：瘟疫术士（腐蚀扩散）**
- 普攻：`projectile` 毒弹，speed 400 / range 320 / cd 0.60 / 溅射44 / 魔法。
- 被动：`burn` 腐蚀 +20%。
- 1 腐毒弹｜`projectile`｜pw1.4 cd1.8 mp14｜speed400 溅射40｜腐蚀扩散。
- 2 瘟疫云｜`aoe_zone`｜pw1.2 cd8 mp18｜半径110 delay0.4｜区域腐蚀。
- 3 疫病护体｜`shield`｜pw45 cd12 mp16｜持续7s｜腐蚀护盾。
- 4 腐魂连矢｜`chain`｜pw1.6 cd9 mp22｜半径240 目标5｜连锁腐蚀。
- 5 瘟疫爆发｜`aoe_zone`｜pw1.9 cd11 mp24｜半径130 delay0.5｜大范围爆发。
- 6 大疫｜`aoe_zone`｜pw2.8 cd16 mp30｜半径160 delay0.7｜终极瘟疫。

**流派 C：尸傀师（亡灵大军）**
- 普攻：`projectile` 魂矢，speed 400 / range 320 / cd 0.55 / 穿透1 / 魔法。
- 被动：`lifesteal` 吸血 +15%。
- 1 腐蚀箭｜`projectile`｜pw1.3 cd2 mp14｜speed400 穿透1｜基础魂矢。
- 2 亡者领域｜`summon`｜pw1.4 cd9 mp24｜2只 持续10s 速度115 间隔1.1｜召唤骷髅。
- 3 尸傀护盾｜`shield`｜pw45 cd12 mp16｜持续7s｜以尸气护体。
- 4 万尸之地｜`summon`｜pw1.8 cd15 mp28｜3只 持续14s 速度130 间隔1.0｜强化亡灵。
- 5 腐化狂潮｜`summon`｜pw2.0 cd12 mp24｜2只 持续12s 速度140 间隔0.8｜快速亡灵。
- 6 亡灵天灾｜`summon`｜pw2.0 cd20 mp34｜5只 持续16s 速度135 间隔0.9｜亡灵大军。

---

## 五、机械系（蒸汽 · 布置引爆）

### 炸弹专家 [bomber] — 爆破工程

**流派 A：爆破专家（单发大爆）**
- 普攻：`lob` 炸弹，range 260 / radius 80 / fuse 0.55 / cd 0.80。
- 被动：纯伤害增幅（技能威力 +25%）。
- 1 投掷炸弹｜`deployable` bomb｜pw1.9 cd3 mp10｜1枚 半径90 fuse0.6｜安放定时炸药。
- 2 大爆破｜`aoe_zone`｜pw1.6 cd8 mp18｜半径110 delay0.5｜区域爆破。
- 3 防爆护甲｜`shield`｜pw50 cd12 mp16｜持续7s｜防爆承伤。
- 4 集束炸弹｜`deployable` bomb｜pw2.6 cd9 mp20｜2枚 散布80 半径100 fuse0.5｜双雷覆盖。
- 5 高爆地雷｜`deployable` mine｜pw2.2 cd10 mp20｜2枚 半径110 持续18s｜布雷封锁。
- 6 终极爆破｜`deployable` bomb｜pw3.0 cd16 mp30｜3枚 散布100 半径120 fuse0.5｜终极爆破。

**流派 B：纵火者（燃烧控场）**
- 普攻：`lob` 燃烧瓶，range 250 / radius 70 / fuse 0.40 / cd 0.75。
- 被动：`burn` 燃烧 +20%。
- 1 燃烧瓶｜`root_zone`｜pw1.1 cd4 mp10｜半径100 定身1.5s｜火海迟滞。
- 2 火墙｜`aoe_zone`｜pw1.3 cd7 mp16｜半径110 delay0.4｜火焰封锁。
- 3 耐火甲｜`shield`｜pw50 cd12 mp16｜持续7s｜耐火护体。
- 4 燃烧弹｜`root_zone`｜pw1.7 cd9 mp20｜半径120 定身2.5s｜强化燃烧。
- 5 火海｜`aoe_zone`｜pw2.0 cd11 mp22｜半径130 delay0.5｜大片火海。
- 6 烈焰炼狱｜`root_zone`｜pw2.6 cd16 mp30｜半径150 定身3.0s｜终极火海。

**流派 C：铝热师（雷区封锁）**
- 普攻：`lob` 铝热弹，range 260 / radius 66 / fuse 0.50 / cd 0.80。
- 被动：无（纯布置流）。
- 1 感应地雷｜`deployable` mine｜pw1.6 cd6 mp12｜1枚 半径80 持续18s｜感应引爆。
- 2 爆破领域｜`deployable` bomb｜pw1.4 cd8 mp18｜2枚 散布80 半径70 fuse0.6｜双雷布场。
- 3 工程护盾｜`shield`｜pw45 cd12 mp16｜持续7s｜布置时的自保。
- 4 雷区｜`deployable` mine｜pw2.0 cd10 mp22｜3枚 散布90 半径90 持续18s｜三雷封锁。
- 5 连环爆破｜`deployable` bomb｜pw2.2 cd14 mp26｜4枚 散布150 半径85 fuse0.6｜连锁起爆。
- 6 焦土雷场｜`deployable` mine｜pw2.6 cd18 mp32｜5枚 散布140 半径100 持续20s｜终极雷场。

### 机甲师 [mech_pilot] — 重装要塞

**流派 A：重装机兵（重炮）**
- 普攻：`projectile` 机炮，speed 480 / range 360 / cd 0.70 / 溅射50。
- 被动：`shield_bonus` 护盾 +30%。
- 1 重炮轰击｜`projectile`｜pw2.0 cd3 mp10｜speed360 溅射60｜主炮轰击。
- 2 装甲强化｜`shield`｜pw70 cd12 mp12｜持续8s｜基础装甲。
- 3 能量护盾｜`buff`｜cd14 mp14｜防御+14 持续7s｜能量减伤。
- 4 轨道炮｜`snipe`｜pw2.6 cd9 mp18｜range640 width18｜重炮贯穿。
- 5 复合装甲｜`shield`｜pw120 cd20 mp22｜持续9s｜复合护盾。
- 6 力场护罩｜`buff`｜cd20 mp20｜防御+26 持续10s｜终极减伤。

**流派 B：速射炮手（速射）**
- 普攻：`projectile` 机炮，speed 560 / range 340 / cd 0.50 / 三弹散布。
- 被动：无（纯频率流）。
- 1 机炮扫射｜`projectile`｜pw0.9 cd2.4 mp8｜三连发 散布0.10｜高频扫射。
- 2 弹幕覆盖｜`aoe_zone`｜pw1.2 cd7 mp16｜半径100 delay0.4｜弹幕压制。
- 3 速射装甲｜`buff`｜cd12 mp14｜攻速+25% 持续6s｜加速输出。
- 4 火神炮｜`projectile`｜pw1.5 cd7 mp18｜四连发 散布0.12｜火力提升。
- 5 弹雨｜`aoe_zone`｜pw1.8 cd10 mp22｜半径120 delay0.4｜范围弹幕。
- 6 全弹发射｜`projectile`｜pw2.2 cd14 mp26｜六连发 散布0.16｜终极弹幕。

**流派 C：要塞驾驶员（护盾）**
- 普攻：`projectile` 机炮，speed 500 / range 360 / cd 0.68 / 溅射38。
- 被动：`shield_bonus` 护盾 +35%。
- 1 装甲强化｜`shield`｜pw80 cd12 mp14｜持续8s｜高额基础盾。
- 2 要塞炮｜`projectile`｜pw1.7 cd4 mp12｜speed400 溅射40｜要塞主炮。
- 3 力场｜`buff`｜cd14 mp16｜防御+16 持续8s｜力场减伤。
- 4 战斗要塞｜`shield`｜pw130 cd20 mp24｜持续10s｜超厚护盾。
- 5 要塞齐射｜`aoe_zone`｜pw1.9 cd12 mp24｜半径130 delay0.5｜全炮齐射。
- 6 不动要塞｜`buff`｜cd22 mp26｜防御+30 持续12s｜终极站场。

### 工程师 [engineer] — 战地工事

**流派 A：炮塔专家（炮塔流）**
- 普攻：`projectile` 枪械，speed 520 / range 340 / cd 0.55。
- 被动：无（设备输出）。
- 1 炮塔部署｜`deployable` turret｜pw1.6 cd7 mp16｜1座 持续14s 间隔0.8｜自动炮塔。
- 2 修理｜`heal`｜pw50 cd9 mp18｜应急修复。
- 3 战术补给｜`buff`｜cd12 mp12｜攻击+8 持续8s｜强化弹头。
- 4 重型炮塔｜`deployable` turret｜pw2.2 cd11 mp24｜持续20s 间隔0.6｜重型火力。
- 5 双联炮塔｜`deployable` turret｜pw1.8 cd14 mp28｜2座 散布60 持续16s 间隔0.7｜双塔交叉。
- 6 要塞炮台｜`deployable` turret｜pw3.0 cd18 mp34｜持续24s 间隔0.45｜终极炮台。

**流派 B：后勤官（支援）**
- 普攻：`projectile` 枪械，speed 520 / range 360 / cd 0.60。
- 被动：`heal_bonus` 治疗 +30%。
- 1 应急修理｜`heal`｜pw60 cd8 mp16｜快速修复。
- 2 战术补给｜`buff`｜cd12 mp12｜攻击+12 持续8s｜团队强化。
- 3 护盾发生器｜`shield`｜pw60 cd12 mp16｜持续7s｜便携护盾。
- 4 战地整备｜`heal`｜pw95 cd14 mp28｜大量回复。
- 5 全队补给｜`buff`｜cd16 mp22｜攻击+20 持续10s｜强力增益。
- 6 战地医院｜`heal_zone`｜cd20 mp32｜半径150 每秒30 持续8s｜领域治疗。

**流派 C：过载技师（超频）**
- 普攻：`projectile` 枪械，speed 560 / range 340 / cd 0.40。
- 被动：无（攻速流）。
- 1 过载弹｜`projectile`｜pw1.2 cd2.5 mp10｜speed600｜超频弹头。
- 2 炮塔部署｜`deployable` turret｜pw1.4 cd7 mp16｜持续12s 间隔0.5｜速射炮塔。
- 3 超频｜`buff`｜cd12 mp14｜攻速+30% 持续6s｜系统超频。
- 4 重型炮塔｜`deployable` turret｜pw1.9 cd10 mp22｜持续14s 间隔0.4｜速射重塔。
- 5 弹幕炮塔｜`deployable` turret｜pw1.6 cd14 mp26｜2座 持续14s 间隔0.5｜双塔速射。
- 6 蒸汽狂潮｜`buff`｜cd18 mp26｜攻速+60% 持续9s｜终极超频。

### 赏金猎人 [bounty_hunter] — 猎杀契约

**流派 A：赏金猎人（标记收割）**
- 普攻：`projectile` 双枪，speed 620 / range 340 / cd 0.58 / 双弹微扩散。
- 被动：无（标记增伤）。
- 1 连射｜`chain`｜pw1.0 cd3 mp10｜半径240 目标3｜多目标速射。
- 2 追踪标记｜`mark`｜cd12 mp8｜半径340 易伤35% 持续8s｜标记猎物。
- 3 快速拔枪｜`buff`｜cd10 mp12｜攻速+20% 持续6s｜出枪加速。
- 4 弹幕压制｜`chain`｜pw1.6 cd8 mp18｜半径220 目标5｜压制射击。
- 5 死神标记｜`mark`｜cd16 mp14｜半径420 易伤50% 持续10s｜强标记。
- 6 猎杀时刻｜`mark`｜cd20 mp20｜半径460 易伤60% 持续12s｜终极标记。

**流派 B：追迹者（弹幕速射）**
- 普攻：`projectile` 双枪，speed 640 / range 340 / cd 0.42 / 双弹微扩散。
- 被动：无（纯射速）。
- 1 速射｜`projectile`｜pw0.9 cd2 mp8｜三连发 散布0.10｜高频射击。
- 2 扫射｜`chain`｜pw1.0 cd5 mp12｜半径220 目标3｜范围扫射。
- 3 疾行｜`buff`｜cd10 mp12｜移速+25% 持续6s｜走位加速。
- 4 弹幕风暴｜`projectile`｜pw1.4 cd7 mp16｜五连发 散布0.14｜密集弹幕。
- 5 弹幕压制｜`chain`｜pw1.6 cd9 mp20｜半径260 目标7｜大范围压制。
- 6 火力全开｜`projectile`｜pw2.0 cd13 mp26｜七连发 散布0.16｜终极弹幕。

**流派 C：赏金之王（单点爆发）**
- 普攻：`projectile` 重弹，speed 700 / range 360 / cd 0.65。
- 被动：无（单点增伤）。
- 1 精准射击｜`projectile`｜pw1.8 cd3 mp10｜speed760｜高伤单发。
- 2 断腕射击｜`stun_wave`｜pw1.5 cd6 mp14｜半径85 眩晕0.8s 击退70｜打断突进。
- 3 猎人直觉｜`buff`｜cd12 mp12｜暴击+25% 持续6s｜蓄势。
- 4 致死射击｜`snipe`｜pw2.4 cd9 mp18｜range360 width12｜致命直线。
- 5 终结标记｜`mark`｜cd15 mp16｜半径420 易伤45% 持续10s｜收尾标记。
- 6 王者一击｜`snipe`｜pw3.2 cd16 mp26｜range420 width16 吸血15%｜终极单点。

---

## 六、传武系（气血 · 贴身缠斗）

### 死亡骑士 [death_knight] — 血怒冲锋

**流派 A：血骑（吸血冲锋）**
- 普攻：`melee` radius 66 / knockback 4 / cd 0.50。
- 被动：`lifesteal` 吸血 +22%。
- 1 死亡冲锋｜`dash_strike`｜pw1.5 cd5 mp10｜distance140 半径60｜突进开团。
- 2 血斩｜`melee_aoe`｜pw1.7 cd4 mp12｜半径80｜范围血斩。
- 3 黑暗护盾｜`shield`｜pw55 cd14 mp16｜持续7s｜以盾抵代价。
- 4 亡者冲锋｜`dash_strike`｜pw2.2 cd9 mp16｜distance180 半径78｜进阶突进。
- 5 血怒斩｜`snipe`｜pw2.4 cd8 mp18｜range260 width22 吸血60%｜血刃穿透。
- 6 血河｜`snipe`｜pw3.2 cd16 mp28｜range340 width28 吸血70%｜终极血刃。

**流派 B：墓卫（重甲坦）**
- 普攻：`melee` radius 70 / knockback 12 / cd 0.55。
- 被动：`shield_bonus` 护盾 +30%。
- 1 墓土重击｜`melee_aoe`｜pw1.5 cd4 mp12｜半径85 击退40｜重击控位。
- 2 黑暗护盾｜`shield`｜pw70 cd13 mp16｜持续8s｜基础厚盾。
- 3 亡者威压｜`buff`｜cd14 mp16｜防御+16 持续8s｜威压减伤。
- 4 暗影壁垒｜`shield`｜pw100 cd18 mp22｜持续9s｜进阶护盾。
- 5 死亡践踏｜`stun_wave`｜pw2.0 cd10 mp20｜半径110 眩晕0.8s 击退80｜践踏控场。
- 6 不朽墓卫｜`shield`｜pw140 cd20 mp26｜持续10s｜终极护盾。

**流派 C：血誓者（血刃）**
- 普攻：`melee` radius 72 / knockback 2 / cd 0.46。
- 被动：`lifesteal` 吸血 +25%。
- 1 血刃｜`melee_aoe`｜pw1.8 cd3.5 mp10｜半径75｜高频血刃。
- 2 血偿｜`heal`｜pw40 cd8 mp14｜以血换伤后回复。
- 3 血盾｜`shield`｜pw45 cd12 mp16｜持续7s｜薄盾救命。
- 4 血斩风暴｜`melee_aoe`｜pw2.4 cd8 mp18｜半径95｜范围斩击。
- 5 血怒斩｜`snipe`｜pw2.6 cd9 mp20｜range280 width24 吸血55%｜远距血刃。
- 6 血海｜`snipe`｜pw3.4 cd15 mp28｜range300 width32 吸血60%｜终极血海。

### 战士 [warrior] — 铁壁反击

**流派 A：狂战士（狂暴）**
- 普攻：`melee` radius 70 / knockback 4 / cd 0.38。
- 被动：`lifesteal` 吸血 +20%。
- 1 旋风斩｜`melee_aoe`｜pw1.8 cd3 mp8｜半径95｜高频范围斩。
- 2 战吼｜`buff`｜cd10 mp10｜攻击+16 持续6s｜爆发窗口。
- 3 暴怒｜`buff`｜cd10 mp12｜暴击+20% 持续6s｜狂暴蓄势。
- 4 裂地斩｜`stun_wave`｜pw2.3 cd9 mp18｜半径120 眩晕0.6s 击退90｜范围硬控。
- 5 不屈战意｜`buff`｜cd18 mp16｜攻击+24 持续9s｜越战越勇。
- 6 狂战风暴｜`melee_aoe`｜pw3.2 cd14 mp26｜半径150｜终极旋风。

**流派 B：剑圣（剑气流）**
- 普攻：`melee` radius 66 / knockback 2 / cd 0.40。
- 被动：`shield_bonus` 护盾 +30%。
- 1 剑气斩｜`snipe`｜pw1.6 cd3 mp10｜range240 width16｜远程剑气。
- 2 旋风斩｜`melee_aoe`｜pw1.6 cd4 mp10｜半径85｜近身横扫。
- 3 剑心｜`buff`｜cd12 mp12｜攻速+20% 持续6s｜剑心通明。
- 4 剑气纵横｜`snipe`｜pw2.4 cd8 mp18｜range300 width20｜进阶剑气。
- 5 剑刃风暴｜`melee_aoe`｜pw2.2 cd10 mp20｜半径110｜范围剑舞。
- 6 万剑归宗｜`snipe`｜pw3.4 cd15 mp28｜range400 width26｜终极剑气。

**流派 C：破阵者（突进震波）**
- 普攻：`melee` radius 64 / knockback 10 / cd 0.44。
- 被动：无（突进流）。
- 1 突进斩｜`dash_strike`｜pw1.5 cd5 mp10｜distance150 半径60｜突进起手。
- 2 裂地斩｜`stun_wave`｜pw1.6 cd6 mp14｜半径100 眩晕0.5s 击退80｜震波控场。
- 3 战吼｜`buff`｜cd10 mp10｜攻击+8 持续6s｜开团增益。
- 4 破阵冲锋｜`dash_strike`｜pw2.2 cd9 mp16｜distance200 半径78｜强力突进。
- 5 震岳｜`stun_wave`｜pw2.2 cd10 mp20｜半径130 眩晕0.8s 击退140｜大范围震波。
- 6 山崩｜`dash_strike`｜pw3.0 cd15 mp26｜distance260 半径110｜终极突进。

### 气宗 [qi_adept] — 内息流转

**流派 A：医武（治疗）**
- 普攻：`melee` radius 70 / knockback 10 / cd 0.42。
- 被动：`heal_bonus` 治疗 +30%。
- 1 气劲掌｜`melee_aoe`｜pw1.4 cd3.5 mp9｜半径78｜基础掌风。
- 2 内息术｜`heal`｜pw50 cd8 mp18｜气血自疗。
- 3 气脉流转｜`buff`｜cd12 mp12｜攻速+18% 持续7s｜气血周天。
- 4 生生不息｜`heal_zone`｜cd12 mp30｜半径140 每秒30 持续6s｜持续治疗领域。
- 5 罡气爆｜`stun_wave`｜pw1.8 cd8 mp18｜半径100 眩晕0.6s 击退80｜自保震波。
- 6 妙手回春｜`heal`｜pw140 cd18 mp34｜大量自愈。

**流派 B：罡气宗师（震波）**
- 普攻：`melee` radius 80 / knockback 16 / cd 0.46。
- 被动：`shield_bonus` 护盾 +30%。
- 1 罡气掌｜`melee_aoe`｜pw1.6 cd4 mp10｜半径85 击退30｜罡气外放。
- 2 罡气爆｜`stun_wave`｜pw1.5 cd6 mp14｜半径100 眩晕0.7s 击退100｜范围震波。
- 3 罡气护体｜`shield`｜pw70 cd14 mp16｜持续8s｜气墙护体。
- 4 震罡｜`stun_wave`｜pw2.2 cd9 mp20｜半径120 眩晕0.9s 击退140｜强力震波。
- 5 气墙｜`buff`｜cd16 mp18｜防御+20 持续9s｜持续减伤。
- 6 罡气天罡｜`stun_wave`｜pw3.0 cd15 mp28｜半径150 眩晕1.2s 击退180｜终极震波。

**流派 C：疾风武者（连击）**
- 普攻：`melee` radius 64 / knockback 4 / cd 0.32。
- 被动：无（纯攻速）。
- 1 疾风掌｜`melee_aoe`｜pw1.3 cd2.5 mp8｜半径70｜高频掌击。
- 2 气脉流转｜`buff`｜cd12 mp12｜攻速+30% 持续7s｜极速周转。
- 3 流云步｜`buff`｜cd10 mp12｜移速+30% 持续6s｜走位如风。
- 4 疾风连击｜`melee_aoe`｜pw1.9 cd7 mp16｜半径85｜连击强化。
- 5 罡风突袭｜`dash_strike`｜pw2.0 cd9 mp18｜distance180 半径70｜突进连击。
- 6 无影疾风｜`melee_aoe`｜pw2.8 cd13 mp24｜半径120｜终极连击。

### 小偷 [thief] — 影袭毒刃

**流派 A：刺客（背刺）**
- 普攻：`melee` radius 52 / cd 0.28。
- 被动：无（背刺爆发）。
- 1 背刺｜`blink_strike`｜pw2.0 cd2.4 mp6｜range180 半径65｜闪现背刺。
- 2 毒刃｜`projectile`｜pw1.2 cd3 mp8｜speed480｜淬毒飞刃。
- 3 烟雾弹｜`buff`｜cd10 mp10｜闪避+30% 持续5s｜脱离仇恨。
- 4 致命背刺｜`blink_strike`｜pw2.8 cd6 mp14｜range220 半径80｜进阶背刺。
- 5 影袭｜`blink_strike`｜pw2.4 cd8 mp16｜range200 半径75｜连续闪袭。
- 6 瞬杀｜`blink_strike`｜pw3.6 cd12 mp24｜range260 半径95｜终极瞬杀。

**流派 B：影行者（闪避）**
- 普攻：`melee` radius 50 / cd 0.30。
- 被动：`shield_bonus` 护盾 +20%。
- 1 影步｜`dash_strike`｜pw1.2 cd3 mp8｜distance140 半径50｜位移脱身。
- 2 烟雾弹｜`buff`｜cd10 mp10｜闪避+45% 持续5s｜高闪避窗口。
- 3 暗影护盾｜`shield`｜pw40 cd12 mp14｜持续6s｜影盾。
- 4 烟幕遁形｜`buff`｜cd14 mp16｜闪避+60% 持续6s｜强隐身。
- 5 影袭｜`blink_strike`｜pw2.0 cd8 mp16｜range190 半径70｜闪现补伤。
- 6 无影｜`buff`｜cd18 mp22｜闪避+70% 持续8s｜终极闪避。

**流派 C：影舞者（毒刃）**
- 普攻：`melee` radius 54 / cd 0.30。
- 被动：无（毒伤扩散）。
- 1 毒刃｜`projectile`｜pw1.2 cd2.5 mp8｜speed500 穿透1｜穿透毒刃。
- 2 淬毒｜`buff`｜cd10 mp10｜攻速+20% 持续6s｜上毒加速。
- 3 毒雾｜`root_zone`｜pw1.0 cd8 mp14｜半径100 定身1.5s｜毒雾迟滞。
- 4 剧毒爆发｜`projectile`｜pw1.8 cd7 mp16｜speed520 溅射45｜毒囊炸裂。
- 5 毒刃风暴｜`projectile`｜pw1.5 cd8 mp18｜三连发 散布0.12｜扇形毒刃。
- 6 万毒噬心｜`root_zone`｜pw2.4 cd14 mp26｜半径140 定身2.5s｜终极毒域。

---

## 七、科技系（算力 · 预判压制）

### 弓箭手 [archer] — 精确投射

**流派 A：神射手（暴击穿透）**
- 普攻：`projectile` 箭，speed 720 / range 400 / cd 0.50 / 穿透1。
- 被动：无（暴击穿透）。
- 1 穿透射击｜`projectile`｜pw1.6 cd2 mp6｜speed620 穿透3 range380｜蓄力贯射。
- 2 鹰眼｜`buff`｜cd12 mp10｜暴击+25% 持续6s｜瞄准要害。
- 3 屏息｜`buff`｜cd10 mp10｜暴击+15% 持续8s｜稳定输出。
- 4 破甲贯射｜`projectile`｜pw2.5 cd6 mp12｜speed680 穿透4 range420｜贯穿直线。
- 5 贯穿箭雨｜`aoe_zone`｜pw1.8 cd10 mp20｜半径110 delay0.4｜区域贯射。
- 6 一箭穿心｜`snipe`｜pw3.2 cd14 mp26｜range520 width14｜终极点杀。

**流派 B：游侠（游击）**
- 普攻：`projectile` 箭，speed 660 / range 380 / cd 0.42。
- 被动：无（机动游击）。
- 1 快速射击｜`projectile`｜pw1.1 cd1.6 mp6｜speed700｜高频射击。
- 2 箭雨｜`aoe_zone`｜pw1.2 cd8 mp15｜半径110 delay0.4｜区域覆盖。
- 3 疾行｜`buff`｜cd10 mp10｜移速+30% 持续6s｜风筝走位。
- 4 万箭齐发｜`aoe_zone`｜pw2.0 cd12 mp22｜半径130 delay0.5｜大范围箭雨。
- 5 束缚箭｜`root_zone`｜pw1.4 cd9 mp16｜半径100 定身1.5s｜限制追击。
- 6 箭雨风暴｜`aoe_zone`｜pw2.8 cd16 mp28｜半径150 delay0.6｜终极箭雨。

**流派 C：疾风猎手（速射）**
- 普攻：`projectile` 箭，speed 700 / range 380 / cd 0.42 / 双箭微扩散。
- 被动：无（纯射速）。
- 1 双箭｜`projectile`｜pw0.9 cd1.8 mp6｜双发 散布0.06｜快速双箭。
- 2 鹰眼｜`buff`｜cd10 mp10｜攻速+20% 持续6s｜加速瞄准。
- 3 疾风｜`buff`｜cd10 mp10｜攻速+15% 持续6s｜疾风身法。
- 4 五连射｜`projectile`｜pw1.4 cd6 mp14｜五连发 散布0.12｜密集射击。
- 5 万箭齐发｜`aoe_zone`｜pw1.8 cd10 mp20｜半径120 delay0.4｜范围覆盖。
- 6 箭幕｜`projectile`｜pw2.2 cd13 mp24｜七连发 散布0.14｜终极箭幕。

### 义体卫士 [cyborg] — 义体壁垒

**流派 A：磁轨先锋（突进）**
- 普攻：`melee` radius 64 / knockback 10 / cd 0.50。
- 被动：无（突进爆发）。
- 1 液压重拳｜`melee_aoe`｜pw1.7 cd4 mp10｜半径74｜重拳开路。
- 2 伺服突进｜`dash_strike`｜pw1.6 cd6 mp12｜distance160 半径64｜突进撞击。
- 3 能量壁垒｜`shield`｜pw70 cd13 mp16｜持续7s｜突进前护盾。
- 4 磁轨突袭｜`dash_strike`｜pw2.6 cd10 mp20｜distance220 半径80｜远距突进。
- 5 震荡践踏｜`stun_wave`｜pw2.2 cd9 mp18｜半径110 眩晕0.7s 击退100｜突进后控场。
- 6 磁轨风暴｜`dash_strike`｜pw3.2 cd16 mp28｜distance300 半径120｜终极突进。

**流派 B：不动堡垒（坦克）**
- 普攻：`melee` radius 70 / knockback 6 / cd 0.60。
- 被动：`shield_bonus` 护盾 +30%。
- 1 能量壁垒｜`shield`｜pw85 cd13 mp16｜持续7s｜基础厚盾。
- 2 重拳｜`melee_aoe`｜pw1.5 cd5 mp12｜半径80 击退30｜近身控位。
- 3 装甲协议｜`buff`｜cd14 mp16｜防御+18 持续8s｜持续减伤。
- 4 神盾协议｜`shield`｜pw130 cd18 mp24｜持续8s｜海量护盾。
- 5 震荡践踏｜`stun_wave`｜pw2.0 cd10 mp20｜半径120 眩晕1.0s 击退90｜范围控场。
- 6 不动堡垒｜`buff`｜cd20 mp26｜防御+32 持续12s｜终极站场。

**流派 C：超频武人（连拳）**
- 普攻：`melee` radius 62 / knockback 6 / cd 0.34。
- 被动：无（纯攻速）。
- 1 液压连拳｜`melee_aoe`｜pw1.4 cd3 mp8｜半径80｜高频重拳。
- 2 伺服突进｜`dash_strike`｜pw1.4 cd6 mp12｜distance150 半径60｜突进贴脸。
- 3 超频｜`buff`｜cd12 mp12｜攻速+30% 持续6s｜义体超频。
- 4 震荡践踏｜`stun_wave`｜pw2.2 cd9 mp18｜半径120 眩晕0.6s 击退80｜震波衔接。
- 5 磁轨突袭｜`dash_strike`｜pw2.4 cd10 mp20｜distance200 半径85｜进阶突进。
- 6 超频风暴｜`melee_aoe`｜pw3.0 cd14 mp26｜半径140｜终极连拳。

### 黑客 [hacker] — 网络入侵

**流派 A：网络行者（病毒扩散）**
- 普攻：`beam` 脉冲射线，range 500 / width 14 / cd 0.60 / 魔法。
- 被动：无（连锁扩散）。
- 1 病毒入侵｜`chain`｜pw1.3 cd4 mp14｜半径220 目标3｜病毒扩散。
- 2 蠕虫病毒｜`chain`｜pw1.5 cd8 mp18｜半径240 目标4｜链路感染。
- 3 系统过载｜`buff`｜cd12 mp14｜攻击+12 持续6s｜算力超频。
- 4 病毒风暴｜`chain`｜pw1.8 cd10 mp22｜半径280 目标6｜大范围扩散。
- 5 全域感染｜`chain`｜pw2.2 cd13 mp26｜半径320 目标8｜全域连锁。
- 6 零日链｜`chain`｜pw3.0 cd18 mp34｜半径360 目标10｜终极感染。

**流派 B：幽灵（断电控场）**
- 普攻：`beam` 脉冲射线，range 460 / width 12 / cd 0.50 / 魔法。
- 被动：无（控场机动）。
- 1 EMP脉冲｜`stun_wave`｜pw1.4 cd7 mp18｜半径120 眩晕0.9s 击退40｜断电硬控。
- 2 幽灵步｜`blink_strike`｜pw1.2 cd6 mp14｜range160 半径55｜瞬移脱离。
- 3 信号干扰｜`buff`｜cd10 mp12｜闪避+30% 持续6s｜干扰锁定。
- 4 全域断电｜`stun_wave`｜pw1.9 cd12 mp22｜半径140 眩晕1.5s 击退30｜大范围瘫痪。
- 5 断链｜`stun_wave`｜pw2.0 cd11 mp22｜半径130 眩晕1.2s 击退60｜链式断电。
- 6 黑域｜`stun_wave`｜pw2.8 cd17 mp30｜半径170 眩晕2.0s 击退50｜终极断域。

**流派 C：网络幽灵（频法）**
- 普攻：`beam` 脉冲射线，range 460 / width 16 / cd 0.45 / 魔法。
- 被动：`shield_bonus` 护盾 +20%。
- 1 病毒入侵｜`chain`｜pw1.2 cd3.5 mp12｜半径220 目标3｜基础感染。
- 2 系统过载｜`buff`｜cd12 mp14｜攻速+30% 持续6s｜高频输出。
- 3 防火墙｜`shield`｜pw55 cd12 mp16｜持续7s｜防护自保。
- 4 超频协议｜`buff`｜cd16 mp22｜攻击+20 持续9s｜强力增益。
- 5 蠕虫病毒｜`chain`｜pw1.8 cd9 mp20｜半径260 目标5｜进阶扩散。
- 6 万物互联｜`buff`｜cd18 mp26｜攻速+50% 持续9s｜终极超频。

### 狙击手 [sniper] — 潜行狙击

**流派 A：狙击手（超远点杀）**
- 普攻：`beam` 狙击射线，range 700 / width 8 / cd 0.90。
- 被动：无（超远点杀）。
- 1 狙击｜`snipe`｜pw2.4 cd4 mp8｜range720 width10｜超远贯穿。
- 2 陷阱｜`deployable` mine｜pw1.5 cd8 mp12｜1枚 半径80 持续18s｜感应地雷。
- 3 精准｜`buff`｜cd12 mp8｜暴击+30% 持续5s｜凝神蓄势。
- 4 死神之眼｜`snipe`｜pw3.2 cd9 mp18｜range800 width14 吸血10%｜远距锁魂。
- 5 爆裂陷阱｜`deployable` mine｜pw2.2 cd12 mp18｜2枚 散布70 半径95 持续16s｜双雷封锁。
- 6 绝杀狙击｜`snipe`｜pw4.2 cd16 mp28｜range900 width18 吸血15%｜终极绝杀。

**流派 B：陷阱大师（雷区）**
- 普攻：`beam` 狙击射线，range 640 / width 10 / cd 0.80。
- 被动：无（布置控线）。
- 1 陷阱｜`deployable` mine｜pw1.5 cd7 mp14｜2枚 散布60 半径80 持续18s｜双雷布场。
- 2 感应雷区｜`deployable` mine｜pw1.3 cd9 mp16｜1枚 半径100 持续20s｜大范围感应。
- 3 隐匿｜`buff`｜cd10 mp10｜闪避+25% 持续6s｜规避近身。
- 4 爆裂陷阱｜`deployable` mine｜pw2.0 cd11 mp20｜3枚 散布100 半径95 持续18s｜三雷封锁。
- 5 雷场｜`deployable` mine｜pw2.2 cd14 mp26｜4枚 散布140 半径100 持续20s｜大片雷区。
- 6 死亡禁区｜`deployable` mine｜pw2.6 cd18 mp34｜6枚 散布180 半径110 持续24s｜终极雷场。

**流派 C：潜伏者（潜行暴击）**
- 普攻：`beam` 狙击射线，range 660 / width 9 / cd 0.85。
- 被动：无（暴击潜行）。
- 1 狙击｜`snipe`｜pw2.2 cd4.5 mp8｜range680 width9｜精准点杀。
- 2 精准｜`buff`｜cd12 mp8｜暴击+35% 持续5s｜潜行蓄势。
- 3 隐匿｜`buff`｜cd10 mp10｜闪避+30% 持续6s｜脱离视线。
- 4 死神之眼｜`snipe`｜pw3.0 cd9 mp18｜range760 width12｜进阶狙击。
- 5 屏息专注｜`buff`｜cd15 mp14｜暴击+45% 持续8s｜极致蓄势。
- 6 暗杀｜`snipe`｜pw4.0 cd15 mp26｜range820 width16｜终极暗杀。

---

## 八、四阶进阶总纲（1转 → 4转）

### 8.1 阶位定义与解锁

| 阶位 | 解锁条件 | 玩法变化 | 存档字段 |
| --- | --- | --- | --- |
| 1转 · 基础职业 | 角色创建 | 职业基础 6 技能 | `class_id` |
| 2转 · 流派 | Lv10，且点亮技能树前 3 个“初始”节点 | 3 选 1，整套替换普攻 + 6 技能 + 被动 | `style_id` |
| 3转 · 专精 | Lv25，且已 2转、点满所属流派 3 个“专精被动”节点 | 流派内 3 选 1，+1 主动（槽 7）+1 被动 | `spec_id` |
| 4转 · 终极形态 | Lv40，且已 3转、点亮技能树终极节点 | 唯一形态，+1 终极主动（槽 8）+1 被动 + 称号/外观 | `apex_id` |

- **3转可重置**：营地“洗点”消耗金币，可重选 A/B/C；已投入的技能树节点保留。
- **4转可随时重置**：消耗金币即可切换，称号与外观随之切换；重置冷却 10 分钟，避免战斗中途反复切换。
- 未达阶位时，槽 7 / 槽 8 在 HUD 上灰显并提示解锁条件。
- 三转、四转**不会**改变流派玩法轴，只在其上叠加一层“更专精的同一件事”。

### 8.2 技能槽与键位

| 槽位 | 键位 | 来源 | 出现时机 |
| --- | --- | --- | --- |
| 1 / 2 / 3 | `1` `2` `3` | 2转流派的 6 技能前 3 个 | 2转 |
| 4 / 5 / 6 | `R` `F` `G` | 2转流派的 6 技能后 3 个 | 技能树解锁对应分支 |
| 7 | `T` | 3转专精主动 | 3转 |
| 8 | `Y` | 4转终极主动 | 4转 |

- 被动不占槽，自动生效。
- HUD 技能栏从 6 格扩为 8 格，7/8 格在解锁后从灰显变为可用。
- `project.godot` 新增输入动作 `skill_7` / `skill_8`；`validate_project.py` 的输入动作清单同步扩充。

### 8.3 数值预算

| 层级 | 参照基准 | 威力 | 冷却 | 法力 |
| --- | --- | --- | --- | --- |
| 3转主动 | 本流派槽 6 技能 | ×1.10~1.35 | ×1.20~1.50 | ×1.10~1.40 |
| 4转终极主动 | 本流派槽 6 技能 | ×1.50~1.90 | ×1.60~2.20 | ×1.50~2.00 |
| 3转被动 | 流派被动 | 单项 +10%~+25% | — | — |
| 4转被动 | 3转被动 | 单项 +20%~+35% | — | — |

- 允许为手感突破 ±10%，由 `validate_project.py` 以“警告”而非“错误”报出。
- 同类加成加算后统一封顶：燃烧 +80%、吸血 +100%、护盾 +80%、闪避 +80%、攻速 +150%、减伤 +50%。
- 同一流派三条 3转 的 `power_score` 差值 ≤ 5%；4转 必须高于三条 3转，且不超过其 1.5 倍。

### 8.4 被动词表

现有 4 种沿用：`burn` / `lifesteal` / `heal_bonus` / `shield_bonus`。
新增 6 种（**需确认**）：

| 键 | 效果 |
| --- | --- |
| `execute` | 对处于定身 / 眩晕状态的敌人增伤 |
| `fortify` | 受到的所有伤害按百分比减免 |
| `haste` | 攻速与移速同时提升 |
| `resonance` | 连续命中同一目标时逐层叠伤，有层数上限 |
| `trap_bonus` | 部署物 / 陷阱的威力与持续时间提升 |
| `summon_bonus` | 召唤物数量或威力提升 |

### 8.5 数据结构与存档

```json
{
  "class_id": "mage",
  "style_id": "mage_fire",
  "spec_id": "mage_fire_spec_a",
  "apex_id": "mage_fire_apex"
}
```

- `STYLE_KITS[style_id]`：2转成果，含 `basic_attack` + `passive` + `skills[6]`。
- `STYLE_SPECS[style_id][a|b|c]`：3转成果，含 `active`（1 个技能）+ `passive`。
- `STYLE_APEX[style_id]`：4转成果，含 `title` + `active` + `passive` + `basic_attack_affix`。
- 派生读取：`get_skill(1..6)` → `STYLE_KITS`；`get_skill(7)` → `STYLE_SPECS[spec_id].active`；`get_skill(8)` → `STYLE_APEX[style_id].active`。
- 技能 id 规则：`{class}_{style}_t6` / `{class}_{style}_spec_a|b|c` / `{class}_{style}_apex`。

---

## 九、三转专精与四转终极（逐流派）

> 格式：`专精名`｜新增主动（类型 / 数值）｜新增被动。每条流派三个 3转 分支 + 一个 4转 终极。
> 数值均为草案，实现时以 `gen_class_content.py` 为准。

### 9.1 法术系（以太 · 蓄势爆发）

#### 法师 [mage]

**流派 A：炎术士**
- 专精一「大咒术师」｜【灰烬领域】`aoe_zone` pw3.9 cd26 mp46｜半径200 delay0.7｜被动 `burn` 燃烧 +25%
- 专精二「焰心行者」｜【烈焰突进】`dash_strike` pw3.5 cd15 mp30｜distance210 半径100｜被动 `fortify` 减伤 -15%
- 专精三「引燃者」｜【火种链】`chain` pw3.4 cd18 mp38｜半径300 目标6｜被动 `execute` 对燃烧目标 +25%
- 4转「焚天者」｜【天火焚城】`aoe_zone` pw5.2 cd32 mp54｜半径240 delay1.0 击退60｜被动 `burn` +40%｜普攻附带火痕

**流派 B：霜法师**
- 专精一「极寒主宰」｜【千里冰封】`root_zone` pw3.0 cd24 mp42｜半径190 定身4.0s｜被动 `shield_bonus` +25%
- 专精二「碎冰者」｜【冰爆术】`aoe_zone` pw3.7 cd20 mp38｜半径160 delay0.5｜被动 `execute` 对定身目标 +30%
- 专精三「霜甲师」｜【霜甲领域】`shield` pw150 cd26 mp36｜持续10s，受击者减速30%｜被动 `shield_bonus` +30%
- 4转「永冬女王」｜【永冬降临】`root_zone` pw4.4 cd30 mp52｜半径220 定身5.0s 附带 pw1.5 冰爆｜被动 `execute` +35%｜周围敌人持续减速

**流派 C：秘法学者**
- 专精一「大奥术师」｜【奥术洪峰】`snipe` pw3.4 cd16 mp30｜range460 width22｜被动 `haste` 攻速 +15%
- 专精二「时序术士」｜【时间停滞】`buff` cd28 mp36｜攻速+60% 持续6s｜被动 `resonance` 每层 +4%，最多 5 层
- 专精三「回响师」｜【奥术回响】`chain` pw3.2 cd14 mp26｜半径280 目标5｜被动 `resonance` 每层 +5%
- 4转「奥术主宰」｜【万法归一】`projectile` pw4.0 cd22 mp44｜九连发 spread0.18 speed600｜被动 `haste` +30%｜施法后 1.5s 内冷却缩减 20%

#### 咒铠师 [runeward]

**流派 A：符阵大师**
- 专精一「符阵宗师」｜【九宫符阵】`heal_zone` cd26 mp36｜半径170 每秒26 持续6s 同时获得 pw60 护盾｜被动 `shield_bonus` +30%
- 专精二「反击符文师」｜【符能反噬】`stun_wave` pw3.6 cd18 mp32｜半径150 眩晕1.0s 击退160｜被动 `fortify` -18%
- 专精三「铭文师」｜【铭文烙印】`mark` cd22 mp26｜半径360 易伤45% 持续10s｜被动 `fortify` -15%
- 4转「符阵圣者」｜【万符天罗】`buff` cd32 mp48｜防御+40 持续12s 反弹 25% 近战伤害｜被动 `shield_bonus` +35%

**流派 B：反噬者**
- 专精一「震符大师」｜【天雷震符】`stun_wave` pw4.2 cd20 mp34｜半径170 眩晕1.2s 击退200｜被动 `fortify` -15%
- 专精二「血符师」｜【血符爆发】`melee_aoe` pw4.0 cd14 mp26｜半径120 吸血30%｜被动 `lifesteal` +18%
- 专精三「荆棘符师」｜【荆棘符甲】`buff` cd28 mp32｜反弹 35% 近战伤害 持续10s｜被动 `shield_bonus` +30%
- 4转「万符之主」｜【万符归宗·极】`stun_wave` pw5.6 cd30 mp50｜半径210 眩晕1.5s 击退240｜被动 `fortify` -25%

**流派 C：守誓者**
- 专精一「圣誓骑士」｜【誓约之光】`heal_zone` cd24 mp40｜半径180 每秒34 持续8s｜被动 `heal_bonus` +30%
- 专精二「铁壁守誓」｜【不朽誓约】`shield` pw180 cd30 mp42｜持续12s｜被动 `shield_bonus` +40%
- 专精三「誓约斗士」｜【誓约反击】`melee_aoe` pw4.6 cd18 mp28｜半径150 吸血20%｜被动 `lifesteal` +18%
- 4转「誓约之神」｜【永恒圣所】`heal_zone` + `shield` cd36 mp56｜半径200 每秒45 持续10s，同时获得 pw150 护盾｜被动 `heal_bonus` +40%

#### 牧师 [priest]

**流派 A：神谕者**
- 专精一「大主教」｜【圣言·愈】`heal` pw130 cd18 mp40｜立即大量回复｜被动 `heal_bonus` +30%
- 专精二「光耀先知」｜【光耀审判】`snipe` pw3.4 cd20 mp36｜range420 width24 吸血20%｜被动 `execute` +25%
- 专精三「圣歌者」｜【圣歌领域】`buff` cd28 mp34｜治疗加成+40% 攻击+20 持续10s｜被动 `heal_bonus` +30%
- 4转「神谕使徒」｜【神谕·创世】`heal_zone` cd34 mp56｜半径200 每秒48 持续10s 并清除负面｜被动 `heal_bonus` +45%

**流派 B：圣殿骑士**
- 专精一「圣裁骑士」｜【圣裁之剑】`snipe` pw3.8 cd20 mp34｜range360 width26 吸血25%｜被动 `execute` +20%
- 专精二「圣盾守卫」｜【圣光壁垒】`shield` pw170 cd28 mp38｜持续10s｜被动 `fortify` -20%
- 专精三「布道者」｜【布道圣言】`heal_zone` cd24 mp38｜半径170 每秒32 持续8s｜被动 `fortify` -15%
- 4转「圣殿大团长」｜【神圣裁决·终】`snipe` pw5.4 cd30 mp52｜range460 width32 吸血30% 击退｜被动 `fortify` -25%

**流派 C：苦修者**
- 专精一「殉道者」｜【殉道圣痕】`heal` pw160 cd22 mp34｜立即大量回复｜被动 `lifesteal` +15%
- 专精二「鞭刑者」｜【赎罪鞭笞】`melee_aoe` pw3.8 cd12 mp24｜半径130 吸血25%｜被动 `lifesteal` +20%
- 专精三「戒律者」｜【戒律锁链】`root_zone` pw3.0 cd22 mp32｜半径160 定身2.5s｜被动 `execute` +25%
- 4转「苦修圣徒」｜【以血证道】`heal` pw220 cd32 mp50｜回复后 8s 内攻击+30｜被动 `lifesteal` +30%

#### 亡灵法师 [necromancer]

**流派 A：收割者**
- 专精一「大收割者」｜【灵魂收割】`snipe` pw4.0 cd22 mp38｜range480 width26 吸血85%｜被动 `lifesteal` +20%
- 专精二「噬魂领主」｜【噬魂领域】`heal_zone` cd24 mp40｜半径160 每秒22 持续8s｜被动 `lifesteal` +18%
- 专精三「亡魂猎手」｜【亡魂标记】`mark` cd22 mp26｜半径400 易伤50% 持续10s，自身吸血+20%｜被动 `lifesteal` +20%
- 4转「死神化身」｜【死亡宣告】`snipe` pw6.0 cd34 mp56｜range560 width32 吸血100%｜被动 `lifesteal` +35%

**流派 B：瘟疫术士**
- 专精一「大瘟疫师」｜【疫病燎原】`aoe_zone` pw3.8 cd24 mp42｜半径190 delay0.6｜被动 `burn` +30%
- 专精二「腐化先知」｜【腐化链】`chain` pw3.6 cd20 mp38｜半径320 目标8｜被动 `execute` +25%
- 专精三「腐骨师」｜【腐骨地刺】`root_zone` pw3.2 cd22 mp34｜半径170 定身2.5s｜被动 `burn` +30%
- 4转「瘟疫之王」｜【末世大疫】`aoe_zone` pw5.2 cd32 mp54｜半径230 delay0.8｜被动 `burn` +45%

**流派 C：尸傀师**
- 专精一「亡灵领主」｜【亡灵领主】`summon` pw3.4 cd26 mp46｜3只 持续18s 速度150 间隔0.8｜被动 `summon_bonus` +25%
- 专精二「尸爆师」｜【尸爆】`aoe_zone` pw4.0 cd20 mp38｜半径170 delay0.4｜被动 `summon_bonus` +20%
- 专精三「魂契师」｜【魂契护盾】`shield` pw140 cd24 mp34｜持续10s，同时强化全部召唤物｜被动 `summon_bonus` +25%
- 4转「亡灵天灾」｜【天灾降临】`summon` pw4.6 cd34 mp58｜6只 持续20s 速度160 间隔0.7｜被动 `summon_bonus` +40%

### 9.2 机械系（蒸汽 · 布置引爆）

#### 炸弹专家 [bomber]

**流派 A：爆破专家**
- 专精一「大爆破师」｜【聚能核爆】`deployable` bomb pw4.2 cd22 mp38｜2枚 半径150 fuse0.8｜被动 `trap_bonus` +25%
- 专精二「要塞爆破」｜【定向爆破】`aoe_zone` pw4.4 cd20 mp36｜半径180 delay0.6 击退120｜被动 `fortify` -15%
- 专精三「连锁师」｜【连锁引爆】`chain` pw4.0 cd20 mp34｜半径280 目标6｜被动 `trap_bonus` +25%
- 4转「爆破之王」｜【终极审判】`deployable` bomb pw6.0 cd34 mp56｜4枚 散布120 半径170 fuse0.6｜被动 `trap_bonus` +40%

**流派 B：纵火者**
- 专精一「大纵火师」｜【火海燎原】`aoe_zone` pw3.8 cd24 mp40｜半径190 delay0.5｜被动 `burn` +30%
- 专精二「燃烬行者」｜【燃烧冲刺】`dash_strike` pw3.6 cd18 mp32｜distance220 半径110｜被动 `burn` +25%
- 专精三「烟幕师」｜【烟幕弹】`root_zone` pw2.6 cd20 mp28｜半径170 定身2.0s｜被动 `fortify` -15%
- 4转「炎狱之主」｜【炎狱焚世】`root_zone` pw5.2 cd32 mp54｜半径220 定身3.5s｜被动 `burn` +45%

**流派 C：铝热师**
- 专精一「雷区大匠」｜【雷区矩阵】`deployable` mine pw3.6 cd26 mp44｜6枚 散布180 半径110 持续22s｜被动 `trap_bonus` +30%
- 专精二「铝热专家」｜【铝热风暴】`aoe_zone` pw4.2 cd22 mp38｜半径170 delay0.5｜被动 `trap_bonus` +25%
- 专精三「工兵」｜【工事炮台】`deployable` turret pw3.6 cd24 mp38｜持续18s 间隔0.6｜被动 `trap_bonus` +30%
- 4转「焦土元帅」｜【焦土禁区】`deployable` mine pw4.8 cd34 mp58｜8枚 散布220 半径120 持续26s｜被动 `trap_bonus` +45%

#### 机甲师 [mech_pilot]

**流派 A：重装机兵**
- 专精一「攻城机兵」｜【攻城炮】`snipe` pw4.4 cd22 mp34｜range760 width24｜被动 `fortify` -18%
- 专精二「重装指挥官」｜【重装阵线】`buff` cd30 mp36｜防御+36 持续12s｜被动 `shield_bonus` +30%
- 专精三「火箭手」｜【火箭齐射】`projectile` pw4.2 cd22 mp34｜六连发 spread0.18｜被动 `haste` +15%
- 4转「战争机器」｜【轨道轰炸】`snipe` pw6.2 cd34 mp52｜range900 width30 击退｜被动 `fortify` -28%

**流派 B：速射炮手**
- 专精一「弹幕大师」｜【弹幕风暴】`projectile` pw3.4 cd18 mp30｜十连发 spread0.20｜被动 `haste` +20%
- 专精二「火力管制官」｜【火力覆盖】`aoe_zone` pw3.8 cd22 mp36｜半径180 delay0.4｜被动 `haste` +15%
- 专精三「穿甲射手」｜【穿甲弹幕】`snipe` pw4.4 cd20 mp32｜range620 width20｜被动 `execute` +25%
- 4转「弹幕之王」｜【全弹幕发射】`projectile` pw4.8 cd30 mp50｜十四连发 spread0.24｜被动 `haste` +35%

**流派 C：要塞驾驶员**
- 专精一「要塞统领」｜【要塞壁垒】`shield` pw200 cd30 mp40｜持续14s｜被动 `shield_bonus` +35%
- 专精二「炮台指挥官」｜【齐射协议】`aoe_zone` pw4.0 cd24 mp38｜半径190 delay0.5｜被动 `fortify` -18%
- 专精三「维修官」｜【维修无人机】`heal_zone` cd24 mp38｜半径170 每秒30 持续8s｜被动 `heal_bonus` +30%
- 4转「移动要塞」｜【要塞形态】`buff` cd36 mp54｜防御+48 持续14s，普攻溅射翻倍｜被动 `shield_bonus` +45%

#### 工程师 [engineer]

**流派 A：炮塔专家**
- 专精一「炮塔大师」｜【重型要塞炮台】`deployable` turret pw3.8 cd24 mp42｜持续26s 间隔0.4｜被动 `trap_bonus` +30%
- 专精二「无人机工程师」｜【无人机编队】`summon` pw3.4 cd22 mp38｜3只 持续16s 速度190 间隔0.9｜被动 `summon_bonus` +25%
- 专精三「地雷工程师」｜【地雷阵】`deployable` mine pw3.6 cd22 mp36｜4枚 散布140 半径100 持续20s｜被动 `trap_bonus` +30%
- 4转「机械领主」｜【炮塔矩阵】`deployable` turret pw4.6 cd32 mp56｜3座 散布90 持续28s 间隔0.35｜被动 `trap_bonus` +45%

**流派 B：后勤官**
- 专精一「战地医官」｜【战地医院·极】`heal_zone` cd26 mp44｜半径190 每秒40 持续10s｜被动 `heal_bonus` +35%
- 专精二「战术指挥官」｜【全军突击】`buff` cd30 mp40｜攻击+34 攻速+15% 持续12s｜被动 `heal_bonus` +30%
- 专精三「护盾工程师」｜【护盾矩阵】`shield` pw160 cd26 mp34｜持续10s｜被动 `shield_bonus` +35%
- 4转「后勤元帅」｜【战争后勤】`heal_zone` cd34 mp58｜半径220 每秒50 持续12s，全队攻击+25｜被动 `heal_bonus` +45%

**流派 C：过载技师**
- 专精一「超频大师」｜【极限超频】`buff` cd26 mp38｜攻速+80% 持续8s｜被动 `haste` +25%
- 专精二「炮台超频者」｜【过载炮塔】`deployable` turret pw4.0 cd22 mp36｜2座 持续18s 间隔0.3｜被动 `trap_bonus` +30%
- 专精三「蒸汽炮手」｜【蒸汽炮击】`projectile` pw3.8 cd16 mp28｜五连发 spread0.14｜被动 `haste` +25%
- 4转「蒸汽狂人」｜【蒸汽永动】`buff` cd34 mp54｜攻速+110% 持续10s 并召唤 1 座速射炮塔｜被动 `haste` +40%

#### 赏金猎人 [bounty_hunter]

**流派 A：赏金猎人**
- 专精一「猎杀者」｜【猎杀清单】`mark` cd28 mp34｜半径520 易伤75% 持续14s｜被动 `execute` +30%
- 专精二「双枪大师」｜【双枪连舞】`projectile` pw3.4 cd18 mp30｜八连发 spread0.14｜被动 `haste` +20%
- 专精三「通缉专家」｜【悬赏通缉】`chain` pw3.6 cd18 mp32｜半径320 目标6｜被动 `execute` +25%
- 4转「赏金之王」｜【悬赏处决】`snipe` pw6.0 cd32 mp52｜range520 width26，对标记目标必暴｜被动 `execute` +40%

**流派 B：追迹者**
- 专精一「弹幕追迹者」｜【追猎弹幕】`chain` pw3.6 cd20 mp34｜半径340 目标8｜被动 `haste` +25%
- 专精二「疾风猎人」｜【疾风突袭】`dash_strike` pw3.4 cd18 mp30｜distance240 半径90｜被动 `haste` +20%
- 专精三「捕猎者」｜【捕兽夹】`root_zone` pw3.0 cd20 mp30｜半径150 定身2.5s｜被动 `trap_bonus` +25%
- 4转「风暴猎人」｜【弹幕风暴·终】`projectile` pw4.6 cd30 mp50｜十二连发 spread0.22｜被动 `haste` +40%

**流派 C：赏金之王**
- 专精一「点杀专家」｜【要害锁定】`buff` cd26 mp32｜暴击+55% 暴伤+50% 持续8s｜被动 `execute` +25%
- 专精二「处刑人」｜【处刑射击】`snipe` pw4.6 cd22 mp36｜range460 width20 吸血20%｜被动 `execute` +30%
- 专精三「连击之王」｜【双枪风暴】`projectile` pw3.8 cd16 mp28｜十连发 spread0.16｜被动 `haste` +25%
- 4转「枪神」｜【一枪定生死】`snipe` pw6.6 cd34 mp54｜range560 width26 吸血25%｜被动 `execute` +45%

### 9.3 传武系（气血 · 贴身缠斗）

#### 死亡骑士 [death_knight]

**流派 A：血骑**
- 专精一「血骑统领」｜【血河冲锋】`dash_strike` pw3.8 cd20 mp32｜distance240 半径95 吸血40%｜被动 `lifesteal` +20%
- 专精二「死亡先锋」｜【死亡践踏】`stun_wave` pw3.8 cd18 mp30｜半径150 眩晕0.9s 击退120｜被动 `fortify` -15%
- 专精三「血魄骑士」｜【血魄护盾】`shield` pw150 cd24 mp30｜持续10s，护盾期间吸血+15%｜被动 `lifesteal` +20%
- 4转「血河之主」｜【血海无涯】`snipe` pw5.6 cd32 mp52｜range420 width34 吸血80%｜被动 `lifesteal` +35%

**流派 B：墓卫**
- 专精一「墓土骑士」｜【墓土壁垒】`shield` pw190 cd28 mp38｜持续12s｜被动 `shield_bonus` +35%
- 专精二「亡者督军」｜【亡者军势】`summon` pw3.6 cd24 mp40｜3只 持续16s 速度140 间隔1.0｜被动 `summon_bonus` +25%
- 专精三「墓火骑士」｜【墓火燎原】`aoe_zone` pw4.2 cd20 mp34｜半径170 delay0.5｜被动 `burn` +30%
- 4转「不朽墓卫」｜【不朽墓域】`buff` cd34 mp52｜防御+46 持续14s 反弹 20% 伤害｜被动 `fortify` -30%

**流派 C：血誓者**
- 专精一「血誓骑士」｜【血誓契约】`buff` cd26 mp34｜攻击+30 吸血+20% 持续10s｜被动 `lifesteal` +20%
- 专精二「血刃大师」｜【血刃风暴】`snipe` pw4.2 cd20 mp34｜range360 width28 吸血60%｜被动 `lifesteal` +25%
- 专精三「献祭者」｜【生命献祭】`melee_aoe` pw4.4 cd16 mp24｜半径130 吸血30%｜被动 `fortify` -15%
- 4转「血誓君王」｜【血海誓约】`snipe` pw6.0 cd32 mp52｜range440 width36 吸血85%｜被动 `lifesteal` +40%

#### 战士 [warrior]

**流派 A：狂战士**
- 专精一「大狂战」｜【狂战风暴】`melee_aoe` pw4.2 cd18 mp30｜半径170｜被动 `lifesteal` +18%
- 专精二「不屈斗士」｜【不屈战吼】`buff` cd26 mp30｜攻击+38 防御+16 持续10s｜被动 `fortify` -15%
- 专精三「嗜血者」｜【嗜血旋风】`melee_aoe` pw4.0 cd14 mp22｜半径150 吸血25%｜被动 `lifesteal` +20%
- 4转「战神」｜【战神降临】`melee_aoe` pw6.2 cd30 mp50｜半径210 眩晕0.8s 击退120｜被动 `lifesteal` +30%

**流派 B：剑圣**
- 专精一「剑豪」｜【万剑归宗·极】`snipe` pw4.6 cd20 mp32｜range460 width30｜被动 `haste` +18%
- 专精二「剑心通明」｜【剑心领域】`buff` cd26 mp34｜攻速+45% 暴击+25% 持续10s｜被动 `resonance` 每层 +5%，最多 5 层
- 专精三「御剑者」｜【御剑术】`projectile` pw3.8 cd16 mp26｜五连发 spread0.12｜被动 `resonance` 每层 +5%
- 4转「剑神」｜【一剑开天】`snipe` pw6.4 cd32 mp50｜range520 width36｜被动 `execute` +35%

**流派 C：破阵者**
- 专精一「破阵先锋」｜【破阵冲锋】`dash_strike` pw4.0 cd18 mp30｜distance280 半径100｜被动 `fortify` -15%
- 专精二「震岳武者」｜【震岳山河】`stun_wave` pw4.4 cd20 mp34｜半径180 眩晕1.0s 击退160｜被动 `fortify` -18%
- 专精三「盾阵者」｜【盾阵壁垒】`shield` pw150 cd24 mp30｜持续10s｜被动 `fortify` -18%
- 4转「山崩地裂」｜【山崩地裂】`dash_strike` pw5.8 cd30 mp50｜distance340 半径140 眩晕0.8s｜被动 `fortify` -25%

#### 气宗 [qi_adept]

**流派 A：医武**
- 专精一「医仙」｜【生生不息·极】`heal_zone` cd24 mp42｜半径190 每秒40 持续8s｜被动 `heal_bonus` +35%
- 专精二「气劲宗师」｜【气劲崩拳】`melee_aoe` pw3.8 cd16 mp26｜半径120｜被动 `resonance` 每层 +4%
- 专精三「点穴师」｜【点穴】`stun_wave` pw3.4 cd18 mp28｜半径140 眩晕1.2s｜被动 `execute` +25%
- 4转「医武圣手」｜【回春圣境】`heal_zone` cd32 mp56｜半径220 每秒52 持续10s 并清除负面｜被动 `heal_bonus` +45%

**流派 B：罡气宗师**
- 专精一「罡气大师」｜【罡气天罡·极】`stun_wave` pw4.5 cd18 mp32｜半径170 眩晕1.2s 击退180｜被动 `fortify` -15%
- 专精二「气墙守御」｜【罡气结界】`shield` pw160 cd26 mp34｜持续10s｜被动 `shield_bonus` +35%
- 专精三「气劲射手」｜【罡气弹】`projectile` pw3.6 cd14 mp24｜五连发 spread0.12｜被动 `haste` +20%
- 4转「天罡武神」｜【天罡破军】`stun_wave` pw5.8 cd30 mp50｜半径210 眩晕1.5s 击退220｜被动 `fortify` -25%

**流派 C：疾风武者**
- 专精一「疾风宗师」｜【无影疾风·极】`melee_aoe` pw3.6 cd10 mp20｜半径140｜被动 `haste` +25%
- 专精二「流云行者」｜【流云幻步】`buff` cd22 mp28｜移速+55% 闪避+35% 持续8s｜被动 `haste` +20%
- 专精三「风刃师」｜【风刃连斩】`snipe` pw3.8 cd16 mp26｜range360 width18｜被动 `resonance` 每层 +5%
- 4转「疾风武神」｜【无影无形】`melee_aoe` pw4.6 cd20 mp36｜半径170 六连击｜被动 `haste` +40%

#### 小偷 [thief]

**流派 A：刺客**
- 专精一「大刺客」｜【瞬杀·极】`blink_strike` pw4.6 cd14 mp24｜range320 半径110｜被动 `execute` +30%
- 专精二「暗影行者」｜【暗影脱离】`blink_strike` pw3.2 cd12 mp20｜range280 半径80，落地闪避+40% 持续3s｜被动 `fortify` -12%
- 专精三「投毒师」｜【淬毒飞刃】`projectile` pw3.6 cd14 mp22｜七连发 spread0.14｜被动 `burn` +30%
- 4转「影王」｜【影杀·终结】`blink_strike` pw6.2 cd26 mp46｜range380 半径140 必暴｜被动 `execute` +45%

**流派 B：影行者**
- 专精一「幻影大师」｜【幻影分身】`summon` pw3.0 cd24 mp34｜2只 持续12s 速度220 间隔0.9｜被动 `haste` +20%
- 专精二「烟幕专家」｜【烟幕领域】`buff` cd24 mp30｜闪避+70% 移速+30% 持续10s｜被动 `fortify` -18%
- 专精三「暗影刺客」｜【暗影突袭】`blink_strike` pw4.4 cd16 mp26｜range300 半径100｜被动 `execute` +30%
- 4转「无影之刃」｜【无影遁】`blink_strike` pw4.4 cd22 mp38｜range300 半径100，之后 5s 暴击+40%｜被动 `fortify` -25%

**流派 C：影舞者**
- 专精一「毒王」｜【万毒噬心·极】`root_zone` pw4.0 cd22 mp34｜半径180 定身3.0s｜被动 `burn` +30%
- 专精二「刃舞者」｜【毒刃风暴】`projectile` pw3.6 cd16 mp28｜九连发 spread0.18｜被动 `haste` +20%
- 专精三「毒雾师」｜【毒雾领域】`aoe_zone` pw3.8 cd18 mp30｜半径170 delay0.4｜被动 `burn` +30%
- 4转「毒影之王」｜【万毒天罗】`root_zone` pw5.4 cd30 mp50｜半径210 定身3.5s 并附带毒爆伤害｜被动 `burn` +45%

### 9.4 科技系（算力 · 预判压制）

#### 弓箭手 [archer]

**流派 A：神射手**
- 专精一「神射宗师」｜【一箭穿心·极】`snipe` pw5.0 cd22 mp34｜range620 width20｜被动 `execute` +30%
- 专精二「鹰眼游侠」｜【鹰眼领域】`buff` cd26 mp30｜暴击+45% 暴伤+60% 持续10s｜被动 `haste` +20%
- 专精三「贯射者」｜【贯穿箭雨】`snipe` pw4.4 cd18 mp28｜range560 width18｜被动 `execute` +25%
- 4转「箭神」｜【射日】`snipe` pw6.8 cd32 mp52｜range720 width26 必暴｜被动 `execute` +45%

**流派 B：游侠**
- 专精一「大游侠」｜【箭雨风暴·极】`aoe_zone` pw4.2 cd22 mp34｜半径190 delay0.5｜被动 `haste` +20%
- 专精二「风行猎手」｜【风行突袭】`dash_strike` pw3.4 cd16 mp28｜distance220 半径90｜被动 `haste` +25%
- 专精三「陷阱游侠」｜【束缚陷阱】`root_zone` pw3.2 cd20 mp28｜半径160 定身2.5s｜被动 `trap_bonus` +25%
- 4转「风之猎手」｜【风暴箭雨】`aoe_zone` pw5.4 cd30 mp50｜半径230 delay0.6｜被动 `haste` +40%

**流派 C：疾风猎手**
- 专精一「速射大师」｜【箭幕·极】`projectile` pw3.6 cd16 mp28｜十连发 spread0.16｜被动 `haste` +30%
- 专精二「风行者」｜【疾风连射】`buff` cd24 mp30｜攻速+60% 移速+20% 持续8s｜被动 `resonance` 每层 +4%
- 专精三「鹰眼射手」｜【鹰眼点射】`snipe` pw4.0 cd16 mp26｜range600 width16 暴击+20%｜被动 `execute` +25%
- 4转「千箭之王」｜【千箭齐发】`projectile` pw4.8 cd26 mp46｜十六连发 spread0.20｜被动 `haste` +45%

#### 义体卫士 [cyborg]

**流派 A：磁轨先锋**
- 专精一「磁轨战士」｜【磁轨风暴·极】`dash_strike` pw4.8 cd20 mp32｜distance360 半径130｜被动 `fortify` -15%
- 专精二「震荡先锋」｜【震荡领域】`stun_wave` pw4.2 cd18 mp30｜半径170 眩晕1.0s 击退120｜被动 `fortify` -18%
- 专精三「义体枪手」｜【义体机枪】`projectile` pw3.8 cd16 mp28｜六连发 spread0.14｜被动 `haste` +20%
- 4转「磁轨天神」｜【磁轨天罚】`dash_strike` pw6.2 cd30 mp50｜distance420 半径160 眩晕1.2s｜被动 `fortify` -25%

**流派 B：不动堡垒**
- 专精一「铁壁统领」｜【神盾协议·极】`shield` pw220 cd28 mp40｜持续12s｜被动 `shield_bonus` +40%
- 专精二「堡垒指挥官」｜【堡垒火力】`aoe_zone` pw4.0 cd22 mp34｜半径180 delay0.5｜被动 `fortify` -20%
- 专精三「堡垒医官」｜【维修立场】`heal_zone` cd24 mp36｜半径170 每秒30 持续8s｜被动 `heal_bonus` +30%
- 4转「不动要塞」｜【绝对壁垒】`buff` cd34 mp52｜防御+50 持续14s 反弹 25% 伤害｜被动 `shield_bonus` +50%

**流派 C：超频武人**
- 专精一「超频拳王」｜【超频风暴·极】`melee_aoe` pw4.4 cd12 mp24｜半径170｜被动 `haste` +30%
- 专精二「伺服武者」｜【伺服连打】`melee_aoe` pw3.8 cd8 mp18｜半径110 三段｜被动 `haste` +25%
- 专精三「电磁拳手」｜【电磁震拳】`stun_wave` pw4.2 cd16 mp26｜半径150 眩晕0.8s 击退140｜被动 `haste` +25%
- 4转「超频武神」｜【超频·无限】`melee_aoe` pw5.8 cd22 mp40｜半径200 眩晕0.6s｜被动 `haste` +50%

#### 黑客 [hacker]

**流派 A：网络行者**
- 专精一「大黑客」｜【零日链·极】`chain` pw4.6 cd22 mp40｜半径420 目标12｜被动 `resonance` 每层 +6%
- 专精二「病毒之王」｜【病毒王冠】`chain` pw4.2 cd20 mp36｜半径380 目标10｜被动 `execute` +25%
- 专精三「防火墙黑客」｜【数据护盾】`shield` pw150 cd24 mp32｜持续10s｜被动 `shield_bonus` +30%
- 4转「零日之主」｜【零日审判】`chain` pw6.0 cd30 mp54｜半径500 目标14｜被动 `resonance` 每层 +8%

**流派 B：幽灵**
- 专精一「断电大师」｜【黑域·极】`stun_wave` pw4.6 cd22 mp38｜半径200 眩晕2.2s 击退40｜被动 `fortify` -15%
- 专精二「幽灵行者」｜【幽灵穿梭】`blink_strike` pw3.4 cd14 mp24｜range280 半径90｜被动 `fortify` -18%
- 专精三「病毒幽灵」｜【病毒爆发】`aoe_zone` pw4.2 cd22 mp34｜半径180 delay0.4｜被动 `execute` +25%
- 4转「黑域幽灵」｜【绝对断域】`stun_wave` pw6.0 cd30 mp52｜半径240 眩晕2.8s 击退30｜被动 `fortify` -25%

**流派 C：网络幽灵**
- 专精一「超频黑客」｜【万物互联·极】`buff` cd26 mp36｜攻速+70% 攻击+28 持续10s｜被动 `haste` +30%
- 专精二「防火墙大师」｜【绝对防火墙】`shield` pw170 cd24 mp32｜持续10s｜被动 `shield_bonus` +30%
- 专精三「链式黑客」｜【链式入侵】`chain` pw3.8 cd18 mp30｜半径340 目标8｜被动 `resonance` 每层 +6%
- 4转「网络之神」｜【全网超频】`buff` cd34 mp52｜攻速+100% 攻击+40 持续12s｜被动 `haste` +45%

#### 狙击手 [sniper]

**流派 A：狙击手**
- 专精一「大狙击手」｜【绝杀狙击·极】`snipe` pw5.4 cd22 mp32｜range980 width22｜被动 `execute` +30%
- 专精二「幽灵射手」｜【潜行狙击】`buff` cd24 mp28｜暴击+50% 闪避+30% 持续8s｜被动 `haste` +15%
- 专精三「爆破狙击」｜【爆裂弹】`aoe_zone` pw4.4 cd20 mp32｜半径170 delay0.4｜被动 `execute` +25%
- 4转「神枪手」｜【天眼绝杀】`snipe` pw7.2 cd34 mp54｜range1100 width26 必暴｜被动 `execute` +50%

**流派 B：陷阱大师**
- 专精一「大陷阱师」｜【死亡禁区·极】`deployable` mine pw4.4 cd26 mp44｜8枚 散布220 半径120 持续26s｜被动 `trap_bonus` +35%
- 专精二「雷场指挥官」｜【雷场矩阵】`deployable` mine pw4.0 cd22 mp38｜6枚 散布180 半径110 持续22s｜被动 `trap_bonus` +30%
- 专精三「诱杀者」｜【诱杀狙击】`snipe` pw4.8 cd20 mp30｜range860 width20｜被动 `trap_bonus` +30%
- 4转「禁区之主」｜【死亡地平线】`deployable` mine pw5.4 cd34 mp56｜10枚 散布260 半径130 持续30s｜被动 `trap_bonus` +50%

**流派 C：潜伏者**
- 专精一「暗杀大师」｜【暗杀·极】`snipe` pw5.0 cd20 mp30｜range900 width20｜被动 `execute` +30%
- 专精二「潜行专家」｜【隐匿领域】`buff` cd24 mp28｜闪避+60% 暴击+35% 持续10s｜被动 `fortify` -15%
- 专精三「毒狙」｜【毒弹狙击】`snipe` pw4.4 cd18 mp28｜range880 width18 附带持续毒伤｜被动 `burn` +30%
- 4转「暗影死神」｜【死神之息】`snipe` pw6.8 cd32 mp50｜range1000 width24 吸血25%｜被动 `execute` +50%

### 9.5 章节统计

| 项目 | 数量 |
| --- | --- |
| 流派 | 48 |
| 3转专精（每流派 3 条） | 144 |
| 4转终极形态（每流派 1 个） | 48 |
| 3转转职新增主动技能 | 144 |
| 4转新增终极主动技能 | 48 |
| 3转被动 | 144 |
| 4转被动 | 48 |
| 本轮新增技能总数 | 192 |
| 新增技能图标（复用为主，招牌各 1） | ≤ 48 |

---

## 十、实现落点（确认后执行）

1. `tools/gen_class_content.py` 新增 `STYLE_KITS[class][style] = {basic_attack, passive, skills[6]}`，生成到 `data/specializations.json`。
2. `CharacterData` 增加 `apply_style(style_id)`：合并 `basic_attack` 与 6 技能，供 `get_basic_attack()` / `get_skill(slot)` 读取。
3. `PlayerController.try_skill` 改读 `character_data.get_skill(slot)`；`try_attack` 已读 `get_basic_attack()`。
4. 技能树解锁逻辑改为按槽位（R/F/G）判定，UI 显示当前流派技能名。
5. HUD 六格技能栏刷新时机增加“切换流派”事件。
6. 存档只存 `style_id` / `spec_id` / `apex_id`，加载后重建有效技能。
7. 图标按“元素 × 形态”复用；每条流派招牌技能新增 1 张，控制在 48 张内。
8. 验收：`validate_project.py` 增加“每职业 3 套完整 6 技能、类型合法、进阶预算达标”校验；无头冒烟增加 3 流派切换后技能可施放断言。

### 10.1 三转 / 四转新增落点

9. `tools/gen_class_content.py` 新增两组契约：
   - `STYLE_SPECS[style_id][a|b|c] = {name, active, passive}`；
   - `STYLE_APEX[style_id] = {title, active, passive, basic_attack_affix}`。
10. `CharacterData` 增加 `apply_spec(spec_id)` 与 `apply_apex(apex_id)`，`get_skill(7/8)` 分别读取二者。
11. `PlayerController` 新增 `try_skill(7/8)` 分支；`project.godot` 增加 `skill_7`（`T`）/ `skill_8`（`Y`）输入动作。
12. HUD 技能栏由 6 格扩为 8 格，7/8 格按解锁状态灰显；技能树 UI 增加“3转专精 / 4转终极”两个展示位。
13. 被动系统新增 6 个键（`execute / fortify / haste / resonance / trap_bonus / summon_bonus`），在 `SkillExecutor` 与伤害管线统一结算，并做加算封顶。
14. 存档迁移：旧存档缺失新字段时按 `spec_id = ""`、`apex_id = ""` 处理，不报错。
15. 验收补充：`validate_project.py` 校验“48 流派 × 3 专精 + 48 终极”完整性、槽 7/8 类型合法、3转/4转预算区间；冒烟脚本覆盖 3转 A/B/C 与 4转技能各施放一次。

## 十一、需要确认的问题

1. 上述 48 条流派命名是否沿用现有专职名？如需改名，请给出新名单。
2. 144 条三转专精与本轮新增的 48 个四转称号是否沿用？如需改名，请指出具体条目。
3. 新增 6 种被动（`execute / fortify / haste / resonance / trap_bonus / summon_bonus`）已确认接受，是否还允许后续再扩充？
4. 技能树 R/F/G 解锁改为“按槽位”是否接受？这会改变现有按技能 id 解锁的实现。
5. 每条流派是否保留“招牌图标”新增，还是全部复用现有图标以压缩素材量？

