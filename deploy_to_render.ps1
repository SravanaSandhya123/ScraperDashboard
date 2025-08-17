# Lavangam Backend Auto-Deploy Script for Render
# This script automatically commits and pushes changes to trigger Render deployment

Write-Host "🚀 Lavangam Backend Auto-Deploy Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Check if git is available
try {
    $gitVersion = git --version
    Write-Host "✅ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git not found. Please install Git first." -ForegroundColor Red
    exit 1
}

# Check current git status
Write-Host "`n📊 Checking git status..." -ForegroundColor Yellow
git status

# Add all changes
Write-Host "`n📦 Adding all changes..." -ForegroundColor Yellow
git add .

# Check what will be committed
Write-Host "`n📋 Changes to be committed:" -ForegroundColor Yellow
git diff --cached --name-only

# Commit changes
$commitMessage = "Auto-deploy: Consolidated backend for Render deployment - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "`n💾 Committing changes..." -ForegroundColor Yellow
Write-Host "📝 Commit message: $commitMessage" -ForegroundColor Cyan
git commit -m "$commitMessage"

# Push to remote repository
Write-Host "`n🚀 Pushing to remote repository..." -ForegroundColor Yellow
git push

Write-Host "`n✅ Deployment initiated successfully!" -ForegroundColor Green
Write-Host "🌐 Render will automatically detect the changes and redeploy" -ForegroundColor Cyan
Write-Host "⏱️  Deployment usually takes 2-5 minutes" -ForegroundColor Yellow
Write-Host "📊 Monitor progress at: https://dashboard.render.com" -ForegroundColor Blue

Write-Host "`n🔍 What was deployed:" -ForegroundColor Yellow
Write-Host "   • New consolidated backend (render_consolidated.py)" -ForegroundColor White
Write-Host "   • Updated render.yaml configuration" -ForegroundColor White
Write-Host "   • All services now run on single port with route prefixes" -ForegroundColor White
Write-Host "   • Render-compatible single service deployment" -ForegroundColor White

Write-Host "`n🌐 Service URLs after deployment:" -ForegroundColor Yellow
Write-Host "   • Main Backend: /" -ForegroundColor White
Write-Host "   • File Manager: /file-manager/" -ForegroundColor White
Write-Host "   • E-Procurement: /eproc/" -ForegroundColor White
Write-Host "   • System Usage: /system/" -ForegroundColor White
Write-Host "   • Dashboard API: /dashboard/" -ForegroundColor White
Write-Host "   • Scrapers API: /scrapers/" -ForegroundColor White
Write-Host "   • Analytics API: /analytics/" -ForegroundColor White
Write-Host "   • Additional Analytics: /analytics-additional/" -ForegroundColor White
Write-Host "   • E-Proc WebSocket: /eproc-ws/" -ForegroundColor White
Write-Host "   • E-Proc API: /eproc-api/" -ForegroundColor White

Write-Host "`n🎯 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Wait for Render to complete deployment (2-5 minutes)" -ForegroundColor White
Write-Host "   2. Check deployment logs at Render dashboard" -ForegroundColor White
Write-Host "   3. Test health endpoint: /health" -ForegroundColor White
Write-Host "   4. Test service status: /services/status" -ForegroundColor White

Write-Host "`n✨ All services are now consolidated and will run automatically!" -ForegroundColor Green
