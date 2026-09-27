#!/usr/bin/env python3
"""
AuraUI Automated Scaffolder Script
Usage:
    python scaffold.py --name <Name> --type <module|engine> --desc "<Description>"
"""

import os
import sys
import argparse

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))

MODULE_TEMPLATE = """-------------------------------------------------------------------------------
-- AuraUI / Modules/{name}.lua
-- {desc}
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local {name} = addonTable:NewModule("{name}")

-------------------------------------------------------------------------------
-- Module State
-------------------------------------------------------------------------------
{name}.enabled = true
{name}.frame   = nil

-------------------------------------------------------------------------------
-- Frame Creation
-------------------------------------------------------------------------------
local function Create{name}Frame()
    local f = CreateFrame("Frame", "AuraUI{name}Frame", UIParent, "BackdropTemplate")
    f:SetSize(200, 40)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    if f.SetBackdrop then
        f:SetBackdrop({{
            bgFile   = "Interface\\\\Buttons\\\\WHITE8X8",
            edgeFile = "Interface\\\\Buttons\\\\WHITE8X8",
            edgeSize = 1,
        }})
        f:SetBackdropColor(0.08, 0.09, 0.11, 0.95)
        f:SetBackdropBorderColor(0, 0.9, 1, 0.6)
    end

    return f
end

-------------------------------------------------------------------------------
-- Lifecycle Methods
-------------------------------------------------------------------------------
function {name}:OnInitialize()
    self.frame = Create{name}Frame()

    local em = addonTable.engine.EditMode
    if em and em.RegisterMover then
        em:RegisterMover(self.frame, "{name}", "{var_name}Pos")
    end

    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.{name} ~= nil then
        self.enabled = AuraUIDB.modules.{name}
    end
end

function {name}:OnEnable()
    if self.enabled and self.frame then
        self.frame:Show()
    end
end

function {name}:OnDisable()
    self.enabled = false
    if self.frame then
        self.frame:Hide()
    end
end
"""

ENGINE_TEMPLATE = """-------------------------------------------------------------------------------
-- AuraUI / Engine/{name}.lua
-- {desc}
-------------------------------------------------------------------------------

local addonName, addonTable = ...
local {name} = {{}}
addonTable.engine.{name} = {name}

-------------------------------------------------------------------------------
-- State & Properties
-------------------------------------------------------------------------------
{name}.enabled = true

-------------------------------------------------------------------------------
-- Public API
-------------------------------------------------------------------------------
function {name}:Enable()
    self.enabled = true
end

function {name}:Disable()
    self.enabled = false
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
function {name}:Initialize()
    if AuraUIDB and AuraUIDB.modules and AuraUIDB.modules.{name} ~= nil then
        self.enabled = AuraUIDB.modules.{name}
    end
end

addonTable:RegisterEvent("PLAYER_LOGIN", function()
    {name}:Initialize()
end)
"""

def scaffold(name, item_type, desc):
    item_type = item_type.lower()
    var_name = name[0].lower() + name[1:]
    
    if item_type == "module":
        target_dir = os.path.join(ROOT_DIR, "AuraUI", "Modules")
        target_file = os.path.join(target_dir, f"{name}.lua")
        content = MODULE_TEMPLATE.format(name=name, desc=desc, var_name=var_name)
        toc_entry = f"Modules\\{name}.lua"
    elif item_type == "engine":
        target_dir = os.path.join(ROOT_DIR, "AuraUI", "Engine")
        target_file = os.path.join(target_dir, f"{name}.lua")
        content = ENGINE_TEMPLATE.format(name=name, desc=desc)
        toc_entry = f"Engine\\{name}.lua"
    else:
        print(f"[ERROR] Unknown type '{item_type}'. Use 'module' or 'engine'.")
        sys.exit(1)

    if os.path.exists(target_file):
        print(f"[WARN] File already exists: {target_file}")
    else:
        with open(target_file, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"[CREATED] {target_file}")

    # Update TOC file
    toc_path = os.path.join(ROOT_DIR, "AuraUI", "AuraUI.toc")
    with open(toc_path, "r", encoding="utf-8") as f:
        toc_text = f.read()

    if toc_entry not in toc_text:
        if item_type == "engine":
            marker = "Config.lua"
            toc_text = toc_text.replace(marker, f"{toc_entry}\n{marker}")
        else:
            marker = "Modules\\TestRunner.lua"
            toc_text = toc_text.replace(marker, f"{toc_entry}\n{marker}")
        with open(toc_path, "w", encoding="utf-8") as f:
            f.write(toc_text)
        print(f"[UPDATED] AuraUI.toc added {toc_entry}")

    # If engine, update tests/run_tests.py
    if item_type == "engine":
        test_runner_path = os.path.join(ROOT_DIR, "tests", "run_tests.py")
        with open(test_runner_path, "r", encoding="utf-8") as f:
            test_text = f.read()
        engine_str = f'"{name}.lua"'
        if engine_str not in test_text:
            test_text = test_text.replace('"Media.lua"]', f'{engine_str}, "Media.lua"]')
            with open(test_runner_path, "w", encoding="utf-8") as f:
                f.write(test_text)
            print(f"[UPDATED] tests/run_tests.py added {engine_str}")

    print(f"\n[DONE] Scaffolding for {name} ({item_type}) complete!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AuraUI Component Scaffolder")
    parser.add_argument("--name", required=True, help="Name of the module or engine subsystem")
    parser.add_argument("--type", choices=["module", "engine"], default="module", help="Component type")
    parser.add_argument("--desc", default="AuraUI component", help="Brief description")
    args = parser.parse_args()
    scaffold(args.name, args.type, args.desc)
