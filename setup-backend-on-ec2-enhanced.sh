#!/bin/bash

# =============================================================================
# LAVANGAM BACKEND COMPLETE SETUP SCRIPT FOR EC2 - ENHANCED VERSION
# This script will install and configure ALL backend services on your EC2 instance
# Including all the specific ports you need: 8000, 5022, 5024, 8004, 5025, 8001, 8002, 5020, 5021, 5023, 5001, 5002, 5005
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Configuration
MYSQL_ROOT_PASSWORD="Lavangam2024!"
MYSQL_DB_NAME="lavangam_db"
MYSQL_USER="lavangam_user"
MYSQL_PASSWORD="Lavangam2024!"
BACKEND_DIR="/home/ubuntu/lavangam-backend"
SERVICES_DIR="/etc/systemd/system"

log "🚀 Starting LAVANGAM Backend Complete Setup on EC2 (Enhanced Version)..."

# =============================================================================
# STEP 1: Update System and Install Dependencies
# =============================================================================
log "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

log "📦 Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libssl-dev \
    libffi-dev \
    git \
    curl \
    wget \
    unzip \
    nginx \
    mysql-server \
    php \
    php-mysql \
    php-common \
    php-mbstring \
    php-xml \
    php-curl \
    php-gd \
    php-zip \
    php-fpm \
    supervisor \
    htop \
    tree \
    net-tools \
    ufw \
    certbot \
    python3-certbot-nginx

# =============================================================================
# STEP 2: Configure MySQL
# =============================================================================
log "🗄️ Configuring MySQL..."

# Secure MySQL installation
sudo mysql_secure_installation <<EOF

y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

# Create database and user
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB_NAME.* TO '$MYSQL_USER'@'localhost';
GRANT ALL PRIVILEGES ON $MYSQL_DB_NAME.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

# Configure MySQL to accept connections from all interfaces
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

log "✅ MySQL configured successfully"

# =============================================================================
# STEP 3: Configure Firewall - ALL YOUR PORTS
# =============================================================================
log "🔥 Configuring firewall for ALL your backend ports..."

sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Allow ALL your backend service ports
sudo ufw allow 8000  # Main API
sudo ufw allow 5022  # Scrapers API
sudo ufw allow 5024  # System Usage API
sudo ufw allow 8004  # Dashboard API
sudo ufw allow 5025  # Admin Metrics API
sudo ufw allow 8001  # Analytics API
sudo ufw allow 8002  # Additional Analytics
sudo ufw allow 5020  # E-Procurement WebSocket
sudo ufw allow 5021  # E-Procurement Server
sudo ufw allow 5023  # E-Procurement Fixed
sudo ufw allow 5001  # File Manager
sudo ufw allow 5002  # Export Server
sudo ufw allow 5005  # E-Procurement API

# Allow MySQL
sudo ufw allow 3306

log "✅ Firewall configured for ALL your ports"

# =============================================================================
# STEP 4: Setup Backend Directory
# =============================================================================
log "📁 Setting up backend directory..."

# Create backend directory
sudo mkdir -p $BACKEND_DIR
sudo chown ubuntu:ubuntu $BACKEND_DIR

cd $BACKEND_DIR

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    flask==3.0.0 \
    flask-cors==4.0.0 \
    flask-socketio==5.3.6 \
    requests==2.31.0 \
    mysql-connector-python==8.2.0 \
    PyMySQL==1.1.0 \
    pandas==2.1.4 \
    python-dotenv==1.0.0 \
    selenium==4.15.2 \
    openpyxl==3.1.2 \
    xlsxwriter==3.1.9 \
    psutil==5.9.6 \
    websockets==12.0 \
    python-multipart==0.0.6 \
    jinja2==3.1.2 \
    pydantic==2.5.0 \
    python-jose[cryptography]==3.3.0 \
    passlib[bcrypt]==1.7.4 \
    bcrypt==4.1.2 \
    cryptography==41.0.8 \
    setuptools==69.0.3

