-- Modules/Skinning.lua: Reskins Blizzard UI Windows, Tooltips & Popups
local addonName, addonTable = ...

local Skinning = addonTable:NewModule("Skinning")

function Skinning:OnInitialize()
    addonTable:Debug("Skinning Module Initialized.")
end

function Skinning:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.skinning or not profile.skinning.enabled then return end

    self:SkinTooltips()
end

function Skinning:SkinTooltips()
    if not GameTooltip then return end
    GameTooltip:HookScript("OnShow", function(self)
        if self.SetBackdropColor then
            self:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        end
    end)
end

