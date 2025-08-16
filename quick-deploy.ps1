# Quick Deploy Script for Lavangam Backend
# This script provides a simple deployment option

Write-Host "🚀 Quick Deploy - Lavangam Backend to AWS EC2" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan

# Check if main deployment script exists
if (-not (Test-Path "deploy-aws-ec2-complete.ps1")) {
    Write-Host "❌ Main deployment script not found!" -ForegroundColor Red
    Write-Host "Please ensure 'deploy-aws-ec2-complete.ps1' is in the current directory." -ForegroundColor Yellow
    exit 1
}

# Check if backend directory exists
if (-not (Test-Path "backend")) {
    Write-Host "⚠️  Backend directory not found in current location" -ForegroundColor Yellow
    Write-Host "Make sure you're running this from the root of your project." -ForegroundColor White
}

# Display deployment options
Write-Host "`n📋 Deployment Options:" -ForegroundColor Cyan
Write-Host "1. Standard deployment (t3.medium)" -ForegroundColor White
Write-Host "2. Small deployment (t3.micro) - for testing" -ForegroundColor White
Write-Host "3. Large deployment (t3.large) - for production" -ForegroundColor White
Write-Host "4. Custom deployment" -ForegroundColor White

$choice = Read-Host "`nSelect option (1-4)"

switch ($choice) {
    "1" {
        Write-Host "`n🚀 Starting standard deployment..." -ForegroundColor Green
        & .\deploy-aws-ec2-complete.ps1
    }
    "2" {
        Write-Host "`n🚀 Starting small deployment for testing..." -ForegroundColor Green
        & .\deploy-aws-ec2-complete.ps1 -InstanceType "t3.micro"
    }
    "3" {
        Write-Host "`n🚀 Starting large deployment for production..." -ForegroundColor Green
        & .\deploy-aws-ec2-complete.ps1 -InstanceType "t3.large"
    }
    "4" {
        Write-Host "`n🔧 Custom deployment options:" -ForegroundColor Cyan
        
        $instanceType = Read-Host "Instance type (default: t3.medium)"
        if (-not $instanceType) { $instanceType = "t3.medium" }
        
        $keyName = Read-Host "Key pair name (default: lavangam-key)"
        if (-not $keyName) { $keyName = "lavangam-key" }
        
        $instanceName = Read-Host "Instance name (default: lavangam-backend-server)"
        if (-not $instanceName) { $instanceName = "lavangam-backend-server" }
        
        Write-Host "`n🚀 Starting custom deployment..." -ForegroundColor Green
        & .\deploy-aws-ec2-complete.ps1 -InstanceType $instanceType -KeyName $keyName -InstanceName $instanceName
    }
    default {
        Write-Host "❌ Invalid option selected. Exiting." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n✅ Quick deploy completed!" -ForegroundColor Green
Write-Host "Check the output above for deployment details and next steps." -ForegroundColor Cyan
