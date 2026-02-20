--============================================================
-- 血死亡骑士循环 (Blood Death Knight APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--
-- 英雄树分支:
-- - 死神 (439843): 已实现
-- - 圣血 (433901): 已实现
--============================================================

--[[
===================================
优先级列表
===================================

=== 通用 ===
0.  打断 - 心灵冰冻 (47528): 15码
0.1 复活亡者 (46585): 宠物不存在
--- 以下需要战斗中 ---

=== 高优先级 (high_prio_actions) ===
1. 灵界打击: 凝血症buff剩余<=GCD
2. 符文武器舞

=== 主循环 ===
- 种族技能/药水 (符文武器舞期间)
- 吸血之血 (无buff时)
- → 分支判断

=== 死神分支 (deathbringer) ===
1. 灵界打击: 符能缺口<20 或 (符能缺口<26且DRW激活)
2. 收割者印记
3. 血沸: DRW激活 且 目标无血瘟
4. 枯萎凋零: 无buff
5. 骨髓裂击: 灭绝buff 或 白骨<5层
6. 灵界打击
7. 鲜血吞噬
8. 血沸
9. 心脏打击: 凝血症<5层
10. 心脏打击

=== 圣血DRW分支 (san_drw) ===
1. 心脏打击: 血女王精华剩余<1.5秒且存在
2. 灵界打击: 符能缺口<36
3. 血沸: 目标无血瘟
4. 枯萎凋零: (敌人<=3且血红天灾) 或 (敌人>3且无DND)
5. 心脏打击
6. 灵界打击
7. 鲜血吞噬
8. 血沸

=== 圣血分支 (sanlayn) ===
1. 血沸: 白骨不足 且 敌人>=2
2. 死亡爱抚: 白骨不足
3. 血沸: 血瘟剩余<3秒
4. 心脏打击: 血女王精华剩余<1.5秒且存在 且 吸血打击触发
5. 灵界打击: 符能缺口<20
6. 鲜血吞噬: DND buff存在
7. 心脏打击: 吸血打击触发 且 DND buff存在
8. 血沸: 白骨<6层 且 敌人>=2
9. 死亡爱抚: 白骨<6层
10. 骨髓裂击: 白骨<6层
11. 枯萎凋零: (敌人<=3且血红天灾) 或 (敌人>3且无DND)
12. 心脏打击: 吸血打击触发
13. 灵界打击
14. 心脏打击: 符文>=2
15. 鲜血吞噬
16. 血沸
17. 心脏打击

===================================
Buff/Debuff ID 参考
===================================
Buff:
- 符文武器舞: 81256
- 吸血之血: 55233
- 白骨护盾: 195181
- 枯萎凋零: 188290
- 凝血症: 391481
- 血红天灾: 81141
- 灭绝: 441416 (死神)
- 血女王精华: 433925 (圣血)

Debuff:
- 血之瘟疫: 55078

天赋/英雄树:
- 死神: 439843
- 圣血: 433901
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("DEATHKNIGHT", 1, {
    -- 冷却技能
    { id = 49028, name = "符文武器舞", default = "burst" },
    { id = 55233, name = "吸血之血", default = "normal" },
    { id = 439843, name = "收割者印记", default = "burst" },
    
    -- 普通技能
    { id = 49998, name = "灵界打击", default = "normal" },
    { id = 206930, name = "心脏打击", default = "normal" },
    { id = 195182, name = "骨髓裂击", default = "normal" },
    { id = 50842, name = "血沸", default = "normal" },
    { id = 43265, name = "枯萎凋零", default = "normal" },
    { id = 1263824, name = "鲜血吞噬", default = "normal" },
    { id = 195292, name = "死亡爱抚", default = "normal" },
    { id = 46585, name = "复活亡者", default = "normal" },
    { id = 47528, name = "心灵冰冻", default = "normal" },
    { id = 61999, name = "复活盟友", default = "normal" },
    { id = 49039, name = "巫妖之躯", default = "normal" },
    { id = 48792, name = "冰封之韧", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    DeathStrike = 49998,           -- 灵界打击 (40符能)
    HeartStrike = 206930,          -- 心脏打击 (1符文)
    Marrowrend = 195182,           -- 骨髓裂击 (2符文)
    BloodBoil = 50842,             -- 血沸
    DeathAndDecay = 43265,         -- 枯萎凋零 (1符文, 血红天灾免费)
    Consumption = 1263824,         -- 鲜血吞噬
    DancingRuneWeapon = 49028,     -- 符文武器舞
    VampiricBlood = 55233,         -- 吸血之血
    RaiseDead = 46585,             -- 复活亡者
    DeathsCaress = 195292,         -- 死亡爱抚
    ReapersMark = 439843,          -- 收割者印记
    MindFreeze = 47528,            -- 心灵冰冻
    RaiseAlly = 61999,             -- 复活盟友 (30符能)
    Lichborne = 49039,             -- 巫妖之躯
    IceboundFortitude = 48792,     -- 冰封之韧
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    Deathbringer = 439843,         -- 死神
    Sanlayn = 433901,              -- 圣血
    Consumption = 1263824,         -- 鲜血吞噬
}

--============================================================
-- 4. Buff ID定义
--============================================================
local BUFF = {
    DancingRuneWeapon = 81256,     -- 符文武器舞
    VampiricBlood = 55233,         -- 吸血之血
    BoneShield = 195181,           -- 白骨护盾
    DeathAndDecay = 188290,        -- 枯萎凋零
    Coagulopathy = 391481,         -- 凝血症
    CrimsonScourge = 81141,        -- 血红天灾
    Exterminate = 441416,          -- 灭绝 (死神)
    EssenceOfTheBloodQueen = 433925, -- 血女王精华 (圣血)
}

--============================================================
-- 5. Debuff ID定义
--============================================================
local DEBUFF = {
    BloodPlague = 55078,           -- 血之瘟疫
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffRemain = NCF.GetBuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffRemain = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetPetExists = NCF.GetPetExists
local GetUnitPower = NCF.GetUnitPower
local GetUnitPowerMax = NCF.GetUnitPowerMax
local GetInterruptTarget = NCF.GetInterruptTarget

--============================================================
-- 7. 主循环
--============================================================
local function CreateBloodRotation()

    local function Rotation()
        -- 鲜血吞噬蓄力处理
        if HasTalent(TALENT.Consumption) then
            local consumptionCastTime = NCF.GetTimeSinceCast(1263824) or 999
            if consumptionCastTime < 1.4 then
                return nil  -- 蓄力中，等待
            elseif consumptionCastTime >= 1.4 and consumptionCastTime < 1.6 then
                return "spell", 1263824  -- 刚满蓄，释放
            end
        end
        
        -- 刷新GCD最大值
        NCF.RefreshGCD()
        local gcd_max = NCF.gcd_max or 1.5
        
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)
        
        -- 获取GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- 判断技能是否可用
        local function IsReady(spellID)
            return GetSpellCooldownRemain(spellID) <= gcd
        end
        
        --==========================================================
        -- 资源
        --==========================================================
        local runes = GetUnitPower("player", "runes") or 0
        local runicPower = GetUnitPower("player", "runicpower") or 0
        local runicPowerMax = GetUnitPowerMax("player", "runicpower") or 100
        local runicPowerDeficit = runicPowerMax - runicPower
        
        --==========================================================
        -- Buff/Debuff 状态
        --==========================================================
        local hasDRW = HasBuff(BUFF.DancingRuneWeapon, "player")
        local hasVampiricBlood = HasBuff(BUFF.VampiricBlood, "player")
        local hasDND = HasBuff(BUFF.DeathAndDecay, "player")
        local hasCrimsonScourge = HasBuff(BUFF.CrimsonScourge, "player")
        local hasCoagulopathy = HasBuff(BUFF.Coagulopathy, "player")
        local coagulopathyRemain = GetBuffRemain(BUFF.Coagulopathy, "player") or 0
        local coagulopathyStacks = GetBuffStacks(BUFF.Coagulopathy, "player") or 0
        local hasExterminate = HasBuff(BUFF.Exterminate, "player")
        local hasEssence = HasBuff(BUFF.EssenceOfTheBloodQueen, "player")
        local essenceRemain = GetBuffRemain(BUFF.EssenceOfTheBloodQueen, "player") or 0
        
        -- 白骨护盾
        local hasBoneShield = HasBuff(BUFF.BoneShield, "player")
        local boneShieldRemain = GetBuffRemain(BUFF.BoneShield, "player") or 0
        local boneShieldStacks = GetBuffStacks(BUFF.BoneShield, "player") or 0
        local boneShieldLow = not hasBoneShield or boneShieldRemain < 1.5 or boneShieldStacks <= 1
        local boneShieldMid = boneShieldStacks < 6
        
        -- 血瘟
        local hasBloodPlague = HasDebuff(DEBUFF.BloodPlague, "target")
        local bloodPlagueRemain = GetDebuffRemain(DEBUFF.BloodPlague, "target") or 0
        
        -- 吸血打击触发检测
        local vampiricStrikeReady = C_Spell.GetOverrideSpell(206930) == 433895
        
        --==========================================================
        -- 英雄树判断
        --==========================================================
        local isDeathbringer = HasTalent(TALENT.Deathbringer)
        local isSanlayn = HasTalent(TALENT.Sanlayn)
        
        -- 玩家血量
        local myHp = NCF.GetUnitHealthPct("player") or 100
        
        --==========================================================
        -- 通用优先级 (战斗外也可执行)
        --==========================================================
        
        -- 0. 打断 - 心灵冰冻: 15码
        local interruptTarget = GetInterruptTarget(15, true, 0.5)
        if interruptTarget and IsReady(SPELL.MindFreeze) then
            return "spell", SPELL.MindFreeze, interruptTarget
        end
        
        -- 0.1 复活亡者
        if not GetPetExists() and IsReady(SPELL.RaiseDead) and not ShouldSkipSpell(SPELL.RaiseDead) then
            return "spell", SPELL.RaiseDead
        end
        
        -- 0.2 复活盟友: 鼠标指向死亡队友
        if UnitExists("mouseover") and UnitIsDead("mouseover") and UnitIsFriend("player", "mouseover") and runicPower >= 30 then
            if IsReady(SPELL.RaiseAlly) and not ShouldSkipSpell(SPELL.RaiseAlly) then
                return "spell", SPELL.RaiseAlly, "mouseover"
            end
        end
        
        -- 0.3 巫妖之躯: 被魅惑/催眠/恐惧时
        local hasCharm = C_LossOfControl and C_LossOfControl.GetActiveLossOfControlDataCount and C_LossOfControl.GetActiveLossOfControlDataCount() > 0
        if hasCharm then
            for i = 1, C_LossOfControl.GetActiveLossOfControlDataCount() do
                local data = C_LossOfControl.GetActiveLossOfControlData(i)
                if data and (data.locType == "CHARM" or data.locType == "FEAR" or data.locType == "SLEEP") then
                    if IsReady(SPELL.Lichborne) and not ShouldSkipSpell(SPELL.Lichborne) then
                        return "spell", SPELL.Lichborne
                    end
                    break
                end
            end
        end
        
        -- 0.4 冰封之韧: 血量<30% 或 被击晕
        local isStunned = false
        if C_LossOfControl and C_LossOfControl.GetActiveLossOfControlDataCount then
            for i = 1, C_LossOfControl.GetActiveLossOfControlDataCount() do
                local data = C_LossOfControl.GetActiveLossOfControlData(i)
                if data and data.locType == "STUN" then
                    isStunned = true
                    break
                end
            end
        end
        if (myHp < 30 or isStunned) and IsReady(SPELL.IceboundFortitude) and not ShouldSkipSpell(SPELL.IceboundFortitude) then
            return "spell", SPELL.IceboundFortitude
        end
        
        -- 非战斗状态不继续
        if not UnitAffectingCombat("player") then
            return nil
        end
        
        -- 0.5 死亡爱抚: 目标距离>5且<30 且 无血瘟
        local targetDistance = NCF.GetDistanceToTarget("target") or 0
        if targetDistance > 5 and targetDistance < 30 and not hasBloodPlague then
            if IsReady(SPELL.DeathsCaress) and not ShouldSkipSpell(SPELL.DeathsCaress) then
                return "spell", SPELL.DeathsCaress
            end
        end
        
        --==========================================================
        -- 高优先级动作 (high_prio_actions)
        --==========================================================
        
        -- 1. 灵界打击: 凝血症buff剩余<=GCD
        if hasCoagulopathy and coagulopathyRemain <= gcd_max and runicPower >= 40 then
            if IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                return "spell", SPELL.DeathStrike
            end
        end
        
        -- 2. 符文武器舞
        if NCF.MeetsSpellTTD(SPELL.DancingRuneWeapon) and IsReady(SPELL.DancingRuneWeapon) and not ShouldSkipSpell(SPELL.DancingRuneWeapon) then
            return "spell", SPELL.DancingRuneWeapon
        end
        
        --==========================================================
        -- 爆发消耗品 (符文武器舞期间)
        --==========================================================
        if NCF.burstModeEnabled and hasDRW then
            NCF.UseTrinket()
            if NCF.enablePotion then
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end
        
        --==========================================================
        -- 吸血之血 (无buff且血量<50%)
        --==========================================================
        if not hasVampiricBlood and myHp < 50 and IsReady(SPELL.VampiricBlood) and not ShouldSkipSpell(SPELL.VampiricBlood) then
            return "spell", SPELL.VampiricBlood
        end
        
        --==========================================================
        -- 死神分支 (deathbringer)
        --==========================================================
        if isDeathbringer then
            
            -- 1. 灵界打击: 符能缺口<20 或 (符能缺口<26且DRW激活)
            if (runicPowerDeficit < 20 or (runicPowerDeficit < 26 and hasDRW)) and runicPower >= 40 then
                if IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                    return "spell", SPELL.DeathStrike
                end
            end
            
            -- 2. 收割者印记
            if NCF.MeetsSpellTTD(SPELL.ReapersMark) and IsReady(SPELL.ReapersMark) and not ShouldSkipSpell(SPELL.ReapersMark) then
                return "spell", SPELL.ReapersMark
            end
            
            -- 3. 血沸: DRW激活 且 目标无血瘟
            if hasDRW and not hasBloodPlague then
                if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                    return "spell", SPELL.BloodBoil
                end
            end
            
            -- 4. 枯萎凋零: 无buff
            if not hasDND then
                local canCastDND = hasCrimsonScourge or runes >= 1
                if canCastDND and IsReady(SPELL.DeathAndDecay) and not ShouldSkipSpell(SPELL.DeathAndDecay) then
                    return "spell", SPELL.DeathAndDecay
                end
            end
            
            -- 5. 骨髓裂击: 灭绝buff 或 白骨<5层
            if (hasExterminate or boneShieldStacks < 5) and runes >= 2 then
                if IsReady(SPELL.Marrowrend) and not ShouldSkipSpell(SPELL.Marrowrend) then
                    return "spell", SPELL.Marrowrend
                end
            end
            
            -- 6. 灵界打击
            if runicPower >= 40 and IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                return "spell", SPELL.DeathStrike
            end
            
            -- 7. 鲜血吞噬
            if HasTalent(TALENT.Consumption) and IsReady(SPELL.Consumption) and not ShouldSkipSpell(SPELL.Consumption) then
                return "spell", SPELL.Consumption
            end
            
            -- 8. 血沸
            if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                return "spell", SPELL.BloodBoil
            end
            
            -- 9. 心脏打击: 凝血症<5层
            if coagulopathyStacks < 5 and runes >= 1 then
                if IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                    return "spell", SPELL.HeartStrike
                end
            end
            
            -- 10. 心脏打击
            if runes >= 1 and IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                return "spell", SPELL.HeartStrike
            end
            
            return nil
        end
        
        --==========================================================
        -- 圣血DRW分支 (san_drw)
        --==========================================================
        if isSanlayn and hasDRW then
            
            -- 1. 心脏打击: 血女王精华剩余<1.5秒且存在
            if hasEssence and essenceRemain < 1.5 and runes >= 1 then
                if IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                    return "spell", SPELL.HeartStrike
                end
            end
            
            -- 2. 灵界打击: 符能缺口<36
            if runicPowerDeficit < 36 and runicPower >= 40 then
                if IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                    return "spell", SPELL.DeathStrike
                end
            end
            
            -- 3. 血沸: 目标无血瘟
            if not hasBloodPlague then
                if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                    return "spell", SPELL.BloodBoil
                end
            end
            
            -- 4. 枯萎凋零: (敌人<=3且血红天灾) 或 (敌人>3且无DND)
            if (enemyCount <= 3 and hasCrimsonScourge) or (enemyCount > 3 and not hasDND) then
                local canCastDND = hasCrimsonScourge or runes >= 1
                if canCastDND and IsReady(SPELL.DeathAndDecay) and not ShouldSkipSpell(SPELL.DeathAndDecay) then
                    return "spell", SPELL.DeathAndDecay
                end
            end
            
            -- 5. 心脏打击
            if runes >= 1 and IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                return "spell", SPELL.HeartStrike
            end
            
            -- 6. 灵界打击
            if runicPower >= 40 and IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                return "spell", SPELL.DeathStrike
            end
            
            -- 7. 鲜血吞噬
            if HasTalent(TALENT.Consumption) and IsReady(SPELL.Consumption) and not ShouldSkipSpell(SPELL.Consumption) then
                return "spell", SPELL.Consumption
            end
            
            -- 8. 血沸
            if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                return "spell", SPELL.BloodBoil
            end
            
            return nil
        end
        
        --==========================================================
        -- 圣血分支 (sanlayn)
        --==========================================================
        if isSanlayn then
            
            -- 1. 血沸: 白骨不足 且 敌人>=2
            if boneShieldLow and enemyCount >= 2 then
                if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                    return "spell", SPELL.BloodBoil
                end
            end
            
            -- 2. 死亡爱抚: 白骨不足
            if boneShieldLow then
                if IsReady(SPELL.DeathsCaress) and not ShouldSkipSpell(SPELL.DeathsCaress) then
                    return "spell", SPELL.DeathsCaress
                end
            end
            
            -- 3. 血沸: 血瘟剩余<3秒
            if bloodPlagueRemain < 3 then
                if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                    return "spell", SPELL.BloodBoil
                end
            end
            
            -- 4. 心脏打击: 血女王精华剩余<1.5秒且存在 且 吸血打击触发
            if hasEssence and essenceRemain < 1.5 and vampiricStrikeReady and runes >= 1 then
                if IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                    return "spell", SPELL.HeartStrike
                end
            end
            
            -- 5. 灵界打击: 符能缺口<20
            if runicPowerDeficit < 20 and runicPower >= 40 then
                if IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                    return "spell", SPELL.DeathStrike
                end
            end
            
            -- 6. 鲜血吞噬: DND buff存在
            if HasTalent(TALENT.Consumption) and hasDND and IsReady(SPELL.Consumption) and not ShouldSkipSpell(SPELL.Consumption) then
                return "spell", SPELL.Consumption
            end
            
            -- 7. 心脏打击: 吸血打击触发 且 DND buff存在
            if vampiricStrikeReady and hasDND and runes >= 1 then
                if IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                    return "spell", SPELL.HeartStrike
                end
            end
            
            -- 8. 血沸: 白骨<6层 且 敌人>=2
            if boneShieldMid and enemyCount >= 2 then
                if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                    return "spell", SPELL.BloodBoil
                end
            end
            
            -- 9. 死亡爱抚: 白骨<6层
            if boneShieldMid then
                if IsReady(SPELL.DeathsCaress) and not ShouldSkipSpell(SPELL.DeathsCaress) then
                    return "spell", SPELL.DeathsCaress
                end
            end
            
            -- 10. 骨髓裂击: 白骨<6层
            if boneShieldMid and runes >= 2 then
                if IsReady(SPELL.Marrowrend) and not ShouldSkipSpell(SPELL.Marrowrend) then
                    return "spell", SPELL.Marrowrend
                end
            end
            
            -- 11. 枯萎凋零: (敌人<=3且血红天灾) 或 (敌人>3且无DND)
            if (enemyCount <= 3 and hasCrimsonScourge) or (enemyCount > 3 and not hasDND) then
                local canCastDND = hasCrimsonScourge or runes >= 1
                if canCastDND and IsReady(SPELL.DeathAndDecay) and not ShouldSkipSpell(SPELL.DeathAndDecay) then
                    return "spell", SPELL.DeathAndDecay
                end
            end
            
            -- 12. 心脏打击: 吸血打击触发
            if vampiricStrikeReady and runes >= 1 then
                if IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                    return "spell", SPELL.HeartStrike
                end
            end
            
            -- 13. 灵界打击
            if runicPower >= 40 and IsReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
                return "spell", SPELL.DeathStrike
            end
            
            -- 14. 心脏打击: 符文>=2
            if runes >= 2 and IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                return "spell", SPELL.HeartStrike
            end
            
            -- 15. 鲜血吞噬
            if HasTalent(TALENT.Consumption) and IsReady(SPELL.Consumption) and not ShouldSkipSpell(SPELL.Consumption) then
                return "spell", SPELL.Consumption
            end
            
            -- 16. 血沸
            if IsReady(SPELL.BloodBoil) and not ShouldSkipSpell(SPELL.BloodBoil) then
                return "spell", SPELL.BloodBoil
            end
            
            -- 17. 心脏打击
            if runes >= 1 and IsReady(SPELL.HeartStrike) and not ShouldSkipSpell(SPELL.HeartStrike) then
                return "spell", SPELL.HeartStrike
            end
            
            return nil
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateBloodRotation()