--============================================================
-- Frost Mage Rotation
-- Version 12.0
-- 
-- Talent Branches:
-- - Frostfire AOE (talent.frostfire_bolt AND enemies >= 3)
-- - Frostfire ST (talent.frostfire_bolt)
-- - Spellslinger AOE (enemies >= 3)
-- - Spellslinger ST (default)
--============================================================

--[[
===================================
Frostfire AOE
===================================
1. Comet Storm
2. Ray of Frost: fight_remains < 12
3. Flurry: cooldown_react AND no Thermal Void buff
4. Frozen Orb
5. Glacial Spike
6. Blizzard
7. Ice Lance: Fingers of Frost proc
8. Ice Lance: Freezing stacks >= 10
9. Frostbolt: Frostfire Empowerment OR prev Glacial Spike
10. Ray of Frost
11. Frostbolt (filler)

===================================
Frostfire ST
===================================
1. Comet Storm
2. Ray of Frost: fight_remains < 12
3. Flurry: cooldown_react AND no Thermal Void buff
4. Frozen Orb
5. Glacial Spike
6. Blizzard: Freezing Rain buff
7. Ice Lance: Fingers of Frost proc
8. Ice Lance: Freezing stacks >= 10
9. Ray of Frost
10. Frostbolt (filler)

===================================
Spellslinger AOE
===================================
1. Comet Storm
2. Ray of Frost: fight_remains < 12
3. Blizzard: Freezing Rain buff
4. Flurry: cooldown_react AND Brain Freeze AND no Thermal Void buff
5. Frozen Orb
6. Glacial Spike
7. Blizzard: no Splinterstorm AND (Freezing Rain OR Freezing Winds OR enemies >= 7)
8. Ice Lance: Fingers of Frost proc
9. Ice Lance: Freezing stacks >= 6
10. Ice Nova: Cone of Frost talent AND enemies >= 4
11. Cone of Cold: Cone of Frost talent AND enemies >= 4
12. Flurry: cooldown_react (no Brain Freeze required)
13. Ray of Frost
14. Frostbolt (filler)

===================================
Spellslinger ST
===================================
1. Comet Storm
2. Ray of Frost: fight_remains < 12
3. Flurry: cooldown_react AND Brain Freeze AND no Thermal Void buff
4. Frozen Orb
5. Glacial Spike
6. Blizzard: enemies = 2 AND Freezing Winds AND Freezing Rain buff
7. Ice Lance: Fingers of Frost proc
8. Ice Lance: Freezing stacks >= 6
9. Flurry: cooldown_react (no Brain Freeze required)
10. Ray of Frost
11. Frostbolt (filler)
]]

--============================================================
-- 1. Register Spells
--============================================================
NCF.RegisterSpells("MAGE", 3, {
    -- Burst spells
    { id = 84714, name = "寒冰宝珠", default = "burst" },
    { id = 205021, name = "冰霜射线", default = "burst" },
    
    -- Core spells
    { id = 116, name = "寒冰箭", default = "normal" },
    { id = 30455, name = "冰枪术", default = "normal" },
    { id = 44614, name = "冰风暴", default = "normal" },
    { id = 120, name = "冰锥术", default = "normal" },
    
    -- Talent spells
    { id = 190356, name = "暴风雪", default = "normal" },
    { id = 153595, name = "彗星风暴", default = "normal" },
    { id = 157997, name = "冰霜新星", default = "normal" },
    { id = 31687, name = "召唤水元素", default = "normal" },
    
    -- Defensive
    { id = 11426, name = "寒冰护体", default = "normal" },
    { id = 414658, name = "寒冰屏障", default = "normal" },
    { id = 55342, name = "镜像", default = "normal" },
    
    -- Utility
    { id = 1459, name = "奥术智慧", default = "normal" },
    { id = 2139, name = "法术反制", default = "normal" },
})

--============================================================
-- 2. Spell ID Definitions
--============================================================
local SPELL = {
    Frostbolt = 116,
    IceLance = 30455,
    Flurry = 44614,
    FrozenOrb = 84714,
    ConeOfCold = 120,
    Blizzard = 190356,
    BlizzardFrostfire = 1248829,
    CometStorm = 153595,
    RayOfFrost = 205021,
    IceNova = 157997,
    SummonWaterElemental = 31687,
    IceBarrier = 11426,
    IceBlock = 414658,
    MirrorImage = 55342,
    ArcaneIntellect = 1459,
    Counterspell = 2139,
}

--============================================================
-- 3. Talent ID Definitions
--============================================================
local TALENT = {
    FrostfireBolt = 431044,
    Splinterstorm = 443783,
    FreezingRain = 270233,
    FreezingWinds = 1216953,
    ConeOfFrost = 1247090,
    CometStorm = 1247777,
    RayOfFrost = 205021,
    GlacialSpike = 1246832,
    ThermalVoid = 1247729,
    Blizzard = 190356,
    BlizzardFrostfire = 1248829,
    IceNova = 157997,
    SummonWaterElemental = 31687,
    IceBlock = 414659,
    MirrorImage = 55342,
    IceBarrier = 11426,
}

--============================================================
-- 4. Buff ID Definitions
--============================================================
local BUFF = {
    FingersOfFrost = 44544,
    BrainFreeze = 190446,
    ThermalVoid = 1247730,
    FreezingRain = 270232,
    FrostfireEmpowerment = 431177,
    Splinterstorm = 1247908,
    Icicles = 205473,
    GlacialSpike = 1222865,
    ArcaneIntellect = 1459,
}

--============================================================
-- 5. Debuff ID Definitions
--============================================================
local DEBUFF = {
    Freezing = 1221389,
    Hypothermia = 41425,
}

--============================================================
-- 6. Get functions from NCF
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffRemain = NCF.GetBuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffStacks = NCF.GetDebuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitHealthPct = NCF.GetUnitHealthPct
local IsSpellReady = NCF.IsSpellReady

