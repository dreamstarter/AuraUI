-- Modules/DamageMeter.lua: Built-in lightweight DPS/HPS meter & threat bar
local addonName, addonTable = ...

local DamageMeter = addonTable:NewModule("DamageMeter")

function DamageMeter:OnInitialize()
    addonTable:Debug("DamageMeter Module Initialized.")
end

function DamageMeter:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.damageMeter or not profile.damageMeter.enabled then return end

    self:CreateMeterFrame(profile.layout.DamageMeter)
end

function DamageMeter:CreateMeterFrame(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_DamageMeter", UIParent, "BackdropTemplate")
    container:SetSize(200, 140)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "BOTTOMRIGHT", UIParent, layoutConfig.relPoint or "BOTTOMRIGHT", layoutConfig.x or -20, layoutConfig.y or 40)
    else
        container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 40)
    end

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    container:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -6)
    title:SetText("AuraUI DPS Meter")

    addonTable.engine.EditMode:RegisterMover(container, "Damage Meter", "DamageMeter")
    self.container = container
end

function DamageMeter:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.DamageMeter and self.container then
        local config = newProfile.layout.DamageMeter
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "BOTTOMRIGHT", UIParent, config.relPoint or "BOTTOMRIGHT", config.x or -20, config.y or 40)
    end
end

