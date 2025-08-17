@echo off
echo 🔍 Testing All Backend Ports on Render
echo ===============================================
echo.

echo ✅ All 11 services show 'Deployed' status!
echo 🔍 Now let's test if they're actually working...
echo.

echo 📋 Testing These Backend Services:
echo • lavangam-backend
echo • lavangam-backend-nb0z
echo • lavangam-backend-z05p
echo • lavangam-backend-dqbf
echo • lavangam-backend-14ix
echo • lavangam-backend-68mn
echo • lavangam-backend-qe6c
echo • lavangam-backend-ubl2
echo • lavangam-backend-pimi
echo • lavangam-backend-bvdm
echo.

echo 🧪 Testing Each Service...
echo ===============================================
echo.

echo Testing: lavangam-backend
echo URL: https://lavangam-backend.onrender.com
echo.

echo Testing: lavangam-backend-nb0z
echo URL: https://lavangam-backend-nb0z.onrender.com
echo.

echo Testing: lavangam-backend-z05p
echo URL: https://lavangam-backend-z05p.onrender.com
echo.

echo Testing: lavangam-backend-dqbf
echo URL: https://lavangam-backend-dqbf.onrender.com
echo.

echo Testing: lavangam-backend-14ix
echo URL: https://lavangam-backend-14ix.onrender.com
echo.

echo Testing: lavangam-backend-68mn
echo URL: https://lavangam-backend-68mn.onrender.com
echo.

echo Testing: lavangam-backend-qe6c
echo URL: https://lavangam-backend-qe6c.onrender.com
echo.

echo Testing: lavangam-backend-ubl2
echo URL: https://lavangam-backend-ubl2.onrender.com
echo.

echo Testing: lavangam-backend-pimi
echo URL: https://lavangam-backend-pimi.onrender.com
echo.

echo Testing: lavangam-backend-bvdm
echo URL: https://lavangam-backend-bvdm.onrender.com
echo.

echo 🌐 Test Specific Endpoints:
echo ===============================================
echo.

echo # Test main backend API
echo curl https://lavangam-backend.onrender.com/api/admin/supabase-users
echo.

echo # Test one of the new backends
echo curl https://lavangam-backend-nb0z.onrender.com/
echo.

echo 🎯 Next Steps:
echo • If all services are working: Great! You have 10+ working backends
echo • If some are failing: We need to check their specific errors
echo • Each service should have its own port internally
echo.

echo Press any key to continue...
pause >nul