# =============================================================================
# STEP 5: Create Environment Configuration
# =============================================================================
log "⚙️ Creating environment configuration for ALL your ports..."

cat > $BACKEND_DIR/.env <<EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=$MYSQL_DB_NAME
DB_USER=$MYSQL_USER
DB_PASSWORD=$MYSQL_PASSWORD
DB_URL=mysql+pymysql://$MYSQL_USER:$MYSQL_PASSWORD@localhost:3306/$MYSQL_DB_NAME

# ALL Your Service Ports
MAIN_API_PORT=8000
SCRAPERS_API_PORT=5022
SYSTEM_USAGE_PORT=5024
DASHBOARD_API_PORT=8004
ADMIN_METRICS_PORT=5025
ANALYTICS_API_PORT=8001
ANALYTICS_ADDITIONAL_PORT=8002
EPROC_WS_PORT=5020
EPROC_SERVER_PORT=5021
EPROC_FIXED_PORT=5023
FILE_MANAGER_PORT=5001
EXPORT_SERVER_PORT=5002
EPROC_API_PORT=5005

# Environment
ENVIRONMENT=production
DEBUG=false
EOF

# =============================================================================
# STEP 6: Create Enhanced Main Application Entry Point
# =============================================================================
log "📝 Creating enhanced main application entry point for ALL your services..."

cat > $BACKEND_DIR/main_app.py <<'EOF'
#!/usr/bin/env python3
"""
Enhanced Main Application Entry Point for LAVANGAM Backend
Starts ALL your services with proper port management
"""

import os
import sys
import time
import threading
import subprocess
from datetime import datetime
import signal
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# ALL Your Service configurations
SERVICES = [
    {
        "name": "Main API",
        "command": ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"],
        "port": 8000,
        "description": "Main FastAPI application with all routers"
    },
    {
        "name": "Scrapers API",
        "command": ["python", "-m", "uvicorn", "scrapers.api:app", "--host", "0.0.0.0", "--port", "5022"],
        "port": 5022,
        "description": "Scraping tools and WebSocket endpoints"
    },
    {
        "name": "System Usage API",
        "command": ["python", "-m", "uvicorn", "system_usage_api:app", "--host", "0.0.0.0", "--port", "5024"],
        "port": 5024,
        "description": "System monitoring and metrics"
    },
    {
        "name": "Dashboard API",
        "command": ["python", "-m", "uvicorn", "dashboard_api:app", "--host", "0.0.0.0", "--port", "8004"],
        "port": 8004,
        "description": "Dashboard metrics and analytics"
    },
    {
        "name": "Admin Metrics API",
        "command": ["python", "-m", "uvicorn", "admin_metrics_api:app", "--host", "0.0.0.0", "--port", "5025"],
        "port": 5025,
        "description": "Admin dashboard metrics"
    },
    {
        "name": "Analytics API",
        "command": ["python", "-m", "uvicorn", "analytics_api:app", "--host", "0.0.0.0", "--port", "8001"],
        "port": 8001,
        "description": "Analytics and reporting API"
    },
    {
        "name": "Additional Analytics API",
        "command": ["python", "-m", "uvicorn", "analytics_additional:app", "--host", "0.0.0.0", "--port", "8002"],
        "port": 8002,
        "description": "Additional analytics endpoints"
    },
    {
        "name": "E-Procurement WebSocket",
        "command": ["python", "eproc_websocket.py"],
        "port": 5020,
        "description": "E-Procurement WebSocket server"
    },
    {
        "name": "E-Procurement Server",
        "command": ["python", "eproc_server.py"],
        "port": 5021,
        "description": "E-Procurement main server"
    },
    {
        "name": "E-Procurement Fixed",
        "command": ["python", "eproc_fixed.py"],
        "port": 5023,
        "description": "E-Procurement fixed version"
    },
    {
        "name": "File Manager",
        "command": ["python", "file_manager.py"],
        "port": 5001,
        "description": "File management service"
    },
    {
        "name": "Export Server",
        "command": ["python", "export_server.py"],
        "port": 5002,
        "description": "Data export service"
    },
    {
        "name": "E-Procurement API",
        "command": ["python", "eproc_api.py"],
        "port": 5005,
        "description": "E-Procurement API endpoints"
    }
]

