# LAVANGAM Backend Deployment Script for Windows
# This script will deploy your backend to the EC2 instance

param(
    [string]$EC2IP = "13.219.190.100",
    [string]$KeyFile = "mahi.pem",
    [string]$Username = "ubuntu"
)

Write-Host "LAVANGAM Backend Deployment Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Check if key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "SSH Key file '$KeyFile' not found!" -ForegroundColor Red
    Write-Host "Please ensure your SSH key file is in the current directory." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To download your key from AWS Console:" -ForegroundColor Cyan
    Write-Host "1. Go to AWS Console → EC2 → Key Pairs" -ForegroundColor Cyan
    Write-Host "2. Download your key file" -ForegroundColor Cyan
    Write-Host "3. Place it in this directory" -ForegroundColor Cyan
    exit 1
}

Write-Host "SSH Key file found: $KeyFile" -ForegroundColor Green

# Fix SSH key permissions
Write-Host "Fixing SSH key permissions..." -ForegroundColor Yellow
try {
    # Remove inheritance and set restrictive permissions
    $acl = Get-Acl $KeyFile
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "Read", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $KeyFile $acl
    Write-Host "SSH key permissions fixed" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not fix permissions automatically" -ForegroundColor Yellow
    Write-Host "You may need to run PowerShell as Administrator" -ForegroundColor Yellow
}

# Test SSH connection
Write-Host "Testing SSH connection to $EC2IP..." -ForegroundColor Yellow
try {
    $testResult = ssh -i $KeyFile -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$Username@$EC2IP" "echo 'SSH connection successful'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SSH connection successful!" -ForegroundColor Green
    } else {
        Write-Host "SSH connection failed!" -ForegroundColor Red
        Write-Host "Error: $testResult" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
        Write-Host "1. Ensure your EC2 instance is running" -ForegroundColor Cyan
        Write-Host "2. Check security group allows SSH (port 22)" -ForegroundColor Cyan
        Write-Host "3. Verify the IP address is correct" -ForegroundColor Cyan
        Write-Host "4. Try using AWS Console → EC2 → Connect" -ForegroundColor Cyan
        exit 1
    }
} catch {
    Write-Host "SSH test failed: $_" -ForegroundColor Red
    exit 1
}

# Copy setup script
Write-Host "Copying setup script to EC2..." -ForegroundColor Yellow
try {
    $copyResult = scp -i $KeyFile -o StrictHostKeyChecking=no "setup-backend-on-ec2.sh" "$Username@$EC2IP`:~/"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Setup script copied successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to copy setup script: $copyResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Copy failed: $_" -ForegroundColor Red
    exit 1
}

# Copy health check script
Write-Host "Copying health check script to EC2..." -ForegroundColor Yellow
try {
    $copyResult = scp -i $KeyFile -o StrictHostKeyChecking=no "check_services.py" "$Username@$EC2IP`:~/"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Health check script copied successfully" -ForegroundColor Green
    } else {
        Write-Host "Failed to copy health check script: $copyResult" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Copy failed: $_" -ForegroundColor Red
    exit 1
}

# Copy backend code if it exists
if (Test-Path "backend") {
    Write-Host "Copying backend code to EC2..." -ForegroundColor Yellow
    try {
        $copyResult = scp -i $KeyFile -o StrictHostKeyChecking=no -r "backend" "$Username@$EC2IP`:~/"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Backend code copied successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to copy backend code: $copyResult" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Copy failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Backend directory not found, skipping..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Files copied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. SSH into your EC2 instance:" -ForegroundColor White
Write-Host "   ssh -i $KeyFile $Username@$EC2IP" -ForegroundColor White
Write-Host ""
Write-Host "2. Make the setup script executable:" -ForegroundColor White
Write-Host "   chmod +x setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host ""
Write-Host "3. Run the setup script:" -ForegroundColor White
Write-Host "   ./setup-backend-on-ec2.sh" -ForegroundColor White
Write-Host ""

# Ask if user wants to SSH immediately
$sshNow = Read-Host "Do you want to SSH into the EC2 instance now? (y/n)"
if ($sshNow -eq "y" -or $sshNow -eq "Y") {
    Write-Host "Connecting to EC2 instance..." -ForegroundColor Green
    ssh -i $KeyFile -o StrictHostKeyChecking=no "$Username@$EC2IP"
} else {
    Write-Host "Deployment preparation complete!" -ForegroundColor Green
    Write-Host "You can SSH manually when ready." -ForegroundColor Cyan
} 