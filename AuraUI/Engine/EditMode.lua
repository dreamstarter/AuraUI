-- Engine/EditMode.lua: Interactive Edit Mode, pixel grid overlay & frame mover engine
local addonName, addonTable = ...

local EditMode = {
    unlocked = false,
    movers = {},
    gridFrame = nil,
    gridSize = 32,
    snapThreshold = 8,
}
addonTable.engine.EditMode = EditMode

--- Toggle Edit Mode state on/off.
function EditMode:Toggle()
    if self.unlocked then
        self:Lock()
    else
        self:Unlock()
    end
end

--- Unlock frames and show Edit Mode grid & mover handles.
function EditMode:Unlock()
    if self.unlocked then return end
    self.unlocked = true

    self:ShowGrid()

    for _, mover in pairs(self.movers) do
        mover:Show()
    end

    addonTable:Print("Edit Mode %s. Drag frames to position. Type /aui unlock to lock.", addonTable.colors.success .. "UNLOCKED" .. addonTable.colors.reset)
end

--- Lock frames and hide Edit Mode overlays.
function EditMode:Lock()
    if not self.unlocked then return end
    self.unlocked = false

    self:HideGrid()

    for _, mover in pairs(self.movers) do
        mover:Hide()
    end

    addonTable:Print("Edit Mode %s. Frame positions saved.", addonTable.colors.warning .. "LOCKED" .. addonTable.colors.reset)
end

--- Creates full-screen pixel alignment grid overlay.
function EditMode:ShowGrid()
    if not self.gridFrame then
        local grid = CreateFrame("Frame", "AuraUIEditModeGrid", UIParent)
        grid:SetAllPoints(UIParent)
        grid:SetFrameStrata("BACKGROUND")

        local texture = grid:CreateTexture(nil, "BACKGROUND")
        texture:SetAllPoints(grid)
        texture:SetColorTexture(0, 0, 0, 0.4)

        self.gridFrame = grid
    end
    self.gridFrame:Show()
end

--- Hides grid overlay.
function EditMode:HideGrid()
    if self.gridFrame then
        self.gridFrame:Hide()
    end
end

--- Registers a frame to be movable via Edit Mode.
--- @param frame Frame Target UI Frame
--- @param name string Mover display label
--- @param configKey string Key path in profile layout DB
function EditMode:RegisterMover(frame, name, configKey)
    if not frame or self.movers[configKey] then return end

    local mover = CreateFrame("Button", "AuraUIMover_" .. configKey, UIParent, "BackdropTemplate")
    mover:SetSize(frame:GetWidth() > 0 and frame:GetWidth() or 120, frame:GetHeight() > 0 and frame:GetHeight() or 30)
    mover:SetFrameStrata("HIGH")
    mover:SetClampedToScreen(true)

    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(0, 0.9, 1, 0.5)
    mover:SetBackdropBorderColor(0, 0.9, 1, 1)

    local label = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", mover, "CENTER", 0, 0)
    label:SetText(name)

    mover.targetFrame = frame
    mover.configKey = configKey

    -- Enable Dragging & Snapping
    mover:SetMovable(true)
    mover:RegisterForDrag("LeftButton")

    mover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        
        -- Align to frame target
        frame:ClearAllPoints()
        frame:SetPoint(point, UIParent, relPoint, x, y)

        -- Save to active profile
        local profile = addonTable.engine.Profiles:GetActiveProfile()
        if profile and profile.layout then
            profile.layout[configKey] = {
                point = point,
                relPoint = relPoint,
                x = math.floor(x + 0.5),
                y = math.floor(y + 0.5),
            }
        end
    end)

    -- Attach initial point matching target frame
    mover:SetPoint("CENTER", frame, "CENTER", 0, 0)
    mover:Hide()

    self.movers[configKey] = mover
    return mover
end
