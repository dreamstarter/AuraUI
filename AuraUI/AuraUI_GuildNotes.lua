if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
-- AuraUI / AuraUI_GuildNotes.lua
-- Fast Guild Roster Viewer with Officer Notes and Inline Search
-- Adheres to auraui-design-system, wow-forever-compat, and AuraUI standards.
-------------------------------------------------------------------------------

local addonName, ns = ...
local AuraUI = _G.AuraUI or {}
_G.AuraUI = AuraUI

local GuildNotes = {}
AuraUI.GuildNotes = GuildNotes

GuildNotes.enabled = true
GuildNotes.frame   = nil

local WINDOW_WIDTH  = 540
local WINDOW_HEIGHT = 440
local ROW_HEIGHT    = 22

-------------------------------------------------------------------------------
-- UI Construction (Dark Glass Window)
-------------------------------------------------------------------------------
local function CreateGuildNotesWindow()
    local f = CreateFrame("Frame", "AuraUIGuildNotesFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER", UIParent, "CENTER", -100, 0)
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
    title:SetText("|cff00e5ffGuild Roster & Officer Notes|r")
    f.title = title

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 22)
    refreshBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, -4)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        if GuildRoster then GuildRoster() end
        GuildNotes:RefreshRoster()
    end)

    local searchBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    searchBox:SetSize(160, 20)
    searchBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 4, -8)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("")
    searchBox:SetScript("OnTextChanged", function(self)
        GuildNotes:RefreshRoster(self:GetText():lower():trim())
    end)
    f.searchBox = searchBox

    local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchLabel:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
    searchLabel:SetText("Filter by name/note")

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -64)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WINDOW_WIDTH - 38, 1)
    scroll:SetScrollChild(content)
    f.content = content

    return f
end

-------------------------------------------------------------------------------
-- Roster Refresh & Rendering
-------------------------------------------------------------------------------
function GuildNotes:RefreshRoster(filter)
    if not IsInGuild() then
        if self.frame and self.frame:IsShown() then
            print("|cff00e5ffAuraUI GuildNotes|r: You are not currently in a guild.")
        end
        return
    end

    if not self.frame or not self.frame.content then return end
    local content = self.frame.content
    for _, child in pairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local numMembers = GetNumGuildMembers()
    local matching = {}

    for i = 1, numMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName = GetGuildRosterInfo(i)
        if name then
            local cleanName = name:match("^(.-)%-") or name
            local matches = true

            if filter and filter ~= "" then
                local searchPool = string.lower(table.concat({ cleanName, note or "", officerNote or "", rank or "", class or "" }, " "))
                if not searchPool:find(filter, 1, true) then
                    matches = false
                end
            end

            if matches then
                table.insert(matching, {
                    name      = cleanName,
                    rank      = rank or "Member",
                    level     = level or "?",
                    class     = class or "Unknown",
                    classFile = classFileName or "WARRIOR",
                    note      = note or "",
                    officerNote = officerNote or "",
                    online    = online,
                })
            end
        end
    end

    content:SetHeight(math.max(1, #matching * ROW_HEIGHT + 4))

    for i, member in ipairs(matching) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(WINDOW_WIDTH - 42, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        if i % 2 == 0 then
            local shade = row:CreateTexture(nil, "BACKGROUND")
            shade:SetAllPoints()
            shade:SetColorTexture(1, 1, 1, 0.03)
        end

        local classCol = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[member.classFile] or { r = 1, g = 1, b = 1 }
        local nameText = string.format("|cff%02x%02x%02x%s|r", classCol.r * 255, classCol.g * 255, classCol.b * 255, member.name)
        local statusText = member.online and "|cff00e676●|r" or "|cff757575○|r"

        local noteDisplay = ""
        if member.officerNote ~= "" then
            noteDisplay = string.format("|cff00e5ff[ON: %s]|r ", member.officerNote)
        end
        if member.note ~= "" then
            noteDisplay = noteDisplay .. string.format("|cffffffff%s|r", member.note)
        end
        if noteDisplay == "" then
            noteDisplay = "|cff666666(no notes)|r"
        end

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", row, "LEFT", 4, 0)
        text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        text:SetJustifyH("LEFT")
        text:SetText(string.format("%s %s (%s - %s) - %s", statusText, nameText, member.level, member.rank, noteDisplay))
    end
end

-------------------------------------------------------------------------------
-- Slash Command & Lookup
-------------------------------------------------------------------------------
SLASH_AUIGUILDNOTES1 = "/guildnotes"
SlashCmdList["AUIGUILDNOTES"] = function(msg)
    local cmd, targetName = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""

    if not IsInGuild() then
        print("|cff00e5ffAuraUI GuildNotes|r: You are not in a guild.")
        return
    end

    if targetName and targetName ~= "" then
        targetName = targetName:lower():trim()
        local numMembers = GetNumGuildMembers()
        local found = false

        for i = 1, numMembers do
            local name, rank, _, level, class, _, note, officerNote, online, _, classFileName = GetGuildRosterInfo(i)
            local cleanName = name and (name:match("^(.-)%-") or name) or ""
            if cleanName:lower() == targetName then
                found = true
                local classCol = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classFileName] or { r = 1, g = 1, b = 1 }
                print("--------------------------------")
                print(string.format("|cff%02x%02x%02x%s|r (Level %d %s - %s)", classCol.r * 255, classCol.g * 255, classCol.b * 255, cleanName, level or 0, class or "", rank or ""))
                print(string.format("Status: %s", online and "|cff00e676Online|r" or "|cff757575Offline|r"))
                if note and note ~= "" then print(string.format("Public Note: |cffffffff%s|r", note)) end
                if officerNote and officerNote ~= "" then print(string.format("Officer Note: |cff00e5ff%s|r", officerNote)) end
                print("--------------------------------")
                break
            end
        end

        if not found then
            print(string.format("|cff00e5ffAuraUI GuildNotes|r: No guild member found matching '|cffffffff%s|r'", targetName))
        end
    else
        if not GuildNotes.frame then
            GuildNotes.frame = CreateGuildNotesWindow()
        end
        if GuildNotes.frame:IsShown() then
            GuildNotes.frame:Hide()
        else
            if GuildRoster then GuildRoster() end
            GuildNotes:RefreshRoster()
            GuildNotes.frame:Show()
        end
    end
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("GUILD_ROSTER_UPDATE")
ef:SetScript("OnEvent", function()
    if GuildNotes.frame and GuildNotes.frame:IsShown() then
        GuildNotes:RefreshRoster(GuildNotes.frame.searchBox:GetText():lower():trim())
    end
end)
