#!/usr/bin/env python3
"""
AuraUI CurseForge-Compliant Distribution Packager Script
Builds a verified, zero-nesting release zip archive for CurseForge and World of Warcraft.

Usage:
    python package.py [--deploy "path/to/Interface/AddOns"] [--skip-tests] [--version X.Y.Z]
"""

import os
import sys
import shutil
import zipfile
import subprocess
import argparse
import re

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    reconfigure_stdout = getattr(sys.stdout, "reconfigure", None)
    if callable(reconfigure_stdout):
        reconfigure_stdout(encoding="utf-8")

# Resolve root directory dynamically
current_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = (
    current_dir
    if os.path.exists(os.path.join(current_dir, "AuraUI", "AuraUI.toc"))
    else os.path.abspath(os.path.join(current_dir, "..", "..", "..", ".."))
)

EXCLUDED_DIR_NAMES = {
    ".git", ".github", ".vscode", ".agents", "tests", "project_docs", "dist",
    "__pycache__", ".idea"
}

EXCLUDED_EXTENSIONS = {
    ".py", ".pyc", ".bak", ".orig", ".tmp", ".log", ".DS_Store"
}

EXCLUDED_FILENAMES = {
    ".gitignore", "Thumbs.db", "desktop.ini"
}

def get_suite_version():
    """Extracts the version from AuraUI/AuraUI.toc."""
    toc_path = os.path.join(root_dir, "AuraUI", "AuraUI.toc")
    if os.path.exists(toc_path):
        with open(toc_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                m = re.match(r"^##\s*Version:\s*(.+)$", line.strip())
                if m:
                    return m.group(1).strip()
    return "9.3"

def run_tests():
    print("==================================================================")
    print("[1/3] Running AuraUI Diagnostic Verification Suite...")
    print("==================================================================")
    test_script = os.path.join(root_dir, "tests", "run_tests.py")
    if not os.path.exists(test_script):
        print(f"[ERROR] Test script not found at {test_script}")
        sys.exit(1)
    res = subprocess.run([sys.executable, test_script], cwd=root_dir)
    if res.returncode != 0:
        print("\n[ERROR] Tests failed! Aborting packaging to protect release integrity.")
        sys.exit(1)
    print("  -> All test diagnostics passed with 100% compliance.\n")

def validate_addon_folders():
    """Validates that all AuraUI* folders contain matching .toc files."""
    folders = sorted([
        d for d in os.listdir(root_dir)
        if os.path.isdir(os.path.join(root_dir, d)) and d.startswith("AuraUI")
    ])

    if not folders:
        print("[ERROR] No AuraUI addon folders found in root!")
        sys.exit(1)

    for folder in folders:
        expected_toc = os.path.join(root_dir, folder, f"{folder}.toc")
        if not os.path.exists(expected_toc):
            print(f"[ERROR] Addon folder '{folder}' is missing its manifest: {folder}.toc")
            sys.exit(1)

    return folders

def package_zip(version: str | None = None, deploy_path: str | None = None) -> None:
    version = version or get_suite_version()
    print("==================================================================")
    print(f"[2/3] Building CurseForge-Compliant Release Archive (v{version})...")
    print("==================================================================")

    dist_dir = os.path.join(root_dir, "dist")
    os.makedirs(dist_dir, exist_ok=True)

    zip_name = f"AuraUI-v{version}.zip"
    zip_path = os.path.join(dist_dir, zip_name)

    folders_to_include = validate_addon_folders()
    print(f"  -> Discovered {len(folders_to_include)} verified suite modules:")
    for f in folders_to_include:
        print(f"     * {f}")

    total_files = 0
    total_uncompressed_bytes = 0

    # Build zip archive with ZERO root-level nesting
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for folder in folders_to_include:
            src_folder = os.path.join(root_dir, folder)
            for root, dirs, files in os.walk(src_folder):
                # Filter out excluded directories in-place
                dirs[:] = [d for d in dirs if d not in EXCLUDED_DIR_NAMES]

                for file in files:
                    ext = os.path.splitext(file)[1].lower()
                    if ext in EXCLUDED_EXTENSIONS or file in EXCLUDED_FILENAMES:
                        continue

                    full_file = os.path.join(root, file)
                    rel_path = os.path.relpath(full_file, root_dir).replace("\\", "/")

                    zf.write(full_file, rel_path)
                    total_files += 1
                    total_uncompressed_bytes += os.path.getsize(full_file)

    compressed_bytes = os.path.getsize(zip_path)

    # Post-packaging archive integrity verification
    print("\n  -> Verifying Archive Integrity for CurseForge App Compliance:")
    with zipfile.ZipFile(zip_path, "r") as zf:
        namelist = zf.namelist()
        root_entries: set[str] = set()
        for item in namelist:
            parts = item.split("/")
            root_entries.add(parts[0])

        # Ensure no loose files at root
        for entry in root_entries:
            if not entry.startswith("AuraUI"):
                print(f"[ERROR] Non-addon entry found at zip root: {entry}")
                sys.exit(1)

        # Confirm primary addon manifest exists at root
        if "AuraUI/AuraUI.toc" not in namelist:
            print("[ERROR] AuraUI/AuraUI.toc not found at expected archive path!")
            sys.exit(1)

    print(f"     [PASS] Zero nesting confirmed: all {len(root_entries)} folders sit directly at archive root.")
    print(f"     [PASS] Primary manifest verified: AuraUI/AuraUI.toc present.")
    print(f"     [PASS] Bundled {total_files} files ({total_uncompressed_bytes / 1024 / 1024:.2f} MB uncompressed).")
    print(f"     [PASS] Compressed size: {compressed_bytes / 1024 / 1024:.2f} MB.")
    print(f"  -> Release package created at: {zip_path}")

    if deploy_path:
        print("\n==================================================================")
        print(f"[3/3] Deploying Directly to WoW AddOns Directory: {deploy_path}")
        print("==================================================================")
        if not os.path.exists(deploy_path):
            print(f"[ERROR] Destination AddOns directory does not exist: {deploy_path}")
            sys.exit(1)

        for folder in folders_to_include:
            src = os.path.join(root_dir, folder)
            dst = os.path.join(deploy_path, folder)
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
            print(f"  -> Deployed {folder}")
        print("  -> Direct deployment complete (identical to CurseForge App install).")
    else:
        print("\n[3/3] Deployment skipped (no --deploy path provided).")

    print("\n==================================================================")
    print("[SUCCESS] CurseForge-compliant packaging complete!")
    print("==================================================================")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AuraUI CurseForge Release Packager")
    parser.add_argument("--deploy", help="Optional path to World of Warcraft Interface/AddOns directory")
    parser.add_argument("--skip-tests", action="store_true", help="Skip running the diagnostic test suite")
    parser.add_argument("--version", help="Explicit version override (defaults to AuraUI.toc version)")
    args = parser.parse_args()

    if not args.skip_tests:
        run_tests()
    else:
        print("[INFO] Skipping diagnostic test suite (--skip-tests specified).\n")

    package_zip(version=args.version, deploy_path=args.deploy)
