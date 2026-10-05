if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
if not (AuraUI and AuraUI.IS_FOREVER) then return end -- Forever Essentials loads on WoW Forever only
-------------------------------------------------------------------------------
--  AUI_ForeverEssentials_Loot_Options.lua
--  Builds the "Loot" page inside the Forever Essentials module.
--  Shows options for loot feed styles, row sizes, filters, and live preview.
-------------------------------------------------------------------------------
if not AuraUI._ModuleNS["AuraUIForeverEssentials"] then return end -- module disabled: no options page

local module = AuraUI._ModuleNS["AuraUIForeverEssentials"]
local LF = module and module.LootFeed

local STYLE_VALUES = {
    accent = "Accent Bar",
    tray   = "Icon Tray",
    toast  = "Loot Toast",
    box    = "Box",
}
local STYLE_ORDER = { "accent", "tray", "toast", "box" }

local QUALITY_VALUES = {
    [0] = "Poor (All Items)",
    [1] = "Common (White+)",
    [2] = "Uncommon (Green+)",
    [3] = "Rare (Blue+)",
    [4] = "Epic (Purple+)",
}
local QUALITY_ORDER = { 0, 1, 2, 3, 4 }

_G._AUI_BuildLootFeedPage = function(pageName, parent, yOffset)
    local W = AuraUI.Widgets
    local y = yOffset
    local _, h
    parent._showRowDivider = true

    if not LF then
        LF = module and module.LootFeed
    end

    local function off()
        return not (LF and LF.Get("enabled"))
    end

    local function Set(key, v)
        if not LF then return end
        LF.Cfg()[key] = v
        LF.Apply()
    end

    -- Run looping preview while the Loot page is open so style choices show live.
    if LF and LF.StartLoopPreview then
        LF.StartLoopPreview()
    end
    if not parent._auiLootFeedCleanupsHooked then
        parent._auiLootFeedCleanupsHooked = true
        parent:HookScript("OnHide", function()
            if LF and LF.StopLoopPreview then LF.StopLoopPreview() end
        end)
        if AuraUI.RegisterOnHide then
            AuraUI:RegisterOnHide(function()
                if LF and LF.StopLoopPreview then LF.StopLoopPreview() end
            end)
        end
    end

    ---------------------------------------------------------------------------
    --  LOOT FEED GENERAL
    ---------------------------------------------------------------------------
    _, h = W:SectionHeader(parent, "LOOT FEED", y); y = y - h

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Enable Loot Feed",
          tooltip = "Shows loot and gains as short animated rows that fade out.",
          getValue = function() return not off() end,
          setValue = function(v)
              if not LF then return end
              LF.Cfg().enabled = v
              LF.Apply()
              if v and LF.StartLoopPreview then
                  LF.StartLoopPreview()
              elseif not v and LF.StopLoopPreview then
                  LF.StopLoopPreview()
              end
              AuraUI:RefreshPage()
          end },
        { type = "dropdown", text = "Feed Style",
          tooltip = "Visual appearance of feed rows.",
          values = STYLE_VALUES, order = STYLE_ORDER,
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("style") or "accent" end,
          setValue = function(v)
              Set("style", v)
              AuraUI:RefreshPage()
          end }
    ); y = y - h

    _, h = W:DualRow(parent, y,
        { type = "slider", text = "Width", min = 150, max = 500, step = 5,
          tooltip = "Width of loot rows.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("width") or 260 end,
          setValue = function(v) Set("width", v) end },
        { type = "slider", text = "Row Height", min = 20, max = 50, step = 1,
          tooltip = "Height of each loot row.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("rowHeight") or 28 end,
          setValue = function(v) Set("rowHeight", v) end }
    ); y = y - h

    _, h = W:DualRow(parent, y,
        { type = "slider", text = "Fade Duration (sec)", min = 2, max = 10, step = 0.5,
          tooltip = "How long rows remain before fading away.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("fadeTime") or 4.0 end,
          setValue = function(v) Set("fadeTime", v) end },
        { type = "toggle", text = "Grow Upwards",
          tooltip = "New loot appears at the bottom and pushes older rows up.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("growUp") or false end,
          setValue = function(v) Set("growUp", v) end }
    ); y = y - h

    ---------------------------------------------------------------------------
    --  CONTENT FILTERS
    ---------------------------------------------------------------------------
    _, h = W:Spacer(parent, y, 12); y = y - h
    _, h = W:SectionHeader(parent, "TRACKED GAINS", y); y = y - h

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Track Items",
          tooltip = "Show item loot in feed.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("showItems") or false end,
          setValue = function(v) Set("showItems", v) end },
        { type = "dropdown", text = "Minimum Item Quality",
          tooltip = "Lowest item quality to display in the feed.",
          values = QUALITY_VALUES, order = QUALITY_ORDER,
          disabled = function() return off() or not (LF and LF.Get("showItems")) end,
          disabledTooltip = "Item Tracking",
          getValue = function() return LF and LF.Get("minQuality") or 0 end,
          setValue = function(v) Set("minQuality", v) end }
    ); y = y - h

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Track Money",
          tooltip = "Show copper, silver, and gold looted.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("showMoney") or false end,
          setValue = function(v) Set("showMoney", v) end },
        { type = "toggle", text = "Track Reputation",
          tooltip = "Show reputation increases.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("showRep") or false end,
          setValue = function(v) Set("showRep", v) end }
    ); y = y - h

    _, h = W:DualRow(parent, y,
        { type = "toggle", text = "Track Currencies",
          tooltip = "Show currency token gains.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("showCurrency") or false end,
          setValue = function(v) Set("showCurrency", v) end },
        { type = "toggle", text = "Track Skill Ups",
          tooltip = "Show profession and skill level increases.",
          disabled = off, disabledTooltip = "Loot Feed",
          getValue = function() return LF and LF.Get("showSkills") or false end,
          setValue = function(v) Set("showSkills", v) end }
    ); y = y - h

    return math.abs(y)
end
