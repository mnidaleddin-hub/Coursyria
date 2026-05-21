@echo off
SET "PUB_CACHE=D:\flutter\.pub-cache"
SET "http_proxy=http://10.12.207.175:7071"
SET "https_proxy=http://10.12.207.175:7071"

cd /d "%~dp0courseria_mobile"
D:\flutter\bin\flutter.bat run -d web-server --web-port=3006 --web-hostname=127.0.0.1 --no-pub --no-version-check

pause
