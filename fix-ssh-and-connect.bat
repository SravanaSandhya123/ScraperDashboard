@echo off
echo ========================================
echo    LAVANGAM EC2 SSH Connection Helper
echo ========================================
echo.

echo Current directory: %CD%
echo SSH Key file: lavangam-key.pem
echo EC2 IP: 13.219.190.100
echo.

echo Step 1: Fixing SSH key permissions...
powershell -Command "& {$acl = Get-Acl 'lavangam-key.pem'; $acl.SetAccessRuleProtection($true, $false); $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, 'FullControl', 'Allow'); $acl.AddAccessRule($rule); Set-Acl 'lavangam-key.pem' $acl; Write-Host 'Permissions fixed successfully!' -ForegroundColor Green}"

echo.
echo Step 2: Testing SSH connection...
echo.
echo If successful, you should see the Ubuntu welcome message.
echo To exit SSH, type: exit
echo.
echo Press any key to attempt SSH connection...
pause >nul

echo.
echo Attempting SSH connection...
ssh -i lavangam-key.pem ubuntu@13.219.190.100

echo.
echo SSH session ended.
echo.
echo Next steps:
echo 1. Upload setup script: scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/
echo 2. Run setup on EC2: chmod +x setup-backend-on-ec2-enhanced.sh && ./setup-backend-on-ec2-enhanced.sh
echo 3. Upload backend code: scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/
echo.
pause
