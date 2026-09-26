-- Modules/Chat.lua: Chat frame skinning, URL copy & short channel names
local addonName, addonTable = ...

local Chat = addonTable:NewModule("Chat")

function Chat:OnInitialize()
    addonTable:Debug("Chat Module Initialized.")
end

function Chat:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.chat or not profile.chat.enabled then return end

    self:StyleChatFrames()
end

function Chat:StyleChatFrames()
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frame:SetClampedToScreen(true)
        end
    end
end

