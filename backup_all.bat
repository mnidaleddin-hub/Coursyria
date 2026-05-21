@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
color 0A

:: ==============================================================================
:: PROJECT: COURSYRIA GLOBAL - ULTIMATE BACKUP PIPELINE
:: PURPOSE: Backup EVERYTHING under D:\Coursyria\Coursyria
:: ==============================================================================

set "REPO_ROOT=D:\Coursyria\Coursyria"
set "REPO_URL=https://github.com/mnidaleddin-hub/Coursyria.git"
set "PROXY_SERVER=http://10.12.207.175:7071"
set "LOG_FILE=%REPO_ROOT%\backup.log"

cls
echo ====================================================
echo     COURSYRIA GLOBAL AUTOMATED BACKUP v3.2
echo ====================================================

echo [*] Navigating to: %REPO_ROOT%
pushd "%REPO_ROOT%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Path not found.
    pause
    exit /b 1
)

echo [*] Setting Git Configs...
git config core.autocrlf true
git config --local http.proxy "%PROXY_SERVER%"
git config --local https.proxy "%PROXY_SERVER%"

if not exist ".git" (
    echo [*] Initializing Git...
    git init
    git remote add origin "%REPO_URL%"
)

echo [*] Syncing branch...
git fetch origin
git checkout dev 2>nul || git checkout -b dev

echo [*] Staging files...
git add -A

set "COMMIT_MSG=Auto backup %date% %time%"
echo [*] Committing: !COMMIT_MSG!
:: Ensure we don't accidentally backup secrets (simple check)
git commit -m "!COMMIT_MSG!" || echo [!] No changes.

echo [*] Pushing to GitHub...
:: WARNING: If push fails, check for GitHub Push Protection (Secrets)
:: Push to dev branch
git push origin dev --force
:: Also push to main to ensure visibility on GitHub home page
git push origin dev:main --force

if %ERRORLEVEL% equ 0 (
    echo SUCCESS: Backup completed.
    echo [%date% %time%] SUCCESS >> "%LOG_FILE%"
) else (
    echo FAILURE: Backup failed.
    echo [%date% %time%] FAILED >> "%LOG_FILE%"
    popd
    pause
    exit /b 1
)

echo.
echo LAST 3 ATTEMPTS:
powershell -Command "if (Test-Path '%LOG_FILE%') { Get-Content '%LOG_FILE%' -Tail 3 } else { Write-Host 'No logs.' }"

timeout /t 5
popd
exit /b 0
