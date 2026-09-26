-- Modules/FriendsList.lua: Enhanced BNet / Friends list with class coloring
local addonName, addonTable = ...

local FriendsList = addonTable:NewModule("FriendsList")

function FriendsList:OnInitialize()
    addonTable:Debug("FriendsList Module Initialized.")
end

function FriendsList:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.friendsList or not profile.friendsList.enabled then return end

    -- Hook Friends list updates if available
end

