if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
-- AuraUI_MapNotes.lua
-- Map Waypoint Notes & Coordinate Pin Manager
-- Adheres to auraui-design-system, wow-forever-compat, and AuraUI standards.
-------------------------------------------------------------------------------
local addonName, ns = ...
local AuraUI = _G.AuraUI or {}
_G.AuraUI = AuraUI

local MapNotes = {}
AuraUI.MapNotes = MapNotes

MapNotes.enabled = true
MapNotes.frame   = nil

local WINDOW_WIDTH  = 440
local WINDOW_HEIGHT = 400
local ROW_HEIGHT    = 24

-------------------------------------------------------------------------------
-- Coordinate Resolution (Safe for WoW: Forever & Modern Clients)
-------------------------------------------------------------------------------
local function GetPlayerCoords()
    local x, y = 0, 0
    local mapID = nil

    if C_Map and C_Map.GetBestMapForUnit then
        mapID = C_Map.GetBestMapForUnit("player")
        if mapID and C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                x, y = pos:GetXY()
            end
        end
    elseif GetPlayerMapPosition then
        x, y = GetPlayerMapPosition("player")
    end

    local zoneName = GetZoneText() or "Unknown Zone"
    return (x or 0) * 100, (y or 0) * 100, zoneName, mapID
end

-------------------------------------------------------------------------------
-- Notes Management (Persistent in AuraUIDB)
-------------------------------------------------------------------------------
local function GetNotesList()
    if not AuraUIDB then AuraUIDB = {} end
    if not AuraUIDB.mapNotes then AuraUIDB.mapNotes = {} end
    return AuraUIDB.mapNotes
end

function MapNotes:AddNote(text, x, y, zone)
    if not text or text:trim() == "" then
        text = "Waypoint"
    end

    if not x or not y then
        local curX, curY, curZone = GetPlayerCoords()
        x = curX
        y = curY
        zone = curZone
    end

    local list = GetNotesList()
    local newNote = {
        id        = time(),
        text      = text,
        x         = tonumber(string.format("%.1f", x or 0)),
        y         = tonumber(string.format("%.1f", y or 0)),
        zone      = zone or GetZoneText() or "Unknown",
        timestamp = date("%m/%d %H:%M"),
    }

    table.insert(list, 1, newNote)
    print(string.format("|cff00e5ffAuraUI MapNotes|r: Added note at %s (%.1f, %.1f): |cffffffff%s|r", newNote.zone, newNote.x, newNote.y, text))

    if self.frame and self.frame:IsShown() then
        self:RefreshList()
    end
end

function MapNotes:DeleteNote(index)
    local list = GetNotesList()
    if list[index] then
        local removed = table.remove(list, index)
        print(string.format("|cff00e5ffAuraUI MapNotes|r: Removed note: |cffffffff%s|r", removed.text))
        self:RefreshList()
    end
end

function MapNotes:ClearAllNotes()
    local list = GetNotesList()
    wipe(list)
    print("|cff00e5ffAuraUI MapNotes|r: All map notes cleared.")
    self:RefreshList()
end

-------------------------------------------------------------------------------
-- UI Construction (Dark Glass Window)
-------------------------------------------------------------------------------
function MapNotes:EnsureFrame()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "AuraUIMapNotesFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER", UIParent, "CENTER", 100, 0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:Hide()

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.09, 0.11, 0.96)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
    end

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
    title:SetText("|cff00e5ffMap Notes & Waypoints|r")
    f.title = title

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(140, 24)
    addBtn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    addBtn:SetText("+ Add at Current Pos")
    addBtn:SetScript("OnClick", function()
        MapNotes:AddNote("Pin")
    end)

    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(90, 24)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        MapNotes:ClearAllNotes()
    end)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -70)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WINDOW_WIDTH - 38, 1)
    scroll:SetScrollChild(content)
    f.content = content

    self.frame = f
    return f
end

function MapNotes:RefreshList()
    if not self.frame or not self.frame.content then return end
    local content = self.frame.content
    for _, child in pairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local list = GetNotesList()
    content:SetHeight(math.max(1, #list * ROW_HEIGHT + 4))

    for i, note in ipairs(list) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(WINDOW_WIDTH - 42, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        if i % 2 == 0 then
            local shade = row:CreateTexture(nil, "BACKGROUND")
            shade:SetAllPoints()
            shade:SetColorTexture(1, 1, 1, 0.03)
        end

        local delBtn = CreateFrame("Button", nil, row)
        delBtn:SetSize(16, 16)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local delText = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delText:SetPoint("CENTER")
        delText:SetText("|cffff1744✕|r")
        delBtn:SetScript("OnClick", function()
            MapNotes:DeleteNote(i)
        end)

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", row, "LEFT", 4, 0)
        text:SetPoint("RIGHT", delBtn, "LEFT", -4, 0)
        text:SetJustifyH("LEFT")
        text:SetText(string.format("|cff00e5ff[%s]|r |cffffd200%.1f, %.1f|r - %s", note.zone, note.x, note.y, note.text))
    end
end

-- Slash commands
SLASH_AUIMAPNOTES1 = "/notes"
SLASH_AUIMAPNOTE1  = "/note"
SlashCmdList["AUIMAPNOTE"] = function(msg)
    local arg = msg and msg:trim() or ""
    MapNotes:AddNote(arg ~= "" and arg or "Waypoint")
end
SlashCmdList["AUIMAPNOTES"] = function()
    MapNotes:EnsureFrame()
    if MapNotes.frame:IsShown() then
        MapNotes.frame:Hide()
    else
        MapNotes:RefreshList()
        MapNotes.frame:Show()
    end
end
