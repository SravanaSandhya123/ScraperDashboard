#!/bin/bash

# Lavangam Backend AWS EC2 Deployment Script with Screen
# This script automates the deployment of all Lavangam backend services to AWS EC2
# Uses screen to run all services in the background on different ports

set -e  # Exit on any error

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as ubuntu user."
fi

log "🚀 Starting Lavangam Backend AWS EC2 Deployment with Screen..."

# Step 1: Update system
log "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install system dependencies including screen
log "🔧 Installing system dependencies including screen..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    mysql-server \
    mysql-client \
    chromium-browser \
    chromium-chromedriver \
    curl \
    wget \
    git \
    unzip \
    htop \
    ufw \
    screen

log "✅ Screen installed successfully - will be used to run all services in background"

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
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Lavangam@2024';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DROP DATABASE IF EXISTS test;"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Create database and user
log "📊 Creating database and user..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS toolinformation;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'lavangam'@'localhost' IDENTIFIED BY 'Lavangam@2024';"
sudo mysql -e "GRANT ALL PRIVILEGES ON toolinformation.* TO 'lavangam'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Step 5: Create application directory
log "📁 Setting up application directory..."
sudo mkdir -p /opt/lavangam
sudo chown ubuntu:ubuntu /opt/lavangam
cd /opt/lavangam

# Step 6: Setup Python virtual environment
log "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Step 7: Install Python dependencies
log "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn supervisor

# Step 8: Create environment file
log "🔧 Creating environment configuration..."
cat > .env << EOF
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_NAME=toolinformation
DB_USER=lavangam
DB_PASSWORD=Lavangam@2024

# API Keys (update these with your actual keys)
GROQ_API_KEY=your_groq_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# Supabase Configuration
SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqZmphZXp6dGZ5ZGlyeXpzeXZkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTAyNzAyMSwiZXhwIjoyMDY2NjAzMDIxfQ.sRbGz6wbBoMmY8Ol3vEPc4VOh2oEWpcONi9DkUsTpKk

# Service Ports
MAIN_PORT=8000
FILE_MANAGER_PORT=5002
EPROC_SERVER_PORT=5023
SYSTEM_USAGE_PORT=5024
DASHBOARD_API_PORT=8004
SCRAPERS_API_PORT=5022
ANALYTICS_API_PORT=8001
ADDITIONAL_ANALYTICS_PORT=8002
EPROC_WEBSOCKET_PORT=5020
EPROC_API_PORT=5021
EOF

log "✅ Environment file created"

# Step 9: Create screen configuration file
log "🔧 Creating screen configuration for all services..."
cat > screen_config.conf << EOF
# Screen configuration for Lavangam services
# Each service runs in its own screen session

# Main Backend (Port 8000)
screen -t "main-backend" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python render_consolidated.py"

# File Manager (Port 5002)
screen -t "file-manager" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from file_manager import app; uvicorn.run(app, host='0.0.0.0', port=5002)\""

# E-Procurement Server (Port 5023)
screen -t "eproc-server" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from eproc_server_fixed import app; uvicorn.run(app, host='0.0.0.0', port=5023)\""

# System Usage API (Port 5024)
screen -t "system-usage" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from system_usage_api import app; uvicorn.run(app, host='0.0.0.0', port=5024)\""

# Dashboard API (Port 8004)
screen -t "dashboard-api" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from dashboard_api import app; uvicorn.run(app, host='0.0.0.0', port=8004)\""

# Scrapers API (Port 5022)
screen -t "scrapers-api" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from api import app; uvicorn.run(app, host='0.0.0.0', port=5022)\""

# Analytics API (Port 8001)
screen -t "analytics-api" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from analytics_api import app; uvicorn.run(app, host='0.0.0.0', port=8001)\""

# Additional Analytics (Port 8002)
screen -t "additional-analytics" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from analytics_api import app; uvicorn.run(app, host='0.0.0.0', port=8002)\""

# E-Procurement WebSocket (Port 5020)
screen -t "eproc-websocket" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from eproc_server_fixed import app; uvicorn.run(app, host='0.0.0.0', port=5020)\""

# E-Procurement API (Port 5021)
screen -t "eproc-api" -dm bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from eproc_server_fixed import app; uvicorn.run(app, host='0.0.0.0', port=5021)\""
EOF

log "✅ Screen configuration created"

# Step 10: Create service management scripts
log "🔧 Creating service management scripts..."

# Start all services script
cat > start_all_services.sh << 'EOF'
#!/bin/bash
# Start all Lavangam services using screen

echo "🚀 Starting all Lavangam services..."

# Kill any existing screen sessions
screen -ls | grep -E "lavangam|main-backend|file-manager|eproc-server|system-usage|dashboard-api|scrapers-api|analytics-api|additional-analytics|eproc-websocket|eproc-api" | cut -d. -f1 | xargs -r kill

# Wait a moment for cleanup
sleep 2

# Start main consolidated backend
echo "📡 Starting Main Backend (Port 8000)..."
screen -dmS main-backend bash -c "cd /opt/lavangam && source venv/bin/activate && python render_consolidated.py"

