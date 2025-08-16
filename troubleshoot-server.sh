#!/bin/bash
echo "=== LAVANGAM BACKEND TROUBLESHOOTING ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Checking systemd service status..."
systemctl status lavangam-backend.service --no-pager || echo "Service not found or failed"
echo ""

echo "2. Checking if application.py exists..."
ls -la /opt/lavangam/application.py || echo "Application file not found"
echo ""

echo "3. Checking deployment files..."
ls -la /opt/lavangam/ | head -20
echo ""

echo "4. Checking Python and dependencies..."
python3 --version
pip3 list | grep -E "(fastapi|uvicorn|flask)" || echo "Dependencies not installed"
echo ""

echo "5. Checking active ports..."
netstat -tlnp | grep -E ":(80|8000|5022|5024|8004|5025)" || echo "No services listening on expected ports"
echo ""

echo "6. Checking system logs..."
journalctl -u lavangam-backend.service -n 20 --no-pager || echo "No service logs found"
echo ""

echo "7. Attempting manual service start..."
cd /opt/lavangam
echo "Current directory: $(pwd)"
echo "Files in directory:"
ls -la
echo ""

echo "8. Testing Python application directly..."
python3 -c "import sys; print('Python path:', sys.path)" 2>&1
echo ""

echo "9. Checking if S3 download worked..."
ls -la /opt/lavangam/*deployment* 2>/dev/null || echo "Deployment files not found"
echo ""

echo "10. Manual dependency installation..."
pip3 install fastapi uvicorn flask flask-cors pandas python-dotenv
echo ""

echo "11. Starting application manually..."
cd /opt/lavangam
python3 application.py &
sleep 5
echo ""

echo "12. Final port check..."
netstat -tlnp | grep -E ":(80|8000|5022|5024|8004|5025)" || echo "Still no services listening"

echo ""
echo "=== TROUBLESHOOTING COMPLETE ==="
