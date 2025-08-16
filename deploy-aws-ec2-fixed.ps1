# Lavangam Backend AWS EC2 Deployment Script (Fixed)
# This script creates an EC2 instance and deploys the backend automatically

param(
    [string]$InstanceType = "t3.medium",
    [string]$KeyName = "lavangam-key",
    [string]$SecurityGroupName = "lavangam-backend-sg",
    [string]$InstanceName = "lavangam-backend-server"
)

Write-Host "🚀 Starting Lavangam Backend Complete AWS EC2 Deployment..." -ForegroundColor Green
Write-Host "===============================================================" -ForegroundColor Cyan

# Check AWS CLI installation
try {
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
    } else {
        throw "AWS CLI not found"
    }
} catch {
    Write-Host "❌ AWS CLI not found or not in PATH!" -ForegroundColor Red
    Write-Host "Please install AWS CLI and configure your credentials first." -ForegroundColor Yellow
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Cyan
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    Write-Host "✅ AWS credentials configured for account: $($identity.Account)" -ForegroundColor Green
    Write-Host "   User: $($identity.Arn)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ AWS credentials not configured!" -ForegroundColor Red
    Write-Host "Please run 'aws configure' to set up your credentials." -ForegroundColor Yellow
    exit 1
}

# Create security group
Write-Host "`n🔒 Creating security group..." -ForegroundColor Yellow
try {
    $sgExists = aws ec2 describe-security-groups --group-names $SecurityGroupName 2>$null
    if ($sgExists) {
        Write-Host "✅ Security group '$SecurityGroupName' already exists" -ForegroundColor Green
    } else {
        $sgId = aws ec2 create-security-group --group-name $SecurityGroupName --description "Lavangam Backend Security Group" --query 'GroupId' --output text
        Write-Host "✅ Security group created: $sgId" -ForegroundColor Green
        
        # Add security group rules
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 443 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 8000 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 8080 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 3306 --cidr 0.0.0.0/0
        
        Write-Host "✅ Security group rules configured" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to create security group: $_" -ForegroundColor Red
    exit 1
}

# Create key pair
Write-Host "`n🔑 Creating key pair..." -ForegroundColor Yellow
try {
    $keyExists = aws ec2 describe-key-pairs --key-names $KeyName 2>$null
    if ($keyExists) {
        Write-Host "✅ Key pair '$KeyName' already exists" -ForegroundColor Green
    } else {
        aws ec2 create-key-pair --key-name $KeyName --query 'KeyMaterial' --output text > "$KeyName.pem"
        Write-Host "✅ Key pair created and saved to $KeyName.pem" -ForegroundColor Green
        Write-Host "⚠️  IMPORTANT: Keep this .pem file secure!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Failed to create key pair: $_" -ForegroundColor Red
    exit 1
}

# Get the latest Ubuntu 22.04 LTS AMI
Write-Host "`n🔍 Getting latest Ubuntu 22.04 LTS AMI..." -ForegroundColor Yellow
try {
    $amiId = aws ssm get-parameters --names "/aws/service/canonical/ubuntu/server/22.04/latest/amd64/hvm/ebs-gp2/ami-id" --query 'Parameters[0].Value' --output text
    Write-Host "✅ Using AMI: $amiId" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to get AMI: $_" -ForegroundColor Red
    exit 1
}

# Create user data script file
Write-Host "`n📝 Creating user data script..." -ForegroundColor Yellow
$userDataScript = @"
#!/bin/bash
# Lavangam Backend Complete Setup Script
set -e

echo "🚀 Starting Lavangam Backend Setup..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install required packages
echo "📦 Installing required packages..."
apt install -y python3 python3-pip python3-venv nginx mysql-server mysql-client curl wget git unzip htop ufw apache2 libapache2-mod-php php php-mysql php-mbstring php-xml php-curl php-gd php-zip

# Install Node.js
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# MySQL Setup
echo "🗄️ Setting up MySQL..."
systemctl start mysql
systemctl enable mysql

# Secure MySQL root user
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'thanuja';"

# Create database and user
mysql -e "DROP DATABASE IF EXISTS toolinfomation;"
mysql -e "CREATE DATABASE toolinfomation CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "GRANT ALL PRIVILEGES ON toolinfomation.* TO 'root'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# phpMyAdmin Setup
echo "🌐 Setting up phpMyAdmin..."
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password thanuja" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password thanuja" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

apt install -y phpmyadmin

# Configure phpMyAdmin
cat > /etc/phpmyadmin/config.inc.php << 'EOF'
<?php
declare(strict_types=1);
$cfg['blowfish_secret'] = 'lavangam-secret-key-2024';
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['port'] = '3306';
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = 'thanuja';
$cfg['PmaAbsoluteUri'] = '/phpmyadmin/';
EOF

# Enable phpMyAdmin in Apache
echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
systemctl restart apache2

# Application Directory Setup
echo "📁 Setting up application directory..."
mkdir -p /opt/lavangam
chown ubuntu:ubuntu /opt/lavangam
cd /opt/lavangam

# Create Python virtual environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install fastapi uvicorn[standard] flask flask-cors flask-socketio requests mysql-connector-python PyMySQL pandas python-dotenv selenium openpyxl xlsxwriter psutil websockets python-multipart jinja2 pydantic python-jose[cryptography] passlib[bcrypt] bcrypt cryptography setuptools gunicorn supervisor

# Create systemd service for backend
echo "🔧 Creating systemd service..."
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

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/lavangam << 'EOF'
server {
    listen 80;
    server_name _;

    # Backend API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # phpMyAdmin proxy
    location /phpmyadmin/ {
        proxy_pass http://127.0.0.1/phpmyadmin/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Root proxy to backend
    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
    }
}
EOF

# Enable site and remove default
ln -sf /etc/nginx/sites-available/lavangam /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# Configure firewall
echo "🔥 Configuring firewall..."
ufw --force enable
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8000
ufw allow 8080
ufw allow 3306

# Create startup script
echo "📜 Creating startup script..."
cat > /opt/lavangam/startup.sh << 'EOF'
#!/bin/bash
cd /opt/lavangam
source venv/bin/activate
sudo systemctl start mysql
sudo systemctl start nginx
sudo systemctl start lavangam-backend
EOF

chmod +x /opt/lavangam/startup.sh

# Add to crontab for auto-startup
(crontab -l 2>/dev/null; echo "@reboot /opt/lavangam/startup.sh") | crontab -

# Create environment file
echo "⚙️ Creating environment file..."
cat > /opt/lavangam/.env << 'EOF'
DB_HOST=localhost
DB_PORT=3306
DB_NAME=toolinfomation
DB_USER=root
DB_PASSWORD=thanuja
DATABASE_URL=mysql+pymysql://root:thanuja@localhost:3306/toolinfomation
EOF

# Create database setup script
echo "🗄️ Creating database setup script..."
cat > /opt/lavangam/setup_database.py << 'EOF'
#!/usr/bin/env python3
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

def setup_database():
    try:
        connection = pymysql.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 3306)),
            user=os.getenv('DB_USER', 'root'),
            password=os.getenv('DB_PASSWORD', 'thanuja'),
            charset='utf8mb4'
        )
        
        cursor = connection.cursor()
        
        # Create database if not exists
        cursor.execute("CREATE DATABASE IF NOT EXISTS toolinfomation")
        cursor.execute("USE toolinfomation")
        
        # Create basic tables
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(255) UNIQUE NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS tools (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                description TEXT,
                status VARCHAR(50) DEFAULT 'active',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        connection.commit()
        print("✅ Database setup completed successfully!")
        
    except Exception as e:
        print(f"❌ Database setup failed: {e}")
    finally:
        if 'connection' in locals():
            connection.close()

if __name__ == "__main__":
    setup_database()
EOF

chmod +x /opt/lavangam/setup_database.py

# Enable and start services
echo "🚀 Enabling and starting services..."
systemctl daemon-reload
systemctl enable lavangam-backend nginx mysql
systemctl start mysql nginx lavangam-backend

# Setup database
echo "🗄️ Setting up database..."
cd /opt/lavangam
source venv/bin/activate
python setup_database.py

# Create status check script
echo "📊 Creating status check script..."
cat > /opt/lavangam/check_status.sh << 'EOF'
#!/bin/bash
echo "=== Lavangam Backend Status ==="
echo "MySQL Status:"
sudo systemctl status mysql --no-pager -l
echo ""
echo "Nginx Status:"
sudo systemctl status nginx --no-pager -l
echo ""
echo "Backend Status:"
sudo systemctl status lavangam-backend --no-pager -l
echo ""
echo "Port Status:"
netstat -tlnp | grep -E ':(80|443|8000|8080|3306)'
echo ""
echo "Process Status:"
ps aux | grep -E '(uvicorn|nginx|mysql)' | grep -v grep
EOF

chmod +x /opt/lavangam/check_status.sh

# Final status check
echo "🔍 Performing final status check..."
sleep 10
/opt/lavangam/check_status.sh

echo ""
echo "🎉 Lavangam Backend Setup Complete!"
echo "=================================="
echo "✅ MySQL Database: toolinfomation (root/thanuja)"
echo "✅ phpMyAdmin: http://YOUR_IP/phpmyadmin/"
echo "✅ Backend API: http://YOUR_IP:8000/"
echo "✅ Nginx Proxy: http://YOUR_IP/"
echo "✅ Health Check: http://YOUR_IP/health"
echo ""
echo "📁 Application Directory: /opt/lavangam"
echo "🔧 Service Management: sudo systemctl [start|stop|restart|status] lavangam-backend"
echo "📊 Status Check: /opt/lavangam/check_status.sh"
echo "🚀 Auto-startup: Configured via systemd and crontab"
echo ""
echo "🔐 SSH Access: ssh -i $KeyName.pem ubuntu@YOUR_IP"
echo "⚠️  Remember to replace YOUR_IP with the actual EC2 instance IP address"
"@

# Save user data script to file
$userDataScript | Out-File -FilePath "user-data-complete.sh" -Encoding UTF8
Write-Host "✅ User data script created: user-data-complete.sh" -ForegroundColor Green

# Launch EC2 instance
Write-Host "`n🚀 Launching EC2 instance..." -ForegroundColor Yellow
try {
    $userDataContent = Get-Content "user-data-complete.sh" -Raw
    $userDataEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($userDataContent))
    
    $instanceParams = @{
        ImageId = $amiId
        MinCount = 1
        MaxCount = 1
        InstanceType = $InstanceType
        KeyName = $KeyName
        SecurityGroupIds = $SecurityGroupName
        UserData = $userDataEncoded
        TagSpecifications = @(
            @{
                ResourceType = "instance"
                Tags = @(
                    @{ Key = "Name"; Value = $InstanceName },
                    @{ Key = "Project"; Value = "Lavangam Backend" },
                    @{ Key = "Environment"; Value = "Production" }
                )
            }
        )
    }
    
    $instance = aws ec2 run-instances @instanceParams --query 'Instances[0]' --output json | ConvertFrom-Json
    $instanceId = $instance.InstanceId
    
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
    Write-Host "⏳ Waiting for instance to be running..." -ForegroundColor Yellow
    
    # Wait for instance to be running
    do {
        Start-Sleep -Seconds 10
        $status = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].State.Name' --output text
        Write-Host "   Instance status: $status" -ForegroundColor Cyan
    } while ($status -ne "running")
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "`n🎉 Deployment Complete!" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Instance ID: $instanceId" -ForegroundColor White
    Write-Host "Public IP: $publicIp" -ForegroundColor White
    Write-Host "Instance Type: $InstanceType" -ForegroundColor White
    
    Write-Host "`n🔗 Access URLs:" -ForegroundColor Yellow
    Write-Host "Backend API: http://$publicIp:8000/" -ForegroundColor Cyan
    Write-Host "Nginx Proxy: http://$publicIp/" -ForegroundColor Cyan
    Write-Host "phpMyAdmin: http://$publicIp/phpmyadmin/" -ForegroundColor Cyan
    Write-Host "Health Check: http://$publicIp/health" -ForegroundColor Cyan
    
    Write-Host "`n🔐 SSH Access:" -ForegroundColor Yellow
    Write-Host "ssh -i $KeyName.pem ubuntu@$publicIp" -ForegroundColor White
    
    Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Wait 5-10 minutes for the setup script to complete" -ForegroundColor White
    Write-Host "2. Test the endpoints using the URLs above" -ForegroundColor White
    Write-Host "3. Upload your backend files to /opt/lavangam on the instance" -ForegroundColor White
    Write-Host "4. Restart the backend service: sudo systemctl restart lavangam-backend" -ForegroundColor White
    
    # Save deployment info
    $deploymentInfo = @{
        InstanceId = $instanceId
        PublicIP = $publicIp
        InstanceType = $InstanceType
        DeploymentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Status = "Deployed"
        AccessURLs = @{
            BackendAPI = "http://$publicIp:8000/"
            NginxProxy = "http://$publicIp/"
            PhpMyAdmin = "http://$publicIp/phpmyadmin/"
            HealthCheck = "http://$publicIp/health"
        }
        SSHCommand = "ssh -i $KeyName.pem ubuntu@$publicIp"
    }
    
    $deploymentInfo | ConvertTo-Json -Depth 10 | Out-File -FilePath "deployment-info.json" -Encoding UTF8
    Write-Host "`n💾 Deployment information saved to: deployment-info.json" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to launch EC2 instance: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Deployment script completed successfully!" -ForegroundColor Green
Write-Host "Your Lavangam backend is now being deployed on AWS EC2." -ForegroundColor Cyan
