# 🚀 LAVANGAM Backend EC2 Deployment Guide

## 📋 Overview

This guide will help you deploy ALL your backend services on your EC2 instance with their specific ports:
- **Main API**: Port 8000
- **Scrapers API**: Port 5022
- **System Usage API**: Port 5024
- **Dashboard API**: Port 8004
- **Admin Metrics API**: Port 5025
- **Analytics API**: Port 8001
- **Additional Analytics**: Port 8002
- **E-Procurement WebSocket**: Port 5020
- **E-Procurement Server**: Port 5021
- **E-Procurement Fixed**: Port 5023
- **File Manager**: Port 5001
- **Export Server**: Port 5002
- **E-Procurement API**: Port 5005

## 🔑 Prerequisites

- ✅ EC2 Instance Created: `13.219.190.100`
- ✅ SSH Key: `lavangam-key.pem`
- ✅ Instance Type: `t3.medium`

## 🚀 Step-by-Step Deployment

### Step 1: Connect to Your EC2 Instance

```bash
# Connect via SSH
ssh -i lavangam-key.pem ubuntu@13.219.190.100
```

### Step 2: Upload the Setup Script

From your local machine, upload the enhanced setup script:

```bash
# From your local machine
scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/
```

### Step 3: Run the Setup Script

```bash
# On the EC2 instance
chmod +x setup-backend-on-ec2-enhanced.sh
./setup-backend-on-ec2-enhanced.sh
```

The script will automatically:
- 📦 Update system packages
- 🗄️ Install and configure MySQL
- 🔥 Configure firewall for ALL your ports
- 🐍 Set up Python environment
- 📝 Create service configurations
- 🔧 Set up systemd services
- 🌐 Configure Nginx with ALL your ports
- 🚀 Start all services

### Step 4: Upload Your Backend Code

After the setup is complete, upload your backend code:

```bash
# From your local machine
scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/
```

### Step 5: Restart Services

```bash
# On the EC2 instance
sudo systemctl restart lavangam-backend
sudo systemctl restart nginx
```

## 🔍 Verification

### Check Service Status

```bash
# Check if all services are running
sudo systemctl status lavangam-backend

# Check all your ports
sudo netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|8001|8002|5020|5021|5023|5001|5002|5005)'

# Run health check
cd ~/lavangam-backend
source venv/bin/activate
python check_services.py
```

### Test Endpoints

```bash
# Test health endpoint
curl http://13.219.190.100/health

# Test main API
curl http://13.219.190.100/api/

# Test scrapers API
curl http://13.219.190.100/scrapers/
```

## 🌐 Access URLs

After deployment, your services will be accessible at:

| Service | Internal Port | External URL |
|---------|---------------|--------------|
| Main API | 8000 | `http://13.219.190.100/api/` |
| Scrapers API | 5022 | `http://13.219.190.100/scrapers/` |
| System Usage API | 5024 | `http://13.219.190.100/system/` |
| Dashboard API | 8004 | `http://13.219.190.100/dashboard/` |
| Admin Metrics API | 5025 | `http://13.219.190.100/admin/` |
| Analytics API | 8001 | `http://13.219.190.100/analytics/` |
| Additional Analytics | 8002 | `http://13.219.190.100/analytics2/` |
| E-Procurement | 5021 | `http://13.219.190.100/eproc/` |
| File Manager | 5001 | `http://13.219.190.100/files/` |
| Export Server | 5002 | `http://13.219.190.100/export/` |
| E-Procurement API | 5005 | `http://13.219.190.100/eproc-api/` |

## 🔧 Management Commands

### Service Management

```bash
# Start all services
sudo systemctl start lavangam-backend

# Stop all services
sudo systemctl stop lavangam-backend

# Restart all services
sudo systemctl restart lavangam-backend

# Check status
sudo systemctl status lavangam-backend

# View logs
sudo journalctl -u lavangam-backend -f
```

### Health Monitoring

```bash
# Check all services health
cd ~/lavangam-backend
source venv/bin/activate
python check_services.py
```

### Database Management

```bash
# Access MySQL
mysql -u lavangam_user -p lavangam_db

# Check database status
sudo systemctl status mysql
```

## 📊 Monitoring

### Check Resource Usage

```bash
# Check CPU and memory
htop

# Check disk usage
df -h

# Check running processes
ps aux | grep python
```

### Check Logs

```bash
# Backend logs
sudo journalctl -u lavangam-backend -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# MySQL logs
sudo tail -f /var/log/mysql/error.log
```

## 🚨 Troubleshooting

### Common Issues

1. **Service not starting**
   ```bash
   sudo systemctl status lavangam-backend
   sudo journalctl -u lavangam-backend -n 50
   ```

2. **Port already in use**
   ```bash
   sudo netstat -tlnp | grep :8000
   sudo lsof -i :8000
   ```

3. **Permission issues**
   ```bash
   sudo chown -R ubuntu:ubuntu ~/lavangam-backend
   sudo chmod -R 755 ~/lavangam-backend
   ```

4. **Firewall issues**
   ```bash
   sudo ufw status
   sudo ufw allow 8000
   ```

### Reset Services

```bash
# Complete reset
sudo systemctl stop lavangam-backend
sudo systemctl stop nginx
sudo systemctl stop mysql

sudo systemctl start mysql
sudo systemctl start nginx
sudo systemctl start lavangam-backend
```

## 🔐 Security Notes

- **MySQL**: Root password is `Lavangam2024!` - change this in production
- **Firewall**: Only necessary ports are open
- **SSH**: Key-based authentication only
- **Services**: Running as `ubuntu` user

## 📞 Support

If you encounter issues:

1. Check the service status: `sudo systemctl status lavangam-backend`
2. View logs: `sudo journalctl -u lavangam-backend -f`
3. Check port availability: `sudo netstat -tlnp`
4. Verify firewall: `sudo ufw status`

## 🎯 Next Steps

After successful deployment:

1. ✅ Test all endpoints
2. ✅ Update your frontend configuration
3. ✅ Set up monitoring and alerts
4. ✅ Configure SSL certificates
5. ✅ Set up automated backups
6. ✅ Monitor performance metrics

---

**🎉 Congratulations!** Your LAVANGAM backend is now running on EC2 with ALL your services and ports!
