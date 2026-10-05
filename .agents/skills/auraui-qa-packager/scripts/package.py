#!/usr/bin/env python3
"""
AuraUI Distribution Packager Script
Usage:
    python package.py [--deploy "path/to/Interface/AddOns"]
"""

import os
import sys
import shutil
import zipfile
import subprocess
import argparse

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))

def run_tests():
    print("[1/3] Running AuraUI Diagnostic Suite...")
    test_script = os.path.join(ROOT_DIR, "tests", "run_tests.py")
    res = subprocess.run([sys.executable, test_script], cwd=ROOT_DIR)
    if res.returncode != 0:
        print("[ERROR] Tests failed! Aborting packaging.")
        sys.exit(1)
    print("  -> All tests passed successfully.\n")

def package_zip(deploy_path=None):
    print("[2/3] Building Release Archive...")
    dist_dir = os.path.join(ROOT_DIR, "dist")
    os.makedirs(dist_dir, exist_ok=True)
    
    zip_name = "AuraUI-Suite-v1.1.0.zip"
    zip_path = os.path.join(dist_dir, zip_name)
    
    folders_to_include = sorted([
        d for d in os.listdir(ROOT_DIR)
        if os.path.isdir(os.path.join(ROOT_DIR, d)) and d.startswith("AuraUI")
    ])
    print(f"  -> Bundling {len(folders_to_include)} suite addons: {', '.join(folders_to_include)}")
    
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for folder in folders_to_include:
            src_folder = os.path.join(ROOT_DIR, folder)
            for root, dirs, files in os.walk(src_folder):
                for file in files:
                    full_file = os.path.join(root, file)
                    rel_path = os.path.relpath(full_file, ROOT_DIR)
                    zf.write(full_file, rel_path)
    
    print(f"  -> Release package created at: {zip_path}")

    if deploy_path:
        print(f"\n[3/3] Deploying to WoW AddOns Directory: {deploy_path}")
        if not os.path.exists(deploy_path):
            print(f"[ERROR] Destination does not exist: {deploy_path}")
            sys.exit(1)
        for folder in folders_to_include:
            src = os.path.join(ROOT_DIR, folder)
            dst = os.path.join(deploy_path, folder)
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
            print(f"  -> Deployed {folder} to {dst}")
        print("  -> Deployment complete!")
    else:
        print("\n[3/3] Deployment skipped (no --deploy path provided).")

    print("\n[SUCCESS] Packaging process complete!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AuraUI Release Packager")
    parser.add_argument("--deploy", help="Optional path to World of Warcraft Interface/AddOns directory")
    args = parser.parse_args()
    
    run_tests()
    package_zip(args.deploy)
