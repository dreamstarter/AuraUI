if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
if not (AuraUI and AuraUI.IS_FOREVER) then return end
-------------------------------------------------------------------------------
--  AuraUIForeverEssentials_LootFeed.lua  (WoW Forever only)
--  Shows what you loot and gain (items, money, reputation, currencies and
--  skill ups) as short rows that fade out after a brief duration.
--  Supports 4 visual styles:
--    * accent (Accent Bar - colored vertical strip beside icon and text)
--    * tray   (Icon Tray - compact floating icon with counter badge)
--    * toast  (Loot Toast - Blizzard toast style banner)
--    * box    (Box - classic enclosed border frame)
-------------------------------------------------------------------------------
local ADDON_NAME, module = ...
local ns = module.LootFeed or {}
module.LootFeed = ns
local AUI = AuraUI

local DEFAULT_FADE_TIME = 4.0
local DEFAULT_WIDTH = 260
local DEFAULT_ROW_HEIGHT = 28
local MAX_ROWS = 6

-- Settings live in AuraUIDB.lootFeed
local DEFAULTS = {
    enabled = true,
    style = "accent", -- "accent", "tray", "toast", "box"
    width = 260,
    rowHeight = 28,
    fadeTime = 4.0,
    growUp = true,
    showItems = true,
    showMoney = true,
    showRep = true,
    showCurrency = true,
    showSkills = true,
    minQuality = 0, -- 0 = Poor, 1 = Common, etc.
}

local function Cfg()
    if not AuraUIDB then return {} end
    AuraUIDB.lootFeed = AuraUIDB.lootFeed or {}
    return AuraUIDB.lootFeed
end

local _NOCFG = {}
local function Read()
    return AuraUIDB and AuraUIDB.lootFeed or _NOCFG
end

local function Get(key)
    local v = Read()[key]
    if v == nil then return DEFAULTS[key] end
    return v
end

ns.Get = Get
ns.Cfg = Cfg

local container
local activeRows = {}
local rowPool = {}
local loopPreviewActive = false
local previewTicker = nil

local function GetQualityRGB(quality)
    if quality and C_Item and C_Item.GetItemQualityColor then
        local r, g, b = C_Item.GetItemQualityColor(quality)
        if r and g and b then return r, g, b end
    end
    if quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local c = ITEM_QUALITY_COLORS[quality]
        return c.r, c.g, c.b
    end
    return 1, 1, 1
end

local function ApplyRowStyle(row, style, r, g, b)
    r = r or 0.047
    g = g or 0.824
    b = b or 0.616

    -- Reset previous sub-regions
    if row.accentStrip then row.accentStrip:Hide() end
    if row.bg then row.bg:Hide() end
    if row.border then row.border:Hide() end

    if style == "accent" then
        -- Accent Bar: sleek dark glass, accent color vertical strip on left edge
        row.bg:SetColorTexture(0.04, 0.04, 0.04, 0.88)
        row.bg:Show()
        row.border:SetColorTexture(0.2, 0.25, 0.3, 0.6)
        row.border:Show()
        row.accentStrip:SetColorTexture(r, g, b, 1.0)
        row.accentStrip:ClearAllPoints()
        row.accentStrip:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
        row.accentStrip:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
        row.accentStrip:SetWidth(3)
        row.accentStrip:Show()
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    elseif style == "tray" then
        -- Icon Tray: minimal icon-focused design with subtle dark backing
        row.bg:SetColorTexture(0.02, 0.02, 0.02, 0.70)
        row.bg:Show()
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    elseif style == "toast" then
        -- Loot Toast: rounded appearance with prominent glow borders
        row.bg:SetColorTexture(0.08, 0.09, 0.11, 0.95)
        row.bg:Show()
        row.border:SetColorTexture(r, g, b, 0.8)
        row.border:Show()
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    else -- "box"
        -- Box: classic enclosed border
        row.bg:SetColorTexture(0.05, 0.05, 0.06, 0.90)
        row.bg:Show()
        row.border:SetColorTexture(0.4, 0.4, 0.4, 0.8)
        row.border:Show()
        row.icon:ClearAllPoints()
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    end
end

