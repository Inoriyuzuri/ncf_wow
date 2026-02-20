--============================================================
-- 浩劫恶魔猎手循环 (Havoc Demon Hunter APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

机制说明：
- 眼棱后进入7秒恶魔形态(162264)，混乱打击→死亡横扫，刃舞→毁灭
- 恶魔变形后进入20秒恶魔形态，眼棱→深渊凝视，献祭光环→吞噬之焰
- 第一次释放死亡横扫/毁灭/深渊凝视/吞噬之焰会施加魔涌dot

恶魔变形后流程：
1. 死亡横扫 (施加dot)
2. 毁灭 (施加dot)
3. 深渊凝视 (触发新一轮强化)
4. 死亡横扫 (再次施加dot)
5. 毁灭 (再次施加dot)
6. 吞噬之焰随时穿插

眼棱后流程：
1. 死亡横扫 (施加dot)
2. 毁灭 (施加dot)

0. 打断 - 瓦解 (183752): 10码，需面朝
1. 恶魔追击 (370965) [爆发]
2. 死亡横扫 (210152): 需要施加dot时优先
3. 毁灭 (201427): 需要施加dot时优先
4. 深渊凝视 (452497): 恶魔变形后，死亡横扫和毁灭都打完后使用
5. 吞噬之焰 (452487): 恶魔形态下随时穿插
6. 恶魔变形 (191427) [爆发]
7. 眼棱 (198013): 无恶魔形态时
8. 献祭光环 (258920): 目标无dot 且 充能 > 1
9. 刃舞 (188499): 怒气 >= 40
10. 混乱打击 (162794): 怒气 >= 40
11. 邪能之刃 (232893): 填充

Buff/Debuff ID 参考:
- 恶魔形态: 162264
- 献祭dot: 258920
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("DEMONHUNTER", 1, {
    -- 爆发技能
    { id = 370965, name = "恶魔追击", default = "burst" },
    { id = 191427, name = "恶魔变形", default = "burst" },
    
    -- 普通技能
    { id = 183752, name = "瓦解", default = "normal" },
    { id = 210152, name = "死亡横扫", default = "normal" },
    { id = 201427, name = "毁灭", default = "normal" },
    { id = 198013, name = "眼棱", default = "normal" },
    { id = 452497, name = "深渊凝视", default = "normal" },
    { id = 452487, name = "吞噬之焰", default = "normal" },
    { id = 258920, name = "献祭光环", default = "normal" },
    { id = 188499, name = "刃舞", default = "normal" },
    { id = 162794, name = "混乱打击", default = "normal" },
    { id = 232893, name = "邪能之刃", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Disrupt = 183752,               -- 瓦解 (打断)
    ThrowGlaive = 370965,           -- 恶魔追击
    DeathSweep = 210152,            -- 死亡横扫 (刃舞升级)
    Annihilation = 201427,          -- 毁灭 (混乱打击升级)
    EyeBeam = 198013,               -- 眼棱
    AbyssGaze = 452497,             -- 深渊凝视 (眼棱升级)
    ConsumingFlame = 452487,        -- 吞噬之焰 (献祭光环升级)
    Metamorphosis = 191427,         -- 恶魔变形
    ImmolationAura = 258920,        -- 献祭光环
    BladeDance = 188499,            -- 刃舞
    ChaosStrike = 162794,           -- 混乱打击
    DemonsBite = 232893,            -- 邪能之刃
}

--============================================================
-- 3. Buff/Debuff ID定义
--============================================================
local BUFF = {
    Metamorphosis = 162264,         -- 恶魔形态
}

local DEBUFF = {
    ImmolationAura = 258920,        -- 献祭dot
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

local function GetFury()
    return GetUnitPower("player", "fury")
end

--============================================================
-- 5. Dot追踪变量
--============================================================
local needDeathSweep = false      -- 是否需要打死亡横扫 (施加dot)
local needAnnihilation = false    -- 是否需要打毁灭 (施加dot)
local needAbyssGaze = false       -- 是否需要打深渊凝视 (恶魔变形后)
local lastMetaState = false       -- 上一次恶魔形态状态
local isFullMetamorphosis = false -- 是否是恶魔变形触发的完整形态 (有吞噬之焰/深渊凝视)

--============================================================
-- 6. 主循环
--============================================================
local function CreateHavocRotation()

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(8, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(NCF.GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local fury = GetFury()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 检查恶魔形态
        local inMetamorphosis = HasBuff(BUFF.Metamorphosis)
        
        -- 获取上一个释放的技能
        local lastSpell = _G.LastCastedSpell
        
        -- 追踪眼棱/深渊凝视后的dot需求
        if lastSpell == SPELL.EyeBeam then
            needDeathSweep = true
            needAnnihilation = true
            -- 眼棱触发的是短暂形态，没有吞噬之焰/深渊凝视
            if not isFullMetamorphosis then
                isFullMetamorphosis = false
            end
        end
        
        if lastSpell == SPELL.AbyssGaze then
            needDeathSweep = true
            needAnnihilation = true
        end
        
        -- 追踪恶魔变形后的深渊凝视需求
        if lastSpell == SPELL.Metamorphosis then
            needDeathSweep = true
            needAnnihilation = true
            needAbyssGaze = true
            isFullMetamorphosis = true  -- 恶魔变形触发的完整形态
        end
        
        -- 打完后重置标记
        if lastSpell == SPELL.DeathSweep then
            needDeathSweep = false
        end
        if lastSpell == SPELL.Annihilation then
            needAnnihilation = false
        end
        if lastSpell == SPELL.AbyssGaze then
            needAbyssGaze = false
        end
        
        -- 恶魔形态消失时重置所有标记
        if lastMetaState and not inMetamorphosis then
            needDeathSweep = false
            needAnnihilation = false
            needAbyssGaze = false
            isFullMetamorphosis = false
        end
        lastMetaState = inMetamorphosis
        
        -- 0. 打断：10码内面前有可打断的敌人
        if IsReady(SPELL.Disrupt) and not ShouldSkipSpell(SPELL.Disrupt) then
            local interruptTarget = NCF.GetInterruptTarget(10, true)
            if interruptTarget then
                return "spell", SPELL.Disrupt, interruptTarget
            end
        end
		
        --爆发
		if NCF.burstModeEnabled and inMetamorphosis then
            if NCF.enablePotion then 
				NCF.UseCombatPotion()
			end
			NCF.UseTrinket()
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
		end
		
		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end
		
        -- 1. 恶魔追击 [爆发]
        if IsReady(SPELL.ThrowGlaive) and not ShouldSkipSpell(SPELL.ThrowGlaive) then
            return "spell", SPELL.ThrowGlaive
        end
        
        -- 恶魔形态下的优先级
        if inMetamorphosis then
            -- 2. 死亡横扫 (需要施加dot时优先), 怒气 >= 35
            if needDeathSweep and fury >= 35 and IsReady(SPELL.DeathSweep) and not ShouldSkipSpell(SPELL.DeathSweep) then
                return "spell", SPELL.DeathSweep
            end
            
            -- 3. 毁灭 (需要施加dot时优先), 怒气 >= 40
            if needAnnihilation and fury >= 40 and IsReady(SPELL.Annihilation) and not ShouldSkipSpell(SPELL.Annihilation) then
                return "spell", SPELL.Annihilation
            end
            
            -- 以下技能只在恶魔变形触发的完整形态下可用
            if isFullMetamorphosis then
                -- 4. 深渊凝视 (死亡横扫和毁灭都打完后), 怒气 <= 60
                if needAbyssGaze and not needDeathSweep and not needAnnihilation and fury <= 60 and IsReady(SPELL.AbyssGaze) and not ShouldSkipSpell(SPELL.AbyssGaze) then
                    return "spell", SPELL.AbyssGaze
                end
                
                -- 5. 吞噬之焰 (随时穿插), 充能 >= 1, 怒气 <= 70
                local consumingFlameCharges = GetSpellCharges(SPELL.ConsumingFlame)
                if fury <= 70 and consumingFlameCharges >= 1 and IsReady(SPELL.ConsumingFlame) and not ShouldSkipSpell(SPELL.ConsumingFlame) then
                    return "spell", SPELL.ConsumingFlame
                end
            end
            
            -- 常规死亡横扫, 怒气 >= 35
            if fury >= 35 and IsReady(SPELL.DeathSweep) and not ShouldSkipSpell(SPELL.DeathSweep) then
                return "spell", SPELL.DeathSweep
            end
            
            -- 常规毁灭, 怒气 >= 40
            if fury >= 40 and IsReady(SPELL.Annihilation) and not ShouldSkipSpell(SPELL.Annihilation) then
                return "spell", SPELL.Annihilation
            end
        end
        
		-- 7. 眼棱, 能量 > 30 且 (怒气 <= 60 或 恶魔变形即将可用)
        local metaReady = IsReady(SPELL.Metamorphosis) and not ShouldSkipSpell(SPELL.Metamorphosis)
        if fury > 30 and (fury <= 60 or metaReady) and IsReady(SPELL.EyeBeam) and not ShouldSkipSpell(SPELL.EyeBeam) then
            return "spell", SPELL.EyeBeam
        end
		
        -- 6. 恶魔变形 [爆发], 眼棱不可用时才释放
        local eyeBeamReady = IsReady(SPELL.EyeBeam) and not ShouldSkipSpell(SPELL.EyeBeam)
        if NCF.MeetsSpellTTD(SPELL.Metamorphosis) and not eyeBeamReady and IsReady(SPELL.Metamorphosis) and not ShouldSkipSpell(SPELL.Metamorphosis) then
            return "spell", SPELL.Metamorphosis
        end
        
        
        -- 8. 献祭光环, 目标无dot 且 充能 > 1 且 怒气 <= 70
        local immolationCharges = GetSpellCharges(SPELL.ImmolationAura)
        if fury <= 70 and immolationCharges > 1 and IsReady(SPELL.ImmolationAura) and not ShouldSkipSpell(SPELL.ImmolationAura) then
            return "spell", SPELL.ImmolationAura
        end
        
        -- 9. 刃舞, 怒气 >= 40
        if fury >= 40 and IsReady(SPELL.BladeDance) and not ShouldSkipSpell(SPELL.BladeDance) then
            return "spell", SPELL.BladeDance
        end
        
        -- 10. 混乱打击, 怒气 >= 40
        if fury >= 40 and IsReady(SPELL.ChaosStrike) and not ShouldSkipSpell(SPELL.ChaosStrike) then
            return "spell", SPELL.ChaosStrike
        end
        
        -- 11. 邪能之刃 (填充)
        if IsReady(SPELL.DemonsBite) and not ShouldSkipSpell(SPELL.DemonsBite) then
            return "spell", SPELL.DemonsBite
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateHavocRotation()