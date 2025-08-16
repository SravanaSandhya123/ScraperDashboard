# EC2 Deployment Script for Lavangam Backend
# This deploys to a simple EC2 instance with auto-startup

param(
    [string]$InstanceType = "t3.medium",
    [string]$KeyPairName = "mahi",
    [string]$Region = "us-west-2"
)

Write-Host "🚀 Deploying Lavangam Backend to EC2" -ForegroundColor Green

# Create security group
Write-Host "`n🔒 Creating security group..." -ForegroundColor Yellow

try {
    $sgResult = aws ec2 create-security-group --group-name "lavangam-backend-sg-$(Get-Random)" --description "Lavangam Backend Security Group" --region $Region --output json | ConvertFrom-Json
    $sgId = $sgResult.GroupId
    Write-Host "✅ Security group created: $sgId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create security group. It may already exist." -ForegroundColor Red
    # Try to find existing security group
    $existingSg = aws ec2 describe-security-groups --group-names "lavangam-backend-sg" --region $Region --query 'SecurityGroups[0].GroupId' --output text 2>$null
    if ($existingSg) {
        $sgId = $existingSg
        Write-Host "✅ Using existing security group: $sgId" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot create or find security group" -ForegroundColor Red
        exit 1
    }
}

# Add security group rules for all your ports
Write-Host "🔓 Adding security group rules..." -ForegroundColor Yellow
$ports = @(22, 80, 443, 8000, 5022, 5024, 8004, 5025, 5000, 5001, 5002, 8765)
foreach ($port in $ports) {
    try {
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port $port --cidr "0.0.0.0/0" --region $Region | Out-Null
        Write-Host "  ✅ Port $port opened" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Port $port may already be open" -ForegroundColor Yellow
    }
}

# Create user data script for auto-startup
$userDataScript = @'
#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip git unzip awscli

# Download and extract your code
cd /opt
mkdir -p lavangam
cd lavangam
aws s3 cp s3://lavangam-backend-deploy-6352/lavangam-backend-deployment.zip .
unzip -o lavangam-backend-deployment.zip

# Install requirements
pip3 install -r requirements.txt

# Create systemd service for auto-startup
cat > /etc/systemd/system/lavangam-backend.service << 'EOF'
[Unit]
Description=Lavangam Backend Services
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/lavangam
ExecStart=/usr/bin/python3 application.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=PORT=80

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable lavangam-backend.service
systemctl start lavangam-backend.service

# Create status check script
cat > /opt/lavangam/check-status.sh << 'EOF'
#!/bin/bash
echo "=== Lavangam Backend Status ==="
systemctl status lavangam-backend.service --no-pager
echo ""
echo "=== Active Ports ==="
netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|5000|5001|80)' || echo "Services may still be starting..."
echo ""
echo "=== Service Logs (last 10 lines) ==="
journalctl -u lavangam-backend.service -n 10 --no-pager
EOF
chmod +x /opt/lavangam/check-status.sh

# Wait for services to start
sleep 30
'@

# Save user data to file
$userDataScript | Out-File -FilePath "user-data.sh" -Encoding UTF8

Write-Host "`n🖥️ Launching EC2 instance..." -ForegroundColor Yellow
Write-Host "   Instance type: $InstanceType" -ForegroundColor Cyan
Write-Host "   Key pair: $KeyPairName" -ForegroundColor Cyan
Write-Host "   This will automatically start all your backend services!" -ForegroundColor Green

# Launch EC2 instance
try {
    $launchResult = aws ec2 run-instances --image-id "ami-0c02fb55956c7d316" --count 1 --instance-type $InstanceType --key-name $KeyPairName --security-group-ids $sgId --user-data "file://user-data.sh" --region $Region --output json | ConvertFrom-Json
    $instanceId = $launchResult.Instances[0].InstanceId

    if ($instanceId) {
        Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
        
        # Wait for instance to be running
        Write-Host "`n⏳ Waiting for instance to be ready (this may take 2-3 minutes)..." -ForegroundColor Yellow
        aws ec2 wait instance-running --instance-ids $instanceId --region $Region
        
        # Get public IP
        $instanceInfo = aws ec2 describe-instances --instance-ids $instanceId --region $Region --output json | ConvertFrom-Json
        $publicIp = $instanceInfo.Reservations[0].Instances[0].PublicIpAddress
        
        Write-Host "✅ Instance is ready!" -ForegroundColor Green
        Write-Host "🌐 Public IP: $publicIp" -ForegroundColor Cyan
        
        Write-Host "`n⏳ Waiting for services to start (30 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        Write-Host "`n🎯 Your Backend URLs:" -ForegroundColor Cyan
        Write-Host "   Health Check: http://$publicIp/health" -ForegroundColor White
        Write-Host "   Main API: http://$publicIp:8000" -ForegroundColor White  
        Write-Host "   Scrapers API: http://$publicIp:5022" -ForegroundColor White
        Write-Host "   System API: http://$publicIp:5024" -ForegroundColor White
        Write-Host "   Dashboard API: http://$publicIp:8004" -ForegroundColor White
        Write-Host "   Admin Metrics: http://$publicIp:5025" -ForegroundColor White
        
        Write-Host "`n🧪 Testing health endpoint..." -ForegroundColor Yellow
        try {
            $healthResponse = Invoke-RestMethod -Uri "http://$publicIp/health" -Method Get -TimeoutSec 10
            Write-Host "✅ Health check passed!" -ForegroundColor Green
            Write-Host "   Response: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor Cyan
        } catch {
            Write-Host "⚠️ Health check failed - services may still be starting" -ForegroundColor Yellow
            Write-Host "   Try again in a few minutes: http://$publicIp/health" -ForegroundColor Cyan
        }
        
        Write-Host "`n📋 Instance Details:" -ForegroundColor Yellow
        Write-Host "   Instance ID: $instanceId" -ForegroundColor White
        Write-Host "   Public IP: $publicIp" -ForegroundColor White
        Write-Host "   Security Group: $sgId" -ForegroundColor White
        
        Write-Host "`n🔧 SSH Access:" -ForegroundColor Yellow
        Write-Host "   ssh -i $KeyPairName.pem ubuntu@$publicIp" -ForegroundColor White
        Write-Host "   Check status: sudo /opt/lavangam/check-status.sh" -ForegroundColor White
        
        # Save connection info
        $connectionInfo = @{
            InstanceId = $instanceId
            PublicIP = $publicIp
            SecurityGroup = $sgId
            KeyPair = $KeyPairName
            Endpoints = @{
                Health = "http://$publicIp/health"
                MainAPI = "http://$publicIp:8000"
                ScrapersAPI = "http://$publicIp:5022"
                SystemAPI = "http://$publicIp:5024"
                DashboardAPI = "http://$publicIp:8004"
                AdminMetrics = "http://$publicIp:5025"
            }
            SSHCommand = "ssh -i $KeyPairName.pem ubuntu@$publicIp"
        }
        
        $connectionInfo | ConvertTo-Json | Out-File "ec2-connection-info.json"
        Write-Host "`n💾 Connection info saved to: ec2-connection-info.json" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ Failed to get instance ID" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to launch EC2 instance: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Make sure your key pair '$KeyPairName' exists in region $Region" -ForegroundColor Yellow
}

Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "Your backend will automatically start all services on boot!" -ForegroundColor Green
Write-Host "All ports (8000, 5022, 5024, 8004, 5025) will be available automatically!" -ForegroundColor Green
