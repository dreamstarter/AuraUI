-- Modules/SkyridingHUD.lua: Skyriding / Dragonriding Vigor Bar HUD & Speedometer
local addonName, addonTable = ...

local SkyridingHUD = addonTable:NewModule("SkyridingHUD")

function SkyridingHUD:OnInitialize()
    addonTable:Debug("SkyridingHUD Module Initialized.")
end

function SkyridingHUD:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.skyridingHUD or not profile.skyridingHUD.enabled then return end

    self:CreateHUD(profile.layout.SkyridingHUD)
end

function SkyridingHUD:CreateHUD(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_SkyridingHUD", UIParent, "BackdropTemplate")
    container:SetSize(200, 30)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "CENTER", UIParent, layoutConfig.relPoint or "CENTER", layoutConfig.x or 0, layoutConfig.y or -160)
    else
        container:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
    end

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    container:SetBackdropBorderColor(0, 0.8, 1, 1)

    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", container, "CENTER", 0, 0)
    text:SetText("Skyriding Speed: 100%")

    addonTable.engine.EditMode:RegisterMover(container, "Skyriding HUD", "SkyridingHUD")
    self.container = container
end

function SkyridingHUD:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.SkyridingHUD and self.container then
        local config = newProfile.layout.SkyridingHUD
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "CENTER", UIParent, config.relPoint or "CENTER", config.x or 0, config.y or -160)
    end
end

