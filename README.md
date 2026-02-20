# NCF 使用指南

## 简介

NCF 是一个魔兽世界技能循环辅助插件，支持多职业多专精，帮助玩家优化输出/治疗/坦克循环。

---

## 安装

### 文件结构

```
nn/
└── scripts/
    ├── _ncf.nn           # 核心文件
    ├── ncf_ui.nn         # UI 界面
    ├── ncf_helper.nn     # 辅助函数
    └── rotations/        # 循环文件夹
        ├── mage_arcane.lua
        ├── warrior_fury.lua
        ├── deathknight_frost.lua
        └── ...
```

### 安装步骤

1. 将核心文件 (`_ncf.nn`, `ncf_ui.nn`, `ncf_helper.nn`) 放入 `nn/scripts/` 目录
2. 将职业循环文件 (`.lua`) 放入 `nn/scripts/rotations/` 目录
3. 重载界面 `/reload`

---

## 悬浮面板

悬浮面板是 NCF 的主要显示界面，显示在屏幕上方，可拖动调整位置。

### 面板组件

从左到右依次为:

| 组件 | 功能 |
|------|------|
| **推荐技能图标** | 显示当前建议释放的技能图标，暂停时显示红色 X |
| **TTD 面板** | 显示目标预估存活时间 (Time To Die) |
| **禁用技能面板** | 显示当前被禁用的技能图标列表 |
| **状态栏** | 显示: 开启/暂停状态、爆发/划水模式、敌人数量 |

### 面板状态说明

**状态栏显示格式:** `已开启-爆发 敌人:5`

| 状态 | 颜色 | 说明 |
|------|------|------|
| 已开启 | 绿色 | 循环正在运行 |
| 已暂停 | 红色 | 循环已停止 |
| 爆发 | 金色 | 爆发模式，使用大技能 |
| 划水 | 绿色 | 划水模式，不使用爆发技能 |

### 未进战提示

当推荐技能图标上方显示「未进战」时，表示当前未进入战斗状态，循环等待中。

### 显示选项

在设置面板中可以单独开关各组件:
- 推荐技能图标
- TTD 面板
- 禁用技能显示
- 状态栏

---

## 设置面板

点击「设置」宏或使用 `/run NCFsettings()` 打开设置面板。

### 基础设置

| 设置项 | 说明 |
|--------|------|
| 开启快捷键 | 绑定循环开关的按键 |
| 爆发/划水切换 | 绑定爆发模式切换的按键 |

### 打断设置

| 设置项 | 说明 |
|--------|------|
| 读条剩余 X 秒内打断 | 当敌人读条剩余时间小于此值时打断 |
| 0 = 立即打断 | 设为 0 则立即打断 |

### 自动索敌设置

| 设置项 | 说明 |
|--------|------|
| 启用自动索敌 | 自动切换到最优目标 |
| 检查距离 | 目标超出范围时自动切换 |
| 检查身前 | 目标在身后时自动切换 |
| 自定义范围 | 设置索敌范围 (留空 = 自动判断) |

### 自动喝药设置

| 设置项 | 说明 |
|--------|------|
| 自动喝药阈值 | 血量低于此百分比时自动喝药 |
| 0 = 关闭 | 设为 0 则不自动喝药 |
| 默认值: 35% | 血量 ≤ 35% 时自动使用治疗药水/治疗石 |

### 悬浮面板显示选项

| 选项 | 说明 |
|------|------|
| 状态栏 | 显示/隐藏状态栏 |
| 推荐技能 | 显示/隐藏推荐技能图标 |
| TTD | 显示/隐藏 TTD 面板 |
| 禁用显示 | 显示/隐藏禁用技能列表 |

### 开发者选项

| 选项 | 说明 |
|------|------|
| [dev]聊天框输出释放 | 在聊天框显示每次释放的技能 (调试用) |

---

## 技能模式设置

点击悬浮面板或使用宏打开技能模式设置面板。

### 技能模式

每个技能有三种模式:

| 模式 | 显示 | 说明 |
|------|------|------|
| 正常 (normal) | 绿色边框 | 正常使用 |
| 爆发 (burst) | 橙色边框 | 仅在爆发模式下使用 |
| 禁用 (skip) | 红色边框 | 不使用此技能 |

### 爆发保护 (TTD)

部分爆发技能可以设置 TTD 保护，当目标预估存活时间小于设定值时，不会使用该技能，避免浪费大招。

### 快捷键绑定

每个技能可以单独绑定快捷键:
- **左键点击**: 设置快捷键
- **右键点击**: 清除快捷键
- **按下快捷键**: 切换技能禁用/启用状态

---

## 宏命令

NCF 会自动创建以下宏:

| 宏名称 | 功能 | 命令 |
|--------|------|------|
| NCF | 开关循环 | `/run NCFswitch()` |
| NCF爆发 | 切换爆发/划水模式 | `/run NCFburst()` |
| NCF智能 | 切换智能目标 | `/run NCFsmart()` |
| 设置 | 打开设置面板 | `/run NCFsettings()` |
| 显示Buff | 显示玩家当前 Buff | `/run NCFbuffs()` |
| 显示Debuff | 显示目标当前 Debuff | `/run NCFdebuffs()` |
| NCF插入 | 插入技能到队列 | `/run NCFInsert(技能ID)` |
| NCF队列 | 显示当前插入队列 | `/run NCFQueue()` |
| LR前跳 | 猎人前跳宏 | `/run NCFDisengage()` |

---

## 插入宏 (NCFInsert)

插入宏用于在循环中插入自定义技能，优先级高于循环建议的技能。

### 使用方法

```
/run NCFInsert(技能ID)
```

或使用技能名称:

```
/run NCFInsert("技能名称")
```

### 示例

**插入嗜血:**
```
/run NCFInsert(2825)
```

**插入英勇:**
```
/run NCFInsert("英勇气概")
```

### 查看队列

```
/run NCFQueue()
```

显示当前插入队列中的技能。

### 使用场景

- 需要临时使用某个技能时
- 循环没有自动建议但你想手动触发的技能
- 配合 WeakAura 或其他插件触发

### 注意事项

- 技能必须已就绪 (不在 CD 中)
- 脱战后队列自动清空
- 技能成功施放后自动从队列移除

---

## 猎人前跳宏 (NCFDisengage)

猎人专用宏，实现「前跳」效果。

### 原理

1. 记录当前朝向
2. 瞬间转身 180 度
3. 施放脱离 (Disengage)
4. 瞬间转回原朝向

### 使用方法

创建宏:

```
#showtooltip 脱离
/run NCFDisengage()
```

或英文客户端:

```
#showtooltip Disengage
/run NCFDisengage()
```

### 效果

按下宏后，角色会向前方跳跃，而不是向后跳。

---

## 快捷键设置

### 支持的快捷键格式

| 类型 | 示例 |
|------|------|
| 单个按键 | `F1`, `1`, `X`, `G` |
| 组合键 | `CTRL-1`, `SHIFT-F`, `ALT-X` |
| 多修饰键 | `CTRL-SHIFT-1`, `CTRL-ALT-F` |
| 鼠标按键 | `BUTTON3` (中键), `BUTTON4`, `BUTTON5` |
| 鼠标滚轮 | `MOUSEWHEELUP`, `MOUSEWHEELDOWN` |
| 鼠标组合键 | `CTRL-BUTTON4`, `SHIFT-BUTTON5` |

### 设置方法

1. 点击快捷键按钮
2. 按下想要绑定的按键/组合键
3. 按 ESC 取消
4. 右键点击清除绑定

---

## 职业专精支持

### 当前支持的专精

| 职业 | 专精 |
|------|------|
| 死亡骑士 | 冰霜、邪恶、鲜血 |
| 恶魔猎手 | 浩劫（虚空）|
| 德鲁伊 | 恢复 |
| 猎人 | 野兽控制、生存 |
| 法师 | 奥术 |
| 武僧 | 酒仙 |
| 牧师 | 暗影 |
| 萨满 | 恢复 |
| 术士 | 恶魔 |
| 战士 | 狂怒、防护 |

---

## 常见问题

### Q: 插件没有显示技能提示？

**A:** 检查以下几点:
1. 确保循环已开启（状态栏显示「已开启」）
2. 确保有目标且目标可攻击
3. 确保 `rotations` 文件夹中有对应专精的循环文件
4. 文件命名格式: `职业_专精.lua` (如 `mage_arcane.lua`)

### Q: 某个技能不想自动使用？

**A:** 在技能模式设置中点击该技能图标，切换到红色（禁用）模式

### Q: 爆发技能没有自动使用？

**A:** 检查以下几点:
1. 确保爆发模式已开启（状态栏显示「爆发」）
2. 确保该技能不是红色禁用状态
3. 检查 TTD 保护设置，Boss 血量太低可能触发保护

### Q: 打断时机不对？

**A:** 调整打断设置:
- 数值越大，打断越早
- 数值越小，打断越晚
- 设为 0 表示立即打断

### Q: 如何强制使用某个技能？

**A:** 使用插入宏:
```
/run NCFInsert(技能ID)
```
技能ID可以在 Wowhead 等网站查询

### Q: 悬浮面板位置怎么保存？

**A:** 拖动面板到想要的位置后，位置会自动保存。

### Q: 猎人前跳宏不生效？

**A:** 确保:
1. 使用 `/run NCFDisengage()` 而不是 `/cast 脱离`
2. 脱离技能不在 CD 中
3. 角色没有被控制

---

## 自定义循环 (编写你自己的循环)

你可以为任何职业/专精编写自己的循环文件，放入 `rotations/` 文件夹即可自动加载。

### 文件命名规则

文件名格式：`职业_专精.lua`（全小写英文）

| 职业 | classFile | 专精1 | 专精2 | 专精3 |
|------|-----------|-------|-------|-------|
| 战士 | WARRIOR | warrior_arms | warrior_fury | warrior_protection |
| 圣骑士 | PALADIN | paladin_holy | paladin_protection | paladin_retribution |
| 猎人 | HUNTER | hunter_beastmastery | hunter_marksmanship | hunter_survival |
| 盗贼 | ROGUE | rogue_assassination | rogue_outlaw | rogue_subtlety |
| 牧师 | PRIEST | priest_discipline | priest_holy | priest_shadow |
| 死亡骑士 | DEATHKNIGHT | deathknight_blood | deathknight_frost | deathknight_unholy |
| 萨满 | SHAMAN | shaman_elemental | shaman_enhancement | shaman_restoration |
| 法师 | MAGE | mage_arcane | mage_fire | mage_frost |
| 术士 | WARLOCK | warlock_affliction | warlock_demonology | warlock_destruction |
| 武僧 | MONK | monk_brewmaster | monk_mistweaver | monk_windwalker |
| 德鲁伊 | DRUID | druid_balance | druid_feral | druid_guardian | druid_restoration (spec 4) |
| 恶魔猎手 | DEMONHUNTER | demonhunter_havoc | demonhunter_vengeance | — |
| 唤魔师 | EVOKER | evoker_devastation | evoker_preservation | evoker_augmentation |

---

### 完整循环模板

```lua
--============================================================
-- 职业名 专精名 Rotation
-- Version 1.0
--============================================================

--============================================================
-- 1. 注册技能 (必须在文件顶部)
-- 规则: Burst 技能放最前面; 技能名使用中文
--============================================================
NCF.RegisterSpells("CLASS", specIndex, {
    -- Burst 技能 (爆发模式才用)
    { id = 12345, name = "爆发技能名", default = "burst" },

    -- 普通技能
    { id = 11111, name = "主要输出技能", default = "normal" },
    { id = 22222, name = "填充技能",     default = "normal" },
    { id = 33333, name = "打断技能",     default = "normal" },
})

--============================================================
-- 2. 技能 ID 定义
--============================================================
local SPELL = {
    MainNuke  = 11111,
    Filler    = 22222,
    Interrupt = 33333,
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
-- 3. 局部化 Helper 函数 (提升性能)
--============================================================
local HasBuff               = NCF.HasBuff
local HasDebuff             = NCF.HasDebuff
local HasTalent             = NCF.HasTalent
local GetBuffRemain         = NCF.GetBuffRemain
local GetBuffStacks         = NCF.GetBuffStacks
local GetDebuffRemain       = NCF.GetDebuffRemain
local GetDebuffStacks       = NCF.GetDebuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges       = NCF.GetSpellCharges
local GetActiveEnemyAmount  = NCF.GetActiveEnemyAmount
local GetUnitHealthPct      = NCF.GetUnitHealthPct
local GetUnitPower          = NCF.GetUnitPower
local ShouldSkipSpell       = NCF.ShouldSkipSpell
local SetEnemyCount         = NCF.SetEnemyCount
local IsSpellReady          = NCF.IsSpellReady

--============================================================
-- 4. 主循环
--============================================================
local function CreateRotation()

    local function Rotation()
        -- 刷新 GCD
        NCF.RefreshGCD()
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)

        -- 移动检测
        local isMoving = GetUnitSpeed("player") > 0

        -- 敌人数量 (必须在开头更新)
        local enemyCount = GetActiveEnemyAmount(40, true)
        SetEnemyCount(enemyCount)

        -- 局部 IsReady
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end

        -- 天赋检查
        local hasSomeTalent = HasTalent(TALENT.SomeTalent)

        -- Buff/Debuff 检查
        local hasProcBuff = HasBuff(BUFF.ProcBuff, "player")
        local dotRemain   = GetDebuffRemain(DEBUFF.MyDot, "target")

        -- 血量
        local playerHP = GetUnitHealthPct("player")
        local targetHP = GetUnitHealthPct("target")

        --======================================================
        -- 优先级 1: 打断 (始终最高优先级)
        --======================================================
        if IsReady(SPELL.Interrupt) and not ShouldSkipSpell(SPELL.Interrupt) then
            local target = NCF.GetInterruptTarget(10, false)
            if target then
                return "spell", SPELL.Interrupt, target
            end
        end

        --======================================================
        -- 优先级 2: 战斗前 (Buff 维护等)
        --======================================================
        -- 示例: 如果有需要在战斗外维护的 Buff 放这里

        --======================================================
        -- 优先级 3: 战斗检查
        --======================================================
        local inCombat = UnitAffectingCombat("player")
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not inCombat and not targetInCombat then
            return "spell", 61304  -- GCD 占位，不在战斗中
        end

        --======================================================
        -- 优先级 4: 爆发/饰品 (仅爆发模式)
        -- 规则: 必须同时满足 burstModeEnabled + 至少一个具体状态条件
        --       不能只判断 burstModeEnabled 就触发饰品/药水
        --======================================================
        local isBigCooldownReady = IsReady(SPELL.BigCooldown) and not ShouldSkipSpell(SPELL.BigCooldown)
        if NCF.burstModeEnabled and isBigCooldownReady then
            NCF.UseTrinket()
            if NCF.enablePotion then NCF.UseCombatPotion() end
            return "spell", SPELL.BigCooldown
        end

        --======================================================
        -- 优先级 5: AOE (多目标，写在 ST 之前)
        --======================================================
        if enemyCount >= 3 then
            -- 在这里写 AOE 逻辑
            -- 示例:
            -- if IsReady(SPELL.AOESpell) and not ShouldSkipSpell(SPELL.AOESpell) then
            --     return "spell", SPELL.AOESpell
            -- end
        end

        --======================================================
        -- 优先级 6: 单目标 (ST)
        --======================================================

        -- DoT 维护
        if dotRemain < 2 and IsReady(SPELL.MainNuke) and not ShouldSkipSpell(SPELL.MainNuke) then
            return "spell", SPELL.MainNuke
        end

        -- Proc 消耗
        if hasProcBuff and IsReady(SPELL.MainNuke) and not ShouldSkipSpell(SPELL.MainNuke) then
            return "spell", SPELL.MainNuke
        end

        -- 填充
        if not isMoving and IsReady(SPELL.Filler) and not ShouldSkipSpell(SPELL.Filler) then
            return "spell", SPELL.Filler
        end

        --======================================================
        -- 移动填充 (最低优先级)
        --======================================================
        -- if isMoving and IsReady(SPELL.InstantFiller) and not ShouldSkipSpell(SPELL.InstantFiller) then
        --     return "spell", SPELL.InstantFiller
        -- end

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
| 技能名使用中文 | `RegisterSpells` 中的 `name` 字段必须是中文，显示在 UI 面板上 |
| Burst 技能放最前 | `RegisterSpells` 列表中，`default = "burst"` 的技能写在最上方 |
| 必须检查 ShouldSkipSpell | 每个技能判断前必须加 `not ShouldSkipSpell(spellID)`，否则禁用/爆发保护不生效 |
| 局部化 NCF 函数 | 在 `CreateRotation()` 外面用 `local X = NCF.X` 局部化，提升性能 |
| 局部 IsReady | 在 `Rotation()` 内定义 `local function IsReady(id) return GetSpellCooldownRemain(id) <= gcd end` |
| 打断最优先 | `GetInterruptTarget` 检查放在 `Rotation()` 最顶部 |
| AOE 在 ST 之前 | 多目标分支写在单目标分支之前 |
| 移动填充最后 | 移动时的技能放在分支末尾 |

---

### 返回值格式

| 格式 | 说明 | 示例 |
|------|------|------|
| `return "spell", spellID` | 对当前目标施法 | `return "spell", SPELL.Fireball` |
| `return "spell", spellID, unit` | 对指定单位施法 | `return "spell", SPELL.Kick, interruptTarget` |
| `return "InstantSpell", spellID, unit` | 瞬发技能（自动面朝） | `return "InstantSpell", SPELL.KillCommand, bestTarget` |
| `return "castselflocation", spellID` | 在玩家位置施放地面技能 | `return "castselflocation", SPELL.DeathAndDecay` |
| `return nil` | 本帧无建议技能 | — |

---

### Helper 函数完整参考

> 在循环文件中先局部化再使用（`local HasBuff = NCF.HasBuff`），直接调用 `NCF.X` 也可以。

---

#### Buff / Debuff

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.HasBuff(spellId, unit)` | unit 默认 `"player"` | boolean |
| `NCF.GetBuffRemain(spellId, unit)` | unit 默认 `"player"` | 剩余秒数，无则 0，永久则 999 |
| `NCF.GetBuffStacks(spellId, unit)` | unit 默认 `"player"` | 层数，无则 0 |
| `NCF.HasDebuff(spellId, unit)` | unit 默认 `"target"` | boolean |
| `NCF.GetDebuffRemain(spellId, unit)` | unit 默认 `"target"` | 剩余秒数，无则 0，永久则 999 |
| `NCF.GetDebuffStacks(spellId, unit)` | unit 默认 `"target"` | 层数，无则 0 |

