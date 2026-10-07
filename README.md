# AuraUI - High-Performance World of Warcraft Interface Suite

**AuraUI** is an all-in-one, high-performance interface suite for World of Warcraft and WoW: Forever. Built on the **Aura Neon Glass** design philosophy, it features deep obsidian backdrops, crisp 1-pixel borders, Electric Cyan (`#00E5FF`) and Deep Violet (`#7C4DFF`) accents, 22 integrated modular systems, an interactive Edit Mode alignment grid, automatic spec-based profile switching, and an automated diagnostic test suite.

---

## 🧩 Complete Module Suite (22 Modules)

1. **AuraUI**: Core shared framework, media textures, fonts, profile management, and innovative utilities.
2. **AuraUIOptions**: Comprehensive Dark Glass interactive configuration window (`/aui config`).
3. **AuraUIActionBars**: Dark Glass action bar containers, button styling, hotkey formatting, and quest XP overlay.
4. **AuraUIUnitFrames**: Custom Player, Target, Focus, Pet, and Target-of-Target frames with class power and castbars.
5. **AuraUIRaidFrames**: Compact 5-man party and 40-man raid grid frames with role icons, debuff manager, and click-casting.
6. **AuraUINameplates**: High-contrast enemy and friendly nameplates with castbars, threat borders, and debuff coloring.
7. **AuraUICooldownManager**: Spell cooldown tracking grid with reverse swipe, timer text, and custom proc glows.
8. **AuraUIResourceBars**: Class resource tracking (Combo Points, Holy Power, Runes, Soul Shards, Energy, Mana).
9. **AuraUIAuraBuffReminders**: Missing self-buff and consumable reminders (Flask, Food, Weapon Enchants).
10. **AuraUIBlizzardSkin**: Dark Glass styling for Blizzard dialogs, spellbook, talents, merchant, and tooltips.
11. **AuraUIMinimap**: Borderless square or circular minimap with curved button arc, coordinates, and datatexts.
12. **AuraUIBags**: Combined inventory container with item quality borders, category sorting, and instant search.
13. **AuraUIChat**: Chat frame skinning, spam filtering, URL copy, timestamp formatting, and short channel names.
14. **AuraUIQuestTracker**: Objective tracker skinning and auto-collapse in instances.
15. **AuraUIDamageMeters**: Lightweight embedded DPS/HPS meter and threat bar.
16. **AuraUIDataBars**: Experience, Reputation, and Honor progress bars with quest log XP forecast.
17. **AuraUIQoL**: Fast loot, vendor junk selling, auto-repair, cinematic skipper, and SCT hit staggering.
18. **AuraUIQuickdraw**: Fast radial shortcuts and utility keybinding wheel.
19. **AuraUIForeverEssentials**: Dedicated Threat Meter and Flight Timer for WoW: Forever (16001).
20. **AuraUIFriends**: Enhanced Friends and Guild roster list with class coloring.
21. **AuraUILocales**: Multi-language localization engine and font mapping.
22. **AuraUIMythicTimer**: Mythic+ keystone HUD with affix tracking and death counters.

---

## 💡 Unique Innovations

* **Smart Auto-Marker (`AuraUI_AutoMarker`)**: Automatically marks priority targets and crowd control assignments based on role.
* **Loot Council Lite (`AuraUI_LootCouncil`)**: In-game raid loot distribution voting interface for guilds and master looters.
* **Map Notes & Waypoints (`AuraUI_MapNotes`)**: Place custom pins and shareable coordinate waypoints with guild members.
* **Guild Roster & Officer Notes (`AuraUI_GuildNotes`)**: In-line editor and search tools for managing guild rank permissions and member notes.
* **Sound Pack Customizer (`AuraUI_SoundPackCustomizer`)**: Select and assign custom audio cues for procs, kicks, and alerts.
* **Smart Chat Filter (`AuraUIChat_Filter`)**: Lightweight regex-driven spam filter that cleans trade and general chat.

---

## 🕹️ Slash Commands

* `/aui` or `/auraui` - Open the interactive configuration window
* `/aui unlock` or `/aui move` - Toggle Interactive Edit Mode (Move & snap frames)
* `/aui lock` - Save and exit Edit Mode
* `/aui spec` - View current spec profile status
* `/aui test` - Run the automated diagnostic test suite (`tests/run_tests.py` or in-game)
* `/aui reset` - Reset current profile or module back to defaults

---

## 🧪 Testing & Quality Assurance

AuraUI includes an automated diagnostic test suite verifying manifest integrity, client gates, and feature logic:

```bash
# Run tests headlessly
python tests/run_tests.py

# Package release for CurseForge (zero-nesting release archive)
python package.py
```

---

## 📦 CurseForge Distribution

Release packages are generated using the zero-nesting packaging script:
```bash
python package.py [--deploy "<path>/Interface/AddOns"]
```
Outputs: `dist/AuraUI-v<version>.zip` ready for direct upload to CurseForge or the CurseForge App.
