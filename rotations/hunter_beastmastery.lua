--============================================================
-- 兽王猎人循环 (Beast Mastery Hunter APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

=== Buff 说明 ===
三个 buff 都是加强杀戮命令并召唤对应野兽:
- 飞龙: 471878
- 野猪: 472324
- 巨熊: 472325

=== 技能说明 ===
- 杀戮命令 (34026): 找 8 码范围内有最多敌人的目标, 返回 InstantSpell
- 倒刺射击 (217200): 找没有倒刺射击 dot 的目标, 返回 InstantSpell
- 眼镜蛇射击 (193455)
- 狂野鞭笞 (1264359)
- 狂野怒火 (19574)
- 反制射击 (147362): 打断
- 召唤宠物 (883)

=== 优先级 ===
0.  召唤宠物 (883): 没有宠物时
1.  打断 - 反制射击 (147362)
2.  饰品 + 种族技能: 有狂野怒火 buff (19574) 时
3.  猎人印记 (257284): Boss 在场且没有任何目标有此 debuff
4.  倒刺射击 (217200): 充能 > 1.9
5.  倒刺射击 (217200): 充能 > 1 且 狂野怒火 ready
6.  狂野鞭笞 (1264359)
7.  狂野怒火 (19574)
8.  杀戮命令 (34026): 充能 > 1.8
9.  倒刺射击 (217200): 充能 > 1
10. 杀戮命令 (34026)
11. 眼镜蛇射击 (193455)

=== Buff ID 参考 ===
- 飞龙召唤: 471878
- 野猪召唤: 472324
- 巨熊召唤: 472325
- 狂野怒火: 19574

=== Debuff ID 参考 ===
- 倒刺射击: 217200
- 猎人印记: 257284
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("HUNTER", 1, {
    -- 冷却技能
    { id = 19574, name = "狂野怒火", default = "burst" },
    
    -- 普通技能
    { id = 883, name = "召唤宠物", default = "normal" },
    { id = 147362, name = "反制射击", default = "normal" },
    { id = 257284, name = "猎人印记", default = "normal" },
    { id = 217200, name = "倒刺射击", default = "normal" },
    { id = 1264359, name = "狂野鞭笞", default = "normal" },
    { id = 34026, name = "杀戮命令", default = "normal" },
    { id = 193455, name = "眼镜蛇射击", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    CallPet = 883,              -- 召唤宠物
    CounterShot = 147362,       -- 反制射击
    HuntersMark = 257284,       -- 猎人印记
    BarbedShot = 217200,        -- 倒刺射击
    DireBeast = 1264359,        -- 狂野鞭笞
    BestialWrath = 19574,       -- 狂野怒火
    KillCommand = 34026,        -- 杀戮命令
    CobraShot = 193455,         -- 眼镜蛇射击
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    DragonhawkSummon = 471878,  -- 飞龙召唤
    BoarSummon = 472324,        -- 野猪召唤
    BearSummon = 472325,        -- 巨熊召唤
    BestialWrath = 19574,       -- 狂野怒火
}

--============================================================
-- 4. Debuff ID定义
--============================================================
local DEBUFF = {
    BarbedShot = 217200,        -- 倒刺射击
    HuntersMark = 257284,       -- 猎人印记
}

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetPetExists = NCF.GetPetExists
local GetEnemyWithoutDebuff = NCF.GetEnemyWithoutDebuff
local GetBestAOETarget = NCF.GetBestAOETarget
local IsInBossFight = NCF.IsInBossFight

--============================================================
-- 6. 主循环
--============================================================
local function CreateBMRotation()

    -- 检查范围内是否有目标有猎人印记
    local function AnyTargetHasHuntersMark()
        local results = {GetActiveEnemyAmount(40, false)}
        local count = results[1]
        for i = 2, count + 1 do
            local unit = results[i]
            if HasDebuff(DEBUFF.HuntersMark, unit) then
                return true
            end
        end
        return false
    end

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(40, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 常用状态缓存
        local hasBestialWrath = HasBuff(BUFF.BestialWrath, "player")
        local bestialWrathCD = GetSpellCooldownRemain(SPELL.BestialWrath)
        local barbedShotCharges = GetSpellCharges(SPELL.BarbedShot)
        local killCommandCharges = GetSpellCharges(SPELL.KillCommand)
        
        -- 射程检查 (用眼镜蛇射击40码作为基准)
        local targetInRange = NCF.IsSpellInRange(SPELL.CobraShot, "target")
        
        -- 目标缓存 (带射程过滤，务必传入 spellID)
        local bestAOETarget = NCF.smartTargetEnabled and GetBestAOETarget(8, 40, false, SPELL.KillCommand) or "target"
        local barbedTarget = GetEnemyWithoutDebuff(DEBUFF.BarbedShot, 40, false, SPELL.BarbedShot) or "target"
        
        --==========================================================
        -- 0. 召唤宠物: 没有宠物时
        --==========================================================
        if not GetPetExists() and IsReady(SPELL.CallPet) and not ShouldSkipSpell(SPELL.CallPet) then
            return "spell", SPELL.CallPet
        end
        
        --==========================================================
        -- 1. 打断: 反制射击 40码 不需要面朝
        --==========================================================
        if IsReady(SPELL.CounterShot) and not ShouldSkipSpell(SPELL.CounterShot) then
            local interruptTarget = NCF.GetInterruptTarget(40, false)
            if interruptTarget then
                return "InstantSpell", SPELL.CounterShot, interruptTarget
            end
        end
        
        --==========================================================
        -- 2. 饰品 + 种族技能: 有狂野怒火 buff 时
        --==========================================================
        if NCF.burstModeEnabled and hasBestialWrath then
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
        -- 3. 猎人印记: Boss 在场且没有任何目标有此 debuff
        --==========================================================
        if IsInBossFight() and not AnyTargetHasHuntersMark() and IsReady(SPELL.HuntersMark) and not ShouldSkipSpell(SPELL.HuntersMark) then
            -- 给 boss1 上印记
            for i = 1, 5 do
                local bossUnit = "boss" .. i
                if UnitExists(bossUnit) and not UnitIsDead(bossUnit) then
                    return "InstantSpell", SPELL.HuntersMark, bossUnit
                end
            end
        end
        
		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end
		
        --==========================================================
        -- 4. 倒刺射击: 充能 > 1.9
        --==========================================================
        if barbedShotCharges > 1.9 and IsReady(SPELL.BarbedShot) and not ShouldSkipSpell(SPELL.BarbedShot) then
            return "InstantSpell", SPELL.BarbedShot, barbedTarget
        end
        
        --==========================================================
        -- 5. 倒刺射击: 充能 > 1 且 狂野怒火 ready
        --==========================================================
        if barbedShotCharges > 1 and bestialWrathCD <= gcd and IsReady(SPELL.BarbedShot) and not ShouldSkipSpell(SPELL.BarbedShot) then
            return "InstantSpell", SPELL.BarbedShot, barbedTarget
        end
        
        --==========================================================
        -- 6. 狂野鞭笞
        --==========================================================
        if IsReady(SPELL.DireBeast) and not ShouldSkipSpell(SPELL.DireBeast) then
            return "spell", SPELL.DireBeast
        end
        
        --==========================================================
        -- 7. 狂野怒火: 爆发保护 (UI可配置)
        --==========================================================
        if NCF.MeetsSpellTTD(SPELL.BestialWrath) and IsReady(SPELL.BestialWrath) and not ShouldSkipSpell(SPELL.BestialWrath) then
            return "spell", SPELL.BestialWrath
        end
        
        --==========================================================
        -- 8. 杀戮命令: 充能 > 1.8
        --==========================================================
        if killCommandCharges > 1.8 and IsReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
            return "InstantSpell", SPELL.KillCommand, bestAOETarget
        end
        
        --==========================================================
        -- 9. 倒刺射击: 充能 > 1
        --==========================================================
        if barbedShotCharges > 1 and IsReady(SPELL.BarbedShot) and not ShouldSkipSpell(SPELL.BarbedShot) then
            return "InstantSpell", SPELL.BarbedShot, barbedTarget
        end
        
        --==========================================================
        -- 10. 杀戮命令
        --==========================================================
        if IsReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
            return "InstantSpell", SPELL.KillCommand, bestAOETarget
        end
        
        --==========================================================
        -- 11. 眼镜蛇射击
        --==========================================================
        if targetInRange and IsReady(SPELL.CobraShot) and not ShouldSkipSpell(SPELL.CobraShot) then
            return "spell", SPELL.CobraShot
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateBMRotation()