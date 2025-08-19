# AWS Console Deployment Script for LAVANGAM Backend
# This bypasses local SSH issues by using AWS Console

Write-Host "LAVANGAM Backend Deployment via AWS Console" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

Write-Host "Your EC2 Instance: 13.219.190.100" -ForegroundColor Cyan
Write-Host ""

Write-Host "STEP 1: Connect to EC2 via AWS Console" -ForegroundColor Yellow
Write-Host "1. In the AWS Console that just opened:" -ForegroundColor White
Write-Host "   - Go to EC2 → Instances" -ForegroundColor White
Write-Host "   - Find instance with IP: 13.219.190.100" -ForegroundColor White
Write-Host "   - Click 'Connect' → 'EC2 Instance Connect'" -ForegroundColor White
Write-Host "   - Click 'Connect' to open browser terminal" -ForegroundColor White
Write-Host ""

Write-Host "STEP 2: Copy these commands to the AWS Console terminal:" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Update system and install dependencies" -ForegroundColor Gray
Write-Host "sudo apt update && sudo apt upgrade -y" -ForegroundColor White
Write-Host "sudo apt install -y python3 python3-pip python3-venv mysql-server nginx git curl wget unzip build-essential" -ForegroundColor White
Write-Host ""

Write-Host "# Create backend directory" -ForegroundColor Gray
Write-Host "mkdir -p ~/lavangam-backend" -ForegroundColor White
Write-Host "cd ~/lavangam-backend" -ForegroundColor White
Write-Host ""

Write-Host "# Create Python virtual environment" -ForegroundColor Gray
Write-Host "python3 -m venv venv" -ForegroundColor White
Write-Host "source venv/bin/activate" -ForegroundColor White
Write-Host ""

Write-Host "# Install Python packages" -ForegroundColor Gray
Write-Host "pip install fastapi uvicorn flask flask-cors mysql-connector-python pandas python-dotenv requests beautifulsoup4 selenium" -ForegroundColor White
Write-Host ""

Write-Host "STEP 3: Upload your files" -ForegroundColor Yellow
Write-Host "In the AWS Console terminal, you need to upload:" -ForegroundColor White
Write-Host "- setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host "- check_services.py" -ForegroundColor White
Write-Host "- backend/ (your backend code)" -ForegroundColor White
Write-Host ""

Write-Host "STEP 4: Run the setup script" -ForegroundColor Yellow
Write-Host "chmod +x setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host "./setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host ""

Write-Host "STEP 5: Verify deployment" -ForegroundColor Yellow
Write-Host "python3 check_services.py" -ForegroundColor White
Write-Host "curl http://44.244.35.65:8000/health" -ForegroundColor White
Write-Host ""

Write-Host "After deployment, your backend will be available at:" -ForegroundColor Cyan
Write-Host "- Main API: http://13.219.190.100:8000" -ForegroundColor White
Write-Host "- Health Check: http://13.219.190.100:8000/health" -ForegroundColor White
Write-Host "- phpMyAdmin: http://13.219.190.100/phpmyadmin/" -ForegroundColor White
Write-Host ""

Write-Host "Press Enter when you're ready to start..." -ForegroundColor Green
Read-Host ""

Write-Host "Opening AWS Console..." -ForegroundColor Yellow
Start-Process "https://console.aws.amazon.com/ec2/v2/home?region=us-east-1"

Write-Host ""
Write-Host "Deployment Guide:" -ForegroundColor Green
Write-Host "1. AWS Console is now open" -ForegroundColor White
Write-Host "2. Follow the steps above" -ForegroundColor White
Write-Host "3. Copy-paste commands into the EC2 terminal" -ForegroundColor White
Write-Host "4. Upload your files" -ForegroundColor White
Write-Host "5. Run the setup script" -ForegroundColor White
Write-Host ""
Write-Host "Need help? Check DEPLOYMENT_GUIDE.md for detailed instructions." -ForegroundColor Cyan
