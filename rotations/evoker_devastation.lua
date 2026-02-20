--============================================================
-- Devastation Evoker Rotation (Simplified)
-- 12.0 Midnight Version
--============================================================

--============================================================
-- 1. Register Spells
--============================================================
NCF.RegisterSpells("EVOKER", 1, {
    { id = 375087, name = "Dragonrage", default = "burst" },
    { id = 382266, name = "Fire Breath", default = "normal" },
    { id = 382411, name = "Eternity Surge", default = "normal" },
    { id = 370553, name = "Tip the Scales", default = "normal" },
    { id = 357211, name = "Pyre", default = "normal" },
    { id = 356995, name = "Disintegrate", default = "normal" },
    { id = 362969, name = "Azure Strike", default = "normal" },
    { id = 361469, name = "Living Flame", default = "normal" },
})

--============================================================
-- 2. IDs
--============================================================
local SPELL = {
    FireBreath = 382266,
    EternitySurge = 382411,
    Dragonrage = 375087,
    TipTheScales = 370553,
    Pyre = 357211,
    Disintegrate = 356995,
    AzureStrike = 362969,
    LivingFlame = 361469,
}

local BUFF = {
    Dragonrage = 375087,
    TipTheScales = 370553,
    EssenceBurst = 359818,
    MassDisintegrateStacks = 436336,
    Burnout = 375802,
    LeapingFlames = 370901,
    AncientFlame = 375583,
    ChargedBlast = 370454,
}

local DEBUFF = {
    FireBreath = 357209,
}

local TALENT = {
    MassDisintegrate = 436335,
    ConsumeFlame = 444088,
    Animosity = 375797,
    FeedTheFlames = 369846,
    Volatility = 369089,
}

--============================================================
-- 3. Helpers
--============================================================
local HasBuff = NCF.HasBuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffRemain = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetMaxTTD = NCF.GetMaxTTD

