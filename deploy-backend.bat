@echo off
echo 🚀 LAVANGAM Backend Deployment
echo ===============================
echo.
echo Starting deployment script...
echo.

powershell -ExecutionPolicy Bypass -File "deploy-backend.ps1"

echo.
echo Deployment script completed.
pause