local function LayoutRows()
    if not container then return end
    local growUp = Get("growUp")
    local rowHeight = Get("rowHeight")
    local spacing = 3

    for i, row in ipairs(activeRows) do
        row:ClearAllPoints()
        local offset = (i - 1) * (rowHeight + spacing)
        if growUp then
            row:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, offset)
        else
            row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -offset)
        end
    end
end

local function ReleaseRow(row)
    for i, r in ipairs(activeRows) do
        if r == row then
            table.remove(activeRows, i)
            break
        end
    end
    row:Hide()
    row:SetScript("OnUpdate", nil)
    table.insert(rowPool, row)
    LayoutRows()
end

local function AcquireRow()
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, container)
        row:SetClampedToScreen(true)

        -- 1px border frame
        local border = row:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        row.border = border

        -- Inner background
        local bg = row:CreateTexture(nil, "BORDER")
        bg:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -1, 1)
        row.bg = bg

        -- Accent strip
        local accentStrip = row:CreateTexture(nil, "ARTWORK")
        row.accentStrip = accentStrip

        -- Icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        row.icon = icon

        -- Text
        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetFont(AuraUI.GetFontPath("essentials"), 11, AuraUI.GetFontOutlineFlag("essentials"))
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        row.text = text
    end
    return row
end

