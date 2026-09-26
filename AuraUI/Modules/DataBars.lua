-- Modules/DataBars.lua: Experience, Reputation, Honor & Renown progress bars
local addonName, addonTable = ...

local DataBars = addonTable:NewModule("DataBars")

function DataBars:OnInitialize()
    addonTable:Debug("DataBars Module Initialized.")
end

function DataBars:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.dataBars or not profile.dataBars.enabled then return end

    self:CreateDataBar(profile.layout.DataBars)
end

function DataBars:CreateDataBar(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_DataBarContainer", UIParent, "BackdropTemplate")
    container:SetSize(400, 10)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOP", UIParent, layoutConfig.relPoint or "TOP", layoutConfig.x or 0, layoutConfig.y or -5)
    else
        container:SetPoint("TOP", UIParent, "TOP", 0, -5)
    end

    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetAllPoints(container)
    bar:SetStatusBarTexture(addonTable.engine.Media:GetTexture("Flat"))
    bar:SetStatusBarColor(0, 0.7, 1)

    addonTable.engine.EditMode:RegisterMover(container, "Data Bar (XP / Rep)", "DataBars")
    self.container = container
    self.bar = bar

    self:UpdateBar()
end

function DataBars:UpdateBar()
    if not self.bar then return end
    local xp = UnitXP("player")
    local maxXp = UnitXPMax("player")
    self.bar:SetMinMaxValues(0, maxXp > 0 and maxXp or 1)
    self.bar:SetValue(xp)
end

function DataBars:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.DataBars and self.container then
        local config = newProfile.layout.DataBars
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "TOP", UIParent, config.relPoint or "TOP", config.x or 0, config.y or -5)
    end
end

