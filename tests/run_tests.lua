-- tests/run_tests.lua: Automated CLI Test Suite for AuraUI
local originalPrint = print
print("\n==========================================")
print("🚀 Running AuraUI Automated Unit Tests")
print("==========================================")

-- 1. Load WoW API Mocks
require("tests.wow_api_mock")

-- Test Runner State
local passed = 0
local failed = 0

local function assert_eq(expected, actual, testName)
    if expected == actual then
        passed = passed + 1
        print(string.format("  [PASS] %s", testName))
    else
        failed = failed + 1
        print(string.format("  [FAIL] %s - Expected: %s, Got: %s", testName, tostring(expected), tostring(actual)))
    end
end

local function assert_true(condition, testName)
    assert_eq(true, not not condition, testName)
end

-- 2. Initialize Addon Namespace
local addonName = "AuraUI"
local addonTable = {}

-- Load Init.lua
local initChunk, err = loadfile("AuraUI/Init.lua")
if not initChunk then
    print("❌ Failed to load Init.lua: " .. tostring(err))
    os.exit(1)
end
initChunk(addonName, addonTable)

print("\n1. Testing Namespace & Module Registry...")
assert_eq("AuraUI", addonTable.name, "Addon Name matches AuraUI")
assert_true(addonTable.colors and addonTable.colors.primary, "Color palette initialized")

-- Register Test Module
local testModule = addonTable:NewModule("TestModule")
assert_eq(testModule, addonTable:GetModule("TestModule"), "NewModule & GetModule retrieval")

print("\n2. Testing Media Engine...")
local mediaChunk = loadfile("AuraUI/Engine/Media.lua")
mediaChunk(addonName, addonTable)
local Media = addonTable.engine.Media

assert_true(Media:GetTexture("Flat"):find("UI-StatusBar"), "Texture lookup 'Flat'")
assert_true(Media:GetFont("Default"):find("TTF"), "Font lookup 'Default'")

print("\n3. Testing Profiles & Database Config Engine...")
local configChunk = loadfile("AuraUI/Config.lua")
configChunk(addonName, addonTable)

addonTable:InitDatabase()
assert_true(AuraUIDB and AuraUIDB.profiles and AuraUIDB.profiles.Default, "Database initialization & default profile schema")

local profilesChunk = loadfile("AuraUI/Engine/Profiles.lua")
profilesChunk(addonName, addonTable)
local Profiles = addonTable.engine.Profiles

local specIndex, specName = Profiles:GetCurrentSpec()
assert_eq(1, specIndex, "GetCurrentSpec spec index")
assert_eq("Protection", specName, "GetCurrentSpec spec name")

local profileKey = Profiles:GetActiveProfileKey()
assert_true(profileKey:find("Paladin_Protection_Spec1"), "GetActiveProfileKey spec string formatting")

print("\n4. Testing EditMode Engine...")
local editModeChunk = loadfile("AuraUI/Engine/EditMode.lua")
editModeChunk(addonName, addonTable)
local EditMode = addonTable.engine.EditMode

EditMode:Unlock()
assert_eq(true, EditMode.unlocked, "EditMode unlock state")
EditMode:Lock()
assert_eq(false, EditMode.unlocked, "EditMode lock state")

print("\n5. Testing ActionBars Formatting...")
local actionBarsChunk = loadfile("AuraUI/Modules/ActionBars.lua")
actionBarsChunk(addonName, addonTable)
local ActionBars = addonTable:GetModule("ActionBars")

assert_eq("S1", ActionBars:FormatKeybindText("SHIFT-1"), "Keybind text formatting SHIFT-1 -> S1")
assert_eq("A2", ActionBars:FormatKeybindText("ALT-2"), "Keybind text formatting ALT-2 -> A2")
assert_eq("C3", ActionBars:FormatKeybindText("CTRL-3"), "Keybind text formatting CTRL-3 -> C3")

print("\n==========================================")
print(string.format("📊 Test Results: %d Passed, %d Failed", passed, failed))
print("==========================================")

if failed > 0 then
    os.exit(1)
end
