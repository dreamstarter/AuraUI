if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AuraUI_StyleLaunchPopup.lua
--
--  One-time login popup announcing the looks (Blizzard Style and the new
--  Classic WoW UI beside the AuraUI look) to EXISTING users -- people who
--  already had AuraUI installed before this version. It shows the first-
--  install picker's three cards (AuraUI_StyleCards.lua) as display cards,
--  with no pick buttons: "Restyle My UI" goes to Global Settings > Style,
--  where the choice is made; "Got It" just closes.
--
--  NEW users never see it: a fresh install gets the style picker itself. The
--  new-vs-existing guarantee mirrors the earlier announcement popups: at the
--  parent ADDON_LOADED, AuraUIDB still reflects ONLY the previous
--  session's data, because child addons have not initialized their
--  per-profile DBs yet this session. So a profile that already carries
--  `addons` data can only have come from a prior version = an existing or
--  upgrade user. A nil DB, or a DB with no prior addon data, is a fresh
--  install: we stamp it at login so it never fires later either. Users who
--  met the first (two-look) picker still see it: Classic WoW UI is new to
--  them.
--
--  WoW Forever never shows it (login announcements stay off there, and its
--  saved variables are not reliable during the beta).
--
--  Fires once, at PLAYER_LOGIN. Guarded by AuraUIDB.styleLaunchIntroShown.
--  Only the newest announcement stays live: the WoW Forever launch
--  announcement retired when this shipped, so users upgrading across several
--  versions never see two intro popups back to back.
-------------------------------------------------------------------------------

local AuraUI = _G.AuraUI
if not AuraUI then return end

-- Suite-only: a single-module standalone build has no style picker story.
-- Deriving this from the host addon name (the `...` vararg) is rename-immune.
local AUI_HOST_ADDON = ...
local IS_STANDALONE = type(AUI_HOST_ADDON) == "string" and AUI_HOST_ADDON:find("Standalone") ~= nil
if IS_STANDALONE then return end

local PP = AuraUI.PanelPP
local MakeBorder = AuraUI.MakeBorder

-------------------------------------------------------------------------------
--  Conflict-check handoff
--  For existing users the addon-conflict check auto-runs ~2s after load (gated
--  in AuraUI.lua on AuraUIDB.firstInstallPopupShown). We raise a
--  pending flag so that check defers while our popup is open, then trigger it
--  here on dismiss -- so the two popups never stack.
-------------------------------------------------------------------------------
local function ReleaseConflictCheck()
    AuraUI._styleLaunchIntroPending = nil
    if AuraUIDB and AuraUIDB.firstInstallPopupShown and AuraUI._RunConflictCheck then
        C_Timer.After(0.3, AuraUI._RunConflictCheck)
    end
end

-------------------------------------------------------------------------------
--  The popup
-------------------------------------------------------------------------------
local function ShowStyleLaunchPopup()
    if not (PP and MakeBorder and AuraUI.ELLESMERE_GREEN and AuraUI.BuildStyleCards) then
        ReleaseConflictCheck()
        return
    end
    local FONT = AuraUI._font or AuraUI.EXPRESSWAY
        or "Interface\\AddOns\\AuraUI\\media\\fonts\\Expressway.ttf"
    local EG = AuraUI.ELLESMERE_GREEN
    -- Vertical budget (top-down): eyebrow 26, title, two-line blurb to ~115,
    -- display cards 132-380, buttons 402-440, footnote at the foot.
    local CARDS_TOP = 132
    local POPUP_W = 700
    local POPUP_H = CARDS_TOP + (AuraUI.STYLE_CARD_DISPLAY_H or 248) + 22 + 82
    -- Dimmer eats clicks (no close on outside click). Escape = Got It.
    local Finish
    local dimmer, popup = AuraUI.BuildPopupShell("EUIStyleLaunchIntro", {
        w = POPUP_W, h = POPUP_H, bump = 1.15,
        onEscape = function() Finish(false) end,
    })

    -- Eyebrow
    local eyebrow = popup:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont(FONT, 13, "")
    eyebrow:SetTextColor(EG.r, EG.g, EG.b, 0.9)
    PP.Point(eyebrow, "TOP", popup, "TOP", 0, -26)
    eyebrow:SetText(AuraUI.L("NEW IN ELLESMEREUI"))

    -- Title
    local title = popup:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 26, "")
    title:SetTextColor(1, 1, 1, 1)
    PP.Point(title, "TOP", eyebrow, "BOTTOM", 0, -6)
    title:SetText(AuraUI.L("Your UI, Restyled in Seconds"))

    -- Description
    local desc = popup:CreateFontString(nil, "OVERLAY")
    desc:SetFont(FONT, 14, "")
    desc:SetTextColor(1, 1, 1, 0.5)
    desc:SetWidth(POPUP_W - 90)
    desc:SetJustifyH("CENTER")
    desc:SetWordWrap(true)
    PP.Point(desc, "TOP", title, "BOTTOM", 0, -10)
    desc:SetText(AuraUI.L("Same setup, same AuraUI features, a new look: switch to Blizzard Style or the new Classic WoW UI in one click, and switch back any time."))

    -- The picker's three cards, display only (AuraUI_StyleCards.lua).
    AuraUI.BuildStyleCards(popup, -CARDS_TOP, { display = true })

    -- Stamp + close. openStyle=true opens Global Settings > Style.
    Finish = function(openStyle)
        if not AuraUIDB then AuraUIDB = {} end
        AuraUIDB.styleLaunchIntroShown = true
        dimmer:Hide()
        ReleaseConflictCheck()
        if not openStyle then return end
        if InCombatLockdown() then
            AuraUI.PrintError("Cannot open options during combat. The looks are under Global Settings > Style.")
            return
        end
        if AuraUI.NavigateToElementSettings then
            -- Carries the options first-open split, so the page still lands
            -- when the panel builds next frame.
            AuraUI:NavigateToElementSettings("_EUIGlobal", "Style")
        end
    end

    -- Primary "Restyle My UI" on the left, secondary "Got It" on the
    -- right, centered as a pair around the popup's bottom center.
    local BTN_W, BTN_GAP = 200, 14
    local openBtn = AuraUI.MakeActionButton(popup, FONT, AuraUI.L("Restyle My UI"), EG.r, EG.g, EG.b, { w = BTN_W })
    PP.Point(openBtn, "BOTTOMRIGHT", popup, "BOTTOM", -BTN_GAP / 2, 44)
    openBtn:SetScript("OnClick", function() Finish(true) end)

    local gotBtn = AuraUI.MakeActionButton(popup, FONT, AuraUI.L("Got It"), 1, 1, 1, { w = BTN_W, secondary = true, hoverA = 0.8 })
    PP.Point(gotBtn, "BOTTOMLEFT", popup, "BOTTOM", BTN_GAP / 2, 44)
    gotBtn:SetScript("OnClick", function() Finish(false) end)

    -- Footnote
    local footnote = popup:CreateFontString(nil, "OVERLAY")
    footnote:SetFont(FONT, 12, "")
    footnote:SetTextColor(1, 1, 1, 0.35)
    footnote:SetWidth(POPUP_W - 90)
    footnote:SetJustifyH("CENTER")
    PP.Point(footnote, "BOTTOM", popup, "BOTTOM", 0, 16)
    footnote:SetText(AuraUI.L("Global Settings > Style sets the look for the whole UI or for each module."))

    dimmer:Show()
