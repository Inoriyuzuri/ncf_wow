# NCF 使用指南

魔兽世界技能循环辅助插件，支持多职业多专精。

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
- [快捷键](#快捷键)
- [支持的职业专精](#支持的职业专精)
- [常见问题](#常见问题)
- [编写自定义循环](#编写自定义循环)
  - [文件命名](#文件命名)
  - [文件结构](#文件结构)
  - [完整模板](#完整模板)
  - [返回值 (actionType)](#返回值-actiontype)
  - [编写规则](#编写规则)
- [API 参考](#api-参考)
  - [Buff / Debuff](#buff--debuff)
  - [技能冷却与充能](#技能冷却与充能)
  - [资源](#资源)
  - [血量](#血量)
  - [敌人检测](#敌人检测)
  - [打断](#打断)
  - [位置与朝向](#位置与朝向)
  - [战斗状态](#战斗状态)
  - [TTD (目标存活时间)](#ttd-目标存活时间)
  - [模式判断](#模式判断)
  - [治疗辅助](#治疗辅助)
  - [饰品与药水](#饰品与药水)
- [调试技巧](#调试技巧)

---

## 安装

```
nn/
└── scripts/
    ├── _ncf.nn           # 核心文件
    ├── ncf_ui.nn         # UI 界面
    ├── ncf_helper.nn     # 辅助函数
    └── rotations/        # 循环文件夹
        ├── mage_arcane.lua
        ├── warrior_fury.lua
        └── ...
```

1. 将核心文件放入 `nn/scripts/` 目录
2. 将循环文件 (`.lua`) 放入 `nn/scripts/rotations/` 目录
3. `/reload` 重载界面

---

## 基本使用

| 操作 | 默认快捷键 | 宏命令 |
|------|-----------|--------|
| 开关循环 | F1 | `/run NCFswitch()` |
| 切换爆发/划水 | F2 | `/run NCFburst()` |
| 打开设置 | — | `/run NCFsettings()` |

**爆发模式**: 使用所有大技能 (金色标记)
**划水模式**: 跳过爆发技能，只用普通技能

---

## 悬浮面板

屏幕上方的浮动面板，从左到右:

| 组件 | 功能 |
|------|------|
| 推荐技能图标 | 当前建议释放的技能，暂停时显示红色 X，脱战显示「未进战」 |
| TTD 面板 | 目标预估存活时间 (绿≥60s, 黄≥45s, 橙≥20s, 红<20s) |
| 禁用技能面板 | 当前被禁用/爆发跳过的技能图标 |
| 状态栏 | 开启/暂停 - 爆发/划水 - 敌人数量 |

所有组件可在设置面板中单独开关，面板可拖动，位置自动保存。

---

## 设置面板

`/run NCFsettings()` 打开。

| 设置项 | 说明 |
|--------|------|
| **开启快捷键** | 绑定循环开关按键 |
| **爆发快捷键** | 绑定爆发/划水切换按键 |
| **打断设置** | 0=立即打断；≤1=读条完成百分比(如0.9=90%时打断)；>1=剩余秒数 |
| **自动索敌** | 自动切换最优目标，可设检查距离/身前/自定义范围 |
| **自动喝药** | 血量≤阈值时自动使用治疗药水/治疗石 (默认35%，0=关闭) |
| **面板显示** | 单独开关状态栏/推荐技能/TTD/禁用显示 |

---

## 技能模式设置

每个技能有三种模式:

| 模式 | 颜色 | 效果 |
|------|------|------|
| 正常 (normal) | 绿色 | 始终使用 |
| 爆发 (burst) | 橙色 | 仅爆发模式下使用 |
| 禁用 (disabled) | 红色 | 永不使用 |

每个技能还可以设置:
- **快捷键**: 左键绑定，右键清除，按下切换禁用/启用
- **TTD 保护**: 目标存活时间低于设定值时不使用该技能 (0=关闭)

---

## 宏命令

| 宏 | 命令 | 功能 |
|----|------|------|
| NCF | `/run NCFswitch()` | 开关循环 |
| NCF爆发 | `/run NCFburst()` | 切换爆发/划水 |
| NCF智能 | `/run NCFsmart()` | 切换智能目标 |
| 设置 | `/run NCFsettings()` | 打开设置面板 |
| 显示Buff | `/run NCFbuffs()` | 显示玩家 Buff 列表 |
| 显示Debuff | `/run NCFdebuffs()` | 显示目标 Debuff 列表 |

---

## 插入宏 (NCFInsert)

在循环中插入自定义技能，优先级高于循环建议。

```
/run NCFInsert(2825)       -- 按技能ID插入
/run NCFInsert("英勇气概")  -- 按技能名插入
/run NCFQueue()             -- 查看当前队列
```

- 技能必须已就绪
- 脱战后队列自动清空
- 施放成功后自动移除

---

## 猎人前跳宏 (NCFDisengage)

猎人专用，实现向前跳跃 (自动转身→脱离→转回)。

```
#showtooltip 脱离
/run NCFDisengage()
```

---

## 快捷键

支持的格式:

| 类型 | 示例 |
|------|------|
| 单个按键 | `F1`, `1`, `X` |
| 组合键 | `CTRL-1`, `SHIFT-F`, `ALT-X` |
| 鼠标 | `BUTTON3`(中键), `BUTTON4`, `BUTTON5` |
| 滚轮 | `MOUSEWHEELUP`, `MOUSEWHEELDOWN` |

设置方法: 左键点击按钮 → 按下按键 → ESC取消 → 右键清除

---

## 支持的职业专精

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
| 牧师 | 暗影 |
| 盗贼 | 刺杀、狂徒 |
| 萨满 | 恢复 |
| 术士 | 恶魔 |
| 战士 | 武器、狂怒、防护 |

---

## 常见问题

**Q: 没有显示技能提示？**
确认: 循环已开启 (状态栏「已开启」) → 有可攻击目标 → `rotations/` 下有对应文件

**Q: 某个技能不想自动使用？**
技能模式设置中切换到红色 (禁用)

**Q: 爆发技能没有触发？**
确认: 爆发模式已开启 → 技能非红色禁用 → 检查 TTD 保护设置

**Q: 打断时机不对？**
调整打断设置: 数值越大打断越早，越小越晚，0=立即

**Q: 如何强制使用技能？**
`/run NCFInsert(技能ID)` — 在 [Wowhead](https://www.wowhead.com) 搜索技能名获取 ID

---

# 编写自定义循环

以下内容面向想编写自己循环文件的开发者。

---

## 文件命名

格式: `职业_专精.lua` (全小写英文)

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

specIndex 对应: 专精1=1, 专精2=2, 专精3=3, 专精4=4

---

## 文件结构

每个循环文件必须按以下顺序:

```
1. NCF.RegisterSpells(...)     -- 注册技能列表 (文件顶部)
2. local SPELL / BUFF / DEBUFF / TALENT = {...}  -- ID 定义
3. local HasBuff = NCF.HasBuff  -- 局部化函数
4. local function CreateXxxRotation() ... end     -- 主循环
5. return CreateXxxRotation()   -- 文件末尾
```

---

## 完整模板

```lua
--============================================================
-- 职业名 专精名 循环
--============================================================

--============================================================
-- 1. 注册技能 (必须在文件顶部)
--    burst 技能放最前面，技能名使用中文
--============================================================
NCF.RegisterSpells("CLASS", specIndex, {
    { id = 12345, name = "大招", default = "burst" },
    { id = 11111, name = "主要技能", default = "normal" },
    { id = 22222, name = "填充技能", default = "normal" },
    { id = 33333, name = "打断技能", default = "normal" },
})

--============================================================
-- 2. ID 定义
--============================================================
local SPELL = {
    BigCD     = 12345,
    MainNuke  = 11111,
    Filler    = 22222,
    Interrupt = 33333,
}

local BUFF = {
    ProcBuff  = 44444,
}

local DEBUFF = {
    MyDot     = 55555,
}

local TALENT = {
    SpecialTalent = 66666,
}

--============================================================
-- 3. 局部化 Helper 函数
--============================================================
local HasBuff               = NCF.HasBuff
local HasDebuff             = NCF.HasDebuff
local HasTalent             = NCF.HasTalent
local GetBuffStacks         = NCF.GetBuffStacks
local GetDebuffRemain       = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges       = NCF.GetSpellCharges
local GetActiveEnemyAmount  = NCF.GetActiveEnemyAmount
local ShouldSkipSpell       = NCF.ShouldSkipSpell
local SetEnemyCount         = NCF.SetEnemyCount

--============================================================
-- 4. 主循环
--============================================================
local function CreateRotation()

    local function Rotation()
        -- GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)

        -- 移动检测
        local isMoving = GetUnitSpeed("player") > 0

        -- 敌人数量 (每帧更新)
        local enemyCount = GetActiveEnemyAmount(40, true)  -- 远程40, 近战8
        SetEnemyCount(enemyCount)

        -- 局部 IsReady
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end

        ----------------------------------------
        -- 打断 (最高优先级)
        ----------------------------------------
        if IsReady(SPELL.Interrupt) and not ShouldSkipSpell(SPELL.Interrupt) then
            local target = NCF.GetInterruptTarget(30, false)
            if target then
                return "InstantSpell", SPELL.Interrupt, target
            end
        end

        ----------------------------------------
        -- 战前 Buff
        ----------------------------------------
        -- 示例: if not HasBuff(BUFF.SomeBuff) then return "spell", SPELL.SomeBuff end

        ----------------------------------------
        -- 战斗检查 (脱战时不往下执行)
        ----------------------------------------
        if not UnitAffectingCombat("player") and not (UnitExists("target") and UnitAffectingCombat("target")) then
            return "spell", 61304
        end

        ----------------------------------------
        -- 爆发 (burstModeEnabled + 某个具体条件)
        ----------------------------------------
        if NCF.burstModeEnabled and HasBuff(BUFF.ProcBuff) then
            NCF.UseTrinket()
            if NCF.enablePotion then NCF.UseCombatPotion() end
        end

        -- 大招 (带 TTD 保护)
        if NCF.MeetsSpellTTD(SPELL.BigCD) and IsReady(SPELL.BigCD) and not ShouldSkipSpell(SPELL.BigCD) then
            return "spell", SPELL.BigCD
        end

        ----------------------------------------
        -- AOE (多目标写在 ST 之前)
        ----------------------------------------
        if enemyCount >= 3 then
            -- ...
        end

        ----------------------------------------
        -- 单目标
        ----------------------------------------

        -- DoT 维护
        if GetDebuffRemain(DEBUFF.MyDot, "target") < 3 and IsReady(SPELL.MainNuke) and not ShouldSkipSpell(SPELL.MainNuke) then
            return "spell", SPELL.MainNuke
        end

        -- 填充
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

## 返回值 (actionType)

循环函数通过 `return actionType, spellID [, target]` 告诉 NCF 该做什么。

### `"spell"` — 普通施法

对当前目标 (或指定目标) 施法。适用于大多数技能。

```lua
-- 对当前目标施法
return "spell", SPELL.Fireball

-- 对指定目标施法 (如治疗队友)
return "spell", SPELL.HealingWave, lowestUnit
```

### `"InstantSpell"` — 瞬发自动转向施法

自动转向目标 → 施法 → 恢复原朝向。**必须同时满足三个条件**:

1. 技能必须是**瞬发** (无读条、无引导、无蓄力)
2. 技能必须**需要面朝**目标 (攻击性技能对敌人)
3. 目标必须是**动态扫描得到的 GUID** (非 `"target"`)

```lua
-- 打断 (扫描到的目标可能在身后)
local target = NCF.GetInterruptTarget(5, false)
if target then
    return "InstantSpell", SPELL.Kick, target
end

-- 对没有 DoT 的敌人上 DoT
local target = NCF.GetEnemyWithoutDebuff(DEBUFF.FlameShock, 40, false, SPELL.FlameShock)
if target then
    return "InstantSpell", SPELL.FlameShock, target
end
```

**不要用 `InstantSpell` 的场景**: 有读条的技能、治疗队友 (不需要面朝)、自身 buff、对当前 `"target"` 施法。这些都用普通 `"spell"`。

### `"castselflocation"` — 地面技能放脚下

对需要点地的技能，自动放在玩家脚下。

```lua
-- 天堂之羽 (给自己加速)
return "castselflocation", SPELL.AngelsFeather
```

### `"interrupt_and_cast"` — 打断自身引导后施法

用于引导中需要打断自己来释放更高优先级的技能。

```lua
-- 暗牧: 引导精神鞭笞时，高优先级技能打断引导
local isChanneling = IsChannelingMindFlay()
local spellType = isChanneling and "interrupt_and_cast" or "spell"

-- 高优先级技能用 spellType (会打断引导)
if IsReady(SPELL.VoidBlast) then
    return spellType, SPELL.VoidBlast
end

-- 精神鞭笞本身用 "spell" (不打断自己)
return "spell", SPELL.MindFlay
```

### `"item"` — 使用物品

```lua
return "item", itemName
```

### `return nil` — 本帧无建议

```lua
return nil
```

### `return "spell", 61304` — 脱战占位

脱战时返回 GCD 占位符，循环暂停等待进入战斗。

---

## 编写规则

| 规则 | 原因 |
|------|------|
| **每个技能必须检查 `not ShouldSkipSpell(spellID)`** | 否则禁用/爆发保护不生效 |
| **RegisterSpells 技能名用中文** | 显示在 UI 面板上 |
| **burst 技能写在 RegisterSpells 最前面** | UI 显示排序 |
| **打断放在最高优先级** | 打断永远最重要 |
| **AOE 分支写在 ST 之前** | 先判断多目标再判断单目标 |
| **爆发触发饰品/药水需要 2+ 条件** | `burstModeEnabled` 加上某个具体 buff/状态，不能只判断 burstModeEnabled |
| **局部化 NCF 函数** | `local HasBuff = NCF.HasBuff`，提升性能 |

---

# API 参考

> 在循环文件中先局部化再使用: `local HasBuff = NCF.HasBuff`

---

## Buff / Debuff

### HasBuff(spellID [, unit])

检查 buff 是否存在。只检测玩家自己施放的 buff。

- `unit`: 默认 `"player"`
- 返回: `boolean`

```lua
-- 检查自己是否有某个 buff
if HasBuff(BUFF.Bloodlust) then ... end

-- 检查队友是否有 buff
if HasBuff(BUFF.Riptide, "party1") then ... end
```

### GetBuffRemain(spellID [, unit])

获取 buff 剩余秒数。

- `unit`: 默认 `"player"`
- 返回: 秒数。无 buff 返回 `0`，永久 buff 返回 `999`

```lua
local remain = GetBuffRemain(BUFF.Recklessness)
if remain > 5 then ... end
```

### GetBuffStacks(spellID [, unit])

获取 buff 层数。

- `unit`: 默认 `"player"`
- 返回: 层数，无 buff 返回 `0`

```lua
local stacks = GetBuffStacks(BUFF.DemonicCore)
if stacks >= 2 then ... end
```

### HasDebuff(spellID [, unit])

检查 debuff 是否存在。只检测玩家自己施放的 debuff。

- `unit`: 默认 `"target"`
- 返回: `boolean`

```lua
if not HasDebuff(DEBUFF.Rip, "target") then
    -- 需要补 DoT
end
```

### GetDebuffRemain(spellID [, unit])

获取 debuff 剩余秒数。

- `unit`: 默认 `"target"`
- 返回: 秒数。无 debuff 返回 `0`，永久返回 `999`

```lua
if GetDebuffRemain(DEBUFF.Rupture, "target") < 5 then
    -- 快到期了，刷新
end
```

### GetDebuffStacks(spellID [, unit])

获取 debuff 层数。

- `unit`: 默认 `"target"`
- 返回: 层数，无 debuff 返回 `0`

---

## 技能冷却与充能

### GetSpellCooldownRemain(spellID)

获取技能剩余 CD。

- 返回: 秒数，`0` = 可用

```lua
local cd = GetSpellCooldownRemain(SPELL.Combustion)
if cd > 30 then
    -- 大招还有30秒以上，可以做别的
end
```

### IsReady 模式 (推荐)

在 `Rotation()` 内定义局部函数，CD ≤ GCD 视为可用:

```lua
local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
local function IsReady(spellId)
    return GetSpellCooldownRemain(spellId) <= gcd
end

if IsReady(SPELL.Fireball) and not ShouldSkipSpell(SPELL.Fireball) then
    return "spell", SPELL.Fireball
end
```

### GetSpellCharges(spellID)

获取充能数 (含小数)。`1.5` 表示 1 层满 + 正在恢复 50%。

- 返回: 浮点数

```lua
local charges = GetSpellCharges(SPELL.BarbedShot)
if charges > 1.9 then
    -- 快满了，赶紧用一次
end
```

### GetSpellChargeInfo(spellID)

获取充能详细信息。

- 返回: `{ currentCharges, maxCharges, cooldownStartTime, cooldownDuration, chargeModRate }` 或 `nil`

### IsSpellInRange(spellID [, unit])

检查技能是否在目标射程内 (含视线检查)。

- `unit`: 默认 `"target"`
- 返回: `boolean`

```lua
if NCF.IsSpellInRange(SPELL.Riptide, "party2") then
    return "spell", SPELL.Riptide, "party2"
end
```

### RefreshGCD()

更新 `NCF.gcd_max` (GCD 总时长，如 1.5 秒)。**大多数循环不需要调用**。只有当你需要用 `NCF.gcd_max` 做定时计算时才调用 (如 `touchCD > gcd_max * 4`)。

普通用法只需要 GCD 剩余时间:
```lua
local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
```

---

## 资源

### GetUnitPower(unit, powerType)

获取资源值。

- `unit`: 通常 `"player"`
- `powerType`: 资源类型字符串 (见下表)
- 返回: 数值

```lua
local energy = NCF.GetUnitPower("player", "energy")
local comboPoints = NCF.GetUnitPower("player", "combopoints")
local runes = NCF.GetUnitPower("player", "runes")  -- 0-6
```

**powerType 完整列表:**

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
| `"pain"` | 痛苦 | 复仇恶魔猎手 |
| `"essence"` | 精华 | 唤魔师 |

### GetUnitPowerMax(unit, powerType)

获取资源最大值。参数同上。

### GetSpellCostByType(spellID, powerType)

获取技能当前消耗量。有些技能会因 buff 变为免费。

- `powerType`: 必须用 `Enum.PowerType.X` 枚举值
- 返回: 消耗量，技能免费时返回 `0`，无法获取返回 `nil`

```lua
local cost = NCF.GetSpellCostByType(SPELL.LightsHammer, Enum.PowerType.HolyPower)
if cost == 0 then
    -- 免费，立即使用
    return "spell", SPELL.LightsHammer
end
```

---

## 血量

### GetUnitHealthPct(unit)

获取单位血量百分比。

- 返回: `0-100`

```lua
local myHP = NCF.GetUnitHealthPct("player")
local targetHP = NCF.GetUnitHealthPct("target")
```

### GetTargetHealthPct()

获取当前目标血量百分比。等同于 `GetUnitHealthPct("target")`。

### GetUnitHealth(unit) / GetUnitHealthMax(unit)

获取原始血量 / 最大血量值。

---

## 敌人检测

### GetActiveEnemyAmount(range, needCheckFront)

获取范围内的敌人数量及其 GUID。

- `range`: 范围码数
- `needCheckFront`: `true` 只算前方 180°，`false` 算 360°
- 返回: `count, guid1, guid2, ...` (GUID 可直接当 unit 用)

```lua
-- 只需要数量
local enemyCount = GetActiveEnemyAmount(8, false)
SetEnemyCount(enemyCount)

-- 遍历所有敌人检查 debuff
local results = {GetActiveEnemyAmount(40, true)}
local count = results[1]
for i = 2, count + 1 do
    local unit = results[i]
    if not HasDebuff(DEBUFF.ShadowWordPain, unit) then
        -- 该目标没有 DoT
    end
end
```

### GetEnemyWithoutDebuff(debuffID, range, needFront [, spellID])

查找范围内**没有**指定 debuff 的敌人。

- `spellID`: 可选，用于射程检查
- 返回: unit 或 `nil`

```lua
-- 找没有烈焰震击的敌人
local target = NCF.GetEnemyWithoutDebuff(DEBUFF.FlameShock, 40, false, SPELL.FlameShock)
if target then
    return "InstantSpell", SPELL.FlameShock, target
end
```

### GetEnemyWithDebuff(debuffID, range, needFront [, spellID])

查找范围内**有**指定 debuff 的敌人。

```lua
-- 找有烈焰震击的敌人 (释放熔岩爆裂)
local target = NCF.GetEnemyWithDebuff(DEBUFF.FlameShock, 40, false, SPELL.LavaBurst)
if target then
    return "InstantSpell", SPELL.LavaBurst, target
end
```

### GetBestAOETarget(range, searchRange, needFront [, spellID])

查找周围敌人最密集的目标 (AOE 最佳目标)。

- `range`: 以目标为中心统计多少码内的敌人
- `searchRange`: 搜索多少码内的候选目标
- 返回: unit 或 `nil`

```lua
local bestTarget = NCF.GetBestAOETarget(8, 40, false, SPELL.KillCommand)
if bestTarget then
    return "InstantSpell", SPELL.KillCommand, bestTarget
end
```

---

## 打断

### GetInterruptTarget(range, needCheckFront)

查找范围内可打断的敌人。

- `range`: 检测范围码数
- `needCheckFront`: 是否需要面朝。如果用 `InstantSpell` 返回，设为 `false` (NCF 会自动转向)
- 返回: unit 或 `nil`

**重要机制:**
- **焦点优先**: 如果有焦点目标且可攻击，只检查焦点。焦点没在读条就直接返回 `nil`，不扫描其他敌人
- **延迟打断**: 使用 `NCF.interruptDelay` (用户在设置面板配置)。≤1=读条完成百分比，>1=剩余秒数。有随机偏移
- **引导技能**: 引导 (channeling) 立即打断，不受延迟影响

```lua
-- 标准打断写法
if IsReady(SPELL.Kick) and not ShouldSkipSpell(SPELL.Kick) then
    local target = NCF.GetInterruptTarget(5, false)
    if target then
        return "InstantSpell", SPELL.Kick, target
    end
end
```

**多打断源** (玩家打断 + 宠物打断):

```lua
-- 1. 玩家打断 (优先)
if IsReady(SPELL.CounterSpell) and not ShouldSkipSpell(SPELL.CounterSpell) then
    local target = NCF.GetInterruptTarget(40, false)
    if target then
        return "InstantSpell", SPELL.CounterSpell, target
    end
end

-- 2. 宠物打断 (玩家打断 CD 时的备选)
if IsReady(SPELL.AxeToss) and not ShouldSkipSpell(SPELL.AxeToss) and not IsReady(SPELL.CounterSpell) then
    local target = NCF.GetInterruptTarget(35, false)
    if target then
        return "InstantSpell", SPELL.AxeToss, target
    end
end
```

---

## 位置与朝向

### GetDistanceToTarget([unit])

获取与目标的有效距离 (减去双方战斗距离)。

- `unit`: 默认 `"target"`
- 返回: 码数，无目标返回 `999`

### IsUnitInFront(unit)

检查单位是否在玩家前方 180°。

- 返回: `boolean`

---

## 战斗状态

### GetCombatTime()

获取当前战斗持续秒数，脱战返回 `0`。

### GetTimeSinceCast(spellID)

获取上次成功释放该技能后经过的秒数。从未释放返回 `999`。

### HasTalent(talentID)

检查是否有该天赋。

- 返回: `boolean`

```lua
if HasTalent(TALENT.FeedTheFlames) then
    -- 特殊逻辑
end
```

### IsStealthed()

检查是否在潜行状态 (包含潜行、消失、暗影之舞等)。

### GetPetExists()

检查宠物是否存在。

```lua
if not NCF.GetPetExists() then
    return "spell", SPELL.SummonPet
end
```

### IsInBossFight()

检查是否在 Boss 战中 (通过 boss1-5 框架判断)。

---

## TTD (目标存活时间)

### MeetsSpellTTD(spellID) — 推荐

检查技能是否满足 TTD 要求。用户在技能模式设置面板中为每个技能配置 TTD 保护秒数 (默认 0 = 不检查)。

- 返回: `boolean`

```lua
-- 标准用法: 大招前检查 TTD
if NCF.MeetsSpellTTD(SPELL.AdrenalineRush) and IsReady(SPELL.AdrenalineRush) and not ShouldSkipSpell(SPELL.AdrenalineRush) then
    return "spell", SPELL.AdrenalineRush
end
```

### GetMaxTTD([range])

获取范围内所有敌人中最长的存活预估时间。

- `range`: 默认 40
- 返回: 秒数。训练假人返回 `120`，刚开战 (血量≥99%) 返回 `999`，无敌人返回 `0`

```lua
-- 硬编码阈值 (当 MeetsSpellTTD 不够灵活时)
local ttd = NCF.GetMaxTTD()
if ttd >= 15 then
    return "spell", SPELL.Dragonrage
end
```

### MeetsTTDRequirement(minTime)

Boss 战直接返回 `true`，非 Boss 战判断 40 码内 TTD > minTime。

### GetSpellTTD(spellID)

获取该技能在设置面板中配置的 TTD 秒数 (0 = 不检查)。

---

## 模式判断

### ShouldSkipSpell(spellID)

检查技能是否应被跳过。**每个技能判断前必须调用**。

- `"disabled"` 模式 → 始终跳过
- `"burst"` 模式 → 划水模式下跳过
- `"normal"` 模式 → 不跳过

```lua
-- 正确写法: 始终包含 ShouldSkipSpell
if IsReady(SPELL.Fireball) and not ShouldSkipSpell(SPELL.Fireball) then
    return "spell", SPELL.Fireball
end
```

### NCF.burstModeEnabled

`boolean`，当前是否爆发模式。

### NCF.enablePotion

`boolean`，用户是否启用了战斗药水。

---

## 治疗辅助

### GetGroupMembers()

获取当前队伍所有存活成员列表。

- 返回: `{"player", "party1", ...}` 或 `{"player", "raid1", ...}`，过滤死亡/离线

### GetLowestHealthMember(range, threshold [, spellID])

获取血量最低的队友。

- `range`: 距离限制
- `threshold`: 只返回血量低于此百分比的目标 (默认 100)
- `spellID`: 可选，用技能射程检查 (优先于 range)
- 返回: `unit, healthPct` 或 `nil, 100`

```lua
local unit, hp = NCF.GetLowestHealthMember(40, 80, SPELL.HealingWave)
if unit then
    return "spell", SPELL.HealingWave, unit
end
```

### GetGroupAverageHealthPct([range, count])

获取团队平均血量。

- `range`: 距离限制 (可选)
- `count`: 只取血量最低的 N 人算均值 (可选)
- 返回: 百分比 `0-100`

```lua
local avgHP = NCF.GetGroupAverageHealthPct(40)     -- 40码内全员平均
local avgHP = NCF.GetGroupAverageHealthPct(40, 3)   -- 40码内最低3人平均
```

### GetTankUnit()

获取队伍中第一个存活的坦克。

- 返回: unit 或 `nil`

```lua
local tank = NCF.GetTankUnit()
if tank and not HasBuff(BUFF.EarthShield, tank) then
    return "spell", SPELL.EarthShield, tank
end
```

### GetDispellableUnit(dispelType [, range, checkEnemy])

查找有可驱散效果的目标。

- `dispelType`: 单个字符串或数组
  - 友方 debuff: `"Curse"`, `"Poison"`, `"Magic"`, `"Disease"`
  - 敌方 buff (需 `checkEnemy=true`): `"Enrage"`, `"Magic"`
  - 多类型: `{"Curse", "Poison"}`
- `range`: 距离限制
- `checkEnemy`: `true` = 检查敌人 buff，`false`(默认) = 检查友方 debuff
- 返回: unit 或 `nil`

```lua
-- 驱散友方 Magic debuff
local target = NCF.GetDispellableUnit("Magic", 40)
if target then
    return "spell", SPELL.PurifySpirit, target
end

-- 驱散敌方 Enrage buff
local enemy = NCF.GetDispellableUnit("Enrage", 10, true)
if enemy then
    return "InstantSpell", SPELL.Soothe, enemy
end
```

---

## 饰品与药水

### UseTrinket()

使用饰品。优先 slot13，CD 中则用 slot14。

- 返回: `boolean`

### UseCombatPotion()

使用背包中的战斗药水 (增强类)。不检查任何条件，由循环自行判断何时调用。

- 返回: `boolean`

### GetRacialSpell()

获取当前种族的爆发技能 ID。大多数种族返回 `nil`。

```lua
-- 爆发阶段标准写法
if NCF.burstModeEnabled and hasSomeBigBuff then
    NCF.UseTrinket()
    if NCF.enablePotion then NCF.UseCombatPotion() end
    local racialSpell = NCF.GetRacialSpell()
    if racialSpell and IsReady(racialSpell) then
        return "spell", racialSpell
    end
end
```

---

## 调试技巧

```
-- 查看当前所有 Buff (含 ID)
/run NCFbuffs()

-- 查看目标所有 Debuff (含 ID)
/run NCFdebuffs()

-- 开启释放日志: 设置面板 → [dev]聊天框输出释放
```

### 如何获取技能 ID

1. [Wowhead](https://www.wowhead.com) 搜索技能名，URL 中的数字即为 ID
2. 游戏内: `/run print(select(7, GetSpellInfo("技能名")))`

### 常见陷阱

- **Buff ID ≠ 施法 ID**: 例如奥术冲击施法 ID 是 365350，但 buff ID 是 365362。用 `NCFbuffs()` / `NCFdebuffs()` 确认正确的 ID
- **忘记 ShouldSkipSpell**: 每个技能都必须检查，否则用户无法在 UI 中禁用该技能
- **InstantSpell 用于非瞬发技能**: 会导致转向后技能读条被打断。只有瞬发技能才能用
- **爆发只判断 burstModeEnabled**: 必须加上第二个条件 (如某个 buff 存在)，否则一进爆发模式就立即触发饰品

---

## 更新日志

### v12.0
- 支持组合快捷键 (CTRL/SHIFT/ALT + 按键)
- 支持鼠标按键绑定 (BUTTON3/4/5/滚轮)
- 优化打断系统 (延迟打断、百分比/秒数模式)
- 新增悬浮面板组件开关
- 新增 TTD 保护功能
- 新增自动喝药功能
- 新增多个职业循环
