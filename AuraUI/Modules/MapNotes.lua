-------------------------------------------------------------------------------
-- AuraUI / Modules / MapNotes.lua
-- Map Waypoint Notes & Coordinate Pin Manager
-- Adheres to auraui-design-system, wow-forever-compat, and EditMode standards.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local MapNotes = addonTable:NewModule("MapNotes")

-------------------------------------------------------------------------------
-- Module State & Constants
-------------------------------------------------------------------------------
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
    return x * 100, y * 100, zoneName, mapID
end

-------------------------------------------------------------------------------
-- Notes Management (Persistent in AuraUICharDB)
-------------------------------------------------------------------------------
local function GetNotesList()
    if not AuraUICharDB then
        AuraUICharDB = {}
    end
    if not AuraUICharDB.mapNotes then
        AuraUICharDB.mapNotes = {}
    end
    return AuraUICharDB.mapNotes
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
        x         = tonumber(string.format("%.1f", x)),
        y         = tonumber(string.format("%.1f", y)),
        zone      = zone or GetZoneText(),
        timestamp = date("%m/%d %H:%M"),
    }

    table.insert(list, 1, newNote)
    addonTable:Print("Added map note at %s (%.1f, %.1f): |cffffffff%s|r", newNote.zone, newNote.x, newNote.y, text)

    if self.frame and self.frame:IsShown() then
        self:RefreshList()
    end
end

function MapNotes:DeleteNote(index)
    local list = GetNotesList()
    if list[index] then
        local removed = table.remove(list, index)
        addonTable:Print("Removed map note: |cffffffff%s|r", removed.text)
        self:RefreshList()
    end
end

function MapNotes:ClearAllNotes()
    local list = GetNotesList()
    wipe(list)
    addonTable:Print("All map notes cleared.")
    self:RefreshList()
end

-------------------------------------------------------------------------------
-- Export / Import Helpers
-------------------------------------------------------------------------------
function MapNotes:ExportNotes()
    local list = GetNotesList()
    local parts = {}
    for _, note in ipairs(list) do
        table.insert(parts, string.format("%s#%.1f#%.1f#%s", note.zone, note.x, note.y, note.text:gsub("#", " ")))
    end
    return table.concat(parts, ";")
end

function MapNotes:ImportNotes(str)
    if not str or str == "" then return 0 end
    local count = 0
    for entry in str:gmatch("[^;]+") do
        local zone, x, y, text = entry:match("^(.-)#(.-)#(.-)#(.-)$")
        if zone and tonumber(x) and tonumber(y) and text then
            table.insert(GetNotesList(), 1, {
                id = time() + count,
                zone = zone,
                x = tonumber(x),
                y = tonumber(y),
                text = text,
                timestamp = date("%m/%d %H:%M"),
            })
            count = count + 1
        end
    end
    if count > 0 then
        addonTable:Print("Successfully imported %d map notes.", count)
        self:RefreshList()
    end
    return count
end

-------------------------------------------------------------------------------
-- UI Construction (Dark Glass Window)
-------------------------------------------------------------------------------
local function CreateNotesWindow()
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

    -- Dark Glass Styling
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.09, 0.11, 0.96)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
    end

    -- Title Bar
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
    title:SetText("|cff00e5ffMap Notes & Waypoints|r")
    f.title = title

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Quick Add Note Button
    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(140, 24)
    addBtn:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    addBtn:SetText("+ Add at Current Pos")
    addBtn:SetScript("OnClick", function()
        MapNotes:AddNote("Pin")
    end)

    -- Clear All Button
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(90, 24)
    clearBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        MapNotes:ClearAllNotes()
    end)

    -- Scroll Frame for Notes
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -70)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WINDOW_WIDTH - 38, 1)
    scroll:SetScrollChild(content)
    f.content = content

    return f
end

-------------------------------------------------------------------------------
-- Refresh List Display
-------------------------------------------------------------------------------
function MapNotes:RefreshList()
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

        -- Alternating zebra striping
        if i % 2 == 0 then
            local shade = row:CreateTexture(nil, "BACKGROUND")
            shade:SetAllPoints()
            shade:SetColorTexture(1, 1, 1, 0.03)
        end

        -- Delete button
        local delBtn = CreateFrame("Button", nil, row)
        delBtn:SetSize(16, 16)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local delText = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        delText:SetPoint("CENTER")
        delText:SetText("|cffff1744✕|r")
        delBtn:SetScript("OnClick", function()
            MapNotes:DeleteNote(i)
        end)

        -- Note Information Text
        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", row, "LEFT", 4, 0)
        text:SetPoint("RIGHT", delBtn, "LEFT", -4, 0)
        text:SetJustifyH("LEFT")
        text:SetText(string.format("|cff00e5ff[%s]|r |cffffd200%.1f, %.1f|r - %s", note.zone, note.x, note.y, note.text))
    end
end

-------------------------------------------------------------------------------
-- Slash Command Dispatcher
-------------------------------------------------------------------------------
local function HandleSlash(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "note" then
        MapNotes:AddNote(arg ~= "" and arg or "Waypoint")
    elseif cmd == "notes" then
        if MapNotes.frame:IsShown() then
            MapNotes.frame:Hide()
        else
            MapNotes:RefreshList()
            MapNotes.frame:Show()
        end
    end
end

-------------------------------------------------------------------------------
-- Lifecycle Methods
-------------------------------------------------------------------------------
function MapNotes:OnInitialize()
    self.frame = CreateNotesWindow()

    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "MapNotes", "mapNotesPos")
    end

    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.MapNotes ~= nil then
        self.enabled = AuraUIDB.modules.MapNotes
    end
end

function MapNotes:OnEnable()
    local orig = SlashCmdList["AURAUI"]
    if orig then
        SlashCmdList["AURAUI"] = function(msg)
            HandleSlash(msg)
            orig(msg)
        end
    end
end

function MapNotes:OnDisable()
    self.enabled = false
    if self.frame then
        self.frame:Hide()
    end
end
