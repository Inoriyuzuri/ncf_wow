--============================================================
-- 防护战士循环 (Protection Warrior APL)
-- 12.0 版本
--============================================================

--[[
=== 优先级循环 ===

0. 打断 - 拳击 (6552)

--- 开场/爆发 ---
1. 冲锋 (100): 开场拉怪
2. 巨像化身 (107574): 雷霆爆裂层数=0 或 <=2
3. 无视苦痛 (190456): 怒气溢出<=15 或 没有buff
4. 毁灭者 (228920): 有天赋
5. 挫志怒吼 (1160): 有天赋雷鸣之声
6. 勇士之矛 (376079): 有天赋
7. 雷霆爆裂 (435222): 敌人>=2 且 层数=2
8. 拆卸 (436358): 巨力层数>=3 且 有天赋
9. 盾牌猛冲 (385952): 有天赋
10. 盾牌格挡 (2565): 剩余时间<=10秒

--- AOE (敌人>=3) ---
11. 雷霆爆裂/雷霆一击: 撕裂<=1秒
12. 雷霆爆裂: 有狂暴爆发buff 且 敌人>=2 且 有巨像化身
13. 斩杀 (163201): 敌人>=2 且 (怒气>=50 或 有猝死buff) 且 有天赋重击
14. 雷霆一击: (有狂暴爆发 且 敌人>=4 且 有巨像化身 且 有天赋轰鸣雷霆) 或 (有狂暴爆发 且 敌人>6 且 有巨像化身)
15. 复仇 (6572): 怒气>=70 且 敌人>=3
16. 盾牌猛击 (23922): 怒气<=60 或 (有狂暴爆发 且 敌人<=4 且 有天赋轰鸣雷霆)
17. 雷霆爆裂/雷霆一击: 填充
18. 复仇: 怒气>=30 或 (怒气>=40 且 有天赋野蛮训练)

--- 单目标 ---
19. 雷霆爆裂: 层数=2 且 爆发之力层数<=1 且 有巨像化身
20. 盾牌猛击: (爆发之力层数=2 且 雷霆爆裂层数<=1 或 有狂暴爆发) 或 (怒气<=70 且 有天赋拆卸)
21. 斩杀: (怒气>=70) 或 (怒气>=40 且 盾牌猛击CD中 且 有天赋拆卸) 或 (怒气>=50 且 盾牌猛击CD中) 或 (有猝死buff 且 有天赋猝死)
22. 盾牌猛击: 填充
23. 投掷毁灭 (384110)
24. 碎裂投掷 (64382)
25. 雷霆爆裂/雷霆一击: 撕裂<=2秒 且 没有狂暴爆发
26. 雷霆爆裂/雷霆一击: 填充
27. 复仇: 复杂条件
28. 斩杀: 填充
29. 复仇: 填充
30. 毁灭打击 (20243): 最终填充

=== Buff ID ===
- 雷霆爆裂: 435615
- 无视苦痛: 190456
- 盾牌格挡: 132404
- 狂暴爆发: 386478
- 巨像化身: 107574
- 猝死: 52437
- 爆发之力: 437121
- 巨力: 440989
- 复仇(免费): 5302

=== Debuff ID ===
- 撕裂: 388539

=== 天赋 ID ===
- 毁灭者: 228920
- 雷鸣之声: 202743
- 勇士之矛: 376079
- 拆卸: 436358
- 盾牌猛冲: 385952
- 重击: 1235088
- 野蛮训练: 383082
- 猝死: 29725
- 屠杀: 281001
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("WARRIOR", 3, {
    -- 爆发技能
    { id = 107574, name = "巨像化身", default = "burst" },
    { id = 228920, name = "毁灭者", default = "burst" },
    { id = 376079, name = "勇士之矛", default = "burst" },
    
    -- 普通技能
    { id = 6552, name = "拳击", default = "normal" },
    { id = 100, name = "冲锋", default = "normal" },
    { id = 57755, name = "英勇投掷", default = "normal" },
    { id = 6673, name = "战斗怒吼", default = "normal" },
    { id = 190456, name = "无视苦痛", default = "normal" },
    { id = 1160, name = "挫志怒吼", default = "normal" },
    { id = 435222, name = "雷霆爆裂", default = "normal" },
    { id = 436358, name = "拆卸", default = "normal" },
    { id = 385952, name = "盾牌猛冲", default = "normal" },
    { id = 2565, name = "盾牌格挡", default = "normal" },
    { id = 6343, name = "雷霆一击", default = "normal" },
    { id = 163201, name = "斩杀", default = "normal" },
    { id = 6572, name = "复仇", default = "normal" },
    { id = 23922, name = "盾牌猛击", default = "normal" },
    { id = 384110, name = "投掷毁灭", default = "normal" },
    { id = 64382, name = "碎裂投掷", default = "normal" },
    { id = 20243, name = "毁灭打击", default = "normal" },
    { id = 202168, name = "胜利在望", default = "normal" },
    { id = 871, name = "盾墙", default = "normal" },
    { id = 97462, name = "集结呐喊", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Pummel = 6552,              -- 拳击 (打断)
    Charge = 100,               -- 冲锋
    HeroicThrow = 57755,        -- 英勇投掷
    BattleShout = 6673,         -- 战斗怒吼
    Avatar = 107574,            -- 巨像化身
    IgnorePain = 190456,        -- 无视苦痛 (35怒气)
    Ravager = 228920,           -- 毁灭者
    DemoralizingShout = 1160,   -- 挫志怒吼
    ChampionsSpear = 376079,    -- 勇士之矛
    ThunderBlast = 435222,      -- 雷霆爆裂
    Demolish = 436358,          -- 拆卸
    ShieldCharge = 385952,      -- 盾牌猛冲
    ShieldBlock = 2565,         -- 盾牌格挡
    ThunderClap = 6343,         -- 雷霆一击
    Execute = 163201,           -- 斩杀 (20+码)
    ExecuteMassacre = 281000,   -- 斩杀 (屠杀天赋)
    Revenge = 6572,             -- 复仇 (20怒气)
    ShieldSlam = 23922,         -- 盾牌猛击
    WreckingThrow = 384110,     -- 投掷毁灭
    ShatteringThrow = 64382,    -- 碎裂投掷
    Devastate = 20243,          -- 毁灭打击
    ImpendingVictory = 202168,  -- 胜利在望
    ShieldWall = 871,           -- 盾墙
    RallyingCry = 97462,        -- 集结呐喊
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    ThunderBlast = 435615,      -- 雷霆爆裂层数
    IgnorePain = 190456,        -- 无视苦痛
    ShieldBlock = 132404,       -- 盾牌格挡
    ViolentOutburst = 386478,   -- 狂暴爆发
    Avatar = 107574,            -- 巨像化身
    SuddenDeath = 52437,        -- 猝死
    BurstOfPower = 437121,      -- 爆发之力
    ColossalMight = 440989,     -- 巨力
    Revenge = 5302,             -- 复仇(免费)
    BattleShout = 6673,         -- 战斗怒吼
    ShieldWall = 871,           -- 盾墙
}

--============================================================
-- 4. Debuff ID定义
--============================================================
local DEBUFF = {
    Rend = 388539,              -- 撕裂
}

--============================================================
-- 5. 天赋ID定义
--============================================================
local TALENT = {
    Ravager = 228920,           -- 毁灭者
    BoomingVoice = 202743,      -- 雷鸣之声
    ChampionsSpear = 376079,    -- 勇士之矛
    Demolish = 436358,          -- 拆卸
    ShieldCharge = 385952,      -- 盾牌猛冲
    HeavyHanded = 1235088,      -- 重击
    BarbaricTraining = 383082,  -- 野蛮训练
    SuddenDeath = 29725,        -- 猝死
    Massacre = 281001,          -- 屠杀
    CrashingThunder = 436707,   -- 轰鸣雷霆 (需确认ID)
    WreckingThrow = 384110,     -- 投掷毁灭
    ShatteringThrow = 64382,    -- 碎裂投掷
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
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower

local function GetRage()
    return GetUnitPower("player", "rage")
end

local function GetRageMax()
    return NCF.GetUnitPowerMax("player", "rage")
end

-- 查找斩杀阈值内的目标 (5码范围)
local function GetExecuteTarget(threshold)
    -- 先检查当前目标
    if UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") then
        local targetHp = NCF.GetUnitHealthPct("target")
        if targetHp <= threshold then
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
                    if hp <= threshold then
                        table.insert(validEnemies, {unit = obj, hp = hp})
                    end
                end
            end
        end
    end
    
    -- 按血量从低到高排序，优先斩杀血量最低的
    if #validEnemies > 0 then
        table.sort(validEnemies, function(a, b) return a.hp < b.hp end)
        return validEnemies[1].unit
    end
    
    return nil
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateProtectionRotation()

    local function Rotation()
        local enemyCount = GetActiveEnemyAmount(8, false)
        SetEnemyCount(enemyCount)
        
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        local rage = GetRage()
        local rageMax = GetRageMax()
        local rageDeficit = rageMax - rage
        
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- Override检查: 雷霆爆裂
        local isThunderBlast = C_Spell.GetOverrideSpell(SPELL.ThunderClap) == SPELL.ThunderBlast
        local thunderSpell = isThunderBlast and SPELL.ThunderBlast or SPELL.ThunderClap
        
        -- 斩杀技能 (屠杀天赋改变ID)
        local executeSpell = SPELL.Execute
        if HasTalent(TALENT.Massacre) then
            executeSpell = SPELL.ExecuteMassacre
        end
        
        -- Buff状态
        local thunderBlastStacks = GetBuffStacks(BUFF.ThunderBlast)
        local hasIgnorePain = HasBuff(BUFF.IgnorePain)
        local shieldBlockRemain = GetBuffRemain(BUFF.ShieldBlock)
        local hasViolentOutburst = HasBuff(BUFF.ViolentOutburst)
        local hasAvatar = HasBuff(BUFF.Avatar)
        local hasSuddenDeath = HasBuff(BUFF.SuddenDeath)
        local burstOfPowerStacks = GetBuffStacks(BUFF.BurstOfPower)
        local colossalMightStacks = GetBuffStacks(BUFF.ColossalMight)
        local hasRevengeBuff = HasBuff(BUFF.Revenge)
        
        -- Debuff状态
        local rendRemain = GetDebuffRemain(DEBUFF.Rend, "target")
        
        -- 天赋检查
        local hasRavager = HasTalent(TALENT.Ravager)
        local hasBoomingVoice = HasTalent(TALENT.BoomingVoice)
        local hasChampionsSpear = HasTalent(TALENT.ChampionsSpear)
        local hasDemolish = HasTalent(TALENT.Demolish)
        local hasShieldCharge = HasTalent(TALENT.ShieldCharge)
        local hasHeavyHanded = HasTalent(TALENT.HeavyHanded)
        local hasBarbaricTraining = HasTalent(TALENT.BarbaricTraining)
        local hasSuddenDeathTalent = HasTalent(TALENT.SuddenDeath)
        local hasMassacre = HasTalent(TALENT.Massacre)
        local hasCrashingThunder = HasTalent(TALENT.CrashingThunder)
		local hasWreckingThrow = HasTalent(TALENT.WreckingThrow)
		local hasShatteringThrow = HasTalent(TALENT.ShatteringThrow)
        
        -- 斩杀阶段阈值
        local executeThreshold = hasMassacre and 35 or 20
        local targetHealthPct = NCF.GetTargetHealthPct()
        local inExecutePhase = targetHealthPct <= executeThreshold
        
        -- 盾牌猛击CD
        local shieldSlamOnCD = GetSpellCooldownRemain(SPELL.ShieldSlam) > gcd
        
        -- 自身血量
        local playerHealthPct = NCF.GetUnitHealthPct("player")
        
        -- 战斗怒吼buff检测
        local hasBattleShout = HasBuff(BUFF.BattleShout)
        local hasShieldWall = HasBuff(BUFF.ShieldWall)
        
        -- 战前: 没有战斗怒吼buff则释放
        if not hasBattleShout and IsReady(SPELL.BattleShout) and not ShouldSkipSpell(SPELL.BattleShout) then
            return "spell", SPELL.BattleShout
        end
        
        -- 爆发阶段
        if NCF.burstModeEnabled and hasAvatar then
            NCF.UseTrinket()
            if NCF.enablePotion then 
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end
        
        -- 战斗检测
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end
        --============================================================
        -- 防御技能 (优先级最高)
        --============================================================
        
        -- 盾墙: 自身血量<=50% 且 没有盾墙buff
        if playerHealthPct <= 50 and not hasShieldWall and IsReady(SPELL.ShieldWall) and not ShouldSkipSpell(SPELL.ShieldWall) then
            return "spell", SPELL.ShieldWall
        end
        
        -- 集结呐喊: 团队平均血量<50%
        local groupAvgHealth = NCF.GetGroupAverageHealthPct(40)
        if groupAvgHealth and groupAvgHealth < 50 and IsReady(SPELL.RallyingCry) and not ShouldSkipSpell(SPELL.RallyingCry) then
            return "spell", SPELL.RallyingCry
        end
        
        -- 胜利在望: 自身血量<=70% 且 10码内有目标
        if playerHealthPct <= 70 and enemyCount > 0 and IsReady(SPELL.ImpendingVictory) and not ShouldSkipSpell(SPELL.ImpendingVictory) then
            return "spell", SPELL.ImpendingVictory
        end
		
        -- 0. 打断
        if IsReady(SPELL.Pummel) and not ShouldSkipSpell(SPELL.Pummel) then
            local interruptTarget = NCF.GetInterruptTarget(5, false)
            if interruptTarget then
                return "InstantSpell", SPELL.Pummel, interruptTarget
            end
        end
        
        --============================================================
        -- 开场/爆发技能
        --============================================================
        
        -- 获取到目标距离
        local distToTarget = NCF.GetDistanceToTarget("target")
        
        -- 1. 冲锋: 没进战斗 且 目标在8码外
        if not UnitAffectingCombat("player") and distToTarget > 8 and IsReady(SPELL.Charge) and not ShouldSkipSpell(SPELL.Charge) then
            return "spell", SPELL.Charge
        end
        
        -- 1.5 英勇投掷: 进战斗 且 目标在8码外
        if UnitAffectingCombat("player") and distToTarget > 8 and IsReady(SPELL.HeroicThrow) and not ShouldSkipSpell(SPELL.HeroicThrow) then
            return "spell", SPELL.HeroicThrow
        end
        
        -- 2. 巨像化身: 雷霆爆裂层数=0 或 <=2
        if (thunderBlastStacks == 0 or thunderBlastStacks <= 2) and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
            return "spell", SPELL.Avatar
        end
        
        -- 3. 无视苦痛: 怒气溢出<=15 或 没有buff
        if (rageDeficit <= 15 or not hasIgnorePain) and rage >= 35 and IsReady(SPELL.IgnorePain) and not ShouldSkipSpell(SPELL.IgnorePain) then
            return "spell", SPELL.IgnorePain
        end
        
        -- 4. 毁灭者: 有天赋
        if hasRavager and IsReady(SPELL.Ravager) and not ShouldSkipSpell(SPELL.Ravager) then
            return "spell", SPELL.Ravager
        end
        
        -- 5. 挫志怒吼: 有天赋雷鸣之声
        if hasBoomingVoice and IsReady(SPELL.DemoralizingShout) and not ShouldSkipSpell(SPELL.DemoralizingShout) then
            return "spell", SPELL.DemoralizingShout
        end
        
        -- 6. 勇士之矛: 有天赋
        if hasChampionsSpear and IsReady(SPELL.ChampionsSpear) and not ShouldSkipSpell(SPELL.ChampionsSpear) then
            return "spell", SPELL.ChampionsSpear
        end
        
        -- 7. 雷霆爆裂: 敌人>=2 且 层数=2
        if isThunderBlast and enemyCount >= 2 and thunderBlastStacks == 2 and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
            return "spell", SPELL.ThunderBlast
        end
        
        -- 8. 拆卸: 巨力层数>=3 且 有天赋
        if hasDemolish and colossalMightStacks >= 3 and IsReady(SPELL.Demolish) and not ShouldSkipSpell(SPELL.Demolish) then
            return "spell", SPELL.Demolish
        end
        
        -- 9. 盾牌猛冲: 有天赋
        if hasShieldCharge and IsReady(SPELL.ShieldCharge) and not ShouldSkipSpell(SPELL.ShieldCharge) then
            return "spell", SPELL.ShieldCharge
        end
        
        -- 10. 盾牌格挡: 剩余时间<=2秒
        if rage >= 30 and shieldBlockRemain <= 2 and IsReady(SPELL.ShieldBlock) and not ShouldSkipSpell(SPELL.ShieldBlock) then
            return "spell", SPELL.ShieldBlock
        end
        
        --============================================================
        -- AOE (敌人>=3)
        --============================================================
        if enemyCount >= 3 then
            -- 11. 雷霆爆裂/雷霆一击: 撕裂<=1秒
            if rendRemain <= 1 and IsReady(thunderSpell) and not ShouldSkipSpell(thunderSpell) then
                return "spell", thunderSpell
            end
            
            -- 12. 雷霆爆裂: 有狂暴爆发buff 且 敌人>=2 且 有巨像化身
            if isThunderBlast and hasViolentOutburst and enemyCount >= 2 and hasAvatar and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 13. 斩杀: 敌人>=2 且 (怒气>=50 或 有猝死buff) 且 有天赋重击
            if hasHeavyHanded and enemyCount >= 2 and (rage >= 50 or hasSuddenDeath) and IsReady(executeSpell) and not ShouldSkipSpell(executeSpell) then
                local exeTarget = GetExecuteTarget(executeThreshold)
                if exeTarget then
                    return "InstantSpell", executeSpell, exeTarget
                end
            end
            
            -- 14. 雷霆一击: 复杂条件
            local tcCondition1 = hasViolentOutburst and enemyCount >= 4 and hasAvatar and hasCrashingThunder
            local tcCondition2 = hasViolentOutburst and enemyCount > 6 and hasAvatar
            if (tcCondition1 or tcCondition2) and IsReady(SPELL.ThunderClap) and not ShouldSkipSpell(SPELL.ThunderClap) then
                return "spell", SPELL.ThunderClap
            end
            
            -- 15. 复仇: 怒气>=70 且 敌人>=3 (需要怒气>=20或免费buff)
            if rage >= 70 and enemyCount >= 3 and (hasRevengeBuff or rage >= 20) and IsReady(SPELL.Revenge) and not ShouldSkipSpell(SPELL.Revenge) then
                return "spell", SPELL.Revenge
            end
            
            -- 16. 盾牌猛击: 怒气<=60 或 (有狂暴爆发 且 敌人<=4 且 有天赋轰鸣雷霆)
            local ssCondition = rage <= 60 or (hasViolentOutburst and enemyCount <= 4 and hasCrashingThunder)
            if ssCondition and IsReady(SPELL.ShieldSlam) and not ShouldSkipSpell(SPELL.ShieldSlam) then
                return "spell", SPELL.ShieldSlam
            end
            
            -- 17. 雷霆爆裂/雷霆一击: 填充
            if IsReady(thunderSpell) and not ShouldSkipSpell(thunderSpell) then
                return "spell", thunderSpell
            end
            
            -- 18. 复仇: (怒气>=30 或 怒气>=40且野蛮训练) 且 (免费buff或怒气>=20)
            local revCondition = rage >= 30 or (rage >= 40 and hasBarbaricTraining)
            if revCondition and (hasRevengeBuff or rage >= 20) and IsReady(SPELL.Revenge) and not ShouldSkipSpell(SPELL.Revenge) then
                return "spell", SPELL.Revenge
            end
        end
        
        --============================================================
        -- 单目标
        --============================================================
        
        -- 19. 雷霆爆裂: 层数=2 且 爆发之力层数<=1 且 有巨像化身
        if isThunderBlast and thunderBlastStacks == 2 and burstOfPowerStacks <= 1 and hasAvatar and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
            return "spell", SPELL.ThunderBlast
        end
        
        -- 20. 盾牌猛击: (爆发之力层数=2 且 雷霆爆裂层数<=1 或 有狂暴爆发) 或 (怒气<=70 且 有天赋拆卸)
        local ssCondition1 = (burstOfPowerStacks == 2 and thunderBlastStacks <= 1) or hasViolentOutburst
        local ssCondition2 = rage <= 70 and hasDemolish
        if (ssCondition1 or ssCondition2) and IsReady(SPELL.ShieldSlam) and not ShouldSkipSpell(SPELL.ShieldSlam) then
            return "spell", SPELL.ShieldSlam
        end
        
        -- 21. 斩杀: 复杂条件
        local exeCondition1 = rage >= 70
        local exeCondition2 = rage >= 40 and shieldSlamOnCD and hasDemolish
        local exeCondition3 = rage >= 50 and shieldSlamOnCD
        local exeCondition4 = hasSuddenDeath and hasSuddenDeathTalent
        if (exeCondition1 or exeCondition2 or exeCondition3 or exeCondition4) and IsReady(executeSpell) and not ShouldSkipSpell(executeSpell) then
            local exeTarget = GetExecuteTarget(executeThreshold)
            if exeTarget then
                return "InstantSpell", executeSpell, exeTarget
            end
        end
        
        -- 22. 盾牌猛击: 填充
        if IsReady(SPELL.ShieldSlam) and not ShouldSkipSpell(SPELL.ShieldSlam) then
            return "spell", SPELL.ShieldSlam
        end
        
        -- 23. 投掷毁灭
        if hasWreckingThrow and IsReady(SPELL.WreckingThrow) and not ShouldSkipSpell(SPELL.WreckingThrow) then
            return "spell", SPELL.WreckingThrow
        end
        
        -- 24. 碎裂投掷
        if hasShatteringThrow and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
            return "spell", SPELL.ShatteringThrow
        end
        
        -- 25. 雷霆爆裂/雷霆一击: 撕裂<=2秒 且 没有狂暴爆发
        if rendRemain <= 2 and not hasViolentOutburst and IsReady(thunderSpell) and not ShouldSkipSpell(thunderSpell) then
            return "spell", thunderSpell
        end
        
        -- 26. 雷霆爆裂: 填充
        if isThunderBlast and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
            return "spell", SPELL.ThunderBlast
        end
        
        -- 27. 雷霆一击: (敌人>1 或 盾牌猛击CD中) 且 没有狂暴爆发
        if (enemyCount > 1 or shieldSlamOnCD) and not hasViolentOutburst and IsReady(SPELL.ThunderClap) and not ShouldSkipSpell(SPELL.ThunderClap) then
            return "spell", SPELL.ThunderClap
        end
        
        -- 28. 复仇: 复杂条件 (需要怒气>=20或免费buff)
        local revCondition1 = rage >= 80 and targetHealthPct > executeThreshold
        local revCondition2 = hasRevengeBuff and inExecutePhase and rage <= 18 and shieldSlamOnCD
        local revCondition3 = hasRevengeBuff and targetHealthPct > executeThreshold
        if (revCondition1 or revCondition2 or revCondition3) and (hasRevengeBuff or rage >= 20) and IsReady(SPELL.Revenge) and not ShouldSkipSpell(SPELL.Revenge) then
            return "spell", SPELL.Revenge
        end
        
        -- 29. 斩杀: 填充 (有符合阈值的目标)
        if IsReady(executeSpell) and not ShouldSkipSpell(executeSpell) then
            local exeTarget = GetExecuteTarget(executeThreshold)
            if exeTarget then
                return "InstantSpell", executeSpell, exeTarget
            end
        end
        
        -- 30. 复仇: 填充 (需要怒气>=20或免费buff)
        if (hasRevengeBuff or rage >= 20) and IsReady(SPELL.Revenge) and not ShouldSkipSpell(SPELL.Revenge) then
            return "spell", SPELL.Revenge
        end
        
        -- 31. 雷霆爆裂/雷霆一击: 有狂暴爆发时
        if hasViolentOutburst and IsReady(thunderSpell) and not ShouldSkipSpell(thunderSpell) then
            return "spell", thunderSpell
        end
        
        -- 32. 毁灭打击: 最终填充
        if IsReady(SPELL.Devastate) and not ShouldSkipSpell(SPELL.Devastate) then
            return "spell", SPELL.Devastate
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateProtectionRotation()