-- Modules/PartyMode.lua: Party Mode, level-up celebration & dungeon announcements
local addonName, addonTable = ...

local PartyMode = addonTable:NewModule("PartyMode")

function PartyMode:OnInitialize()
    addonTable:Debug("PartyMode Module Initialized.")
end

function PartyMode:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.partyMode or not profile.partyMode.enabled then return end

    addonTable:RegisterEvent("PLAYER_LEVEL_UP", function(event, level)
        addonTable:Print("🎉 Congratulations on reaching Level %d! Party Mode activated!", level)
    end)
end

