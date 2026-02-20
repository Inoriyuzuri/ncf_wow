--============================================================
-- 惩戒骑士循环 (Retribution Paladin APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

0. 打断
   - 责难 (96231): 5码内有可打断目标，需面朝

1. CD 管理
   - 灰烬觉醒 (255937): 复仇之怒 和 处决宣判 CD 都 > 30秒
   - 圣洁鸣钟 (375576): 30码内敌人 >= 2
   - 处决宣判 (343527): 复仇之怒 CD < 2秒
   - 复仇之怒 (31884): 无条件

2. 常规循环
   - 圣光之锤 (427453): 两种触发方式，通过 GetSpellCostByType 判断
     * 圣光裁决(433674)叠满触发: 消耗为0，免费释放
     * 灰烬觉醒后触发: 消耗为5，需要足够神圣能量
   - 神圣风暴 (53385): 神圣能量 = 5 且 8码内敌人 >= 2
   - 最终审判 (383328): 神圣能量 = 5 且 8码内敌人 < 2
   - 审判 (20271): 神圣能量 <= 4 且 充能 > 1.6 (复仇之怒期间用24275获取充能)
   - 公正之剑 (184575): 神圣能量 <= 3
   - 神圣风暴 (53385): 有苍穹之力 buff 326733
   - 免费终结技 (DivinePurpose 408458): 根据敌人数量打神圣风暴或最终审判
   - 神圣风暴 (53385): 神圣能量 >= 3 且 8码内敌人 >= 2
   - 最终审判 (383328): 神圣能量 >= 3 且 8码内敌人 < 2
   - 公正之剑 (184575): 填充
   - 审判 (20271): 填充

Buff ID 参考:
- 圣光之锤: 427441
- 苍穹之力: 326733
- DivinePurpose: 408458
- 复仇之怒: 31884
- 圣光裁决: 433674
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("PALADIN", 3, {
    -- 爆发技能
    { id = 255937, name = "灰烬觉醒", default = "burst" },
    { id = 375576, name = "圣洁鸣钟", default = "burst" },
    { id = 31884, name = "复仇之怒", default = "burst" },
    { id = 343527, name = "处决宣判", default = "burst" },
    
    -- 普通技能
	{ id = 427453, name = "圣光之锤", default = "normal" },
    { id = 20271, name = "审判", default = "normal" },
    { id = 53385, name = "神圣风暴", default = "normal" },
    { id = 383328, name = "最终审判", default = "normal" },
    { id = 184575, name = "公正之剑", default = "normal" },
    { id = 96231, name = "责难", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Judgment = 20271,               -- 审判/愤怒之锤
    JudgmentAW = 24275,             -- 审判 (复仇之怒期间)
    DivineStorm = 53385,            -- 神圣风暴
    FinalVerdict = 383328,          -- 最终审判
    WakeOfAshes = 255937,           -- 灰烬觉醒
    LightsHammer = 427453,          -- 圣光之锤 (灰烬觉醒变体)
    DivineResonance = 375576,       -- 圣洁鸣钟
    AvengingWrath = 31884,          -- 复仇之怒
    ExecutionSentence = 343527,     -- 处决宣判
    BladeOfJustice = 184575,        -- 公正之剑
    Rebuke = 96231,                 -- 责难
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    LightsHammer = 427441,          -- 圣光之锤
    EmpyreanPower = 326733,         -- 苍穹之力
    DivinePurpose = 408458,         -- 神圣意志
    AvengingWrath = 31884,          -- 复仇之怒
    EmpyreanLegacy = 432629,        -- 公允裁定 (圣光之锤后15%极速，持续8秒)
}

local DEBUFF = {
    ExecutionSentence = 1260251,    -- 处决宣判
}

--============================================================
-- 4. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower
local GetSpellCostByType = NCF.GetSpellCostByType
local GetTimeSinceCast = NCF.GetTimeSinceCast

local function GetHolyPower()
    return GetUnitPower("player", "holypower")
end

--============================================================
-- 5. 主循环
--============================================================
local function CreateRetributionRotation()

    local function Rotation()
        -- 获取敌人数量 (8码用于常规技能)
        local enemyCount8 = GetActiveEnemyAmount(8, false)
        -- 获取敌人数量 (30码用于圣洁鸣钟)
        local enemyCount30 = GetActiveEnemyAmount(30, false)
        SetEnemyCount(enemyCount8)
        
        -- 获取 GCD
        local gcd = math.max(NCF.GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local holyPower = GetHolyPower()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 0. 打断：5码内面前有可打断的敌人
        if IsReady(SPELL.Rebuke) and not ShouldSkipSpell(SPELL.Rebuke) then
            local interruptTarget = NCF.GetInterruptTarget(5, true)
            if interruptTarget then
                return "spell", SPELL.Rebuke, interruptTarget
            end
        end

		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end
		
		if NCF.burstModeEnabled and HasBuff(BUFF.AvengingWrath) then
			NCF.UseTrinket()
            if NCF.enablePotion then 
				NCF.UseCombatPotion()
			end
			local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
		end
		
        -- 审判, if 神圣能量 <= 4 且 充能 > 1.6
        -- 复仇之怒期间用 24275 获取充能，否则用 20271
        local judgmentSpellForCharges = HasBuff(BUFF.AvengingWrath) and SPELL.JudgmentAW or SPELL.Judgment
        local judgmentCharges = GetSpellCharges(judgmentSpellForCharges)
        if holyPower <= 4 and judgmentCharges > 1.6 and IsReady(SPELL.Judgment) and not ShouldSkipSpell(SPELL.Judgment) then
            return "spell", SPELL.Judgment
        end
        
        -- 公正之剑, if 神圣能量 <= 3
        if holyPower <= 3 and IsReady(SPELL.BladeOfJustice) and not ShouldSkipSpell(SPELL.BladeOfJustice) then
            return "spell", SPELL.BladeOfJustice
        end
		
        -- 1. CD 管理
        local avengingWrathCD = GetSpellCooldownRemain(SPELL.AvengingWrath)
        local executionSentenceCD = GetSpellCooldownRemain(SPELL.ExecutionSentence)
        
        -- 灰烬觉醒, if 复仇之怒 和 处决宣判 CD 都 > 30秒
        if NCF.MeetsSpellTTD(SPELL.WakeOfAshes) and avengingWrathCD > 20 and executionSentenceCD > 20 and IsReady(SPELL.WakeOfAshes) and not ShouldSkipSpell(SPELL.WakeOfAshes) then
            return "spell", SPELL.WakeOfAshes
        end
        
        -- 圣洁鸣钟, if 30码内敌人 >= 1
        if NCF.MeetsSpellTTD(SPELL.DivineResonance) and enemyCount30 >= 1 and IsReady(SPELL.DivineResonance) and not ShouldSkipSpell(SPELL.DivineResonance) then
            return "spell", SPELL.DivineResonance
        end
        
        -- 处决宣判, if 复仇之怒 CD < 2秒
        if NCF.MeetsSpellTTD(SPELL.ExecutionSentence) and avengingWrathCD < 2 and IsReady(SPELL.ExecutionSentence) and not ShouldSkipSpell(SPELL.ExecutionSentence) then
            return "spell", SPELL.ExecutionSentence
        end
        
        -- 复仇之怒
        if NCF.MeetsSpellTTD(SPELL.AvengingWrath) and IsReady(SPELL.AvengingWrath) and not ShouldSkipSpell(SPELL.AvengingWrath) then
            return "spell", SPELL.AvengingWrath
        end
        
        -- 2. 常规循环
        
        -- 检查是否有圣光之锤 buff
        local hasLightsHammerBuff = HasBuff(BUFF.LightsHammer)
        -- 检查是否有公允裁定 buff (圣光之锤后的极速buff，持续8秒)
        local hasEmpyreanLegacy = HasBuff(BUFF.EmpyreanLegacy)
        
        -- 是否可以打神圣风暴/最终审判
        -- 有公允裁定buff → 可以打 (说明刚打完圣光之锤，在享受极速)
        -- 没有圣光之锤buff → 可以打
        local canUseFinisher = hasEmpyreanLegacy or not hasLightsHammerBuff
        
        -- 圣光之锤判断 (两种触发方式)
        -- 1. 灰烬觉醒后的圣光之锤 - 需要 5 能量
        -- 2. 圣光裁决(433674)叠满后的免费圣光之锤 - 不需要能量
        -- 通过 GetSpellCostByType 直接判断当前技能消耗
        -- 有公允裁定buff时不打圣光之锤 (等buff消失再打，最大化极速收益)
        -- 但是：如果目标有处决宣判debuff，无视公允裁定直接打，提升处决结算伤害
        local hasExecutionSentence = HasDebuff(DEBUFF.ExecutionSentence, "target")
        local canUseLightsHammer = hasExecutionSentence or not hasEmpyreanLegacy
        
        if hasLightsHammerBuff and canUseLightsHammer and IsReady(SPELL.LightsHammer) and not ShouldSkipSpell(SPELL.LightsHammer) then
            local hammerCost = GetSpellCostByType(SPELL.LightsHammer, Enum.PowerType.HolyPower)
            
            if hammerCost == 0 then
                -- 免费的，直接放
                return "spell", SPELL.LightsHammer
            elseif hammerCost and holyPower >= hammerCost then
                -- 需要能量，够了才放
                return "spell", SPELL.LightsHammer
            end
        end
        
        -- 神圣风暴 if 神圣能量 = 5 且 8码内敌人 >= 2
        if canUseFinisher and holyPower == 5 and enemyCount8 >= 2 and IsReady(SPELL.DivineStorm) and not ShouldSkipSpell(SPELL.DivineStorm) then
            return "spell", SPELL.DivineStorm
        end
        
        -- 最终审判 if 神圣能量 = 5 且 8码内敌人 < 2
        if canUseFinisher and holyPower == 5 and enemyCount8 < 2 and IsReady(SPELL.FinalVerdict) and not ShouldSkipSpell(SPELL.FinalVerdict) then
            return "spell", SPELL.FinalVerdict
        end
        
        
        -- 神圣风暴, if 有苍穹之力 buff (免费)
        if canUseFinisher and HasBuff(BUFF.EmpyreanPower) and IsReady(SPELL.DivineStorm) and not ShouldSkipSpell(SPELL.DivineStorm) then
            local stormCost = GetSpellCostByType(SPELL.DivineStorm, Enum.PowerType.HolyPower)
            if stormCost == 0 then
                return "spell", SPELL.DivineStorm
            end
        end
        
        -- 免费终结技 (神圣意志 buff)，看数量打
        if canUseFinisher and HasBuff(BUFF.DivinePurpose) then
            local stormCost = GetSpellCostByType(SPELL.DivineStorm, Enum.PowerType.HolyPower)
            local verdictCost = GetSpellCostByType(SPELL.FinalVerdict, Enum.PowerType.HolyPower)
            
            if enemyCount8 >= 2 and stormCost == 0 and IsReady(SPELL.DivineStorm) then
                return "spell", SPELL.DivineStorm
            elseif enemyCount8 < 2 and verdictCost == 0 and IsReady(SPELL.FinalVerdict) then
                return "spell", SPELL.FinalVerdict
            end
        end
        
        -- 神圣风暴 if 神圣能量 >= 3 且 8码内敌人 >= 2
        if canUseFinisher and holyPower >= 3 and enemyCount8 >= 2 and IsReady(SPELL.DivineStorm) and not ShouldSkipSpell(SPELL.DivineStorm) then
            return "spell", SPELL.DivineStorm
        end
        
        -- 最终审判 if 神圣能量 >= 3 且 8码内敌人 < 2
        if canUseFinisher and holyPower >= 3 and enemyCount8 < 2 and IsReady(SPELL.FinalVerdict) and not ShouldSkipSpell(SPELL.FinalVerdict) then
            return "spell", SPELL.FinalVerdict
        end
        
        -- 公正之剑 (填充)
        if IsReady(SPELL.BladeOfJustice) and not ShouldSkipSpell(SPELL.BladeOfJustice) then
            return "spell", SPELL.BladeOfJustice
        end
        
        -- 审判 (填充)
        if IsReady(SPELL.Judgment) and not ShouldSkipSpell(SPELL.Judgment) then
            return "spell", SPELL.Judgment
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateRetributionRotation()