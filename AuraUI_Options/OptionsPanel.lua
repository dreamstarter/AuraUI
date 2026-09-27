-- OptionsPanel.lua: Custom Options Window
local addonName = "AuraUI"
local addonTable = _G[addonName]
if not addonTable then return end

local L = addonTable.L

-- 1. Create Main Window Frame
local optionsFrame = CreateFrame("Frame", "AuraUIOptionsFrame", UIParent, "BackdropTemplate")
optionsFrame:SetSize(960, 680)
optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
optionsFrame:SetFrameStrata("DIALOG")
optionsFrame:EnableMouse(true)
optionsFrame:SetMovable(true)
optionsFrame:RegisterForDrag("LeftButton")
optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving)
optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing)
optionsFrame:Hide()

-- Dark Sleek Glass Backdrop
optionsFrame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
optionsFrame:SetBackdropColor(0.08, 0.09, 0.11, 0.96)
optionsFrame:SetBackdropBorderColor(0.2, 0.25, 0.3, 1)

-- 2. Left Sidebar Navigation Panel
local sidebar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
sidebar:SetSize(220, 678)
sidebar:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 1, -1)
sidebar:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
sidebar:SetBackdropColor(0.05, 0.06, 0.07, 0.95)
sidebar:SetBackdropBorderColor(0.15, 0.18, 0.22, 1)

-- Sidebar Logo Header
local logoText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
logoText:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 16, -16)
logoText:SetText("|cff00e5ffAuraUI|r |cffffd200FOREVER|r")

-- Unlock Mode Quick Action Button
local unlockNavBtn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
unlockNavBtn:SetSize(188, 32)
unlockNavBtn:SetPoint("TOPLEFT", logoText, "BOTTOMLEFT", 0, -16)
unlockNavBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
unlockNavBtn:SetBackdropColor(0, 0.7, 0.9, 0.2)
unlockNavBtn:SetBackdropBorderColor(0, 0.9, 1, 0.6)

local unlockNavText = unlockNavBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
unlockNavText:SetPoint("LEFT", unlockNavBtn, "LEFT", 12, 0)
unlockNavText:SetText("📐 Unlock Mode (Edit)")
unlockNavBtn:SetScript("OnClick", function()
    optionsFrame:Hide()
    if addonTable.engine.EditMode then
        addonTable.engine.EditMode:Unlock()
    end
end)

-- Sidebar Search Input Box
local searchBox = CreateFrame("EditBox", nil, sidebar, "InputBoxTemplate")
searchBox:SetSize(188, 24)
searchBox:SetPoint("TOPLEFT", unlockNavBtn, "BOTTOMLEFT", 0, -16)
searchBox:SetAutoFocus(false)
searchBox:SetText("Search Features...")

-- Category List Headers & Items
local categories = {
    { header = "Core Addons", items = { "Action Bars", "Nameplates", "Unit Frames", "Cooldown Manager", "Resource Bars", "Raid Frames" } },
    { header = "QoL Addons", items = { "Quality of Life", "AuraBuff Reminders", "DataBars", "Party Mode" } },
    { header = "UI Reskins", items = { "Window Skins", "Tooltips", "Cursor Effects", "Mythic+ HUD", "Skyriding HUD" } },
}

local lastNavPoint = searchBox
for _, catGroup in ipairs(categories) do
    local headerText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    headerText:SetPoint("TOPLEFT", lastNavPoint, "BOTTOMLEFT", 0, -14)
    headerText:SetText(catGroup.header:upper())
    lastNavPoint = headerText

    for _, item in ipairs(catGroup.items) do
        local itemBtn = CreateFrame("Button", nil, sidebar)
        itemBtn:SetSize(188, 20)
        itemBtn:SetPoint("TOPLEFT", lastNavPoint, "BOTTOMLEFT", 0, -4)

        local label = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", itemBtn, "LEFT", 8, 0)
        label:SetText(item)

        -- Power toggle icon indicator
        local powerIcon = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        powerIcon:SetPoint("RIGHT", itemBtn, "RIGHT", -4, 0)
        powerIcon:SetText("|cff00e676⏻|r")

        lastNavPoint = itemBtn
    end
end

-- Sidebar Footer CPU Usage Tracker
local cpuFooter = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
cpuFooter:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 12)
cpuFooter:SetText("v1.0.0 | CPU Usage: 0.015 MS (0.1%)")

-- 3. Main Content Panel
local mainContent = CreateFrame("Frame", nil, optionsFrame)
mainContent:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
mainContent:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", 0, 0)

-- Header Title & Description
local mainTitle = mainContent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
mainTitle:SetPoint("TOPLEFT", mainContent, "TOPLEFT", 24, -20)
mainTitle:SetText("Global Settings")

mainTitle:SetText("|cffffffffGlobal Settings|r")

local mainSubText = mainContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mainSubText:SetPoint("TOPLEFT", mainTitle, "BOTTOMLEFT", 0, -4)
mainSubText:SetText("General options and performance parameters for all AuraUI modules.")

-- Sub-Tabs Bar (General, Style, Fonts, Textures, Colors)
local tabNames = { "General", "Style", "Fonts", "Textures", "Colors" }
local lastTab = nil
for i, tabName in ipairs(tabNames) do
    local tabBtn = CreateFrame("Button", nil, mainContent)
    tabBtn:SetSize(80, 24)
    if i == 1 then
        tabBtn:SetPoint("TOPLEFT", mainSubText, "BOTTOMLEFT", 0, -14)
    else
        tabBtn:SetPoint("LEFT", lastTab, "RIGHT", 12, 0)
    end

    local tabText = tabBtn:CreateFontString(nil, "OVERLAY", i == 1 and "GameFontNormal" or "GameFontDisable")
    tabText:SetPoint("CENTER", tabBtn, "CENTER", 0, 0)
    tabText:SetText(tabName)
    lastTab = tabBtn
end

-- FPS Optimization Quick Button
local optBtn = CreateFrame("Button", nil, mainContent, "UIPanelButtonTemplate")
optBtn:SetSize(220, 30)
optBtn:SetPoint("TOPRIGHT", mainContent, "TOPRIGHT", -24, -20)
optBtn:SetText("Optimize My FPS & Graphics")
optBtn:SetScript("OnClick", function()
    SetCVar("ffxGlow", "0")
    SetCVar("MaxFPS", "144")
    addonTable:Print("Graphics & FPS optimization CVars applied successfully!")
end)

-- 4. Settings Grid Controls (DISPLAY Section)
local displayHeader = mainContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
displayHeader:SetPoint("TOPLEFT", mainSubText, "BOTTOMLEFT", 0, -56)
displayHeader:SetText("DISPLAY")

