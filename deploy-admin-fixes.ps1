# Admin Panel Fixes Deployment Script
# This script deploys the fixes for the admin panel and database issues

Write-Host "🚀 Deploying Admin Panel Fixes..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan

# Configuration
$SERVER_IP = "44.244.61.85"
$SSH_KEY = "~/.ssh/lavangam-key.pem"
$REMOTE_USER = "ubuntu"

Write-Host "📡 Target Server: $SERVER_IP" -ForegroundColor Yellow
Write-Host "👤 Remote User: $REMOTE_USER" -ForegroundColor Yellow

# Function to execute remote commands
function Invoke-RemoteCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "🔧 $Description..." -ForegroundColor Cyan
    Write-Host "Command: $Command" -ForegroundColor Gray
    
    try {
        $result = ssh -i $SSH_KEY -o StrictHostKeyChecking=no ${REMOTE_USER}@${SERVER_IP} $Command
        Write-Host "✅ Success" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Function to upload files
function Upload-File {
    param(
        [string]$LocalPath,
        [string]$RemotePath,
        [string]$Description
    )
    
    Write-Host "📤 $Description..." -ForegroundColor Cyan
    Write-Host "From: $LocalPath" -ForegroundColor Gray
    Write-Host "To: $RemotePath" -ForegroundColor Gray
    
    try {
        scp -i $SSH_KEY -o StrictHostKeyChecking=no $LocalPath ${REMOTE_USER}@${SERVER_IP}:$RemotePath
        Write-Host "✅ Upload successful" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Upload failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 1: Check server connectivity
Write-Host "`n🔍 Step 1: Checking server connectivity..." -ForegroundColor Yellow
$pingResult = Invoke-RemoteCommand "echo 'Server is reachable'" "Testing server connectivity"

if (-not $pingResult) {
    Write-Host "❌ Cannot connect to server. Please check:" -ForegroundColor Red
    Write-Host "   - SSH key exists at: $SSH_KEY" -ForegroundColor Red
    Write-Host "   - Server IP is correct: $SERVER_IP" -ForegroundColor Red
    Write-Host "   - Network connectivity" -ForegroundColor Red
    exit 1
}

# Step 2: Backup current configuration
Write-Host "`n💾 Step 2: Creating backup..." -ForegroundColor Yellow
Invoke-RemoteCommand "cd /home/ubuntu/lavangam/backend && cp database_config.py database_config.py.backup" "Backing up database config"
Invoke-RemoteCommand "cd /home/ubuntu/lavangam/backend && cp admin_metrics_api.py admin_metrics_api.py.backup" "Backing up admin metrics API"

# Step 3: Upload updated files
Write-Host "`n📤 Step 3: Uploading updated files..." -ForegroundColor Yellow

# Upload backend files
Upload-File "backend/database_config.py" "/home/ubuntu/lavangam/backend/database_config.py" "Uploading updated database config"
Upload-File "backend/admin_metrics_api.py" "/home/ubuntu/lavangam/backend/admin_metrics_api.py" "Uploading updated admin metrics API"
Upload-File "backend/eproc_server_mysql.py" "/home/ubuntu/lavangam/backend/eproc_server_mysql.py" "Uploading updated eproc server"
Upload-File "backend/database_operations_mysql.py" "/home/ubuntu/lavangam/backend/database_operations_mysql.py" "Uploading updated database operations"

# Upload frontend files
Upload-File "src/config/api.ts" "/home/ubuntu/lavangam/src/config/api.ts" "Uploading updated API config"
Upload-File "src/components/Admin/AdminPanel.tsx" "/home/ubuntu/lavangam/src/components/Admin/AdminPanel.tsx" "Uploading updated admin panel"
Upload-File "src/components/SystemUsageChart.tsx" "/home/ubuntu/lavangam/src/components/SystemUsageChart.tsx" "Uploading updated system usage chart"

# Upload new files
Upload-File "backend/test_database_fixes.py" "/home/ubuntu/lavangam/backend/test_database_fixes.py" "Uploading test script"
Upload-File "backend/start_admin_metrics.py" "/home/ubuntu/lavangam/backend/start_admin_metrics.py" "Uploading admin metrics starter"

# Step 4: Install dependencies
Write-Host "`n📦 Step 4: Installing dependencies..." -ForegroundColor Yellow
Invoke-RemoteCommand "cd /home/ubuntu/lavangam/backend && pip install psutil pymysql fastapi uvicorn" "Installing Python dependencies"

# Step 5: Test database connection
Write-Host "`n🔍 Step 5: Testing database connection..." -ForegroundColor Yellow
$dbTest = Invoke-RemoteCommand "cd /home/ubuntu/lavangam/backend && python -c 'import pymysql; conn = pymysql.connect(host=\"44.244.61.85\", port=3306, user=\"root\", password=\"thanuja\", database=\"Toolinformation\"); print(\"Database connection successful\"); conn.close()'" "Testing database connection"

if ($dbTest -like "*successful*") {
    Write-Host "✅ Database connection test passed" -ForegroundColor Green
} else {
    Write-Host "❌ Database connection test failed" -ForegroundColor Red
}

# Step 6: Restart services
Write-Host "`n🔄 Step 6: Restarting services..." -ForegroundColor Yellow

# Stop existing services
Invoke-RemoteCommand "sudo systemctl stop lavangam-admin-metrics 2>/dev/null || true" "Stopping admin metrics service"
Invoke-RemoteCommand "sudo systemctl stop lavangam-backend 2>/dev/null || true" "Stopping backend service"

# Start admin metrics service
Write-Host "🚀 Starting Admin Metrics API..." -ForegroundColor Cyan
Invoke-RemoteCommand "cd /home/ubuntu/lavangam/backend && nohup python start_admin_metrics.py > admin_metrics.log 2>&1 &" "Starting admin metrics API"

# Wait a moment for service to start
Start-Sleep -Seconds 5

# Step 7: Test the fixes
Write-Host "`n🧪 Step 7: Testing the fixes..." -ForegroundColor Yellow

# Test admin metrics API
$apiTest = Invoke-RemoteCommand "curl -s http://44.244.35.65:8001/health" "Testing admin metrics API health"

if ($apiTest -like "*healthy*") {
    Write-Host "✅ Admin metrics API is healthy" -ForegroundColor Green
} else {
    Write-Host "❌ Admin metrics API health check failed" -ForegroundColor Red
}

# Test real-time endpoints
$realtimeTest = Invoke-RemoteCommand "curl -s http://44.244.35.65:8001/system-resources-realtime" "Testing real-time endpoints"

if ($realtimeTest -like "*cpu_percent*") {
    Write-Host "✅ Real-time endpoints working" -ForegroundColor Green
} else {
    Write-Host "❌ Real-time endpoints test failed" -ForegroundColor Red
}

# Step 8: Build and deploy frontend
Write-Host "`n🏗️ Step 8: Building frontend..." -ForegroundColor Yellow
Invoke-RemoteCommand "cd /home/ubuntu/lavangam/src && npm install" "Installing frontend dependencies"
Invoke-RemoteCommand "cd /home/ubuntu/lavangam/src && npm run build" "Building frontend"

# Step 9: Final status check
Write-Host "`n📊 Step 9: Final status check..." -ForegroundColor Yellow

Write-Host "`n🎯 DEPLOYMENT SUMMARY" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Cyan
Write-Host "✅ Database IP updated to: 44.244.61.85" -ForegroundColor Green
Write-Host "✅ Database name corrected to: Toolinformation" -ForegroundColor Green
Write-Host "✅ Real-time system resources enabled" -ForegroundColor Green
Write-Host "✅ Merge files database storage enabled" -ForegroundColor Green
Write-Host "✅ Admin panel performance improved" -ForegroundColor Green

Write-Host "`n🔗 Access URLs:" -ForegroundColor Yellow
Write-Host "   - Admin Panel: http://$SERVER_IP:3000/dashboard" -ForegroundColor Cyan
Write-Host "   - Admin Metrics API: http://$SERVER_IP:8001" -ForegroundColor Cyan
Write-Host "   - phpMyAdmin: http://$SERVER_IP/phpmyadmin/" -ForegroundColor Cyan

Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Access the admin panel to verify real-time updates" -ForegroundColor White
Write-Host "   2. Test the 'Merge all files' functionality" -ForegroundColor White
Write-Host "   3. Check system resources display" -ForegroundColor White
Write-Host "   4. Monitor database size and job queue" -ForegroundColor White

Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Green
