if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
if not (AuraUI and AuraUI.IS_FOREVER) then return end -- Forever Essentials loads on WoW Forever only
-------------------------------------------------------------------------------
--  AUI_ForeverEssentials_Travel_Options.lua
--  Builds the "Travel" page inside the Forever Essentials module.
-------------------------------------------------------------------------------
if not AuraUI._ModuleNS["AuraUIForeverEssentials"] then return end  -- module disabled: no options page

local TEXT_SIDES = { none = "None", left = "Left", center = "Center", right = "Right" }
local TEXT_SIDE_ORDER = { "none", "left", "center", "right" }

_G._AUI_BuildFlightTimerPage = function(pageName, parent, yOffset)
    local W = AuraUI.Widgets
    local PP = AuraUI.PP
    local FT = AuraUI._FlightTimer
    local y = yOffset
    local _, h
    parent._showRowDivider = true

    local function off()
        return not FT.Get("enabled")
    end
    local function Set(key, v)
        FT.Cfg()[key] = v
        FT.ApplyStyle()
    end

    local function TextCogRows(prefix)
        return {
            { type = "slider", label = "Text Size", min = 8, max = 24, step = 1,
              get = function() return FT.Get(prefix .. "Size") end,
              set = function(v) Set(prefix .. "Size", v) end },
            { type = "slider", label = "X Offset", min = -100, max = 100, step = 1,
              get = function() return FT.Get(prefix .. "X") end,
              set = function(v) Set(prefix .. "X", v) end },
            { type = "slider", label = "Y Offset", min = -100, max = 100, step = 1,
              get = function() return FT.Get(prefix .. "Y") end,
              set = function(v) Set(prefix .. "Y", v) end },
        }
    end

    ---------------------------------------------------------------------------
    --  GENERAL
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "FLIGHT TIMER", y);  y = y - h

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Enable Flight Timer",
          tooltip = "Shows a bar with the time left while you ride a flight path.",
          getValue = function() return not off() end,
          setValue = function(v)
              FT.Cfg().enabled = v
              FT.Apply()
              AuraUI:RefreshPage()
          end },
        { type = "labeledButton", text = "Preview", buttonText = "Show Bar",
          disabled = off,
          disabledTooltip = "Flight Timer",
          onClick = function() FT.Preview() end }
    );  y = y - h

    _, h = W:DualRow(parent, y,
        { type = "labeledButton", text = "Learned Flight Speed", buttonText = "Reset",
          tooltip = "Flight time estimates get more accurate with each flight you finish.",
          disabled = function() return FT.Get("speed") == nil end,
          onClick = function()
              AuraUI:ShowConfirmPopup({
                  title = "Reset Learned Flight Speed",
                  message = "Flight times go back to the starting estimate.",
                  confirmText = "Reset",
                  cancelText = "Cancel",
                  onConfirm = function()
                      FT.Cfg().speed = nil
                      AuraUI:RefreshPage()
                  end,
              })
          end },
        { type = "label", text = "" }
    );  y = y - h

    _, h = W:Spacer(parent, y, 20);  y = y - h

    ---------------------------------------------------------------------------
    --  LAYOUT
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "LAYOUT", y);  y = y - h

    _, h = W:DualRow(parent, y,
        { type = "slider", text = "Width", min = 50, max = 800, step = 1,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("width") end,
          setValue = function(v) Set("width", v) end },
        { type = "slider", text = "Height", min = 4, max = 60, step = 1,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("height") end,
          setValue = function(v) Set("height", v) end }
    );  y = y - h

    _, h = W:Spacer(parent, y, 20);  y = y - h

    ---------------------------------------------------------------------------
    --  DISPLAY
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "DISPLAY", y);  y = y - h

    local texValues, texOrder = {}, {}
    do
        local t = FT.textures
        AuraUI.AppendSharedMediaTextures(t.names, t.order, nil, t.lookup)
        for _, key in ipairs(t.order) do
            if key ~= "---" then texValues[key] = t.names[key] or key end
            texOrder[#texOrder + 1] = key
        end
    end

    local borderRow
    borderRow, h = W:DualRow(parent, y,
        { type = "slider", text = "Border Size", min = 0, max = 4, step = 1,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("borderSize") end,
          setValue = function(v) Set("borderSize", v); AuraUI:RefreshPage() end },
        { type = "dropdown", text = "Bar Texture", values = texValues, order = texOrder,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("texture") end,
          setValue = function(v) Set("texture", v) end }
    );  y = y - h
    if not AuraUI._prebuilding then
        AuraUI.BuildInlineSwatches(borderRow._leftRegion, {
            { tooltip = "Border Color",
              -- Nothing to colour at size 0 (the slider + inline swatch pattern).
              disabled = function() return off() or FT.Get("borderSize") == 0 end,
              disabledTooltip = function() return off() and "Flight Timer" or "Border Size" end,
              getValue = function() return FT.Get("borderR"), FT.Get("borderG"), FT.Get("borderB"), 1 end,
              setValue = function(r, g, b)
                  local c = FT.Cfg()
                  c.borderR, c.borderG, c.borderB = r, g, b
                  FT.ApplyStyle()
              end },
        }, { disabled = off, disabledTooltip = "Flight Timer" })
    end

    local colorRow
    colorRow, h = W:DualRow(parent, y,
        { type = "slider", text = "Fill Color", min = 0, max = 100, step = 1, trackWidth = 120,
          tooltip = "Opacity of the bar fill.",
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("fillOpacity") end,
          setValue = function(v) Set("fillOpacity", v) end },
        { type = "slider", text = "Background", min = 0, max = 100, step = 1,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return math.floor(FT.Get("bgA") * 100 + 0.5) end,
          setValue = function(v) Set("bgA", v / 100) end }
    );  y = y - h
    if not AuraUI._prebuilding then
        AuraUI.BuildInlineSwatches(colorRow._leftRegion, {
            { tooltip = "Custom Colored",
              getValue = function()
                  local fr = FT.Get("fillR")
                  if fr then return fr, FT.Get("fillG"), FT.Get("fillB"), 1 end
                  local EG = AuraUI.ELLESMERE_GREEN
                  return EG.r, EG.g, EG.b, 1
              end,
              setValue = function(r, g, b)
                  local c = FT.Cfg()
                  c.fillR, c.fillG, c.fillB = r, g, b
                  c.classColored = false
                  FT.ApplyStyle(); AuraUI:RefreshPage()
              end,
              onClick = function(self)
                  if FT.Get("classColored") then
                      Set("classColored", false); AuraUI:RefreshPage()
                      return
                  end
                  if self._eabOrigClick then self._eabOrigClick(self) end
              end,
              refreshAlpha = function() return FT.Get("classColored") and 0.3 or 1 end },
            { tooltip = "Class Colored",
              getValue = function()
                  local _, classFile = UnitClass("player")
                  local cc = classFile and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classFile]
                  if cc then return cc.r, cc.g, cc.b, 1 end
                  return 1, 1, 1, 1
              end,
              setValue = function() end,
              onClick = function()
                  Set("classColored", true); AuraUI:RefreshPage()
              end,
              refreshAlpha = function() return FT.Get("classColored") and 1 or 0.3 end },
        }, { disabled = off, disabledTooltip = "Flight Timer" })
    end

    local textRow
    textRow, h = W:DualRow(parent, y,
        { type = "dropdown", text = "Destination Text", values = TEXT_SIDES, order = TEXT_SIDE_ORDER,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("destText") end,
          setValue = function(v) Set("destText", v); AuraUI:RefreshPage() end },
        { type = "dropdown", text = "Time Text", values = TEXT_SIDES, order = TEXT_SIDE_ORDER,
          disabled = off, disabledTooltip = "Flight Timer",
          getValue = function() return FT.Get("timeText") end,
          setValue = function(v) Set("timeText", v); AuraUI:RefreshPage() end }
    );  y = y - h
    AuraUI.BuildInlineCog(textRow._leftRegion, { title = "Destination Text Settings", rows = TextCogRows("dest"),
        icon = AuraUI.DIRECTIONS_ICON, gap = 9, disabledTooltip = "Destination Text",
        disabled = function() return off() or FT.Get("destText") == "none" end })
    AuraUI.BuildInlineCog(textRow._rightRegion, { title = "Time Text Settings", rows = TextCogRows("time"),
        icon = AuraUI.DIRECTIONS_ICON, gap = 9, disabledTooltip = "Time Text",
        disabled = function() return off() or FT.Get("timeText") == "none" end })

    do
        local fontValues, fontOrder = AuraUI.BuildFontDropdownData()
        local outlineValues = {
            ["__global"] = { text = "AUI Global Default" },
            ["none"]     = { text = "Drop Shadow" },
            ["outline"]  = { text = "Outline" },
            ["thick"]    = { text = "Thick Outline" },
        }
        _, h = W:DualRow(parent, y,
            { type = "dropdown", text = "Font", values = fontValues, order = fontOrder,
              disabled = off, disabledTooltip = "Flight Timer",
              getValue = function() return FT.Get("font") end,
              setValue = function(v) Set("font", v) end },
            { type = "dropdown", text = "Font Outline", values = outlineValues,
              order = { "__global", "none", "outline", "thick" },
              disabled = off, disabledTooltip = "Flight Timer",
              getValue = function() return FT.Get("outlineMode") end,
              setValue = function(v) Set("outlineMode", v) end }
        );  y = y - h
    end

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Show Total Time",
          tooltip = "Shows the full flight time next to the time left, for example 1:23 / 4:19.",
          disabled = function() return off() or FT.Get("timeText") == "none" end,
          disabledTooltip = "Time Text",
          getValue = function() return FT.Get("showTotal") end,
          setValue = function(v) FT.Cfg().showTotal = v end },
        { type = "label", text = "" }
    );  y = y - h

    return math.abs(y)
end
