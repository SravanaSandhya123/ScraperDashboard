# File Upload Script for LAVANGAM Backend
# Uploads required files to EC2 instance

param(
    [string]$EC2IP = "13.219.190.100",
    [string]$KeyFile = "mahi.pem",
    [string]$Username = "ubuntu"
)

Write-Host "LAVANGAM Backend - File Upload Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Target EC2 Instance: $Username@$EC2IP" -ForegroundColor Cyan
Write-Host ""

# Check if key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "ERROR: SSH Key file '$KeyFile' not found!" -ForegroundColor Red
    Write-Host "Please ensure your SSH key file is in the current directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "SSH Key found: $KeyFile" -ForegroundColor Green
Write-Host ""

# Upload setup script
Write-Host "Uploading setup-backend-on-ec2.sh..." -ForegroundColor Yellow
if (Test-Path "setup-backend-on-ec2.sh") {
    try {
        $result = scp -i $KeyFile -o StrictHostKeyChecking=no "setup-backend-on-ec2.sh" "$Username@$EC2IP`:~/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ setup-backend-on-ec2.sh uploaded successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to upload setup-backend-on-ec2.sh" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Upload error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "❌ setup-backend-on-ec2.sh not found in current directory" -ForegroundColor Red
}

Write-Host ""

# Upload health check script
Write-Host "Uploading check_services.py..." -ForegroundColor Yellow
if (Test-Path "check_services.py") {
    try {
        $result = scp -i $KeyFile -o StrictHostKeyChecking=no "check_services.py" "$Username@$EC2IP`:~/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ check_services.py uploaded successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to upload check_services.py" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Upload error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "❌ check_services.py not found in current directory" -ForegroundColor Red
}

Write-Host ""

# Upload backend directory
Write-Host "Uploading backend/ directory..." -ForegroundColor Yellow
if (Test-Path "backend") {
    try {
        $result = scp -i $KeyFile -o StrictHostKeyChecking=no -r "backend" "$Username@$EC2IP`:~/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ backend/ directory uploaded successfully" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to upload backend/ directory" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Upload error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "❌ backend/ directory not found in current directory" -ForegroundColor Red
}

Write-Host ""
Write-Host "File upload completed!" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps on your EC2 instance:" -ForegroundColor Cyan
Write-Host "1. Navigate to your home directory:" -ForegroundColor White
Write-Host "   cd ~" -ForegroundColor White
Write-Host ""
Write-Host "2. Make the setup script executable:" -ForegroundColor White
Write-Host "   chmod +x setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host ""
Write-Host "3. Run the setup script:" -ForegroundColor White
Write-Host "   ./setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host ""
Write-Host "4. After setup completes, verify deployment:" -ForegroundColor White
Write-Host "   python3 check_services.py" -ForegroundColor White
Write-Host "   curl http://localhost:8000/health" -ForegroundColor White
Write-Host ""

Write-Host "Your backend will be available at:" -ForegroundColor Cyan
Write-Host "- Main API: http://$EC2IP:8000" -ForegroundColor White
Write-Host "- Health Check: http://$EC2IP:8000/health" -ForegroundColor White
Write-Host "- phpMyAdmin: http://$EC2IP/phpmyadmin/" -ForegroundColor White
Write-Host ""

Write-Host "Press Enter to start file upload..." -ForegroundColor Green
Read-Host ""
