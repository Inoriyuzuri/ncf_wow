--============================================================
-- 狂徒盗贼循环 (Outlaw Rogue APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

=== 脱战准备 ===
- 伤残毒药 (315584): 脱战且没有buff
- 即时毒药 (381637): 脱战且没有buff

=== 打断 ===
- 脚踢 (1766): 5码, 不需要面朝, InstantSpell

=== 骰子逻辑 ===
- 命运骨骰 (1214909): 没有任何骰子buff
- 命运骨骰 (1214909): 有level 1或2 buff 且 有灌铅骰子天赋
- 命运骨骰 (1214909): 只有level 1 buff

=== AOE (8码内敌人 > 1) ===
- 剑刃乱舞 (13877): 没有剑刃乱舞buff
- 剑刃乱舞 (13877): 连击点 <= 2 且 有剑刃乱舞buff
- 刀锋冲刺 (271877): 有剑刃乱舞buff (需天赋)

=== 主循环 ===
- 影舞步 (51690): 连击点 >= 7 (需天赋)
- 命中眉心 (315341): 连击点 >= 6, 优先有惊慌debuff的目标
- 斩击 (2098) / 致命一击 (441776): 连击点 >= 6
- 刀锋冲刺 (271877): (需天赋)
- 冲动 (13750): TTD > 15秒
- 手枪射击 (185763): 可乘之机buff >= 3 且 连击点 <= 3
- 影袭 (196819): 连击点 <= 5

Buff ID 参考:
- 骰子 level 1: 1214933
- 骰子 level 2: 1214934
- 骰子 level 3: 1214935
- 骰子 level 4: 1214937
- 剑刃乱舞: 13877
- 冲动: 13750
- 可乘之机: 195627
- 锋化之刃: 441786
- 伤残毒药: 315584
- 即时毒药: 381637

Debuff ID 参考:
- 惊慌: 441224

天赋 ID 参考:
- 刀锋冲刺: 271877
- 影舞步: 51690
- 灌铅骰子: 256171
- 致命一击: 441423
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("ROGUE", 2, {
    -- 冷却技能
    { id = 13750, name = "冲动", default = "burst" },
    
    -- 普通技能
    { id = 1766, name = "脚踢", default = "normal" },
    { id = 1214909, name = "命运骨骰", default = "normal" },
    { id = 13877, name = "剑刃乱舞", default = "normal" },
    { id = 271877, name = "刀锋冲刺", default = "normal" },
    { id = 51690, name = "影舞步", default = "normal" },
    { id = 315341, name = "命中眉心", default = "normal" },
    { id = 2098, name = "斩击", default = "normal" },
    { id = 441776, name = "致命一击", default = "normal" },
    { id = 185763, name = "手枪射击", default = "normal" },
    { id = 193315, name = "影袭", default = "normal" },
    { id = 315584, name = "速效毒药", default = "normal" },
    { id = 381637, name = "萎缩毒药", default = "normal" },
    { id = 1784, name = "自动潜行", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Kick = 1766,                -- 脚踢
    RollTheBones = 1214909,     -- 命运骨骰
    BladeFlurry = 13877,        -- 剑刃乱舞
    BladeRush = 271877,         -- 刀锋冲刺
    ShadowDance = 51690,        -- 影舞步
    BetweenTheEyes = 315341,    -- 命中眉心
    Dispatch = 2098,            -- 斩击
    CoupDeGrace = 441776,       -- 致命一击
    AdrenalineRush = 13750,     -- 冲动
    PistolShot = 185763,        -- 手枪射击
    SinisterStrike = 193315,    -- 影袭
    CripplingPoison = 315584,   -- 速效毒药
    InstantPoison = 381637,     -- 萎缩毒药
	Stealth = 1784,
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    BladeRush = 271877,         -- 刀锋冲刺
    ShadowDance = 51690,        -- 影舞步
    LoadedDice = 256171,        -- 灌铅骰子
    CoupDeGrace = 441423,       -- 致命一击天赋
    InstantPoison = 381637,     -- 萎缩毒药
}

--============================================================
-- 4. Buff ID定义
--============================================================
local BUFF = {
    RollLevel1 = 1214933,       -- 骰子 level 1
    RollLevel2 = 1214934,       -- 骰子 level 2
    RollLevel3 = 1214935,       -- 骰子 level 3
    RollLevel4 = 1214937,       -- 骰子 level 4
    BladeFlurry = 13877,        -- 剑刃乱舞
    AdrenalineRush = 13750,     -- 冲动
    Opportunity = 195627,       -- 可乘之机
    Sharpened = 441786,         -- 锋化之刃
    CripplingPoison = 315584,   -- 速效毒药
    InstantPoison = 381637,     -- 萎缩毒药
    LoadedDice = 256171,        -- 灌铅骰子
}

--============================================================
-- 5. Debuff ID定义
--============================================================
local DEBUFF = {
    Panic = 441224,             -- 惊慌
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower

local function GetComboPoints()
    return GetUnitPower("player", "combopoints")
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateOutlawRotation()

    -- 检查是否有任何骰子buff
    local function HasAnyRollBuff()
        return HasBuff(BUFF.RollLevel1, "player") 
            or HasBuff(BUFF.RollLevel2, "player") 
            or HasBuff(BUFF.RollLevel3, "player") 
            or HasBuff(BUFF.RollLevel4, "player")
    end
    
    -- 查找30码内有惊慌debuff的目标
    local function FindPanicTarget()
        local results = {GetActiveEnemyAmount(30, false)}
        local count = results[1]
        for i = 2, count + 1 do
            local unit = results[i]
            if HasDebuff(DEBUFF.Panic, unit) then
                return unit
            end
        end
        return nil
    end

    local function Rotation()
		
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(8, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(NCF.GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local cp = GetComboPoints()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 常用状态缓存
        local inCombat = UnitAffectingCombat("player")
        local hasBladeFlurry = HasBuff(BUFF.BladeFlurry, "player")
        local hasAdrenalineRush = HasBuff(BUFF.AdrenalineRush, "player")
        local opportunityStacks = GetBuffStacks(BUFF.Opportunity, "player")
        local sharpenedStacks = GetBuffStacks(BUFF.Sharpened, "player")
        local hasRollLevel1 = HasBuff(BUFF.RollLevel1, "player")
        local hasRollLevel2 = HasBuff(BUFF.RollLevel2, "player")
        
        --==========================================================
        -- 脱战准备
        --==========================================================
        if not inCombat then
            -- 速效毒药
            if not HasBuff(BUFF.CripplingPoison, "player") and IsReady(SPELL.CripplingPoison) then
                return "spell", SPELL.CripplingPoison
            end
            -- 萎缩毒药
            if HasTalent(TALENT.InstantPoison) and not HasBuff(BUFF.InstantPoison, "player") and IsReady(SPELL.InstantPoison) then
                return "spell", SPELL.InstantPoison
            end
        end
        
		
		--自动潜行
		if not UnitAffectingCombat("player") and not IsMounted() and not IsStealthed() 
            and not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            if IsReady(SPELL.Stealth) and not ShouldSkipSpell(SPELL.Stealth) then
                return "spell", SPELL.Stealth
            end
        end

		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
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
        -- 饰品: 有冲动buff时使用
        --==========================================================
        if NCF.burstModeEnabled and hasAdrenalineRush then
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
        -- 骰子逻辑
        --==========================================================
        if IsReady(SPELL.RollTheBones) and not ShouldSkipSpell(SPELL.RollTheBones) then
            -- 没有任何骰子buff
            if not HasAnyRollBuff() then
                return "spell", SPELL.RollTheBones
            end
            
            -- 有level 1或2 buff 且 有灌铅骰子天赋
            if (hasRollLevel1 or hasRollLevel2) and HasBuff(BUFF.LoadedDice) then
                return "spell", SPELL.RollTheBones
            end
            
            -- 只有level 1 buff
            if hasRollLevel1 and not hasRollLevel2 then
                return "spell", SPELL.RollTheBones
            end
        end
        
        --==========================================================
        -- AOE (8码内敌人 > 1)
        --==========================================================
        if enemyCount > 1 then
            -- 剑刃乱舞: 没有buff
            if not hasBladeFlurry and IsReady(SPELL.BladeFlurry) and not ShouldSkipSpell(SPELL.BladeFlurry) then
                return "spell", SPELL.BladeFlurry
            end
            
            -- 剑刃乱舞: 连击点 <= 2 且 有buff
            if hasBladeFlurry and cp <= 2 and IsReady(SPELL.BladeFlurry) and not ShouldSkipSpell(SPELL.BladeFlurry) then
                return "spell", SPELL.BladeFlurry
            end
            
            -- 刀锋冲刺: 有剑刃乱舞buff 且 离目标 <= 5码 (需天赋)
            if hasBladeFlurry and HasTalent(TALENT.BladeRush) and NCF.GetDistanceToTarget("target") <= 5 and IsReady(SPELL.BladeRush) and not ShouldSkipSpell(SPELL.BladeRush) then
                return "spell", SPELL.BladeRush
            end
        end
        
        --==========================================================
        -- 主循环
        --==========================================================
        
        -- 影舞步: 连击点 >= 7 (需天赋)
        if cp >= 7 and HasTalent(TALENT.ShadowDance) and IsReady(SPELL.ShadowDance) and not ShouldSkipSpell(SPELL.ShadowDance) then
            return "spell", SPELL.ShadowDance
        end
        
        -- 命中眉心: 连击点 >= 6, 优先有惊慌debuff的目标
        if cp >= 6 and IsReady(SPELL.BetweenTheEyes) and not ShouldSkipSpell(SPELL.BetweenTheEyes) then
            local panicTarget = FindPanicTarget()
            if panicTarget then
                return "InstantSpell", SPELL.BetweenTheEyes, panicTarget
            elseif UnitExists("target") and not UnitIsDead("target") then
                return "InstantSpell", SPELL.BetweenTheEyes, "target"
            end
        end
        
        -- 斩击/致命一击: 连击点 >= 6 且 影舞步在冷却中
        local shadowDanceCD = GetSpellCooldownRemain(SPELL.ShadowDance)
        if cp >= 6 and (shadowDanceCD > gcd or ShouldSkipSpell(SPELL.ShadowDance)) then
            -- 致命一击: 锋化之刃 >= 4 且 有致命一击天赋
            if sharpenedStacks >= 4 and HasTalent(TALENT.CoupDeGrace) and IsReady(SPELL.CoupDeGrace) and not ShouldSkipSpell(SPELL.CoupDeGrace) then
                return "spell", SPELL.CoupDeGrace
            end
            
            -- 斩击
            if IsReady(SPELL.Dispatch) and not ShouldSkipSpell(SPELL.Dispatch) then
                return "spell", SPELL.Dispatch
            end
        end
        
        -- 刀锋冲刺: 离目标 <= 5码 (需天赋)
        if HasTalent(TALENT.BladeRush) and NCF.GetDistanceToTarget("target") <= 5 and IsReady(SPELL.BladeRush) and not ShouldSkipSpell(SPELL.BladeRush) then
            return "spell", SPELL.BladeRush
        end
        
        -- 冲动: TTD > 15秒
        if NCF.MeetsSpellTTD(SPELL.AdrenalineRush) and IsReady(SPELL.AdrenalineRush) and not ShouldSkipSpell(SPELL.AdrenalineRush) then
            return "spell", SPELL.AdrenalineRush
        end
        
        -- 手枪射击: 可乘之机buff >= 3 且 连击点 <= 3
        if opportunityStacks >= 3 and cp <= 3 and IsReady(SPELL.PistolShot) and not ShouldSkipSpell(SPELL.PistolShot) then
            return "spell", SPELL.PistolShot
        end
        
        -- 影袭: 连击点 <= 5
        if cp <= 5 and IsReady(SPELL.SinisterStrike) and not ShouldSkipSpell(SPELL.SinisterStrike) then
            return "spell", SPELL.SinisterStrike
        end
        
        -- 影袭: 影舞步ready 且 连击点 <= 6
        local shadowDanceReady = GetSpellCooldownRemain(SPELL.ShadowDance) <= gcd
        if shadowDanceReady and cp <= 6 and IsReady(SPELL.SinisterStrike) and not ShouldSkipSpell(SPELL.SinisterStrike) then
            return "spell", SPELL.SinisterStrike
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateOutlawRotation()