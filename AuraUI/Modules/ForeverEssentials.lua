-- Modules/ForeverEssentials.lua: WoW: Forever Quality of Life & Essentials Suite
local addonName, addonTable = ...

local ForeverEssentials = addonTable:NewModule("ForeverEssentials")

function ForeverEssentials:OnInitialize()
    addonTable:Debug("ForeverEssentials Module Initialized.")
end

function ForeverEssentials:OnEnable()
    local profile = addonTable.engine.Profiles:GetActiveProfile()
    if not profile then return end

    self:RegisterQuestHooks()
    self:RegisterMerchantHooks()
end

--- Registers Quest Auto-Accept and Fast Interaction Hooks.
function ForeverEssentials:RegisterQuestHooks()
    -- Auto-accept quests
    addonTable:RegisterEvent("QUEST_DETAIL", function()
        if AcceptQuest then AcceptQuest() end
    end)

    -- Auto-complete quests when single option
    addonTable:RegisterEvent("QUEST_COMPLETE", function()
        if GetNumQuestChoices and GetNumQuestChoices() <= 1 and CompleteQuest then
            GetQuestReward(1)
        end
    end)

    -- Skip Gossip dialogs if single quest option exists
    addonTable:RegisterEvent("GOSSIP_SHOW", function()
        if C_GossipInfo and C_GossipInfo.GetNumOptions then
            local options = C_GossipInfo.GetOptions()
            if options and #options == 1 and options[1].type == "gossip" then
                C_GossipInfo.SelectOption(options[1].gossipOptionID)
            end
        end
    end)
end

--- Registers Fast Merchant Auto-Sell Junk & Repair Hooks.
function ForeverEssentials:RegisterMerchantHooks()
    addonTable:RegisterEvent("MERCHANT_SHOW", function()
        -- Auto-sell junk items (Quality = 0)
        for bag = 0, 4 do
            local numSlots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag) or (GetContainerNumSlots and GetContainerNumSlots(bag) or 0)
            for slot = 1, numSlots do
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

        -- Auto-repair items
        if CanMerchantRepair and CanMerchantRepair() then
            local cost, canRepair = GetRepairAllCost()
            if canRepair and cost > 0 then
                RepairAllItems(false)
                addonTable:Print("Repaired all items for %s.", GetCoinTextureString and GetCoinTextureString(cost) or tostring(cost))
            end
        end
    end)
end
