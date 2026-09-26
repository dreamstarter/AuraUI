-- Modules/TestRunner.lua: In-Game Self-Diagnostic & Automated Test Suite (/aui test)
local addonName, addonTable = ...

local TestRunner = addonTable:NewModule("TestRunner")

function TestRunner:OnInitialize()
    addonTable:Debug("TestRunner Module Initialized.")
end

function TestRunner:OnEnable()
    -- Hook test command into SlashCmdList
    local originalSlashHandler = SlashCmdList["AURAUI"]
    SlashCmdList["AURAUI"] = function(msg)
        local command, rest = msg:match("^(%S*)%s*(.-)$")
        command = command and command:lower() or ""

        if command == "test" or command == "diag" then
            TestRunner:RunDiagnostics()
        else
            if originalSlashHandler then
                originalSlashHandler(msg)
            end
        end
    end
end

--- Runs in-game diagnostic test suite and outputs formatted results to ChatFrame.
function TestRunner:RunDiagnostics()
    local passed = 0
    local failed = 0

    addonTable:Print("------------------------------------------")
    addonTable:Print("🧪 Running AuraUI In-Game Self-Diagnostics")
    addonTable:Print("------------------------------------------")

    local function assert_test(condition, name)
        if condition then
            passed = passed + 1
            DEFAULT_CHAT_FRAME:AddMessage(addonTable.colors.success .. "  [PASS] " .. addonTable.colors.reset .. name)
        else
            failed = failed + 1
            DEFAULT_CHAT_FRAME:AddMessage(addonTable.colors.danger .. "  [FAIL] " .. addonTable.colors.reset .. name)
        end
    end

    -- 1. Database & Profile Checks
    assert_test(addonTable.db ~= nil, "Global Database Object Exists")
    assert_test(addonTable.db and addonTable.db.global and addonTable.db.global.profiles ~= nil, "Profiles Database Schema Initialized")

    local activeProfile = addonTable.engine.Profiles:GetActiveProfile()
    assert_test(activeProfile ~= nil, "Active Spec Profile Resolved")
    assert_test(activeProfile and activeProfile.layout ~= nil, "Profile Layout Schema Present")

    -- 2. Module Registration Count
    local expectedModules = 22 -- 21 Core + TestRunner
    local registeredCount = 0
    for name, mod in pairs(addonTable.modules) do
        registeredCount = registeredCount + 1
    end
    assert_test(registeredCount >= 21, string.format("Module Registration Count (%d / 21 Modules Active)", registeredCount))

    -- 3. Media Asset Engine
    local Media = addonTable.engine.Media
    assert_test(Media ~= nil, "Media Engine Loaded")
    assert_test(Media:GetTexture("Flat") ~= nil, "Media Texture Lookup ('Flat')")
    assert_test(Media:GetFont("Default") ~= nil, "Media Font Lookup ('Default')")

    -- 4. EditMode Mover Engine
    local EditMode = addonTable.engine.EditMode
    assert_test(EditMode ~= nil, "EditMode Engine Active")
    local moverCount = 0
    for k, v in pairs(EditMode.movers) do
        moverCount = moverCount + 1
    end
    assert_test(moverCount > 0, string.format("EditMode Mover Registration Count (%d Movers Registered)", moverCount))

    -- 5. Keybind Formatter Test
    local ActionBars = addonTable:GetModule("ActionBars")
    if ActionBars and ActionBars.FormatKeybindText then
        assert_test(ActionBars:FormatKeybindText("SHIFT-1") == "S1", "ActionBars Keybind Formatting ('SHIFT-1' -> 'S1')")
    end

    addonTable:Print("------------------------------------------")
    addonTable:Print(string.format("Diagnostic Summary: %s%d Passed%s, %s%d Failed%s", 
        addonTable.colors.success, passed, addonTable.colors.reset,
        failed > 0 and addonTable.colors.danger or addonTable.colors.reset, failed, addonTable.colors.reset))
    addonTable:Print("------------------------------------------")
end
