-- Modules/Bags.lua: Combined Inventory & Bank all-in-one container
local addonName, addonTable = ...

local Bags = addonTable:NewModule("Bags")

function Bags:OnInitialize()
    addonTable:Debug("Bags Module Initialized.")
end

function Bags:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.bags or not profile.bags.enabled then return end

    -- All-in-one bags handler
end
