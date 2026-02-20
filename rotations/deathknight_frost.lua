--============================================================
-- 冰霜死亡骑士循环 (Frost Death Knight APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--
-- 英雄树分支:
-- - 天启骑士 (444005): 已实现
-- - 死神 (439843): 已实现
--============================================================

--[[
===================================
变量定义 (variables)
===================================
- sending_cds: 可放CD = true (简化处理)
- cooldown_check: CD检查 = (有冰霜之柱天赋 且 冰霜之柱激活) 或 无冰霜之柱天赋
- rune_pooling: 符文囤积 = 死神英雄树 且 收割者印记CD<6秒 且 符文<3 且 可放CD
- rp_pooling: 符能囤积 = 有辛达苟萨之息天赋 且 辛达苟萨CD<4*GCD 且 符能不足
- frostscythe_prio: 冰霜镰刀优先级 = 3+(有恐惧君临天赋 且 非(有劈斩天赋 且 凛冬凋零激活))
- breath_check: 辛达苟萨检查 = 有辛达苟萨天赋 且 (CD>20 或 (就绪 且 符能>=60-20*死神))

===================================
通用优先级
===================================
0.   打断 - 心灵冰冻 (47528): 15码, 需面朝
0.1  复活亡者 (46585): 宠物不存在
--- 以下需要战斗中 ---

===================================
冷却技能 (cooldowns)
===================================
1. 凛冬凋零: 可放CD 且 (敌人>1 或 有聚集风暴天赋) 或 (聚集风暴10层 且 凛冬凋零剩余<GCD)
2. 冰龙吐息(天启骑士): 天启骑士 且 有末日降临天赋 且 冰霜之柱CD<GCD 且 (无辛达苟萨天赋 或 符能>=60)
3. 冰霜之柱(无辛达苟萨): 无辛达苟萨天赋 且 可放CD 且 (非死神 或 符文>=2)
4. 冰霜之柱(有辛达苟萨): 有辛达苟萨天赋 且 辛达苟萨检查 且 (非死神 或 符文>=2)
5. 辛达苟萨之息: 无辛达苟萨buff 且 冰霜之柱激活
6. 收割者印记: 目标无收割者印记debuff 且 (冰霜之柱激活 或 冰霜之柱CD>5秒)
7. 冰龙吐息(非天启骑士): 冰霜之柱激活 且 冰龙吐息条件
8. 符文武器强化: (符文<2 或 无杀戮机器) 且 符能<35+(寒冰猛袭层数*5)

===================================
AOE循环 (敌人>=3)
===================================
1. 冰霜镰刀: (杀戮机器=2 或 (有杀戮机器 且 符文>=3)) 且 敌人>=冰霜镰刀优先级
2. 湮灭: 杀戮机器=2 或 (有杀戮机器 且 符文>=3)
3. 凛冽寒风: (有白霜 且 有霜缚意志天赋) 或 目标无冰霜热病
4. 霜噬: 有天赋
5. 冰霜打击: 锐冰=5层 且 有霜噬buff
6. 冰霜打击: 锐冰=5层 且 有碎裂之刃天赋 且 敌人<5 且 不囤符能 且 无霜噬天赋
7. 冰霜镰刀: 有杀戮机器 且 不囤符文 且 敌人>=冰霜镰刀优先级
8. 湮灭: 有杀戮机器 且 不囤符文
9. 凛冽寒风: 有白霜
10. 冰河突进: 不囤符能
11. 冰霜镰刀: 不囤符文 且 非(有湮灭天赋 且 冰霜之柱激活) 且 敌人>=冰霜镰刀优先级
12. 湮灭: 不囤符文 且 非(有湮灭天赋 且 冰霜之柱激活)
13. 凛冽寒风: 无杀戮机器 且 有湮灭天赋 且 冰霜之柱激活

===================================
单体循环 (敌人<3)
===================================
1. 湮灭: 杀戮机器=2 或 (有杀戮机器 且 符文>=3)
2. 凛冽寒风: 有白霜 且 有霜缚意志天赋
3. 霜噬: 有天赋
4. 冰霜打击: 锐冰=5层 且 有碎裂之刃天赋 且 不囤符能
5. 凛冽寒风: 有白霜
6. 冰霜打击: 无碎裂之刃天赋 且 不囤符能 且 符能缺口<30
7. 湮灭: 有杀戮机器 且 不囤符文
8. 冰霜打击: 不囤符能
9. 湮灭: 不囤符文 且 非(有湮灭天赋 且 冰霜之柱激活)
10. 凛冽寒风: 无杀戮机器 且 有湮灭天赋 且 冰霜之柱激活

===================================
Buff/Debuff ID 参考
===================================
Buff:
- 杀戮机器: 51124
- 白霜: 59052
- 冰霜之柱: 51271
- 辛达苟萨之息: 1249658
- 凛冬凋零: 1233152
- 聚集风暴: 211802
- 邪恶力量: 53365
- 碎骨者冰霜: 377101
- 寒冰猛袭: 1230273
- 霜噬: 1229310

Debuff:
- 冰霜热病: 55095
- 锐冰: 51714
- 收割者印记: 434765
- 寒冰锁链减速: 444834

天赋:
- 冰霜之柱: 51271
- 辛达苟萨之息: 1249658
- 湮灭: 49020
- 聚集风暴: 194912
- 碎裂之刃: 207057
- 霜缚意志: 1238680
- 霜噬: 455993
- 末日降临: 444040
- 恐惧君临: 1265949
- 劈斩: 316916
- 碎骨者: 377098
- 寒冰猛袭: 1230272
- 连杀: 1230153
- 凛冬凋零被动: 377226

英雄树:
- 天启骑士: 444005
- 死神: 439843
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("DEATHKNIGHT", 2, {
    -- 冷却技能
    { id = 51271, name = "冰霜之柱", default = "burst" },
    { id = 1249658, name = "辛达苟萨之息", default = "burst" },
    { id = 279302, name = "冰龙吐息", default = "burst" },
    { id = 439843, name = "收割者印记", default = "burst" },
    { id = 47568, name = "符文武器强化", default = "normal" },
    { id = 196770, name = "凛冬凋零", default = "normal" },
    
    -- 普通技能
    { id = 49020, name = "湮灭", default = "normal" },
    { id = 49143, name = "冰霜打击", default = "normal" },
    { id = 49184, name = "凛冽寒风", default = "normal" },
    { id = 207230, name = "冰霜镰刀", default = "normal" },
    { id = 194913, name = "冰河突进", default = "normal" },
    { id = 1228433, name = "霜噬", default = "normal" },
    { id = 46585, name = "复活亡者", default = "normal" },
    { id = 47528, name = "心灵冰冻", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Obliterate = 49020,           -- 湮灭
    FrostStrike = 49143,          -- 冰霜打击
    HowlingBlast = 49184,         -- 凛冽寒风
    Frostscythe = 207230,         -- 冰霜镰刀
    GlacialAdvance = 194913,      -- 冰河突进
    Frostbane = 1228433,          -- 霜噬
    RemorselessWinter = 196770,   -- 凛冬凋零
    PillarOfFrost = 51271,        -- 冰霜之柱
    BreathOfSindragosa = 1249658, -- 辛达苟萨之息
    FrostwyrmsFury = 279302,      -- 冰龙吐息
    ReapersMark = 439843,         -- 收割者印记
    RaiseDead = 46585,            -- 复活亡者
    EmpowerRuneWeapon = 47568,    -- 符文武器强化
    MindFreeze = 47528,           -- 心灵冰冻
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    PillarOfFrost = 51271,        -- 冰霜之柱
    BreathOfSindragosa = 1249658, -- 辛达苟萨之息
    Obliteration = 49020,         -- 湮灭
    GatheringStorm = 194912,      -- 聚集风暴
    ShatteringBlade = 207057,     -- 碎裂之刃
    FrostboundWill = 1238680,     -- 霜缚意志
    Frostbane = 455993,           -- 霜噬
    ApocalypseNow = 444040,       -- 末日降临
    LetTerrorReign = 1265949,     -- 恐惧君临
    CleavingStrikes = 316916,     -- 劈斩
    Bonegrinder = 377098,         -- 碎骨者
    IcyOnslaught = 1230272,       -- 寒冰猛袭
    KillingStreak = 1230153,      -- 连杀
    RemorselessWinterPassive = 377226, -- 凛冬凋零被动
    -- 英雄树
    RiderOfTheApocalypse = 444005, -- 天启骑士
    Deathbringer = 439843,         -- 死神
}

--============================================================
-- 4. Buff ID定义
--============================================================
local BUFF = {
    KillingMachine = 51124,       -- 杀戮机器
    Rime = 59052,                 -- 白霜
    PillarOfFrost = 51271,        -- 冰霜之柱
    BreathOfSindragosa = 1249658, -- 辛达苟萨之息
    RemorselessWinter = 1233152,  -- 凛冬凋零
    GatheringStorm = 211802,      -- 聚集风暴
    UnholyStrength = 53365,       -- 邪恶力量
    BonegrinderFrost = 377101,    -- 碎骨者冰霜
    IcyOnslaught = 1230273,       -- 寒冰猛袭
    Frostbane = 1229310,          -- 霜噬
}

--============================================================
-- 5. Debuff ID定义
--============================================================
local DEBUFF = {
    FrostFever = 55095,           -- 冰霜热病
    Razorice = 51714,             -- 锐冰
    ReapersMark = 434765,         -- 收割者印记
    ChainsOfIceSlow = 444834,     -- 寒冰锁链减速
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffRemain = NCF.GetBuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffStacks = NCF.GetDebuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetPetExists = NCF.GetPetExists
local GetUnitPower = NCF.GetUnitPower
local GetUnitPowerMax = NCF.GetUnitPowerMax

--============================================================
-- 7. 主循环
--============================================================
local function CreateFrostRotation()

    local function Rotation()
        -- 刷新GCD最大值
        NCF.RefreshGCD()
        local gcd_max = NCF.gcd_max or 0.75
        
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 资源
        local runes = GetUnitPower("player", "runes")
        local runicPower = GetUnitPower("player", "runicpower")
        local runicPowerDeficit = (GetUnitPowerMax("player", "runicpower") or 100) - runicPower
        
        -- Buff状态
        local kmStacks = GetBuffStacks(BUFF.KillingMachine, "player")
        local hasKM = kmStacks > 0
        local hasRime = HasBuff(BUFF.Rime, "player")
        local hasPillar = HasBuff(BUFF.PillarOfFrost, "player")
        local hasBreath = HasBuff(BUFF.BreathOfSindragosa, "player")
        local hasRemorseless = HasBuff(BUFF.RemorselessWinter, "player")
        local remorselessRemain = GetBuffRemain(BUFF.RemorselessWinter, "player")
        local gatheringStacks = GetBuffStacks(BUFF.GatheringStorm, "player")
        local icyOnslaughtStacks = GetBuffStacks(BUFF.IcyOnslaught, "player")
        local hasFrostbaneBuff = HasBuff(BUFF.Frostbane, "player")
        
        -- Debuff状态
        local hasFrostFever = HasDebuff(DEBUFF.FrostFever, "target")
        local razoriceStacks = GetDebuffStacks(DEBUFF.Razorice, "target")
        local hasReapersMark = HasDebuff(DEBUFF.ReapersMark, "target")
        
        -- CD
        local pillarCD = GetSpellCooldownRemain(SPELL.PillarOfFrost)
        local breathCD = GetSpellCooldownRemain(SPELL.BreathOfSindragosa)
        local reaperCD = GetSpellCooldownRemain(SPELL.ReapersMark)
        
        -- 英雄树判断
        local isRider = HasTalent(TALENT.RiderOfTheApocalypse)
        local isDeathbringer = HasTalent(TALENT.Deathbringer)
        
        -- 变量计算
        local sendingCDs = true  -- 简化处理
        local cooldownCheck = (HasTalent(TALENT.PillarOfFrost) and hasPillar) or not HasTalent(TALENT.PillarOfFrost)
        local runePooling = isDeathbringer and reaperCD < 6 and runes < 3 and sendingCDs
        local rpPooling = HasTalent(TALENT.BreathOfSindragosa) and breathCD < 4 * gcd_max and runicPower < (60 + (35 + 5 * icyOnslaughtStacks) - (10 * runes)) and sendingCDs
        local frostscythePrio = 3 + ((HasTalent(TALENT.LetTerrorReign) and not (HasTalent(TALENT.CleavingStrikes) and hasRemorseless)) and 1 or 0)
        local breathCheck = HasTalent(TALENT.BreathOfSindragosa) and (breathCD > 20 or (IsReady(SPELL.BreathOfSindragosa) and runicPower >= (60 - (isDeathbringer and 20 or 0))))
        
        -- 冰龙吐息条件
        local fwfBuffs = (GetBuffRemain(BUFF.PillarOfFrost, "player") < gcd_max or 
                        (HasBuff(BUFF.UnholyStrength, "player") and GetBuffRemain(BUFF.UnholyStrength, "player") < gcd_max) or
                        (HasTalent(TALENT.Bonegrinder) and HasBuff(BUFF.BonegrinderFrost, "player") and GetBuffRemain(BUFF.BonegrinderFrost, "player") < gcd_max)) and
                        (enemyCount > 1 or razoriceStacks == 5 or HasTalent(TALENT.ShatteringBlade))
        
        -- 0. 打断: 心灵冰冻 15码 需面朝
        if IsReady(SPELL.MindFreeze) and not ShouldSkipSpell(SPELL.MindFreeze) then
            local interruptTarget = NCF.GetInterruptTarget(15, true)
            if interruptTarget then
                return "spell", SPELL.MindFreeze, interruptTarget
            end
        end
        
        -- 0.1 鼠标指向战复: 复苏 (30符能)
        if UnitExists("mouseover") and UnitIsDead("mouseover") and UnitIsFriend("player", "mouseover") and runicPower >= 30 and IsReady(61999) and not ShouldSkipSpell(61999) then
            return "spell", 61999, "mouseover"
        end
        
        -- 0.2 灵界打击: 血量<15% 且 符能>=35
        local playerHP = NCF.GetUnitHealthPct("player")
        if playerHP < 15 and runicPower >= 35 and IsReady(49998) and not ShouldSkipSpell(49998) then
            return "spell", 49998
        end
        
        -- 0.3 冰封之韧: 血量<35%
        if playerHP < 35 and IsReady(48792) and not ShouldSkipSpell(48792) then
            return "spell", 48792
        end
        
        -- 0.4 复活亡者: 宠物不存在
        if not GetPetExists() and IsReady(SPELL.RaiseDead) and not ShouldSkipSpell(SPELL.RaiseDead) then
            return "spell", SPELL.RaiseDead
        end
        
        -- 以下需要战斗中才执行
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return 'spell', 61304
        end
        
        -- 冰柱buff期间使用药剂/饰品/种族技能
        if NCF.burstModeEnabled and hasPillar then
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
        -- 冷却技能 (cooldowns)
        --==========================================================
        
        -- 1. 凛冬凋零: (可放CD 且 (敌人>1 或 有聚集风暴天赋)) 或 (聚集风暴10层 且 凛冬凋零剩余<GCD)
        if not HasTalent(TALENT.RemorselessWinterPassive) then
            local remorselessCondition = (sendingCDs and (enemyCount > 1 or HasTalent(TALENT.GatheringStorm))) or (gatheringStacks == 10 and remorselessRemain < gcd_max)
            if remorselessCondition and IsReady(SPELL.RemorselessWinter) and not ShouldSkipSpell(SPELL.RemorselessWinter) then
                return "spell", SPELL.RemorselessWinter
            end
        end
        
        -- 2. 冰龙吐息(天启骑士): 天启骑士 且 有末日降临天赋 且 冰霜之柱CD<GCD 且 (无辛达苟萨天赋 或 符能>=60)
        if isRider and HasTalent(TALENT.ApocalypseNow) and sendingCDs and pillarCD < gcd_max then
            local breathCondition = not HasTalent(TALENT.BreathOfSindragosa) or runicPower >= 60
            if breathCondition and NCF.MeetsSpellTTD(SPELL.FrostwyrmsFury) and IsReady(SPELL.FrostwyrmsFury) and not ShouldSkipSpell(SPELL.FrostwyrmsFury) then
                return "spell", SPELL.FrostwyrmsFury
            end
        end
        
        -- 3. 冰霜之柱(无辛达苟萨): 无辛达苟萨天赋 且 可放CD 且 (非死神 或 符文>=2)
        if HasTalent(TALENT.PillarOfFrost) and not HasTalent(TALENT.BreathOfSindragosa) and sendingCDs and (not isDeathbringer or runes >= 2) then
            if NCF.MeetsSpellTTD(SPELL.PillarOfFrost) and IsReady(SPELL.PillarOfFrost) and not ShouldSkipSpell(SPELL.PillarOfFrost) then
                return "spell", SPELL.PillarOfFrost
            end
        end
        
        -- 4. 冰霜之柱(有辛达苟萨): 有辛达苟萨天赋 且 辛达苟萨检查 且 (非死神 或 符文>=2)
        if HasTalent(TALENT.PillarOfFrost) and HasTalent(TALENT.BreathOfSindragosa) and sendingCDs and breathCheck and (not isDeathbringer or runes >= 2) then
            if NCF.MeetsSpellTTD(SPELL.PillarOfFrost) and IsReady(SPELL.PillarOfFrost) and not ShouldSkipSpell(SPELL.PillarOfFrost) then
                return "spell", SPELL.PillarOfFrost
            end
        end
        
        -- 5. 辛达苟萨之息: 无辛达苟萨buff 且 冰霜之柱激活
        if HasTalent(TALENT.BreathOfSindragosa) and not hasBreath and hasPillar and runicPower >= 60 then
            if IsReady(SPELL.BreathOfSindragosa) and not ShouldSkipSpell(SPELL.BreathOfSindragosa) then
                return "spell", SPELL.BreathOfSindragosa
            end
        end
        
        -- 6. 收割者印记: 目标无收割者印记debuff 且 (冰霜之柱激活 或 冰霜之柱CD>5秒)
        if isDeathbringer and not hasReapersMark and (hasPillar or pillarCD > 5) then
            if IsReady(SPELL.ReapersMark) and not ShouldSkipSpell(SPELL.ReapersMark) then
                return "spell", SPELL.ReapersMark
            end
        end
        
        -- 7. 冰龙吐息(非天启骑士): 非天启骑士 且 冰霜之柱激活 且 冰龙吐息条件
        if not isRider and not HasTalent(TALENT.ApocalypseNow) and hasPillar and fwfBuffs then
            if NCF.MeetsSpellTTD(SPELL.FrostwyrmsFury) and IsReady(SPELL.FrostwyrmsFury) and not ShouldSkipSpell(SPELL.FrostwyrmsFury) then
                return "spell", SPELL.FrostwyrmsFury
            end
        end
        
        -- 8. 符文武器强化: (符文<2 或 无杀戮机器) 且 符能<35+(寒冰猛袭层数*5)
        local erwCondition = (runes < 2 or not hasKM) and runicPower < (35 + icyOnslaughtStacks * 5)
        if erwCondition and IsReady(SPELL.EmpowerRuneWeapon) and not ShouldSkipSpell(SPELL.EmpowerRuneWeapon) then
            return "spell", SPELL.EmpowerRuneWeapon
        end
        
        --==========================================================
        -- AOE循环 (敌人>=3)
        --==========================================================
        if enemyCount >= 3 then
            
            -- 1. 冰霜镰刀: (杀戮机器=2 或 (有杀戮机器 且 符文>=3)) 且 敌人>=冰霜镰刀优先级
            if (kmStacks == 2 or (hasKM and runes >= 3)) and enemyCount >= frostscythePrio and IsReady(SPELL.Frostscythe) and not ShouldSkipSpell(SPELL.Frostscythe) then
                return "spell", SPELL.Frostscythe
            end
            
            -- 2. 湮灭: 杀戮机器=2 或 (有杀戮机器 且 符文>=3)
            if (kmStacks == 2 or (hasKM and runes >= 3)) and IsReady(SPELL.Obliterate) and not ShouldSkipSpell(SPELL.Obliterate) then
                return "spell", SPELL.Obliterate
            end
            
            -- 3. 凛冽寒风: (有白霜 且 有霜缚意志天赋) 或 目标无冰霜热病
            if ((hasRime and HasTalent(TALENT.FrostboundWill)) or not hasFrostFever) and IsReady(SPELL.HowlingBlast) and not ShouldSkipSpell(SPELL.HowlingBlast) then
                return "spell", SPELL.HowlingBlast
            end
            
            -- 4. 霜噬: 有天赋 且 有霜噬buff 且 符能>=35
            if HasTalent(TALENT.Frostbane) and hasFrostbaneBuff and runicPower >= 35 and IsReady(SPELL.Frostbane) and not ShouldSkipSpell(SPELL.Frostbane) then
                return "spell", SPELL.Frostbane
            end
            
            -- 5. 冰霜打击: 锐冰=5层 且 有霜噬buff
            if razoriceStacks == 5 and hasFrostbaneBuff and runicPower >= 35 and IsReady(SPELL.FrostStrike) and not ShouldSkipSpell(SPELL.FrostStrike) then
                return "spell", SPELL.FrostStrike
            end
            
            -- 6. 冰霜打击: 锐冰=5层 且 有碎裂之刃天赋 且 敌人<5 且 不囤符能 且 无霜噬天赋
            if razoriceStacks == 5 and HasTalent(TALENT.ShatteringBlade) and enemyCount < 5 and not rpPooling and runicPower >= 35 and not HasTalent(TALENT.Frostbane) and IsReady(SPELL.FrostStrike) and not ShouldSkipSpell(SPELL.FrostStrike) then
                return "spell", SPELL.FrostStrike
            end
            
            -- 7. 冰霜镰刀: 有杀戮机器 且 不囤符文 且 敌人>=冰霜镰刀优先级
            if hasKM and not runePooling and runes >= 2 and enemyCount >= frostscythePrio and IsReady(SPELL.Frostscythe) and not ShouldSkipSpell(SPELL.Frostscythe) then
                return "spell", SPELL.Frostscythe
            end
            
            -- 8. 湮灭: 有杀戮机器 且 不囤符文
            if hasKM and not runePooling and runes >= 2 and IsReady(SPELL.Obliterate) and not ShouldSkipSpell(SPELL.Obliterate) then
                return "spell", SPELL.Obliterate
            end
            
            -- 9. 凛冽寒风: 有白霜
            if hasRime and IsReady(SPELL.HowlingBlast) and not ShouldSkipSpell(SPELL.HowlingBlast) then
                return "spell", SPELL.HowlingBlast
            end
            
            -- 10. 冰河突进: 不囤符能
            if not rpPooling and runicPower >= 35 and IsReady(SPELL.GlacialAdvance) and not ShouldSkipSpell(SPELL.GlacialAdvance) then
                return "spell", SPELL.GlacialAdvance
            end
            
            -- 11. 冰霜镰刀: 不囤符文 且 非(有湮灭天赋 且 冰霜之柱激活) 且 敌人>=冰霜镰刀优先级
            if not runePooling and runes >= 2 and not (HasTalent(TALENT.Obliteration) and hasPillar) and enemyCount >= frostscythePrio and IsReady(SPELL.Frostscythe) and not ShouldSkipSpell(SPELL.Frostscythe) then
                return "spell", SPELL.Frostscythe
            end
            
            -- 12. 湮灭: 不囤符文 且 非(有湮灭天赋 且 冰霜之柱激活)
            if not runePooling and runes >= 2 and not (HasTalent(TALENT.Obliteration) and hasPillar) and IsReady(SPELL.Obliterate) and not ShouldSkipSpell(SPELL.Obliterate) then
                return "spell", SPELL.Obliterate
            end
            
            -- 13. 凛冽寒风: 无杀戮机器 且 有湮灭天赋 且 冰霜之柱激活
            if not hasKM and HasTalent(TALENT.Obliteration) and hasPillar and runes >= 1 and IsReady(SPELL.HowlingBlast) and not ShouldSkipSpell(SPELL.HowlingBlast) then
                return "spell", SPELL.HowlingBlast
            end
            
        --==========================================================
        -- 单体循环 (敌人<3)
        --==========================================================
        else
            
            -- 1. 湮灭: 杀戮机器=2 或 (有杀戮机器 且 符文>=3)
            if (kmStacks == 2 or (hasKM and runes >= 3)) and IsReady(SPELL.Obliterate) and not ShouldSkipSpell(SPELL.Obliterate) then
                return "spell", SPELL.Obliterate
            end
            
            -- 2. 凛冽寒风: 有白霜 且 有霜缚意志天赋
            if hasRime and HasTalent(TALENT.FrostboundWill) and IsReady(SPELL.HowlingBlast) and not ShouldSkipSpell(SPELL.HowlingBlast) then
                return "spell", SPELL.HowlingBlast
            end
            
            -- 3. 霜噬: 有天赋 且 有霜噬buff 且 符能>=35
            if HasTalent(TALENT.Frostbane) and hasFrostbaneBuff and runicPower >= 35 and IsReady(SPELL.Frostbane) and not ShouldSkipSpell(SPELL.Frostbane) then
                return "spell", SPELL.Frostbane
            end
            
            -- 4. 冰霜打击: 锐冰=5层 且 有碎裂之刃天赋 且 不囤符能
            if razoriceStacks == 5 and HasTalent(TALENT.ShatteringBlade) and not rpPooling and runicPower >= 35 and IsReady(SPELL.FrostStrike) and not ShouldSkipSpell(SPELL.FrostStrike) then
                return "spell", SPELL.FrostStrike
            end
            
            -- 5. 凛冽寒风: 有白霜
            if hasRime and IsReady(SPELL.HowlingBlast) and not ShouldSkipSpell(SPELL.HowlingBlast) then
                return "spell", SPELL.HowlingBlast
            end
            
            -- 6. 冰霜打击: 无碎裂之刃天赋 且 不囤符能 且 符能缺口<30
            if not HasTalent(TALENT.ShatteringBlade) and not rpPooling and runicPower >= 35 and runicPowerDeficit < 30 and IsReady(SPELL.FrostStrike) and not ShouldSkipSpell(SPELL.FrostStrike) then
                return "spell", SPELL.FrostStrike
            end
            
            -- 7. 湮灭: 有杀戮机器 且 不囤符文
            if hasKM and not runePooling and runes >= 2 and IsReady(SPELL.Obliterate) and not ShouldSkipSpell(SPELL.Obliterate) then
                return "spell", SPELL.Obliterate
            end
            
            -- 8. 冰霜打击: 不囤符能
            if not rpPooling and runicPower >= 35 and IsReady(SPELL.FrostStrike) and not ShouldSkipSpell(SPELL.FrostStrike) then
                return "spell", SPELL.FrostStrike
            end
            
            -- 9. 湮灭: 不囤符文 且 非(有湮灭天赋 且 冰霜之柱激活)
            if not runePooling and runes >= 2 and not (HasTalent(TALENT.Obliteration) and hasPillar) and IsReady(SPELL.Obliterate) and not ShouldSkipSpell(SPELL.Obliterate) then
                return "spell", SPELL.Obliterate
            end
            
            -- 10. 凛冽寒风: 无杀戮机器 且 有湮灭天赋 且 冰霜之柱激活
            if not hasKM and HasTalent(TALENT.Obliteration) and hasPillar and runes >= 1 and IsReady(SPELL.HowlingBlast) and not ShouldSkipSpell(SPELL.HowlingBlast) then
                return "spell", SPELL.HowlingBlast
            end
            
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateFrostRotation()