--============================================================
-- 刺杀盗贼循环 (Assassination Rogue APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

=== 脱战准备 ===
- 潜行 (1784): 脱战自动潜行

=== 打断 ===
- 脚踢 (1766): 5码, 需面朝

=== 冷却技能 ===
1. 死亡印记 (360194): 绞喉&割裂在目标上 且 弑君CD<=2 且 有毒伤buff
2. 饰品/药水/种族: 弑君debuff在目标上 (爆发模式)
3. 弑君 (385627): 绞喉&割裂在目标上 且 (死亡印记在目标上 或 死亡印记CD>52)
4. 消失 (1856)(单体): 单目标 且 有强化绞喉天赋 且 死亡印记未就绪
5. 消失 (1856)(AOE): 多目标 且 有强化绞喉天赋

=== 蓟茶 ===
- 蓟茶 (381623): 能量<50% 且 战斗即将结束 (TTD<10)

=== 核心DoT ===
1. 绞喉 (703)(强化): 有强化绞喉buff或潜行 且 绞喉剩余<=宽松阈值
2. 绞喉 (703)(普通): 连击点缺口>=1 且 可刷新 且 TTD>12
3. 割裂 (1943): 连击点>=5 且 可刷新 且 TTD>12 且 (无至暗之夜buff 或 割裂未激活)

=== 攒连击点 (generate) ===
条件: 连击点未满 或 (猩红风暴天赋 且 敌人>=5 且 DoT未铺满)
1. 猩红风暴 (1247227): 多目标 且 有目标缺少DoT
2. 毒刃 (5938): 至暗之夜buff 且 连击点缺口=1 且 敌人<=3 且 有剧毒短刺天赋
3. 伏击 (8676): 敌人<=1+盲区天赋 且 (潜行 或 盲区buff)
4. 毁伤 (1329): 敌人<=1+盲区天赋
5. 刀扇 (51723): 敌人>1+盲区天赋

=== 花连击点 (spend) ===
条件: 连击点已满
1. 毒伤 (32645): 无情猎手层数<4
2. 毒伤 (32645): 能量>70%

Buff ID 参考:
- 毒伤: 32645
- 至暗之夜: 457280
- 强化绞喉: 392403
- 盲区: 121153
- 无情猎手: 0 (TODO: 需要ID)

Debuff ID 参考:
- 绞喉: 703
- 割裂: 1943
- 死亡印记: 360194
- 弑君: 385627

天赋 ID 参考:
- 强化绞喉: 381632
- 锋线: 0 (TODO: 需要ID)
- 剧毒短刺: 0 (TODO: 需要ID)
- 盲区: 0 (TODO: 需要ID)
- 猩红风暴: 0 (TODO: 需要ID)
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("ROGUE", 1, {
    -- 冷却技能
    { id = 1856, name = "消失", default = "burst" },
    { id = 360194, name = "死亡印记", default = "burst" },
    { id = 385627, name = "弑君", default = "burst" },

    -- 普通技能
    { id = 1784, name = "潜行", default = "normal" },
    { id = 1329, name = "毁伤", default = "normal" },
    { id = 8676, name = "伏击", default = "normal" },
    { id = 32645, name = "毒伤", default = "normal" },
    { id = 1943, name = "割裂", default = "normal" },
    { id = 703, name = "绞喉", default = "normal" },
    { id = 51723, name = "刀扇", default = "normal" },
    { id = 1247227, name = "猩红风暴", default = "normal" },
    { id = 5938, name = "毒刃", default = "normal" },
    { id = 381623, name = "蓟茶", default = "normal" },
    { id = 1766, name = "脚踢", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Stealth = 1784,           -- 潜行
    Kick = 1766,              -- 脚踢
    Mutilate = 1329,          -- 毁伤
    Ambush = 8676,            -- 伏击
    Envenom = 32645,          -- 毒伤
    Rupture = 1943,           -- 割裂
    Garrote = 703,            -- 绞喉
    FanOfKnives = 51723,      -- 刀扇
    Vanish = 1856,            -- 消失
    Deathmark = 360194,       -- 死亡印记
    Kingsbane = 385627,       -- 弑君
    ThistleTea = 381623,      -- 蓟茶
    Shiv = 5938,              -- 毒刃
    CrimsonTempest = 1247227, -- 猩红风暴
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    ImprovedGarrote = 381632, -- 强化绞喉
    RazorWire = 0,            -- 锋线 (TODO: 需要ID)
    ToxicStiletto = 0,        -- 剧毒短刺 (TODO: 需要ID)
    Blindside = 0,            -- 盲区 (TODO: 需要ID)
    CrimsonTempest = 0,       -- 猩红风暴 (TODO: 需要ID)
}

--============================================================
-- 4. Buff ID定义
--============================================================
local BUFF = {
    Envenom = 32645,          -- 毒伤
    DarkestNight = 457280,    -- 至暗之夜
    ImprovedGarrote = 392403, -- 强化绞喉
    Blindside = 121153,       -- 盲区
    ImplacableTracker = 0,    -- 无情猎手 (TODO: 需要ID)
}

--============================================================
-- 5. Debuff ID定义
--============================================================
local DEBUFF = {
    Garrote = 703,            -- 绞喉
    Rupture = 1943,           -- 割裂
    Deathmark = 360194,       -- 死亡印记
    Kingsbane = 385627,       -- 弑君
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffRemain = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local IsStealthed = NCF.IsStealthed
local GetUnitPower = NCF.GetUnitPower
local GetUnitPowerMax = NCF.GetUnitPowerMax

local function GetComboPoints()
    return GetUnitPower("player", "combopoints")
end

local function GetEnergyPct()
    local energy = GetUnitPower("player", "energy") or 0
    local maxEnergy = GetUnitPowerMax("player", "energy") or 100
    return (energy / maxEnergy) * 100
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateAssassinationRotation()

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)

        -- 获取 GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)

        -- 获取资源
        local cp = GetComboPoints()
        local hasDarkestNight = HasBuff(BUFF.DarkestNight, "player")
        local maxCP = hasDarkestNight and 7 or 5
        local cpDeficit = maxCP - cp

        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end

        -- 常用状态缓存
        local inCombat = UnitAffectingCombat("player")
        local singleTarget = enemyCount <= 1
        local hasGarrote = HasDebuff(DEBUFF.Garrote, "target")
        local hasRupture = HasDebuff(DEBUFF.Rupture, "target")
        local hasDeathmark = HasDebuff(DEBUFF.Deathmark, "target")
        local hasEnvenomBuff = HasBuff(BUFF.Envenom, "player")
        local hasImprovedGarrote = HasBuff(BUFF.ImprovedGarrote, "player")
        local implacableStacks = GetBuffStacks(BUFF.ImplacableTracker, "player")
        local deathmarkCD = GetSpellCooldownRemain(SPELL.Deathmark)
        local kingsbaneCD = GetSpellCooldownRemain(SPELL.Kingsbane)
        local garroteRemain = GetDebuffRemain(DEBUFF.Garrote, "target")
        local ruptureRemain = GetDebuffRemain(DEBUFF.Rupture, "target")
        local hasBlindsideTalent = HasTalent(TALENT.Blindside)
        local blindsideValue = hasBlindsideTalent and 1 or 0

        -- 绞喉刷新阈值: 基础18秒的30% = 5.4秒, 有锋线天赋+6秒 → 24秒的30% = 7.2秒
        local garroteRefresh = HasTalent(TALENT.RazorWire) and 7.2 or 5.4
        -- 割裂刷新阈值: 5连击点 = 24秒的30% = 7.2秒
        local ruptureRefresh = 7.2

        --==========================================================
        -- 脱战准备: 自动潜行
        --==========================================================
        if not inCombat and not IsMounted() and not IsStealthed()
            and not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            if IsReady(SPELL.Stealth) and not ShouldSkipSpell(SPELL.Stealth) then
                return "spell", SPELL.Stealth
            end
        end

        -- 以下需要战斗中才执行 (自己/目标/队友任一在战斗中)
        if not inCombat and not NCF.IsInCombat() then
            return "spell", 61304
        end

        --==========================================================
        -- 打断: 脚踢 5码 不需要面朝
        --==========================================================
        if IsReady(SPELL.Kick) and not ShouldSkipSpell(SPELL.Kick) then
            local interruptTarget = NCF.GetInterruptTarget(5, false)
            if interruptTarget then
                return "InstantSpell", SPELL.Kick, interruptTarget
            end
        end

        --==========================================================
        -- 冷却技能 (cooldowns)
        --==========================================================

        -- 1. 死亡印记: 绞喉&割裂在目标上 且 弑君CD<=2 且 有毒伤buff
        if hasGarrote and hasRupture and kingsbaneCD <= 2 and hasEnvenomBuff
            and IsReady(SPELL.Deathmark) and not ShouldSkipSpell(SPELL.Deathmark) then
            return "spell", SPELL.Deathmark
        end

        -- 2. 饰品/药水/种族: 弑君debuff在目标上 (爆发模式)
        if NCF.burstModeEnabled and HasDebuff(DEBUFF.Kingsbane, "target") then
            NCF.UseTrinket()
            if NCF.enablePotion then
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end

        -- 3. 弑君: 绞喉&割裂在目标上 且 (死亡印记在目标上 或 死亡印记CD>52)
        if hasGarrote and hasRupture and (hasDeathmark or deathmarkCD > 52)
            and IsReady(SPELL.Kingsbane) and not ShouldSkipSpell(SPELL.Kingsbane) then
            return "spell", SPELL.Kingsbane
        end

        -- 4/5. 消失: 非潜行 且 有强化绞喉天赋
        if not IsStealthed() and HasTalent(TALENT.ImprovedGarrote) then
            -- 单体: 死亡印记未就绪 (维护强化绞喉到下个爆发窗口)
            if singleTarget and not IsReady(SPELL.Deathmark)
                and IsReady(SPELL.Vanish) and not ShouldSkipSpell(SPELL.Vanish) then
                return "spell", SPELL.Vanish
            end
            -- AOE: 多目标传播强化绞喉
            if not singleTarget
                and IsReady(SPELL.Vanish) and not ShouldSkipSpell(SPELL.Vanish) then
                return "spell", SPELL.Vanish
            end
        end

        --==========================================================
        -- 蓟茶: 能量<50% 且 战斗即将结束 (TTD<10)
        --==========================================================
        if GetEnergyPct() < 50 and NCF.GetMaxTTD() < 10
            and IsReady(SPELL.ThistleTea) and not ShouldSkipSpell(SPELL.ThistleTea) then
            return "spell", SPELL.ThistleTea
        end

        --==========================================================
        -- 核心 DoT 维护
        --==========================================================

        -- 1. 绞喉 (强化): 有强化绞喉buff或潜行
        --    宽松阈值: 14 + 6*锋线 + 4*多目标 (基本上总是重新打)
        if (hasImprovedGarrote or IsStealthed()) and not ShouldSkipSpell(SPELL.Garrote) then
            local improvedThreshold = 14 + (HasTalent(TALENT.RazorWire) and 6 or 0) + (singleTarget and 0 or 4)
            if garroteRemain <= improvedThreshold then
                return "spell", SPELL.Garrote
            end
        end

        -- 2. 绞喉 (普通): 连击点缺口>=1 且 可刷新 且 TTD>12
        if cpDeficit >= 1 and garroteRemain < garroteRefresh
            and NCF.GetMaxTTD() > 12
            and not ShouldSkipSpell(SPELL.Garrote) then
            return "spell", SPELL.Garrote
        end

        -- 3. 割裂: 连击点>=5 且 可刷新 且 TTD>12 且 (无至暗之夜 或 割裂未激活)
        if cp >= 5 and ruptureRemain < ruptureRefresh
            and NCF.GetMaxTTD() > 12
            and (not hasDarkestNight or not hasRupture)
            and not ShouldSkipSpell(SPELL.Rupture) then
            return "spell", SPELL.Rupture
        end

        --==========================================================
        -- 攒连击点 (generate)
        --==========================================================
        -- 条件: 连击点未满 或 (猩红风暴天赋 且 敌人>=5 且 DoT未铺满)
        local needGenerate = (not hasDarkestNight and cp < 5) or (hasDarkestNight and cpDeficit > 0)
        local needSpreadDots = HasTalent(TALENT.CrimsonTempest) and enemyCount >= 5
            and (NCF.GetEnemyWithoutDebuff(DEBUFF.Garrote, 10, false) or NCF.GetEnemyWithoutDebuff(DEBUFF.Rupture, 10, false))

        if needGenerate or needSpreadDots then
            -- 1. 猩红风暴: 多目标 且 有目标缺少DoT
            if not singleTarget
                and (NCF.GetEnemyWithoutDebuff(DEBUFF.Garrote, 10, false) or NCF.GetEnemyWithoutDebuff(DEBUFF.Rupture, 10, false))
                and IsReady(SPELL.CrimsonTempest) and not ShouldSkipSpell(SPELL.CrimsonTempest) then
                return "spell", SPELL.CrimsonTempest
            end

            -- 2. 毒刃: 至暗之夜buff 且 连击点缺口=1 且 敌人<=3 且 有剧毒短刺天赋
            if hasDarkestNight and cpDeficit == 1 and enemyCount <= 3
                and HasTalent(TALENT.ToxicStiletto)
                and IsReady(SPELL.Shiv) and not ShouldSkipSpell(SPELL.Shiv) then
                return "spell", SPELL.Shiv
            end

            -- 3. 伏击: 敌人<=1+盲区天赋 且 (潜行 或 有盲区buff)
            if enemyCount <= 1 + blindsideValue
                and (IsStealthed() or HasBuff(BUFF.Blindside, "player"))
                and IsReady(SPELL.Ambush) and not ShouldSkipSpell(SPELL.Ambush) then
                return "spell", SPELL.Ambush
            end

            -- 4. 毁伤: 敌人<=1+盲区天赋
            if enemyCount <= 1 + blindsideValue
                and IsReady(SPELL.Mutilate) and not ShouldSkipSpell(SPELL.Mutilate) then
                return "spell", SPELL.Mutilate
            end

            -- 5. 刀扇: 敌人>1+盲区天赋
            if enemyCount > 1 + blindsideValue
                and IsReady(SPELL.FanOfKnives) and not ShouldSkipSpell(SPELL.FanOfKnives) then
                return "spell", SPELL.FanOfKnives
            end
        end

        --==========================================================
        -- 花连击点 (spend)
        --==========================================================
        -- 条件: 连击点已满
        local canSpend = (not hasDarkestNight and cp >= 5) or (hasDarkestNight and cpDeficit == 0)

        if canSpend then
            -- 1. 毒伤: 无情猎手层数<4
            if implacableStacks < 4
                and IsReady(SPELL.Envenom) and not ShouldSkipSpell(SPELL.Envenom) then
                return "spell", SPELL.Envenom
            end

            -- 2. 毒伤: 能量>70%
            if GetEnergyPct() > 70
                and IsReady(SPELL.Envenom) and not ShouldSkipSpell(SPELL.Envenom) then
                return "spell", SPELL.Envenom
            end
        end

        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateAssassinationRotation()
