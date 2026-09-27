---
name: auraui-qa-packager
description: >-
  Use this skill whenever running test suites, validating diagnostic health, checking TOC integrity, or packaging release zip archives for AuraUI.
---

# AuraUI QA & Packager Guide

This skill handles quality assurance, automated diagnostic testing, and production packaging for the AuraUI suite.

---

## 1. Test Suite Execution

AuraUI uses a dual testing approach:
1. **Headless Diagnostic Suite** (`tests/run_tests.py`):
   Validates TOC file manifests, Lua module registrations, engine subsystem presence, and syntax integrity without requiring a game client.
   ```powershell
   python tests/run_tests.py
   ```
2. **In-Game Live Diagnostics** (`Modules/TestRunner.lua`):
   Available in-game via `/aui test` or `/aui diag`. Runs live runtime tests against the active game engine and database.

---

## 2. Release Packaging

The included `package.py` script automatically verifies tests and builds a clean release zip archive:
- Validates the test suite first (aborts if any test fails).
- Bundles `AuraUI` and `AuraUI_Options` into a standalone zip file in `dist/`.
- Omits developer files (`tests/`, `project_docs/`, `.git/`, `.agents/`).

### Command
```powershell
python .agents/skills/auraui-qa-packager/scripts/package.py
```

Optional target directory to deploy directly to a local WoW client:
```powershell
python .agents/skills/auraui-qa-packager/scripts/package.py --deploy "D:/World of Warcraft/_retail_/Interface/AddOns"
```
