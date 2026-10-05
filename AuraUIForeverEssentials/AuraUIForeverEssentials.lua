if AUI_CLIENT_BLOCKED then return end -- pre-12.1 client failsafe (AuraUI_ClientGate.lua)
-------------------------------------------------------------------------------
--  AuraUIForeverEssentials.lua  (WoW Forever only)
--  Essential tools for WoW Forever. Each feature lives in its own file, listed
--  after this one in the TOC; this file publishes the module.
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...
if not (AuraUI and AuraUI._ModuleNS) then AUI_CLIENT_BLOCKED = true; return end -- stale-parent guard: a partially updated install (old parent, new child) goes dormant via the line-1 failsafe instead of erroring
AuraUI._ModuleNS[ADDON_NAME] = ns  -- LOD options files read this module ns via the registry

-- Lifecycle object (OnInitialize / OnEnable) for features that need one. No
-- per-profile DB: every feature so far keeps account-wide settings.
ns.addon = AuraUI.Lite.NewAddon(ADDON_NAME)
