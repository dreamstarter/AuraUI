-- Modules/ForeverClassBars.lua: Class-specific resource tickers & mechanics for WoW: Forever
local addonName, addonTable = ...

local ForeverClassBars = addonTable:NewModule("ForeverClassBars")

function ForeverClassBars:OnInitialize()
    addonTable:Debug("ForeverClassBars Module Initialized.")
end

function ForeverClassBars:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return end

    local _, class = UnitClass("player")
    if class == "ROGUE" or class == "DRUID" then
        self:CreateEnergyTicker()
    end
    if class == "PRIEST" or class == "SHAMAN" or class == "PALADIN" or class == "MAGE" or class == "DRUID" or class == "WARLOCK" then
        self:CreateFiveSecondManaTicker()
    end
end

--- Creates 2-second energy tick spark for Rogue / Cat.
function ForeverClassBars:CreateEnergyTicker()
    local unitFrames = addonTable:GetModule("UnitFrames")
    if not unitFrames or not unitFrames.frames or not unitFrames.frames.player then return end

    local powerBar = unitFrames.frames.player.powerBar
    if not powerBar then return end

    local spark = powerBar:CreateTexture(nil, "OVERLAY")
    spark:SetSize(8, 16)
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", powerBar, "LEFT", 0, 0)

    self.energySpark = spark
end

--- Creates 5-second rule mana ticker spark for casters.
function ForeverClassBars:CreateFiveSecondManaTicker()
    local unitFrames = addonTable:GetModule("UnitFrames")
    if not unitFrames or not unitFrames.frames or not unitFrames.frames.player then return end

    local powerBar = unitFrames.frames.player.powerBar
    if not powerBar then return end

    local manaSpark = powerBar:CreateTexture(nil, "OVERLAY")
    manaSpark:SetSize(10, 18)
    manaSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    manaSpark:SetVertexColor(0, 0.8, 1, 1)
    manaSpark:SetBlendMode("ADD")
    manaSpark:SetPoint("CENTER", powerBar, "RIGHT", 0, 0)

    self.manaSpark = manaSpark
end
