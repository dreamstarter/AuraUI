-- Engine/Profiles.lua: Spec-based profile management & auto-switching engine
local addonName, addonTable = ...

local Profiles = {}
addonTable.engine.Profiles = Profiles

--- Gets the active character specialization ID/Index.
--- @return number specIndex
--- @return string specName
function Profiles:GetCurrentSpec()
    local specIndex = 1
    local specName = "Default"

    if GetSpecialization then
        local currentSpec = GetSpecialization()
        if currentSpec then
            specIndex = currentSpec
            local _, name = GetSpecializationInfo(currentSpec)
            if name then
                specName = name
            end
        end
    end

    return specIndex, specName
end

--- Returns the profile key for the active spec or global override.
--- @return string profileKey
function Profiles:GetActiveProfileKey()
    if not addonTable.db or not addonTable.db.global then return "Default" end

    local globalDB = addonTable.db.global
    if not globalDB.useSpecProfiles then
        return "Global"
    end

    local specIndex, specName = self:GetCurrentSpec()
    local _, className = UnitClass("player")
    return string.format("%s_%s_Spec%d", className or "Player", specName:gsub("%s+", ""), specIndex)
end

--- Retrieves current active spec profile data, initializing defaults if necessary.
--- @return table profile
function Profiles:GetActiveProfile()
    local key = self:GetActiveProfileKey()

    if not addonTable.db.global.profiles then
        addonTable.db.global.profiles = {}
    end

    if not addonTable.db.global.profiles[key] then
        -- Copy default layout into new spec profile
        addonTable.db.global.profiles[key] = addonTable:CopyTable(addonTable.defaultProfile)
    end

    return addonTable.db.global.profiles[key]
end

--- Called when specialization changes in-game.
function Profiles:OnSpecChanged()
    local key = self:GetActiveProfileKey()
    local specIndex, specName = self:GetCurrentSpec()

    addonTable:Print("Switched to Spec Profile: %s (%s)", self.colors and self.colors.primary .. specName .. "|r" or specName, key)

    -- Notify modules to refresh layout/anchors
    for name, module in pairs(addonTable.modules) do
        if type(module.OnProfileChanged) == "function" then
            module:OnProfileChanged(self:GetActiveProfile())
        end
    end
end

--- Prints current spec profile details to chat frame.
function Profiles:PrintCurrentSpecInfo()
    local specIndex, specName = self:GetCurrentSpec()
    local profileKey = self:GetActiveProfileKey()
    addonTable:Print("Active Spec: %s (Spec #%d)", specName, specIndex)
    addonTable:Print("Active Profile Key: %s", profileKey)
end