end

AuraUI.ShowStyleLaunchIntroPopup = ShowStyleLaunchPopup

-------------------------------------------------------------------------------
--  Trigger: existing users only, once, at login
--
--  Decision is captured at the parent ADDON_LOADED, while AuraUIDB still
--  holds only the previous session's data:
--    "show" -> existing/upgrade user (a profile already carries addon data)
--    "new"  -> fresh install (nil DB, or DB with no prior addon data, or the
--              session the style picker itself is due), or the WoW Forever
--              client; stamp at login so it never fires later
--    "done" -> already shown before
-------------------------------------------------------------------------------
local _decision

local function ComputeDecision()
    -- A session the first-install picker owns is a fresh install whatever the
    -- profile store holds (the picker's loader runs first and seeds data).
    if AuraUI.IS_FOREVER or AuraUI._firstInstallPending then return "new" end
    if not AuraUIDB then
        -- No SavedVariables at all -> brand-new first session.
        return "new"
    end
    if AuraUIDB.styleLaunchIntroShown then
        return "done"
    end
    -- The style picker is due this login (the session after the module
    -- picker): that popup already offers every look.
    if AuraUIDB.styleChoicePending then
        AuraUIDB.styleLaunchIntroShown = true
        return "new"
    end
    local profiles = AuraUIDB.profiles
    if type(profiles) == "table" then
        for _, prof in pairs(profiles) do
            if type(prof) == "table" and type(prof.addons) == "table" and next(prof.addons) then
                -- Data from a previous session = existing/upgrade user.
                return "show"
            end
        end
    end
    -- DB exists but carries no prior addon data -> treat as fresh, stamp now.
    AuraUIDB.styleLaunchIntroShown = true
    return "new"
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" then
        if addonName ~= "AuraUI" then return end
        self:UnregisterEvent("ADDON_LOADED")
        _decision = ComputeDecision()
        if _decision == "show" then
            -- Hold the auto conflict check until our popup is dismissed.
            AuraUI._styleLaunchIntroPending = true
        end
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        if _decision == "new" or AuraUI._firstInstallPending then
            -- Stamp brand-new users so the popup never fires in a later
            -- session. The picker's pending flag is the authority on "fresh",
            -- so a decision reached ahead of it still stands down here.
            if not AuraUIDB then AuraUIDB = {} end
            AuraUIDB.styleLaunchIntroShown = true
            if AuraUI._styleLaunchIntroPending then ReleaseConflictCheck() end
            return
        end
        if _decision ~= "show" then return end
        local function TryShow()
            if AuraUIDB and AuraUIDB.styleLaunchIntroShown then
                ReleaseConflictCheck()
                return
            end
            -- Defer behind any other login announcement still pending or
            -- open, so announcements never stack on a single login.
            if AuraUI._launchVideoIntroPending then
                C_Timer.After(0.4, TryShow)
                return
            end
            ShowStyleLaunchPopup()
        end
        C_Timer.After(0.5, TryShow)
    end
end)

-------------------------------------------------------------------------------
--  Reset command: clears the one-time stamp so the announcement fires again
--  on the next /reload (testing aid, same as the earlier intro popups).
-------------------------------------------------------------------------------
SLASH_AUISTYLEINTRO1 = "/auistyleintro"
SlashCmdList["EUISTYLEINTRO"] = function()
    if AuraUIDB then AuraUIDB.styleLaunchIntroShown = nil end
    print("|cff00ff98AuraUI:|r Style announcement reset. It fires on your next /reload.")
end
