--============================================================
-- Arcane Mage Rotation
-- Version 12.0
-- 
-- Talent Branches:
-- - Splintering Sorcery + Orb Mastery (443739 + orb_mastery)
-- - Splintering Sorcery without Orb Mastery (443739)
-- - Spellfire Spheres / Sunfury (448601)
--============================================================

--[[
===================================
Cooldowns (shared)
===================================
0. Arcane Orb: opener phase AND Orb Mastery (combatTime < 5)
1. Arcane Missiles: opener phase AND Spellfire Spheres talent
2. Arcane Blast: Splintering AND salvo < 20 AND (opener OR Orb Mastery surge prep)
3. Touch of the Magi: complex conditions
4. Arcane Surge: on CD
5. Evocation: mana < 10% AND no surge AND no touch debuff AND surge CD > 10

===================================
Spellslinger + Orb Mastery Branch
===================================
1. Arcane Orb: after Barrage with CC to recoup charges, or in AOE
2. Arcane Barrage: salvo >= 20 (or 18+ with Orb Barrage), hold for CDs
3. Arcane Missiles: with HV or OPM, salvo <= threshold, not after Orb
4. Presence of Mind: charges < 2, no CC or no HV, not after Orb/Missiles
5. Arcane Blast: if Presence of Mind up
6. Arcane Pulse: enemies > 3
7. Arcane Blast: filler
8. Arcane Barrage: filler

===================================
Spellslinger (no Orb Mastery) Branch
===================================
1. Arcane Orb: charges < 3 (or < 4 with 2+ enemies), need charges
2. Arcane Barrage: salvo >= 20, hold for CDs
3. Arcane Barrage: AOE with CC + OPM + HV
4. Arcane Missiles: for charges with HV and salvo stacks
5. Presence of Mind: charges < 2, conditions
6. Arcane Blast: if Presence of Mind up
7. Arcane Pulse: enemies > 3
8. Arcane Blast: filler
9. Arcane Barrage: filler

===================================
Sunfury Branch
===================================
Variable: sunfury_hold_for_cds - pooling logic for Touch/Surge/Soul

1. Arcane Barrage: complex conditions with hold_for_cds, or Soul buff, or Touch timing
2. Arcane Missiles: CC with salvo threshold, Touch+Surge combo
3. Arcane Orb: charges < 2
4. Arcane Pulse: enemies > 3
5. Arcane Explosion: enemies > 3, charges < 2, no Impetus
6. Arcane Blast: filler
7. Arcane Barrage: filler
]]

--============================================================
-- 1. Register Spells
--============================================================
NCF.RegisterSpells("MAGE", 1, {
    -- Cooldown spells
    { id = 365350, name = "Arcane Surge", default = "burst" },
    { id = 321507, name = "Touch of the Magi", default = "burst" },
    { id = 12051, name = "Evocation", default = "normal" },
    { id = 205025, name = "Presence of Mind", default = "normal" },
    
    -- Normal spells
    { id = 5143, name = "Arcane Missiles", default = "normal" },
    { id = 153626, name = "Arcane Orb", default = "normal" },
    { id = 44425, name = "Arcane Barrage", default = "normal" },
    { id = 30451, name = "Arcane Blast", default = "normal" },
    { id = 1449, name = "Arcane Explosion", default = "normal" },
    { id = 1241462, name = "Arcane Pulse", default = "normal" },
    { id = 2139, name = "Counterspell", default = "normal" },
    { id = 1459, name = "Arcane Intellect", default = "normal" },
    
    -- Defensive spells
    { id = 235450, name = "Prismatic Barrier", default = "normal" },
    { id = 414658, name = "Ice Block", default = "normal" },
    { id = 475, name = "Remove Curse", default = "normal" },
})

--============================================================
-- 2. Spell ID Definitions
--============================================================
local SPELL = {
    ArcaneMissiles = 5143,
    TouchOfTheMagi = 321507,
    ArcaneSurge = 365350,
    Evocation = 12051,
    ArcaneOrb = 153626,
    ArcaneBarrage = 44425,
    ArcaneBlast = 30451,
    PresenceOfMind = 205025,
    ArcanePulse = 1241462,
    ArcaneExplosion = 1449,
    CounterSpell = 2139,
    ArcaneIntellect = 1459,
    PrismaticBarrier = 235450,
    IceBlock = 414658,
    RemoveCurse = 475,
}

--============================================================
-- 3. Talent ID Definitions
--============================================================
local TALENT = {
    SplintertingSorcery = 443739,
    SpellfireSpheres = 448601,
    HighVoltage = 461248,
    OrbBarrage = 384858,
    Impetus = 383676,
    Evocation = 12051,
    PresenceOfMind = 205025,
    ArcanePulse = 1241462,
    OverpoweredMissiles = 1244329,
    RemoveCurse = 475,
    OrbMastery = 1243435,
}

--============================================================
-- 4. Buff ID Definitions
--============================================================
local BUFF = {
    ArcaneSurge = 365362,
    Clearcasting = 263725,
    ArcaneSalvo = 1242974,
    OverpoweredMissiles = 1277009,
    ArcaneSoul = 451038,
    PresenceOfMind = 205025,
}

--============================================================
-- 5. Debuff ID Definitions
--============================================================
local DEBUFF = {
    TouchOfTheMagi = 210824,
    Hypothermia = 41425,          -- Prevents Ice Block
}

--============================================================
-- 6. Get functions from NCF
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffRemain = NCF.GetBuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffRemain = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower
local GetUnitPowerMax = NCF.GetUnitPowerMax
local IsMidnight = NCF.IsMidnight
local secretunwrap = NCF.secretunwrap

-- Get mana percentage
local function GetManaPct()
    local mana = GetUnitPower("player", "mana")
    local maxMana = GetUnitPowerMax("player", "mana")
    if maxMana == 0 then return 100 end
    return (mana / maxMana) * 100
end

