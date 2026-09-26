-- Modules/UnitFrames.lua: Custom Unit Frames (Player, Target, Focus, Pet, Boss)
local addonName, addonTable = ...

local UnitFrames = addonTable:NewModule("UnitFrames")
UnitFrames.frames = {}

function UnitFrames:OnInitialize()
    addonTable:Debug("UnitFrames Module Initialized.")
end

function UnitFrames:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    self:CreateUnitFrame("PlayerFrame", "player", "Player", profile.layout.PlayerFrame)
    self:CreateUnitFrame("TargetFrame", "target", "Target", profile.layout.TargetFrame)
    self:CreateUnitFrame("FocusFrame", "focus", "Focus", profile.layout.FocusFrame)
    self:CreateUnitFrame("PetFrame", "pet", "Pet", profile.layout.PetFrame)

    -- Register Event Updates
    addonTable:RegisterEvent("UNIT_HEALTH", function(event, unit)
        self:UpdateUnit(unit)
    end)
    addonTable:RegisterEvent("UNIT_MAXHEALTH", function(event, unit)
        self:UpdateUnit(unit)
    end)
    addonTable:RegisterEvent("UNIT_POWER_UPDATE", function(event, unit)
        self:UpdateUnit(unit)
    end)
    addonTable:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        self:UpdateUnit("target")
    end)
    addonTable:RegisterEvent("PLAYER_FOCUS_CHANGED", function()
        self:UpdateUnit("focus")
    end)

    -- Initial Update
    self:UpdateAll()
end

--- Constructs a custom unit frame.
--- @param frameName string Frame Identifier
--- @param unit string UnitId (e.g. "player", "target")
--- @param title string Display Title
--- @param layoutConfig table Saved layout point
function UnitFrames:CreateUnitFrame(frameName, unit, title, layoutConfig)
    if self.frames[unit] then return self.frames[unit] end

    local frame = CreateFrame("Button", "AuraUI_" .. frameName, UIParent, "SecureUnitButtonTemplate,BackdropTemplate")
    frame:SetSize(220, 42)
    frame:SetAttribute("unit", unit)
    RegisterUnitWatch(frame)

    -- Context menu registration
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")

    -- Backdrop Styling
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Position Frame
    if layoutConfig then
        frame:SetPoint(layoutConfig.point or "CENTER", UIParent, layoutConfig.relPoint or "CENTER", layoutConfig.x or 0, layoutConfig.y or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Health Bar
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetSize(216, 24)
    healthBar:SetPoint("TOP", frame, "TOP", 0, -2)
    healthBar:SetStatusBarTexture(addonTable.engine.Media:GetTexture("Flat"))
    healthBar:SetStatusBarColor(0.1, 0.8, 0.3, 1)

    -- Health Text
    local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    healthText:SetPoint("RIGHT", healthBar, "RIGHT", -6, 0)
    healthBar.Text = healthText

    -- Name Text
    local nameText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("LEFT", healthBar, "LEFT", 6, 0)
    nameText:SetText(title)
    healthBar.NameText = nameText

    -- Power Bar
    local powerBar = CreateFrame("StatusBar", nil, frame)
    powerBar:SetSize(216, 10)
    powerBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, -2)
    powerBar:SetStatusBarTexture(addonTable.engine.Media:GetTexture("Flat"))
    powerBar:SetStatusBarColor(0.1, 0.5, 0.9, 1)

    frame.unit = unit
    frame.healthBar = healthBar
    frame.powerBar = powerBar

    -- Register with EditMode Mover Engine
    addonTable.engine.EditMode:RegisterMover(frame, title .. " Frame", frameName)

    self.frames[unit] = frame
    return frame
end

--- Updates health/power values for a target unit frame.
--- @param unit string
function UnitFrames:UpdateUnit(unit)
    local frame = self.frames[unit]
    if not frame or not UnitExists(unit) then return end

    -- Update Health
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    frame.healthBar:SetMinMaxValues(0, maxHealth > 0 and maxHealth or 1)
    frame.healthBar:SetValue(health)

    local pct = maxHealth > 0 and math.floor((health / maxHealth) * 100) or 0
    frame.healthBar.Text:SetText(string.format("%s (%d%%)", AbbreviateNumbers and AbbreviateNumbers(health) or health, pct))

    -- Update Unit Name
    local name = UnitName(unit)
    if name then
        frame.healthBar.NameText:SetText(name)
    end

    -- Update Power
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    frame.powerBar:SetMinMaxValues(0, maxPower > 0 and maxPower or 1)
    frame.powerBar:SetValue(power)
end

--- Updates all active unit frames.
function UnitFrames:UpdateAll()
    for unit, frame in pairs(self.frames) do
        self:UpdateUnit(unit)
    end
end

--- Called when profile updates.
function UnitFrames:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout then
        for unit, frame in pairs(self.frames) do
            local frameKey = unit:sub(1,1):upper() .. unit:sub(2) .. "Frame"
            local config = newProfile.layout[frameKey]
            if config then
                frame:ClearAllPoints()
                frame:SetPoint(config.point or "CENTER", UIParent, config.relPoint or "CENTER", config.x or 0, config.y or 0)
            end
        end
    end
end