running_processes = {}
stop_event = threading.Event()

def log(message, level="INFO"):
    """Log messages with timestamp"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}", flush=True)

def start_service(service_config):
    """Start a single service in background"""
    name = service_config["name"]
    command = service_config["command"]
    port = service_config.get("port", "N/A")
    
    try:
        log(f"Starting {name} on port {port}...")
        
        # Start the process
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=os.path.dirname(os.path.abspath(__file__))
        )
        
        running_processes[name] = {
            "process": process,
            "config": service_config,
            "start_time": datetime.now()
        }
        
        log(f"✅ {name} started successfully (PID: {process.pid})")
        return True
        
    except Exception as e:
        log(f"❌ Failed to start {name}: {e}", "ERROR")
        return False

def start_all_services():
    """Start ALL your services in background threads"""
    log("🚀 Starting ALL LAVANGAM backend services...")
    
    for service in SERVICES:
        thread = threading.Thread(target=start_service, args=(service,))
        thread.daemon = True
        thread.start()
        time.sleep(2)  # Small delay between service starts
    
    log("✅ All services started. Monitoring...")
    
    # Monitor services
    while not stop_event.is_set():
        time.sleep(30)
        for name, service_info in running_processes.items():
            process = service_info["process"]
            if process.poll() is not None:
                log(f"⚠️ Service {name} has stopped. Restarting...", "WARNING")
                # Restart the service
                start_service(service_info["config"])

def stop_all_services():
    """Stop all running services"""
    log("🛑 Stopping all services...")
    stop_event.set()
    
    for name, service_info in running_processes.items():
        process = service_info["process"]
        try:
            process.terminate()
            process.wait(timeout=10)
            log(f"✅ {name} stopped")
        except subprocess.TimeoutExpired:
            process.kill()
            log(f"⚠️ {name} force killed")
        except Exception as e:
            log(f"❌ Error stopping {name}: {e}", "ERROR")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    log("🛑 Received shutdown signal. Cleaning up...")
    stop_all_services()
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

if __name__ == "__main__":
    try:
        start_all_services()
    except KeyboardInterrupt:
        log("🛑 Keyboard interrupt received")
        stop_all_services()
EOF

# =============================================================================
# STEP 7: Create Systemd Services
# =============================================================================
log "🔧 Creating systemd services for ALL your backend services..."

# Main backend service
cat > $SERVICES_DIR/lavangam-backend.service <<EOF
[Unit]
Description=LAVANGAM Backend Services (ALL PORTS)
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=$BACKEND_DIR
Environment=PATH=$BACKEND_DIR/venv/bin
ExecStart=$BACKEND_DIR/venv/bin/python main_app.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# MySQL service (ensure it's enabled)
sudo systemctl enable mysql

# =============================================================================
# STEP 8: Configure Nginx for ALL Your Ports
# =============================================================================
log "🌐 Configuring Nginx for ALL your backend ports..."

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/lavangam-backend <<EOF
server {
    listen 80;
    server_name _;
    
    # Main API (Port 8000)
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Scrapers API (Port 5022)
    location /scrapers/ {
        proxy_pass http://localhost:5022;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # System Usage API (Port 5024)
    location /system/ {
        proxy_pass http://localhost:5024;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Dashboard API (Port 8004)
    location /dashboard/ {
        proxy_pass http://localhost:8004;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Admin Metrics API (Port 5025)
    location /admin/ {
        proxy_pass http://localhost:5025;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Analytics API (Port 8001)
    location /analytics/ {
        proxy_pass http://localhost:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Additional Analytics (Port 8002)
    location /analytics2/ {
        proxy_pass http://localhost:8002;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # E-Procurement Server (Port 5021)
    location /eproc/ {
        proxy_pass http://localhost:5021;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # File Manager (Port 5001)
    location /files/ {
        proxy_pass http://localhost:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Export Server (Port 5002)
    location /export/ {
        proxy_pass http://localhost:5002;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # E-Procurement API (Port 5005)
    location /eproc-api/ {
        proxy_pass http://localhost:5005;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8000/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Root redirect
    location / {
        return 301 /health;
    }
}

# WebSocket support for E-Procurement (Port 5020)
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name _;
    
    location /ws/ {
        proxy_pass http://localhost:5020;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/lavangam-backend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# =============================================================================
# STEP 9: Create Service Health Checker
# =============================================================================
log "🔍 Creating service health checker for ALL your ports..."

cat > $BACKEND_DIR/check_services.py <<'EOF'
#!/usr/bin/env python3
"""
Enhanced Service Health Checker for LAVANGAM Backend
Checks ALL your services on their specific ports
"""

import requests
import time
from datetime import datetime

# ALL Your Services with their ports
SERVICES = [
    {"name": "Main API", "url": "http://localhost:8000/health", "port": 8000},
    {"name": "Scrapers API", "url": "http://localhost:5022/health", "port": 5022},
    {"name": "System Usage API", "url": "http://localhost:5024/health", "port": 5024},
    {"name": "Dashboard API", "url": "http://localhost:8004/health", "port": 8004},
    {"name": "Admin Metrics API", "url": "http://localhost:5025/health", "port": 5025},
    {"name": "Analytics API", "url": "http://localhost:8001/health", "port": 8001},
    {"name": "Additional Analytics", "url": "http://localhost:8002/health", "port": 8002},
    {"name": "E-Procurement WebSocket", "url": "http://localhost:5020/", "port": 5020},
    {"name": "E-Procurement Server", "url": "http://localhost:5021/health", "port": 5021},
    {"name": "E-Procurement Fixed", "url": "http://localhost:5023/health", "port": 5023},
    {"name": "File Manager", "url": "http://localhost:5001/health", "port": 5001},
    {"name": "Export Server", "url": "http://localhost:5002/health", "port": 5002},
    {"name": "E-Procurement API", "url": "http://localhost:5005/health", "port": 5005},
]

def check_service(service):
    try:
        response = requests.get(service["url"], timeout=5)
        if response.status_code == 200:
            return True, "✅ OK"
        else:
            return False, f"❌ HTTP {response.status_code}"
    except requests.exceptions.RequestException as e:
        return False, f"❌ Error: {str(e)}"

def main():
    print(f"🔍 LAVANGAM Backend Service Health Check - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    
    all_healthy = True
    
    for service in SERVICES:
        healthy, status = check_service(service)
        if not healthy:
            all_healthy = False
        
        print(f"{service['name']:<30} (Port {service['port']:<4}) {status}")
    
    print("=" * 80)
    
    if all_healthy:
        print("🎉 All services are healthy!")
    else:
        print("⚠️ Some services are not responding")
    
    return 0 if all_healthy else 1

if __name__ == "__main__":
    exit(main())
EOF

chmod +x $BACKEND_DIR/check_services.py

# =============================================================================
# STEP 10: Final Configuration and Startup
# =============================================================================
log "🔧 Final configuration and startup..."

# Set proper permissions
sudo chown -R ubuntu:ubuntu $BACKEND_DIR
sudo chmod -R 755 $BACKEND_DIR

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable lavangam-backend

# Start services
sudo systemctl start lavangam-backend
sudo systemctl restart nginx
sudo systemctl restart mysql

# Wait a moment for services to start
sleep 15

# =============================================================================
# STEP 11: Verification and Status
# =============================================================================
log "🔍 Verifying installation of ALL your services..."

# Check service status
echo "📊 Service Status:"
sudo systemctl status lavangam-backend --no-pager -l
echo ""

# Check Nginx status
echo "🌐 Nginx Status:"
sudo systemctl status nginx --no-pager -l
echo ""

# Check MySQL status
echo "🗄️ MySQL Status:"
sudo systemctl status mysql --no-pager -l
echo ""

# Check ALL your open ports
echo "🔌 ALL Your Open Ports:"
sudo netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|8001|8002|5020|5021|5023|5001|5002|5005|3306|80|443)'
echo ""

# =============================================================================
# STEP 12: Installation Complete
# =============================================================================
log "🎉 LAVANGAM Backend Setup Complete with ALL your ports!"
echo ""
echo "=============================================================================="
echo "🚀 LAVANGAM BACKEND SUCCESSFULLY DEPLOYED ON EC2 WITH ALL YOUR PORTS!"
echo "=============================================================================="
echo ""
echo "📍 Instance Details:"
echo "   • Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   • Backend Directory: $BACKEND_DIR"
echo ""
echo "🔌 ALL Your Service Ports:"
echo "   • Main API: 8000"
echo "   • Scrapers API: 5022"
echo "   • System Usage API: 5024"
echo "   • Dashboard API: 8004"
echo "   • Admin Metrics API: 5025"
echo "   • Analytics API: 8001"
echo "   • Additional Analytics: 8002"
echo "   • E-Procurement WebSocket: 5020"
echo "   • E-Procurement Server: 5021"
echo "   • E-Procurement Fixed: 5023"
echo "   • File Manager: 5001"
echo "   • Export Server: 5002"
echo "   • E-Procurement API: 5005"
echo "   • MySQL: 3306"
echo "   • HTTP: 80"
echo ""
echo "🌐 Access URLs:"
echo "   • Backend Health: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health"
echo "   • Main API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api/"
echo "   • Scrapers API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/scrapers/"
echo "   • Dashboard API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/dashboard/"
echo ""
echo "🔧 Management Commands:"
echo "   • Check all services: $BACKEND_DIR/check_services.py"
echo "   • View logs: sudo journalctl -u lavangam-backend -f"
echo "   • Restart services: sudo systemctl restart lavangam-backend"
echo ""
echo "📋 Next Steps:"
echo "   1. Upload your backend code to: $BACKEND_DIR"
echo "   2. Update .env file if needed"
echo "   3. Restart services: sudo systemctl restart lavangam-backend"
echo "   4. Test all endpoints"
echo ""
echo "🔐 Default Credentials:"
echo "   • MySQL Root: root / $MYSQL_ROOT_PASSWORD"
echo "   • MySQL User: $MYSQL_USER / $MYSQL_PASSWORD"
echo "   • Database: $MYSQL_DB_NAME"
echo ""
echo "=============================================================================="
echo "✅ Setup completed successfully at $(date)"
echo "=============================================================================="

# Create a summary file
cat > $BACKEND_DIR/SETUP_SUMMARY.txt <<EOF
LAVANGAM Backend Setup Summary - ALL PORTS
==========================================

Setup completed: $(date)
Instance IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

Services Installed:
- MySQL Database (Port 3306)
- Nginx Web Server (Port 80)
- Python Backend Services
- Systemd Services

ALL Your Service Ports:
- Main API: 8000
- Scrapers API: 5022
- System Usage API: 5024
- Dashboard API: 8004
- Admin Metrics API: 5025
- Analytics API: 8001
- Additional Analytics: 8002
- E-Procurement WebSocket: 5020
- E-Procurement Server: 5021
- E-Procurement Fixed: 5023
- File Manager: 5001
- Export Server: 5002
- E-Procurement API: 5005

Database:
- Name: $MYSQL_DB_NAME
- User: $MYSQL_USER
- Password: $MYSQL_PASSWORD

Management:
- Health Check: $BACKEND_DIR/check_services.py
- View Logs: sudo journalctl -u lavangam-backend -f
- Restart: sudo systemctl restart lavangam-backend

Next Steps:
1. Upload your backend code
2. Update .env file if needed
3. Restart services
4. Test all endpoints
EOF

log "📋 Setup summary saved to $BACKEND_DIR/SETUP_SUMMARY.txt"
log "🎯 Your LAVANGAM backend is now ready on EC2 with ALL your ports!"