---

#### 技能冷却与充能

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.RefreshGCD()` | 无（每帧开头必须调用） | 更新 `NCF.gcd_max` |
| `NCF.IsSpellReady(spellId)` | — | boolean，冷却 ≤ GCD 视为可用 |
| `NCF.GetSpellCooldownRemain(spellId)` | — | 剩余 CD 秒数，0 = 可用 |
| `NCF.GetSpellCharges(spellId)` | — | 充能数（含小数，如 `1.5` 表示恢复中） |
| `NCF.GetSpellChargeInfo(spellId)` | — | 表：`{currentCharges, maxCharges, cooldownStartTime, cooldownDuration, chargeModRate}` |
| `NCF.IsSpellInRange(spellId, unit)` | unit 默认 `"target"` | boolean，含视线（LoS）检查 |

---

#### 资源

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetUnitPower(unit, powerType)` | powerType 字符串（见下表） | 当前资源值 |
| `NCF.GetUnitPowerMax(unit, powerType)` | 同上 | 最大资源值 |
| `NCF.GetSpellCostByType(spellId, powerType)` | powerType 为 `Enum.PowerType.X` | 技能消耗量，无则 nil |

**powerType 字符串列表：**

| 字符串 | 资源类型 |
|--------|---------|
| `"energy"` | 能量（盗贼/武僧/猫德） |
| `"rage"` | 怒气（战士/熊德） |
| `"focus"` | 集中值（猎人） |
| `"runicpower"` | 符能（死亡骑士） |
| `"mana"` | 法力 |
| `"combopoints"` | 连击点（盗贼） |
| `"runes"` | 符文（死骑，返回可用数量 0-6） |
| `"soulshards"` | 灵魂碎片（术士） |
| `"holypower"` | 圣能（圣骑士） |
| `"maelstrom"` | 漩涡值（萨满） |
| `"chi"` | 真气（武僧） |
| `"insanity"` | 狂乱值（暗牧） |
| `"arcanecharges"` | 奥术充能（奥法） |
| `"fury"` | 怒火（恶魔猎手） |
| `"pain"` | 痛苦（复仇恶魔猎手） |
| `"essence"` | 精华（唤魔师） |

