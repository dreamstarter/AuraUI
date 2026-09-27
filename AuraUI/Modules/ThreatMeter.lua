-------------------------------------------------------------------------------
-- AuraUI / Modules / ThreatMeter.lua
-- Threat Meter Lite
-- Lightweight threat display using UnitThreatSituation() for WoW: Forever.
-- Integrates with Engine/SoundAlerts.lua for 90%+ threat warning.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local ThreatMeter = addonTable:NewModule("ThreatMeter")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local UPDATE_INTERVAL  = 0.25   -- seconds between threat polls
local WARNING_THRESHOLD = 90    -- percent — triggers sound alert
local MAX_PARTY_SIZE   = 40     -- handles up to full raid
local BAR_WIDTH        = 180
local BAR_HEIGHT       = 14
local BAR_SPACING      = 2
local FRAME_PADDING    = 8

-------------------------------------------------------------------------------
-- Threat color levels (mirrors WoW's built-in threat colors)
-- UnitThreatSituation returns: nil=no threat, 0=low, 1=medium, 2=high, 3=tanking
-------------------------------------------------------------------------------
local THREAT_COLORS = {
    [0] = { r = 0.07, g = 1.00, b = 0.07 },  -- green  — safe
    [1] = { r = 1.00, g = 0.65, b = 0.00 },  -- orange — caution
    [2] = { r = 1.00, g = 0.00, b = 0.00 },  -- red    — danger
    [3] = { r = 0.43, g = 0.67, b = 1.00 },  -- blue   — tanking
}

-------------------------------------------------------------------------------
-- Frame helpers
-------------------------------------------------------------------------------
local function CreateThreatBar(parent, index)
    local y = -FRAME_PADDING - (index - 1) * (BAR_HEIGHT + BAR_SPACING)

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(BAR_WIDTH, BAR_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", FRAME_PADDING, y)

    -- Background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)

    -- Fill bar
    local fill = row:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMLEFT")
    fill:SetWidth(1)  -- starts at 1 px
    fill:SetColorTexture(0.07, 1, 0.07, 0.9)
    row.fill = fill

    -- Name label
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    name:SetPoint("LEFT", 3, 0)
    name:SetTextColor(1, 1, 1, 0.9)
    name:SetJustifyH("LEFT")
    row.nameLabel = name

    -- Percent label
    local pct = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pct:SetPoint("RIGHT", -3, 0)
    pct:SetTextColor(1, 1, 1, 0.9)
    pct:SetJustifyH("RIGHT")
    row.pctLabel = pct

    row:Hide()
    return row
end

local function CreateMainFrame()
    local f = CreateFrame("Frame", "AuraUIThreatMeterFrame", UIParent, "BackdropTemplate")
    f:SetSize(BAR_WIDTH + FRAME_PADDING * 2, 200)   -- height is dynamic
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 200, -200)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    -- Header
    local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOP", f, "TOP", 0, -4)
    header:SetText("|cff00e5ffThreat|r")
    f.header = header

    -- Backdrop
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.03, 0.03, 0.03, 0.85)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
    end

    -- Bars pool (up to 40)
    f.bars = {}
    for i = 1, MAX_PARTY_SIZE do
        f.bars[i] = CreateThreatBar(f, i + 1)  -- +1 to leave room for header
    end

    return f
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
ThreatMeter.frame         = nil
ThreatMeter.updateTimer   = 0
ThreatMeter.warnedUnits   = {}   -- track which units already triggered the sound
ThreatMeter.enabled       = true

-------------------------------------------------------------------------------
-- Core update logic
-------------------------------------------------------------------------------
local function GetUnitThreatPct(unit)
    local status = UnitThreatSituation("player", unit)
    if not status then return nil, nil end
    local _, _, _, percent = UnitDetailedThreatSituation("player", unit)
    return status, (percent or 0)
end

local function UpdateBars(self)
    local bars     = self.frame.bars
    local rowIndex = 0
    local soundAlerts = addonTable.engine.SoundAlerts

    -- Gather units — try raid first, then party
    local units = {}
    local raidSize = GetNumGroupMembers()
    if raidSize > 0 then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, raidSize do
            units[#units + 1] = prefix .. i
        end
    end
    units[#units + 1] = "target"  -- always show target threat

    -- Collect threat data
    local data = {}
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local status, pct = GetUnitThreatPct(unit)
            if status then
                data[#data + 1] = {
                    name   = UnitName(unit) or unit,
                    status = status,
                    pct    = pct,
                    unit   = unit,
                }
            end
        end
    end

    -- Sort by pct descending
    table.sort(data, function(a, b) return a.pct > b.pct end)

    -- Render bars
    for i, entry in ipairs(data) do
        local bar = bars[i]
        if not bar then break end

        local col = THREAT_COLORS[entry.status] or THREAT_COLORS[0]
        bar.fill:SetColorTexture(col.r, col.g, col.b, 0.9)
        bar.fill:SetWidth(math.max(1, (entry.pct / 100) * BAR_WIDTH))
        bar.nameLabel:SetText(entry.name)
        bar.pctLabel:SetText(string.format("%d%%", entry.pct))
        bar:Show()
        rowIndex = i

        -- Sound alert: integrate with SoundAlerts engine
        if entry.pct >= WARNING_THRESHOLD and entry.status == 2 then
            if not self.warnedUnits[entry.unit] then
                self.warnedUnits[entry.unit] = true
                if soundAlerts and soundAlerts.PlayAlert then
                    soundAlerts:PlayAlert("Interrupt")   -- reuse interrupt sound for now
                end
            end
        else
            self.warnedUnits[entry.unit] = nil
        end
    end

    -- Hide unused bars
    for i = rowIndex + 1, MAX_PARTY_SIZE do
        if bars[i] then bars[i]:Hide() end
    end

    -- Resize frame to fit content
    local newHeight = FRAME_PADDING * 2 + 18 + rowIndex * (BAR_HEIGHT + BAR_SPACING)
    self.frame:SetHeight(math.max(40, newHeight))
end

-------------------------------------------------------------------------------
-- OnUpdate
-------------------------------------------------------------------------------
local function OnUpdate(self, elapsed)
    local tm = ThreatMeter
    if not tm.enabled then return end

    tm.updateTimer = tm.updateTimer + elapsed
    if tm.updateTimer >= UPDATE_INTERVAL then
        tm.updateTimer = 0
        UpdateBars(tm)
    end
end

-------------------------------------------------------------------------------
-- Slash command
-------------------------------------------------------------------------------
local function HandleSlash(msg)
    if msg == "threat" then
        local f = ThreatMeter.frame
        if f:IsShown() then f:Hide() else f:Show() end
    end
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------
function ThreatMeter:OnInitialize()
    self.frame = CreateMainFrame()
    self.frame:SetScript("OnUpdate", OnUpdate)

    -- Register with EditMode
    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "ThreatMeter", "threatMeterPos")
    end

    -- Load saved state
    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.ThreatMeter ~= nil then
        self.enabled = AuraUIDB.modules.ThreatMeter
    end
end

function ThreatMeter:OnEnable()
    if self.enabled then
        self.frame:Show()
    end

    -- Extend the /aui slash handler
    local orig = SLASH_AURAUI1 and SlashCmdList["AURAUI"]
    if orig then
        local wrapped = SlashCmdList["AURAUI"]
        SlashCmdList["AURAUI"] = function(msg)
            HandleSlash(msg)
            wrapped(msg)
        end
    end
end

function ThreatMeter:OnDisable()
    self.enabled = false
    self.frame:Hide()
end

