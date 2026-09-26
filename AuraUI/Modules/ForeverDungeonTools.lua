-- Modules/ForeverDungeonTools.lua: Dungeon timers, Raid Target bar & priority mob marking
local addonName, addonTable = ...

local ForeverDungeonTools = addonTable:NewModule("ForeverDungeonTools")

function ForeverDungeonTools:OnInitialize()
    addonTable:Debug("ForeverDungeonTools Module Initialized.")
end

function ForeverDungeonTools:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return end

    self:CreateRaidTargetBar(profile.layout.ForeverDungeonTools)
    self:CreateDungeonTimer()
end

--- Creates quick-access Raid Target Bar (Skull, Cross, Square, Moon, Triangle, Diamond, Circle, Star).
--- @param layoutConfig table
function ForeverDungeonTools:CreateRaidTargetBar(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_RaidTargetBar", UIParent, "BackdropTemplate")
    container:SetSize(220, 30)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOP", UIParent, layoutConfig.relPoint or "TOP", layoutConfig.x or 0, layoutConfig.y or -80)
    else
        container:SetPoint("TOP", UIParent, "TOP", 0, -80)
    end

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    container:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Create 8 Raid Marker Buttons
    for i = 1, 8 do
        local btn = CreateFrame("Button", nil, container)
        btn:SetSize(22, 22)
        btn:SetPoint("LEFT", container, "LEFT", 4 + (i - 1) * 26, 0)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints(btn)
        tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        SetRaidTargetIconTexture(tex, i)

        btn:SetScript("OnClick", function()
            if SetRaidTarget then
                SetRaidTarget("target", i)
            end
        end)
    end

    addonTable.engine.EditMode:RegisterMover(container, "Raid Target Bar", "ForeverDungeonTools")
    self.container = container
end

--- Creates a lightweight dungeon timer frame.
function ForeverDungeonTools:CreateDungeonTimer()
    local timerFrame = CreateFrame("Frame", "AuraUI_DungeonTimer", UIParent, "BackdropTemplate")
    timerFrame:SetSize(160, 24)
    timerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -180)

    timerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    timerFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    timerFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local text = timerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", timerFrame, "CENTER", 0, 0)
    text:SetText("Dungeon Timer: 00:00")

    self.timerFrame = timerFrame
end
