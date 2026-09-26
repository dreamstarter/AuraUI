-- Modules/MacroFactory.lua: Automated Macro Generator & Combat Macro Tools
local addonName, addonTable = ...

local MacroFactory = addonTable:NewModule("MacroFactory")

function MacroFactory:OnInitialize()
    addonTable:Debug("MacroFactory Module Initialized.")
end

function MacroFactory:OnEnable()
    -- Ready for macro creation calls
end

--- Auto-creates useful combat macro in WoW client.
--- @param name string Macro Title
--- @param icon string Icon ID/Path
--- @param body string Macro script body
function MacroFactory:CreateCombatMacro(name, icon, body)
    if InCombatLockdown() then return end
    if CreateMacro then
        local index = GetMacroIndexByName(name)
        if index == 0 then
            CreateMacro(name, icon or "INV_MISC_QUESTIONMARK", body, false)
            addonTable:Print("Created macro: |cffffd200%s|r", name)
        end
    end
end

--- Generates default suite combat macros (Mouseover Interrupt, Focus Kick).
function MacroFactory:GenerateDefaultMacros()
    self:CreateCombatMacro("AuraKick", "ABILITY_KICK", "#showtooltip\n/cast [@focus,harm,nodead][@target,harm,nodead] Kick")
    self:CreateCombatMacro("AuraHeal", "SPELL_HOLY_FLASHHEAL", "#showtooltip\n/cast [@mouseover,help,nodead][@target,help,nodead][@player] Flash Heal")
end
