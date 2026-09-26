-- Engine/FirstInstall.lua: Step-by-step Onboarding Setup Wizard
local addonName, addonTable = ...

local FirstInstall = {}
addonTable.engine.FirstInstall = FirstInstall

--- Triggers the first-time setup wizard if not yet completed.
function FirstInstall:CheckFirstInstall()
    if addonTable.db and addonTable.db.global and not addonTable.db.global.firstInstallCompleted then
        self:ShowWizard()
    end
end

--- Constructs and displays the interactive onboarding modal dialog.
function FirstInstall:ShowWizard()
    if self.wizardFrame then
        self.wizardFrame:Show()
        return
    end

    local wizard = CreateFrame("Frame", "AuraUIFirstInstallWizard", UIParent, "BackdropTemplate")
    wizard:SetSize(520, 360)
    wizard:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    wizard:SetFrameStrata("DIALOG")
    wizard:EnableMouse(true)
    wizard:SetMovable(true)

    wizard:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    wizard:SetBackdropColor(0.08, 0.09, 0.11, 0.98)
    wizard:SetBackdropBorderColor(0, 0.9, 1, 1)

    -- Header Title
    local title = wizard:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", wizard, "TOP", 0, -20)
    title:SetText("Welcome to |cff00e5ffAuraUI|r!")

    -- Subtitle
    local desc = wizard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetText("Let's set up your preferred UI preset and layout.")

    -- Preset Selection Buttons (Healer, Tank, DPS)
    local healerBtn = CreateFrame("Button", nil, wizard, "UIPanelButtonTemplate")
    healerBtn:SetSize(140, 32)
    healerBtn:SetPoint("CENTER", wizard, "CENTER", -110, 20)
    healerBtn:SetText("Healer Preset")

    local dpsBtn = CreateFrame("Button", nil, wizard, "UIPanelButtonTemplate")
    dpsBtn:SetSize(140, 32)
    dpsBtn:SetPoint("CENTER", wizard, "CENTER", 0, 20)
    dpsBtn:SetText("DPS / Tank Preset")

    local classicBtn = CreateFrame("Button", nil, wizard, "UIPanelButtonTemplate")
    classicBtn:SetSize(140, 32)
    classicBtn:SetPoint("CENTER", wizard, "CENTER", 110, 20)
    classicBtn:SetText("Minimalist Preset")

    -- Finish Button
    local finishBtn = CreateFrame("Button", nil, wizard, "UIPanelButtonTemplate")
    finishBtn:SetSize(160, 30)
    finishBtn:SetPoint("BOTTOM", wizard, "BOTTOM", 0, 30)
    finishBtn:SetText("Complete Setup")
    finishBtn:SetScript("OnClick", function()
        if addonTable.db and addonTable.db.global then
            addonTable.db.global.firstInstallCompleted = true
        end
        wizard:Hide()
        addonTable:Print("AuraUI setup completed! Type /aui unlock to move frames.")
    end)

    self.wizardFrame = wizard
end
