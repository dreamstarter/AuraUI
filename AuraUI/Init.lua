-- Init.lua: AddOn namespace, module registry & slash commands
local addonName, addonTable = ...

_G["AuraUI"] = addonTable

addonTable.name = "AuraUI"
addonTable.version = "1.0.0"
addonTable.modules = {}
addonTable.engine = {}

-- UI Color Palette Constants
addonTable.colors = {
    primary = "|cff00e5ff",   -- Cyan Highlight
    secondary = "|cff7c4dff", -- Purple Accent
    success = "|cff00e676",   -- Green
    warning = "|cffffab00",   -- Yellow/Orange
    danger = "|cffff1744",    -- Red
    reset = "|r",
}

--- Print formatted output to ChatFrame.
--- @param ... any
function addonTable:Print(...)
    local message = string.format(...)
    DEFAULT_CHAT_FRAME:AddMessage(self.colors.primary .. "[AuraUI]" .. self.colors.reset .. " " .. tostring(message))
end

--- Print debug output when debug mode is active.
--- @param ... any
function addonTable:Debug(...)
    if addonTable.db and addonTable.db.global and addonTable.db.global.debugMode then
        local message = string.format(...)
        DEFAULT_CHAT_FRAME:AddMessage(self.colors.secondary .. "[AuraUI Debug]" .. self.colors.reset .. " " .. tostring(message))
    end
end

--- Register a module within AuraUI.
--- @param name string Module unique identifier
--- @return table module
function addonTable:NewModule(name)
    if self.modules[name] then
        return self.modules[name]
    end

    local module = {
        name = name,
        enabled = true,
    }

    function module:OnInitialize() end
    function module:OnEnable() end
    function module:OnDisable() end

    self.modules[name] = module
    return module
end

--- Retrieve registered module by name.
--- @param name string
--- @return table|nil
function addonTable:GetModule(name)
    return self.modules[name]
end

-- Slash Commands Registration
SLASH_AURAUI1 = "/auraui"
SLASH_AURAUI2 = "/aui"

SlashCmdList["AURAUI"] = function(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = command and command:lower() or ""

    if command == "unlock" or command == "move" or command == "edit" then
        if addonTable.engine.EditMode then
            addonTable.engine.EditMode:Toggle()
        end
    elseif command == "config" or command == "options" then
        addonTable:OpenOptions()
    elseif command == "spec" or command == "profile" then
        if addonTable.engine.Profiles then
            addonTable.engine.Profiles:PrintCurrentSpecInfo()
        end
    elseif command == "version" then
        addonTable:Print("Version %s", addonTable.version)
    else
        addonTable:Print("Commands:")
        addonTable:Print("  /aui unlock - Toggle Interactive Edit Mode (Move & Snap frames)")
        addonTable:Print("  /aui config - Open settings configuration panel")
        addonTable:Print("  /aui spec   - View current specialization profile")
        addonTable:Print("  /aui version - View addon version")
    end
end
