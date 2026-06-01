@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
color 0A

:: ==============================================================================
:: PROJECT: COURSYRIA GLOBAL - DEV-ONLY BACKUP PIPELINE
:: PURPOSE: Backup EVERYTHING under D:\Coursyria\Coursyria to branch dev ONLY
:: ==============================================================================

set "REPO_ROOT=D:\Coursyria\Coursyria"
set "REPO_URL=https://github.com/mnidaleddin-hub/Coursyria.git"
set "PROXY_SERVER=http://10.12.207.175:7071"
set "LOG_FILE=%REPO_ROOT%\backup.log"

cls
echo ====================================================
echo     COURSYRIA DEV-ONLY BACKUP v3.3
echo ====================================================

echo [*] Navigating to: %REPO_ROOT%
pushd "%REPO_ROOT%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Path not found.
    pause
    exit /b 1
)

set /p USE_PROXY="هل يتوفر بروكسي؟ (yes/non): "

echo [*] Setting Git Configs...
git config core.autocrlf true

:: Clear environment variables proxy for this session
set "http_proxy="
set "https_proxy="
set "HTTP_PROXY="
set "HTTPS_PROXY="

if /i "%USE_PROXY%"=="non" (
    echo [*] Running without proxy...
    :: Override any global/system proxy by setting local to empty string
    git config --local http.proxy ""
    git config --local https.proxy ""
) else (
    echo [*] Running with proxy: %PROXY_SERVER%
    git config --local http.proxy "%PROXY_SERVER%"
    git config --local https.proxy "%PROXY_SERVER%"
)

echo [*] Current Proxy in Git:
git config --local http.proxy

if not exist ".git" (
    echo [*] Initializing Git...
    git init
    git remote add origin "%REPO_URL%"
)

echo [*] Syncing remote dev branch info...
git fetch origin dev 2>nul

echo [*] Switching to dev branch...
git checkout dev 2>nul || git checkout -b dev

echo [*] Staging files...
git add -A

set "COMMIT_MSG=Auto backup %date% %time%"
echo [*] Committing: !COMMIT_MSG!
git commit -m "!COMMIT_MSG!" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [!] No new changes to commit.
) else (
    echo [✓] Commit successful.
)

echo [*] Pushing to GitHub (dev branch only)...
git push origin dev --force-with-lease

if %ERRORLEVEL% equ 0 (
    echo ====================================================
    echo     ✅✅✅  SUCCESS  ✅✅✅
    echo     Backup completed and pushed to dev.
    echo ====================================================
    echo [%date% %time%] SUCCESS >> "%LOG_FILE%"
) else (
    echo ====================================================
    echo     ❌❌❌  FAILURE  ❌❌❌
    echo     Push to dev failed.
    echo ====================================================
    echo [%date% %time%] FAILED >> "%LOG_FILE%"
    popd
    pause
    exit /b 1
)

echo.
echo LAST 3 ATTEMPTS:
if exist "%LOG_FILE%" (
    powershell -Command "Get-Content '%LOG_FILE%' -Tail 3" 2>nul
) else (
    echo No logs yet.
)

timeout /t 5 >nul
popd
exit /b 0