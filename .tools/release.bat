@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%.."

echo ==================================================================
echo [1/2] Running AuraUI Diagnostic Verification Suite...
echo ==================================================================
python tests/run_tests.py
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Diagnostic tests failed! Aborting packaging.
    exit /b %ERRORLEVEL%
)

echo ==================================================================
echo [2/2] Running CurseForge Release Packager...
echo ==================================================================
python package.py %*
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Packaging failed with exit code %ERRORLEVEL%.
    exit /b %ERRORLEVEL%
)

echo [SUCCESS] Release packaging complete!
exit /b 0
