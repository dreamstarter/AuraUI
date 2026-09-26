# EllesmereUI vs. AuraUI: Technical Analysis & Feature Gap Comparison

This document provides a comprehensive architectural analysis and feature comparison between **EllesmereUI** (v9.2.9) and **AuraUI** (v1.0.0). It outlines current parity, structural differences, and a prioritized development roadmap for building out remaining feature capabilities in AuraUI.

---

## 1. Executive Summary

| Metric / Dimension | EllesmereUI (v9.2.9) | AuraUI (v1.0.0) | Gap Status |
| :--- | :--- | :--- | :--- |
| **Architecture** | 21 LoadOnDemand Sub-AddOns + Shared Core (`EllesmereUI_Lite`) | Single Core AddOn + LoadOnDemand Options (`AuraUI_Options`) | 🟢 **AuraUI is cleaner & more unified** |
| **Edit Mode / Movers** | `EUI_UnlockMode.lua` with snapping & grid alignment | `Engine/EditMode.lua` with snapping & grid overlay | 🟢 **Parity achieved** |
| **Spec Profiles** | `EllesmereUI_Profiles.lua` (Auto-switches on spec change) | `Engine/Profiles.lua` (Auto-switches on spec change) | 🟢 **Parity achieved** |
| **Profile Import/Export** | Supported via `LibDeflate` (Compressed Base64 string strings) | SavedVariables DB table copying | 🟡 **Needs Profile String Sharing Engine** |
| **Testing & QA** | Manual in-game testing | Dual-Runner Suite (`/aui test` + Headless Python/Lua CLI) | 🟢 **AuraUI exceeds EllesmereUI** |
| **Spell Range Engine** | `EllesmereUI_Range.lua` (Desaturates buttons when out of range) | Standard action bar styling | 🔴 **Target for Phase 1** |
| **Mouseover / Click-Cast** | `EllesmereUI_Mouse.lua` (Click-casting on unit frames) | Standard unit frame click targets | 🔴 **Target for Phase 1** |
| **Interrupt / Kick Tracker** | `EllesmereUI_Kick.lua` (Tracks party kicks & announces interrupts) | Not implemented | 🔴 **Target for Phase 1** |
| **Proc & Button Glows** | `EllesmereUI_Glows.lua` (Pixel glow, proc overlays) | Standard button borders | 🔴 **Target for Phase 1** |
| **First Install Wizard** | `EllesmereUI_FirstInstall.lua` (Step-by-step setup guide) | Immediate default layout | 🟡 **Target for Phase 2** |

---

## 2. Feature-by-Feature Comparison Matrix

| Module / Feature System | EllesmereUI Implementation | AuraUI Implementation | Status |
| :--- | :--- | :--- | :--- |
| **Action Bars** | `EllesmereUIActionBars` | `Modules/ActionBars.lua` | 🟢 Parity |
| **Unit Frames** | `EllesmereUIUnitFrames` | `Modules/UnitFrames.lua` | 🟢 Parity |
| **Nameplates** | `EllesmereUINameplates` | `Modules/Nameplates.lua` | 🟢 Parity |
| **Party & Raid Frames** | `EllesmereUIRaidFrames` | `Modules/RaidFrames.lua` | 🟢 Parity |
| **Cooldown Manager** | `EllesmereUICooldownManager` | `Modules/Cooldowns.lua` | 🟢 Parity |
| **Resource & Cast Bars** | `EllesmereUIResourceBars` | `Modules/ResourceBars.lua` | 🟢 Parity |
| **Buff Reminders** | `EllesmereUIAuraBuffReminders` | `Modules/BuffReminders.lua` | 🟢 Parity |
| **Blizzard UI Reskins** | `EllesmereUIBlizzardSkin` | `Modules/Skinning.lua` | 🟢 Parity |
| **Cursor Effects** | `EllesmereUI_Mouse.lua` | `Modules/CursorEffects.lua` | 🟢 Parity |
| **Quality of Life** | `EllesmereUIQoL` | `Modules/QualityOfLife.lua` | 🟢 Parity |
| **Mythic+ Keystone HUD** | `EllesmereUIMythicTimer` | `Modules/MythicPlus.lua` | 🟢 Parity |
| **Skyriding HUD** | `EllesmereUIForeverEssentials` | `Modules/SkyridingHUD.lua` | 🟢 Parity |
| **Minimap & Datatexts** | `EllesmereUIMinimap` | `Modules/Minimap.lua` | 🟢 Parity |
| **Friends List** | `EllesmereUIFriends` | `Modules/FriendsList.lua` | 🟢 Parity |
| **Chat Enhancements** | `EllesmereUIChat` | `Modules/Chat.lua` | 🟢 Parity |
| **Quest Tracker** | `EllesmereUIQuestTracker` | `Modules/QuestTracker.lua` | 🟢 Parity |
| **Damage Meter** | `EllesmereUIDamageMeters` | `Modules/DamageMeter.lua` | 🟢 Parity |
| **Combined Bags** | `EllesmereUIBags` | `Modules/Bags.lua` | 🟢 Parity |
| **Data Progress Bars** | `EllesmereUIDataBars` | `Modules/DataBars.lua` | 🟢 Parity |
| **Party Mode** | `EllesmereUI_PartyMode.lua` | `Modules/PartyMode.lua` | 🟢 Parity |
| **UI Utilities** | `EllesmereUIQuickdraw` | `Modules/UIUtilities.lua` | 🟢 Parity |
| **Profile Import/Export** | `LibDeflate` string import/export | Not implemented | 🔴 Missing |
| **Spell Range Desaturation** | `EllesmereUI_Range.lua` | Not implemented | 🔴 Missing |
| **Mouseover Click-Casting** | `EllesmereUI_Mouse.lua` | Not implemented | 🔴 Missing |
| **Interrupt / Kick Tracker** | `EllesmereUI_Kick.lua` | Not implemented | 🔴 Missing |
| **Button Proc Glow Engine** | `EllesmereUI_Glows.lua` | Not implemented | 🔴 Missing |
| **First Install Wizard** | `EllesmereUI_FirstInstall.lua` | Not implemented | 🔴 Missing |
| **Mana-Regen Spark** | `EllesmereUI_ManaRegenSpark.lua` | Not implemented | 🔴 Missing |
| **Macro Factory Generator** | `EUI_MacroFactory.lua` | Not implemented | 🔴 Missing |

---

## 3. Detailed Development Roadmap for AuraUI

### 🚀 Phase 1: Core Combat & Utility Engine Gaps (High Priority)

1. **Spell Range Engine (`AuraUI/Engine/Range.lua`)**:
   - Monitor target distance via `IsSpellInRange` or `C_Spell.IsSpellInRange`.
   - Desaturate/red-tint action buttons dynamically when out of range or lacking resource/mana.

2. **Mouseover & Click-Casting System (`AuraUI/Modules/ClickCasting.lua`)**:
   - Provide an in-game GUI allowing players to bind spells directly to mouse buttons on unit frames (e.g. `LeftButton` = Target, `RightButton` = Menu, `Shift-LeftButton` = Flash Heal, `Ctrl-RightButton` = Cleanse).

3. **Interrupt & Kick Tracker (`AuraUI/Modules/InterruptTracker.lua`)**:
   - Listen for `COMBAT_LOG_EVENT_UNFILTERED` (`SPELL_INTERRUPT`).
   - Track party member kick cooldowns and announce successful interrupts in party/raid chat.

4. **Proc & Button Glow Engine (`AuraUI/Engine/Glows.lua`)**:
   - Integrate custom action button glows (Pixel Glow, Auto-cast Glow, Proc Highlights) when spells become available.

5. **Profile Import / Export String Sharing (`AuraUI/Engine/ProfileSharing.lua`)**:
   - Implement base64 encoding/decoding for profile strings so players can copy and share layout strings with friends.

---

### 🎨 Phase 2: User Experience & Onboarding (Medium Priority)

1. **Onboarding Setup Wizard (`AuraUI/Engine/FirstInstall.lua`)**:
   - First-time login popup guide walking players through selecting their preferred UI style (Modern Flat vs Glossy), profile preset (Healer, Tank, DPS), and Edit Mode grid scaling.

2. **Mana-Regen 5-Second Spark Indicator (`AuraUI/Modules/ManaSpark.lua`)**:
   - Adds a moving spark ticker on healer mana bars indicating 2-second energy/mana ticks and 5-second rule cast pauses.

3. **Global Feature Search Filter in Options (`OptionsPanel.lua`)**:
   - Live filtering text input in the settings panel to quickly search for any setting across all 21 modules.

---

### 🛠️ Phase 3: Advanced Customization Tools (Lower Priority)

1. **Automated Macro Factory (`AuraUI/Modules/MacroFactory.lua`)**:
   - Auto-generates useful combat macros (Mouseover Heal, Focus Kick, Arena Target 1/2/3).

2. **Advanced Visibility Driver (`AuraUI/Engine/Visibility.lua`)**:
   - Allows users to set custom macro visibility conditions on any frame (e.g. `[combat] show; hide` or `[group] show; hide`).

---

## 4. Summary & Recommended Next Steps

AuraUI already has full structural parity with EllesmereUI across all **21 core module categories**, an **Interactive Edit Mode**, **Spec-Based Profile Switching**, and an **Automated Dual-Runner Test Suite**.

To reach complete functional equivalence with EllesmereUI's advanced combat features, our next development sprint should focus on implementing:
1. **Profile Import/Export String Sharing**
2. **Spell Range Desaturation Engine**
3. **Mouseover & Click-Casting Module**
4. **Interrupt & Kick Tracker**
5. **Button Proc Glow Engine**
