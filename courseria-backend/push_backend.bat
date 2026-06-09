@echo off
echo [PUSH BACKEND] Starting Git Sync...
cd D:\Coursyria\Coursyria\courseria-backend
git add .
set /p commit_msg="Enter commit message: "
git commit -m "%commit_msg%"
git push origin main
echo [PUSH BACKEND] Done!
pause
