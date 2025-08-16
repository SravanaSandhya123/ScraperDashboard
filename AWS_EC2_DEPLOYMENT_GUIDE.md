# 🚀 Lavangam Backend AWS EC2 Complete Deployment Guide

This guide will help you deploy your Lavangam backend to AWS EC2 with automatic startup, Nginx reverse proxy, phpMyAdmin, and MySQL database.

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **PowerShell** (Windows) or **Bash** (Linux/Mac)
4. **SSH client** (PuTTY on Windows, or built-in SSH on Linux/Mac)

## 🔧 Setup Steps

### Step 1: Configure AWS CLI

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-west-2)
- Default output format (json)

### Step 2: Run the Deployment Script

#### Option A: PowerShell (Windows)
```powershell
.\deploy-aws-ec2-complete.ps1
```

#### Option B: Custom Parameters
```powershell
.\deploy-aws-ec2-complete.ps1 -InstanceType "t3.medium" -KeyName "my-key" -InstanceName "my-backend"
```

### Step 3: Wait for Instance Launch

The script will:
- Create security group with required ports
- Create key pair for SSH access
- Launch EC2 instance with Ubuntu 22.04 LTS
- Configure all services automatically

## 🏗️ What Gets Deployed

### 1. **EC2 Instance**
- **OS**: Ubuntu 22.04 LTS
- **Instance Type**: t3.medium (configurable)
- **Storage**: 8GB GP2 EBS (default)

### 2. **Security Group**
- **Port 22**: SSH access
- **Port 80**: HTTP (Nginx)
- **Port 443**: HTTPS (Nginx)
- **Port 8000**: Backend API
- **Port 8080**: Alternative backend port
- **Port 3306**: MySQL database

### 3. **Services Installed**
- **Python 3.10+** with virtual environment
- **MySQL 8.0** with database `toolinfomation`
- **Nginx** as reverse proxy
- **phpMyAdmin** for database management
- **Node.js 18.x** for additional tools
- **UFW Firewall** for security

### 4. **Database Configuration**
- **Username**: `root`
- **Password**: `thanuja`
- **Database**: `toolinfomation`
- **Host**: `localhost`
- **Port**: `3306`

## 🔗 Access URLs

Once deployed, you can access:

- **Backend API**: `http://YOUR_EC2_IP:8000`
- **phpMyAdmin**: `http://YOUR_EC2_IP/phpmyadmin/`
- **Nginx**: `http://YOUR_EC2_IP`
- **Health Check**: `http://YOUR_EC2_IP/health`

## 📁 File Structure on EC2

```
/opt/lavangam/
├── venv/                    # Python virtual environment
├── .env                     # Environment variables
├── startup.sh              # Auto-startup script
├── check_status.sh         # Status check script
├── setup_database.py       # Database setup script
└── main.py                 # Your backend code (to be uploaded)
```

## 🚀 Automatic Startup

The backend is configured to start automatically:

1. **Systemd Service**: `lavangam-backend.service`
2. **Crontab**: `@reboot` script execution
3. **Dependencies**: MySQL → Nginx → Backend

## 📊 Monitoring & Management

### Check Service Status
```bash
/opt/lavangam/check_status.sh
```

### View Backend Logs
```bash
sudo journalctl -u lavangam-backend -f
```

### Restart Services
```bash
sudo systemctl restart lavangam-backend
sudo systemctl restart nginx
sudo systemctl restart mysql
```

## 🔐 Security Features

1. **Firewall (UFW)** enabled with specific port access
2. **MySQL** secured with root password
3. **SSH** access only via key pair
4. **Nginx** reverse proxy for API protection

## 📝 Manual Deployment (Alternative)

If you prefer manual deployment:

### 1. Connect to EC2
```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

### 2. Upload Backend Code
```bash
# Option A: SCP from local machine
scp -i your-key.pem -r backend/ ubuntu@YOUR_EC2_IP:/opt/lavangam/

# Option B: Clone from repository
cd /opt/lavangam
git clone YOUR_REPOSITORY_URL .
```

### 3. Run Setup Script
```bash
cd /opt/lavangam
chmod +x ec2-setup-complete.sh
./ec2-setup-complete.sh
```

## 🐛 Troubleshooting

### Common Issues

1. **Backend not starting**
   ```bash
   sudo systemctl status lavangam-backend
   sudo journalctl -u lavangam-backend -f
   ```

2. **Database connection failed**
   ```bash
   sudo systemctl status mysql
   mysql -u root -p
   ```

3. **Nginx not working**
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   ```

4. **Port access issues**
   ```bash
   sudo ufw status
   sudo netstat -tlnp
   ```

### Reset Services
```bash
sudo systemctl daemon-reload
sudo systemctl restart lavangam-backend
sudo systemctl restart nginx
sudo systemctl restart mysql
```

## 💰 Cost Optimization

- **Instance Type**: Start with t3.micro for testing, upgrade as needed
- **Storage**: Use GP2 EBS for better performance/cost ratio
- **Reserved Instances**: Consider for production workloads
- **Auto Scaling**: Implement based on traffic patterns

## 🔄 Updates & Maintenance

### Update Backend Code
```bash
cd /opt/lavangam
git pull origin main
sudo systemctl restart lavangam-backend
```

### Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### Backup Database
```bash
mysqldump -u root -p toolinfomation > backup_$(date +%Y%m%d).sql
```

## 📞 Support

If you encounter issues:

1. Check the service status scripts
2. Review system logs
3. Verify security group settings
4. Ensure all ports are accessible

## 🎯 Next Steps

After successful deployment:

1. **Test API endpoints** at `http://YOUR_EC2_IP:8000`
2. **Access phpMyAdmin** to manage your database
3. **Configure domain** (if you have one)
4. **Set up SSL certificates** for HTTPS
5. **Implement monitoring** (CloudWatch, etc.)
6. **Set up backups** for database and files

---

**Happy Deploying! 🚀**

Your Lavangam backend is now running on AWS EC2 with automatic startup, Nginx reverse proxy, phpMyAdmin, and a secure MySQL database.
