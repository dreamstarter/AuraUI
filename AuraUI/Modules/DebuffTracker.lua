-------------------------------------------------------------------------------
-- AuraUI / Modules / DebuffTracker.lua
-- Debuff Priority Tracker
-- Large icon display for important debuffs on player/target, with countdown
-- timers and flashing warnings at < 3 seconds remaining.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local DebuffTracker = addonTable:NewModule("DebuffTracker")

-------------------------------------------------------------------------------
-- Default priority debuff lists per class
-- Keys are class names returned by select(2, UnitClass("player"))
-- Values are arrays of { spellID, label } pairs
-------------------------------------------------------------------------------
local CLASS_DEBUFFS = {
    WARRIOR = {
        { id = 12867, label = "Deep Wounds" },   -- Warrior Deep Wounds
        { id = 7922,  label = "Charge Stun" },
    },
    MAGE = {
        { id = 22959, label = "Scorch" },
        { id = 12654, label = "Ignite" },
    },
    WARLOCK = {
        { id = 17877, label = "Curse of Doom" },
        { id = 1490,  label = "CoE" },           -- Curse of Elements
        { id = 702,   label = "CoW" },           -- Curse of Weakness
    },
    PRIEST = {
        { id = 2944, label = "Devouring Plague" },
        { id = 589,  label = "SW:Pain" },
    },
    DRUID = {
        { id = 1079, label = "Rip" },
        { id = 8647, label = "Expose Armor" },
    },
    ROGUE = {
        { id = 8647, label = "Expose Armor" },
        { id = 2818, label = "Deadly Poison" },
    },
    SHAMAN = {
        { id = 8050, label = "Flame Shock" },
        { id = 3600, label = "Earthbind" },
    },
    PALADIN = {
        { id = 20066, label = "Repentance" },
        { id = 10326, label = "Turn Evil" },
    },
    HUNTER = {
        { id = 3043, label = "Scorpid Sting" },
        { id = 1978, label = "Serpent Sting" },
    },
}

-- Fallback list for unlisted classes
local DEFAULT_DEBUFFS = {
    { id = 0, label = "Debuff 1" },
}

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local ICON_SIZE      = 48
local ICON_SPACING   = 4
local WARN_THRESHOLD = 3.0     -- seconds — icon flashes below this
local FLASH_SPEED    = 4.0     -- alpha cycles per second
local MAX_ICONS      = 6

-------------------------------------------------------------------------------
-- Frame helpers
-------------------------------------------------------------------------------
local function CreateDebuffIcon(parent, index)
    local x = (index - 1) * (ICON_SIZE + ICON_SPACING)

    local cell = CreateFrame("Frame", nil, parent)
    cell:SetSize(ICON_SIZE, ICON_SIZE)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)

    -- Spell icon texture
    local icon = cell:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    cell.icon = icon

    -- Dark overlay (desaturate when inactive)
    local overlay = cell:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints(icon)
    overlay:SetColorTexture(0, 0, 0, 0.5)
    overlay:Hide()
    cell.overlay = overlay

    -- Flash border (red when < WARN_THRESHOLD)
    local border = cell:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(1, 0, 0, 0)
    cell.border = border

    -- Countdown timer text
    local timer = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timer:SetPoint("CENTER")
    timer:SetTextColor(1, 1, 0.2, 1)
    cell.timerText = timer

    -- Label below
    local label = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", cell, "BOTTOM", 0, -1)
    label:SetTextColor(0.8, 0.8, 0.8, 0.9)
    label:SetText("")
    cell.labelText = label

    cell:Hide()
    return cell
end

local function CreateMainFrame()
    local totalWidth = MAX_ICONS * (ICON_SIZE + ICON_SPACING) - ICON_SPACING
    local f = CreateFrame("Frame", "AuraUIDebuffTrackerFrame", UIParent)
    f:SetSize(totalWidth, ICON_SIZE + 16)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    f.icons = {}
    for i = 1, MAX_ICONS do
        f.icons[i] = CreateDebuffIcon(f, i)
    end

    return f
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
DebuffTracker.frame     = nil
DebuffTracker.debuffs   = {}    -- current priority list for this character
DebuffTracker.flashTime = 0
DebuffTracker.enabled   = true

