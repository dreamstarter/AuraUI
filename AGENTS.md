# Project Guidelines & Agent Rules

## Code Style

- **Lua 5.1 only**: No `goto`, no `::labels::`.
- **ASCII only**: In code, comments, and strings. No em dashes, no curly quotes. Multi-byte punctuation corrupts in the packaging pipeline.
- **Match surrounding code**: Before building any options widget (row, slider, swatch, cog popup), find the nearest existing example in the same file and copy its shape. The codebase is consistent on purpose.
- **House UI systems, not Blizzard defaults**:
  - Plain-text tooltips use `AuraUI.ShowWidgetTooltip` / `HideWidgetTooltip` (item/spell tooltips via `GameTooltip:SetHyperlink` and friends are fine).
  - Confirmations use `AuraUI:ShowConfirmPopup`, never `StaticPopup_Show`.
- **Options pages layout**:
  - Use two-slot rows (`W:DualRow`).
  - Fill slots left to right with no gaps.
  - Never pass `nil` as the right slot (use `AuraUI.BlankRowCfg()`, a fresh blank label on every call).
  - Only the last row of a section may have an empty slot (filled with `AuraUI.BlankRowCfg()`).
- **Source Code Integrity**: Never leave diff preview placeholders (`... [truncated]`, `... [truncated for diff preview]`), unclosed literal strings, or git conflict markers in any code or comments. Always run `python tests/run_tests.py` before finalizing changes to verify Section 12 integrity checks pass.
- **Multi-Client Invariants**: AuraUI actively targets three client flavors:
  - **WoW Midnight** (`120000+` / `standard`)
  - **WoW: Forever** (`16000-19999` / `camelot`)
  - **Mists of Pandaria Classic** (`50000-59999` / `mists`)
  Never remove or break client gates in `AuraUI_ClientGate.lua`, and ensure changes maintain compatibility across all three flavor TOC manifests (`.toc`, `_Camelot.toc`, and `_Mists.toc`).

## AI Coding Rules

- **Never study or look at another addon's code** unless it has an open source license or its author has given permission. That includes letting an AI tool read, search, summarize, or learn from it.
- **Research the game through Blizzard's own UI source** (https://github.com/Gethe/wow-ui-source) and look up game data on https://wago.tools/.
- **Only submit original code**: Nothing may be copied from another addon or project, including code an AI tool reproduces from somewhere else. Check what your assistant generates before you submit it.
- **Keep comments brief**: Only what is needed to understand the code: no restating what a line does, no change history.
- **Reuse what already exists**: Build on the existing logic and the shared, centralized helpers instead of writing your own copies, and follow the patterns already in the file.
