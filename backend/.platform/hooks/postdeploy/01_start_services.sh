#!/bin/bash
# Post-deployment hook to ensure all services are running
# This runs after the application is deployed

echo "$(date): Starting post-deployment service initialization..."

# Wait for main application to be ready
sleep 10

# Check if application.py is running
if pgrep -f "application.py" > /dev/null; then
    echo "$(date): Main application is running"
else
    echo "$(date): Main application not found, starting..."
    cd /var/app/current
    nohup python application.py > /var/log/application.log 2>&1 &
fi

# Create systemd service for automatic restart (if not exists)
if [ ! -f /etc/systemd/system/lavangam-backend.service ]; then
    echo "$(date): Creating systemd service..."
    cat > /etc/systemd/system/lavangam-backend.service << EOF
[Unit]
Description=Lavangam Backend Services
After=network.target

[Service]
Type=simple
User=webapp
WorkingDirectory=/var/app/current
ExecStart=/var/app/venv/*/bin/python application.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable lavangam-backend.service
    echo "$(date): Systemd service created and enabled"
fi

echo "$(date): Post-deployment setup complete"
