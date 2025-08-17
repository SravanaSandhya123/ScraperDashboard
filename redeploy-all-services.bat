@echo off
echo 🚀 Lavangam Services Redeployment Helper
echo ===============================================
echo.

echo 📋 Services to Redeploy:
echo.

echo • lavangam-analytics-api (Port: 8001)
echo   Build Command: pip install -r requirements-simple.txt
echo.
echo • lavangam-dashboard-api (Port: 8004)
echo   Build Command: pip install -r requirements-simple.txt
echo.
echo • lavangam-eproc-server (Port: 5021)
echo   Build Command: pip install -r requirements-simple.txt
echo.
echo • lavangam-file-manager (Port: 5002)
echo   Build Command: pip install -r requirements-minimal.txt
echo.
echo • lavangam-system-usage (Port: 5024)
echo   Build Command: pip install -r requirements-minimal.txt
echo.
echo • lavangam-scrapers-api (Port: 5022)
echo   Build Command: pip install -r requirements-simple.txt
echo.
echo • lavangam-eproc-api (Port: 5023)
echo   Build Command: pip install -r requirements-simple.txt
echo.
echo • lavangam-admin-metrics (Port: 8005)
echo   Build Command: pip install -r requirements-simple.txt
echo.
echo • lavangam-unified-api (Port: 8006)
echo   Build Command: pip install -r requirements-simple.txt
echo.

echo 🔧 Manual Redeployment Steps:
echo ===============================================
echo.

echo Step 1: lavangam-analytics-api
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-analytics-api
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 2: lavangam-dashboard-api
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-dashboard-api
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 3: lavangam-eproc-server
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-eproc-server
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 4: lavangam-file-manager
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-file-manager
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-minimal.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 5: lavangam-system-usage
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-system-usage
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-minimal.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 6: lavangam-scrapers-api
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-scrapers-api
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 7: lavangam-eproc-api
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-eproc-api
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 8: lavangam-admin-metrics
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-admin-metrics
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo Step 9: lavangam-unified-api
echo 1. Go to: https://dashboard.render.com/web
echo 2. Click on: lavangam-unified-api
echo 3. Click: Settings
echo 4. Update Build Command to: pip install -r requirements-simple.txt
echo 5. Click: Save Changes
echo 6. Click: Manual Deploy
echo 7. Wait for deployment to complete
echo.

echo 🌐 After Redeployment, Test These URLs:
echo ===============================================
echo.

echo • lavangam-analytics-api: https://lavangam-analytics-api.onrender.com
echo • lavangam-dashboard-api: https://lavangam-dashboard-api.onrender.com
echo • lavangam-eproc-server: https://lavangam-eproc-server.onrender.com
echo • lavangam-file-manager: https://lavangam-file-manager.onrender.com
echo • lavangam-system-usage: https://lavangam-system-usage.onrender.com
echo • lavangam-scrapers-api: https://lavangam-scrapers-api.onrender.com
echo • lavangam-eproc-api: https://lavangam-eproc-api.onrender.com
echo • lavangam-admin-metrics: https://lavangam-admin-metrics.onrender.com
echo • lavangam-unified-api: https://lavangam-unified-api.onrender.com
echo.

echo 📝 Quick Commands to Test Services:
echo ===============================================
echo.

echo # Test Analytics API
echo curl https://lavangam-analytics-api.onrender.com/api/system-metrics
echo.
echo # Test Dashboard API
echo curl https://lavangam-dashboard-api.onrender.com/api/dashboard
echo.
echo # Test E-Proc Server
echo curl https://lavangam-eproc-server.onrender.com/
echo.

echo ✅ All services should now deploy successfully!
echo 🚫 Main backend (lavangam-backend) was excluded as requested
echo.

pause
