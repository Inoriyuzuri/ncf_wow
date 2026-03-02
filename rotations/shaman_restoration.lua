--============================================================
-- 恢复萨满循环 (Restoration Shaman APL)
-- 12.0 Midnight 版本
--============================================================

--[[
优先级列表:

=== 战前增益 (战斗内外均维护) ===
- 天空之怒 (462854): 自己没有buff 462854
- 大地之盾 (974 天赋): 对自己/坦克施放, 没有buff 383648
- 水之护盾 (52127): 自己没有buff 52127

=== 中断 ===
- 风剪 (57994): 打断施法

=== 防御 ===
- 星界位移 (108271 天赋): 自己血量 < 40%
- 大地元素 (198103 天赋): 自己血量 < 75%

=== 净化 (自动/鼠标模式) ===
- 净化灵魂 (77130): 驱散魔法效果

=== 升腾 (burst) ===
- 升腾 (114052): 团队均值血量 <= 80%

=== 治疗循环 ===
1.   生命释放 (73685 天赋)
1.1  先祖迅捷 (443454 天赋): 有人血量比均值低30%
1.2  治疗波: 对血量比均值低30%的目标
1.2.1 暴风溪流图腾 (1267068): buff 1267089存在 且 (剩余<5s 或 缺血>治疗量 或 均值<80%)
1.3  治疗之泉图腾 (5394 天赋): 充能>=2 且 无暴风溪流buff
1.4  治疗之泉图腾 (5394 天赋): 充能>1 且 无暴风溪流buff 且 均值<90%
2.   激流: 充能 > 2.8
3.   激流: 凝聚之水 == 2层
4.   治疗波/治疗链 (缺血计算): 潮汐之波 >= 3层
5.   激流: 凝聚之水 >= 1层
6.   治疗波/治疗链 (缺血计算): 有潮汐之波
7.   激流
8.   治疗波/治疗链 (缺血计算)

ID 参考:
Buff:  天空之怒=462854, 大地之盾=383648, 水之护盾=52127, 激流=61295
       升腾=114052, 潮汐之波=53390, 凝聚之水=470077, 暴风溪流=1267089
       生命释放=73685, 先祖迅捷=443454
天赋:  大地之盾=974, 激流锚定=382039, 洪涌=200076, 潮汐之波=51564
       凝聚之水=470076, 治疗之泉=5394, 生命释放=73685, 先祖迅捷=443454
       星界位移=108271, 大地元素=198103
]]

--============================================================
-- 1. 注册技能列表
--============================================================
NCF.RegisterSpells("SHAMAN", 3, {
    -- 爆发技能
    { id = 114052,  name = "升腾",            default = "burst"  },

    -- 治疗技能
    { id = 1064,    name = "治疗链",          default = "normal" },
    { id = 77472,   name = "治疗波",          default = "normal" },
    { id = 61295,   name = "激流",            default = "normal" },
    { id = 5394,    name = "治疗之泉图腾",    default = "normal" },
    { id = 1267068, name = "暴风溪流图腾",    default = "normal" },
    { id = 73685,   name = "生命释放",        default = "normal" },
    { id = 443454,  name = "先祖迅捷",        default = "normal" },

    -- 防御技能
    { id = 108271,  name = "星界位移",        default = "normal" },
    { id = 198103,  name = "大地元素",        default = "normal" },

    -- Buff技能
    { id = 462854,  name = "天空之怒图腾",    default = "normal" },
    { id = 974,     name = "大地之盾",        default = "normal" },
    { id = 52127,   name = "水之护盾",        default = "normal" },

    -- 功能技能
    { id = 77130,   name = "净化灵魂",        default = "normal" },
    { id = 57994,   name = "风剪",            default = "normal" },

})

