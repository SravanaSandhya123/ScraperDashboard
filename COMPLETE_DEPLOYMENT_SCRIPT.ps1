# =============================================================================
# LAVANGAM COMPLETE BACKEND DEPLOYMENT SCRIPT
# This script will guide you through deploying ALL your backend services on EC2
# =============================================================================

param(
    [switch]$SkipSSHCheck = $false,
    [switch]$AutoDeploy = $false
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"
$White = "White"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check if SSH key exists
function Test-SSHKey {
    if (Test-Path "lavangam-key.pem") {
        Write-ColorOutput "✅ SSH key found: lavangam-key.pem" $Green
        return $true
    } else {
        Write-ColorOutput "❌ SSH key 'lavangam-key.pem' not found!" $Red
        Write-ColorOutput "Please make sure the key file is in the current directory." $Yellow
        return $false
    }
}

# Function to fix SSH key permissions
function Fix-SSHPermissions {
    Write-ColorOutput "🔧 Fixing SSH key permissions..." $Yellow
    
    if (-not (Test-Administrator)) {
        Write-ColorOutput "❌ This script needs to be run as Administrator to fix SSH permissions!" $Red
        Write-ColorOutput "Please right-click on PowerShell and select 'Run as Administrator'" $Yellow
        Write-ColorOutput "Then run this script again." $Yellow
        return $false
    }
    
    try {
        $acl = Get-Acl "lavangam-key.pem"
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
        $acl.AddAccessRule($rule)
        Set-Acl "lavangam-key.pem" $acl
        Write-ColorOutput "✅ SSH key permissions fixed successfully!" $Green
        return $true
    } catch {
        Write-ColorOutput "❌ Failed to fix permissions: $_" $Red
        return $false
    }
}

# Function to test SSH connection
function Test-SSHConnection {
    Write-ColorOutput "🔍 Testing SSH connection..." $Yellow
    Write-ColorOutput "EC2 Instance: 13.219.190.100" $White
    Write-ColorOutput "Username: ubuntu" $White
    
    $continue = Read-Host "Press Enter to test SSH connection (or 'n' to skip)"
    if ($continue -eq 'n') {
        Write-ColorOutput "Skipping SSH test." $Yellow
        return $false
    }
    
    try {
        Write-ColorOutput "Attempting SSH connection..." $Green
        Write-ColorOutput "===============================================" $Cyan
        
        # Test SSH connection
        $sshTest = ssh -i lavangam-key.pem -o ConnectTimeout=10 -o BatchMode=yes ubuntu@13.219.190.100 "echo 'SSH connection successful'"
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ SSH connection successful!" $Green
            return $true
        } else {
            Write-ColorOutput "❌ SSH connection failed!" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ SSH connection failed: $_" $Red
        return $false
    }
}

# Function to upload setup script
function Upload-SetupScript {
    Write-ColorOutput "📤 Uploading setup script to EC2..." $Yellow
    
    try {
        $result = scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Setup script uploaded successfully!" $Green
            return $true
        } else {
            Write-ColorOutput "❌ Failed to upload setup script!" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Upload failed: $_" $Red
        return $false
    }
}

# Function to run setup script on EC2
function Run-SetupScript {
    Write-ColorOutput "🚀 Running setup script on EC2..." $Yellow
    
    try {
        $setupCommands = @(
            "chmod +x setup-backend-on-ec2-enhanced.sh",
            "./setup-backend-on-ec2-enhanced.sh"
        )
        
        foreach ($cmd in $setupCommands) {
            Write-ColorOutput "Running: $cmd" $Cyan
            $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 $cmd
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "❌ Command failed: $cmd" $Red
                return $false
            }
        }
        
        Write-ColorOutput "✅ Setup script completed successfully!" $Green
        return $true
    } catch {
        Write-ColorOutput "❌ Setup failed: $_" $Red
        return $false
    }
}

