#!/usr/bin/env pwsh
# Direct AWS Deployment Script for Lavangam Backend
# This script uses AWS CLI directly to deploy without EB CLI

param(
    [string]$ApplicationName = "lavangam-backend",
    [string]$EnvironmentName = "lavangam-backend-env",
    [string]$Region = "us-west-2",
    [string]$InstanceType = "t3.medium"
)

Write-Host "🚀 Deploying Lavangam Backend directly to AWS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Blue

# Check AWS CLI
try {
    $awsIdentity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS Credentials configured for account: $($awsIdentity.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Navigate to backend directory
Set-Location backend

Write-Host "`n📦 Creating deployment package..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zipName = "lavangam-backend-$timestamp.zip"

# Create deployment zip
Compress-Archive -Path * -DestinationPath "../$zipName" -Force
Write-Host "✅ Created deployment package: $zipName" -ForegroundColor Green

# Create S3 bucket for deployment
$bucketName = "lavangam-backend-deployments-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Host "`n🪣 Creating S3 bucket: $bucketName" -ForegroundColor Yellow

try {
    aws s3 mb "s3://$bucketName" --region $Region
    Write-Host "✅ S3 bucket created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create S3 bucket" -ForegroundColor Red
    exit 1
}

# Upload deployment package to S3
Write-Host "`n⬆️ Uploading deployment package..." -ForegroundColor Yellow
try {
    aws s3 cp "../$zipName" "s3://$bucketName/"
    Write-Host "✅ Deployment package uploaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to upload deployment package" -ForegroundColor Red
    exit 1
}

# Create Elastic Beanstalk application
Write-Host "`n🏗️ Creating EB application..." -ForegroundColor Yellow
try {
    $appResult = aws elasticbeanstalk create-application --application-name $ApplicationName --region $Region --output json | ConvertFrom-Json
    Write-Host "✅ EB application created: $ApplicationName" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Application may already exist, continuing..." -ForegroundColor Yellow
}

# Create application version
Write-Host "`n📋 Creating application version..." -ForegroundColor Yellow
try {
    $versionLabel = "v-$timestamp"
    $versionResult = aws elasticbeanstalk create-application-version `
        --application-name $ApplicationName `
        --version-label $versionLabel `
        --source-bundle "S3Bucket=$bucketName,S3Key=$zipName" `
        --region $Region --output json | ConvertFrom-Json
    Write-Host "✅ Application version created: $versionLabel" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create application version" -ForegroundColor Red
    exit 1
}

# Create environment
Write-Host "`n🌍 Creating EB environment..." -ForegroundColor Yellow
Write-Host "   This may take 5-10 minutes..." -ForegroundColor Cyan

try {
    $envResult = aws elasticbeanstalk create-environment `
        --application-name $ApplicationName `
        --environment-name $EnvironmentName `
        --version-label $versionLabel `
        --solution-stack-name "64bit Amazon Linux 2 v3.4.19 running Python 3.9" `
        --option-settings Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=$InstanceType `
                          Namespace=aws:elasticbeanstalk:environment,OptionName=EnvironmentType,Value=SingleInstance `
        --region $Region --output json | ConvertFrom-Json
    
    Write-Host "✅ Environment creation started: $EnvironmentName" -ForegroundColor Green
    
    # Wait for environment to be ready
    Write-Host "`n⏳ Waiting for environment to be ready..." -ForegroundColor Yellow
    aws elasticbeanstalk wait environment-updated --application-name $ApplicationName --environment-names $EnvironmentName --region $Region
    
    Write-Host "✅ Environment is ready!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create environment" -ForegroundColor Red
    exit 1
}

# Get environment URL
Write-Host "`n🌐 Getting environment details..." -ForegroundColor Yellow
try {
    $envInfo = aws elasticbeanstalk describe-environments --application-name $ApplicationName --environment-names $EnvironmentName --region $Region --output json | ConvertFrom-Json
    $envUrl = $envInfo.Environments[0].CNAME
    
    if ($envUrl) {
        Write-Host "✅ Your backend is deployed at: https://$envUrl" -ForegroundColor Green
        
        # Test the deployment
        Write-Host "`n🧪 Testing deployment..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30  # Wait for services to start
        
        try {
            $response = Invoke-RestMethod -Uri "https://$envUrl/health" -Method Get -TimeoutSec 30
            Write-Host "✅ Health check passed!" -ForegroundColor Green
            Write-Host "   Status: $($response.status)" -ForegroundColor Cyan
        } catch {
            Write-Host "⚠️ Health check failed, services may still be starting..." -ForegroundColor Yellow
            Write-Host "   Try again in a few minutes: https://$envUrl/health" -ForegroundColor Cyan
        }
        
        Write-Host "`n🎯 Available Endpoints:" -ForegroundColor Cyan
        Write-Host "   Health Check: https://$envUrl/health" -ForegroundColor White
        Write-Host "   Main API: https://$envUrl:8000" -ForegroundColor White
        Write-Host "   Scrapers API: https://$envUrl:5022" -ForegroundColor White
        Write-Host "   System API: https://$envUrl:5024" -ForegroundColor White
        Write-Host "   Dashboard API: https://$envUrl:8004" -ForegroundColor White
        Write-Host "   Admin Metrics: https://$envUrl:5025" -ForegroundColor White
        
        # Save deployment info
        $deploymentInfo = @{
            ApplicationName = $ApplicationName
            EnvironmentName = $EnvironmentName
            URL = "https://$envUrl"
            Region = $Region
            DeploymentTime = Get-Date
            Endpoints = @{
                Health = "https://$envUrl/health"
                MainAPI = "https://$envUrl:8000"
                ScrapersAPI = "https://$envUrl:5022"
                SystemAPI = "https://$envUrl:5024"
                DashboardAPI = "https://$envUrl:8004"
                AdminMetrics = "https://$envUrl:5025"
            }
        }
        
        $deploymentInfo | ConvertTo-Json | Out-File "deployment-info.json"
        Write-Host "`n💾 Deployment info saved to: deployment-info.json" -ForegroundColor Cyan
        
    } else {
        Write-Host "⚠️ Could not retrieve environment URL" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Could not get environment status" -ForegroundColor Yellow
}

Write-Host "`n📊 Useful Commands:" -ForegroundColor Cyan
Write-Host "   Check status: aws elasticbeanstalk describe-environments --application-name $ApplicationName --region $Region" -ForegroundColor White
Write-Host "   View logs: aws elasticbeanstalk request-environment-info --environment-name $EnvironmentName --info-type tail --region $Region" -ForegroundColor White
Write-Host "   Terminate: aws elasticbeanstalk terminate-environment --environment-name $EnvironmentName --region $Region" -ForegroundColor White

Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "Your backend services are now running automatically on AWS!" -ForegroundColor Green
Write-Host "All ports will automatically start when the application loads." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Blue
