-- Modules/QuestTracker.lua: Objective tracker skinning & auto-collapse
local addonName, addonTable = ...

local QuestTracker = addonTable:NewModule("QuestTracker")

function QuestTracker:OnInitialize()
    addonTable:Debug("QuestTracker Module Initialized.")
end

function QuestTracker:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.questTracker or not profile.questTracker.enabled then return end

    self:SetupTracker(profile.layout.QuestTracker)
end

function QuestTracker:SetupTracker(layoutConfig)
    local trackerFrame = ObjectiveTrackerFrame or WatchFrame
    if not trackerFrame then return end

    local container = CreateFrame("Frame", "AuraUI_QuestTrackerAnchor", UIParent)
    container:SetSize(240, 400)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOPRIGHT", UIParent, layoutConfig.relPoint or "TOPRIGHT", layoutConfig.x or -20, layoutConfig.y or -240)
    else
        container:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -240)
    end

    addonTable.engine.EditMode:RegisterMover(container, "Quest / Objective Tracker", "QuestTracker")
    self.container = container
end

function QuestTracker:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.QuestTracker and self.container then
        local config = newProfile.layout.QuestTracker
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "TOPRIGHT", UIParent, config.relPoint or "TOPRIGHT", config.x or -20, config.y or -240)
    end
end

