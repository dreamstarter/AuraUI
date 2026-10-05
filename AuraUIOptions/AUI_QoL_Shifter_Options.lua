if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AUI_QoL_Shifter_Options.lua
--  Builds the "Shifter" page inside the Quality of Life module.
-------------------------------------------------------------------------------

-- "CharacterFrame" -> "Character", "AuctionHouseFrame" -> "Auction House", etc.
if not AuraUI._ModuleNS["AuraUIQoL"] then return end  -- module disabled: no options page

local function PrettifyName(name)
    local pretty = name:gsub("Frame$", "")
    pretty = pretty:gsub("(%l)(%u)", "%1 %2")
                    :gsub("(%u)(%u%l)", "%1 %2")
    return pretty
end

_G._AUI_BuildShifterPage = function(pageName, parent, yOffset)
    local W = AuraUI.Widgets
    local y = yOffset
    local _, h

    -- Info text (top of page, matching bags pattern)
    do
        local fontPath = (AuraUI.GetFontPath())
            or "Fonts\\FRIZQT__.TTF"
        local infoFrame = CreateFrame("Frame", nil, parent)
        infoFrame:SetSize(parent:GetWidth(), 34)
        infoFrame:SetPoint("TOP", parent, "TOP", 0, y - 10)
        infoFrame._isSpacer = true
        local line1 = infoFrame:CreateFontString(nil, "OVERLAY")
        line1:SetFont(fontPath, 15, "")
        line1:SetTextColor(1, 1, 1, 0.75)
        line1:SetPoint("TOP", infoFrame, "TOP", 0, 0)
        line1:SetJustifyH("CENTER")
        line1:SetText(AuraUI.L("Shift + Left-Click Drag to permanently save a panel's position."))
        local line2 = infoFrame:CreateFontString(nil, "OVERLAY")
        line2:SetFont(fontPath, 15, "")
        line2:SetTextColor(1, 1, 1, 0.75)
        line2:SetPoint("TOP", line1, "BOTTOM", 0, -2)
        line2:SetJustifyH("CENTER")
        line2:SetText(AuraUI.L("Ctrl + Left-Click Drag for a temporary move that resets when the panel closes."))
        local line3 = infoFrame:CreateFontString(nil, "OVERLAY")
        line3:SetFont(fontPath, 15, "")
        line3:SetTextColor(1, 1, 1, 0.75)
        line3:SetPoint("TOP", line2, "BOTTOM", 0, -2)
        line3:SetJustifyH("CENTER")
        line3:SetText(AuraUI.L("Shift + Scroll to permanently zoom a panel. Ctrl + Scroll for a temporary zoom."))
        y = y - 70
    end

    -- Reset All button
    _, h = W:WideButton(parent, "Reset All Positions & Zoom", y,
        function()
            AuraUI:ShowConfirmPopup({
                title   = "Reset Shifter Positions & Zoom",
                message = "This will reset all saved panel positions and zoom levels and reload your UI.",
                confirmText = "Reset",
                cancelText  = "Cancel",
                reload = true,
                onConfirm = function()
                    if AuraUI._ResetShifterPositions then
                        AuraUI._ResetShifterPositions()
                    end
                end,
            })
        end
    );  y = y - h

    ---------------------------------------------------------------------------
    --  SHIFTER
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "SHIFTER", y);  y = y - h

    parent._showRowDivider = true

    -- Build dropdown values for Reset Specific Window (any window with a
    -- saved position OR a saved zoom)
    local ddValues = { [""] = "Choose Window..." }
    local ddOrder  = {}
    do
        local seen = {}
        local function collect(tbl)
            if not tbl then return end
            for name in pairs(tbl) do
                if not seen[name] then
                    seen[name] = true
                    ddValues[name] = PrettifyName(name)
                    ddOrder[#ddOrder + 1] = name
                end
            end
        end
        collect(AuraUIDB and AuraUIDB.shifterPositions)
        collect(AuraUIDB and AuraUIDB.shifterScales)
        table.sort(ddOrder, function(a, b)
            return ddValues[a] < ddValues[b]
        end)
    end

    -- Row 1: Enable Shifter | Reset Specific Window
    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Enable Shifter",
          getValue = function()
              return AuraUIDB and AuraUIDB.shifterEnabled or false
          end,
          setValue = function(v)
              if not AuraUIDB then AuraUIDB = {} end
              AuraUIDB.shifterEnabled = v
              if v and AuraUI._InitShifter then
                  AuraUI._InitShifter()
              elseif not v and AuraUI._ShutdownShifter then
                  AuraUI._ShutdownShifter()
              end
          end },
        { type = "dropdown", text = "Reset Specific Window",
          values = ddValues,
          order  = ddOrder,
          getValue = function() return "" end,
          setValue = function(frameName)
              if frameName == "" then return end
              local pretty = ddValues[frameName] or PrettifyName(frameName)
              AuraUI:ShowConfirmPopup({
                  title   = "Reset Window Position & Zoom",
                  message = AuraUI.Lf("Reset %1$s to its default position and zoom and reload your UI?", pretty),
                  confirmText = "Reset",
                  cancelText  = "Cancel",
                  reload = true,
                  onConfirm = function()
                      if AuraUIDB and AuraUIDB.shifterPositions then
                          AuraUIDB.shifterPositions[frameName] = nil
                      end
                      if AuraUIDB and AuraUIDB.shifterScales then
                          AuraUIDB.shifterScales[frameName] = nil
                      end
                  end,
              })
          end }
    );  y = y - h

    -- Row 2: Move windows without shift
    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Move Windows Without Shift",
          tooltip = "When enabled, left-click dragging a window will save its position without needing to hold Shift. Ctrl+drag still does a temporary move.",
          getValue = function()
              return AuraUIDB and AuraUIDB.shifterNoShift or false
          end,
          setValue = function(v)
              if not AuraUIDB then AuraUIDB = {} end
              AuraUIDB.shifterNoShift = v
          end },
        { type = "label", text = "" }
    );  y = y - h

    ---------------------------------------------------------------------------
    --  LOOT WINDOWS
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "LOOT WINDOWS", y);  y = y - h

    local function lootUnlockOff()
        return not (AuraUIDB and AuraUIDB.shifterLootUnlock)
    end

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Move Loot Windows in Unlock Mode",
          tooltip = "Adds Bonus Roll, Group Loot, and Alert Toast movers to Unlock Mode.",
          getValue = function()
              return AuraUIDB and AuraUIDB.shifterLootUnlock or false
          end,
          setValue = function(v)
              if not AuraUIDB then AuraUIDB = {} end
              AuraUIDB.shifterLootUnlock = v
              if v then
                  if AuraUI._InitShifterLootWindows then
                      AuraUI._InitShifterLootWindows()
                  end
              else
                  if AuraUI._DisableShifterLootWindows then
                      AuraUI._DisableShifterLootWindows()
                  end
              end
              AuraUI:RefreshPage()  -- update the overlay toggle disabled state
          end },
        { type = "toggle", text = "Hide Unlock Mode Overlays",
          tooltip = "Hides the loot window movers in Unlock Mode while keeping their saved positions applied.",
          disabled = lootUnlockOff, disabledTooltip = "Move Loot Windows in Unlock Mode",
          getValue = function()
              return AuraUIDB and AuraUIDB.shifterLootHideOverlays or false
          end,
          setValue = function(v)
              if not AuraUIDB then AuraUIDB = {} end
              AuraUIDB.shifterLootHideOverlays = v
          end }
    );  y = y - h

    ---------------------------------------------------------------------------
    --  BLIZZARD TOP BAR EVENT TEXT
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "BLIZZARD TOP BAR EVENT TEXT", y);  y = y - h

    local function topBarUnlockOff()
        return not (AuraUIDB and AuraUIDB.shifterTopBarUnlock)
    end

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Move Top Bar Event Text in Unlock Mode",
          tooltip = "Adds a mover for Blizzard's top-center event text and widgets (scenario, event, and encounter bars).",
          getValue = function()
              return AuraUIDB and AuraUIDB.shifterTopBarUnlock or false
          end,
          setValue = function(v)
              if not AuraUIDB then AuraUIDB = {} end
              AuraUIDB.shifterTopBarUnlock = v
              if v then
                  if AuraUI._InitShifterTopBar then
                      AuraUI._InitShifterTopBar()
                  end
              else
                  if AuraUI._DisableShifterTopBar then
                      AuraUI._DisableShifterTopBar()
                  end
              end
              AuraUI:RefreshPage()  -- update the overlay toggle disabled state
          end },
        { type = "toggle", text = "Hide Unlock Mode Overlay",
          tooltip = "Hides the Top Bar Event Text mover in Unlock Mode while keeping its saved position applied.",
          disabled = topBarUnlockOff, disabledTooltip = "Move Top Bar Event Text in Unlock Mode",
          getValue = function()
              return AuraUIDB and AuraUIDB.shifterTopBarHideOverlay or false
          end,
          setValue = function(v)
              if not AuraUIDB then AuraUIDB = {} end
              AuraUIDB.shifterTopBarHideOverlay = v
          end }
    );  y = y - h

    return math.abs(y)
end