--============================================================
-- 2. 技能ID定义
--============================================================
local SPELL = {
    -- 治疗
    ChainHeal          = 1064,
    HealingWave        = 77472,
    Riptide            = 61295,
    HealingStreamTotem = 5394,
    StormstreamTotem   = 1267068,
    UnleashLife        = 73685,
    AncestralSwiftness = 443454,
    Ascendance         = 114052,
    -- 防御
    AstralShift        = 108271,
    EarthElemental     = 198103,
    -- Buff
    Skyfury            = 462854,
    EarthShield        = 974,
    WaterShield        = 52127,
    -- 功能
    PurifySpirit       = 77130,
    WindShear          = 57994,
}

--============================================================
-- 3. Buff ID定义
--============================================================
local BUFF = {
    Skyfury            = 462854,
    EarthShield        = 383648,   -- 自身buff ID
    EarthShieldTank    = 974,      -- 坦克侧buff ID
    WaterShield        = 52127,
    Riptide            = 61295,
    Ascendance         = 114052,
    TidalWaves         = 53390,
    CoalescingWater    = 470077,
    StormstreamTotem   = 1267089,
    UnleashLife        = 73685,
    AncestralSwiftness = 443454,
}

--============================================================
-- 4. 天赋ID定义
--============================================================
local TALENT = {
    EarthShield        = 974,
    ChainHealRiptide   = 382039,    -- 治疗链优先激流目标 (+30%)
    Deluge             = 200076,    -- 对有激流的目标 +15%
    TidalWaves         = 51564,
    CoalescingWater    = 470076,
    HealingStreamTotem = 5394,
    UnleashLife        = 73685,
    AncestralSwiftness = 443454,
    AstralShift        = 108271,
    EarthElemental     = 198103,
}

--============================================================
-- 6. 从全局 NCF 表获取函数
--============================================================
local HasBuff               = NCF.HasBuff
local GetBuffRemain         = NCF.GetBuffRemain
local GetBuffStacks         = NCF.GetBuffStacks
local HasTalent             = NCF.HasTalent
local IsSpellInRange        = NCF.IsSpellInRange
local GetSpellCooldownRemain = NCF.GetSpellCooldownRemain
local GetSpellCharges       = NCF.GetSpellCharges
local ShouldSkipSpell       = NCF.ShouldSkipSpell
local SetEnemyCount         = NCF.SetEnemyCount
local GetActiveEnemyAmount  = NCF.GetActiveEnemyAmount
local GetGroupAverageHealthPct = NCF.GetGroupAverageHealthPct
local GetLowestHealthMember = NCF.GetLowestHealthMember
local GetTankUnit           = NCF.GetTankUnit
local GetUnitHealthPct      = NCF.GetUnitHealthPct
local GetTrueDeficit        = NCF.GetTrueDeficit
local GetDispellableUnit    = NCF.GetDispellableUnit

--============================================================
-- 7. 净化面板 (净化模式 + 缺血面板)
--============================================================
if not NCF.shamanPurifyMode then
    NCF.shamanPurifyMode = "auto"
end
if not NCF.shamanHealMode then
    NCF.shamanHealMode = "mana"     -- "mana" = 法力效率优先 | "hps" = 治疗量优先
end
if not NCF.shamanHealModeKey then
    NCF.shamanHealModeKey = ""
end

local shamanPanel = nil

