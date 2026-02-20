--============================================================
-- 武器战士循环 (Arms Warrior APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--
-- 天赋分支:
-- - 巨人威仪 (429636): 已实现
-- - 无情强袭 (444780): 已实现
--============================================================

--[[
优先级列表：

0.   打断 - 拳击 (6552): 5码, 需面朝
0.1  冲锋 (100): 距离 8-25 码

=== 斩杀阶段判断 ===
有毁灭天赋(281001): 血量 < 35%
无毁灭天赋: 血量 < 20%

=== 饰品 ===
天神下凡激活 且 巨人打击CD < 3秒

=== AOE 循环 (敌人 > 1) ===
1.  横扫攻击 (260708): (buff未激活 且 巨人打击CD > 7 且 有巨人送横扫天赋) 或 (buff未激活 且 无巨人送横扫天赋)
2.  撕裂 (388539): 目标没有撕裂debuff 且 怒气 >= 20
3.  天神下凡 (107574): 灭战者CD < 2秒
4.  灭战者 (167105)
5.  崩摧 (436358)
6.  破坏者 (228920): 目标有巨人打击易伤buff
7.  顺劈斩 (845): 怒气 >= 20
8.  致死打击 (12294): 怒气 >= 30
9.  压制 (7384)
10. 撕裂 (388539): 可刷新 (剩余 < 5秒) 且 怒气 >= 20
11. 斩杀 (163201): (目标处于斩杀阶段 或 有猝死buff) 且 斩杀CD就绪 且 怒气 >= 20
12. 碎裂投掷 (64382): 需天赋
13. 撕裂 (388539): 填充 且 怒气 >= 20

=== 单体斩杀循环 (敌人 = 1 且 斩杀阶段) ===
1.  破坏者 (228920): 灭战者CD < 2秒
2.  天神下凡 (107574): 灭战者CD < 2秒
3.  灭战者 (167105)
4.  崩摧 (436358)
5.  致死打击 (12294): 有2层处决者精准buff 且 怒气 >= 30
6.  压制 (7384): 怒气 < 90
7.  斩杀 (163201): 目标处于斩杀阶段 且 斩杀CD就绪 且 怒气 >= 20
8.  碎裂投掷 (64382): 需天赋

=== 单体非斩杀循环 (敌人 = 1 且 非斩杀阶段) ===
1.  撕裂 (388539): 目标没有撕裂debuff 且 怒气 >= 20
2.  破坏者 (228920): 灭战者CD < 2秒
3.  天神下凡 (107574): 灭战者CD < 2秒
4.  灭战者 (167105)
5.  崩摧 (436358)
6.  压制 (7384): 2层充能 且 怒气 >= 80
7.  致死打击 (12294): 怒气 >= 30
8.  压制 (7384)
9.  斩杀 (163201): 有猝死buff 且 怒气 >= 20
10. 碎裂投掷 (64382): 需天赋
11. 撕裂 (388539): 可刷新 (剩余 < 5秒) 且 怒气 >= 20
12. 猛击 (1464): 怒气 > 30

Buff ID 参考:
- 猝死: 52437
- 处决者精准: 386633
- 横扫攻击: 260708
- 天神下凡: 107574

Debuff ID 参考:
- 撕裂: 388539
- 巨人打击易伤: 208086
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("WARRIOR", 1, {
    -- 冷却技能
    { id = 107574, name = "天神下凡", default = "burst" },
    { id = 167105, name = "巨人打击", default = "burst" },
    { id = 227847, name = "剑刃风暴", default = "burst" },
    
    -- 普通技能
    { id = 100, name = "冲锋", default = "normal" },
    { id = 260708, name = "横扫攻击", default = "normal" },
    { id = 388539, name = "撕裂", default = "normal" },
    { id = 436358, name = "崩摧", default = "normal" },
    { id = 228920, name = "破坏者", default = "normal" },
    { id = 845, name = "顺劈斩", default = "normal" },
    { id = 12294, name = "致死打击", default = "normal" },
    { id = 7384, name = "压制", default = "normal" },
    { id = 163201, name = "斩杀", default = "normal" },
    { id = 64382, name = "碎裂投掷", default = "normal" },
    { id = 1464, name = "猛击", default = "normal" },
    { id = 6552, name = "拳击", default = "normal" },
    { id = 6673, name = "攻强", default = "normal" },

})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Charge = 100,               -- 冲锋
    Avatar = 107574,            -- 天神下凡
    ColossusSmash = 167105,     -- 巨人打击
    SweepingStrikes = 260708,   -- 横扫攻击
    Rend = 772,              	-- 撕裂
    Demolish = 436358,          -- 崩摧
    Skullsplitter = 228920,     -- 破坏者
    Cleave = 845,               -- 顺劈斩
    MortalStrike = 12294,       -- 致死打击
    Overpower = 7384,           -- 压制
    Execute = 281000,           -- 斩杀 (毁灭天赋)
    ExecuteBase = 163201,       -- 斩杀 (无毁灭天赋)
    ShatteringThrow = 64382,    -- 碎裂投掷
    Slam = 1464,                -- 猛击
    Pummel = 6552,              -- 拳击
    Bladestorm = 227847,        -- 剑刃风暴
	BattleCry = 6673,
}

--============================================================
-- 3. 天赋ID定义
--============================================================
local TALENT = {
    Massacre = 281001,          -- 毁灭 (斩杀阈值提升到35%)
    ShatteringThrow = 64382,    -- 碎裂投掷
    Skullsplitter = 228920,     -- 破坏者
    ColossalSweep = 1261049,    -- 巨人送横扫
    Bladestorm = 227847,        -- 剑刃风暴
    Cleave = 845,               -- 顺劈斩
    
    -- 天赋分支
    ColossusSmash = 429636,     -- 巨人威仪 (巨人打击分支)
    RelentlessAssault = 444780, -- 无情强袭 (无情强袭分支)
}

--============================================================
-- 4. Buff ID定义
--============================================================
local BUFF = {
    SuddenDeath = 52437,            -- 猝死
    ExecutionersPrecision = 386633, -- 处决者精准
    SweepingStrikes = 260708,       -- 横扫攻击
    Avatar = 107574,                -- 天神下凡
	BattleCry = 6673,
}

--============================================================
-- 5. Debuff ID定义
--============================================================
local DEBUFF = {
    Rend = 388539,              -- 撕裂
    ColossusSmash = 208086,     -- 巨人打击易伤
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetDebuffRemain = NCF.GetDebuffRemain
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

-- 获取正确的斩杀技能ID (根据是否有毁灭天赋)
local function GetExecuteSpellID()
    if HasTalent(TALENT.Massacre) then
        return SPELL.Execute  -- 281000
    else
        return SPELL.ExecuteBase  -- 163201
    end
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateArmsRotation()

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
        local hasSuddenDeath = HasBuff(BUFF.SuddenDeath, "player")
        local hasRend = HasDebuff(DEBUFF.Rend, "target")
        local hasColossusSmash = HasDebuff(DEBUFF.ColossusSmash, "target")
        local avatarCD = GetSpellCooldownRemain(SPELL.Avatar)
        local colossusCD = GetSpellCooldownRemain(SPELL.ColossusSmash)
        local rendRemain = GetDebuffRemain(DEBUFF.Rend, "target")
        local executionerStacks = GetBuffStacks(BUFF.ExecutionersPrecision, "player")
        local overpowerCharges = GetSpellCharges(SPELL.Overpower)
        local inExecutePhase = IsExecutePhase("target")
        
        -- 获取正确的斩杀ID
        local executeID = GetExecuteSpellID()
        
        -- 0. 打断: 拳击 5码 需面朝
        if IsReady(SPELL.Pummel) and not ShouldSkipSpell(SPELL.Pummel) then
            local interruptTarget = NCF.GetInterruptTarget(5, true)
            if interruptTarget then
                return "InstantSpell", SPELL.Pummel, interruptTarget
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
	
        -- 0.1 冲锋: 距离 8-25 码
        local distance = GetDistanceToTarget()
        if distance > 8 and distance < 25 and IsReady(SPELL.Charge) and not ShouldSkipSpell(SPELL.Charge) then
            return "spell", SPELL.Charge
        end
        
        -- 饰品: 天神下凡激活 且 巨人打击CD < 3秒
        local hasAvatar = HasBuff(BUFF.Avatar, "player")
        if NCF.burstModeEnabled and hasAvatar and colossusCD < 3 then
            if NCF.enablePotion then 
				NCF.UseCombatPotion()
			end
            NCF.UseTrinket()
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end
        
        --==========================================================
        -- 巨人威仪天赋分支
        --==========================================================
        if HasTalent(TALENT.ColossusSmash) then
        
        --==========================================================
        -- AOE 循环 (敌人 > 1)
        --==========================================================
        if enemyCount > 1 then
            -- 1. 横扫攻击: (buff未激活 且 巨人打击CD > 7 且 有巨人送横扫天赋) 或 (buff未激活 且 无巨人送横扫天赋)
            if not HasBuff(BUFF.SweepingStrikes, "player") and IsReady(SPELL.SweepingStrikes) and not ShouldSkipSpell(SPELL.SweepingStrikes) then
                if (HasTalent(TALENT.ColossalSweep) and colossusCD > 7) or not HasTalent(TALENT.ColossalSweep) then
                    return "spell", SPELL.SweepingStrikes
                end
            end
            
            -- 2. 撕裂: 目标没有撕裂debuff 且 怒气 >= 20
            if not hasRend and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 3. 天神下凡: 巨人打击CD < 2秒
            if NCF.MeetsSpellTTD(SPELL.Avatar) and colossusCD < 2 and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 4. 巨人打击
            if NCF.MeetsSpellTTD(SPELL.ColossusSmash) and IsReady(SPELL.ColossusSmash) and not ShouldSkipSpell(SPELL.ColossusSmash) then
                return "spell", SPELL.ColossusSmash
            end
            
            -- 5. 崩摧
            if NCF.MeetsSpellTTD(SPELL.Demolish) and IsReady(SPELL.Demolish) and not ShouldSkipSpell(SPELL.Demolish) then
                return "spell", SPELL.Demolish
            end
            
            -- 6. 破坏者: 目标有巨人打击易伤buff
            if HasTalent(TALENT.Skullsplitter) and NCF.MeetsSpellTTD(SPELL.Skullsplitter) and hasColossusSmash and IsReady(SPELL.Skullsplitter) and not ShouldSkipSpell(SPELL.Skullsplitter) then
                return "spell", SPELL.Skullsplitter
            end
            
            -- 7. 顺劈斩: 怒气 >= 20
            if HasTalent(TALENT.Cleave) and rage >= 20 and IsReady(SPELL.Cleave) and not ShouldSkipSpell(SPELL.Cleave) then
                return "spell", SPELL.Cleave
            end
            
            -- 8. 致死打击: 怒气 >= 30
            if rage >= 30 and IsReady(SPELL.MortalStrike) and not ShouldSkipSpell(SPELL.MortalStrike) then
                return "spell", SPELL.MortalStrike
            end
            
            -- 9. 压制
            if IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 10. 撕裂: 可刷新 (剩余 < 5秒) 且 怒气 >= 20
            if rendRemain > 0 and rendRemain < 5 and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 11. 斩杀: (目标处于斩杀阶段 或 有猝死buff) 且 斩杀CD就绪 怒气 >= 20
            if rage >= 20 and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                if hasSuddenDeath then
                    local execTarget = FindExecuteTarget()
                    if execTarget then
                        return "InstantSpell", executeID, execTarget
                    elseif UnitExists("target") and not UnitIsDead("target") then
                        return "InstantSpell", executeID, "target"
                    end
                else
                    local execTarget = FindExecuteTarget()
                    if execTarget then
                        return "InstantSpell", executeID, execTarget
                    end
                end
            end
            
            -- 12. 碎裂投掷: 需天赋
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
            
            -- 13. 撕裂: 填充 且 怒气 >= 20
            if rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
        
        --==========================================================
        -- 单体斩杀循环 (敌人 = 1 且 斩杀阶段)
        --==========================================================
        elseif inExecutePhase then
            -- 1. 破坏者: 巨人打击CD < 2秒
            if HasTalent(TALENT.Skullsplitter) and NCF.MeetsSpellTTD(SPELL.Skullsplitter) and colossusCD < 2 and IsReady(SPELL.Skullsplitter) and not ShouldSkipSpell(SPELL.Skullsplitter) then
                return "spell", SPELL.Skullsplitter
            end
            
            -- 2. 天神下凡: 巨人打击CD < 2秒
            if NCF.MeetsSpellTTD(SPELL.Avatar) and colossusCD < 2 and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 3. 巨人打击
            if NCF.MeetsSpellTTD(SPELL.ColossusSmash) and IsReady(SPELL.ColossusSmash) and not ShouldSkipSpell(SPELL.ColossusSmash) then
                return "spell", SPELL.ColossusSmash
            end
            
            -- 4. 崩摧
            if NCF.MeetsSpellTTD(SPELL.Demolish) and IsReady(SPELL.Demolish) and not ShouldSkipSpell(SPELL.Demolish) then
                return "spell", SPELL.Demolish
            end
            
            -- 5. 致死打击: 有2层处决者精准buff 且 怒气 >= 30
            if executionerStacks >= 2 and rage >= 30 and IsReady(SPELL.MortalStrike) and not ShouldSkipSpell(SPELL.MortalStrike) then
                return "spell", SPELL.MortalStrike
            end
            
            -- 6. 压制: 怒气 < 90
            if rage < 90 and IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 7. 斩杀: 目标处于斩杀阶段 且 斩杀CD就绪
            if rage >= 20 and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                elseif UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end
            
            -- 8. 碎裂投掷: 需天赋
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
        
        --==========================================================
        -- 单体非斩杀循环 (敌人 = 1 且 非斩杀阶段)
        --==========================================================
        else
            -- 1. 撕裂: 目标没有撕裂debuff 且 怒气 >= 20
            if not hasRend and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 2. 破坏者: 巨人打击CD < 2秒
            if HasTalent(TALENT.Skullsplitter) and NCF.MeetsSpellTTD(SPELL.Skullsplitter) and colossusCD < 2 and IsReady(SPELL.Skullsplitter) and not ShouldSkipSpell(SPELL.Skullsplitter) then
                return "spell", SPELL.Skullsplitter
            end
            
            -- 3. 天神下凡: 巨人打击CD < 2秒
            if NCF.MeetsSpellTTD(SPELL.Avatar) and colossusCD < 2 and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 4. 巨人打击
            if NCF.MeetsSpellTTD(SPELL.ColossusSmash) and IsReady(SPELL.ColossusSmash) and not ShouldSkipSpell(SPELL.ColossusSmash) then
                return "spell", SPELL.ColossusSmash
            end
            
            -- 5. 崩摧
            if NCF.MeetsSpellTTD(SPELL.Demolish) and IsReady(SPELL.Demolish) and not ShouldSkipSpell(SPELL.Demolish) then
                return "spell", SPELL.Demolish
            end
            
            -- 6. 压制: 2层充能 且 怒气 >= 80
            if overpowerCharges >= 2 and rage >= 80 and IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 7. 致死打击: 怒气 >= 30
            if rage >= 30 and IsReady(SPELL.MortalStrike) and not ShouldSkipSpell(SPELL.MortalStrike) then
                return "spell", SPELL.MortalStrike
            end
            
            -- 8. 压制
            if IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 9. 斩杀: 有猝死buff 且 怒气 >= 20
            if hasSuddenDeath and rage >= 20 and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                if UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end
            
            -- 10. 碎裂投掷: 需天赋
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
            
            -- 11. 撕裂: 可刷新 (剩余 < 5秒) 且 怒气 >= 20
            if rendRemain > 0 and rendRemain < 5 and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 12. 猛击: 怒气 > 30
            if rage > 30 and IsReady(SPELL.Slam) and not ShouldSkipSpell(SPELL.Slam) then
                return "spell", SPELL.Slam
            end
        end
        
        end -- 巨人威仪天赋分支结束
        
        --==========================================================
        -- 无情强袭天赋分支
        --==========================================================
        if HasTalent(TALENT.RelentlessAssault) then
        
        --==========================================================
        -- AOE 循环 (敌人 > 1)
        --==========================================================
        if enemyCount > 1 then
            -- 1. 撕裂: 8码内有目标没有撕裂debuff 且 怒气 >= 20
            if rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                local rendTarget = NCF.GetEnemyWithoutDebuff(DEBUFF.Rend, 8, false)
                if rendTarget then
                    return "InstantSpell", SPELL.Rend, rendTarget
                end
            end
            
            -- 2. 横扫攻击: (buff未激活 且 巨人打击CD > 7 且 有巨人送横扫天赋) 或 (buff未激活 且 无巨人送横扫天赋)
            if not HasBuff(BUFF.SweepingStrikes, "player") and IsReady(SPELL.SweepingStrikes) and not ShouldSkipSpell(SPELL.SweepingStrikes) then
                if (HasTalent(TALENT.ColossalSweep) and colossusCD > 7) or not HasTalent(TALENT.ColossalSweep) then
                    return "spell", SPELL.SweepingStrikes
                end
            end
            
            -- 3. 天神下凡: 巨人打击CD < 2秒
            if NCF.MeetsSpellTTD(SPELL.Avatar) and colossusCD < 2 and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 4. 巨人打击
            if NCF.MeetsSpellTTD(SPELL.ColossusSmash) and IsReady(SPELL.ColossusSmash) and not ShouldSkipSpell(SPELL.ColossusSmash) then
                return "spell", SPELL.ColossusSmash
            end
            
            -- 5. 剑刃风暴: 目标有巨人打击易伤buff
            if HasTalent(TALENT.Bladestorm) and NCF.MeetsSpellTTD(SPELL.Bladestorm) and hasColossusSmash and IsReady(SPELL.Bladestorm) and not ShouldSkipSpell(SPELL.Bladestorm) then
                return "spell", SPELL.Bladestorm
            end
            
            -- 6. 顺劈斩: 怒气 >= 20
            if HasTalent(TALENT.Cleave) and rage >= 20 and IsReady(SPELL.Cleave) and not ShouldSkipSpell(SPELL.Cleave) then
                return "spell", SPELL.Cleave
            end
            
            -- 7. 致死打击: 怒气 >= 30
            if rage >= 30 and IsReady(SPELL.MortalStrike) and not ShouldSkipSpell(SPELL.MortalStrike) then
                return "spell", SPELL.MortalStrike
            end
            
            -- 8. 压制
            if IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 9. 撕裂: 刷新 (剩余 < 4秒) 且 怒气 >= 20
            if rendRemain > 0 and rendRemain < 4 and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 10. 斩杀: 斩杀CD就绪 且 怒气 >= 20
            if rage >= 20 and IsReady(executeID) and not ShouldSkipSpell(executeID) then
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
            
            -- 11. 碎裂投掷: 需天赋
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
            
            -- 12. 撕裂: 极限刷新 (剩余 < GCD) 且 怒气 >= 20
            if rendRemain > 0 and rendRemain < gcd and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
        
        --==========================================================
        -- 单体斩杀循环 (敌人 = 1 且 斩杀阶段)
        --==========================================================
        elseif inExecutePhase then
            -- 1. 天神下凡: 巨人打击CD < 2秒
            if NCF.MeetsSpellTTD(SPELL.Avatar) and colossusCD < 2 and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 2. 巨人打击
            if NCF.MeetsSpellTTD(SPELL.ColossusSmash) and IsReady(SPELL.ColossusSmash) and not ShouldSkipSpell(SPELL.ColossusSmash) then
                return "spell", SPELL.ColossusSmash
            end
            
            -- 3. 剑刃风暴: 巨人打击易伤激活 且 2层处决者精准
            if HasTalent(TALENT.Bladestorm) and NCF.MeetsSpellTTD(SPELL.Bladestorm) and hasColossusSmash and executionerStacks >= 2 and IsReady(SPELL.Bladestorm) and not ShouldSkipSpell(SPELL.Bladestorm) then
                return "spell", SPELL.Bladestorm
            end
            
            -- 4. 致死打击: 2层处决者精准 且 怒气 >= 30
            if executionerStacks >= 2 and rage >= 30 and IsReady(SPELL.MortalStrike) and not ShouldSkipSpell(SPELL.MortalStrike) then
                return "spell", SPELL.MortalStrike
            end
            
            -- 5. 压制: 怒气 < 60
            if rage < 60 and IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 6. 斩杀: 斩杀CD就绪 且 怒气 >= 20
            if rage >= 20 and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                local execTarget = FindExecuteTarget()
                if execTarget then
                    return "InstantSpell", executeID, execTarget
                elseif UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end
            
            -- 7. 碎裂投掷: 需天赋
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
        
        --==========================================================
        -- 单体非斩杀循环 (敌人 = 1 且 非斩杀阶段)
        --==========================================================
        else
            -- 1. 撕裂: 目标没有撕裂debuff 且 怒气 >= 20
            if not hasRend and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 2. 天神下凡: 巨人打击CD < 2秒
            if NCF.MeetsSpellTTD(SPELL.Avatar) and colossusCD < 2 and IsReady(SPELL.Avatar) and not ShouldSkipSpell(SPELL.Avatar) then
                return "spell", SPELL.Avatar
            end
            
            -- 3. 巨人打击
            if NCF.MeetsSpellTTD(SPELL.ColossusSmash) and IsReady(SPELL.ColossusSmash) and not ShouldSkipSpell(SPELL.ColossusSmash) then
                return "spell", SPELL.ColossusSmash
            end
            
            -- 4. 致死打击: 怒气 >= 30
            if rage >= 30 and IsReady(SPELL.MortalStrike) and not ShouldSkipSpell(SPELL.MortalStrike) then
                return "spell", SPELL.MortalStrike
            end
            
            -- 5. 剑刃风暴: 目标有巨人打击易伤buff
            if HasTalent(TALENT.Bladestorm) and NCF.MeetsSpellTTD(SPELL.Bladestorm) and hasColossusSmash and IsReady(SPELL.Bladestorm) and not ShouldSkipSpell(SPELL.Bladestorm) then
                return "spell", SPELL.Bladestorm
            end
            
            -- 6. 斩杀: 有猝死buff 且 斩杀CD就绪 且 怒气 >= 20
            if hasSuddenDeath and rage >= 20 and IsReady(executeID) and not ShouldSkipSpell(executeID) then
                if UnitExists("target") and not UnitIsDead("target") then
                    return "InstantSpell", executeID, "target"
                end
            end
            
            -- 7. 压制
            if IsReady(SPELL.Overpower) and not ShouldSkipSpell(SPELL.Overpower) then
                return "spell", SPELL.Overpower
            end
            
            -- 8. 撕裂: 刷新 (剩余 < 5秒) 且 怒气 >= 20
            if rendRemain > 0 and rendRemain < 5 and rage >= 20 and IsReady(SPELL.Rend) and not ShouldSkipSpell(SPELL.Rend) then
                return "spell", SPELL.Rend
            end
            
            -- 9. 碎裂投掷: 需天赋
            if HasTalent(TALENT.ShatteringThrow) and IsReady(SPELL.ShatteringThrow) and not ShouldSkipSpell(SPELL.ShatteringThrow) then
                return "spell", SPELL.ShatteringThrow
            end
            
            -- 10. 猛击: 怒气 > 30
            if rage > 30 and IsReady(SPELL.Slam) and not ShouldSkipSpell(SPELL.Slam) then
                return "spell", SPELL.Slam
            end
        end
        
        end -- 无情强袭天赋分支结束
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateArmsRotation()