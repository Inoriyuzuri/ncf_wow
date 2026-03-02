--============================================================
-- 神圣牧师循环 (Holy Priest Rotation)
-- 12.0 Midnight 版本
-- 模块化文件，由主文件通过 RequireFile() 加载
--============================================================

--[[
优先级列表 (基于代码实际顺序):

--- 战前 ---
0.  真言术：韧 (21562): 没有buff时
0.1 净化 (527): 友方魔法驱散

-- TODO: 0.2 心灵尖啸 (8122): 8码内敌人释放不可打断法术时使用
-- TODO: 0.3 天使之羽 (121536): 移动超过2秒时使用
-- TODO: 祝福 (Benediction): 愈合祷言跳转时有概率对目标施放恢复

--- 战斗门槛: 自己战斗中 或 队友战斗中 ---

0.6 绝望祷言 (19236): 自身血量 < 25%

--- 核心循环 ---
1.  命运扭转维持: 有天赋且无buff时，攻击 <35% 血量的敌人
    1.1 暗言术：灭 (32379) — 瞬发
    1.2 圣言术：罚 (88625) — 瞬发
    1.3 神圣之火 (14914) — 炽热星火buff下瞬发
    1.4 神圣之火 (14914) — 需要站桩
    1.5 惩击 (585) — 需要站桩

2.  愈合祷言 (33076): 优先坦克，层数管理 (每次施放7层，上限14层)

2.5 守护之魂 (47788): 队友血量 < 20%

3.  圣言术：静 (2050): 根据天赋/充能/缺血量智能施放

--- 爆发: 神圣颂歌buff存在时 ---
    饰品/药水/种族技能

4.  快速治疗 vs 治疗祈祷: 根据法强和团队缺血量智能选择

Buff ID:
- 真言术韧: 21562
- 命运扭转: 390978
- 炽热星火: 372617
- 神圣颂歌: 200183
- 愈合祷言: 33076
- 天使羽毛: 121557

特殊机制:
- 快速治疗 vs 治疗祈祷: 根据法强计算实际有效治疗量，选择更高效的技能
- 愈合祷言层数管理: 每次施放7层，上限14层，优先坦克
- 圣言术：静充能管理: 奇迹工匠天赋下2层充能，神圣颂歌加速恢复
- 终极宁静: 圣言术：静额外治疗4个队友 (原治疗量的15%)
]]

--============================================================
-- 1. 注册技能列表 (用于技能模式设置)
--============================================================
NCF.RegisterSpells("PRIEST", 2, {
    -- 爆发技能
    { id = 47788, name = "守护之魂", default = "burst" },

    -- 普通技能
    { id = 21562, name = "真言术：韧", default = "normal" },
    { id = 527, name = "净化", default = "normal" },
    { id = 19236, name = "绝望祷言", default = "normal" },
    { id = 32379, name = "暗言术：灭", default = "normal" },
    { id = 88625, name = "圣言术：罚", default = "normal" },
    { id = 14914, name = "神圣之火", default = "normal" },
    { id = 585, name = "惩击", default = "normal" },
    { id = 33076, name = "愈合祷言", default = "normal" },
    { id = 2050, name = "圣言术：静", default = "normal" },
    { id = 2061, name = "快速治疗", default = "normal" },
    { id = 596, name = "治疗祈祷", default = "normal" },
    { id = 132157, name = "神圣新星", default = "normal" },
})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    PowerWordFortitude = 21562,     -- 真言术：韧
    Purify = 527,                   -- 净化 (友方魔法驱散)
    DesperatePrayer = 19236,        -- 绝望祷言
    ShadowWordDeath = 32379,        -- 暗言术：灭
    HolyWordChastise = 88625,       -- 圣言术：罚
    HolyFire = 14914,               -- 神圣之火
    Smite = 585,                    -- 惩击
    PrayerOfMending = 33076,        -- 愈合祷言
    GuardianSpirit = 47788,         -- 守护之魂
    HolyWordSerenity = 2050,        -- 圣言术：静
    FlashHeal = 2061,               -- 快速治疗
    PrayerOfHealing = 596,          -- 治疗祈祷
    PowerInfusion = 10060,          -- 能量灌注
    AngelicFeather = 121536,        -- 天使之羽
    HolyNova = 132157,              -- 神圣新星
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    PowerWordFortitude = 21562,     -- 真言术：韧
    TwistOfFate = 390978,           -- 命运扭转
    EmpyrealBlaze = 372617,         -- 炽热星火 (使神圣之火变为瞬发)
    Apotheosis = 200183,            -- 神圣颂歌
    PrayerOfMending = 33076,        -- 愈合祷言
    AngelicFeather = 121557,        -- 天使羽毛
    SurgeOfLight = 114255,          -- 圣光涌动 (快速治疗变为瞬发, 省蓝)
    EchoOfLight = 77489,            -- 回光 (HoT, 视为+5%血量)
    Lightweaver = 390993,           -- 织光者 (PoH治疗+18%, 读条-30%)
    Divinity = 1216314,             -- 神性 (PoH也变瞬发)
    Benediction = 1262766,          -- 祝福 (FH+30%, 溅射4人200%SP)
}

--============================================================
-- 3.5 Debuff ID定义
--============================================================
local DEBUFF = {
    HolyFire = 14914,               -- 神圣之火 (DoT)
}

--============================================================
-- 4. 天赋ID定义
--============================================================
local TALENT = {
    TwistOfFate = 390972,           -- 命运扭转
    ShadowWordDeath = 32378,        -- 暗言术：灭
    HolyWordChastise = 88625,       -- 圣言术：罚
    HolyFire = 14914,               -- 神圣之火
    PrayerOfHealing = 596,          -- 治疗祈祷
    GuardianSpirit = 47788,         -- 守护之魂
    MiracleWorker = 235587,         -- 奇迹工匠 (圣言术：静2层充能)
    UltimateSerenity = 1246517,     -- 终极宁静 (圣言术：静额外治疗4人)
    AngelicFeatherTarget = 440670,  -- 天使之羽可对队友释放
    PsychicScream = 8122,           -- 心灵尖啸
    Lightweaver = 390992,           -- 织光者 (FH后获得buff, 增强下一次PoH)
    PrayerfulLitany = 391209,       -- 虔诚连祷 (PoH主目标+125%治疗)
    TrailOfLight = 2001208,         -- 光之踪迹 (FH+15%治疗)
    Spiritwell = 1247178,            -- 灵魂之井 (圣光涌动可被治疗祈祷消耗)
    PrayersOfTheVirtuous = 390977,  -- 美德祈祷 (愈合祷言7层/上限14, 否则5层/上限10)
    ProphetWill = 433905,           -- 先知意志 (对自身FH治疗量+30%)
    EfficientPrayers = 1247131,     -- 有效祈祷 (PoH法力值-15%)
    HealingFocus = 1247166,         -- 治疗专注 (FH法力值-15%)
    FocusedOutburst = 1272320,      -- 专注爆发 (PoH法力值-10%, 读条-15%)
}

--[[
天赋对三大核心治疗技能的影响:

=== 快速治疗 (Flash Heal, 2061) ===
基础: 单体治疗, 系数 15.84, 有读条 (约1.25秒)
- 光之踪迹 (TrailOfLight):       FH 治疗量 +15%
- 圣光涌动 (SurgeOfLight buff):  FH 变为瞬发 + 免费 (最多2层, 施放FH消耗1层)
- 织光者 (Lightweaver talent):   施放FH后获得织光者buff → 增强下一次PoH
  → FH 不仅是治疗技能, 也是 PoH 的"准备技能"
- 先知意志 (ProphetWill):        FH 对自身治疗量 +30%
- 祝福 (Benediction buff):       FH 治疗量 +30%, 额外智能溅射4名缺血队友各200%SP, 施放FH消耗

=== 治疗祈祷 (Prayer of Healing, 596) ===
基础: 智能治疗最缺血的5人, 系数 7.89/人, 有读条 (约2秒)
- 织光者buff (Lightweaver buff): PoH 治疗量 +18%, 读条 -30% (施放后消耗buff)
- 虔诚连祷 (PrayerfulLitany):    PoH 主目标(最缺血的人) 治疗量 +125% (即 x2.25)
- 灵魂之井 (Spiritwell):         PoH 也可消耗圣光涌动buff → PoH 变瞬发+免费
- 神性buff (Divinity):           PoH 变为瞬发 (独立于圣光涌动)
  → PoH 瞬发条件: (圣光涌动buff + 灵魂之井天赋) 或 神性buff

=== 圣言术：静 (Holy Word: Serenity, 2050) ===
基础: 强力单体治疗, 系数 33.00, 瞬发, 60秒CD
- 奇迹工匠 (MiracleWorker):      2层充能 (默认1层), 更积极使用, 防止充能溢出
- 终极宁静 (UltimateSerenity):    额外溅射治疗4名队友, 每人主治疗量的15%
  → 溅射价值判断: 需要4+队友缺血量 >= serenityRaw*0.15 才值得考虑AoE收益
- 神圣颂歌buff (Apotheosis):      加速圣言术CD恢复 → 充能回复更快, 可更积极使用

=== 核心交互 ===
织光者循环: FH(层数+1, 最多4层) → PoH(消耗1层, +18%) → FH → PoH → ...
  代码 step 4.0 保证: 0层时强制FH, 确保PoH前至少有1层buff
  读条预测: 读条FH中预测层数+1, 读条PoH中预测层数-1, 避免重复排队

圣光涌动分配: 2层或即将过期时必须消耗
  有灵魂之井: FH和PoH都可消耗 → 走效率比较选更优的技能
  无灵魂之井: 只有FH能消耗 → 直接用FH

回光 (EchoOfLight, mastery): 治疗后附加HoT
  在FH vs PoH缺血量计算中, 有回光HoT的队友视为额外+5%有效血量, 减少过量治疗
]]

--============================================================
-- 5. 从全局 NCF 表获取函数
--============================================================
local HasBuff = NCF.HasBuff
local GetBuffRemain = NCF.GetBuffRemain
local GetBuffStacks = NCF.GetBuffStacks
local HasDebuff = NCF.HasDebuff
local GetEnemyWithoutDebuff = NCF.GetEnemyWithoutDebuff
local HasTalent = NCF.HasTalent
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges = NCF.GetSpellCharges
local GetActiveEnemyAmount = NCF.GetActiveEnemyAmount
local ShouldSkipSpell = NCF.ShouldSkipSpell
local SetEnemyCount = NCF.SetEnemyCount
local GetUnitHealthPct = NCF.GetUnitHealthPct
local GetUnitHealth = NCF.GetUnitHealth
local GetUnitHealthMax = NCF.GetUnitHealthMax
local GetGroupAverageHealthPct = NCF.GetGroupAverageHealthPct
local GetLowestHealthMember = NCF.GetLowestHealthMember
local GetTankUnit = NCF.GetTankUnit
local GetDispellableUnit = NCF.GetDispellableUnit
local IsSpellInRange = NCF.IsSpellInRange
local GetTrueDeficit = NCF.GetTrueDeficit
local UnitIsUnit = NCF.UnitIsUnit

local IsMidnight = true

--============================================================
-- 6. 辅助函数
--============================================================

-- 获取玩家法术强度 (智力)
local function GetSpellPower()
    local _, sp = UnitStat("player", 4)
    return sp
end

-- 查找范围内血量低于阈值的敌人 (IsSpellInRange负责射程+LoS检查)
local function FindLowHealthEnemy(threshold, range)
    local results = {GetActiveEnemyAmount(range, false)}
    local count = results[1]
    for i = 2, count + 1 do
        local unit = results[i]
        if GetUnitHealthPct(unit) < threshold and IsSpellInRange(SPELL.Smite, unit) then
            return unit
        end
    end
    return nil
end

-- 查找范围内血量最低的敌人 (IsSpellInRange负责射程+LoS检查)
local function FindLowestHealthEnemy(range)
    local results = {GetActiveEnemyAmount(range, false)}
    local count = results[1]
    local bestUnit, bestHp = nil, 101
    for i = 2, count + 1 do
        local unit = results[i]
        local hp = GetUnitHealthPct(unit)
        if hp < bestHp and IsSpellInRange(SPELL.Smite, unit) then
            bestHp = hp
            bestUnit = unit
        end
    end
    return bestUnit
end