--============================================================
-- 7. Main Rotation
--============================================================
local function CreateFrostRotation()

    local function Rotation()
        -- Refresh GCD max
        NCF.RefreshGCD()
        local gcd_max = NCF.gcd_max or 0.75
        
        -- Moving detection
        local currentSpeed = GetUnitSpeed("player")
        local isMoving = currentSpeed > 0
        
        -- Enemy count
        local enemyCount = GetActiveEnemyAmount(40, true)
        SetEnemyCount(enemyCount)
        
        -- GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- Spell ready check
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- Player HP
        local playerHP = GetUnitHealthPct("player")
        
        -- Talent checks
        local hasFrostfireBolt = HasTalent(TALENT.FrostfireBolt)
        local hasSplinterstorm = HasTalent(TALENT.Splinterstorm)
        local hasFreezingRain = HasTalent(TALENT.FreezingRain)
        local hasFreezingWinds = HasTalent(TALENT.FreezingWinds)
        local hasConeOfFrost = HasTalent(TALENT.ConeOfFrost)
        local hasCometStorm = HasTalent(TALENT.CometStorm)
        local hasRayOfFrost = HasTalent(TALENT.RayOfFrost)
        local hasGlacialSpike = HasTalent(TALENT.GlacialSpike)
        local hasIceNova = HasTalent(TALENT.IceNova)
        local hasWaterElemental = HasTalent(TALENT.SummonWaterElemental)
        
        -- Blizzard spell ID based on talent (190356 or 1248829)
        local blizzardSpellId = HasTalent(1248829) and 1248829 or 190356
        
        -- Comet Storm ready check (override spell)
        local isCometStormReady = hasCometStorm and C_Spell.GetOverrideSpell(SPELL.RayOfFrost) == SPELL.CometStorm
        
        -- Glacial Spike ready check (buff exists)
        local isGlacialSpikeReady = hasGlacialSpike and HasBuff(BUFF.GlacialSpike, "player")
        
        -- Buff checks
        local hasFingersOfFrost = HasBuff(BUFF.FingersOfFrost, "player")
        local hasBrainFreeze = HasBuff(BUFF.BrainFreeze, "player")
        local hasThermalVoid = HasBuff(BUFF.ThermalVoid, "player")
        local hasFreezingRainBuff = HasBuff(BUFF.FreezingRain, "player")
        local hasFrostfireEmpowerment = HasBuff(BUFF.FrostfireEmpowerment, "player")
        local hasSplinterstormBuff = HasBuff(BUFF.Splinterstorm, "player")
        
        -- Debuff checks
        local freezingStacks = GetDebuffStacks(DEBUFF.Freezing, "target")
        
        -- Last spell check
        local lastSpell = _G.LastCastedSpell or 0
        local prevGlacialSpike = (lastSpell == SPELL.Frostbolt and isGlacialSpikeReady)
        
        --==========================================================
        -- Pre-combat / Always
        --==========================================================
        
        -- 0. Interrupt: Counterspell
        if IsReady(SPELL.Counterspell) and not ShouldSkipSpell(SPELL.Counterspell) then
            local interruptTarget = NCF.GetInterruptTarget(40, false)
            if interruptTarget then
                return "spell", SPELL.Counterspell, interruptTarget
            end
        end
        
        -- 0.1 Arcane Intellect: no buff
        if not HasBuff(BUFF.ArcaneIntellect, "player") and IsReady(SPELL.ArcaneIntellect) and not ShouldSkipSpell(SPELL.ArcaneIntellect) then
            return "spell", SPELL.ArcaneIntellect
        end
        
        -- 0.2 Summon Water Elemental: no pet
        if hasWaterElemental and not NCF.GetPetExists() and IsReady(SPELL.SummonWaterElemental) and not ShouldSkipSpell(SPELL.SummonWaterElemental) then
            return "spell", SPELL.SummonWaterElemental
        end
        
        -- Combat check
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end
        
        --==========================================================
        -- Trinkets & Burst: during Freezing Rain buff
        --==========================================================
        if NCF.burstModeEnabled and hasFreezingRainBuff then
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
        -- Defensive Abilities
        --==========================================================
        local hasIceBarrier = HasTalent(TALENT.IceBarrier)
        local hasMirrorImage = HasTalent(TALENT.MirrorImage)
        local hasIceBlock = HasTalent(TALENT.IceBlock)
        
        local barrierCharges = hasIceBarrier and GetSpellCharges(SPELL.IceBarrier) or 0
        local iceBlockCharges = hasIceBlock and GetSpellCharges(SPELL.IceBlock) or 0
        
        -- Ice Barrier: 90% HP with charges > 1.9 | 60% HP with charges > 1
        if hasIceBarrier and not ShouldSkipSpell(SPELL.IceBarrier) then
            if barrierCharges > 1.9 and playerHP <= 90 then
                return "spell", SPELL.IceBarrier
            end
            if barrierCharges > 1 and playerHP <= 60 then
                return "spell", SPELL.IceBarrier
            end
        end
        
        -- Mirror Image: 55% HP
        if hasMirrorImage and playerHP <= 55 and IsReady(SPELL.MirrorImage) and not ShouldSkipSpell(SPELL.MirrorImage) then
            return "spell", SPELL.MirrorImage
        end
        
        -- Ice Block: 45% HP with charges > 1.9 | 30% HP with charges > 1, no Hypothermia
        local hasHypothermia = HasDebuff(DEBUFF.Hypothermia, "player")
        if hasIceBlock and not hasHypothermia and not ShouldSkipSpell(SPELL.IceBlock) then
            if iceBlockCharges > 1.9 and playerHP <= 45 then
                return "spell", SPELL.IceBlock
            end
            if iceBlockCharges > 1 and playerHP <= 30 then
                return "spell", SPELL.IceBlock
            end
        end
        
        --==========================================================
        -- Frostfire AOE (enemies >= 3)
        --==========================================================
        if hasFrostfireBolt and enemyCount >= 3 then
            
            -- 1. Comet Storm
            if isCometStormReady and not ShouldSkipSpell(SPELL.CometStorm) then
                return "spell", SPELL.CometStorm
            end
            
            -- 2. Ray of Frost: fight_remains < 12 (skip for now, use TTD later)
            -- Using Ray of Frost as low priority filler instead
            
            -- 3. Flurry: cooldown_react AND no Thermal Void buff
            if not hasThermalVoid and IsReady(SPELL.Flurry) and not ShouldSkipSpell(SPELL.Flurry) then
                return "spell", SPELL.Flurry
            end
            
            -- 4. Frozen Orb
            if IsReady(SPELL.FrozenOrb) and not ShouldSkipSpell(SPELL.FrozenOrb) then
                return "spell", SPELL.FrozenOrb
            end
            
            -- 5. Glacial Spike
            if isGlacialSpikeReady and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt  -- Glacial Spike uses Frostbolt ID
            end
            
            -- 6. Blizzard
            if IsReady(blizzardSpellId) and not ShouldSkipSpell(blizzardSpellId) then
                return "spell", blizzardSpellId
            end
            
            -- 7. Ice Lance: Fingers of Frost proc
            if hasFingersOfFrost and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            -- 8. Ice Lance: Freezing stacks >= 10
            if freezingStacks >= 10 and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            -- 9. Frostbolt: Frostfire Empowerment OR prev Glacial Spike
            if (hasFrostfireEmpowerment or prevGlacialSpike) and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt
            end
            
            -- 10. Ray of Frost (skip while moving)
            if not isMoving and hasRayOfFrost and IsReady(SPELL.RayOfFrost) and not ShouldSkipSpell(SPELL.RayOfFrost) then
                return "spell", SPELL.RayOfFrost
            end
            
            -- 11. Frostbolt (filler) - skip while moving unless Frostfire Empowerment
            if (not isMoving or hasFrostfireEmpowerment) and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt
            end
            
            -- 12. Ice Lance (moving filler)
            if isMoving and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            return nil
        end
        
        --==========================================================
        -- Frostfire ST
        --==========================================================
        if hasFrostfireBolt then
            
            -- 1. Comet Storm
            if isCometStormReady and not ShouldSkipSpell(SPELL.CometStorm) then
                return "spell", SPELL.CometStorm
            end
            
            -- 2. Ray of Frost: fight_remains < 12 (skip)
            
            -- 3. Flurry: cooldown_react AND no Thermal Void buff
            if not hasThermalVoid and IsReady(SPELL.Flurry) and not ShouldSkipSpell(SPELL.Flurry) then
                return "spell", SPELL.Flurry
            end
            
            -- 4. Frozen Orb
            if IsReady(SPELL.FrozenOrb) and not ShouldSkipSpell(SPELL.FrozenOrb) then
                return "spell", SPELL.FrozenOrb
            end
            
            -- 5. Glacial Spike
            if isGlacialSpikeReady and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt
            end
            
            -- 6. Blizzard: Freezing Rain buff
            if hasFreezingRainBuff and IsReady(blizzardSpellId) and not ShouldSkipSpell(blizzardSpellId) then
                return "spell", blizzardSpellId
            end
            
            -- 7. Ice Lance: Fingers of Frost proc
            if hasFingersOfFrost and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            -- 8. Ice Lance: Freezing stacks >= 10
            if freezingStacks >= 10 and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            -- 9. Ray of Frost (skip while moving)
            if not isMoving and hasRayOfFrost and IsReady(SPELL.RayOfFrost) and not ShouldSkipSpell(SPELL.RayOfFrost) then
                return "spell", SPELL.RayOfFrost
            end
            
            -- 10. Frostbolt (filler) - skip while moving unless Frostfire Empowerment
            if (not isMoving or hasFrostfireEmpowerment) and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt
            end
            
            -- 11. Ice Lance (moving filler)
            if isMoving and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            return nil
        end
        
        --==========================================================
        -- Spellslinger AOE (enemies >= 3)
        --==========================================================
        if enemyCount >= 3 then
            
            -- 1. Comet Storm
            if isCometStormReady and not ShouldSkipSpell(SPELL.CometStorm) then
                return "spell", SPELL.CometStorm
            end
            
            -- 2. Ray of Frost: fight_remains < 12 (skip)
            
            -- 3. Blizzard: Freezing Rain buff
            if hasFreezingRainBuff and IsReady(blizzardSpellId) and not ShouldSkipSpell(blizzardSpellId) then
                return "spell", blizzardSpellId
            end
            
            -- 4. Flurry: cooldown_react AND Brain Freeze AND no Thermal Void buff
            if hasBrainFreeze and not hasThermalVoid and IsReady(SPELL.Flurry) and not ShouldSkipSpell(SPELL.Flurry) then
                return "spell", SPELL.Flurry
            end
            
            -- 5. Frozen Orb
            if IsReady(SPELL.FrozenOrb) and not ShouldSkipSpell(SPELL.FrozenOrb) then
                return "spell", SPELL.FrozenOrb
            end
            
            -- 6. Glacial Spike
            if isGlacialSpikeReady and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt
            end
            
            -- 7. Blizzard: no Splinterstorm AND (Freezing Rain OR Freezing Winds OR enemies >= 7)
            local blizzardCondition = not hasSplinterstormBuff and (hasFreezingRain or hasFreezingWinds or enemyCount >= 7)
            if blizzardCondition and IsReady(blizzardSpellId) and not ShouldSkipSpell(blizzardSpellId) then
                return "spell", blizzardSpellId
            end
            
            -- 8. Ice Lance: Fingers of Frost proc
            if hasFingersOfFrost and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            -- 9. Ice Lance: Freezing stacks >= 6
            if freezingStacks >= 6 and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            -- 10. Ice Nova: Cone of Frost talent AND enemies >= 4
            if hasIceNova and hasConeOfFrost and enemyCount >= 4 and IsReady(SPELL.IceNova) and not ShouldSkipSpell(SPELL.IceNova) then
                return "spell", SPELL.IceNova
            end
            
            -- 11. Cone of Cold: Cone of Frost talent AND enemies >= 4
            if hasConeOfFrost and enemyCount >= 4 and IsReady(SPELL.ConeOfCold) and not ShouldSkipSpell(SPELL.ConeOfCold) then
                return "spell", SPELL.ConeOfCold
            end
            
            -- 12. Flurry: cooldown_react (no Brain Freeze required)
            if IsReady(SPELL.Flurry) and not ShouldSkipSpell(SPELL.Flurry) then
                return "spell", SPELL.Flurry
            end
            
            -- 13. Ray of Frost (skip while moving)
            if not isMoving and hasRayOfFrost and IsReady(SPELL.RayOfFrost) and not ShouldSkipSpell(SPELL.RayOfFrost) then
                return "spell", SPELL.RayOfFrost
            end
            
            -- 14. Frostbolt (filler) - skip while moving unless Frostfire Empowerment
            if (not isMoving or hasFrostfireEmpowerment) and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
                return "spell", SPELL.Frostbolt
            end
            
            -- 15. Ice Lance (moving filler)
            if isMoving and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
                return "spell", SPELL.IceLance
            end
            
            return nil
        end
        
        --==========================================================
        -- Spellslinger ST (default)
        --==========================================================
        
        -- 1. Comet Storm
        if isCometStormReady and not ShouldSkipSpell(SPELL.CometStorm) then
            return "spell", SPELL.CometStorm
        end
        
        -- 2. Ray of Frost: fight_remains < 12 (skip)
        
        -- 3. Flurry: cooldown_react AND Brain Freeze AND no Thermal Void buff
        if hasBrainFreeze and not hasThermalVoid and IsReady(SPELL.Flurry) and not ShouldSkipSpell(SPELL.Flurry) then
            return "spell", SPELL.Flurry
        end
        
        -- 4. Frozen Orb
        if IsReady(SPELL.FrozenOrb) and not ShouldSkipSpell(SPELL.FrozenOrb) then
            return "spell", SPELL.FrozenOrb
        end
        
        -- 5. Glacial Spike
        if isGlacialSpikeReady and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
            return "spell", SPELL.Frostbolt
        end
        
        -- 6. Blizzard: enemies = 2 AND Freezing Winds AND Freezing Rain buff
        if enemyCount == 2 and hasFreezingWinds and hasFreezingRainBuff and IsReady(blizzardSpellId) and not ShouldSkipSpell(blizzardSpellId) then
            return "spell", blizzardSpellId
        end
        
        -- 7. Ice Lance: Fingers of Frost proc
        if hasFingersOfFrost and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
            return "spell", SPELL.IceLance
        end
        
        -- 8. Ice Lance: Freezing stacks >= 6
        if freezingStacks >= 6 and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
            return "spell", SPELL.IceLance
        end
        
        -- 9. Flurry: cooldown_react (no Brain Freeze required)
        if IsReady(SPELL.Flurry) and not ShouldSkipSpell(SPELL.Flurry) then
            return "spell", SPELL.Flurry
        end
        
        -- 10. Ray of Frost (skip while moving)
        if not isMoving and hasRayOfFrost and IsReady(SPELL.RayOfFrost) and not ShouldSkipSpell(SPELL.RayOfFrost) then
            return "spell", SPELL.RayOfFrost
        end
        
        -- 11. Frostbolt (filler) - skip while moving unless Frostfire Empowerment
        if (not isMoving or hasFrostfireEmpowerment) and IsReady(SPELL.Frostbolt) and not ShouldSkipSpell(SPELL.Frostbolt) then
            return "spell", SPELL.Frostbolt
        end
        
        -- 12. Ice Lance (moving filler)
        if isMoving and IsReady(SPELL.IceLance) and not ShouldSkipSpell(SPELL.IceLance) then
            return "spell", SPELL.IceLance
        end
        
        -- Fallback
        return nil
    end

    return Rotation
end

-- Create and return rotation instance
return CreateFrostRotation()