--============================================================
-- 7. Main Rotation
--============================================================
local function CreateArcaneRotation()

    local function Rotation()
        -- Refresh GCD max
        NCF.RefreshGCD()
        local gcd_max = NCF.gcd_max or 0.75
        
        -- Combat time
        local combatTime = NCF.GetCombatTime() or 0
        
        -- Enemy count
        local enemyCount = GetActiveEnemyAmount(40, true)
        SetEnemyCount(enemyCount)
        
        -- GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- Spell ready check
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- Cache common states
        local arcaneCharges = GetUnitPower("player", "arcanecharges")
        local arcaneSalvoStacks = GetBuffStacks(BUFF.ArcaneSalvo, "player")
        
        -- Predict charges and salvo if casting Arcane Blast
        local currentCast = select(9, UnitCastingInfo("player"))
        if IsMidnight then currentCast = secretunwrap(currentCast) end
        if currentCast == SPELL.ArcaneBlast then
            local chargeGain = HasTalent(TALENT.Impetus) and 2 or 1
            arcaneCharges = math.min(arcaneCharges + chargeGain, 4)
            local maxSalvoStacks = HasTalent(TALENT.SpellfireSpheres) and 25 or 20
            arcaneSalvoStacks = math.min(arcaneSalvoStacks + 2, maxSalvoStacks)
        end
        
        local manaPct = GetManaPct()
        local playerHP = NCF.GetUnitHealthPct("player")
        local hasArcaneSurge = HasBuff(BUFF.ArcaneSurge, "player")
        local arcaneSurgeRemain = GetBuffRemain(BUFF.ArcaneSurge, "player")
        local hasClearcasting = HasBuff(BUFF.Clearcasting, "player")
        local clearcastingStacks = GetBuffStacks(BUFF.Clearcasting, "player")
        local hasOPM = HasTalent(TALENT.OverpoweredMissiles) and HasBuff(BUFF.OverpoweredMissiles, "player")
        local hasArcaneSoul = HasBuff(BUFF.ArcaneSoul, "player")
        local hasTouchDebuff = HasDebuff(DEBUFF.TouchOfTheMagi, "target")
        local touchDebuffRemain = GetDebuffRemain(DEBUFF.TouchOfTheMagi, "target")
        local arcaneSurgeCD = GetSpellCooldownRemain(SPELL.ArcaneSurge)
        local touchCD = GetSpellCooldownRemain(SPELL.TouchOfTheMagi)
        local orbCharges = GetSpellCharges(SPELL.ArcaneOrb)
        local hasPresenceOfMind = HasBuff(BUFF.PresenceOfMind, "player")
        
        -- Last casted spell for prev_gcd checks
        local lastSpell = _G.LastCastedSpell or 0
        local prevOrb = (lastSpell == SPELL.ArcaneOrb)
        local prevMissiles = (lastSpell == SPELL.ArcaneMissiles)
        local prevBarrage = (lastSpell == SPELL.ArcaneBarrage)
        local prevTouch = (lastSpell == SPELL.TouchOfTheMagi)
        
        -- Talent checks
        local hasSplintering = HasTalent(TALENT.SplintertingSorcery)
        local hasSunfury = HasTalent(TALENT.SpellfireSpheres)
        local hasOrbMastery = HasTalent(TALENT.OrbMastery)
        local hasHighVoltage = HasTalent(TALENT.HighVoltage)
        local hasOrbBarrage = HasTalent(TALENT.OrbBarrage)
        local hasImpetus = HasTalent(TALENT.Impetus)
        local hasOPMTalent = HasTalent(TALENT.OverpoweredMissiles)
        
        -- Opener variable (ends when Touch debuff is applied)
        local isOpener = (combatTime < 5) and not hasTouchDebuff
        
        --==========================================================
        -- Sunfury hold_for_cds variable (pooling logic)
        -- Basic idea: don't spend Barrage near cooldowns unless you can recover
        --==========================================================
        local sunfury_hold_for_cds = false
        if hasSunfury then
            local canRecoverCharges = hasClearcasting or (orbCharges > 0.95 and enemyCount >= 3)
            local nearCDs = touchCD <= gcd_max * 4 or arcaneSurgeCD <= gcd_max * 4
            local duringCDs = hasArcaneSurge and arcaneSurgeRemain > gcd_max * 6
            
            if not hasArcaneSurge and not nearCDs then
                sunfury_hold_for_cds = true
            elseif hasArcaneSurge and canRecoverCharges and duringCDs then
                sunfury_hold_for_cds = true
            end
        end
        
        --==========================================================
        -- Pre-combat / Always
        --==========================================================
        
        -- 0. Interrupt: Counterspell 40yd
        if IsReady(SPELL.CounterSpell) and not ShouldSkipSpell(SPELL.CounterSpell) then
            local interruptTarget = NCF.GetInterruptTarget(40, true)
            if interruptTarget then
                return "InstantSpell", SPELL.CounterSpell, interruptTarget
            end
        end
        
        -- 0.1 Ice Block: HP < 30% AND no Hypothermia debuff
        local hasHypothermia = HasDebuff(DEBUFF.Hypothermia, "player")
        if playerHP < 30 and not hasHypothermia and IsReady(SPELL.IceBlock) and not ShouldSkipSpell(SPELL.IceBlock) then
            return "spell", SPELL.IceBlock
        end
        
        -- 0.2 Prismatic Barrier: HP < 70%
        if playerHP < 70 and IsReady(SPELL.PrismaticBarrier) and not ShouldSkipSpell(SPELL.PrismaticBarrier) then
            return "spell", SPELL.PrismaticBarrier
        end
        
        -- 0.3 Remove Curse: ally has curse
        if HasTalent(TALENT.RemoveCurse) and IsReady(SPELL.RemoveCurse) and not ShouldSkipSpell(SPELL.RemoveCurse) then
            local curseTarget = NCF.GetDispellableUnit("Curse", 40)
            if curseTarget and NCF.IsSpellInRange(SPELL.RemoveCurse, curseTarget) then
                return "InstantSpell", SPELL.RemoveCurse, curseTarget
            end
        end
        
        -- 0.4 Arcane Intellect: no buff
        if not HasBuff(SPELL.ArcaneIntellect, "player") and IsReady(SPELL.ArcaneIntellect) and not ShouldSkipSpell(SPELL.ArcaneIntellect) then
            return "spell", SPELL.ArcaneIntellect
        end
        
        -- Combat check
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end
        
        -- Burst: trinkets and racials
        if NCF.burstModeEnabled and hasArcaneSurge then
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
        -- Cooldowns
        --==========================================================
        
        -- 0. Opener Orb: Orb Mastery builds cast Orb right after first Blast
        if isOpener and hasSplintering and hasOrbMastery and IsReady(SPELL.ArcaneOrb) and not ShouldSkipSpell(SPELL.ArcaneOrb) then
            return "spell", SPELL.ArcaneOrb
        end
        
        -- 1. Arcane Missiles: opener AND Sunfury
        if hasSunfury and isOpener and hasClearcasting and IsReady(SPELL.ArcaneMissiles) and not ShouldSkipSpell(SPELL.ArcaneMissiles) then
            return "spell", SPELL.ArcaneMissiles
        end
        
        -- 2. Arcane Blast: Splintering AND salvo < 20 AND (opener OR Orb Mastery surge prep)
        local blastBuilderCondition = hasSplintering and arcaneSalvoStacks < 20 and (isOpener or (hasOrbMastery and arcaneSurgeCD < gcd_max * (manaPct / 16)))
        if blastBuilderCondition and IsReady(SPELL.ArcaneBlast) and not ShouldSkipSpell(SPELL.ArcaneBlast) then
            return "spell", SPELL.ArcaneBlast
        end
        
        -- 3. Touch of the Magi
        local touchCondition = false
        -- Splintering: use after Surge
        if hasSplintering and hasArcaneSurge then
            touchCondition = true
        end
        -- Sunfury: use at end of Surge (< 5s remain)
        if hasSunfury and hasArcaneSurge and arcaneSurgeRemain < (5 + gcd) then
            touchCondition = true
        end
        -- Off-CD use: Surge CD > 30 and no Surge buff
        if touchCD <= gcd and arcaneSurgeCD > 30 and not hasArcaneSurge then
            touchCondition = true
        end
        if touchCondition and IsReady(SPELL.TouchOfTheMagi) and not ShouldSkipSpell(SPELL.TouchOfTheMagi) then
            return "spell", SPELL.TouchOfTheMagi
        end
        
        -- 4. Arcane Surge
        if NCF.MeetsSpellTTD(SPELL.ArcaneSurge) and IsReady(SPELL.ArcaneSurge) and not ShouldSkipSpell(SPELL.ArcaneSurge) then
            return "spell", SPELL.ArcaneSurge
        end
        
        -- 5. Evocation: mana < 10% AND no surge AND no touch debuff AND surge CD > 10
        if HasTalent(TALENT.Evocation) and manaPct < 10 and not hasArcaneSurge and not hasTouchDebuff and arcaneSurgeCD > 10 and IsReady(SPELL.Evocation) and not ShouldSkipSpell(SPELL.Evocation) then
            return "spell", SPELL.Evocation
        end
        
        --==========================================================
        -- Spellslinger + Orb Mastery Branch
        --==========================================================
        if hasSplintering and hasOrbMastery then
            
            -- 1. Arcane Orb: after Barrage with CC to recoup, or in AOE (salvo <= 14)
            local orbCondition = (prevBarrage or enemyCount >= 4) and ((hasClearcasting or (not hasClearcasting and orbCharges > 0.95 and hasArcaneSurge and arcaneCharges == 0)) and arcaneSalvoStacks <= 14)
            if orbCondition and IsReady(SPELL.ArcaneOrb) and not ShouldSkipSpell(SPELL.ArcaneOrb) then
                return "spell", SPELL.ArcaneOrb
            end
            
            -- 2. Arcane Barrage: salvo >= 20 (or 18+ with Orb Barrage), hold for CDs
            local barrageCondition = (arcaneCharges == 4 or hasOrbBarrage) and arcaneSalvoStacks >= 20 and touchCD > gcd_max * 4
            -- Also barrage at end of Surge with salvo >= 10
            barrageCondition = barrageCondition or (arcaneSurgeRemain < gcd_max and hasArcaneSurge and arcaneSalvoStacks >= 10)
            if barrageCondition and IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            -- 3. Arcane Missiles: with HV or OPM, salvo <= threshold, not after Orb
            local missileThreshold = hasOPM and 10 or 15
            local missileCondition = (hasHighVoltage or hasOPMTalent) and hasClearcasting and arcaneSalvoStacks <= missileThreshold and not prevOrb
            missileCondition = missileCondition and (not hasArcaneSurge or (hasHighVoltage and enemyCount == 1))
            missileCondition = missileCondition and (enemyCount < 2 or hasOPMTalent)
            if missileCondition and IsReady(SPELL.ArcaneMissiles) and not ShouldSkipSpell(SPELL.ArcaneMissiles) then
                return "spell", SPELL.ArcaneMissiles
            end
            
            -- 4. Presence of Mind: charges < 2, no CC or no HV with orb < 0.95, not after Orb/Missiles
            local pomCondition = arcaneCharges < 2 and (not hasClearcasting or (not hasHighVoltage and orbCharges < 0.95)) and not prevOrb and not prevMissiles
            if pomCondition and HasTalent(TALENT.PresenceOfMind) and IsReady(SPELL.PresenceOfMind) and not ShouldSkipSpell(SPELL.PresenceOfMind) then
                return "spell", SPELL.PresenceOfMind
            end
            
            -- 5. Arcane Blast: if Presence of Mind up
            if hasPresenceOfMind and IsReady(SPELL.ArcaneBlast) and not ShouldSkipSpell(SPELL.ArcaneBlast) then
                return "spell", SPELL.ArcaneBlast
            end
            
            -- 6. Arcane Pulse: enemies > 3
            if HasTalent(TALENT.ArcanePulse) and enemyCount > 3 and IsReady(SPELL.ArcanePulse) and not ShouldSkipSpell(SPELL.ArcanePulse) then
                return "spell", SPELL.ArcanePulse
            end
            
            -- 7. Arcane Blast: filler
            if IsReady(SPELL.ArcaneBlast) and not ShouldSkipSpell(SPELL.ArcaneBlast) then
                return "spell", SPELL.ArcaneBlast
            end
            
            -- 8. Arcane Barrage: filler
            if IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            return nil
        end
        
        --==========================================================
        -- Spellslinger (no Orb Mastery) Branch
        --==========================================================
        if hasSplintering and not hasOrbMastery then
            
            -- 1. Arcane Orb: charges < 3 (or < 4 with 2+ enemies), need charges
            local chargeThreshold = enemyCount >= 2 and 4 or 3
            local orbCondition = arcaneCharges < chargeThreshold
            orbCondition = orbCondition and ((not hasClearcasting and hasHighVoltage) or (hasClearcasting and arcaneSalvoStacks >= 12) or enemyCount >= 2)
            orbCondition = orbCondition and touchCD > gcd_max * 4
            if orbCondition and IsReady(SPELL.ArcaneOrb) and not ShouldSkipSpell(SPELL.ArcaneOrb) then
                return "spell", SPELL.ArcaneOrb
            end
            
            -- 2. Arcane Barrage: salvo >= 20, hold for CDs
            if arcaneSalvoStacks >= 20 and (arcaneCharges == 4 or hasOrbBarrage) and touchCD > gcd_max * 4 and IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            -- 3. Arcane Barrage: AOE with CC + OPM + HV, salvo between 5-14
            if enemyCount >= 2 and arcaneCharges == 4 and hasClearcasting and hasOPM and hasHighVoltage and arcaneSalvoStacks > 5 and arcaneSalvoStacks < 14 and touchCD > gcd_max * 4 and IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            -- 4. Arcane Missiles: for charges with HV and salvo stacks
            local missileThreshold = hasOPM and 10 or 15
            local missileCondition = hasClearcasting and ((arcaneSalvoStacks < missileThreshold) or (arcaneCharges < 2 and hasHighVoltage and enemyCount >= 2))
            if missileCondition and IsReady(SPELL.ArcaneMissiles) and not ShouldSkipSpell(SPELL.ArcaneMissiles) then
                return "spell", SPELL.ArcaneMissiles
            end
            
            -- 5. Presence of Mind: charges < 2, conditions
            local pomCondition = arcaneCharges < 2 and (not hasClearcasting or (not hasHighVoltage and orbCharges < 0.95)) and not prevOrb and not prevMissiles
            if pomCondition and HasTalent(TALENT.PresenceOfMind) and IsReady(SPELL.PresenceOfMind) and not ShouldSkipSpell(SPELL.PresenceOfMind) then
                return "spell", SPELL.PresenceOfMind
            end
            
            -- 6. Arcane Blast: if Presence of Mind up
            if hasPresenceOfMind and IsReady(SPELL.ArcaneBlast) and not ShouldSkipSpell(SPELL.ArcaneBlast) then
                return "spell", SPELL.ArcaneBlast
            end
            
            -- 7. Arcane Pulse: enemies > 3
            if HasTalent(TALENT.ArcanePulse) and enemyCount > 3 and IsReady(SPELL.ArcanePulse) and not ShouldSkipSpell(SPELL.ArcanePulse) then
                return "spell", SPELL.ArcanePulse
            end
            
            -- 8. Arcane Blast: filler
            if IsReady(SPELL.ArcaneBlast) and not ShouldSkipSpell(SPELL.ArcaneBlast) then
                return "spell", SPELL.ArcaneBlast
            end
            
            -- 9. Arcane Barrage: filler
            if IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            return nil
        end
        
        --==========================================================
        -- Sunfury Branch
        --==========================================================
        if hasSunfury then
            
            -- 1. Arcane Barrage: complex conditions
            local barrageCondition = false
            
            -- During Arcane Soul - always barrage
            if hasArcaneSoul then
                barrageCondition = true
            end
            
            -- Right after Touch
            if prevTouch then
                barrageCondition = true
            end
            
            -- End of Touch debuff
            if touchDebuffRemain < gcd_max and hasTouchDebuff and arcaneCharges == 4 then
                barrageCondition = true
            end
            
            -- Salvo spending with hold_for_cds check
            if arcaneCharges == 4 and sunfury_hold_for_cds then
                local canRecover = (hasClearcasting and hasHighVoltage) or (orbCharges > 0.95 and enemyCount >= 3)
                -- Spend at 0-7, 10-12, 15-17 salvo ranges, or at 25
                local inSpendRange = (arcaneSalvoStacks >= 0 and arcaneSalvoStacks < 7) or 
                                     (arcaneSalvoStacks >= 10 and arcaneSalvoStacks < 12) or 
                                     (arcaneSalvoStacks >= 15 and arcaneSalvoStacks < 17)
                if (canRecover and inSpendRange) or arcaneSalvoStacks == 25 then
                    barrageCondition = true
                end
            end
            
            if barrageCondition and IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            -- 2. Arcane Missiles: CC with complex conditions
            local missileCondition = false
            if hasClearcasting then
                -- Check OPM buff (not talent) for threshold
                local hasOPMBuff = HasBuff(BUFF.OverpoweredMissiles, "player")
                local salvoThreshold = (hasOPMBuff and not hasArcaneSurge) and 10 or 15
                
                -- Basic condition: salvo < threshold
                local basicCondition = (touchCD > gcd_max * 8 and not hasOPMBuff) or hasArcaneSurge or arcaneCharges < 3 or clearcastingStacks > 1
                basicCondition = basicCondition and arcaneSalvoStacks < salvoThreshold
                
                -- Touch + Surge combo
                local comboCondition = hasTouchDebuff and hasArcaneSurge
                
                if basicCondition or comboCondition then
                    missileCondition = true
                end
            end
            
            if missileCondition and IsReady(SPELL.ArcaneMissiles) and not ShouldSkipSpell(SPELL.ArcaneMissiles) then
                return "spell", SPELL.ArcaneMissiles
            end
            
            -- 3. Arcane Orb: charges < 2
            if arcaneCharges < 2 and IsReady(SPELL.ArcaneOrb) and not ShouldSkipSpell(SPELL.ArcaneOrb) then
                return "spell", SPELL.ArcaneOrb
            end
            
            -- 4. Arcane Pulse: enemies > 3
            if HasTalent(TALENT.ArcanePulse) and enemyCount > 3 and IsReady(SPELL.ArcanePulse) and not ShouldSkipSpell(SPELL.ArcanePulse) then
                return "spell", SPELL.ArcanePulse
            end
            
            -- 5. Arcane Explosion: enemies > 3, charges < 2, no Impetus
            if enemyCount > 3 and arcaneCharges < 2 and not hasImpetus and IsReady(SPELL.ArcaneExplosion) and not ShouldSkipSpell(SPELL.ArcaneExplosion) then
                return "spell", SPELL.ArcaneExplosion
            end
            
            -- 6. Arcane Blast: filler
            if IsReady(SPELL.ArcaneBlast) and not ShouldSkipSpell(SPELL.ArcaneBlast) then
                return "spell", SPELL.ArcaneBlast
            end
            
            -- 7. Arcane Barrage: filler
            if IsReady(SPELL.ArcaneBarrage) and not ShouldSkipSpell(SPELL.ArcaneBarrage) then
                return "spell", SPELL.ArcaneBarrage
            end
            
            return nil
        end
        
        -- Fallback
        return nil
    end

    return Rotation
end

-- Create and return rotation instance
return CreateArcaneRotation()