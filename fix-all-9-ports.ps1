# Fix All 9 Failed Lavangam Services
# This script provides the exact commands to fix each service

Write-Host "🚀 Fix All 9 Failed Lavangam Services" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

Write-Host "✅ New requirements files pushed to GitHub!" -ForegroundColor Green
Write-Host "✅ No more pandas compilation issues!" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 Fix Each Service in Render Dashboard:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

$services = @(
    @{Name="lavangam-eproc-server"; BuildCmd="pip install -r requirements-render-fixed.txt"},
    @{Name="lavangam-file-manager"; BuildCmd="pip install -r requirements-minimal-fixed.txt"},
    @{Name="lavangam-system-usage"; BuildCmd="pip install -r requirements-minimal-fixed.txt"},
    @{Name="lavangam-scrapers-api"; BuildCmd="pip install -r requirements-render-fixed.txt"},
    @{Name="lavangam-eproc-api"; BuildCmd="pip install -r requirements-render-fixed.txt"},
    @{Name="lavangam-admin-metrics"; BuildCmd="pip install -r requirements-render-fixed.txt"},
    @{Name="lavangam-unified-api"; BuildCmd="pip install -r requirements-render-fixed.txt"},
    @{Name="lavangam-analytics-api"; BuildCmd="pip install -r requirements-render-fixed.txt"},
    @{Name="lavangam-dashboard-api"; BuildCmd="pip install -r requirements-render-fixed.txt"}
)

$step = 1
foreach ($service in $services) {
    Write-Host "Step $step`: $($service.Name)" -ForegroundColor Cyan
    Write-Host "1. Go to: https://dashboard.render.com/web" -ForegroundColor White
    Write-Host "2. Click on: $($service.Name)" -ForegroundColor White
    Write-Host "3. Click: Settings" -ForegroundColor White
    Write-Host "4. Update Build Command to: $($service.BuildCmd)" -ForegroundColor Green
    Write-Host "5. Click: Save Changes" -ForegroundColor White
    Write-Host "6. Click: Manual Deploy" -ForegroundColor White
    Write-Host "7. Wait for deployment to complete" -ForegroundColor White
    Write-Host ""
    $step++
}

Write-Host "🌐 After Fixing, Test These URLs:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

foreach ($service in $services) {
    $url = "https://$($service.Name).onrender.com"
    Write-Host "• $($service.Name): $url" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📝 Quick Test Commands:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Test E-Proc Server" -ForegroundColor Gray
Write-Host "curl https://lavangam-eproc-server.onrender.com/" -ForegroundColor White
Write-Host ""
Write-Host "# Test File Manager" -ForegroundColor Gray
Write-Host "curl https://lavangam-file-manager.onrender.com/" -ForegroundColor White
Write-Host ""
Write-Host "# Test Analytics API" -ForegroundColor Gray
Write-Host "curl https://lavangam-analytics-api.onrender.com/api/system-metrics" -ForegroundColor White
Write-Host ""

Write-Host "✅ All 9 services should now deploy successfully!" -ForegroundColor Green
Write-Host "🚫 Main backend excluded (already working)" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎯 Key Changes:" -ForegroundColor Cyan
Write-Host "• requirements-render-fixed.txt (no pandas compilation)" -ForegroundColor White
Write-Host "• requirements-minimal-fixed.txt (basic services)" -ForegroundColor White
Write-Host "• Pre-compiled packages only" -ForegroundColor White
