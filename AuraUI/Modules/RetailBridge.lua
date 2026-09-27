-- Modules/RetailBridge.lua: Retail Client Compatibility & Deferred Feature Bridge
local addonName, addonTable = ...

local RetailBridge = addonTable:NewModule("RetailBridge")

function RetailBridge:OnInitialize()
    addonTable:Debug("RetailBridge Module Initialized.")
end

function RetailBridge:OnEnable()
    -- Safely checks if client is running modern retail build
    local isRetail = (LE_EXPANSION_LEVEL_CURRENT and LE_EXPANSION_LEVEL_CURRENT >= 9)
    if not isRetail then
        addonTable:Debug("WoW: Forever client detected. Retail bridge features in idle mode.")
        return
    end

    addonTable:Print("Retail client detected. Activating Skyriding HUD & Warband features.")
end

