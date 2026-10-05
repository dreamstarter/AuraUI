if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AUI_ForeverEssentials_Options.lua
--  Registers the Forever Essentials sidebar addon (WoW Forever only) with its
--  tabs:
--    * Travel -- flight timer (built by AUI_ForeverEssentials_Travel_Options.lua)
--    * Threat -- threat meter (built by AUI_ForeverEssentials_Threat_Options.lua)
-------------------------------------------------------------------------------
-- Page names are DEEP-LINK IDENTIFIERS: every NavigateToElementSettings tuple
-- and What's New nav carries them as strings and fails SILENTLY on a mismatch.
if not AuraUI._ModuleNS["AuraUIForeverEssentials"] then return end  -- module disabled: no options page

local PAGE_GENERAL = "General"
local PAGE_TRAVEL = "Travel"
local PAGE_THREAT = "Threat"
local PAGE_LOOT = "Loot"

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")

    AuraUI:RegisterModule("AuraUIForeverEssentials", {
        title       = "Forever Essentials",
        description = "Essential tools for WoW Forever.",
        pages       = { PAGE_GENERAL, PAGE_TRAVEL, PAGE_THREAT, PAGE_LOOT },
        searchTerms = { "flight timer", "flight path", "threat", "threat meter", "aggro", "auto uprank", "uprank", "spell rank", "spells", "loot", "loot feed", "accent bar" },
        buildPage   = function(pageName, parent, yOffset)
            if pageName == PAGE_GENERAL and _G._AUI_BuildForeverGeneralPage then
                return _G._AUI_BuildForeverGeneralPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_TRAVEL and _G._AUI_BuildFlightTimerPage then
                return _G._AUI_BuildFlightTimerPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_THREAT and _G._AUI_BuildThreatMeterPage then
                return _G._AUI_BuildThreatMeterPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_LOOT and _G._AUI_BuildLootFeedPage then
                return _G._AUI_BuildLootFeedPage(pageName, parent, yOffset)
            end
        end,
        -- The Threat page's preview lives in the content header; declaring its
        -- builder makes a cached page whose header was dropped rebuild with it.
        getHeaderBuilder = function(pageName)
            if pageName == PAGE_THREAT then return _G._AUI_ThreatHeaderBuilder end
        end,
        onReset = function()
            if AuraUIDB then
                AuraUIDB.autoUprank = nil
                AuraUIDB.flightTimer = nil
                AuraUIDB.threatMeter = nil
                AuraUIDB.lootFeed = nil
                if AuraUIDB.unlockAnchors then
                    AuraUIDB.unlockAnchors.AUI_FlightTimer = nil
                    AuraUIDB.unlockAnchors.AUI_ThreatMeter = nil
                    AuraUIDB.unlockAnchors.AUI_LootFeed = nil
                end
            end
            local FT = AuraUI._FlightTimer
            if FT then
                FT.Apply()
                FT.ApplyStyle()
                FT.ApplyPosition()
            end
            local TM = AuraUI._ThreatMeter
            if TM then
                TM.Apply()
                TM.ApplyStyle()
                TM.ApplyPosition()
            end
            local module = AuraUI._ModuleNS["AuraUIForeverEssentials"]
            local LF = module and module.LootFeed
            if LF and LF.Apply then
                LF.Apply()
            end
            AuraUI:InvalidatePageCache()
        end,
    })
end)
-- LoadOnDemand: this addon loads after PLAYER_LOGIN, so the event above will never fire; run the init now.
if IsLoggedIn() then initFrame:GetScript("OnEvent")(initFrame) end
