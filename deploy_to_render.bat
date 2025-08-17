@echo off
chcp 65001 >nul
echo 🚀 Lavangam Backend Auto-Deploy Script
echo =====================================
echo.

echo 📊 Checking git status...
git status

echo.
echo 📦 Adding all changes...
git add .

echo.
echo 📋 Changes to be committed:
git diff --cached --name-only

echo.
echo 💾 Committing changes...
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "datestamp=%YYYY%-%MM%-%DD% %HH%:%Min%:%Sec%"

set "commitMessage=🚀 Auto-deploy: Consolidated backend for Render deployment - %datestamp%"
echo 📝 Commit message: %commitMessage%
git commit -m "%commitMessage%"

echo.
echo 🚀 Pushing to remote repository...
git push

echo.
echo ✅ Deployment initiated successfully!
echo 🌐 Render will automatically detect the changes and redeploy
echo ⏱️  Deployment usually takes 2-5 minutes
echo 📊 Monitor progress at: https://dashboard.render.com

echo.
echo 🔍 What was deployed:
echo    • New consolidated backend (render_consolidated.py)
echo    • Updated render.yaml configuration
echo    • All services now run on single port with route prefixes
echo    • Render-compatible single service deployment

echo.
echo 🌐 Service URLs after deployment:
echo    • Main Backend: /
echo    • File Manager: /file-manager/
echo    • E-Procurement: /eproc/
echo    • System Usage: /system/
echo    • Dashboard API: /dashboard/
echo    • Scrapers API: /scrapers/
echo    • Analytics API: /analytics/
echo    • Additional Analytics: /analytics-additional/
echo    • E-Proc WebSocket: /eproc-ws/
echo    • E-Proc API: /eproc-api/

echo.
echo 🎯 Next steps:
echo    1. Wait for Render to complete deployment (2-5 minutes)
echo    2. Check deployment logs at Render dashboard
echo    3. Test health endpoint: /health
echo    4. Test service status: /services/status

echo.
echo ✨ All services are now consolidated and will run automatically!
pause
