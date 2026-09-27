-- Engine/SoundAlerts.lua: Audio Alert & Voicepack Cue Engine
local addonName, addonTable = ...

local SoundAlerts = {}
addonTable.engine.SoundAlerts = SoundAlerts

-- Built-in WoW Alert Sound IDs
SoundAlerts.sounds = {
    LowHealth = 567458,  -- Raid Warning Alert
    Execute = 567478,    -- Ready Sound
    Interrupt = 567439,  -- Chime Sound
}

--- Plays a registered sound alert by key name.
--- @param soundKey string
function SoundAlerts:PlayAlert(soundKey)
    local soundId = self.sounds[soundKey]
    if soundId and PlaySound then
        PlaySound(soundId, "Master")
    end
end

--- Monitored health event checker.
function SoundAlerts:CheckPlayerHealth()
    local hp = UnitHealth("player")
    local maxHp = UnitHealthMax("player")
    if maxHp > 0 and (hp / maxHp) < 0.20 and not self.lowHpWarned then
        self:PlayAlert("LowHealth")
        self.lowHpWarned = true
    elseif maxHp > 0 and (hp / maxHp) >= 0.25 then
        self.lowHpWarned = false
    end
end

-- Hook health monitoring
addonTable:RegisterEvent("UNIT_HEALTH", function(event, unit)
    if unit == "player" then
        SoundAlerts:CheckPlayerHealth()
    end
end)

