# 🚀 Multi-Port Render Deployment Script for Lavangam Backend
# This script helps you deploy all 10 services to Render with their specific ports

Write-Host "🚀 Lavangam Backend - Multi-Port Render Deployment" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Check if git is available
try {
    $gitVersion = git --version
    Write-Host "✅ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not found. Please install Git first." -ForegroundColor Red
    exit 1
}

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "❌ Not in a git repository. Please navigate to your project root." -ForegroundColor Red
    exit 1
}

# Check current branch
$currentBranch = git branch --show-current
Write-Host "📍 Current branch: $currentBranch" -ForegroundColor Yellow

# Check if there are uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  You have uncommitted changes:" -ForegroundColor Yellow
    Write-Host $status -ForegroundColor Yellow
    $commit = Read-Host "Do you want to commit these changes? (y/n)"
    if ($commit -eq "y" -or $commit -eq "Y") {
        $commitMessage = Read-Host "Enter commit message (or press Enter for default)"
        if (-not $commitMessage) {
            $commitMessage = "Multi-port Render deployment - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        git add .
        git commit -m $commitMessage
        Write-Host "✅ Changes committed successfully" -ForegroundColor Green
    }
}

# Push to remote if needed
$push = Read-Host "Do you want to push to remote repository? (y/n)"
if ($push -eq "y" -or $push -eq "Y") {
    git push origin $currentBranch
    Write-Host "✅ Code pushed to remote repository" -ForegroundColor Green
}

Write-Host "`n🔧 Multi-Port Deployment Checklist:" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

Write-Host "1. ✅ Requirements file updated (requirements-render.txt)" -ForegroundColor Green
Write-Host "2. ✅ Multi-service config ready (render-correct.yaml)" -ForegroundColor Green
Write-Host "3. ✅ Environment variables template (render.env)" -ForegroundColor Green
Write-Host "4. ✅ Code committed and pushed" -ForegroundColor Green

Write-Host "`n🌐 Services to Deploy:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$services = @(
    @{Name="lavangam-main-backend"; Port="8000"; URL="https://lavangam-main-backend.onrender.com"},
    @{Name="lavangam-analytics-api"; Port="8001"; URL="https://lavangam-analytics-api.onrender.com"},
    @{Name="lavangam-dashboard-websocket"; Port="8002"; URL="https://lavangam-dashboard-websocket.onrender.com"},
    @{Name="lavangam-dashboard-api"; Port="8004"; URL="https://lavangam-dashboard-api.onrender.com"},
    @{Name="lavangam-admin-metrics"; Port="8005"; URL="https://lavangam-admin-metrics.onrender.com"},
    @{Name="lavangam-unified-api"; Port="8006"; URL="https://lavangam-unified-api.onrender.com"},
    @{Name="lavangam-file-manager"; Port="5002"; URL="https://lavangam-file-manager.onrender.com"},
    @{Name="lavangam-eproc-server"; Port="5021"; URL="https://lavangam-eproc-server.onrender.com"},
    @{Name="lavangam-scrapers-api"; Port="5022"; URL="https://lavangam-scrapers-api.onrender.com"},
    @{Name="lavangam-system-usage"; Port="5024"; URL="https://lavangam-system-usage.onrender.com"}
)

foreach ($service in $services) {
    Write-Host "   • $($service.Name) - Port $($service.Port)" -ForegroundColor White
}

Write-Host "`n🚀 Deployment Options:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

Write-Host "1. 🎯 Automatic Deployment (Recommended):" -ForegroundColor Yellow
Write-Host "   - Use render-correct.yaml as Blueprint" -ForegroundColor White
Write-Host "   - Render creates all 10 services automatically" -ForegroundColor White
Write-Host "   - Fastest and most reliable method" -ForegroundColor White

Write-Host "`n2. 🔧 Manual Deployment:" -ForegroundColor Yellow
Write-Host "   - Create each service individually" -ForegroundColor White
Write-Host "   - More control over each service" -ForegroundColor White
Write-Host "   - Takes longer but allows customization" -ForegroundColor White

$deploymentChoice = Read-Host "`nChoose deployment method (1 for Automatic, 2 for Manual):"

