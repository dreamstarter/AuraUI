# AuraUI - High-Performance World of Warcraft AddOn Suite

**AuraUI** is a lightweight, high-performance UI suite for World of Warcraft:Forever, featuring 21 fully integrated modular systems, an interactive Edit Mode alignment grid, automatic spec-based profile switching, and an automated dual-runner test suite.

---

## 🧩 Complete Module Suite (21 Modules)

1. ⚔️ **[ActionBars.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/ActionBars.lua)**: Action bar containers, button styling & keybind text formatting.
2. 💚 **[UnitFrames.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/UnitFrames.lua)**: Custom Player, Target, Focus, Pet, and Boss unit frames.
3. 🏷️ **[Nameplates.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/Nameplates.lua)**: Custom enemy & friendly nameplates with castbars and threat highlights.
4. 🛡️ **[RaidFrames.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/RaidFrames.lua)**: Compact Party & Raid grid frames with role icons and debuff tracking.
5. ⏳ **[Cooldowns.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/Cooldowns.lua)**: Spell cooldown manager with timer icons and countdown numbers.
6. ⚡ **[ResourceBars.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/ResourceBars.lua)**: Class resource tracking (Combo Points, Holy Power, Shards, Runes, Energy, Mana).
7. 🔔 **[BuffReminders.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/BuffReminders.lua)**: Missing self-buff reminders (Flask, Food, Rune, Weapon Enchants).
8. 🎨 **[Skinning.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/Skinning.lua)**: Reskins Blizzard UI windows, tooltips, dialogs, and popups.
9. 🎯 **[CursorEffects.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/CursorEffects.lua)**: High-visibility cursor trails & glow effects for fast combat tracking.
10. ⚡ **[QualityOfLife.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/QualityOfLife.lua)**: Merchant auto-sell junk, auto-repair, and fast looting.
11. 🏆 **[MythicPlus.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/MythicPlus.lua)**: Custom Mythic+ Keystone HUD with timer, death counter, and affixes.
12. 🐉 **[SkyridingHUD.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/SkyridingHUD.lua)**: Skyriding / Dragonriding Vigor bar HUD & speedometer.
13. 📍 **[Minimap.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/Minimap.lua)**: Borderless minimap skin and dynamic datatext bar (FPS, MS, Gold).
14. 👥 **[FriendsList.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/FriendsList.lua)**: Enhanced BNet / Friends list with class coloring and zone info.
15. 💬 **[Chat.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/Chat.lua)**: Chat frame skinning, URL copy links, timestamp formatting, and short channel names.
16. 📜 **[QuestTracker.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/QuestTracker.lua)**: Objective tracker skinning and auto-collapse in dungeons/raids.
17. 📊 **[DamageMeter.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/DamageMeter.lua)**: Built-in lightweight DPS/HPS meter and threat bar.
18. 🎒 **[Bags.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/Bags.lua)**: All-in-one combined inventory container with item quality borders.
19. 📈 **[DataBars.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/DataBars.lua)**: Experience, Reputation, Honor, and Renown progress bars.
20. 🎉 **[PartyMode.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/PartyMode.lua)**: Celebratory level-up announcements & dungeon completion effects.
21. 🛠️ **[UIUtilities.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/UIUtilities.lua)**: Quick raid marker bar, character sheet item level display, and combat text tweaks.
22. 🧪 **[TestRunner.lua](file:///d:/Development/personal/wow%20addon%20suite/AuraUI/Modules/TestRunner.lua)**: In-game automated diagnostic suite (`/aui test`).

---

## 🧪 Testing & Quality Assurance

AuraUI includes a **Dual-Runner Test Suite**:

1. **In-Game Diagnostic Test Runner (`/aui test`)**:
   - Run `/aui test` in World of Warcraft to trigger real-time diagnostics on module registrations, profile data integrity, Edit Mode mover anchors, media lookups, and keybind formatters.

2. **Standalone CLI Test Runner ([tests/run_tests.lua](file:///d:/Development/personal/wow%20addon%20suite/tests/run_tests.lua))**:
   - Mocks the World of Warcraft API ([tests/wow_api_mock.lua](file:///d:/Development/personal/wow%20addon%20suite/tests/wow_api_mock.lua)) to allow running automated unit tests headlessly via standard Lua (`lua tests/run_tests.lua`).

---

## 🛠️ Usage Commands

- `/aui test` - Run automated diagnostic tests.
- `/aui unlock` or `/aui move` - Toggle Interactive Edit Mode (Move & snap frames).
- `/aui config` or `/aui options` - Open configuration settings.
- `/aui spec` - View current spec profile status.
