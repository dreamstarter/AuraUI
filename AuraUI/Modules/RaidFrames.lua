-- Modules/RaidFrames.lua: Party & Raid Compact Grid Frames
local addonName, addonTable = ...

local RaidFrames = addonTable:NewModule("RaidFrames")
RaidFrames.unitButtons = {}

function RaidFrames:OnInitialize()
    addonTable:Debug("RaidFrames Module Initialized.")
end

function RaidFrames:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.raidFrames or not profile.raidFrames.enabled then return end

    self:CreateRaidHeader(profile.layout.RaidFrames)
end

--- Creates the raid grid container and header frame.
--- @param layoutConfig table
function RaidFrames:CreateRaidHeader(layoutConfig)
    if self.container then return end

    local container = CreateFrame("Frame", "AuraUI_RaidContainer", UIParent)
    container:SetSize(380, 200)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOPLEFT", UIParent, layoutConfig.relPoint or "TOPLEFT", layoutConfig.x or 20, layoutConfig.y or -140)
    else
        container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -140)
    end

    addonTable.engine.EditMode:RegisterMover(container, "Party / Raid Frames", "RaidFrames")
    self.container = container
end

function RaidFrames:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.RaidFrames and self.container then
        local config = newProfile.layout.RaidFrames
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "TOPLEFT", UIParent, config.relPoint or "TOPLEFT", config.x or 20, config.y or -140)
    end
end

