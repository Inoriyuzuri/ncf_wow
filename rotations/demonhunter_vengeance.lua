--============================================================
-- 复仇恶魔猎手循环 (Vengeance Demon Hunter APL)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 Nn:Require() 加载
--============================================================

--[[
优先级列表：

1.   打断 - 瓦解 (183752): 10码, 需面朝
1.1  投掷利刃 (204157): 距离 >5 且 <=40 时使用
2.   恶魔变形 (187827)
3.   怨念符咒 (390163)
4.   恶魔尖刺 (203720): 无恶魔尖刺buff(203819)时
5.   烈火烙印 (204021): 无烈火烙印buff(207771)时
5.1  破裂 (263642): 充能 > 1.8
6.   幽魂炸弹 (247454): 灵魂残片(203981) >= 5层
7.   灵魂劈裂 (228477): 幽魂炸弹CD中 且 怒气 >= 40
8.   献祭光环 (258920): 无献祭光环buff(258920)时
9.   投掷利刃 (204157): 大战刃就绪时
10.  破裂 (263642): 填充

大战刃机制:
- buff 444661 叠到20层后消耗，层数减少时投掷利刃被override为大战刃(1283344)
- 通过追踪buff层数变化检测
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("DEMONHUNTER", 2, {
    -- 爆发技能
    { id = 187827, name = "恶魔变形", default = "burst" },
    
    -- 普通技能
    { id = 183752, name = "瓦解", default = "normal" },
    { id = 204157, name = "投掷利刃", default = "normal" },
    { id = 390163, name = "怨念符咒", default = "normal" },
    { id = 203720, name = "恶魔尖刺", default = "normal" },
    { id = 204021, name = "烈火烙印", default = "normal" },
    { id = 247454, name = "幽魂炸弹", default = "normal" },
    { id = 228477, name = "灵魂劈裂", default = "normal" },
    { id = 258920, name = "献祭光环", default = "normal" },
    { id = 263642, name = "破裂", default = "normal" },
    { id = 1283344, name = "大战刃", default = "normal" },
	{ id = 212084, name = "邪能毁灭", default = "normal" },
	{ id = 204596, name = "烈焰符咒", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    Disrupt = 183752,              -- 瓦解 (打断)
    ThrowGlaive = 204157,          -- 投掷利刃
    Metamorphosis = 187827,        -- 恶魔变形
    SigilOfSpite = 390163,         -- 怨念符咒
    DemonSpikes = 203720,          -- 恶魔尖刺
    FieryBrand = 204021,           -- 烈火烙印
    Fracture = 263642,             -- 破裂
    SpiritBomb = 247454,           -- 幽魂炸弹
    SoulCleave = 228477,           -- 灵魂劈裂
    ImmolationAura = 258920,       -- 献祭光环
    EmpoweredGlaive = 1283344,     -- 大战刃 (override投掷利刃)
	FelDestruction = 212084,       -- 邪能毁灭
	HotRune = 204596, 			   --烈焰符咒
}

--============================================================
-- 3. Buff/Debuff ID定义
--============================================================
local BUFF = {
    DemonSpikes = 203819,          -- 恶魔尖刺
    FieryBrand = 207771,           -- 烈火烙印
    ImmolationAura = 258920,       -- 献祭光环
    SoulFragments = 203981,        -- 灵魂残片
    GlaiveStacks = 444661,         -- 大战刃叠层
    Metamorphosis = 187827,        -- 恶魔变形
}

--============================================================
-- 4. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local GetDebuffRemain = NCF.GetDebuffRemain
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
local function CreateVengeanceRotation()
    -- 大战刃追踪
    local lastGlaiveStacks = 0
    local empoweredGlaiveReady = false
    local lastCheckedSpell = nil

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(10, false)
        SetEnemyCount(enemyCount)
        
        -- 获取 GCD
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        
        -- 获取资源
        local fury = NCF.GetUnitPower("player", "fury")
        local distance = GetDistanceToTarget("target")
        
        -- 判断技能是否可用 (CD <= GCD)
        local function IsReady(spellId)
            return GetSpellCooldownRemain(spellId) <= gcd
        end
        
        -- 大战刃追踪 (三个触发源)
        local currentStacks = GetBuffStacks(BUFF.GlaiveStacks)
        -- 1. buff层数减少 (叠满消耗后)
        if currentStacks < lastGlaiveStacks then
            empoweredGlaiveReady = true
        end
        -- 2. buff层数 >= 20
        if currentStacks >= 20 then
            empoweredGlaiveReady = true
        end
        lastGlaiveStacks = currentStacks
        
        -- 3. 怨念符咒释放成功触发
        if LastCastedSpell == SPELL.SigilOfSpite and lastCheckedSpell ~= SPELL.SigilOfSpite then
            empoweredGlaiveReady = true
        end
        -- 投掷利刃释放成功后清除标记
        if LastCastedSpell == SPELL.ThrowGlaive and lastCheckedSpell ~= SPELL.ThrowGlaive and empoweredGlaiveReady then
            empoweredGlaiveReady = false
        end
        lastCheckedSpell = LastCastedSpell
        
        -- 1. 打断：瓦解 10码 需面朝
        if IsReady(SPELL.Disrupt) and not ShouldSkipSpell(SPELL.Disrupt) then
            local interruptTarget = NCF.GetInterruptTarget(10, true)
            if interruptTarget then
                return "spell", SPELL.Disrupt, interruptTarget
            end
        end
        
		-- 以下需要战斗中才执行 (自己战斗中 或 目标在战斗中)
		local targetInCombat = UnitExists("target") and UnitAffectingCombat("target")
		if not UnitAffectingCombat("player") and not targetInCombat then 
			return 'spell', 61304
		end
		
        -- 1.1 投掷利刃：距离 >5 且 <=40
        if distance > 5 and distance <= 40 and IsReady(SPELL.ThrowGlaive) and not ShouldSkipSpell(SPELL.ThrowGlaive) then
            return "spell", SPELL.ThrowGlaive
        end
        
        -- 1.2 饰品：恶魔变形期间
        if NCF.burstModeEnabled and HasBuff(BUFF.Metamorphosis) then
            NCF.UseTrinket()
            if NCF.enablePotion then 
				NCF.UseCombatPotion()
			end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
			end
        end
        
        -- 2. 恶魔变形
        if IsReady(SPELL.Metamorphosis) and not ShouldSkipSpell(SPELL.Metamorphosis) then
            return "spell", SPELL.Metamorphosis
        end
        
        -- 3. 怨念符咒
        if IsReady(SPELL.SigilOfSpite) and not ShouldSkipSpell(SPELL.SigilOfSpite) then
            return "spell", SPELL.SigilOfSpite
        end
        
        -- 4. 恶魔尖刺：无buff时
        if not HasBuff(BUFF.DemonSpikes) and IsReady(SPELL.DemonSpikes) and not ShouldSkipSpell(SPELL.DemonSpikes) then
            return "spell", SPELL.DemonSpikes
        end
        
        -- 5. 烈火烙印：无buff时
        if not HasBuff(BUFF.FieryBrand) and IsReady(SPELL.FieryBrand) and not ShouldSkipSpell(SPELL.FieryBrand) then
            return "spell", SPELL.FieryBrand
        end
		
		-- 5.1 烈焰符咒
        if IsReady(SPELL.HotRune) and not ShouldSkipSpell(SPELL.HotRune) then
            return "spell", SPELL.HotRune
        end
		
		-- 5.2 邪能毁灭
        if IsReady(SPELL.FelDestruction) and fury >= 50 and not ShouldSkipSpell(SPELL.FelDestruction) then
            return "spell", SPELL.FelDestruction
        end
        
        -- 5.3 破裂：充能 > 1.8
        if GetSpellCharges(SPELL.Fracture) > 1.8 and not ShouldSkipSpell(SPELL.Fracture) then
            return "spell", SPELL.Fracture
        end
        
        -- 6. 幽魂炸弹：灵魂残片 >= 5 且 怒气 >= 40
        if not IsReady(SPELL.FelDestruction) and GetBuffStacks(BUFF.SoulFragments) >= 5 and fury >= 40 and IsReady(SPELL.SpiritBomb) and not ShouldSkipSpell(SPELL.SpiritBomb) then
            return "spell", SPELL.SpiritBomb
        end
        
        -- 7. 灵魂劈裂：幽魂炸弹CD中 且 怒气 >= 40
        if not IsReady(SPELL.FelDestruction) and not IsReady(SPELL.SpiritBomb) and fury >= 40 and IsReady(SPELL.SoulCleave) and not ShouldSkipSpell(SPELL.SoulCleave) then
            return "spell", SPELL.SoulCleave
        end
        
        -- 8. 献祭光环：无buff时
        if not HasBuff(BUFF.ImmolationAura) and IsReady(SPELL.ImmolationAura) and not ShouldSkipSpell(SPELL.ImmolationAura) then
            return "spell", SPELL.ImmolationAura
        end
        
        -- 9. 投掷利刃：大战刃就绪时
        if empoweredGlaiveReady and IsReady(SPELL.ThrowGlaive) and not ShouldSkipSpell(SPELL.EmpoweredGlaive) then
            return "spell", SPELL.ThrowGlaive
        end
        
        -- 10. 破裂 (填充)
        if GetSpellCharges(SPELL.Fracture) >= 1 and not ShouldSkipSpell(SPELL.Fracture) then
            return "spell", SPELL.Fracture
        end
        
        return nil
    end

    return Rotation
end

-- 创建并返回循环实例
return CreateVengeanceRotation()