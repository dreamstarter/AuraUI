if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
-- AuraUI / AuraUI_SoundPackCustomizer.lua
-- Selectable Sound Profiles and In-Game Preview Engine
-- Adheres to wow-forever-compat sound ID guidelines.
-------------------------------------------------------------------------------

local addonName, ns = ...
local AuraUI = _G.AuraUI or {}
_G.AuraUI = AuraUI

local SoundPackCustomizer = {}
AuraUI.SoundPackCustomizer = SoundPackCustomizer

-------------------------------------------------------------------------------
-- Sound Pack Profiles
-- Validated numeric sound IDs from wow-forever-compat
-------------------------------------------------------------------------------
local SOUND_PACKS = {
    Classic = {
        LowHealth = 567458,  -- Raid Warning Alert
        Execute   = 567478,  -- Ready Sound
        Interrupt = 567439,  -- Alarm Clock Ring Chime
        Proc      = 567400,  -- Bonus Roll Start Energy
        LootWon   = 567420,  -- Loot Roll Won
    },
    Arena = {
        LowHealth = 567458,  -- Raid Warning
        Execute   = 567520,  -- Encounter Victory Brass
        Interrupt = 567439,  -- Chime
        Proc      = 567400,  -- Energy burst
        LootWon   = 567420,  -- Loot Won
    },
    Subtle = {
        LowHealth = 3081,    -- Whisper Ping
        Execute   = 618,     -- Quest Complete Fanfare
        Interrupt = 567439,  -- Soft Chime
        Proc      = 567400,  -- Soft energy
        LootWon   = 3081,    -- Soft ping
    },
    Mute = {
        LowHealth = 0,
        Execute   = 0,
        Interrupt = 0,
        Proc      = 0,
        LootWon   = 0,
    },
}

SoundPackCustomizer.activePack = "Classic"
SoundPackCustomizer.packs      = SOUND_PACKS

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function SoundPackCustomizer:SetPack(packName)
    if SOUND_PACKS[packName] then
        self.activePack = packName
        if AuraUIDB then
            AuraUIDB.soundPack = packName
        end
        print(string.format("|cff00e5ffAuraUI SoundPack|r: Sound profile set to: |cffffffff%s|r", packName))
    end
end

function SoundPackCustomizer:GetSound(eventKey)
    local pack = SOUND_PACKS[self.activePack] or SOUND_PACKS.Classic
    return pack[eventKey] or 0
end

function SoundPackCustomizer:TestSound(eventKey)
    local id = self:GetSound(eventKey)
    if id and id > 0 and PlaySound then
        PlaySound(id, "Master")
        print(string.format("|cff00e5ffAuraUI SoundPack|r: Playing preview for |cffffffff%s|r (ID: %d)", eventKey, id))
    else
        print(string.format("|cff00e5ffAuraUI SoundPack|r: Sound for %s is muted in '%s'.", eventKey, self.activePack))
    end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
function SoundPackCustomizer:Initialize()
    if AuraUIDB and AuraUIDB.soundPack then
        self.activePack = AuraUIDB.soundPack
    end
    self:SetPack(self.activePack)
end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_LOGIN")
ef:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        SoundPackCustomizer:Initialize()
    end
end)
