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

1. **8 个技能全部由流派数据决定**：1转选定流派后一次解锁 6 技能 + 3 专精 + 1 极致，不再逐级点技能。
2. **技能树改为融合/成长树**：16 节点不再门控技能；每层 +1 操作栏格，并提供融合槽与属性被动，技能可两两融合。
3. **流派即专职载体**：1转写 `style_id`；2转后本职业三条流派常驻，另存 `loadout` 与 `fusion_id`。
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

## 八、四阶进阶总纲（流派全精通 → 万流归宗 → 生命跃迁 → 超脱）

### 8.1 阶位定义与解锁

| 阶位 | 等级 | 名称 | 解锁条件 | 内容 |
| --- | --- | --- | --- | --- |
| 1转 | Lv10 | 流派全精通 | 完成职业试炼 | 选定 1 条流派并**全精通**：6 技能 + 专属普攻 + 流派被动 + 3 条专精 + 1 个流派极致 |
| 2转 | Lv30 | 万流归宗 | 已 1转，且本职业 3 条流派的「流派极致」全部解锁 | **所有流派精通**：跨流派自由配招（18 选 6）+ 职业融合技 |
| 3转 | Lv50 | 生命跃迁 | 已 2转，完成「生命试炼」 | **生命层次提升**：生命/法力上限突破，获得变身主动 + 跃迁被动 |
| 4转 | Lv70 | 超脱 | 已 3转，击败「镜像·超脱」 | **脱离职业框架**：跨源流借技 1 个 + 超脱终极 + 超脱被动 + 称号/外观 |

- 1转的“全精通”指**一次到位**：选定流派后直接获得该流派全部 6 技能、3 条专精、1 个流派极致，不再逐级点技能。
- 2转的硬性门槛是“所有流派精通”：必须先把本职业 3 条流派的极致全部拿到，才允许跨流派配招与融合。
- 3转不再属于任何流派，是**生命层次**（体质、灵魂、机体）的跃迁，本职业所有流派共享。
- 4转**脱离职业框架**：可借用其他源流 1 个招牌技能，并解锁本职业超脱形态。

- 1转后可在营地逐条修习本职业其余流派（金币/材料）；三条流派的「流派极致」全部获得，才满足 2转 条件。2转后三条流派常驻，无需重选。
- 3转生命形态可重置（稀有道具）；4转超脱可随时重置（金币，冷却 10 分钟）。

### 8.2 操作栏与配招

- 操作栏**基础 6 格**，键位 `1/2/3/R/F/G`。
- 技能树每完成 1 层（4 节点），操作栏 **+1 格**，依次为 `T` / `Y` / `V` / `B`，最多 **10 格**。
- **格位不绑定具体技能**：玩家从已解锁能力池中自行拖入——1转流派 6 技能、3 条专精、1 个极致、2转融合技、3转变身、4转终极与借技、以及融合技能。
- **流派技能最多占 6 格**：1转时为选定流派的 6 个技能；2转后从本职业 18 个技能中任选 6 个。其余格位放专精 / 极致 / 融合 / 变身 / 超脱 / 借技 / 融合技能。
- 同一能力不可重复放入多个格位；未解锁能力在面板中灰显。
- 配招方案存入 `loadout`，营地内可随时调整；战斗中不可改。
- 被动不占格，自动生效。

### 8.3 数值预算

| 层级 | 参照基准 | 威力 | 冷却 | 法力 |
| --- | --- | --- | --- | --- |
| 1转 专精主动 | 本流派槽 6 技能 | ×1.10~1.35 | ×1.20~1.50 | ×1.10~1.40 |
| 1转 流派极致 | 本流派槽 6 技能 | ×1.50~1.90 | ×1.60~2.20 | ×1.50~2.00 |
| 2转 融合技 | 本职业最强槽 6 技能 | ×1.60~2.00 | ×1.80~2.40 | ×1.60~2.00 |
| 3转 跃迁变身 | 强度≈槽 6 ×1.3 | 持续 12~18s | 冷却 70~90s | ×1.8~2.2 |
| 4转 超脱终极 | 本职业融合技 ×1.25 | ×1.25~1.40 | 冷却 60~90s | ×2.0~2.5 |

- 允许为手感突破 ±10%，由 `validate_project.py` 以“警告”而非“错误”报出。
- 同类加成加算后统一封顶：燃烧 +80%、吸血 +100%、护盾 +80%、闪避 +80%、攻速 +150%、减伤 +50%。
- 同一流派三条专精的 `power_score` 差值 ≤ 5%；流派极致必须高于三条专精，且不超过其 1.5 倍。
- 3转 生命层次提升：生命上限 +20%~+50%、法力上限 +10%~+40%（按职业定位分配）。

### 8.4 被动词表

现有 4 种沿用：`burn` / `lifesteal` / `heal_bonus` / `shield_bonus`。
新增 6 种（已确认）：

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
  "spec_id": "mage_fire_spec_b",
  "apex_id": "mage_fire_apex",
  "loadout": ["mage_fire_1", "mage_frost_2", "mage_arcane_5", "mage_fire_spec_b", "mage_fire_apex"],
  "fusions": ["mage_fire_1__mage_frost_1"],
  "fusion_id": "mage_fusion",
  "ascension_id": "mage_ascension",
  "transcend_id": "mage_transcend",
  "borrowed_skill": "tech_chain_borrow"
}
```

- `STYLE_KITS[style_id]`：1转流派，含 `basic_attack` + `passive` + `skills[6]`。
- `STYLE_SPECS[style_id][a|b|c]`：1转专精，含 `active` + `passive`。
- `STYLE_APEX[style_id]`：1转流派极致，含 `title` + `active` + `passive` + `basic_attack_affix`。
- `CLASS_FUSION[class_id]`：2转融合技，含 `active` + `passive`。
- `CLASS_ASCENSION[class_id]`：3转生命跃迁，含 `active` + `passive` + `life_bonus`。
- `CLASS_TRANSCEND[class_id]`：4转超脱，含 `title` + `ultimate` + `passive`。
- `BORROW_POOL[source]`：4转跨源流借技池，4 选 1（不得借本源流）。
- `fusions[]`：技能融合结果，元素为“主技能 id + 副技能 id”；与 2转的 `fusion_id`（职业融合技）不是同一概念。
- 派生读取：`get_skill(1..10)` 按 `loadout` 对应格位返回；未配置的格位回退到流派 1..6 顺序。
- 能力来源索引：1转流派技能 / 专精 / 极致 → `STYLE_*`；2转 → `CLASS_FUSION`；3转 → `CLASS_ASCENSION`；4转 → `CLASS_TRANSCEND` + `BORROW_POOL`；融合 → `fusions[]`。
- 技能 id 规则：`{class}_{style}_{1..6}` / `{class}_{style}_spec_a|b|c` / `{class}_{style}_apex` / `{class}_fusion` / `{class}_ascension` / `{class}_transcend`。

### 8.6 技能融合（技能树新职能）

技能树 16 节点不再门控技能，而是提供**成长 + 融合**：

- **成长**：每层（4 节点）完成 → 操作栏 +1 格（见 8.2）；其余节点提供属性与被动。
- **融合**：每完成 2 层解锁 1 个融合槽，最多 **2 个融合槽**。
- 融合 = **主技能 + 副技能**，占 1 格：
  - 主技能保留原类型与形态；
  - 副技能只贡献 **1 个词条**：元素（燃烧/冰冻/腐蚀/圣光）、控制（定身 0.5s / 击退 / 眩晕 0.3s）、位移（小幅突进）、召唤（1 只小怪），按副技能类型自动取；
  - 数值：威力 = 主 ×1.15，冷却 = 主 ×1.25，法力 = 主 + 副 ×0.5；
  - 限制：只能用本职业已解锁技能；终极 / 变身 / 超脱不可作副技能；同一技能只能参与一次融合；融合可撤销、不耗资源。
- 融合技能 id：`{主 id}__{副 id}`；存档只存 id，加载后重建。
- 示例：火花术 + 冰锥 = 冰火弹（火伤 + 减速）；烈焰喷发 + 冰霜新星 = 冰火领域（燃烧 + 定身）；亡者领域 + 腐毒弹 = 毒骸召唤（召唤 + 腐蚀）。

---

## 九、一转 · 流派全精通（逐流派）

> 1转选定一条流派即获得其全部内容：6 技能 + 专属普攻 + 流派被动 + 3 条专精 + 1 个流派极致。
> 格式：`专精名`｜新增主动（类型 / 数值）｜新增被动。每条流派三个专精分支 + 一个极致形态（含称号）。
> 数值均为草案，实现时以 `gen_class_content.py` 为准。

### 9.1 法术系（以太 · 蓄势爆发）

#### 法师 [mage]

**流派 A：炎术士**
- 专精一「大咒术师」｜【灰烬领域】`aoe_zone` pw3.9 cd26 mp46｜半径200 delay0.7｜被动 `burn` 燃烧 +25%
- 专精二「焰心行者」｜【烈焰突进】`dash_strike` pw3.5 cd15 mp30｜distance210 半径100｜被动 `fortify` 减伤 -15%
- 专精三「引燃者」｜【火种链】`chain` pw3.4 cd18 mp38｜半径300 目标6｜被动 `execute` 对燃烧目标 +25%
- 极致「焚天者」｜【天火焚城】`aoe_zone` pw5.2 cd32 mp54｜半径240 delay1.0 击退60｜被动 `burn` +40%｜普攻附带火痕

**流派 B：霜法师**
- 专精一「极寒主宰」｜【千里冰封】`root_zone` pw3.0 cd24 mp42｜半径190 定身4.0s｜被动 `shield_bonus` +25%
- 专精二「碎冰者」｜【冰爆术】`aoe_zone` pw3.7 cd20 mp38｜半径160 delay0.5｜被动 `execute` 对定身目标 +30%
- 专精三「霜甲师」｜【霜甲领域】`shield` pw150 cd26 mp36｜持续10s，受击者减速30%｜被动 `shield_bonus` +30%
- 极致「永冬女王」｜【永冬降临】`root_zone` pw4.4 cd30 mp52｜半径220 定身5.0s 附带 pw1.5 冰爆｜被动 `execute` +35%｜周围敌人持续减速

**流派 C：秘法学者**
- 专精一「大奥术师」｜【奥术洪峰】`snipe` pw3.4 cd16 mp30｜range460 width22｜被动 `haste` 攻速 +15%
- 专精二「时序术士」｜【时间停滞】`buff` cd28 mp36｜攻速+60% 持续6s｜被动 `resonance` 每层 +4%，最多 5 层
- 专精三「回响师」｜【奥术回响】`chain` pw3.2 cd14 mp26｜半径280 目标5｜被动 `resonance` 每层 +5%
- 极致「奥术主宰」｜【万法归一】`projectile` pw4.0 cd22 mp44｜九连发 spread0.18 speed600｜被动 `haste` +30%｜施法后 1.5s 内冷却缩减 20%

#### 咒铠师 [runeward]

**流派 A：符阵大师**
- 专精一「符阵宗师」｜【九宫符阵】`heal_zone` cd26 mp36｜半径170 每秒26 持续6s 同时获得 pw60 护盾｜被动 `shield_bonus` +30%
- 专精二「反击符文师」｜【符能反噬】`stun_wave` pw3.6 cd18 mp32｜半径150 眩晕1.0s 击退160｜被动 `fortify` -18%
- 专精三「铭文师」｜【铭文烙印】`mark` cd22 mp26｜半径360 易伤45% 持续10s｜被动 `fortify` -15%
- 极致「符阵圣者」｜【万符天罗】`buff` cd32 mp48｜防御+40 持续12s 反弹 25% 近战伤害｜被动 `shield_bonus` +35%

**流派 B：反噬者**
- 专精一「震符大师」｜【天雷震符】`stun_wave` pw4.2 cd20 mp34｜半径170 眩晕1.2s 击退200｜被动 `fortify` -15%
- 专精二「血符师」｜【血符爆发】`melee_aoe` pw4.0 cd14 mp26｜半径120 吸血30%｜被动 `lifesteal` +18%
- 专精三「荆棘符师」｜【荆棘符甲】`buff` cd28 mp32｜反弹 35% 近战伤害 持续10s｜被动 `shield_bonus` +30%
- 极致「万符之主」｜【万符归宗·极】`stun_wave` pw5.6 cd30 mp50｜半径210 眩晕1.5s 击退240｜被动 `fortify` -25%

**流派 C：守誓者**
- 专精一「圣誓骑士」｜【誓约之光】`heal_zone` cd24 mp40｜半径180 每秒34 持续8s｜被动 `heal_bonus` +30%
- 专精二「铁壁守誓」｜【不朽誓约】`shield` pw180 cd30 mp42｜持续12s｜被动 `shield_bonus` +40%
- 专精三「誓约斗士」｜【誓约反击】`melee_aoe` pw4.6 cd18 mp28｜半径150 吸血20%｜被动 `lifesteal` +18%
- 极致「誓约之神」｜【永恒圣所】`heal_zone` + `shield` cd36 mp56｜半径200 每秒45 持续10s，同时获得 pw150 护盾｜被动 `heal_bonus` +40%

#### 牧师 [priest]

**流派 A：神谕者**
- 专精一「大主教」｜【圣言·愈】`heal` pw130 cd18 mp40｜立即大量回复｜被动 `heal_bonus` +30%
- 专精二「光耀先知」｜【光耀审判】`snipe` pw3.4 cd20 mp36｜range420 width24 吸血20%｜被动 `execute` +25%
- 专精三「圣歌者」｜【圣歌领域】`buff` cd28 mp34｜治疗加成+40% 攻击+20 持续10s｜被动 `heal_bonus` +30%
- 极致「神谕使徒」｜【神谕·创世】`heal_zone` cd34 mp56｜半径200 每秒48 持续10s 并清除负面｜被动 `heal_bonus` +45%

**流派 B：圣殿骑士**
- 专精一「圣裁骑士」｜【圣裁之剑】`snipe` pw3.8 cd20 mp34｜range360 width26 吸血25%｜被动 `execute` +20%
- 专精二「圣盾守卫」｜【圣光壁垒】`shield` pw170 cd28 mp38｜持续10s｜被动 `fortify` -20%
- 专精三「布道者」｜【布道圣言】`heal_zone` cd24 mp38｜半径170 每秒32 持续8s｜被动 `fortify` -15%
- 极致「圣殿大团长」｜【神圣裁决·终】`snipe` pw5.4 cd30 mp52｜range460 width32 吸血30% 击退｜被动 `fortify` -25%

**流派 C：苦修者**
- 专精一「殉道者」｜【殉道圣痕】`heal` pw160 cd22 mp34｜立即大量回复｜被动 `lifesteal` +15%
- 专精二「鞭刑者」｜【赎罪鞭笞】`melee_aoe` pw3.8 cd12 mp24｜半径130 吸血25%｜被动 `lifesteal` +20%
- 专精三「戒律者」｜【戒律锁链】`root_zone` pw3.0 cd22 mp32｜半径160 定身2.5s｜被动 `execute` +25%
- 极致「苦修圣徒」｜【以血证道】`heal` pw220 cd32 mp50｜回复后 8s 内攻击+30｜被动 `lifesteal` +30%

#### 亡灵法师 [necromancer]

**流派 A：收割者**
- 专精一「大收割者」｜【灵魂收割】`snipe` pw4.0 cd22 mp38｜range480 width26 吸血85%｜被动 `lifesteal` +20%
- 专精二「噬魂领主」｜【噬魂领域】`heal_zone` cd24 mp40｜半径160 每秒22 持续8s｜被动 `lifesteal` +18%
- 专精三「亡魂猎手」｜【亡魂标记】`mark` cd22 mp26｜半径400 易伤50% 持续10s，自身吸血+20%｜被动 `lifesteal` +20%
- 极致「死神化身」｜【死亡宣告】`snipe` pw6.0 cd34 mp56｜range560 width32 吸血100%｜被动 `lifesteal` +35%

**流派 B：瘟疫术士**
- 专精一「大瘟疫师」｜【疫病燎原】`aoe_zone` pw3.8 cd24 mp42｜半径190 delay0.6｜被动 `burn` +30%
- 专精二「腐化先知」｜【腐化链】`chain` pw3.6 cd20 mp38｜半径320 目标8｜被动 `execute` +25%
- 专精三「腐骨师」｜【腐骨地刺】`root_zone` pw3.2 cd22 mp34｜半径170 定身2.5s｜被动 `burn` +30%
- 极致「瘟疫之王」｜【末世大疫】`aoe_zone` pw5.2 cd32 mp54｜半径230 delay0.8｜被动 `burn` +45%

**流派 C：尸傀师**
- 专精一「亡灵领主」｜【亡灵领主】`summon` pw3.4 cd26 mp46｜3只 持续18s 速度150 间隔0.8｜被动 `summon_bonus` +25%
- 专精二「尸爆师」｜【尸爆】`aoe_zone` pw4.0 cd20 mp38｜半径170 delay0.4｜被动 `summon_bonus` +20%
- 专精三「魂契师」｜【魂契护盾】`shield` pw140 cd24 mp34｜持续10s，同时强化全部召唤物｜被动 `summon_bonus` +25%
- 极致「亡灵天灾」｜【天灾降临】`summon` pw4.6 cd34 mp58｜6只 持续20s 速度160 间隔0.7｜被动 `summon_bonus` +40%

### 9.2 机械系（蒸汽 · 布置引爆）

#### 炸弹专家 [bomber]

**流派 A：爆破专家**
- 专精一「大爆破师」｜【聚能核爆】`deployable` bomb pw4.2 cd22 mp38｜2枚 半径150 fuse0.8｜被动 `trap_bonus` +25%
- 专精二「要塞爆破」｜【定向爆破】`aoe_zone` pw4.4 cd20 mp36｜半径180 delay0.6 击退120｜被动 `fortify` -15%
- 专精三「连锁师」｜【连锁引爆】`chain` pw4.0 cd20 mp34｜半径280 目标6｜被动 `trap_bonus` +25%
- 极致「爆破之王」｜【终极审判】`deployable` bomb pw6.0 cd34 mp56｜4枚 散布120 半径170 fuse0.6｜被动 `trap_bonus` +40%

**流派 B：纵火者**
- 专精一「大纵火师」｜【火海燎原】`aoe_zone` pw3.8 cd24 mp40｜半径190 delay0.5｜被动 `burn` +30%
- 专精二「燃烬行者」｜【燃烧冲刺】`dash_strike` pw3.6 cd18 mp32｜distance220 半径110｜被动 `burn` +25%
- 专精三「烟幕师」｜【烟幕弹】`root_zone` pw2.6 cd20 mp28｜半径170 定身2.0s｜被动 `fortify` -15%
- 极致「炎狱之主」｜【炎狱焚世】`root_zone` pw5.2 cd32 mp54｜半径220 定身3.5s｜被动 `burn` +45%

**流派 C：铝热师**
- 专精一「雷区大匠」｜【雷区矩阵】`deployable` mine pw3.6 cd26 mp44｜6枚 散布180 半径110 持续22s｜被动 `trap_bonus` +30%
- 专精二「铝热专家」｜【铝热风暴】`aoe_zone` pw4.2 cd22 mp38｜半径170 delay0.5｜被动 `trap_bonus` +25%
- 专精三「工兵」｜【工事炮台】`deployable` turret pw3.6 cd24 mp38｜持续18s 间隔0.6｜被动 `trap_bonus` +30%
- 极致「焦土元帅」｜【焦土禁区】`deployable` mine pw4.8 cd34 mp58｜8枚 散布220 半径120 持续26s｜被动 `trap_bonus` +45%

#### 机甲师 [mech_pilot]

**流派 A：重装机兵**
- 专精一「攻城机兵」｜【攻城炮】`snipe` pw4.4 cd22 mp34｜range760 width24｜被动 `fortify` -18%
- 专精二「重装指挥官」｜【重装阵线】`buff` cd30 mp36｜防御+36 持续12s｜被动 `shield_bonus` +30%
- 专精三「火箭手」｜【火箭齐射】`projectile` pw4.2 cd22 mp34｜六连发 spread0.18｜被动 `haste` +15%
- 极致「战争机器」｜【轨道轰炸】`snipe` pw6.2 cd34 mp52｜range900 width30 击退｜被动 `fortify` -28%

**流派 B：速射炮手**
- 专精一「弹幕大师」｜【弹幕风暴】`projectile` pw3.4 cd18 mp30｜十连发 spread0.20｜被动 `haste` +20%
- 专精二「火力管制官」｜【火力覆盖】`aoe_zone` pw3.8 cd22 mp36｜半径180 delay0.4｜被动 `haste` +15%
- 专精三「穿甲射手」｜【穿甲弹幕】`snipe` pw4.4 cd20 mp32｜range620 width20｜被动 `execute` +25%
- 极致「弹幕之王」｜【全弹幕发射】`projectile` pw4.8 cd30 mp50｜十四连发 spread0.24｜被动 `haste` +35%

**流派 C：要塞驾驶员**
- 专精一「要塞统领」｜【要塞壁垒】`shield` pw200 cd30 mp40｜持续14s｜被动 `shield_bonus` +35%
- 专精二「炮台指挥官」｜【齐射协议】`aoe_zone` pw4.0 cd24 mp38｜半径190 delay0.5｜被动 `fortify` -18%
- 专精三「维修官」｜【维修无人机】`heal_zone` cd24 mp38｜半径170 每秒30 持续8s｜被动 `heal_bonus` +30%
- 极致「移动要塞」｜【要塞形态】`buff` cd36 mp54｜防御+48 持续14s，普攻溅射翻倍｜被动 `shield_bonus` +45%

#### 工程师 [engineer]

**流派 A：炮塔专家**
- 专精一「炮塔大师」｜【重型要塞炮台】`deployable` turret pw3.8 cd24 mp42｜持续26s 间隔0.4｜被动 `trap_bonus` +30%
- 专精二「无人机工程师」｜【无人机编队】`summon` pw3.4 cd22 mp38｜3只 持续16s 速度190 间隔0.9｜被动 `summon_bonus` +25%
- 专精三「地雷工程师」｜【地雷阵】`deployable` mine pw3.6 cd22 mp36｜4枚 散布140 半径100 持续20s｜被动 `trap_bonus` +30%
- 极致「机械领主」｜【炮塔矩阵】`deployable` turret pw4.6 cd32 mp56｜3座 散布90 持续28s 间隔0.35｜被动 `trap_bonus` +45%

**流派 B：后勤官**
- 专精一「战地医官」｜【战地医院·极】`heal_zone` cd26 mp44｜半径190 每秒40 持续10s｜被动 `heal_bonus` +35%
- 专精二「战术指挥官」｜【全军突击】`buff` cd30 mp40｜攻击+34 攻速+15% 持续12s｜被动 `heal_bonus` +30%
- 专精三「护盾工程师」｜【护盾矩阵】`shield` pw160 cd26 mp34｜持续10s｜被动 `shield_bonus` +35%
- 极致「后勤元帅」｜【战争后勤】`heal_zone` cd34 mp58｜半径220 每秒50 持续12s，全队攻击+25｜被动 `heal_bonus` +45%

**流派 C：过载技师**
- 专精一「超频大师」｜【极限超频】`buff` cd26 mp38｜攻速+80% 持续8s｜被动 `haste` +25%
- 专精二「炮台超频者」｜【过载炮塔】`deployable` turret pw4.0 cd22 mp36｜2座 持续18s 间隔0.3｜被动 `trap_bonus` +30%
- 专精三「蒸汽炮手」｜【蒸汽炮击】`projectile` pw3.8 cd16 mp28｜五连发 spread0.14｜被动 `haste` +25%
- 极致「蒸汽狂人」｜【蒸汽永动】`buff` cd34 mp54｜攻速+110% 持续10s 并召唤 1 座速射炮塔｜被动 `haste` +40%

#### 赏金猎人 [bounty_hunter]

**流派 A：赏金猎人**
- 专精一「猎杀者」｜【猎杀清单】`mark` cd28 mp34｜半径520 易伤75% 持续14s｜被动 `execute` +30%
- 专精二「双枪大师」｜【双枪连舞】`projectile` pw3.4 cd18 mp30｜八连发 spread0.14｜被动 `haste` +20%
- 专精三「通缉专家」｜【悬赏通缉】`chain` pw3.6 cd18 mp32｜半径320 目标6｜被动 `execute` +25%
- 极致「赏金之王」｜【悬赏处决】`snipe` pw6.0 cd32 mp52｜range520 width26，对标记目标必暴｜被动 `execute` +40%

**流派 B：追迹者**
- 专精一「弹幕追迹者」｜【追猎弹幕】`chain` pw3.6 cd20 mp34｜半径340 目标8｜被动 `haste` +25%
- 专精二「疾风猎人」｜【疾风突袭】`dash_strike` pw3.4 cd18 mp30｜distance240 半径90｜被动 `haste` +20%
- 专精三「捕猎者」｜【捕兽夹】`root_zone` pw3.0 cd20 mp30｜半径150 定身2.5s｜被动 `trap_bonus` +25%
- 极致「风暴猎人」｜【弹幕风暴·终】`projectile` pw4.6 cd30 mp50｜十二连发 spread0.22｜被动 `haste` +40%

**流派 C：赏金之王**
- 专精一「点杀专家」｜【要害锁定】`buff` cd26 mp32｜暴击+55% 暴伤+50% 持续8s｜被动 `execute` +25%
- 专精二「处刑人」｜【处刑射击】`snipe` pw4.6 cd22 mp36｜range460 width20 吸血20%｜被动 `execute` +30%
- 专精三「连击之王」｜【双枪风暴】`projectile` pw3.8 cd16 mp28｜十连发 spread0.16｜被动 `haste` +25%
- 极致「枪神」｜【一枪定生死】`snipe` pw6.6 cd34 mp54｜range560 width26 吸血25%｜被动 `execute` +45%

### 9.3 传武系（气血 · 贴身缠斗）

#### 死亡骑士 [death_knight]

**流派 A：血骑**
- 专精一「血骑统领」｜【血河冲锋】`dash_strike` pw3.8 cd20 mp32｜distance240 半径95 吸血40%｜被动 `lifesteal` +20%
- 专精二「死亡先锋」｜【死亡践踏】`stun_wave` pw3.8 cd18 mp30｜半径150 眩晕0.9s 击退120｜被动 `fortify` -15%
- 专精三「血魄骑士」｜【血魄护盾】`shield` pw150 cd24 mp30｜持续10s，护盾期间吸血+15%｜被动 `lifesteal` +20%
- 极致「血河之主」｜【血海无涯】`snipe` pw5.6 cd32 mp52｜range420 width34 吸血80%｜被动 `lifesteal` +35%

**流派 B：墓卫**
- 专精一「墓土骑士」｜【墓土壁垒】`shield` pw190 cd28 mp38｜持续12s｜被动 `shield_bonus` +35%
- 专精二「亡者督军」｜【亡者军势】`summon` pw3.6 cd24 mp40｜3只 持续16s 速度140 间隔1.0｜被动 `summon_bonus` +25%
- 专精三「墓火骑士」｜【墓火燎原】`aoe_zone` pw4.2 cd20 mp34｜半径170 delay0.5｜被动 `burn` +30%
- 极致「不朽墓卫」｜【不朽墓域】`buff` cd34 mp52｜防御+46 持续14s 反弹 20% 伤害｜被动 `fortify` -30%

**流派 C：血誓者**
- 专精一「血誓骑士」｜【血誓契约】`buff` cd26 mp34｜攻击+30 吸血+20% 持续10s｜被动 `lifesteal` +20%
- 专精二「血刃大师」｜【血刃风暴】`snipe` pw4.2 cd20 mp34｜range360 width28 吸血60%｜被动 `lifesteal` +25%
- 专精三「献祭者」｜【生命献祭】`melee_aoe` pw4.4 cd16 mp24｜半径130 吸血30%｜被动 `fortify` -15%
- 极致「血誓君王」｜【血海誓约】`snipe` pw6.0 cd32 mp52｜range440 width36 吸血85%｜被动 `lifesteal` +40%

#### 战士 [warrior]

**流派 A：狂战士**
- 专精一「大狂战」｜【狂战风暴】`melee_aoe` pw4.2 cd18 mp30｜半径170｜被动 `lifesteal` +18%
- 专精二「不屈斗士」｜【不屈战吼】`buff` cd26 mp30｜攻击+38 防御+16 持续10s｜被动 `fortify` -15%
- 专精三「嗜血者」｜【嗜血旋风】`melee_aoe` pw4.0 cd14 mp22｜半径150 吸血25%｜被动 `lifesteal` +20%
- 极致「战神」｜【战神降临】`melee_aoe` pw6.2 cd30 mp50｜半径210 眩晕0.8s 击退120｜被动 `lifesteal` +30%

**流派 B：剑圣**
- 专精一「剑豪」｜【万剑归宗·极】`snipe` pw4.6 cd20 mp32｜range460 width30｜被动 `haste` +18%
- 专精二「剑心通明」｜【剑心领域】`buff` cd26 mp34｜攻速+45% 暴击+25% 持续10s｜被动 `resonance` 每层 +5%，最多 5 层
- 专精三「御剑者」｜【御剑术】`projectile` pw3.8 cd16 mp26｜五连发 spread0.12｜被动 `resonance` 每层 +5%
- 极致「剑神」｜【一剑开天】`snipe` pw6.4 cd32 mp50｜range520 width36｜被动 `execute` +35%

**流派 C：破阵者**
- 专精一「破阵先锋」｜【破阵冲锋】`dash_strike` pw4.0 cd18 mp30｜distance280 半径100｜被动 `fortify` -15%
- 专精二「震岳武者」｜【震岳山河】`stun_wave` pw4.4 cd20 mp34｜半径180 眩晕1.0s 击退160｜被动 `fortify` -18%
- 专精三「盾阵者」｜【盾阵壁垒】`shield` pw150 cd24 mp30｜持续10s｜被动 `fortify` -18%
- 极致「山崩地裂」｜【山崩地裂】`dash_strike` pw5.8 cd30 mp50｜distance340 半径140 眩晕0.8s｜被动 `fortify` -25%

#### 气宗 [qi_adept]

**流派 A：医武**
- 专精一「医仙」｜【生生不息·极】`heal_zone` cd24 mp42｜半径190 每秒40 持续8s｜被动 `heal_bonus` +35%
- 专精二「气劲宗师」｜【气劲崩拳】`melee_aoe` pw3.8 cd16 mp26｜半径120｜被动 `resonance` 每层 +4%
- 专精三「点穴师」｜【点穴】`stun_wave` pw3.4 cd18 mp28｜半径140 眩晕1.2s｜被动 `execute` +25%
- 极致「医武圣手」｜【回春圣境】`heal_zone` cd32 mp56｜半径220 每秒52 持续10s 并清除负面｜被动 `heal_bonus` +45%

**流派 B：罡气宗师**
- 专精一「罡气大师」｜【罡气天罡·极】`stun_wave` pw4.5 cd18 mp32｜半径170 眩晕1.2s 击退180｜被动 `fortify` -15%
- 专精二「气墙守御」｜【罡气结界】`shield` pw160 cd26 mp34｜持续10s｜被动 `shield_bonus` +35%
- 专精三「气劲射手」｜【罡气弹】`projectile` pw3.6 cd14 mp24｜五连发 spread0.12｜被动 `haste` +20%
- 极致「天罡武神」｜【天罡破军】`stun_wave` pw5.8 cd30 mp50｜半径210 眩晕1.5s 击退220｜被动 `fortify` -25%

**流派 C：疾风武者**
- 专精一「疾风宗师」｜【无影疾风·极】`melee_aoe` pw3.6 cd10 mp20｜半径140｜被动 `haste` +25%
- 专精二「流云行者」｜【流云幻步】`buff` cd22 mp28｜移速+55% 闪避+35% 持续8s｜被动 `haste` +20%
- 专精三「风刃师」｜【风刃连斩】`snipe` pw3.8 cd16 mp26｜range360 width18｜被动 `resonance` 每层 +5%
- 极致「疾风武神」｜【无影无形】`melee_aoe` pw4.6 cd20 mp36｜半径170 六连击｜被动 `haste` +40%

#### 小偷 [thief]

**流派 A：刺客**
- 专精一「大刺客」｜【瞬杀·极】`blink_strike` pw4.6 cd14 mp24｜range320 半径110｜被动 `execute` +30%
- 专精二「暗影行者」｜【暗影脱离】`blink_strike` pw3.2 cd12 mp20｜range280 半径80，落地闪避+40% 持续3s｜被动 `fortify` -12%
- 专精三「投毒师」｜【淬毒飞刃】`projectile` pw3.6 cd14 mp22｜七连发 spread0.14｜被动 `burn` +30%
- 极致「影王」｜【影杀·终结】`blink_strike` pw6.2 cd26 mp46｜range380 半径140 必暴｜被动 `execute` +45%

**流派 B：影行者**
- 专精一「幻影大师」｜【幻影分身】`summon` pw3.0 cd24 mp34｜2只 持续12s 速度220 间隔0.9｜被动 `haste` +20%
- 专精二「烟幕专家」｜【烟幕领域】`buff` cd24 mp30｜闪避+70% 移速+30% 持续10s｜被动 `fortify` -18%
- 专精三「暗影刺客」｜【暗影突袭】`blink_strike` pw4.4 cd16 mp26｜range300 半径100｜被动 `execute` +30%
- 极致「无影之刃」｜【无影遁】`blink_strike` pw4.4 cd22 mp38｜range300 半径100，之后 5s 暴击+40%｜被动 `fortify` -25%

**流派 C：影舞者**
- 专精一「毒王」｜【万毒噬心·极】`root_zone` pw4.0 cd22 mp34｜半径180 定身3.0s｜被动 `burn` +30%
- 专精二「刃舞者」｜【毒刃风暴】`projectile` pw3.6 cd16 mp28｜九连发 spread0.18｜被动 `haste` +20%
- 专精三「毒雾师」｜【毒雾领域】`aoe_zone` pw3.8 cd18 mp30｜半径170 delay0.4｜被动 `burn` +30%
- 极致「毒影之王」｜【万毒天罗】`root_zone` pw5.4 cd30 mp50｜半径210 定身3.5s 并附带毒爆伤害｜被动 `burn` +45%

### 9.4 科技系（算力 · 预判压制）

#### 弓箭手 [archer]

**流派 A：神射手**
- 专精一「神射宗师」｜【一箭穿心·极】`snipe` pw5.0 cd22 mp34｜range620 width20｜被动 `execute` +30%
- 专精二「鹰眼游侠」｜【鹰眼领域】`buff` cd26 mp30｜暴击+45% 暴伤+60% 持续10s｜被动 `haste` +20%
- 专精三「贯射者」｜【贯穿箭雨】`snipe` pw4.4 cd18 mp28｜range560 width18｜被动 `execute` +25%
- 极致「箭神」｜【射日】`snipe` pw6.8 cd32 mp52｜range720 width26 必暴｜被动 `execute` +45%

**流派 B：游侠**
- 专精一「大游侠」｜【箭雨风暴·极】`aoe_zone` pw4.2 cd22 mp34｜半径190 delay0.5｜被动 `haste` +20%
- 专精二「风行猎手」｜【风行突袭】`dash_strike` pw3.4 cd16 mp28｜distance220 半径90｜被动 `haste` +25%
- 专精三「陷阱游侠」｜【束缚陷阱】`root_zone` pw3.2 cd20 mp28｜半径160 定身2.5s｜被动 `trap_bonus` +25%
- 极致「风之猎手」｜【风暴箭雨】`aoe_zone` pw5.4 cd30 mp50｜半径230 delay0.6｜被动 `haste` +40%

**流派 C：疾风猎手**
- 专精一「速射大师」｜【箭幕·极】`projectile` pw3.6 cd16 mp28｜十连发 spread0.16｜被动 `haste` +30%
- 专精二「风行者」｜【疾风连射】`buff` cd24 mp30｜攻速+60% 移速+20% 持续8s｜被动 `resonance` 每层 +4%
- 专精三「鹰眼射手」｜【鹰眼点射】`snipe` pw4.0 cd16 mp26｜range600 width16 暴击+20%｜被动 `execute` +25%
- 极致「千箭之王」｜【千箭齐发】`projectile` pw4.8 cd26 mp46｜十六连发 spread0.20｜被动 `haste` +45%

#### 义体卫士 [cyborg]

**流派 A：磁轨先锋**
- 专精一「磁轨战士」｜【磁轨风暴·极】`dash_strike` pw4.8 cd20 mp32｜distance360 半径130｜被动 `fortify` -15%
- 专精二「震荡先锋」｜【震荡领域】`stun_wave` pw4.2 cd18 mp30｜半径170 眩晕1.0s 击退120｜被动 `fortify` -18%
- 专精三「义体枪手」｜【义体机枪】`projectile` pw3.8 cd16 mp28｜六连发 spread0.14｜被动 `haste` +20%
- 极致「磁轨天神」｜【磁轨天罚】`dash_strike` pw6.2 cd30 mp50｜distance420 半径160 眩晕1.2s｜被动 `fortify` -25%

**流派 B：不动堡垒**
- 专精一「铁壁统领」｜【神盾协议·极】`shield` pw220 cd28 mp40｜持续12s｜被动 `shield_bonus` +40%
- 专精二「堡垒指挥官」｜【堡垒火力】`aoe_zone` pw4.0 cd22 mp34｜半径180 delay0.5｜被动 `fortify` -20%
- 专精三「堡垒医官」｜【维修立场】`heal_zone` cd24 mp36｜半径170 每秒30 持续8s｜被动 `heal_bonus` +30%
- 极致「不动要塞」｜【绝对壁垒】`buff` cd34 mp52｜防御+50 持续14s 反弹 25% 伤害｜被动 `shield_bonus` +50%

**流派 C：超频武人**
- 专精一「超频拳王」｜【超频风暴·极】`melee_aoe` pw4.4 cd12 mp24｜半径170｜被动 `haste` +30%
- 专精二「伺服武者」｜【伺服连打】`melee_aoe` pw3.8 cd8 mp18｜半径110 三段｜被动 `haste` +25%
- 专精三「电磁拳手」｜【电磁震拳】`stun_wave` pw4.2 cd16 mp26｜半径150 眩晕0.8s 击退140｜被动 `haste` +25%
- 极致「超频武神」｜【超频·无限】`melee_aoe` pw5.8 cd22 mp40｜半径200 眩晕0.6s｜被动 `haste` +50%

#### 黑客 [hacker]

**流派 A：网络行者**
- 专精一「大黑客」｜【零日链·极】`chain` pw4.6 cd22 mp40｜半径420 目标12｜被动 `resonance` 每层 +6%
- 专精二「病毒之王」｜【病毒王冠】`chain` pw4.2 cd20 mp36｜半径380 目标10｜被动 `execute` +25%
- 专精三「防火墙黑客」｜【数据护盾】`shield` pw150 cd24 mp32｜持续10s｜被动 `shield_bonus` +30%
- 极致「零日之主」｜【零日审判】`chain` pw6.0 cd30 mp54｜半径500 目标14｜被动 `resonance` 每层 +8%

**流派 B：幽灵**
- 专精一「断电大师」｜【黑域·极】`stun_wave` pw4.6 cd22 mp38｜半径200 眩晕2.2s 击退40｜被动 `fortify` -15%
- 专精二「幽灵行者」｜【幽灵穿梭】`blink_strike` pw3.4 cd14 mp24｜range280 半径90｜被动 `fortify` -18%
- 专精三「病毒幽灵」｜【病毒爆发】`aoe_zone` pw4.2 cd22 mp34｜半径180 delay0.4｜被动 `execute` +25%
- 极致「黑域幽灵」｜【绝对断域】`stun_wave` pw6.0 cd30 mp52｜半径240 眩晕2.8s 击退30｜被动 `fortify` -25%

**流派 C：网络幽灵**
- 专精一「超频黑客」｜【万物互联·极】`buff` cd26 mp36｜攻速+70% 攻击+28 持续10s｜被动 `haste` +30%
- 专精二「防火墙大师」｜【绝对防火墙】`shield` pw170 cd24 mp32｜持续10s｜被动 `shield_bonus` +30%
- 专精三「链式黑客」｜【链式入侵】`chain` pw3.8 cd18 mp30｜半径340 目标8｜被动 `resonance` 每层 +6%
- 极致「网络之神」｜【全网超频】`buff` cd34 mp52｜攻速+100% 攻击+40 持续12s｜被动 `haste` +45%

#### 狙击手 [sniper]

**流派 A：狙击手**
- 专精一「大狙击手」｜【绝杀狙击·极】`snipe` pw5.4 cd22 mp32｜range980 width22｜被动 `execute` +30%
- 专精二「幽灵射手」｜【潜行狙击】`buff` cd24 mp28｜暴击+50% 闪避+30% 持续8s｜被动 `haste` +15%
- 专精三「爆破狙击」｜【爆裂弹】`aoe_zone` pw4.4 cd20 mp32｜半径170 delay0.4｜被动 `execute` +25%
- 极致「神枪手」｜【天眼绝杀】`snipe` pw7.2 cd34 mp54｜range1100 width26 必暴｜被动 `execute` +50%

**流派 B：陷阱大师**
- 专精一「大陷阱师」｜【死亡禁区·极】`deployable` mine pw4.4 cd26 mp44｜8枚 散布220 半径120 持续26s｜被动 `trap_bonus` +35%
- 专精二「雷场指挥官」｜【雷场矩阵】`deployable` mine pw4.0 cd22 mp38｜6枚 散布180 半径110 持续22s｜被动 `trap_bonus` +30%
- 专精三「诱杀者」｜【诱杀狙击】`snipe` pw4.8 cd20 mp30｜range860 width20｜被动 `trap_bonus` +30%
- 极致「禁区之主」｜【死亡地平线】`deployable` mine pw5.4 cd34 mp56｜10枚 散布260 半径130 持续30s｜被动 `trap_bonus` +50%

**流派 C：潜伏者**
- 专精一「暗杀大师」｜【暗杀·极】`snipe` pw5.0 cd20 mp30｜range900 width20｜被动 `execute` +30%
- 专精二「潜行专家」｜【隐匿领域】`buff` cd24 mp28｜闪避+60% 暴击+35% 持续10s｜被动 `fortify` -15%
- 专精三「毒狙」｜【毒弹狙击】`snipe` pw4.4 cd18 mp28｜range880 width18 附带持续毒伤｜被动 `burn` +30%
- 极致「暗影死神」｜【死神之息】`snipe` pw6.8 cd32 mp50｜range1000 width24 吸血25%｜被动 `execute` +50%

### 9.5 章节统计

| 项目 | 数量 |
| --- | --- |
| 流派 | 48 |
| 流派技能（6 / 条） | 288 |
| 专精（3 / 条） | 144 |
| 流派极致（1 / 条，含称号） | 48 |
| 一转可获得主动技能总量 | 480 |
| 新增技能图标（复用为主，招牌各 1） | ≤ 48 |

---

## 十、二转 / 三转 / 四转（职业级）

> 2转 起内容不再按流派拆分，而是按职业给 1 套；3转、4转 更是脱离流派的生命层次。

### 10.1 二转 · 万流归宗（16 融合技）

解锁硬性条件：本职业 3 条流派的「流派极致」全部获得。
效果：1~6 槽改为跨流派自选（18 选 6），并解锁下表融合技（1 主动 + 1 被动）。

| 职业 | 融合技 | 类型 / 数值 | 被动 |
| --- | --- | --- | --- |
| 法师 | 元素轮舞 | `aoe_zone` pw5.0 cd30 mp60｜半径220 delay0.6 火→冰→奥三段 | `resonance` 每层 +6% |
| 咒铠师 | 符阵归一 | `buff` cd34 mp52｜护盾+50% 防御+30 反弹30% 持续12s | `shield_bonus` +40% |
| 牧师 | 三位一体 | `heal_zone` cd32 mp56｜半径210 每秒50 持续10s，同时造成圣光伤害 | `heal_bonus` +40% |
| 亡灵法师 | 生死轮回 | `summon` cd36 mp58｜5只 持续20s，每只死亡时爆炸 | `summon_bonus` +40% |
| 炸弹专家 | 三重爆破 | `deployable` bomb cd34 mp54｜3枚（燃烧/破片/铝热）散布120 半径160 fuse0.6 | `trap_bonus` +40% |
| 机甲师 | 要塞齐射 | `aoe_zone` pw5.2 cd32 mp52｜半径210 delay0.5 三段炮击 | `fortify` -25% |
| 工程师 | 战争工事 | `deployable` turret cd36 mp56｜2座 持续26s 间隔0.35，附带治疗脉冲 | `trap_bonus` +40% |
| 赏金猎人 | 猎杀交响 | `mark` cd30 mp40｜半径560 易伤70% 持续14s，标记目标受连锁伤害 | `execute` +40% |
| 死亡骑士 | 血墓冲锋 | `dash_strike` pw5.4 cd28 mp46｜distance300 半径140 吸血50% | `lifesteal` +30% |
| 战士 | 剑阵风暴 | `melee_aoe` pw5.6 cd28 mp46｜半径210 眩晕0.8s | `fortify` -25% |
| 气宗 | 气海无量 | `heal_zone` cd32 mp54｜半径210 每秒46 持续10s，范围内敌人受气劲伤害 | `heal_bonus` +38% |
| 小偷 | 毒影分身 | `summon` cd30 mp48｜3只 持续14s，攻击附带中毒 | `burn` +35% |
| 弓箭手 | 万箭穿心 | `snipe` pw6.0 cd30 mp50｜range760 width26 穿透4 | `execute` +40% |
| 义体卫士 | 磁轨壁垒 | `dash_strike` pw5.2 cd30 mp48｜distance340 半径150，落地获得 pw180 护盾 | `shield_bonus` +35% |
| 黑客 | 全网瘫痪 | `chain` pw5.4 cd32 mp54｜半径460 目标12，命中眩晕0.8s | `execute` +40% |
| 狙击手 | 死亡禁区 | `deployable` mine cd34 mp54｜8枚 散布240 半径120 持续26s，同时锁定最远目标 | `trap_bonus` +40% |

### 10.2 三转 · 生命跃迁（16 变身）

不再属于流派，是生命层次的整体提升：永久提高生命/法力上限，并获得 1 个变身主动 + 1 个跃迁被动。

| 职业 | 变身 | 效果 | 被动 | 生命层提升 |
| --- | --- | --- | --- | --- |
| 法师 | 灵体化 | `buff` 法伤+45% 移速+20% 15s，免疫减速 | `resonance` +6% | HP+20% MP+40% |
| 咒铠师 | 符骸 | `shield` pw260 cd75 mp60 持续15s，期间防御+40 | `fortify` -25% | HP+35% MP+20% |
| 牧师 | 圣体 | `heal_zone` cd75 mp62｜半径220 每秒55 持续12s | `heal_bonus` +45% | HP+30% MP+30% |
| 亡灵法师 | 巫妖化 | `buff` 吸血+40% 召唤物+50% 15s | `lifesteal` +35% | HP+25% MP+40% |
| 炸弹专家 | 火元素体 | `aoe_zone` pw5.0 cd75 mp58｜半径200 delay0.3 持续燃烧 | `burn` +45% | HP+25% MP+25% |
| 机甲师 | 机体超载 | `buff` 攻击+40 攻速+25% 受伤-20% 15s | `fortify` -25% | HP+45% MP+15% |
| 工程师 | 机械融合 | `deployable` turret pw5.0 cd80 mp62｜2座 持续20s 间隔0.3 | `trap_bonus` +45% | HP+30% MP+25% |
| 赏金猎人 | 猎人体质 | `buff` 暴击+40% 移速+30% 15s | `execute` +40% | HP+30% MP+20% |
| 死亡骑士 | 不死之躯 | `buff` 吸血+35% 受伤-20% 15s，濒死免疫一次 | `lifesteal` +35% | HP+40% MP+20% |
| 战士 | 战神体 | `buff` 攻击+45 防御+25 15s | `fortify` -25% | HP+45% MP+15% |
| 气宗 | 先天真气 | `buff` 治疗+50% 攻速+35% 15s | `heal_bonus` +40% | HP+30% MP+35% |
| 小偷 | 影体 | `blink_strike` pw5.6 cd70 mp56｜range320 半径140 必暴，之后闪避+50% 8s | `haste` +35% | HP+25% MP+25% |
| 弓箭手 | 鹰神体 | `buff` 暴伤+80% 攻速+30% 15s | `execute` +40% | HP+30% MP+20% |
| 义体卫士 | 全身义体化 | `shield` pw300 cd80 mp56 持续15s，期间受伤-25% | `shield_bonus` +45% | HP+50% MP+10% |
| 黑客 | 数据生命 | `chain` pw5.2 cd75 mp62｜半径480 目标12，命中缩减自身冷却 | `resonance` +7% | HP+25% MP+40% |
| 狙击手 | 鹰神之眼 | `snipe` pw6.4 cd72 mp56｜range900 width26 必暴 | `execute` +45% | HP+25% MP+25% |

### 10.3 四转 · 超脱（16 终极 + 借技池）

脱离职业框架：获得 1 个超脱终极 + 1 个超脱被动 + 称号/外观，并可从**其他源流**借 1 个招牌技能。

| 职业 | 超脱称号 | 超脱终极 | 被动 |
| --- | --- | --- | --- |
| 法师 | 万象法师 | `aoe_zone` pw8.0 cd70 mp120｜半径280 delay0.8 三段元素 | `resonance` +8% |
| 咒铠师 | 不朽符主 | `buff` cd80 mp110｜防御+60 反弹40% 持续16s | `fortify` -35% |
| 牧师 | 创世圣者 | `heal_zone` cd80 mp120｜半径260 每秒70 持续12s 并复活一次 | `heal_bonus` +55% |
| 亡灵法师 | 冥界之主 | `summon` cd90 mp120｜8只 持续24s | `summon_bonus` +55% |
| 炸弹专家 | 终焉爆破 | `deployable` bomb cd80 mp110｜6枚 散布160 半径200 fuse0.5 | `trap_bonus` +55% |
| 机甲师 | 天基要塞 | `snipe` pw9.0 cd80 mp110｜range1200 width40 | `fortify` -35% |
| 工程师 | 机械神国 | `deployable` turret cd90 mp120｜4座 持续30s 间隔0.25 | `trap_bonus` +55% |
| 赏金猎人 | 猎神 | `mark` cd70 mp90｜半径700 易伤90% 持续16s，低血目标直接处决 | `execute` +55% |
| 死亡骑士 | 血海轮回 | `snipe` pw8.4 cd80 mp110｜range560 width40 吸血100% | `lifesteal` +50% |
| 战士 | 剑之极 | `melee_aoe` pw9.0 cd70 mp100｜半径260 眩晕1.0s | `fortify` -35% |
| 气宗 | 天人合一 | `heal_zone` cd80 mp115｜半径260 每秒64 持续12s 并造成气劲伤害 | `heal_bonus` +55% |
| 小偷 | 无我 | `blink_strike` pw9.0 cd60 mp90｜range420 半径180 必暴 | `execute` +55% |
| 弓箭手 | 射日者 | `snipe` pw9.4 cd75 mp100｜range1000 width30 必暴 | `execute` +55% |
| 义体卫士 | 钢铁飞升 | `dash_strike` pw8.6 cd75 mp100｜distance480 半径200 眩晕1.2s | `shield_bonus` +55% |
| 黑客 | 数字永生 | `chain` pw8.4 cd80 mp110｜半径600 目标20 | `resonance` +10% |
| 狙击手 | 一击必杀 | `snipe` pw10.0 cd85 mp110｜range1400 width30 必暴 | `execute` +60% |

**借技池（4 选 1，不得借本源流）**

| 源流 | 借技 | 类型 / 数值 |
| --- | --- | --- |
| 法术 | 秘法射线 | `snipe` pw6.0 cd40 mp50｜range600 width24 |
| 机械 | 爆破核心 | `deployable` bomb pw6.0 cd45 mp55｜2枚 半径160 fuse0.6 |
| 传武 | 破空突进 | `dash_strike` pw6.0 cd35 mp40｜distance280 半径120 |
| 科技 | 数据链 | `chain` pw6.0 cd40 mp50｜半径420 目标10 |

### 10.4 统计

| 项目 | 数量 |
| --- | --- |
| 二转融合技（1 主动 + 1 被动 / 职业） | 16 + 16 |
| 三转变身（1 主动 + 1 被动 / 职业） | 16 + 16 |
| 四转超脱（1 终极 + 1 被动 / 职业） | 16 + 16 |
| 四转借技池 | 4 |
| 二~四转新增条目合计 | 100 |

---

## 十一、实现落点（确认后执行）

1. `tools/gen_class_content.py` 新增三组流派契约，生成到 `data/specializations.json`：
   - `STYLE_KITS[style_id] = {basic_attack, passive, skills[6]}`；
   - `STYLE_SPECS[style_id][a|b|c] = {name, active, passive}`；
   - `STYLE_APEX[style_id] = {title, active, passive, basic_attack_affix}`。
2. 新增职业级契约：`CLASS_FUSION[16]`、`CLASS_ASCENSION[16]`、`CLASS_TRANSCEND[16]`、`BORROW_POOL[4]`。
3. `CharacterData` 增加 `apply_style / apply_spec / apply_apex / apply_fusion / apply_ascension / apply_transcend`，并支持自由配招 `loadout`（最多 10 格）。
4. `get_skill(1..10)` 按 8.5 的派生规则读取；`try_attack` 继续读 `get_basic_attack()`。
5. `PlayerController.try_skill` 支持槽 1~10；`project.godot` 新增 `skill_7`~`skill_10`（`T` / `Y` / `V` / `B`）。
6. HUD 技能栏由 6 格扩为 10 格（随技能树逐层解锁），提供自由配招面板；未解锁格位灰显。
7. **技能树改为成长/融合树**：每层（4 节点）完成 → 操作栏 +1 格；每 2 层解锁 1 个融合槽（最多 2 个）；其余节点给属性/被动。
8. 新增融合系统：`FusionService` 负责校验主/副技能、生成融合技能（主类型 + 副技能 1 词条）、撤销与存档；`SkillExecutor` 按主技能原语执行并叠加词条效果。
9. 操作栏改为自由配招：`loadout` 保存最多 10 个能力 id，其中**流派技能最多 6 个**；拖拽面板只显示已解锁项，同一能力不可重复放入。
10. 被动系统新增 6 个键（`execute / fortify / haste / resonance / trap_bonus / summon_bonus`），在 `SkillExecutor` 与伤害管线统一结算并加算封顶。
11. 3转生命层提升写进 `CharacterData` 的上限计算（HP/MP 百分比），需与装备、药水加成统一结算顺序。
12. 存档迁移：旧存档缺失新字段时按 `spec_id = ""`、`apex_id = ""`、`loadout = []`、`fusions = []` 处理，不报错。
13. 修复 `scripts/combat/deployable.gd` 第 77 行类型推断错误（炸弹/炮塔冒烟失败）。
14. 图标按“元素 × 形态”复用；每条流派招牌技能新增 1 张，控制在 48 张内；融合/跃迁/超脱优先复用。
15. 验收：`validate_project.py` 校验“1转 480 技能 + 2转 16 融合 + 3转 16 变身 + 4转 16 超脱 + 4 借技”的完整性、类型合法、预算区间；冒烟覆盖自由配招、技能融合、1转流派切换、2转跨流派配招、3转变身、4转终极。

## 十二、需要确认的问题

1. 48 条流派名、144 条专精名、48 个流派极致称号是否沿用现有命名？如需改名请指出条目。
2. 2转「18 选 6」跨流派自由配招是否接受？还是限定每流派至少 1 个技能？
3. 操作栏“基础 6 格、随技能树每层 +1 至 10 格、玩家自行配招”是否接受？
4. 3转变身时长 12~18s、冷却 70~90s，以及生命上限 +20%~+50% 的提升幅度是否合适？
5. 4转借技为“4 选 1、不得借本源流”，是否接受？
6. 技能融合规则是否接受：主技能原形态、副技能只带 1 个词条、威力 ×1.15 / 冷却 ×1.25 / 法力 主+副×0.5、最多 2 个融合槽？
7. 每条流派是否保留“招牌图标”新增，还是全部复用现有图标以压缩素材量？