-- 智能选择: 快速治疗 vs 治疗祈祷
-- 法力效率模式: 比较每点法力有效治疗量 (pohEff/pohMana vs fhEff/fhMana)
-- 治疗量优先模式: 按施法时间加权比较有效治疗量
-- FH基础法力: 7875 | PoH基础法力: 13125
-- 治疗专注天赋: FH-15% | 有效祈祷天赋: PoH-15% | 专注爆发天赋: PoH-10%读条-15%
-- 圣光涌动: FH法力-50%; 灵魂之井: PoH也享受-50%
local function ShouldCastPrayerOfHealing(members, sp, surgeActive, predictedLwStacks, fhBonusMult, benedictionActive)
    local lightweaverActive = predictedLwStacks > 0
    local divinityActive = HasBuff(BUFF.Divinity, "player")
    local hasPrayerfulLitany = HasTalent(TALENT.PrayerfulLitany)
    local hasTrailOfLight = HasTalent(TALENT.TrailOfLight)
    local hasSpiritwell = HasTalent(TALENT.Spiritwell)
    local hasFocusedOutburst = HasTalent(TALENT.FocusedOutburst)

    -- PoH: 基础 * 织光者buff
    local pohMult = lightweaverActive and 1.18 or 1.0
    local pohRaw = sp * 7.89 * pohMult

    -- FH: 基础 * 光之踪迹天赋 * 先知意志/祝福加成
    local fhMult = hasTrailOfLight and 1.15 or 1.0
    local fhRaw = sp * 15.84 * fhMult * (fhBonusMult or 1.0)

    -- 收集射程+LoS内队友的缺血量
    -- 有回光(Echo of Light)HoT的队友视为额外+5%血量, 减少实际缺血量
    local deficits = {}
    for _, unit in ipairs(members) do
        if IsSpellInRange(SPELL.PrayerOfHealing, unit) then
            local deficit, maxHp = GetTrueDeficit(unit)
            if HasBuff(BUFF.EchoOfLight, unit) then
                deficit = deficit - maxHp * 0.05
            end
            if deficit > 0 then
                table.insert(deficits, deficit)
            end
        end
    end

    -- 按缺血量从大到小排序 (PoH智能治疗最需要治疗的5人)
    table.sort(deficits, function(a, b) return a > b end)

    -- 治疗祈祷有效治疗 = 最多5人, 每人 min(pohRaw, 缺血量)
    -- 虔诚连祷: 主目标(缺血最多) +125%
    local pohEffective = 0
    for i = 1, math.min(5, #deficits) do
        local heal = pohRaw
        if i == 1 and hasPrayerfulLitany then
            heal = heal * 2.25  -- +125% = x2.25
        end
        pohEffective = pohEffective + math.min(heal, deficits[i])
    end

    -- 快速治疗有效治疗 = 最缺血的1人, min(fhRaw, 缺血量)
    local fhEffective = deficits[1] and math.min(fhRaw, deficits[1]) or 0

    -- 祝福溅射: FH额外智能治疗4名缺血队友, 每人200%SP
    if benedictionActive then
        local fhSplash = sp * 2.0
        for i = 2, math.min(5, #deficits) do
            fhEffective = fhEffective + math.min(fhSplash, deficits[i])
        end
    end

    local pohInstant = (surgeActive and hasSpiritwell) or divinityActive
    local fhInstant = surgeActive

    local usePoh
    if NCF.holyPriestHealMode == "mana" then
        -- 法力效率模式: pohEff/pohMana > fhEff/fhMana ⟺ pohEff*fhMana > fhEff*pohMana
        local fhManaCost = 7875
        if HasTalent(TALENT.HealingFocus) then fhManaCost = fhManaCost * 0.85 end
        if fhInstant then fhManaCost = fhManaCost * 0.50 end  -- 圣光涌动-50%

        local pohManaCost = 13125
        if HasTalent(TALENT.EfficientPrayers) then pohManaCost = pohManaCost * 0.85 end
        if hasFocusedOutburst then pohManaCost = pohManaCost * 0.90 end
        if surgeActive and hasSpiritwell then pohManaCost = pohManaCost * 0.50 end  -- 灵魂之井-50%

        if pohManaCost <= 0 then
            usePoh = true
        elseif fhManaCost <= 0 then
            usePoh = false
        else
            usePoh = pohEffective * fhManaCost > fhEffective * pohManaCost
        end
    else
        -- 治疗量优先模式: 按施法时间加权比较
        -- 专注爆发天赋: PoH读条-15%, 降低PoH时间权重
        local foMult = hasFocusedOutburst and 0.85 or 1.0
        local fhTimeWeight
        if fhInstant and pohInstant then
            fhTimeWeight = 1.0
        elseif fhInstant then
            fhTimeWeight = (lightweaverActive and 1.75 or 2.5) * foMult
        elseif pohInstant then
            fhTimeWeight = 0.625
        else
            fhTimeWeight = (lightweaverActive and 1.12 or 1.6) * foMult
        end
        usePoh = pohEffective > fhEffective * fhTimeWeight
    end

    local recommend = benedictionActive and "Benediction FH" or (usePoh and "PoH" or "FH")
    print(string.format("[NCF Holy] PoH=%.0f FH=%.0f members=%d mode=%s → %s",
        pohEffective, fhEffective, #deficits, NCF.holyPriestHealMode, recommend))

    return usePoh
end

-- 查找愈合祷言目标
-- 优先坦克 → 无buff队友 → 低层数队友 → 自己
-- 美德祈祷天赋: 每次7层/上限14, 无天赋: 每次5层/上限10
local function FindPoMTarget(members, tankUnit)
    local pomPerCast = HasTalent(TALENT.PrayersOfTheVirtuous) and 7 or 5

    -- 2.1 坦克无愈合祷言buff
    if tankUnit and IsSpellInRange(SPELL.PrayerOfMending, tankUnit) then
        if not HasBuff(BUFF.PrayerOfMending, tankUnit) then
            return tankUnit
        end
        -- 2.2 坦克层数 <= pomPerCast (还能叠满不溢出)
        local stacks = GetBuffStacks(BUFF.PrayerOfMending, tankUnit)
        if stacks <= pomPerCast then
            return tankUnit
        end
    end

    -- 2.3 任何队友无愈合祷言buff
    for _, unit in ipairs(members) do
        if IsSpellInRange(SPELL.PrayerOfMending, unit) then
            if not HasBuff(BUFF.PrayerOfMending, unit) then
                return unit
            end
        end
    end

    -- 2.4 任何队友层数 <= pomPerCast
    for _, unit in ipairs(members) do
        if IsSpellInRange(SPELL.PrayerOfMending, unit) then
            local stacks = GetBuffStacks(BUFF.PrayerOfMending, unit)
            if stacks <= pomPerCast then
                return unit
            end
        end
    end

    -- 2.5 fallback: 自己
    return "player"
end

-- 计算射程内缺血量 >= threshold 的队友数量
local function CountDeficitMembers(members, threshold, spellID)
    local count = 0
    for _, unit in ipairs(members) do
        if IsSpellInRange(spellID, unit) then
            local deficit = GetTrueDeficit(unit)
            if deficit >= threshold then
                count = count + 1
            end
        end
    end
    return count
end

--============================================================
-- 7. 全局函数: 力量灌注
--============================================================

-- /run NCFpowerinfusion()
-- 对选定目标施放力量灌注 (需要LoS), 否则对自己施放
_G.NCFpowerinfusion = function()
    local target = NCF.holyPriestSelectedTarget
    if target and UnitExists(target) and not UnitIsDead(target) then
        if IsSpellInRange(SPELL.PowerInfusion, target) then
            NCF.API.CastSpell(GetSpellInfo(SPELL.PowerInfusion), target)
            return
        end
    end
    -- fallback: 对自己施放
    NCF.API.CastSpell(GetSpellInfo(SPELL.PowerInfusion))
end

--============================================================
-- 8. 控制面板 (PI目标 + 净化模式 + 缺血面板)
--============================================================

local holyTargetPanel = nil

local function CreateHolyPanel()
    local BACKDROP = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    }
    local DD_WIDTH = 160
    local ROW_HEIGHT = 20
    local ROW_SPACING = 24
    local DEFICIT_ROW_HEIGHT = 14
    local DEFICIT_COUNT = 5
    local PADDING = 5
    local PANEL_WIDTH = 300
    local DEFAULT_LABEL = "选择队友"
    local REFRESH_LABEL = "刷新"
    local TARGET_LABEL  = "灌注目标:"
    local PURIFY_LABEL  = "净化模式:"

    if not NCF.holyPriestPurifyMode then
        NCF.holyPriestPurifyMode = "auto"
    end
    if not NCF.holyPriestHealMode then
        NCF.holyPriestHealMode = "mana"
    end
    if not NCF.holyPriestHealModeKey then
        NCF.holyPriestHealModeKey = ""
    end

    -- Panel height: 4 control rows + separator + 5 deficit rows
    local controlHeight = PADDING + ROW_SPACING * 4 + PADDING
    local deficitHeight = 2 + DEFICIT_ROW_HEIGHT * (DEFICIT_COUNT + 1)  -- separator + title + 5 rows
    local totalHeight = controlHeight + deficitHeight + PADDING

    --=== Main frame — left 1/3 of screen ===
    local frame = CreateFrame("Frame", "NCFHolyPanel", UIParent, "BackdropTemplate")
    frame:SetSize(PANEL_WIDTH, totalHeight)
    local screenW = GetScreenWidth()
    frame:SetPoint("LEFT", UIParent, "LEFT", screenW / 6 - PANEL_WIDTH / 2, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Shadow
    local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    shadow:SetPoint("TOPLEFT", -4, 4)
    shadow:SetPoint("BOTTOMRIGHT", 4, -4)
    shadow:SetFrameLevel(frame:GetFrameLevel() - 1)
    shadow:SetBackdrop({
        edgeFile = "Interface\\TutorialFrame\\UI-TutorialFrame-CalloutGlow",
        edgeSize = 16, tileEdge = true,
    })
    shadow:SetBackdropBorderColor(0, 0, 0, 0.5)

    --========================================
    -- Row 1: PI target dropdown + refresh
    --========================================
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2))
    label:SetText(TARGET_LABEL)
    label:SetTextColor(0.9, 0.8, 0.5)

    local ddBtn = CreateFrame("Button", nil, frame)
    ddBtn:SetSize(DD_WIDTH, 20)
    ddBtn:SetPoint("LEFT", label, "RIGHT", 6, 0)

    local ddBd = CreateFrame("Frame", nil, ddBtn, "BackdropTemplate")
    ddBd:SetAllPoints()
    ddBd:SetFrameLevel(ddBtn:GetFrameLevel() - 1)
    ddBd:SetBackdrop(BACKDROP)
    ddBd:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    ddBd:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local ddLabel = ddBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ddLabel:SetPoint("LEFT", 6, 0)
    ddLabel:SetPoint("RIGHT", -14, 0)
    ddLabel:SetJustifyH("LEFT")
    ddLabel:SetText(DEFAULT_LABEL)
    ddLabel:SetTextColor(0.6, 0.6, 0.6)

    local ddArrow = ddBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ddArrow:SetPoint("RIGHT", -4, 0)
    ddArrow:SetText("|cFFAAAAAA▼|r")

    ddBtn:SetScript("OnEnter", function()
        ddBd:SetBackdropColor(0.18, 0.18, 0.18, 0.9)
        ddBd:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    ddBtn:SetScript("OnLeave", function()
        ddBd:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
        ddBd:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    local popup = CreateFrame("Frame", nil, ddBtn, "BackdropTemplate")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetPoint("TOP", ddBtn, "BOTTOM", 0, -1)
    popup:SetSize(DD_WIDTH, 22)
    popup:SetBackdrop(BACKDROP)
    popup:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    popup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    popup:Hide()

    local clickAway = CreateFrame("Button", nil, popup)
    clickAway:SetFrameStrata("FULLSCREEN")
    clickAway:SetAllPoints(UIParent)
    clickAway:SetScript("OnClick", function() popup:Hide() end)
    clickAway:Hide()

    popup:SetScript("OnShow", function() clickAway:Show() end)
    popup:SetScript("OnHide", function() clickAway:Hide() end)

    ddBtn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else popup:Show() end
    end)

    local refreshBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    refreshBtn:SetSize(40, 20)
    refreshBtn:SetPoint("LEFT", ddBtn, "RIGHT", 4, 0)
    refreshBtn:SetBackdrop(BACKDROP)
    refreshBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    refreshBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local refreshText = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    refreshText:SetPoint("CENTER")
    refreshText:SetText(REFRESH_LABEL)
    refreshText:SetTextColor(0.8, 0.8, 0.8)

    refreshBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 0.9)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    refreshBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    --========================================
    -- Row 2: Purify mode
    --========================================
    local purifyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    purifyLabel:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2 + ROW_SPACING))
    purifyLabel:SetText(PURIFY_LABEL)
    purifyLabel:SetTextColor(0.9, 0.8, 0.5)

    local purifyModes = {
        {value = "auto", text = "|cFF00FF00自动净化|r"},
        {value = "mouseover", text = "|cFFFFFF00鼠标净化|r"},
    }

    local purifyBtn = CreateFrame("Button", nil, frame)
    purifyBtn:SetSize(100, 20)
    purifyBtn:SetPoint("LEFT", purifyLabel, "RIGHT", 6, 0)

    local purifyBd = CreateFrame("Frame", nil, purifyBtn, "BackdropTemplate")
    purifyBd:SetAllPoints()
    purifyBd:SetFrameLevel(purifyBtn:GetFrameLevel() - 1)
    purifyBd:SetBackdrop(BACKDROP)
    purifyBd:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    purifyBd:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local purifyDdLabel = purifyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    purifyDdLabel:SetPoint("LEFT", 6, 0)
    purifyDdLabel:SetPoint("RIGHT", -14, 0)
    purifyDdLabel:SetJustifyH("LEFT")
    purifyDdLabel:SetText(NCF.holyPriestPurifyMode == "mouseover" and "|cFFFFFF00鼠标净化|r" or "|cFF00FF00自动净化|r")

    local purifyArrow = purifyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    purifyArrow:SetPoint("RIGHT", -4, 0)
    purifyArrow:SetText("|cFFAAAAAA▼|r")

    purifyBtn:SetScript("OnEnter", function()
        purifyBd:SetBackdropColor(0.18, 0.18, 0.18, 0.9)
        purifyBd:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    purifyBtn:SetScript("OnLeave", function()
        purifyBd:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
        purifyBd:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    local purifyPopup = CreateFrame("Frame", nil, purifyBtn, "BackdropTemplate")
    purifyPopup:SetFrameStrata("FULLSCREEN_DIALOG")
    purifyPopup:SetPoint("TOP", purifyBtn, "BOTTOM", 0, -1)
    purifyPopup:SetSize(100, #purifyModes * ROW_HEIGHT + 2)
    purifyPopup:SetBackdrop(BACKDROP)
    purifyPopup:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    purifyPopup:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    purifyPopup:Hide()

    local purifyClickAway = CreateFrame("Button", nil, purifyPopup)
    purifyClickAway:SetFrameStrata("FULLSCREEN")
    purifyClickAway:SetAllPoints(UIParent)
    purifyClickAway:SetScript("OnClick", function() purifyPopup:Hide() end)
    purifyClickAway:Hide()

    purifyPopup:SetScript("OnShow", function() purifyClickAway:Show() end)
    purifyPopup:SetScript("OnHide", function() purifyClickAway:Hide() end)

    purifyBtn:SetScript("OnClick", function()
        if purifyPopup:IsShown() then purifyPopup:Hide() else purifyPopup:Show() end
    end)

    for i, mode in ipairs(purifyModes) do
        local row = CreateFrame("Button", nil, purifyPopup)
        row:SetSize(98, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 1, -(i - 1) * ROW_HEIGHT - 1)

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(1, 1, 1, 0)

        local rowText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rowText:SetPoint("LEFT", 6, 0)
        rowText:SetText(mode.text)

        row:SetScript("OnEnter", function() rowBg:SetColorTexture(0.3, 0.5, 0.8, 0.3) end)
        row:SetScript("OnLeave", function() rowBg:SetColorTexture(1, 1, 1, 0) end)
        row:SetScript("OnClick", function()
            NCF.holyPriestPurifyMode = mode.value
            purifyDdLabel:SetText(mode.text)
            purifyPopup:Hide()
            print(string.format("|cFF00FF00[NCF Holy]|r 净化模式: %s", mode.text))
        end)
    end

    --========================================
    -- Row 3: 治疗模式切换
    --========================================
    local healModeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healModeLabel:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2 + ROW_SPACING * 2))
    healModeLabel:SetText("治疗模式:")
    healModeLabel:SetTextColor(0.9, 0.8, 0.5)

    local function GetHealModeText()
        return NCF.holyPriestHealMode == "mana"
            and "|cFF00CCFF法力效率|r"
            or  "|cFFFFAA00治疗量优先|r"
    end

    local healModeBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    healModeBtn:SetSize(120, 20)
    healModeBtn:SetPoint("LEFT", healModeLabel, "RIGHT", 6, 0)
    healModeBtn:SetBackdrop(BACKDROP)
    healModeBtn:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    healModeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local healModeBtnLabel = healModeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    healModeBtnLabel:SetPoint("CENTER")
    healModeBtnLabel:SetText(GetHealModeText())

    healModeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.18, 0.18, 0.9)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    healModeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    healModeBtn:SetScript("OnClick", function()
        NCF.holyPriestHealMode = NCF.holyPriestHealMode == "mana" and "hps" or "mana"
        healModeBtnLabel:SetText(GetHealModeText())
        print(string.format("|cFF00FF00[NCF Holy]|r 治疗模式: %s", GetHealModeText()))
    end)

    --========================================
    -- Row 4: 快捷键设置
    --========================================
    local keybindLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keybindLabel:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2 + ROW_SPACING * 3))
    keybindLabel:SetText("切换快捷键:")
    keybindLabel:SetTextColor(0.9, 0.8, 0.5)

    local function FormatKey(key)
        return (key and key ~= "") and key or "|cFF888888未设置|r"
    end

    local keyDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keyDisplay:SetPoint("LEFT", keybindLabel, "RIGHT", 6, 0)
    keyDisplay:SetText(FormatKey(NCF.holyPriestHealModeKey))
    keyDisplay:SetTextColor(1, 1, 1)

    local setKeyBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    setKeyBtn:SetSize(40, 18)
    setKeyBtn:SetPoint("RIGHT", frame, "RIGHT", -PADDING, -(PADDING + 2 + ROW_SPACING * 3 + 1))
    setKeyBtn:SetBackdrop(BACKDROP)
    setKeyBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    setKeyBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local setKeyText = setKeyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    setKeyText:SetPoint("CENTER")
    setKeyText:SetText("设置")
    setKeyText:SetTextColor(0.8, 0.8, 0.8)

    setKeyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.25, 0.25, 0.9)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    setKeyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)

    local capturing = false
    local hotkeyFrame = CreateFrame("Frame", "NCFHolyHotkeyFrame", UIParent)
    hotkeyFrame:EnableKeyboard(true)
    hotkeyFrame:SetPropagateKeyboardInput(true)
    hotkeyFrame:SetAllPoints()

    hotkeyFrame:SetScript("OnKeyDown", function(self, key)
        if key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT"
            or key == "LSHIFT" or key == "RSHIFT" then return end

        if capturing then
            capturing = false
            setKeyText:SetText("设置")
            setKeyBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            if key == "ESCAPE" then
                NCF.holyPriestHealModeKey = ""
                keyDisplay:SetText(FormatKey(""))
            else
                local mod = ""
                if IsControlKeyDown() then mod = mod .. "CTRL-" end
                if IsAltKeyDown()     then mod = mod .. "ALT-"  end
                if IsShiftKeyDown()   then mod = mod .. "SHIFT-" end
                NCF.holyPriestHealModeKey = mod .. key
                keyDisplay:SetText(NCF.holyPriestHealModeKey)
            end
            return
        end

        if NCF.holyPriestHealModeKey ~= "" then
            local mod = ""
            if IsControlKeyDown() then mod = mod .. "CTRL-" end
            if IsAltKeyDown()     then mod = mod .. "ALT-"  end
            if IsShiftKeyDown()   then mod = mod .. "SHIFT-" end
            if mod .. key == NCF.holyPriestHealModeKey then
                NCF.holyPriestHealMode = NCF.holyPriestHealMode == "mana" and "hps" or "mana"
                healModeBtnLabel:SetText(GetHealModeText())
                print(string.format("|cFF00FF00[NCF Holy]|r 治疗模式: %s", GetHealModeText()))
            end
        end
    end)

    setKeyBtn:SetScript("OnClick", function(self)
        capturing = true
        setKeyText:SetText("...")
        self:SetBackdropColor(0.3, 0.5, 0.2, 0.9)
        self:SetBackdropBorderColor(0.5, 0.8, 0.3, 1)
        print("|cFF00FF00[NCF Holy]|r 请按下快捷键 (ESC 清除绑定)")
    end)

    --========================================
    -- Separator line
    --========================================
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", PADDING, -controlHeight)
    sep:SetPoint("TOPRIGHT", -PADDING, -controlHeight)
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    --========================================
    -- Deficit rows (5 most wounded)
    --========================================
    local deficitTop = controlHeight + 2

    local deficitTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deficitTitle:SetPoint("TOPLEFT", PADDING + 2, -deficitTop)
    deficitTitle:SetText("|cFF00FF00缺血面板|r")

    local function AbbreviateNumber(n)
        if n >= 1000000 then
            return string.format("%.1fM", n / 1000000)
        elseif n >= 1000 then
            return string.format("%.0fK", n / 1000)
        end
        return string.format("%.0f", n)
    end

    local deficitRows = {}
    for i = 1, DEFICIT_COUNT do
        local row = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row:SetPoint("TOPLEFT", PADDING + 2, -deficitTop - DEFICIT_ROW_HEIGHT * i)
        row:SetPoint("RIGHT", frame, "RIGHT", -PADDING, 0)
        row:SetJustifyH("LEFT")
        row:SetText("")
        deficitRows[i] = row
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.15 then return end
        self.elapsed = 0
        local data = NCF.holyDeficitData
        if not data then return end
        for i = 1, DEFICIT_COUNT do
            local d = data[i]
            if d then
                local color = d.hp < 50 and "FF4444" or (d.hp < 75 and "FFAA00" or "AAAAAA")
                deficitRows[i]:SetText(string.format("|cFF%s%s  %.0f%%  -%s|r", color, d.name, d.hp, AbbreviateNumber(d.deficit)))
            else
                deficitRows[i]:SetText("")
            end
        end
    end)

    --========================================
    -- PI target row pool + refresh
    --========================================
    local rowPool = {}
    local rowCount = 0

    local function GetOrCreateRow(idx)
        if rowPool[idx] then return rowPool[idx] end
        local row = CreateFrame("Button", nil, popup)
        row:SetSize(DD_WIDTH - 2, ROW_HEIGHT)

        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(1, 1, 1, 0)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", 6, 0)

        row:SetScript("OnEnter", function() rowBg:SetColorTexture(0.3, 0.5, 0.8, 0.3) end)
        row:SetScript("OnLeave", function() rowBg:SetColorTexture(1, 1, 1, 0) end)
        row:SetScript("OnClick", function(self)
            NCF.holyPriestSelectedTarget = self.unit
            local name = self.displayName or self.unit
            local c = self.classColor or {r = 0.8, g = 0.8, b = 0.8}
            ddLabel:SetText(string.format("|cFF%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name))
            popup:Hide()
            print(string.format("|cFF00FF00[NCF Holy]|r 目标已选择: %s", name))
        end)

        rowPool[idx] = row
        return row
    end

    local function RefreshMembers()
        for i = 1, #rowPool do
            rowPool[i]:Hide()
        end
        rowCount = 0

        local members = NCF.GetGroupMembers()
        local selectedTarget = NCF.holyPriestSelectedTarget
        local foundSelection = false

        for idx, unit in ipairs(members) do
            local row = GetOrCreateRow(idx)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, -(idx - 1) * ROW_HEIGHT - 1)
            row.unit = unit

            local rawName = UnitName(unit)
            if IsMidnight and rawName then rawName = secretunwrap(rawName) end
            local name = rawName or unit
            local _, classToken = UnitClass(unit)
            if IsMidnight and classToken then classToken = secretunwrap(classToken) end
            local color = RAID_CLASS_COLORS[classToken] or {r = 0.8, g = 0.8, b = 0.8}

            row.displayName = name
            row.classColor = color
            row.nameText:SetText(string.format("|cFF%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name))

            if selectedTarget and UnitIsUnit(unit, selectedTarget) then
                foundSelection = true
                ddLabel:SetText(string.format("|cFF%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name))
            end

            row:Show()
            rowCount = idx
        end

        if not foundSelection then
            NCF.holyPriestSelectedTarget = nil
            ddLabel:SetText(DEFAULT_LABEL)
            ddLabel:SetTextColor(0.6, 0.6, 0.6)
        end

        popup:SetSize(DD_WIDTH, rowCount * ROW_HEIGHT + 2)
    end

    refreshBtn:SetScript("OnClick", function()
        RefreshMembers()
    end)

    frame.RefreshMembers = RefreshMembers
    RefreshMembers()

    return frame
end

holyTargetPanel = CreateHolyPanel()

_G.NCFholytarget = function()
    holyTargetPanel:RefreshMembers()
end

-- Auto-create Power Infusion macro
do
    local macroName = "NCF牧师灌注"
    if GetMacroIndexByName(macroName) == 0 then
        local numGlobal = GetNumMacros()
        if numGlobal < MAX_ACCOUNT_MACROS then
            CreateMacro(macroName, "Spell_Holy_PowerInfusion",
                "#showtooltip 能量灌注\n/run NCFpowerinfusion()", false)
            print("|cFF00FF00[NCF] 创建宏: " .. macroName .. "|r")
        end
    end
end

--============================================================
-- 9. 主循环
--============================================================
local function CreateHolyRotation()

    -- 移动追踪 (持久状态)
    local moveStartTime = 0
    local lastX, lastY, lastZ = 0, 0, 0

    local function UpdateMovement()
        local x, y, z = NCF.API.GetPosition("player")
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

    local function Rotation()
        -- 获取敌人数量
        local enemyCount = GetActiveEnemyAmount(40, false)
        SetEnemyCount(enemyCount)

        -- GCD
        NCF.RefreshGCD()
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        local isMoving = GetUnitSpeed("player") > 0

        local function IsReady(spellID)
            return GetSpellCooldownRemain(spellID) <= gcd
        end

        -- 常用状态缓存
        local members = NCF.GetGroupMembers()
        local avgHp = GetGroupAverageHealthPct(40)
        local lowestUnit, lowestHp = GetLowestHealthMember(40, 95, SPELL.FlashHeal, 10)
        local myHp = GetUnitHealthPct("player")
        local tankUnit = GetTankUnit()
        local sp = GetSpellPower()
        local serenityRaw = sp * 33.00          -- 圣言术：静基础治疗量

        -- 圣光涌动: 快速治疗变为瞬发, 省蓝 (灵魂之井天赋下PoH也可消耗)
        local surgeStacks = GetBuffStacks(BUFF.SurgeOfLight, "player")
        local surgeRemain = GetBuffRemain(BUFF.SurgeOfLight, "player")
        local surgeActive = surgeStacks > 0

        -- 祝福buff: FH+30%, 溅射4人200%SP, 施放FH消耗
        local benedictionActive = HasBuff(BUFF.Benediction, "player")

        -- 读条预测: 织光者层数 + 祝福消耗
        local lightweaverStacks = GetBuffStacks(BUFF.Lightweaver, "player")
        local predictedLwStacks = lightweaverStacks
        local hasLightweaverTalent = HasTalent(TALENT.Lightweaver)
        if hasLightweaverTalent or benedictionActive then
            local castingSpellID = select(9, UnitCastingInfo("player"))
            if IsMidnight and castingSpellID then castingSpellID = secretunwrap(castingSpellID) end
            castingSpellID = castingSpellID and tonumber(castingSpellID)
            if castingSpellID == SPELL.FlashHeal then
                if hasLightweaverTalent then
                    predictedLwStacks = math.min(lightweaverStacks + 1, 4)
                end
                benedictionActive = false  -- FH消耗祝福buff
            elseif castingSpellID == SPELL.PrayerOfHealing and hasLightweaverTalent then
                predictedLwStacks = math.max(lightweaverStacks - 1, 0)
            end
        end

        -- FH加成: 先知意志(对自身+30%) + 祝福buff(+30%), 在读条预测之后计算
        local hasProphetWill = HasTalent(TALENT.ProphetWill)
        local prophetWillMult = (hasProphetWill and lowestUnit and UnitIsUnit(lowestUnit, "player")) and 1.30 or 1.0
        local benedictionMult = benedictionActive and 1.30 or 1.0
        local fhBonusMult = prophetWillMult * benedictionMult
        local fhRaw = sp * 15.84 * fhBonusMult  -- 快速治疗基础治疗量 (含加成)

        -- 缺血面板数据: 收集前5名缺血最多的队友
        do
            local ddata = {}
            for _, unit in ipairs(members) do
                local deficit = GetTrueDeficit(unit)
                if deficit > 0 then
                    local name = UnitName(unit) or unit
                    local hp = GetUnitHealthPct(unit)
                    ddata[#ddata + 1] = { name = name, deficit = deficit, hp = hp }
                end
            end
            table.sort(ddata, function(a, b) return a.deficit > b.deficit end)
            NCF.holyDeficitData = ddata
        end

        --========================================
        -- 0. 战前增益: 真言术：韧
        --========================================
        if not HasBuff(BUFF.PowerWordFortitude, "player") and IsReady(SPELL.PowerWordFortitude) and not ShouldSkipSpell(SPELL.PowerWordFortitude) then
            return "spell", SPELL.PowerWordFortitude
        end

        --========================================
        -- 0.1 净化: 友方魔法驱散
        -- 自动模式: 自动选择可驱散的队友
        -- 鼠标模式: 对鼠标悬停的友方施放
        --========================================
        if IsReady(SPELL.Purify) and not ShouldSkipSpell(SPELL.Purify) then
            if NCF.holyPriestPurifyMode == "mouseover" then
                local mo = "mouseover"
                if UnitExists(mo) and UnitIsFriend("player", mo) and not UnitIsDead(mo)
                    and IsSpellInRange(SPELL.Purify, mo) then
                    return "spell", SPELL.Purify, mo
                end
            else
                local dispelTarget = GetDispellableUnit("Magic", 40)
                if dispelTarget then
                    return "spell", SPELL.Purify, dispelTarget
                end
            end
        end

        -- TODO: 0.2 心灵尖啸 (PsychicScream 8122)
        -- 8码内敌人释放不可打断法术时使用

        --========================================
        -- 0.3 天使之羽: 移动超过2秒且无buff时, 丢脚下
        --========================================
        if IsReady(SPELL.AngelicFeather) and not ShouldSkipSpell(SPELL.AngelicFeather) then
            local moveDuration = UpdateMovement()
            if moveDuration > 2 and not HasBuff(BUFF.AngelicFeather, "player") then
                return "castselflocation", SPELL.AngelicFeather
            end
        end

        --========================================
        -- 战斗门槛
        --========================================
        if not NCF.IsInCombat() then
            return "spell", 61304
        end

        --========================================
        -- 0.6 绝望祷言: 自身血量 < 25%
        --========================================
        if myHp < 25 and IsReady(SPELL.DesperatePrayer) and not ShouldSkipSpell(SPELL.DesperatePrayer) then
            return "spell", SPELL.DesperatePrayer
        end

        --========================================
        -- 爆发: 神圣颂歌buff存在时使用饰品/药水/种族技能
        --========================================
        if NCF.burstModeEnabled and HasBuff(BUFF.Apotheosis, "player") then
            NCF.UseTrinket()
            if NCF.enablePotion then
                NCF.UseCombatPotion()
            end
            local racialSpell = NCF.GetRacialSpell()
            if racialSpell and IsReady(racialSpell) then
                return "spell", racialSpell
            end
        end

        --========================================
        -- 1. 愈合祷言 (Prayer of Mending)
        -- 优先坦克, 美德祈祷: 7层/上限14, 否则5层/上限10
        --========================================
        if IsReady(SPELL.PrayerOfMending) and not ShouldSkipSpell(SPELL.PrayerOfMending) then
            local pomTarget = FindPoMTarget(members, tankUnit)
            if pomTarget then
                return "spell", SPELL.PrayerOfMending, pomTarget
            end
        end

        --========================================
        -- 2.5 守护之魂 (Guardian Spirit)
        -- 队友血量 < 20% 时使用
        --========================================
        if HasTalent(TALENT.GuardianSpirit) and IsReady(SPELL.GuardianSpirit) and not ShouldSkipSpell(SPELL.GuardianSpirit) then
            for _, unit in ipairs(members) do
                if GetUnitHealthPct(unit) < 20 and IsSpellInRange(SPELL.GuardianSpirit, unit) then
                    return "spell", SPELL.GuardianSpirit, unit
                end
            end
        end

        --========================================
        -- 3. 圣言术：静 (Holy Word: Serenity)
        -- 根据天赋/充能/缺血量智能施放
        --========================================
        if IsReady(SPELL.HolyWordSerenity) and not ShouldSkipSpell(SPELL.HolyWordSerenity) then
            local ultimateSerenityPerTarget = serenityRaw * 0.15  -- 终极宁静: 额外治疗4人, 每人15%

            -- 最低血量队友的缺血量
            local lowestDeficit = 0
            if lowestUnit then
                lowestDeficit = GetTrueDeficit(lowestUnit)
            end

            local hasMiracleWorker = HasTalent(TALENT.MiracleWorker)
            local hasApotheosis = HasBuff(BUFF.Apotheosis, "player")
            local hasUltimateSerenity = HasTalent(TALENT.UltimateSerenity)
            local shouldCast = false

            if hasMiracleWorker then
                -- 奇迹工匠: 2层充能
                local charges = GetSpellCharges(SPELL.HolyWordSerenity)

                -- 3.1 充能 > 1.82 → 防止溢出
                if charges > 1.82 then
                    shouldCast = true
                -- 3.2 充能 > 1.60 且有神圣颂歌buff → 加速恢复期间更积极使用
                elseif charges > 1.60 and hasApotheosis then
                    shouldCast = true
                -- 3.3 最低缺血量 > 快速治疗 * 2 → 伤口够大, 值得用大治疗
                elseif lowestDeficit > fhRaw * 2 then
                    shouldCast = true
                -- 3.4 终极宁静: 主目标缺血量够大 + 4+队友需要溅射 → AoE价值高
                elseif hasUltimateSerenity and lowestDeficit > fhRaw * 1.5 and CountDeficitMembers(members, ultimateSerenityPerTarget, SPELL.HolyWordSerenity) >= 4 then
                    shouldCast = true
                -- 3.5 有人 < 50% → 紧急治疗
                elseif lowestHp < 50 then
                    shouldCast = true
                end
            elseif hasApotheosis then
                -- 无奇迹工匠 + 有神圣颂歌: 加速恢复, 积极使用
                -- 3.6 神圣颂歌期间直接施放
                shouldCast = true
            else
                -- 无奇迹工匠 + 无神圣颂歌: 常规判断
                -- 3.7 最低缺血量 > 快速治疗 * 2
                if lowestDeficit > fhRaw * 1.75 then
                    shouldCast = true
                -- 3.8 终极宁静: 主目标缺血量够大 + 4+队友需要溅射
                elseif hasUltimateSerenity and lowestDeficit > fhRaw * 1.5 and CountDeficitMembers(members, ultimateSerenityPerTarget, SPELL.HolyWordSerenity) >= 4 then
                    shouldCast = true
                -- 3.9 有人 < 50%
                elseif lowestHp < 50 then
                    shouldCast = true
                end
            end

            if shouldCast and lowestUnit then
                return "spell", SPELL.HolyWordSerenity, lowestUnit
            end
        end

        --========================================
        -- 3.5 命运扭转 (Twist of Fate) 维持
        -- 有天赋且无buff时, 攻击 <35% 血量的敌人来触发
        --========================================
        if HasTalent(TALENT.TwistOfFate) and not HasBuff(BUFF.TwistOfFate, "player") then
            local lowEnemy = FindLowHealthEnemy(35, 40)
            if lowEnemy then
                -- 暗言术：灭 (瞬发)
                if HasTalent(TALENT.ShadowWordDeath) and IsReady(SPELL.ShadowWordDeath) and not ShouldSkipSpell(SPELL.ShadowWordDeath) then
                    return "InstantSpell", SPELL.ShadowWordDeath, lowEnemy
                end
                -- 圣言术：罚 (瞬发)
                if HasTalent(TALENT.HolyWordChastise) and IsReady(SPELL.HolyWordChastise) and not ShouldSkipSpell(SPELL.HolyWordChastise) then
                    return "InstantSpell", SPELL.HolyWordChastise, lowEnemy
                end
                -- 神圣之火 (炽热星火buff下瞬发)
                if HasBuff(BUFF.EmpyrealBlaze, "player") and HasTalent(TALENT.HolyFire) and IsReady(SPELL.HolyFire) and not ShouldSkipSpell(SPELL.HolyFire) then
                    return "InstantSpell", SPELL.HolyFire, lowEnemy
                end
                -- 神圣之火 (需要站桩)
                if not isMoving and HasTalent(TALENT.HolyFire) and IsReady(SPELL.HolyFire) and not ShouldSkipSpell(SPELL.HolyFire) then
                    return "spell", SPELL.HolyFire, lowEnemy
                end
                -- 惩击 (需要站桩, fallback)
                if not isMoving and IsReady(SPELL.Smite) and not ShouldSkipSpell(SPELL.Smite) then
                    return "spell", SPELL.Smite, lowEnemy
                end
            end
        end

        --========================================
        -- 4. 快速治疗 vs 治疗祈祷
        -- 织光者天赋: 先FH获取buff, 再用增强PoH群刷
        -- 圣光涌动: 变为瞬发, 省蓝
        -- 灵魂之井: 治疗祈祷也可消耗圣光涌动
        -- 2层/即将过期时必须消耗, 有灵魂之井时走正常FH/PoH比较
        --========================================

        -- 4.0 织光者: 无buff时先FH获取buff, 为下次PoH增强做准备
        -- 移动中跳过 (FH有读条), 除非圣光涌动使其瞬发
        if hasLightweaverTalent and predictedLwStacks == 0
            and (not isMoving or surgeActive) then
            if lowestUnit and IsReady(SPELL.FlashHeal) and not ShouldSkipSpell(SPELL.FlashHeal) then
                return "spell", SPELL.FlashHeal, lowestUnit
            end
        end

        local hasSpiritwell = HasTalent(TALENT.Spiritwell)
        local surgeUrgent = surgeStacks >= 2 or (surgeActive and surgeRemain < NCF.gcd_max * 3)

        if surgeUrgent and lowestUnit then
            if hasSpiritwell and HasTalent(TALENT.PrayerOfHealing) and IsReady(SPELL.PrayerOfHealing) and not ShouldSkipSpell(SPELL.PrayerOfHealing) then
                -- 灵魂之井: PoH也能消耗圣光涌动, 走正常比较选更优
                if ShouldCastPrayerOfHealing(members, sp, surgeActive, predictedLwStacks, fhBonusMult, benedictionActive) then
                    return "spell", SPELL.PrayerOfHealing, lowestUnit
                end
            end
            -- 无灵魂之井或PoH不划算: 用FH消耗
            if IsReady(SPELL.FlashHeal) and not ShouldSkipSpell(SPELL.FlashHeal) then
                return "spell", SPELL.FlashHeal, lowestUnit
            end
        end

        -- 紧急单体: 最低血量比团队平均低30%以上, 先FH稳住再群刷
        if lowestUnit and (avgHp - lowestHp) > 30 and IsReady(SPELL.FlashHeal) and not ShouldSkipSpell(SPELL.FlashHeal) then
            return "spell", SPELL.FlashHeal, lowestUnit
        end

        -- 非紧急: 正常FH vs PoH比较
        if lowestUnit and HasTalent(TALENT.PrayerOfHealing) and IsReady(SPELL.PrayerOfHealing) and not ShouldSkipSpell(SPELL.PrayerOfHealing) then
            if ShouldCastPrayerOfHealing(members, sp, surgeActive, predictedLwStacks, fhBonusMult, benedictionActive) then
                return "spell", SPELL.PrayerOfHealing, lowestUnit
            end
        end

        -- 快速治疗: 默认单体治疗
        if lowestUnit and IsReady(SPELL.FlashHeal) and not ShouldSkipSpell(SPELL.FlashHeal) then
            return "spell", SPELL.FlashHeal, lowestUnit
        end

        --========================================
        -- 5. DPS输出 (最低优先级)
        --========================================

        -- 5.1 暗言术：灭: 任何敌人血量 < 20% (瞬发, 不需要面朝)
        if HasTalent(TALENT.ShadowWordDeath) and IsReady(SPELL.ShadowWordDeath) and not ShouldSkipSpell(SPELL.ShadowWordDeath) then
            local executeTarget = FindLowHealthEnemy(20, 40)
            if executeTarget then
                return "InstantSpell", SPELL.ShadowWordDeath, executeTarget
            end
        end

        -- 5.2 圣言术：罚: 对血量最低的敌人 (瞬发, 不需要面朝)
        if HasTalent(TALENT.HolyWordChastise) and IsReady(SPELL.HolyWordChastise) and not ShouldSkipSpell(SPELL.HolyWordChastise) then
            local chastiseTarget = FindLowestHealthEnemy(30)
            if chastiseTarget then
                return "InstantSpell", SPELL.HolyWordChastise, chastiseTarget
            end
        end

        -- 5.3 神圣之火: 优先无debuff的敌人, 其次血量最低 (炽热星火buff下瞬发, 否则需要站桩)
        if HasTalent(TALENT.HolyFire) and IsReady(SPELL.HolyFire) and not ShouldSkipSpell(SPELL.HolyFire) then
            if HasBuff(BUFF.EmpyrealBlaze, "player") then
                local fireTarget = GetEnemyWithoutDebuff(DEBUFF.HolyFire, 40, false, SPELL.HolyFire) or FindLowestHealthEnemy(40)
                if fireTarget then
                    return "InstantSpell", SPELL.HolyFire, fireTarget
                end
            elseif not isMoving then
                local fireTarget = GetEnemyWithoutDebuff(DEBUFF.HolyFire, 40, false, SPELL.HolyFire)
                if fireTarget then
                    return "spell", SPELL.HolyFire, fireTarget
                else
                    return "spell", SPELL.HolyFire
                end
            end
        end

        -- 5.4 神圣新星: 8码内敌人 >= 2
        local meleeEnemies = GetActiveEnemyAmount(8, false)
        if meleeEnemies >= 2 and IsReady(SPELL.HolyNova) and not ShouldSkipSpell(SPELL.HolyNova) then
            return "spell", SPELL.HolyNova
        end

        -- 5.5 惩击: 填充 (需要站桩)
        if not isMoving and IsReady(SPELL.Smite) and not ShouldSkipSpell(SPELL.Smite) then
            return "spell", SPELL.Smite
        end

        return nil
    end

    return Rotation
end

return CreateHolyRotation()
