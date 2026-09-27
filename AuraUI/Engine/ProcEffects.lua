-------------------------------------------------------------------------------
-- AuraUI / Engine / ProcEffects.lua
-- Animated aura proc effects and screen-edge flashes for high-impact combat procs.
-- Adheres to auraui-design-system and wow-forever-compat guidelines.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local ProcEffects = {}
addonTable.engine.ProcEffects = ProcEffects

-------------------------------------------------------------------------------
-- Class Proc Spell Definitions & Color Palettes
-------------------------------------------------------------------------------
local CLASS_PROCS = {
    WARRIOR = {
        color = { r = 1.0, g = 0.25, b = 0.25 },
        spells = {
            [12292] = "Overpower",
            [46916] = "Bloodsurge",
            [12281] = "Sword Spec",
        },
    },
    PALADIN = {
        color = { r = 1.0, g = 0.85, b = 0.2 },
        spells = {
            [53488] = "Art of War",
            [59578] = "Art of War",
            [20178] = "Reckoning",
        },
    },
    MAGE = {
        color = { r = 0.2, g = 0.85, b = 1.0 },
        spells = {
            [12536] = "Clearcasting",
            [44401] = "Missile Barrage",
            [54741] = "Fireball!",
            [44544] = "Fingers of Frost",
            [57761] = "Brain Freeze",
        },
    },
    WARLOCK = {
        color = { r = 0.75, g = 0.3, b = 1.0 },
        spells = {
            [17941] = "Shadow Trance",
            [47383] = "Molten Core",
            [63158] = "Decimation",
            [34936] = "Backlash",
        },
    },
    DRUID = {
        color = { r = 0.25, g = 1.0, b = 0.35 },
        spells = {
            [16870] = "Clearcasting",
            [16864] = "Omen of Clarity",
            [48518] = "Eclipse (Solar)",
            [48517] = "Eclipse (Lunar)",
            [69369] = "Predatory Strikes",
        },
    },
    SHAMAN = {
        color = { r = 0.1, g = 0.6, b = 1.0 },
        spells = {
            [16246] = "Clearcasting",
            [53817] = "Maelstrom Weapon",
            [51562] = "Tidal Waves",
            [16277] = "Elemental Focus",
        },
    },
    PRIEST = {
        color = { r = 1.0, g = 0.95, b = 0.7 },
        spells = {
            [33151] = "Surge of Light",
            [63730] = "Serendipity",
            [14743] = "Focused Casting",
        },
    },
    ROGUE = {
        color = { r = 1.0, g = 0.75, b = 0.1 },
        spells = {
            [14251] = "Riposte",
            [31234] = "Relentless Strikes",
        },
    },
    HUNTER = {
        color = { r = 0.75, g = 0.95, b = 0.25 },
        spells = {
            [56342] = "Lock and Load",
            [53220] = "Improved Steady Shot",
        },
    },
    DEATHKNIGHT = {
        color = { r = 0.4, g = 0.85, b = 1.0 },
        spells = {
            [51128] = "Killing Machine",
            [59052] = "Rime",
            [49016] = "Unholy Frenzy",
        },
    },
}

-------------------------------------------------------------------------------
-- Constants & Configuration
-------------------------------------------------------------------------------
local FLASH_DURATION = 0.6
local FADE_SPEED     = 2.5
local SOUND_PROC_ID  = 567400 -- SOUNDKIT.UI_BONUS_ROLL_START

ProcEffects.enabled   = true
ProcEffects.intensity = "Full" -- "Full", "Subtle", "Off"
ProcEffects.soundOn   = true
ProcEffects.activeProcs = {}
ProcEffects.flashTimer  = 0
ProcEffects.currentAlpha = 0

