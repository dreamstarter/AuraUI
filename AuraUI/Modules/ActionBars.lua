-- Modules/ActionBars.lua: Action Bar layout & keybind text styling
local addonName, addonTable = ...

local ActionBars = addonTable:NewModule("ActionBars")
ActionBars.containers = {}

function ActionBars:OnInitialize()
    addonTable:Debug("ActionBars Module Initialized.")
end

function ActionBars:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    self:SetupContainer("ActionBar1", MainMenuBar, "Action Bar 1", profile.layout.ActionBar1)
    self:SetupContainer("ActionBar2", MultiBarBottomLeft, "Action Bar 2", profile.layout.ActionBar2)

    self:StyleButtons()
end

--- Creates a container anchor frame for Blizzard Action Bars.
--- @param name string Container identifier
--- @param barFrame Frame Target Blizzard Action Bar frame
--- @param title string Mover title label
--- @param layoutConfig table Layout point
function ActionBars:SetupContainer(name, barFrame, title, layoutConfig)
    if not barFrame then return end

    local container = CreateFrame("Frame", "AuraUI_Anchor_" .. name, UIParent)
    container:SetSize(barFrame:GetWidth() > 0 and barFrame:GetWidth() or 480, barFrame:GetHeight() > 0 and barFrame:GetHeight() or 40)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "BOTTOM", UIParent, layoutConfig.relPoint or "BOTTOM", layoutConfig.x or 0, layoutConfig.y or 0)
    else
        container:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 40)
    end

    -- Anchor Blizzard bar frame to container if not restricted by combat
    if not InCombatLockdown() then
        barFrame:ClearAllPoints()
        barFrame:SetPoint("CENTER", container, "CENTER", 0, 0)
    end

    addonTable.engine.EditMode:RegisterMover(container, title, name)
    self.containers[name] = container
end

--- Formats hotkey / keybind text on action buttons (e.g. converting "SHIFT-1" to "S1", "ALT-2" to "A2").
--- @param text string
--- @return string
function ActionBars:FormatKeybindText(text)
    if not text then return "" end
    text = text:gsub("S%-", "S")
    text = text:gsub("A%-", "A")
    text = text:gsub("C%-", "C")
    text = text:gsub("Mouse Button ", "M")
    text = text:gsub("Middle Button", "M3")
    text = text:gsub("Num Pad ", "N")
    return text
end

--- Styles action bar buttons.
function ActionBars:StyleButtons()
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            local hotkey = _G["ActionButton" .. i .. "HotKey"]
            if hotkey then
                local keyText = hotkey:GetText()
                if keyText then
                    hotkey:SetText(self:FormatKeybindText(keyText))
                end
            end
        end
    end
end

--- Called when profile updates.
function ActionBars:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout then
        for name, container in pairs(self.containers) do
            local config = newProfile.layout[name]
            if config then
                container:ClearAllPoints()
                container:SetPoint(config.point or "BOTTOM", UIParent, config.relPoint or "BOTTOM", config.x or 0, config.y or 0)
            end
        end
    end
end
