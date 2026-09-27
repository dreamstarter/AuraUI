---
name: auraui-module-scaffolder
description: >-
  Use this skill whenever creating, scaffolding, or wiring a new AuraUI module or engine subsystem.
  Enforces proper lifecycle hooks, EditMode integration, Config defaults, TOC manifest entries, Options panel toggles, and test suite registration.
---

# AuraUI Module & Engine Scaffolder

This skill guides the end-to-end creation, registration, and wiring of modules and engine subsystems in AuraUI.

---

## 1. Architectural Rules & Standards

### Module vs. Engine Subsystem
- **Module** (`AuraUI/Modules/<Name>.lua`): A discrete player-facing or combat feature (e.g. `ActionBars`, `ThreatMeter`, `DebuffTracker`).
  - Registers via `local MyMod = addonTable:NewModule("MyMod")`.
  - Implements lifecycle methods: `OnInitialize()`, `OnEnable()`, `OnDisable()`.
  - Registered in the `Modules` section of `AuraUI.toc`.
- **Engine Subsystem** (`AuraUI/Engine/<Name>.lua`): A core service or framework component consumed by multiple modules (e.g. `EditMode`, `Media`, `Profiles`, `Glows`, `SoundAlerts`, `SpellQueue`).
  - Stored directly on `addonTable.engine.<Name>`.
  - Initialized on `ADDON_LOADED` or `PLAYER_LOGIN` via event hooks.
  - Registered in the `Engine` section of `AuraUI.toc` (before `Config.lua` and `Core.lua`).

---

## 2. Standard Module Boilerplate

When creating `AuraUI/Modules/<Name>.lua`:

```lua
-------------------------------------------------------------------------------
-- AuraUI / Modules/<Name>.lua
-- <Title / Short Description>
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local <Name> = addonTable:NewModule("<Name>")

-------------------------------------------------------------------------------
-- Module State
-------------------------------------------------------------------------------
<Name>.enabled = true
<Name>.frame   = nil

-------------------------------------------------------------------------------
-- Frame Creation & EditMode
-------------------------------------------------------------------------------
local function Create<Name>Frame()
    local f = CreateFrame("Frame", "AuraUI<Name>Frame", UIParent, "BackdropTemplate")
    f:SetSize(200, 40)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    -- Backdrop styling (AuraUI Dark Glass standard)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.09, 0.11, 0.95)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
    end

    return f
end

-------------------------------------------------------------------------------
-- Lifecycle Methods
-------------------------------------------------------------------------------
function <Name>:OnInitialize()
    self.frame = Create<Name>Frame()

    -- Register with EditMode mover system
    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "<Name>", "<nameLower>Pos")
    end

    -- Load saved enabled state
    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.<Name> ~= nil then
        self.enabled = AuraUIDB.modules.<Name>
    end
end

function <Name>:OnEnable()
    if self.enabled and self.frame then
        self.frame:Show()
    end
end

function <Name>:OnDisable()
    self.enabled = false
    if self.frame then
        self.frame:Hide()
    end
end
```

---

## 3. Required Multi-File Checklist

Whenever creating a module or engine subsystem, ensure all 6 steps are completed:

1. **Implementation File**: `AuraUI/Modules/<Name>.lua` or `AuraUI/Engine/<Name>.lua`.
2. **TOC Manifest** (`AuraUI/AuraUI.toc`): Add file path in the proper section (`Engine\` before `Config.lua`, or `Modules\` before `Modules\TestRunner.lua`).
3. **Database Config Defaults** (`AuraUI/Config.lua`):
   - Add default anchor to `addonTable.defaultProfile.layout.<Name>` (if visual).
   - Add default settings block to `addonTable.defaultProfile.<nameLower> = { enabled = true }`.
4. **Options Panel Toggle** (`AuraUI_Options/OptionsPanel.lua`):
   - Add checkbox toggle in the appropriate section (General, Display, or Combat).
5. **Test Runner Updates** (`tests/run_tests.py`):
   - If engine: Add `<Name>.lua` to the `engines` list in `tests/run_tests.py`.
   - If module: Automatically checked by directory scanner.
6. **Verification**: Run `python tests/run_tests.py` to confirm 100% pass rate.

---

## 4. Automation Helper Script

Use the included helper script to scaffold boilerplate automatically:
```powershell
python .agents/skills/auraui-module-scaffolder/scripts/scaffold.py --name <Name> --type module --desc "<Description>"
```
