-- Modules/ManaSpark.lua: Healer Mana-Regen 5-Second Spark Ticker
local addonName, addonTable = ...

local ManaSpark = addonTable:NewModule("ManaSpark")

function ManaSpark:OnInitialize()
    addonTable:Debug("ManaSpark Module Initialized.")
end

function ManaSpark:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return end

    self:CreateSparkTicker()
end

--- Creates spark overlay ticker on player mana bar.
function ManaSpark:CreateSparkTicker()
    local unitFrames = addonTable:GetModule("UnitFrames")
    if not unitFrames or not unitFrames.frames or not unitFrames.frames.player then return end

    local playerFrame = unitFrames.frames.player
    local powerBar = playerFrame.powerBar
    if not powerBar then return end

    local spark = powerBar:CreateTexture(nil, "OVERLAY")
    spark:SetSize(12, 20)
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", powerBar, "LEFT", 0, 0)

    self.spark = spark
end
