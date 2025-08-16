# AWS Security Group Setup for Lavangam Backend (PowerShell)
# This script configures security groups for all your backend ports

Write-Host "🔒 Setting up AWS Security Groups for Lavangam Backend..." -ForegroundColor Green
Write-Host "📍 IP Address: 18.236.173.88" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI not found"
    }
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Installation guide: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" -ForegroundColor Yellow
    exit 1
}

# Check if user is authenticated
try {
    $callerIdentity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw "Not authenticated"
    }
    Write-Host "🔐 AWS CLI authenticated successfully!" -ForegroundColor Green
    Write-Host "   Account: $($callerIdentity.Account)" -ForegroundColor Cyan
    Write-Host "   User: $($callerIdentity.Arn)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ AWS CLI is not authenticated. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Get instance information
Write-Host "ℹ️  Getting instance information..." -ForegroundColor Blue
$instanceInfo = aws ec2 describe-instances --filters "Name=ip-address,Values=18.236.173.88" --query 'Reservations[].Instances[0]' --output json 2>$null | ConvertFrom-Json

if (-not $instanceInfo -or $instanceInfo.Count -eq 0) {
    Write-Host "❌ Could not find EC2 instance with IP 18.236.173.88" -ForegroundColor Red
    Write-Host "Please make sure the instance is running and the IP is correct." -ForegroundColor Yellow
    exit 1
}

$instanceId = $instanceInfo.InstanceId
$securityGroupId = $instanceInfo.SecurityGroups[0].GroupId

Write-Host "✅ Found instance: $instanceId" -ForegroundColor Green
Write-Host "✅ Found security group: $securityGroupId" -ForegroundColor Green
Write-Host ""

# Define all the ports that need to be opened
$ports = @(
    @{Port = 80; Description = "HTTP"},
    @{Port = 443; Description = "HTTPS"},
    @{Port = 8000; Description = "Main API"},
    @{Port = 5022; Description = "Scrapers API"},
    @{Port = 5024; Description = "System Usage API"},
    @{Port = 8004; Description = "Dashboard API"},
    @{Port = 5025; Description = "Admin Metrics API"},
    @{Port = 8001; Description = "Analytics API"},
    @{Port = 8002; Description = "Additional Analytics"},
    @{Port = 5020; Description = "E-Procurement WebSocket"},
    @{Port = 5021; Description = "E-Procurement Server"},
    @{Port = 5023; Description = "E-Procurement Fixed"},
    @{Port = 5001; Description = "File Manager"},
    @{Port = 5002; Description = "Export Server"},
    @{Port = 5005; Description = "E-Procurement API"}
)

Write-Host "ℹ️  Configuring security group rules for all ports..." -ForegroundColor Blue
Write-Host ""

# Add rules for each port
foreach ($portInfo in $ports) {
    $port = $portInfo.Port
    $description = $portInfo.Description
    
    Write-Host "ℹ️  Adding rule for $description (Port $port)..." -ForegroundColor Blue
    
    # Check if rule already exists
    $existingRule = aws ec2 describe-security-groups --group-ids $securityGroupId --query "SecurityGroups[].IpPermissions[?FromPort==$port && ToPort==$port]" --output text 2>$null
    
    if ($existingRule -and $existingRule.Trim() -ne "") {
        Write-Host "⚠️  Rule for port $port already exists, skipping..." -ForegroundColor Yellow
    } else {
        # Add the rule
        $result = aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port $port --cidr 0.0.0.0/0 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Added rule for $description (Port $port)" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to add rule for port $port" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "✅ Security group configuration complete!" -ForegroundColor Green
Write-Host ""

# Display current security group rules
Write-Host "ℹ️  Current security group rules:" -ForegroundColor Blue
aws ec2 describe-security-groups --group-ids $securityGroupId --query 'SecurityGroups[].IpPermissions[?IpRanges[0].CidrIp==`0.0.0.0/0`]' --output table

Write-Host ""
Write-Host "ℹ️  Testing connectivity to key ports..." -ForegroundColor Blue

# Test key ports
$testPorts = @(8000, 5022, 5024, 8004, 5025, 8001)
foreach ($port in $testPorts) {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ConnectAsync("18.236.173.88", $port).Wait(5000) | Out-Null
        
        if ($tcpClient.Connected) {
            Write-Host "✅ Port $port is accessible" -ForegroundColor Green
            $tcpClient.Close()
        } else {
            Write-Host "⚠️  Port $port is not accessible (may still be starting up)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Port $port is not accessible (may still be starting up)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ Security group setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your backend services should now be accessible at:" -ForegroundColor Cyan
Write-Host "   Main API: http://18.236.173.88:8000" -ForegroundColor White
Write-Host "   Scrapers API: http://18.236.173.88:5022" -ForegroundColor White
Write-Host "   System API: http://18.236.173.88:5024" -ForegroundColor White
Write-Host "   Dashboard API: http://18.236.173.88:8004" -ForegroundColor White
Write-Host "   Admin Metrics: http://18.236.173.88:5025" -ForegroundColor White
Write-Host "   Analytics API: http://18.236.173.88:8001" -ForegroundColor White
Write-Host ""
Write-Host "🔒 Security group: $securityGroupId" -ForegroundColor Cyan
Write-Host "🖥️  Instance: $instanceId" -ForegroundColor Cyan
Write-Host "📍 IP Address: 18.236.173.88" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Start your backend services on the EC2 instance" -ForegroundColor White
Write-Host "   2. Test all endpoints from external devices" -ForegroundColor White
Write-Host "   3. Update your frontend to use the new AWS URLs" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Your Lavangam backend is now ready for AWS deployment!" -ForegroundColor Green