local function PushLootItem(text, iconTexture, qualityRGB)
    if not Get("enabled") and not loopPreviewActive then return end
    if not container then return end

    local row = AcquireRow()
    local rowWidth = Get("width")
    local rowHeight = Get("rowHeight")
    local iconSize = rowHeight - 6

    row:SetSize(rowWidth, rowHeight)
    row.icon:SetSize(iconSize, iconSize)
    row.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.text:SetText(text or "")

    local qr, qg, qb = 1, 1, 1
    if qualityRGB then
        qr, qg, qb = qualityRGB[1] or 1, qualityRGB[2] or 1, qualityRGB[3] or 1
    end

    local style = Get("style")
    ApplyRowStyle(row, style, qr, qg, qb)

    row:SetAlpha(1.0)
    row:Show()

    table.insert(activeRows, 1, row)
    while #activeRows > MAX_ROWS do
        ReleaseRow(activeRows[#activeRows])
    end

    LayoutRows()

    -- Fade timer
    local fadeTime = Get("fadeTime")
    local startTime = GetTime()
    local holdTime = math.max(0.5, fadeTime - 1.0)

    row:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local elapsed = now - startTime
        if elapsed >= fadeTime then
            ReleaseRow(self)
        elseif elapsed > holdTime then
            local remain = fadeTime - elapsed
            self:SetAlpha(remain / (fadeTime - holdTime))
        else
            self:SetAlpha(1.0)
        end
    end)
end

ns.PushLootItem = PushLootItem

-------------------------------------------------------------------------------
--  Live Events
-------------------------------------------------------------------------------
local function FormatMoneyString(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local str = ""
    if g > 0 then str = str .. format("%d|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t ", g) end
    if s > 0 then str = str .. format("%d|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t ", s) end
    if c > 0 or str == "" then str = str .. format("%d|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t", c) end
    return str
end

local function OnChatMsgLoot(msg)
    if not Get("showItems") then return end
    if not msg then return end

    -- Match item links
    local itemLink = msg:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)")
    if not itemLink then return end

    local count = msg:match("x(%d+)") or 1
    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    if itemQuality and itemQuality < Get("minQuality") then return end

    local countStr = tonumber(count) and tonumber(count) > 1 and (" x" .. count) or ""
    local displayText = itemLink .. countStr
    local r, g, b = GetQualityRGB(itemQuality)

    PushLootItem(displayText, itemTexture, { r, g, b })
end

local function OnChatMsgMoney(msg)
    if not Get("showMoney") then return end
    if not msg then return end

    local gold = tonumber(msg:match("(%d+)%s*Gold") or msg:match("(%d+)%s*gold") or 0) or 0
    local silver = tonumber(msg:match("(%d+)%s*Silver") or msg:match("(%d+)%s*silver") or 0) or 0
    local copper = tonumber(msg:match("(%d+)%s*Copper") or msg:match("(%d+)%s*copper") or 0) or 0
    local total = (gold * 10000) + (silver * 100) + copper
    if total <= 0 then return end

    local moneyStr = FormatMoneyString(total)
    local text = format("+ %s", moneyStr)
    PushLootItem(text, "Interface\\Icons\\INV_Misc_Coin_02", { 1.0, 0.84, 0.0 })
end

local function OnChatMsgFaction(msg)
    if not Get("showRep") then return end
    if not msg then return end
    -- Check reputation pattern: "Reputation with <Faction> increased by <Amount>."
    local faction, amount = msg:match("Reputation with (.-) increased by (%d+)")
    if not faction then
        faction, amount = msg:match("(.-) increased by (%d+)")
    end
    if faction and amount then
        local text = format("+%s %s", amount, faction)
        PushLootItem(text, "Interface\\Icons\\Achievement_Reputation_01", { 0.3, 0.7, 1.0 })
    end
end

local function OnChatMsgSkill(msg)
    if not Get("showSkills") then return end
    if not msg then return end
    -- Check skill pattern: "Your skill in <Skill> has increased to <Rank>."
    local skill, rank = msg:match("Your skill in (.-) has increased to (%d+)")
    if skill and rank then
        local text = format("%s (%s)", skill, rank)
        PushLootItem(text, "Interface\\Icons\\Trade_Engineering", { 0.8, 0.6, 1.0 })
    end
end

local function OnCurrencyUpdate(currencyID, quantity, quantityChange)
    if not Get("showCurrency") then return end
    if not currencyID or not quantityChange or quantityChange <= 0 then return end
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info and info.name then
        local text = format("+%d %s", quantityChange, info.name)
        PushLootItem(text, info.iconFileID or "Interface\\Icons\\INV_Misc_Coin_01", { 0.4, 0.8, 0.9 })
    end
end

-------------------------------------------------------------------------------
--  Container Frame & Unlock Mode
-------------------------------------------------------------------------------
local function CreateContainer()
    if container then return end
    container = CreateFrame("Frame", "AUI_LootFeed", UIParent)
    container:SetSize(Get("width"), Get("rowHeight") * MAX_ROWS)
    container:SetClampedToScreen(true)

    -- Saved position
    local pos = Read().pos
    if pos and pos.point then
        container:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -280, 220)
    end
end

local function ApplyPosition()
    if not container then return end
    local pos = Read().pos
    container:ClearAllPoints()
    if pos and pos.point then
        container:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -280, 220)
    end
end

local function Apply()
    CreateContainer()
    if not container then return end
    container:SetSize(Get("width"), Get("rowHeight") * MAX_ROWS)
    LayoutRows()
end

ns.Apply = Apply

