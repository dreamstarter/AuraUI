if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AUI_PartyMode_Options.lua
--  Party Mode options page for AuraUI
--  Shared across all AuraUI addons — only the first to load runs.
--  DEFERRED: body runs on first AuraUI:EnsureLoaded() call, not at load.
-------------------------------------------------------------------------------
if _G._AuraUIPartyModeOptionsLoaded then return end
_G._AuraUIPartyModeOptionsLoaded = true

local AuraUI = _G.AuraUI
AuraUI._deferredInits[#AuraUI._deferredInits + 1] = function()

-- EnsureLoaded runs after PLAYER_LOGIN, so execute the init body directly.
do

    if not AuraUI or not AuraUI.RegisterModule then return end
    local PP = AuraUI.PanelPP

    local PAGE_PARTY = "Party Mode"

    ---------------------------------------------------------------------------
    --  Build the Party Mode page
    ---------------------------------------------------------------------------
    local function BuildPartyModePage(pageName, parent, yOffset)
        local W = AuraUI.Widgets
        local y = yOffset
        local _, h

        -------------------------------------------------------------------
        --  Activate / Deactivate button
        -------------------------------------------------------------------
        local activateBtnFrame, activateBtnLbl
        activateBtnFrame, h = W:WideButton(parent,
            (AuraUIDB and AuraUIDB.partyMode) and "Deactivate Party Mode" or "Activate Party Mode",
            y,
            function()
                if AuraUI_TogglePartyMode then AuraUI_TogglePartyMode() end
                -- Update label after toggle
                if activateBtnLbl then
                    activateBtnLbl:SetText(
                        (AuraUIDB and AuraUIDB.partyMode) and AuraUI.L("Deactivate Party Mode") or AuraUI.L("Activate Party Mode")
                    )
                end
            end
        );  y = y - h
        -- Grab the label FontString from the button child
        if not AuraUI._prebuilding then
            local btn = select(1, activateBtnFrame:GetChildren())
            if btn then
                for i = 1, btn:GetNumRegions() do
                    local rgn = select(i, btn:GetRegions())
                    if rgn and rgn.GetText and rgn:GetText() then
                        activateBtnLbl = rgn
                        break
                    end
                end
            end
        end
        -- Keep label in sync if toggled via keybind while panel is open
        if activateBtnLbl then
            AuraUI.RegisterWidgetRefresh(function()
                activateBtnLbl:SetText(
                    (AuraUIDB and AuraUIDB.partyMode) and AuraUI.L("Deactivate Party Mode") or AuraUI.L("Activate Party Mode")
                )
            end)
        end

        -------------------------------------------------------------------
        --  PARTY MODE (disco lights overlay)
        -------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "PARTY MODE", y);  y = y - h

        -- Row 1: Toggle Keybind (full-width custom row)
        do
            local ROW_H = 50
            local SIDE_PAD = 20
            local kbFrame = CreateFrame("Frame", nil, parent)
            local totalW = parent:GetWidth() - AuraUI.CONTENT_PAD * 2
            PP.Size(kbFrame, totalW, ROW_H)
            PP.Point(kbFrame, "TOPLEFT", parent, "TOPLEFT", AuraUI.CONTENT_PAD, y)
            AuraUI.RowBg(kbFrame, parent)

            local label = AuraUI.MakeFont(kbFrame, 14, nil, AuraUI.TEXT_WHITE_R, AuraUI.TEXT_WHITE_G, AuraUI.TEXT_WHITE_B)
            PP.Point(label, "LEFT", kbFrame, "LEFT", SIDE_PAD, 0)
            label:SetText(AuraUI.L("Toggle On/Off Keybind"))

            local kbBtn, refresh = AuraUI.BuildKeybindButton(kbFrame, {
                w = 140, h = 30, font = 13,
                get = function() return AuraUIDB and AuraUIDB.partyModeKey end,
                set = function(fullKey)
                    if not AuraUIDB then AuraUIDB = {} end
                    if fullKey then
                        ClearOverrideBindings(AuraUIPartyModeBindBtn)
                        SetOverrideBindingClick(AuraUIPartyModeBindBtn, true, fullKey, "AuraUIPartyModeBindBtn")
                    elseif AuraUIDB.partyModeKey then
                        ClearOverrideBindings(AuraUIPartyModeBindBtn)
                    end
                    AuraUIDB.partyModeKey = fullKey
                end,
            })
            PP.Point(kbBtn, "RIGHT", kbFrame, "RIGHT", -SIDE_PAD, 0)
            AuraUI.RegisterWidgetRefresh(refresh)

            y = y - ROW_H
        end

        -- Row 2: Brightness slider (full-width)
        do
            local ROW_H = 50
            local SIDE_PAD = 20
            local frame = CreateFrame("Frame", nil, parent)
            local totalW = parent:GetWidth() - AuraUI.CONTENT_PAD * 2
            PP.Size(frame, totalW, ROW_H)
            PP.Point(frame, "TOPLEFT", parent, "TOPLEFT", AuraUI.CONTENT_PAD, y)
            AuraUI.RowBg(frame, parent)

            local label = AuraUI.MakeFont(frame, 14, nil, AuraUI.TEXT_WHITE_R, AuraUI.TEXT_WHITE_G, AuraUI.TEXT_WHITE_B)
            PP.Point(label, "LEFT", frame, "LEFT", SIDE_PAD, 0)
            label:SetText(AuraUI.L("Brightness"))

            local function briGet()
                local db = AuraUIDB
                local v = db and db.partyModeBrightness
                if v == nil then v = 0.65 end
                return math.floor(v * 100 + 0.5)
            end
            local function briSet(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.partyModeBrightness = v / 100
            end

            local trackFrame, valBox = AuraUI.BuildSliderCore(frame, 160, 4, 14, 40, 26, 13, AuraUI.SL_INPUT_A,
                0, 100, 1, briGet, briSet, false)
            PP.Point(valBox, "RIGHT", frame, "RIGHT", -SIDE_PAD, 0)
            PP.Point(trackFrame, "RIGHT", valBox, "LEFT", -12, 0)

            y = y - ROW_H
        end

        -- Row 3: Dim the Lights While Active (toggle)
        _, h = W:Toggle(parent, "Dim the Lights While Active", y,
            function() return AuraUIDB and (AuraUIDB.partyModeDimLights ~= false) end,
            function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.partyModeDimLights = v
                -- Live apply/restore if party mode is currently active
                if AuraUIDB.partyMode then
                    if v and not AuraUI_IsDimLightsActive() then
                        AuraUI_ApplyDimLights()
                    elseif not v and AuraUI_IsDimLightsActive() then
                        AuraUI_RestoreDimLights()
                    end
                end
            end,
            nil
        );  y = y - h

        -- Row 3b: Spinning (checkbox dropdown + speed cog). Full-width row
        -- (nil right slot expands the left region), matching the rest of
        -- this section. Each target's spin lives in its own module; this page
        -- owns only the shared AuraUIDB keys, so a target whose addon is
        -- disabled is a harmless no-op. partyModeSpinBars is a boolean (Action
        -- Bars only) or a per-target table: AuraUI.PartySpinOn reads
        -- both and AuraUI.PartySpinSet turns a boolean into the table on
        -- its first write, with the same meaning. One speed drives every target.
        do
            local SPIN_ITEMS = {
                { key = "actionBars", label = "Action Bars" },
                { key = "dataBars",   label = "Data Bars" },
                { key = "unitFrames", label = "Unit Frames" },
                { key = "resource",   label = "Resource Bars" },
                { key = "power",      label = "Power Bars" },
            }
            local spinRow
            spinRow, h = W:DualRow(parent, y,
                { type="dropdown", text="Spinning",
                  tooltip="Slowly orbits the checked elements while Party Mode is active; they stay upright and pause in combat.",
                  values={ ["_placeholder"]="..." }, order={ "_placeholder" },
                  getValue=function() return "_placeholder" end,
                  setValue=function() end },
                nil
            );  y = y - h
            if not AuraUI._prebuilding then
                local rgn = spinRow._leftRegion
                if rgn._control then rgn._control:Hide() end
                local cbDD, cbDDRefresh = AuraUI.BuildVisOptsCBDropdown(
                    rgn, 200, rgn:GetFrameLevel() + 2,
                    SPIN_ITEMS,
                    -- The setting itself, whether or not Party Mode is on.
                    function(k) return AuraUI.PartySpinOn(k, true) end,
                    function(k, v)
                        AuraUI.PartySpinSet(k, v)
                        AuraUI.PartySpin_RefreshAll()
                    end)
                PP.Point(cbDD, "RIGHT", rgn, "RIGHT", -20, 0)
                rgn._control = cbDD
                rgn._lastInline = nil
                AuraUI.RegisterWidgetRefresh(cbDDRefresh)
                AuraUI.BuildInlineCog(rgn, {
                    title = "Spin",
                    rows = {
                        { type="slider", label="Speed", min=0, max=720, step=10,
                          tooltip="Degrees per second. 360 is one full turn a second; 0 parks the bars where they are.",
                          get=function()
                              local v = AuraUIDB and AuraUIDB.partyModeSpinSpeed
                              if v == nil then v = 120 end
                              return v
                          end,
                          set=function(v)
                              if not AuraUIDB then AuraUIDB = {} end
                              AuraUIDB.partyModeSpinSpeed = v
                              AuraUI.PartySpin_RefreshAll()
                          end },
                    },
                })
            end
        end

        -- Row 4: Play Sound on Party Mode (dropdown; shares the whisper
        -- alert catalogue incl. SharedMedia, with per-item preview icons)
        do
            local sndPaths, sndNames, sndOrder = {}, { none = "None" }, { "none" }
            if AuraUI_GetPartyModeSounds then
                sndPaths, sndNames, sndOrder = AuraUI_GetPartyModeSounds()
            end
            -- Shallow-copy the shared names table so _menuOpts (preview
            -- icon) doesn't pollute it.
            local sndValues = {}
            for k, v in pairs(sndNames) do sndValues[k] = v end
            sndValues._menuOpts = {
                itemHeight = 26,
                maxTextWidthPct = 0.8,
                searchable = true,
                iconAtlas = function(key)
                    if key == "none" then return nil end
                    if not sndPaths[key] then return nil end
                    return "common-icon-sound"
                end,
                iconPressedAtlas = function(key)
                    if key == "none" then return nil end
                    return "common-icon-sound-pressed"
                end,
                iconOnClick = function(key)
                    local path = sndPaths[key]
                    if path then PlaySoundFile(path, "Master") end
                end,
                iconTooltip = function() return "Preview Sound" end,
            }
            _, h = W:Dropdown(parent, "Play Sound on Party Mode", y, sndValues,
                function() return (AuraUIDB and AuraUIDB.partyModeSoundKey) or "none" end,
                function(v)
                    if not AuraUIDB then AuraUIDB = {} end
                    AuraUIDB.partyModeSoundKey = v
                end,
                sndOrder)
            y = y - h
        end

        -------------------------------------------------------------------
        --  CELEBRATION TRIGGERS
        -------------------------------------------------------------------
        _, h = W:SectionHeader(parent, "CELEBRATION TRIGGERS", y);  y = y - h

        -- Helper: set a trigger DB key and refresh widgets
        local function TriggerSet(key)
            return function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB[key] = v
                local rl = AuraUI._widgetRefreshList
                if rl then for i = 1, #rl do rl[i]() end end
            end
        end
        local function TriggerGet(key)
            return function() return AuraUIDB and AuraUIDB[key] or false end
        end

        local CB_SPLITS = { 0.333, 0.333, 0.334, rowHeight = 36 }
        local randomlyCheckbox = { type = "checkbox", text = "Randomly", getValue = TriggerGet("partyModeTriggerRandom"), setValue = function(v)
            if not AuraUIDB then AuraUIDB = {} end
            AuraUIDB.partyModeTriggerRandom = v
            if v then
                AuraUI_StartRandomTrigger()
            else
                AuraUI_StopRandomTrigger()
            end
            local rl = AuraUI._widgetRefreshList
            if rl then for i = 1, #rl do rl[i]() end end
        end }
        -- Bloodlust is debuff-triggered with a hardcoded 40s celebration; it is
        -- intentionally NOT wired into the Auto Celebration Duration slider, so
        -- it has its own setValue rather than the shared TriggerSet.
        local bloodlustCheckbox = { type = "checkbox", text = "Bloodlust",
            getValue = TriggerGet("partyModeTriggerBloodlust"),
            setValue = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.partyModeTriggerBloodlust = v
                if AuraUI_UpdatePartyModeLustListener then AuraUI_UpdatePartyModeLustListener() end
                local rl = AuraUI._widgetRefreshList
                if rl then for i = 1, #rl do rl[i]() end end
            end }
        local levelUpCheckbox = { type = "checkbox", text = "Level Up",
            getValue = TriggerGet("partyModeTriggerLevelUp"),
            setValue = function(v)
                if not AuraUIDB then AuraUIDB = {} end
                AuraUIDB.partyModeTriggerLevelUp = v
                if AuraUI_UpdatePartyModeLevelUpListener then AuraUI_UpdatePartyModeLevelUpListener() end
                local rl = AuraUI._widgetRefreshList
                if rl then for i = 1, #rl do rl[i]() end end
            end }

        if AuraUI.IS_FOREVER then
            -- WoW Forever has no keystones, no rated PvP and no Mythic, Heroic or
            -- Raid Finder difficulties, and its vanilla raids report difficulty 9 or
            -- 148, which no boss kill trigger maps. Show only what can fire there.
            _, h = W:TripleRow(parent, y,
                randomlyCheckbox, bloodlustCheckbox, levelUpCheckbox,
                CB_SPLITS
            );  y = y - h
        else
            -- Row 1: Randomly | Timed Keystone | Mythic Boss Kill
            _, h = W:TripleRow(parent, y,
                randomlyCheckbox,
                { type = "checkbox", text = "Timed Keystone",     getValue = TriggerGet("partyModeTriggerKeystone"),   setValue = TriggerSet("partyModeTriggerKeystone") },
                { type = "checkbox", text = "Mythic Boss Kill",   getValue = TriggerGet("partyModeTriggerMythicBoss"), setValue = TriggerSet("partyModeTriggerMythicBoss") },
                CB_SPLITS
            );  y = y - h

            -- Row 2: Rated Arena Win | Rated BG Win | Heroic Boss Kill
            _, h = W:TripleRow(parent, y,
                { type = "checkbox", text = "Rated Arena Win",    getValue = TriggerGet("partyModeTriggerRatedArena"), setValue = TriggerSet("partyModeTriggerRatedArena") },
                { type = "checkbox", text = "Rated BG Win",       getValue = TriggerGet("partyModeTriggerRatedBG"),    setValue = TriggerSet("partyModeTriggerRatedBG") },
                { type = "checkbox", text = "Heroic Boss Kill",   getValue = TriggerGet("partyModeTriggerHeroicBoss"), setValue = TriggerSet("partyModeTriggerHeroicBoss") },
                CB_SPLITS
            );  y = y - h

            -- Row 3: Normal Boss Kill | Raid Finder Boss Kill | Mythic 0 Completion
            _, h = W:TripleRow(parent, y,
                { type = "checkbox", text = "Normal Boss Kill",       getValue = TriggerGet("partyModeTriggerNormalBoss"),  setValue = TriggerSet("partyModeTriggerNormalBoss") },
                { type = "checkbox", text = "Raid Finder Boss Kill",  getValue = TriggerGet("partyModeTriggerLFRBoss"),     setValue = TriggerSet("partyModeTriggerLFRBoss") },
                { type = "checkbox", text = "Mythic 0 Completion",    getValue = TriggerGet("partyModeTriggerMythic0"),     setValue = TriggerSet("partyModeTriggerMythic0") },
                CB_SPLITS
            );  y = y - h

            -- Row 4: Bloodlust | Level Up
            _, h = W:TripleRow(parent, y,
                bloodlustCheckbox, levelUpCheckbox, nil,
                CB_SPLITS
            );  y = y - h
        end

        -- Bottom border for the checkbox grid (matches SectionHeader separator style)
        -- Placed 1px above current y so the next row's background doesn't cover it
        do
            local totalW = parent:GetWidth() - AuraUI.CONTENT_PAD * 2
            local sep = parent:CreateTexture(nil, "ARTWORK", nil, 7)
            sep:SetColorTexture(AuraUI.BORDER_R, AuraUI.BORDER_G, AuraUI.BORDER_B, 0.02)
            PP.Size(sep, totalW, 1)
            PP.Point(sep, "TOPLEFT", parent, "TOPLEFT", AuraUI.CONTENT_PAD, y + 1)
        end

        -- Celebration Trigger Duration slider (conditionally enabled)
        local durFrame
        do
            local function AnyCelebrationTriggerEnabled()
                if not AuraUIDB then return false end
                return AuraUIDB.partyModeTriggerKeystone
                    or AuraUIDB.partyModeTriggerMythicBoss
                    or AuraUIDB.partyModeTriggerHeroicBoss
                    or AuraUIDB.partyModeTriggerNormalBoss
                    or AuraUIDB.partyModeTriggerLFRBoss
                    or AuraUIDB.partyModeTriggerMythic0
                    or AuraUIDB.partyModeTriggerRatedBG
                    or AuraUIDB.partyModeTriggerRatedArena
                    or AuraUIDB.partyModeTriggerLevelUp
                    or AuraUIDB.partyModeTriggerRandom
                    or false
            end

            durFrame, h = W:Slider(parent, "Auto Celebration Duration", y, 10, 60, 1,
                function()
                    local db = AuraUIDB
                    local v = db and db.partyModeMPlusDuration
                    if v == nil then v = 30 end
                    return v
                end,
                function(v)
                    if not AuraUIDB then AuraUIDB = {} end
                    AuraUIDB.partyModeMPlusDuration = v
                end,
                nil
            );  y = y - h

            -- Add "(seconds)" suffix in smaller, dimmer text
            if not AuraUI._prebuilding then
                local suffix = durFrame:CreateFontString(nil, "OVERLAY")
                suffix:SetFont(AuraUI.EXPRESSWAY, 11, "")
                suffix:SetTextColor(1, 1, 1, 0.35)
                local durLabel
                for i = 1, durFrame:GetNumRegions() do
                    local reg = select(i, durFrame:GetRegions())
                    if reg and reg.GetText and AuraUI.EnKey(reg:GetText()) == "Auto Celebration Duration" then
                        durLabel = reg
                        break
                    end
                end
                if durLabel then
                    -- Anchor to the END OF THE TEXT, not the region's right
                    -- edge: ClampRowLabel stretches full-width row labels to
                    -- the slider track, so "RIGHT" sits at the track edge.
                    suffix:SetPoint("LEFT", durLabel, "LEFT", durLabel:GetStringWidth() + 5, 0)
                else
                    suffix:SetPoint("LEFT", durFrame, "LEFT", 250, 0)
                end
                suffix:SetText(AuraUI.L("(seconds)"))
            end

            local function RefreshDurDisabled()
                local enabled = AnyCelebrationTriggerEnabled()
                durFrame:SetAlpha(enabled and 1 or 0.35)
                durFrame:EnableMouse(enabled)
            end
            RefreshDurDisabled()
            AuraUI.RegisterWidgetRefresh(RefreshDurDisabled)

            -- Disabled tooltip for duration slider (split: label zone + control zone)
            if not AuraUI._prebuilding then
                -- Find the label and slider control regions
                local durLabel, durControl
                for i = 1, durFrame:GetNumRegions() do
                    local reg = select(i, durFrame:GetRegions())
                    if reg and reg.GetText and AuraUI.EnKey(reg:GetText()) == "Auto Celebration Duration" then
                        durLabel = reg
                        break
                    end
                end

                -- Label hit zone (left half)
                local durHitLabel = CreateFrame("Frame", nil, durFrame)
                durHitLabel:SetFrameLevel(durFrame:GetFrameLevel() + 10)
                durHitLabel:EnableMouse(false)
                if durLabel then
                    durHitLabel:SetPoint("TOPLEFT", durFrame, "TOPLEFT", 0, 0)
                    durHitLabel:SetPoint("BOTTOMLEFT", durFrame, "BOTTOMLEFT", 0, 0)
                    durHitLabel:SetWidth(durFrame:GetWidth() * 0.5)
                end
                durHitLabel:SetScript("OnEnter", function(self)
                    if not AnyCelebrationTriggerEnabled() then
                        AuraUI.ShowWidgetTooltip(self, AuraUI.DisabledTooltip("at least one Celebration Trigger"))
                    end
                end)
                durHitLabel:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

                -- Control hit zone (right half)
                local durHitControl = CreateFrame("Frame", nil, durFrame)
                durHitControl:SetFrameLevel(durFrame:GetFrameLevel() + 10)
                durHitControl:EnableMouse(false)
                durHitControl:SetPoint("TOPRIGHT", durFrame, "TOPRIGHT", 0, 0)
                durHitControl:SetPoint("BOTTOMRIGHT", durFrame, "BOTTOMRIGHT", 0, 0)
                durHitControl:SetWidth(durFrame:GetWidth() * 0.5)
                durHitControl:SetScript("OnEnter", function(self)
                    if not AnyCelebrationTriggerEnabled() then
                        AuraUI.ShowWidgetTooltip(self, AuraUI.DisabledTooltip("at least one Celebration Trigger"))
                    end
                end)
                durHitControl:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

                local function UpdateDurHit()
                    local dis = not AnyCelebrationTriggerEnabled()
                    durHitLabel:EnableMouse(dis)
                    durHitControl:EnableMouse(dis)
                end
                UpdateDurHit()
                AuraUI.RegisterWidgetRefresh(UpdateDurHit)
            end

            -- Random cooldown slider (grayed out unless random trigger is enabled)
            local cdFrame
            cdFrame, h = W:Slider(parent, "Random Celebrations Minimum Cooldown", y, 1, 30, 1,
                function()
                    local db = AuraUIDB
                    local v = db and db.partyModeRandomCooldown
                    if v == nil then v = 10 end
                    return v
                end,
                function(v)
                    if not AuraUIDB then AuraUIDB = {} end
                    AuraUIDB.partyModeRandomCooldown = v
                end,
                nil
            );  y = y - h

            -- Add "(minutes)" suffix in smaller, dimmer text
            if not AuraUI._prebuilding then
                local suffix = cdFrame:CreateFontString(nil, "OVERLAY")
                suffix:SetFont(AuraUI.EXPRESSWAY, 11, "")
                suffix:SetTextColor(1, 1, 1, 0.35)
                local cdLabel
                for i = 1, cdFrame:GetNumRegions() do
                    local reg = select(i, cdFrame:GetRegions())
                    if reg and reg.GetText and AuraUI.EnKey(reg:GetText()) == "Random Celebrations Minimum Cooldown" then
                        cdLabel = reg
                        break
                    end
                end
                if cdLabel then
                    -- Same text-end anchoring as the duration suffix above.
                    suffix:SetPoint("LEFT", cdLabel, "LEFT", cdLabel:GetStringWidth() + 5, 0)
                else
                    suffix:SetPoint("LEFT", cdFrame, "LEFT", 350, 0)
                end
                suffix:SetText(AuraUI.L("(minutes)"))
            end

            local function RefreshCdDisabled()
                local enabled = AuraUIDB and AuraUIDB.partyModeTriggerRandom or false
                cdFrame:SetAlpha(enabled and 1 or 0.35)
                cdFrame:EnableMouse(enabled)
            end
            RefreshCdDisabled()
            AuraUI.RegisterWidgetRefresh(RefreshCdDisabled)

            -- Disabled tooltip for cooldown slider (split: label zone + control zone)
            do
                local cdLabel
                for i = 1, cdFrame:GetNumRegions() do
                    local reg = select(i, cdFrame:GetRegions())
                    if reg and reg.GetText and AuraUI.EnKey(reg:GetText()) == "Random Celebrations Minimum Cooldown" then
                        cdLabel = reg
                        break
                    end
                end

                -- Label hit zone (left half)
                local cdHitLabel = CreateFrame("Frame", nil, cdFrame)
                cdHitLabel:SetFrameLevel(cdFrame:GetFrameLevel() + 10)
                cdHitLabel:EnableMouse(false)
                if cdLabel then
                    cdHitLabel:SetPoint("TOPLEFT", cdFrame, "TOPLEFT", 0, 0)
                    cdHitLabel:SetPoint("BOTTOMLEFT", cdFrame, "BOTTOMLEFT", 0, 0)
                    cdHitLabel:SetWidth(cdFrame:GetWidth() * 0.5)
                end
                cdHitLabel:SetScript("OnEnter", function(self)
                    local enabled = AuraUIDB and AuraUIDB.partyModeTriggerRandom or false
                    if not enabled then
                        AuraUI.ShowWidgetTooltip(self, AuraUI.DisabledTooltip("the Randomly trigger"))
                    end
                end)
                cdHitLabel:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

                -- Control hit zone (right half)
                local cdHitControl = CreateFrame("Frame", nil, cdFrame)
                cdHitControl:SetFrameLevel(cdFrame:GetFrameLevel() + 10)
                cdHitControl:EnableMouse(false)
                cdHitControl:SetPoint("TOPRIGHT", cdFrame, "TOPRIGHT", 0, 0)
                cdHitControl:SetPoint("BOTTOMRIGHT", cdFrame, "BOTTOMRIGHT", 0, 0)
                cdHitControl:SetWidth(cdFrame:GetWidth() * 0.5)
                cdHitControl:SetScript("OnEnter", function(self)
                    local enabled = AuraUIDB and AuraUIDB.partyModeTriggerRandom or false
                    if not enabled then
                        AuraUI.ShowWidgetTooltip(self, AuraUI.DisabledTooltip("the Randomly trigger"))
                    end
                end)
                cdHitControl:SetScript("OnLeave", function() AuraUI.HideWidgetTooltip() end)

                local function UpdateCdHit()
                    local enabled = AuraUIDB and AuraUIDB.partyModeTriggerRandom or false
                    cdHitLabel:EnableMouse(not enabled)
                    cdHitControl:EnableMouse(not enabled)
                end
                UpdateCdHit()
                AuraUI.RegisterWidgetRefresh(UpdateCdHit)
            end
        end

        return math.abs(y)
    end

    ---------------------------------------------------------------------------
    --  Register the module
    ---------------------------------------------------------------------------
    AuraUI:RegisterModule("AuraUIPartyMode", {
        title       = "Party Mode",
        description = "Disco lights overlay for celebrations.",
        pages       = { PAGE_PARTY },
        buildPage   = function(pageName, parent, yOffset)
            if pageName == PAGE_PARTY then
                return BuildPartyModePage(pageName, parent, yOffset)
            end
        end,
        onReset     = function()
            -- Stop party mode (restores CVars if dimmed)
            if AuraUIDB and AuraUIDB.partyMode then
                AuraUIDB.partyMode = false
                AuraUI_StopPartyMode()
            end
            if AuraUIDB then
                AuraUIDB.partyMode = nil
                AuraUIDB.partyModeKey = nil
                AuraUIDB.partyModeMPlus = nil
                AuraUIDB.partyModeMPlusDuration = nil
                AuraUIDB.partyModeBrightness = nil
                AuraUIDB.partyModeTriggerKeystone = nil
                AuraUIDB.partyModeTriggerMythicBoss = nil
                AuraUIDB.partyModeTriggerHeroicBoss = nil
                AuraUIDB.partyModeTriggerNormalBoss = nil
                AuraUIDB.partyModeTriggerLFRBoss = nil
                AuraUIDB.partyModeTriggerMythic0 = nil
                AuraUIDB.partyModeTriggerBloodlust = nil
                AuraUIDB.partyModeTriggerLevelUp = nil
                AuraUIDB.partyModeTriggerRatedBG = nil
                AuraUIDB.partyModeTriggerRatedArena = nil
                AuraUIDB.partyModeTriggerRandom = nil
                AuraUIDB.partyModeRandomCooldown = nil
                AuraUIDB.partyModeDimLights = nil
                AuraUIDB.partyModeSoundKey = nil
            end
            -- Stop random trigger timer
            AuraUI_StopRandomTrigger()
            -- Drop the Bloodlust and Level Up event listeners with their keys
            if AuraUI_UpdatePartyModeLustListener then AuraUI_UpdatePartyModeLustListener() end
            if AuraUI_UpdatePartyModeLevelUpListener then AuraUI_UpdatePartyModeLevelUpListener() end
            -- Clear any override bindings
            if AuraUIPartyModeBindBtn then
                ClearOverrideBindings(AuraUIPartyModeBindBtn)
            end
            AuraUI:SelectPage(PAGE_PARTY)
        end,
    })
end  -- end do block
end  -- end deferred init
