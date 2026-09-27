-------------------------------------------------------------------------------
-- AuraUI / Engine / SpellQueue.lua
-- Spell Queue Window Visualizer
-- Shows a "next cast" icon frame to minimize GCD dead-time on WoW: Forever.
-- Listens for UNIT_SPELLCAST_SENT / UNIT_SPELLCAST_START on the player.
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local SpellQueue = {}
addonTable.engine.SpellQueue = SpellQueue

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local FLASH_DURATION   = 0.25   -- seconds the icon flashes on cast-start
local ICON_SIZE        = 42     -- px
local FADE_IN_SPEED    = 4      -- alpha per second
local FADE_OUT_SPEED   = 2

-------------------------------------------------------------------------------
-- Frame creation
-------------------------------------------------------------------------------
local function CreateQueueFrame()
    local f = CreateFrame("Frame", "AuraUISpellQueueFrame", UIParent)
    f:SetSize(ICON_SIZE, ICON_SIZE)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -120) -- below cast bar by default
    f:SetAlpha(0)
    f:Hide()

    -- Background
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)

    -- Spell icon
    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    f.icon = icon

    -- Border glow
    local border = f:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0, 0.9, 1, 0.4)
    f.border = border

    -- "Next" label
    local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOP", f, "BOTTOM", 0, -2)
    label:SetText("Next")
    label:SetTextColor(0.6, 0.9, 1, 0.8)
    f.label = label

    return f
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
SpellQueue.frame        = nil
SpellQueue.queuedSpell  = nil   -- spellID currently queued
SpellQueue.flashTimer   = 0
SpellQueue.alpha        = 0
SpellQueue.enabled      = true

-------------------------------------------------------------------------------
-- Internal helpers
-------------------------------------------------------------------------------
local function SetQueuedSpell(spellID)
    if not SpellQueue.enabled then return end
    SpellQueue.queuedSpell = spellID

    local f = SpellQueue.frame
    if not f then return end

    if spellID then
        local tex = GetSpellTexture(spellID)
        if tex then
            f.icon:SetTexture(tex)
            f:Show()
        end
    else
        f:Hide()
        SpellQueue.alpha = 0
        f:SetAlpha(0)
    end
end

local function FlashFrame()
    SpellQueue.flashTimer = FLASH_DURATION
    SpellQueue.frame.border:SetColorTexture(1, 1, 0.3, 0.9)   -- bright yellow flash
end

-------------------------------------------------------------------------------
-- OnUpdate — handle fade-in and flash decay
-------------------------------------------------------------------------------
local function OnUpdate(self, elapsed)
    local sq = SpellQueue

    -- Flash decay
    if sq.flashTimer > 0 then
        sq.flashTimer = sq.flashTimer - elapsed
        if sq.flashTimer <= 0 then
            sq.flashTimer = 0
            self.border:SetColorTexture(0, 0.9, 1, 0.4)  -- back to cyan glow
        end
    end

    -- Alpha fade-in when queued spell is set
    if sq.queuedSpell then
        if sq.alpha < 1 then
            sq.alpha = math.min(1, sq.alpha + FADE_IN_SPEED * elapsed)
            self:SetAlpha(sq.alpha)
        end
    else
        if sq.alpha > 0 then
            sq.alpha = math.max(0, sq.alpha - FADE_OUT_SPEED * elapsed)
            self:SetAlpha(sq.alpha)
            if sq.alpha == 0 then self:Hide() end
        end
    end
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------
local function OnEvent(self, event, unit, ...)
    if unit ~= "player" then return end

    if event == "UNIT_SPELLCAST_SENT" then
        -- arg1 = target, arg2 = castGUID, arg3 = spellID
        local spellID = select(3, ...)
        SetQueuedSpell(spellID)

    elseif event == "UNIT_SPELLCAST_START" then
        -- Spell actually started casting — flash the border
        FlashFrame()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" or
           event == "UNIT_SPELLCAST_FAILED"    or
           event == "UNIT_SPELLCAST_INTERRUPTED" then
        -- Clear queue
        SetQueuedSpell(nil)
    end
end

-------------------------------------------------------------------------------
-- EditMode registration
-------------------------------------------------------------------------------
local function RegisterMover()
    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(SpellQueue.frame, "SpellQueue", "spellQueuePos")
    end
end

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function SpellQueue:Enable()
    self.enabled = true
    if self.frame then self.frame:Show() end
end

function SpellQueue:Disable()
    self.enabled = false
    SetQueuedSpell(nil)
    if self.frame then self.frame:Hide() end
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
function SpellQueue:Initialize()
    self.frame = CreateQueueFrame()
    self.frame:SetScript("OnUpdate", OnUpdate)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:SetScript("OnEvent", OnEvent)

    RegisterMover()

    -- Load saved position
    local db = AuraUICharDB
    if db and db.spellQueuePos then
        local p = db.spellQueuePos
        self.frame:ClearAllPoints()
        self.frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    end

    -- Load enabled state
    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.SpellQueue ~= nil then
        self.enabled = AuraUIDB.modules.SpellQueue
    end
end

addonTable:RegisterEvent("PLAYER_LOGIN", function()
    SpellQueue:Initialize()
end)

