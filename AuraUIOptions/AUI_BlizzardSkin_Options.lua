if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AUI_BlizzardSkin_Options.lua
-------------------------------------------------------------------------------
local ns = AuraUI._ModuleNS["AuraUIBlizzardSkin"]  -- module namespace (published by the module at its load)
if not ns then return end  -- module disabled: no options page
local PAGE_WINDOWSKINS   = "Blizzard Window Skins"
local PAGE_TOOLTIPS      = "Tooltips, Menus & Popups"
local PAGE_DRAGONRIDING  = "Dragon Riding"

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    if not AuraUI or not AuraUI.RegisterModule then return end

    local function BuildTooltipsPage(pageName, parent, yOffset)
        if not AuraUIDB then AuraUIDB = {} end
        local W = AuraUI.Widgets
        local y = yOffset
        local _, h
        -- The step the skin renders with (_applyConfiguredBorder in AuraUIBlizzardSkin.lua):
        -- the stored label (an unknown one = thin); unset = the legacy numeric tooltipBorderSize for the tooltip, 1 otherwise.
        local function BorderStep(prefix)
            local key = AuraUIDB[prefix.."BorderThickness"]
            if key then return AuraUI.BORDER_STEP_OF_LABEL[key] or 1 end
            if prefix == "tooltip" then return AuraUIDB.tooltipBorderSize or 1 end
            return 1
        end
        -- Border Size in pixels over <prefix>BorderThickness (still a label) and its <prefix>BorderThicknessPx companion.
        local function BorderSizeSlider(prefix, text, disabledFn, apply)
            return AuraUI.BorderPxSliderCfg{
                text = text, disabled = disabledFn,
                getStep = function() return BorderStep(prefix) end,
                setStep = function(step) AuraUIDB[prefix.."BorderThickness"] = AuraUI.BORDER_LABEL_OF_STEP[step] or "thin" end,
                getTex = function() return AuraUIDB[prefix.."BorderTexture"] or "solid" end,
                getPx = function() return AuraUIDB[prefix.."BorderThicknessPx"] end,
                setPx = function(v) AuraUIDB[prefix.."BorderThicknessPx"] = v end,
                apply = apply,
            }
        end
        -- The registry sizeKey the skin passes beside the addonKey "blizzardSkin" (registered
        -- nowhere, so an UNSET offset resolves to 0/0, never to the global per-texture defaults).
        local function BorderSizeKey(prefix)
            return AuraUIDB[prefix.."BorderThickness"] or AuraUI.BORDER_LABEL_OF_STEP[BorderStep(prefix)] or "thin"
        end
        -- Width Offset | Height Offset right below a Border Style row, only while its style is
        -- textured (a solid border has no offsets). Built in every pass so the y advance never differs.
        local function BorderOffsetRow(prefix, disabledFn)
            local tex = AuraUIDB[prefix.."BorderTexture"] or "solid"
            if tex == "" or tex == "solid" then return end
            local ocfgL, ocfgR = AuraUI.BorderOffsetRowCfgs{
                addonKey = "blizzardSkin", disabled = disabledFn,
                getTex = function() return AuraUIDB[prefix.."BorderTexture"] or "solid" end,
                getStep = function() return BorderStep(prefix) end,
                getSizeKey = function() return BorderSizeKey(prefix) end,
                getPx = function() return AuraUIDB[prefix.."BorderThicknessPx"] end,
                getX = function() return AuraUIDB[prefix.."BorderOffsetX"] end,
                setX = function(v) AuraUIDB[prefix.."BorderOffsetX"] = v end,
                getY = function() return AuraUIDB[prefix.."BorderOffsetY"] end,
                setY = function(v) AuraUIDB[prefix.."BorderOffsetY"] = v end,
            }
            _, h = W:DualRow(parent, y, ocfgL, ocfgR); y = y - h
        end

        local function AttachBorderControls(row, prefix, disabledFn, allowBehind)
            local PP = AuraUI.PanelPP
            if not AuraUI._prebuilding then
            local left, right = row._leftRegion, row._rightRegion
            -- The offsets live in their own row below the style row (BorderOffsetRow); the cog
            -- keeps only Show Behind, so a surface without that option gets no cog at all.
            if allowBehind then
            local popupRows = {
                { type="toggle", label="Show Behind",
                  get=function() return AuraUIDB[prefix.."BorderBehind"] or false end,
                  set=function(v) AuraUIDB[prefix.."BorderBehind"]=v end },
            }
            AuraUI.BuildInlineCog(left, {
                title = "Border Options", rows = popupRows,
                icon = AuraUI.DIRECTIONS_ICON, anchorTo = left._control,
                disabled = disabledFn,
                disabledTooltip = prefix == "tooltip" and "Reskin Tooltip" or "Reskin Popups and Menus",
            })
            end

            local function AddModeSwatch(anchor, mode, tip, getColor, custom)
                local sw, refresh=AuraUI.BuildColorSwatch(right,right:GetFrameLevel()+5,getColor,
                    function(r,g,b,a) AuraUIDB[prefix.."BorderColor"]={r=r,g=g,b=b}; AuraUIDB[prefix.."BorderOpacity"]=a; AuraUIDB[prefix.."BorderColorMode"]="custom" end,
                    custom,20)
                PP.Point(sw,"RIGHT",anchor,"LEFT",-8,0)
                local orig=sw:GetScript("OnClick")
                sw:SetScript("OnClick",function(self)
                    if mode~="custom" or (AuraUIDB[prefix.."BorderColorMode"] or "custom")~="custom" then
                        AuraUIDB[prefix.."BorderColorMode"]=mode; AuraUI:RefreshPage(); return
                    end
                    orig(self)
                end)
                sw:HookScript("OnEnter",function(self) AuraUI.ShowWidgetTooltip(self,tip) end)
                sw:HookScript("OnLeave",function() AuraUI.HideWidgetTooltip() end)
                -- Applied once at build time too -- widget refresh only fires
                -- on later changes, so without this every swatch opened lit.
                local function UpdSwatchState()
                    local off=disabledFn and disabledFn(); local active=(AuraUIDB[prefix.."BorderColorMode"] or "custom")==mode
                    sw:SetAlpha(off and .15 or (active and 1 or .3)); sw:EnableMouse(not off); refresh()
                end
                AuraUI.RegisterWidgetRefresh(UpdSwatchState)
                UpdSwatchState()
                return sw
            end
            local accent=AddModeSwatch(right._control,"accent","Accent Color",function() local c=AuraUI.ELLESMERE_GREEN; return c.r,c.g,c.b,1 end,false)
            local class=AddModeSwatch(accent,"class","Class Color",function() local _,k=UnitClass("player"); local c=RAID_CLASS_COLORS[k]; return c.r,c.g,c.b,1 end,false)
            local custom=AddModeSwatch(class,"custom","Custom Color",function() local c=AuraUIDB[prefix.."BorderColor"] or {r=1,g=1,b=1}; return c.r,c.g,c.b,AuraUIDB[prefix.."BorderOpacity"] or AuraUI.RESKIN.BRD_ALPHA end,true)
            right._lastInline=custom
            end
        end

        if AuraUI.ClearContentHeader then AuraUI:ClearContentHeader() end
        parent._showRowDivider = true

        _, h = W:Spacer(parent, y, 20);  y = y - h

        _, h = W:SectionHeader(parent, "BLIZZARD POPUPS & GAME MENU", y);  y = y - h

        _, h = W:DualRow(parent, y,
            { type="toggle", text="Reskin Popups and Menus",
              tooltip="Reskins Blizzard's right-click context menus and pop-up dialogs with the AUI dark style. Requires reload to apply.",
              getValue=function()
                  -- Seeded from the old master by the blizzskin_reskin_master_split_v1
                  -- migration; independent thereafter. Default on.
                  return not AuraUIDB or AuraUIDB.reskinPopupsMenus ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.reskinPopupsMenus = v
                  AuraUI:RefreshPage()  -- update the border cog + swatch disabled states
                  AuraUI:ShowConfirmPopup({
                      title       = "Reload Required",
                      message     = "Reskin setting requires a UI reload to fully apply.",
                      confirmText = "Reload Now",
                      cancelText  = "Later",
                      reload      = true,
                  })
              end },
            { type="toggle", text="Resurrect Accept Glow",
              tooltip="Adds a glowing, pulsating border around the Accept button of resurrection popups so a pending resurrect is hard to miss. Follows the Element & Text Color setting. Applies instantly, no reload needed.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.resurrectAcceptGlow or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.resurrectAcceptGlow = v
                  if AuraUI._EnsureResurrectGlow then AuraUI._EnsureResurrectGlow() end
              end }
        );  y = y - h

        local function popupOff() return AuraUIDB.reskinPopupsMenus == false end
        do
            local texValues,texOrder=AuraUI.GetBorderTextureDropdown()
            local outer
            outer,h=W:DualRow(parent,y,
                {type="dropdown",text="Border Style",disabled=popupOff,values=texValues,order=texOrder,getValue=function() return AuraUIDB.popupMenuBorderTexture or "solid" end,setValue=function(v) local c,b=AuraUI.GetBorderStyleSelectDefaults(v); AuraUIDB.popupMenuBorderTexture=v; AuraUIDB.popupMenuBorderOffsetX=nil; AuraUIDB.popupMenuBorderOffsetY=nil; AuraUIDB.popupMenuBorderBehind=b; AuraUIDB.popupMenuBorderColor=c; if AuraUIDB.popupMenuBorderThicknessPx then AuraUIDB.popupMenuBorderThicknessPx=false end; AuraUI:RefreshPage(true) end},
                BorderSizeSlider("popupMenu","Border Size",popupOff)); y=y-h
            AttachBorderControls(outer,"popupMenu",popupOff,true)
            BorderOffsetRow("popupMenu",popupOff)
            local buttons
            buttons,h=W:DualRow(parent,y,
                {type="dropdown",text="Button Border Style",disabled=popupOff,values=texValues,order=texOrder,getValue=function() return AuraUIDB.popupMenuButtonBorderTexture or "solid" end,setValue=function(v) AuraUIDB.popupMenuButtonBorderTexture=v; local sc=AuraUI.GetBorderSelectColor(v); if sc then AuraUIDB.popupMenuButtonBorderColor=sc end; AuraUIDB.popupMenuButtonBorderOffsetX=nil; AuraUIDB.popupMenuButtonBorderOffsetY=nil; if AuraUIDB.popupMenuButtonBorderThicknessPx then AuraUIDB.popupMenuButtonBorderThicknessPx=false end; AuraUI:RefreshPage(true) end},
                BorderSizeSlider("popupMenuButton","Button Border Size",popupOff)); y=y-h
            AttachBorderControls(buttons,"popupMenuButton",popupOff)
            BorderOffsetRow("popupMenuButton",popupOff)
        end

        _,h=W:DualRow(parent,y,
            {type="colorpicker",text="Button Background",hasAlpha=true,disabled=popupOff,getValue=function() local c=AuraUIDB.popupMenuButtonBackgroundColor or {r=.1,g=.1,b=.1,a=.8}; return c.r,c.g,c.b,c.a end,setValue=function(r,g,b,a) AuraUIDB.popupMenuButtonBackgroundColor={r=r,g=g,b=b,a=a} end},
            {type="multiSwatch",text="Element & Text Color",disabled=popupOff,swatches={
                -- Effective mode comes from the skin file's resolver: unset =
                -- native unless the legacy Accent Colored Elements opt-in is present.
                -- All four highlights read it so the default state is shown truthfully.
                {tooltip="Native Colors",hasAlpha=false,getValue=function() return 1,1,1 end,setValue=function() end,onClick=function() AuraUIDB.popupMenuButtonTextColorMode="native"; AuraUI:RefreshPage() end,refreshAlpha=function() local m=AuraUI._getPopupMenuElementMode and AuraUI._getPopupMenuElementMode() or "native"; return m=="native" and 1 or .3 end},
                {tooltip="Accent Color",hasAlpha=false,getValue=function() local c=AuraUI.ELLESMERE_GREEN; return c.r,c.g,c.b end,setValue=function() end,onClick=function() AuraUIDB.popupMenuButtonTextColorMode="accent"; AuraUI:RefreshPage() end,refreshAlpha=function() local m=AuraUI._getPopupMenuElementMode and AuraUI._getPopupMenuElementMode() or "native"; return m=="accent" and 1 or .3 end},
                {tooltip="Custom Color",hasAlpha=false,getValue=function() local c=AuraUIDB.popupMenuButtonTextColor or {r=1,g=1,b=1}; return c.r,c.g,c.b end,setValue=function(r,g,b) AuraUIDB.popupMenuButtonTextColorMode="custom"; AuraUIDB.popupMenuButtonTextColor={r=r,g=g,b=b} end,onClick=function(self) local m=AuraUI._getPopupMenuElementMode and AuraUI._getPopupMenuElementMode() or "native"; if m~="custom" then AuraUIDB.popupMenuButtonTextColorMode="custom"; AuraUI:RefreshPage(); return end self._eabOrigClick(self) end,refreshAlpha=function() local m=AuraUI._getPopupMenuElementMode and AuraUI._getPopupMenuElementMode() or "native"; return m=="custom" and 1 or .3 end},
                {tooltip="Class Color",hasAlpha=false,getValue=function() local _,k=UnitClass("player"); local c=RAID_CLASS_COLORS[k]; return c.r,c.g,c.b end,setValue=function() end,onClick=function() AuraUIDB.popupMenuButtonTextColorMode="class"; AuraUI:RefreshPage() end,refreshAlpha=function() local m=AuraUI._getPopupMenuElementMode and AuraUI._getPopupMenuElementMode() or "native"; return m=="class" and 1 or .3 end},
            }}); y=y-h

        local queueRow
        queueRow, h = W:DualRow(parent, y,
            { type="slider", text="Font Size Scale",
              tooltip="Scales the font size of reskinned Blizzard tooltips, menus, and popups.",
              min=0.7, max=1.5, step=0.05, format="%.0f%%",
              displayMul=100,
              getValue=function()
                  return AuraUIDB and AuraUIDB.tooltipFontScale or 1.0
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.tooltipFontScale = v
              end },
            { type="toggle", text="Reskin Queue Popup",
              tooltip="Reskins the dungeon and battleground queue accept popups with the AUI dark style, and adds an accept countdown timer bar to the dungeon one.",
              getValue=function()
                  -- Independent, default on (not tied to any master reskin toggle).
                  return not AuraUIDB or AuraUIDB.reskinQueuePopup ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.reskinQueuePopup = v
                  if not v and AuraUI.ShowConfirmPopup then
                      AuraUI:ShowConfirmPopup({
                          title       = "Reload Required",
                          message     = "Disabling queue popup reskin requires a UI reload to restore Blizzard's default style.",
                          confirmText = "Reload Now",
                          cancelText  = "Later",
                          reload      = true,
                      })
                  end
              end }
        );  y = y - h

        -- Red "!" warning left of the Reskin Queue Popup toggle when EnhanceQoL is loaded
        local _eqolLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EnhanceQoL")
        if _eqolLoaded and queueRow and queueRow._rightRegion and not AuraUI._prebuilding then
            local rgn = queueRow._rightRegion
            local toggle = rgn._control
            if toggle then
                local fontPath = (AuraUI.GetFontPath()) or "Fonts\\FRIZQT__.TTF"
                local warnBtn = CreateFrame("Button", nil, rgn)
                warnBtn:SetSize(28, 28)
                warnBtn:SetPoint("RIGHT", toggle, "LEFT", -4, 0)
                warnBtn:SetFrameLevel(rgn:GetFrameLevel() + 5)
                local warnFS = warnBtn:CreateFontString(nil, "OVERLAY")
                warnFS:SetFont(fontPath, 28, "")
                warnFS:SetTextColor(1, 0.3, 0.3, 1)
                warnFS:SetText("!")
                warnFS:SetPoint("CENTER")
                warnBtn:SetScript("OnEnter", function(self)
                    AuraUI.ShowWidgetTooltip(self, "Enhance QoL's Mover may conflict with this reskin. The reskin is auto-disabled when its mover is active.")
                end)
                warnBtn:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            end
        end

        local queueTimerRow
        queueTimerRow, h = W:DualRow(parent, y,
            { type="toggle", text="Show Queue Timer",
              tooltip="Shows a countdown bar below the queue accept popup indicating how long you have to accept. Works with or without the reskin. Use the swatch and cog to set the countdown text color, text size, bar height and text offset.",
              getValue=function()
                  return not AuraUIDB or AuraUIDB.showQueueTimer ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showQueueTimer = v
                  AuraUI:RefreshPage()  -- update the style cog + swatch disabled states
              end },
            { type="toggle", text="Enable Blizzard Pause Menu",
              tooltip="Reskins the ESC / Game Menu with the AUI dark style, matching fonts, and accent-colored title.",
              getValue=function()
                  -- Independent, default on (not tied to any master reskin toggle).
                  return not AuraUIDB or AuraUIDB.reskinGameMenu ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.reskinGameMenu = v
                  AuraUI:ShowConfirmPopup({
                      title       = "Reload Required",
                      message     = "Changing the pause menu reskin requires a UI reload.",
                      confirmText = "Reload Now",
                      cancelText  = "Later",
                      reload      = true,
                  })
              end }
        );  y = y - h

        -- Countdown text color + style cog on the Show Queue Timer toggle.
        if not AuraUI._prebuilding then
            local PP = AuraUI.PanelPP
            local QT = AuraUI.QUEUE_TIMER
            local leftRgn = queueTimerRow._leftRegion
            local function timerOff()
                return AuraUIDB and AuraUIDB.showQueueTimer == false
            end
            local function Get(key, default)
                return (AuraUIDB and AuraUIDB[key]) or default
            end
            local function Set(key, v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB[key] = v
                if AuraUI.RefreshQueueTimerStyle then AuraUI.RefreshQueueTimerStyle() end
            end

            local qtCog = AuraUI.BuildInlineCog(leftRgn, {
                gap = 9,
                disabled = timerOff,
                disabledTooltip = "Show Queue Timer",
                title = "Queue Timer Style",
                rows = {
                    { type="slider", label="Text Size", min=6, max=24, step=1,
                      get=function() return Get("queueTimerTextSize", QT.TEXT_SIZE) end,
                      set=function(v) Set("queueTimerTextSize", v) end },
                    { type="slider", label="Bar Height", min=4, max=24, step=1,
                      get=function() return Get("queueTimerBarHeight", QT.BAR_HEIGHT) end,
                      set=function(v) Set("queueTimerBarHeight", v) end },
                    { type="slider", label="Text Offset Y", min=-20, max=20, step=1,
                      tooltip="Moves the countdown number up or down relative to the bar.",
                      get=function() return Get("queueTimerTextOffsetY", QT.TEXT_OFFSET_Y) end,
                      set=function(v) Set("queueTimerTextOffsetY", v) end },
                },
            })


            local qtSwatch, qtSwatchRefresh = AuraUI.BuildColorSwatch(leftRgn,
                leftRgn:GetFrameLevel() + 5,
                function()
                    local c = AuraUIDB and AuraUIDB.queueTimerTextColor
                    return (c and c.r) or QT.TEXT_R, (c and c.g) or QT.TEXT_G, (c and c.b) or QT.TEXT_B
                end,
                function(r, g, b) Set("queueTimerTextColor", { r = r, g = g, b = b }) end,
                false, 20)
            PP.Point(qtSwatch, "RIGHT", qtCog, "LEFT", -8, 0)
            leftRgn._lastInline = qtSwatch
            qtSwatch:HookScript("OnEnter", function(self)
                AuraUI.ShowWidgetTooltip(self, "Countdown Text Color")
            end)
            qtSwatch:HookScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

            -- Called at build time too: the refresh list only runs on page show.
            local function UpdQueueTimerState()
                local off = timerOff()
                qtSwatch:SetAlpha(off and 0.15 or 1); qtSwatch:EnableMouse(not off)
                qtSwatchRefresh()
            end
            AuraUI.RegisterWidgetRefresh(UpdQueueTimerState)
            UpdQueueTimerState()
        end

        _, h = W:Spacer(parent, y, 20);  y = y - h

        _, h = W:SectionHeader(parent, "BLIZZARD TOOLTIP", y);  y = y - h

        -- "Reskin Tooltip" (customTooltips) is the master for this section: its
        -- reskin-driven sub-settings gray out (and stop applying) when it is off.
        -- Per-line tooltip content settings (titles, item level, M+ score, detailed
        -- tooltips, health strip) live in the content cog on this toggle. Settings
        -- independent of the skin (Show Detailed Tooltips, Hide Unit Health Strip, Show
        -- Spell ID, Show Max Stack) stay editable with the reskin off.
        local function ttReskinOff()
            return AuraUIDB and AuraUIDB.customTooltips == false
        end

        local ttCursorRow
        ttCursorRow, h = W:DualRow(parent, y,
            { type="toggle", text="Reskin Tooltip",
              tooltip="Reskins Blizzard tooltips with a dark, minimal style matching the AUI aesthetic. Requires reload to apply.",
              getValue=function()
                  return not AuraUIDB or AuraUIDB.customTooltips ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.customTooltips = v
                  if AuraUI.SyncAuraTooltipSkin then AuraUI.SyncAuraTooltipSkin() end
                  AuraUI:RefreshPage()  -- gray/ungray the rest of the section now
                  AuraUI:ShowConfirmPopup({
                      title       = "Reload Required",
                      message     = "Reskin setting requires a UI reload to fully apply.",
                      confirmText = "Reload Now",
                      cancelText  = "Later",
                      reload      = true,
                  })
              end },
            { type="toggle", text="Anchor to Cursor",
              tooltip="Makes the game tooltip follow your mouse cursor instead of showing at its fixed screen position (drag the Tooltip box in Unlock Mode to change that). Use the arrows icon to pick the position relative to the cursor and fine-tune the X/Y offset.",
              disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
              getValue=function()
                  return AuraUIDB and AuraUIDB.tooltipAnchorCursor or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.tooltipAnchorCursor = v
                  if AuraUI._applyTooltipCursorAnchor then AuraUI._applyTooltipCursorAnchor() end
                  -- Re-park the fixed anchor (and seed it if this profile never
                  -- has) so turning the cursor mode off resumes cleanly.
                  if AuraUI._applyTooltipFixedAnchor then AuraUI._applyTooltipFixedAnchor() end
                  AuraUI:RefreshPage()  -- update the position cog + Growth Direction disabled states
              end }
        );  y = y - h

        -- Position control on Anchor to Cursor (right region): position + X/Y offset
        if not AuraUI._prebuilding then
            local rightRgn = ttCursorRow._rightRegion
            local function ttCursorOff()
                return not (AuraUIDB and AuraUIDB.tooltipAnchorCursor)
            end
            AuraUI.BuildInlineCog(rightRgn, {
                icon = AuraUI.DIRECTIONS_ICON, gap = 9,
                disabled = ttCursorOff,
                disabledTooltip = "Anchor to Cursor",
                title = "Cursor Tooltip Position",
                rows = {
                    { type="dropdown", label="Position",
                      values={ bottomright="Bottom Right", bottomleft="Bottom Left",
                               topright="Top Right", topleft="Top Left",
                               right="Right", left="Left", top="Top", bottom="Bottom",
                               center="Center" },
                      order={ "bottomright", "bottomleft", "topright", "topleft",
                              "right", "left", "top", "bottom", "center" },
                      get=function() return AuraUIDB and AuraUIDB.tooltipCursorPosition or "top" end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipCursorPosition = v
                      end },
                    { type="slider", label="Offset X", min=-100, max=100, step=1,
                      get=function() return (AuraUIDB and AuraUIDB.tooltipCursorOffsetX) or 0 end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipCursorOffsetX = v
                      end },
                    { type="slider", label="Offset Y", min=-100, max=100, step=1,
                      get=function() return (AuraUIDB and AuraUIDB.tooltipCursorOffsetY) or 0 end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipCursorOffsetY = v
                      end },
                },
            })
        end

        -- Content cog on Reskin Tooltip (left region): the per-line tooltip content
        -- settings. The cog itself stays active with the reskin off because Show
        -- Detailed Tooltips and Hide Unit Health Strip work with the default Blizzard
        -- tooltip too; the reskin-driven rows gray out individually inside the popup.
        if not AuraUI._prebuilding then
            local leftRgn = ttCursorRow._leftRegion
            AuraUI.BuildInlineCog(leftRgn, {
                gap = 9,
                title = "Tooltip Content",
                rows = {
                    { type="toggle", label="Show Player Titles",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return AuraUIDB and AuraUIDB.tooltipPlayerTitles or false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipPlayerTitles = v
                      end },
                    { type="toggle", label="Show Item Level",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return not AuraUIDB or AuraUIDB.tooltipItemLevel ~= false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipItemLevel = v
                      end },
                    { type="toggle", label="Show M+ Score",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return not AuraUIDB or AuraUIDB.tooltipMythicScore ~= false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipMythicScore = v
                      end },
                    { type="toggle", label="Show Mount",
                      tooltip="Adds the mount a player is riding to their tooltip, with a green check if you own it or a red X if you don't.",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return AuraUIDB and AuraUIDB.tooltipShowMount or false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipShowMount = v
                      end },
                    { type="toggle", label="Show Guild Rank",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return AuraUIDB and AuraUIDB.tooltipShowGuildRank or false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipShowGuildRank = v
                      end },
                    { type="toggle", label="Show Unit Target",
                      tooltip="Adds a Targeting line showing who the hovered player or NPC is targeting, in green when it's you.",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return AuraUIDB and AuraUIDB.tooltipShowTarget or false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipShowTarget = v
                      end },
                    -- CVar-backed; only enforced on login after the user has
                    -- toggled it once (uberTooltipsManual).
                    { type="toggle", label="Show Detailed Tooltips",
                      get=function()
                          return GetCVar("UberTooltips") == "1"
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.uberTooltipsManual = true
                          AuraUIDB.uberTooltips = v
                          SetCVar("UberTooltips", v and "1" or "0")
                      end },
                    { type="toggle", label="Hide Unit Health Strip",
                      get=function()
                          return not (AuraUIDB and AuraUIDB.tooltipHideHealthStrip == false)
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipHideHealthStrip = v
                          if AuraUI._applyTooltipHealthStrip then AuraUI._applyTooltipHealthStrip() end
                      end },
                    { type="toggle", label="Show Player Buffs",
                      tooltip="Shows player buffs as icons on the tooltip when hovering another player.",
                      disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
                      get=function()
                          return AuraUIDB and AuraUIDB.tooltipPlayerBuffs or false
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipPlayerBuffs = v
                      end },
                    { type="dropdown", label="Buffs Position",
                      disabled=function() return ttReskinOff() or not (AuraUIDB and AuraUIDB.tooltipPlayerBuffs) end,
                      disabledTooltip="Show Player Buffs",
                      values={ BOTTOM="Bottom", TOP="Top" },
                      order={ "BOTTOM", "TOP" },
                      get=function()
                          return (AuraUIDB and AuraUIDB.tooltipPlayerBuffsPosition) or "BOTTOM"
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipPlayerBuffsPosition = v
                      end },
                    { type="slider", label="Buff Icon Size", min=12, max=32, step=1,
                      disabled=function() return ttReskinOff() or not (AuraUIDB and AuraUIDB.tooltipPlayerBuffs) end,
                      disabledTooltip="Show Player Buffs",
                      get=function()
                          return (AuraUIDB and AuraUIDB.tooltipPlayerBuffsSize) or 18
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipPlayerBuffsSize = v
                      end },
                    { type="slider", label="Buffs Per Row", min=4, max=12, step=1,
                      disabled=function() return ttReskinOff() or not (AuraUIDB and AuraUIDB.tooltipPlayerBuffs) end,
                      disabledTooltip="Show Player Buffs",
                      get=function()
                          return (AuraUIDB and AuraUIDB.tooltipPlayerBuffsPerRow) or 6
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipPlayerBuffsPerRow = v
                      end },
                },
            })
        end

        -- Unified tooltip background: controls BOTH the Blizzard tooltip reskin
        -- and the AUI custom tooltips (read live via AuraUI.GetTooltipBg).
        -- Defaults to the RESKIN palette (#111111 @ 92%); the next tooltip shown
        -- picks up changes, so no reload is needed.
        _, h = W:DualRow(parent, y,
            { type="colorpicker", text="Background Color",
              tooltip="Background color for both Blizzard tooltips and AuraUI's own tooltips",
              disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
              getValue=function()
                  local c = AuraUIDB and AuraUIDB.tooltipBgColor
                  if c then return c.r, c.g, c.b end
                  local R = AuraUI.RESKIN
                  return R.BG_R, R.BG_G, R.BG_B
              end,
              setValue=function(r, g, b)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.tooltipBgColor = { r = r, g = g, b = b }
                  if AuraUI.SyncAuraTooltipSkin then AuraUI.SyncAuraTooltipSkin() end
              end },
            { type="slider", text="Background Opacity", min=0, max=100, step=1,
              disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
              getValue=function()
                  local a = (AuraUIDB and AuraUIDB.tooltipBgOpacity) or AuraUI.RESKIN.TT_ALPHA
                  return math.floor(a * 100 + 0.5)
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.tooltipBgOpacity = v / 100
                  if AuraUI.SyncAuraTooltipSkin then AuraUI.SyncAuraTooltipSkin() end
              end });  y = y - h

        local ttModeRow
        ttModeRow, h = W:DualRow(parent, y,
            { type="dropdown", text="Show Tooltips",
              tooltip="Controls when game tooltips appear",
              disabled=ttReskinOff, disabledTooltip="Reskin Tooltip",
              values={ always="Always", outOfCombat="Out of Combat", outOfBossCombat="Out of Boss Combat", never="Never" },
              order={ "always", "outOfCombat", "outOfBossCombat", "never" },
              getValue=function() return (AuraUIDB and AuraUIDB.tooltipShowMode) or "always" end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.tooltipShowMode = v
                  AuraUI:RefreshPage()  -- update the Use Modifier cog disabled state
              end },
            -- Front-end duplicate of the toggle in Global Settings > Developer;
            -- same AuraUIDB.showSpellID key read by the tooltip logic in
            -- AuraUI.lua (no separate backend). Independent of the reskin.
            { type="toggle", text="Show Spell ID on Tooltip",
              tooltip="Appends the spell or item ID to tooltips. The same setting as Global Settings > Developer.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.showSpellID or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showSpellID = v
                  if AuraUI.SyncAuraSpellIDCVar then AuraUI.SyncAuraSpellIDCVar() end
                  AuraUI:RefreshPage()  -- update the Use Modifier cog disabled state
              end }
        );  y = y - h

        -- "Use Modifier" cog on Show Spell ID (right region): the spell/item ID
        -- lines only show while the chosen modifier is held. Disabled (blocked +
        -- dimmed) when Show Spell ID is off, mirroring the cursor-position cog.
        if not AuraUI._prebuilding then
            local rightRgn = ttModeRow._rightRegion
            local function sidOff()
                return not (AuraUIDB and AuraUIDB.showSpellID)
            end
            AuraUI.BuildInlineCog(rightRgn, {
                gap = 9,
                disabled = sidOff,
                disabledTooltip = "Show Spell ID on Tooltip",
                title = "Spell ID",
                rows = {
                    { type="dropdown", label="Use Modifier",
                      values={ none="None", shift="Shift", control="Control", alt="Alt" },
                      order={ "none", "shift", "control", "alt" },
                      get=function() return (AuraUIDB and AuraUIDB.spellIDModifier) or "none" end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.spellIDModifier = v
                          -- Modifier choice gates the engine-side combat
                          -- aura-ID CVar (12.1; no-op on retail).
                          if AuraUI.SyncAuraSpellIDCVar then AuraUI.SyncAuraSpellIDCVar() end
                      end },
                    { type="toggle", label="Show Icon ID",
                      get=function() return not AuraUIDB or AuraUIDB.showIconID ~= false end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.showIconID = v
                      end },
                    { type="toggle", label="Show Item ID",
                      get=function() return not AuraUIDB or AuraUIDB.showItemID ~= false end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.showItemID = v
                      end },
                },
            })
        end

        -- "Use Modifier" cog on Show Tooltips (left region): while the chosen
        -- modifier is held, suppression is lifted so a hidden tooltip can be
        -- read on hover (e.g. peeking a spell in combat). Disabled (blocked +
        -- dimmed) when the reskin is off or the mode is "Always" (nothing hides).
        if not AuraUI._prebuilding then
            local leftRgn = ttModeRow._leftRegion
            local function showModOff()
                if ttReskinOff() then return true end
                return ((AuraUIDB and AuraUIDB.tooltipShowMode) or "always") == "always"
            end
            AuraUI.BuildInlineCog(leftRgn, {
                gap = 9,
                disabled = showModOff,
                disabledTooltip = function()
                    return ttReskinOff() and "Reskin Tooltip" or "This option requires Show Tooltips to be set to hide tooltips"
                end,
                title = "Show Tooltips",
                rows = {
                    { type="dropdown", label="Peek Modifier",
                      values={ none="None", shift="Shift", control="Control", alt="Alt" },
                      order={ "none", "shift", "control", "alt" },
                      get=function() return (AuraUIDB and AuraUIDB.tooltipShowModifier) or "none" end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.tooltipShowModifier = v
                      end },
                },
            })
        end

        do
            local texValues,texOrder=AuraUI.GetBorderTextureDropdown()
            local tooltipBorder
            tooltipBorder,h=W:DualRow(parent,y,
                {type="dropdown",text="Border Style",disabled=ttReskinOff,values=texValues,order=texOrder,getValue=function() return AuraUIDB.tooltipBorderTexture or "solid" end,setValue=function(v) local c,b=AuraUI.GetBorderStyleSelectDefaults(v); AuraUIDB.tooltipBorderTexture=v; AuraUIDB.tooltipBorderOffsetX=nil; AuraUIDB.tooltipBorderOffsetY=nil; AuraUIDB.tooltipBorderBehind=b; AuraUIDB.tooltipBorderColor=c; if AuraUIDB.tooltipBorderThicknessPx then AuraUIDB.tooltipBorderThicknessPx=false end; if AuraUI.SyncAuraTooltipSkin then AuraUI.SyncAuraTooltipSkin() end; AuraUI:RefreshPage(true) end},
                BorderSizeSlider("tooltip","Border Size",ttReskinOff,function() if AuraUI.SyncAuraTooltipSkin then AuraUI.SyncAuraTooltipSkin() end end)); y=y-h
            AttachBorderControls(tooltipBorder,"tooltip",ttReskinOff,true)
            BorderOffsetRow("tooltip",ttReskinOff)
        end

        local borderRow
        borderRow, h = W:DualRow(parent, y,
            -- Independent of the reskin, so it is NOT gated by "Reskin
            -- Tooltip" -- like Show Spell ID.
            { type="toggle", text="Show Max Stack for Items",
              tooltip="Appends an item's max stack count on tooltip.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.showItemMaxStacks or false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showItemMaxStacks = v
                  AuraUI:RefreshPage()  -- update the Use Modifier cog disabled state
              end },
            -- Default screen-anchored tooltip only (see ApplyGrowthDirection in
            -- AuraUIBlizzardSkin.lua): Blizzard picks the anchored corner
            -- dynamically from the tooltip's screen position; "Expand Up"/"Expand Down"
            -- force the vertical component of that corner. The cursor anchor re-points
            -- the tooltip itself, so this grays out while Anchor to Cursor is on.
            { type="dropdown", text="Growth Direction",
              tooltip="Forces which way the default screen-anchored tooltip expands as lines are added. Default lets Blizzard decide from the tooltip's screen position.",
              disabled=function()
                  return ttReskinOff() or (AuraUIDB and AuraUIDB.tooltipAnchorCursor and true or false)
              end,
              disabledTooltip=function()
                  if ttReskinOff() then return "Reskin Tooltip" end
                  return "This option does not apply while Anchor to Cursor is enabled"
              end,
              values={ default="Default", up="Expand Up", down="Expand Down" },
              order={ "default", "up", "down" },
              getValue=function()
                  return (AuraUIDB and AuraUIDB.tooltipGrowthDirection) or "default"
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.tooltipGrowthDirection = v
              end }
        );  y = y - h

        -- "Use Modifier" cog on Show Max Stack for Items (right region): the Max
        -- Stack line only shows while the chosen modifier is held. Disabled
        -- (blocked + dimmed) when the toggle is off, mirroring the Spell ID cog.
        if not AuraUI._prebuilding then
            -- The toggle now lives in the LEFT slot (slot swap above).
            local rightRgn = borderRow._leftRegion
            local function iStacksOff()
                return not (AuraUIDB and AuraUIDB.showItemMaxStacks)
            end
            AuraUI.BuildInlineCog(rightRgn, {
                gap = 9,
                disabled = iStacksOff,
                disabledTooltip = "Show Max Stack for Items",
                title = "Item Stacks",
                rows = {
                    { type="dropdown", label="Use Modifier",
                      values={ none="None", shift="Shift", control="Control", alt="Alt" },
                      order={ "none", "shift", "control", "alt" },
                      get=function() return (AuraUIDB and AuraUIDB.itemStackModifier) or "none" end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.itemStackModifier = v
                      end },
                },
            })
        end

        -----------------------------------------------------------------------
        --  Blizzard HUD. Two on-screen elements that are not windows, so they
        --  get plain toggles here rather than cards on the Window Skins page.
        --
        --  EXACTLY TWO configs in the DualRow below. W:DualRow takes a left and
        --  a right and SILENTLY DROPS a third -- a row shipped with three once
        --  rendered only two toggles and nothing errored. If a third HUD toggle
        --  is ever added, it needs its own row.
        -----------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "BLIZZARD HUD", y);  y = y - h

        local hudRow
        hudRow, h = W:DualRow(parent, y,
            { type="toggle", text="Reskin Widget Bars",
              tooltip="Restyles Blizzard's on-screen progress bars (event objectives, nameplate counters) to the AUI look. Requires reload to apply.\n\nThese bars are drawn over rather than modified, so if the game ever reports their contents as protected the original bar is shown instead.\n\nUse the cog to set a minimum size, so bars on shrunken nameplates stay readable.",
              getValue=function()
                  return not AuraUIDB or AuraUIDB.reskinWidgetBars ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.reskinWidgetBars = v and true or false
                  -- Reload-bound, like the window packs: turned OFF, the skin
                  -- registers no events at all rather than running and
                  -- returning early, so the decision is taken once at login.
                  AuraUI:ShowConfirmPopup({
                      title       = "Reload Required",
                      message     = "Widget bar reskin requires a UI reload to apply.",
                      confirmText = "Reload Now",
                      cancelText  = "Later",
                      reload      = true,
                  })
              end },
            { type="toggle", text="Reskin Extra Action Buttons",
              tooltip="Squares the extra action and zone ability buttons and gives them a thin black border.\n\nOff by default. The size slider below works whether this is on or off.",
              getValue=function()
                  -- DEFAULT OFF: opt-in, so nil reads as unchecked.
                  return AuraUIDB and AuraUIDB.reskinExtraActionButton == true
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.reskinExtraActionButton = v and true or false
              end })
        y = y - h

        -- Minimum widget bar size (plate-hosted covers), a cog on "Reskin Widget
        -- Bars": the floor below which a shrunken nameplate's bar scales itself
        -- up. 0 = off (default, mirror Blizzard's rect exactly).
        if hudRow and hudRow._leftRegion and not AuraUI._prebuilding then
            local lrgn  = hudRow._leftRegion
            local function CogOff()
                -- Same default-on test the toggle itself uses: nil means on.
                return not (not AuraUIDB or AuraUIDB.reskinWidgetBars ~= false)
            end
            AuraUI.BuildInlineCog(lrgn, {
                icon = AuraUI.RESIZE_ICON, anchorTo = lrgn._control,
                disabled = CogOff, disabledTooltip = "Reskin Widget Bars",
                tip = "Smallest on-screen size a reskinned bar is drawn at.\n\n" ..
                    "Widget bars on a nameplate inherit that nameplate's scale, so " ..
                    "they come out tiny on small units. Below this size the bar is " ..
                    "scaled up instead, text and all.\n\nSet to 0 to mirror " ..
                    "Blizzard's size exactly.",
                title = "Widget Bar Size",
                rows  = {
                    { type="slider", label="Minimum", min=0, max=24, step=1,
                      get=function()
                          local v = AuraUIDB and AuraUIDB.widgetBarMinSize
                          if type(v) == "number" then return v end
                          return 0
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.widgetBarMinSize = v
                          -- Live: the seam re-reads and books one refresh; nil
                          -- only while the reskin is off (cog greyed then).
                          if AuraUI._HUDWidgetSetMinSize then
                              AuraUI._HUDWidgetSetMinSize()
                          end
                      end },
                },
            })
        end

        return math.abs(y)
    end

    ---------------------------------------------------------------------------
    --  Character Sheet card content (Blizzard Window Skins page). The style
    --  choice lives on the card header dropdown; everything here is the
    --  window's sub-settings, built as direct children of the page wrapper so
    --  inline search and nav deep-links still see them.
    ---------------------------------------------------------------------------
    -- Section headers inside window-skin cards: title indented 5px to sit
    -- with the card chrome (the divider stays full width).
    local function WSCardSection(parent, text, y)
        local W = AuraUI.Widgets
        local hf, h = W:SectionHeader(parent, text, y)
        if hf and hf._label then
            AuraUI.PanelPP.Point(hf._label, "BOTTOMLEFT", hf, "BOTTOMLEFT", 5, 8)
        end
        return hf, h
    end

    local function BuildCharacterSheetContent(parent, y)
        local W = AuraUI.Widgets
        local _, h
        local PP = AuraUI.PanelPP

        local function themedOff()
            return AuraUIDB and AuraUIDB.themedCharacterSheet == false
        end
        -- Stock styles only: "Blizzard UI Color" (on unless turned off) paints
        -- every stat category in Blizzard's yellow, so the colour swatches
        -- stand down while it is on. On WoW Forever a stock style is
        -- Blizzard's own sheet, colours included, so they always stand down.
        local function blizzColorsOn()
            local bs = AuraUI.BlizzStyle
            return bs and bs.Get("charsheet")
                and (AuraUI.IS_FOREVER or not (AuraUIDB and AuraUIDB.charSheetBlizzColors == false))
        end

        local function AttachDisabledOverlay(target)
            local block = CreateFrame("Frame", nil, target)
            block:SetAllPoints(target)
            block:SetFrameLevel(target:GetFrameLevel() + 10)
            block:EnableMouse(true)
            local bg = AuraUI.SolidTex(block, "BACKGROUND", 0, 0, 0, 0)
            bg:SetAllPoints()
            block:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(block, AuraUI.DisabledTooltip("Character Sheet"))
            end)
            block:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            local function refresh()
                if themedOff() then block:Show(); target:SetAlpha(0.3)
                else block:Hide(); target:SetAlpha(1) end
            end
            AuraUI.RegisterWidgetRefresh(refresh); refresh()
        end

        local function AttachStatSwatch(rgn, dbColorKey, defaultColor, parentEnabledFn, cogOpts)
            if not AuraUI._prebuilding then
            local swGet = function()
                local c = AuraUIDB and AuraUIDB.statCategoryColors and AuraUIDB.statCategoryColors[dbColorKey]
                if c then return c.r, c.g, c.b, 1 end
                return defaultColor.r, defaultColor.g, defaultColor.b, 1
            end
            local swSet = function(r, g, b)
                if not AuraUIDB then AuraUIDB = {} end
                if not AuraUIDB.statCategoryColors then AuraUIDB.statCategoryColors = {} end
                if not AuraUIDB.statCategoryUseColor then AuraUIDB.statCategoryUseColor = {} end
                AuraUIDB.statCategoryColors[dbColorKey] = { r = r, g = g, b = b }
                AuraUIDB.statCategoryUseColor[dbColorKey] = true
                if AuraUI._refreshCharacterSheetColors then AuraUI._refreshCharacterSheetColors() end
            end
            local swatch, updateSwatch = AuraUI.BuildColorSwatch(rgn, rgn:GetFrameLevel() + 5, swGet, swSet, false, 20)
            PP.Point(swatch, "RIGHT", rgn._lastInline or rgn._control, "LEFT", -9, 0)
            rgn._lastInline = swatch
            local function refresh()
                local parentEnabled = parentEnabledFn() and not blizzColorsOn()
                if themedOff() then
                    swatch:SetAlpha(0.15); swatch:EnableMouse(false)
                else
                    swatch:SetAlpha(parentEnabled and 1 or 0.3)
                    swatch:EnableMouse(parentEnabled)
                end
                updateSwatch()
            end
            AuraUI.RegisterWidgetRefresh(refresh); refresh()

            if cogOpts then
                AuraUI.BuildInlineCog(rgn, {
                    title = cogOpts.title, rows = cogOpts.rows, gap = 9,
                    disabled = function() return themedOff() or not parentEnabledFn() end,
                    disabledTooltip = function() return themedOff() and "Character Sheet" or rgn._cfg.text end,
                })
            end
            end
        end

        local function StatCategoryToggle(text, key, tooltipText)
            return { type="toggle", text=text, tooltip=tooltipText,
                     getValue=function()
                         return AuraUIDB and AuraUIDB["showStatCategory_"..key] ~= false
                     end,
                     setValue=function(v)
                         if not AuraUIDB then AuraUIDB = {} end
                         AuraUIDB["showStatCategory_"..key] = v
                         if AuraUI._updateStatCategoryVisibility then
                             AuraUI._updateStatCategoryVisibility()
                         end
                         local sf = CharacterFrame and AuraUI._GetFFD(CharacterFrame).scrollFrame
                         if sf then sf:SetVerticalScroll(0) end
                         AuraUI:RefreshPage()
                     end }
        end
        local function StatCategoryEnabled(key)
            return function()
                return AuraUIDB and AuraUIDB["showStatCategory_"..key] ~= false
            end
        end

        -- Style page stock styles (Blizzard Style / Classic WoW UI) keep
        -- Blizzard's own character sheet with our stats section, slot text and
        -- socket strip: the gem icons and Icon Zoom are the AuraUI sheet's own.
        local BS = AuraUI.BlizzStyle
        local function csGate(cfg)
            if BS then BS.Gate("charsheet", cfg) end
            return cfg
        end
        -- WoW Forever: Blizzard Style and Classic WoW UI keep Blizzard's sheet
        -- untouched, so the slot text rows stand down there; the WoW Forever
        -- style keeps the slot text, so they stay live under it.
        local fvStock = AuraUI.IS_FOREVER and BS and BS.Get("charsheet") and not BS.Forever("charsheet") or false
        local function fvGate(cfg)
            if fvStock then csGate(cfg) end
            return cfg
        end

        ---------------------------------------------------------------------------
        --  CORE OPTIONS
        ---------------------------------------------------------------------------
        _, h = WSCardSection(parent, "CORE OPTIONS", y);  y = y - h
        if BS then y = BS.Note(parent, y, "charsheet") end

        -- WoW Forever shows neither (no Mythic+, and its slot text carries no
        -- item level), so the whole row stays off there.
        if not AuraUI.IS_FOREVER then
        local coreRow1
        coreRow1, h = W:DualRow(parent, y,
            { type="toggle", text="Show Mythic+ Rating",
              tooltip="Display your Mythic+ rating above the item level on the character sheet.",
              getValue=function() return AuraUIDB and AuraUIDB.showMythicRating or false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showMythicRating = v
                  if AuraUI._updateMythicRatingDisplay then AuraUI._updateMythicRatingDisplay() end
              end },
            { type="toggle", text="Item Level",
              tooltip="Toggle visibility of item level text on the character sheet.",
              getValue=function() return AuraUIDB and AuraUIDB.showItemLevel ~= false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showItemLevel = v
                  if AuraUI._refreshItemLevelVisibility then AuraUI._refreshItemLevelVisibility() end
              end }
        );  y = y - h
        AttachDisabledOverlay(coreRow1)
        end -- not IS_FOREVER

        -- WoW Forever has no upgrade tracks: the same key shows each item's
        -- main and secondary stat (or its armor when it has none) and each
        -- weapon's damage per second there.
        local upgradeTrackCfg = fvGate({ type="toggle", text=AuraUI.IS_FOREVER and "Show Item Stats" or "Upgrade Track",
              tooltip=AuraUI.IS_FOREVER and "Show each item's main and secondary stat (or its armor) and each weapon's damage per second beside its slot."
                  or "Toggle visibility of upgrade track text on the character sheet.",
              getValue=function() return AuraUIDB and AuraUIDB.showUpgradeTrack ~= false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showUpgradeTrack = v
                  if AuraUI._refreshUpgradeTrackVisibility then AuraUI._refreshUpgradeTrackVisibility() end
              end })
        local showGemsCfg = csGate({ type="toggle", text="Show Gems",
              tooltip="Toggle visibility of gem icons inside equipment slots.",
              getValue=function() return AuraUIDB and AuraUIDB.showGems ~= false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showGems = v
                  if AuraUI._refreshGemsVisibility then AuraUI._refreshGemsVisibility() end
              end })
        -- Both looks: under the stock styles the strip hangs below Blizzard's
        -- sheet in its tab art (AuraUIBlizzardSkin_SocketPanel.lua).
        local socketPanelCfg = { type="toggle", text="Socket Panel",
              tooltip="Show a panel of equipped-gear sockets on the character sheet; click a socket to gem it.",
              getValue=function() return AuraUIDB and AuraUIDB.charSheetSocketPanel ~= false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.charSheetSocketPanel = v
                  if AuraUI._refreshCharSheetSocketPanel then AuraUI._refreshCharSheetSocketPanel() end
              end }
        -- Blizzard's own slot icons under the stock styles (the inspect sheet
        -- keeps its stored zoom).
        local iconZoomCfg = csGate({ type="slider", text="Icon Zoom", min=0, max=0.20, step=0.01,
              tooltip="Crops the border of the equipment-slot item icons on the character and inspect sheets. 0 shows the full icon. Only affects the themed character sheet.",
              getValue=function() return (AuraUIDB and AuraUIDB.charSheetIconZoom) or 0.07 end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.charSheetIconZoom = v
                  if AuraUI._refreshCharSheetIconZoom then AuraUI._refreshCharSheetIconZoom() end
              end })
        -- Stock styles pair Socket Panel beside Upgrade Track and put the two
        -- AuraUI-only controls together, so that row hides whole and no
        -- blank slot is left; the AuraUI order is unchanged.
        local stockSheet = BS and BS.Get("charsheet")

        local coreRow2
        coreRow2, h = W:DualRow(parent, y, upgradeTrackCfg, stockSheet and socketPanelCfg or showGemsCfg);  y = y - h
        AttachDisabledOverlay(coreRow2)

        local socketRow
        socketRow, h = W:DualRow(parent, y, stockSheet and showGemsCfg or socketPanelCfg, iconZoomCfg);  y = y - h
        AttachDisabledOverlay(socketRow)

        local enchGemRow
        enchGemRow, h = W:DualRow(parent, y,
            fvGate({ type="toggle", text="Enchants",
              tooltip="Toggle visibility of enchant text on the character sheet.",
              getValue=function() return AuraUIDB and AuraUIDB.showEnchants ~= false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showEnchants = v
                  if AuraUI._refreshEnchantsVisibility then AuraUI._refreshEnchantsVisibility() end
                  -- Refresh so the inline Enchant Settings cog updates its
                  -- disabled state in lockstep with this toggle.
                  AuraUI:RefreshPage()
              end }),
            { type="toggle", text="Show PvP Item Level",
              tooltip="Display your PvP item level above the Mythic+ rating on the character sheet.",
              getValue=function() return AuraUIDB and AuraUIDB.showPvpItemLevel or false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showPvpItemLevel = v
                  if AuraUI._updatePvpIlvlDisplay then AuraUI._updatePvpIlvlDisplay() end
              end }
        );  y = y - h
        AttachDisabledOverlay(enchGemRow)

        -- Inline cog on the Enchants toggle: "Show Enchant Names". Disabled
        -- (grayed, non-interactive) while Enchants are hidden, since the name
        -- only replaces the enchant icon when enchants are shown.
        if not AuraUI._prebuilding then
            local rgn = enchGemRow._leftRegion
            AuraUI.BuildInlineCog(rgn, {
                disabled = function() return fvStock or not (AuraUIDB and AuraUIDB.showEnchants ~= false) end,
                disabledTooltip = fvStock and BS.Label("charsheet") or "Enchants",
                requireState = fvStock and "disabled" or nil,
                title = "Enchant Settings",
                rows = {
                    { type="toggle", label="Show Enchant Names",
                      tooltip="Show each enchant's name as text (colored to match that item's item level) instead of its icon. The name normally appears only when hovering the icon.",
                      get=function() return AuraUIDB and AuraUIDB.charSheetEnchantNames or false end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.charSheetEnchantNames = v
                          if AuraUI._refreshCharSheetSlotLabels then AuraUI._refreshCharSheetSlotLabels() end
                      end },
                    -- The WoW Forever style always shows the enchant as text,
                    -- so its size applies with or without Show Enchant Names there.
                    { type="slider", label="Text Size", min=6, max=20, step=1,
                      disabled=function() return not (AuraUI.IS_FOREVER and BS and BS.Forever("charsheet")) and not (AuraUIDB and AuraUIDB.charSheetEnchantNames) end,
                      disabledTooltip="Show Enchant Names",
                      get=function() return (AuraUIDB and AuraUIDB.charSheetEnchantSize) or 9 end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.charSheetEnchantSize = v
                          if AuraUI._refreshCharSheetSlotLabels then AuraUI._refreshCharSheetSlotLabels() end
                      end },
                },
            })
        end

        -- Gear flyout item levels. Independent of the themed character sheet
        -- (it enhances Blizzard's own equipment flyout), so it is not gated by
        -- the section's disabled overlay.
        local flyoutDurRow
        flyoutDurRow, h = W:DualRow(parent, y,
            { type="toggle", text="Gear Flyout Item Levels",
              tooltip="Shows the item level on each item in the character sheet gear flyout (the popup of same-slot bag items that appears when hovering an equipped slot), coloured by quality.",
              getValue=function() return AuraUIDB and AuraUIDB.flyoutItemLevels or false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.flyoutItemLevels = v
              end },
            { type="toggle", text="Show Item Durability",
              tooltip="Show total equipped durability above the character model, colored from green to red.",
              getValue=function() return AuraUIDB and AuraUIDB.showCharSheetDurability or false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showCharSheetDurability = v
                  if v then
                      if AuraUIDB.charSheetDurabilityLocation == nil then
                          AuraUIDB.charSheetDurabilityLocation = "model"
                      end
                      if AuraUIDB.charSheetDurabilityShowLabel == nil then
                          AuraUIDB.charSheetDurabilityShowLabel = true
                      end
                  end
                  if AuraUI._updateCharSheetDurability then AuraUI._updateCharSheetDurability() end
                  if AuraUI._updateScrollHeaderOffset then AuraUI._updateScrollHeaderOffset() end
                  AuraUI:RefreshPage()
              end }
        );  y = y - h

        if not AuraUI._prebuilding then
            local rgn = flyoutDurRow._rightRegion
            AuraUI.BuildInlineCog(rgn, {
                disabled = function() return not (AuraUIDB and AuraUIDB.showCharSheetDurability) end,
                disabledTooltip = "Show Item Durability",
                title = "Durability Settings",
                rows = {
                    { type="dropdown", label="Location",
                      values={ model="Above Model", header="Stats Header", footer="Frame Footer" },
                      order={ "model", "header", "footer" },
                      get=function()
                          return AuraUIDB and AuraUIDB.charSheetDurabilityLocation or "model"
                      end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.charSheetDurabilityLocation = v
                          if AuraUI._updateCharSheetDurability then AuraUI._updateCharSheetDurability() end
                          if AuraUI._updateScrollHeaderOffset then AuraUI._updateScrollHeaderOffset() end
                      end },
                    { type="toggle", label="Show Label",
                      tooltip="Prefix the durability percent with \"Durability:\".",
                      get=function() return not AuraUIDB or AuraUIDB.charSheetDurabilityShowLabel ~= false end,
                      set=function(v)
                          if not AuraUIDB then AuraUIDB = {} end
                          AuraUIDB.charSheetDurabilityShowLabel = v
                          if AuraUI._updateCharSheetDurability then AuraUI._updateCharSheetDurability() end
                      end },
                },
            })
        end

        _, h = W:Spacer(parent, y, 10);  y = y - h

        ---------------------------------------------------------------------------
        --  STAT DISPLAY
        ---------------------------------------------------------------------------
        _, h = WSCardSection(parent, "STAT DISPLAY", y);  y = y - h

        local secondaryCogOpts = {
            title = "Secondary Stats Settings",
            rows = {
                { type="toggle", label="Show Raw Rating",
                  get=function() return AuraUIDB and AuraUIDB.showSecondaryRaw or false end,
                  set=function(v)
                      if not AuraUIDB then AuraUIDB = {} end
                      AuraUIDB.showSecondaryRaw = v
                      if v then AuraUIDB.showSecondaryBoth = false end
                      if AuraUI._refreshStatFormats then AuraUI._refreshStatFormats() end
                  end },
                { type="toggle", label="Show % and Raw",
                  get=function() return AuraUIDB and AuraUIDB.showSecondaryBoth or false end,
                  set=function(v)
                      if not AuraUIDB then AuraUIDB = {} end
                      AuraUIDB.showSecondaryBoth = v
                      if v then AuraUIDB.showSecondaryRaw = false end
                      if AuraUI._refreshStatFormats then AuraUI._refreshStatFormats() end
                  end },
            },
        }
        local tertiaryCogOpts = {
            title = "Tertiary Stats Settings",
            rows = {
                { type="toggle", label="Show Raw Rating",
                  get=function() return AuraUIDB and AuraUIDB.showTertiaryRaw or false end,
                  set=function(v)
                      if not AuraUIDB then AuraUIDB = {} end
                      AuraUIDB.showTertiaryRaw = v
                      if v then AuraUIDB.showTertiaryBoth = false end
                      if AuraUI._refreshStatFormats then AuraUI._refreshStatFormats() end
                  end },
                { type="toggle", label="Show % and Raw",
                  get=function() return AuraUIDB and AuraUIDB.showTertiaryBoth or false end,
                  set=function(v)
                      if not AuraUIDB then AuraUIDB = {} end
                      AuraUIDB.showTertiaryBoth = v
                      if v then AuraUIDB.showTertiaryRaw = false end
                      if AuraUI._refreshStatFormats then AuraUI._refreshStatFormats() end
                  end },
            },
        }
        local function crestRow(label, key)
            return { type="toggle", label=label,
                     get=function()
                         return not (AuraUIDB and AuraUIDB["showCrest_"..key] == false)
                     end,
                     set=function(v)
                         if not AuraUIDB then AuraUIDB = {} end
                         AuraUIDB["showCrest_"..key] = v
                         if AuraUI._refreshStatsVisibility then AuraUI._refreshStatsVisibility() end
                     end }
        end
        local attributesCogOpts = {
            title = "Attributes",
            rows = {
                { type="toggle", label="Show Mana",
                  get=function() return AuraUIDB and AuraUIDB.showManaStat == true end,
                  set=function(v)
                      if not AuraUIDB then AuraUIDB = {} end
                      AuraUIDB.showManaStat = v
                      if AuraUI._refreshStatsVisibility then AuraUI._refreshStatsVisibility() end
                  end },
            },
        }
        local crestsCogOpts = {
            title = "Crests",
            rows = {
                crestRow("Show Myth",       "Myth"),
                crestRow("Show Hero",       "Hero"),
                crestRow("Show Champion",   "Champion"),
                crestRow("Show Veteran",    "Veteran"),
                crestRow("Show Adventurer", "Adventurer"),
            },
        }

        local drCfg = { type="toggle", text="Show Diminishing Returns",
              tooltip="Add diminishing-returns detail (adjusted rating, wasted rating, and current penalty bracket) to the Secondary and Tertiary stat tooltips.",
              getValue=function() return AuraUIDB and AuraUIDB.showAdjustedStats or false end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.showAdjustedStats = v
              end }

        -- Stock styles only: "Blizzard UI Color" opens the section, paired with
        -- Show Diminishing Returns (so Show PvP takes the odd last slot). On
        -- unless turned off; the AuraUI look never builds or reads it,
        -- and neither does WoW Forever (its sheet has no AuraUI stats
        -- section to tint).
        local stockCS = BS and BS.Get("charsheet") and not AuraUI.IS_FOREVER
        if stockCS then
            local colorRow
            colorRow, h = W:DualRow(parent, y,
                { type="toggle", text="Blizzard UI Color",
                  tooltip="Shows the item level and stat category titles in Blizzard's yellow, with values in the label color.",
                  getValue=function() return not (AuraUIDB and AuraUIDB.charSheetBlizzColors == false) end,
                  setValue=function(v)
                      if not AuraUIDB then AuraUIDB = {} end
                      AuraUIDB.charSheetBlizzColors = v
                      if AuraUI._refreshCharacterSheetColors then AuraUI._refreshCharacterSheetColors() end
                      AuraUI:RefreshPage()
                  end },
                drCfg
            );  y = y - h
            AttachDisabledOverlay(colorRow)
        end

        local statRow1
        statRow1, h = W:DualRow(parent, y,
            StatCategoryToggle("Show Attributes", "Attributes",
                "Toggle visibility of the Attributes stat category."),
            StatCategoryToggle("Show Secondary", "SecondaryStats",
                "Toggle visibility of the Secondary Stats category.")
        );  y = y - h
        AttachDisabledOverlay(statRow1)
        AttachStatSwatch(statRow1._leftRegion, "Attributes",
            { r = 0.047, g = 0.824, b = 0.616 }, StatCategoryEnabled("Attributes"),
            attributesCogOpts)
        AttachStatSwatch(statRow1._rightRegion, "Secondary Stats",
            { r = 0.471, g = 0.255, b = 0.784 }, StatCategoryEnabled("SecondaryStats"),
            secondaryCogOpts)

        local statRow2
        statRow2, h = W:DualRow(parent, y,
            StatCategoryToggle("Show Tertiary", "Tertiary",
                "Toggle visibility of the Tertiary stat category (Leech, Avoidance, Speed)."),
            StatCategoryToggle("Show Attack", "Attack",
                "Toggle visibility of the Attack stat category.")
        );  y = y - h
        AttachDisabledOverlay(statRow2)
        AttachStatSwatch(statRow2._leftRegion, "Tertiary Stats",
            { r = 0.859, g = 0.325, b = 0.855 }, StatCategoryEnabled("Tertiary"),
            tertiaryCogOpts)
        AttachStatSwatch(statRow2._rightRegion, "Attack",
            { r = 1, g = 0.353, b = 0.122 }, StatCategoryEnabled("Attack"))

        local statRow3
        statRow3, h = W:DualRow(parent, y,
            StatCategoryToggle("Show Defense", "Defense",
                "Toggle visibility of the Defense stat category."),
            StatCategoryToggle("Show Crests", "Crests",
                "Toggle visibility of the Crests stat category.")
        );  y = y - h
        AttachDisabledOverlay(statRow3)
        AttachStatSwatch(statRow3._leftRegion, "Defense",
            { r = 0.247, g = 0.655, b = 1 }, StatCategoryEnabled("Defense"))
        AttachStatSwatch(statRow3._rightRegion, "Crests",
            { r = 1, g = 0.784, b = 0.341 }, StatCategoryEnabled("Crests"),
            crestsCogOpts)

        local statRow4
        statRow4, h = W:DualRow(parent, y,
            StatCategoryToggle("Show PvP", "PvP",
                "Toggle visibility of the PvP stat category (Honor Level, Honor, Conquest)."),
            stockCS and { type="label", text="" } or drCfg
        );  y = y - h
        AttachDisabledOverlay(statRow4)
        AttachStatSwatch(statRow4._leftRegion, "PvP",
            { r = 0.671, g = 0.431, b = 0.349 }, StatCategoryEnabled("PvP"))

        ---------------------------------------------------------------------------
        --  INSPECT SHEET
        ---------------------------------------------------------------------------
        _, h = WSCardSection(parent, "INSPECT SHEET", y);  y = y - h

        local themedInspectSheetRow
        themedInspectSheetRow, h = W:DualRow(parent, y,
            { type="toggle", text="Enable Inspect Sheet",
              tooltip="Applies AuraUI theme styling to the inspect sheet window.",
              getValue=function()
                  return not AuraUIDB or AuraUIDB.themedInspectSheet ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.themedInspectSheet = v
                  AuraUI:ShowConfirmPopup({
                      title       = "Reload Required",
                      message     = "Inspect Sheet theme setting requires a UI reload to fully apply.",
                      confirmText = "Reload Now",
                      cancelText  = "Later",
                      reload      = true,
                  })
                  AuraUI:RefreshPage()
              end },
            { type="toggle", text="Show Enchants",
              tooltip="Toggle visibility of enchant icons on the inspect sheet.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.inspectShowEnchants ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.inspectShowEnchants = v
                  if AuraUI._refreshInspectEnchantsVisibility then
                      AuraUI._refreshInspectEnchantsVisibility()
                  end
              end }
        );  y = y - h

        local itemLevelInspectRow
        itemLevelInspectRow, h = W:DualRow(parent, y,
            { type="toggle", text="Show Item Level",
              tooltip="Toggle visibility of item level text on the inspect sheet.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.inspectShowItemLevel ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.inspectShowItemLevel = v
                  if AuraUI._refreshInspectItemLevelVisibility then
                      AuraUI._refreshInspectItemLevelVisibility()
                  end
              end },
            { type="toggle", text="Show Upgrade Track",
              tooltip="Toggle visibility of upgrade track text on the inspect sheet.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.inspectShowUpgradeTrack ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.inspectShowUpgradeTrack = v
                  if AuraUI._refreshInspectUpgradeTrackVisibility then
                      AuraUI._refreshInspectUpgradeTrackVisibility()
                  end
              end }
        );  y = y - h

        if not AuraUI._prebuilding then
            local function themedOff()
                return not (AuraUIDB and AuraUIDB.themedInspectSheet)
            end

            local itemLevelInspectBlock = CreateFrame("Frame", nil, itemLevelInspectRow)
            itemLevelInspectBlock:SetAllPoints(itemLevelInspectRow)
            itemLevelInspectBlock:SetFrameLevel(itemLevelInspectRow:GetFrameLevel() + 10)
            itemLevelInspectBlock:EnableMouse(true)
            local itemLevelInspectBg = AuraUI.SolidTex(itemLevelInspectBlock, "BACKGROUND", 0, 0, 0, 0)
            itemLevelInspectBg:SetAllPoints()
            itemLevelInspectBlock:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(itemLevelInspectBlock, AuraUI.DisabledTooltip("Inspect Sheet"))
            end)
            itemLevelInspectBlock:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

            AuraUI.RegisterWidgetRefresh(function()
                if themedOff() then
                    itemLevelInspectBlock:Show()
                    itemLevelInspectRow:SetAlpha(0.3)
                else
                    itemLevelInspectBlock:Hide()
                    itemLevelInspectRow:SetAlpha(1)
                end
            end)
            if themedOff() then itemLevelInspectBlock:Show() itemLevelInspectRow:SetAlpha(0.3) else itemLevelInspectBlock:Hide() itemLevelInspectRow:SetAlpha(1) end
        end

        return y
    end

    ---------------------------------------------------------------------------
    --  LFG Menu card content
    ---------------------------------------------------------------------------
    local function BuildLFGMenuContent(parent, y)
        local W = AuraUI.Widgets
        local _, h

        _, h = WSCardSection(parent, "QUALITY OF LIFE", y);  y = y - h

        _, h = W:DualRow(parent, y,
            { type="toggle", text="Remember Sign-Up Roles",
              tooltip="Remembers the Tank/Healer/DPS roles you last applied with and restores them the next time you sign up to a premade group (limited to roles your current spec can fill). Works with or without the reskin.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.lfgRememberRoles == true
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.lfgRememberRoles = v
                  if AuraUI._GroupFinder_RefreshQoL then AuraUI._GroupFinder_RefreshQoL() end
              end },
            { type="label", text="" }
        );  y = y - h

        return y
    end

    local function BuildMerchantContent(parent, y)
        local W = AuraUI.Widgets
        local _, h

        local function themedOff()
            return AuraUIDB and AuraUIDB.reskinMerchant == false
        end

        local function AttachDisabledOverlay(target)
            local block = CreateFrame("Frame", nil, target)
            block:SetAllPoints(target)
            block:SetFrameLevel(target:GetFrameLevel() + 10)
            block:EnableMouse(true)
            local bg = AuraUI.SolidTex(block, "BACKGROUND", 0, 0, 0, 0)
            bg:SetAllPoints()
            block:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(block, AuraUI.DisabledTooltip("Merchant"))
            end)
            block:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            local function refresh()
                if themedOff() then block:Show(); target:SetAlpha(0.3)
                else block:Hide(); target:SetAlpha(1) end
            end
            AuraUI.RegisterWidgetRefresh(refresh); refresh()
        end

        _, h = WSCardSection(parent, "QUALITY OF LIFE", y);  y = y - h

        local function merchantShowAsListOff()
            return AuraUIDB and AuraUIDB.merchantShowAsList == false
        end

        local row
        row, h = W:DualRow(parent, y,
            { type="toggle", text="Show As List",
              tooltip="Shows the items as a list instead of pages.",
              getValue=function()
                return AuraUIDB and AuraUIDB.merchantShowAsList == true
              end,
              setValue=function(v)
                if not AuraUIDB then AuraUIDB = {} end
                local previousValue = AuraUIDB.merchantShowAsList
                AuraUIDB.merchantShowAsList = v

                -- Enabling the setting breaks the UI immediately, a reload is required
                AuraUI:ShowConfirmPopup({
                    title       = "Reload Required",
                    message     = "Merchant Show As List setting requires a UI reload to fully apply.",
                    confirmText = "Reload Now",
                    cancelText  = "Cancel",
                    reload      = true,
                    onCancel    = function()
                        AuraUIDB.merchantShowAsList = previousValue;
                        AuraUI:RefreshPage()
                    end,
                })
              end },
            { type="slider", text="Row Height", min=24, max=40, step=1,
              disabled=merchantShowAsListOff, disabledTooltip="Show As List",
              getValue=function() return (AuraUIDB and AuraUIDB.merchantListRowHeight) or 32 end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.merchantListRowHeight = v
                  if AuraUI._Merchant_RefreshRowHeight then AuraUI._Merchant_RefreshRowHeight() end
              end }
        ); y = y - h
        AttachDisabledOverlay(row)

        _, h = W:DualRow(parent, y,
            { type="toggle", text="Show Item Level",
              tooltip="Shows the item level on weapons and armor a vendor sells.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.merchantShowItemLevel == true
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.merchantShowItemLevel = v
                  if AuraUI._Merchant_RefreshItemLevels then AuraUI._Merchant_RefreshItemLevels() end
              end },
            { type="label", text="" }
        ); y = y - h

        return y
    end


    local function BuildLootToastContent(parent, y)
        local W = AuraUI.Widgets
        local _, h

        _, h = WSCardSection(parent, "QUALITY OF LIFE", y);  y = y - h

        _, h = W:DualRow(parent, y,
            { type="toggle", text="Quality Strip",
              tooltip="Adds a strip down the left edge of a loot toast in the item's quality color. The flat skin drops Blizzard's quality ring around the icon, so this puts that rarity cue back.",
              getValue=function()
                  return not AuraUIDB or AuraUIDB.lootToastQualityStrip ~= false
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.lootToastQualityStrip = v
                  if AuraUI._LootToast_Refresh then AuraUI._LootToast_Refresh() end
              end },
            { type="toggle", text="Gold Toast Strip",
              tooltip="Also show the strip on gold toasts, in the header's gold color. Gold has no rarity to signal, so this is off by default.",
              getValue=function()
                  return AuraUIDB and AuraUIDB.lootToastQualityStripMoney == true
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.lootToastQualityStripMoney = v
                  if AuraUI._LootToast_Refresh then AuraUI._LootToast_Refresh() end
              end }
        ); y = y - h

        _, h = W:DualRow(parent, y,
            { type="slider", text="Toast Scale",
              tooltip="Scales the loot and gold toasts.",
              min=0.5, max=1.5, step=0.05, format="%.0f%%",
              displayMul=100,
              getValue=function()
                  return AuraUIDB and AuraUIDB.lootToastScale or 1.0
              end,
              setValue=function(v)
                  if not AuraUIDB then AuraUIDB = {} end
                  AuraUIDB.lootToastScale = v
                  if AuraUI._LootToast_Refresh then AuraUI._LootToast_Refresh() end
              end },
            { type="label", text="" }
        ); y = y - h

        return y
    end

    ---------------------------------------------------------------------------
    --  Blizzard Window Skins page: one expandable card per reskinned window.
    --  Card headers are custom chrome, but every sub-setting ROW is a standard
    --  W: widget built as a direct child of the page wrapper, so inline search
    --  and nav deep-links keep working. Expand state is session-only; clicking
    --  a header rebuilds the page with that card open or closed.
    ---------------------------------------------------------------------------
    local WS_ARROW_DOWN = "Interface\\AddOns\\AuraUI\\media\\icons\\aui-arrow-down3.png"
    local WS_ARROW_UP   = "Interface\\AddOns\\AuraUI\\media\\icons\\aui-arrow-up3.png"
    local WS_CARD_INSET = 0    -- card edges align with the DualRow content width
    local WS_HEADER_H   = 54
    local WS_CARD_GAP   = 14

    local _wsExpanded = {}
    local _wsApplyAllStyle = "eui"  -- set-all dropdown pick (session-only)

    local function WSReloadPopup(message)
        AuraUI:ShowConfirmPopup({
            title       = "Reload Required",
            message     = message,
            confirmText = "Reload Now",
            cancelText  = "Later",
            reload      = true,
        })
    end

    -- Style vocabulary shared by the per-card dropdowns and the set-all row.
    local WS_STYLE_VALUES = { eui = "AuraUI", modern = "Modern", off = "Blizz Default" }
    local WS_STYLE_ORDER  = { "eui", "modern", "off" }

    -- Modern background color + opacity: ONE global setting for the Modern
    -- style, resolved by the window-skin engine and applied live to every
    -- window currently set to Modern.
    local function WSModernGet()
        if ns.WSkin and ns.WSkin.GetModernBG then
            return ns.WSkin.GetModernBG()
        end
        return 0.067, 0.067, 0.067, 0.97
    end
    local function WSModernSet(r, g, b, a)
        if not AuraUIDB then AuraUIDB = {} end
        AuraUIDB.blizzWindowModernDefault = { r = r, g = g, b = b, a = a }
        if AuraUI._WSkinRefreshStyles then AuraUI._WSkinRefreshStyles() end
    end

    -- Single Modern color swatch left of the set-all dropdown. The picker
    -- carries the opacity slider; edits write the Modern preset directly, so
    -- windows already on Modern recolor immediately (no Apply to All).
    local function AttachModernSwatch(host, anchorTo)
        local swatch, updateSwatch = AuraUI.BuildColorSwatch(host, host:GetFrameLevel() + 5,
            function() return WSModernGet() end,
            function(r, g, b, a) WSModernSet(r, g, b, a) end,
            true, 20)
        AuraUI.PanelPP.Point(swatch, "RIGHT", anchorTo, "LEFT", -8, 0)
        swatch:HookScript("OnEnter", function(s)
            AuraUI.ShowWidgetTooltip(s, "Background color for the Modern style.")
        end)
        swatch:HookScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
        AuraUI.RegisterWidgetRefresh(updateSwatch)
    end

    -- Global look settings (Global Options section): central tables, nil =
    -- defaults, resolved by the window-skin engine and applied live.
    local function WSLook(key)
        return AuraUIDB and AuraUIDB[key]
    end
    local function WSLookSet(key, field, v)
        if not AuraUIDB then AuraUIDB = {} end
        local t = AuraUIDB[key]
        if not t then t = {}; AuraUIDB[key] = t end
        t[field] = v
        if AuraUI._WSkinRefreshLooks then AuraUI._WSkinRefreshLooks() end
    end

    -- Inline accent|custom swatch pair on a DualRow region (the standard
    -- dual-swatch treatment): custom sits nearest the control, accent left of
    -- it; the active mode renders bright, the other dimmed.
    local function AttachLookSwatches(rgn, row, key)
        local PP = AuraUI.PanelPP
        local ctrl = rgn._control

        local customSwatch, updateCustom = AuraUI.BuildColorSwatch(
            rgn, row:GetFrameLevel() + 3,
            function()
                local c = WSLook(key)
                local col = c and c.color
                if col then return col.r or 1, col.g or 1, col.b or 1 end
                return 1, 1, 1
            end,
            function(r, g, b)
                WSLookSet(key, "color", { r = r, g = g, b = b })
                WSLookSet(key, "useCustom", true)
                AuraUI:RefreshPage()
            end,
            false, 20)
        PP.Point(customSwatch, "RIGHT", ctrl, "LEFT", -8, 0)
        local origClick = customSwatch:GetScript("OnClick")
        customSwatch:SetScript("OnClick", function(self, ...)
            local c = WSLook(key)
            if not (c and c.useCustom) then
                WSLookSet(key, "useCustom", true)
                AuraUI:RefreshPage()
                return
            end
            if origClick then origClick(self, ...) end
        end)
        customSwatch:SetScript("OnEnter", function()
            AuraUI.ShowWidgetTooltip(customSwatch, "Custom Color")
        end)
        customSwatch:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

        local accentSwatch, updateAccent = AuraUI.BuildColorSwatch(
            rgn, row:GetFrameLevel() + 3,
            function()
                return AuraUI.ResolveActiveAccent()
            end,
            function()
                WSLookSet(key, "useCustom", false)
                AuraUI:RefreshPage()
            end,
            false, 20)
        PP.Point(accentSwatch, "RIGHT", customSwatch, "LEFT", -8, 0)
        accentSwatch:SetScript("OnClick", function()
            WSLookSet(key, "useCustom", false)
            AuraUI:RefreshPage()
        end)
        accentSwatch:SetScript("OnEnter", function()
            AuraUI.ShowWidgetTooltip(accentSwatch, "Accent Color")
        end)
        accentSwatch:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
        rgn._lastInline = accentSwatch

        local function refreshPair()
            updateCustom(); updateAccent()
            local c = WSLook(key)
            local useCustom = c and c.useCustom
            customSwatch:SetAlpha(useCustom and 1 or 0.3)
            accentSwatch:SetAlpha(useCustom and 0.3 or 1)
        end
        AuraUI.RegisterWidgetRefresh(refreshPair)
        refreshPair()
    end

    local WINDOWS = {
        {
            key   = "charsheet",
            title = "Character Sheet",
            desc  = "Equipment panel with stat categories, item level, enchants, gems, and the inspect sheet.",
            reloadMsg = "Character Sheet theme setting requires a UI reload to fully apply.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.themedCharacterSheet = v
                AuraUIDB.themedInspectSheet = v
                -- Individual feature toggles retain their values.
            end,
            buildContent = BuildCharacterSheetContent,
        },
        {
            key   = "lfg",
            title = "LFG Menu",
            desc  = "Group Finder and Premade Groups window, plus browsing quality-of-life extras.",
            reloadMsg = "Changing the Group Finder reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinLFGMenu = v
            end,
            buildContent = BuildLFGMenuContent,
        },
        {
            key   = "greatvault",
            title = "Great Vault",
            desc  = "Weekly rewards window with custom tile backgrounds, progress colors, and completion states.",
            reloadMsg = "Changing the Great Vault reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinGreatVault = v
            end,
        },
        {
            key   = "adventureguide",
            title = "Adventure Guide",
            desc  = "Encounter Journal: instance select, boss details, loot lists, and the bottom nav tabs.",
            reloadMsg = "Changing the Adventure Guide reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinAdventureGuide = v
            end,
        },
        {
            key   = "collections",
            title = "Collections",
            desc  = "Mounts, pets, toys, heirlooms, appearances, and campsites.",
            reloadMsg = "Changing the Collections reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinCollections = v
            end,
        },
        {
            key   = "playerspells",
            title = "Talents & Spellbook",
            desc  = "The Player Spells window: talents, spec selection, and the spellbook.",
            reloadMsg = "Changing the Talents & Spellbook reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinPlayerSpells = v
            end,
        },
        {
            key   = "professionsbook",
            title = "Professions",
            desc  = "The professions overview book with squared icons and flat progress bars.",
            reloadMsg = "Changing the Professions reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinProfessionsBook = v
            end,
        },
        {
            key   = "professions",
            title = "Profession Crafting",
            desc  = "The profession crafting window: recipe list, schematic, specializations, and crafting orders.",
            reloadMsg = "Changing the Profession Crafting reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinProfessions = v
            end,
        },
        {
            key   = "worldmap",
            title = "Map & Quest Log",
            desc  = "The world map window chrome and the quest log side panel.",
            reloadMsg = "Changing the Map & Quest Log reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinWorldMap = v
            end,
        },
        {
            key   = "guild",
            title = "Guild & Communities",
            desc  = "The Guild & Communities window: roster, chat, and the community list.",
            reloadMsg = "Changing the Guild & Communities reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinGuild = v
            end,
        },
        {
            key   = "calendar",
            title = "Calendar",
            desc  = "The monthly calendar grid, event dialogs, and navigation arrows.",
            reloadMsg = "Changing the Calendar reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinCalendar = v
            end,
        },
        {
            key   = "achievements",
            title = "Achievements",
            desc  = "The achievement window: categories, rows, progress bars, and search.",
            reloadMsg = "Changing the Achievements reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinAchievements = v
            end,
        },
        {
            key   = "mail",
            title = "Mail",
            desc  = "The mailbox: inbox rows, send mail, open mail, and attachment slots.",
            reloadMsg = "Changing the Mail reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinMail = v
            end,
        },
        {
            key   = "catalyst",
            title = "Catalyst",
            desc  = "The item conversion window (catalyst and similar kiosks).",
            reloadMsg = "Changing the Catalyst reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinCatalyst = v
            end,
        },
        {
            key   = "socket",
            title = "Gem Socketing",
            desc  = "The gem socketing window with squared gem slots.",
            reloadMsg = "Changing the Gem Socketing reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinSocket = v
            end,
        },
        {
            key   = "itemupgrade",
            title = "Item Upgrades",
            desc  = "The item upgrade window: upgrade slot, track selector, cost, and the currency strip.",
            reloadMsg = "Changing the Item Upgrades reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinItemUpgrade = v
            end,
        },
        {
            key   = "loot",
            title = "Loot Window",
            desc  = "The loot window: item rows with squared icons, kept item quality colors.",
            reloadMsg = "Changing the Loot Window reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinLoot = v
            end,
        },
        {
            key   = "loottoast",
            title = "Loot Toasts",
            desc  = "The \"You received\" popups for loot, currency, and upgrades.",
            reloadMsg = "Changing the Loot Toasts reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinLootToast = v
            end,
            buildContent = BuildLootToastContent,
        },
        {
            key   = "bnettoast",
            title = "Friend Notifications",
            desc  = "The Battle.net popup when a friend comes online or goes offline, plus broadcasts and invites.",
            reloadMsg = "Changing the Friend Notifications reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinBNetToast = v
            end,
        },
        {
            key   = "lootroll",
            title = "Loot Roll Popups",
            desc  = "The need / greed / pass roll popups, with a squared icon and a flat roll timer.",
            reloadMsg = "Changing the Loot Roll Popups reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinLootRoll = v
            end,
        },
        {
            key   = "loothistory",
            title = "Loot Rolls Window",
            desc  = "The pending-rolls window: encounter picker, roll timer, and the result rows.",
            reloadMsg = "Changing the Loot Rolls Window reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinLootHistory = v
            end,
        },
        {
            key   = "groupinvite",
            title = "Group Invite Popup",
            desc  = "The \"you have been invited to a group\" dialogs, with your role and Accept / Decline.",
            reloadMsg = "Changing the Group Invite Popup reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinGroupInvite = v
            end,
        },
        {
            key   = "readycheck",
            title = "Ready Check",
            desc  = "The ready check prompt with its Yes / No buttons.",
            reloadMsg = "Changing the Ready Check reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinReadyCheck = v
            end,
        },
        {
            key   = "housing",
            title = "Housing Dashboard",
            desc  = "The housing dashboard window background, border, and title bar.",
            reloadMsg = "Changing the Housing Dashboard reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinHousing = v
            end,
        },
        {
            key   = "micromenu",
            title = "Micro Menu",
            desc  = "Flattens the micro menu buttons into the AuraUI style.",
            reloadMsg = "Changing the Micro Menu reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinMicroMenu = v
            end,
        },
        {
            key   = "dressup",
            title = "Dressing Room",
            desc  = "The item preview / transmog dressing room window.",
            reloadMsg = "Changing the Dressing Room reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinDressUp = v
            end,
        },
        {
            key   = "transmog",
            title = "Transmogrifier",
            desc  = "The transmogrification window at the transmogrifier.",
            reloadMsg = "Changing the Transmogrifier reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinTransmog = v
            end,
        },
        {
            key   = "merchant",
            title = "Merchant",
            desc  = "The vendor window: item list, buyback, and bottom money bar.",
            reloadMsg = "Changing the Merchant reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinMerchant = v
            end,
            buildContent = BuildMerchantContent,
        },
        {
            key   = "auctionhouse",
            title = "Auction House",
            desc  = "The auction house: browse, sell, and my auctions views.",
            reloadMsg = "Changing the Auction House reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinAuctionHouse = v
            end,
        },
        {
            key   = "macros",
            title = "Macros",
            desc  = "The macro editor: tabs, icon grid, text well, and buttons.",
            reloadMsg = "Changing the Macros reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinMacros = v
            end,
        },
        {
            key   = "settings",
            title = "Options Panel",
            desc  = "Blizzard's options window chrome: frame, tabs, search, and category rail.",
            reloadMsg = "Changing the Options Panel reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinSettings = v
            end,
        },
        {
            key   = "addonlist",
            title = "AddOn List",
            desc  = "The addon manager: list rows, checkboxes, and buttons.",
            reloadMsg = "Changing the AddOn List reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinAddonList = v
            end,
        },
        {
            key   = "craftorders",
            title = "Crafting Orders",
            desc  = "The customer crafting orders window: browse, order form, and my orders.",
            reloadMsg = "Changing the Crafting Orders reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinCraftOrders = v
            end,
        },
        {
            key   = "trainer",
            title = "Trainer",
            desc  = "The class and profession trainer window: skill list, train button, and cost display.",
            reloadMsg = "Changing the Trainer reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinTrainer = v
            end,
        },
        {
            key   = "gossip",
            title = "Gossip",
            desc  = "The NPC dialog window: greeting text, gossip and quest options, and goodbye button.",
            reloadMsg = "Changing the Gossip reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinGossip = v
            end,
        },
        {
            key   = "quest",
            title = "Quest",
            desc  = "The NPC quest window: quest detail, progress, and reward panels plus the multi-quest greeting list.",
            reloadMsg = "Changing the Quest reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinQuest = v
            end,
        },
        {
            key   = "inspectrecipe",
            title = "Inspect Recipe",
            desc  = "The recipe preview window shown from a linked recipe or an inspected crafter.",
            reloadMsg = "Changing the Inspect Recipe reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinInspectRecipe = v
            end,
        },
        {
            key   = "delves",
            title = "Delves Companion",
            desc  = "Brann's configuration window: role and trinket slots, abilities, and the ability list.",
            reloadMsg = "Changing the Delves Companion reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinDelves = v
            end,
        },
        {
            key   = "socialui",
            title = "Friends List",
            desc  = "The Social window frame, border, title bar, Battle.net bar, search boxes, filter dropdowns and buttons. List contents and the side tab icons stay untouched.",
            reloadMsg = "Changing the Friends List reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinSocialUI = v
            end,
        },
        {
            key   = "queuestatus",
            title = "Queue Status",
            desc  = "The panel the minimap Group Finder eye shows on hover: queue titles, role icons and counts, and time in queue.",
            reloadMsg = "Changing the Queue Status reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinQueueStatus = v
            end,
        },
        {
            key   = "delvepicker",
            title = "Delve Tier Picker",
            desc  = "The delve difficulty window: tier dropdown, reward list and Enter button. The Map Properties row is left stock -- it is a Blizzard widget display and is not safe to restyle.",
            reloadMsg = "Changing the Delve Tier Picker reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinDelvePicker = v
            end,
        },
        {
            key   = "playerchoice",
            title = "Choice Windows",
            desc  = "Weekly and event choice windows such as Abundance harvests and \"how will you aid...\" pickers: option plates, headers, reward icons and buttons. Option artwork stays.",
            reloadMsg = "Changing the Choice Windows reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinPlayerChoice = v
            end,
        },
        {
            key   = "trade",
            title = "Trade",
            desc  = "The player-to-player trade window: frame, both item columns, the enchant slots, money rows and buttons. Item icons are squared and carry a rarity border. Both portraits are removed, as on every other window.",
            reloadMsg = "Changing the Trade reskin requires a UI reload to fully swap between Blizzard and Aura styles.",
            setEnabled = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.reskinTrade = v
            end,
        },
    }

    -- WoW Forever keeps Blizzard's micro menu art: its pack is not registered
    -- there (WindowPacks), so the card is not offered either.
    if AuraUI.IS_FOREVER then
        for i = #WINDOWS, 1, -1 do
            if WINDOWS[i].key == "micromenu" then table.remove(WINDOWS, i) end
        end
    end

    local function WSGetStyle(win)
        return AuraUI.GetBlizzWindowStyle(win.key)
    end

    -- Window skins a module's Style page choice overrides: while that module
    -- renders a stock style its pack stands down, so the card's style
    -- dropdown is blocked and Apply to All leaves the card alone.
    local WS_STYLE_OWNERS = { socialui = "friends" }
    local function WSStyleOwned(win)
        local owner = WS_STYLE_OWNERS[win.key]
        return owner and AuraUI.BlizzStyle and AuraUI.BlizzStyle.Get(owner) or false
    end

    -- Applies a style to one window. Returns true when the change crosses the
    -- on/off boundary (= needs a reload). suppressPopup lets Apply to All show
    -- one popup for the whole batch instead of one per window.
    local function WSSetStyle(win, style, suppressPopup)
        local old = WSGetStyle(win)
        if old == style then return false end
        if not AuraUIDB then AuraUIDB = {} end
        -- A pick here belongs to the whole UI's current look: the Style
        -- page's Apply to All saves it into that look's window slot when
        -- the look changes (AuraUI.SwapWindowSkinStyle).
        win.setEnabled(style ~= "off")
        if style ~= "off" then
            -- Remember which skin set this window uses; kept while "off" so
            -- re-enabling restores the same pick.
            if not AuraUIDB.blizzWindowSkinStyles then AuraUIDB.blizzWindowSkinStyles = {} end
            AuraUIDB.blizzWindowSkinStyles[win.key] = style
        end
        local crossed = (old == "off") ~= (style == "off")
        -- eui<->modern applies live (shell backdrops swap in place).
        if AuraUI._WSkinRefreshStyles then AuraUI._WSkinRefreshStyles() end
        if crossed and not suppressPopup then
            WSReloadPopup(win.reloadMsg)
        end
        return crossed
    end

    -- One expandable card: custom header (mini-window glyph + title + style
    -- dropdown + chevron) over a shared card background, with the window's
    -- rows below when expanded. Returns the new y cursor.
    local function BuildWindowCard(parent, y, win)
        local PP = AuraUI.PanelPP
        local EG = AuraUI.ELLESMERE_GREEN
        local L  = AuraUI.L
        local hasSettings = win.buildContent ~= nil
        local expanded = hasSettings and _wsExpanded[win.key]
        local cardTop = y
        local brd  -- whole-card border, created with the bg below (hover closure)

        -- Explicit size + single TOPLEFT anchor (the widget contract): inline
        -- search re-anchors and restores direct children through their FIRST
        -- point only, so a frame that gets its width from a second point
        -- collapses to zero width the first time a search is cleared.
        local cardW = parent:GetWidth() - (AuraUI.CONTENT_PAD - WS_CARD_INSET) * 2
        local hdr = CreateFrame("Button", nil, parent)
        PP.Size(hdr, cardW, WS_HEADER_H)
        PP.Point(hdr, "TOPLEFT", parent, "TOPLEFT", AuraUI.CONTENT_PAD - WS_CARD_INSET, y)
        hdr:SetFrameLevel(parent:GetFrameLevel() + 3)

        -- Search metadata: the header acts as its own section, so searching a
        -- window's title or description returns the card (style dropdown and
        -- all) as a result. Deep links are unaffected: they match the exact
        -- section names created inside buildContent, never this joined string.
        local searchName = win.title .. " " .. (win.desc or "")
        hdr._isSectionHeader = true
        hdr._sectionName = searchName
        local searchNameLoc = L(win.title) .. " " .. L(win.desc or "")
        if searchNameLoc ~= searchName then hdr._sectionNameLoc = searchNameLoc end

        -- Global (sidebar) search: the card header never goes through
        -- SectionHeader, so the index would otherwise have no entry for it --
        -- searching a window's title/description found it inline but not in
        -- the sidebar results. Register it with the same title + description
        -- keywords the inline pseudo-section matches (title as the display
        -- label, description via the tooltip field, which the fuzzy scorer
        -- also searches). section = the exact joined string stamped above, so
        -- a jump scrolls to and glows this header; the page's
        -- NavigateToElementSettings pre-hook expands the cards first.
        if AuraUI._RegisterSearchEntry then
            local titleLoc = L(win.title)
            local descSearch = win.desc or ""
            local descLoc = L(win.desc or "")
            if descLoc ~= descSearch then descSearch = descSearch .. " " .. descLoc end
            AuraUI._RegisterSearchEntry(win.title,
                titleLoc ~= win.title and titleLoc or nil,
                descSearch,
                AuraUI._buildingModule, AuraUI._buildingPage,
                searchName, nil, nil, true)
        end

        -- Hover wash (transparent when idle; the card bg below provides the fill)
        local hbg = AuraUI.SolidTex(hdr, "BACKGROUND", 0, 0, 0, 0)
        hbg:SetAllPoints()

        -- Procedural mini-window glyph: a tiny framed "window" with a title
        -- bar. The bar lights up in accent while the reskin is enabled, but
        -- only on cards that actually have settings.
        local glyph = CreateFrame("Frame", nil, hdr)
        PP.Size(glyph, 22, 16)
        PP.Point(glyph, "LEFT", hdr, "LEFT", 16, 0)
        local glyphBrd = AuraUI.MakeBorder(glyph, 1, 1, 1, 0.35, PP)
        local glyphBar = glyph:CreateTexture(nil, "ARTWORK")
        glyphBar:SetHeight(4)
        PP.Point(glyphBar, "TOPLEFT", glyph, "TOPLEFT", 1, -1)
        PP.Point(glyphBar, "TOPRIGHT", glyph, "TOPRIGHT", -1, -1)
        if glyphBar.SetSnapToPixelGrid then glyphBar:SetSnapToPixelGrid(false); glyphBar:SetTexelSnappingBias(0) end

        local title = AuraUI.MakeFont(hdr, 14, nil, 1, 1, 1, 0.9)
        PP.Point(title, "TOPLEFT", hdr, "TOPLEFT", 50, -12)
        title:SetText(L(win.title))

        local desc = AuraUI.MakeFont(hdr, 11, nil, 1, 1, 1, 0.42)
        PP.Point(desc, "TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        desc:SetWidth(590)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(false)
        desc:SetText(L(win.desc))

        -- Expand chevron only on cards that actually have settings; cards
        -- without any are not expandable at all.
        local chev
        if hasSettings then
            chev = hdr:CreateTexture(nil, "OVERLAY")
            PP.Size(chev, 16, 16)
            PP.Point(chev, "RIGHT", hdr, "RIGHT", -16, 0)
            chev:SetTexture(expanded and WS_ARROW_UP or WS_ARROW_DOWN)
            chev:SetAlpha(0.45)
            if expanded then chev:SetVertexColor(EG.r, EG.g, EG.b) end
        end

        -- Style dropdown: pick AuraUI / Modern / Blizz Default for this
        -- window without expanding the card.
        local dd = AuraUI.BuildDropdownControl(hdr, 148, hdr:GetFrameLevel() + 2,
            WS_STYLE_VALUES, WS_STYLE_ORDER,
            function() return WSGetStyle(win) end,
            function(v)
                WSSetStyle(win, v)
                AuraUI:RefreshPage()
            end)
        PP.Point(dd, "RIGHT", hdr, "RIGHT", -44, 0)
        local owner = WS_STYLE_OWNERS[win.key]
        if owner and AuraUI.BlizzStyle then AuraUI.BlizzStyle.BlockInline(owner, dd) end

        local strip  -- accent strip on the header's left edge (created with bg)
        local function RefreshCardState()
            local on = WSGetStyle(win) ~= "off"
            glyphBrd:SetColor(1, 1, 1, on and 0.4 or 0.2)
            -- Glyph title bar: accent is reserved for cards that have settings; windows
            -- without any keep a gray bar darker than the glyph border.
            if not hasSettings then
                glyphBar:SetColorTexture(1, 1, 1, 0.12)
            elseif on then
                glyphBar:SetColorTexture(EG.r, EG.g, EG.b, 0.85)
            else
                glyphBar:SetColorTexture(1, 1, 1, 0.2)
            end
            -- Accent edge marks cards that actually have settings; windows
            -- without any keep the faint neutral strip.
            if strip then
                if hasSettings then
                    strip:SetColorTexture(EG.r, EG.g, EG.b, 0.7)
                else
                    strip:SetColorTexture(1, 1, 1, 0.10)
                end
            end
            if dd._refreshLabel then dd._refreshLabel() end
        end

        local function ApplyHeaderHover()
            hbg:SetColorTexture(1, 1, 1, 0.05)
            title:SetAlpha(1)
            chev:SetAlpha(0.85)
            if brd then brd:SetColor(1, 1, 1, 0.22) end
        end
        local function ClearHeaderHover()
            -- Moving between the header and its dropdown fires OnLeave first;
            -- keep the row highlight while the pointer is still inside the header.
            if hdr:IsMouseOver() then return end
            hbg:SetColorTexture(0, 0, 0, 0)
            title:SetAlpha(0.9)
            chev:SetAlpha(0.45)
            if brd then brd:SetColor(1, 1, 1, expanded and 0.16 or 0.12) end
        end
        -- Cards without settings are inert: no hover wash, no click-to-expand.
        -- Their dropdown still works on its own.
        if hasSettings then
            hdr:SetScript("OnEnter", ApplyHeaderHover)
            hdr:SetScript("OnLeave", ClearHeaderHover)
            -- The dropdown keeps its own hover scripts; hook (not replace) so the
            -- full row highlight also holds while the pointer is on the dropdown.
            dd:HookScript("OnEnter", ApplyHeaderHover)
            dd:HookScript("OnLeave", ClearHeaderHover)
            hdr:SetScript("OnClick", function()
                _wsExpanded[win.key] = not _wsExpanded[win.key]
                AuraUI:RefreshPage(true)
            end)
        end

        y = y - WS_HEADER_H

        if expanded then
            -- Divider between the header and the card's settings
            local div = hdr:CreateTexture(nil, "ARTWORK")
            div:SetColorTexture(1, 1, 1, 0.07)
            div:SetHeight(1)
            PP.Point(div, "BOTTOMLEFT", hdr, "BOTTOMLEFT", 1, 0)
            PP.Point(div, "BOTTOMRIGHT", hdr, "BOTTOMRIGHT", -1, 0)
            PP.DisablePixelSnap(div)

            y = y - 8
            y = win.buildContent(parent, y)
            y = y - 8
        end

        -- Card background + border spanning the header and any expanded content. Child
        -- of the header, NOT the page wrapper: the inline search walks direct wrapper
        -- children, and as a header child the bg is never collected as a row, follows
        -- the header wherever the search re-flows it, and hides/shows with it for free.
        -- Explicitly sized because the header's own rect is the only anchor left.
        local bg = CreateFrame("Frame", nil, hdr)
        bg:SetFrameLevel(parent:GetFrameLevel())
        PP.Size(bg, cardW, cardTop - y)
        PP.Point(bg, "TOPLEFT", hdr, "TOPLEFT", 0, 0)
        local fill = AuraUI.SolidTex(bg, "BACKGROUND", 0.06, 0.08, 0.10, 0.5)
        fill:SetAllPoints()
        brd = AuraUI.MakeBorder(bg, 1, 1, 1, expanded and 0.16 or 0.12, PP)

        -- Header-height only: the strip marks the header, never the expanded
        -- settings block below it.
        strip = bg:CreateTexture(nil, "ARTWORK")
        strip:SetWidth(2)
        PP.Point(strip, "TOPLEFT", hdr, "TOPLEFT", 1, -1)
        PP.Point(strip, "BOTTOMLEFT", hdr, "BOTTOMLEFT", 1, 1)
        if strip.SetSnapToPixelGrid then strip:SetSnapToPixelGrid(false); strip:SetTexelSnappingBias(0) end

        AuraUI.RegisterWidgetRefresh(RefreshCardState)
        RefreshCardState()

        return y - WS_CARD_GAP
    end

    -- Per-profile master kill switch (the ONLY per-profile setting in this
    -- section): profile-root key disableWindowSkins, resolved live by
    -- AuraUI.BlizzWindowSkinsKilled(). Skins install at load, so every
    -- toggle shows the reload popup.
    local function WSKillSwitchSet(disabled)
        local prof = AuraUI.GetActiveProfileData()
        if not prof then return end
        prof.disableWindowSkins = disabled and true or nil
        -- Structural change (settings <-> hero takeover): force a rebuild,
        -- a plain refresh only re-reads widget values on the cached page.
        AuraUI:RefreshPage(true)
        WSReloadPopup(disabled
            and "Window skins are now disabled for this profile. A UI reload is required to restore the stock Blizzard windows."
            or "Window skins are now enabled for this profile. A UI reload is required to apply them.")
    end

    -- Feature hero shown INSTEAD of the page content while window skins are
    -- disabled for this profile: the intro popup's art (three mini windows,
    -- eyebrow, bullets) rebuilt inline, with one big Enable button.
    local function BuildWindowSkinsDisabledHero(parent, yOffset)
        local PP = AuraUI.PanelPP
        local EG = AuraUI.ELLESMERE_GREEN
        local L  = AuraUI.L
        local MakeBorder = AuraUI.MakeBorder
        local FONT = AuraUI._font or "Interface\\AddOns\\AuraUI\\media\\fonts\\Expressway.ttf"

        local HERO_H = 470
        local host = CreateFrame("Frame", nil, parent)
        PP.Size(host, parent:GetWidth() - AuraUI.CONTENT_PAD * 2, HERO_H)
        PP.Point(host, "TOPLEFT", parent, "TOPLEFT", AuraUI.CONTENT_PAD, yOffset - 24)

        -- Three mini Blizzard "windows" with colored title bars (the intro
        -- popup's header visual): center one scaled up with a resize grip.
        local CARD_W, CARD_H, CARD_GAP = 124, 52, 14
        local titleColors = {
            { EG.r, EG.g, EG.b },
            { 0.25, 0.50, 0.90 },
            { 0.64, 0.39, 0.93 },
        }
        for i = 1, 3 do
            local isCenter = (i == 2)
            local w = CARD_W
            local ch = isCenter and (CARD_H + 10) or CARD_H
            local card = CreateFrame("Frame", nil, host)
            card:SetFrameLevel(host:GetFrameLevel() + 1)
            PP.Size(card, w, ch)
            PP.Point(card, "CENTER", host, "TOP", (i - 2) * (CARD_W + CARD_GAP), -64)
            local cbg = card:CreateTexture(nil, "BACKGROUND")
            cbg:SetAllPoints()
            cbg:SetColorTexture(0.12, 0.13, 0.15, 1)
            local c = titleColors[i]
            local bar = card:CreateTexture(nil, "ARTWORK")
            bar:SetColorTexture(c[1], c[2], c[3], isCenter and 0.95 or 0.75)
            bar:SetHeight(8)
            PP.Point(bar, "TOPLEFT", card, "TOPLEFT", 1, -1)
            PP.Point(bar, "TOPRIGHT", card, "TOPRIGHT", -1, -1)
            if bar.SetSnapToPixelGrid then bar:SetSnapToPixelGrid(false); bar:SetTexelSnappingBias(0) end
            local dot = card:CreateTexture(nil, "OVERLAY")
            dot:SetColorTexture(0, 0, 0, 0.4)
            PP.Size(dot, 4, 4)
            PP.Point(dot, "RIGHT", bar, "RIGHT", -3, 0)
            local l1 = card:CreateTexture(nil, "ARTWORK")
            l1:SetColorTexture(1, 1, 1, isCenter and 0.42 or 0.32)
            PP.Size(l1, w - 26, 5)
            PP.Point(l1, "TOPLEFT", card, "TOPLEFT", 13, -18)
            local l2 = card:CreateTexture(nil, "ARTWORK")
            l2:SetColorTexture(1, 1, 1, 0.18)
            PP.Size(l2, w - 46, 5)
            PP.Point(l2, "TOPLEFT", l1, "BOTTOMLEFT", 0, -7)
            if isCenter then
                local l3 = card:CreateTexture(nil, "ARTWORK")
                l3:SetColorTexture(1, 1, 1, 0.14)
                PP.Size(l3, w - 66, 5)
                PP.Point(l3, "TOPLEFT", l2, "BOTTOMLEFT", 0, -7)
                local grip = card:CreateTexture(nil, "OVERLAY")
                grip:SetColorTexture(EG.r, EG.g, EG.b, 0.85)
                PP.Size(grip, 5, 5)
                PP.Point(grip, "BOTTOMRIGHT", card, "BOTTOMRIGHT", -2, 2)
            end
            MakeBorder(card, 1, 1, 1, isCenter and 0.16 or 0.10, PP)
        end

        local eyebrow = host:CreateFontString(nil, "OVERLAY")
        eyebrow:SetFont(FONT, 13, "")
        eyebrow:SetTextColor(EG.r, EG.g, EG.b, 0.9)
        PP.Point(eyebrow, "TOP", host, "TOP", 0, -122)
        eyebrow:SetText(L("AUI FEATURE"))

        local title = host:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT, 25, "")
        title:SetTextColor(1, 1, 1, 1)
        PP.Point(title, "TOP", eyebrow, "BOTTOM", 0, -6)
        title:SetText(L("Blizzard Window Skinning"))

        local desc = host:CreateFontString(nil, "OVERLAY")
        desc:SetFont(FONT, 15, "")
        desc:SetTextColor(1, 1, 1, 0.5)
        desc:SetWidth(430)
        desc:SetJustifyH("CENTER")
        desc:SetWordWrap(true)
        PP.Point(desc, "TOP", title, "BOTTOM", 0, -12)
        desc:SetText(L("Blizzard's windows match the AuraUI theme with a WoW 2.0 Dark Theme, from the Dungeon Journal to the Auction House and beyond."))

        local BULLETS = {
            "Every major Blizzard window themed to match AUI",
            "Recolor the theme to any color and opacity you like",
            "Scale any window larger or smaller with Shifter",
        }
        local prev
        for i, text in ipairs(BULLETS) do
            local bl = host:CreateFontString(nil, "OVERLAY")
            bl:SetFont(FONT, 14, "")
            bl:SetTextColor(1, 1, 1, 0.72)
            bl:SetJustifyH("LEFT")
            if i == 1 then
                PP.Point(bl, "TOP", host, "TOP", -20, -252)
                bl:SetPoint("LEFT", host, "CENTER", -160, 0)
            else
                PP.Point(bl, "TOPLEFT", prev, "BOTTOMLEFT", 0, -10)
            end
            bl:SetText(L(text))
            local bdot = host:CreateTexture(nil, "OVERLAY")
            bdot:SetColorTexture(EG.r, EG.g, EG.b, 1)
            PP.Size(bdot, 5, 5)
            PP.Point(bdot, "RIGHT", bl, "LEFT", -10, 0)
            prev = bl
        end

        local enableBtn = CreateFrame("Button", nil, host)
        PP.Size(enableBtn, 220, 40)
        PP.Point(enableBtn, "TOP", host, "TOP", 0, -344)
        enableBtn:SetFrameLevel(host:GetFrameLevel() + 2)
        AuraUI.MakeStyledButton(enableBtn, "Enable Window Skins", 15,
            AuraUI.WB_COLOURS, function() WSKillSwitchSet(false) end)

        local footnote = host:CreateFontString(nil, "OVERLAY")
        footnote:SetFont(FONT, 12, "")
        footnote:SetTextColor(1, 1, 1, 0.35)
        PP.Point(footnote, "TOP", enableBtn, "BOTTOM", 0, -12)
        footnote:SetText(L("Window skins are currently disabled for this profile."))

        -- Builders return the page's total HEIGHT (positive), same as the
        -- normal page's math.abs(y) tail.
        return math.abs(yOffset - 24 - HERO_H)
    end

    ---------------------------------------------------------------------------
    --  THIRD-PARTY ADDONS section: addons that registered for AUI skinning
    --  via AuraUI.RegisterSkin (SkinAPI). Deliberately independent of
    --  the per-profile kill switch and of every per-window setting -- window
    --  styles only decide WHICH theme third-party skins get -- so it renders
    --  on both the normal page and the disabled hero. Hidden entirely when
    --  no addon has registered. Skins install at load: turning a toggle ON
    --  applies live when possible, turning OFF is reload-bound.
    ---------------------------------------------------------------------------
    local function BuildThirdPartySection(parent, y)
        local W = AuraUI.Widgets
        local list = ns.GetThirdPartySkinList and ns.GetThirdPartySkinList()
        if not list or #list == 0 then return y end

        local _, h
        _, h = W:Spacer(parent, y, 10); y = y - h
        _, h = W:SectionHeader(parent, "THIRD-PARTY ADDONS", y); y = y - h

        local function MasterOff()
            return (AuraUIDB and AuraUIDB.thirdPartySkinsOff) and true or false
        end
        local function TurnedOn()
            -- Live-apply any skins that can install right now; only removal
            -- needs the reload.
            local fired = ns.TryDispatchThirdPartySkins and ns.TryDispatchThirdPartySkins()
            AuraUI:RefreshPage()
            if not fired then
                WSReloadPopup("Some addon skins could not apply live. A UI reload will fully apply them.")
            end
        end

        local items = {}
        items[1] = { type = "toggle", text = "Skin Third-Party Addons",
            tooltip = "Master switch for skinning other addons that support the AuraUI skinning API.",
            getValue = function() return not MasterOff() end,
            setValue = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.thirdPartySkinsOff = (not v) and true or nil
                if v then
                    TurnedOn()
                else
                    AuraUI:RefreshPage()
                    WSReloadPopup("Removing third-party addon skins requires a UI reload.")
                end
            end }
        for _, info in ipairs(list) do
            local name = info.name
            items[#items + 1] = { type = "toggle", text = name,
                tooltip = "Skin " .. name .. " to match the AuraUI theme.",
                disabled = MasterOff,
                disabledTooltip = "Enable Skin Third-Party Addons",
                getValue = function()
                    local t = AuraUIDB and AuraUIDB.thirdPartySkinAddons
                    return not (t and t[name] == false)
                end,
                setValue = function(v)
                    if not AuraUIDB then AuraUIDB = {} end
                    local t = AuraUIDB.thirdPartySkinAddons
                    if not t then t = {}; AuraUIDB.thirdPartySkinAddons = t end
                    if v then t[name] = nil else t[name] = false end
                    if v then
                        TurnedOn()
                    else
                        WSReloadPopup("Removing " .. name .. "'s skin requires a UI reload.")
                    end
                end }
        end
        local h2
        for i = 1, #items, 2 do
            _, h2 = W:DualRow(parent, y, items[i], items[i + 1] or { type = "label", text = "" })
            y = y - h2
        end
        return y
    end

    local function BuildWindowSkinsPage(pageName, parent, yOffset)
        local W = AuraUI.Widgets
        local PP = AuraUI.PanelPP
        local L  = AuraUI.L
        local y = yOffset
        local _, h

        parent._showRowDivider = true

        -- Per-profile kill switch takeover: while window skins are disabled
        -- for this profile, hide every setting and show the feature hero.
        -- Third-party skinning is decoupled from the kill switch, so its
        -- section stays reachable below the hero.
        if AuraUI.BlizzWindowSkinsKilled and AuraUI.BlizzWindowSkinsKilled() then
            local heroH = BuildWindowSkinsDisabledHero(parent, yOffset)
            local y2 = BuildThirdPartySection(parent, -heroH)
            return math.abs(y2)
        end

        _, h = W:Spacer(parent, y, 14);  y = y - h

        -- Hosted on a sized frame (not a raw region on the wrapper) so the
        -- inline search hides it while filtering and restores it on clear;
        -- regions are invisible to the search and would float over results.
        local introHost = CreateFrame("Frame", nil, parent)
        PP.Size(introHost, parent:GetWidth() - AuraUI.CONTENT_PAD * 2, 20)
        PP.Point(introHost, "TOPLEFT", parent, "TOPLEFT", AuraUI.CONTENT_PAD, y)
        local intro = AuraUI.MakeFont(introHost, 13, nil, 1, 1, 1, 0.5)
        PP.Point(intro, "TOP", introHost, "TOP", 0, 0)
        intro:SetText(L("Pick a style for all reskinned Blizzard windows."))

        -- Per-profile master switch (top right; the only per-profile setting
        -- in this section). One step below Blizz Default: no-ops the whole
        -- window engine + CharacterSheet/Inspect + LFG skinning. Reload-bound.
        local disBtn = CreateFrame("Button", nil, introHost)
        PP.Size(disBtn, 160, 24)
        PP.Point(disBtn, "RIGHT", introHost, "RIGHT", 0, 0)
        disBtn:SetFrameLevel(introHost:GetFrameLevel() + 3)
        AuraUI.MakeStyledButton(disBtn, "Disable Window Skins", 11,
            AuraUI.WB_COLOURS, function() WSKillSwitchSet(true) end)
        disBtn:HookScript("OnEnter", function(s)
            AuraUI.ShowWidgetTooltip(s, L("Turns off ALL window skinning for this profile. Requires a reload."))
        end)
        disBtn:HookScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

        y = y - 28

        -- Set-all row: pick a style, then push it to every window below. The
        -- swatch + cog edit the GLOBAL Modern background (windows without a
        -- per-window override follow it).
        local allDD = AuraUI.BuildDropdownControl(parent, 170, parent:GetFrameLevel() + 3,
            WS_STYLE_VALUES, WS_STYLE_ORDER,
            function() return _wsApplyAllStyle end,
            function(v)
                _wsApplyAllStyle = v
                AuraUI:RefreshPage()
            end)
        PP.Point(allDD, "TOPLEFT", parent, "TOP", -115, y)
        allDD._ttText = "Style to apply to every window below."
        AttachModernSwatch(parent, allDD)

        local applyBtn = CreateFrame("Button", nil, parent)
        PP.Size(applyBtn, 110, 30)
        PP.Point(applyBtn, "LEFT", allDD, "RIGHT", 10, 0)
        applyBtn:SetFrameLevel(parent:GetFrameLevel() + 3)
        AuraUI.MakeStyledButton(applyBtn, "Apply to All", 12, AuraUI.WB_COLOURS, function()
            local crossed = false
            for _, win in ipairs(WINDOWS) do
                if not WSStyleOwned(win) and WSSetStyle(win, _wsApplyAllStyle, true) then crossed = true end
            end
            AuraUI:RefreshPage()
            if crossed then
                WSReloadPopup("Changing window skin styles requires a UI reload to fully apply.")
            end
        end)
        y = y - 30 - 26

        -- GLOBAL OPTIONS: look settings shared by every reskinned window.
        _, h = W:SectionHeader(parent, "GLOBAL OPTIONS", y); y = y - h

        local gRow1
        gRow1, h = W:DualRow(parent, y,
            { type = "toggle", text = "Show Accent Bar",
              tooltip = "Accent bar on the active tab of reskinned windows.",
              getValue = function()
                  local c = WSLook("blizzWinAccentBar")
                  return not (c and c.enabled == false)
              end,
              setValue = function(v)
                  WSLookSet("blizzWinAccentBar", "enabled", v and true or false)
              end },
            { type = "slider", text = "Bar Fill Opacity",
              min = 10, max = 100, step = 1,
              getValue = function()
                  local c = WSLook("blizzWinBarFill")
                  return math.floor(((c and c.alpha) or 0.95) * 100 + 0.5)
              end,
              setValue = function(v) WSLookSet("blizzWinBarFill", "alpha", v / 100) end })
        if not AuraUI._prebuilding then
        AttachLookSwatches(gRow1._leftRegion, gRow1, "blizzWinAccentBar")
        AttachLookSwatches(gRow1._rightRegion, gRow1, "blizzWinBarFill")
        end
        y = y - h

        _, h = W:DualRow(parent, y,
            { type = "multiSwatch", text = "Link Color",
              swatches = {
                  { tooltip = "Accent Color",
                    getValue = function()
                        return AuraUI.ResolveActiveAccent()
                    end,
                    setValue = function() end,
                    onClick = function()
                        WSLookSet("blizzWinLinks", "useCustom", false)
                        AuraUI:RefreshPage()
                    end,
                    refreshAlpha = function()
                        local c = WSLook("blizzWinLinks")
                        return (c and c.useCustom) and 0.3 or 1
                    end },
                  { tooltip = "Custom Color",
                    getValue = function()
                        local c = WSLook("blizzWinLinks")
                        local col = c and c.color
                        if col then return col.r or 1, col.g or 1, col.b or 1 end
                        return 1, 1, 1
                    end,
                    setValue = function(r, g, b)
                        WSLookSet("blizzWinLinks", "color", { r = r, g = g, b = b })
                        WSLookSet("blizzWinLinks", "useCustom", true)
                        AuraUI:RefreshPage()
                    end,
                    onClick = function(self)
                        local c = WSLook("blizzWinLinks")
                        if not (c and c.useCustom) then
                            WSLookSet("blizzWinLinks", "useCustom", true)
                            AuraUI:RefreshPage()
                            return
                        end
                        if self._eabOrigClick then self._eabOrigClick(self) end
                    end,
                    refreshAlpha = function()
                        local c = WSLook("blizzWinLinks")
                        return (c and c.useCustom) and 1 or 0.3
                    end },
              } },
            { type = "label", text = "" })
        y = y - h

        -- Breathing room between the global settings and the window cards.
        y = y - 30

        -- Cards with their own settings content (buildContent) sit at the top of the
        -- list, keeping their relative order; plain style-only cards follow in theirs.
        -- WINDOWS itself stays in its defined order -- the apply-all and reset loops
        -- don't care, and new entries keep being added by category there.
        local ordered = {}
        for _, win in ipairs(WINDOWS) do
            if win.buildContent then ordered[#ordered + 1] = win end
        end
        for _, win in ipairs(WINDOWS) do
            if not win.buildContent then ordered[#ordered + 1] = win end
        end
        for _, win in ipairs(ordered) do
            y = BuildWindowCard(parent, y, win)
        end

        y = BuildThirdPartySection(parent, y)

        _, h = W:Spacer(parent, y, 20);  y = y - h
        return math.abs(y)
    end

    ---------------------------------------------------------------------------
    --  Dragon Riding page
    ---------------------------------------------------------------------------
    local function EDR_DB()
        return ns.edrDB and ns.edrDB.profile
    end
    local function EDR_Cfg(k) local p = EDR_DB(); return p and p[k] end
    local function EDR_Set(k, v) local p = EDR_DB(); if p then p[k] = v end end
    local function EDR_SetField(k, field, v)
        local t = EDR_Cfg(k); if t then t[field] = v end
    end
    local function EDR_Rebuild() if ns.edrRebuild then ns.edrRebuild() end
        AuraUI:RefreshPage()
    end
    local function EDR_Redraw() if ns.edrRedraw then ns.edrRedraw() end end

    -------------------------------------------------------------------
    --  Bar texture dropdown tables (shared media path, same as ERB)
    -------------------------------------------------------------------
    local EDR_BAR_TEXTURES = ns.EDR_BAR_TEXTURES
    local _, EDR_BAR_TEXTURE_NAMES, EDR_BAR_TEXTURE_ORDER =
        AuraUI.BuildBarTextureTables()

    local function BuildDragonRidingPage(pageName, parent, yOffset)
        local W = AuraUI.Widgets
        local y = yOffset
        local _, h

        if AuraUI.ClearContentHeader then AuraUI:ClearContentHeader() end
        parent._showRowDivider = true

        -- Append SharedMedia textures (safe to call multiple times)
        AuraUI.AppendSharedMediaTextures(
            EDR_BAR_TEXTURE_NAMES,
            EDR_BAR_TEXTURE_ORDER,
            nil,
            EDR_BAR_TEXTURES
        )
        local edrTexValues = {}
        local edrTexOrder  = {}
        for _, key in ipairs(EDR_BAR_TEXTURE_ORDER) do
            if key ~= "---" then
                edrTexValues[key] = EDR_BAR_TEXTURE_NAMES[key] or key
                edrTexOrder[#edrTexOrder + 1] = key
            end
        end
        edrTexValues._menuOpts = {
            itemHeight = 28,
            background = function(key) return EDR_BAR_TEXTURES[key] end,
        }

        local justifyValues = { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }
        local justifyOrder  = { "LEFT", "CENTER", "RIGHT" }

        -- The bar art is chosen on Global Settings > Style ("Skyriding HUD")
        -- and latched for the session like every other module's style, so
        -- the rows below are laid out for the look the HUD renders.
        local BS = AuraUI.BlizzStyle
        local edrStyle = BS.Active("dragonriding")

        _, h = W:SectionHeader(parent, "GENERAL", y); y = y - h
        y = BS.Note(parent, y, "dragonriding")
        _, h = W:DualRow(parent, y,
            { type = "toggle", text = "Enable Dragon Riding Bar",
              getValue = function() return EDR_Cfg("enabled") == true end,
              -- DependentSetValue: everything below Row 1 is hidden while the
              -- bar is off; the flip forces the full rebuild.
              setValue = AuraUI.DependentSetValue(
                  function() return EDR_Cfg("enabled") == true end,
                  function(v) EDR_Set("enabled", v); EDR_Rebuild() end) },
            { type = "toggle", text = "Hide in Combat",
              disabled = function() return EDR_Cfg("enabled") ~= true end,
              disabledTooltip = "Dragon Riding Bar",
              getValue = function() return EDR_Cfg("hideInCombat") == true end,
              setValue = function(v) EDR_Set("hideInCombat", v); EDR_Rebuild() end }
        ); y = y - h

        -- Everything below Row 1 (the rest of GENERAL plus the LAYOUT and
        -- SPEED BAR sections) is HIDDEN entirely while the bar is off.
        if EDR_Cfg("enabled") == true then
        local function EDR_IsGems() return EDR_Cfg("vigorStyle") == "gems" end
        local function EDR_ShowSpeed() return EDR_Cfg("showSpeed") ~= false end
        local function EDR_ShowSW() return EDR_Cfg("showSecondWind") ~= false end
        local function EDR_WSOff() return EDR_Cfg("showWhirlingSurge") == false end
        -- The icon's automatic size, in the Icon Size slider's range.
        local function EDR_AutoIconSize()
            local v = math.floor(((ns.edrIconSize and ns.edrIconSize()) or 34) + 0.5)
            return math.max(16, math.min(80, v))
        end

        -- The parts the HUD shows. The speed bar's and Second Wind's own
        -- rows exist only while they are shown, so those two rebuild the page.
        _, h = W:DualRow(parent, y,
            { type = "toggle", text = "Show Speed Bar",
              getValue = EDR_ShowSpeed,
              setValue = AuraUI.DependentSetValue(EDR_ShowSpeed,
                  function(v) EDR_Set("showSpeed", v); EDR_Rebuild() end) },
            { type = "toggle", text = "Show Second Wind",
              getValue = EDR_ShowSW,
              setValue = AuraUI.DependentSetValue(EDR_ShowSW,
                  function(v) EDR_Set("showSecondWind", v); EDR_Rebuild() end) }
        ); y = y - h
        local wsRow
        wsRow, h = W:DualRow(parent, y,
            { type = "toggle", text = "Show Whirling Surge",
              getValue = function() return not EDR_WSOff() end,
              setValue = function(v) EDR_Set("showWhirlingSurge", v); EDR_Rebuild() end },
            { type = "toggle", text = "Show Icon Cooldown Text",
              disabled = EDR_WSOff, disabledTooltip = "Show Whirling Surge",
              getValue = function() return EDR_Cfg("whirlingSurgeText") and EDR_Cfg("whirlingSurgeText").enabled ~= false end,
              setValue = function(v) EDR_SetField("whirlingSurgeText", "enabled", v); EDR_Redraw() end }
        ); y = y - h
        -- Icon size: automatic (as tall as the bars) while Auto Size is on;
        -- turning it off hands the slider the current automatic size.
        if not AuraUI._prebuilding then
            AuraUI.BuildInlineCog(wsRow._leftRegion, {
                icon = AuraUI.RESIZE_ICON,
                title = "Whirling Surge Icon",
                disabled = EDR_WSOff, disabledTooltip = "Show Whirling Surge",
                rows = {
                    { type = "toggle", label = "Auto Size",
                      tooltip = "Keeps the icon as tall as the bars.",
                      get = function() return EDR_Cfg("iconSize") == nil end,
                      set = function(v)
                          if v then
                              EDR_Set("iconSize", nil)
                          else
                              EDR_Set("iconSize", EDR_AutoIconSize())
                          end
                          EDR_Rebuild()
                      end },
                    { type = "slider", label = "Icon Size", min = 16, max = 80, step = 1,
                      disabled = function() return EDR_Cfg("iconSize") == nil end,
                      disabledTooltip = "Auto Size", requireState = "disabled",
                      get = function() return EDR_Cfg("iconSize") or EDR_AutoIconSize() end,
                      set = function(v) EDR_Set("iconSize", v); EDR_Rebuild() end },
                },
            })
        end
        -- Classic Gems replaces the charge row with Blizzard's original gems
        -- (the page rebuilds: the Charge row and the gem scale follow it).
        -- The cog holds the full-charge chime and, for the gems, their scale.
        local vigorRow
        vigorRow, h = W:DualRow(parent, y,
            { type = "dropdown", text = "Vigor Style",
              values = { bars = "Bars", gems = "Classic Gems" },
              order  = { "bars", "gems" },
              tooltip = "Classic Gems brings back Blizzard's original vigor display above the bars.",
              getValue = function() return EDR_Cfg("vigorStyle") or "bars" end,
              setValue = AuraUI.DependentSetValue(EDR_IsGems,
                  function(v) EDR_Set("vigorStyle", v); EDR_Rebuild() end) },
            { type = "slider", pixel = true, text = "Stack Spacing", min = 0, max = 10, step = 1,
              -- The gap between pips: nothing to space with no pip row shown.
              disabled = function() return EDR_IsGems() and not EDR_ShowSW() end,
              disabledTooltip = "This option requires the Bars vigor style or Show Second Wind",
              getValue = function() return EDR_Cfg("stackSpacing") end,
              setValue = function(v) EDR_Set("stackSpacing", v); EDR_Rebuild() end }
        ); y = y - h
        if not AuraUI._prebuilding then
            local vigorRows = {
                { type = "toggle", label = "Play Sound on Full Charge",
                  tooltip = "Plays Blizzard's vigor chime each time a skyriding charge fills.",
                  get = function() return EDR_Cfg("chargeSound") == true end,
                  set = function(v) EDR_Set("chargeSound", v) end },
            }
            if EDR_IsGems() then
                vigorRows[2] = { type = "slider", label = "Gem Scale", min = 0.5, max = 2.0, step = 0.05,
                    get = function() return EDR_Cfg("classicScale") or 1 end,
                    set = function(v) EDR_Set("classicScale", v); EDR_Rebuild() end }
            end
            AuraUI.BuildInlineCog(vigorRow._leftRegion, { title = "Vigor", rows = vigorRows })
        end
        _, h = W:DualRow(parent, y,
            { type = "slider", text = "Width", min = 80, max = 600, step = 1,
              getValue = function() return EDR_Cfg("width") end,
              setValue = function(v) EDR_Set("width", v); EDR_Rebuild() end },
            { type = "slider", pixel = true, text = "Element Spacing", min = 0, max = 12, step = 1,
              getValue = function() return EDR_Cfg("gap") end,
              setValue = function(v) EDR_Set("gap", v); EDR_Rebuild() end }
        ); y = y - h
        -- Border Size: the AuraUI border and its colour on the
        -- AuraUI look; under Classic WoW UI the slot sizes the vanilla
        -- frame, as the Resource Bars' Border Size does; Blizzard Style's
        -- panel has no size to set.
        local borderCfg
        if edrStyle == "classic" then
            borderCfg = BS.ClassicBorderSizeCfg(
                function() return EDR_Cfg("classicFrameSize") end,
                function(v) EDR_Set("classicFrameSize", v); EDR_Rebuild() end)
        else
            borderCfg = BS.Gate("dragonriding",
                { type = "slider", text = "Border Size", min = 0, max = 4, step = 1,
                  getValue = function() return EDR_Cfg("borderThickness") or 0 end,
                  setValue = function(v)
                      EDR_Set("borderThickness", v); EDR_Redraw()
                      AuraUI:RefreshPage()
                  end })
        end
        local borderRow
        borderRow, h = W:DualRow(parent, y, borderCfg,
            { type = "dropdown", text = "Bar Texture",
              values = edrTexValues, order = edrTexOrder,
              getValue = function() return EDR_Cfg("barTexture") or "none" end,
              setValue = function(v) EDR_Set("barTexture", v); EDR_Redraw() end }
        ); y = y - h
        if not AuraUI._prebuilding and edrStyle == "eui" then
            local rgn = borderRow._leftRegion
            local ctrl = rgn._control
            local swatch, updateSwatch = AuraUI.BuildColorSwatch(
                rgn, borderRow:GetFrameLevel() + 3,
                function() local t = EDR_Cfg("borderColor"); return t.r, t.g, t.b, t.a end,
                function(r, g, b, a) local p = EDR_Cfg("borderColor"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                true, 20)
            AuraUI.PanelPP.Point(swatch, "RIGHT", ctrl, "LEFT", -8, 0)
            rgn._lastInline = swatch
            -- No border to colour at size 0: dimmed and blocked.
            local block = CreateFrame("Frame", nil, swatch)
            block:SetAllPoints()
            block:SetFrameLevel(swatch:GetFrameLevel() + 10)
            block:EnableMouse(true)
            block:SetScript("OnEnter", function()
                AuraUI.ShowWidgetTooltip(swatch, AuraUI.DisabledTooltip("This option requires a Border Size above 0."))
            end)
            block:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)
            local function UpdateSwatchState()
                if (EDR_Cfg("borderThickness") or 0) == 0 then
                    swatch:SetAlpha(0.3); block:Show()
                else
                    swatch:SetAlpha(1); block:Hide()
                end
            end
            AuraUI.RegisterWidgetRefresh(function() updateSwatch(); UpdateSwatchState() end)
            UpdateSwatchState()
        end
        _, h = W:Spacer(parent, y, 20); y = y - h

        -- Charge and Second Wind rows, each only while its part is shown
        -- (Classic Gems replaces the charge row); no section without either.
        local showCharges, showSW = not EDR_IsGems(), EDR_ShowSW()
        if showCharges or showSW then
            _, h = W:SectionHeader(parent, "LAYOUT", y); y = y - h
            if showCharges then
                _, h = W:DualRow(parent, y,
                    { type = "slider", text = "Charge Height", min = 2, max = 24, step = 1,
                      getValue = function() return EDR_Cfg("skyridingHeight") end,
                      setValue = function(v) EDR_Set("skyridingHeight", v); EDR_Rebuild() end },
                    { type = "multiSwatch", text = "Charge Color",
                      swatches = {
                        { text = "Background",
                          getValue = function() local t = EDR_Cfg("skyridingBg"); return t.r, t.g, t.b, t.a end,
                          setValue = function(r, g, b, a) local p = EDR_Cfg("skyridingBg"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                          hasAlpha = true,
                          tooltip = "Background" },
                        { text = "Stacks",
                          getValue = function() local t = EDR_Cfg("skyridingFilled"); return t.r, t.g, t.b, t.a end,
                          setValue = function(r, g, b, a) local p = EDR_Cfg("skyridingFilled"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                          hasAlpha = true,
                          tooltip = "Charges" },
                      } }
                ); y = y - h
            end
            if showSW then
                _, h = W:DualRow(parent, y,
                    { type = "slider", text = "Second Wind Height", min = 2, max = 24, step = 1,
                      getValue = function() return EDR_Cfg("secondWindHeight") end,
                      setValue = function(v) EDR_Set("secondWindHeight", v); EDR_Rebuild() end },
                    { type = "multiSwatch", text = "Second Wind Color",
                      swatches = {
                        { text = "Background",
                          getValue = function() local t = EDR_Cfg("secondWindBg"); return t.r, t.g, t.b, t.a end,
                          setValue = function(r, g, b, a) local p = EDR_Cfg("secondWindBg"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                          hasAlpha = true,
                          tooltip = "Background" },
                        { text = "Second Wind",
                          getValue = function() local t = EDR_Cfg("secondWindFilled"); return t.r, t.g, t.b, t.a end,
                          setValue = function(r, g, b, a) local p = EDR_Cfg("secondWindFilled"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                          hasAlpha = true,
                          tooltip = "Second Wind" },
                      } }
                ); y = y - h
            end
            _, h = W:Spacer(parent, y, 20); y = y - h
        end

        -- The speed bar's own section only while the bar is shown.
        if EDR_ShowSpeed() then
        _, h = W:SectionHeader(parent, "SPEED BAR", y); y = y - h
        _, h = W:DualRow(parent, y,
            { type = "slider", text = "Height", min = 4, max = 40, step = 1,
              getValue = function() return EDR_Cfg("speedHeight") end,
              setValue = function(v) EDR_Set("speedHeight", v); EDR_Rebuild() end },
            { type = "toggle", text = "Thrill Color Change",
              getValue = function() return EDR_Cfg("thrillColorToggle") == true end,
              setValue = function(v) EDR_Set("thrillColorToggle", v); EDR_Redraw() end }
        ); y = y - h
        _, h = W:DualRow(parent, y,
            { type = "multiSwatch", text = "Speed Color",
              swatches = {
                { text = "Background",
                  getValue = function() local t = EDR_Cfg("speedBarBg"); return t.r, t.g, t.b, t.a end,
                  setValue = function(r, g, b, a) local p = EDR_Cfg("speedBarBg"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                  hasAlpha = true,
                  tooltip = "Background" },
                { text = "Speed",
                  getValue = function() local t = EDR_Cfg("normalColor"); return t.r, t.g, t.b, t.a end,
                  setValue = function(r, g, b, a) local p = EDR_Cfg("normalColor"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                  hasAlpha = true,
                  tooltip = "Speed" },
              } },
            { type = "multiSwatch", text = "Thrill Color",
              swatches = {
                { text = "Hash",
                  getValue = function() local t = EDR_Cfg("tickColor"); return t.r, t.g, t.b, t.a end,
                  setValue = function(r, g, b, a) local p = EDR_Cfg("tickColor"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                  hasAlpha = true,
                  tooltip = "Hash Marker" },
                { text = "Thrill",
                  getValue = function() local t = EDR_Cfg("thrillColor"); return t.r, t.g, t.b, t.a end,
                  setValue = function(r, g, b, a) local p = EDR_Cfg("thrillColor"); p.r, p.g, p.b, p.a = r, g, b, a; EDR_Redraw() end,
                  hasAlpha = true,
                  tooltip = "Thrill" },
              } }
        ); y = y - h
        local speedTextRow
        speedTextRow, h = W:DualRow(parent, y,
            { type = "toggle", text = "Show Speed Text",
              getValue = function() return EDR_Cfg("speedText") and EDR_Cfg("speedText").enabled ~= false end,
              setValue = function(v) EDR_SetField("speedText", "enabled", v); EDR_Redraw() end },
            { type = "dropdown", text = "Text Align",
              values = justifyValues, order = justifyOrder,
              getValue = function() return (EDR_Cfg("speedText") or {}).justify or "CENTER" end,
              setValue = function(v) EDR_SetField("speedText", "justify", v); EDR_Redraw() end }
        )
        if not AuraUI._prebuilding then
        AuraUI.BuildInlineCog(speedTextRow._rightRegion, {
            icon = AuraUI.RESIZE_ICON,
            title = "Speed Text Position",
            rows = {
                { type = "slider", label = "Size",     min = 6,    max = 32,  step = 1,
                  get = function() return (EDR_Cfg("speedText") or {}).size    or 12 end,
                  set = function(v) EDR_SetField("speedText", "size",    v); EDR_Redraw() end },
                { type = "slider", label = "Offset X", min = -200, max = 200, step = 1,
                  get = function() return (EDR_Cfg("speedText") or {}).offsetX or 0  end,
                  set = function(v) EDR_SetField("speedText", "offsetX", v); EDR_Redraw() end },
                { type = "slider", label = "Offset Y", min = -200, max = 200, step = 1,
                  get = function() return (EDR_Cfg("speedText") or {}).offsetY or 0  end,
                  set = function(v) EDR_SetField("speedText", "offsetY", v); EDR_Redraw() end },
            },
        })
        end
        y = y - h
        _, h = W:Spacer(parent, y, 20); y = y - h
        end -- Show Speed Bar
        end   -- close Dragon Riding hidden-while-disabled gate

        -- The wrapper is SetAllPoints-anchored, so SetHeight on it is inert;
        -- return the measured height so the scroll range is correct.
        return math.abs(y)
    end

    AuraUI:RegisterModule("AuraUIBlizzardSkin", {
        title       = "Blizz UI Enhanced",
        -- WoW Forever has no skyriding: the Dragon Riding tab is not registered there
        -- (its resident file returns at load, so the page would have no DB to read).
        description = AuraUI.IS_FOREVER and "Themed Blizzard frames: window skins, tooltips, menus, popups."
            or "Themed Blizzard frames: window skins, tooltips, menus, popups, Dragon Riding HUD.",
        searchTerms = "blizzard skin character sheet tooltip menu popup dragon riding skyriding window skins lfg group finder premade queue pause game menu great vault inspect collections mounts pets toys spellbook talents adventure guide encounter journal professions guild communities calendar achievements mail catalyst gem socket item upgrade upgrades crest loot window loot toast you received popup micro menu modern delves companion brann loot roll need greed pass disenchant loot rolls pending rolls group invite invited to a group role",
        pages       = AuraUI.IS_FOREVER and { PAGE_WINDOWSKINS, PAGE_TOOLTIPS }
            or { PAGE_WINDOWSKINS, PAGE_TOOLTIPS, PAGE_DRAGONRIDING },
        buildPage   = function(pageName, parent, yOffset)
            if pageName == PAGE_WINDOWSKINS then
                return BuildWindowSkinsPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_TOOLTIPS then
                return BuildTooltipsPage(pageName, parent, yOffset)
            end
            if pageName == PAGE_DRAGONRIDING then
                return BuildDragonRidingPage(pageName, parent, yOffset)
            end
        end,
        onReset = function()
            if AuraUIDragonRidingDB then
                AuraUIDragonRidingDB.profiles = nil
                AuraUIDragonRidingDB.profileKeys = nil
            end
            -- Per-profile master kill switch: reset re-enables skins for the
            -- ACTIVE profile (other profiles keep their own choice).
            do
                local prof = AuraUI.GetActiveProfileData()
                if prof then prof.disableWindowSkins = nil end
            end
            if AuraUIDB then
                -- NOTE: these account-global keys also travel in profile exports via
                -- BLIZZ_SKIN_GLOBAL_KEYS in AuraUI_Profiles.lua (the "Window &
                -- Tooltip Skins" include). A new account-global setting on the Window
                -- Skins or Tooltips, Menus & Popups tab must be added to BOTH lists.
                AuraUIDB.thirdPartySkinsOff = nil
                AuraUIDB.thirdPartySkinAddons = nil
                AuraUIDB.customTooltips = nil
                AuraUIDB.reskinPopupsMenus = nil
                AuraUIDB.accentReskinElements = nil
                AuraUIDB.tooltipPlayerTitles = nil
                AuraUIDB.tooltipFontScale = nil
                AuraUIDB.tooltipMythicScore = nil
                AuraUIDB.tooltipAnchorCursor = nil
                AuraUIDB.tooltipCursorPosition = nil
                AuraUIDB.tooltipCursorOffsetX = nil
                AuraUIDB.tooltipCursorOffsetY = nil
                AuraUIDB.tooltipFixedPos = nil  -- stale key from the account-global build
                -- Per-profile fixed tooltip position: clearing it re-seeds from
                -- Blizzard's CURRENT Edit Mode spot on the next tooltip show.
                do
                    local prof = AuraUI.GetActiveProfileData()
                    if prof then prof.tooltipFixedPos = nil end
                end
                AuraUIDB.uberTooltips = nil
                AuraUIDB.uberTooltipsManual = nil
                AuraUIDB.tooltipHideHealthStrip = nil
                AuraUIDB.showItemMaxStacks = nil
                AuraUIDB.itemStackModifier = nil
                AuraUIDB.tooltipShowGuildRank = nil
                AuraUIDB.tooltipShowMount = nil
                AuraUIDB.tooltipShowTarget = nil
                AuraUIDB.reskinQueuePopup = nil
                AuraUIDB.resurrectAcceptGlow = nil
                -- Clear any glow on a currently visible popup (the setting
                -- just went nil = off; hooks stay installed but inert).
                if AuraUI._EnsureResurrectGlow then AuraUI._EnsureResurrectGlow() end
                AuraUIDB.reskinGameMenu = nil
                AuraUIDB.popupMenuButtonBackgroundColor=nil
                AuraUIDB.popupMenuButtonTextColorMode=nil
                AuraUIDB.popupMenuButtonTextColor=nil
                for _,prefix in ipairs({"popupMenu","popupMenuButton","tooltip"}) do
                    for _,suffix in ipairs({"BorderTexture","BorderThickness","BorderThicknessPx","BorderColor","BorderColorMode","BorderOpacity","BorderOffsetX","BorderOffsetY","BorderShiftX","BorderShiftY","BorderBehind"}) do
                        AuraUIDB[prefix..suffix]=nil
                    end
                end
                -- Legacy numeric key the tooltip Border Size still falls back
                -- to when tooltipBorderThickness is unset.
                AuraUIDB.tooltipBorderSize = nil
                if AuraUI.SyncAuraTooltipSkin then AuraUI.SyncAuraTooltipSkin() end
                AuraUIDB.reskinGreatVault = nil
                AuraUIDB.reskinLFGMenu = nil
                AuraUIDB.showQueueTimer = nil
                AuraUIDB.queueTimerTextColor = nil
                AuraUIDB.queueTimerTextSize = nil
                AuraUIDB.queueTimerBarHeight = nil
                AuraUIDB.queueTimerTextOffsetY = nil
                AuraUIDB.blizzWindowSkinStyles = nil
                AuraUIDB.blizzWindowModernBG = nil
                AuraUIDB.blizzWindowModernDefault = nil
                AuraUIDB.blizzWinAccentBar = nil
                AuraUIDB.blizzWinBarFill = nil
                AuraUIDB.blizzWinLinks = nil
                AuraUIDB.reskinCollections = nil
                AuraUIDB.reskinPlayerSpells = nil
                AuraUIDB.reskinAdventureGuide = nil
                AuraUIDB.reskinProfessionsBook = nil
                AuraUIDB.reskinGuild = nil
                AuraUIDB.reskinCalendar = nil
                AuraUIDB.reskinAchievements = nil
                AuraUIDB.reskinMail = nil
                AuraUIDB.reskinCatalyst = nil
                AuraUIDB.reskinSocket = nil
                AuraUIDB.reskinItemUpgrade = nil
                AuraUIDB.reskinLoot = nil
                AuraUIDB.reskinLootToast = nil
                AuraUIDB.reskinBNetToast = nil
                AuraUIDB.lootToastQualityStrip = nil
                AuraUIDB.lootToastQualityStripMoney = nil
                AuraUIDB.lootToastScale = nil
                AuraUIDB.reskinLootRoll = nil
                AuraUIDB.reskinLootHistory = nil
                AuraUIDB.reskinGroupInvite = nil
                AuraUIDB.reskinReadyCheck = nil
                AuraUIDB.reskinMicroMenu = nil
                AuraUIDB.reskinHousing = nil
                AuraUIDB.reskinProfessions = nil
                AuraUIDB.reskinWorldMap = nil
                AuraUIDB.reskinDressUp = nil
                AuraUIDB.reskinTransmog = nil
                AuraUIDB.reskinMerchant = nil
                AuraUIDB.reskinAuctionHouse = nil
                AuraUIDB.reskinMacros = nil
                AuraUIDB.reskinSettings = nil
                AuraUIDB.reskinAddonList = nil
                AuraUIDB.reskinCraftOrders = nil
                AuraUIDB.reskinTrainer = nil
                AuraUIDB.reskinGossip = nil
                AuraUIDB.reskinQuest = nil
                AuraUIDB.reskinInspectRecipe = nil
                AuraUIDB.reskinDelves = nil
                AuraUIDB.reskinSocialUI = nil
                AuraUIDB.reskinQueueStatus = nil
                AuraUIDB.reskinDelvePicker = nil
                AuraUIDB.reskinPlayerChoice = nil
                AuraUIDB.reskinTrade = nil
                AuraUIDB.windowSkinsStockSeeded = nil
                AuraUIDB.windowSkinStyleSlots = nil
                AuraUIDB.reskinWidgetBars = nil
                AuraUIDB.widgetBarMinSize = nil
                AuraUIDB.reskinExtraActionButton = nil
                AuraUIDB.lfgRememberRoles = nil
                AuraUIDB.lfgSavedRoles = nil
                AuraUIDB.showMythicRating = nil
                AuraUIDB.showPvpItemLevel = nil
                AuraUIDB.flyoutItemLevels = nil
                AuraUIDB.showCharSheetDurability = nil
                AuraUIDB.charSheetDurabilityLocation = nil
                AuraUIDB.charSheetDurabilityShowLabel = nil
                AuraUIDB.statCategoryColors = nil
                AuraUIDB.statSectionsOrder = nil
                AuraUIDB.charSheetCollapsedSections = nil
                -- Character Sheet style (the Style page row): per profile,
                -- so only the active profile's, like the kill switch; the
                -- module latches it per session, so the reset lands at the
                -- reload. Root copies are moved onto profiles at load, so
                -- they are cleared too.
                do
                    local prof = AuraUI.GetActiveProfileData()
                    if prof then
                        prof.charSheetUseBlizzardStyle = nil
                        prof.charSheetUseClassicStyle = nil
                        prof.charSheetUseForeverStyle = nil
                    end
                end
                AuraUIDB.charSheetUseBlizzardStyle = nil
                AuraUIDB.charSheetUseClassicStyle = nil
                AuraUIDB.charSheetBlizzColors = nil
                AuraUIDB.characterFramePos = nil
                AuraUIDB.friendsFramePos = nil
            end
            if AuraUI._applyTooltipCursorAnchor then AuraUI._applyTooltipCursorAnchor() end
            if AuraUI._applyTooltipFixedAnchor then AuraUI._applyTooltipFixedAnchor() end
            if AuraUI._applyTooltipHealthStrip then AuraUI._applyTooltipHealthStrip() end
        end,
    })

    -- Deep links (What's New, search) into the Window Skins page target rows
    -- that only exist while a card is expanded. Pre-hook: expand every card and
    -- drop the page cache so the nav's SelectPage cold-builds with all rows
    -- present before it resolves the section/highlight.
    local origNav = AuraUI.NavigateToElementSettings
    if origNav then
        function AuraUI:NavigateToElementSettings(moduleName, pageName, sectionName, preSelectFn, highlightText)
            if moduleName == "AuraUIBlizzardSkin" and pageName == PAGE_WINDOWSKINS
               and (sectionName or highlightText) then
                local changed = false
                for _, win in ipairs(WINDOWS) do
                    if not _wsExpanded[win.key] then
                        _wsExpanded[win.key] = true
                        changed = true
                    end
                end
                if changed and AuraUI.InvalidatePageCache then
                    AuraUI:InvalidatePageCache()
                end
            end
            return origNav(self, moduleName, pageName, sectionName, preSelectFn, highlightText)
        end
    end

    SLASH_EBSK1 = "/ebsk"
    SlashCmdList.EBSK = function()
        if InCombatLockdown and InCombatLockdown() then return end
        AuraUI:ShowModule("AuraUIBlizzardSkin")
    end
end)
-- LoadOnDemand: this addon loads after PLAYER_LOGIN, so the event above will never fire; run the init now.
if IsLoggedIn() then initFrame:GetScript("OnEvent")(initFrame) end
