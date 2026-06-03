@echo off
setlocal enabledelayedexpansion
set "REPO_ROOT=D:\Coursyria\Coursyria"
set "PROXY_SERVER=http://10.12.207.175:7071"
cls
echo ====================================================
echo     COURSYRIA MERGE: DEV TO MAIN (v2.2)
echo ====================================================
echo [*] Navigating to repo...
pushd "%REPO_ROOT%"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Path not found.
    pause
    exit /b 1
)
echo [*] Cleaning git locks...
taskkill /F /IM git.exe /T >nul 2>&1
if exist ".git\index.lock" del /f /q ".git\index.lock"
set /p USE_PROXY="Do you have a proxy? (yes/non): "
echo [*] Configuring Git...
git config core.autocrlf true
set "http_proxy="
set "https_proxy="
set "HTTP_PROXY="
set "HTTPS_PROXY="
if /i "%USE_PROXY%"=="non" (
    echo [*] Mode: No Proxy
    git config --local http.proxy ""
    git config --local https.proxy ""
) else (
    echo [*] Mode: Proxy %PROXY_SERVER%
    git config --local http.proxy "%PROXY_SERVER%"
    git config --local https.proxy "%PROXY_SERVER%"
)
echo [*] Saving local work (Stash)...
git stash save "merge_auto_stash"
echo [*] Updating dev branch...
git checkout dev
git fetch origin
git pull origin dev
echo [*] Preparing main branch...
git checkout main || git checkout -b main
git pull origin main 2>nul
echo [*] Merging dev into main...
git merge dev --no-edit
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Merge conflict detected.
    pause
    popd
    exit /b 1
)
echo [*] Pushing to GitHub...
git push origin main
if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Merge completed.
) else (
    echo [FAILURE] Push failed. Check your GitHub branch rules.
    pause
)
echo [*] Returning to dev...
git checkout dev
git stash pop 2>nul
echo [*] Operation Finished.
pause
popd
exit /b 0
