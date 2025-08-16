# EC2 Deployment Script for Lavangam Backend
# This deploys to a simple EC2 instance with auto-startup

param(
    [string]$InstanceType = "t3.medium",
    [string]$KeyPairName = "lavangam-key",
    [string]$Region = "us-west-2"
)

Write-Host "🚀 Deploying Lavangam Backend to EC2" -ForegroundColor Green

# Create security group
Write-Host "`n🔒 Creating security group..." -ForegroundColor Yellow
$sgId = aws ec2 create-security-group --group-name lavangam-backend-sg --description "Lavangam Backend Security Group" --region $Region --query 'GroupId' --output text

# Add security group rules for all your ports
$ports = @(22, 80, 443, 8000, 5022, 5024, 8004, 5025, 5000, 5001, 5002, 8765)
foreach ($port in $ports) {
    aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port $port --cidr 0.0.0.0/0 --region $Region
}

Write-Host "✅ Security group created: $sgId" -ForegroundColor Green

# Create user data script for auto-startup
$userDataScript = @"
#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip git unzip awscli

# Download and extract your code
cd /opt
mkdir lavangam
cd lavangam
aws s3 cp s3://lavangam-backend-deploy-6352/lavangam-backend-deployment.zip .
unzip lavangam-backend-deployment.zip

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
systemctl status lavangam-backend.service
echo ""
echo "=== Active Ports ==="
netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|5000|5001|80)'
EOF
chmod +x /opt/lavangam/check-status.sh
"@

# Save user data to file
$userDataScript | Out-File -FilePath "user-data.sh" -Encoding UTF8

Write-Host "`n🖥️ Launching EC2 instance..." -ForegroundColor Yellow
Write-Host "   Instance type: $InstanceType" -ForegroundColor Cyan
Write-Host "   This will automatically start all your backend services!" -ForegroundColor Green

# Launch EC2 instance
$instanceId = aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --count 1 --instance-type $InstanceType --key-name $KeyPairName --security-group-ids $sgId --user-data file://user-data.sh --region $Region --query 'Instances[0].InstanceId' --output text

if ($instanceId) {
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
    
    # Wait for instance to be running
    Write-Host "`n⏳ Waiting for instance to be ready..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region $Region
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --region $Region --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "✅ Instance is ready!" -ForegroundColor Green
    Write-Host "🌐 Public IP: $publicIp" -ForegroundColor Cyan
    
    Write-Host "`n🎯 Your Backend URLs:" -ForegroundColor Cyan
    Write-Host "   Health Check: http://$publicIp/health" -ForegroundColor White
    Write-Host "   Main API: http://$publicIp:8000" -ForegroundColor White  
    Write-Host "   Scrapers API: http://$publicIp:5022" -ForegroundColor White
    Write-Host "   System API: http://$publicIp:5024" -ForegroundColor White
    Write-Host "   Dashboard API: http://$publicIp:8004" -ForegroundColor White
    Write-Host "   Admin Metrics: http://$publicIp:5025" -ForegroundColor White
    
    Write-Host "`n📋 Instance Details:" -ForegroundColor Yellow
    Write-Host "   Instance ID: $instanceId" -ForegroundColor White
    Write-Host "   Public IP: $publicIp" -ForegroundColor White
    Write-Host "   Security Group: $sgId" -ForegroundColor White
    
    Write-Host "`n🔧 SSH Access:" -ForegroundColor Yellow
    Write-Host "   ssh -i $KeyPairName.pem ubuntu@$publicIp" -ForegroundColor White
    Write-Host "   Check status: sudo /opt/lavangam/check-status.sh" -ForegroundColor White
    
} else {
    Write-Host "❌ Failed to launch EC2 instance" -ForegroundColor Red
}

Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "Your backend will automatically start all services on boot!" -ForegroundColor Green
