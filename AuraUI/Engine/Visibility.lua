-- Engine/Visibility.lua: Advanced Frame Visibility Driver Engine
local addonName, addonTable = ...

local Visibility = {}
addonTable.engine.Visibility = Visibility

--- Registers conditional macro visibility driver on a UI frame.
--- @param frame Frame Target UI frame
--- @param visibilityCondition string Macro condition string e.g. "[combat] show; hide"
function Visibility:SetVisibilityDriver(frame, visibilityCondition)
    if not frame or not RegisterStateDriver then return end
    RegisterStateDriver(frame, "visibility", visibilityCondition or "[combat] show; hide")
end

--- Unregisters state visibility driver.
--- @param frame Frame
function Visibility:UnsetVisibilityDriver(frame)
    if not frame or not UnregisterStateDriver then return end
    UnregisterStateDriver(frame, "visibility")
end
