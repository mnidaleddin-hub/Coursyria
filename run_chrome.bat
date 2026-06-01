@echo off
setlocal

echo ====================================================
echo [CHROME MODE - ULTRA FAST] جاري تشغيل كورسيريا
echo ====================================================

:: قتل أي عملية تستخدم المنفذ 3000
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do (
    taskkill /F /PID %%a 2>nul
)

:: 1. إعدادات البروكسي (للطوارئ) واستثناء المحلي
set HTTP_PROXY=http://10.12.207.175:7071
set HTTPS_PROXY=http://10.12.207.175:7071
set http_proxy=http://10.12.207.175:7071
set https_proxy=http://10.12.207.175:7071
set NO_PROXY=localhost,127.0.0.1,::1
set no_proxy=localhost,127.0.0.1,::1

:: 2. الانتقال لمجلد المشروع
cd /d "%~dp0courseria_mobile"

echo [1/1] جاري تشغيل التطبيق (الوضع السريع جداً)...
echo [INFO] تم تعطيل فحص التبعيات والاتصال بالإنترنت.

:: 3. تجربة المنفذ 3000، إذا فشل استخدم 3001
set PORT=3000
call flutter run -d chrome --no-pub --web-renderer html --web-port %PORT% --web-hostname 127.0.0.1 --no-version-check --web-browser-flag="--proxy-bypass-list=127.0.0.1;localhost" || (
    set PORT=3001
    echo [WARN] فشل المنفذ 3000، جاري التجربة على المنفذ %PORT%...
    call flutter run -d chrome --no-pub --web-renderer html --web-port %PORT% --web-hostname 127.0.0.1 --no-version-check --web-browser-flag="--proxy-bypass-list=127.0.0.1;localhost"
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] حدث خطأ أثناء تشغيل التطبيق.
    echo [FIX] يرجى تصوير هذه النافذة وإرسالها للمساعد.
    echo.
    pause
)

pause
