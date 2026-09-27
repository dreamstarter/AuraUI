-------------------------------------------------------------------------------
-- AuraUI / Modules / LootAnnounce.lua
-- Loot Announce & Roll Tracker
-- Auto-announces loot rolls to party/raid chat and tracks all rolls in a
-- compact history window. WoW: Forever only — disabled on retail via RetailBridge.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local LootAnnounce = addonTable:NewModule("LootAnnounce")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local MAX_HISTORY      = 20        -- max rolls to keep in memory
local WINDOW_WIDTH     = 260
local WINDOW_HEIGHT    = 300
local ROW_HEIGHT       = 18
local FONT_SMALL       = "GameFontNormalSmall"
local QUALITY_COLORS   = {
    [0] = "|cff9d9d9d",   -- Poor
    [1] = "|cffffffff",   -- Common
    [2] = "|cff1eff00",   -- Uncommon (green)
    [3] = "|cff0070dd",   -- Rare (blue)
    [4] = "|cffa335ee",   -- Epic (purple)
    [5] = "|cffff8000",   -- Legendary (orange)
}

-------------------------------------------------------------------------------
-- Roll history
-------------------------------------------------------------------------------
local rollHistory = {}  -- { { player, item, roll, rollType, quality, time } }

-------------------------------------------------------------------------------
-- Announce channel helper
-------------------------------------------------------------------------------
local function GetAnnounceChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil  -- solo — no announce
end

-------------------------------------------------------------------------------
-- Frame: roll history window
-------------------------------------------------------------------------------
local function CreateHistoryWindow()
    local f = CreateFrame("Frame", "AuraUILootAnnounceFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)

    -- Backdrop
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.04, 0.04, 0.04, 0.92)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.5)
    end

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -6)
    title:SetText("|cff00e5ffLoot Roll History|r")
    f.title = title

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(60, 18)
    clearBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        wipe(rollHistory)
        LootAnnounce:RefreshWindow()
    end)

    -- Scroll area
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -28)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WINDOW_WIDTH - 32, 1)
    scroll:SetScrollChild(content)
    f.content = content

    f:Hide()
    return f
end

-------------------------------------------------------------------------------
-- Refresh window rows
-------------------------------------------------------------------------------
function LootAnnounce:RefreshWindow()
    local content = self.frame.content
    -- Clear old rows
    for _, child in pairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local rowCount = #rollHistory
    content:SetHeight(math.max(1, rowCount * ROW_HEIGHT + 4))

    for i, entry in ipairs(rollHistory) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(WINDOW_WIDTH - 32, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        -- Alternating row shading
        if i % 2 == 0 then
            local shade = row:CreateTexture(nil, "BACKGROUND")
            shade:SetAllPoints()
            shade:SetColorTexture(1, 1, 1, 0.04)
        end

        local qColor  = QUALITY_COLORS[entry.quality] or QUALITY_COLORS[1]
        local typeStr = entry.rollType == "need" and "|cffff4444Need|r"
                     or entry.rollType == "greed" and "|cffffff44Greed|r"
                     or "|cffaaaaааPass|r"

        local text = row:CreateFontString(nil, "OVERLAY", FONT_SMALL)
        text:SetPoint("LEFT", 4, 0)
        text:SetPoint("RIGHT", -4, 0)
        text:SetJustifyH("LEFT")
        text:SetText(string.format(
            "[%s] %s%s|r — %s — %s",
            entry.time,
            qColor,
            entry.item,
            typeStr,
            entry.player
        ))
        text:SetTextColor(1, 1, 1, 0.9)
    end
end

-------------------------------------------------------------------------------
-- Record a roll and optionally announce it
-------------------------------------------------------------------------------
local function RecordRoll(player, item, quality, roll, rollType)
    local entry = {
        player   = player,
        item     = item,
        quality  = quality or 1,
        roll     = roll,
        rollType = rollType,
        time     = date("%H:%M"),
    }

    -- Prepend (newest first)
    table.insert(rollHistory, 1, entry)
    if #rollHistory > MAX_HISTORY then
        table.remove(rollHistory)
    end

    -- Announce to group if it's the player themselves rolling
    if player == UnitName("player") then
        local channel = GetAnnounceChannel()
        if channel then
            local typeStr = rollType == "need" and "Need" or rollType == "greed" and "Greed" or "Pass"
            SendChatMessage(
                string.format("AuraUI: %s on %s — rolled %d", typeStr, item, roll),
                channel
            )
        end
    end

    -- Refresh window if visible
    if LootAnnounce.frame and LootAnnounce.frame:IsShown() then
        LootAnnounce:RefreshWindow()
    end
end

-------------------------------------------------------------------------------
-- Event handling
-------------------------------------------------------------------------------
local function OnEvent(self, event, ...)
    if event == "START_LOOT_ROLL" then
        -- arg1 = rollID, arg2 = rollTime
        -- We can't get the item easily here; CHAT_MSG_LOOT handles it better
        return

    elseif event == "CHAT_MSG_LOOT" then
        local msg = ...
        -- Pattern: "PlayerName rolls X (Need/Greed) for [ItemLink]."
        -- WoW: Forever format varies but common patterns:
        local player, roll, rollType, item

        player, roll = msg:match("^(.+) rolls (%d+) %(Need%)")
        if player then rollType = "need" end

        if not player then
            player, roll = msg:match("^(.+) rolls (%d+) %(Greed%)")
            if player then rollType = "greed" end
        end

        if not player then
            player = msg:match("^(.+) passes%.")
            if player then roll = 0; rollType = "pass" end
        end

        item = msg:match("%[(.-)%]") or "Unknown Item"

        if player and rollType then
            RecordRoll(player, item, 2, tonumber(roll) or 0, rollType)
        end

    elseif event == "CHAT_MSG_SYSTEM" then
        -- "PlayerName rolls X (1-100)." — generic system roll
        local msg = ...
        local player, roll = msg:match("^(.+) rolls (%d+)")
        if player and roll then
            RecordRoll(player, "—", 1, tonumber(roll), "roll")
        end
    end
end

-------------------------------------------------------------------------------
-- Slash command toggle
-------------------------------------------------------------------------------
local function HandleSlash(msg)
    if msg == "loot" then
        local f = LootAnnounce.frame
        if f:IsShown() then
            f:Hide()
        else
            LootAnnounce:RefreshWindow()
            f:Show()
        end
    end
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------
function LootAnnounce:OnInitialize()
    -- Skip initialization on retail clients
    local rb = addonTable.engine and addonTable.engine.RetailBridge
        or (addonTable.modules and addonTable.modules.RetailBridge)
    if rb and rb.isRetail then
        return
    end

    self.frame = CreateHistoryWindow()

    -- Register with EditMode
    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "LootAnnounce", "lootAnnouncePos")
    end

    -- Load enabled state
    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.LootAnnounce ~= nil then
        self.enabled = AuraUIDB.modules.LootAnnounce
    else
        self.enabled = true
    end
end

function LootAnnounce:OnEnable()
    if not self.frame then return end  -- disabled on retail

    local ef = CreateFrame("Frame")
    ef:RegisterEvent("CHAT_MSG_LOOT")
    ef:RegisterEvent("CHAT_MSG_SYSTEM")
    ef:RegisterEvent("START_LOOT_ROLL")
    ef:SetScript("OnEvent", OnEvent)
    self.eventFrame = ef

    -- Extend /aui slash handler
    local wrapped = SlashCmdList["AURAUI"]
    if wrapped then
        SlashCmdList["AURAUI"] = function(msg)
            HandleSlash(msg)
            wrapped(msg)
        end
    end
end

function LootAnnounce:OnDisable()
    self.enabled = false
    if self.frame then self.frame:Hide() end
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
    end
end

