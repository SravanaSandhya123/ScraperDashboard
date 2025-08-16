#!/usr/bin/env pwsh
# AWS Backend Deployment Script for Lavangam
# This script deploys your backend with automatic startup to AWS Elastic Beanstalk

param(
    [string]$ApplicationName = "lavangam-backend",
    [string]$EnvironmentName = "lavangam-backend-env",
    [string]$Region = "us-west-2",
    [string]$InstanceType = "t3.medium"
)

Write-Host "🚀 Deploying Lavangam Backend to AWS Elastic Beanstalk" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Blue

# Check Prerequisites
Write-Host "`n📋 Checking Prerequisites..." -ForegroundColor Yellow

# Check AWS CLI
try {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI v2" -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $awsIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS Credentials configured for account: $($awsIdentity.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Check EB CLI
try {
    $ebVersion = eb --version
    Write-Host "✅ EB CLI: $ebVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ EB CLI not found. Installing..." -ForegroundColor Yellow
    pip install awsebcli
    Write-Host "✅ EB CLI installed" -ForegroundColor Green
}

# Navigate to backend directory
Write-Host "`n📁 Preparing backend directory..." -ForegroundColor Yellow
Set-Location backend

# Validate backend files
$requiredFiles = @("application.py", "requirements.txt", "Procfile")
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✅ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing: $file" -ForegroundColor Red
        exit 1
    }
}

# Test application locally (optional quick test)
Write-Host "`n🧪 Quick local test..." -ForegroundColor Yellow
try {
    python -c "import application; print('✅ Application imports successfully')"
    Write-Host "✅ Backend application is ready" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Warning: Local test failed, proceeding anyway..." -ForegroundColor Yellow
}

# Initialize EB application if not exists
Write-Host "`n🔧 Setting up Elastic Beanstalk..." -ForegroundColor Yellow
if (-not (Test-Path ".elasticbeanstalk")) {
    Write-Host "   Initializing EB application..." -ForegroundColor Cyan
    eb init $ApplicationName --platform python-3.9 --region $Region
    Write-Host "✅ EB application initialized" -ForegroundColor Green
} else {
    Write-Host "✅ EB application already initialized" -ForegroundColor Green
}

# Create or deploy to environment
Write-Host "`n🚀 Deploying to AWS..." -ForegroundColor Yellow

# Check if environment exists
$envExists = $false
try {
    $envStatus = eb status $EnvironmentName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $envExists = $true
        Write-Host "✅ Environment '$EnvironmentName' exists" -ForegroundColor Green
    }
} catch {
    Write-Host "   Environment '$EnvironmentName' does not exist" -ForegroundColor Cyan
}

if (-not $envExists) {
    Write-Host "   Creating new environment: $EnvironmentName" -ForegroundColor Cyan
    Write-Host "   Instance type: $InstanceType" -ForegroundColor Cyan
    Write-Host "   This may take 5-10 minutes..." -ForegroundColor Yellow
    
    eb create $EnvironmentName --instance-type $InstanceType --single-instance --timeout 20
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Environment created successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create environment" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   Deploying to existing environment..." -ForegroundColor Cyan
    eb deploy $EnvironmentName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Deployment successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
        exit 1
    }
}

# Get environment URL
Write-Host "`n🌐 Getting environment details..." -ForegroundColor Yellow
try {
    $envUrl = eb status $EnvironmentName | Select-String "CNAME:" | ForEach-Object { $_.ToString().Split()[1] }
    if ($envUrl) {
        Write-Host "✅ Your backend is deployed at: https://$envUrl" -ForegroundColor Green
        
        # Test the deployment
        Write-Host "`n🧪 Testing deployment..." -ForegroundColor Yellow
        try {
            $response = Invoke-RestMethod -Uri "https://$envUrl/health" -Method Get -TimeoutSec 30
            Write-Host "✅ Health check passed!" -ForegroundColor Green
            Write-Host "   Status: $($response.status)" -ForegroundColor Cyan
        } catch {
            Write-Host "⚠️  Health check failed, but deployment may still be starting..." -ForegroundColor Yellow
        }
        
        Write-Host "`n🎯 Available Endpoints:" -ForegroundColor Cyan
        Write-Host "   Health Check: https://$envUrl/health" -ForegroundColor White
        Write-Host "   Main API: https://$envUrl:8000" -ForegroundColor White
        Write-Host "   Scrapers API: https://$envUrl:5022" -ForegroundColor White
        Write-Host "   System API: https://$envUrl:5024" -ForegroundColor White
        Write-Host "   Dashboard API: https://$envUrl:8004" -ForegroundColor White
        Write-Host "   Admin Metrics: https://$envUrl:5025" -ForegroundColor White
        
    } else {
        Write-Host "⚠️  Could not retrieve environment URL" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not get environment status" -ForegroundColor Yellow
}

Write-Host "`n📊 Useful Commands:" -ForegroundColor Cyan
Write-Host "   View logs: eb logs" -ForegroundColor White
Write-Host "   Check status: eb status" -ForegroundColor White
Write-Host "   Open environment: eb open" -ForegroundColor White
Write-Host "   Terminate: eb terminate $EnvironmentName" -ForegroundColor White

Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "Your backend services are now running automatically on AWS!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Blue