-------------------------------------------------------------------------------
-- UI Frame Construction (Screen Edges & Center Burst Icon)
-------------------------------------------------------------------------------
local function CreateProcFrame()
    local f = CreateFrame("Frame", "AuraUIProcEffectsFrame", UIParent)
    f:SetAllPoints(UIParent)
    f:SetFrameStrata("HIGH")
    f:SetAlpha(0)
    f:Hide()

    -- 4 Edge Vignette Textures
    f.edges = {}

    -- Top edge
    local top = f:CreateTexture(nil, "BACKGROUND")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(80)
    top:SetColorTexture(0, 0.9, 1, 0.5)
    f.edges.top = top

    -- Bottom edge
    local bottom = f:CreateTexture(nil, "BACKGROUND")
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetHeight(80)
    bottom:SetColorTexture(0, 0.9, 1, 0.5)
    f.edges.bottom = bottom

    -- Left edge
    local left = f:CreateTexture(nil, "BACKGROUND")
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(80)
    left:SetColorTexture(0, 0.9, 1, 0.5)
    f.edges.left = left

    -- Right edge
    local right = f:CreateTexture(nil, "BACKGROUND")
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetWidth(80)
    right:SetColorTexture(0, 0.9, 1, 0.5)
    f.edges.right = right

    -- Center Burst Icon Container
    local center = CreateFrame("Frame", nil, f)
    center:SetSize(64, 64)
    center:SetPoint("CENTER", UIParent, "CENTER", 0, 120)

    local icon = center:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\Spell_Holy_MindVision")
    center.icon = icon

    local border = center:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0, 0.9, 1, 0.8)
    center.border = border

    local procLabel = center:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    procLabel:SetPoint("TOP", center, "BOTTOM", 0, -6)
    procLabel:SetTextColor(1, 1, 1, 1)
    center.label = procLabel

    f.center = center
    return f
end

-------------------------------------------------------------------------------
-- Trigger Flash Animation
-------------------------------------------------------------------------------
function ProcEffects:TriggerProc(spellId, spellName, texture)
    if not self.enabled or self.intensity == "Off" then return end

    local _, class = UnitClass("player")
    local classData = CLASS_PROCS[class] or { color = { r = 0, g = 0.9, b = 1 } }
    local col = classData.color

    local f = self.frame
    if not f then return end

    -- Set edge colors
    for _, edge in pairs(f.edges) do
        edge:SetColorTexture(col.r, col.g, col.b, self.intensity == "Subtle" and 0.25 or 0.5)
    end

    -- Setup center icon
    if self.intensity == "Full" then
        if texture then
            f.center.icon:SetTexture(texture)
        end
        f.center.border:SetColorTexture(col.r, col.g, col.b, 0.9)
        f.center.label:SetText(spellName or "PROC!")
        f.center.label:SetTextColor(col.r, col.g, col.b, 1)
        f.center:Show()
    else
        f.center:Hide()
    end

    -- Play sound
    if self.soundOn and PlaySound then
        PlaySound(SOUND_PROC_ID, "Master")
    end

    -- Start animation
    self.flashTimer = FLASH_DURATION
    self.currentAlpha = 1.0
    f:SetAlpha(1.0)
    f:Show()
end

-------------------------------------------------------------------------------
-- OnUpdate Animation
-------------------------------------------------------------------------------
local function OnUpdate(self, elapsed)
    local pe = ProcEffects
    if pe.flashTimer > 0 then
        pe.flashTimer = pe.flashTimer - elapsed
        pe.currentAlpha = math.max(0, pe.currentAlpha - elapsed * FADE_SPEED)
        self:SetAlpha(pe.currentAlpha)
        if pe.flashTimer <= 0 or pe.currentAlpha <= 0 then
            pe.flashTimer = 0
            self:Hide()
        end
    end
end

-------------------------------------------------------------------------------
-- Aura Scanner (WoW: Forever safe UnitBuff loop)
-------------------------------------------------------------------------------
local function CheckProcs()
    local _, class = UnitClass("player")
    local classData = CLASS_PROCS[class]
    if not classData then return end

    local currentActive = {}

    -- Scan up to 40 player buffs
    for i = 1, 40 do
        local name, icon, _, _, _, _, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end

        if spellId and classData.spells[spellId] then
            currentActive[spellId] = true
            -- New proc detected!
            if not ProcEffects.activeProcs[spellId] then
                ProcEffects:TriggerProc(spellId, name, icon)
            end
        end
    end

    ProcEffects.activeProcs = currentActive
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function ProcEffects:Enable()
    self.enabled = true
end

function ProcEffects:Disable()
    self.enabled = false
    if self.frame then self.frame:Hide() end
end

function ProcEffects:SetIntensity(level)
    self.intensity = level
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
function ProcEffects:Initialize()
    self.frame = CreateProcFrame()
    self.frame:SetScript("OnUpdate", OnUpdate)

    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.ProcEffects ~= nil then
        self.enabled = AuraUIDB.modules.ProcEffects
    end
end

-- Event Listeners
addonTable:RegisterEvent("PLAYER_LOGIN", function()
    ProcEffects:Initialize()
end)

addonTable:RegisterEvent("UNIT_AURA", function(event, unit)
    if unit == "player" and ProcEffects.enabled then
        CheckProcs()
    end
end)
