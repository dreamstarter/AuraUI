if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
-- AuraUIChat_Filter.lua
-- Smart Chat Spam & Boost Filter for WoW: Forever
-- Suppresses boost sales, GDKP spam, casino rolls, and gold selling.
-------------------------------------------------------------------------------
local addonName, ns = ...

-- Common spam keywords & regexes
local SPAM_PATTERNS = {
    "[Ww][Tt][Ss]%s+.*[Bb][Oo][Oo][Ss][Tt]",
    "[Gg][Dd][Kk][Pp]",
    "[Cc][Aa][Ss][Ii][Nn][Oo]",
    "[Ff][Uu][Ll][Ll]%s+[Cc][Aa][Rr][Rr][Yy]",
    "[Cc][Aa][Rr][Rr][Yy]%s+[Ss][Ee][Rr][Vv][Ii][Cc][Ee]",
    "[Ww][Tt][Ss]%s+.*[Gg][Oo][Ll][Dd]",
}

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
