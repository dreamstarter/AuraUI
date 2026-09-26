-- Modules/CursorEffects.lua: High-visibility cursor glow/trail effects
local addonName, addonTable = ...

local CursorEffects = addonTable:NewModule("CursorEffects")

function CursorEffects:OnInitialize()
    addonTable:Debug("CursorEffects Module Initialized.")
end

function CursorEffects:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.cursorEffects or not profile.cursorEffects.enabled then return end

    self:CreateCursorTrail()
end

function CursorEffects:CreateCursorTrail()
    local frame = CreateFrame("Frame", "AuraUICursorFrame", UIParent)
    frame:SetSize(24, 24)
    frame:SetFrameStrata("TOOLTIP")

    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(frame)
    texture:SetTexture("Interface\\GLUES\\Models\\UI_Draenei\\HexGlow")
    texture:SetVertexColor(0, 0.9, 1, 0.6)

    frame:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end)

    self.trailFrame = frame
end

