if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
if not (AuraUI and AuraUI.IS_FOREVER) then return end
-------------------------------------------------------------------------------
--  AuraUIForeverEssentials_AutoUprank.lua  (WoW Forever only)
--  Learning a new spell rank automatically swaps it onto action bars in place
--  of the older rank.
-------------------------------------------------------------------------------
local ADDON_NAME, module = ...
local AUI = AuraUI

local pendingSpells = {}

local function Enabled()
    if AuraUIDB and AuraUIDB.autoUprank ~= nil then
        return AuraUIDB.autoUprank
    end
    return true -- enabled by default
end

local function SetEnabled(val)
    if not AuraUIDB then return end
    AuraUIDB.autoUprank = (val == true)
end

local function GetSpellRankNumber(spellID)
    if not spellID then return nil end
    local subtext
    if GetSpellSubtext then
        subtext = GetSpellSubtext(spellID)
    end
    if not subtext or subtext == "" then
        local _, rankStr = GetSpellInfo(spellID)
        subtext = rankStr
    end
    if subtext and type(subtext) == "string" then
        local rankNum = tonumber(subtext:match("(%d+)"))
        if rankNum then return rankNum end
    end
    return nil
end

local function ProcessUprank(spellID)
    if not spellID then return end
    if not Enabled() then return end

    if InCombatLockdown() then
        pendingSpells[spellID] = true
        return
    end

    local newName = GetSpellInfo(spellID)
    if not newName then return end
    local newRank = GetSpellRankNumber(spellID)

    -- Scan action bar slots 1 through 120.
    local candidates = {}
    local maxSlottedRank = 0

    for slot = 1, 120 do
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" and id and id ~= spellID then
            local slotName = GetSpellInfo(id)
            if slotName == newName then
                local slotRank = GetSpellRankNumber(id) or 0
                if not newRank or slotRank < newRank then
                    table.insert(candidates, { slot = slot, rank = slotRank, id = id })
                    if slotRank > maxSlottedRank then
                        maxSlottedRank = slotRank
                    end
                end
            end
        end
    end

    if #candidates == 0 then return end

    -- Swap matching slots: if the player has multiple ranks slotted (e.g. downranked Rank 1
    -- and a previous max rank), only replace slots matching the highest slotted rank to protect
    -- intentional downranking choices. If all slotted instances share the same rank, uprank all.
    for _, item in ipairs(candidates) do
        if not newRank or item.rank == maxSlottedRank or maxSlottedRank == 0 then
            ClearCursor()
            PickupSpell(spellID)
            PlaceAction(item.slot)
            ClearCursor()
        end
    end
end

local function FlushPending()
    if InCombatLockdown() then return end
    for spellID in pairs(pendingSpells) do
        pendingSpells[spellID] = nil
        ProcessUprank(spellID)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "LEARNED_SPELL_IN_TAB" then
        local spellID = arg1
        if spellID then
            if not GetSpellInfo(spellID) and GetSpellBookItemInfo then
                local _, bookSpellID = GetSpellBookItemInfo(spellID, "spell")
                if bookSpellID then spellID = bookSpellID end
            end
            ProcessUprank(spellID)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        FlushPending()
    end
end)

-- Public API
AuraUI._AutoUprank = {
    IsEnabled = Enabled,
    SetEnabled = SetEnabled,
    ProcessUprank = ProcessUprank,
    GetSpellRankNumber = GetSpellRankNumber,
}
