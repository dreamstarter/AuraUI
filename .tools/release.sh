#!/usr/bin/env bash
# AuraUI Local Packager Script (BigWigs packager parity)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

echo "=================================================================="
echo "[1/3] Running AuraUI Diagnostic Verification Suite..."
echo "=================================================================="
python3 tests/run_tests.py || python tests/run_tests.py

PACKAGER_DIR="${ROOT_DIR}/.tools"
PACKAGER_SCRIPT="${PACKAGER_DIR}/packager.sh"
PACKAGER_VERSION="v2.6.1"

echo "=================================================================="
echo "[2/3] Fetching BigWigs Packager (${PACKAGER_VERSION})..."
echo "=================================================================="
if [ ! -f "${PACKAGER_SCRIPT}" ]; then
    curl -sSL "https://raw.githubusercontent.com/BigWigsMods/packager/${PACKAGER_VERSION}/release.sh" -o "${PACKAGER_SCRIPT}"
    chmod +x "${PACKAGER_SCRIPT}"
fi

echo "=================================================================="
echo "[3/3] Executing BigWigs Packager (Dry Run / Local Packaging)..."
echo "=================================================================="
# -d: dry run (skip uploading)
# -z: create zip archive in .release/
bash "${PACKAGER_SCRIPT}" -d -z "$@"

echo ""
echo "[SUCCESS] Local packaging complete! Check .release/ for generated archives."

