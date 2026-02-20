--============================================================
-- 刺杀盗贼循环 (Assassination Rogue APL)
-- 模块化文件，由主文件通过 Nn:Require() 加载
-- 使用全局 NCF 表访问主文件函数
--============================================================

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("ROGUE", 1, {
    -- 爆发技能 (默认在平缓模式下不使用)
    { id = 1856, name = "消失", default = "burst" },
    { id = 360194, name = "死亡印记", default = "burst" },
    { id = 385627, name = "弑君", default = "burst" },
    
    -- 平缓技能 (默认始终使用)
    { id = 1784, name = "潜行", default = "normal" },
    { id = 1329, name = "毁伤", default = "normal" },
    { id = 8676, name = "伏击", default = "normal" },
    { id = 32645, name = "毒伤", default = "normal" },
    { id = 1943, name = "割裂", default = "normal" },
    { id = 703, name = "绞喉", default = "normal" },
    { id = 51723, name = "刀扇", default = "normal" },
    { id = 1247227, name = "猩红风暴", default = "normal" },
    { id = 1766, name = "脚踢", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    -- 基础技能
    Stealth = 1784,           -- 潜行
    Kick = 1766,              -- 脚踢
    Mutilate = 1329,          -- 毁伤
    Ambush = 8676,            -- 伏击
    Envenom = 32645,          -- 毒伤
    Rupture = 1943,           -- 割裂
    Garrote = 703,            -- 绞喉
    FanOfKnives = 51723,      -- 刀扇
    SliceAndDice = 315496,    -- 切割
    
    -- 冷却技能
    Vanish = 1856,            -- 消失
    Deathmark = 360194,       -- 死亡印记
    Kingsbane = 385627,       -- 弑君
    ColdBlood = 382245,       -- 冷血
    ThistleTea = 381623,      -- 蓟茶
    Shiv = 5938,              -- 毒刃
    
    -- AOE 技能
    CrimsonStorm = 1247227,   -- 猩红风暴 (传染割裂和绞喉)
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    Kingsbane = 385627,           -- 弑君
    DashingScoundrel = 381797,    -- 风流剑客
    ViciousVenoms = 381634,       -- 恶毒之毒
    AmplifyingPoison = 381664,    -- 增幅毒药
    ScentOfBlood = 394080,        -- 血腥气息
    IndiscriminateCarnage = 385754, -- 无差别杀戮
    ImprovedGarrote = 381632,     -- 强化绞喉
    MasterAssassin = 255989,      -- 大师刺客
    Subterfuge = 108208,          -- 潜伏
    ArterialPrecision = 400801,   -- 动脉精准
    CausticSpatter = 421975,      -- 腐蚀飞溅
    MomentumOfDespair = 457270,   -- 绝望之势
    ThrownPrecision = 457111,     -- 投掷精准
    ZoldyckRecipe = 381798,       -- 佐迪克秘方
    Deathstalker = 457054,        -- 死亡追踪者
    PoisonBomb = 255544,          -- 毒药炸弹
    ShroudedSuffocation = 385478, -- 暗影窒息
}

--============================================================
-- 4. Buff ID定义 (玩家身上的增益效果)
--============================================================
local BUFF = {
    Envenom = 32645,              -- 毒伤
    SliceAndDice = 315496,        -- 切割
    DarkestNight = 457280,        -- 至暗之夜
    IndiscriminateCarnage = 385754, -- 无差别杀戮
    MasterAssassin = 256735,      -- 大师刺客
    Blindside = 121153,           -- 盲点
    ScentOfBlood = 394080,        -- 血腥气息
    ClearTheWitnesses = 457178,   -- 清除证人
    FateboundCoinTails = 452903,  -- 命运硬币(反)
    FateboundCoinHeads = 452922,  -- 命运硬币(正)
    ImprovedGarrote = 392403,     -- 强化绞喉 (潜行后获得)
    LingeringDarkness = 457273,   -- 挥之不去的黑暗
    ColdBlood = 382245,           -- 冷血
    Stealth = 1784,               -- 潜行
    Vanish = 11327,               -- 消失
    ShadowDance = 185422,         -- 暗影之舞
    Subterfuge = 115191,          -- 潜伏
}

--============================================================
-- 5. Debuff ID定义 (目标身上的减益效果)
--============================================================
local DEBUFF = {
    Kingsbane = 385627,           -- 弑君
    Deathmark = 360194,           -- 死亡印记
    Garrote = 703,                -- 绞喉
    Rupture = 1943,               -- 割裂
    DeadlyPoison = 2818,          -- 致命毒药
    AmplifyingPoison = 381664,    -- 增幅毒药
    CausticSpatter = 421976,      -- 腐蚀飞溅
    DeathstalkersMark = 457052,   -- 死亡追踪者印记
    Shiv = 319504,                -- 毒刃减速
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local IsSpellReady = NCF.IsSpellReady
local IsStealthed = NCF.IsStealthed
local GetBuffRemain = NCF.GetBuffRemain
local GetDebuffRemain = NCF.GetDebuffRemain
local GetDebuffStacks = NCF.GetDebuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local GetCombatTime = NCF.GetCombatTime
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount

local function GetComboPoints()
    return NCF.GetUnitPower("player", "combopoints")
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateAssassinationRotation()

    --[[
        获取有效连击点消耗上限
        - 正常情况下为 5 点
        - 当拥有"至暗之夜"(Darkest Night) buff 时为 7 点
        - 这会影响何时使用终结技
    ]]
    local function GetEffectiveSpendCP()
        if HasBuff(BUFF.DarkestNight) then
            return 7
        end
        return 5
    end

    --[[
        消失/潜行 使用逻辑
        
        优先级：
        1. 非战斗状态 → 使用潜行 (Stealth, 1784)
        2. 战斗状态 → 只在死亡印记和弑君都在2秒内就绪时使用消失
        
        消失的目的是配合"强化绞喉"天赋，在潜行状态下绞喉造成额外伤害
        流程：消失 → 强化绞喉 → 死亡印记 → 弑君
        
        注意：战斗开始前10秒，盗贼从潜行开怪自带强化绞喉，不需要消失
    ]]
    local function AssassinationVanish()
        -- 非战斗状态：优先使用普通潜行而非消失
        if not UnitAffectingCombat("player") and not IsStealthed() and IsSpellReady(SPELL.Stealth) then
            if not ShouldSkipSpell(SPELL.Stealth) then
                return SPELL.Stealth
            end
        end
        
        if not IsSpellReady(SPELL.Vanish) then return nil end
        
        -- 检查消失是否被禁用/爆发限制
        if ShouldSkipSpell(SPELL.Vanish) then return nil end
        
        -- 战斗前10秒，从潜行开怪自带强化绞喉，不需要消失
        local combatTime = GetCombatTime()
        if combatTime > 0 and combatTime < 10 then
            return nil
        end
        
        -- 战斗中：只在死亡印记和弑君都在2秒内就绪时使用消失
        local deathmarkCD = GetSpellCooldownRemain(SPELL.Deathmark)
        local kingsbaneCD = GetSpellCooldownRemain(SPELL.Kingsbane)
        
        if HasTalent(TALENT.Kingsbane) then
            -- 有弑君天赋：两者都在2秒内就绪
            if deathmarkCD <= 2 and kingsbaneCD <= 2 then
                return SPELL.Vanish
            end
        else
            -- 没有弑君天赋：只检查死亡印记
            if deathmarkCD <= 2 then
                return SPELL.Vanish
            end
        end
        
        return nil
    end

    --[[
        冷却技能 (Cooldowns) 管理
        
        优先级顺序：
        1. 消失 (Vanish) - 只在死亡印记和弑君都在2秒内就绪时使用（战斗10秒后）
        2. 死亡印记 (Deathmark) - 目标有割裂和绞喉时使用
        3. 弑君 (Kingsbane) - 和死亡印记对齐，CD差距>10秒时才单独释放
        
        爆发流程：消失 → 强化绞喉 → 死亡印记 → 弑君
        
        注意：战斗开始前10秒，盗贼从潜行开怪自带强化绞喉
        此时直接释放死亡印记和弑君，不需要等消失
    ]]
    local function AssassinationCooldowns()
        -- 获取战斗时间
        local combatTime = GetCombatTime()
        local isOpener = combatTime > 0 and combatTime < 10  -- 开怪阶段
        
        -- 消失：只在死亡印记和弑君都在2秒内就绪时使用（开怪阶段不需要消失）
        if not isOpener then
            local vanishSpell = AssassinationVanish()
            if vanishSpell then return vanishSpell end
        end
        
        -- 获取两个大技能的CD
        local deathmarkCD = GetSpellCooldownRemain(SPELL.Deathmark)
        local kingsbaneCD = GetSpellCooldownRemain(SPELL.Kingsbane)
        
		if NCF.enablePotion and NCF.burstModeEnabled and HasDebuff(DEBUFF.Kingsbane) then
			NCF.UseTrinket()
			NCF.UseCombatPotion()
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsSpellReady(racialSpell) then
                return "spell", racialSpell
            end			
		end
		
        -- 死亡印记：目标有割裂和绞喉时使用
        local deathmarkCondition = HasDebuff(DEBUFF.Rupture) and HasDebuff(DEBUFF.Garrote)
        if deathmarkCondition and IsSpellReady(SPELL.Deathmark) and not ShouldSkipSpell(SPELL.Deathmark) then
            if HasTalent(TALENT.Kingsbane) then
                -- 有弑君天赋：弑君也在2秒内就绪时才开死亡印记
                if kingsbaneCD <= 2 then
                    return SPELL.Deathmark
                end
                -- 否则等待对齐（不释放）
            else
                -- 没有弑君天赋：直接使用
                return SPELL.Deathmark
            end
        end
        
        -- 弑君：和死亡印记对齐
        if HasTalent(TALENT.Kingsbane) and IsSpellReady(SPELL.Kingsbane) and not ShouldSkipSpell(SPELL.Kingsbane) then
            -- 只有当死亡印记CD > 10秒时才单独释放弑君
            if deathmarkCD > 10 then
                return SPELL.Kingsbane
            end
            -- 否则等待对齐（不释放）
        end
        
        return nil
    end

    --[[
        潜行状态 动作优先级
        在潜行、消失或相关 buff 期间的特殊行为
        
        优先级：
        1. 强化绞喉 - 配合死亡印记爆发 (最高优先级)
        2. 伏击上死亡追踪者印记 (Deathstalker 天赋)
        3. 毒伤维护 (弑君期间保持 buff)
        4. 大师刺客期间毒伤
    ]]
    local function AssassinationStealthed()
        local cp = GetComboPoints()
        local effectiveSpendCP = GetEffectiveSpendCP()
        
        -- 强化绞喉天赋：潜行状态下绞喉有额外伤害
        -- 配合死亡印记爆发窗口，优先打强化绞喉
        if HasTalent(TALENT.ImprovedGarrote) and IsStealthed() and not ShouldSkipSpell(SPELL.Garrote) then
            -- 死亡印记就绪时，立即打绞喉
            if IsSpellReady(SPELL.Deathmark) then
                return "spell", SPELL.Garrote
            end
            -- 或者绞喉即将掉落时刷新
            if GetDebuffRemain(DEBUFF.Garrote) < 12 then
                return "spell", SPELL.Garrote
            end
        end
        
        -- 死亡追踪者天赋：用伏击上印记 debuff
        if HasTalent(TALENT.Deathstalker) and not HasDebuff(DEBUFF.DeathstalkersMark) and cp < effectiveSpendCP then
            if not ShouldSkipSpell(SPELL.Ambush) then
                return "spell", SPELL.Ambush
            end
        end
        
        -- 弑君期间：保持毒伤 buff (提高弑君伤害)
        if cp >= effectiveSpendCP and HasDebuff(DEBUFF.Kingsbane) and GetBuffRemain(BUFF.Envenom) <= 3 then
            if HasDebuff(DEBUFF.DeathstalkersMark) or HasBuff(BUFF.ColdBlood) or (HasBuff(BUFF.DarkestNight) and cp == 7) then
                if not ShouldSkipSpell(SPELL.Envenom) then
                    return "spell", SPELL.Envenom
                end
            end
        end
        
        -- 大师刺客 buff 期间：利用暴击加成打毒伤
        if cp >= effectiveSpendCP and HasBuff(BUFF.MasterAssassin) then
            if HasDebuff(DEBUFF.DeathstalkersMark) or HasBuff(BUFF.ColdBlood) or (HasBuff(BUFF.DarkestNight) and cp == 7) then
                if not ShouldSkipSpell(SPELL.Envenom) then
                    return "spell", SPELL.Envenom
                end
            end
        end
        
        return nil, nil
    end

    --[[
        检查10码内是否有目标缺少割裂或绞喉
        返回: needSpread (是否需要传染), allHaveDots (所有目标都有DoT)
    ]]
    local function CheckAoEDotsStatus()
        local results = {GetActiveEnemyAmount(10, false)}
        local total = results[1]
        if total == 0 then
            return false, false
        end
        
        local withDots = 0
        for i = 2, total + 1 do
            local unit = results[i]
            if unit and HasDebuff(DEBUFF.Rupture, unit) and HasDebuff(DEBUFF.Garrote, unit) then
                withDots = withDots + 1
            end
        end
        
        return withDots < total, withDots == total
    end

    --[[
        核心 DoT 维护
        保持绞喉 (Garrote) 和割裂 (Rupture) 的高覆盖率
        
        刷新时机：
        - 绞喉：剩余 <5.4 秒时刷新 (30% 持续时间)
        - 割裂：剩余 <7.2 秒时刷新 (30% 持续时间)
    ]]
    local function AssassinationCoreDot(cp, effectiveSpendCP, regenSaturated)
        -- 绞喉：低连击点时维护，避免浪费连击点
        if cp < effectiveSpendCP and GetDebuffRemain(DEBUFF.Garrote) < 5.4 then
            if not ShouldSkipSpell(SPELL.Garrote) then
                return SPELL.Garrote
            end
        end
        
        -- 割裂：满连击点时维护，但不在冷血/至暗之夜 buff 期间
        -- (这些 buff 应该用来打毒伤而非割裂)
        if cp >= effectiveSpendCP and not HasBuff(BUFF.ColdBlood) and not HasBuff(BUFF.DarkestNight) then
            if GetDebuffRemain(DEBUFF.Rupture) < 7.2 then
                if not ShouldSkipSpell(SPELL.Rupture) then
                    return SPELL.Rupture
                end
            end
        end
        
        return nil
    end

    --[[
        AOE DoT 传染
        当10码内有目标缺少割裂或绞喉时，使用猩红风暴传染
    ]]
    local function AssassinationAoEDot(enemyCount)
        if enemyCount < 2 then return nil end
        
        local needSpread, allHaveDots = CheckAoEDotsStatus()
        
        -- 有目标缺少DoT时，使用猩红风暴传染
        if needSpread and IsSpellReady(SPELL.CrimsonStorm) and not ShouldSkipSpell(SPELL.CrimsonStorm) then
            return SPELL.CrimsonStorm
        end
        
        return nil
    end

    --[[
        直接伤害技能
        填充技能和终结技的使用逻辑
        
        优先级：
        1. 毒伤 (Envenom) - 满连击点时的主要输出
        2. 至暗之夜毒伤 - 7 连击点时使用
        3. 伏击 (Ambush) - 盲点触发或潜行状态
        4. 刀扇/毁伤 - AOE用刀扇，单体用毁伤
    ]]
    local function AssassinationDirect(cp, cpDeficit, effectiveSpendCP, notPooling, singleTarget, cdSoon, enemyCount)
        -- 是否使用填充技：连击点未满，且不需要为 CD 囤能量
        local useFiller = cp <= effectiveSpendCP and (not cdSoon or notPooling or not singleTarget)
        
        -- 毒伤：满连击点时使用 (非至暗之夜状态)
        if not HasBuff(BUFF.DarkestNight) and cp >= effectiveSpendCP then
            -- 不囤能量时使用，或者增幅毒药层数满时使用
            if notPooling or GetDebuffStacks(DEBUFF.AmplifyingPoison) >= 20 or not singleTarget then
                if not ShouldSkipSpell(SPELL.Envenom) then
                    return SPELL.Envenom
                end
            end
        end
        
        -- 至暗之夜毒伤：需要 7 连击点
        if HasBuff(BUFF.DarkestNight) and cp >= 7 then
            if not ShouldSkipSpell(SPELL.Envenom) then
                return SPELL.Envenom
            end
        end
        
        -- 伏击：盲点 (Blindside) 触发时免费使用，或潜行状态下使用
        if useFiller and (HasBuff(BUFF.Blindside) or IsStealthed()) then
            -- 避免在弑君+死亡印记期间浪费伏击 (除非是盲点触发)
            if not HasDebuff(DEBUFF.Kingsbane) or not HasDebuff(DEBUFF.Deathmark) or HasBuff(BUFF.Blindside) then
                if not ShouldSkipSpell(SPELL.Ambush) then
                    return SPELL.Ambush
                end
            end
        end
        
        -- 填充技能：AOE用刀扇，单体用毁伤
        if useFiller then
            -- AOE模式 (>=2目标)：检查是否所有目标都有DoT
            if enemyCount >= 2 then
                local needSpread, allHaveDots = CheckAoEDotsStatus()
                -- 所有目标都有DoT时，用刀扇
                if allHaveDots and not ShouldSkipSpell(SPELL.FanOfKnives) then
                    return SPELL.FanOfKnives
                end
            end
            
            -- 单体或DoT未铺满时，用毁伤
            if not ShouldSkipSpell(SPELL.Mutilate) then
                return SPELL.Mutilate
            end
        end
        
        return nil
    end

    --[[
        刺杀盗贼循环主函数
        整合所有子函数，按优先级返回下一个应该使用的技能
        
        优先级顺序：
        0. 强化绞喉 buff 存在时立即打绞喉 (最高优先级)
        1. 潜行状态特殊动作
        2. 冷却技能 (爆发)
        3. 核心 DoT 维护 (当前目标)
        4. AOE DoT 传染 (猩红风暴)
        5. 直接伤害 (毒伤、刀扇/毁伤)
    ]]
    local function Rotation()
	
        -- 非战斗中自动进入潜行
        if not UnitAffectingCombat("player") and not IsMounted() and not IsStealthed() 
            and not UnitCastingInfo("player") and not UnitChannelInfo("player") then
            if IsSpellReady(SPELL.Stealth) and not ShouldSkipSpell(SPELL.Stealth) then
                return "spell", SPELL.Stealth
            end
        end
		

        
        local cp = GetComboPoints()
        local effectiveSpendCP = GetEffectiveSpendCP()
        local cpDeficit = effectiveSpendCP - cp
        
        -- 获取附近敌人数量 (10码内360度) 并更新全局变量
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)
        
        -- 状态变量
        local singleTarget = enemyCount <= 1   -- 单目标模式：附近只有1个或更少敌人
        local notPooling = true                -- 不需要囤能量
        local cdSoon = false                   -- CD 即将就绪
        local regenSaturated = false           -- 能量回复饱和
        
        -- 以下需要战斗中才执行
        if not UnitAffectingCombat("player") then return 'spell', 61304 end
		
        -- 0. 强化绞喉 buff (392403) 存在时，立即打绞喉 (最高优先级)
        if HasBuff(BUFF.ImprovedGarrote) and not ShouldSkipSpell(SPELL.Garrote) then
            return "spell", SPELL.Garrote
        end
        
        local stealthed = IsStealthed()
        
        -- 打断：5码内面前有可打断的敌人
        if IsSpellReady(SPELL.Kick) and not ShouldSkipSpell(SPELL.Kick) then
            local interruptTarget = NCF.GetInterruptTarget(5, true)
            if interruptTarget then
                return "spell", SPELL.Kick, interruptTarget
            end
        end
        
        -- 1. 潜行状态处理 (最高优先级)
        if stealthed or HasBuff(BUFF.IndiscriminateCarnage) or HasBuff(BUFF.MasterAssassin) then
            local aType, sID = AssassinationStealthed()
            if sID then return aType, sID end
        end
        
        -- 2. 冷却技能管理
        local cdSpell = AssassinationCooldowns()
        if cdSpell then 
            return "spell", cdSpell 
        end
        
        -- 3. 核心 DoT 维护 (当前目标)
        local dotSpell = AssassinationCoreDot(cp, effectiveSpendCP, regenSaturated)
        if dotSpell then 
            return "spell", dotSpell 
        end
        
        -- 4. AOE DoT 传染 (猩红风暴) - 有目标缺少DoT时使用
        local aoeSpell = AssassinationAoEDot(enemyCount)
        if aoeSpell then
            return "spell", aoeSpell
        end
        
        -- 5. 直接伤害技能 (传入 enemyCount 用于AOE判断)
        local directSpell = AssassinationDirect(cp, cpDeficit, effectiveSpendCP, notPooling, singleTarget, cdSoon, enemyCount)
        if directSpell then 
            return "spell", directSpell 
        end
        
        return nil, nil
    end

    -- 返回主循环函数
    return Rotation
end

-- 创建并返回循环实例
return CreateAssassinationRotation()