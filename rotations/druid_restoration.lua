--============================================================
-- 恢复德鲁伊循环 (Restoration Druid APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

=== 猫形态 (野性之心输出阶段, 团队血量 >= 95%) ===
1. 割裂 (1079): 连击点 >= 4, 优先对5码内没有割裂debuff的目标
2. 斜掠 (1822): 优先对5码内没有斜掠debuff(155722)的目标
3. 团队血量 < 95% 或 丰饶层数 <= 5 → 变人形态 (768)

=== 人形态 (治疗阶段) ===
0. 铁木树皮 (102342): 最低血量 < 50%
0.1 树皮 (22812): 自己血量 < 50%
0.2 驱散 (88423): 友方有可驱散debuff (诅咒/毒)
1. 共生关系 (474750): 坦克没有buff 474750时释放
2. 生命绽放 (33763): 对当前坦克
3. 万灵 (391528): 团队血量 <= 50%
4. 宁静 (740): 团队血量 <= 65%
5. 自然迅捷 (132158): 最低血量 < 60%
6. 迅捷治愈 (18562): 最低3人平均血量 < 60%
7. 愈合 (8936): 最低血量 < 80%
8. 回春 (774): 对血量 < 100% 且没有两个回春buff(774,155777)的人
9. 回春 (774): 如果buff 丰饶(207640) 层数 <= 5, 对任意没有两个回春buff的人

=== 形态切换 ===
- 团队血量 >= 95% → 变猫 (768)
- 团队血量 < 95% → 变人 (768), 等待buff 768消失后开始治疗

Buff ID 参考:
- 猫形态: 768
- 回春术: 774
- 萌芽回春: 155777
- 化身·生命之树: 33891
- 清晰预兆: 16870
- 丰饶: 207640
- 共生关系: 474750

Debuff ID 参考:
- 割裂: 1079
- 斜掠: 155722
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("DRUID", 4, {
    -- 爆发技能
    { id = 391528, name = "万灵", default = "burst" },
    { id = 740, name = "宁静", default = "burst" },
    { id = 102342, name = "铁木树皮", default = "burst" },

    -- 普通技能
    { id = 774, name = "回春术", default = "normal" },
    { id = 8936, name = "愈合", default = "normal" },
    { id = 18562, name = "迅捷治愈", default = "normal" },
    { id = 33763, name = "生命绽放", default = "normal" },
    { id = 132158, name = "自然迅捷", default = "normal" },
    { id = 474750, name = "共生关系", default = "normal" },
    { id = 88423, name = "驱散", default = "normal" },
    { id = 22812, name = "树皮", default = "normal" },
    { id = 1079, name = "割裂", default = "normal" },
    { id = 1822, name = "斜掠", default = "normal" },
    { id = 48438, name = "野性成长", default = "normal" },
    { id = 20484, name = "战复", default = "normal" },
    { id = 768, name = "变形", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    -- 治疗
    Rejuvenation = 774,             -- 回春术
    Regrowth = 8936,                -- 愈合
    Swiftmend = 18562,              -- 迅捷治愈
    Lifebloom = 33763,              -- 生命绽放
    NaturesSwiftness = 132158,      -- 自然迅捷
    Tranquility = 740,              -- 宁静
    ConvokeTheSpirits = 391528,     -- 万灵
    Symbiosis = 474750,             -- 共生关系
    NatureCure = 88423,             -- 驱散
    Ironbark = 102342,              -- 铁木树皮
    Barkskin = 22812,               -- 树皮
    Rebirth = 20484,                -- 复生 (战斗复活)
    WildGrowth = 48438,            -- 野性成长

    -- 猫形态
    Rip = 1079,                     -- 割裂
    Rake = 1822,                    -- 斜掠

    -- 形态
    ShapeShift = 768,               -- 变形 (猫/人切换)
    
    -- Buff技能
    MarkOfTheWild = 1126,           -- 野性印记
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    CatForm = 768,                  -- 猫形态
    Rejuvenation = 774,             -- 回春术
    Germination = 155777,           -- 萌芽回春
    GroveGuardians = 207640,        -- 丰饶
    SymbiosisHoT = 474750,         -- 共生关系 (坦克身上的buff)
    ClearCasting = 16870,           -- 清晰预兆
    MarkOfTheWild = 1126,           -- 野性印记
}

--============================================================
-- 4. Debuff ID定义
--============================================================
local DEBUFF = {
    Rip = 1079,                     -- 割裂
    Rake = 155722,                  -- 斜掠
}

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local GetBuffRemain = NCF.GetBuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local GetUnitPower = NCF.GetUnitPower
local GetUnitHealthPct = NCF.GetUnitHealthPct
local GetGroupAverageHealthPct = NCF.GetGroupAverageHealthPct
local GetLowestHealthMember = NCF.GetLowestHealthMember
local GetTankUnit = NCF.GetTankUnit
local GetDispellableUnit = NCF.GetDispellableUnit
local GetEnemyWithoutDebuff = NCF.GetEnemyWithoutDebuff
local GetSpellCharges = NCF.GetSpellCharges

-- 连击点
local function GetComboPoints()
    return GetUnitPower("player", "combopoints")
end

-- 是否处于猫形态
local function IsInCatForm()
    return HasBuff(BUFF.CatForm, "player")
end

-- 检查友方是否有双回春 (回春 + 萌芽)
local function HasDoubleRejuv(unit)
    return HasBuff(BUFF.Rejuvenation, unit) and HasBuff(BUFF.Germination, unit)
end

-- 查找没有双回春的友方 (血量 < threshold, 使用技能射程检查LoS)
local function GetMemberNeedRejuv(threshold)
    local members = NCF.GetGroupMembers()
    for _, unit in ipairs(members) do
        -- 使用技能射程检查 (包含LoS)
        if NCF.IsSpellInRange(SPELL.Rejuvenation, unit) then
            local hp = GetUnitHealthPct(unit)
            if hp < threshold and not HasDoubleRejuv(unit) then
                return unit
            end
        end
    end
    return nil
end

--============================================================
-- 6. 主循环
--============================================================
local function CreateRestorationRotation()

    local function Rotation()
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)

        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)

        local function IsReady(spellID)
            return GetSpellCooldownRemain(spellID) <= gcd
        end

        local avgHp = GetGroupAverageHealthPct(40)
        local lowestUnit, lowestHp = GetLowestHealthMember(40, 100, SPELL.Regrowth)
        local myHp = GetUnitHealthPct("player")
        local tankUnit = GetTankUnit()

        --========================================
        -- 猫形态逻辑
        --========================================
        if IsInCatForm() then

            -- 团队血量 < 93% 或 丰饶层数 <= 5 → 变回人形态
            local groveStacks = NCF.GetBuffStacks(BUFF.GroveGuardians, "player")
            if avgHp < 93 and lowestHp<=95 or groveStacks <= 5 then
                if IsReady(SPELL.ShapeShift) then
                    return "spell", SPELL.ShapeShift
                end
            end

            local cp = GetComboPoints()

            -- 1. 割裂: 连击点 >= 4
            if cp >= 4 and IsReady(SPELL.Rip) then
                -- 优先找5码内没有割裂debuff的敌人
                local noRipTarget = GetEnemyWithoutDebuff(DEBUFF.Rip, 5, true)
                if noRipTarget then
                    return "InstantSpell", SPELL.Rip, noRipTarget
                end
                -- 都有debuff, 对当前目标
                if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
                    return "InstantSpell", SPELL.Rip, "target"
                end
            end

            -- 2. 斜掠: 优先找5码内没有斜掠debuff的敌人
            if IsReady(SPELL.Rake) then
                local noRakeTarget = GetEnemyWithoutDebuff(DEBUFF.Rake, 5, true)
                if noRakeTarget then
                    return "InstantSpell", SPELL.Rake, noRakeTarget
                end
                -- 都有debuff, 对当前目标
                if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
                    return "InstantSpell", SPELL.Rake, "target"
                end
            end

            return nil
        end

        --========================================
        -- 人形态治疗逻辑
        --========================================

        -- 还有猫buff说明正在变形中, 等待
        if HasBuff(BUFF.CatForm, "player") then
            return nil
        end

        -- 团队血量 >= 95% → 变猫输出
        if avgHp >= 95 and lowestHp > 95 and enemyCount > 0 and NCF.GetBuffStacks(BUFF.GroveGuardians, "player") >= 5 then
            if IsReady(SPELL.ShapeShift) and not IsInCatForm() and not ShouldSkipSpell(SPELL.ShapeShift) then
                return "spell", SPELL.ShapeShift
            end
        end

        -- 0. 复生: 有队友死亡时战斗复活 (检查射程)
        if IsReady(SPELL.Rebirth) and not ShouldSkipSpell(SPELL.Rebirth) then
            local members = NCF.GetGroupMembers()
            -- GetGroupMembers 过滤了死人, 需要单独遍历
            if IsInRaid() then
                for i = 1, GetNumGroupMembers() do
                    local unit = "raid" .. i
                    if UnitExists(unit) and UnitIsDead(unit) and UnitIsConnected(unit) then
                        if NCF.IsSpellInRange(SPELL.Rebirth, unit) then
                            return "spell", SPELL.Rebirth, unit
                        end
                    end
                end
            elseif IsInGroup() then
                for i = 1, 4 do
                    local unit = "party" .. i
                    if UnitExists(unit) and UnitIsDead(unit) and UnitIsConnected(unit) then
                        if NCF.IsSpellInRange(SPELL.Rebirth, unit) then
                            return "spell", SPELL.Rebirth, unit
                        end
                    end
                end
            end
        end

        -- 0.1 铁木树皮: 最低血量 < 50%
        if lowestUnit and lowestHp < 50 and NCF.IsSpellInRange(SPELL.Ironbark, lowestUnit) and IsReady(SPELL.Ironbark) and not ShouldSkipSpell(SPELL.Ironbark) then
            return "spell", SPELL.Ironbark, lowestUnit
        end

        -- 0.1 树皮: 自己血量 < 50%
        if myHp < 50 and IsReady(SPELL.Barkskin) and not ShouldSkipSpell(SPELL.Barkskin) then
            return "spell", SPELL.Barkskin
        end

        -- 0.2 驱散: 友方有可驱散debuff (诅咒/毒)
        local dispelTarget = GetDispellableUnit({"Curse", "Poison", "Magic"}, 40)
        if dispelTarget and IsReady(SPELL.NatureCure) and not ShouldSkipSpell(SPELL.dispelTarget) then
            return "spell", SPELL.NatureCure, dispelTarget
        end

        -- 战前准备: 野性印记
        if not HasBuff(BUFF.MarkOfTheWild, "player") and IsReady(SPELL.MarkOfTheWild) then
            return "spell", SPELL.MarkOfTheWild
        end

		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end

        -- 1. 共生关系: 坦克没有共生关系buff时释放
        if tankUnit and NCF.IsSpellInRange(SPELL.Symbiosis, tankUnit) and not HasBuff(BUFF.SymbiosisHoT, tankUnit) and IsReady(SPELL.Symbiosis) and not ShouldSkipSpell(SPELL.Symbiosis) then
            return "spell", SPELL.Symbiosis, tankUnit
        end

        -- 2. 生命绽放: 对坦克
        if tankUnit and NCF.IsSpellInRange(SPELL.Lifebloom, tankUnit) and IsReady(SPELL.Lifebloom) and not HasBuff(33763, tankUnit) then
            return "spell", SPELL.Lifebloom, tankUnit
        end

        -- 3. 万灵: 团队血量 <= 65% 或 最低血量 <= 20%
        if (avgHp <= 65 or lowestHp <= 20) and IsReady(SPELL.ConvokeTheSpirits) and not ShouldSkipSpell(SPELL.ConvokeTheSpirits) then
            return "spell", SPELL.ConvokeTheSpirits
        end

        -- 3.5 野性成长: 团队血量 < 80%
        if avgHp < 80 and IsReady(SPELL.WildGrowth) then
            return "spell", SPELL.WildGrowth
        end

        -- 4. 宁静: 团队血量 <= 50%
        if avgHp <= 50 and IsReady(SPELL.Tranquility) and not ShouldSkipSpell(SPELL.Tranquility) then
            return "spell", SPELL.Tranquility
        end

        -- 5. 自然迅捷: 最低血量 < 60%
        if lowestUnit and lowestHp < 60 and IsReady(SPELL.NaturesSwiftness) and not HasBuff(SPELL.NaturesSwiftness, "player") then
            return "spell", SPELL.NaturesSwiftness
        end

        -- 6. 迅捷治愈: 最低3人平均血量 < 60% 且丰饶 >= 1
        local low3Avg = GetGroupAverageHealthPct(40, 3)
        if low3Avg < 60 and lowestUnit and NCF.GetBuffStacks(BUFF.GroveGuardians, "player") >= 1 and IsReady(SPELL.Swiftmend) then
            return "spell", SPELL.Swiftmend, lowestUnit
        end

        -- 7. 愈合: 最低血量 < 70%
        if lowestUnit and lowestHp < 70 and IsReady(SPELL.Regrowth) then
            return "spell", SPELL.Regrowth, lowestUnit
        end

        -- 8. 回春: 对血量 < 100% 且没有双回春的人
        if IsReady(SPELL.Rejuvenation) then
            local rejuvTarget = GetMemberNeedRejuv(100)
            if rejuvTarget then
                return "spell", SPELL.Rejuvenation, rejuvTarget
            end
        end

        -- 9. 回春: 丰饶buff层数 <= 5, 对任意没有双回春的人
        --    优先级: 两个回春都没有 > 有一个回春 (坦克除外)
        local groveStacks = NCF.GetBuffStacks(BUFF.GroveGuardians, "player")
        if groveStacks <= 8 and IsReady(SPELL.Rejuvenation) then
            local members = NCF.GetGroupMembers()
            local oneRejuvTarget = nil
            
            for _, unit in ipairs(members) do
                -- 使用技能射程检查 (包含LoS)
                if NCF.IsSpellInRange(SPELL.Rejuvenation, unit) and not HasDoubleRejuv(unit) then
                    local hasAny = HasBuff(BUFF.Rejuvenation, unit) or HasBuff(BUFF.Germination, unit)
                    if not hasAny then
                        -- 两个都没有, 最高优先级, 直接放
                        return "spell", SPELL.Rejuvenation, unit
                    end
                    -- 有一个, 记下来但跳过坦克
                    if not oneRejuvTarget and unit ~= tankUnit then
                        oneRejuvTarget = unit
                    end
                end
            end
            
            -- 没有0 HoT的人, 给有1个的非坦克
            if oneRejuvTarget then
                return "spell", SPELL.Rejuvenation, oneRejuvTarget
            end
        end

        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateRestorationRotation()