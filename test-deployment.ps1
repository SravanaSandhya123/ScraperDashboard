# Test Deployment Script for Lavangam Backend
# This script tests the deployed backend endpoints

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [string]$Protocol = "http",
    [int]$BackendPort = 8000,
    [int]$HttpPort = 80
)

Write-Host "🧪 Testing Lavangam Backend Deployment" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Server IP: $ServerIP" -ForegroundColor White
Write-Host "Protocol: $Protocol" -ForegroundColor White
Write-Host "Backend Port: $BackendPort" -ForegroundColor White
Write-Host "HTTP Port: $HttpPort" -ForegroundColor White

# Test functions
function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Description
    )
    
    try {
        Write-Host "`n🔍 Testing $Description..." -ForegroundColor Yellow
        Write-Host "URL: $Url" -ForegroundColor Gray
        
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✅ $Description - Status: $($response.StatusCode)" -ForegroundColor Green
        
        if ($response.Content.Length -gt 0) {
            Write-Host "   Content length: $($response.Content.Length) characters" -ForegroundColor Gray
        }
        
        return $true
    }
    catch {
        Write-Host "❌ $Description - Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-DatabaseConnection {
    param(
        [string]$ServerIP
    )
    
    try {
        Write-Host "`n🗄️ Testing Database Connection..." -ForegroundColor Yellow
        
        # Test MySQL port
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ConnectAsync($ServerIP, 3306).Wait(5000) | Out-Null
        
        if ($tcpClient.Connected) {
            Write-Host "✅ MySQL port 3306 is accessible" -ForegroundColor Green
            $tcpClient.Close()
        } else {
            Write-Host "❌ MySQL port 3306 is not accessible" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Database connection test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test results tracking
$testResults = @{}

Write-Host "`n🚀 Starting deployment tests..." -ForegroundColor Green

# Test 1: Backend API Health
$backendHealthUrl = "$Protocol`://$ServerIP`:$BackendPort/health"
$testResults.BackendHealth = Test-Endpoint -Url $backendHealthUrl -Description "Backend Health Check"

# Test 2: Backend API Root
$backendRootUrl = "$Protocol`://$ServerIP`:$BackendPort/"
$testResults.BackendRoot = Test-Endpoint -Url $backendRootUrl -Description "Backend Root Endpoint"

# Test 3: Nginx HTTP
$nginxUrl = "$Protocol`://$ServerIP`:$HttpPort"
$testResults.Nginx = Test-Endpoint -Url $nginxUrl -Description "Nginx HTTP Server"

# Test 4: Nginx Health Check
$nginxHealthUrl = "$Protocol`://$ServerIP`:$HttpPort/health"
$testResults.NginxHealth = Test-Endpoint -Url $nginxHealthUrl -Description "Nginx Health Check"

# Test 5: phpMyAdmin
$phpMyAdminUrl = "$Protocol`://$ServerIP`:$HttpPort/phpmyadmin/"
$testResults.PhpMyAdmin = Test-Endpoint -Url $phpMyAdminUrl -Description "phpMyAdmin Interface"

# Test 6: Database Connection
Test-DatabaseConnection -ServerIP $ServerIP

# Test 7: Port Availability
Write-Host "`n🔌 Testing Port Availability..." -ForegroundColor Yellow
$ports = @(22, 80, 443, 8000, 8080, 3306)

foreach ($port in $ports) {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ConnectAsync($ServerIP, $port).Wait(3000) | Out-Null
        
        if ($tcpClient.Connected) {
            Write-Host "✅ Port $port is open" -ForegroundColor Green
            $tcpClient.Close()
        } else {
            Write-Host "❌ Port $port is closed" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Port $port test failed" -ForegroundColor Red
    }
}

# Test 8: API Endpoints (if available)
Write-Host "`n🔗 Testing API Endpoints..." -ForegroundColor Yellow

$apiEndpoints = @(
    "/api/dashboard-overview",
    "/api/export-data",
    "/api/export-files"
)

foreach ($endpoint in $apiEndpoints) {
    $apiUrl = "$Protocol`://$ServerIP`:$BackendPort$endpoint"
    $testResults."API_$($endpoint.Replace('/', '_').Replace('-', '_'))" = Test-Endpoint -Url $apiUrl -Description "API Endpoint: $endpoint"
}

# Summary
Write-Host "`n📊 Test Results Summary:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

$passedTests = 0
$totalTests = $testResults.Count

foreach ($test in $testResults.GetEnumerator()) {
    $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$status - $($test.Key)" -ForegroundColor $(if ($test.Value) { "Green" } else { "Red" })
    if ($test.Value) { $passedTests++ }
}

Write-Host "`n📈 Overall Results:" -ForegroundColor Cyan
Write-Host "Passed: $passedTests/$totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 All tests passed! Your backend is working correctly." -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Some tests failed. Please check the deployment and try again." -ForegroundColor Yellow
}

# Connection information
Write-Host "`n🔗 Access Information:" -ForegroundColor Cyan
Write-Host "Backend API: $Protocol`://$ServerIP`:$BackendPort" -ForegroundColor White
Write-Host "phpMyAdmin: $Protocol`://$ServerIP`:$HttpPort/phpmyadmin/" -ForegroundColor White
Write-Host "Nginx: $Protocol`://$ServerIP`:$HttpPort" -ForegroundColor White

Write-Host "`n🔐 Database Credentials:" -ForegroundColor Cyan
Write-Host "Username: root" -ForegroundColor White
Write-Host "Password: thanuja" -ForegroundColor White
Write-Host "Database: toolinfomation" -ForegroundColor White

Write-Host "`n✅ Testing completed!" -ForegroundColor Green