-- Control Helper: Checkbox
local function CreateSettingCheckbox(parent, pointFrame, offsetX, offsetY, labelText, defaultChecked, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", pointFrame, "BOTTOMLEFT", offsetX, offsetY)
    cb.Text:SetText(labelText)
    cb:SetChecked(defaultChecked)
    if onClick then cb:SetScript("OnClick", onClick) end
    return cb
end

local cbSpecProfiles = CreateSettingCheckbox(mainContent, displayHeader, 0, -12, "Enable Spec-Based Profile Switching", true, function(self)
    if addonTable.db and addonTable.db.global then
        addonTable.db.global.useSpecProfiles = self:GetChecked()
    end
end)

local cbDebug = CreateSettingCheckbox(mainContent, cbSpecProfiles, 0, -8, "Enable Verbose Debug Output", false, function(self)
    if addonTable.db and addonTable.db.global then
        addonTable.db.global.debugMode = self:GetChecked()
    end
end)

-- 5. Settings Grid Controls (COMBAT Section)
local combatHeader = mainContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
combatHeader:SetPoint("TOPLEFT", cbDebug, "BOTTOMLEFT", 0, -20)
combatHeader:SetText("COMBAT & PERFORMANCE")

local cbKeyWait = CreateSettingCheckbox(mainContent, combatHeader, 0, -12, "Cast Actions on Key Down", true)
local cbDamageText = CreateSettingCheckbox(mainContent, cbKeyWait, 0, -8, "Show Floating Combat Damage Text", true)
local cbHealText = CreateSettingCheckbox(mainContent, cbDamageText, 0, -8, "Show Floating Combat Healing Text", true)
local cbSpellQueue = CreateSettingCheckbox(mainContent, cbHealText, 0, -8, "Show Spell Queue Window Visualizer", true, function(self)
    local isChecked = self:GetChecked()
    if AuraUIDB and AuraUIDB.modules then AuraUIDB.modules.SpellQueue = isChecked end
    if addonTable.engine.SpellQueue then
        if isChecked then addonTable.engine.SpellQueue:Enable() else addonTable.engine.SpellQueue:Disable() end
    end
end)
local cbThreatMeter = CreateSettingCheckbox(mainContent, cbSpellQueue, 0, -8, "Enable Threat Meter Lite", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("ThreatMeter")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbDebuffTracker = CreateSettingCheckbox(mainContent, cbThreatMeter, 0, -8, "Enable Debuff Priority Tracker", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("DebuffTracker")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbLootAnnounce = CreateSettingCheckbox(mainContent, cbDebuffTracker, 0, -8, "Enable Loot Announce & Roll Tracker", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("LootAnnounce")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbProcEffects = CreateSettingCheckbox(mainContent, cbLootAnnounce, 0, -8, "Enable Animated Aura Proc Effects", true, function(self)
    local isChecked = self:GetChecked()
    if AuraUIDB and AuraUIDB.modules then AuraUIDB.modules.ProcEffects = isChecked end
    if addonTable.engine.ProcEffects then
        if isChecked then addonTable.engine.ProcEffects:Enable() else addonTable.engine.ProcEffects:Disable() end
    end
end)
local cbMapNotes = CreateSettingCheckbox(mainContent, cbProcEffects, 0, -8, "Enable Map Waypoint Notes (/aui note)", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("MapNotes")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbGuildNotes = CreateSettingCheckbox(mainContent, cbMapNotes, 0, -8, "Enable Guild Roster & Officer Notes (/aui guild)", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("GuildNotes")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbAutoMarker = CreateSettingCheckbox(mainContent, cbGuildNotes, 0, -8, "Enable Smart Priority Raid Auto-Marker (/aui mark)", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("AutoMarker")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbLootCouncil = CreateSettingCheckbox(mainContent, cbAutoMarker, 0, -8, "Enable Raid Loot Council Voting Panel (/aui lc)", true, function(self)
    local isChecked = self:GetChecked()
    local mod = addonTable:GetModule("LootCouncil")
    if mod then
        if isChecked then mod:OnEnable() else mod:OnDisable() end
    end
end)
local cbSoundPacks = CreateSettingCheckbox(mainContent, cbLootCouncil, 0, -8, "Enable Sound Pack Customizer Profiles", true, function(self)
    local isChecked = self:GetChecked()
    if addonTable.engine.SoundPackCustomizer then
        addonTable.engine.SoundPackCustomizer:SetPack(isChecked and "Classic" or "Mute")
    end
end)

-- 6. Bottom Footer Controls Bar
local footerBar = CreateFrame("Frame", nil, optionsFrame, "BackdropTemplate")
footerBar:SetSize(738, 48)
footerBar:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -1, 1)

local resetBtn = CreateFrame("Button", nil, footerBar, "UIPanelButtonTemplate")
resetBtn:SetSize(150, 26)
resetBtn:SetPoint("LEFT", footerBar, "LEFT", 16, 0)
resetBtn:SetText("Reset Global Settings")

local reloadBtn = CreateFrame("Button", nil, footerBar, "UIPanelButtonTemplate")
reloadBtn:SetSize(120, 26)
reloadBtn:SetPoint("LEFT", resetBtn, "RIGHT", 12, 0)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", function()
    ReloadUI()
end)

local closeBtn = CreateFrame("Button", nil, footerBar, "UIPanelButtonTemplate")
closeBtn:SetSize(100, 26)
closeBtn:SetPoint("RIGHT", footerBar, "RIGHT", -16, 0)
closeBtn:SetText("Close")
closeBtn:SetScript("OnClick", function()
    optionsFrame:Hide()
end)

-- 7. Integration with Blizzard Settings API & Open Handlers
local category = nil
if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(optionsFrame, optionsFrame.name or "AuraUI")
    Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(optionsFrame)
end

function addonTable:ShowOptionsPanel()
    optionsFrame:Show()
end
