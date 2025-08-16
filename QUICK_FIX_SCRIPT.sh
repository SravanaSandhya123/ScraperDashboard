#!/bin/bash

echo "🔧 QUICK FIX for LAVANGAM Backend Issues..."

# Get your actual public IP
YOUR_ACTUAL_IP=$(curl -s ifconfig.me)
echo "Your actual public IP: $YOUR_ACTUAL_IP"

# Stop current services
echo "Stopping current services..."
sudo systemctl stop lavangam-backend
sudo systemctl stop nginx

# Fix Nginx configuration with correct IP
echo "Fixing Nginx configuration..."
sudo tee /etc/nginx/sites-available/lavangam-backend > /dev/null << NGINXEOF
server {
    listen 80;
    server_name $YOUR_ACTUAL_IP;

    # Main API
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Scrapers API
    location /scrapers/ {
        proxy_pass http://localhost:5022/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # System Usage API
    location /system/ {
        proxy_pass http://localhost:5024/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Dashboard API
    location /dashboard/ {
        proxy_pass http://localhost:8004/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Admin Metrics API
    location /admin/ {
        proxy_pass http://localhost:5025/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Analytics API
    location /analytics/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Analytics2 API
    location /analytics2/ {
        proxy_pass http://localhost:8002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # E-Procurement Server
    location /eproc/ {
        proxy_pass http://localhost:5021/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # E-Procurement Fixed
    location /eproc-fixed/ {
        proxy_pass http://localhost:5023/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # File Manager
    location /files/ {
        proxy_pass http://localhost:5001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Export Server
    location /export/ {
        proxy_pass http://localhost:5002/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # E-Procurement API
    location /eproc-api/ {
        proxy_pass http://localhost:5005/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # PHP Admin Panel - FIXED CONFIGURATION
    location /phpadmin/ {
        alias /usr/share/phpmyadmin/;
        index index.php index.html;
        try_files \$uri \$uri/ /phpadmin/index.php?\$query_string;
    }

    location ~ ^/phpadmin/(.+\.php)$ {
        alias /usr/share/phpmyadmin/\$1;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /usr/share/phpmyadmin/\$1;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
}
NGINXEOF

# Fix phpMyAdmin permissions
echo "Fixing phpMyAdmin permissions..."
sudo chown -R www-data:www-data /usr/share/phpmyadmin
sudo chmod -R 755 /usr/share/phpmyadmin

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Start services
echo "Starting services..."
sudo systemctl start lavangam-backend
sudo systemctl start nginx

# Wait for services to start
echo "Waiting for services to start..."
sleep 15

# Test services
echo "Testing services..."
curl -s "http://localhost:8000/" && echo "✅ Main API (8000) is running"
curl -s "http://localhost:5022/" && echo "✅ Scrapers API (5022) is running"
curl -s "http://localhost:5024/" && echo "✅ System API (5024) is running"

# Test Nginx proxy
echo "Testing Nginx proxy..."
curl -s "http://localhost/api/" && echo "✅ Nginx proxy to Main API is working"

echo ""
echo "🎉 QUICK FIX COMPLETE!"
echo ""
echo "Your services should now be accessible at:"
echo "phpMyAdmin: http://$YOUR_ACTUAL_IP/phpadmin/"
echo "Main API: http://$YOUR_ACTUAL_IP/api/"
echo "Scrapers: http://$YOUR_ACTUAL_IP/scrapers/"
echo ""
echo "IMPORTANT: Access through port 80 (http://$YOUR_ACTUAL_IP/) NOT port 8000!"
echo ""
echo "To check status:"
echo "sudo systemctl status lavangam-backend"
echo "sudo systemctl status nginx"
