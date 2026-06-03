@echo off
setlocal

echo ====================================================
echo [CHROME MODE - OPTIMIZED] جاري تشغيل كورسيريا
echo ====================================================

:: 1. تنظيف العمليات العالقة والمنافذ
echo [1/3] تنظيف العمليات والمنافذ...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter_tool.exe 2>nul

:: قتل أي عملية تستخدم المنفذ 3000 أو 3001
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do taskkill /F /PID %%a 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3001" ^| find "LISTENING"') do taskkill /F /PID %%a 2>nul

:: 2. الانتقال لمجلد المشروع
cd /d "%~dp0courseria_mobile"

echo [2/3] جاري تشغيل التطبيق (الوضع المحسن)...
echo [INFO] تم تثبيت المنفذ وتثبيت المضيف لتقليل استهلاك الواي فاي.

:: 3. تشغيل التطبيق مع إعدادات تقليل حمل الشبكة
set PORT=3000
call flutter run -d chrome --web-renderer html --web-port %PORT% --web-hostname 127.0.0.1 --no-version-check --web-browser-flag="--proxy-bypass-list=127.0.0.1;localhost" --web-browser-flag="--disable-extensions" --web-browser-flag="--incognito"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] حدث خطأ أثناء تشغيل التطبيق.
    echo.
    pause
)

pause
