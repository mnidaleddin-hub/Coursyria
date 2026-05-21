@echo off
TITLE Coursyria APK Builder
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1"
pause
