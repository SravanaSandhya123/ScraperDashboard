@echo off
echo ============================================================================
echo LAVANGAM BACKEND DEPLOYMENT LAUNCHER
echo ============================================================================
echo.
echo This will launch the complete deployment script for your backend services.
echo.
echo IMPORTANT: You may need to run this as Administrator to fix SSH permissions.
echo.
pause

powershell -ExecutionPolicy Bypass -File "COMPLETE_DEPLOYMENT_SCRIPT.ps1"

echo.
echo Deployment script completed.
pause
