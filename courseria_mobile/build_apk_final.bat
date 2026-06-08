@echo off 
echo ==================================================== 
echo Building Courseria APK - FINAL ATTEMPT 
echo ==================================================== 

cd /d D:\Coursyria\Coursyria\courseria_mobile 

echo [1/4] Cleaning project... 
flutter clean > build_log.txt 2>&1 

echo [2/4] Getting packages... 
flutter pub get >> build_log.txt 2>&1 

echo [3/4] Building APK for ARM64... 
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons >> build_log.txt 2>&1 

echo [4/4] Building APK for ARMv7... 
flutter build apk --release --target-platform android-arm --no-tree-shake-icons >> build_log.txt 2>&1 

echo ==================================================== 
echo Build completed. Check build\app\outputs\flutter-apk\ 
echo ==================================================== 
pause