# tests/run_tests.py: Automated verification script for AuraUI files & module integrity
import os
import re
import sys

if sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

print("==========================================")
print("[TEST RUNNER] AuraUI Comprehensive Diagnostic Suite")
print("==========================================")

toc_file = "AuraUI/AuraUI.toc"
if not os.path.exists(toc_file):
    print(f"[ERROR] {toc_file} not found!")
    sys.exit(1)

with open(toc_file, "r", encoding="utf-8") as f:
    toc_lines = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]

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

print("\n1. Verifying File Manifest in AuraUI.toc...")
for rel_path in toc_lines:
    full_path = os.path.join("AuraUI", rel_path.replace("\\", "/"))
    check(os.path.exists(full_path), f"File manifest check: {rel_path}")

print("\n2. Verifying Module Declarations & Syntax Integrity...")
modules = []
modules_dir = "AuraUI/Modules"
for file_name in os.listdir(modules_dir):
    if file_name.endswith(".lua"):
        mod_path = os.path.join(modules_dir, file_name)
        with open(mod_path, "r", encoding="utf-8") as f:
            content = f.read()
            match = re.search(r'addonTable:NewModule\(["\'](\w+)["\']\)', content)
            if match:
                mod_name = match.group(1)
                modules.append(mod_name)
                check(True, f"Registered module '{mod_name}' in {file_name}")
            else:
                check(False, f"No module registration found in {file_name}")

print("\n3. Verifying Core Engines...")
engines = ["Range.lua", "Kick.lua", "Glows.lua", "ProfileSharing.lua", "FirstInstall.lua", "Visibility.lua", "ThemePresets.lua", "SoundAlerts.lua", "SpellQueue.lua", "Profiles.lua", "EditMode.lua", "Media.lua"]
for eng in engines:
    eng_path = os.path.join("AuraUI/Engine", eng)
    check(os.path.exists(eng_path), f"Core Engine presence: {eng}")

print("\n==========================================")
print(f"Diagnostic Results: {passed} Passed, {failed} Failed")
print("==========================================")

if failed > 0:
    sys.exit(1)

