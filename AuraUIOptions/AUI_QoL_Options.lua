if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AUI_QoL_Options.lua
--  Registers the Quality of Life sidebar addon with its two tabs:
--    * Quality of Life -- general QoL features (built by parent general options)
--    * Cursor          -- cursor skin (built by AUI_QoL_Cursor_Options.lua)
-------------------------------------------------------------------------------
-- Page names are DEEP-LINK IDENTIFIERS, not just tab labels: every
-- NavigateToElementSettings tuple (_ELEMENT_SETTINGS_MAP, What's New nav)
-- and every GetActivePage() comparison carries them as strings and fails
-- SILENTLY on a mismatch. Renaming one means updating every consumer.
if not AuraUI._ModuleNS["AuraUIQoL"] then return end  -- module disabled: no options page

local PAGE_QOL      = "QoL"
local PAGE_CURSOR   = "Cursor"
local PAGE_UPGCALC  = "Upgrader"
local PAGE_SHIFTER  = "Shifter"
local PAGE_MOVEMENT = "MoveAlert"
local PAGE_RAIDTOOLS = "Raid Tools"

-------------------------------------------------------------------------------
--  Hide Item Transforms picker popup
--  Item checklist styled after the spec-assign popup: dimmed backdrop, one
--  column per category, Check/Uncheck All links and a green Apply button.
--  Edits are staged and only written on Apply; clicking outside or pressing
--  Escape discards them. Item data comes from AuraUI.HideTransformsData
--  (owned by the runtime in AuraUIQoL.lua).
-------------------------------------------------------------------------------
local transformsPopup
local transformsStaged = {}

local function ShowTransformsPopup()
    local data = AuraUI.HideTransformsData
    if not data then return end

    if not transformsPopup then
        local FONT = AuraUI._font or "Interface\\AddOns\\AuraUI\\media\\fonts\\Expressway.ttf"
        local EG = AuraUI.ELLESMERE_GREEN or { r = 0.05, g = 0.82, b = 0.62 }
        local PP = AuraUI.PanelPP
        local COL_W, COL_GAP = 190, 12
        local CONTENT_LEFT, CONTENT_RIGHT, CONTENT_TOP = 41, 36, 118
        local HDR_H, ROW_H = 30, 26
        local numCols = #data.order

        -- Group items per category; the tallest column drives the popup height.
        local catItems = {}
        for _, item in ipairs(data.items) do
            catItems[item.cat] = catItems[item.cat] or {}
            catItems[item.cat][#catItems[item.cat] + 1] = item
        end
        local maxRows = 0
        for _, cat in ipairs(data.order) do
            local n = catItems[cat] and #catItems[cat] or 0
            if n > maxRows then maxRows = n end
        end

        local POPUP_W = CONTENT_LEFT + CONTENT_RIGHT + numCols * COL_W + (numCols - 1) * COL_GAP
        local POPUP_H = CONTENT_TOP + HDR_H + 4 + maxRows * ROW_H + 24 + 39 + 38
        local ppScale = AuraUI.GetPopupScale() or 1

        local dimmer = CreateFrame("Frame", nil, UIParent)
        dimmer:SetFrameStrata("FULLSCREEN_DIALOG")
        dimmer:SetAllPoints(UIParent)
        dimmer:EnableMouse(true)
        dimmer:EnableMouseWheel(true)
        dimmer:SetScript("OnMouseWheel", function() end)
        dimmer:Hide()
        dimmer:SetScale(ppScale)
        local dimTex = dimmer:CreateTexture(nil, "BACKGROUND")
        dimTex:SetAllPoints()
        dimTex:SetColorTexture(0, 0, 0, 0.25)

        local popup = CreateFrame("Frame", nil, dimmer)
        popup:SetScale(AuraUI.PopupBump(1))
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetFrameLevel(dimmer:GetFrameLevel() + 10)
        popup:SetSize(POPUP_W, POPUP_H)
        popup:SetPoint("CENTER", AuraUI._mainFrame or UIParent, "CENTER", 0, 0)
        popup:EnableMouse(true)
        local pf = AuraUI._popupFrames
        if pf then pf[#pf + 1] = { popup = popup, dimmer = dimmer } end

        local bg = popup:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.06, 0.08, 0.10, 1)
        AuraUI.MakeBorder(popup, 1, 1, 1, 0.15, PP)

        local title = popup:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT, 22, "")
        title:SetTextColor(1, 1, 1, 1)
        title:SetPoint("TOP", popup, "TOP", 0, -32)
        title:SetText(AuraUI.L("Hide Item Transforms"))

        local sub = popup:CreateFontString(nil, "OVERLAY")
        sub:SetFont(FONT, 14, "")
        sub:SetTextColor(1, 1, 1, 0.45)
        sub:SetPoint("TOP", title, "BOTTOM", 0, -8)
        sub:SetText(AuraUI.L("Checked transforms are removed automatically when applied to you."))

        local rows = {}
        local function RefreshRows()
            for _, row in ipairs(rows) do
                if transformsStaged[row._key] then
                    row._check:Show()
                    row._boxBorder:SetColor(EG.r, EG.g, EG.b, 0.8)
                else
                    row._check:Hide()
                    row._boxBorder:SetColor(0.4, 0.4, 0.4, 0.6)
                end
            end
        end
        popup._refreshRows = RefreshRows

        -- Check All / Uncheck All links
        local function SetAll(v)
            for _, item in ipairs(data.items) do transformsStaged[item.key] = v end
            RefreshRows()
        end
        local checkAllBtn = CreateFrame("Button", nil, popup)
        checkAllBtn:SetFrameLevel(popup:GetFrameLevel() + 2)
        local checkAllLbl = checkAllBtn:CreateFontString(nil, "OVERLAY")
        checkAllLbl:SetFont(FONT, 14, "")
        checkAllLbl:SetText(AuraUI.L("Check All"))
        checkAllLbl:SetTextColor(1, 1, 1, 0.45)
        checkAllLbl:SetPoint("CENTER")
        checkAllBtn:SetSize(checkAllLbl:GetStringWidth() + 4, 20)
        checkAllBtn:SetPoint("TOPLEFT", popup, "TOPLEFT", CONTENT_LEFT, -(CONTENT_TOP - 22))
        checkAllBtn:SetScript("OnEnter", function() checkAllLbl:SetTextColor(1, 1, 1, 0.80) end)
        checkAllBtn:SetScript("OnLeave", function() checkAllLbl:SetTextColor(1, 1, 1, 0.45) end)
        checkAllBtn:SetScript("OnClick", function() SetAll(true) end)

        local linkDivider = popup:CreateTexture(nil, "OVERLAY", nil, 7)
        linkDivider:SetColorTexture(1, 1, 1, 0.18)
        if linkDivider.SetSnapToPixelGrid then linkDivider:SetSnapToPixelGrid(false); linkDivider:SetTexelSnappingBias(0) end
        linkDivider:SetPoint("LEFT", checkAllBtn, "RIGHT", 10, 0)
        linkDivider:SetWidth(1)
        linkDivider:SetHeight(12)

        local uncheckAllBtn = CreateFrame("Button", nil, popup)
        uncheckAllBtn:SetFrameLevel(popup:GetFrameLevel() + 2)
        local uncheckAllLbl = uncheckAllBtn:CreateFontString(nil, "OVERLAY")
        uncheckAllLbl:SetFont(FONT, 14, "")
        uncheckAllLbl:SetText(AuraUI.L("Uncheck All"))
        uncheckAllLbl:SetTextColor(1, 1, 1, 0.45)
        uncheckAllLbl:SetPoint("CENTER")
        uncheckAllBtn:SetSize(uncheckAllLbl:GetStringWidth() + 4, 20)
        uncheckAllBtn:SetPoint("LEFT", checkAllBtn, "RIGHT", 20, 0)
        uncheckAllBtn:SetScript("OnEnter", function() uncheckAllLbl:SetTextColor(1, 1, 1, 0.80) end)
        uncheckAllBtn:SetScript("OnLeave", function() uncheckAllLbl:SetTextColor(1, 1, 1, 0.45) end)
        uncheckAllBtn:SetScript("OnClick", function() SetAll(false) end)

        -- Category columns
        for colIdx, cat in ipairs(data.order) do
            local colX = CONTENT_LEFT + (colIdx - 1) * (COL_W + COL_GAP)
            local hdr = popup:CreateFontString(nil, "OVERLAY")
            hdr:SetFont(FONT, 17, "")
            hdr:SetTextColor(1, 1, 1, 0.7)
            hdr:SetPoint("TOPLEFT", popup, "TOPLEFT", colX + 4, -(CONTENT_TOP + 8))
            hdr:SetText(AuraUI.L(data.labels[cat] or cat))

            local items = catItems[cat] or {}
            for i, item in ipairs(items) do
                local row = CreateFrame("Button", nil, popup)
                row:SetSize(COL_W, ROW_H)
                row:SetPoint("TOPLEFT", popup, "TOPLEFT", colX, -(CONTENT_TOP + HDR_H + 4 + (i - 1) * ROW_H))
                row._key = item.key

                local box = CreateFrame("Frame", nil, row)
                box:SetSize(18, 18)
                box:SetPoint("LEFT", row, "LEFT", 4, 0)
                box:SetFrameLevel(row:GetFrameLevel() + 1)
                local boxBg = box:CreateTexture(nil, "BACKGROUND")
                boxBg:SetAllPoints()
                boxBg:SetColorTexture(0.12, 0.12, 0.14, 1)
                row._boxBorder = AuraUI.MakeBorder(box, 0.4, 0.4, 0.4, 0.6, PP)
                local check = box:CreateTexture(nil, "ARTWORK")
                check:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
                check:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
                check:SetColorTexture(EG.r, EG.g, EG.b, 1)
                row._check = check

                local lbl = row:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(FONT, 13, "")
                lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
                lbl:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                lbl:SetJustifyH("LEFT")
                lbl:SetWordWrap(false)
                lbl:SetTextColor(1, 1, 1, 0.65)
                lbl:SetText(AuraUI.L(item.label))

                row:SetScript("OnEnter", function() lbl:SetTextColor(1, 1, 1, 0.95) end)
                row:SetScript("OnLeave", function() lbl:SetTextColor(1, 1, 1, 0.65) end)
                row:SetScript("OnClick", function()
                    transformsStaged[item.key] = not transformsStaged[item.key]
                    RefreshRows()
                end)
                rows[#rows + 1] = row
            end
        end

        -- Apply button (green, spec-popup style)
        local applyBtn = CreateFrame("Button", nil, popup)
        applyBtn:SetFrameLevel(popup:GetFrameLevel() + 2)
        applyBtn:SetSize(200, 39)
        applyBtn:SetPoint("BOTTOM", popup, "BOTTOM", 0, 38)
        local applyBg = applyBtn:CreateTexture(nil, "BACKGROUND")
        applyBg:SetAllPoints()
        applyBg:SetColorTexture(0.06, 0.08, 0.10, 0.92)
        local applyBrd = AuraUI.MakeBorder(applyBtn, EG.r, EG.g, EG.b, 0.9, PP)
        local applyLbl = applyBtn:CreateFontString(nil, "OVERLAY")
        applyLbl:SetFont(FONT, 16, "")
        applyLbl:SetPoint("CENTER")
        applyLbl:SetText(AuraUI.L("Apply"))
        applyLbl:SetTextColor(EG.r, EG.g, EG.b, 0.9)
        applyBtn:SetScript("OnEnter", function()
            applyLbl:SetTextColor(EG.r, EG.g, EG.b, 1)
            applyBrd:SetColor(EG.r, EG.g, EG.b, 1)
        end)
        applyBtn:SetScript("OnLeave", function()
            applyLbl:SetTextColor(EG.r, EG.g, EG.b, 0.9)
            applyBrd:SetColor(EG.r, EG.g, EG.b, 0.9)
        end)
        applyBtn:SetScript("OnClick", function()
            if not AuraUIDB then AuraUIDB = {} end
            AuraUIDB.hideTransformItems = AuraUIDB.hideTransformItems or {}
            local t = AuraUIDB.hideTransformItems
            for _, item in ipairs(data.items) do
                local staged = transformsStaged[item.key] and true or false
                if staged == (not item.defaultOff) then
                    t[item.key] = nil       -- matches the per-key default
                else
                    t[item.key] = staged    -- stored deviations only
                end
            end
            if AuraUI._applyHideTransforms then AuraUI._applyHideTransforms() end
            dimmer:Hide()
        end)

        -- Click outside or Escape discards staged edits
        dimmer:SetScript("OnMouseDown", function(self)
            if not popup:IsMouseOver() then self:Hide() end
        end)
        popup:EnableKeyboard(true)
        popup:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                dimmer:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)

        popup._dimmer = dimmer
        transformsPopup = popup
    end

    -- Seed the staged state from the saved settings, then show
    for _, item in ipairs(data.items) do
        transformsStaged[item.key] = AuraUI.GetHideTransformItem(item.key) and true or false
    end
    transformsPopup._refreshRows()
    transformsPopup._dimmer:Show()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    if not AuraUI or not AuraUI.RegisterModule then return end

    ---------------------------------------------------------------------------
    --  QoL Features page
    ---------------------------------------------------------------------------
    local function BuildQoLPage(pageName, parent, yOffset)
        local W = AuraUI.Widgets
        local y = yOffset
        local _, h
        local PP = AuraUI.PanelPP

        parent._showRowDivider = true

        _, h = W:Spacer(parent, y, 20);  y = y - h

        -- The Macro Factory is deliberately NOT part of the global search. Its builder
        -- arms live machinery at build time (a session event frame that rewrites the
        -- player's real AUI_* macros on bag/spec events), so the hidden search
        -- pre-build must never run it, and its rows are kept out of the search index so
        -- results can never point into it (the index would otherwise deep-link to rows
        -- whose page state the factory manages itself).
        if AuraUI.BuildMacroFactory and not AuraUI._prebuilding then
            AuraUI._searchIndexSuppress = true
            local mfH = AuraUI.BuildMacroFactory(parent, y, PP)
            AuraUI._searchIndexSuppress = nil
            y = y - mfH
        end

        ---------------------------------------------------------------------------
        --  GENERAL
        ---------------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "GENERAL", y);  y = y - h

        local row1
        row1, h = W:DualRow(parent, y,
            { type="toggle", text="Hide Blizzard Party Panel",
              tooltip="Hides the collapsed Blizzard party/raid sidebar panel on the side of the screen.",
              disabled=function() return C_AddOns and C_AddOns.IsAddOnLoaded("AuraUIRaidFrames") end,
              disabledTooltip="This option is now controlled by the Raid Frames addon", rawTooltip=true,
              getValue=function()
                  return AuraUIDB and AuraUIDB.hideBlizzardPartyFrame or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideBlizzardPartyFrame = v
                  AuraUI._applyHideBlizzardPartyFrame()
              end },
            { type="toggle", text="Skip Cinematics",
              tooltip="When you press Escape or Space during a cinematic, the confirmation prompt is automatically accepted.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.skipCinematics or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.skipCinematics = v
                  AuraUI:RefreshPage()
              end }
        );  y = y - h

        -- Cog on Skip Cinematics (right region of row1)
        if not AuraUI._prebuilding then
            local rightRgn = row1._rightRegion
            local function cinematicsOff()
                return not (AuraUIDB and AuraUIDB.skipCinematics)
            end

            AuraUI.BuildInlineCog(rightRgn, {
                title = "Cinematic Settings",
                rows = {
                    { type="toggle", label="Automatically Skip If Possible",
                      get=function()
                          return AuraUIDB and AuraUIDB.skipCinematicsAuto or false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.skipCinematicsAuto = v
                      end },
                },
                gap = 9, disabled = cinematicsOff, disabledTooltip = "Skip Cinematics",
            })
        end

        local row2
        row2, h = W:DualRow(parent, y,
            { type="toggle", text="Quick Loot",
              tooltip="Enables auto loot and hides the loot window when looting. Hold Shift when looting to show.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.quickLoot or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.quickLoot = v
                  if AuraUI._applyQuickLoot then AuraUI._applyQuickLoot() end
              end },
            { type="toggle", text="Auto-Fill Delete Confirmation",
              tooltip="Automatically types DELETE when throwing away a valuable item. Also allows you to press enter to accept the deletion.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.autoFillDelete or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoFillDelete = v
                  AuraUI:RefreshPage()
              end }
        );  y = y - h

        -- Auto Repair | Auto Sell Junk
        local repairRow
        repairRow, h = W:DualRow(parent, y,
            { type="toggle", text="Auto Repair",
              tooltip="Automatically repair all gear when visiting a repair vendor.",
              getValue=function()
                  if not AuraUIDB then return true end
                  return AuraUIDB.autoRepair ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoRepair = v
                  AuraUI:RefreshPage()
              end },
            { type="toggle", text="Auto Sell Junk",
              tooltip="Automatically sell all junk items when visiting a vendor.",
              getValue=function()
                  if not AuraUIDB then return true end
                  return AuraUIDB.autoSellJunk ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoSellJunk = v
              end }
        );  y = y - h

        -- Cog on Auto Repair (left region)
        if not AuraUI._prebuilding then
            local leftRgn = repairRow._leftRegion
            local function repairOff()
                return not (AuraUIDB and AuraUIDB.autoRepair ~= false)
            end

            AuraUI.BuildInlineCog(leftRgn, {
                title = "Auto Repair Settings",
                rows = {
                    { type="toggle", label="Use Guild Bank Funds",
                      get=function()
                          if not AuraUIDB then return true end
                          return AuraUIDB.autoRepairGuild ~= false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.autoRepairGuild = v
                      end },
                    -- Off (default) = short text "12o 34a"; on = coin icons.
                    { type="toggle", label="Coin Icons",
                      get=function()
                          return AuraUIDB and AuraUIDB.repairCoinIcons == true
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.repairCoinIcons = v
                      end },
                },
                gap = 9, disabled = repairOff, disabledTooltip = "Auto Repair",
            })
        end

        -- AH Current Expansion Only | Hide Talking Head. Not offered on WoW
        -- Forever: the row is not built there and neither runtime block exists.
        if not AuraUI.IS_FOREVER then
        _, h = W:DualRow(parent, y,
            { type="toggle", text="AH Current Expansion Only",
              tooltip="Automatically enables the 'Current Expansion Only' filter whenever you open the Auction House.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.ahCurrentExpansion or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.ahCurrentExpansion = v
              end },
            { type="toggle", text="Hide Talking Head",
              tooltip="Hides the large NPC dialogue popup that appears during quests and dungeons.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.hideTalkingHead or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideTalkingHead = v
              end }
        );  y = y - h
        end -- not IS_FOREVER

        -- Row 5: Show Coordinates on Map (left, with cog) | Suppress Lua Errors
        -- (Suppress Lua Errors is a front-end duplicate of the toggle in
        -- Global Settings > Developer; same AuraUIDB.suppressErrors key and
        -- scriptErrors CVar, applied on login by the parent General module.)
        local coordRow
        coordRow, h = W:DualRow(parent, y,
            { type="toggle", text="Show Coordinates on Map",
              tooltip="Displays cursor and player coordinates at the bottom of the world map.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.mapCoords or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.mapCoords = v
                  if AuraUI._applyMapCoords then AuraUI._applyMapCoords() end
                  AuraUI:RefreshPage()
              end },
            { type="toggle", text="Suppress Lua Errors",
              tooltip="Hides the Lua error popup. The same setting as Global Settings > Developer.",
              getValue=function()
                  return not (AuraUIDB and AuraUIDB.suppressErrors == false)
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.suppressErrors = v
                  if not InCombatLockdown() then SetCVar("scriptErrors", v and "0" or "1") end
              end }
        );  y = y - h

        -- Cog on Show Coordinates on Map (left region)
        if not AuraUI._prebuilding then
            local leftRgn = coordRow._leftRegion
            local function coordsOff()
                return AuraUIDB and AuraUIDB.mapCoords == false
            end

            AuraUI.BuildInlineCog(leftRgn, {
                title = "Map Coordinates Settings",
                rows = {
                    { type = "slider", label = "Text Size", min = 8, max = 24, step = 1,
                      get = function()
                          return (AuraUIDB and AuraUIDB.mapCoordsTextSize) or 12
                      end,
                      set = function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.mapCoordsTextSize = v
                          if AuraUI._applyMapCoords then AuraUI._applyMapCoords() end
                      end },
                },
                gap = 9, disabled = coordsOff, disabledTooltip = "Show Coordinates on Map",
            })
        end

        -- Row 6: Hide Error Messages (left) | Hide Tutorial Pop-ups (right)
        _, h = W:DualRow(parent, y,
            { type="toggle", text="Hide Error Messages",
              tooltip="Hides most red error messages (such as 'Not enough rage' or 'Ability is not ready yet'). Important errors like a full bag or quest log are still shown.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.hideErrorMessages or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideErrorMessages = v
                  if AuraUI._applyHideErrorMessages then AuraUI._applyHideErrorMessages() end
              end },
            { type="toggle", text="Hide Tutorial Pop-ups",
              tooltip="Hides Blizzard's tutorial UI: the yellow HelpTip bubbles and the glowing (i) help-plate buttons on the spellbook, talents, map, collections, and other panels.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.hideTutorials or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideTutorials = v
                  if AuraUI._applyHideTutorials then AuraUI._applyHideTutorials() end
              end }
        );  y = y - h

        -- Row: Hide Loot Rolls Window (left, with settings cog) | Combat
        -- Alert (right, with its own settings cog below)
        local lootHistRow
        lootHistRow, h = W:DualRow(parent, y,
            { type="toggle", text="Hide Loot Rolls Window",
              tooltip="Hides Blizzard's \"Loot Rolls\" window -- the running list of dropped items showing who rolled what and who won. Use the cog to let it appear briefly and close itself instead. The Need/Greed roll popups themselves are not affected.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.hideLootHistory or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideLootHistory = v
                  if AuraUI._applyHideLootHistory then AuraUI._applyHideLootHistory() end
                  AuraUI:RefreshPage()  -- update the cog disabled state
              end },
            { type="toggle", text="Combat Alert",
              tooltip="Shows a large on-screen text when you enter and/or leave combat (e.g. \"+Combat\" / \"-Combat\"). Use the cog to set the display text, size, colors and which transitions are shown; use Unlock Mode to reposition the alert.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.combatAlertEnabled or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.combatAlertEnabled = v
                  if AuraUI._applyCombatAlert then AuraUI._applyCombatAlert() end
                  AuraUI:RefreshPage()
              end }
        );  y = y - h

        -- Inline cog (mode + auto-close delay) on the Hide Loot Rolls toggle
        if not AuraUI._prebuilding then
            local leftRgn = lootHistRow._leftRegion
            local function lootHistOff()
                return not (AuraUIDB and AuraUIDB.hideLootHistory)
            end
            -- The delay only means anything in auto-close mode.
            local function delayOff()
                return lootHistOff()
                    or (AuraUIDB and AuraUIDB.lootHistoryMode) ~= "autoclose"
            end

            local lhModeValues = {
                hide      = "Hide Completely",
                autoclose = "Close After Delay",
            }
            local lhModeOrder = { "hide", "autoclose" }

            AuraUI.BuildInlineCog(leftRgn, {
                title = "Loot Rolls Window Settings",
                minWidth = 300,
                rows = {
                    { type="dropdown", label="Mode",
                      values=lhModeValues, order=lhModeOrder,
                      get=function() return (AuraUIDB and AuraUIDB.lootHistoryMode) or "hide" end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.lootHistoryMode = v
                        if AuraUI._applyHideLootHistory then AuraUI._applyHideLootHistory() end
                      end },
                    { type="slider", label="Close After (sec)",
                      min=1, max=30, step=1,
                      disabled=delayOff,
                      get=function()
                        return (AuraUIDB and AuraUIDB.lootHistoryDelay) or 5
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.lootHistoryDelay = v
                        if AuraUI._applyHideLootHistory then AuraUI._applyHideLootHistory() end
                      end },
                },
                gap = 9, disabled = lootHistOff, disabledTooltip = "Hide Loot Rolls Window",
            })
        end

        -- Row 7: Announce Group Deaths (left, with Text Size cog) | Hide Item
        -- Transforms (right, with picker cog)
        local deathRow
        deathRow, h = W:DualRow(parent, y,
            { type="toggle", text="Announce Group Deaths",
              tooltip="Shows a large on-screen alert (e.g. \"Player DIED!\") whenever a party or raid member dies, so you immediately notice deaths during dungeons and raids. Use Unlock Mode to reposition the alert.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.announceGroupDeaths or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.announceGroupDeaths = v
                  if AuraUI._applyAnnounceGroupDeaths then AuraUI._applyAnnounceGroupDeaths() end
                  AuraUI:RefreshPage()
              end },
            { type="toggle", text="Hide Item Transforms (ex: Chef's Hat)",
              tooltip="Automatically removes cosmetic transforms when they are applied to you, such as profession gear, holiday costumes, toys and consumables. Use the cog to pick exactly which transforms are removed. Transforms applied during combat are removed when combat ends.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.hideTransforms or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideTransforms = v
                  if AuraUI._applyHideTransforms then
                      AuraUI._applyHideTransforms()
                  end
                  AuraUI:RefreshPage()  -- update the picker cog disabled state
              end }
        );  y = y - h

        -- Inline cog (Text Size) on the Announce Group Deaths toggle
        if not AuraUI._prebuilding then
            local leftRgn = deathRow._leftRegion
            local function deathOff()
                return not (AuraUIDB and AuraUIDB.announceGroupDeaths)
            end

            -- Sound dropdown values (mirrors Chat's "Whisper Sound"): shallow-copy
            -- the runtime name table and attach _menuOpts so each row gets a
            -- click-to-preview speaker icon.
            local gdSoundPaths = AuraUI._groupDeathSoundPaths or {}
            local gdSoundNames = AuraUI._groupDeathSoundNames or { none = "None" }
            local gdSoundOrder = AuraUI._groupDeathSoundOrder or { "none" }
            local gdSoundValues = {}
            for k, v in pairs(gdSoundNames) do gdSoundValues[k] = v end
            gdSoundValues._menuOpts = {
                itemHeight = 26,
                maxTextWidthPct = 0.8,
                searchable = true,
                iconAtlas = function(key)
                    if key == "none" then return nil end
                    if not gdSoundPaths[key] then return nil end
                    return "common-icon-sound"
                end,
                iconPressedAtlas = function(key)
                    if key == "none" then return nil end
                    return "common-icon-sound-pressed"
                end,
                iconOnClick = function(key)
                    local path = gdSoundPaths[key]
                    if path then PlaySoundFile(path, "Master") end
                end,
                iconTooltip = function() return "Preview Sound" end,
            }

            AuraUI.BuildInlineCog(leftRgn, {
                title = "Group Death Alert Settings",
                rows = {
                    { type="slider", label="Text Size",
                      min=14, max=64, step=1,
                      get=function()
                        return (AuraUIDB and AuraUIDB.groupDeathTextSize) or 34
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.groupDeathTextSize = v
                        if AuraUI._applyGroupDeathAlert then AuraUI._applyGroupDeathAlert() end
                        if AuraUI._groupDeathShowVisual then AuraUI._groupDeathShowVisual() end
                      end },
                    { type="dropdown", label="Sound",
                      values=gdSoundValues, order=gdSoundOrder,
                      get=function()
                        return (AuraUIDB and AuraUIDB.groupDeathSoundKey) or "none"
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.groupDeathSoundKey = v
                        if v ~= "none" and AuraUI._groupDeathPlaySound then
                            AuraUI._groupDeathPlaySound()
                        end
                      end },
                },
                gap = 9, disabled = deathOff, disabledTooltip = "Announce Group Deaths",
            })
        end

        -- Inline cog (text, size, colors, mode) on the Combat Alert toggle
        -- (the RIGHT slot of the Hide Loot Rolls row above).
        if not AuraUI._prebuilding then
            local leftRgn = lootHistRow._rightRegion
            local function caOff()
                return not (AuraUIDB and AuraUIDB.combatAlertEnabled)
            end
            local function enterClassOn()
                return AuraUIDB and AuraUIDB.combatAlertEnterUseClassColor
            end
            local function leaveClassOn()
                return AuraUIDB and AuraUIDB.combatAlertLeaveUseClassColor
            end

            local caModeValues = {
                both  = "Enter & Leave",
                enter = "Enter Only",
                leave = "Leave Only",
            }
            local caModeOrder = { "both", "enter", "leave" }

            AuraUI.BuildInlineCog(leftRgn, {
                title = "Combat Alert Settings",
                minWidth = 300,
                rows = {
                    { type="dropdown", label="Show On",
                      values=caModeValues, order=caModeOrder,
                      get=function() return (AuraUIDB and AuraUIDB.combatAlertMode) or "both" end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertMode = v
                      end },
                    { type="slider", label="Text Size",
                      min=14, max=64, step=1,
                      get=function()
                        return (AuraUIDB and AuraUIDB.combatAlertTextSize) or 22
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertTextSize = v
                        if AuraUI._applyCombatAlertFrame then AuraUI._applyCombatAlertFrame() end
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("enter") end
                      end },
                    { type="input", label="Enter Text", inputWidth=90,
                      get=function()
                        return (AuraUIDB and AuraUIDB.combatAlertEnterText) or "+Combat"
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertEnterText = v
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("enter") end
                      end },
                    { type="colorpicker", label="Enter Color",
                      disabled=enterClassOn,
                      disabledTooltip="Disable Class Color to pick a custom color.", rawTooltip=true,
                      get=function()
                        local c = (AuraUIDB and AuraUIDB.combatAlertEnterColor) or { r=1.00, g=1.00, b=1.00 }
                        return c.r, c.g, c.b
                      end,
                      set=function(r, g, b)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertEnterColor = { r=r, g=g, b=b }
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("enter") end
                      end },
                    { type="toggle", label="Enter Class Color",
                      get=function() return enterClassOn() end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertEnterUseClassColor = v
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("enter") end
                      end },
                    { type="input", label="Leave Text", inputWidth=90,
                      get=function()
                        return (AuraUIDB and AuraUIDB.combatAlertLeaveText) or "-Combat"
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertLeaveText = v
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("leave") end
                      end },
                    { type="colorpicker", label="Leave Color",
                      disabled=leaveClassOn,
                      disabledTooltip="Disable Class Color to pick a custom color.", rawTooltip=true,
                      get=function()
                        local c = (AuraUIDB and AuraUIDB.combatAlertLeaveColor) or { r=1.00, g=1.00, b=1.00 }
                        return c.r, c.g, c.b
                      end,
                      set=function(r, g, b)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertLeaveColor = { r=r, g=g, b=b }
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("leave") end
                      end },
                    { type="toggle", label="Leave Class Color",
                      get=function() return leaveClassOn() end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.combatAlertLeaveUseClassColor = v
                        if AuraUI._combatAlertPreview then AuraUI._combatAlertPreview("leave") end
                      end },
                },
                footer = { unlockKey = "AUI_CombatAlert" },
                gap = 9, disabled = caOff, disabledTooltip = "Combat Alert",
            })
        end

        -- (Target Distance Text moved to the EXTRAS section, Row 4 right slot.)

        -- Inline picker cog on Hide Item Transforms (right slot of the death
        -- row): opens the item checklist popup. Dimmed and inert while the
        -- toggle is off, mirroring the resource-bar spec-picker button.
        if not AuraUI._prebuilding then
            local rgn = deathRow._rightRegion
            local function hitOff()
                return not (AuraUIDB and AuraUIDB.hideTransforms)
            end
            AuraUI.BuildInlineCog(rgn, {
                gap = 9, tip = AuraUI.L("Choose which transforms are removed"),
                disabled = hitOff, disabledTooltip = "Hide Item Transforms",
                show = function() ShowTransformsPopup() end,
            })
        end

        _, h = W:DualRow(parent, y,
            { type="toggle", text="Auto Select Single Gossip",
              tooltip="Talking to an NPC with only one dialog option picks it for you, unless they have a quest for you.",
              getValue=function()
                  if not AuraUIDB then return true end
                  return AuraUIDB.autoSelectSingleGossip ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoSelectSingleGossip = v
              end },
            AuraUI.BlankRowCfg()
        );  y = y - h

        _, h = W:Spacer(parent, y, 20);  y = y - h

        ---------------------------------------------------------------------------
        --  EXTRAS
        ---------------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "EXTRAS", y);  y = y - h

        -- Row 1: Show FPS Counter (left, with swatch+cog) | FPS Toggle Keybind (right)
        local fpsRow
        fpsRow, h = W:DualRow(parent, y,
            { type="toggle", text="Show FPS Counter",
              getValue=function()
                return AuraUI.QoLExtrasGet("showFPS") or false
              end,
              setValue=function(v)
                AuraUI.QoLExtrasSet("showFPS", v)
                if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                AuraUI:RefreshPage()
              end },
            { type="label", text="FPS Toggle Keybind" }
        );  y = y - h

        -- Inline color swatch + cog on the FPS toggle (left region)
        if not AuraUI._prebuilding then
            local leftRgn = fpsRow._leftRegion
            local function fpsOff()
                return not AuraUI.QoLExtrasGet("showFPS")
            end

            -- Inline class + custom colour swatches, the same convention as the
            -- Secondary Stats row: the active mode renders at full alpha, the
            -- other dimmed, each with a naming tooltip.
            local function fpsMode()
                -- No mode saved: custom -- the look before the mode existed,
                -- which is white until a colour is actually picked.
                return AuraUI.QoLExtrasGet("fpsColorMode") or "custom"
            end
            local fpsUpdateState   -- forward: swatches reference it from OnClick
            local function fpsSetMode(v)
                AuraUI.QoLExtrasSet("fpsColorMode", v)
                if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                if fpsUpdateState then fpsUpdateState() end
            end

            local fpsSwGet = function()
                local c = AuraUI.QoLExtrasGet("fpsColor")
                if c then return c.r, c.g, c.b, c.a end
                return 1, 1, 1, 1
            end
            local fpsSwSet = function(r, g, b, a)
                AuraUI.QoLExtrasSet("fpsColor", { r = r, g = g, b = b, a = a })
                AuraUI.QoLExtrasSet("fpsColorMode", "custom")
                if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                if fpsUpdateState then fpsUpdateState() end
            end
            -- Custom swatch (nearest the control): a click switches to custom
            -- mode first; a second click opens the picker.
            local fpsSwatch, fpsUpdateSwatch = AuraUI.BuildColorSwatch(leftRgn, leftRgn:GetFrameLevel() + 5, fpsSwGet, fpsSwSet, true, 20)
            do
                local openPicker = fpsSwatch:GetScript("OnClick")
                fpsSwatch:SetScript("OnClick", function(self)
                    if fpsMode() ~= "custom" then fpsSetMode("custom") return end
                    if openPicker then openPicker(self) end
                end)
            end
            PP.Point(fpsSwatch, "RIGHT", leftRgn._control, "LEFT", -12, 0)
            leftRgn._lastInline = fpsSwatch

            -- Class-colour swatch: live player class colour.
            local fpsClassSw, fpsUpdClass = AuraUI.BuildColorSwatch(
                leftRgn, leftRgn:GetFrameLevel() + 5,
                function()
                    local cc = AuraUI.GetClassColor(select(2, UnitClass("player")))
                    if cc then return cc.r, cc.g, cc.b end
                    return 1, 1, 1
                end,
                function() end, nil, 20)
            fpsClassSw:SetScript("OnClick", function() fpsSetMode("class") end)
            PP.Point(fpsClassSw, "RIGHT", leftRgn._lastInline, "LEFT", -8, 0)
            leftRgn._lastInline = fpsClassSw

            local fpsTips = { { fpsClassSw, "Class Color" }, { fpsSwatch, "Custom Color" } }
            for _, e in ipairs(fpsTips) do
                e[1]:HookScript("OnEnter", function() AuraUI.ShowWidgetTooltip(e[1], e[2]) end)
                e[1]:HookScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            end

            -- Blocking overlays while Show FPS Counter is off (shown from the
            -- single refresh below, like the swatch alphas).
            local fpsBlocks = {}
            for _, e in ipairs(fpsTips) do
                local sw = e[1]
                local block = CreateFrame("Frame", nil, sw)
                block:SetAllPoints()
                block:SetFrameLevel(sw:GetFrameLevel() + 10)
                block:EnableMouse(true)
                block:SetScript("OnEnter", function()
                    AuraUI.ShowWidgetTooltip(sw, AuraUI.DisabledTooltip("Show FPS Counter"))
                end)
                block:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
                fpsBlocks[#fpsBlocks + 1] = block
            end

            -- While the counter is off both swatches dim flat; while on, the
            -- active mode is bright and the other dimmed. One refresh owns
            -- both, plus the swatch fills (class color changes, custom picks).
            fpsUpdateState = function()
                if fpsUpdateSwatch then fpsUpdateSwatch() end
                if fpsUpdClass then fpsUpdClass() end
                local off = fpsOff()
                for _, block in ipairs(fpsBlocks) do block:SetShown(off) end
                local m = not off and fpsMode() or nil
                fpsClassSw:SetAlpha(m == "class" and 1 or 0.3)
                fpsSwatch:SetAlpha(m == "custom" and 1 or 0.3)
            end
            AuraUI.RegisterWidgetRefresh(fpsUpdateState)
            fpsUpdateState()

            AuraUI.BuildInlineCog(leftRgn, {
                title = "FPS Counter Settings",
                rows = {
                    { type="toggle", label="Attach to Secondary Stats",
                      disabled=function()
                        return not AuraUI.QoLExtrasGet("showSecondaryStats")
                      end,
                      disabledTooltip="Secondary Stat Display",
                      get=function()
                        return AuraUI.QoLExtrasGet("fpsAttachToStats") or false
                      end,
                      set=function(v)
                        AuraUI.QoLExtrasSet("fpsAttachToStats", v)
                        if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                      end },
                    -- Attached rows take the Secondary Stats font size, so this
                    -- has nothing to drive while the readout lives over there.
                    { type="slider", label="Text Size",
                      min=8, max=30, step=1,
                      disabled=function()
                        return AuraUI._fpsAttachedToStats
                            and AuraUI._fpsAttachedToStats() or false
                      end,
                      disabledTooltip="Attach to Secondary Stats",
                      requireState="disabled",
                      get=function()
                        return AuraUI.QoLExtrasGet("fpsTextSize") or 12
                      end,
                      set=function(v)
                        AuraUI.QoLExtrasSet("fpsTextSize", v)
                        if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                      end },
                    { type="toggle", label="Show Local MS",
                      get=function()
                        local sl = AuraUI.QoLExtrasGet("fpsShowLocalMS")
                        if sl == nil then return true end
                        return sl
                      end,
                      set=function(v)
                        AuraUI.QoLExtrasSet("fpsShowLocalMS", v)
                        if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                      end },
                    { type="toggle", label="Show World MS",
                      get=function()
                        return AuraUI.QoLExtrasGet("fpsShowWorldMS") or false
                      end,
                      set=function(v)
                        AuraUI.QoLExtrasSet("fpsShowWorldMS", v)
                        if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                      end },
                    { type="toggle", label="Hide Local/World Label",
                      get=function()
                        return AuraUI.QoLExtrasGet("fpsHideLabel") or false
                      end,
                      set=function(v)
                        AuraUI.QoLExtrasSet("fpsHideLabel", v)
                        if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                      end },
                    { type="slider", label="Update Interval", min=1, max=5, step=1,
                      get=function()
                        return AuraUI.QoLExtrasGet("fpsUpdateInterval") or 3
                      end,
                      set=function(v)
                        AuraUI.QoLExtrasSet("fpsUpdateInterval", v)
                        if AuraUI._applyFPSDisplay then AuraUI._applyFPSDisplay() end
                      end },
                },
                gap = 9, disabled = fpsOff, disabledTooltip = "Show FPS Counter",
            })
        end

        -- FPS Toggle Keybind (built into right region of fpsRow)
        if not AuraUI._prebuilding then
            local rightRgn = fpsRow._rightRegion
            local kbBtn, refresh = AuraUI.BuildKeybindButton(rightRgn, {
                w = 140, h = 30, font = 13,
                get = function() return AuraUIDB and AuraUIDB.fpsToggleKey end,
                set = function(fullKey)
                    if not AuraUIDB then AuraUIDB = {} end
                    local bindBtn = _G["AUI_FPSBindBtn"]
                    if not fullKey then
                        if AuraUIDB.fpsToggleKey and bindBtn then ClearOverrideBindings(bindBtn) end
                    elseif bindBtn then
                        -- Binding refused in combat: keep the old key.
                        if InCombatLockdown() then return end
                        ClearOverrideBindings(bindBtn)
                        SetOverrideBindingClick(bindBtn, true, fullKey, "AUI_FPSBindBtn")
                    end
                    AuraUIDB.fpsToggleKey = fullKey
                end,
            })
            PP.Point(kbBtn, "RIGHT", rightRgn, "RIGHT", -20, 0)
            AuraUI.RegisterWidgetRefresh(refresh)
        end

        -- Row 2: Low Durability Warning (left, with cog+eye+swatch) | Disable Right Click Targeting (right)
        local durWarnRow
        durWarnRow, h = W:DualRow(parent, y,
            { type="toggle", text="Low Durability Warning",
              tooltip="Flashes a warning on screen when any equipped item drops below the configured durability threshold. Only triggers out of combat.",
              getValue=function()
                return AuraUIDB and AuraUIDB.repairWarning ~= false
              end,
              setValue=function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.repairWarning = v
                if AuraUI._syncDurWarnEvents then AuraUI._syncDurWarnEvents() end
                if not v and AuraUI._durWarnHidePreview then
                    AuraUI._durWarnHidePreview()
                end
                AuraUI:RefreshPage()
              end },
            { type="dropdown", text="Disable Right Click",
              tooltip="Suppresses right click targeting. Enemies applies everywhere. Allies In Combat only suppresses friendly targets while you are in combat, so you can still right click vendors and NPCs out of combat.\n\nNote: while this is active, holding Left+Right click to move forward won't work if your cursor is over a suppressed nameplate/unit, since this feature has to take over the right mouse button entirely to block targeting.",
              values={ ["_placeholder"]="..." }, order={ "_placeholder" },
              getValue=function() return "_placeholder" end,
              setValue=function() end }
        );  y = y - h

        -- Right slot: multi-select dropdown (Enemies / Allies In Combat).
        -- The backend stays two independent booleans; the dropdown is purely a
        -- front-end grouping, so existing disableRightClickTarget users are kept
        -- exactly as-is and Allies is additive (defaults off).
        if not AuraUI._prebuilding then
            local rcRgn = durWarnRow._rightRegion
            if rcRgn._control then rcRgn._control:Hide() end
            local rcItems = {
                { key = "enemy", label = "Enemies" },
                { key = "ally",  label = "Allies In Combat" },
            }
            local rcCB, rcCBRefresh = AuraUI.BuildVisOptsCBDropdown(
                rcRgn, 200, rcRgn:GetFrameLevel() + 2,
                rcItems,
                function(k)
                    if not AuraUIDB then return false end
                    if k == "enemy" then return AuraUIDB.disableRightClickTarget or false end
                    return AuraUIDB.disableRightClickTargetAllyCombat or false
                end,
                function(k, v)
                    if not AuraUIDB then AuraUIDB = {} end
                    if k == "enemy" then
                        AuraUIDB.disableRightClickTarget = v
                    else
                        AuraUIDB.disableRightClickTargetAllyCombat = v
                    end
                    if AuraUI._applyRightClickTarget then AuraUI._applyRightClickTarget() end
                end)
            PP.Point(rcCB, "RIGHT", rcRgn, "RIGHT", -20, 0)
            rcRgn._control = rcCB
            rcRgn._lastInline = nil
            AuraUI.RegisterWidgetRefresh(rcCBRefresh)
        end

        -- Inline: eyeball | cog | color swatch on the durability warning toggle
        if not AuraUI._prebuilding then
            local leftRgn = durWarnRow._leftRegion
            local function durOff()
                return AuraUIDB and AuraUIDB.repairWarning == false
            end

            -- Color swatch (rightmost inline, closest to toggle)
            local durSwGet = function()
                local c = AuraUIDB and AuraUIDB.durWarnColor
                if c then return c.r, c.g, c.b end
                return 1, 0.27, 0.27
            end
            local durSwSet = function(r, g, b)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.durWarnColor = { r = r, g = g, b = b }
                if AuraUI._applyDurWarn then AuraUI._applyDurWarn() end
            end
            local durSwatch, durUpdateSwatch = AuraUI.BuildColorSwatch(leftRgn, leftRgn:GetFrameLevel() + 5, durSwGet, durSwSet, nil, 20)
            PP.Point(durSwatch, "RIGHT", leftRgn._control, "LEFT", -12, 0)
            leftRgn._lastInline = durSwatch

            -- Disabled overlay for swatch when durability warning is off
            local durSwBlock = CreateFrame("Frame", nil, durSwatch)
            durSwBlock:SetAllPoints()
            durSwBlock:SetFrameLevel(durSwatch:GetFrameLevel() + 10)
            durSwBlock:EnableMouse(true)
            durSwBlock:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(durSwatch, AuraUI.DisabledTooltip("Low Durability Warning"))
            end)
            durSwBlock:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

            AuraUI.RegisterWidgetRefresh(function()
                local off = durOff()
                if off then
                    durSwatch:SetAlpha(0.3)
                    durSwBlock:Show()
                else
                    durSwatch:SetAlpha(1)
                    durSwBlock:Hide()
                end
                durUpdateSwatch()
            end)
            local durInitOff = durOff()
            durSwatch:SetAlpha(durInitOff and 0.3 or 1)
            if durInitOff then durSwBlock:Show() else durSwBlock:Hide() end

            -- Cog popup for durability settings (left of swatch)
            AuraUI.BuildInlineCog(leftRgn, {
                title = "Durability Settings",
                rows = {
                    { type="slider", label="Text Size",
                      min=10, max=50, step=1,
                      get=function()
                        return (AuraUIDB and AuraUIDB.durWarnTextSize) or 30
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.durWarnTextSize = v
                        if AuraUI._durWarnApplySettings then AuraUI._durWarnApplySettings() end
                      end },
                    { type="slider", label="Y-Offset",
                      min=-600, max=600, step=1,
                      get=function()
                        return AuraUIDB and AuraUIDB.durWarnYOffset or 250
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.durWarnYOffset = v
                        AuraUIDB.durWarnPos = nil  -- clear custom pos so slider always takes effect
                        if AuraUI._durWarnPreview then AuraUI._durWarnPreview() end
                      end },
                    { type="slider", label="Repair %",
                      min=5, max=100, step=1,
                      get=function()
                        return AuraUIDB and AuraUIDB.durWarnThreshold or 40
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.durWarnThreshold = v
                      end },
                },
                icon = AuraUI.DIRECTIONS_ICON, gap = 9, disabled = durOff, disabledTooltip = "Low Durability Warning",
            })

            -- Eye icon to toggle durability warning preview (left of cog)
            local EYE_VISIBLE   = AuraUI.EYE_VISIBLE_ICON
            local EYE_INVISIBLE = AuraUI.EYE_INVISIBLE_ICON
            local durPreviewShown = false
            local eyeBtn = CreateFrame("Button", nil, leftRgn)
            eyeBtn:SetSize(26, 26)
            eyeBtn:SetPoint("RIGHT", leftRgn._lastInline or leftRgn._control, "LEFT", -8, 0)
            leftRgn._lastInline = eyeBtn
            eyeBtn:SetFrameLevel(leftRgn:GetFrameLevel() + 5)
            eyeBtn:SetAlpha(durOff() and 0.15 or 0.4)
            local eyeTex = eyeBtn:CreateTexture(nil, "OVERLAY")
            eyeTex:SetAllPoints()
            local function RefreshDurEye()
                if durPreviewShown then
                    eyeTex:SetTexture(EYE_INVISIBLE)
                else
                    eyeTex:SetTexture(EYE_VISIBLE)
                end
            end
            RefreshDurEye()
            eyeBtn:SetScript("OnEnter", function(self)
                self:SetAlpha(0.7)
                AuraUI.ShowWidgetTooltip(self, "Preview durability warning")
            end)
            eyeBtn:SetScript("OnLeave", function(self)
                AuraUI.HideWidgetTooltip()
                self:SetAlpha(0.4)
            end)
            eyeBtn:SetScript("OnClick", function(self)
                durPreviewShown = not durPreviewShown
                RefreshDurEye()
                if durPreviewShown then
                    if AuraUI._applyDurWarn then AuraUI._applyDurWarn() end
                    if AuraUI._durWarnPreview then
                        AuraUI._durWarnPreview()
                    end
                else
                    if AuraUI._durWarnHidePreview then
                        AuraUI._durWarnHidePreview()
                    end
                end
            end)

            -- Blocking overlay for eye when durability warning is off
            local eyeBlock = CreateFrame("Frame", nil, eyeBtn)
            eyeBlock:SetAllPoints()
            eyeBlock:SetFrameLevel(eyeBtn:GetFrameLevel() + 10)
            eyeBlock:EnableMouse(true)
            eyeBlock:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(eyeBtn, AuraUI.DisabledTooltip("Low Durability Warning"))
            end)
            eyeBlock:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

            AuraUI.RegisterWidgetRefresh(function()
                local off = durOff()
                if off then
                    durPreviewShown = false
                    RefreshDurEye()
                    eyeBtn:SetAlpha(0.15)
                    eyeBlock:Show()
                else
                    eyeBtn:SetAlpha(0.4)
                    eyeBlock:Hide()
                end
            end)
            local eyeInitOff = durOff()
            eyeBtn:SetAlpha(eyeInitOff and 0.15 or 0.4)
            if eyeInitOff then eyeBlock:Show() else eyeBlock:Hide() end
        end

        -- Row 3: Secondary Stat Display (left, with swatch+cog) | Guild Chat Privacy (right)
        local row4
        row4, h = W:DualRow(parent, y,
            { type="toggle", text="Secondary Stat Display",
              tooltip=AuraUI.IS_FOREVER
                  and "Displays secondary stat percentages (Crit, Haste) at the top left of the screen."
                  or "Displays secondary stat percentages (Crit, Haste, Mastery, Vers) at the top left of the screen.",
              getValue=function()
                return AuraUI.QoLExtrasGet("showSecondaryStats") or false
              end,
              setValue=function(v)
                AuraUI.QoLExtrasSet("showSecondaryStats", v)
                -- Turning the block off has to release an attached FPS readout
                -- back to its own frame, so route through the shared apply.
                if AuraUI._applyFPSDisplay then
                    AuraUI._applyFPSDisplay()
                elseif AuraUI._applySecondaryStats then
                    AuraUI._applySecondaryStats()
                end
                AuraUI:RefreshPage()
              end },
            { type="toggle", text="Guild Chat Privacy Cover",
              tooltip="Displays a spoiler tag over guild chat in the communities window that you can click to hide",
              getValue=function()
                return AuraUIDB and AuraUIDB.guildChatPrivacy or false
              end,
              setValue=function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.guildChatPrivacy = v
                if AuraUI._applyGuildChatPrivacy then AuraUI._applyGuildChatPrivacy() end
              end }
        );  y = y - h

        -- Inline color swatch + cog on Secondary Stat Display (left region)
        if not AuraUI._prebuilding then
            local leftRgn = row4._leftRegion
            local function statsOff()
                return not AuraUI.QoLExtrasGet("showSecondaryStats")
            end

            -- Inline default + class + custom colour swatches, following the
            -- minimap border's swatch-row convention: the active mode renders
            -- at full alpha, the others dimmed, each with a naming tooltip.
            local function ssMode()
                local m = AuraUI.QoLExtrasGet("secondaryStatsColorMode")
                if m then return m end
                -- No mode saved: a stored color was in use, otherwise class
                -- color -- the pre-mode default look.
                return AuraUI.QoLExtrasGet("secondaryStatsColor") and "custom" or "class"
            end
            local ssUpdateState   -- forward: swatches reference it from OnClick
            local function ssSetMode(v)
                AuraUI.QoLExtrasSet("secondaryStatsColorMode", v)
                if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                if ssUpdateState then ssUpdateState() end
            end

            -- Custom swatch (nearest the control): stored custom colour. A
            -- click switches to custom mode first; a second click opens the
            -- picker (same two-step as the minimap border swatches).
            local ssCustom, ssUpdCustom = AuraUI.BuildColorSwatch(
                leftRgn, leftRgn:GetFrameLevel() + 5,
                function()
                    local c = AuraUI.QoLExtrasGet("secondaryStatsColor")
                    if c then return c.r, c.g, c.b end
                    return 1, 1, 1
                end,
                function(r, g, b)
                    AuraUI.QoLExtrasSet("secondaryStatsColor", { r = r, g = g, b = b })
                    AuraUI.QoLExtrasSet("secondaryStatsColorMode", "custom")
                    if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                    if ssUpdateState then ssUpdateState() end
                end, nil, 20)
            do
                local openPicker = ssCustom:GetScript("OnClick")
                ssCustom:SetScript("OnClick", function(self)
                    if ssMode() ~= "custom" then ssSetMode("custom") return end
                    if openPicker then openPicker(self) end
                end)
            end
            PP.Point(ssCustom, "RIGHT", leftRgn._control, "LEFT", -12, 0)
            leftRgn._lastInline = ssCustom

            -- Class-colour swatch: live player class colour.
            local ssClass, ssUpdClass = AuraUI.BuildColorSwatch(
                leftRgn, leftRgn:GetFrameLevel() + 5,
                function()
                    local cc = AuraUI.GetClassColor(select(2, UnitClass("player")))
                    if cc then return cc.r, cc.g, cc.b end
                    return 1, 1, 1
                end,
                function() end, nil, 20)
            ssClass:SetScript("OnClick", function() ssSetMode("class") end)
            PP.Point(ssClass, "RIGHT", leftRgn._lastInline, "LEFT", -8, 0)
            leftRgn._lastInline = ssClass

            -- Multicolored swatch (outermost): the per-stat palette, previewed
            -- by its first hue (crit gold).
            local ssMulti, ssUpdMulti = AuraUI.BuildColorSwatch(
                leftRgn, leftRgn:GetFrameLevel() + 5,
                function() return 1, 209 / 255, 0 end,
                function() end, nil, 20)
            ssMulti:SetScript("OnClick", function() ssSetMode("palette") end)
            PP.Point(ssMulti, "RIGHT", leftRgn._lastInline, "LEFT", -8, 0)
            leftRgn._lastInline = ssMulti

            local ssTips = { { ssMulti, "Multicolored" }, { ssClass, "Class Color" }, { ssCustom, "Custom Color" } }
            for _, e in ipairs(ssTips) do
                e[1]:HookScript("OnEnter", function() AuraUI.ShowWidgetTooltip(e[1], e[2]) end)
                e[1]:HookScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            end

            -- Blocking overlays while Secondary Stat Display is off (shown from
            -- the single refresh below, like the swatch alphas).
            local ssBlocks = {}
            for _, e in ipairs(ssTips) do
                local sw = e[1]
                local block = CreateFrame("Frame", nil, sw)
                block:SetAllPoints()
                block:SetFrameLevel(sw:GetFrameLevel() + 10)
                block:EnableMouse(true)
                block:SetScript("OnEnter", function()
                    AuraUI.ShowWidgetTooltip(sw, AuraUI.DisabledTooltip("Secondary Stat Display"))
                end)
                block:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
                ssBlocks[#ssBlocks + 1] = block
            end

            -- While the display is off every swatch dims flat; while on, the
            -- active mode is bright and the others dimmed. One refresh owns
            -- both, plus the swatch fills (class color changes, custom picks).
            ssUpdateState = function()
                if ssUpdCustom then ssUpdCustom() end
                if ssUpdClass then ssUpdClass() end
                if ssUpdMulti then ssUpdMulti() end
                local off = statsOff()
                for _, block in ipairs(ssBlocks) do block:SetShown(off) end
                local m = not off and ssMode() or nil
                ssMulti:SetAlpha(m == "palette" and 1 or 0.3)
                ssClass:SetAlpha(m == "class" and 1 or 0.3)
                ssCustom:SetAlpha(m == "custom" and 1 or 0.3)
            end
            AuraUI.RegisterWidgetRefresh(ssUpdateState)
            ssUpdateState()

            -- Cog popup: stat visibility/order + tertiary swatch pair + Scale
            local function tsMode()
                local m = AuraUI.QoLExtrasGet("tertiaryStatsColorMode")
                if m then return m end
                -- No mode saved: an old profile with a stored color was using it.
                return AuraUI.QoLExtrasGet("tertiaryStatsColor") and "custom" or "class"
            end
            local function tsSetMode(v)
                AuraUI.QoLExtrasSet("tertiaryStatsColorMode", v)
                if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
            end
            local STAT_LABELS = {
                crit = "Crit", haste = "Haste", mastery = "Mastery", vers = "Versatility",
                leech = "Leech", avoidance = "Avoidance", speed = "Speed",
            }
            local TERTIARY_STATS = { leech = true, avoidance = true, speed = true }
            local DEFAULT_STAT_ORDER = {
                "crit", "haste", "mastery", "vers", "leech", "avoidance", "speed",
            }
            local function StatItems()
                local order = AuraUI._secondaryStatsOrder
                    and AuraUI._secondaryStatsOrder() or DEFAULT_STAT_ORDER
                local items = {}
                for _, key in ipairs(order) do
                    items[#items + 1] = { key = key, label = STAT_LABELS[key] }
                end
                return items
            end
            AuraUI.BuildInlineCog(leftRgn, {
                title = "Secondary Stats Settings",
                rows = {
                    -- Key stays `coloredPercentages`: it is the shipped setting
                    -- name, and renaming it would drop everyone's saved choice.
                    { type = "toggle", label = "Colored Values",
                      get = function()
                          return AuraUI.QoLExtrasGet("coloredPercentages") or false
                      end,
                      set = function(v)
                          AuraUI.QoLExtrasSet("coloredPercentages", v)
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end },
                    { type = "toggle", label = "Abbreviate Stat Labels",
                      get = function()
                          return AuraUI.QoLExtrasGet("secondaryStatsAbbreviateLabels") or false
                      end,
                      set = function(v)
                          AuraUI.QoLExtrasSet("secondaryStatsAbbreviateLabels", v)
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end },
                    { type = "toggle", label = "Show Raw Rating",
                      get = function()
                          return AuraUI.QoLExtrasGet("showSecondaryStatsRaw") or false
                      end,
                      set = function(v)
                          AuraUI.QoLExtrasSet("showSecondaryStatsRaw", v)
                          if v then AuraUI.QoLExtrasSet("showSecondaryStatsBoth", false) end
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end },
                    { type = "toggle", label = "Show % and Raw",
                      get = function()
                          return AuraUI.QoLExtrasGet("showSecondaryStatsBoth") or false
                      end,
                      set = function(v)
                          AuraUI.QoLExtrasSet("showSecondaryStatsBoth", v)
                          if v then AuraUI.QoLExtrasSet("showSecondaryStatsRaw", false) end
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end },
                    { type = "reordercheck", label = "Stats to Show",
                      items = StatItems,
                      hint = "Drag to Reorder",
                      get = function(key)
                          local hidden = AuraUI.QoLExtrasGet("secondaryStatsHidden")
                          return not (type(hidden) == "table" and hidden[key])
                      end,
                      set = function(key, shown)
                          local old = AuraUI.QoLExtrasGet("secondaryStatsHidden")
                          local hidden = {}
                          if type(old) == "table" then
                              for k, v in pairs(old) do hidden[k] = v end
                          end
                          if shown then
                              -- Tertiaries default off, so false is the explicit
                              -- per-profile override that keeps one checked.
                              if TERTIARY_STATS[key] then
                                  hidden[key] = false
                              else
                                  hidden[key] = nil
                              end
                          else
                              hidden[key] = true
                          end
                          AuraUI.QoLExtrasSet("secondaryStatsHidden", hidden)
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end,
                      setOrder = function(keys)
                          local order = {}
                          for i, key in ipairs(keys) do order[i] = key end
                          AuraUI.QoLExtrasSet("secondaryStatsOrder", order)
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end },
                    -- Class / custom swatch pair, the same convention as the
                    -- minimap border row: the active mode at full alpha, a
                    -- naming tooltip on each swatch.
                    { type = "multiswatch", label = "Tertiary Label Color",
                      disabled = function()
                          local hidden = AuraUI.QoLExtrasGet("secondaryStatsHidden")
                          return type(hidden) == "table"
                              and hidden.leech and hidden.avoidance and hidden.speed
                      end,
                      disabledTooltip = "a tertiary stat in Stats to Show",
                      swatches = {
                          { tooltip = "Class Color",
                            getValue = function()
                                local cc = AuraUI.GetClassColor(select(2, UnitClass("player")))
                                if cc then return cc.r, cc.g, cc.b end
                                return 1, 1, 1
                            end,
                            onClick = function() tsSetMode("class") end,
                            refreshAlpha = function() return tsMode() == "class" and 1 or 0.3 end },
                          { tooltip = "Custom Color",
                            getValue = function()
                                local c = AuraUI.QoLExtrasGet("tertiaryStatsColor")
                                if c then return c.r, c.g, c.b end
                                return 1, 1, 1
                            end,
                            setValue = function(r, g, b)
                                AuraUI.QoLExtrasSet("tertiaryStatsColor", { r = r, g = g, b = b })
                                AuraUI.QoLExtrasSet("tertiaryStatsColorMode", "custom")
                                if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                            end,
                            -- First click switches to custom; a second opens the picker.
                            onClick = function(self, ...)
                                if tsMode() ~= "custom" then tsSetMode("custom") return end
                                if self._eabOrigClick then self._eabOrigClick(self, ...) end
                            end,
                            refreshAlpha = function() return tsMode() == "custom" and 1 or 0.3 end },
                      } },
                    { type = "slider", label = "Scale", min = 50, max = 200, step = 5,
                      get = function()
                          local pos = AuraUI.QoLExtrasGet("secondaryStatsPos")
                          return math.floor(((pos and pos.scale) or 1.0) * 100 + 0.5)
                      end,
                      set = function(v)
                          -- Shallow-copy so we never mutate the shared account-wide
                          -- fallback table in place; the write lands per-profile.
                          local prev = AuraUI.QoLExtrasGet("secondaryStatsPos")
                          local newPos = {}
                          if prev then for pk, pv in pairs(prev) do newPos[pk] = pv end end
                          newPos.scale = v / 100
                          AuraUI.QoLExtrasSet("secondaryStatsPos", newPos)
                          if AuraUI._applySecondaryStats then AuraUI._applySecondaryStats() end
                      end },
                },
                disabled = statsOff, disabledTooltip = "Secondary Stat Display",
            })
        end

        -- Row 4: Rested Indicator (left) |
        local restedRow
        restedRow, h = W:DualRow(parent, y,
            { type="toggle", text="Rested Indicator",
              tooltip="Displays a ZZZ indicator on your player frame when you are in a resting area.",
              getValue=function()
                if not AuraUIDB then return true end
                return AuraUIDB.showRestedIndicator == true
              end,
              setValue=function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.showRestedIndicator = v
                local pf = _G["AuraUIUnitFrames_Player"]
                if pf and pf._restIndicator then
                    if v and IsResting() then pf._restIndicator:Show() else pf._restIndicator:Hide() end
                end
                AuraUI:RefreshPage()
              end },
            { type="toggle", text="Target Distance Text",
              tooltip="Shows the approximate distance to your current target as movable on-screen text (default 30-35). Use the cog for format, alignment, and text size; use Unlock Mode to position or Anchor to your Player Frame.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.targetDistanceEnabled or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.targetDistanceEnabled = v
                  if AuraUI._applyTargetDistance then AuraUI._applyTargetDistance() end
                  AuraUI:RefreshPage()
              end }
        );  y = y - h

        -- Inline cog on Rested Indicator (left region) for X/Y offsets
        if not AuraUI._prebuilding then
            local leftRgn = restedRow._leftRegion
            local function ApplyRestIndicatorPos()
                local pf = _G["AuraUIUnitFrames_Player"]
                if pf and pf._restIndicator then
                    pf._restIndicator:ClearAllPoints()
                    local rx = (AuraUIDB and AuraUIDB.restedIndicatorXOffset) or 0
                    local ry = (AuraUIDB and AuraUIDB.restedIndicatorYOffset) or 0
                    pf._restIndicator:SetPoint("TOPLEFT", pf.Health, "TOPLEFT", 3 + rx, -2 + ry)
                end
            end
            local function restOff()
                return not AuraUIDB or AuraUIDB.showRestedIndicator ~= true
            end
            AuraUI.BuildInlineCog(leftRgn, {
                title = "Rested Indicator Position",
                rows = {
                    { type="slider", label="X Offset", min=-50, max=50, step=1,
                      get=function() return (AuraUIDB and AuraUIDB.restedIndicatorXOffset) or 0 end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.restedIndicatorXOffset = v
                          ApplyRestIndicatorPos()
                      end },
                    { type="slider", label="Y Offset", min=-50, max=50, step=1,
                      get=function() return (AuraUIDB and AuraUIDB.restedIndicatorYOffset) or 0 end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.restedIndicatorYOffset = v
                          ApplyRestIndicatorPos()
                      end },
                },
                gap = 9, disabled = restOff, disabledTooltip = "Rested Indicator",
            })
        end

        -- Target Distance settings cog (right slot of the Rested row)
        if not AuraUI._prebuilding then
            local rgn = restedRow._rightRegion
            local function tdOff()
                return not (AuraUIDB and AuraUIDB.targetDistanceEnabled)
            end

            local tdFormatValues = {
                range = "Range (30-35)",
                plus  = "Lower Bound (30+)",
                min   = "Minimum (30)",
            }
            local tdFormatOrder = { "range", "plus", "min" }
            local tdAlignValues = {
                LEFT   = "Left",
                CENTER = "Center",
                RIGHT  = "Right",
            }
            local tdAlignOrder = { "LEFT", "CENTER", "RIGHT" }

            AuraUI.BuildInlineCog(rgn, {
                title = "Target Distance Settings",
                minWidth = 280,
                rows = {
                    { type="dropdown", label="Format",
                      values=tdFormatValues, order=tdFormatOrder,
                      get=function()
                        local f = AuraUIDB and AuraUIDB.targetDistanceFormat
                        if f == "plus" or f == "min" or f == "range" then return f end
                        return "range"
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.targetDistanceFormat = v
                        if AuraUI._applyTargetDistanceFrame then AuraUI._applyTargetDistanceFrame() end
                      end },
                    { type="dropdown", label="Text Align",
                      values=tdAlignValues, order=tdAlignOrder,
                      get=function()
                        local a = AuraUIDB and AuraUIDB.targetDistanceAlign
                        if a == "LEFT" or a == "CENTER" or a == "RIGHT" then return a end
                        return "CENTER"
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.targetDistanceAlign = v
                        if AuraUI._applyTargetDistanceFrame then AuraUI._applyTargetDistanceFrame() end
                      end },
                    { type="slider", label="Text Size",
                      min=10, max=48, step=1,
                      get=function()
                        return (AuraUIDB and AuraUIDB.targetDistanceTextSize) or 18
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.targetDistanceTextSize = v
                        if AuraUI._applyTargetDistanceFrame then AuraUI._applyTargetDistanceFrame() end
                      end },
                    { type="dropdown", label="Frame Strata",
                      tooltip="Controls the order that overlapping elements display in. Set higher to show above other elements.",
                      values = AuraUI.FRAME_STRATA_LABELS,
                      order = AuraUI.FRAME_STRATA_ORDER_BASE,
                      get=function()
                        return (AuraUIDB and AuraUIDB.targetDistanceStrata) or "HIGH"
                      end,
                      set=function(v)
                        if not AuraUIDB then AuraUIDB = {} end
                        AuraUIDB.targetDistanceStrata = v
                        if AuraUI._applyTargetDistanceFrame then AuraUI._applyTargetDistanceFrame() end
                      end },
                },
                footer = { unlockKey = "AUI_TargetDistance" },
                gap = 9, disabled = tdOff, disabledTooltip = "Target Distance Text",
            })
        end

        _, h = W:Spacer(parent, y, 20);  y = y - h

        ---------------------------------------------------------------------------
        --  CROSSHAIR
        ---------------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "CROSSHAIR", y);  y = y - h

        -- Crosshair: per-profile live in the QoL DB (_ECL_AceDB.profile),
        -- with the account-wide AuraUIDB root as the inherited default.
        local function cdb() return _G._ECL_AceDB and _G._ECL_AceDB.profile end
        local function cget(k)
            local p = cdb()
            if p and p[k] ~= nil then return p[k] end
            return AuraUIDB and AuraUIDB[k]
        end
        local function cset(k, v) local p = cdb(); if p then p[k] = v end end
        local function crosshairOff()
            return (cget("crosshairSize") or "None") == "None"
        end

        -- True when the effective thickness is custom (would display as
        -- "Custom" if enabled) -- i.e. H/V widths differ or don't match a preset.
        -- Checked regardless of None so a saved custom config can be restored.
        local function crosshairIsCustom()
            local P = AuraUI.CROSSHAIR_PRESETS
            local s = cget("crosshairSize")
            local sizeForBase = (s and s ~= "None" and s) or "Normal"
            local base = (P and (P[sizeForBase] or P.Normal)) or { width = 2 }
            local hw = cget("crosshairHWidth") or base.width
            local vw = cget("crosshairVWidth") or base.width
            if hw ~= vw then return true end
            if P then
                for _, p in pairs(P) do if p.width == hw then return false end end
            end
            return true
        end

        -- Row 1: Character Crosshair (left: dropdown + swatch + cog) | Visibility
        local crosshairRow
        crosshairRow, h = W:DualRow(parent, y,
            { type="dropdown", text="Character Crosshair",
              tooltip="Displays a crosshair at the center of the screen.",
              -- "Custom" is only selectable when a custom thickness is
              -- stored (re-evaluated each time the menu opens); otherwise it's
              -- greyed, since picking it would just produce a preset look.
              itemDisabled=function(v) return v == "custom" and not crosshairIsCustom() end,
			  itemDisabledTooltip=function(v)
				if v == "custom" then return "This option requires a custom thickness to be set." end
      		  end,
              -- The shown value is derived from the actual thickness: a preset name
              -- when the width matches one, otherwise "Custom". "Custom" is also
              -- selectable -- picking it re-enables using the user's stored values
              values={ ["None"]="None", ["Thin"]="Thin", ["Normal"]="Normal", ["Thick"]="Thick", ["custom"]="Custom" },
              order={ "None", "Thin", "Normal", "Thick", "custom" },
              getValue=function()
                local size = cget("crosshairSize") or "None"
                if size == "None" then return "None" end
                local P = AuraUI.CROSSHAIR_PRESETS
                local base = (P and (P[size] or P.Normal)) or { width = 2 }
                local hw = cget("crosshairHWidth") or base.width
                local vw = cget("crosshairVWidth") or base.width
                if hw == vw and P then
                    for name, p in pairs(P) do
                        if p.width == hw then return name end
                    end
                end
                return "custom"
              end,
              setValue=function(v)
                local p = cdb()
                if not p then return end
                p.crosshairSize = v
                -- Presets exist mainly for backwards compatibility. They stamp
                -- only the thickness baseline so Thin/Normal/Thick stay distinct
                -- and the cog reflects them. Length is not touched: it defaults
                -- to the preset length (40) only while unset, and once a user
                -- customises it, it persists across preset changes.
                local preset = AuraUI.CROSSHAIR_PRESETS and AuraUI.CROSSHAIR_PRESETS[v]
                if preset then
                    p.crosshairHWidth = preset.width
                    p.crosshairVWidth = preset.width
                end
                if AuraUI._applyCrosshair then AuraUI._applyCrosshair() end
                AuraUI:RefreshPage()
              end },
            { type="dropdown", text="Visibility",
              tooltip="Choose when the crosshair is shown.",
              disabled=function() return crosshairOff() end,
              disabledTooltip="Enable the crosshair to set its visibility.", rawTooltip=true,
              -- Real control is a multi-select checkbox dropdown injected below;
              -- this placeholder just provides the labelled right-region slot.
              values={ ["_placeholder"]="..." }, order={ "_placeholder" },
              getValue=function() return "_placeholder" end,
              setValue=function() end }
        );  y = y - h

        -- Visibility: multi-select checkbox dropdown (Always / Combat / Instances),
        -- backed by the single crosshairVisibility string for backwards compat:
        --   always | combat | instances | instances_combat
        -- "Always" is the base state. Picking it
        -- clears the others; clearing both reverts to it.
        if not AuraUI._prebuilding then
            local visRgn = crosshairRow._rightRegion
            if visRgn._control then visRgn._control:Hide() end

            local function curVis() return cget("crosshairVisibility") or "always" end
            local visItems = {
                { key = "always",    label = "Always",
                  tooltip = "Always show the crosshair." },
                { key = "combat",    label = "Combat",
                  tooltip = "Show only while in combat. Combine with Instances to show only during instanced combat." },
                { key = "instances", label = "Instances",
                  tooltip = "Show only while in a dungeon, raid, arena or battleground. Combine with Combat to show only during instanced combat." },
            }
            local visCB, visCBRefresh = AuraUI.BuildVisOptsCBDropdown(
                visRgn, 200, visRgn:GetFrameLevel() + 2,
                visItems,
                function(k)
                    local v = curVis()
                    if k == "always"    then return v == "always" end
                    if k == "combat"    then return v == "combat" or v == "instances_combat" end
                    return v == "instances" or v == "instances_combat"
                end,
                function(k, on)
                    local v = curVis()
                    local combat    = (v == "combat" or v == "instances_combat")
                    local instances = (v == "instances" or v == "instances_combat")
                    if k == "always" then
                        if not on then return end  -- can't un-pick the base state directly
                        combat, instances = false, false
                    elseif k == "combat" then
                        combat = on
                    else
                        instances = on
                    end
                    local nv = "always"
                    if combat and instances then nv = "instances_combat"
                    elseif combat then nv = "combat"
                    elseif instances then nv = "instances" end
                    cset("crosshairVisibility", nv)
                    if AuraUI._applyCrosshair then AuraUI._applyCrosshair() end
                end)
            PP.Point(visCB, "RIGHT", visRgn, "RIGHT", -20, 0)
            visRgn._control = visCB
            visRgn._lastInline = nil

            -- Disabled overlay: grey + block when the crosshair is off, matching
            -- the placeholder's disabled state.
            local visBlock = CreateFrame("Frame", nil, visCB)
            visBlock:SetAllPoints()
            visBlock:SetFrameLevel(visCB:GetFrameLevel() + 20)
            visBlock:EnableMouse(true)
            visBlock:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(visCB, "Enable the crosshair to set its visibility.")
            end)
            visBlock:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            local function visUpdateDisabled()
                if crosshairOff() then
                    visCB:SetAlpha(0.4); visBlock:Show()
                else
                    visCB:SetAlpha(1); visBlock:Hide()
                end
            end
            AuraUI.RegisterWidgetRefresh(visCBRefresh)
            AuraUI.RegisterWidgetRefresh(visUpdateDisabled)
            visUpdateDisabled()
        end

        -- Inline color swatch on the crosshair dropdown (left region)
        if not AuraUI._prebuilding then
            local leftRgn = crosshairRow._leftRegion

            local chSwGet = function()
                local c = cget("crosshairColor")
                if c then return c.r, c.g, c.b, c.a end
                return 1, 1, 1, 0.75
            end
            local chSwSet = function(r, g, b, a)
                cset("crosshairColor", { r = r, g = g, b = b, a = a or 1 })
                if AuraUI._applyCrosshair then AuraUI._applyCrosshair() end
            end
            local chSwatch, chUpdateSwatch = AuraUI.BuildColorSwatch(leftRgn, leftRgn:GetFrameLevel() + 5, chSwGet, chSwSet, true, 20)
            PP.Point(chSwatch, "RIGHT", leftRgn._control, "LEFT", -12, 0)
            leftRgn._lastInline = chSwatch

            local chSwBlock = CreateFrame("Frame", nil, chSwatch)
            chSwBlock:SetAllPoints()
            chSwBlock:SetFrameLevel(chSwatch:GetFrameLevel() + 10)
            chSwBlock:EnableMouse(true)
            chSwBlock:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(chSwatch, AuraUI.DisabledTooltip("Character Crosshair"))
            end)
            chSwBlock:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

            AuraUI.RegisterWidgetRefresh(function()
                local off = crosshairOff()
                if off then
                    chSwatch:SetAlpha(0.3)
                    chSwBlock:Show()
                else
                    chSwatch:SetAlpha(1)
                    chSwBlock:Hide()
                end
                chUpdateSwatch()
            end)
            local chInitOff = crosshairOff()
            chSwatch:SetAlpha(chInitOff and 0.3 or 1)
            if chInitOff then chSwBlock:Show() else chSwBlock:Hide() end
        end

        -- Inline cog on the crosshair dropdown (left region) for expanded options
        if not AuraUI._prebuilding then
            local leftRgn = crosshairRow._leftRegion
            local function chCogOff() return crosshairOff() end
            local function presetThick()
                local s = cget("crosshairSize")
                local P = AuraUI.CROSSHAIR_PRESETS
                local p = P and (P[s] or P.Normal)
                return (p and p.width) or 2
            end
            local function applyCH()
                if AuraUI._applyCrosshair then AuraUI._applyCrosshair() end
            end
            local function dbset(k, v)
                cset(k, v)
                applyCH()
            end
            -- Re-resolve the size dropdown's label so it shows "Custom" (or snaps
            -- back to a preset) live when the thickness is changed in this cog.
            local function refreshSizeLabel()
                local ctrl = crosshairRow._leftRegion and crosshairRow._leftRegion._control
                if ctrl and ctrl._refreshLabel then ctrl._refreshLabel() end
            end

            local chCogRows = {
                    { type="slider", label="H Length", min=1, max=500, step=1,
                      get=function() return cget("crosshairHLength") or 40 end,
                      set=function(v) dbset("crosshairHLength", v) end },
                    { type="slider", label="H Width", min=1, max=20, step=1,
                      get=function() return cget("crosshairHWidth") or presetThick() end,
                      set=function(v) dbset("crosshairHWidth", v); refreshSizeLabel() end },
                    { type="slider", label="V Length", min=1, max=500, step=1,
                      get=function() return cget("crosshairVLength") or 40 end,
                      set=function(v) dbset("crosshairVLength", v) end },
                    { type="slider", label="V Width", min=1, max=20, step=1,
                      get=function() return cget("crosshairVWidth") or presetThick() end,
                      set=function(v) dbset("crosshairVWidth", v); refreshSizeLabel() end },
                    { type="slider", label="Border", min=0, max=5, step=1,
                      get=function() return cget("crosshairBorderSize") or 0 end,
                      set=function(v) dbset("crosshairBorderSize", v) end },
                    { type="colorpicker", label="Border Color", hasAlpha=true,
                      get=function()
                          local bc = cget("crosshairBorderColor")
                          if bc then return bc.r, bc.g, bc.b, bc.a end
                          return 0, 0, 0, 1
                      end,
                      set=function(r, g, b, a)
                          cset("crosshairBorderColor", { r = r, g = g, b = b, a = a or 1 })
                          applyCH()
                      end },
                    { type="slider", label="X Offset", min=-200, max=200, step=1,
                      get=function() return cget("crosshairXOffset") or 0 end,
                      set=function(v) dbset("crosshairXOffset", v) end },
                    { type="slider", label="Y Offset", min=-200, max=200, step=1,
                      get=function() return cget("crosshairYOffset") or 0 end,
                      set=function(v) dbset("crosshairYOffset", v) end },
                    { type="dropdown", label="Frame Strata",
                      tooltip="Controls the order that overlapping elements display in. Set higher to show above other elements.",
                      values = AuraUI.FRAME_STRATA_LABELS,
                      order = AuraUI.FRAME_STRATA_ORDER_BASE,
                      get=function() return cget("crosshairStrata") or "MEDIUM" end,
                      set=function(v) dbset("crosshairStrata", v) end },
            }
            -- Holy Paladin uses a 40yd out-of-range cutoff by default; let
            -- paladins opt into a melee (5yd) cutoff. Shown only for Paladins.
            if select(2, UnitClass("player")) == "PALADIN" then
                chCogRows[#chCogRows + 1] = {
                    type="toggle", label="Show Melee Range for Hpal",
                    get=function() return cget("crosshairHpalMelee") == true end,
                    set=function(v)
                        cset("crosshairHpalMelee", v)
                        if AuraUI._RefreshCrosshairCutoffRange then AuraUI._RefreshCrosshairCutoffRange() end
                        applyCH()
                    end,
                }
            end

            AuraUI.BuildInlineCog(leftRgn, {
                title = "Crosshair Options",
                rows = chCogRows,
                gap = 9, disabled = chCogOff, disabledTooltip = "Character Crosshair",
            })
        end

        -- Color Out of Range (toggle + inline color picker)
        local meleeRow
        meleeRow, h = W:DualRow(parent, y,
            { type="toggle", text="Color Out of Range",
              tooltip=function()
                  local s = AuraUI.L("Changes the crosshair color when your current target is out of range.")
                  if AuraUI._getCrosshairCutoffRange then
                      local range = AuraUI._getCrosshairCutoffRange()
                      s = s .. " " .. AuraUI.Lf("Currently active range cutoff: %1$syd.", range)
                  end
                  return s
              end,
              disabled=function() return crosshairOff() end,
              disabledTooltip="Enable the crosshair to use this option.", rawTooltip=true,
              getValue=function() return cget("crosshairMeleeColorEnabled") == true end,
              setValue=function(v)
                cset("crosshairMeleeColorEnabled", v)
                if AuraUI._applyCrosshair then AuraUI._applyCrosshair() end
                AuraUI:RefreshPage()
              end },
            { type="label", text="" }
        );  y = y - h
        -- Inline color swatch (disabled when toggle is off or crosshair is None)
        if not AuraUI._prebuilding then
            local leftRgn = meleeRow._leftRegion
            local function meleeOff()
                return crosshairOff() or cget("crosshairMeleeColorEnabled") ~= true
            end
            local mcGet = function()
                local c = cget("crosshairMeleeColor")
                if c then return c.r, c.g, c.b, c.a end
                return 1, 0, 0, 1
            end
            local mcSet = function(r, g, b, a)
                cset("crosshairMeleeColor", { r = r, g = g, b = b, a = a or 1 })
                if AuraUI._applyCrosshair then AuraUI._applyCrosshair() end
            end
            local mcSwatch, mcUpdate = AuraUI.BuildColorSwatch(leftRgn, leftRgn:GetFrameLevel() + 5, mcGet, mcSet, true, 20)
            PP.Point(mcSwatch, "RIGHT", leftRgn._control, "LEFT", -12, 0)
            leftRgn._lastInline = mcSwatch

            local mcBlock = CreateFrame("Frame", nil, mcSwatch)
            mcBlock:SetAllPoints()
            mcBlock:SetFrameLevel(mcSwatch:GetFrameLevel() + 10)
            mcBlock:EnableMouse(true)
            mcBlock:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(mcSwatch, AuraUI.DisabledTooltip("Color Out of Range"))
            end)
            mcBlock:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            AuraUI.RegisterWidgetRefresh(function()
                local off = meleeOff()
                mcSwatch:SetAlpha(off and 0.3 or 1)
                if off then mcBlock:Show() else mcBlock:Hide() end
                mcUpdate()
            end)
            local mcInitOff = meleeOff()
            mcSwatch:SetAlpha(mcInitOff and 0.3 or 1)
            if mcInitOff then mcBlock:Show() else mcBlock:Hide() end
        end

        _, h = W:Spacer(parent, y, 20);  y = y - h

        ---------------------------------------------------------------------------
        --  GROUP FINDER
        ---------------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "GROUP FINDER", y);  y = y - h

        -- Auto Insert Keystone | Announce Instance Reset, then Quick Signup |
        -- Persistent Signup Note. WoW Forever has no keystones and no premade
        -- group list, so only Announce Instance Reset is built there.
        local autoKeyCfg = { type="toggle", text="Auto Insert Keystone",
              tooltip="Automatically inserts your key into the Font of Power.",
              getValue=function()
                  if not AuraUIDB then return true end
                  return AuraUIDB.autoInsertKeystone ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoInsertKeystone = v
              end }
        local announceCfg = { type="toggle", text="Announce Instance Reset",
              tooltip="After a successful instance reset, automatically announces it in party or raid chat so your group knows they can re-enter.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.instanceResetAnnounce or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.instanceResetAnnounce = v
                  if AuraUI._applyInstanceResetAnnounce then
                      AuraUI._applyInstanceResetAnnounce()
                  end
              end }
        local quickCfg = { type="toggle", text="Quick Signup",
              tooltip="Double-click a group listing to instantly sign up without pressing the Sign Up button. Hold Shift to keep the dialog open, e.g. to type a signup note.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.quickSignup or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.quickSignup = v
                  if AuraUI._applyQuickSignup then
                      AuraUI._applyQuickSignup()
                  end
              end }
        local persistCfg = { type="toggle", text="Persistent Signup Note",
              tooltip="Keeps a saved signup note you can copy into the Sign Up dialog with the Copy button.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.persistSignupNote or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.persistSignupNote = v
                  if AuraUI._applyPersistSignupNote then
                      AuraUI._applyPersistSignupNote()
                  end
                  AuraUI:RefreshPage()
              end }
        local noteRow
        if AuraUI.IS_FOREVER then
            _, h = W:DualRow(parent, y, announceCfg, AuraUI.BlankRowCfg());  y = y - h
        else
            _, h = W:DualRow(parent, y, autoKeyCfg, announceCfg);  y = y - h
            noteRow, h = W:DualRow(parent, y, quickCfg, persistCfg);  y = y - h
        end

        if noteRow and not AuraUI._prebuilding then
            local rightRgn = noteRow._rightRegion
            local function persistOff()
                return not (AuraUIDB and AuraUIDB.persistSignupNote)
            end

            AuraUI.BuildInlineCog(rightRgn, {
                gap = 9, tip = "Edit the saved signup note.",
                disabled = persistOff, disabledTooltip = "Persistent Signup Note",
                show = function()
                    AuraUI:ShowInputPopup({
                        title="Signup Note",
                        message="Saved between reloads and relogs. In Group Finder, choose Copy, press Ctrl+C, then Ctrl+V.",
                        placeholder="Enter signup note...",
                        initialText=AuraUI.GetPersistentSignupNote
                            and AuraUI.GetPersistentSignupNote() or "",
                        maxLetters=63,
                        inputHeight=70,
                        multiline=true,
                        showCount=true,
                        allowEmpty=true,
                        confirmText="Save",
                        onConfirm=function(note)
                            if AuraUI.SetPersistentSignupNote then
                                AuraUI.SetPersistentSignupNote(note or "")
                            end
                        end,
                    })
                end,
            })
        end

        _, h = W:Spacer(parent, y, 20);  y = y - h

        ---------------------------------------------------------------------------
        --  UI
        ---------------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "UI", y);  y = y - h

        _, h = W:DualRow(parent, y,
            { type="toggle", text="Hide Screenshot Status",
              tooltip="Hides the 'Screenshot saved' notification that appears on screen after taking a screenshot.",
              getValue=function()
                  if not AuraUIDB then return true end
                  return AuraUIDB.hideScreenshotStatus ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.hideScreenshotStatus = v
                  if AuraUI._applyScreenshotStatus then
                      AuraUI._applyScreenshotStatus()
                  end
              end },
            { type="toggle", text="Train All Button",
              tooltip="Adds a 'Train All' button next to the Train button at profession trainers, allowing you to learn all available skills with one click.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.trainAllButton or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.trainAllButton = v
                  if AuraUI._applyTrainAllButton then
                      AuraUI._applyTrainAllButton()
                  end
              end }
        );  y = y - h

        -- Auto Unwrap Collections | Auto Open Containers
        local autoOpenContainerRow
        autoOpenContainerRow, h = W:DualRow(parent, y,
            { type="toggle", text="Auto Unwrap Collections",
              tooltip="Automatically dismisses the 'new mount/pet/toy' fanfare notification when you receive one, so you don't have to click through the collections journal.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.autoUnwrapCollections or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoUnwrapCollections = v
                  if AuraUI._applyAutoUnwrap then
                      AuraUI._applyAutoUnwrap()
                  end
              end },
            { type="toggle", text="Auto Open Containers",
              tooltip="Automatically opens bags, boxes and parcels in your inventory when they are added to your bags.\n\nContainers received from the mailbox are held until you close the mailbox, so opening them cannot collide with mail still delivering items.",
              getValue=function()
                  if not AuraUIDB then return false end
                  return AuraUIDB.autoOpenContainers == true
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.autoOpenContainers = v
                  if AuraUI._applyAutoOpenContainers then
                      AuraUI._applyAutoOpenContainers()
                  end
                  AuraUI:RefreshPage()
              end }
        );  y = y - h

        -- Cog on Auto Open Containers (right region)
        if not AuraUI._prebuilding then
            local rightRgn = autoOpenContainerRow._rightRegion
            local function autoOpenContainerOff()
                return not (AuraUIDB and AuraUIDB.autoOpenContainers == true)
            end

            AuraUI.BuildInlineCog(rightRgn, {
                title = "Auto Open Containers Settings",
                rows = {
                    { type="toggle", label="Exclude Warbound Containers",
                      get=function()
                          if not AuraUIDB then return true end
                          return AuraUIDB.autoOpenContainersExcludeWarbound ~= false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.autoOpenContainersExcludeWarbound = v
                      end },
                    { type="toggle", label="Hold Capped Artisan Payouts",
                      tooltip="Keeps Artisan's Consortium Payouts closed while Shard of Dundun is at its maximum, then resumes automatic opening after you spend shards.",
                      get=function()
                          return AuraUIDB
                              and AuraUIDB.autoOpenContainersHoldCappedArtisanPayouts == true
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.autoOpenContainersHoldCappedArtisanPayouts = v
                          if AuraUI._applyAutoOpenContainers then
                              AuraUI._applyAutoOpenContainers()
                          end
                      end },
                },
                gap = 9, disabled = autoOpenContainerOff, disabledTooltip = "Auto Open Containers",
            })
        end

        -- Keys, Logs & Brez sections live at the bottom of this page (the
        -- separate tab was retired to keep the tab bar at five pages).
        if _G._AUI_BuildAutoLoggingPage then
            _, h = W:Spacer(parent, y, 16);  y = y - h
            local alH = _G._AUI_BuildAutoLoggingPage(pageName, parent, y)
            if alH then y = y - alH end
        end

        return math.abs(y)
    end

    local pages = { PAGE_QOL, PAGE_RAIDTOOLS, PAGE_CURSOR, PAGE_SHIFTER, PAGE_MOVEMENT }
    -- No item upgrade system on WoW Forever: the Upgrader tab is not offered there
    -- (its resident file returns at load, so the page builder never exists either).
    if not AuraUI.IS_FOREVER then pages[#pages + 1] = PAGE_UPGCALC end
    AuraUI:RegisterModule("AuraUIQoL", {
        title       = "Quality of Life",
        description = "Quality of life features and custom cursor.",
        pages       = pages,
        searchTerms = { "brez", "bres", "battle res", "combat res", "cursor", "macro", "fps", "logging", "combat log", "warcraft logs", "upgrade", "ilvl", "item level", "crest", "upgrade calculator", "shifter", "move", "drag", "position", "demodal", "drift", "combat alert", "enter combat", "leave combat", "in combat", "combat text", "combat notification", "transform", "transforms", "costume", "disguise", "chef's hat", "noggenfogger", "target distance", "distance to target", "range text", "yard", "yards", "movement", "mobility", "gap closer", "blink", "gateway", "warlock gateway", "control shard", "time spiral", "free movement", "raid tools", "raid", "pull timer", "pull", "ready check", "role check", "raid marker", "target marker", "world marker", "flare", "disband", "convert to raid", "countdown" },
        buildPage   = function(pageName, parent, yOffset)
            -- The Raid Tools settings preview ends when any OTHER QoL page
            -- builds (the CDM tracking-bars placeholder arrangement); window
            -- close and module switches are handled in the Raid Tools options
            -- file. Global Search's hidden pre-build never touches it.
            if pageName ~= PAGE_RAIDTOOLS and not AuraUI._prebuilding
               and _G._AUI_RaidTools_Preview then
                _G._AUI_RaidTools_Preview(false)
            end
            if pageName == PAGE_QOL then
                return BuildQoLPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_CURSOR and _G._EBS_BuildCursorPage then
                return _G._EBS_BuildCursorPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_UPGCALC and _G._AUI_BuildUpgradeCalcPage then
                return _G._AUI_BuildUpgradeCalcPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_SHIFTER and _G._AUI_BuildShifterPage then
                return _G._AUI_BuildShifterPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_MOVEMENT and _G._AUI_BuildMovementAlertPage then
                return _G._AUI_BuildMovementAlertPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_RAIDTOOLS and _G._AUI_BuildRaidToolsPage then
                return _G._AUI_BuildRaidToolsPage(pageName, parent, yOffset)
            end
        end,
        -- Cached pages are restored WITHOUT a rebuild, so buildPage never runs
        -- on the warm path -- reopening the window onto Raid Tools would leave
        -- its settings preview off without this (the CDM tracking-bars
        -- arrangement: mirror the flag on BOTH paths).
        onPageCacheRestore = function(pageName)
            if AuraUI._prebuilding then return end
            if _G._AUI_RaidTools_Preview then
                _G._AUI_RaidTools_Preview(pageName == PAGE_RAIDTOOLS)
            end
        end,
        onReset = function()
            if AuraUIDB then
                AuraUIDB.hideBlizzardPartyFrame = false
                AuraUIDB.quickLoot = false
                AuraUIDB.skipCinematics = false
                AuraUIDB.skipCinematicsAuto = false
                AuraUIDB.autoFillDelete = false
                AuraUIDB.autoSelectSingleGossip = nil
                AuraUIDB.autoInsertKeystone = false
                AuraUIDB.instanceResetAnnounce = false
                AuraUIDB.instanceResetAnnounceMsg = ""
                AuraUIDB.quickSignup = false
                AuraUIDB.persistSignupNote = false
                AuraUIDB.signupNote = nil
                AuraUIDB.ahCurrentExpansion = false
                AuraUIDB.hideScreenshotStatus = false
                AuraUIDB.trainAllButton = false
                AuraUIDB.autoUnwrapCollections = false
                AuraUIDB.autoOpenContainers = false
                AuraUIDB.autoOpenContainersExcludeWarbound = true
                AuraUIDB.autoOpenContainersHoldCappedArtisanPayouts = false
                AuraUIDB.autoRepairGuild = false
                AuraUIDB.shifterEnabled = false
                AuraUIDB.shifterPositions = nil
                AuraUIDB.hideErrorMessages = false
                AuraUIDB.hideLootHistory = false
                AuraUIDB.lootHistoryMode = nil
                AuraUIDB.lootHistoryDelay = nil
                if AuraUI._applyHideLootHistory then AuraUI._applyHideLootHistory() end
                AuraUIDB.announceGroupDeaths = false
                AuraUIDB.groupDeathTextSize = nil
                AuraUIDB.groupDeathAlertPos = nil
                AuraUIDB.groupDeathSound = nil      -- legacy boolean (pre-dropdown)
                AuraUIDB.groupDeathSoundKey = nil
                AuraUIDB.combatAlertEnabled = false
                AuraUIDB.combatAlertMode = nil
                AuraUIDB.combatAlertTextSize = nil
                AuraUIDB.combatAlertPos = nil
                AuraUIDB.combatAlertEnterText = nil
                AuraUIDB.combatAlertLeaveText = nil
                AuraUIDB.combatAlertEnterColor = nil
                AuraUIDB.combatAlertLeaveColor = nil
                AuraUIDB.combatAlertEnterUseClassColor = nil
                AuraUIDB.combatAlertLeaveUseClassColor = nil
                AuraUIDB.targetDistanceEnabled = false
                AuraUIDB.targetDistanceFormat = nil
                AuraUIDB.targetDistanceAlign = nil
                AuraUIDB.targetDistanceAttach = nil
                AuraUIDB.targetDistanceOffsetX = nil
                AuraUIDB.targetDistanceOffsetY = nil
                AuraUIDB.targetDistanceTextSize = nil
                AuraUIDB.targetDistancePos = nil
                if AuraUIDB.unlockAnchors then
                    AuraUIDB.unlockAnchors.AUI_TargetDistance = nil
                end
                AuraUIDB.hideTransforms = false
                AuraUIDB.hideTransformItems = nil
            end
            AuraUIDB.autoLogging = nil
            if _G._AUI_ResetUpgradeCalc then _G._AUI_ResetUpgradeCalc() end
            if _G._EBS_ResetCursor then _G._EBS_ResetCursor() end
            AuraUI._applyHideBlizzardPartyFrame()
            if AuraUI._applyHideErrorMessages then AuraUI._applyHideErrorMessages() end
            if AuraUI._applyAnnounceGroupDeaths then AuraUI._applyAnnounceGroupDeaths() end
            if AuraUI._applyCombatAlert then AuraUI._applyCombatAlert() end
            if AuraUI._applyTargetDistance then AuraUI._applyTargetDistance() end
            if AuraUI._applyHideTransforms then AuraUI._applyHideTransforms() end
            if AuraUI._applyQuickSignup then AuraUI._applyQuickSignup() end
            if AuraUI._applyPersistSignupNote then AuraUI._applyPersistSignupNote() end
            if AuraUI._applyQuickLoot then AuraUI._applyQuickLoot() end
            if AuraUI._applyInstanceResetAnnounce then AuraUI._applyInstanceResetAnnounce() end
            if AuraUI._applyAutoOpenContainers then AuraUI._applyAutoOpenContainers() end
            if AuraUI._ShutdownShifter then AuraUI._ShutdownShifter() end
            if _G._AUI_AutoLogging_Check then _G._AUI_AutoLogging_Check() end
            AuraUI:InvalidatePageCache()
        end,
        -- Tears down Duration Warning, Raid Tools, and Movement Alert
        -- previews on module switch (Movement Alert also stops its ticker).
        onModuleLeave = function()
            if AuraUI._durWarnHidePreview then AuraUI._durWarnHidePreview() end
            if _G._AUI_RaidTools_Preview then _G._AUI_RaidTools_Preview(false) end
            if AuraUI._MovementAlertPreview then AuraUI._MovementAlertPreview(false) end
        end,
    })

    SLASH_EQOL1 = "/qol"
    SlashCmdList.EQOL = function()
        if InCombatLockdown and InCombatLockdown() then return end
        AuraUI:ShowModule("AuraUIQoL")
    end
end)
-- LoadOnDemand: this addon loads after PLAYER_LOGIN, so the event above will never fire; run the init now.
if IsLoggedIn() then initFrame:GetScript("OnEvent")(initFrame) end
