--============================================================
-- 暗影牧师循环 (Shadow Priest APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表 (基于代码实际顺序):

--- 战前 ---
0.  真言术：韧 (21562): 没有buff时
0.1 天堂之羽 (121536): 移动超过1秒 且 没有天使羽毛buff (121557), 丢脚下

--- 战斗门槛前 ---
1.  暗影形态 (232698): 没有暗影形态buff 且 不在虚空形态

--- 战斗门槛: 自己战斗中 或 目标战斗中 ---

--- 爆发: 虚空形态中 且 爆发模式开启 ---
    饰品/药水/种族技能

--- 核心循环 ---
2.  虚空触击 (1227280): 有敌人没有双dot (暗言术痛589 + 吸血鬼之触34914)
3.  虚空齐射 (1242173): 虚空形态中
4.  能量灌注 (10060): 虚空形态中, 对自己释放
5.  虚空冲击 (450983): 有熵能裂隙buff (450193)
6.  暗言术：癫 (335467): 能量>=90 且 虚空形态中
7.  虚空洪流 (263165): 虚空形态中
8.  暗言术：癫 (335467): 能量>=45 且 虚空形态中
9.  精神鞭笞 (15407): 虚空形态中

--- 非虚空形态 ---
10. 虚空形态 (228260): TTD达标 [爆发]
11. 虚空洪流 (263165): 虚空形态CD > 15秒
12. 暗言术：癫 (335467): 能量>=45
13. 暗言术：灭 (32379): 任意目标血量<=20%
14. 心灵震爆 (8092)
15. 精神鞭笞 (15407): 填充

Buff ID:
- 暗影形态: 232698
- 天使羽毛: 121557
- 虚空形态: 194249
- 熵能裂隙: 450193
- 暗影洞察: 375981
- 真言术韧: 21562

Debuff ID:
- 暗言术痛: 589
- 吸血鬼之触: 34914
- 暗言术癫: 335467

特殊机制:
- 引导精神鞭笞时, 高优先级技能用 interrupt_and_cast 打断引导
- 精神鞭笞本身不打断自己
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("PRIEST", 3, {
    -- 爆发技能
    { id = 228260, name = "虚空形态", default = "burst" },
    
    -- 普通技能
    { id = 232698, name = "暗影形态", default = "normal" },
    { id = 1227280, name = "虚空触击", default = "normal" },
    { id = 1242173, name = "虚空齐射", default = "normal" },
    { id = 10060, name = "能量灌注", default = "normal" },
    { id = 450983, name = "虚空冲击", default = "normal" },
    { id = 335467, name = "暗言术：癫", default = "normal" },
    { id = 263165, name = "虚空洪流", default = "normal" },
    { id = 15407, name = "精神鞭笞", default = "normal" },
    { id = 8092, name = "心灵震爆", default = "normal" },
    { id = 32379, name = "暗言术：灭", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Shadowform = 232698,            -- 暗影形态
    VoidEruption = 228260,          -- 虚空形态 (进入虚空形态的技能)
    VoidTouch = 1227280,            -- 虚空触击
    VoidVolley = 1242173,           -- 虚空齐射
    PowerInfusion = 10060,          -- 能量灌注
    VoidBlast = 450983,             -- 虚空冲击
    Devouring = 335467,             -- 暗言术：癫
    VoidTorrent = 263165,           -- 虚空洪流
    MindFlay = 15407,               -- 精神鞭笞
    MindBlast = 8092,               -- 心灵震爆
    ShadowWordDeath = 32379,        -- 暗言术：灭
    PowerWordFortitude = 21562,     -- 真言术：韧
    AngelsFeather = 121536,         -- 天堂之羽
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    Shadowform = 232698,            -- 暗影形态
    Voidform = 194249,              -- 虚空形态
    EntropicRift = 450193,          -- 熵能裂隙
    ShadowInsight = 375981,         -- 暗影洞察
    PowerWordFortitude = 21562,     -- 真言术：韧
    AngelsFeather = 121557,         -- 天使羽毛
}

--============================================================
-- 4. Debuff ID定义
--============================================================
local DEBUFF = {
    ShadowWordPain = 589,           -- 暗言术痛
    VampiricTouch = 34914,          -- 吸血鬼之触
    Devouring = 335467,             -- 暗言术癫
}

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local GetDebuffRemain = NCF.GetDebuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitPower = NCF.GetUnitPower
local GetTargetHealthPct = NCF.GetTargetHealthPct
local GetUnitHealthPct = NCF.GetUnitHealthPct

local function GetInsanity()
    return GetUnitPower("player", "insanity")
end

-- 检测是否在引导精神鞭笞
local function IsChannelingMindFlay()
    local name, _, _, _, _, _, _, spellId = UnitChannelInfo("player")
    if not spellId then return false end
    
    local _, _, _, tocVersion = GetBuildInfo()
    if tocVersion >= 120000 then
        spellId = secretunwrap(spellId)
    end
    
    return spellId == SPELL.MindFlay
end

--============================================================
-- 6. 移动追踪
--============================================================
local moveStartTime = 0
local lastX, lastY, lastZ = 0, 0, 0

local function UpdateMovement()
    local x, y, z = ObjectPosition("player")
    if not x then return 0 end
    
    local moved = (x ~= lastX or y ~= lastY or z ~= lastZ)
    
    if moved then
        if moveStartTime == 0 then
            moveStartTime = GetTime()
        end
        lastX, lastY, lastZ = x, y, z
    else
        moveStartTime = 0
    end
    
    if moveStartTime > 0 then
        return GetTime() - moveStartTime
    end
    return 0
end

--============================================================
-- 7. 主循环
--============================================================
local function CreateShadowRotation()

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(40, true)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(NCF.GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local insanity = GetInsanity()
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 检查虚空形态
        local inVoidform = HasBuff(BUFF.Voidform)
        
        -- 检查是否在引导精神鞭笞 (需要打断来释放更高优先级技能)
        local channelingMindFlay = IsChannelingMindFlay()
        
        -- 如果在引导精神鞭笞，高优先级技能需要打断
        local spellType = channelingMindFlay and "interrupt_and_cast" or "spell"
        
        -- 0. 真言术：韧 (战前buff)
        if not HasBuff(BUFF.PowerWordFortitude) and IsReady(SPELL.PowerWordFortitude) then
            return spellType, SPELL.PowerWordFortitude
        end
        
        -- 0.1 天堂之羽: 移动超过1秒 且 没有天使羽毛buff
        local moveDuration = UpdateMovement()
        if moveDuration > 1 and not HasBuff(BUFF.AngelsFeather) and IsReady(SPELL.AngelsFeather) then
            return "castselflocation", SPELL.AngelsFeather
        end
        
        -- 1. 暗影形态: 没有暗影形态buff 且 不在虚空形态
        if not HasBuff(BUFF.Shadowform) and not inVoidform and IsReady(SPELL.Shadowform) and not ShouldSkipSpell(SPELL.Shadowform) then
            return spellType, SPELL.Shadowform
        end
        
        -- 战斗门槛: 自己战斗中 或 目标战斗中
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
            return "spell", 61304
        end

        -- 爆发: 虚空形态中 + 爆发模式开启 -> 饰品/药水/种族
        if NCF.burstModeEnabled and inVoidform then
            NCF.UseTrinket()
            if NCF.enablePotion then 
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end	
        end

        -- 2. 虚空触击: 有敌人没有双dot (暗言术痛+吸血鬼之触)
        if IsReady(SPELL.VoidTouch) and not ShouldSkipSpell(SPELL.VoidTouch) then
            local results = {GetActiveEnemyAmount(40, true)}
            local count = results[1]
            
            local targetWithoutDots = nil
            
            for i = 2, count + 1 do
                local unit = results[i]
                if unit then
                    local hasPain = GetDebuffRemain(DEBUFF.ShadowWordPain, unit) > 0
                    local hasVT = GetDebuffRemain(DEBUFF.VampiricTouch, unit) > 0
                    
                    if not hasPain or not hasVT then
                        targetWithoutDots = unit
                        break
                    end
                end
            end
            
            -- 也检查当前目标
            if not targetWithoutDots then
                local hasPain = HasDebuff(DEBUFF.ShadowWordPain, "target")
                local hasVT = HasDebuff(DEBUFF.VampiricTouch, "target")
                if not hasPain or not hasVT then
                    targetWithoutDots = "target"
                end
            end
            
            if targetWithoutDots then
                if targetWithoutDots == "target" then
                    return spellType, SPELL.VoidTouch
                else
                    return spellType, SPELL.VoidTouch, targetWithoutDots
                end
            end
        end
        
        -- 3. 虚空齐射: 虚空形态中
        if inVoidform and IsReady(SPELL.VoidVolley) and not ShouldSkipSpell(SPELL.VoidVolley) then
            return spellType, SPELL.VoidVolley
        end
        
        -- 4. 能量灌注: 虚空形态中, 对自己释放
        if inVoidform and IsReady(SPELL.PowerInfusion) and not ShouldSkipSpell(SPELL.PowerInfusion) then
            return spellType, SPELL.PowerInfusion, "player"
        end
        
        -- 5. 虚空冲击: 有熵能裂隙buff
        if HasBuff(BUFF.EntropicRift) and IsReady(SPELL.VoidBlast) and not ShouldSkipSpell(SPELL.VoidBlast) then
            return spellType, SPELL.VoidBlast
        end
        
        -- 6. 暗言术：癫: 能量>=90 且 虚空形态中
        if inVoidform and insanity >= 90 and IsReady(SPELL.Devouring) and not ShouldSkipSpell(SPELL.Devouring) then
            return spellType, SPELL.Devouring
        end
        
        -- 7. 虚空洪流: 虚空形态中
        if inVoidform and IsReady(SPELL.VoidTorrent) and not ShouldSkipSpell(SPELL.VoidTorrent) then
            return spellType, SPELL.VoidTorrent
        end
        
        -- 8. 暗言术：癫: 能量>=45 且 虚空形态中
        if inVoidform and insanity >= 45 and IsReady(SPELL.Devouring) and not ShouldSkipSpell(SPELL.Devouring) then
            return spellType, SPELL.Devouring
        end
        
        -- 9. 精神鞭笞: 虚空形态中 (不打断自己)
        if inVoidform and IsReady(SPELL.MindFlay) and not ShouldSkipSpell(SPELL.MindFlay) then
            return "spell", SPELL.MindFlay
        end
        
        -- 10. 虚空形态 [爆发]: TTD达标
        if NCF.MeetsSpellTTD(SPELL.VoidEruption) and IsReady(SPELL.VoidEruption) and not ShouldSkipSpell(SPELL.VoidEruption) then
            return spellType, SPELL.VoidEruption
        end
        
        -- 11. 虚空洪流: 虚空形态CD > 15秒
        if GetSpellCooldownRemain(SPELL.VoidEruption) > 15 and IsReady(SPELL.VoidTorrent) and not ShouldSkipSpell(SPELL.VoidTorrent) then
            return spellType, SPELL.VoidTorrent
        end
        
        -- 12. 暗言术：癫: 能量>=45
        if insanity >= 45 and IsReady(SPELL.Devouring) and not ShouldSkipSpell(SPELL.Devouring) then
            return spellType, SPELL.Devouring
        end
        
        -- 13. 暗言术：灭: 任意目标血量<=20% (包括身后敌人)
        if IsReady(SPELL.ShadowWordDeath) and not ShouldSkipSpell(SPELL.ShadowWordDeath) then
            -- 检查当前目标
            if GetTargetHealthPct() <= 20 then
                return spellType, SPELL.ShadowWordDeath
            end
            
            -- 检查其他敌人 (包括身后)
            local results = {GetActiveEnemyAmount(40, false)}  -- false = 不检查面朝
            local count = results[1]
            
            for i = 2, count + 1 do
                local unit = results[i]
                if unit then
                    local healthPct = GetUnitHealthPct(unit)
                    if healthPct <= 20 then
                        -- 用 InstantSpell 自动转身释放
                        return "InstantSpell", SPELL.ShadowWordDeath, unit
                    end
                end
            end
        end
        
        -- 14. 心灵震爆
        if IsReady(SPELL.MindBlast) and not ShouldSkipSpell(SPELL.MindBlast) then
            return spellType, SPELL.MindBlast
        end
        
        -- 15. 精神鞭笞 (填充, 不打断自己)
        if IsReady(SPELL.MindFlay) and not ShouldSkipSpell(SPELL.MindFlay) then
            return "spell", SPELL.MindFlay
        end
        
        return "spell", 61304
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateShadowRotation()