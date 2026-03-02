# NCF 使用指南

NCF 是一个魔兽世界技能循环辅助插件，支持多职业多专精，帮助玩家优化输出/治疗/坦克循环。

---

## 目录

- [安装](#安装)
- [基本使用](#基本使用)
- [悬浮面板](#悬浮面板)
- [设置面板](#设置面板)
- [技能模式设置](#技能模式设置)
- [宏命令](#宏命令)
- [插入宏](#插入宏-ncfinsert)
- [猎人前跳宏](#猎人前跳宏-ncfdisengage)
- [快捷键设置](#快捷键设置)
- [职业专精支持](#职业专精支持)
- [常见问题](#常见问题)
- [编写自定义循环](#编写自定义循环)
  - [文件命名](#文件命名规则)
  - [完整模板](#完整循环模板)
  - [编写规则](#编写规则)
  - [返回值 (actionType)](#返回值-actiontype)
  - [API 参考](#api-参考)
  - [调试工具](#调试工具)

---

## 安装

### 文件结构

```
nn/
└── scripts/
    ├── _ncf.nn           # 核心文件
    ├── ncf_ui.nn         # UI 界面
    ├── ncf_helper.nn     # 辅助函数
    ├── adapters/         # 解锁器适配层
    │   └── nn.lua        # Nn 适配器
    └── rotations/        # 循环文件夹
        ├── mage_arcane.lua
        ├── warrior_fury.lua
        └── ...
```

### 安装步骤

1. 将核心文件 (`_ncf.nn`, `ncf_ui.nn`, `ncf_helper.nn`) 放入 `nn/scripts/` 目录
2. 将职业循环文件 (`.lua`) 放入 `nn/scripts/rotations/` 目录
3. 重载界面 `/reload`

---

## 基本使用

1. 进入游戏后 NCF 自动加载
2. 按 **F1** (默认) 开启/关闭循环
3. 按 **F2** (默认) 切换爆发/划水模式
4. 选中目标后自动建议技能

> 按住 Alt、Shift 或 Ctrl 时循环暂停，松开后恢复。骑乘状态下也会暂停。

---

## 悬浮面板

悬浮面板显示在屏幕上方，可拖动调整位置。

### 面板组件

| 组件 | 功能 |
|------|------|
| **推荐技能图标** | 当前建议释放的技能。暂停时红色 X，未进战显示「未进战」 |
| **TTD 面板** | 目标预估存活时间。绿色(≥60s) 黄色(≥45s) 橙色(≥20s) 红色(<20s) |
| **禁用技能面板** | 被禁用或爆发跳过的技能图标列表 |
| **状态栏** | 格式: `已开启-爆发 敌人:5` |

### 状态栏颜色

| 状态 | 颜色 | 说明 |
|------|------|------|
| 已开启 | 绿色 | 循环正在运行 |
| 已暂停 | 红色 | 循环已停止 |
| 爆发 | 金色 | 使用大技能 |
| 划水 | 绿色 | 不使用爆发技能 |

在设置面板中可单独开关每个组件。

---

## 设置面板

使用 `/run NCFsettings()` 或点击宏「设置」打开。

| 设置项 | 说明 |
|--------|------|
| 开启快捷键 | 循环开关按键 (默认 F1) ⭐全局 |
| 爆发/划水切换 | 爆发模式切换按键 (默认 F2) ⭐全局 |
| 打断过滤列表 | 过滤特定技能不打断 ⭐全局 |
| 驱散过滤列表 | 过滤特定效果不驱散 ⭐全局 |

> ⭐**全局** 标记的设置跨角色共享，修改后所有角色生效。其余设置为角色独立保存。首次更新后旧配置自动迁移，无需手动操作。

### 打断设置

| 值 | 行为 |
|----|------|
| `0` | 立即打断 |
| `0.1` ~ `1.0` | 读条完成该百分比时打断 (如 `0.9` = 完成 90% 时) |
| `> 1` | 读条剩余该秒数时打断 (如 `2` = 剩余 2 秒时) |

> 打断有随机偏移: 百分比模式 ±5%，秒数模式 ±0.3秒。引导技能不受延迟影响，立即打断。

### 自动索敌

| 设置项 | 说明 |
|--------|------|
| 启用自动索敌 | 战斗中自动切换到最优目标 (血量最高) |
| 检查距离 | 目标超出范围时切换 |
| 检查身前 | 目标在身后时优先切换到身前目标 |
| 自定义范围 | 留空 = 根据职业自动判断 (近战5码/远程40码) |

> 治疗专精不会自动索敌。

### 自动喝药

| 设置项 | 默认值 | 说明 |
|--------|--------|------|
| 治疗药水阈值 | 35% | 血量低于此值时自动使用治疗药水 |
| 治疗石阈值 | 35% | 血量低于此值时自动使用治疗石 |
| 战斗药水 | 开启 | 爆发时是否自动使用增强药水 |

设为 `0` 关闭对应功能。

---

## 技能模式设置

在设置面板中点击「技能模式设置」打开。

### 三种模式

| 模式 | 边框颜色 | 行为 |
|------|----------|------|
| 正常 (normal) | 绿色 | 正常使用 |
| 爆发 (burst) | 橙色 | 仅在爆发模式下使用 |
| 禁用 (disabled) | 红色 | 永远不使用 |

### TTD 保护

对爆发技能设置最低 TTD (秒)。敌人存活时间低于此值时不使用该技能。设为 `0` 关闭。

### 每技能快捷键

- **左键**: 设置快捷键
- **右键**: 清除快捷键
- **按下快捷键**: 实时切换禁用/启用

---

## 宏命令

| 宏名称 | 命令 | 功能 |
|--------|------|------|
| NCF | `/run NCFswitch()` | 开关循环 |
| NCF爆发 | `/run NCFburst()` | 切换爆发/划水模式 |
| NCF智能 | `/run NCFsmart()` | 切换智能目标 |
| 设置 | `/run NCFsettings()` | 打开设置面板 |
| 显示Buff | `/run NCFbuffs()` | 打印玩家当前所有 Buff 及 ID |
| 显示Debuff | `/run NCFdebuffs()` | 打印目标当前所有 Debuff 及 ID |
| NCF插入 | `/run NCFInsert(技能ID)` | 插入技能到优先队列 |
| NCF队列 | `/run NCFQueue()` | 显示当前插入队列 |
| LR前跳 | `/run NCFDisengage()` | 猎人前跳宏 |

---

## 插入宏 (NCFInsert)

在循环中插入自定义技能，优先级高于循环建议。

```
/run NCFInsert(2825)         -- 按技能ID
/run NCFInsert("英勇气概")    -- 按技能名
```

显示队列: `/run NCFQueue()`

- 技能必须已就绪 (不在 CD 中)
- 插入后屏幕左侧显示完整队列 (3秒后自动淡出)
- 施放成功后自动刷新显示
- 施放前自动检查资源是否足够 (能量/法力/怒气等)，不够时跳过等待
- 脱战后队列自动清空

---

## 猎人前跳宏 (NCFDisengage)

猎人专用，记录朝向 → 转身180° → 脱离 → 转回。

```
#showtooltip 脱离
/run NCFDisengage()
```

---

## 快捷键设置

| 类型 | 示例 |
|------|------|
| 单个按键 | `F1`, `1`, `X`, `G` |
| 组合键 | `CTRL-1`, `SHIFT-F`, `ALT-X` |
| 多修饰键 | `CTRL-SHIFT-1`, `CTRL-ALT-F` |
| 鼠标按键 | `BUTTON3` (中键), `BUTTON4`, `BUTTON5` |
| 鼠标滚轮 | `MOUSEWHEELUP`, `MOUSEWHEELDOWN` |
| 鼠标组合 | `CTRL-BUTTON4`, `SHIFT-BUTTON5` |

左键设置 → 按下绑定 → ESC取消 → 右键清除。

---

## 职业专精支持

| 职业 | 专精 |
|------|------|
| 死亡骑士 | 鲜血、冰霜、邪恶 |
| 恶魔猎手 | 浩劫、复仇、虚空 |
| 德鲁伊 | 恢复 |
| 唤魔师 | 毁灭 |
| 猎人 | 野兽控制、生存 |
| 法师 | 奥术、冰霜 |
| 武僧 | 酒仙 |
| 圣骑士 | 惩戒 |
| 牧师 | 神圣、暗影 |
| 盗贼 | 刺杀、狂徒 |
| 萨满 | 恢复 |
| 术士 | 恶魔 |
| 战士 | 武器、狂怒、防护 |


---

## 常见问题

**Q: 没有显示技能提示？**
1. 确保循环已开启 (状态栏「已开启」)
2. 确保有可攻击的目标
3. 确保 `rotations/` 中有对应专精的 `.lua` 文件

**Q: 某个技能不想用？**
技能模式设置中切换为红色 (禁用)。

**Q: 爆发技能没有自动使用？**
1. 状态栏是否显示「爆发」
2. 该技能是否红色禁用
3. TTD 保护是否阻止 (Boss 血太低)

**Q: 打断时机不对？**
调整打断设置数值。越大越早，越小越晚，`0` 立即打断。

**Q: 如何强制使用某个技能？**
`/run NCFInsert(技能ID)` — 技能ID 可在 Wowhead 查询。

---

## 编写自定义循环

### 文件命名规则

格式: `职业_专精.lua` (全小写英文)，放入 `rotations/` 后 `/reload`。

| 职业 | 专精1 | 专精2 | 专精3 | 专精4 |
|------|-------|-------|-------|-------|
| WARRIOR | warrior_arms | warrior_fury | warrior_protection | — |
| PALADIN | paladin_holy | paladin_protection | paladin_retribution | — |
| HUNTER | hunter_beastmastery | hunter_marksmanship | hunter_survival | — |
| ROGUE | rogue_assassination | rogue_outlaw | rogue_subtlety | — |
| PRIEST | priest_discipline | priest_holy | priest_shadow | — |
| DEATHKNIGHT | deathknight_blood | deathknight_frost | deathknight_unholy | — |
| SHAMAN | shaman_elemental | shaman_enhancement | shaman_restoration | — |
| MAGE | mage_arcane | mage_fire | mage_frost | — |
| WARLOCK | warlock_affliction | warlock_demonology | warlock_destruction | — |
| MONK | monk_brewmaster | monk_mistweaver | monk_windwalker | — |
| DRUID | druid_balance | druid_feral | druid_guardian | druid_restoration |
| DEMONHUNTER | demonhunter_havoc | demonhunter_vengeance | demonhunter_void | — |
| EVOKER | evoker_devastation | evoker_preservation | evoker_augmentation | — |

---

### 完整循环模板

```lua
--============================================================
-- 职业名 专精名 Rotation
-- Version 1.0
--============================================================

--============================================================
-- 1. 注册技能 (必须在文件最顶部)
--    burst 技能放前面, name 用中文
--============================================================
NCF.RegisterSpells("CLASS", specIndex, {
    { id = 12345, name = "爆发技能名", default = "burst" },
    { id = 11111, name = "主要输出技能", default = "normal" },
    { id = 22222, name = "填充技能",     default = "normal" },
    { id = 33333, name = "打断技能",     default = "normal" },
})

--============================================================
-- 2. ID 定义
--============================================================
local SPELL = {
    MainNuke    = 11111,
    Filler      = 22222,
    Interrupt   = 33333,
    BigCooldown = 12345,
}

local BUFF = {
    ProcBuff = 44444,
}

local DEBUFF = {
    MyDot = 55555,
}

local TALENT = {
    SomeTalent = 66666,
}

--============================================================
-- 3. 局部化 Helper 函数
--============================================================
local HasBuff                = NCF.HasBuff
local HasDebuff              = NCF.HasDebuff
local HasTalent              = NCF.HasTalent
local GetBuffRemain          = NCF.GetBuffRemain
local GetBuffStacks          = NCF.GetBuffStacks
local GetDebuffRemain        = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges        = NCF.GetSpellCharges
local GetActiveEnemyAmount   = NCF.GetActiveEnemyAmount
local GetUnitHealthPct       = NCF.GetUnitHealthPct
local GetUnitPower           = NCF.GetUnitPower
local ShouldSkipSpell        = NCF.ShouldSkipSpell
local SetEnemyCount          = NCF.SetEnemyCount

--============================================================
-- 4. 主循环
--============================================================
local function CreateRotation()

    local function Rotation()
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        local isMoving = GetUnitSpeed("player") > 0
        local enemyCount = GetActiveEnemyAmount(40, true)
        SetEnemyCount(enemyCount)

        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end

        -- 打断 (最高优先级)
        if IsReady(SPELL.Interrupt) and not ShouldSkipSpell(SPELL.Interrupt) then
            local target = NCF.GetInterruptTarget(10, false)
            if target then
                return "InstantSpell", SPELL.Interrupt, target
            end
        end

        -- 战斗检查 (自己/目标/队友任一在战斗中)
        if not NCF.IsInCombat() then
            return "spell", 61304
        end

        -- 爆发 / 饰品
        if NCF.burstModeEnabled and HasBuff(BUFF.ProcBuff) then
            NCF.UseTrinket()
            if NCF.enablePotion then NCF.UseCombatPotion() end
        end

        if NCF.MeetsSpellTTD(SPELL.BigCooldown) and IsReady(SPELL.BigCooldown) and not ShouldSkipSpell(SPELL.BigCooldown) then
            return "spell", SPELL.BigCooldown
        end

        -- AOE
        if enemyCount >= 3 then
            -- AOE 逻辑...
        end

        -- ST
        if GetDebuffRemain(DEBUFF.MyDot, "target") < 2 and IsReady(SPELL.MainNuke) and not ShouldSkipSpell(SPELL.MainNuke) then
            return "spell", SPELL.MainNuke
        end

        if not isMoving and IsReady(SPELL.Filler) and not ShouldSkipSpell(SPELL.Filler) then
            return "spell", SPELL.Filler
        end

        return nil
    end

    return Rotation
end

return CreateRotation()
```

---

### 编写规则

| 规则 | 说明 |
|------|------|
| `RegisterSpells` 在文件最顶部 | 必须在任何 `local` 之前 |
| burst 技能放最前 | `default = "burst"` 的技能放列表最上方 |
| 技能名用中文 | 显示在 UI 面板上 |
| **每个技能必须 `not ShouldSkipSpell()`** | 否则禁用/爆发保护不生效 |
| 打断最优先 | 放在战斗逻辑最顶部 |
| AOE 在 ST 之前 | 多目标分支先判断 |
| 文件末尾 `return CreateRotation()` | 必须返回循环闭包 |
| 非战斗返回 `"spell", 61304` | GCD 占位符 |

---

### 返回值 (actionType)

循环通过 `return actionType, spellID [, target]` 告诉 NCF 该做什么。

---

#### `"spell"` — 普通施法 (最常用)

对当前目标或指定单位施法。

```lua
return "spell", SPELL.Fireball               -- 对当前目标
return "spell", SPELL.HealingWave, lowestUnit -- 对指定队友
```

适用于: 读条技能、引导技能、蓄力技能、瞬发(对当前目标)、自身Buff。

---

#### `"InstantSpell"` — 瞬发 + 自动面朝

NCF 自动转向目标 → 施法 → 恢复朝向。

```lua
-- 打断
local target = NCF.GetInterruptTarget(5, false)
if target then
    return "InstantSpell", SPELL.Kick, target
end

-- 给没有 DoT 的敌人上 DoT
local target = NCF.GetEnemyWithoutDebuff(DEBUFF.FlameShock, 40, false, SPELL.FlameShock)
if target then
    return "InstantSpell", SPELL.FlameShock, target
end

-- AOE: 找周围敌人最多的目标
local best = NCF.GetBestAOETarget(8, 40, false, SPELL.KillCommand)
if best then
    return "InstantSpell", SPELL.KillCommand, best
end
```

**三个必要条件 (缺一不可):**

| # | 条件 | 原因 |
|---|------|------|
| 1 | **瞬发技能** (无读条/引导/蓄力) | 施法后立即恢复朝向，非瞬发会中断 |
| 2 | **需要面朝目标** (对敌人的进攻技能) | 治疗队友/自身Buff不需要面朝，用 `"spell"` |
| 3 | **动态扫描出的目标** | 对当前 `"target"` 直接用 `"spell"` 即可 |

---

#### `"castselflocation"` — 脚下放地面技能

施法后自动在玩家脚下点击。

```lua
return "castselflocation", SPELL.AngelsFeather  -- 天堂之羽放脚下加速
```

---

#### `"cast_ground_spell_to_tank"` — 地面技能放在坦克位置

施法后自动在坦克位置点击。优先选择有仇恨的坦克 (2个坦克时选正在扛怪的)，检查距离 (≤40码) 和视线。如果没有坦克、坦克超出距离或视线被遮挡，则退回到玩家脚下。

```lua
return "cast_ground_spell_to_tank", SPELL.HealingRain  -- 治疗之雨放在坦克脚下
```

适用于: 治疗类地面技能 (治疗之雨等)。

---

#### `"interrupt_and_cast"` — 打断自己的引导后施法

用于需要打断自己引导来释放更高优先级技能的场景。

```lua
-- 暗牧: 引导精神鞭笞时，高优先级技能需要打断引导
local isChanneling = IsChannelingMindFlay()
local spellType = isChanneling and "interrupt_and_cast" or "spell"

-- 高优先级: 需要打断引导
return spellType, SPELL.VoidBlast

-- 精神鞭笞自己: 永远用 "spell"，不打断自己
return "spell", SPELL.MindFlay
```

---

#### `"item"` — 使用物品

```lua
return "item", itemID
```

---

#### `return nil` — 本帧无建议

---

#### 地面技能自动点击

死亡凋零、火焰风暴、地震术等地面技能已内置自动点击，直接用 `"spell"` 返回即可。

---

### API 参考

> 推荐先局部化: `local HasBuff = NCF.HasBuff`。也可直接 `NCF.HasBuff(...)` 调用。

---

#### Buff / Debuff

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `HasBuff(spellID [, unit])` | boolean | 是否有Buff。unit 默认 `"player"` |
| `GetBuffRemain(spellID [, unit])` | number | Buff剩余秒数。无=`0`，永久=`999` |
| `GetBuffStacks(spellID [, unit])` | number | Buff层数。无=`0` |
| `HasDebuff(spellID [, unit])` | boolean | 目标是否有Debuff (玩家施放的)。unit 默认 `"target"` |
| `GetDebuffRemain(spellID [, unit])` | number | Debuff剩余秒数。无=`0`，永久=`999` |
| `GetDebuffStacks(spellID [, unit])` | number | Debuff层数。无=`0` |

> Buff/Debuff 只检测**玩家施放**的 (PLAYER filter)。

```lua
-- 自己是否有鲁莽
if HasBuff(BUFF.Recklessness) then ... end

-- 坦克是否有大地之盾
if HasBuff(BUFF.EarthShield, tankUnit) then ... end

-- 目标割裂剩余时间
local remain = GetDebuffRemain(DEBUFF.Rupture, "target")
if remain < 5 then ... end  -- 快掉了，刷新

-- 充能爆发层数
local stacks = GetBuffStacks(BUFF.ChargedBlast)
if stacks >= 12 then ... end
```

---

#### 技能冷却与充能

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `GetSpellCooldownRemain(spellID)` | number | 剩余CD秒数。`0` = 可用 |
| `IsSpellReady(spellID)` | boolean | CD ≤ GCD 视为可用 |
| `GetSpellCharges(spellID)` | number | 充能数含小数。如 `1.5` = 1层满+恢复50% |
| `GetSpellChargeInfo(spellID)` | table/nil | `{currentCharges, maxCharges, cooldownStartTime, cooldownDuration, chargeModRate}` |
| `IsSpellInRange(spellID [, unit])` | boolean | 在射程内 **且** 有视线(LoS)。unit 默认 `"target"` |
| `RefreshGCD()` | — | 更新 `NCF.gcd_max`。仅当需要 `gcd_max` 做计算时才调用 |

```lua
-- 技能CD检查 (大多数循环使用内联 IsReady)
local function IsReady(spellId)
    return GetSpellCooldownRemain(spellId) <= gcd
end

-- 充能检查
local charges = GetSpellCharges(SPELL.BarbedShot)
if charges > 1.9 then ... end  -- 快满了，用一个

-- 技能射程 + 视线
if NCF.IsSpellInRange(SPELL.Riptide, unit) then
    return "spell", SPELL.Riptide, unit
end
```

---

#### 资源

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `GetUnitPower(unit, powerType)` | number | 当前资源值 |
| `GetUnitPowerMax(unit, powerType)` | number | 最大资源值 |
| `GetSpellCostByType(spellID, Enum.PowerType.X)` | number/nil | 技能消耗量。免费=`0`，无法获取=`nil` |
| `CanAffordSpell(spellID)` | boolean | 玩家是否有足够资源施放该技能 |

**powerType 字符串对照:**

| 字符串 | 资源 | 职业 |
|--------|------|------|
| `"energy"` | 能量 | 盗贼、武僧、猫德 |
| `"rage"` | 怒气 | 战士、熊德 |
| `"focus"` | 集中值 | 猎人 |
| `"runicpower"` | 符能 | 死亡骑士 |
| `"runes"` | 符文 (返回可用数量 0-6) | 死亡骑士 |
| `"mana"` | 法力 | 法师、治疗 |
| `"combopoints"` | 连击点 | 盗贼、猫德 |
| `"soulshards"` | 灵魂碎片 | 术士 |
| `"holypower"` | 圣能 | 圣骑士 |
| `"maelstrom"` | 漩涡值 | 萨满 |
| `"chi"` | 真气 | 武僧 |
| `"insanity"` | 狂乱值 | 暗牧 |
| `"arcanecharges"` | 奥术充能 | 奥法 |
| `"fury"` | 怒火 | 恶魔猎手 |
| `"pain"` | 痛苦 | 复仇DH |
| `"essence"` | 精华 | 唤魔师 |

```lua
local energy = GetUnitPower("player", "energy")
local combo  = GetUnitPower("player", "combopoints")
local runes  = GetUnitPower("player", "runes")  -- 0-6 可用符文

-- 检查技能是否免费
local cost = NCF.GetSpellCostByType(SPELL.LightsHammer, Enum.PowerType.HolyPower)
if cost == 0 then
    return "spell", SPELL.LightsHammer  -- 免费，立即用
end
```

---

#### 血量

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `GetUnitHealthPct(unit)` | number | 血量百分比 0-100 |
| `GetTargetHealthPct()` | number | 等同于 `GetUnitHealthPct("target")` |
| `GetUnitHealth(unit)` | number | 当前血量原始值 |
| `GetUnitHealthMax(unit)` | number | 最大血量原始值 |

```lua
local myHP = GetUnitHealthPct("player")
if myHP < 30 then ... end  -- 血量危险

-- 斩杀阶段
if GetTargetHealthPct() <= 20 then
    return "spell", SPELL.Execute
end
```

---

#### 敌人检测

##### `GetActiveEnemyAmount(range, needFront)` — 范围内敌人数量

| 参数 | 说明 |
|------|------|
| range | 检测范围 (码) |
| needFront | `true` = 只算前方180°，`false` = 360° |

返回: `count, guid1, guid2, ...` — GUID 可直接当 unit token 用。

```lua
-- 只要数量
local enemyCount = GetActiveEnemyAmount(8, false)

-- 遍历所有敌人检查 debuff
local results = {GetActiveEnemyAmount(40, true)}
local count = results[1]
for i = 2, count + 1 do
    local unit = results[i]
    if not HasDebuff(DEBUFF.SWPain, unit) then
        -- 这个敌人没有暗言术痛
    end
end
```

##### `SetEnemyCount(count)` / `GetEnemyCount()` — 存取敌人数量

每帧开头 `SetEnemyCount` 更新，供 UI 显示。

##### `GetEnemyWithoutDebuff(debuffID, range, needFront, spellID)` — 找没有指定 Debuff 的敌人

| 参数 | 说明 |
|------|------|
| debuffID | 要检查的 Debuff ID |
| range | 搜索范围 (码) |
| needFront | 是否需要面朝。搭配 `InstantSpell` 时传 `false` |
| spellID | 可选，额外检查技能射程 |

返回: `unit` 或 `nil`

```lua
local target = NCF.GetEnemyWithoutDebuff(DEBUFF.FlameShock, 40, false, SPELL.FlameShock)
if target then
    return "InstantSpell", SPELL.FlameShock, target
end
```

##### `GetEnemyWithDebuff(debuffID, range, needFront, spellID)` — 找有指定 Debuff 的敌人

用法同上，返回**有**该 Debuff 的第一个敌人。

```lua
local target = NCF.GetEnemyWithDebuff(DEBUFF.FlameShock, 40, false, SPELL.LavaBurst)
if target then
    return "InstantSpell", SPELL.LavaBurst, target
end
```

##### `GetBestAOETarget(range, searchRange, needFront, spellID)` — 最佳 AOE 目标

| 参数 | 说明 |
|------|------|
| range | 爆炸半径 (以目标为中心统计) |
| searchRange | 搜索范围 |
| needFront | 是否需要面朝 |
| spellID | 可选，射程检查 |

返回: 周围敌人最多的 `unit` 或 `nil`

```lua
local best = NCF.GetBestAOETarget(8, 40, false, SPELL.KillCommand)
if best then
    return "InstantSpell", SPELL.KillCommand, best
end
```

##### `GetInterruptTarget(range, needFront)` — 找可打断的敌人

| 参数 | 说明 |
|------|------|
| range | 检测范围 (码) |
| needFront | 搭配 `InstantSpell` 时传 `false` |

返回: `unit` 或 `nil`

```lua
if IsReady(SPELL.Kick) and not ShouldSkipSpell(SPELL.Kick) then
    local target = NCF.GetInterruptTarget(5, false)
    if target then
        return "InstantSpell", SPELL.Kick, target
    end
end
```

**重要行为:**
- **焦点优先**: 有焦点时只检查焦点。焦点没在读条就返回 `nil`，不扫描其他敌人。
- **延迟打断**: 仅对施法(casting)生效，引导(channeling)立即打断。

---

#### 位置与朝向

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `GetDistanceToTarget([unit])` | number | 有效距离(码)，减去双方战斗距离。无目标=`999` |
| `IsUnitInFront(unit)` | boolean | 是否在玩家前方180° |

---

#### 战斗状态

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `IsInCombat()` | boolean | 组队感知的战斗检测：玩家/目标/队友任一在战斗中 |
| `GetCombatTime()` | number | 战斗持续秒数。脱战=`0` |
| `GetTimeSinceCast(spellID)` | number | 上次施放后经过的秒数。从未施放=`999` |
| `HasTalent(talentID)` | boolean | 是否有该天赋 |
| `IsStealthed()` | boolean | 潜行/消失/暗影之舞等 |
| `GetPetExists()` | boolean | 宠物是否存在 |
| `IsInBossFight()` | boolean | 是否 Boss 战 (boss1-5框架) |

```lua
if HasTalent(TALENT.Doomsday) then ... end

if not NCF.GetPetExists() then
    return "spell", SPELL.SummonPet
end

if NCF.IsStealthed() then
    return "spell", SPELL.Ambush
end
```

---

#### TTD (目标存活时间)

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `GetMaxTTD([range])` | number | 范围内最长TTD秒数。默认40码 |
| `MeetsTTDRequirement(minTime)` | boolean | Boss战直接true，否则 `GetMaxTTD(40) > minTime` |
| `MeetsSpellTTD(spellID)` | boolean | 读取该技能在设置面板的TTD配置。TTD=0 不检查(返回true) |
| `GetSpellTTD(spellID)` | number | 该技能配置的TTD要求(秒)。0=不检查 |

**GetMaxTTD 返回值规则:**

| 情况 | 返回值 |
|------|--------|
| 敌人血量 ≥ 99% (刚开打) | `999` |
| 训练假人 | `120` |
| 无敌人 | `0` |
| 正常情况 | 线性推算 |

**推荐用法:** 大CD用 `MeetsSpellTTD`，让用户在设置面板自行调整:

```lua
if NCF.MeetsSpellTTD(SPELL.AdrenalineRush) and IsReady(SPELL.AdrenalineRush) and not ShouldSkipSpell(SPELL.AdrenalineRush) then
    return "spell", SPELL.AdrenalineRush
end
```

硬编码 TTD 阈值用 `GetMaxTTD`:

```lua
local ttd = NCF.GetMaxTTD()
if ttd >= 30 and IsReady(SPELL.Dragonrage) then ... end  -- ST: 需要30秒
if ttd >= 15 and IsReady(SPELL.Dragonrage) then ... end  -- AOE: 15秒就够
```

---

#### 模式判断

| 函数/变量 | 类型 | 说明 |
|-----------|------|------|
| `ShouldSkipSpell(spellID)` | boolean | disabled→始终跳; burst+划水模式→跳; 其他→不跳 |
| `NCF.burstModeEnabled` | boolean | 当前是否爆发模式 |
| `NCF.enablePotion` | boolean | 用户是否开启战斗药水 |

**ShouldSkipSpell 逻辑:**

| 技能模式 | 爆发模式 | 划水模式 |
|----------|----------|----------|
| normal | 不跳 | 不跳 |
| burst | 不跳 | **跳过** |
| disabled | **跳过** | **跳过** |

> **每个技能判断前必须检查 `not ShouldSkipSpell()`。没有例外。**

**爆发/饰品规则:** 不要仅靠 `burstModeEnabled` 触发饰品/药水，必须同时有具体状态:

```lua
-- 正确: burstModeEnabled + 某个大招激活
if NCF.burstModeEnabled and HasBuff(BUFF.Recklessness) then
    NCF.UseTrinket()
end

-- 错误: 单独 burstModeEnabled
if NCF.burstModeEnabled then
    NCF.UseTrinket()  -- 不要这样!
end
```

---

#### 治疗辅助

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `GetGroupMembers()` | table | `{"player","party1",...}` 或 `{"player","raid1",...}`。过滤死亡/离线 |
| `GetGroupAverageHealthPct([range, count])` | number | 团队平均血量%。count=取最低N人算 |
| `GetLowestHealthMember([range, threshold, spellID, tankHpOffset])` | unit, pct | 血量最低的队友。使用真实缺血量(扣除即将到达的治疗)。tankHpOffset=Tank视为多X%血量。无=`nil, nil` |
| `GetTrueDeficit(unit)` | deficit, maxHp | 真实缺血量: 扣除即将到达的治疗，加上治疗吸收盾。deficit ≥ 0 |
| `GetTankUnit()` | unit/nil | 持有仇恨的坦克 (UnitThreatSituation ≥ 3)；无仇恨时返回第一个 TANK 职责成员 |
| `GetDispellableUnit(type [, range, checkEnemy])` | unit/nil | 可驱散的目标 |

```lua
-- 全团40码内平均血量
local avgHp = GetGroupAverageHealthPct(40)

-- 最低3人平均
local avgHp = GetGroupAverageHealthPct(40, 3)

-- 血量最低的队友 (用技能射程检查)
local unit, hp = GetLowestHealthMember(40, 100, SPELL.HealingWave)
if unit and hp < 90 then
    return "spell", SPELL.HealingWave, unit
end

-- Tank视为多10%血量, 降低治疗优先级
local unit, hp = GetLowestHealthMember(40, 95, SPELL.FlashHeal, 10)

-- 真实缺血量 (扣除即将到达的治疗, 加上治疗吸收)
local deficit, maxHp = NCF.GetTrueDeficit("party1")

-- 坦克大地之盾维护
local tank = GetTankUnit()
if tank and not HasBuff(BUFF.EarthShield, tank) then
    return "spell", SPELL.EarthShield, tank
end
```

**驱散:**

```lua
-- 友方 debuff 驱散
local unit = NCF.GetDispellableUnit("Magic", 40)
if unit then return "spell", SPELL.Purify, unit end

-- 多类型
local unit = NCF.GetDispellableUnit({"Curse", "Poison"}, 40)

-- 敌方 buff 驱散 (checkEnemy=true)
local enemy = NCF.GetDispellableUnit("Enrage", 10, true)
if enemy then return "InstantSpell", SPELL.Soothe, enemy end
```

**dispelType 可选值:** 友方: `"Curse"`, `"Poison"`, `"Magic"`, `"Disease"` / 敌方: `"Enrage"`, `"Magic"`

> 友方驱散检查视线(LoS)，敌方驱散不检查。

---

#### 饰品、药水与施法辅助

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `UseTrinket()` | boolean | 使用饰品。优先slot13，CD则用slot14 |
| `UseCombatPotion()` | boolean | 使用背包中的增强药水 |
| `GetRacialSpell()` | number/nil | 种族爆发技能ID。大部分种族返回 `nil` |

```lua
-- 爆发阶段
if NCF.burstModeEnabled and HasBuff(BUFF.BigCD) then
    NCF.UseTrinket()
    if NCF.enablePotion then NCF.UseCombatPotion() end
    local racial = NCF.GetRacialSpell()
    if racial and IsReady(racial) then
        return "spell", racial
    end
end
```

---

#### 投射物追踪

追踪技能飞行状态，防止重复施放。

**注册 (循环文件顶部，SPELL 表之后):**

```lua
NCF.RegisterProjectile(SPELL.Frostbolt, 35)       -- 35 码/秒
NCF.RegisterProjectile(SPELL.Fireball, 45)         -- 45 码/秒
NCF.RegisterProjectile(SPELL.Meteor, nil, 3.0)     -- 固定 3 秒飞行时间
```

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `RegisterProjectile(spellID, speed, fixedTime)` | — | 注册投射物。speed=码/秒，fixedTime=固定秒数 |
| `GetProjectileCount(id1, id2, ...)` | number | 飞行中的投射物总数 (支持多个技能) |

```lua
-- 检查多个技能的飞行中总数
local inFlight = NCF.GetProjectileCount(SPELL.Frostbolt, SPELL.IceLance, SPELL.Flurry)
if inFlight < 2 then
    return "spell", SPELL.Frostbolt
end

-- 单个技能
if NCF.GetProjectileCount(SPELL.Frostbolt) == 0 then
    return "spell", SPELL.Frostbolt
end
```

- 同一技能可追踪多个飞行实例
- `UNIT_SPELLCAST_SUCCEEDED` 自动记录，脱战自动清空
- 未注册的技能自动忽略，无性能开销

---

#### 技能队列 (循环级)

供循环文件检查和处理用户通过 `NCFInsert` 插入的技能。

| 函数 | 返回值 | 说明 |
|------|--------|------|
| `QueueSpell(spellID [, target])` | — | 添加技能到队列。同一技能不重复，会刷新时间 |
| `GetQueuedSpell([id1, id2, ...])` | spellID, target / nil | 不传参=队列第一个；传参=匹配指定ID |
| `ConsumeQueuedSpell([spellID])` | boolean | 移除已处理的技能。不传参=移除第一个 |
| `ClearSpellQueue()` | — | 清空队列 |
| `GetSpellQueueSize()` | number | 队列长度 |

超时: 默认 3 秒自动过期 (`NCF.spellQueueTimeout`)

```lua
-- 检查队列中是否有特定技能
local id = NCF.GetQueuedSpell(SPELL.Metamorphosis, SPELL.EyeBeam)
if id and IsReady(id) then
    NCF.ConsumeQueuedSpell(id)
    return "spell", id
end

-- 获取队列中任意技能
local id, target = NCF.GetQueuedSpell()
if id and IsReady(id) then
    NCF.ConsumeQueuedSpell(id)
    return "spell", id, target
end
```

---

### 调试工具

```
/run NCFbuffs()     -- 打印自己所有 Buff 及 ID
/run NCFdebuffs()   -- 打印目标所有 Debuff 及 ID
```

设置面板勾选 `[dev]聊天框输出释放` 可在聊天框看到每次施法的技能名和 ID。

**获取技能 ID:**
1. [Wowhead](https://www.wowhead.com) 搜索技能，URL 中的数字即 ID
2. 游戏内: `/run print(select(7, GetSpellInfo("技能名")))`
3. 用 `NCFbuffs()` / `NCFdebuffs()` 查看当前效果的 ID

> **注意:** 施法 ID 和 Buff/Debuff ID 经常不同！例如奥术冲击施法ID `365350`，Buff ID `365362`。务必分别确认。

---

## 更新日志

### v12.5
- **治疗模式切换 (恢复萨满 & 神圣牧师)** — 新增法力效率/治疗量双模式。面板按钮一键切换，支持自定义快捷键绑定；脱战后自动恢复为法力模式
- **神圣牧师法力天赋支持** — Flash Heal vs PoH 效率比较加入 HealingFocus、EfficientPrayers、FocusedOutburst 天赋法力修正
- **恢复萨满移除输出循环** — 移除烈焰冲击/熔岩爆发输出部分，专注治疗
- **`GetTankUnit` 优化** — 优先返回持有仇恨的坦克 (UnitThreatSituation ≥ 3)，无仇恨时回退到第一个 TANK 职责成员

### v12.4
- **新增神圣牧师循环** — 智能治疗选择 (Flash Heal vs Prayer of Healing 效率比较)、Surge of Light 层数管理、Holy Word: Serenity 充能优化、Guardian Spirit 紧急治疗、Twist of Fate 保持、DPS 填充、移动时天堂之羽
- **UI 全面美化 (ElvUI 风格)** — 面板/按钮/勾选框/下拉菜单统一扁平风格，Spinner 数字输入组件，辉光阴影效果
- **屏幕中央通知** — 开关 NCF、切换爆发/划水模式时屏幕中央淡入淡出提示，可在设置中开关
- **新增 `GetTrueDeficit(unit)`** — 真实缺血量计算 (扣除即将到达的治疗，加上治疗吸收)
- **`GetLowestHealthMember` 智能化** — 使用真实缺血量比较，新增 `tankHpOffset` 参数降低 Tank 治疗优先级
- **TTD 面板精简** — 移除文字标签，只显示数值，框体更紧凑
- **Tooltip 提示** — 悬浮面板开关、勾选框添加鼠标悬停说明
- **动态面板高度** — 设置面板最大高度为屏幕 75%，适配不同分辨率
- **打断/驱散过滤重构** — 合并为通用 FilterSection，减少约 260 行重复代码
- 修复打断/驱散过滤列表中技能 ID 类型不一致问题 (tonumber 守护)

### v12.3
- 快捷键 (开启/爆发切换) 和打断/驱散过滤列表改为全局配置，跨角色共享
- 旧配置自动迁移，无需手动操作

### v12.2
- 新增适配器抽象层 (`NCF.API`)，解耦解锁器依赖
- 所有解锁器相关调用 (ObjectManager, Distance, CastSpellByName 等) 统一通过 `NCF.API` 访问
- 当前支持 Nn 适配器 (`adapters/nn.lua`)，新增解锁器只需添加对应适配器文件
- 循环文件无需任何修改，仍然只调用 `NCF.*` 函数

### v12.1
- 新增投射物飞行追踪 (`RegisterProjectile` / `GetProjectileCount`)，防止重复施放远程技能
- 新增循环级技能队列 API (`QueueSpell` / `GetQueuedSpell` / `ConsumeQueuedSpell`)
- 新增资源检查 (`CanAffordSpell`)，插入队列施放前自动验证能量/法力等
- 插入队列改为屏幕左侧可视化显示，3秒自动淡出

### v12.0
- 支持组合快捷键 (CTRL/SHIFT/ALT + 按键)
- 支持鼠标按键绑定 (BUTTON3/4/5) 和鼠标滚轮
- 优化打断系统 (延迟打断 + 随机偏移)
- 新增悬浮面板组件开关
- 新增 TTD 保护功能
- 新增自动喝药功能
- 新增多个职业循环
- 修复配置保存问题
- 优化 UI 界面

---

**祝游戏愉快！**
