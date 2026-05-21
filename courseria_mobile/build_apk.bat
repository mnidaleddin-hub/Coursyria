@echo off
set HTTP_PROXY=http://10.12.207.175:7071
set HTTPS_PROXY=http://10.12.207.175:7071
set GRADLE_OPTS=-Dhttp.proxyHost=10.12.207.175 -Dhttp.proxyPort=7071 -Dhttps.proxyHost=10.12.207.175 -Dhttps.proxyPort=7071
call D:\Development\flutter\bin\flutter.bat build apk --split-per-abi
