--============================================================
-- Survival Hunter Rotation
-- Version 12.0
--============================================================

--[[
=== Priority List ===

--- Precombat ---
0. Interrupt - Muzzle
1. Summon Pet: if no pet

--- Main Logic ---
- If enemies < 3 AND has Howl of the Pack Leader talent -> Pack Leader ST
- If enemies > 2 AND has Howl of the Pack Leader talent -> Pack Leader Cleave
- If enemies < 3 AND NOT Howl of the Pack Leader talent -> Sentinel ST
- If enemies > 2 AND NOT Howl of the Pack Leader talent -> Sentinel Cleave

--- Pack Leader Cleave (enemies > 2) ---
1. Kill Command: if Tip of the Spear stacks = 0 OR (stacks < 2 AND has any Howl buff)
2. Kill Command: if Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
3. Takedown: if Tip of the Spear up
4. Boomstick: if Tip of the Spear up
5. Wildfire Bomb: if Tip of the Spear up AND charges > 1.5
6. Wildfire Bomb: if Wyvern's Cry buff AND Tip of the Spear up
7. Flamefang Pitch: always
8. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
9. Kill Command: filler

--- Pack Leader ST (enemies < 3) ---
1. Kill Command: if Tip of the Spear stacks = 0 OR (stacks < 2 AND has any Howl buff)
2. Kill Command: if Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
3. Takedown: if Tip of the Spear up
4. Flamefang Pitch: always
5. Boomstick: if Tip of the Spear up
6. Wildfire Bomb: if Wyvern's Cry buff AND Tip of the Spear up
7. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
8. Kill Command: filler

--- Sentinel Cleave (enemies > 2) ---
1. Kill Command: if Tip of the Spear stacks = 0
2. Boomstick: if Tip of the Spear up
3. Wildfire Bomb: if Tip up AND (Sentinel's Mark debuff OR full recharge < 4 + gcd)
4. Kill Command: if Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
5. Takedown: if Tip of the Spear up
6. Boomstick: if Tip of the Spear up
7. Moonlight Chakram: if Tip of the Spear up
8. Flamefang Pitch: if has talent
9. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
10. Kill Command: filler

--- Sentinel ST (enemies < 3) ---
1. Kill Command: if Tip of the Spear stacks = 0
2. Boomstick: if Tip of the Spear up
3. Wildfire Bomb: if Tip up AND (Sentinel's Mark debuff OR full recharge < 4 + gcd)
4. Kill Command: if Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
5. Takedown: if Tip of the Spear up
6. Boomstick: if Tip of the Spear up
7. Moonlight Chakram: if Tip of the Spear up
8. Flamefang Pitch: if has talent
9. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
10. Kill Command: filler
]]

--============================================================
-- 1. Register Spells
--============================================================
NCF.RegisterSpells("HUNTER", 3, {
    -- Burst spells
    { id = 259489, name = "Kill Command", default = "burst" },
    
    -- Normal spells
    { id = 187707, name = "Muzzle", default = "normal" },
    { id = 883, name = "Summon Pet", default = "normal" },
    { id = 1250646, name = "Takedown", default = "normal" },
    { id = 1261193, name = "Boomstick", default = "normal" },
    { id = 259495, name = "Wildfire Bomb", default = "normal" },
    { id = 1251592, name = "Flamefang Pitch", default = "normal" },
    { id = 186270, name = "Raptor Strike", default = "normal" },
    { id = 1264949, name = "Moonlight Chakram", default = "normal" },
})

--============================================================
-- 2. Spell ID Definitions
--============================================================
local SPELL = {
    Muzzle = 187707,              -- Interrupt
    SummonPet = 883,              -- Summon Pet
    KillCommand = 259489,         -- Kill Command
    Takedown = 1250646,           -- Takedown
    Boomstick = 1261193,          -- Boomstick
    WildfireBomb = 259495,        -- Wildfire Bomb
    FlamefangPitch = 1251592,     -- Flamefang Pitch
    RaptorStrike = 186270,        -- Raptor Strike
    MoonlightChakram = 1264949,   -- Moonlight Chakram (override of Takedown)
}

--============================================================
-- 3. Buff ID Definitions
--============================================================
local BUFF = {
    TipOfTheSpear = 260286,       -- Tip of the Spear
    HowlWyvern = 471878,          -- Howl of the Pack Leader (Wyvern)
    HowlBoar = 472324,            -- Howl of the Pack Leader (Boar)
    HowlBear = 472325,            -- Howl of the Pack Leader (Bear)
    WyvernsCry = 471881,          -- Wyvern's Cry
    RaptorSwipe = 1259003,        -- Raptor Swipe
	TakeDown = 1250646,
}

--============================================================
-- 4. Debuff ID Definitions
--============================================================
local DEBUFF = {
    SentinelsMark = 1253601,      -- Sentinel's Mark
}

--============================================================
-- 5. Talent ID Definitions
--============================================================
local TALENT = {
    HowlOfThePackLeader = 471876, -- Howl of the Pack Leader
    TwinFangs = 1272139,          -- Twin Fangs
    FlamefangPitch = 1251592,     -- Flamefang Pitch
}

--============================================================
-- 6. Get functions from NCF
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetBuffRemain = NCF.GetBuffRemain
local GetDebuffRemain = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetSpellChargeInfo = NCF.GetSpellChargeInfo
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetPetExists = NCF.GetPetExists
local IsSpellReady = NCF.IsSpellReady
local GetInterruptTarget = NCF.GetInterruptTarget

-- Get full recharge time for Wildfire Bomb
local function GetFullRechargeTime(spellId)
    local chargeInfo = GetSpellChargeInfo(spellId)
    if not chargeInfo then return 0 end
    
    local currentCharges = chargeInfo.currentCharges or 0
    local maxCharges = chargeInfo.maxCharges or 1
    local cooldownStart = chargeInfo.cooldownStartTime or 0
    local cooldownDuration = chargeInfo.cooldownDuration or 0
    
    if currentCharges >= maxCharges then return 0 end
    
    local chargesNeeded = maxCharges - currentCharges
    local timeToNextCharge = 0
    
    if cooldownStart > 0 and cooldownDuration > 0 then
        timeToNextCharge = (cooldownStart + cooldownDuration) - GetTime()
        if timeToNextCharge < 0 then timeToNextCharge = 0 end
    end
    
    return timeToNextCharge + (chargesNeeded - 1) * cooldownDuration
end

--============================================================
-- 7. Main Rotation
--============================================================
local function CreateSurvivalRotation()

    local function Rotation()
        local enemyCount = GetActiveEnemyAmount(8, false)
        SetEnemyCount(enemyCount)
        
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- Buff states
        local tipStacks = GetBuffStacks(BUFF.TipOfTheSpear)
        local hasTip = tipStacks > 0
        local hasHowlWyvern = HasBuff(BUFF.HowlWyvern)
        local hasHowlBoar = HasBuff(BUFF.HowlBoar)
        local hasHowlBear = HasBuff(BUFF.HowlBear)
        local hasAnyHowl = hasHowlWyvern or hasHowlBoar or hasHowlBear
        local hasWyvernsCry = HasBuff(BUFF.WyvernsCry)
        local hasRaptorSwipe = HasBuff(BUFF.RaptorSwipe)
		local hasTakeDown = HasBuff(BUFF.TakeDown)
        
        -- Debuff states
        local hasSentinelsMark = HasDebuff(DEBUFF.SentinelsMark, "target")
        
        -- Talent checks
        local hasHowlTalent = HasTalent(TALENT.HowlOfThePackLeader)
        local hasTwinFangs = HasTalent(TALENT.TwinFangs)
        local hasFlamefangTalent = HasTalent(TALENT.FlamefangPitch)
        
        -- CD checks
        local takedownCD = GetSpellCooldownRemain(SPELL.Takedown)
        local wildfireCharges = GetSpellCharges(SPELL.WildfireBomb)
        local wildfireFullRecharge = GetFullRechargeTime(SPELL.WildfireBomb)
        
        -- Moonlight Chakram available check (Takedown override)
        local isMoonlightChakram = C_Spell.GetOverrideSpell(SPELL.Takedown) == SPELL.MoonlightChakram
        
        -- Burst phase
        if NCF.burstModeEnabled and hasTakeDown then
            NCF.UseTrinket()
            if NCF.enablePotion then 
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsSpellReady(racialSpell) then
                return "spell", racialSpell
            end
        end
        
        --============================================================
        -- Pre-combat / Always
        --============================================================
        
        -- 0. Interrupt
        if IsSpellReady(SPELL.Muzzle) and not ShouldSkipSpell(SPELL.Muzzle) then
            local interruptTarget = GetInterruptTarget(5, false)
            if interruptTarget then
                return "spell", SPELL.Muzzle, interruptTarget
            end
        end
        
        -- 1. Summon Pet: if no pet
        if not GetPetExists() and IsSpellReady(SPELL.SummonPet) and not ShouldSkipSpell(SPELL.SummonPet) then
            return "spell", SPELL.SummonPet
        end
        
        -- Combat check
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end
        
        --============================================================
        -- Pack Leader Cleave (enemies > 2, has Howl talent)
        --============================================================
        if enemyCount > 2 and hasHowlTalent then
            -- 1. Kill Command: Tip stacks = 0 OR (stacks < 2 AND has any Howl buff)
            local kcCondition = tipStacks == 0 or (tipStacks < 2 and hasAnyHowl)
            if kcCondition and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            -- 2. Kill Command: Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
            if takedownCD < gcd and tipStacks < 2 and not hasTwinFangs and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            -- 3. Takedown: if Tip up
            if hasTip and IsSpellReady(SPELL.Takedown) and not ShouldSkipSpell(SPELL.Takedown) then
                return "spell", SPELL.Takedown
            end
            
            -- 4. Boomstick: if Tip up
            if hasTip and IsSpellReady(SPELL.Boomstick) and not ShouldSkipSpell(SPELL.Boomstick) then
                return "spell", SPELL.Boomstick
            end
            
            -- 5. Wildfire Bomb: if Tip up AND charges > 1.5
            if hasTip and wildfireCharges > 1.5 and IsSpellReady(SPELL.WildfireBomb) and not ShouldSkipSpell(SPELL.WildfireBomb) then
                return "spell", SPELL.WildfireBomb
            end
            
            -- 6. Wildfire Bomb: if Wyvern's Cry buff AND Tip up
            if hasWyvernsCry and hasTip and IsSpellReady(SPELL.WildfireBomb) and not ShouldSkipSpell(SPELL.WildfireBomb) then
                return "spell", SPELL.WildfireBomb
            end
            
            -- 7. Flamefang Pitch: always
            if hasFlamefangTalent and IsSpellReady(SPELL.FlamefangPitch) and not ShouldSkipSpell(SPELL.FlamefangPitch) then
                return "spell", SPELL.FlamefangPitch
            end
            
            -- 8. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
            local raptorCondition = (hasTip and hasRaptorSwipe) or not hasRaptorSwipe
            if raptorCondition and IsSpellReady(SPELL.RaptorStrike) and not ShouldSkipSpell(SPELL.RaptorStrike) then
                return "spell", SPELL.RaptorStrike
            end
            
            -- 9. Kill Command: filler
            if IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            return nil
        end
        
        --============================================================
        -- Pack Leader ST (enemies < 3, has Howl talent)
        --============================================================
        if enemyCount < 3 and hasHowlTalent then
            -- 1. Kill Command: Tip stacks = 0 OR (stacks < 2 AND has any Howl buff)
            local kcCondition = tipStacks == 0 or (tipStacks < 2 and hasAnyHowl)
            if kcCondition and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            -- 2. Kill Command: Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
            if takedownCD < gcd and tipStacks < 2 and not hasTwinFangs and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            -- 3. Takedown: if Tip up
            if hasTip and IsSpellReady(SPELL.Takedown) and not ShouldSkipSpell(SPELL.Takedown) then
                return "spell", SPELL.Takedown
            end
            
            -- 4. Flamefang Pitch: always
            if hasFlamefangTalent and IsSpellReady(SPELL.FlamefangPitch) and not ShouldSkipSpell(SPELL.FlamefangPitch) then
                return "spell", SPELL.FlamefangPitch
            end
            
            -- 5. Boomstick: if Tip up
            if hasTip and IsSpellReady(SPELL.Boomstick) and not ShouldSkipSpell(SPELL.Boomstick) then
                return "spell", SPELL.Boomstick
            end
            
            -- 6. Wildfire Bomb: if Wyvern's Cry buff AND Tip up
            if hasWyvernsCry and hasTip and IsSpellReady(SPELL.WildfireBomb) and not ShouldSkipSpell(SPELL.WildfireBomb) then
                return "spell", SPELL.WildfireBomb
            end
            
            -- 7. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
            local raptorCondition = (hasTip and hasRaptorSwipe) or not hasRaptorSwipe
            if raptorCondition and IsSpellReady(SPELL.RaptorStrike) and not ShouldSkipSpell(SPELL.RaptorStrike) then
                return "spell", SPELL.RaptorStrike
            end
            
            -- 8. Kill Command: filler
            if IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            return nil
        end
        
        --============================================================
        -- Sentinel Cleave (enemies > 2, no Howl talent)
        --============================================================
        if enemyCount > 2 and not hasHowlTalent then
            -- 1. Kill Command: if Tip stacks = 0
            if tipStacks == 0 and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            -- 2. Boomstick: if Tip up
            if hasTip and IsSpellReady(SPELL.Boomstick) and not ShouldSkipSpell(SPELL.Boomstick) then
                return "spell", SPELL.Boomstick
            end
            
            -- 3. Wildfire Bomb: if Tip up AND (Sentinel's Mark debuff OR full recharge < 4 + gcd)
            local wfCondition = hasTip and (hasSentinelsMark or wildfireFullRecharge < 4 + gcd)
            if wfCondition and IsSpellReady(SPELL.WildfireBomb) and not ShouldSkipSpell(SPELL.WildfireBomb) then
                return "spell", SPELL.WildfireBomb
            end
            
            -- 4. Kill Command: Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
            if takedownCD < gcd and tipStacks < 2 and not hasTwinFangs and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            -- 5. Takedown: if Tip up
            if hasTip and IsSpellReady(SPELL.Takedown) and not ShouldSkipSpell(SPELL.Takedown) then
                return "spell", SPELL.Takedown
            end
            
            -- 6. Boomstick: if Tip up (duplicate in APL)
            if hasTip and IsSpellReady(SPELL.Boomstick) and not ShouldSkipSpell(SPELL.Boomstick) then
                return "spell", SPELL.Boomstick
            end
            
            -- 7. Moonlight Chakram: if Tip up (when available)
            if isMoonlightChakram and hasTip and IsSpellReady(SPELL.MoonlightChakram) and not ShouldSkipSpell(SPELL.MoonlightChakram) then
                return "spell", SPELL.MoonlightChakram
            end
            
            -- 8. Flamefang Pitch: if has talent
            if hasFlamefangTalent and IsSpellReady(SPELL.FlamefangPitch) and not ShouldSkipSpell(SPELL.FlamefangPitch) then
                return "spell", SPELL.FlamefangPitch
            end
            
            -- 9. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
            local raptorCondition = (hasTip and hasRaptorSwipe) or not hasRaptorSwipe
            if raptorCondition and IsSpellReady(SPELL.RaptorStrike) and not ShouldSkipSpell(SPELL.RaptorStrike) then
                return "spell", SPELL.RaptorStrike
            end
            
            -- 10. Kill Command: filler
            if IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
                return "spell", SPELL.KillCommand
            end
            
            return nil
        end
        
        --============================================================
        -- Sentinel ST (enemies < 3, no Howl talent)
        --============================================================
        
        -- 1. Kill Command: if Tip stacks = 0
        if tipStacks == 0 and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
            return "spell", SPELL.KillCommand
        end
        
        -- 2. Boomstick: if Tip up
        if hasTip and IsSpellReady(SPELL.Boomstick) and not ShouldSkipSpell(SPELL.Boomstick) then
            return "spell", SPELL.Boomstick
        end
        
        -- 3. Wildfire Bomb: if Tip up AND (Sentinel's Mark debuff OR full recharge < 4 + gcd)
        local wfCondition = hasTip and (hasSentinelsMark or wildfireFullRecharge < 4 + gcd)
        if wfCondition and IsSpellReady(SPELL.WildfireBomb) and not ShouldSkipSpell(SPELL.WildfireBomb) then
            return "spell", SPELL.WildfireBomb
        end
        
        -- 4. Kill Command: Takedown CD < gcd AND Tip stacks < 2 AND NOT Twin Fangs
        if takedownCD < gcd and tipStacks < 2 and not hasTwinFangs and IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
            return "spell", SPELL.KillCommand
        end
        
        -- 5. Takedown: if Tip up
        if hasTip and IsSpellReady(SPELL.Takedown) and not ShouldSkipSpell(SPELL.Takedown) then
            return "spell", SPELL.Takedown
        end
        
        -- 6. Boomstick: if Tip up (duplicate in APL)
        if hasTip and IsSpellReady(SPELL.Boomstick) and not ShouldSkipSpell(SPELL.Boomstick) then
            return "spell", SPELL.Boomstick
        end
        
        -- 7. Moonlight Chakram: if Tip up (when available)
        if isMoonlightChakram and hasTip and IsSpellReady(SPELL.MoonlightChakram) and not ShouldSkipSpell(SPELL.MoonlightChakram) then
            return "spell", SPELL.MoonlightChakram
        end
        
        -- 8. Flamefang Pitch: if has talent
        if hasFlamefangTalent and IsSpellReady(SPELL.FlamefangPitch) and not ShouldSkipSpell(SPELL.FlamefangPitch) then
            return "spell", SPELL.FlamefangPitch
        end
        
        -- 9. Raptor Strike: if (Tip up AND Raptor Swipe buff) OR NOT Raptor Swipe buff
        local raptorCondition = (hasTip and hasRaptorSwipe) or not hasRaptorSwipe
        if raptorCondition and IsSpellReady(SPELL.RaptorStrike) and not ShouldSkipSpell(SPELL.RaptorStrike) then
            return "spell", SPELL.RaptorStrike
        end
        
        -- 10. Kill Command: filler
        if IsSpellReady(SPELL.KillCommand) and not ShouldSkipSpell(SPELL.KillCommand) then
            return "spell", SPELL.KillCommand
        end
        
        return nil
    end

    return Rotation
end

-- Create and return rotation instance
return CreateSurvivalRotation()