local function CreateShamanPanel()
    local BACKDROP = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 },
    }
    local PANEL_WIDTH        = 220
    local ROW_HEIGHT         = 20
    local ROW_SPACING        = 24
    local DEFICIT_ROW_HEIGHT = 14
    local DEFICIT_COUNT      = 5
    local PADDING            = 5

    local controlHeight = PADDING + ROW_SPACING * 3 + PADDING
    local deficitHeight = 2 + DEFICIT_ROW_HEIGHT * (DEFICIT_COUNT + 1)
    local totalHeight   = controlHeight + deficitHeight + PADDING

    local frame = CreateFrame("Frame", "NCFShamanPanel", UIParent, "BackdropTemplate")
    frame:SetSize(PANEL_WIDTH, totalHeight)
    local screenW = GetScreenWidth()
    frame:SetPoint("LEFT", UIParent, "LEFT", screenW / 6 - PANEL_WIDTH / 2, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

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
    -- 净化模式下拉菜单
    --========================================
    local purifyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    purifyLabel:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2))
    purifyLabel:SetText("净化模式:")
    purifyLabel:SetTextColor(0.9, 0.8, 0.5)

    local purifyModes = {
        { value = "auto",      text = "|cFF00FF00自动净化|r" },
        { value = "mouseover", text = "|cFFFFFF00鼠标净化|r" },
    }

    local purifyBtn = CreateFrame("Button", nil, frame)
    purifyBtn:SetSize(120, 20)
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
    purifyDdLabel:SetText(NCF.shamanPurifyMode == "mouseover"
        and "|cFFFFFF00鼠标净化|r" or "|cFF00FF00自动净化|r")

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
    purifyPopup:SetSize(120, #purifyModes * ROW_HEIGHT + 2)
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
        row:SetSize(118, ROW_HEIGHT)
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
            NCF.shamanPurifyMode = mode.value
            purifyDdLabel:SetText(mode.text)
            purifyPopup:Hide()
            print(string.format("|cFF00FF00[NCF 恢复萨满]|r 净化模式: %s", mode.text))
        end)
    end

    --========================================
    -- Row 2: 治疗模式切换按钮
    --========================================
    local modeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2 + ROW_SPACING))
    modeLabel:SetText("治疗模式:")
    modeLabel:SetTextColor(0.9, 0.8, 0.5)

    local function GetModeText()
        return NCF.shamanHealMode == "mana"
            and "|cFF00CCFF法力效率|r"
            or  "|cFFFFAA00治疗量优先|r"
    end

    local modeBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    modeBtn:SetSize(120, 20)
    modeBtn:SetPoint("LEFT", modeLabel, "RIGHT", 6, 0)
    modeBtn:SetBackdrop(BACKDROP)
    modeBtn:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
    modeBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local modeBtnLabel = modeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeBtnLabel:SetPoint("CENTER")
    modeBtnLabel:SetText(GetModeText())

    modeBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.18, 0.18, 0.9)
        self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    modeBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.12, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    modeBtn:SetScript("OnClick", function()
        NCF.shamanHealMode = NCF.shamanHealMode == "mana" and "hps" or "mana"
        modeBtnLabel:SetText(GetModeText())
        print(string.format("|cFF00FF00[NCF 恢复萨满]|r 治疗模式: %s", GetModeText()))
    end)

    --========================================
    -- Row 3: 快捷键设置
    --========================================
    local keybindLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keybindLabel:SetPoint("TOPLEFT", PADDING + 2, -(PADDING + 2 + ROW_SPACING * 2))
    keybindLabel:SetText("切换快捷键:")
    keybindLabel:SetTextColor(0.9, 0.8, 0.5)

    local function FormatKey(key)
        return (key and key ~= "") and key or "|cFF888888未设置|r"
    end

    local keyDisplay = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    keyDisplay:SetPoint("LEFT", keybindLabel, "RIGHT", 6, 0)
    keyDisplay:SetText(FormatKey(NCF.shamanHealModeKey))
    keyDisplay:SetTextColor(1, 1, 1)

    local setKeyBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    setKeyBtn:SetSize(40, 18)
    setKeyBtn:SetPoint("RIGHT", frame, "RIGHT", -PADDING, -(PADDING + 2 + ROW_SPACING * 2 + 1))
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

    -- 热键捕获 + 检测帧
    local capturing = false
    local hotkeyFrame = CreateFrame("Frame", "NCFShamanHotkeyFrame", UIParent)
    hotkeyFrame:EnableKeyboard(true)
    hotkeyFrame:SetPropagateKeyboardInput(true)
    hotkeyFrame:SetAllPoints()

    hotkeyFrame:SetScript("OnKeyDown", function(self, key)
        -- 忽略纯修饰键
        if key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT"
            or key == "LSHIFT" or key == "RSHIFT" then return end

        if capturing then
            capturing = false
            setKeyText:SetText("设置")
            setKeyBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
            if key == "ESCAPE" then
                -- 取消: 清除绑定
                NCF.shamanHealModeKey = ""
                keyDisplay:SetText(FormatKey(""))
            else
                local mod = ""
                if IsControlKeyDown() then mod = mod .. "CTRL-" end
                if IsAltKeyDown()     then mod = mod .. "ALT-"  end
                if IsShiftKeyDown()   then mod = mod .. "SHIFT-" end
                NCF.shamanHealModeKey = mod .. key
                keyDisplay:SetText(NCF.shamanHealModeKey)
            end
            return
        end

        -- 热键触发
        if NCF.shamanHealModeKey ~= "" then
            local mod = ""
            if IsControlKeyDown() then mod = mod .. "CTRL-" end
            if IsAltKeyDown()     then mod = mod .. "ALT-"  end
            if IsShiftKeyDown()   then mod = mod .. "SHIFT-" end
            if mod .. key == NCF.shamanHealModeKey then
                NCF.shamanHealMode = NCF.shamanHealMode == "mana" and "hps" or "mana"
                modeBtnLabel:SetText(GetModeText())
                print(string.format("|cFF00FF00[NCF 恢复萨满]|r 治疗模式: %s", GetModeText()))
            end
        end
    end)

    setKeyBtn:SetScript("OnClick", function(self)
        capturing = true
        setKeyText:SetText("...")
        self:SetBackdropColor(0.3, 0.5, 0.2, 0.9)
        self:SetBackdropBorderColor(0.5, 0.8, 0.3, 1)
        print("|cFF00FF00[NCF 恢复萨满]|r 请按下快捷键 (ESC 清除绑定)")
    end)

    --========================================
    -- 分隔线
    --========================================
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", PADDING, -controlHeight)
    sep:SetPoint("TOPRIGHT", -PADDING, -controlHeight)
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    --========================================
    -- 缺血面板
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
        local data = NCF.shamanDeficitData
        if not data then return end
        for i = 1, DEFICIT_COUNT do
            local d = data[i]
            if d then
                local color = d.hp < 50 and "FF4444" or (d.hp < 75 and "FFAA00" or "AAAAAA")
                deficitRows[i]:SetText(string.format("|cFF%s%s  %.0f%%  -%s|r",
                    color, d.name, d.hp, AbbreviateNumber(d.deficit)))
            else
                deficitRows[i]:SetText("")
            end
        end
    end)

    return frame
