-- Engine/ThemePresets.lua: EllesmereUI Forever Theme Presets & Character Stats
local addonName, addonTable = ...

local ThemePresets = {}
addonTable.engine.ThemePresets = ThemePresets

-- Palette Presets
ThemePresets.presets = {
    ForeverDarkGlass = {
        name = "EllesmereUI Forever Dark Glass",
        bgR = 0.05, bgG = 0.07, bgB = 0.09, bgA = 0.95,
        borderR = 0, borderG = 0.8, borderB = 1, borderA = 1,
        accentColor = "|cff00e5ff",
    },
    ClassicDark = {
        name = "Classic Darkened",
        bgR = 0.08, bgG = 0.08, bgB = 0.08, bgA = 0.9,
        borderR = 0.2, borderG = 0.2, borderB = 0.2, borderA = 1,
        accentColor = "|cffffd200",
    },
    ModernFlat = {
        name = "Modern Flat",
        bgR = 0.1, bgG = 0.1, bgB = 0.1, bgA = 0.85,
        borderR = 0.1, borderG = 0.1, borderB = 0.1, borderA = 0.5,
        accentColor = "|cff00e676",
    }
}

--- Applies a theme preset to a target backdrop frame.
--- @param frame Frame
--- @param presetKey string
function ThemePresets:ApplyPreset(frame, presetKey)
    if not frame or not frame.SetBackdropColor then return end

    local preset = self.presets[presetKey] or self.presets.ForeverDarkGlass
    frame:SetBackdropColor(preset.bgR, preset.bgG, preset.bgB, preset.bgA)
    frame:SetBackdropBorderColor(preset.borderR, preset.borderG, preset.borderB, preset.borderA)
end

--- Gets formatted live character stats string for WoW: Forever (Crit %, Haste %, Hit %, Spell Power, Armor).
--- @return string statsText
function ThemePresets:GetCharacterStatsSummary()
    local spellPower = GetSpellBonusDamage and GetSpellBonusDamage(2) or 0
    local crit = GetCritChance and GetCritChance() or 0
    local haste = GetHaste and GetHaste() or 0
    local armor = UnitArmor and select(2, UnitArmor("player")) or 0

    return string.format(
        "|cff00e5ffSP:|r %d  |cff00e5ffCrit:|r %.1f%%  |cff00e5ffHaste:|r %.1f%%  |cff00e5ffArmor:|r %d",
        spellPower,
        crit,
        haste,
        armor
    )
end
