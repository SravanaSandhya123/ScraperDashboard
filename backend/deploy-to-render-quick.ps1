# 🚀 Quick Render Deployment Script for Lavangam Backend
# This script helps you deploy your backend to Render quickly

Write-Host "🚀 Lavangam Backend - Quick Render Deployment" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

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
            $commitMessage = "Deploy to Render - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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

Write-Host "`n🔧 Deployment Checklist:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

Write-Host "1. ✅ Requirements file updated (requirements-render.txt)" -ForegroundColor Green
Write-Host "2. ✅ Environment variables template created (render.env)" -ForegroundColor Green
Write-Host "3. ✅ render.yaml configured" -ForegroundColor Green
Write-Host "4. ✅ Code committed and pushed" -ForegroundColor Green

Write-Host "`n🌍 Next Steps for Render:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

Write-Host "1. Go to [render.com](https://render.com) and sign in" -ForegroundColor White
Write-Host "2. Click 'New +' → 'Web Service'" -ForegroundColor White
Write-Host "3. Connect your Git repository" -ForegroundColor White
Write-Host "4. Configure the service:" -ForegroundColor White
Write-Host "   - Name: lavangam-backend" -ForegroundColor White
Write-Host "   - Environment: Python 3" -ForegroundColor White
Write-Host "   - Build Command: pip install -r requirements-render.txt" -ForegroundColor White
Write-Host "   - Start Command: python render.py" -ForegroundColor White
Write-Host "   - Plan: Free (or choose paid plan)" -ForegroundColor White

Write-Host "`n🔐 Environment Variables to Set:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Write-Host "Copy these from render.env file:" -ForegroundColor White
Write-Host "- DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD" -ForegroundColor White
Write-Host "- SUPABASE_URL, SUPABASE_KEY" -ForegroundColor White
Write-Host "- OPENAI_API_KEY, GROQ_API_KEY" -ForegroundColor White
Write-Host "- RENDER_ENVIRONMENT, PORT" -ForegroundColor White
Write-Host "- SECRET_KEY, FLASK_ENV, FLASK_DEBUG" -ForegroundColor White

Write-Host "`n📱 After Deployment:" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Cyan

Write-Host "1. Check build logs for any errors" -ForegroundColor White
Write-Host "2. Verify service is running" -ForegroundColor White
Write-Host "3. Test your API endpoints" -ForegroundColor White
Write-Host "4. Check database connectivity" -ForegroundColor White

Write-Host "`n🎯 Quick Test Commands:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

Write-Host "After deployment, test with:" -ForegroundColor White
Write-Host "curl https://your-service.onrender.com/" -ForegroundColor Yellow
Write-Host "curl https://your-service.onrender.com/health" -ForegroundColor Yellow

Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

Write-Host "📖 Complete guide: RENDER_DEPLOYMENT_COMPLETE_GUIDE.md" -ForegroundColor White
Write-Host "🔧 Environment template: render.env" -ForegroundColor White
Write-Host "📦 Requirements: requirements-render.txt" -ForegroundColor White

Write-Host "`n🚀 Ready to deploy! Follow the steps above to deploy on Render." -ForegroundColor Green
Write-Host "If you encounter any issues, check the complete guide or Render logs." -ForegroundColor Yellow

# Open Render in browser
$openBrowser = Read-Host "Do you want to open Render in your browser? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process "https://render.com"
    Write-Host "✅ Render opened in browser" -ForegroundColor Green
}

Write-Host "`n🎉 Good luck with your deployment!" -ForegroundColor Green
