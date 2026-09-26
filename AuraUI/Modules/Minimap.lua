-- Modules/Minimap.lua: Minimap skinning & dynamic datatext bar
local addonName, addonTable = ...

local MinimapModule = addonTable:NewModule("Minimap")

function MinimapModule:OnInitialize()
    addonTable:Debug("Minimap Module Initialized.")
end

function MinimapModule:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    self:SetupMinimap(profile.layout.Minimap)
    self:CreateDatatextBar()
end

--- Skins and anchors the Minimap frame.
--- @param layoutConfig table
function MinimapModule:SetupMinimap(layoutConfig)
    if not Minimap then return end

    local container = CreateFrame("Frame", "AuraUI_MinimapContainer", UIParent, "BackdropTemplate")
    container:SetSize(180, 180)

    if layoutConfig then
        container:SetPoint(layoutConfig.point or "TOPRIGHT", UIParent, layoutConfig.relPoint or "TOPRIGHT", layoutConfig.x or -20, layoutConfig.y or -20)
    else
        container:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
    end

    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.8)
    container:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    -- Anchor Blizzard Minimap to Container
    if not InCombatLockdown() then
        Minimap:SetParent(container)
        Minimap:ClearAllPoints()
        Minimap:SetPoint("CENTER", container, "CENTER", 0, 0)
        Minimap:SetSize(176, 176)
    end

    addonTable.engine.EditMode:RegisterMover(container, "Minimap", "Minimap")
    self.container = container
end

--- Creates the live Datatext bar below the minimap.
function MinimapModule:CreateDatatextBar()
    if not self.container then return end

    local dtBar = CreateFrame("Frame", "AuraUI_DatatextBar", self.container, "BackdropTemplate")
    dtBar:SetSize(180, 22)
    dtBar:SetPoint("TOP", self.container, "BOTTOM", 0, -2)

    dtBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dtBar:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    dtBar:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

    local text = dtBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", dtBar, "CENTER", 0, 0)
    dtBar.Text = text

    -- Update loop every 1 second
    dtBar.timer = 0
    dtBar:SetScript("OnUpdate", function(self, elapsed)
        self.timer = self.timer + elapsed
        if self.timer >= 1.0 then
            self.timer = 0
            MinimapModule:UpdateDatatexts(text)
        end
    end)

    self:UpdateDatatexts(text)
end

--- Formats and updates datatext string (FPS, Latency, Gold, Spec).
--- @param fontString FontString
function MinimapModule:UpdateDatatexts(fontString)
    if not fontString then return end

    local framerate = math.floor(GetFramerate() + 0.5)
    local _, _, latencyHome, latencyWorld = GetNetStats()
    local money = GetMoney()
    local gold = math.floor(money / 10000)

    fontString:SetText(string.format(
        "|cff00e5ffFPS:|r %d  |cff00e5ffMS:|r %d  |cffffd200Gold:|r %dg",
        framerate,
        latencyHome,
        gold
    ))
end

--- Called when profile updates.
function MinimapModule:OnProfileChanged(newProfile)
    if newProfile and newProfile.layout and newProfile.layout.Minimap and self.container then
        local config = newProfile.layout.Minimap
        self.container:ClearAllPoints()
        self.container:SetPoint(config.point or "TOPRIGHT", UIParent, config.relPoint or "TOPRIGHT", config.x or -20, config.y or -20)
    end
end
