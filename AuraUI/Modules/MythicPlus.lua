-- Modules/MythicPlus.lua: Mythic+ Keystone Timer, Death Counter & Affixes HUD
local addonName, addonTable = ...

local MythicPlus = addonTable:NewModule("MythicPlus")

function MythicPlus:OnInitialize()
    addonTable:Debug("MythicPlus Module Initialized.")
end

function MythicPlus:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.mythicPlus or not profile.mythicPlus.enabled then return end

    self:CreateHUD(profile.layout.MythicPlus)
end

function MythicPlus:CreateHUD(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_MythicPlusHUD", UIParent, "BackdropTemplate")
    container:SetSize(180, 50)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOPLEFT", UIParent, layoutConfig.relPoint or "TOPLEFT", layoutConfig.x or 200, layoutConfig.y or -20)
    else
        container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 200, -20)
    end

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    container:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local text = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", container, "CENTER", 0, 0)
    text:SetText("Mythic+ Timer Ready")

    addonTable.engine.EditMode:RegisterMover(container, "Mythic+ Timer", "MythicPlus")
    self.container = container
end

function MythicPlus:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.MythicPlus and self.container then
        local config = newProfile.layout.MythicPlus
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "TOPLEFT", UIParent, config.relPoint or "TOPLEFT", config.x or 200, config.y or -20)
    end
end