# Start individual services
echo "📁 Starting File Manager (Port 5002)..."
screen -dmS file-manager bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from file_manager import app; uvicorn.run(app, host='0.0.0.0', port=5002)\""

echo "🛒 Starting E-Procurement Server (Port 5023)..."
screen -dmS eproc-server bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from eproc_server_fixed import app; uvicorn.run(app, host='0.0.0.0', port=5023)\""

echo "📊 Starting System Usage API (Port 5024)..."
screen -dmS system-usage bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from system_usage_api import app; uvicorn.run(app, host='0.0.0.0', port=5024)\""

echo "📈 Starting Dashboard API (Port 8004)..."
screen -dmS dashboard-api bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from dashboard_api import app; uvicorn.run(app, host='0.0.0.0', port=8004)\""

echo "🕷️ Starting Scrapers API (Port 5022)..."
screen -dmS scrapers-api bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from api import app; uvicorn.run(app, host='0.0.0.0', port=5022)\""

echo "📊 Starting Analytics API (Port 8001)..."
screen -dmS analytics-api bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from analytics_api import app; uvicorn.run(app, host='0.0.0.0', port=8001)\""

echo "📊 Starting Additional Analytics (Port 8002)..."
screen -dmS additional-analytics bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from analytics_api import app; uvicorn.run(app, host='0.0.0.0', port=8002)\""

echo "🔌 Starting E-Procurement WebSocket (Port 5020)..."
screen -dmS eproc-websocket bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from eproc_server_fixed import app; uvicorn.run(app, host='0.0.0.0', port=5020)\""

echo "🔌 Starting E-Procurement API (Port 5021)..."
screen -dmS eproc-api bash -c "cd /opt/lavangam && source venv/bin/activate && python -c \"import uvicorn; from eproc_server_fixed import app; uvicorn.run(app, host='0.0.0.0', port=5021)\""

# Wait for services to start
sleep 5

echo "✅ All services started! Check status with: screen -ls"
echo "🌐 Services running on ports: 8000, 5002, 5023, 5024, 8004, 5022, 8001, 8002, 5020, 5021"
EOF

# Stop all services script
cat > stop_all_services.sh << 'EOF'
#!/bin/bash
# Stop all Lavangam services

echo "🛑 Stopping all Lavangam services..."

# Kill all screen sessions
screen -ls | grep -E "lavangam|main-backend|file-manager|eproc-server|system-usage|dashboard-api|scrapers-api|analytics-api|additional-analytics|eproc-websocket|eproc-api" | cut -d. -f1 | xargs -r kill

echo "✅ All services stopped!"
EOF

# Check services status script
cat > check_services.sh << 'EOF'
#!/bin/bash
# Check status of all Lavangam services

echo "🔍 Checking Lavangam services status..."
echo "=================================="

# Check screen sessions
echo "📺 Screen Sessions:"
screen -ls | grep -E "lavangam|main-backend|file-manager|eproc-server|system-usage|dashboard-api|scrapers-api|analytics-api|additional-analytics|eproc-websocket|eproc-api" || echo "No services running"

echo ""
echo "🌐 Port Status:"
echo "Port 8000 (Main Backend): $(netstat -tlnp 2>/dev/null | grep :8000 || echo 'Not listening')"
echo "Port 5002 (File Manager): $(netstat -tlnp 2>/dev/null | grep :5002 || echo 'Not listening')"
echo "Port 5023 (E-Proc Server): $(netstat -tlnp 2>/dev/null | grep :5023 || echo 'Not listening')"
echo "Port 5024 (System Usage): $(netstat -tlnp 2>/dev/null | grep :5024 || echo 'Not listening')"
echo "Port 8004 (Dashboard API): $(netstat -tlnp 2>/dev/null | grep :8004 || echo 'Not listening')"
echo "Port 5022 (Scrapers API): $(netstat -tlnp 2>/dev/null | grep :5022 || echo 'Not listening')"
echo "Port 8001 (Analytics API): $(netstat -tlnp 2>/dev/null | grep :8001 || echo 'Not listening')"
echo "Port 8002 (Add Analytics): $(netstat -tlnp 2>/dev/null | grep :8002 || echo 'Not listening')"
echo "Port 5020 (E-Proc WS): $(netstat -tlnp 2>/dev/null | grep :5020 || echo 'Not listening')"
echo "Port 5021 (E-Proc API): $(netstat -tlnp 2>/dev/null | grep :5021 || echo 'Not listening')"

echo ""
echo "💾 Memory Usage:"
free -h

echo ""
echo "🖥️ CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print "CPU Usage: " $1 "%"}'
EOF

# Make scripts executable
chmod +x start_all_services.sh stop_all_services.sh check_services.sh

log "✅ Service management scripts created"

