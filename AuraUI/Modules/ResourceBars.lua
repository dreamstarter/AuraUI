-- Modules/ResourceBars.lua: Class Resource Bars (Combo Points, Holy Power, Shards, Energy, Mana, Runes)
local addonName, addonTable = ...

local ResourceBars = addonTable:NewModule("ResourceBars")

function ResourceBars:OnInitialize()
    addonTable:Debug("ResourceBars Module Initialized.")
end

function ResourceBars:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.resourceBars or not profile.resourceBars.enabled then return end

    self:CreateResourceBar(profile.layout.ResourceBars)
end

function ResourceBars:CreateResourceBar(layoutConfig)
    local container = CreateFrame("Frame", "AuraUI_ResourceBar", UIParent, "BackdropTemplate")
    container:SetSize(220, 16)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "BOTTOM", UIParent, layoutConfig.relPoint or "BOTTOM", layoutConfig.x or 0, layoutConfig.y or 310)
    else
        container:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 310)
    end

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    container:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetAllPoints(container)
    bar:SetStatusBarTexture(addonTable.engine.Media:GetTexture("Flat"))
    bar:SetStatusBarColor(0.9, 0.2, 0.2)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.Text = text

    addonTable.engine.EditMode:RegisterMover(container, "Class Resource Bar", "ResourceBars")
    self.container = container
    self.bar = bar

    -- Register resource update listener
    addonTable:RegisterEvent("UNIT_POWER_UPDATE", function(event, unit, powerType)
        if unit == "player" then
            self:UpdateResource()
        end
    end)

    self:UpdateResource()
end

function ResourceBars:UpdateResource()
    if not self.bar then return end
    local power = UnitPower("player")
    local maxPower = UnitPowerMax("player")
    self.bar:SetMinMaxValues(0, maxPower > 0 and maxPower or 1)
    self.bar:SetValue(power)
    self.bar.Text:SetText(string.format("%d / %d", power, maxPower))
end

function ResourceBars:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.ResourceBars and self.container then
        local config = newProfile.layout.ResourceBars
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "BOTTOM", UIParent, config.relPoint or "BOTTOM", config.x or 0, config.y or 310)
    end
end

