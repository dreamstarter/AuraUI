-- Modules/UIUtilities.lua: Raid Marker Bar, Character iLvl Display & UI Utilities
local addonName, addonTable = ...

local UIUtilities = addonTable:NewModule("UIUtilities")

function UIUtilities:OnInitialize()
    addonTable:Debug("UIUtilities Module Initialized.")
end

function UIUtilities:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.uiUtilities then return end

    -- Custom UI utilities
end

