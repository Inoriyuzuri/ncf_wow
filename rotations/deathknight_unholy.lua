--============================================================
-- 邪恶死亡骑士循环 (Unholy Death Knight APL)
-- 12.0 版本
--============================================================

--[[
=== 优先级循环 ===

--- 变量定义 ---
spending_rp = (亡者军团CD>5 且 符能溢出<20) 或 (亡者军团CD<=5 且 符能溢出<60) 或 没有亡者军团天赋 或 符文<2 或 (有禁忌知识buff 且 符文<4)

--- 战前 ---
0. 打断 - 心灵冰冻 (47528)
1. 复活死者 (46584): 没有宠物

--- CD技能 ---
2. 爆发 (77575): 没有恶性瘟疫debuff 且 没有瘟疫buff
3. 亡者军团 (42650): 有天赋
4. 黑暗突变 (1233448): CD好了就用
5. 灵魂收割者 (343294): (没有瘟疫天赋 或 没有悲伤侵染天赋) 且 腐化充能>=1 或 目标血量<=35%
6. 腐化 (1247378): 有禁忌知识buff 且 符能溢出>10 或 充能满

--- AOE (敌人>=4) ---
7. 死亡凋零 (43265): 没有死亡凋零buff 且 有亵渎天赋
8. 脓疮打击 (85948): 有脓疮毒镰天赋 且 ((有脓疮毒镰buff 且 (buff剩余<=3 或 debuff剩余<3)) 或 (没有脓疮毒镰buff 且 debuff剩余<3))
9. 天灾打击 (55090): 小鬼准备层数=8 (满)
10. 扩散 (207317): (敌人>=4 且 没有禁忌知识buff 或 敌人>=7 且 有禁忌知识buff) 且 (有末日突降触发 或 spending_rp)
11. 凋零缠绕 (47541): 敌人<7 且 有禁忌知识buff 且 (有末日突降触发 或 spending_rp)
12. 脓疮打击: 小鬼准备层数=0 或 (有脓疮毒镰buff 且 (buff剩余<=3 或 debuff剩余<3))
13. 天灾打击: 小鬼准备层数>=1
14. 腐化: 没有灵魂收割者天赋
15. 扩散: spending_rp 且 (敌人>=4 且 没有禁忌知识buff 或 敌人>=7 且 有禁忌知识buff)
16. 凋零缠绕: spending_rp

--- 单目标 (敌人<4) ---
17. 脓疮打击: 有脓疮毒镰天赋 且 ((有脓疮毒镰buff 且 (buff剩余<=3 或 debuff剩余<3)) 或 (没有脓疮毒镰buff 且 debuff剩余<3))
18. 天灾打击: 小鬼准备层数=8 (满)
19. 凋零缠绕: 有末日突降触发 或 spending_rp
20. 脓疮打击: 小鬼准备层数=0
21. 天灾打击: 小鬼准备层数>=1
22. 腐化: 没有灵魂收割者天赋
23. 凋零缠绕: spending_rp (填充)

=== Buff ID ===
- 小鬼准备: 1254252 (最大8层)
- 脓疮毒镰: 458123
- 末日突降: 1268917
- 禁忌知识: 1242158
- 收割: 1242654
- 瘟疫: 1271975
- 死亡凋零: 188290
- 圣劳恩之赐: 434153

=== Debuff ID ===
- 恶性瘟疫: 191587
- 脓疮毒镰debuff: 1241077

=== 天赋 ID ===
- 亵渎: 1234559
- 禁忌知识: 1242158
- 脓疮毒镰: 455397
- 灵魂收割者: 343294
- 瘟疫: 1271974
- 悲伤侵染: 434143
- 枯萎爆发: 1254552
- 亡者军团: 42650
- 召唤石像鬼: 1242147
- 圣劳恩之赐: 434152
- 收割: 377514
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("DEATHKNIGHT", 3, {
    -- 爆发技能
    { id = 42650, name = "亡者军团", default = "burst" },
    { id = 1233448, name = "黑暗突变", default = "burst" },
    { id = 343294, name = "灵魂收割者", default = "burst" },
    
    -- 普通技能
    { id = 47528, name = "心灵冰冻", default = "normal" },
    { id = 46584, name = "亡者复生", default = "normal" },
    { id = 77575, name = "爆发", default = "normal" },
    { id = 1247378, name = "腐化", default = "normal" },
    { id = 43265, name = "死亡凋零", default = "normal" },
    { id = 85948, name = "脓疮打击", default = "normal" },
    { id = 55090, name = "天灾打击", default = "normal" },
    { id = 207317, name = "扩散", default = "normal" },
    { id = 47541, name = "凋零缠绕", default = "normal" },
    { id = 61999, name = "复活盟友", default = "normal" },
    { id = 49998, name = "死亡打击", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    MindFreeze = 47528,           -- 心灵冰冻 (打断)
    RaiseDead = 46584,            -- 亡者复生
    RaiseAlly = 61999,            -- 复活盟友 (战复, 30符能)
    DeathStrike = 49998,          -- 死亡打击 (35符能)
    Outbreak = 77575,             -- 爆发
    ArmyOfTheDead = 42650,        -- 亡者军团
    DarkTransformation = 1233448, -- 黑暗突变
    SoulReaper = 343294,          -- 灵魂收割者
    Putrefy = 1247378,            -- 腐化
    DeathAndDecay = 43265,        -- 死亡凋零
    FesteringStrike = 85948,      -- 脓疮打击
    ScourgeStrike = 55090,        -- 天灾打击
    Epidemic = 207317,            -- 扩散
    DeathCoil = 47541,            -- 凋零缠绕
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    LesserGhoul = 1254252,        -- 小鬼准备 (最大8层)
    FesteringScythe = 458123,     -- 脓疮毒镰
    SuddenDoom = 81340,         -- 末日突降
    ForbiddenKnowledge = 1242158, -- 禁忌知识
    Reaping = 1242654,            -- 收割
    Pestilence = 1271975,         -- 瘟疫
    DeathAndDecay = 188290,       -- 死亡凋零
    GiftOfTheSanlayn = 434153,    -- 圣劳恩之赐
}

--============================================================
-- 4. Debuff ID定义
--============================================================
local DEBUFF = {
    VirulentPlague = 191587,      -- 恶性瘟疫
    FesteringScythe = 1241077,    -- 脓疮毒镰debuff
}

--============================================================
-- 5. 天赋ID定义
--============================================================
local TALENT = {
    Desecrate = 1234559,          -- 亵渎
    ForbiddenKnowledge = 1242158, -- 禁忌知识
    FesteringScythe = 455397,     -- 脓疮毒镰
    SoulReaper = 343294,          -- 灵魂收割者
    Pestilence = 1271974,         -- 瘟疫
    InflictionOfSorrow = 434143,  -- 悲伤侵染
    Blightburst = 1254552,        -- 枯萎爆发
    ArmyOfTheDead = 42650,        -- 亡者军团
    SummonGargoyle = 1242147,     -- 召唤石像鬼
    GiftOfTheSanlayn = 434152,    -- 圣劳恩之赐
    Reaping = 377514,             -- 收割
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetBuffRemain = NCF.GetBuffRemain
local GetDebuffRemain = NCF.GetDebuffRemain
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower
local GetUnitPowerMax = NCF.GetUnitPowerMax
local GetTargetHealthPct = NCF.GetTargetHealthPct
local GetPetExists = NCF.GetPetExists
local IsSpellReady = NCF.IsSpellReady
local GetInterruptTarget = NCF.GetInterruptTarget
local GetCombatTime = NCF.GetCombatTime

-- 获取可用符文数量
local function GetReadyRunes()
    return GetUnitPower("player", "runes")
end

-- 查找灵魂收割目标 (5码范围内血量<=35%的敌人)
local function GetSoulReaperTarget()
    -- 先检查当前目标
    if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
        local targetHp = NCF.GetUnitHealthPct("target")
        if targetHp <= 35 then
            return "target"
        end
    end
    
    -- 搜索周围5码内的敌人
    local validEnemies = {}
    local objects = ObjectManager("Unit" or 5) or {}
    
    for i = 1, #objects do
        local obj = objects[i]
        if ObjectType(obj) == 5 and not UnitIsDead(obj) and UnitCanAttack("player", obj) then
            if UnitAffectingCombat(obj) or NCF.IsTrainingDummy(obj) then
                local dist = Distance("player", obj) - CombatReach("player") - CombatReach(obj)
                if dist <= 5 then
                    local hp = NCF.GetUnitHealthPct(obj)
                    if hp <= 35 then
                        table.insert(validEnemies, {unit = obj, hp = hp})
                    end
                end
            end
        end
    end
    
    -- 按血量从低到高排序，优先收割血量最低的
    if #validEnemies > 0 then
        table.sort(validEnemies, function(a, b) return a.hp < b.hp end)
        return validEnemies[1].unit
    end
    
    return nil
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateUnholyRotation()

    local function Rotation()
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)
        
        local runicPower = GetUnitPower("player", "runicpower")
        local runicPowerMax = GetUnitPowerMax("player", "runicpower")
        local runicPowerDeficit = runicPowerMax - runicPower
        local runes = GetReadyRunes()
        local targetHealthPct = GetTargetHealthPct()
        
        -- Buff状态
        local lesserGhoulStacks = GetBuffStacks(BUFF.LesserGhoul)
        local hasFesteringScytheBuff = HasBuff(BUFF.FesteringScythe)
        local festeringScytheBuffRemain = GetBuffRemain(BUFF.FesteringScythe)
        local hasSuddenDoom = HasBuff(BUFF.SuddenDoom)
        local hasForbiddenKnowledge = HasBuff(BUFF.ForbiddenKnowledge)
        local hasPestilence = HasBuff(BUFF.Pestilence)
        local hasDeathAndDecay = HasBuff(BUFF.DeathAndDecay)
        local hasReaping = HasBuff(BUFF.Reaping)
		
        -- Debuff状态
        local hasVirulentPlague = HasDebuff(DEBUFF.VirulentPlague, "target")
        local festeringScytheDebuffRemain = GetDebuffRemain(DEBUFF.FesteringScythe, "target")
        
        -- 资源消耗检查
        local canFesteringStrike = hasFesteringScytheBuff or runes >= 2           -- 2符文, 有脓疮毒镰buff免费
        local canScourgeStrike = runes >= 1                                        -- 1符文
        local canOutbreak = hasPestilence or runes >= 1                            -- 1符文, 有瘟疫buff免费
        local canDeathCoil = hasSuddenDoom and runicPower >= 15 or runicPower >= 30  -- 30符能, 有末日突降15符能
        local canEpidemic = canDeathCoil                                           -- 同凋零缠绕
        local canDeathAndDecay = runes >= 1                                        -- 1符文
        local canArmyOfTheDead = runes >= 1                                        -- 1符文
        
        -- 天赋检查
        local hasDesecrate = HasTalent(TALENT.Desecrate)
        local hasFesteringScytheTalent = HasTalent(TALENT.FesteringScythe)
        local hasSoulReaper = HasTalent(TALENT.SoulReaper)
        local hasPestilenceTalent = HasTalent(TALENT.Pestilence)
        local hasInflictionOfSorrow = HasTalent(TALENT.InflictionOfSorrow)
        local hasArmyOfTheDead = HasTalent(TALENT.ArmyOfTheDead)
        
        -- CD检查
        local armyCD = GetSpellCooldownRemain(SPELL.ArmyOfTheDead)
        local darkTransformCD = GetSpellCooldownRemain(SPELL.DarkTransformation)
        local putrefyCharges = GetSpellCharges(SPELL.Putrefy)

        
        -- 黑暗突变激活检测: CD > 30秒说明正在使用中
        local isDarkTransformActive = darkTransformCD > 30
        
        -- spending_rp 变量
        local spending_rp = (armyCD > 5 and runicPowerDeficit < 20) 
                         or (armyCD <= 5 and runicPowerDeficit < 60) 
                         or (not hasArmyOfTheDead) 
                         or (runes < 2) 
                         or (hasForbiddenKnowledge and runes < 4)
        
        -- 爆发阶段
        if NCF.burstModeEnabled and isDarkTransformActive then
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
        -- 战前/始终
        --============================================================
        
        -- 0. 打断
        if IsSpellReady(SPELL.MindFreeze) and not ShouldSkipSpell(SPELL.MindFreeze) then
            local interruptTarget = GetInterruptTarget(15, false)
            if interruptTarget then
                return "InstantSpell", SPELL.MindFreeze, interruptTarget
            end
        end
        
        
        -- 1. 复活死者: 没有宠物
        if not GetPetExists() and IsSpellReady(SPELL.RaiseDead) and not ShouldSkipSpell(SPELL.RaiseDead) then
            return "spell", SPELL.RaiseDead
        end
        
        -- 战斗检测
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end
        
        -- 0.6 死亡打击: 自身血量<20% (需要35符能)
        local playerHealthPct = NCF.GetUnitHealthPct("player")
        if playerHealthPct < 20 and runicPower >= 35 and IsSpellReady(SPELL.DeathStrike) and not ShouldSkipSpell(SPELL.DeathStrike) then
            return "spell", SPELL.DeathStrike
        end
		
        -- 0.5 战复: 鼠标指向死亡的友方队友 (需要30符能)
        if runicPower >= 30 and UnitExists("mouseover") and UnitIsDead("mouseover") and UnitIsFriend("player", "mouseover") and IsSpellReady(SPELL.RaiseAlly) and not ShouldSkipSpell(SPELL.RaiseAlly) then
            return "spell", SPELL.RaiseAlly, "mouseover"
        end
        --============================================================
        -- CD技能
        --============================================================
        
        -- 2. 爆发: 没有恶性瘟疫debuff 且 没有瘟疫buff (需要1符文或有瘟疫buff免费)
        if canOutbreak and not hasVirulentPlague and not hasPestilence and IsSpellReady(SPELL.Outbreak) and not ShouldSkipSpell(SPELL.Outbreak) then
            return "spell", SPELL.Outbreak
        end
        
        -- 3. 亡者军团: 有天赋 (需要1符文)
        if canArmyOfTheDead and hasArmyOfTheDead and IsSpellReady(SPELL.ArmyOfTheDead) and not ShouldSkipSpell(SPELL.ArmyOfTheDead) then
            return "spell", SPELL.ArmyOfTheDead
        end
        
        -- 4. 黑暗突变: CD好了就用
        if IsSpellReady(SPELL.DarkTransformation) and not ShouldSkipSpell(SPELL.DarkTransformation) then
            return "spell", SPELL.DarkTransformation
        end
        
        -- 5. 灵魂收割者: 只能对<35%血量目标释放, 有Reaping buff时可对任意血量释放
        if hasSoulReaper and IsSpellReady(SPELL.SoulReaper) and not ShouldSkipSpell(SPELL.SoulReaper) then
            local soulReaperCondition = (not hasPestilenceTalent or not hasInflictionOfSorrow) and putrefyCharges >= 1
            
            if hasReaping then
                -- 有Reaping buff, 可以对任意血量目标释放
                if soulReaperCondition then
                    return "spell", SPELL.SoulReaper
                end
            else
                -- 没有Reaping buff, 只能对<35%血量目标释放
                if soulReaperCondition then
                    if targetHealthPct <= 35 then
                        -- 当前目标满足条件
                        return "spell", SPELL.SoulReaper
                    else
                        -- 当前目标血量>35%, 搜索5码内<=35%血量目标
                        local soulReaperTarget = GetSoulReaperTarget()
                        if soulReaperTarget then
                            return "InstantSpell", SPELL.SoulReaper, soulReaperTarget
                        end
                    end
                end
            end
        end
        
        -- 6. 腐化: 有禁忌知识buff 且 符能溢出>10 或 充能满
        local putrefyCondition = (hasForbiddenKnowledge and runicPowerDeficit > 10) or (putrefyCharges >= 2)
        if putrefyCondition and IsSpellReady(SPELL.Putrefy) and not ShouldSkipSpell(SPELL.Putrefy) then
            return "spell", SPELL.Putrefy
        end
        
        --============================================================
        -- AOE (敌人>=2)
        --============================================================
        if enemyCount >= 2 then
            -- 7. 死亡凋零: 没有死亡凋零buff 且 有亵渎天赋 (需要1符文)
            if canDeathAndDecay and hasDesecrate and not hasDeathAndDecay and IsSpellReady(SPELL.DeathAndDecay) and not ShouldSkipSpell(SPELL.DeathAndDecay) then
                return "spell", SPELL.DeathAndDecay
            end
            
            -- 8. 脓疮打击: 脓疮毒镰条件 (需要2符文或有脓疮毒镰buff免费)
            local fsCondition = hasFesteringScytheTalent and (
                (hasFesteringScytheBuff and (festeringScytheBuffRemain <= 3 or festeringScytheDebuffRemain < 3)) or
                (not hasFesteringScytheBuff and festeringScytheDebuffRemain < 3)
            )
            if canFesteringStrike and fsCondition and IsSpellReady(SPELL.FesteringStrike) and not ShouldSkipSpell(SPELL.FesteringStrike) then
                return "spell", SPELL.FesteringStrike
            end
            
            -- 9. 天灾打击: 小鬼准备层数=8 (满) (需要1符文)
            if canScourgeStrike and lesserGhoulStacks >= 8 and IsSpellReady(SPELL.ScourgeStrike) and not ShouldSkipSpell(SPELL.ScourgeStrike) then
                return "spell", SPELL.ScourgeStrike
            end
            
            -- 10. 扩散: (敌人>=4 且 没有禁忌知识buff 或 敌人>=7 且 有禁忌知识buff) 且 (有末日突降触发 或 spending_rp) (需要30符能或末日突降15符能)
            local epidemicCondition = (enemyCount >= 4 and not hasForbiddenKnowledge) or (enemyCount >= 7 and hasForbiddenKnowledge)
            if canEpidemic and epidemicCondition and (hasSuddenDoom or spending_rp) and IsSpellReady(SPELL.Epidemic) and not ShouldSkipSpell(SPELL.Epidemic) then
                return "spell", SPELL.Epidemic
            end
            
            -- 11. 凋零缠绕: 敌人<7 且 有禁忌知识buff 且 (有末日突降触发 或 spending_rp) (需要30符能或末日突降15符能)
            if canDeathCoil and enemyCount < 7 and hasForbiddenKnowledge and (hasSuddenDoom or spending_rp) and IsSpellReady(SPELL.DeathCoil) and not ShouldSkipSpell(SPELL.DeathCoil) then
                return "spell", SPELL.DeathCoil
            end
            
            -- 12. 脓疮打击: 小鬼准备层数=0 或 脓疮毒镰条件 (需要2符文或有脓疮毒镰buff免费)
            local fsCondition2 = lesserGhoulStacks == 0 or (hasFesteringScytheBuff and (festeringScytheBuffRemain <= 3 or festeringScytheDebuffRemain < 3))
            if canFesteringStrike and fsCondition2 and IsSpellReady(SPELL.FesteringStrike) and not ShouldSkipSpell(SPELL.FesteringStrike) then
                return "spell", SPELL.FesteringStrike
            end
            
            -- 13. 天灾打击: 小鬼准备层数>=1 (需要1符文)
            if canScourgeStrike and lesserGhoulStacks >= 1 and IsSpellReady(SPELL.ScourgeStrike) and not ShouldSkipSpell(SPELL.ScourgeStrike) then
                return "spell", SPELL.ScourgeStrike
            end
            
            -- 14. 腐化: 没有灵魂收割者天赋
            if not hasSoulReaper and IsSpellReady(SPELL.Putrefy) and not ShouldSkipSpell(SPELL.Putrefy) then
                return "spell", SPELL.Putrefy
            end
            
            -- 15. 扩散: spending_rp (需要30符能或末日突降15符能)
            if canEpidemic and spending_rp and epidemicCondition and IsSpellReady(SPELL.Epidemic) and not ShouldSkipSpell(SPELL.Epidemic) then
                return "spell", SPELL.Epidemic
            end
            
            -- 16. 凋零缠绕: spending_rp (需要30符能或末日突降15符能)
            if canDeathCoil and spending_rp and IsSpellReady(SPELL.DeathCoil) and not ShouldSkipSpell(SPELL.DeathCoil) then
                return "spell", SPELL.DeathCoil
            end
            
            return nil  -- AOE分支结束
        end
        
        --============================================================
        -- 单目标 (敌人<4)
        --============================================================
        
        -- 17. 脓疮打击: 脓疮毒镰条件 (需要2符文或有脓疮毒镰buff免费)
        local fsCondition = hasFesteringScytheTalent and (
            (hasFesteringScytheBuff and (festeringScytheBuffRemain <= 3 or festeringScytheDebuffRemain < 3)) or
            (not hasFesteringScytheBuff and festeringScytheDebuffRemain < 3)
        )
        if canFesteringStrike and fsCondition and IsSpellReady(SPELL.FesteringStrike) and not ShouldSkipSpell(SPELL.FesteringStrike) then
            return "spell", SPELL.FesteringStrike
        end
        
        -- 18. 天灾打击: 小鬼准备层数=8 (满) (需要1符文)
        if canScourgeStrike and lesserGhoulStacks >= 8 and IsSpellReady(SPELL.ScourgeStrike) and not ShouldSkipSpell(SPELL.ScourgeStrike) then
            return "spell", SPELL.ScourgeStrike
        end
        
        -- 19. 凋零缠绕: 有末日突降触发 或 spending_rp (需要30符能或末日突降15符能)
        if canDeathCoil and (hasSuddenDoom or spending_rp) and IsSpellReady(SPELL.DeathCoil) and not ShouldSkipSpell(SPELL.DeathCoil) then
            return "spell", SPELL.DeathCoil
        end
        
        -- 20. 脓疮打击: 小鬼准备层数=0 (需要2符文或有脓疮毒镰buff免费)
        if canFesteringStrike and lesserGhoulStacks == 0 and IsSpellReady(SPELL.FesteringStrike) and not ShouldSkipSpell(SPELL.FesteringStrike) then
            return "spell", SPELL.FesteringStrike
        end
        
        -- 21. 天灾打击: 小鬼准备层数>=1 (需要1符文)
        if canScourgeStrike and lesserGhoulStacks >= 1 and IsSpellReady(SPELL.ScourgeStrike) and not ShouldSkipSpell(SPELL.ScourgeStrike) then
            return "spell", SPELL.ScourgeStrike
        end
        
        -- 22. 腐化: 没有灵魂收割者天赋
        if not hasSoulReaper and IsSpellReady(SPELL.Putrefy) and not ShouldSkipSpell(SPELL.Putrefy) then
            return "spell", SPELL.Putrefy
        end
        
        -- 23. 凋零缠绕: spending_rp (填充) (需要30符能或末日突降15符能)
        if canDeathCoil and spending_rp and IsSpellReady(SPELL.DeathCoil) and not ShouldSkipSpell(SPELL.DeathCoil) then
            return "spell", SPELL.DeathCoil
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateUnholyRotation()