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
netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|5000|5001|80)'
echo ""
echo "=== Service Logs (last 10 lines) ==="
journalctl -u lavangam-backend.service -n 10 --no-pager
EOF
chmod +x /opt/lavangam/check-status.sh

# Wait for services to start
sleep 30
