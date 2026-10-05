# tests/run_tests.py: Automated verification script for AuraUI suite integrity & WoW: Forever compliance
import os
import re
import sys
import glob

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

print("==================================================================")
print("[TEST RUNNER] AuraUI Comprehensive Diagnostic Suite (WoW: Forever)")
print("==================================================================")

passed = 0
failed = 0

def check(condition, desc):
    global passed, failed
    if condition:
        passed += 1
        print(f"  [PASS] {desc}")
    else:
        failed += 1
        print(f"  [FAIL] {desc}")

# 1. AddOn Folders Check
print("\n1. Verifying AddOn Folders...")
expected_addons = [
    "AuraUI", "AuraUIActionBars", "AuraUIAuraBuffReminders", "AuraUIBags",
    "AuraUIBlizzardSkin", "AuraUIChat", "AuraUICooldownManager", "AuraUIDamageMeters",
    "AuraUIDataBars", "AuraUIForeverEssentials", "AuraUIFriends", "AuraUILocales",
    "AuraUIMinimap", "AuraUIMythicTimer", "AuraUINameplates", "AuraUIOptions",
    "AuraUIQoL", "AuraUIQuestTracker", "AuraUIQuickdraw", "AuraUIRaidFrames",
    "AuraUIResourceBars", "AuraUIUnitFrames"
]
for addon in expected_addons:
    check(os.path.isdir(addon), f"Addon folder exists: {addon}")

# 2. TOC Manifest & File Existence Check
print("\n2. Verifying TOC Manifests & Referenced Files...")
all_tocs = glob.glob("AuraUI*/*.toc")
for toc_path in sorted(all_tocs):
    addon_dir = os.path.dirname(toc_path)
    with open(toc_path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
    
    # Check interface tag
    content = "".join(lines)
    has_interface = "## Interface:" in content
    check(has_interface, f"{toc_path} defines ## Interface")

    # Check referenced files
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # Strip game type conditional tags like [AllowLoadGameType standard]
        file_ref = re.sub(r"\[.*?\]", "", line).strip()
        if not file_ref:
            continue
        target_file = os.path.join(addon_dir, file_ref.replace("\\", "/"))
        check(os.path.exists(target_file), f"Manifest entry {file_ref} in {toc_path}")

# 3. Camelot Metadata & Client Gate Check
print("\n3. Verifying WoW: Forever Camelot Metadata & Client Gate...")
gate_file = "AuraUI/AuraUI_ClientGate.lua"
check(os.path.exists(gate_file), "Client gate file exists (AuraUI_ClientGate.lua)")
if os.path.exists(gate_file):
    with open(gate_file, "r", encoding="utf-8") as f:
        gate_content = f.read()
    check("AUI_CLIENT_FOREVER = true" in gate_content, "AUI_CLIENT_FOREVER armed in ClientGate")
    check("16000" in gate_content and "20000" in gate_content, "Interface build range [16000, 20000] handled")

camelot_tocs = glob.glob("AuraUI*/*_Camelot.toc")
check(len(camelot_tocs) >= 19, f"Camelot TOC files count: {len(camelot_tocs)} (>= 19)")
for c_toc in camelot_tocs:
    with open(c_toc, "r", encoding="utf-8", errors="ignore") as f:
        c_content = f.read()
    check("AllowLoadGameType: camelot" in c_content, f"camelot game type in {c_toc}")
    check("16001" in c_content, f"16001 interface in {c_toc}")

# 4. AuraUI Unique Innovations Check
print("\n4. Verifying AuraUI Unique Innovation Modules...")
innovations = [
    ("AuraUI/AuraUI_AutoMarker.lua", "Smart Auto-Marker Module"),
    ("AuraUI/AuraUI_LootCouncil.lua", "Loot Council Lite Module"),
    ("AuraUI/AuraUI_MapNotes.lua", "Map Notes & Waypoint Module"),
    ("AuraUI/AuraUI_GuildNotes.lua", "Guild Roster & Officer Notes Module"),
    ("AuraUI/AuraUI_SoundPackCustomizer.lua", "Sound Pack Customizer Module"),
    ("AuraUIChat/AuraUIChat_Filter.lua", "Smart Chat Spam Filter Module"),
]
for mod_file, desc in innovations:
    exists = os.path.exists(mod_file)
    check(exists, f"{desc} ({mod_file}) exists")
    if exists:
        with open(mod_file, "r", encoding="utf-8") as f:
            code = f.read()
        check("if AUI_CLIENT_BLOCKED then return end" in code, f"{desc} has AUI_CLIENT_BLOCKED guard")

# 5. Media & Assets Check
print("\n5. Verifying Media Assets...")
media_files = [
    "AuraUI/media/aui-logo.tga",
    "AuraUI/media/backgrounds/aui-bg-new.png",
    "AuraUI/media/backgrounds/aui-bg-forever-compressed.png",
    "AuraUI/media/borders/blizz-border.tga",
    "AuraUI/media/textures/glass.tga",
    "AuraUI/media/fonts/Expressway.ttf",
]
for m in media_files:
    check(os.path.exists(m), f"Media asset exists: {m}")

# 6. Upstream 9.3.7 WoW: Forever Features & Fixes
print("\n6. Verifying 9.3.7 WoW: Forever Features & Upstream Fixes...")
uprank_file = "AuraUIForeverEssentials/AuraUIForeverEssentials_AutoUprank.lua"
check(os.path.exists(uprank_file), "Auto Uprank module exists")
if os.path.exists(uprank_file):
    with open(uprank_file, "r", encoding="utf-8") as f:
        uprank_code = f.read()
    check("LEARNED_SPELL_IN_TAB" in uprank_code, "Auto Uprank registers LEARNED_SPELL_IN_TAB")
    check("InCombatLockdown()" in uprank_code, "Auto Uprank protects combat state")
    check("PickupSpell" in uprank_code and "PlaceAction" in uprank_code, "Auto Uprank handles action bar placement")

options_general = "AuraUIOptions/AUI_ForeverEssentials_General_Options.lua"
check(os.path.exists(options_general), "Forever Essentials General options page exists")

with open("AuraUI/AuraUI.lua", "r", encoding="utf-8") as f:
    aui_code = f.read()
check("PLAYER_LEVEL_UP" in aui_code and "_playerCastBarCombatRegenFrame" in aui_code, "Blizzard cast bar combat level up suppression active")

with open("AuraUIActionBars/AuraUIActionBars.lua", "r", encoding="utf-8") as f:
    ab_code = f.read()
check("ActionBarButtonEventsFrame" in ab_code and "statehidden" in ab_code and "_auiCooldownSuppressed" in ab_code, "Hidden action buttons combat cooldown error guard active")

with open("AuraUIForeverEssentials/AuraUIForeverEssentials_FlightTimer.lua", "r", encoding="utf-8") as f:
    ft_code = f.read()
check("StartLoopPreview" in ft_code and "StopLoopPreview" in ft_code, "Flight timer loop preview API active")

print("\n7. Verifying Group A Upstream Sync Features...")
with open("AuraUIQuestTracker/AuraUIQuestTracker.lua", "r", encoding="utf-8") as f:
    qt_code = f.read()
check("autoAcceptIgnoreLowLevel = false" in qt_code, "Quest Tracker autoAcceptIgnoreLowLevel default exists")

with open("AuraUIQuestTracker/AuraUIQuestTracker_QoL.lua", "r", encoding="utf-8") as f:
    qt_qol = f.read()
check("autoAcceptIgnoreLowLevel" in qt_qol and "QuestIsTrivial" in qt_qol, "Quest Tracker ignore low level quest check active")

with open("AuraUIQoL/AuraUIQoL.lua", "r", encoding="utf-8") as f:
    qol_code = f.read()
check("autoSelectSingleGossip" in qol_code and "SelectGossipOption" in qol_code, "QoL auto select single gossip handler active")

with open("AuraUIActionBars/AuraUIActionBars.lua", "r", encoding="utf-8") as f:
    ab_code2 = f.read()
check("_questCompleteBar" in ab_code2 and "_questIncompleteBar" in ab_code2 and "GetQuestLogXP" in ab_code2, "Action Bars Quest XP overlay active")

loot_feed_file = "AuraUIForeverEssentials/AuraUIForeverEssentials_LootFeed.lua"
check(os.path.exists(loot_feed_file), "Forever Essentials Loot Feed module exists")
with open(loot_feed_file, "r", encoding="utf-8") as f:
    lf_code = f.read()
check("AUI_LootFeed" in lf_code and "StartLoopPreview" in lf_code and "ApplyRowStyle" in lf_code, "Loot Feed styles and preview loop active")

loot_options_file = "AuraUIOptions/AUI_ForeverEssentials_Loot_Options.lua"
check(os.path.exists(loot_options_file), "Forever Essentials Loot options page exists")

print("\n==================================================================")
print(f"Diagnostic Results: {passed} Passed, {failed} Failed")
print("==================================================================")

if failed > 0:
    sys.exit(1)
else:
    print("[SUCCESS] All diagnostics passed with 100% compliance!")
    sys.exit(0)
