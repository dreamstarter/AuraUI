-- Modules/QualityOfLife.lua: Auto-sell junk, auto-repair & fast loot
local addonName, addonTable = ...

local QualityOfLife = addonTable:NewModule("QualityOfLife")

function QualityOfLife:OnInitialize()
    addonTable:Debug("QualityOfLife Module Initialized.")
end

function QualityOfLife:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile.qualityOfLife then return end

    -- Merchant Auto-Sell & Auto-Repair
    addonTable:RegisterEvent("MERCHANT_SHOW", function()
        if profile.qualityOfLife.autoSellJunk then
            self:SellJunk()
        end
        if profile.qualityOfLife.autoRepair then
            self:AutoRepair()
        end
    end)
end

function QualityOfLife:SellJunk()
    for bag = 0, 4 do
        local slots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag) or GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == 0 then
                if C_Container and C_Container.UseContainerItem then
                    C_Container.UseContainerItem(bag, slot)
                elseif UseContainerItem then
                    UseContainerItem(bag, slot)
                end
            end
        end
    end
end

function QualityOfLife:AutoRepair()
    if CanMerchantRepair and CanMerchantRepair() then
        local cost = GetRepairAllCost()
        if cost > 0 then
            RepairAllItems(false)
        end
    end
end

