# Coursyria APK Build Automation Script
# Created by Trae AI

$ErrorActionPreference = "Continue"

# 1. Environment Configuration
$GRADLE_CACHE = "D:\GradleCache_Fresh"
$JAVA_HOME_PATH = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$PROJECT_ROOT = Get-Location
$ANDROID_DIR = Join-Path $PROJECT_ROOT "android"
$APK_PATH = Join-Path $PROJECT_ROOT "build\app\outputs\flutter-apk\app-debug.apk"

# 2. Set Environment Variables
$env:GRADLE_USER_HOME = $GRADLE_CACHE
$env:JAVA_HOME = $JAVA_HOME_PATH
$env:JAVA_TOOL_OPTIONS = "-Dfile.encoding=UTF-8 -Duser.language=en -Duser.country=US"

Write-Host "===================================================="
Write-Host "Starting Coursyria APK Build"
Write-Host "===================================================="

Write-Host "Cache Path: $GRADLE_CACHE"
Write-Host "Java Home: $JAVA_HOME_PATH"

# 3. Check Directory
if (-not (Test-Path $ANDROID_DIR)) {
    Write-Host "Error: android directory not found. Run from project root."
    Read-Host "Press any key to exit..."
    exit
}

# 4. Run Build
Set-Location $ANDROID_DIR
Write-Host "Running Gradle... Please wait."

cmd.exe /c ".\gradlew.bat assembleDebug --no-daemon --info"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build Successful!"
    if (Test-Path $APK_PATH) {
        $apkFile = Get-Item $APK_PATH
        Write-Host "APK Location: $($apkFile.FullName)"
        Write-Host "Size: $([math]::Round($apkFile.Length / 1MB, 2)) MB"
    }
} else {
    Write-Host "Build Failed. Exit Code: $LASTEXITCODE"
}

Set-Location $PROJECT_ROOT
Write-Host "===================================================="
Write-Host "Process Finished. Press any key to close..."
Read-Host
