@echo off
setlocal enabledelayedexpansion

:: ====================================================
::        Coursyria APK Builder - Professional Edition
:: ====================================================

title Coursyria APK Builder

echo.
echo  ####################################################
echo  #                                                  #
echo  #       Coursyria Mobile App - Build System        #
echo  #                                                  #
echo  ####################################################
echo.

:: Check for Flutter Path
set "FLUTTER_PATH=D:\Development\flutter\bin\flutter.bat"
if not exist "%FLUTTER_PATH%" (
    echo [ERROR] Flutter SDK not found at %FLUTTER_PATH%
    set /p FLUTTER_PATH="Please enter the full path to flutter.bat: "
)

:: Menu Options
echo [1] Build Release APK (Split per ABI - Recommended)
echo [2] Build Release APK (Fat APK - Single File)
echo [3] Run Flutter Clean first
echo [4] Run Flutter Pub Get first
echo [5] Exit
echo.
set /p CHOICE="Choose an option (1-5) [Default=1]: "
if "%CHOICE%"=="" set CHOICE=1

if "%CHOICE%"=="5" exit /b
if "%CHOICE%"=="3" (
    echo [STEP] Cleaning project...
    call "%FLUTTER_PATH%" clean
    echo.
    set CHOICE=1
)
if "%CHOICE%"=="4" (
    echo [STEP] Getting dependencies...
    call "%FLUTTER_PATH%" pub get
    echo.
    set CHOICE=1
)

:: Proxy Configuration
echo.
echo ----------------------------------------------------
echo  Proxy Configuration
echo ----------------------------------------------------
set /p PROXY_INPUT="Enter Proxy (e.g. 10.12.207.175:7071) or press ENTER for NO PROXY: "

if "%PROXY_INPUT%"=="" (
    echo [INFO] Building WITHOUT Proxy...
    set "HTTP_PROXY="
    set "HTTPS_PROXY="
    set "GRADLE_OPTS=-Dhttp.proxyHost= -Dhttp.proxyPort= -Dhttps.proxyHost= -Dhttps.proxyPort="
) else (
    echo [INFO] Building WITH Proxy: %PROXY_INPUT%
    for /f "tokens=1,2 delims=:" %%a in ("%PROXY_INPUT%") do (
        set "P_HOST=%%a"
        set "P_PORT=%%b"
    )
    set "HTTP_PROXY=http://%PROXY_INPUT%"
    set "HTTPS_PROXY=http://%PROXY_INPUT%"
    set "GRADLE_OPTS=-Dhttp.proxyHost=!P_HOST! -Dhttp.proxyPort=!P_PORT! -Dhttps.proxyHost=!P_HOST! -Dhttps.proxyPort=!P_PORT!"
)

set "NO_PROXY=localhost,127.0.0.1"

:: Build Command
echo.
echo [STEP] Running Flutter Build...
set "BUILD_ARGS=--release"

if "%CHOICE%"=="1" (
    set "BUILD_ARGS=%BUILD_ARGS% --split-per-abi"
    echo [INFO] Mode: Split per ABI (Optimized size)
) else (
    echo [INFO] Mode: Fat APK (Universal compatibility)
)

:: Ask about --no-pub
set /p NOPUB="Use --no-pub? (y/n) [Default=y]: "
if "%NOPUB%"=="" set NOPUB=y
if /i "%NOPUB%"=="y" set "BUILD_ARGS=%BUILD_ARGS% --no-pub"

echo [EXEC] flutter build apk %BUILD_ARGS%
call "%FLUTTER_PATH%" build apk %BUILD_ARGS%

if %ERRORLEVEL% equ 0 (
    echo.
    echo  ====================================================
    echo  [SUCCESS] APK Build Completed Successfully!
    echo  ====================================================
    echo.
    echo  Output Location:
    dir /b /s "build\app\outputs\apk\release\*.apk"
    echo.
    set /p OPEN_FOLDER="Open output folder? (y/n): "
    if /i "!OPEN_FOLDER!"=="y" start "" "build\app\outputs\apk\release\"
) else (
    echo.
    echo  ====================================================
    echo  [ERROR] Build Failed with exit code %ERRORLEVEL%
    echo  ====================================================
)

echo.
echo Press any key to exit...
pause > nul
