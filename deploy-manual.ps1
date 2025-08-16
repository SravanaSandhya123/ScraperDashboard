# Simple Manual Deployment Script
# This will help you deploy your backend step by step

Write-Host "LAVANGAM Backend Manual Deployment" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Your EC2 Instance: 13.219.190.100" -ForegroundColor Cyan
Write-Host ""

Write-Host "Deployment Steps:" -ForegroundColor Yellow
Write-Host "1. Go to AWS Console → EC2 → Instances" -ForegroundColor White
Write-Host "2. Select instance: 13.219.190.100" -ForegroundColor White
Write-Host "3. Click 'Connect' → 'EC2 Instance Connect'" -ForegroundColor White
Write-Host "4. Use the browser terminal" -ForegroundColor White
Write-Host ""

Write-Host "Commands to run on EC2:" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Update system" -ForegroundColor Gray
Write-Host "sudo apt update and sudo apt upgrade -y" -ForegroundColor White
Write-Host ""

Write-Host "# Install dependencies" -ForegroundColor Gray
Write-Host "sudo apt install -y python3 python3-pip python3-venv mysql-server nginx git curl wget" -ForegroundColor White
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
Write-Host "pip install fastapi uvicorn flask flask-cors mysql-connector-python pandas python-dotenv" -ForegroundColor White
Write-Host ""

Write-Host "# Download setup script" -ForegroundColor Gray
Write-Host "wget https://raw.githubusercontent.com/your-repo/setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host "chmod +x setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Copy the commands above" -ForegroundColor White
Write-Host "2. Paste them in the AWS Console terminal" -ForegroundColor White
Write-Host "3. Run them one by one" -ForegroundColor White
Write-Host "4. Upload your backend code" -ForegroundColor White
Write-Host ""

Write-Host "Files you need to upload:" -ForegroundColor Yellow
Write-Host "- setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host "- check_services.py" -ForegroundColor White
Write-Host "- backend/ (your backend code)" -ForegroundColor White
Write-Host ""

Write-Host "After deployment, access:" -ForegroundColor Cyan
Write-Host "- Backend: http://13.219.190.100:8000" -ForegroundColor White
Write-Host "- Health: http://13.219.190.100:8000/health" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to continue"