# Step 11: Setup Nginx reverse proxy
log "🌐 Setting up Nginx reverse proxy..."
sudo tee /etc/nginx/sites-available/lavangam << EOF
server {
    listen 80;
    server_name _;

    # Main Backend (Port 8000)
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # File Manager (Port 5002)
    location /file-manager/ {
        proxy_pass http://localhost:5002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # E-Procurement Server (Port 5023)
    location /eproc/ {
        proxy_pass http://localhost:5023/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # System Usage (Port 5024)
    location /system/ {
        proxy_pass http://localhost:5024/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Dashboard API (Port 8004)
    location /dashboard/ {
        proxy_pass http://localhost:8004/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Scrapers API (Port 5022)
    location /scrapers/ {
        proxy_pass http://localhost:5022/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Analytics API (Port 8001)
    location /analytics/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Additional Analytics (Port 8002)
    location /analytics-additional/ {
        proxy_pass http://localhost:8002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # E-Procurement WebSocket (Port 5020)
    location /eproc-ws/ {
        proxy_pass http://localhost:5020/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # E-Procurement API (Port 5021)
    location /eproc-api/ {
        proxy_pass http://localhost:5021/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/lavangam /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

log "✅ Nginx reverse proxy configured"

# Step 12: Setup firewall
log "🔥 Setting up firewall..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8000/tcp  # Main Backend
sudo ufw allow 5002/tcp  # File Manager
sudo ufw allow 5023/tcp  # E-Proc Server
sudo ufw allow 5024/tcp  # System Usage
sudo ufw allow 8004/tcp  # Dashboard API
sudo ufw allow 5022/tcp  # Scrapers API
sudo ufw allow 8001/tcp  # Analytics API
sudo ufw allow 8002/tcp  # Additional Analytics
sudo ufw allow 5020/tcp  # E-Proc WebSocket
sudo ufw allow 5021/tcp  # E-Proc API

sudo ufw --force enable
log "✅ Firewall configured"

# Step 13: Create systemd service for auto-start
log "🔧 Creating systemd service for auto-start..."
sudo tee /etc/systemd/system/lavangam.service << EOF
[Unit]
Description=Lavangam Backend Services
After=network.target mysql.service

[Service]
Type=forking
User=ubuntu
WorkingDirectory=/opt/lavangam
ExecStart=/opt/lavangam/start_all_services.sh
ExecStop=/opt/lavangam/stop_all_services.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable lavangam.service

log "✅ Systemd service created and enabled"

# Step 14: Create monitoring script
log "🔧 Creating monitoring script..."
cat > monitor_services.sh << 'EOF'
#!/bin/bash
# Monitor all Lavangam services

echo "🔍 Lavangam Services Monitor"
echo "============================"
echo ""

# Check screen sessions
echo "📺 Active Screen Sessions:"
screen -ls | grep -E "lavangam|main-backend|file-manager|eproc-server|system-usage|dashboard-api|scrapers-api|analytics-api|additional-analytics|eproc-websocket|eproc-api" || echo "No services running"

echo ""
echo "🌐 Port Status:"
ports=(8000 5002 5023 5024 8004 5022 8001 8002 5020 5021)
services=("Main Backend" "File Manager" "E-Proc Server" "System Usage" "Dashboard API" "Scrapers API" "Analytics API" "Additional Analytics" "E-Proc WebSocket" "E-Proc API")

for i in "${!ports[@]}"; do
    port=${ports[$i]}
    service=${services[$i]}
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        echo "✅ Port $port ($service): LISTENING"
    else
        echo "❌ Port $port ($service): NOT LISTENING"
    fi
done

echo ""
echo "💾 System Resources:"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2 " (" $3/$2*100.0 "%)"}')"
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1 "%"}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

echo ""
echo "📊 Process Count:"
echo "Python processes: $(pgrep -c python3)"
echo "Screen sessions: $(screen -ls | grep -c "lavangam\|main-backend\|file-manager\|eproc-server\|system-usage\|dashboard-api\|scrapers-api\|analytics-api\|additional-analytics\|eproc-websocket\|eproc-api")"
EOF

chmod +x monitor_services.sh

log "✅ Monitoring script created"

# Step 15: Final setup and start services
log "🚀 Final setup and starting services..."

# Start all services
./start_all_services.sh

# Wait for services to start
sleep 10

# Check status
./check_services.sh

log "🎉 Deployment completed successfully!"
log ""
log "📋 Next steps:"
log "1. Update your .env file with actual API keys"
log "2. Test your services: curl http://your-ec2-ip/"
log "3. Monitor services: ./monitor_services.sh"
log "4. View logs: screen -r [session-name]"
log "5. Stop services: ./stop_all_services.sh"
log "6. Restart services: ./start_all_services.sh"
log ""
log "🔗 Service URLs:"
log "Main Backend: http://your-ec2-ip/"
log "File Manager: http://your-ec2-ip/file-manager/"
log "E-Proc Server: http://your-ec2-ip/eproc/"
log "System Usage: http://your-ec2-ip/system/"
log "Dashboard API: http://your-ec2-ip/dashboard/"
log "Scrapers API: http://your-ec2-ip/scrapers/"
log "Analytics API: http://your-ec2-ip/analytics/"
log "Additional Analytics: http://your-ec2-ip/analytics-additional/"
log "E-Proc WebSocket: http://your-ec2-ip/eproc-ws/"
log "E-Proc API: http://your-ec2-ip/eproc-api/"
log ""
log "✅ All services are now running in screen sessions!"
log "🌐 Access your application at: http://your-ec2-ip/"