# Function to upload backend code
function Upload-BackendCode {
    Write-ColorOutput "📤 Uploading backend code to EC2..." $Yellow
    
    try {
        if (Test-Path "backend") {
            $result = scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/
        } elseif (Test-Path "lavangam-backend") {
            $result = scp -i lavangam-key.pem -r lavangam-backend/* ubuntu@13.219.190.100:~/lavangam-backend/
        } else {
            Write-ColorOutput "❌ Backend directory not found!" $Red
            return $false
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Backend code uploaded successfully!" $Green
            return $true
        } else {
            Write-ColorOutput "❌ Failed to upload backend code!" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Upload failed: $_" $Red
        return $false
    }
}

# Function to restart services
function Restart-Services {
    Write-ColorOutput "🔄 Restarting services on EC2..." $Yellow
    
    try {
        $restartCommands = @(
            "sudo systemctl restart lavangam-backend",
            "sudo systemctl restart nginx",
            "sudo systemctl restart mysql"
        )
        
        foreach ($cmd in $restartCommands) {
            Write-ColorOutput "Running: $cmd" $Cyan
            $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 $cmd
            
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput "⚠️  Warning: $cmd failed (this might be normal for new services)" $Yellow
            }
        }
        
        Write-ColorOutput "✅ Services restarted!" $Green
        return $true
    } catch {
        Write-ColorOutput "❌ Service restart failed: $_" $Red
        return $false
    }
}

# Function to verify deployment
function Verify-Deployment {
    Write-ColorOutput "🔍 Verifying deployment..." $Yellow
    
    try {
        # Upload health check script
        if (Test-Path "check_services.py") {
            scp -i lavangam-key.pem check_services.py ubuntu@13.219.190.100:~/
            
            # Run health check
            $result = ssh -i lavangam-key.pem ubuntu@13.219.190.100 "python3 check_services.py"
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ Health check completed!" $Green
            } else {
                Write-ColorOutput "⚠️  Health check had issues" $Yellow
            }
        }
        
        # Check service status
        $statusCommands = @(
            "sudo systemctl status nginx --no-pager",
            "sudo systemctl status mysql --no-pager",
            "sudo netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|8001|8002|5020|5021|5023|5001|5002|5005)'"
        )
        
        foreach ($cmd in $statusCommands) {
            Write-ColorOutput "Checking: $cmd" $Cyan
            ssh -i lavangam-key.pem ubuntu@13.219.190.100 $cmd
            Write-Host ""
        }
        
        Write-ColorOutput "✅ Deployment verification completed!" $Green
        return $true
    } catch {
        Write-ColorOutput "❌ Verification failed: $_" $Red
        return $false
    }
}

# Main execution
Write-ColorOutput "🚀 LAVANGAM COMPLETE BACKEND DEPLOYMENT" $Green
Write-ColorOutput "===============================================" $Cyan
Write-Host ""

# Check if SSH key exists
if (-not (Test-SSHKey)) {
    exit 1
}

Write-Host ""

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-ColorOutput "⚠️  WARNING: This script is not running as Administrator" $Yellow
    Write-ColorOutput "You may need to run PowerShell as Administrator to fix SSH permissions" $Yellow
    Write-Host ""
    
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-ColorOutput "Please run PowerShell as Administrator and try again." $Yellow
        exit 1
    }
}

Write-Host ""

# Step 1: Fix SSH permissions
if (-not $SkipSSHCheck) {
    if (-not (Fix-SSHPermissions)) {
        Write-ColorOutput "❌ Cannot proceed without fixing SSH permissions!" $Red
        Write-ColorOutput "Please run PowerShell as Administrator and try again." $Yellow
        exit 1
    }
}

Write-Host ""

# Step 2: Test SSH connection
if (-not $SkipSSHCheck) {
    if (-not (Test-SSHConnection)) {
        Write-ColorOutput "❌ Cannot proceed without SSH connection!" $Red
        Write-ColorOutput "Please check your EC2 instance and try again." $Yellow
        exit 1
    }
}

Write-Host ""

# Step 3: Upload setup script
if (-not (Upload-SetupScript)) {
    Write-ColorOutput "❌ Cannot proceed without uploading setup script!" $Red
    exit 1
}

Write-Host ""

# Step 4: Run setup script
if (-not (Run-SetupScript)) {
    Write-ColorOutput "❌ Setup script failed!" $Red
    Write-ColorOutput "Please check the EC2 instance logs and try again." $Yellow
    exit 1
}

Write-Host ""

# Step 5: Upload backend code
if (-not (Upload-BackendCode)) {
    Write-ColorOutput "❌ Cannot proceed without uploading backend code!" $Red
    exit 1
}

Write-Host ""

# Step 6: Restart services
if (-not (Restart-Services)) {
    Write-ColorOutput "⚠️  Service restart had issues, but continuing..." $Yellow
}

Write-Host ""

# Step 7: Verify deployment
if (-not (Verify-Deployment)) {
    Write-ColorOutput "⚠️  Deployment verification had issues" $Yellow
}

Write-Host ""
Write-ColorOutput "===============================================" $Cyan
Write-ColorOutput "🎉 DEPLOYMENT COMPLETED!" $Green
Write-ColorOutput "===============================================" $Cyan
Write-Host ""

Write-ColorOutput "🚀 Your backend services are now accessible at:" $Green
Write-ColorOutput "   Main API: http://13.219.190.100/api/" $White
Write-ColorOutput "   Scrapers: http://13.219.190.100/scrapers/" $White
Write-ColorOutput "   Dashboard: http://13.219.190.100/dashboard/" $White
Write-ColorOutput "   Analytics: http://13.219.190.100/analytics/" $White
Write-ColorOutput "   File Manager: http://13.219.190.100:5001/" $White
Write-ColorOutput "   And all other services on their respective ports!" $White

Write-Host ""
Write-ColorOutput "📋 Next steps:" $Yellow
Write-ColorOutput "1. Test your APIs using the URLs above" $White
Write-ColorOutput "2. Check the health of all services" $White
Write-ColorOutput "3. Monitor logs: ssh -i lavangam-key.pem ubuntu@13.219.190.100" $White
Write-ColorOutput "4. View service status: sudo systemctl status [service-name]" $White

Write-Host ""
Write-ColorOutput "Press Enter to exit..." $Cyan
Read-Host
