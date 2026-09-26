-- Engine/Kick.lua: Class Interrupt & Kick Tracker Engine
local addonName, addonTable = ...

local Kick = {}
addonTable.engine.Kick = Kick

-- Class Kick/Interrupt Spell Table
local kickSpellsByClass = {
    DEATHKNIGHT = { 47528 },               -- Mind Freeze
    WARRIOR     = { 6552 },                -- Pummel
    WARLOCK     = { 19647, 89766, 132409 },-- Spell Lock / Axe Toss / Command Demon
    SHAMAN      = { 57994 },               -- Wind Shear
    ROGUE       = { 1766 },                -- Kick
    PRIEST      = { 15487 },               -- Silence
    PALADIN     = { 96231, 31935 },        -- Rebuke / Avenger's Shield
    MONK        = { 116705 },              -- Spear Hand Strike
    MAGE        = { 2139 },                -- Counterspell
    HUNTER      = { 147362, 187707 },      -- Counter Shot / Muzzle
    EVOKER      = { 351338 },              -- Quell
    DRUID       = { 106839, 78675 },       -- Skull Bash / Solar Beam
    DEMONHUNTER = { 183752 },              -- Disrupt
}

local activeKickSpell = nil

--- Refresh active class interrupt spell.
function Kick:RefreshKickAbility()
    local _, class = UnitClass("player")
    local classKicks = kickSpellsByClass[class]
    activeKickSpell = nil
    if not classKicks then return end

    for _, spellId in ipairs(classKicks) do
        if C_SpellBook and C_SpellBook.IsSpellKnownOrInSpellBook then
            if C_SpellBook.IsSpellKnownOrInSpellBook(spellId) then
                activeKickSpell = spellId
                break
            end
        elseif IsSpellKnown and IsSpellKnown(spellId) then
            activeKickSpell = spellId
            break
        end
    end
end

--- Get currently active class interrupt spell.
--- @return number|nil
function Kick:GetActiveKickSpell()
    if not activeKickSpell then
        self:RefreshKickAbility()
    end
    return activeKickSpell
end

--- Evaluate cast bar tint based on kick readiness.
--- @param baseR number
--- @param baseG number
--- @param baseB number
--- @return number r, number g, number b
function Kick:GetCastBarTint(baseR, baseG, baseB)
    local kickSpell = self:GetActiveKickSpell()
    if not kickSpell then
        return baseR, baseG, baseB
    end

    if C_Spell and C_Spell.GetSpellCooldownDuration then
        local duration = C_Spell.GetSpellCooldownDuration(kickSpell)
        if duration and duration.IsZero and duration:IsZero() then
            -- Kick Ready: Highlight castbar green tint
            return 0, 0.9, 0.4
        end
    end

    return baseR, baseG, baseB
end

-- COMBAT_LOG_EVENT_UNFILTERED Interrupt Announcement Listener
addonTable:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(event)
    if not CombatLogGetCurrentEventInfo then return end
    local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _, spellID, spellName, _, extraSpellID, extraSpellName = CombatLogGetCurrentEventInfo()

    if subevent == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player") then
        addonTable:Print("⚡ Interrupted %s's |cffffd200[%s]|r!", destName or "Target", extraSpellName or "Spell")
    end
end)
