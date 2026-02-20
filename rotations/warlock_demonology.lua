--============================================================
-- 恶魔术士循环 (Demonology Warlock APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

0. 召唤宠物
   - 召唤恶魔卫士 (30146): 宠物不存在

1. 打断
   - 巨斧投掷 (119914): 35码内有可打断目标，无需面朝

2. 古尔丹之手 (105174): 灵魂碎片 >= 3
2.5. 魔典：邪能破坏者 (1276467): 灵魂碎片 >= 1
3. 召唤末日守卫 (1276672): 灵魂碎片 >= 1，有末日降临天赋
4. 召唤恶魔猎犬 (104316): 如果有末日降临天赋，末日守卫CD>10时才放
5. 召唤恶魔暴君 (265187): 如果有末日降临天赋，末日守卫CD>10时才放
6. 古尔丹之手 (105174): 有陨灭 buff
7. 内爆 (196277): 野生小鬼 >= 6 且 敌人 >= 3
8. 恶魔之箭 (264178): 恶魔之核 >= 1
9. 暗影箭 (686): 有狱火箭 buff 且 灵魂碎片 <= 2
10. 暗影箭 (686): 填充

Buff ID 参考:
- 陨灭: 433885
- 野生小鬼: 296553
- 恶魔之核: 264173
- 狱火箭: 433891

天赋 ID 参考:
- 末日降临: 460551
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("WARLOCK", 2, {
    -- 爆发技能
    { id = 265187, name = "召唤恶魔暴君", default = "burst" },
    { id = 104316, name = "召唤恶魔猎犬", default = "burst" },
    { id = 1276672, name = "召唤末日守卫", default = "burst" },
    
    -- 普通技能
    { id = 30146, name = "召唤恶魔卫士", default = "normal" },
    { id = 333889, name = "恶魔支配", default = "normal" },
    { id = 119914, name = "巨斧投掷", default = "normal" },
    { id = 105174, name = "古尔丹之手", default = "normal" },
    { id = 196277, name = "内爆", default = "normal" },
    { id = 264178, name = "恶魔之箭", default = "normal" },
    { id = 686, name = "暗影箭", default = "normal" },
    { id = 1276467, name = "魔典：邪能破坏者", default = "normal" },
	{ id = 132409, name = "法术封锁", default = "normal" },
    { id = 111400, name = "血跑", default = "normal" },
    { id = 20707, name = "灵魂石", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    SummonFelguard = 30146,     -- 召唤恶魔卫士
    FelDomination = 333889,     -- 恶魔支配
    AxeToss = 119914,           -- 巨斧投掷
    HandOfGuldan = 105174,      -- 古尔丹之手
    SummonDemonicTyrant = 265187, -- 召唤恶魔暴君
    SummonDemonic = 104316,     -- 召唤恶魔猎犬
    Implosion = 196277,         -- 内爆
    DemonicBolt = 264178,       -- 恶魔之箭
    ShadowBolt = 686,           -- 暗影箭
    SummonDoomguard = 1276672,  -- 召唤末日守卫 (天赋)
    GrimoireFelguard = 1276467, -- 魔典：邪能破坏者 (天赋)
	CounterSpell = 132409,
    BurningRush = 111400,         -- 血跑
    Soulstone = 20707,            -- 灵魂石
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    Annihilation = 433885,      -- 陨灭
    WildImps = 296553,          -- 野生小鬼
    DemonicCore = 264173,       -- 恶魔之核
    InfernalBolt = 433891,      -- 狱火箭
	AbyssalDominate = 456323,    --深渊支配
	CounterSpellActive = 1276610, --魔典正在生效
    BurningRush = 111400,       -- 血跑
}

--============================================================
-- 4. 天赋ID定义
--============================================================
local TALENT = {
    Doomsday = 460551,          -- 末日降临
}

local DEBUFF = {
    Doom = 460553,              -- 末日降临 (debuff)
}

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local GetDebuffRemain = NCF.GetDebuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetPetExists = NCF.GetPetExists
local GetUnitPower = NCF.GetUnitPower
local HasTalent = NCF.HasTalent

local function GetSoulShards()
    return GetUnitPower("player", "soulshards")
end

--============================================================
-- 6. 主循环
--============================================================
local function CreateDemonologyRotation()

    -- 移动检测变量
    local lastMovingState = false
    local stateChangeTime = 0

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(40, true)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(NCF.GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local shards = GetSoulShards()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 血跑自动开关
        local isMoving = GetUnitSpeed("player") > 0
        local hasBurningRush = HasBuff(BUFF.BurningRush, "player")
        local now = GetTime()
        
        -- 检测移动状态变化
        if isMoving ~= lastMovingState then
            lastMovingState = isMoving
            stateChangeTime = now
        end
        
        local stateDuration = now - stateChangeTime
        
        -- 移动超过1秒，开启血跑
        if isMoving and stateDuration > 0.45 and not hasBurningRush then
            if IsReady(SPELL.BurningRush) and not ShouldSkipSpell(SPELL.BurningRush) then
                return "spell", SPELL.BurningRush
            end
        end
        
        -- 站定超过1秒，关闭血跑
        if not isMoving and stateDuration > 0.45 and hasBurningRush then
            if IsReady(SPELL.BurningRush) and not ShouldSkipSpell(SPELL.BurningRush) then
                return "spell", SPELL.BurningRush
            end
        end
        
        -- 灵魂石: 鼠标指向死亡的友方目标
        if UnitExists("mouseover") and UnitIsDead("mouseover") and UnitIsFriend("player", "mouseover") then
            if IsReady(SPELL.Soulstone) and not ShouldSkipSpell(SPELL.Soulstone) then
                return "spell", SPELL.Soulstone, "mouseover"
            end
        end
        
        -- 0. 召唤恶魔卫士, if 宠物不存在
        if not GetPetExists() then
            -- 先用恶魔支配
            if IsReady(SPELL.FelDomination) and not ShouldSkipSpell(SPELL.FelDomination) then
                return "spell", SPELL.FelDomination
            end
            -- 再召唤宠物
            if IsReady(SPELL.SummonFelguard) and not ShouldSkipSpell(SPELL.SummonFelguard) then
                return "spell", SPELL.SummonFelguard
            end
        end
        
		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end
		
        -- 1. 打断：40码内有可打断的敌人 (需面朝)
		if IsReady(SPELL.CounterSpell) and HasBuff(BUFF.CounterSpellActive) and not ShouldSkipSpell(SPELL.CounterSpell) then
            local interruptTarget = NCF.GetInterruptTarget(40, true)
            if interruptTarget then
                return "spell", SPELL.CounterSpell, interruptTarget
            end
        end
		
        -- 1. 打断：35码内有可打断的敌人 (无需面朝)
        if IsReady(SPELL.AxeToss) and not ShouldSkipSpell(SPELL.AxeToss) and not IsReady(SPELL.CounterSpell) then
            local interruptTarget = NCF.GetInterruptTarget(35, false)
            if interruptTarget then
                return "spell", SPELL.AxeToss, interruptTarget
            end
        end
        
		-- SP，爆发技能
		if NCF.burstModeEnabled and HasBuff(BUFF.AbyssalDominate) then
            if NCF.enablePotion then 
				NCF.UseCombatPotion()
			end
			NCF.UseTrinket()
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end
		
        -- 2. 古尔丹之手, if 灵魂碎片 >= 3
        -- 找末日降临debuff持续时间最短的目标释放，如果都没有debuff就正常对目标释放
        if shards >= 3 and IsReady(SPELL.HandOfGuldan) and not ShouldSkipSpell(SPELL.HandOfGuldan) then
			return "spell", SPELL.HandOfGuldan
        end
        
        -- 2.5 魔典：邪能破坏者 (天赋), 灵魂碎片 >= 1
        if shards >= 1 and IsReady(SPELL.GrimoireFelguard) and not HasBuff(BUFF.CounterSpellActive) and not ShouldSkipSpell(SPELL.GrimoireFelguard) then
            return "spell", SPELL.GrimoireFelguard
        end
        
        -- 3. 召唤末日守卫 (天赋), 灵魂碎片 >= 1
        if NCF.MeetsSpellTTD(SPELL.SummonDoomguard) and shards >= 1 and HasTalent(TALENT.Doomsday) and IsReady(SPELL.SummonDoomguard) and not ShouldSkipSpell(SPELL.SummonDoomguard) then
            return "spell", SPELL.SummonDoomguard
        end
        
        -- 4. 召唤恶魔猎犬
        if NCF.MeetsSpellTTD(SPELL.SummonDemonic) and IsReady(SPELL.SummonDemonic) and not ShouldSkipSpell(SPELL.SummonDemonic) then
            -- 如果有末日守卫天赋，等末日守卫CD好了再放
            if HasTalent(TALENT.Doomsday) then
                if GetSpellCooldownRemain(SPELL.SummonDoomguard) > 10 then
                    return "spell", SPELL.SummonDemonic
                end
                -- 否则不放，等末日守卫
            else
                -- 没有末日守卫天赋，直接放
                return "spell", SPELL.SummonDemonic
            end
        end
        
        -- 5. 召唤恶魔暴君
        if NCF.MeetsSpellTTD(SPELL.SummonDemonicTyrant) and IsReady(SPELL.SummonDemonicTyrant) and not ShouldSkipSpell(SPELL.SummonDemonicTyrant) then
            if HasTalent(TALENT.Doomsday) then
                if GetSpellCooldownRemain(SPELL.SummonDoomguard) > 10 then
                    return "spell", SPELL.SummonDemonicTyrant
                end
            else
                return "spell", SPELL.SummonDemonicTyrant
            end
        end
        
        -- 6. 古尔丹之手, if 有陨灭 buff
        if HasBuff(BUFF.Annihilation) and IsReady(SPELL.HandOfGuldan) and not ShouldSkipSpell(SPELL.HandOfGuldan) then
            return "spell", SPELL.HandOfGuldan
        end
        
        -- 7. 内爆, if 野生小鬼 >= 6 且 敌人 >= 3
        local impStacks = GetBuffStacks(BUFF.WildImps)
        if impStacks >= 6 and enemyCount >= 3 and IsReady(SPELL.Implosion) and not ShouldSkipSpell(SPELL.Implosion) then
            return "spell", SPELL.Implosion
        end
        
        -- 8. 恶魔之箭, if 恶魔之核 >= 1
        -- 优先找没有末日降临debuff的目标
        local coreStacks = GetBuffStacks(BUFF.DemonicCore)
        if coreStacks >= 1 and IsReady(SPELL.DemonicBolt) and not ShouldSkipSpell(SPELL.DemonicBolt) then
            -- 优先找没有Doom debuff的目标
            local noDoomTarget = NCF.GetEnemyWithoutDebuff(DEBUFF.Doom, 40, true, SPELL.DemonicBolt)
            if noDoomTarget then
                return "spell", SPELL.DemonicBolt, noDoomTarget
            end
            -- 都有debuff，对当前目标释放
            return "spell", SPELL.DemonicBolt
        end
        
        -- 9. 暗影箭, if 有狱火箭 buff 且 灵魂碎片 <= 2
        if HasBuff(BUFF.InfernalBolt) and shards <= 2 and IsReady(SPELL.ShadowBolt) and not ShouldSkipSpell(SPELL.ShadowBolt) then
            return "spell", SPELL.ShadowBolt
        end
        
        -- 10. 暗影箭 (填充)
        if IsReady(SPELL.ShadowBolt) and not ShouldSkipSpell(SPELL.ShadowBolt) then
            return "spell", SPELL.ShadowBolt
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateDemonologyRotation()