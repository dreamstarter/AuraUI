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

The root `package.py` script automatically verifies tests and builds a CurseForge-compliant release zip archive:
- Validates the test suite first (aborts if any of the 800+ diagnostic tests fail).
- Bundles all 22 verified suite modules directly at the archive root.
- Guarantees **zero nesting** (no outer folder wrapper) so CurseForge and WoW install directly into `Interface/AddOns/`.
- Verifies all 61 `.toc` manifests across Midnight, Camelot (`*_Camelot.toc`), and Mists (`*_Mists.toc`).
- Omits developer files (`tests/`, `project_docs/`, `.git/`, `.agents/`, `.vscode/`).

### Command
```powershell
python package.py [--deploy "path/to/Interface/AddOns"] [--skip-tests] [--version X.Y.Z]
```

Optional target directory to deploy directly to a local WoW client:
```powershell
python package.py --deploy "D:/World of Warcraft/_retail_/Interface/AddOns"
```