local function RegisterUnlock()
    local MK = AuraUI.MakeUnlockElement
    local PPs = AuraUI.PP
    AuraUI:RegisterUnlockElements({
        MK({
            key      = "AUI_LootFeed",
            label    = "Loot Feed",
            group    = "Forever Essentials",
            order    = 735,
            isHidden = function() return not Get("enabled") end,
            getFrame = function()
                if not Get("enabled") then return nil end
                CreateContainer()
                return container
            end,
            getSize = function() return Get("width"), Get("rowHeight") * 3 end,
            setWidth = function(_, w)
                Cfg().width = math.max(150, PPs.Snap(w))
                Apply()
            end,
            setHeight = function(_, h)
                Cfg().rowHeight = math.max(20, math.floor(PPs.Snap(h) / 3))
                Apply()
            end,
            savePos = function(_, point, relPoint, x, y)
                if not point then return end
                Cfg().pos = { point = point, relPoint = relPoint, x = x, y = y }
                if container and not AuraUI._unlockActive then ApplyPosition() end
            end,
            loadPos = function()
                local pos = Read().pos
                if pos and pos.point then return pos end
                return { point = "BOTTOMRIGHT", relPoint = "BOTTOMRIGHT", x = -280, y = 220 }
            end,
            clearPos = function()
                Cfg().pos = nil
                if container then ApplyPosition() end
            end,
            applyPos = function()
                if not Get("enabled") then return end
                CreateContainer()
                ApplyPosition()
            end,
        }),
    }, "AuraUIForeverEssentials")
end

-------------------------------------------------------------------------------
--  Live Looping Preview for Options Page
-------------------------------------------------------------------------------
local SAMPLE_LOOT = {
    { text = "|cffa335ee[Netherblade Facemask]|r", icon = "Interface\\Icons\\INV_Helmet_08", rgb = { 0.64, 0.21, 0.93 } },
    { text = "+ 14|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t 32|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t", icon = "Interface\\Icons\\INV_Misc_Coin_02", rgb = { 1.0, 0.84, 0.0 } },
    { text = "|cff0070dd[Primal Nether]|r x2", icon = "Interface\\Icons\\INV_Misc_Gem_BloodGem_02", rgb = { 0.0, 0.44, 0.87 } },
    { text = "+250 Ashtongue Deathsworn", icon = "Interface\\Icons\\Achievement_Reputation_01", rgb = { 0.3, 0.7, 1.0 } },
    { text = "+15 Badge of Justice", icon = "Interface\\Icons\\Spell_Holy_ChampionsGrace", rgb = { 0.4, 0.8, 0.9 } },
    { text = "Tailoring (375)", icon = "Interface\\Icons\\Trade_Tailoring", rgb = { 0.8, 0.6, 1.0 } },
}

local sampleIndex = 1

function ns.StartLoopPreview()
    CreateContainer()
    loopPreviewActive = true
    if previewTicker then previewTicker:Cancel(); previewTicker = nil end

    -- Push initial sample immediately
    local s = SAMPLE_LOOT[sampleIndex]
    PushLootItem(s.text, s.icon, s.rgb)
    sampleIndex = (sampleIndex % #SAMPLE_LOOT) + 1

    if C_Timer and C_Timer.NewTicker then
        previewTicker = C_Timer.NewTicker(1.6, function()
            if not loopPreviewActive then return end
            local sample = SAMPLE_LOOT[sampleIndex]
            PushLootItem(sample.text, sample.icon, sample.rgb)
            sampleIndex = (sampleIndex % #SAMPLE_LOOT) + 1
        end)
    end
end

function ns.StopLoopPreview()
    loopPreviewActive = false
    if previewTicker then
        previewTicker:Cancel()
        previewTicker = nil
    end
    -- Clear active rows
    while #activeRows > 0 do
        ReleaseRow(activeRows[#activeRows])
    end
end

-------------------------------------------------------------------------------
--  Lifecycle / Boot
-------------------------------------------------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("CHAT_MSG_LOOT")
        self:RegisterEvent("CHAT_MSG_MONEY")
        self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
        self:RegisterEvent("CHAT_MSG_SKILL")
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        Apply()
        RegisterUnlock()
    elseif event == "CHAT_MSG_LOOT" then
        OnChatMsgLoot(...)
    elseif event == "CHAT_MSG_MONEY" then
        OnChatMsgMoney(...)
    elseif event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        OnChatMsgFaction(...)
    elseif event == "CHAT_MSG_SKILL" then
        OnChatMsgSkill(...)
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        OnCurrencyUpdate(...)
    end
end)
