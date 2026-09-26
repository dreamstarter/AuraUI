-- Modules/Cooldowns.lua: Spell Cooldown Manager & Timer Icons
local addonName, addonTable = ...

local Cooldowns = addonTable:NewModule("Cooldowns")

function Cooldowns:OnInitialize()
    addonTable:Debug("Cooldowns Module Initialized.")
end

function Cooldowns:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.cooldowns or not profile.cooldowns.enabled then return end

    self:CreateCooldownTracker(profile.layout.Cooldowns)
end

function Cooldowns:CreateCooldownTracker(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_CooldownTracker", UIParent)
    container:SetSize(240, 48)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "CENTER", UIParent, layoutConfig.relPoint or "CENTER", layoutConfig.x or 0, layoutConfig.y or -100)
    else
        container:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    end

    addonTable.engine.EditMode:RegisterMover(container, "Cooldown Manager", "Cooldowns")
    self.container = container
end

function Cooldowns:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.Cooldowns and self.container then
        local config = newProfile.layout.Cooldowns
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "CENTER", UIParent, config.relPoint or "CENTER", config.x or 0, config.y or -100)
    end
end

