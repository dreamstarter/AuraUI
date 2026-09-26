-- Modules/ClickCasting.lua: Secure Unit Frame Click-Casting & Context Menu Handler
local addonName, addonTable = ...

local ClickCasting = addonTable:NewModule("ClickCasting")

function ClickCasting:OnInitialize()
    addonTable:Debug("ClickCasting Module Initialized.")
end

function ClickCasting:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return end

    -- Hook unit frame click bindings if active
end

--- Attaches secure right-click menu proxy to a unit frame to prevent modern WoW taints.
--- @param frame Button UnitFrame button
function ClickCasting:AttachSecureMenu(frame)
    if not frame then return end
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("*type2", "togglemenu")
end
