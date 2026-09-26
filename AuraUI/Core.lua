-- Core.lua: Main event handling & specialization listener
local addonName, addonTable = ...

local eventFrame = CreateFrame("Frame", addonName .. "CoreFrame")
addonTable.eventFrame = eventFrame

local eventMap = {}

--- Register event callback.
--- @param event string
--- @param handler function
function addonTable:RegisterEvent(event, handler)
    if not eventMap[event] then
        eventMap[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(eventMap[event], handler)
end

-- Event dispatching
eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handlers = eventMap[event]
    if handlers then
        for _, handler in ipairs(handlers) do
            handler(event, ...)
        end
    end
end)

-- Main AddOn Loaded Listener
addonTable:RegisterEvent("ADDON_LOADED", function(event, name)
    if name == addonName then
        addonTable:InitDatabase()

        -- Initialize Modules
        for modName, module in pairs(addonTable.modules) do
            if type(module.OnInitialize) == "function" then
                pcall(module.OnInitialize, module)
            end
        end
    end
end)

-- Main Player Login Listener
addonTable:RegisterEvent("PLAYER_LOGIN", function(event)
    -- Enable Modules
    for modName, module in pairs(addonTable.modules) do
        if type(module.OnEnable) == "function" then
            pcall(module.OnEnable, module)
        end
    end

    addonTable:Print("Loaded successfully. Type %s to open Edit Mode or %s for settings.", addonTable.colors.primary .. "/aui unlock" .. addonTable.colors.reset, addonTable.colors.primary .. "/aui config" .. addonTable.colors.reset)
end)

-- Specialization Change Listeners
local function OnSpecChange()
    if addonTable.engine.Profiles then
        addonTable.engine.Profiles:OnSpecChanged()
    end
end

addonTable:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", OnSpecChange)
addonTable:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", OnSpecChange)

--- Dynamically loads and opens options panel.
function addonTable:OpenOptions()
    local optionsAddon = addonName .. "_Options"
    local loaded = false

    if C_AddOns and C_AddOns.IsAddOnLoaded then
        loaded = C_AddOns.IsAddOnLoaded(optionsAddon)
    elseif IsAddOnLoaded then
        loaded = IsAddOnLoaded(optionsAddon)
    end

    if not loaded then
        local success, reason
        if C_AddOns and C_AddOns.LoadAddOn then
            success, reason = C_AddOns.LoadAddOn(optionsAddon)
        elseif LoadAddOn then
            success, reason = LoadAddOn(optionsAddon)
        end

        if not success then
            addonTable:Print("Failed to load options module: %s", tostring(reason))
            return
        end
    end

    if addonTable.ShowOptionsPanel then
        addonTable:ShowOptionsPanel()
    end
end
