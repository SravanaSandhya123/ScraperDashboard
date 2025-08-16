# LAVANGAM EC2 Connection Script
# This script fixes SSH permissions and connects to your EC2 instance

Write-Host "🚀 LAVANGAM EC2 Connection Helper" -ForegroundColor Green
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

# Step 1: Fix SSH key permissions
Write-Host "🔧 Step 1: Fixing SSH key permissions..." -ForegroundColor Yellow
try {
    $acl = Get-Acl "lavangam-key.pem"
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl "lavangam-key.pem" $acl
    Write-Host "✅ SSH key permissions fixed successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to fix permissions: $_" -ForegroundColor Red
    Write-Host "Try running PowerShell as Administrator" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 2: Test SSH connection
Write-Host "🔍 Step 2: Testing SSH connection..." -ForegroundColor Yellow
Write-Host "EC2 Instance: 13.219.190.100" -ForegroundColor White
Write-Host "Username: ubuntu" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "- If successful, you'll see the Ubuntu welcome message" -ForegroundColor White
Write-Host "- To exit SSH, type: exit" -ForegroundColor White
Write-Host "- To upload files, open a new terminal and use scp" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Press Enter to attempt SSH connection (or 'n' to skip)"
if ($continue -eq 'n') {
    Write-Host "Skipping SSH connection." -ForegroundColor Yellow
} else {
    Write-Host "Attempting SSH connection..." -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Cyan
    
    try {
        & ssh -i lavangam-key.pem ubuntu@13.219.190.100
    } catch {
        Write-Host "❌ SSH connection failed: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "📋 Next Steps After Successful Connection:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Upload setup script:" -ForegroundColor White
Write-Host "   scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. On EC2, run setup:" -ForegroundColor White
Write-Host "   chmod +x setup-backend-on-ec2-enhanced.sh" -ForegroundColor Cyan
Write-Host "   ./setup-backend-on-ec2-enhanced.sh" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Upload backend code:" -ForegroundColor White
Write-Host "   scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. Restart services:" -ForegroundColor White
Write-Host "   sudo systemctl restart lavangam-backend nginx mysql" -ForegroundColor Cyan
Write-Host ""

Write-Host "5. Verify deployment:" -ForegroundColor White
Write-Host "   python3 check_services.py" -ForegroundColor Cyan
Write-Host ""

Write-Host "🚀 Your backend will be accessible at:" -ForegroundColor Green
Write-Host "   Main API: http://13.219.190.100/api/" -ForegroundColor White
Write-Host "   Scrapers: http://13.219.190.100/scrapers/" -ForegroundColor White
Write-Host "   Dashboard: http://13.219.190.100/dashboard/" -ForegroundColor White
Write-Host "   And all other services on their respective ports!" -ForegroundColor White

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host
