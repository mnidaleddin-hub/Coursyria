@echo off 
echo ==================================================== 
echo Saving Courseria Project to GitHub (Main Branch)
echo ==================================================== 

cd /d D:\Coursyria\Coursyria 

echo [1/5] Checking Git status... 
git status 

echo [2/5] Adding all changes... 
git add . 

echo [3/5] Committing changes... 
git commit -m "Final production version: AI + Gamification + 900+ improvements - %date% %time%" 

echo [4/5] Pushing to GitHub... 
git push origin main 

echo [5/5] Done! 
echo ==================================================== 
echo Project saved successfully to GitHub 
echo ==================================================== 
pause