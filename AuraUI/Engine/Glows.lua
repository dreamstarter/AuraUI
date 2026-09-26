-- Engine/Glows.lua: Action Button Glows & Proc Highlight Engine
local addonName, addonTable = ...

local Glows = {}
addonTable.engine.Glows = Glows

--- Shows custom action button proc glow overlay.
--- @param button Frame ActionButton frame
function Glows:ShowProcGlow(button)
    if not button then return end

    if ActionButton_ShowOverlayGlow then
        ActionButton_ShowOverlayGlow(button)
    elseif button.glowFrame then
        button.glowFrame:Show()
    else
        local glow = CreateFrame("Frame", nil, button, "BackdropTemplate")
        glow:SetAllPoints(button)
        glow:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        glow:SetBackdropBorderColor(1, 0.8, 0, 1)
        button.glowFrame = glow
    end
end

--- Hides action button proc glow overlay.
--- @param button Frame
function Glows:HideProcGlow(button)
    if not button then return end

    if ActionButton_HideOverlayGlow then
        ActionButton_HideOverlayGlow(button)
    elseif button.glowFrame then
        button.glowFrame:Hide()
    end
end