---

#### 血量

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetUnitHealthPct(unit)` | `"player"`, `"target"`, `"party1"` 等 | 血量百分比 0-100 |
| `NCF.GetTargetHealthPct()` | 无（等同于 `GetUnitHealthPct("target")`） | 目标血量百分比 |
| `NCF.GetUnitHealth(unit)` | — | 当前血量（原始值） |
| `NCF.GetUnitHealthMax(unit)` | — | 最大血量（原始值） |

---

#### 敌人检测

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetActiveEnemyAmount(range, needFront)` | `needFront=true` 只算身前 180° | `count, guid1, guid2, ...`（GUID 可直接当 unit 用） |
| `NCF.GetEnemyCount()` | 无 | 上次 `SetEnemyCount` 存储的值 |
| `NCF.SetEnemyCount(count)` | 无返回（每帧开头更新） | — |
| `NCF.GetEnemyWithoutDebuff(debuffId, range, needFront, spellId)` | spellId 可选，用于射程检查 | 第一个没有该 Debuff 的敌人 unit，或 nil |
| `NCF.GetEnemyWithDebuff(debuffId, range, needFront, spellId)` | 同上 | 第一个有该 Debuff 的敌人 unit，或 nil |
| `NCF.GetBestAOETarget(range, searchRange, needFront, spellId)` | range=爆炸半径，searchRange=搜索半径 | 周围敌人最多的目标 unit，或 nil |
| `NCF.GetInterruptTarget(range, needFront, remainTime)` | remainTime: 秒数或百分比（≤1），有焦点时优先焦点 | 可打断的目标 unit，或 nil |

---

#### 位置与朝向

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetDistanceToTarget(unit)` | unit 默认 `"target"`，减去双方战斗距离 | 有效距离（码） |
| `NCF.IsUnitInFront(unit)` | — | boolean，是否在玩家身前 180° |

---

#### 战斗状态

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetCombatTime()` | 无 | 当前战斗持续时间（秒），脱战时 0 |
| `NCF.GetTimeSinceCast(spellId)` | — | 上次成功释放该技能后经过的秒数，从未释放返回 999 |
| `NCF.HasTalent(talentId)` | — | boolean |
| `NCF.IsStealthed()` | 无 | boolean，检查潜行/消失/暗影之舞等 |
| `NCF.GetPetExists()` | 无 | boolean |
| `NCF.IsInBossFight()` | 无 | boolean，通过 boss1-5 框架判断 |

