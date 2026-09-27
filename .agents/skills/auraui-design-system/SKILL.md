---
name: auraui-design-system
description: >-
  Use this skill whenever designing, styling, skinning, or constructing UI components, windows, tooltips, or action frames for AuraUI.
  Enforces the EllesmereUI Dark Glass aesthetic, consistent color palettes, typography, and EditMode integration.
---

# AuraUI Design System & Style Guide

AuraUI uses a sleek, high-contrast, modern **Dark Glass** visual aesthetic inspired by EllesmereUI and modern eSports UI designs.

---

## 1. Visual Identity & Color Palette

### Brand & Accent Colors
```lua
addonTable.colors = {
    primary   = "|cff00e5ff",  -- Electric Cyan (Main highlight, active tabs, header icons)
    secondary = "|cff7c4dff",  -- Deep Violet (Sub-headers, debug badges)
    success   = "|cff00e676",  -- Vibrant Mint (Pass status, safe health, power toggle on)
    warning   = "|cffffab00",  -- Amber / Gold (Caution threat, cast bar warnings)
    danger    = "|cffff1744",  -- Crimson Red (Low health alerts, aggro danger, interrupt misses)
    reset     = "|r",
}
```

### Frame & Glass Backdrops
Always use these exact RGBA values for transparent glass panels:
- **Main Windows / Dialogs**: `RGBA(0.08, 0.09, 0.11, 0.96)` with 1px border `RGBA(0.2, 0.25, 0.3, 1.0)`.
- **Floating HUD Modules (Threat, Cooldowns, Loot)**: `RGBA(0.04, 0.04, 0.04, 0.88)` with 1px border `RGBA(0, 0.9, 1, 0.5)`.
- **Sidebar / Nav Rails**: `RGBA(0.05, 0.06, 0.07, 0.95)` with 1px border `RGBA(0.15, 0.18, 0.22, 1.0)`.

---

## 2. Standard Frame Construction Pattern

All visible frames must follow this blueprint:

```lua
local function CreateStyledFrame(name, parent, width, height)
    local f = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    f:SetSize(width, height)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.09, 0.11, 0.95)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6) -- Cyan glowing edge
    end

    -- Title Bar Header
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -6)
    title:SetText("|cff00e5ff" .. name .. "|r")
    f.title = title

    return f
end
```

---

## 3. Typography Standards

| Role | Font String Template | Use Case |
| :--- | :--- | :--- |
| **Window Title** | `GameFontNormalHuge` or `GameFontNormalLarge` | Top-level options / wizard headers |
| **Section Header** | `GameFontDisableSmall` (uppercase) | Category label dividers (`DISPLAY`, `COMBAT`) |
| **Body / Labels** | `GameFontHighlightSmall` or `GameFontNormalSmall` | Button labels, checkbox titles, item names |
| **Timer / Counter** | `GameFontNormalLarge` (Yellow/White) | Countdown timers on debuffs and spell queue |

---

## 4. EditMode Mover Rules

1. Every repositionable HUD frame **must** register with `addonTable.engine.EditMode`:
   ```lua
   local em = addonTable.engine.EditMode
   if em and em.RegisterMover then
       em:RegisterMover(frame, "ModuleName", "moduleNamePos")
   end
   ```
2. Saved positions must be loaded in `OnInitialize` from `AuraUICharDB.<moduleNamePos>`:
   ```lua
   local db = AuraUICharDB
   if db and db.<moduleNamePos> then
       local p = db.<moduleNamePos>
       frame:ClearAllPoints()
       frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
   end
   ```
3. Use dragging handlers on frames during unlock mode:
   ```lua
   f:RegisterForDrag("LeftButton")
   f:SetScript("OnDragStart", f.StartMoving)
   f:SetScript("OnDragStop",  f.StopMovingOrSizing)
   ```
