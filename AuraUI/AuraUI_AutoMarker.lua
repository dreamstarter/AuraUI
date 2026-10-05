if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
-- AuraUI / AuraUI_AutoMarker.lua
-- Smart Automated Raid & Dungeon Priority Target Marker
-- Adheres to auraui-design-system, wow-forever-compat, and AuraUI standards.
-------------------------------------------------------------------------------

local addonName, ns = ...
local AuraUI = _G.AuraUI or {}
_G.AuraUI = AuraUI

local AutoMarker = {}
AuraUI.AutoMarker = AutoMarker

-------------------------------------------------------------------------------
-- Module State & Constants
-------------------------------------------------------------------------------
AutoMarker.enabled     = true
AutoMarker.autoMark    = true
AutoMarker.frame       = nil
AutoMarker.markedGUIDs = {}  -- [guid] = markIndex

-- Raid Target Icon Indices
-- 8: Skull, 7: Cross, 6: Square, 5: Moon, 4: Triangle, 3: Diamond, 2: Circle, 1: Star
local ICON_SKULL  = 8
local ICON_CROSS  = 7
local ICON_SQUARE = 6
local ICON_MOON   = 5

-------------------------------------------------------------------------------
-- Permission Checks (Safe for Classic & Modern Group Formats)
-------------------------------------------------------------------------------
local function CanMarkTargets()
    if not IsInGroup() then return true end
    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then return true end
    return false
end

-------------------------------------------------------------------------------
-- Auto-Marking Engine
-------------------------------------------------------------------------------
function AutoMarker:MarkUnit(unit, markIndex)
    if not CanMarkTargets() then return end
    if not UnitExists(unit) or UnitIsDead(unit) or not UnitCanAttack("player", unit) then return end

    local currentMark = GetRaidTargetIndex(unit)
    if currentMark ~= markIndex then
        SetRaidTarget(unit, markIndex)
        local guid = UnitGUID(unit)
        if guid then
            self.markedGUIDs[guid] = markIndex
        end
    end
end

function AutoMarker:ClearAllMarks()
    if not CanMarkTargets() then return end
    for i = 1, 8 do
        SetRaidTarget("player", 0)
    end
    wipe(self.markedGUIDs)
    print("|cff00e5ffAuraUI AutoMarker|r: Raid target markers cleared.")
end

local function OnTargetChanged()
    if not AutoMarker.enabled or not AutoMarker.autoMark then return end
    if not CanMarkTargets() then return end

    local unit = "target"
    if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
        local currentMark = GetRaidTargetIndex(unit)
        if not currentMark or currentMark == 0 then
            AutoMarker:MarkUnit(unit, ICON_SKULL)
        end
    end
end

-------------------------------------------------------------------------------
-- UI Construction (Floating Quick-Marker Bar)
-------------------------------------------------------------------------------
local function CreateAutoMarkerFrame()
    local f = CreateFrame("Frame", "AuraUIAutoMarkerFrame", UIParent, "BackdropTemplate")
    f:SetSize(180, 36)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -260)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    -- Dark Glass Styling
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.06, 0.07, 0.08, 0.92)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
    end

    local markers = {
        { id = 8, name = "Skull",  tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8" },
        { id = 7, name = "Cross",  tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7" },
        { id = 6, name = "Square", tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6" },
        { id = 5, name = "Moon",   tex = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5" },
    }

    f.buttons = {}
    for i, m in ipairs(markers) do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(24, 24)
        btn:SetPoint("LEFT", f, "LEFT", 8 + (i - 1) * 28, 0)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(m.tex)
        btn.icon = icon

        btn:SetScript("OnClick", function()
            if UnitExists("target") then
                SetRaidTarget("target", m.id)
            end
        end)
        f.buttons[i] = btn
    end

    -- Clear Button
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(48, 22)
    clearBtn:SetPoint("RIGHT", f, "RIGHT", -6, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        if UnitExists("target") then
            SetRaidTarget("target", 0)
        else
            AutoMarker:ClearAllMarks()
        end
    end)
    f.clearBtn = clearBtn

    return f
end

-------------------------------------------------------------------------------
-- Slash Command Dispatcher
-------------------------------------------------------------------------------
SLASH_AUIAUTOMARKER1 = "/automark"
SlashCmdList["AUIAUTOMARKER"] = function(msg)
    local cmd, arg = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "auto" or cmd == "toggle" then
        AutoMarker.autoMark = not AutoMarker.autoMark
        print(string.format("|cff00e5ffAuraUI AutoMarker|r: Auto-marking is now %s.", AutoMarker.autoMark and "|cff00e676Enabled|r" or "|cffff1744Disabled|r"))
    elseif cmd == "clear" then
        AutoMarker:ClearAllMarks()
    else
        if not AutoMarker.frame then
            AutoMarker.frame = CreateAutoMarkerFrame()
        end
        if AutoMarker.frame:IsShown() then
            AutoMarker.frame:Hide()
        else
            AutoMarker.frame:Show()
        end
    end
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_TARGET_CHANGED")
ef:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_TARGET_CHANGED" then
        OnTargetChanged()
    end
end)
