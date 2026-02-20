--============================================================
-- 狂暴战士循环 (Fury Warrior APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
-- 前置条件：需要天赋 434969
--
-- 天赋分支:
-- - 风暴的化身 (437134): 已实现
-- - 无情强袭 (444780): 已实现
--============================================================

--[[
===================================
通用优先级 (所有天赋分支共享)
===================================

0.   打断 - 拳击 (6552): 5码内有可打断目标, 需面朝
0.01 战斗怒吼 (6673): 自身没有战斗怒吼buff
--- 以下需要战斗中 (自己战斗中 或 目标战斗中) ---
0.1  冲锋 (100): 目标距离 > 8码

===================================
风暴的化身 (437134) - AOE (敌人 > 1)
===================================

1.  爆发阶段: 鲁莽激活时 -> 药水 + 饰品 + 种族技能
2.  雷霆一击 (6343): 无旋风斩buff (触发顺劈)
3.  嗜血 (23881): 鲁莽CD < 2秒 且 无浴血之躯buff
4.  天神下凡 (107574): 目标有撕裂debuff 且 有浴血之躯buff 且 鲁莽激活 [爆发]
5.  鲁莽 (1719): 目标有撕裂debuff 且 有浴血之躯buff [爆发]
6.  暴怒 (184367): 怒气 >= 80 且 (无激怒buff 或 怒气 > 110)
7.  奥丁之怒 (385059): 有浴血之躯buff [爆发]
8.  雷霆一击 (6343): 有雷霆轰击uff 且 天神下凡激活
9.  浴血奋战 (23881): 鲁莽激活
10. 斩杀 (280735): 有猝死uff 或 目标处于斩杀阶段
11. 嗜血 (23881): 天神下凡激活
12. 雷霆一击 (6343): 天神下凡激活
13. 暴怒 (184367): 怒气 >= 80
14. 嗜血 (23881): 填充
15. 怒击 (85288): 填充
16. 雷霆一击 (6343): 填充
17. 旋风斩 (190411): 填充

===================================
风暴的化身 (437134) - 单体 (敌人 = 1)
===================================

1.  爆发阶段: 鲁莽激活时 -> 药水 + 饰品 + 种族技能
2.  天神下凡 (107574): 鲁莽激活 [爆发]
3.  鲁莽 (1719): 可用 [爆发]
4.  奥丁之怒 (385059): 有浴血之躯buff [爆发]
5.  暴怒 (184367): 怒气 >= 80 且 (无激怒buff 或 激怒剩余 < GCD 或 怒气 > 110)
6.  斩杀 (280735): 猝死层数 >= 2 或 猝死剩余 < GCD
7.  斩杀 (280735): 目标处于斩杀阶段
8.  雷霆一击 (6343): 雷霆轰击层数 >= 2
9.  雷霆一击 (6343): 天神下凡激活 且 鲁莽未激活 且 有雷霆轰击uff
10. 嗜血 (23881): 无浴血之躯buff
11. 怒击 (85288): 充能 >= 2
12. 斩杀 (280735): 有猝死uff
13. 嗜血 (23881): 填充
14. 怒击 (85288): 填充
15. 暴怒 (184367): 怒气 >= 80 填充
16. 雷霆一击 (6343): 有雷霆轰击uff
17. 碎裂投掷 (384110): 填充 (需天赋)
18. 雷霆一击 (6343): 填充
19. 旋风斩 (190411): 填充

===================================
无情强袭 (444780) - AOE (敌人 > 1)
===================================

1.  爆发阶段: 鲁莽激活时 -> 药水 + 饰品 + 种族技能
2.  旋风斩 (190411): 无旋风斩buff (触发顺劈)
3.  天神下凡 (107574): 鲁莽激活 [爆发]
4.  鲁莽 (1719): 有旋风斩buff [爆发]
5.  剑刃风暴 (227847): 有激怒buff [爆发]
6.  暴怒 (184367): 怒气 >= 80 且 (无激怒buff 或 激怒剩余 < GCD 或 怒气 > 100)
7.  斩杀 (280735): 猝死层数 >= 2 或 猝死剩余 < GCD
8.  斩杀 (280735): 目标处于斩杀阶段
9.  嗜血/浴血奋战 (23881): 鲁莽激活
10. 奥丁之怒 (385059): 有浴血之躯buff [爆发]
11. 怒击 (85288): 填充
12. 斩杀 (280735): 有猝死uff
13. 暴怒 (184367): 怒气 >= 80 填充
13.05 撕裂 (772): 目标无撕裂debuff
13.1 嗜血 (23881): 填充
14. 旋风斩 (190411): 填充

===================================
无情强袭 (444780) - 单体 (敌人 = 1)
===================================

1.  爆发阶段: 鲁莽激活时 -> 药水 + 饰品 + 种族技能
2.  天神下凡 (107574): 鲁莽激活 [爆发]
3.  鲁莽 (1719): 可用 [爆发]
4.  剑刃风暴 (227847): 有激怒buff 且 鲁莽CD > 15秒 [爆发]
5.  暴怒 (184367): 怒气 >= 80 且 (无激怒buff 或 激怒剩余 < GCD 或 怒气 > 100)
6.  斩杀 (280735): 猝死层数 >= 2 或 猝死剩余 < GCD
7.  斩杀 (280735): 目标处于斩杀阶段
8.  奥丁之怒 (385059): 有浴血之躯buff [爆发]
9.  嗜血 (23881): 无浴血之躯buff
10. 怒击 (85288): 无蛮力爆发buff
11. 斩杀 (280735): 有猝死uff
13. 怒击 (85288): 填充
14. 撕裂 (772): 目标无撕裂debuff
15. 嗜血 (23881): 填充
16. 暴怒 (184367): 怒气 >= 80 填充
17. 碎裂投掷 (384110): 填充 (需天赋)
18. 旋风斩 (190411): 填充

===================================
斩杀阶段判断
===================================
- 有屠杀天赋 (206315): 血量 < 35%
- 无屠杀天赋: 血量 < 20%

===================================
Buff ID 参考
===================================
- 激怒: 184362
- 鲁莽: 1719
- 猝死: 52437
- 雷霆轰击: 435615
- 旋风斩: 85739
- 浴血之躯: 1265406
- 天神下凡: 107574
- 蛮力爆发: 1265560
- 战斗怒吼: 6673

===================================
Debuff ID 参考
===================================
- 撕裂: 388539
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("WARRIOR", 2, {
    -- 冷却技能
    { id = 1719, name = "鲁莽", default = "burst" },
    { id = 107574, name = "天神下凡", default = "burst" },
    { id = 385059, name = "奥丁之怒", default = "burst" },
    { id = 227847, name = "剑刃风暴", default = "burst" },
    
    -- 普通技能
    { id = 100, name = "冲锋", default = "normal" },
    { id = 184367, name = "暴怒", default = "normal" },
    { id = 23881, name = "嗜血", default = "normal" },
    { id = 202910, name = "浴血奋战", default = "normal" },
    { id = 280735, name = "斩杀", default = "normal" },
    { id = 85288, name = "怒击", default = "normal" },
    { id = 6343, name = "雷霆一击", default = "normal" },
    { id = 190411, name = "旋风斩", default = "normal" },
    { id = 384110, name = "碎裂投掷", default = "normal" },
    { id = 772, name = "撕裂", default = "normal" },
    { id = 6552, name = "拳击", default = "normal" },
    { id = 6673, name = "攻强", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Charge = 100,               -- 冲锋
    Recklessness = 1719,        -- 鲁莽
    Avatar = 107574,            -- 天神下凡
    OdynsWrath = 385059,        -- 奥丁之怒
    Rampage = 184367,           -- 暴怒
    Bloodthirst = 23881,        -- 嗜血
    Bloodbath = 23881,         -- 浴血奋战 (鲁莽期间的嗜血)
    Execute = 280735,           -- 斩杀 (屠杀天赋)
    ExecuteBase = 5308,         -- 斩杀 (无屠杀天赋)
    RagingBlow = 85288,         -- 怒击
    ThunderBlast = 6343,        -- 雷霆一击
    Whirlwind = 190411,         -- 旋风斩
    ShatteringThrow = 384110,    -- 碎裂投掷
    Pummel = 6552,              -- 拳击
    Bladestorm = 227847,        -- 剑刃风暴
    Rend = 772,                 -- 撕裂
	BattleCry = 6673,
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    Massacre = 206315,          -- 屠杀 (斩杀阈值提升到35%)
    ShatteringThrow = 384110,   -- 碎裂投掷
    Avatar = 107574,            -- 天神下凡
    OdynsWrath = 385059,        -- 奥丁之怒
    BrutalFervor = 1265359,     -- 蛮力爆发
    Bladestorm = 227847,        -- 剑刃风暴
    
    -- 天赋分支
    StormOfSwords = 437134,     -- 风暴的化身
    RelentlessAssault = 444780, -- 无情强袭
}

--============================================================
-- 4. Buff ID定义
--============================================================
local BUFF = {
    Enrage = 184362,            -- 激怒
    Recklessness = 1719,        -- 鲁莽
    SuddenDeath = 52437,        -- 猝死
    ThunderBlast = 435615,      -- 雷霆轰击
    Whirlwind = 85739,          -- 旋风斩
    BloodCraze = 1265406,       -- 浴血之躯
    Avatar = 107574,            -- 天神下凡
    BrutalFervor = 1265560,     -- 蛮力爆发
	BattleCry = 6673,
}

--============================================================
-- 5. Debuff ID定义
--============================================================
local DEBUFF = {
    Rend = 388539,              -- 撕裂
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffRemain = NCF.GetBuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower
local GetDistanceToTarget = NCF.GetDistanceToTarget
local GetUnitHealthPct = NCF.GetUnitHealthPct

local function GetRage()
    return GetUnitPower("player", "rage")
end

-- 获取正确的斩杀技能ID (根据是否有屠杀天赋)
local function GetExecuteSpellID()
    if HasTalent(TALENT.Massacre) then
        return SPELL.Execute  -- 280735
    else
        return SPELL.ExecuteBase  -- 5308
    end
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateFuryRotation()

    -- 判断目标是否处于斩杀阶段
    local function IsExecutePhase(unit)
        unit = unit or "target"
        local hp = GetUnitHealthPct(unit)
        if HasTalent(TALENT.Massacre) then
            return hp < 35
        else
            return hp < 20
        end
    end

    -- 扫描5码内面前处于斩杀阶段的目标
    local function FindExecuteTarget()
        local results = {GetActiveEnemyAmount(5, false)}
        local count = results[1]
        for i = 2, count + 1 do
            local unit = results[i]
            if IsExecutePhase(unit) then
                return unit
            end
        end
        return nil
    end

    local function Rotation()
        
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(8, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local rage = GetRage()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 常用状态缓存
        local hasEnrage = HasBuff(BUFF.Enrage, "player")
        local hasRecklessness = HasBuff(BUFF.Recklessness, "player")
        local hasBloodCraze = HasBuff(BUFF.BloodCraze, "player")
        local hasAvatar = HasBuff(BUFF.Avatar, "player")
        local hasSuddenDeath = HasBuff(BUFF.SuddenDeath, "player")
        local hasWhirlwind = HasBuff(BUFF.Whirlwind, "player")
        local hasThunderBlast = HasBuff(BUFF.ThunderBlast, "player")
        local hasRend = HasDebuff(DEBUFF.Rend, "target")
        local recklessnessCD = GetSpellCooldownRemain(SPELL.Recklessness)
        
        -- 获取正确的斩杀ID
        local executeID = GetExecuteSpellID()
        
        -- 0. 打断: 拳击 5码 需面朝
        if IsReady(SPELL.Pummel) and not ShouldSkipSpell(SPELL.Pummel) then
            local interruptTarget = NCF.GetInterruptTarget(5, true)
            if interruptTarget then
                return "spell", SPELL.Pummel, interruptTarget
            end
        end
        
		-- 0.01. 攻强: 自己没有buff
        if not HasBuff(BUFF.BattleCry, "player") and IsReady(SPELL.BattleCry) and not ShouldSkipSpell(SPELL.BattleCry) then
            return "spell", SPELL.BattleCry
        end

		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end

        -- 0.1 冲锋: 距离 8-20 码
        local distance = GetDistanceToTarget()
        if distance > 8 and IsReady(SPELL.Charge) and not ShouldSkipSpell(SPELL.Charge) then
            return "spell", SPELL.Charge
        end
        
        --==========================================================
        -- 天赋分支: 风暴的化身 (437134)
        --==========================================================
        if HasTalent(TALENT.StormOfSwords) then
        
        --==========================================================
        -- AOE 循环 (敌人 > 1)
        --==========================================================
        if enemyCount > 1 then
            -- 1. 饰品: 鲁莽激活
            if NCF.burstModeEnabled and hasRecklessness then
                if NCF.enablePotion then 
					NCF.UseCombatPotion()
				end
				NCF.UseTrinket()
                local racialSpell = NCF.GetRacialSpell()
                if racialSpell and IsReady(racialSpell) then
                    return "spell", racialSpell
                end
            end
            
            -- 2. 雷霆一击: 无旋风斩buff (触发/维持顺劈)
            if not hasWhirlwind and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 3. 嗜血: 鲁莽CD < 2 且 无浴血之躯buff
            if recklessnessCD < 2 and not hasBloodCraze and IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 4. 天神下凡: 目标有撕裂debuff 且 自身有浴血之躯buff 且 鲁莽激活
            if HasTalent(TALENT.Avatar) and NCF.MeetsSpellTTD(SPELL.Avatar) and hasBloodCraze and hasRecklessness and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 5. 鲁莽: 自身有浴血之躯buff
            if NCF.MeetsSpellTTD(SPELL.Recklessness) and hasBloodCraze and IsReady(SPELL.Recklessness) and not ShouldSkipSpell(SPELL.Recklessness) then
                return "spell", SPELL.Recklessness
            end
            
            -- 6. 暴怒: 无激怒buff 或 怒气 > 110
            if rage >= 80 and (not hasEnrage or rage > 110) and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
            
            -- 7. 奥丁之怒: 有浴血之躯buff
            if HasTalent(TALENT.OdynsWrath) and NCF.MeetsSpellTTD(SPELL.OdynsWrath) and hasBloodCraze and IsReady(SPELL.OdynsWrath) and not ShouldSkipSpell(SPELL.OdynsWrath) then
                return "spell", SPELL.OdynsWrath
            end
            
            -- 8. 雷霆一击: 有雷霆轰击buff 且 天神下凡buff激活
            if hasThunderBlast and hasAvatar and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 9. 浴血奋战
            if hasRecklessness and IsReady(SPELL.Bloodbath) and not ShouldSkipSpell(SPELL.Bloodbath) then
                return "spell", SPELL.Bloodbath
            end
            
            -- 10. 斩杀: (有猝死buff 或 目标处于斩杀阶段) 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if hasSuddenDeath then
                    if execTarget then
                        return "InstantSpell", executeID, execTarget
                    elseif UnitExists("target") and not UnitIsDead("target") then
                        return "InstantSpell", executeID, "target"
                    end
                elseif execTarget then
                    return "InstantSpell", executeID, execTarget
                end
            end
            
            -- 11. 嗜血: 天神下凡buff激活期间
            if hasAvatar and IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 12. 雷霆一击: 天神下凡buff激活期间
            if hasAvatar and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 13. 暴怒: 怒气 >= 80
            if rage >= 80 and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
            
            -- 14. 嗜血 (填充)
            if IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 15. 怒击 (填充)
            if IsReady(SPELL.RagingBlow) and not ShouldSkipSpell(SPELL.RagingBlow) then
                return "spell", SPELL.RagingBlow
            end
            
            -- 16. 雷霆一击 (填充)
            if IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 17. 旋风斩 (填充)
            if IsReady(SPELL.Whirlwind) and not ShouldSkipSpell(SPELL.Whirlwind) then
                return "spell", SPELL.Whirlwind
            end
        
        --==========================================================
        -- 单体循环 (敌人 = 1)
        --==========================================================
        else
            local enrageRemain = GetBuffRemain(BUFF.Enrage, "player")
            local suddenDeathStacks = GetBuffStacks(BUFF.SuddenDeath, "player")
            local suddenDeathRemain = GetBuffRemain(BUFF.SuddenDeath, "player")
            local thunderBlastStacks = GetBuffStacks(BUFF.ThunderBlast, "player")
            local ragingBlowCharges = GetSpellCharges(SPELL.RagingBlow)
            
            -- 1. 饰品: 鲁莽激活
            if NCF.burstModeEnabled and hasRecklessness then
                if NCF.enablePotion then 
					NCF.UseCombatPotion()
				end
				NCF.UseTrinket()
                local racialSpell = NCF.GetRacialSpell()
                if racialSpell and IsReady(racialSpell) then
                    return "spell", racialSpell
                end
            end
            
            -- 2. 天神下凡: 鲁莽激活
            if HasTalent(TALENT.Avatar) and NCF.MeetsSpellTTD(SPELL.Avatar) and hasRecklessness and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 3. 鲁莽
            if NCF.MeetsSpellTTD(SPELL.Recklessness) and IsReady(SPELL.Recklessness) and not ShouldSkipSpell(SPELL.Recklessness) then
                return "spell", SPELL.Recklessness
            end
            
            -- 4. 奥丁之怒: 有浴血之躯buff
            if HasTalent(TALENT.OdynsWrath) and NCF.MeetsSpellTTD(SPELL.OdynsWrath) and hasBloodCraze and IsReady(SPELL.OdynsWrath) and not ShouldSkipSpell(SPELL.OdynsWrath) then
                return "spell", SPELL.OdynsWrath
            end
            
            -- 5. 暴怒: 无激怒buff 或 激怒剩余时间 < GCD 或 怒气 > 110
            if rage >= 80 and (not hasEnrage or enrageRemain < gcd or rage > 110) and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
            
            -- 6. 斩杀: (2层猝死buff 或 猝死剩余时间 < GCD) 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                if suddenDeathStacks >= 2 or (hasSuddenDeath and suddenDeathRemain < gcd) then
                    local execTarget = FindExecuteTarget()
                    if execTarget then
                        return "InstantSpell", executeID, execTarget
                    elseif UnitExists("target") and not UnitIsDead("target") then
                        return "InstantSpell", executeID, "target"
                    end
                end
            end
            
            -- 7. 斩杀: 目标处于斩杀阶段 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                end
            end
            
            -- 8. 雷霆一击: 2层雷霆轰击buff
            if thunderBlastStacks >= 2 and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 9. 雷霆一击: 天神下凡激活 且 鲁莽未激活 且 有雷霆轰击buff
            if hasAvatar and not hasRecklessness and hasThunderBlast and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 10. 嗜血: 无浴血之躯buff
            if not hasBloodCraze and IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 11. 怒击: 2层充能
            if ragingBlowCharges >= 2 and IsReady(SPELL.RagingBlow) and not ShouldSkipSpell(SPELL.RagingBlow) then
                return "spell", SPELL.RagingBlow
            end
            
            -- 12. 斩杀: 有猝死buff 且 斩杀CD就绪
            if hasSuddenDeath and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                elseif UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end
            
            -- 13. 嗜血 (填充)
            if IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 14. 怒击 (填充)
            if IsReady(SPELL.RagingBlow) and not ShouldSkipSpell(SPELL.RagingBlow) then
                return "spell", SPELL.RagingBlow
            end
            
            -- 15. 暴怒 (填充)
            if rage >= 80 and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
            
            -- 16. 雷霆一击: 有雷霆轰击buff
            if hasThunderBlast and IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 17. 碎裂投掷 (填充, 需要天赋)
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
            
            -- 18. 雷霆一击 (填充)
            if IsReady(SPELL.ThunderBlast) and not ShouldSkipSpell(SPELL.ThunderBlast) then
                return "spell", SPELL.ThunderBlast
            end
            
            -- 19. 旋风斩 (填充)
            if IsReady(SPELL.Whirlwind) and not ShouldSkipSpell(SPELL.Whirlwind) then
                return "spell", SPELL.Whirlwind
            end
        end
        
        end -- 风暴的化身分支结束
        
        --==========================================================
        -- 天赋分支: 无情强袭 (444780)
        --==========================================================
        if HasTalent(TALENT.RelentlessAssault) then
        
        --==========================================================
        -- AOE 循环 (敌人 > 1)
        --==========================================================
        if enemyCount > 1 then
            local enrageRemain = GetBuffRemain(BUFF.Enrage, "player")
            local suddenDeathStacks = GetBuffStacks(BUFF.SuddenDeath, "player")
            local suddenDeathRemain = GetBuffRemain(BUFF.SuddenDeath, "player")
            
            -- 1. 饰品: 鲁莽激活
            if NCF.burstModeEnabled and hasRecklessness then
				if NCF.enablePotion then 
					NCF.UseCombatPotion()
				end
				NCF.UseTrinket()
                local racialSpell = NCF.GetRacialSpell()
                if racialSpell and IsReady(racialSpell) then
                    return "spell", racialSpell
                end
            end
            
            -- 2. 旋风斩: 无旋风斩buff (触发/维持顺劈)
            if not hasWhirlwind and IsReady(SPELL.Whirlwind) and not ShouldSkipSpell(SPELL.Whirlwind) then
                return "spell", SPELL.Whirlwind
            end
            
            -- 3. 天神下凡: 鲁莽激活
            if HasTalent(TALENT.Avatar) and NCF.MeetsSpellTTD(SPELL.Avatar) and hasRecklessness and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 4. 鲁莽: 有旋风斩buff
            if NCF.MeetsSpellTTD(SPELL.Recklessness) and hasWhirlwind and IsReady(SPELL.Recklessness) and not ShouldSkipSpell(SPELL.Recklessness) then
                return "spell", SPELL.Recklessness
            end
            
            -- 5. 剑刃风暴: 有激怒buff
            if HasTalent(TALENT.Bladestorm) and NCF.MeetsSpellTTD(SPELL.Bladestorm) and hasEnrage and IsReady(SPELL.Bladestorm) and not ShouldSkipSpell(SPELL.Bladestorm) then
                return "spell", SPELL.Bladestorm
            end
            
            -- 6. 暴怒: 无激怒buff 或 激怒即将结束 或 怒气 > 100
            if rage >= 80 and (not hasEnrage or enrageRemain < gcd or rage > 100) and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
            
            -- 7. 斩杀: (2层猝死buff 或 猝死剩余时间 < GCD) 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                if suddenDeathStacks >= 2 or (hasSuddenDeath and suddenDeathRemain < gcd) then
                    local execTarget = FindExecuteTarget()
                    if execTarget then
                        return "InstantSpell", executeID, execTarget
                    elseif UnitExists("target") and not UnitIsDead("target") then
                        return "InstantSpell", executeID, "target"
                    end
                end
            end
            
            -- 8. 斩杀: 目标处于斩杀阶段 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                end
            end
            
            -- 9. 嗜血 (浴血奋战)
            if IsReady(SPELL.Bloodthirst) and hasRecklessness and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 10. 奥丁之怒: 有浴血之躯buff
            if HasTalent(TALENT.OdynsWrath) and NCF.MeetsSpellTTD(SPELL.OdynsWrath) and hasBloodCraze and IsReady(SPELL.OdynsWrath) and not ShouldSkipSpell(SPELL.OdynsWrath) then
                return "spell", SPELL.OdynsWrath
            end
            
            -- 11. 怒击
            if IsReady(SPELL.RagingBlow) and not ShouldSkipSpell(SPELL.RagingBlow) then
                return "spell", SPELL.RagingBlow
            end
            
            -- 12. 斩杀: 有猝死buff 且 斩杀CD就绪
            if hasSuddenDeath and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                elseif UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end
            
            -- 13. 暴怒 (填充)
            if rage >= 80 and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
			
			-- 13.05 撕裂
			if not hasRend and not ShouldSkipSpell(SPELL.Rend) then
				return "spell", SPELL.Rend
			end
			
             -- 13.1. 嗜血
            if IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
			
            -- 14. 旋风斩 (填充)
            if IsReady(SPELL.Whirlwind) and not ShouldSkipSpell(SPELL.Whirlwind) then
                return "spell", SPELL.Whirlwind
            end
        
        --==========================================================
        -- 单体循环 (敌人 = 1)
        --==========================================================
        else
            local enrageRemain = GetBuffRemain(BUFF.Enrage, "player")
            local suddenDeathStacks = GetBuffStacks(BUFF.SuddenDeath, "player")
            local suddenDeathRemain = GetBuffRemain(BUFF.SuddenDeath, "player")
            local hasBrutalFervor = HasTalent(TALENT.BrutalFervor) and HasBuff(BUFF.BrutalFervor, "player")
            
            -- 1. 饰品: 鲁莽激活
            if NCF.burstModeEnabled and hasRecklessness then
				if NCF.enablePotion then 
					NCF.UseCombatPotion()
				end
				NCF.UseTrinket()
                local racialSpell = NCF.GetRacialSpell()
                if racialSpell and IsReady(racialSpell) then
                    return "spell", racialSpell
                end
            end
            
            -- 2. 天神下凡: 鲁莽激活
            if HasTalent(TALENT.Avatar) and NCF.MeetsSpellTTD(SPELL.Avatar) and hasRecklessness and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 3. 鲁莽
            if NCF.MeetsSpellTTD(SPELL.Recklessness) and IsReady(SPELL.Recklessness) and not ShouldSkipSpell(SPELL.Recklessness) then
                return "spell", SPELL.Recklessness
            end
            
            -- 4. 剑刃风暴: 有激怒buff 且 鲁莽CD > 15秒
            if HasTalent(TALENT.Bladestorm) and NCF.MeetsSpellTTD(SPELL.Bladestorm) and hasEnrage and recklessnessCD > 15 and IsReady(SPELL.Bladestorm) and not ShouldSkipSpell(SPELL.Bladestorm) then
                return "spell", SPELL.Bladestorm
            end
            
            -- 5. 暴怒: 无激怒buff 或 激怒剩余时间 < GCD 或 怒气 > 100
            if rage >= 80 and (not hasEnrage or enrageRemain < gcd or rage > 100) and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
            
            -- 6. 斩杀: (2层猝死buff 或 猝死剩余时间 < GCD) 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                if suddenDeathStacks >= 2 or (hasSuddenDeath and suddenDeathRemain < gcd) then
                    local execTarget = FindExecuteTarget()
                    if execTarget then
                        return "InstantSpell", executeID, execTarget
                    elseif UnitExists("target") and not UnitIsDead("target") then
                        return "InstantSpell", executeID, "target"
                    end
                end
            end
            
            -- 7. 斩杀: 目标处于斩杀阶段 且 斩杀CD就绪
            if IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                end
            end
            
            -- 8. 奥丁之怒: 有浴血之躯buff
            if HasTalent(TALENT.OdynsWrath) and NCF.MeetsSpellTTD(SPELL.OdynsWrath) and hasBloodCraze and IsReady(SPELL.OdynsWrath) and not ShouldSkipSpell(SPELL.OdynsWrath) then
                return "spell", SPELL.OdynsWrath
            end
            
            -- 9. 嗜血: 无浴血之躯buff
            if not hasBloodCraze and IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 10. 怒击: 无蛮力爆发buff
            if not hasBrutalFervor and IsReady(SPELL.RagingBlow) and not ShouldSkipSpell(SPELL.RagingBlow) then
                return "spell", SPELL.RagingBlow
            end
            
            -- 11. 斩杀: 有猝死buff 且 斩杀CD就绪
            if hasSuddenDeath and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                elseif UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end

            -- 13. 怒击 (填充)
            if IsReady(SPELL.RagingBlow) and not ShouldSkipSpell(SPELL.RagingBlow) then
                return "spell", SPELL.RagingBlow
            end

            -- 14. 撕裂: 目标没有撕裂debuff
            if not hasRend and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 15. 嗜血 (填充)
            if IsReady(SPELL.Bloodthirst) and not ShouldSkipSpell(SPELL.Bloodthirst) then
                return "spell", SPELL.Bloodthirst
            end
            
            -- 16. 暴怒 (填充)
            if rage >= 80 and IsReady(SPELL.Rampage) and not ShouldSkipSpell(SPELL.Rampage) then
                return "spell", SPELL.Rampage
            end
                    
            -- 17. 碎裂投掷 (填充, 需要天赋)
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
            
            -- 18. 旋风斩 (填充)
            if IsReady(SPELL.Whirlwind) and not ShouldSkipSpell(SPELL.Whirlwind) then
                return "spell", SPELL.Whirlwind
            end
        end
        
        end -- 无情强袭分支结束
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateFuryRotation()