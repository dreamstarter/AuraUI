-- Modules/BuffReminders.lua: Missing Self-Buff Warnings & Reminders
local addonName, addonTable = ...

local BuffReminders = addonTable:NewModule("BuffReminders")

function BuffReminders:OnInitialize()
    addonTable:Debug("BuffReminders Module Initialized.")
end

function BuffReminders:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.buffReminders or not profile.buffReminders.enabled then return end

    self:CreateReminderFrame(profile.layout.BuffReminders)
end

function BuffReminders:CreateReminderFrame(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_BuffReminders", UIParent, "BackdropTemplate")
    container:SetSize(160, 36)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOPLEFT", UIParent, layoutConfig.relPoint or "TOPLEFT", layoutConfig.x or 20, layoutConfig.y or -20)
    else
        container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
    end

    local text = container:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    text:SetPoint("CENTER", container, "CENTER", 0, 0)
    text:SetText("Buff Check Active")

    addonTable.engine.EditMode:RegisterMover(container, "Buff Reminders", "BuffReminders")
    self.container = container
end

function BuffReminders:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.BuffReminders and self.container then
        local config = newProfile.layout.BuffReminders
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "TOPLEFT", UIParent, config.relPoint or "TOPLEFT", config.x or 20, config.y or -20)
    end
end
