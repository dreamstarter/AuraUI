if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
if not (AuraUI and AuraUI.IS_FOREVER) then return end -- Forever Essentials loads on WoW Forever only
-------------------------------------------------------------------------------
--  AUI_ForeverEssentials_General_Options.lua
--  Builds the "General" page inside the Forever Essentials module.
-------------------------------------------------------------------------------
if not AuraUI._ModuleNS["AuraUIForeverEssentials"] then return end  -- module disabled: no options page

_G._AUI_BuildForeverGeneralPage = function(pageName, parent, yOffset)
    local W = AuraUI.Widgets
    local y = yOffset
    local _, h
    parent._showRowDivider = true

    ---------------------------------------------------------------------------
    --  SPELLS
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "SPELLS", y);  y = y - h

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Auto Uprank Spells",
          tooltip = "Learning a new spell rank automatically swaps it onto your action bars in place of the old rank.",
          getValue = function()
              return AuraUI._AutoUprank and AuraUI._AutoUprank.IsEnabled()
          end,
          setValue = function(v)
              if AuraUI._AutoUprank then
                  AuraUI._AutoUprank.SetEnabled(v)
              end
          end },
        { type = "label", text = "" }
    );  y = y - h

    return math.abs(y)
end