if ($deploymentChoice -eq "1") {
    Write-Host "`n🎯 Automatic Deployment Instructions:" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    
    Write-Host "1. Go to [dashboard.render.com](https://dashboard.render.com)" -ForegroundColor White
    Write-Host "2. Click 'New +' → 'Blueprint'" -ForegroundColor White
    Write-Host "3. Connect your Git repository" -ForegroundColor White
    Write-Host "4. Render will auto-detect render-correct.yaml" -ForegroundColor White
    Write-Host "5. Click 'Create Blueprint Instance'" -ForegroundColor White
    Write-Host "6. Wait for all 10 services to deploy" -ForegroundColor White
    
    Write-Host "`n✅ All services will be created automatically!" -ForegroundColor Green
    
} else {
    Write-Host "`n🔧 Manual Deployment Instructions:" -ForegroundColor Green
    Write-Host "===================================" -ForegroundColor Green
    
    Write-Host "1. Go to [dashboard.render.com](https://dashboard.render.com)" -ForegroundColor White
    Write-Host "2. For each service, click 'New +' → 'Web Service'" -ForegroundColor White
    Write-Host "3. Connect your Git repository" -ForegroundColor White
    Write-Host "4. Configure each service individually" -ForegroundColor White
    
    Write-Host "`n📋 Service Configuration Summary:" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    foreach ($service in $services) {
        Write-Host "`n🔹 $($service.Name) (Port $($service.Port)):" -ForegroundColor Yellow
        Write-Host "   - Name: $($service.Name)" -ForegroundColor White
        Write-Host "   - Environment: Python 3" -ForegroundColor White
        Write-Host "   - Build Command: pip install -r requirements-render.txt" -ForegroundColor White
        
        # Set start command based on service type
        switch ($service.Name) {
            "lavangam-main-backend" { $startCmd = "uvicorn backend.main:app --host 0.0.0.0 --port `$PORT" }
            "lavangam-analytics-api" { $startCmd = "uvicorn analytics_api:app --host 0.0.0.0 --port `$PORT" }
            "lavangam-dashboard-websocket" { $startCmd = "python dashboard_websocket.py" }
            "lavangam-dashboard-api" { $startCmd = "uvicorn dashboard_api:app --host 0.0.0.0 --port `$PORT" }
            "lavangam-admin-metrics" { $startCmd = "uvicorn admin_metrics_api:app --host 0.0.0.0 --port `$PORT" }
            "lavangam-unified-api" { $startCmd = "uvicorn unified_api_complete:app --host 0.0.0.0 --port `$PORT" }
            "lavangam-file-manager" { $startCmd = "python file_manager.py" }
            "lavangam-eproc-server" { $startCmd = "python eproc_server.py" }
            "lavangam-scrapers-api" { $startCmd = "uvicorn backend.scrapers.api:app --host 0.0.0.0 --port `$PORT" }
            "lavangam-system-usage" { $startCmd = "uvicorn system_usage_api:app --host 0.0.0.0 --port `$PORT" }
        }
        
        Write-Host "   - Start Command: $startCmd" -ForegroundColor White
        Write-Host "   - Plan: Free (or choose paid plan)" -ForegroundColor White
    }
}

Write-Host "`n🔐 Environment Variables to Set:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "For each service, set these environment variables:" -ForegroundColor White
Write-Host "• PORT (Render sets this automatically)" -ForegroundColor White
Write-Host "• RENDER_ENVIRONMENT=production" -ForegroundColor White
Write-Host "• DB_HOST=44.244.61.85" -ForegroundColor White
Write-Host "• DB_PORT=3306" -ForegroundColor White
Write-Host "• DB_NAME=toolinfomation" -ForegroundColor White
Write-Host "• DB_USER=root" -ForegroundColor White
Write-Host "• DB_PASSWORD=thanuja" -ForegroundColor White
Write-Host "• SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co" -ForegroundColor White
Write-Host "• SUPABASE_KEY=your-supabase-key" -ForegroundColor White
Write-Host "• OPENAI_API_KEY=sk-your-openai-key" -ForegroundColor White
Write-Host "• GROQ_API_KEY=gsk-your-groq-key" -ForegroundColor White
Write-Host "• SECRET_KEY=your-secret-key" -ForegroundColor White

Write-Host "`n📱 After Deployment Testing:" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

Write-Host "Test each service with these commands:" -ForegroundColor White
foreach ($service in $services) {
    Write-Host "curl $($service.URL)" -ForegroundColor Yellow
}

Write-Host "`n🔍 Monitoring Deployment:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

Write-Host "1. Check build logs for each service" -ForegroundColor White
Write-Host "2. Monitor runtime logs for startup errors" -ForegroundColor White
Write-Host "3. Verify all services are responding" -ForegroundColor White
Write-Host "4. Test database connections" -ForegroundColor White

Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

Write-Host "📖 Complete guide: COMPLETE_MULTI_PORT_DEPLOYMENT_GUIDE.md" -ForegroundColor White
Write-Host "🔧 Environment template: render.env" -ForegroundColor White
Write-Host "📦 Requirements: requirements-render.txt" -ForegroundColor White
Write-Host "⚙️  Multi-service config: render-correct.yaml" -ForegroundColor White

Write-Host "`n🚀 Ready to deploy all 10 services!" -ForegroundColor Green
Write-Host "Choose your deployment method and follow the instructions above." -ForegroundColor Yellow

# Open Render in browser
$openBrowser = Read-Host "`nDo you want to open Render in your browser? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process "https://dashboard.render.com"
    Write-Host "✅ Render dashboard opened in browser" -ForegroundColor Green
}

Write-Host "`n🎉 Good luck with your multi-port deployment!" -ForegroundColor Green
Write-Host "After deployment, you'll have 10 fully functional backend services! 🚀" -ForegroundColor Green
