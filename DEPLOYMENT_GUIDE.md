# 🚀 LAVANGAM Backend Deployment Guide

## Current Status
✅ **EC2 Instance**: Running at 13.219.190.100  
✅ **Setup Scripts**: Ready (setup-backend-on-ec2.sh)  
✅ **Health Check**: Ready (check_services.py)  
⚠️ **SSH Access**: Needs permission fix  

## 🎯 Quick Deployment Options

### Option 1: Automated Deployment (Recommended)
1. **Download your SSH key** from AWS Console → EC2 → Key Pairs
2. **Place the key file** in this directory (rename to `mahi.pem`)
3. **Run the deployment script**:
   ```bash
   # Double-click this file:
   deploy-backend.bat
   
   # Or run PowerShell:
   .\deploy-backend.ps1
   ```

### Option 2: Manual Deployment
1. **Fix SSH permissions** (PowerShell as Administrator):
   ```powershell
   cd C:\lavangam\lavangam
   icacls "mahi.pem" /inheritance:r /grant:r "$($env:USERNAME):(R)"
   ```

2. **Copy files to EC2**:
   ```bash
   scp -i "mahi.pem" setup-backend-on-ec2.sh ubuntu@13.219.190.100:~/
   scp -i "mahi.pem" check_services.py ubuntu@13.219.190.100:~/
   ```

3. **SSH and run setup**:
   ```bash
   ssh -i "mahi.pem" ubuntu@13.219.190.100
   
   # On EC2:
   chmod +x setup-backend-on-ec2.sh
   ./setup-backend-on-ec2.sh
   ```

### Option 3: AWS Console (Alternative)
1. Go to AWS Console → EC2 → Instances
2. Select instance (13.219.190.100)
3. Click "Connect" → "EC2 Instance Connect"
4. Use browser terminal to run setup

## 🔧 What the Setup Script Does

The `setup-backend-on-ec2.sh` script will:

1. **Install Dependencies**:
   - Python 3, pip, virtual environments
   - MySQL database server
   - Nginx web server
   - phpMyAdmin for database management

2. **Configure Services**:
   - MySQL database with secure credentials
   - Nginx reverse proxy for all APIs
   - Systemd services for auto-startup
   - Firewall configuration

3. **Setup Backend Structure**:
   - Create Python virtual environment
   - Install all required Python packages
   - Configure environment variables
   - Create service management scripts

4. **Configure Ports**:
   - Main API: 8000
   - Scrapers API: 5022
   - System Usage: 5024
   - Dashboard API: 8004
   - Admin Metrics: 5025
   - Analytics: 8001
   - E-Procurement: 5021
   - File Manager: 5001
   - Export Server: 5002
   - MySQL: 3306
   - HTTP: 80

## 🌐 After Deployment

### Access URLs
- **Backend Health**: http://13.219.190.100/health
- **phpMyAdmin**: http://13.219.190.100/phpmyadmin/
- **Main API**: http://13.219.190.100/api/
- **Dashboard**: http://13.219.190.100/dashboard/

### Default Credentials
- **MySQL Root**: `root` / `Lavangam2024!`
- **MySQL User**: `lavangam_user` / `Lavangam2024!`
- **Database**: `lavangam_db`

### Management Commands
```bash
# Check service status
python3 check_services.py

# Manage services
sudo systemctl status lavangam-backend
sudo systemctl restart lavangam-backend

# View logs
sudo journalctl -u lavangam-backend -f
```

## 🚨 Troubleshooting

### SSH Permission Issues
```powershell
# Run PowerShell as Administrator
icacls "mahi.pem" /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

### Connection Refused
- Check EC2 security group allows SSH (port 22)
- Verify instance is running
- Check if IP address is correct

### Service Not Starting
```bash
# Check service status
sudo systemctl status lavangam-backend

# Check logs
sudo journalctl -u lavangam-backend -f

# Restart service
sudo systemctl restart lavangam-backend
```

## 📋 Next Steps After Deployment

1. **Upload Your Backend Code**:
   ```bash
   scp -i "mahi.pem" -r backend/ ubuntu@13.219.190.100:~/lavangam-backend/
   ```

2. **Update Environment Variables**:
   - Edit `.env` file on EC2
   - Update database credentials if needed

3. **Restart Services**:
   ```bash
   sudo systemctl restart lavangam-backend
   sudo systemctl restart nginx
   ```

4. **Test Endpoints**:
   ```bash
   python3 check_services.py
   curl http://44.244.35.65:8000/health
   ```

5. **Update Frontend**:
   - Change API_BASE_URL to `http://13.219.190.100`
   - Test all functionality

## 🎉 Success Indicators

- All services show "RUNNING" status
- Health check returns 200 OK
- phpMyAdmin accessible
- No error messages in logs
- All ports responding

---

**Need Help?** Check the logs and service status first, then refer to the troubleshooting section above.
