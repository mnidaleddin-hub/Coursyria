@echo off
echo [PUSH MOBILE] Starting Git Sync...
cd D:\Coursyria\Coursyria\courseria_mobile
git add .
set /p commit_msg="Enter commit message: "
git commit -m "%commit_msg%"
git push origin main
echo [PUSH MOBILE] Done!
pause
