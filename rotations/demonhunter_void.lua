--============================================================
-- 虚空恶魔猎手循环 (Void Demon Hunter APL)
-- 12.0 Midnight 版本
-- 支持: 歼灭分支 / 虚痕分支 (天赋 VoidScar 452402)
--============================================================

--[[
=== 优先级循环 ===

0. 打断 - 瓦解 (183752): 30码内有可打断目标

--- 爆发阶段 (爆发模式 且 有恶魔形态buff) ---
   - 使用饰品
   - 使用战斗药水 (如果启用)
   - 使用种族技能

--- 战斗门槛: 自己战斗中 或 目标战斗中 ---

1. 坍缩之星 (1221167): 坍缩层数 >= 30 且 不移动

=== 虚痕分支 (天赋 VoidScar) ===
2. 复仇回避 (198793): 有虚空瞬步buff
3. 饥渴斩击 (1239123): 有饥渴斩击buff 且 有天赋
4. 收割者之钟 (1245470): 虚空之刃override为收割者之钟时
5. 刺穿虚空 (1245483): 虚空之刃override为刺穿虚空时
6. 掠食者觉醒 (1259431): 恶魔追击override为掠食者觉醒时
7. 恶魔追击 (1246167): 没有饥渴斩击buff 且 有天赋
8. 虚空之刃 (1245412): 没有饥渴斩击buff 且 有天赋

=== 通用部分 ===
9. 收割 (1226019): 虚空天坠=3 且 虚痕分支 且 (层数>=31且灵魂饕餮 | 层数>=44)
10. 虚空射线 (473728): (恶魔形态未激活且怒气>=100 | 恶魔形态激活) 且 没有根除buff
11. 虚空变形 (1217605): 有渴望时刻buff 且 (层数>=35且灵魂饕餮 | 层数>=50) [爆发]
12. 根除/收割: 有根除buff 且 (残片>=10且多目标 | 单目标 | 恶魔形态且怒气<=40)
13. 收割: 无根除buff 且 (充能=2 | 恶魔形态无渴望天赋 | 恶魔形态有渴望天赋且残片>=4 | 有渴望时刻buff)
14. 吞噬 (473662): 填充

=== Override技能检查 ===
- Reap(1226019) -> Eradicate(1225826): 根除
- DemonPursuit(1246167) -> PredatorsWake(1259431): 掠食者觉醒
- VoidBlade(1245412) -> PierceTheVeil(1245483): 刺穿虚空
- VoidBlade(1245412) -> ReapersToll(1245470): 收割者之钟

=== Buff ID ===
- 虚空天坠: 1256301
- 渴望时刻: 1238495
- 灵魂残片: 1245577
- 恶魔形态: 1217607
- 虚空变形条件层数: 1225789
- 饥渴斩击buff: 1239525
- 虚空瞬步buff: 1223157

=== 天赋 ID ===
- 灵魂饕餮: 1247534
- 万界空虚: 1242492
- 虚痕: 452402
- 饥渴斩击: 1239519
- 恶魔追击: 1246167
- 渴望: 1239537
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("DEMONHUNTER", 3, {
    -- 爆发技能
    { id = 1217605, name = "虚空变形", default = "burst" },
    
    -- 普通技能
    { id = 183752, name = "瓦解", default = "normal" },
    { id = 1221167, name = "坍缩之星", default = "normal" },
    { id = 1226019, name = "收割", default = "normal" },
    { id = 473728, name = "虚空射线", default = "normal" },
    { id = 473662, name = "吞噬", default = "normal" },
    
    -- 虚痕分支技能
    { id = 1246167, name = "恶魔追击", default = "normal" },
    { id = 1245412, name = "虚空之刃", default = "normal" },
    { id = 1239123, name = "饥渴斩击", default = "normal" },
    { id = 198793, name = "复仇回避", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Disrupt = 183752,               -- 瓦解 (打断)
    CollapsingStar = 1221167,       -- 坍缩之星
    Reap = 1226019,                 -- 收割
    Eradicate = 1225826,            -- 根除 (Reap的override)
    VoidMorph = 1217605,            -- 虚空变形
    VoidRay = 473728,               -- 虚空射线
    Consume = 473662,               -- 吞噬
    -- 虚痕分支
    DemonPursuit = 1246167,         -- 恶魔追击 (The Hunt)
    PredatorsWake = 1259431,        -- 掠食者觉醒 (The Hunt的override)
    VoidBlade = 1245412,            -- 虚空之刃
    PierceTheVeil = 1245483,        -- 刺穿虚空 (VoidBlade的override)
    ThirstyStrike = 1239123,        -- 饥渴斩击
    VengefulRetreat = 198793,       -- 复仇回避
	ReapersToll = 1245470,
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    VoidFall = 1256301,             -- 虚空天坠
    Eradication = 1239524,          -- 根除
    SoulFragments = 1245577,        -- 灵魂残片
    DemonForm = 1217607,            -- 恶魔形态
    CollapsingStacks = 1227702,     -- 坍缩层数
    VoidMorphCondition = 1225789,   -- 虚空变形条件buff
    -- 虚痕分支
    ThirstyStrike = 1239525,        -- 饥渴斩击buff
    VoidStep = 1223157,             -- 虚空瞬步buff
	MomentOfCraving = 1238495,
}

--============================================================
-- 4. 天赋ID定义
--============================================================
local TALENT = {
    SoulFeast = 1247534,            -- 灵魂饕餮
    VoidOfAll = 1242492,            -- 万界空虚
    VoidScar = 452402,              -- 虚痕
    ThirstyStrike = 1239519,        -- 饥渴斩击
    DemonPursuit = 1246167,         -- 恶魔追击 (The Hunt)
	Thirsty = 1239537,
	VoidFall = 1253304,
}

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower
local GetSpellCharges = NCF.GetSpellCharges
local GetBuffRemain = NCF.GetBuffRemain


local function GetFury()
    return GetUnitPower("player", "fury")
end

--============================================================
-- 6. 主循环
--============================================================
local function CreateVoidRotation()

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(40, false)
        SetEnemyCount(enemyCount)
        
        -- Override检查
        local isEradicate = C_Spell.GetOverrideSpell(SPELL.Reap) == SPELL.Eradicate
        local isPredatorsWake = C_Spell.GetOverrideSpell(SPELL.DemonPursuit) == SPELL.PredatorsWake
		local isPierceTheViel = C_Spell.GetOverrideSpell(SPELL.VoidBlade) == SPELL.PierceTheVeil
		local isReapersToll = C_Spell.GetOverrideSpell(SPELL.VoidBlade) == SPELL.ReapersToll
        -- 获取 GCD
        local gcd = math.max(NCF.GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local fury = GetFury()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 0. 打断: 30码内面前有可打断的敌人
        if IsReady(SPELL.Disrupt) and not ShouldSkipSpell(SPELL.Disrupt) then
            local interruptTarget = NCF.GetInterruptTarget(30, false)
            if interruptTarget then
                return "InstantSpell", SPELL.Disrupt, interruptTarget
            end
        end
		
        -- 获取buff层数
        local voidFallStacks = GetBuffStacks(BUFF.VoidFall)
        local soulFragments = GetBuffStacks(BUFF.SoulFragments)
        local collapsingStacks = GetBuffStacks(BUFF.CollapsingStacks)
        local voidConditionStacks = GetBuffStacks(BUFF.VoidMorphCondition)
        local hasEradication = C_Spell.GetOverrideSpell(SPELL.Reap) == SPELL.Eradicate
		local hasThirstyStrike = C_Spell.GetOverrideSpell(SPELL.VoidBlade) == SPELL.ThirstyStrike
        local hasDemonForm = HasBuff(BUFF.DemonForm)
		local hasMomentOfCraving = HasBuff(BUFF.MomentOfCraving)
		local ReapCharges = GetSpellCharges(SPELL.Reap)
		local MomentOfCravingRemains = GetBuffRemain(BUFF.MomentOfCraving)
		local hasVoidStep = HasBuff(BUFF.VoidStep)
        
        -- 如果正在读吞噬，预估灵魂残片+2
        local spellName = UnitCastingInfo("player")
        if spellName then
			spellName = secretunwrap(spellName)
            local castSpellName = GetSpellInfo(SPELL.Consume)
            if spellName == castSpellName then
                soulFragments = soulFragments + 2
				fury = fury + 8
            end
        end
        
        -- 爆发阶段: 药水、饰品、种族技能
        if NCF.burstModeEnabled and hasDemonForm then
            NCF.UseTrinket()
            if NCF.enablePotion then 
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end
        
        -- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end
        
		--[[local ischanneling = UnitChannelInfo("player")
		if ischanneling then return end]]
        
        -- 检测虚痕天赋
        local isVoidScar = HasTalent(TALENT.VoidScar)
		local isVoidFall = HasTalent(TALENT.VoidFall)
		
		-- 1. 坍缩之星: 坍缩层数 >= 30 且 玩家不在移动
        local isMoving = GetUnitSpeed("player") > 0
        isMoving = secretunwrap(isMoving)
        if collapsingStacks >= 30 and not isMoving and IsReady(SPELL.CollapsingStar) and not ShouldSkipSpell(SPELL.CollapsingStar) then
            return "spell", SPELL.CollapsingStar
        end
			
		-- 2 [根除]：天赋虚痕激活且已激活“根除”Buff时施放且噬欲时刻<4s激活且恶魔变形激活
		if isEradicate and isVoidScar and MomentOfCravingRemains <= 4 and hasDemonForm and IsReady(SPELL.Reap) and not ShouldSkipSpell(SPELL.Reap) then
			return "spell", SPELL.Reap
		end
		
		-- 3 收割： 天赋虚痕激活且噬欲时刻<4s激活且恶魔变形激活
		if not isEradicate and isVoidScar and MomentOfCravingRemains <= 4 and hasDemonForm and IsReady(SPELL.Reap) and not ShouldSkipSpell(SPELL.Reap) then
			return "spell", SPELL.Reap
		end
		
        -- 复仇回避: 有虚空瞬步buff
        if NCF.GetTimeSinceCast(SPELL.VengefulRetreat) > 0.5 and hasVoidStep and IsReady(SPELL.VengefulRetreat) and not ShouldSkipSpell(SPELL.VengefulRetreat) then
            return "spell", SPELL.VengefulRetreat
        end

        -- 饥渴斩击: 有饥渴斩击buff 且 有天赋
        if HasTalent(TALENT.ThirstyStrike) and hasThirstyStrike and IsReady(SPELL.ThirstyStrike) and not ShouldSkipSpell(SPELL.ThirstyStrike) then
            return "spell", SPELL.ThirstyStrike
        end
		
		-- 收割者之钟: 虚空之刃override为收割者之钟
		if isReapersToll and IsReady(SPELL.ReapersToll) then
            return "spell", SPELL.ReapersToll
        end
		
		-- 刺穿虚空: 虚空之刃override为刺穿虚空
		if isPierceTheViel and IsReady(SPELL.PierceTheVeil) and IsReady(SPELL.VoidBlade) then
            return "spell", SPELL.PierceTheVeil
        end
			
		-- 掠食者觉醒: 恶魔追击override为掠食者觉醒
		if NCF.GetTimeSinceCast(SPELL.PredatorsWake) > 5 and isPredatorsWake and IsReady(SPELL.PredatorsWake) then
           return "spell", SPELL.PredatorsWake
        end
			
		-- 恶魔追击: 没有饥渴斩击buff 且 有天赋
        if HasTalent(TALENT.DemonPursuit) and not hasThirstyStrike and IsReady(SPELL.DemonPursuit) and not ShouldSkipSpell(SPELL.DemonPursuit) then
            return "spell", SPELL.DemonPursuit
        end
		
        -- 虚空之刃: 没有饥渴斩击buff 且 有天赋
        if HasTalent(TALENT.ThirstyStrike) and not hasThirstyStrike and IsReady(SPELL.VoidBlade) and not ShouldSkipSpell(SPELL.VoidBlade) then
            return "spell", SPELL.VoidBlade
        end    
		
		-- 天赋检查
		local hasSoulFeast = HasTalent(TALENT.SoulFeast)
		local hasVoidOfAll = HasTalent(TALENT.VoidOfAll)
		
		-- 收割: 虚空天坠=3 且 虚痕分支 且 (层数>=31且灵魂饕餮 | 层数>=44)
		if voidFallStacks == 3 and isVoidFall and ((voidConditionStacks >= 31 and hasSoulFeast) or voidConditionStacks >= 44) and IsReady(SPELL.Reap) and not ShouldSkipSpell(SPELL.Reap) then
			return "spell", SPELL.Reap
		end
		
        -- 虚空射线: (恶魔形态未激活且怒气>=100 | 恶魔形态激活) 且 没有根除buff
        local voidRayCondition = (not hasDemonForm and fury >= 100) or hasDemonForm
        if voidRayCondition and not hasMomentOfCraving and IsReady(SPELL.VoidRay) and not ShouldSkipSpell(SPELL.VoidRay) then
            return "spell", SPELL.VoidRay
        end
        
        -- 虚空变形: 有渴望时刻buff 且 (层数>=35且灵魂饕餮 | 层数>=50) [爆发]
        local voidMorphCondition = (voidConditionStacks >= 35 and hasSoulFeast) or voidConditionStacks >= 50
        if hasMomentOfCraving and voidMorphCondition and NCF.MeetsSpellTTD(SPELL.VoidMorph) and IsReady(SPELL.VoidMorph) and not ShouldSkipSpell(SPELL.VoidMorph) then
			return "spell", SPELL.VoidMorph
        end
        
        -- 根除(收割): 有根除buff 且 (残片>=10且多目标 | 单目标 | 恶魔形态且怒气<=40)
        if isEradicate and IsReady(SPELL.Reap) and not ShouldSkipSpell(SPELL.Reap) then
			local condition1 = soulFragments >= 10 and enemyCount > 1
			local condition2 = enemyCount == 1
			local condition3 = hasDemonForm and fury <= 40
			if condition1 or condition2 or condition3 then
				return "spell", SPELL.Reap
			end
        end
        
        -- 收割: 无根除buff 且 (充能=2 | 恶魔形态无渴望天赋 | 恶魔形态有渴望天赋且残片>=4 | 有渴望时刻buff)
        if not isEradicate and IsReady(SPELL.Reap) and not ShouldSkipSpell(SPELL.Reap) then
            local condition1 = ReapCharges == 2 and soulFragments >= 4
            local condition2 = hasDemonForm and not HasTalent(TALENT.Thirsty)
            local condition3 = hasDemonForm and soulFragments >= 4 and HasTalent(TALENT.Thirsty)
			local condition4 = hasMomentOfCraving
            if condition1 or condition2 or condition3 or condition4 then
                return "spell", SPELL.Reap
            end
        end
        
        -- 吞噬: 填充
        if IsReady(SPELL.Consume) and not ShouldSkipSpell(SPELL.Consume) then
            return "spell", SPELL.Consume
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateVoidRotation()