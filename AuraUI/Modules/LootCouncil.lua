-------------------------------------------------------------------------------
-- AuraUI / Modules / LootCouncil.lua
-- Lightweight In-Game Raid Loot Council Voting & Award Engine
-- Adheres to auraui-design-system, wow-forever-compat, and EditMode standards.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local LootCouncil = addonTable:NewModule("LootCouncil")

-------------------------------------------------------------------------------
-- Module State & Constants
-------------------------------------------------------------------------------
LootCouncil.enabled      = true
LootCouncil.frame        = nil
LootCouncil.activeVote   = nil
LootCouncil.candidates   = {} -- { { name = "Player", choice = "BiS", time = 12 } }

local WINDOW_WIDTH  = 460
local WINDOW_HEIGHT = 380
local ROW_HEIGHT    = 24
local VOTE_DURATION = 30 -- seconds

-------------------------------------------------------------------------------
-- Voting Tiers & Colors
-------------------------------------------------------------------------------
local TIERS = {
    { key = "BiS",      label = "Best in Slot", color = "|cff00e676" }, -- Green
    { key = "Major",    label = "Major Upgrade", color = "|cff00e5ff" }, -- Cyan
    { key = "Minor",    label = "Minor Upgrade", color = "|cffffd200" }, -- Yellow
    { key = "OffSpec",  label = "Off-Spec / XMOG", color = "|cffa335ee" }, -- Purple
    { key = "Pass",     label = "Pass", color = "|cff888888" }, -- Gray
}

-------------------------------------------------------------------------------
-- Session Management
-------------------------------------------------------------------------------
function LootCouncil:StartSession(itemLink)
    if not itemLink then return end

    self.activeVote = {
        itemLink  = itemLink,
        startTime = GetTime(),
        expires   = GetTime() + VOTE_DURATION,
    }
    wipe(self.candidates)

    local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    self.frame.itemText:SetText(itemLink)
    if itemTexture then
        self.frame.itemIcon:SetTexture(itemTexture)
    end

    self:RefreshCandidates()
    self.frame:Show()

    local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    if channel then
        SendChatMessage(string.format("AuraUI LootCouncil: Voting started for %s! (30s)", itemLink), channel)
    end
end

function LootCouncil:Vote(choice)
    local player = UnitName("player")
    -- Check if already voted
    for _, c in ipairs(self.candidates) do
        if c.name == player then
            c.choice = choice
            self:RefreshCandidates()
            return
        end
    end

    table.insert(self.candidates, {
        name   = player,
        choice = choice,
        time   = date("%H:%M:%S"),
    })
    self:RefreshCandidates()
end

function LootCouncil:AwardLoot(candidateName)
    if not self.activeVote or not self.activeVote.itemLink then return end
    local item = self.activeVote.itemLink

    local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    if channel then
        SendChatMessage(string.format("AuraUI LootCouncil: %s has been awarded to %s!", item, candidateName), channel)
    end
    addonTable:Print("Awarded %s to |cffffffff%s|r.", item, candidateName)

    self.activeVote = nil
    self.frame:Hide()
end

-------------------------------------------------------------------------------
-- UI Construction (Dark Glass Window)
-------------------------------------------------------------------------------
local function CreateLootCouncilFrame()
    local f = CreateFrame("Frame", "AuraUILootCouncilFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
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

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8)
    title:SetText("|cff00e5ffLoot Council Voting|r")
    f.title = title

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Item Icon & Display
    local itemIcon = f:CreateTexture(nil, "ARTWORK")
    itemIcon:SetSize(36, 36)
    itemIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -36)
    itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    f.itemIcon = itemIcon

    local itemBorder = f:CreateTexture(nil, "OVERLAY")
    itemBorder:SetPoint("TOPLEFT", itemIcon, "TOPLEFT", -1, 1)
    itemBorder:SetPoint("BOTTOMRIGHT", itemIcon, "BOTTOMRIGHT", 1, -1)
    itemBorder:SetColorTexture(0, 0.9, 1, 0.8)

    local itemText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemText:SetPoint("LEFT", itemIcon, "RIGHT", 12, 0)
    itemText:SetText("No Active Session")
    f.itemText = itemText

    -- Player Voting Buttons Bar
    f.voteButtons = {}
    local lastBtn = nil
    for i, tier in ipairs(TIERS) do
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(80, 22)
        if i == 1 then
            btn:SetPoint("TOPLEFT", itemIcon, "BOTTOMLEFT", 0, -12)
        else
            btn:SetPoint("LEFT", lastBtn, "RIGHT", 4, 0)
        end
        btn:SetText(tier.key)
        btn:SetScript("OnClick", function()
            LootCouncil:Vote(tier.key)
        end)
        f.voteButtons[i] = btn
        lastBtn = btn
    end

    -- Candidates Roster ScrollFrame
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -114)
    scroll:SetPoint("BOTTOMRIGHT", -28, 12)
    f.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WINDOW_WIDTH - 40, 1)
    scroll:SetScrollChild(content)
    f.content = content

    return f
end

-------------------------------------------------------------------------------
-- Candidates Roster Rendering
-------------------------------------------------------------------------------
function LootCouncil:RefreshCandidates()
    local content = self.frame.content
    for _, child in pairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    content:SetHeight(math.max(1, #self.candidates * ROW_HEIGHT + 4))

    for i, candidate in ipairs(self.candidates) do
        local row = CreateFrame("Frame", nil, content)
        row:SetSize(WINDOW_WIDTH - 44, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)

        if i % 2 == 0 then
            local shade = row:CreateTexture(nil, "BACKGROUND")
            shade:SetAllPoints()
            shade:SetColorTexture(1, 1, 1, 0.03)
        end

        -- Award button for Raid Leader / Officer
        local awardBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        awardBtn:SetSize(60, 18)
        awardBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        awardBtn:SetText("Award")
        awardBtn:SetScript("OnClick", function()
            LootCouncil:AwardLoot(candidate.name)
        end)

        -- Candidate info
        local choiceColor = "|cffffffff"
        for _, t in ipairs(TIERS) do
            if t.key == candidate.choice then
                choiceColor = t.color
                break
            end
        end

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", row, "LEFT", 4, 0)
        text:SetPoint("RIGHT", awardBtn, "LEFT", -4, 0)
        text:SetJustifyH("LEFT")
        text:SetText(string.format("%s - %s%s|r (submitted at %s)", candidate.name, choiceColor, candidate.choice, candidate.time))
    end
end

-------------------------------------------------------------------------------
-- Slash Command Dispatcher
-------------------------------------------------------------------------------
local function HandleSlash(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "lc" or cmd == "lootcouncil" then
        if arg and arg ~= "" then
            LootCouncil:StartSession(arg)
        else
            if LootCouncil.frame:IsShown() then
                LootCouncil.frame:Hide()
            else
                LootCouncil.frame:Show()
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Lifecycle Methods
-------------------------------------------------------------------------------
function LootCouncil:OnInitialize()
    self.frame = CreateLootCouncilFrame()

    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "LootCouncil", "lootCouncilPos")
    end

    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.LootCouncil ~= nil then
        self.enabled = AuraUIDB.modules.LootCouncil
    end
end

function LootCouncil:OnEnable()
    local orig = SlashCmdList["AURAUI"]
    if orig then
        SlashCmdList["AURAUI"] = function(msg)
            HandleSlash(msg)
            orig(msg)
        end
    end
end

function LootCouncil:OnDisable()
    self.enabled = false
    if self.frame then
        self.frame:Hide()
    end
end
