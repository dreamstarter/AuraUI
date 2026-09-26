-- Engine/ProfileSharing.lua: Profile Serializer & String Import/Export Engine
local addonName, addonTable = ...

local ProfileSharing = {}
addonTable.engine.ProfileSharing = ProfileSharing

-- Base64 Alphabet Map
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

--- Encodes data string to Base64.
--- @param data string
--- @return string
function ProfileSharing:Base64Encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d%d%d%d', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

--- Exports active spec profile layout as an importable string.
--- @return string exportString
function ProfileSharing:ExportCurrentProfile()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return "" end

    local jsonStr = ""
    -- Basic serialization payload string format
    local parts = {}
    if profile.layout then
        for k, v in pairs(profile.layout) do
            table.insert(parts, string.format("%s:%s,%s,%d,%d", k, v.point or "CENTER", v.relPoint or "CENTER", v.x or 0, v.y or 0))
        end
    end
    jsonStr = table.concat(parts, ";")

    return "AURAUI:1:" .. self:Base64Encode(jsonStr)
end
