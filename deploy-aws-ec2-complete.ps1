# Lavangam Backend Complete AWS EC2 Deployment Script
# This script deploys your backend with Nginx, phpMyAdmin, MySQL, and automatic startup

param(
    [string]$InstanceType = "t3.medium",
    [string]$KeyName = "lavangam-key",
    [string]$SecurityGroupName = "lavangam-backend-sg",
    [string]$InstanceName = "lavangam-backend-server"
)

Write-Host "🚀 Starting Lavangam Backend Complete AWS EC2 Deployment..." -ForegroundColor Green

# Check if AWS CLI is installed
try {
    aws --version | Out-Null
    Write-Host "✅ AWS CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if AWS credentials are configured
try {
    $identity = aws sts get-caller-identity --query 'Arn' --output text 2>$null
    if ($identity) {
        Write-Host "✅ AWS credentials configured: $identity" -ForegroundColor Green
    } else {
        throw "No credentials"
    }
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Step 1: Create Security Group
Write-Host "🔒 Creating Security Group..." -ForegroundColor Yellow
try {
    # Check if security group already exists
    $existingSG = aws ec2 describe-security-groups --group-names $SecurityGroupName --query 'SecurityGroups[0].GroupId' --output text 2>$null
    
    if ($existingSG -and $existingSG -ne "None") {
        Write-Host "✅ Security Group already exists: $existingSG" -ForegroundColor Green
        $securityGroupId = $existingSG
    } else {
        # Create new security group
        $securityGroupId = aws ec2 create-security-group `
            --group-name $SecurityGroupName `
            --description "Security group for Lavangam Backend" `
            --query 'GroupId' --output text
        
        Write-Host "✅ Created Security Group: $securityGroupId" -ForegroundColor Green
        
        # Add inbound rules
        aws ec2 authorize-security-group-ingress `
            --group-id $securityGroupId `
            --protocol tcp --port 22 --cidr 0.0.0.0/0 | Out-Null
        
        aws ec2 authorize-security-group-ingress `
            --group-id $securityGroupId `
            --protocol tcp --port 80 --cidr 0.0.0.0/0 | Out-Null
        
        aws ec2 authorize-security-group-ingress `
            --group-id $securityGroupId `
            --protocol tcp --port 443 --cidr 0.0.0.0/0 | Out-Null
        
        aws ec2 authorize-security-group-ingress `
            --group-id $securityGroupId `
            --protocol tcp --port 8000 --cidr 0.0.0.0/0 | Out-Null
        
        aws ec2 authorize-security-group-ingress `
            --group-id $securityGroupId `
            --protocol tcp --port 8080 --cidr 0.0.0.0/0 | Out-Null
        
        aws ec2 authorize-security-group-ingress `
            --group-id $securityGroupId `
            --protocol tcp --port 3306 --cidr 0.0.0.0/0 | Out-Null
        
        Write-Host "✅ Security Group rules configured" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to create Security Group: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create Key Pair
Write-Host "🔑 Creating Key Pair..." -ForegroundColor Yellow
try {
    # Check if key pair already exists
    $existingKey = aws ec2 describe-key-pairs --key-names $KeyName --query 'KeyPairs[0].KeyName' --output text 2>$null
    
    if ($existingKey -and $existingKey -ne "None") {
        Write-Host "✅ Key Pair already exists: $existingKey" -ForegroundColor Green
    } else {
        # Create new key pair
        aws ec2 create-key-pair --key-name $KeyName --query 'KeyMaterial' --output text > "$KeyName.pem"
        
        # Set proper permissions on Windows
        icacls "$KeyName.pem" /inheritance:r /grant:r "$env:USERNAME`:F" | Out-Null
        
        Write-Host "✅ Created Key Pair: $KeyName.pem" -ForegroundColor Green
        Write-Host "⚠️  IMPORTANT: Keep the $KeyName.pem file secure!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to create Key Pair: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Launch EC2 Instance
Write-Host "🖥️ Launching EC2 Instance..." -ForegroundColor Yellow
try {
    # Get the latest Ubuntu 22.04 LTS AMI
    $amiId = aws ssm get-parameters `
        --names "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id" `
        --query 'Parameters[0].Value' --output text
    
    Write-Host "📦 Using AMI: $amiId" -ForegroundColor Cyan
    
    # Launch instance
    $instanceId = aws ec2 run-instances `
        --image-id $amiId `
        --count 1 `
        --instance-type $InstanceType `
        --key-name $KeyName `
        --security-group-ids $securityGroupId `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$InstanceName}]" `
        --query 'Instances[0].InstanceId' --output text
    
    Write-Host "✅ Launched EC2 Instance: $instanceId" -ForegroundColor Green
    
    # Wait for instance to be running
    Write-Host "⏳ Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId
    
    # Get public IP
    $publicIP = aws ec2 describe-instances `
        --instance-ids $instanceId `
        --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "✅ Instance is running with IP: $publicIP" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to launch EC2 Instance: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Create User Data Script
Write-Host "📝 Creating User Data Script..." -ForegroundColor Yellow
$userDataScript = @"
#!/bin/bash
# Lavangam Backend Complete Setup Script

set -e

# Update system
apt update && apt upgrade -y

# Install system dependencies
apt install -y python3 python3-pip python3-venv nginx mysql-server mysql-client curl wget git unzip htop ufw

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Setup MySQL
systemctl start mysql
systemctl enable mysql

# Secure MySQL installation
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'thanuja';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

# Create database
mysql -e "CREATE DATABASE IF NOT EXISTS toolinfomation;"
mysql -e "GRANT ALL PRIVILEGES ON toolinfomation.* TO 'root'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Install phpMyAdmin
apt install -y php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
apt install -y apache2 libapache2-mod-php

# Configure phpMyAdmin
echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
systemctl restart apache2

# Create application directory
mkdir -p /opt/lavangam
cd /opt/lavangam

# Setup Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install fastapi uvicorn[standard] flask flask-cors flask-socketio requests mysql-connector-python PyMySQL pandas python-dotenv selenium openpyxl xlsxwriter psutil websockets python-multipart jinja2 pydantic python-jose[cryptography] passlib[bcrypt] bcrypt cryptography setuptools gunicorn supervisor

# Create systemd service for backend
cat > /etc/systemd/system/lavangam-backend.service << 'EOF'
[Unit]
Description=Lavangam Backend Service
After=network.target mysql.service

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/lavangam
Environment=PATH=/opt/lavangam/venv/bin
ExecStart=/opt/lavangam/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start backend service
systemctl daemon-reload
systemctl enable lavangam-backend
systemctl start lavangam-backend

# Configure Nginx
cat > /etc/nginx/sites-available/lavangam << 'EOF'
server {
    listen 80;
    server_name _;

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # phpMyAdmin
    location /phpmyadmin/ {
        proxy_pass http://127.0.0.1/phpmyadmin/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Root redirect to backend
    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site and restart Nginx
ln -sf /etc/nginx/sites-available/lavangam /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Configure firewall
ufw --force enable
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8000
ufw allow 8080
ufw allow 3306

# Create startup script
cat > /opt/lavangam/startup.sh << 'EOF'
#!/bin/bash
cd /opt/lavangam
source venv/bin/activate
systemctl start mysql
systemctl start nginx
systemctl start lavangam-backend
EOF

chmod +x /opt/lavangam/startup.sh

# Add to crontab for auto-startup
(crontab -l 2>/dev/null; echo "@reboot /opt/lavangam/startup.sh") | crontab -

echo "Setup completed successfully!"
"@

# Save user data script
$userDataScript | Out-File -FilePath "user-data-complete.sh" -Encoding UTF8
Write-Host "✅ User Data Script created: user-data-complete.sh" -ForegroundColor Green

# Step 5: Wait for instance to be ready and deploy
Write-Host "⏳ Waiting for instance to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Step 6: Copy backend files to instance
Write-Host "📁 Copying backend files to instance..." -ForegroundColor Yellow
try {
    # Create a deployment package
    if (Test-Path "backend") {
        Compress-Archive -Path "backend\*" -DestinationPath "lavangam-backend-deploy.zip" -Force
        Write-Host "✅ Created deployment package" -ForegroundColor Green
    }
    
    # Wait a bit more for SSH to be ready
    Start-Sleep -Seconds 30
    
    # Copy files using SCP (if available) or provide instructions
    Write-Host "📋 Manual deployment steps:" -ForegroundColor Cyan
    Write-Host "1. Connect to your instance: ssh -i $KeyName.pem ubuntu@$publicIP" -ForegroundColor White
    Write-Host "2. Upload your backend files or clone from your repository" -ForegroundColor White
    Write-Host "3. Run the setup script: sudo bash /opt/lavangam/setup.sh" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to copy files: $_" -ForegroundColor Red
}

# Step 7: Display connection information
Write-Host "`n🎉 Deployment Summary:" -ForegroundColor Green
Write-Host "Instance ID: $instanceId" -ForegroundColor White
Write-Host "Public IP: $publicIP" -ForegroundColor White
Write-Host "Security Group: $securityGroupId" -ForegroundColor White
Write-Host "Key Pair: $KeyName.pem" -ForegroundColor White

Write-Host "`n🔗 Access URLs:" -ForegroundColor Cyan
Write-Host "Backend API: http://$publicIP:8000" -ForegroundColor White
Write-Host "phpMyAdmin: http://$publicIP/phpmyadmin/" -ForegroundColor White
Write-Host "Nginx: http://$publicIP" -ForegroundColor White

Write-Host "`n🔐 Database Credentials:" -ForegroundColor Cyan
Write-Host "Username: root" -ForegroundColor White
Write-Host "Password: thanuja" -ForegroundColor White
Write-Host "Database: toolinfomation" -ForegroundColor White

Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Connect to your instance using the key file" -ForegroundColor White
Write-Host "2. Upload your backend code to /opt/lavangam/" -ForegroundColor White
Write-Host "3. The backend will start automatically on reboot" -ForegroundColor White
Write-Host "4. Check services: sudo systemctl status lavangam-backend" -ForegroundColor White

Write-Host "`n✅ Deployment script completed!" -ForegroundColor Green
