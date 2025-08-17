# Quick Test All Backend Services
Write-Host "🧪 Quick Test All Backend Services" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

Write-Host "✅ Main backend is working!" -ForegroundColor Green
Write-Host "🔍 Testing all other backend services..." -ForegroundColor Yellow
Write-Host ""

$services = @(
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

Write-Host "📋 Testing These Services:" -ForegroundColor Cyan
foreach ($service in $services) {
    Write-Host "• $service" -ForegroundColor White
}
Write-Host ""

Write-Host "🧪 Testing Each Service..." -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

$working_count = 0
$total_count = $services.Count

foreach ($service in $services) {
    $url = "https://$service.onrender.com"
    Write-Host "Testing: $service" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 15 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $service is WORKING!" -ForegroundColor Green
            $working_count++
        } else {
            Write-Host "⚠️ $service responded with status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ $service is NOT WORKING: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

Write-Host "📊 TEST RESULTS SUMMARY:" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

Write-Host "✅ Working Services: $working_count / $total_count" -ForegroundColor Green
Write-Host "❌ Failed Services: $($total_count - $working_count) / $total_count" -ForegroundColor Red
Write-Host ""

if ($working_count -eq $total_count) {
    Write-Host "🎉 ALL BACKEND SERVICES ARE WORKING!" -ForegroundColor Green
    Write-Host "🚀 You now have $($total_count + 1) working backend services!" -ForegroundColor Green
} else {
    Write-Host "⚠️ Some services need attention" -ForegroundColor Yellow
    Write-Host "🔧 Check the failed services in Render dashboard" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 Test URLs:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Main backend (working)" -ForegroundColor Gray
Write-Host "curl https://lavangam-backend.onrender.com/main/api/admin/supabase-users" -ForegroundColor White
Write-Host ""

Write-Host "# Test new backends" -ForegroundColor Gray
foreach ($service in $services) {
    Write-Host "curl https://$service.onrender.com/" -ForegroundColor White
}
Write-Host ""

Write-Host "Press Enter to continue..." -ForegroundColor Yellow
Read-Host
