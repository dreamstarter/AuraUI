-- Modules/Nameplates.lua: Custom Nameplates, Castbars & Threat Highlighting
local addonName, addonTable = ...

local Nameplates = addonTable:NewModule("Nameplates")

function Nameplates:OnInitialize()
    addonTable:Debug("Nameplates Module Initialized.")
end

function Nameplates:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.nameplates or not profile.nameplates.enabled then return end

    addonTable:RegisterEvent("NAME_PLATE_UNIT_ADDED", function(event, unit)
        self:SetupNameplate(unit)
    end)

    addonTable:RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(event, unit)
        self:RemoveNameplate(unit)
    end)

    self:UpdateAllNameplates()
end

--- Skins and customizes a World Nameplate frame.
--- @param unit string UnitId e.g. "nameplate1"
function Nameplates:SetupNameplate(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate or not nameplate.UnitFrame then return end

    local frame = nameplate.UnitFrame
    if frame.auraUISkinned then return end
    frame.auraUISkinned = true

    -- Style HealthBar
    if frame.healthBar then
        frame.healthBar:SetStatusBarTexture(addonTable.engine.Media:GetTexture("Flat"))
        
        -- Threat & Class Coloring
        if UnitIsPlayer(unit) then
            local _, class = UnitClass(unit)
            local color = RAID_CLASS_COLORS[class]
            if color then
                frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
            end
        elseif UnitIsEnemy("player", unit) then
            frame.healthBar:SetStatusBarColor(0.8, 0.2, 0.2)
        else
            frame.healthBar:SetStatusBarColor(0.2, 0.8, 0.2)
        end
    end

    -- Style CastBar if available
    if frame.castBar then
        frame.castBar:SetStatusBarTexture(addonTable.engine.Media:GetTexture("Flat"))
        frame.castBar:SetStatusBarColor(1, 0.7, 0)
    end
end

function Nameplates:RemoveNameplate(unit)
    -- Clean up nameplate state if necessary
end

function Nameplates:UpdateAllNameplates()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        if nameplate.namePlateUnitToken then
            self:SetupNameplate(nameplate.namePlateUnitToken)
        end
    end
end

function Nameplates:OnProfileChanged(newProfile)
    self:UpdateAllNameplates()
end

