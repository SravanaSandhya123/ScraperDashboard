# 🚀 Manual EC2 Setup Guide for LAVANGAM Backend

## ✅ Current Status
- **EC2 Instance**: Running at `13.219.190.100`
- **Instance Type**: `t3.medium`
- **SSH Key**: `lavangam-key.pem`
- **Status**: Ready for setup

## 🔧 Step-by-Step Manual Setup

### Step 1: Fix SSH Key Permissions (Windows)

Since we're having SSH permission issues on Windows, let's fix this first:

```powershell
# Open PowerShell as Administrator and run:
$acl = Get-Acl "lavangam-key.pem"
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
$acl.AddAccessRule($rule)
Set-Acl "lavangam-key.pem" $acl
```

### Step 2: Test SSH Connection

```bash
# Test the connection
ssh -i lavangam-key.pem ubuntu@13.219.190.100
```

If successful, you should see the Ubuntu welcome message.

### Step 3: Upload Setup Script

From your local machine (in a new terminal):

```bash
# Upload the enhanced setup script
scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/
```

### Step 4: Run Setup Script on EC2

On the EC2 instance:

```bash
# Make script executable
chmod +x setup-backend-on-ec2-enhanced.sh

# Run the setup script
./setup-backend-on-ec2-enhanced.sh
```

**⚠️ Important**: This will take 15-20 minutes to complete.

### Step 5: Upload Backend Code

After setup completes, upload your backend code:

```bash
# From your local machine
scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/
```

### Step 6: Restart Services

On the EC2 instance:

```bash
# Restart all services
sudo systemctl restart lavangam-backend
sudo systemctl restart nginx
sudo systemctl restart mysql
```

### Step 7: Verify Deployment

```bash
# Check service status
sudo systemctl status lavangam-backend

# Check all ports
sudo netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|8001|8002|5020|5021|5023|5001|5002|5005)'

# Run health check
cd ~/lavangam-backend
source venv/bin/activate
python3 check_services.py
```

## 🌐 Alternative: Use AWS Console

If SSH continues to have issues, you can:

1. **Go to AWS Console** → EC2 → Instances
2. **Select your instance** (`13.219.190.100`)
3. **Click "Connect"** → **"EC2 Instance Connect"**
4. **Click "Connect"** to open a browser-based terminal
5. **Run the setup commands manually**

## 🔍 Troubleshooting SSH Issues

### Option 1: Use PuTTY (Windows)
1. Download PuTTY and PuTTYgen
2. Convert your .pem key to .ppk format
3. Use PuTTY to connect

### Option 2: Use Windows Subsystem for Linux (WSL)
1. Install WSL
2. Copy your key to WSL
3. Use Linux SSH commands

### Option 3: Use Git Bash
1. Install Git for Windows
2. Use Git Bash terminal
3. SSH commands work better in Git Bash

## 📋 Quick Commands Reference

```bash
# Connect to EC2
ssh -i lavangam-key.pem ubuntu@13.219.190.100

# Upload files
scp -i lavangam-key.pem filename ubuntu@13.219.190.100:~/

# Check services
sudo systemctl status lavangam-backend
sudo systemctl status nginx
sudo systemctl status mysql

# View logs
sudo journalctl -u lavangam-backend -f
sudo tail -f /var/log/nginx/access.log

# Check ports
sudo netstat -tlnp
```

## 🎯 Expected Results

After successful setup, you should have:

- ✅ MySQL running on port 3306
- ✅ Nginx running on port 80/443
- ✅ All 13 backend services running on their ports
- ✅ Automatic startup on reboot
- ✅ Proper firewall configuration
- ✅ Health check script working

## 🆘 Need Help?

If you continue to have issues:

1. **Check AWS Console** for instance status
2. **Verify Security Groups** have all required ports open
3. **Check Instance Logs** in AWS Console
4. **Try EC2 Instance Connect** as alternative to SSH

---

**🚀 Ready to proceed?** Choose your preferred method and let's get your backend deployed!
