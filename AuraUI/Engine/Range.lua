-- Engine/Range.lua: Target Distance & Spell Range Engine
local addonName, addonTable = ...

local Range = {}
addonTable.engine.Range = Range

-- Fixed-range harm item ladders for fallback distance inference
local RANGE_ITEMS = {
    { range = 5,  ids = { 8149, 136605, 63427 } },   -- 5 yd
    { range = 8,  ids = { 34368, 33278 } },          -- 8 yd
    { range = 10, ids = { 32321, 17626, 10699 } },   -- 10 yd
    { range = 15, ids = { 33069, 31129 } },          -- 15 yd
    { range = 20, ids = { 10645, 21519 } },          -- 20 yd
    { range = 25, ids = { 13289, 24268, 41509 } },   -- 25 yd
    { range = 30, ids = { 17202, 835, 7734 } },      -- 30 yd
    { range = 35, ids = { 18904, 24269 } },          -- 35 yd
    { range = 40, ids = { 28767, 18640 } },          -- 40 yd
}

--- Evaluates class/spec attack cutoff range.
--- @return number rangeYards
function Range:GetAttackCutoff()
    local _, classFile = UnitClass("player")
    local specIndex = GetSpecialization and GetSpecialization()

    if classFile == "PALADIN" or classFile == "WARRIOR" or classFile == "DEATHKNIGHT" or classFile == "ROGUE" or classFile == "DEMONHUNTER" or classFile == "MONK" then
        return 5 -- Melee 5 yd
    elseif classFile == "MAGE" or classFile == "WARLOCK" or classFile == "PRIEST" or classFile == "HUNTER" then
        return 40 -- Ranged 40 yd
    elseif classFile == "DRUID" then
        return (specIndex == 2 or specIndex == 3) and 5 or 40
    elseif classFile == "SHAMAN" then
        return (specIndex == 2) and 5 or 40
    elseif classFile == "EVOKER" then
        return 25 -- Evoker 25-30 yd
    end

    return 5
end

--- Checks if target unit is within attack range.
--- @param unit string
--- @return boolean inRange
function Range:IsUnitInRange(unit)
    if not UnitExists(unit) then return false end

    -- Check harm items
    for _, rung in ipairs(RANGE_ITEMS) do
        for _, itemId in ipairs(rung.ids or { rung.id }) do
            if C_Item and C_Item.IsItemInRange then
                local result = C_Item.IsItemInRange(itemId, unit)
                if result ~= nil then
                    return result
                end
            end
        end
    end

    return true
end