-------------------------------------------------------------------------------
-- Utility: scan aura slots on a unit for a given spellID
-------------------------------------------------------------------------------
local function FindDebuffOnUnit(unit, spellID)
    if spellID == 0 then return nil end
    for i = 1, 40 do
        local name, _, _, count, _, duration, expires, _, _, _, id =
            UnitDebuff(unit, i)
        if not name then break end
        if id == spellID then
            return {
                name     = name,
                count    = count or 1,
                duration = duration or 0,
                expires  = expires or 0,
            }
        end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Refresh: scan target + player for all priority debuffs and update icons
-------------------------------------------------------------------------------
local function Refresh(self)
    local icons    = self.frame.icons
    local debuffs  = self.debuffs
    local now      = GetTime()
    local shown    = 0

    for _, entry in ipairs(debuffs) do
        if shown >= MAX_ICONS then break end

        -- Check both "player" and "target" units
        local found = FindDebuffOnUnit("target", entry.id)
                   or FindDebuffOnUnit("player", entry.id)

        if found then
            shown = shown + 1
            local cell     = icons[shown]
            local timeLeft = (found.expires > 0) and (found.expires - now) or math.huge
            local isWarn   = (timeLeft < WARN_THRESHOLD and timeLeft < math.huge)

            -- Icon texture
            local tex = GetSpellTexture(entry.id)
            if tex then cell.icon:SetTexture(tex) end
            cell.overlay:Hide()

            -- Timer text
            if timeLeft < math.huge then
                cell.timerText:SetText(string.format("%.1f", timeLeft))
            else
                cell.timerText:SetText("")
            end

            -- Label
            cell.labelText:SetText(entry.label)

            -- Flash border
            if isWarn then
                cell.border:SetColorTexture(1, 0, 0, 0.8)
            else
                cell.border:SetColorTexture(0, 0.9, 1, 0.4)
            end

            cell:Show()
        end
    end

    -- Hide unused slots
    for i = shown + 1, MAX_ICONS do
        icons[i]:Hide()
    end
end

-------------------------------------------------------------------------------
-- OnUpdate
-------------------------------------------------------------------------------
local updateInterval = 0.1
local updateTimer    = 0

local function OnUpdate(self, elapsed)
    if not DebuffTracker.enabled then return end

    updateTimer = updateTimer + elapsed
    if updateTimer >= updateInterval then
        updateTimer = 0
        Refresh(DebuffTracker)
    end

    -- Animate flash on warn icons
    DebuffTracker.flashTime = DebuffTracker.flashTime + elapsed * FLASH_SPEED
    local alpha = 0.5 + 0.5 * math.abs(math.sin(DebuffTracker.flashTime * math.pi))
    for _, cell in ipairs(DebuffTracker.frame.icons) do
        if cell:IsShown() and cell.border:GetAlpha() > 0.5 then
            cell.border:SetAlpha(alpha)
        end
    end
end

-------------------------------------------------------------------------------
-- Event: reacquire debuff list on spec change
-------------------------------------------------------------------------------
local function OnPlayerLogin()
    local _, classID = UnitClass("player")
    DebuffTracker.debuffs = CLASS_DEBUFFS[classID] or DEFAULT_DEBUFFS
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------
function DebuffTracker:OnInitialize()
    self.frame = CreateMainFrame()
    self.frame:SetScript("OnUpdate", OnUpdate)

    -- Register with EditMode
    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "DebuffTracker", "debuffTrackerPos")
    end

    -- Load enabled state
    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.DebuffTracker ~= nil then
        self.enabled = AuraUIDB.modules.DebuffTracker
    end
end

function DebuffTracker:OnEnable()
    OnPlayerLogin()
    if self.enabled then
        self.frame:Show()
    end

    -- Also refresh on spec change
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LOGIN" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            OnPlayerLogin()
        end
    end)
end

function DebuffTracker:OnDisable()
    self.enabled = false
    self.frame:Hide()
end

