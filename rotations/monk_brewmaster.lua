--============================================================
-- 酒仙武僧循环 (Brewmaster Monk APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表:

0.  打断 - 切喉手 (116705): 5码, 需面朝

--- 战斗门槛: 自己战斗中 或 目标战斗中 ---

1.  活血酒 (119582): charges=2 且 血量<92%
2.  活血酒 (119582): 有重度醉酿(124273) debuff
3.  活血酒 (119582): 有强化醉拳(1260619) buff [需天赋:坚定不屈196737]
4.  活血酒 (119582): 血量<35% 且 charges>1
5.  玄牛酒 (115399): 活血酒charges<0.7 且 血量<30% [需天赋check]
6.  醉酿投 (121253): 距离8-25码 且 能量>=60 (拉怪)
7.  玄牛下凡 (132578): TTD达标
8.  轮回之触 (322109): 5码内敌人血量<=自身最大生命值
9.  幻灭踢 (205523): 没有醒酒buff(215479) (接怪)
10. 天神酒 (322507) [需天赋check]
11. 天神灌注 (1241059) [需天赋check]
12. 火焰之息 (115181) [需天赋check]
13. 爆炸酒桶 (325153): 醉酿投充能<2 [需天赋check]
14. 真气爆裂 (123986)
15. 醉酿投 (121253): 幻灭连击buff 且 能量>=40
16. 猛虎掌 (100780): 幻灭连击buff 且 醉酿投充能<1 且 能量>=25
17. 幻灭踢 (205523): 常规
18. 醉酿投 (121253): 能量>=40

Buff ID:
- 幻灭连击: 228563
- 醒酒: 215479
- 强化醉拳: 1260619

Debuff ID:
- 重度醉酿: 124273
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("MONK", 1, {
    -- 爆发技能
    { id = 132578, name = "玄牛下凡", default = "burst" },
    
    -- 普通技能
    { id = 116705, name = "切喉手", default = "normal" },
    { id = 119582, name = "活血酒", default = "normal" },
    { id = 115399, name = "玄牛酒", default = "normal" },
    { id = 322507, name = "天神酒", default = "normal" },
    { id = 1241059, name = "天神灌注", default = "normal" },
    { id = 115181, name = "火焰之息", default = "normal" },
    { id = 325153, name = "爆炸酒桶", default = "normal" },
    { id = 121253, name = "醉酿投", default = "normal" },
    { id = 100780, name = "猛虎掌", default = "normal" },
    { id = 205523, name = "幻灭踢", default = "normal" },
    { id = 322109, name = "轮回之触", default = "normal" },
    { id = 123986, name = "真气爆裂", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    SpearHandStrike = 116705,      -- 切喉手 (打断)
    PurifyingBrew = 119582,        -- 活血酒
    FortifyingBrew = 115399,       -- 玄牛酒
    InvokeNiuzao = 132578,         -- 玄牛下凡
    TouchOfDeath = 322109,         -- 轮回之触
    CelestialBrew = 322507,        -- 天神酒
    CelestialConduit = 1241059,    -- 天神灌注
    BreathOfFire = 115181,         -- 火焰之息
    ExplodingKeg = 325153,         -- 爆炸酒桶
    ChiBurst = 123986,             -- 真气爆裂
    KegSmash = 121253,             -- 醉酿投
    TigerPalm = 100780,            -- 猛虎掌
    BlackoutKick = 205523,         -- 幻灭踢
}

--============================================================
-- 3. Buff/Debuff ID定义
--============================================================
local BUFF = {
    BlackoutCombo = 228563,        -- 幻灭连击
    Sober = 215479,                -- 醒酒
    ElusiveBrawler = 1260619,      -- 强化醉拳
}

local DEBUFF = {
    HeavyStagger = 124273,         -- 重度醉酿
}

-- 天赋ID
local TALENT = {
    Stormstouts = 196737,          -- 坚定不屈 (触发强化醉拳)
    FortifyingBrew = 115399,       -- 玄牛酒
    CelestialBrew = 322507,        -- 天神酒
    CelestialConduit = 1241059,    -- 天神灌注
    BreathOfFire = 115181,         -- 火焰之息
    ExplodingKeg = 325153,         -- 爆炸酒桶
}

--============================================================
-- 4. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
local GetBuffStacks = NCF.GetBuffStacks
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local GetDistanceToTarget = NCF.GetDistanceToTarget
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount

--============================================================
-- 5. 主循环
--============================================================
local function CreateBrewmasterRotation()

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local energy = NCF.GetUnitPower("player", "energy")
        local distance = GetDistanceToTarget("target")
        local playerHP = NCF.GetUnitHealthPct("player")
        local purifyCharges = GetSpellCharges(SPELL.PurifyingBrew)
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 0. 打断: 切喉手 5码 需面朝
        if IsReady(SPELL.SpearHandStrike) and not ShouldSkipSpell(SPELL.SpearHandStrike) then
            local interruptTarget = NCF.GetInterruptTarget(5, true)
            if interruptTarget then
                return "spell", SPELL.SpearHandStrike, interruptTarget
            end
        end
        
        -- 以下需要战斗中才执行 (自己战斗中 或 目标战斗中)
        local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
        if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
        end
        
        --[[ 1. 活血酒: charges=2 且 血量<92%
        if purifyCharges >= 2 and playerHP < 92 and IsReady(SPELL.PurifyingBrew) and not ShouldSkipSpell(SPELL.PurifyingBrew) then
            return "spell", SPELL.PurifyingBrew
        end]]
        
        -- 2. 活血酒: 有重度醉酿 debuff
        if HasDebuff(DEBUFF.HeavyStagger, "player") and IsReady(SPELL.PurifyingBrew) and not ShouldSkipSpell(SPELL.PurifyingBrew) then
            return "spell", SPELL.PurifyingBrew
        end
        
        -- 3. 活血酒: 有强化醉拳 buff [需天赋:坚定不屈]
        if HasTalent(TALENT.Stormstouts) and HasBuff(BUFF.ElusiveBrawler) and IsReady(SPELL.PurifyingBrew) and not ShouldSkipSpell(SPELL.PurifyingBrew) then
            return "spell", SPELL.PurifyingBrew
        end
        
        -- 4. 活血酒: 血量<35% 且 charges>1
        if playerHP < 35 and purifyCharges > 1 and IsReady(SPELL.PurifyingBrew) and not ShouldSkipSpell(SPELL.PurifyingBrew) then
            return "spell", SPELL.PurifyingBrew
        end
        
        -- 5. 玄牛酒: 活血酒charges<0.7 且 血量<30% [需天赋]
        if HasTalent(TALENT.FortifyingBrew) and purifyCharges < 0.7 and playerHP < 30 and IsReady(SPELL.FortifyingBrew) and not ShouldSkipSpell(SPELL.FortifyingBrew) then
            return "spell", SPELL.FortifyingBrew
        end
        
        -- 6. 醉酿投: 距离8-25码 且 能量>=60 (拉怪)
        if distance > 8 and distance <= 25 and energy >= 60 and IsReady(SPELL.KegSmash) and not ShouldSkipSpell(SPELL.KegSmash) then
            return "spell", SPELL.KegSmash
        end
        
        -- 7. 玄牛下凡: TTD达标
        if NCF.MeetsSpellTTD(SPELL.InvokeNiuzao) and IsReady(SPELL.InvokeNiuzao) and not ShouldSkipSpell(SPELL.InvokeNiuzao) then
            return "spell", SPELL.InvokeNiuzao
        end
        
        -- 8. 轮回之触: 5码内敌人血量<=自身最大生命值
        if IsReady(SPELL.TouchOfDeath) and not ShouldSkipSpell(SPELL.TouchOfDeath) then
            local myMaxHP = UnitHealthMax("player")
            local objects = Objects()
            if objects then
                for i = 1, #objects do
                    local obj = objects[i]
                    if ObjectType(obj) == 5 and UnitCanAttack("player", obj) and not UnitIsDead(obj) then
                        local dist = Distance("player", obj) - CombatReach("player") - CombatReach(obj)
                        if dist <= 5 then
                            local hp = UnitHealth(obj)
                            if IsMidnight then hp = secretunwrap(hp) end
                            if hp and hp <= myMaxHP then
                                return "InstantSpell", SPELL.TouchOfDeath, obj
                            end
                        end
                    end
                end
            end
        end
        
        -- 9. 幻灭踢: 没有醒酒buff (接怪)
        if not HasBuff(BUFF.Sober) and IsReady(SPELL.BlackoutKick) and not ShouldSkipSpell(SPELL.BlackoutKick) then
            return "spell", SPELL.BlackoutKick
        end
        
        -- 10. 天神酒 [需天赋]
        if HasTalent(TALENT.CelestialBrew) and IsReady(SPELL.CelestialBrew) and not ShouldSkipSpell(SPELL.CelestialBrew) then
            return "spell", SPELL.CelestialBrew
        end
        
        -- 11. 天神灌注 [需天赋]
        if HasTalent(TALENT.CelestialConduit) and IsReady(SPELL.CelestialConduit) and not ShouldSkipSpell(SPELL.CelestialConduit) then
            return "spell", SPELL.CelestialConduit
        end
        
        -- 12. 火焰之息 [需天赋]
        if HasTalent(TALENT.BreathOfFire) and IsReady(SPELL.BreathOfFire) and not ShouldSkipSpell(SPELL.BreathOfFire) then
            return "spell", SPELL.BreathOfFire
        end
        
        -- 13. 爆炸酒桶: 醉酿投充能<2 [需天赋]
        if HasTalent(TALENT.ExplodingKeg) and GetSpellCharges(SPELL.KegSmash) < 2 and IsReady(SPELL.ExplodingKeg) and not ShouldSkipSpell(SPELL.ExplodingKeg) then
            return "spell", SPELL.ExplodingKeg
        end
        
        -- 14. 真气爆裂
        if IsReady(SPELL.ChiBurst) and not ShouldSkipSpell(SPELL.ChiBurst) then
            return "spell", SPELL.ChiBurst
        end
        
        -- 15. 醉酿投: 幻灭连击buff 且 能量>=40
        if HasBuff(BUFF.BlackoutCombo) and energy >= 40 and IsReady(SPELL.KegSmash) and not ShouldSkipSpell(SPELL.KegSmash) then
            return "spell", SPELL.KegSmash
        end
        
        -- 16. 猛虎掌: 幻灭连击buff 且 醉酿投充能<1 且 能量>=25
        if HasBuff(BUFF.BlackoutCombo) and GetSpellCharges(SPELL.KegSmash) < 1 and energy >= 25 and IsReady(SPELL.TigerPalm) and not ShouldSkipSpell(SPELL.TigerPalm) then
            return "spell", SPELL.TigerPalm
        end
        
        -- 17. 幻灭踢: 常规
        if IsReady(SPELL.BlackoutKick) and not ShouldSkipSpell(SPELL.BlackoutKick) then
            return "spell", SPELL.BlackoutKick
        end
        
        -- 18. 醉酿投: 能量>=40
        if energy >= 40 and IsReady(SPELL.KegSmash) and not ShouldSkipSpell(SPELL.KegSmash) then
            return "spell", SPELL.KegSmash
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateBrewmasterRotation()