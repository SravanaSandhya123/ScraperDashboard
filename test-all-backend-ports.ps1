# Test All Backend Ports - Check Which Services Are Actually Working
Write-Host "🔍 Testing All Backend Ports on Render" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

Write-Host "✅ All 11 services show 'Deployed' status!" -ForegroundColor Green
Write-Host "🔍 Now let's test if they're actually working..." -ForegroundColor Yellow
Write-Host ""

# List of all backend services to test
$services = @(
    "lavangam-backend",
    "lavangam-backend-nb0z",
    "lavangam-backend-z05p", 
    "lavangam-backend-dqbf",
    "lavangam-backend-14ix",
    "lavangam-backend-68mn",
    "lavangam-backend-qe6c",
    "lavangam-backend-ubl2",
    "lavangam-backend-pimi",
    "lavangam-backend-bvdm"
)

Write-Host "📋 Testing These Backend Services:" -ForegroundColor Cyan
foreach ($service in $services) {
    Write-Host "• $service" -ForegroundColor White
}
Write-Host ""

Write-Host "🧪 Testing Each Service..." -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

$working_services = @()
$failed_services = @()

foreach ($service in $services) {
    $url = "https://$service.onrender.com"
    Write-Host "Testing: $service" -ForegroundColor Cyan
    Write-Host "URL: $url" -ForegroundColor Gray
    
    try {
        # Test basic connectivity
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $service is WORKING!" -ForegroundColor Green
            $working_services += $service
        } else {
            Write-Host "⚠️ $service responded with status: $($response.StatusCode)" -ForegroundColor Yellow
            $failed_services += $service
        }
    } catch {
        Write-Host "❌ $service is NOT WORKING: $($_.Exception.Message)" -ForegroundColor Red
        $failed_services += $service
    }
    Write-Host ""
}

Write-Host "📊 TEST RESULTS SUMMARY:" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

Write-Host "✅ WORKING Services ($($working_services.Count)):" -ForegroundColor Green
foreach ($service in $working_services) {
    Write-Host "• $service" -ForegroundColor White
}
Write-Host ""

if ($failed_services.Count -gt 0) {
    Write-Host "❌ FAILED Services ($($failed_services.Count)):" -ForegroundColor Red
    foreach ($service in $failed_services) {
        Write-Host "• $service" -ForegroundColor White
    }
    Write-Host ""
}

Write-Host "🌐 Test Specific Endpoints:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Test main backend API" -ForegroundColor Gray
Write-Host "curl https://lavangam-backend.onrender.com/api/admin/supabase-users" -ForegroundColor White
Write-Host ""

Write-Host "# Test one of the new backends" -ForegroundColor Gray
Write-Host "curl https://lavangam-backend-nb0z.onrender.com/" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "• If all services are working: Great! You have 10+ working backends" -ForegroundColor White
Write-Host "• If some are failing: We need to check their specific errors" -ForegroundColor White
Write-Host "• Each service should have its own port internally" -ForegroundColor White
Write-Host ""

Write-Host "Press Enter to run the tests..." -ForegroundColor Yellow
Read-Host
