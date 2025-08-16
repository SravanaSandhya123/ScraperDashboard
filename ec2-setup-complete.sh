#!/bin/bash

# Lavangam Backend Complete EC2 Setup Script
# This script sets up the complete backend environment on EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

log "🚀 Starting Lavangam Backend Complete EC2 Setup..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as ubuntu user."
fi

# Step 1: Update system
log "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install system dependencies
log "🔧 Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    mysql-server \
    mysql-client \
    curl \
    wget \
    git \
    unzip \
    htop \
    ufw \
    apache2 \
    libapache2-mod-php \
    php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip

# Step 3: Install Node.js
log "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Step 4: Setup MySQL
log "🗄️ Setting up MySQL database..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure MySQL installation (non-interactive)
log "🔒 Securing MySQL installation..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'thanuja';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Create database and user
log "📊 Creating database and user..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS toolinfomation;"
sudo mysql -e "GRANT ALL PRIVILEGES ON toolinfomation.* TO 'root'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Step 5: Install and configure phpMyAdmin
log "🔧 Installing and configuring phpMyAdmin..."
sudo apt install -y phpmyadmin

# Configure phpMyAdmin for Apache
echo "Include /etc/phpmyadmin/apache.conf" | sudo tee -a /etc/apache2/apache2.conf

# Create phpMyAdmin configuration
sudo tee /etc/phpmyadmin/config.inc.php > /dev/null << 'EOF'
<?php
declare(strict_types=1);

$cfg['blowfish_secret'] = 'lavangam-secret-key-2024';

$i = 0;
$i++;

$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['Servers'][$i]['port'] = '3306';
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = 'thanuja';

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';
$cfg['PmaAbsoluteUri'] = '/phpmyadmin/';
EOF

# Restart Apache
sudo systemctl restart apache2

# Step 6: Create application directory
log "📁 Setting up application directory..."
sudo mkdir -p /opt/lavangam
sudo chown ubuntu:ubuntu /opt/lavangam
cd /opt/lavangam

# Step 7: Setup Python virtual environment
log "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Step 8: Install Python dependencies
log "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install fastapi uvicorn[standard] flask flask-cors flask-socketio requests mysql-connector-python PyMySQL pandas python-dotenv selenium openpyxl xlsxwriter psutil websockets python-multipart jinja2 pydantic python-jose[cryptography] passlib[bcrypt] bcrypt cryptography setuptools gunicorn supervisor

# Step 9: Create systemd service for backend
log "🔧 Creating systemd service for backend..."
sudo tee /etc/systemd/system/lavangam-backend.service > /dev/null << 'EOF'
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Step 10: Configure Nginx
log "🌐 Configuring Nginx..."
sudo tee /etc/nginx/sites-available/lavangam > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # phpMyAdmin
    location /phpmyadmin/ {
        proxy_pass http://127.0.0.1/phpmyadmin/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Root redirect to backend
    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable site and restart Nginx
sudo ln -sf /etc/nginx/sites-available/lavangam /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Step 11: Configure firewall
log "🔥 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8000
sudo ufw allow 8080
sudo ufw allow 3306

# Step 12: Create startup script
log "🚀 Creating startup script..."
tee /opt/lavangam/startup.sh > /dev/null << 'EOF'
#!/bin/bash
cd /opt/lavangam
source venv/bin/activate

# Start MySQL
sudo systemctl start mysql

# Start Nginx
sudo systemctl start nginx

# Start Backend
sudo systemctl start lavangam-backend

echo "All services started successfully!"
EOF

chmod +x /opt/lavangam/startup.sh

# Step 13: Add to crontab for auto-startup
log "⏰ Setting up auto-startup..."
(crontab -l 2>/dev/null; echo "@reboot /opt/lavangam/startup.sh") | crontab -

# Step 14: Create environment file
log "📝 Creating environment file..."
tee /opt/lavangam/.env > /dev/null << 'EOF'
DB_HOST=localhost
DB_PORT=3306
DB_NAME=toolinfomation
DB_USER=root
DB_PASSWORD=thanuja
DATABASE_URL=mysql+pymysql://root:thanuja@localhost:3306/toolinfomation
EOF

# Step 15: Create database setup script
log "🗄️ Creating database setup script..."
tee /opt/lavangam/setup_database.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

def setup_database():
    try:
        # Connect to MySQL
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
        
        # Create basic tables (you can modify these based on your needs)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                username VARCHAR(255) NOT NULL UNIQUE,
                email VARCHAR(255) NOT NULL UNIQUE,
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
        if connection:
            connection.close()

if __name__ == "__main__":
    setup_database()
EOF

chmod +x /opt/lavangam/setup_database.py

# Step 16: Enable and start services
log "🔧 Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable lavangam-backend
sudo systemctl enable nginx
sudo systemctl enable mysql

# Start services
sudo systemctl start mysql
sudo systemctl start nginx
sudo systemctl start lavangam-backend

# Step 17: Setup database
log "🗄️ Setting up database..."
cd /opt/lavangam
source venv/bin/activate
python setup_database.py

# Step 18: Create status check script
log "📊 Creating status check script..."
tee /opt/lavangam/check_status.sh > /dev/null << 'EOF'
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
echo "=== Port Status ==="
echo "Port 80 (HTTP):"
sudo netstat -tlnp | grep :80
echo "Port 8000 (Backend):"
sudo netstat -tlnp | grep :8000
echo "Port 3306 (MySQL):"
sudo netstat -tlnp | grep :3306
EOF

chmod +x /opt/lavangam/check_status.sh

# Step 19: Final status check
log "🔍 Checking final status..."
sleep 5

# Check if services are running
if sudo systemctl is-active --quiet mysql; then
    log "✅ MySQL is running"
else
    warn "⚠️ MySQL is not running"
fi

if sudo systemctl is-active --quiet nginx; then
    log "✅ Nginx is running"
else
    warn "⚠️ Nginx is not running"
fi

if sudo systemctl is-active --quiet lavangam-backend; then
    log "✅ Backend service is running"
else
    warn "⚠️ Backend service is not running"
fi

# Step 20: Display access information
log "🎉 Setup completed successfully!"
echo ""
echo "=== Access Information ==="
echo "Backend API: http://$(curl -s ifconfig.me):8000"
echo "phpMyAdmin: http://$(curl -s ifconfig.me)/phpmyadmin/"
echo "Nginx: http://$(curl -s ifconfig.me)"
echo ""
echo "=== Database Credentials ==="
echo "Username: root"
echo "Password: thanuja"
echo "Database: toolinfomation"
echo ""
echo "=== Useful Commands ==="
echo "Check status: /opt/lavangam/check_status.sh"
echo "View logs: sudo journalctl -u lavangam-backend -f"
echo "Restart backend: sudo systemctl restart lavangam-backend"
echo "Restart nginx: sudo systemctl restart nginx"
echo "Restart mysql: sudo systemctl restart mysql"
echo ""
echo "=== Auto-startup ==="
echo "The backend will automatically start on system reboot"
echo "All services are configured to start automatically"
