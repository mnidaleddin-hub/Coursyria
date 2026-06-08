@echo off
set "PATH=%PATH%;D:\Development\flutter\bin"
call D:\Development\flutter\bin\flutter.bat build apk --release --split-per-abi --no-pub
