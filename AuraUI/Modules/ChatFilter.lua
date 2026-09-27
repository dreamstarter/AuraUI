-- Modules/ChatFilter.lua: Smart Chat Spam & Boost Filter for WoW: Forever
local addonName, addonTable = ...

local ChatFilter = addonTable:NewModule("ChatFilter")

-- Common spam keywords
local SPAM_PATTERNS = {
    "[Ww][Tt][Ss]%s+.*[Bb][Oo][Oo][Ss][Tt]",
    "[Gg][Dd][Kk][Pp]",
    "[Cc][Aa][Ss][Ii][Nn][Oo]",
    "[Ff][Uu][Ll][Ll]%s+[Cc][Aa][Rr][Rr][Yy]",
    "[Cc][Aa][Rr][Rr][Yy]%s+[Ss][Ee][Rr][Vv][Ii][Cc][Ee]",
}

function ChatFilter:OnInitialize()
    addonTable:Debug("ChatFilter Module Initialized.")
end

function ChatFilter:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return end

    self:RegisterFilterHooks()
end

--- Registers chat filter hooks for channel, say, and yell messages.
function ChatFilter:RegisterFilterHooks()
    local function FilterMessage(self, event, msg, sender, ...)
        if not msg then return false, msg, sender, ... end

        for _, pattern in ipairs(SPAM_PATTERNS) do
            if string.find(msg, pattern) then
                return true -- Suppress spam message
            end
        end

        return false, msg, sender, ...
    end

    if ChatFrame_AddMessageEventFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", FilterMessage)
        ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FilterMessage)
    end
end

