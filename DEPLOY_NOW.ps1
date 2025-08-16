# =============================================================================
# LAVANGAM BACKEND DEPLOYMENT - SIMPLIFIED VERSION
# This script will deploy your backend services on EC2
# =============================================================================

Write-Host "🚀 LAVANGAM BACKEND DEPLOYMENT STARTING..." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Check if SSH key exists
if (-not (Test-Path "lavangam-key.pem")) {
    Write-Host "❌ SSH key 'lavangam-key.pem' not found!" -ForegroundColor Red
    Write-Host "Please make sure the key file is in the current directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ SSH key found: lavangam-key.pem" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: This script is not running as Administrator" -ForegroundColor Yellow
    Write-Host "You may need to run PowerShell as Administrator to fix SSH permissions" -ForegroundColor Yellow
    Write-Host ""
    
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

# Step 1: Fix SSH permissions (if running as admin)
if ($isAdmin) {
    Write-Host "🔧 Fixing SSH key permissions..." -ForegroundColor Yellow
    try {
        $acl = Get-Acl "lavangam-key.pem"
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
        $acl.AddAccessRule($rule)
        Set-Acl "lavangam-key.pem" $acl
        Write-Host "✅ SSH key permissions fixed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to fix permissions: $_" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Skipping SSH permission fix (not running as Administrator)" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Test SSH connection
Write-Host "🔍 Testing SSH connection..." -ForegroundColor Yellow
Write-Host "EC2 Instance: 13.219.190.100" -ForegroundColor White
Write-Host "Username: ubuntu" -ForegroundColor White

$continue = Read-Host "Press Enter to test SSH connection (or 'n' to skip)"
if ($continue -eq 'n') {
    Write-Host "Skipping SSH test." -ForegroundColor Yellow
} else {
    Write-Host "Attempting SSH connection..." -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Cyan
    
    try {
        $sshTest = ssh -i lavangam-key.pem -o ConnectTimeout=10 -o BatchMode=yes ubuntu@13.219.190.100 "echo 'SSH connection successful'"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ SSH connection successful!" -ForegroundColor Green
        } else {
            Write-Host "❌ SSH connection failed!" -ForegroundColor Red
            Write-Host "Please check your EC2 instance and try again." -ForegroundColor Yellow
            exit 1
        }
    } catch {
        Write-Host "❌ SSH connection failed: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 3: Upload setup script
Write-Host "📤 Uploading setup script to EC2..." -ForegroundColor Yellow

try {
    $result = scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Setup script uploaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to upload setup script!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Upload failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Run setup script on EC2
Write-Host "🚀 Running setup script on EC2..." -ForegroundColor Yellow

try {
    Write-Host "Running: chmod +x setup-backend-on-ec2-enhanced.sh" -ForegroundColor Cyan
    $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 "chmod +x setup-backend-on-ec2-enhanced.sh"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Running: ./setup-backend-on-ec2-enhanced.sh" -ForegroundColor Cyan
        $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 "./setup-backend-on-ec2-enhanced.sh"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Setup script completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Setup script failed!" -ForegroundColor Red
            Write-Host "Please check the EC2 instance logs and try again." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "❌ Failed to make script executable!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Setup failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 5: Upload backend code
Write-Host "📤 Uploading backend code to EC2..." -ForegroundColor Yellow

try {
    if (Test-Path "backend") {
        $result = scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/
    } elseif (Test-Path "lavangam-backend") {
        $result = scp -i lavangam-key.pem -r lavangam-backend/* ubuntu@13.219.190.100:~/lavangam-backend/
    } else {
        Write-Host "❌ Backend directory not found!" -ForegroundColor Red
        exit 1
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Backend code uploaded successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to upload backend code!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Upload failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 6: Restart services
Write-Host "🔄 Restarting services on EC2..." -ForegroundColor Yellow

try {
    $restartCommands = @(
        "sudo systemctl restart lavangam-backend",
        "sudo systemctl restart nginx",
        "sudo systemctl restart mysql"
    )
    
    foreach ($cmd in $restartCommands) {
        Write-Host "Running: $cmd" -ForegroundColor Cyan
        $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 $cmd
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Warning: $cmd failed (this might be normal for new services)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "✅ Services restarted!" -ForegroundColor Green
} catch {
    Write-Host "❌ Service restart failed: $_" -ForegroundColor Red
}

Write-Host ""

# Step 7: Verify deployment
Write-Host "🔍 Verifying deployment..." -ForegroundColor Yellow

try {
    # Upload health check script
    if (Test-Path "check_services.py") {
        scp -i lavangam-key.pem check_services.py ubuntu@13.219.190.100:~/
        
        # Run health check
        $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 "python3 check_services.py"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Health check completed!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Health check had issues" -ForegroundColor Yellow
        }
    }
    
    # Check service status
    $statusCommands = @(
        "sudo systemctl status nginx --no-pager",
        "sudo systemctl status mysql --no-pager",
        "sudo netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|8001|8002|5020|5021|5023|5001|5002|5005)'"
    )
    
    foreach ($cmd in $statusCommands) {
        Write-Host "Checking: $cmd" -ForegroundColor Cyan
        ssh -i lavangam-key.pem ubuntu@13.219.190.100 $cmd
        Write-Host ""
    }
    
    Write-Host "✅ Deployment verification completed!" -ForegroundColor Green
} catch {
    Write-Host "❌ Verification failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "🎉 DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Your backend services are now accessible at:" -ForegroundColor Green
Write-Host "   Main API: http://13.219.190.100/api/" -ForegroundColor White
Write-Host "   Scrapers: http://13.219.190.100/scrapers/" -ForegroundColor White
Write-Host "   Dashboard: http://13.219.190.100/dashboard/" -ForegroundColor White
Write-Host "   Analytics: http://13.219.190.100/analytics/" -ForegroundColor White
Write-Host "   File Manager: http://13.219.190.100:5001/" -ForegroundColor White
Write-Host "   And all other services on their respective ports!" -ForegroundColor White

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Test your APIs using the URLs above" -ForegroundColor White
Write-Host "2. Check the health of all services" -ForegroundColor White
Write-Host "3. Monitor logs: ssh -i lavangam-key.pem ubuntu@13.219.190.100" -ForegroundColor White
Write-Host "4. View service status: sudo systemctl status [service-name]" -ForegroundColor White

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Cyan
Read-Host