--============================================================
-- 4. Main Rotation
--============================================================
local function CreateDevastationRotation()
    return function()
        NCF.RefreshGCD()

        local enemyCount = GetActiveEnemyAmount(25, false)
        SetEnemyCount(enemyCount)

        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        local isMoving = GetUnitSpeed("player") > 0
        local targetTTD = GetMaxTTD() or 999
        
        -- Cooldowns
        local dragonrageCD = GetSpellCooldownRemain(SPELL.Dragonrage)
        local fireBreathCD = GetSpellCooldownRemain(SPELL.FireBreath)
        local eternitySurgeCD = GetSpellCooldownRemain(SPELL.EternitySurge)
        
        -- Buffs
        local hasDragonrage = HasBuff(BUFF.Dragonrage)
        local hasTipTheScales = HasBuff(BUFF.TipTheScales)
        local hasMassDisintegrateStacks = HasBuff(BUFF.MassDisintegrateStacks)
        local hasBurnout = HasBuff(BUFF.Burnout)
        local hasLeapingFlames = HasBuff(BUFF.LeapingFlames)
        local hasAncientFlame = HasBuff(BUFF.AncientFlame)
        local chargedBlastStacks = GetBuffStacks(BUFF.ChargedBlast)
        
        -- Debuffs
        local fireBreathRemain = GetDebuffRemain(DEBUFF.FireBreath, "target")
        
        -- Talents
        local hasMassDisintegrate = HasTalent(TALENT.MassDisintegrate)
        local hasConsumeFlame = HasTalent(TALENT.ConsumeFlame)
        local hasAnimosity = HasTalent(TALENT.Animosity)
        local hasFeedTheFlames = HasTalent(TALENT.FeedTheFlames)
        local hasVolatility = HasTalent(TALENT.Volatility)
        
        -- Ready checks
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- Burst phase
        if NCF.burstModeEnabled and hasDragonrage then
            NCF.UseTrinket()
            if NCF.enablePotion then NCF.UseCombatPotion() end
        end
        
        -- Combat check
        if not UnitAffectingCombat("player") and not (UnitExists("target") and UnitAffectingCombat("target")) then
            return "spell", 61304
        end
        
        --============================================================
        -- AOE (enemies >= 3)
        --============================================================
        if enemyCount >= 3 then
            -- Dragonrage
            if targetTTD >= 15 and IsReady(SPELL.Dragonrage) and not ShouldSkipSpell(SPELL.Dragonrage) then
                return "spell", SPELL.Dragonrage
            end
            
            -- Tip the Scales (not if already have buff)
            if hasDragonrage and not hasTipTheScales and IsReady(SPELL.TipTheScales) and not ShouldSkipSpell(SPELL.TipTheScales) then
                return "spell", SPELL.TipTheScales
            end
            
            -- Eternity Surge
            if eternitySurgeCD <= gcd and not ShouldSkipSpell(SPELL.EternitySurge) then
                return "spell", SPELL.EternitySurge
            end
            
            -- Fire Breath
            if fireBreathRemain < 5 and fireBreathCD <= gcd and not ShouldSkipSpell(SPELL.FireBreath) then
                return "spell", SPELL.FireBreath
            end
            
            -- Pyre (charged_blast >= 12)
            if chargedBlastStacks >= 12 and IsReady(SPELL.Pyre) and not ShouldSkipSpell(SPELL.Pyre) then
                return "spell", SPELL.Pyre
            end
            
            -- Disintegrate (mass stacks)
            if hasMassDisintegrateStacks and hasMassDisintegrate and IsReady(SPELL.Disintegrate) and not ShouldSkipSpell(SPELL.Disintegrate) then
                return "spell", SPELL.Disintegrate
            end
            
            -- Pyre
            if IsReady(SPELL.Pyre) and not ShouldSkipSpell(SPELL.Pyre) then
                return "spell", SPELL.Pyre
            end
            
            -- Living Flame (leaping flames)
            if hasLeapingFlames and IsReady(SPELL.LivingFlame) and not ShouldSkipSpell(SPELL.LivingFlame) then
                return "spell", SPELL.LivingFlame
            end
            
            -- Azure Strike
            if IsReady(SPELL.AzureStrike) and not ShouldSkipSpell(SPELL.AzureStrike) then
                return "spell", SPELL.AzureStrike
            end
            
        --============================================================
        -- ST (enemies < 3)
        --============================================================
        else
            -- Dragonrage
            if targetTTD >= 30 and IsReady(SPELL.Dragonrage) and not ShouldSkipSpell(SPELL.Dragonrage) then
                return "spell", SPELL.Dragonrage
            end
            
            -- Tip the Scales (in dragonrage, not if already have buff)
            if hasDragonrage and not hasTipTheScales and IsReady(SPELL.TipTheScales) and not ShouldSkipSpell(SPELL.TipTheScales) then
                return "spell", SPELL.TipTheScales
            end
            
            -- Eternity Surge
            if eternitySurgeCD <= gcd and not ShouldSkipSpell(SPELL.EternitySurge) then
                return "spell", SPELL.EternitySurge
            end
            
            -- Fire Breath
            if fireBreathRemain < 5 and fireBreathCD <= gcd and not ShouldSkipSpell(SPELL.FireBreath) then
                return "spell", SPELL.FireBreath
            end
            
            -- Disintegrate (mass stacks)
            if hasMassDisintegrateStacks and hasMassDisintegrate and not isMoving and IsReady(SPELL.Disintegrate) and not ShouldSkipSpell(SPELL.Disintegrate) then
                return "spell", SPELL.Disintegrate
            end
            
            -- Pyre (2 target with FTF + Volatility)
            if enemyCount > 1 and hasFeedTheFlames and hasVolatility and IsReady(SPELL.Pyre) and not ShouldSkipSpell(SPELL.Pyre) then
                return "spell", SPELL.Pyre
            end
            
            -- Disintegrate
            if not isMoving and IsReady(SPELL.Disintegrate) and not ShouldSkipSpell(SPELL.Disintegrate) then
                return "spell", SPELL.Disintegrate
            end
            
            -- Living Flame (burnout / leaping / ancient)
            if (hasBurnout or hasLeapingFlames or hasAncientFlame) and IsReady(SPELL.LivingFlame) and not ShouldSkipSpell(SPELL.LivingFlame) then
                return "spell", SPELL.LivingFlame
            end
            
            -- Azure Strike (2+ targets)
            if enemyCount >= 2 and IsReady(SPELL.AzureStrike) and not ShouldSkipSpell(SPELL.AzureStrike) then
                return "spell", SPELL.AzureStrike
            end
            
            -- Living Flame (not moving)
            if not isMoving and IsReady(SPELL.LivingFlame) and not ShouldSkipSpell(SPELL.LivingFlame) then
                return "spell", SPELL.LivingFlame
            end
            
            -- Azure Strike
            if IsReady(SPELL.AzureStrike) and not ShouldSkipSpell(SPELL.AzureStrike) then
                return "spell", SPELL.AzureStrike
            end
        end
        
        return nil
    end
end

return CreateDevastationRotation()