# Lavangam Backend Auto-Deploy Script
Write-Host "Starting Lavangam Backend Auto-Deploy..." -ForegroundColor Green

# Check git status
Write-Host "Checking git status..." -ForegroundColor Yellow
git status

# Add all changes
Write-Host "Adding all changes..." -ForegroundColor Yellow
git add .

# Commit changes
$commitMessage = "Auto-deploy: Consolidated backend for Render deployment - $(Get-Date)"
Write-Host "Committing changes..." -ForegroundColor Yellow
Write-Host "Commit message: $commitMessage" -ForegroundColor Cyan
git commit -m "$commitMessage"

# Push to remote
Write-Host "Pushing to remote repository..." -ForegroundColor Yellow
git push

Write-Host "Deployment initiated successfully!" -ForegroundColor Green
Write-Host "Render will automatically redeploy in 2-5 minutes" -ForegroundColor Cyan
Write-Host "Monitor at: https://dashboard.render.com" -ForegroundColor Blue
