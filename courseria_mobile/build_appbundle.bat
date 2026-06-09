@echo off
echo [BUILD APPBUNDLE] Optimizing for production...
cd D:\Coursyria\Coursyria\courseria_mobile
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
echo [BUILD APPBUNDLE] Done! Path: build\app\outputs\bundle\release\app-release.aab
pause