end

shamanPanel = CreateShamanPanel()

--============================================================
-- 8. 主循环
--============================================================
local function CreateRestorationRotation()

    -- 法术强度 (UnitStat 返回普通数字, 无需 secretunwrap)
    local function GetSpellPower()
        local _, sp = UnitStat("player", 4)
        return sp or 0
    end

    -- 激流目标选择: 最低血量且无激流buff → 最低血量 → 自己
    local function GetRiptideTarget(members, lowestUnit)
        local best, bestHp = nil, 101
        for _, unit in ipairs(members) do
            if IsSpellInRange(SPELL.Riptide, unit) and not HasBuff(BUFF.Riptide, unit) then
                local hp = GetUnitHealthPct(unit)
                if hp < bestHp then best, bestHp = unit, hp end
            end
        end
        return best or lowestUnit or "player"
    end

    --[[
        计算是否施放治疗链 (vs 治疗波)
        系数:
          治疗链: 1013% 主目标, 每次跳跃递减
            - 无升腾: 4跳, 每跳-30%
            - 有升腾: 7跳, 每跳-10%
            - 天赋382039: 优先有激流的目标, +30%
            - 洪涌天赋: 对有激流目标 +15%
          治疗波: 2116% (升腾: 4549%主+2274%副)
            - 洪涌天赋: 对有激流目标 +15%
        返回: shouldCastCH, chTarget, hwTarget
    ]]
    local function ShouldCastChainHeal(sp, members, lowestUnit)
        local hasAscendance    = HasBuff(BUFF.Ascendance, "player")
        local hasRiptideTalent = HasTalent(TALENT.ChainHealRiptide)
        local hasDeluge        = HasTalent(TALENT.Deluge)

        -- 治疗链锚定目标: 天赋382039时优先有激流buff的最低血量目标
        local chTarget = lowestUnit
        if hasRiptideTalent then
            local best, bestHp = nil, 101
            for _, unit in ipairs(members) do
                if IsSpellInRange(SPELL.ChainHeal, unit) and HasBuff(BUFF.Riptide, unit) then
                    local hp = GetUnitHealthPct(unit)
                    if hp < bestHp then best, bestHp = unit, hp end
                end
            end
            if best then chTarget = best end
        end

        -- 治疗链倍率
        local chMult = 1.0
        local chTargetHasRiptide = chTarget and HasBuff(BUFF.Riptide, chTarget)
        if hasRiptideTalent and chTargetHasRiptide then
            chMult = chMult * 1.30
        end
        if hasDeluge and chTargetHasRiptide then
            chMult = chMult * 1.15
        end

        -- 跳跃参数 (天赋382039: 额外+1跳)
        local jumps, reduce
        if hasAscendance then
            jumps  = 7
            reduce = 0.10
        else
            jumps  = 4
            reduce = 0.30
        end
        if hasRiptideTalent then jumps = jumps + 1 end

        local baseChHeal = sp * 10.13 * chMult

        -- 收集射程内所有成员的缺血量 (前两大值也用于暴风溪流判断)
        local deficits = {}
        for _, unit in ipairs(members) do
            if IsSpellInRange(SPELL.ChainHeal, unit) then
                local deficit = GetTrueDeficit(unit)
                if deficit > 0 then
                    deficits[#deficits + 1] = deficit
                end
            end
        end
        table.sort(deficits, function(a, b) return a > b end)

        -- 治疗链有效总量
        local chEffective = 0
        local currentHeal = baseChHeal
        for i = 0, jumps do
            if deficits[i + 1] then
                chEffective = chEffective + math.min(currentHeal, deficits[i + 1])
            end
            currentHeal = currentHeal * (1 - reduce)
        end

        -- 治疗波有效量
        local hwTarget = lowestUnit
        local hwMult = 1.0
        if hasDeluge and hwTarget and HasBuff(BUFF.Riptide, hwTarget) then
            hwMult = hwMult * 1.15
        end

        local hwEffective
        local mainDef = hwTarget and GetTrueDeficit(hwTarget) or 0
        if hasAscendance then
            local mainRaw   = sp * 45.49 * hwMult
            local splashRaw = sp * 22.74
            hwEffective = math.min(mainRaw, mainDef)
            if deficits[2] then
                hwEffective = hwEffective + math.min(splashRaw, deficits[2])
            end
        else
            hwEffective = math.min(sp * 21.16 * hwMult, mainDef)
        end

        -- 治疗链门槛: 至少3人缺血量 >= 500%sp, 否则优先治疗波
        local minDeficit = sp * 5.0
        local eligibleCount = 0
        for _, d in ipairs(deficits) do
            if d >= minDeficit then eligibleCount = eligibleCount + 1 end
        end

        -- 法力效率模式: CH需提供 >2.117x 治疗量才划算 (11250/5312)
        -- 治疗量优先模式: 直接比较有效治疗量
        local useChain
        if NCF.shamanHealMode == "mana" then
            useChain = eligibleCount >= 3 and (chEffective * 5312 > hwEffective * 11250)
        else
            useChain = eligibleCount >= 3 and chEffective > hwEffective
        end

        print(string.format("[NCF Shaman] CH=%.0f HW=%.0f eligible=%d/%d mode=%s → %s",
            chEffective, hwEffective, eligibleCount, #deficits, NCF.shamanHealMode,
            useChain and "Chain" or "Wave"))

        return useChain, chTarget, hwTarget
    end

    local function Rotation()
        local gcd = math.max(GetSpellCooldownRemain(61304), 0.25)
        local function IsReady(id) return GetSpellCooldownRemain(id) <= gcd end

        local enemyCount = GetActiveEnemyAmount(40, false)
        SetEnemyCount(enemyCount)

        local members  = NCF.GetGroupMembers()
        local avgHp    = GetGroupAverageHealthPct(40)
        local lowestUnit, lowestHp = GetLowestHealthMember(40, 100, SPELL.HealingWave, 10)
        local myHp     = GetUnitHealthPct("player")
        local tankUnit = GetTankUnit()
        local sp       = GetSpellPower()

        -- 施法预测: 正在施放治疗链/治疗波时
        --   潮汐之波 (天赋51564): -1层 (本次施法消耗)
        --   凝聚之水 (天赋470076): +1层 (本次施法积累, 上限2)
        local castSpellID = select(9, UnitCastingInfo("player"))
        if IsMidnight and castSpellID then castSpellID = secretunwrap(castSpellID) end
        local tidalStacks     = GetBuffStacks(BUFF.TidalWaves, "player")
        local coalescingStacks = GetBuffStacks(BUFF.CoalescingWater, "player")
        if castSpellID == SPELL.ChainHeal or castSpellID == SPELL.HealingWave then
            if HasTalent(TALENT.TidalWaves) and tidalStacks > 0 then
                tidalStacks = tidalStacks - 1
            end
            if HasTalent(TALENT.CoalescingWater) then
                coalescingStacks = math.min(coalescingStacks + 1, 2)
            end
        end

        -- 更新缺血面板数据 (每tick)
        do
            local sorted = {}
            for _, unit in ipairs(members) do
                local deficit = GetTrueDeficit(unit)
                if deficit > 0 then
                    sorted[#sorted + 1] = { unit = unit, deficit = deficit, hp = GetUnitHealthPct(unit) }
                end
            end
            table.sort(sorted, function(a, b) return a.deficit > b.deficit end)
            local data = {}
            for i = 1, math.min(5, #sorted) do
                local d = sorted[i]
                local rawName = UnitName(d.unit)
                if IsMidnight and rawName then rawName = secretunwrap(rawName) end
                data[i] = { name = rawName or d.unit, hp = d.hp, deficit = d.deficit }
            end
            NCF.shamanDeficitData = data
        end

        --========================================
        -- 中断
        --========================================
        if IsReady(SPELL.WindShear) and not ShouldSkipSpell(SPELL.WindShear) then
            local interruptTarget = NCF.GetInterruptTarget(30, false)
            if interruptTarget then
                return "InstantSpell", SPELL.WindShear, interruptTarget
            end
        end

        --========================================
        -- 战前增益 (战斗内外均维护)
        --========================================

        -- 天空之怒图腾
        if not HasBuff(BUFF.Skyfury, "player") and IsReady(SPELL.Skyfury)
            and not ShouldSkipSpell(SPELL.Skyfury) then
            return "spell", SPELL.Skyfury
        end

        -- 大地之盾 (天赋): 坦克无buff 974时补; 自己无buff 383648时补
        if HasTalent(TALENT.EarthShield) and IsReady(SPELL.EarthShield)
            and not ShouldSkipSpell(SPELL.EarthShield) then
            if tankUnit and IsSpellInRange(SPELL.EarthShield, tankUnit)
                and not HasBuff(BUFF.EarthShieldTank, tankUnit) then
                return "spell", SPELL.EarthShield, tankUnit
            end
            if not HasBuff(BUFF.EarthShield, "player") then
                return "spell", SPELL.EarthShield
            end
        end

        -- 水之护盾
        if not HasBuff(BUFF.WaterShield, "player") and IsReady(SPELL.WaterShield)
            and not ShouldSkipSpell(SPELL.WaterShield) then
            return "spell", SPELL.WaterShield
        end

        --========================================
        -- 战斗检查
        --========================================
        if not NCF.IsInCombat() then
            return "spell", 61304
        end

        --========================================
        -- 防御技能
        --========================================
        if HasTalent(TALENT.AstralShift) and myHp < 40
            and IsReady(SPELL.AstralShift) and not ShouldSkipSpell(SPELL.AstralShift) then
            return "spell", SPELL.AstralShift
        end

        if HasTalent(TALENT.EarthElemental) and myHp < 75
            and IsReady(SPELL.EarthElemental) and not ShouldSkipSpell(SPELL.EarthElemental) then
            return "spell", SPELL.EarthElemental
        end

        --========================================
        -- 净化灵魂
        --========================================
        if IsReady(SPELL.PurifySpirit) and not ShouldSkipSpell(SPELL.PurifySpirit) then
            if NCF.shamanPurifyMode == "mouseover" then
                if UnitExists("mouseover") and UnitIsFriend("player", "mouseover")
                    and IsSpellInRange(SPELL.PurifySpirit, "mouseover") then
                    return "spell", SPELL.PurifySpirit, "mouseover"
                end
            else
                local dispelTarget = GetDispellableUnit("Magic", 40)
                if dispelTarget then
                    return "spell", SPELL.PurifySpirit, dispelTarget
                end
            end
        end

        --========================================
        -- 升腾 (burst CD)
        --========================================
        if avgHp <= 80 and IsReady(SPELL.Ascendance)
            and not ShouldSkipSpell(SPELL.Ascendance) then
            return "spell", SPELL.Ascendance
        end

        --========================================
        -- 治疗循环
        --========================================

        -- 辅助状态
        local outlierUnit = (lowestUnit and (avgHp - lowestHp) >= 30) and lowestUnit or nil

        local hasStormstream    = HasBuff(BUFF.StormstreamTotem, "player")
        local stormstreamRemain = hasStormstream and GetBuffRemain(BUFF.StormstreamTotem, "player") or 0
        local sstHealPerTarget  = sp * 16.41

        -- 暴风溪流图腾触发条件
        local function ShouldCastStormstream()
            if not hasStormstream then return false end
            if not IsReady(SPELL.StormstreamTotem) then return false end
            if ShouldSkipSpell(SPELL.StormstreamTotem) then return false end
            if stormstreamRemain < 5 then return true end
            if avgHp < 80 then return true end
            -- 缺血量最大的两人各自超过暴风溪流的治疗量
            local d1, d2 = 0, 0
            for _, unit in ipairs(members) do
                local deficit = GetTrueDeficit(unit)
                if deficit > d1 then
                    d2 = d1
                    d1 = deficit
                elseif deficit > d2 then
                    d2 = deficit
                end
            end
            return d2 > sstHealPerTarget
        end

        local totemCharges = GetSpellCharges(SPELL.HealingStreamTotem) or 0

        -- 1. 生命释放
        if HasTalent(TALENT.UnleashLife) and IsReady(SPELL.UnleashLife)
            and not ShouldSkipSpell(SPELL.UnleashLife) then
            return "spell", SPELL.UnleashLife
        end

        -- 1.1 先祖迅捷: 有异常目标 (血量比均值低30%)
        if outlierUnit and HasTalent(TALENT.AncestralSwiftness)
            and not HasBuff(BUFF.AncestralSwiftness, "player")
            and IsReady(SPELL.AncestralSwiftness)
            and not ShouldSkipSpell(SPELL.AncestralSwiftness) then
            return "spell", SPELL.AncestralSwiftness
        end

        -- 1.2 治疗波: 对异常目标
        if outlierUnit and IsReady(SPELL.HealingWave) and not ShouldSkipSpell(SPELL.HealingWave) then
            return "spell", SPELL.HealingWave, outlierUnit
        end

        -- 1.2.1 暴风溪流图腾
        if ShouldCastStormstream() then
            return "spell", SPELL.StormstreamTotem
        end

        -- 1.3 治疗之泉图腾: 充能 >= 2 且无暴风溪流buff
        if HasTalent(TALENT.HealingStreamTotem) and totemCharges >= 2 and not hasStormstream
            and IsReady(SPELL.HealingStreamTotem) and not ShouldSkipSpell(SPELL.HealingStreamTotem) then
            return "spell", SPELL.HealingStreamTotem
        end

        -- 1.4 治疗之泉图腾: 充能 > 1 且无暴风溪流buff 且均值 < 90%
        if HasTalent(TALENT.HealingStreamTotem) and totemCharges > 1 and not hasStormstream
            and avgHp < 90
            and IsReady(SPELL.HealingStreamTotem) and not ShouldSkipSpell(SPELL.HealingStreamTotem) then
            return "spell", SPELL.HealingStreamTotem
        end

        local riptideCharges = GetSpellCharges(SPELL.Riptide) or 0

        -- 2. 激流: 充能 > 2.8
        if riptideCharges > 2.8 and IsReady(SPELL.Riptide) and not ShouldSkipSpell(SPELL.Riptide) then
            return "spell", SPELL.Riptide, GetRiptideTarget(members, lowestUnit)
        end

        -- 3. 激流: 凝聚之水 == 2 (上限, 防止浪费)
        if coalescingStacks >= 2 and IsReady(SPELL.Riptide) and not ShouldSkipSpell(SPELL.Riptide) then
            return "spell", SPELL.Riptide, GetRiptideTarget(members, lowestUnit)
        end

        -- 4. 治疗波/治疗链: 潮汐之波 >= 3层
        if tidalStacks >= 3 then
            local chReady = IsReady(SPELL.ChainHeal) and not ShouldSkipSpell(SPELL.ChainHeal)
            local hwReady = IsReady(SPELL.HealingWave) and not ShouldSkipSpell(SPELL.HealingWave)
            if chReady or hwReady then
                local useCH, chTarget, hwTarget = ShouldCastChainHeal(sp, members, lowestUnit)
                if useCH and chReady and chTarget then
                    return "spell", SPELL.ChainHeal, chTarget
                elseif hwReady and hwTarget then
                    return "spell", SPELL.HealingWave, hwTarget
                end
            end
        end

        -- 5. 激流: 凝聚之水 >= 1
        if coalescingStacks >= 1 and IsReady(SPELL.Riptide) and not ShouldSkipSpell(SPELL.Riptide) then
            return "spell", SPELL.Riptide, GetRiptideTarget(members, lowestUnit)
        end

        -- 6. 治疗波/治疗链: 有潮汐之波
        if tidalStacks >= 1 then
            local chReady = IsReady(SPELL.ChainHeal) and not ShouldSkipSpell(SPELL.ChainHeal)
            local hwReady = IsReady(SPELL.HealingWave) and not ShouldSkipSpell(SPELL.HealingWave)
            if chReady or hwReady then
                local useCH, chTarget, hwTarget = ShouldCastChainHeal(sp, members, lowestUnit)
                if useCH and chReady and chTarget then
                    return "spell", SPELL.ChainHeal, chTarget
                elseif hwReady and hwTarget then
                    return "spell", SPELL.HealingWave, hwTarget
                end
            end
        end

        -- 7. 激流
        if IsReady(SPELL.Riptide) and not ShouldSkipSpell(SPELL.Riptide) then
            return "spell", SPELL.Riptide, GetRiptideTarget(members, lowestUnit)
        end

        -- 8. 治疗波/治疗链
        do
            local chReady = IsReady(SPELL.ChainHeal) and not ShouldSkipSpell(SPELL.ChainHeal)
            local hwReady = IsReady(SPELL.HealingWave) and not ShouldSkipSpell(SPELL.HealingWave)
            if chReady or hwReady then
                local useCH, chTarget, hwTarget = ShouldCastChainHeal(sp, members, lowestUnit)
                if useCH and chReady and chTarget then
                    return "spell", SPELL.ChainHeal, chTarget
                elseif hwReady and hwTarget then
                    return "spell", SPELL.HealingWave, hwTarget
                end
            end
        end

        return nil
    end

    return Rotation
end

return CreateRestorationRotation()