---

#### TTD（目标存活时间）

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetMaxTTD(range)` | range 默认 40 码 | 范围内最长 TTD 秒数（训练假人返回 120） |
| `NCF.MeetsTTDRequirement(minTime)` | — | boolean，Boss 战直接 true，否则判断 TTD > minTime |
| `NCF.GetSpellTTD(spellId)` | — | 该技能在设置面板配置的 TTD 要求（秒），0 = 不检查 |
| `NCF.MeetsSpellTTD(spellId)` | — | boolean，综合 GetSpellTTD + MeetsTTDRequirement |

---

#### 模式判断

| 函数 / 变量 | 说明 |
|------------|------|
| `NCF.ShouldSkipSpell(spellId)` | 是否应跳过：disabled 模式 或 burst 技能但当前平缓模式 |
| `NCF.burstModeEnabled` | boolean，当前是否爆发模式 |
| `NCF.enablePotion` | boolean，是否使用战斗药水 |

---

#### 治疗辅助（适用于治疗循环）

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.GetGroupMembers()` | 无 | `{"player","party1",...}` 或 `{"raid1",...}`，过滤死亡/离线 |
| `NCF.GetGroupAverageHealthPct(range, count)` | range 可选距离限制；count 取血量最低的 N 人算均值 | 平均血量百分比 |
| `NCF.GetLowestHealthMember(range, threshold, spellId)` | threshold 默认 100；spellId 可选用于射程检查 | `unit, healthPct`，无则 `nil, 100` |
| `NCF.GetTankUnit()` | 无 | 队伍中第一个存活的 TANK 角色 unit，或 nil |
| `NCF.GetDispellableUnit(dispelType, range, checkEnemy)` | dispelType 可为字符串或数组；checkEnemy=true 时扫描敌方 buff | 可驱散的目标 unit，或 nil |

**dispelType 可选值：**
- 友方 Debuff 驱散：`"Curse"`, `"Poison"`, `"Magic"`, `"Disease"`
- 敌方 Buff 驱散（checkEnemy=true）：`"Enrage"`, `"Magic"`
- 多类型传数组：`{"Curse", "Poison"}`

---

#### 饰品、药水与施法辅助

| 函数 | 参数说明 | 返回值 |
|------|---------|--------|
| `NCF.UseTrinket()` | 无 | boolean，优先 slot13，CD 则用 slot14 |
| `NCF.UseCombatPotion()` | 无 | boolean，使用背包中的战斗药水 |
| `NCF.GetRacialSpell()` | 无 | 当前种族的爆发技能 ID，无则 nil |
| `NCF.CastWithFacing(spellName, target)` | target 默认 `"target"`；施法前自动转向，施法后转回 | — |

---

### 如何获取技能 ID

1. 打开 [Wowhead](https://www.wowhead.com)，搜索技能名
2. URL 中的数字即为技能 ID（如 `spell=116` 中的 `116`）
3. 游戏内使用 `/run print(select(7, GetSpellInfo("技能名")))` 查询

### 如何调试

```
-- 查看当前 Buff
/run NCFbuffs()

-- 查看目标 Debuff
/run NCFdebuffs()

-- 开启聊天框输出释放技能 (设置面板 -> [dev]聊天框输出释放)
```

---

## 循环文件结构 (简版参考，完整示例见上方模板)

---

## 更新日志

### v12.0
- 支持组合快捷键 (CTRL/SHIFT/ALT + 按键)
- 支持鼠标按键绑定 (BUTTON3/4/5)
- 支持鼠标滚轮绑定
- 优化打断系统
- 新增悬浮面板组件开关
- 新增 TTD 保护功能
- 新增自动喝药功能
- 新增多个职业循环
- 修复配置保存问题
- 优化 UI 界面

---

**祝游戏愉快！**