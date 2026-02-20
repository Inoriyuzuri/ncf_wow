--============================================================
-- 恢复萨满循环 (Restoration Shaman APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

=== 治疗阶段 ===
1. 生命释放 (73685): 任意队友血量 < 95%
2. 先祖迅捷 (443454): 自己没有buff 443454 且 任意队友血量 < 95%
3. 激流 (61295): 对没有激流buff的最低血量队友
4. 水之护盾 (52127): 自己没有buff 52127
5. 大地之盾 (974): 坦克没有buff 974
6. 治疗之泉图腾 (5394): 团队血量 < 90% 且 充能 > 1.9
7. 治疗之泉图腾 (5394): 团队血量 < 50% 且 充能 > 1
8. 治疗波 (77472): 任意队友血量 < 90%
9. 治疗之雨 (73920): 自己没有buff 73920
10. 升腾 (114052): 团队血量 < 45%

=== 输出阶段 ===
11. 烈焰震击 (470411): 对没有烈焰震击debuff(188389)的敌人
12. 熔岩爆裂 (51505): 有熔岩奔涌buff(77762)时, 对有烈焰震击debuff的敌人
13. 闪电箭 (188196): 敌人 < 2
14. 闪电链 (188443): 敌人 >= 2

Buff ID 参考:
- 熔岩奔涌: 77762
- 激流: 61295
- 水之护盾: 52127
- 大地之盾: 974
- 先祖迅捷: 443454
- 治疗之雨: 73920

Debuff ID 参考:
- 烈焰震击: 188389
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("SHAMAN", 3, {
    -- 爆发技能
    { id = 114052, name = "升腾", default = "burst" },
    
    -- 治疗技能
    { id = 73685, name = "生命释放", default = "normal" },
    { id = 443454, name = "先祖迅捷", default = "normal" },
    { id = 61295, name = "激流", default = "normal" },
    { id = 52127, name = "水之护盾", default = "normal" },
    { id = 974, name = "大地之盾", default = "normal" },
    { id = 5394, name = "治疗之泉图腾", default = "normal" },
    { id = 77472, name = "治疗波", default = "normal" },
    { id = 73920, name = "治疗之雨", default = "normal" },
    { id = 77130, name = "净化灵魂", default = "normal" },
    { id = 57994, name = "风剪", default = "normal" },
    
    -- 输出技能
    { id = 470411, name = "烈焰震击", default = "normal" },
    { id = 51505, name = "熔岩爆裂", default = "normal" },
    { id = 188196, name = "闪电箭", default = "normal" },
    { id = 188443, name = "闪电链", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    -- 治疗
    Unleash = 73685,                -- 生命释放
    AncestralSwiftness = 443454,    -- 先祖迅捷
    Riptide = 61295,                -- 激流
    WaterShield = 52127,            -- 水之护盾
    EarthShield = 974,              -- 大地之盾
    HealingStreamTotem = 5394,      -- 治疗之泉图腾
    HealingWave = 77472,            -- 治疗波
    HealingRain = 73920,            -- 治疗之雨
    Ascendance = 114052,            -- 升腾
    PurifySpirit = 77130,           -- 净化灵魂
    WindShear = 57994,              -- 风剪
    
    -- Buff技能
    Windfury = 462854,              -- 风怒
    
    -- 输出
    FlameShock = 470411,            -- 烈焰震击
    LavaBurst = 51505,              -- 熔岩爆裂
    LightningBolt = 188196,         -- 闪电箭
    ChainLightning = 188443,        -- 闪电链
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    LavaSurge = 77762,              -- 熔岩奔涌
    Riptide = 61295,                -- 激流
    WaterShield = 52127,            -- 水之护盾
    EarthShield = 974,              -- 大地之盾
    AncestralSwiftness = 443454,    -- 先祖迅捷
    HealingRain = 73920,            -- 治疗之雨
    Windfury = 462854,              -- 风怒
}

--============================================================
-- 4. Debuff ID定义
--============================================================
local DEBUFF = {
    FlameShock = 188389,            -- 烈焰震击
}

--============================================================
-- 4.5 天赋ID定义
--============================================================
local TALENT = {
    HealingRain = 73920,            -- 治疗之雨
}

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local GetEnemyWithoutDebuff = NCF.GetEnemyWithoutDebuff
local GetEnemyWithDebuff = NCF.GetEnemyWithDebuff
local GetGroupAverageHealthPct = NCF.GetGroupAverageHealthPct
local GetLowestHealthMember = NCF.GetLowestHealthMember
local GetTankUnit = NCF.GetTankUnit
local GetUnitHealthPct = NCF.GetUnitHealthPct
local GetDispellableUnit = NCF.GetDispellableUnit

--============================================================
-- 6. 辅助函数
--============================================================

-- 查找没有激流buff的最低血量队友 (使用技能射程检查)
local function GetLowestWithoutRiptide(spellID)
    local members = NCF.GetGroupMembers()
    local lowestUnit = nil
    local lowestPct = 101
    
    for _, unit in ipairs(members) do
        -- 使用技能射程检查
        if NCF.IsSpellInRange(spellID, unit) and not HasBuff(BUFF.Riptide, unit) then
            local pct = GetUnitHealthPct(unit)
            if pct < lowestPct then
                lowestPct = pct
                lowestUnit = unit
            end
        end
    end
    
    return lowestUnit, lowestPct
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateRestorationRotation()

    local function Rotation()
        local enemyCount = GetActiveEnemyAmount(40, false)
        SetEnemyCount(enemyCount)

        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)

        local function IsReady(spellID)
            return GetSpellCooldownRemain(spellID) <= gcd
        end

        -- 常用状态缓存
        local avgHp = GetGroupAverageHealthPct(40)
        local lowestUnit, lowestHp = GetLowestHealthMember(40, 100, SPELL.HealingWave)
        local myHp = GetUnitHealthPct("player")
        local tankUnit = GetTankUnit()
        local hasLavaSurge = HasBuff(BUFF.LavaSurge, "player")

        --========================================
        -- 打断
        --========================================
        
        -- 风剪: 30码 不需要面朝
        if IsReady(SPELL.WindShear) and not ShouldSkipSpell(SPELL.WindShear) then
            local interruptTarget = NCF.GetInterruptTarget(30, false)
            if interruptTarget then
                return "InstantSpell", SPELL.WindShear, interruptTarget
            end
        end

        -- 4. 水之护盾: 自己没有buff
        if not HasBuff(BUFF.WaterShield, "player") and IsReady(SPELL.WaterShield) and not ShouldSkipSpell(SPELL.WaterShield) then
            return "spell", SPELL.WaterShield
        end
        
        -- 战前准备: 风怒
        if not HasBuff(BUFF.Windfury, "player") and IsReady(SPELL.Windfury) then
            return "spell", SPELL.Windfury
        end
		
		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end
        --========================================
        -- 治疗循环
        --========================================

        -- 0. 净化灵魂: 友方有可驱散debuff (Magic)
        local dispelTarget = GetDispellableUnit("Magic", 40)
        if dispelTarget and IsReady(SPELL.PurifySpirit) and not ShouldSkipSpell(SPELL.PurifySpirit) then
            return "spell", SPELL.PurifySpirit, dispelTarget
        end

        -- 1. 生命释放: 任意队友血量 < 95%
        if lowestHp < 95 and IsReady(SPELL.Unleash) and not ShouldSkipSpell(SPELL.Unleash) then
            return "spell", SPELL.Unleash
        end

        -- 2. 先祖迅捷: 自己没有buff 且 任意队友血量 < 95%
        if lowestHp < 95 and not HasBuff(BUFF.AncestralSwiftness, "player") and IsReady(SPELL.AncestralSwiftness) and not ShouldSkipSpell(SPELL.AncestralSwiftness) then
            return "spell", SPELL.AncestralSwiftness
        end

        -- 3. 激流: 对没有激流buff的最低血量队友
        if IsReady(SPELL.Riptide) and not ShouldSkipSpell(SPELL.Riptide) then
            local riptideTarget = GetLowestWithoutRiptide(SPELL.Riptide)
            if riptideTarget then
                return "spell", SPELL.Riptide, riptideTarget
            end
        end

        -- 4. 水之护盾: 自己没有buff
        if not HasBuff(BUFF.WaterShield, "player") and IsReady(SPELL.WaterShield) and not ShouldSkipSpell(SPELL.WaterShield) then
            return "spell", SPELL.WaterShield
        end

        -- 5. 大地之盾: 坦克没有buff
        if tankUnit and NCF.IsSpellInRange(SPELL.EarthShield, tankUnit) and not HasBuff(BUFF.EarthShield, tankUnit) and IsReady(SPELL.EarthShield) and not ShouldSkipSpell(SPELL.EarthShield) then
            return "spell", SPELL.EarthShield, tankUnit
        end

        -- 6. 治疗之泉图腾: 团队血量 < 90% 且 充能 > 1.9
        local totemCharges = GetSpellCharges(SPELL.HealingStreamTotem) or 0
        if avgHp < 90 and totemCharges > 1.9 and IsReady(SPELL.HealingStreamTotem) and not ShouldSkipSpell(SPELL.HealingStreamTotem) then
            return "spell", SPELL.HealingStreamTotem
        end

        -- 7. 治疗之泉图腾: 团队血量 < 50% 且 充能 > 1
        if avgHp < 50 and totemCharges > 1 and IsReady(SPELL.HealingStreamTotem) and not ShouldSkipSpell(SPELL.HealingStreamTotem) then
            return "spell", SPELL.HealingStreamTotem
        end

        -- 8. 治疗波: 任意队友血量 < 90%
        if lowestUnit and lowestHp < 90 and IsReady(SPELL.HealingWave) and not ShouldSkipSpell(SPELL.HealingWave) then
            return "spell", SPELL.HealingWave, lowestUnit
        end

        -- 9. 治疗之雨: 需要天赋 且 自己没有buff
        if HasTalent(TALENT.HealingRain) and not HasBuff(BUFF.HealingRain, "player") and IsReady(SPELL.HealingRain) and not ShouldSkipSpell(SPELL.HealingRain) then
            return "spell", SPELL.HealingRain
        end

        -- 10. 升腾: 团队血量 < 45%
        if avgHp < 45 and IsReady(SPELL.Ascendance) and not ShouldSkipSpell(SPELL.Ascendance) then
            return "spell", SPELL.Ascendance
        end

        --========================================
        -- 输出循环
        --========================================

        -- 11. 烈焰震击: 对没有debuff的敌人
        if IsReady(SPELL.FlameShock) and not ShouldSkipSpell(SPELL.FlameShock) then
            local noFSTarget = GetEnemyWithoutDebuff(DEBUFF.FlameShock, 40, false, SPELL.FlameShock)
            if noFSTarget then
                return "InstantSpell", SPELL.FlameShock, noFSTarget
            end
        end

        -- 12. 熔岩爆裂: 有熔岩奔涌buff时, 对有烈焰震击debuff的敌人
        if hasLavaSurge and IsReady(SPELL.LavaBurst) and not ShouldSkipSpell(SPELL.LavaBurst) then
            local fsTarget = GetEnemyWithDebuff(DEBUFF.FlameShock, 40, false, SPELL.LavaBurst)
            if fsTarget then
                return "InstantSpell", SPELL.LavaBurst, fsTarget
            end
        end

        -- 13. 闪电箭: 敌人 < 2
        if enemyCount < 2 and IsReady(SPELL.LightningBolt) and not ShouldSkipSpell(SPELL.LightningBolt) then
            if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
                return "spell", SPELL.LightningBolt
            end
        end

        -- 14. 闪电链: 敌人 >= 2
        if enemyCount >= 2 and IsReady(SPELL.ChainLightning) and not ShouldSkipSpell(SPELL.ChainLightning) then
            if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
                return "spell", SPELL.ChainLightning
            end
        end
		
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateRestorationRotation()