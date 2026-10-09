---
name: wow-forever-compat
description: >-
  Use this skill whenever writing or inspecting World of Warcraft Lua code targeting the WoW: Forever client.
  Provides API compatibility guidelines, client build quirks, safe fallback wrappers, and sound ID references to avoid runtime Lua errors.
---

# Multi-Client API & Compatibility Guide (Midnight, Forever, Mists of Pandaria)

AuraUI targets three game client environments with isolated flavor manifests:

| Client Flavor | Game Type Tag | Interface Range | Primary TOC | Detected Flag |
| :--- | :--- | :--- | :--- | :--- |
| **WoW Midnight** | `standard` | `>= 120000` | `<Addon>.toc` | `AuraUI.IS_MIDNIGHT` |
| **WoW: Forever** | `camelot` | `16000 - 19999` | `<Addon>_Camelot.toc` | `AuraUI.IS_FOREVER` |
| **Mists of Pandaria** | `mists` | `50000 - 59999` | `<Addon>_Mists.toc` | `AuraUI.IS_MOP` |

---

## 1. Quick API Compatibility Rules

### 🚫 Prohibited Retail APIs (Do NOT use on WoW: Forever)
| Modern Retail API | Why It Fails | Safe WoW: Forever Alternative |
| :--- | :--- | :--- |
| `C_UnitAuras.GetAuraDataByIndex` | Namespace does not exist | `UnitBuff(unit, i)` or `UnitDebuff(unit, i)` |
| `C_Container.GetContainerNumSlots` | Container namespace absent on older builds | Fallback wrapper: `(C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots` |
| `C_Container.GetContainerItemID` | Container namespace absent on older builds | `(C_Container and C_Container.GetContainerItemID) or GetContainerItemID` |
| `C_Spell.GetSpellInfo` | Modern spell namespace | `GetSpellInfo(spellID)` or `GetSpellTexture(spellID)` |
| `PlaySoundFile("sound/...")` | Requires file path | Use numeric sound ID via `PlaySound(soundID, "Master")` |
| `C_Traits.*` / `C_ClassTalents.*` | Retail talent tree system | `GetNumTalents()`, `GetTalentInfo()`, `GetSpecialization()` |

---

## 2. Safe Fallback Patterns

### Container / Bag APIs
Always wrap bag calls with fallback guards:
```lua
local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink

local function ScanBag(bagID)
    local numSlots = GetNumSlots(bagID)
    for slot = 1, numSlots do
        local link = GetItemLink(bagID, slot)
        -- process item
    end
end
```

### Buff / Debuff Scanning
WoW: Forever uses the classic return order for `UnitDebuff`:
```lua
-- UnitDebuff returns: name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId
local function FindDebuff(unit, targetSpellId)
    for i = 1, 40 do
        local name, icon, count, _, duration, expires, _, _, _, spellId = UnitDebuff(unit, i)
        if not name then break end
        if spellId == targetSpellId then
            return { name = name, count = count, duration = duration, expires = expires }
        end
    end
    return nil
end
```

### Frame Backdrops (`BackdropTemplate`)
Modern WoW requires inheriting `"BackdropTemplate"` when creating frames with backdrops. Older classic clients may have `SetBackdrop` directly on frames:
```lua
local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
if f.SetBackdrop then
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.08, 0.09, 0.11, 0.95)
    f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
end
```

### Combat Lockdown Guards
Always respect `InCombatLockdown()` before modifying protected frames or textures:
```lua
if InCombatLockdown() then
    -- Queue update or defer until PLAYER_REGEN_ENABLED
    addonTable:RegisterEvent("PLAYER_REGEN_ENABLED", function(event)
        -- perform secure frame updates
    end)
    return
end
```

---

## 3. Audio & Sound IDs

Refer to [sound_ids.md](./references/sound_ids.md) for the complete list of verified numeric sound IDs compatible with `PlaySound(id, "Master")`.

---

## 4. Defensive Polyfills & Classic Textures

- **`issecretvalue`**: Polyfilled in `AuraUI_ClientGate.lua` to return `false` on clients without secret value semantics.
- **`C_Container`**: Wrapped in `AuraUI_ClientGate.lua` with fallback to `_G` functions for older Classic/MoP builds.
- **Texture / Icon IDs**: Modern retail icon IDs (`7500000+`) do not exist on Forever or MoP Classic. Use classic file IDs (`134400...`) to prevent missing texture green squares.
