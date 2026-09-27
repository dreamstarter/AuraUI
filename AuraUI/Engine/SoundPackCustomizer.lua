-------------------------------------------------------------------------------
-- AuraUI / Engine / SoundPackCustomizer.lua
-- Selectable Sound Profiles and In-Game Preview Engine
-- Adheres to wow-forever-compat sound ID guidelines.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local SoundPackCustomizer = {}
addonTable.engine.SoundPackCustomizer = SoundPackCustomizer

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

        -- Update SoundAlerts engine directly
        local sa = addonTable.engine.SoundAlerts
        if sa and sa.sounds then
            for k, id in pairs(SOUND_PACKS[packName]) do
                sa.sounds[k] = id
            end
        end

        addonTable:Print("Sound profile set to: |cff00e5ff%s|r", packName)
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
        addonTable:Print("Playing sound preview for |cff00e5ff%s|r (ID: %d)", eventKey, id)
    else
        addonTable:Print("Sound for |cff00e5ff%s|r is muted in the '%s' profile.", eventKey, self.activePack)
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

addonTable:RegisterEvent("PLAYER_LOGIN", function()
    SoundPackCustomizer:Initialize()
end)
