# Redeploy All Lavangam Services on Render
# This script helps you redeploy all failed services

Write-Host "🚀 Lavangam Services Redeployment Helper" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# List of all services to redeploy (excluding main backend)
$services = @(
    @{Name="lavangam-analytics-api"; Port="8001"; BuildCmd="pip install -r requirements-simple.txt"},
    @{Name="lavangam-dashboard-api"; Port="8004"; BuildCmd="pip install -r requirements-simple.txt"},
    @{Name="lavangam-eproc-server"; Port="5021"; BuildCmd="pip install -r requirements-simple.txt"},
    @{Name="lavangam-file-manager"; Port="5002"; BuildCmd="pip install -r requirements-minimal.txt"},
    @{Name="lavangam-system-usage"; Port="5024"; BuildCmd="pip install -r requirements-minimal.txt"},
    @{Name="lavangam-scrapers-api"; Port="5022"; BuildCmd="pip install -r requirements-simple.txt"},
    @{Name="lavangam-eproc-api"; Port="5023"; BuildCmd="pip install -r requirements-simple.txt"},
    @{Name="lavangam-admin-metrics"; Port="8005"; BuildCmd="pip install -r requirements-simple.txt"},
    @{Name="lavangam-unified-api"; Port="8006"; BuildCmd="pip install -r requirements-simple.txt"}
)

Write-Host "📋 Services to Redeploy:" -ForegroundColor Yellow
Write-Host ""

foreach ($service in $services) {
    Write-Host "• $($service.Name) (Port: $($service.Port))" -ForegroundColor Cyan
    Write-Host "  Build Command: $($service.BuildCmd)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "🔧 Manual Redeployment Steps:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

$step = 1
foreach ($service in $services) {
    Write-Host "Step $step`: $($service.Name)" -ForegroundColor Green
    Write-Host "1. Go to: https://dashboard.render.com/web" -ForegroundColor White
    Write-Host "2. Click on: $($service.Name)" -ForegroundColor White
    Write-Host "3. Click: Settings" -ForegroundColor White
    Write-Host "4. Update Build Command to: $($service.BuildCmd)" -ForegroundColor White
    Write-Host "5. Click: Save Changes" -ForegroundColor White
    Write-Host "6. Click: Manual Deploy" -ForegroundColor White
    Write-Host "7. Wait for deployment to complete" -ForegroundColor White
    Write-Host ""
    $step++
}

Write-Host "🌐 After Redeployment, Test These URLs:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

foreach ($service in $services) {
    $url = "https://$($service.Name).onrender.com"
    Write-Host "• $($service.Name): $url" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📝 Quick Commands to Test Services:" -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Test Analytics API" -ForegroundColor Gray
Write-Host "curl https://lavangam-analytics-api.onrender.com/api/system-metrics" -ForegroundColor White
Write-Host ""
Write-Host "# Test Dashboard API" -ForegroundColor Gray
Write-Host "curl https://lavangam-dashboard-api.onrender.com/api/dashboard" -ForegroundColor White
Write-Host ""
Write-Host "# Test E-Proc Server" -ForegroundColor Gray
Write-Host "curl https://lavangam-eproc-server.onrender.com/" -ForegroundColor White
Write-Host ""

Write-Host "✅ All services should now deploy successfully!" -ForegroundColor Green
Write-Host "🚫 Main backend (lavangam-backend) was excluded as requested" -ForegroundColor Yellow
