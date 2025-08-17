# 🚀 AWS EC2 Deployment Guide with Screen

## Overview
This guide will help you deploy your Lavangam backend application on AWS EC2 using `screen` to run all services in the background on different ports.

## 🎯 What This Deployment Achieves
- **10 different services** running on separate ports
- **Screen sessions** for each service (runs in background)
- **Nginx reverse proxy** for unified access
- **Auto-start** on system reboot
- **Monitoring and management** scripts
- **Firewall security** configuration

## 📋 Prerequisites
- AWS Account with EC2 access
- Basic knowledge of AWS EC2
- SSH client (PuTTY, Terminal, etc.)
- Your application code ready

## 🔧 Step-by-Step Deployment

### Step 1: Launch EC2 Instance

1. **Go to AWS Console** → EC2 → Launch Instance
2. **Choose AMI**: Ubuntu Server 22.04 LTS (recommended)
3. **Instance Type**: 
   - Development: `t3.medium` (2 vCPU, 4GB RAM)
   - Production: `t3.large` (2 vCPU, 8GB RAM) or higher
4. **Key Pair**: Create or select existing key pair
5. **Security Group**: Create new with these rules:
   ```
   SSH (22) - Your IP
   HTTP (80) - 0.0.0.0/0
   HTTPS (443) - 0.0.0.0/0
   Custom TCP (8000) - 0.0.0.0/0
   Custom TCP (5002) - 0.0.0.0/0
   Custom TCP (5023) - 0.0.0.0/0
   Custom TCP (5024) - 0.0.0.0/0
   Custom TCP (8004) - 0.0.0.0/0
   Custom TCP (5022) - 0.0.0.0/0
   Custom TCP (8001) - 0.0.0.0/0
   Custom TCP (8002) - 0.0.0.0/0
   Custom TCP (5020) - 0.0.0.0/0
   Custom TCP (5021) - 0.0.0.0/0
   ```

### Step 2: Connect to Your EC2 Instance

```bash
# Replace with your key file and instance IP
ssh -i "your-key.pem" ubuntu@your-ec2-public-ip
```

### Step 3: Upload Your Application

#### Option A: Using SCP (from your local machine)
```bash
# Create a zip of your backend folder
cd /path/to/your/project
zip -r backend.zip backend/

# Upload to EC2
scp -i "your-key.pem" backend.zip ubuntu@your-ec2-public-ip:~/
```

#### Option B: Using Git (if your code is in a repository)
```bash
# On EC2 instance
sudo apt update
sudo apt install git -y
git clone https://github.com/yourusername/your-repo.git
cd your-repo
```

### Step 4: Run the Deployment Script

```bash
# Make the script executable
chmod +x aws_screen_deployment.sh

# Run the deployment script
./aws_screen_deployment.sh
```

**What the script does automatically:**
- ✅ Updates system packages
- ✅ Installs Python, Node.js, MySQL, Nginx, Screen
- ✅ Sets up MySQL database
- ✅ Creates Python virtual environment
- ✅ Installs all Python dependencies
- ✅ Creates environment configuration
- ✅ Sets up Screen sessions for all services
- ✅ Configures Nginx reverse proxy
- ✅ Sets up firewall rules
- ✅ Creates management scripts
- ✅ Starts all services

### Step 5: Verify Deployment

```bash
# Check if all services are running
./check_services.sh

# Monitor services
./monitor_services.sh

# List screen sessions
screen -ls
```

## 🎮 Managing Your Services

### Start All Services
```bash
./start_all_services.sh
```

### Stop All Services
```bash
./stop_all_services.sh
```

### Check Service Status
```bash
./check_services.sh
```

### Monitor Services
```bash
./monitor_services.sh
```

### View Service Logs
```bash
# List all screen sessions
screen -ls

# Connect to a specific service session
screen -r main-backend
screen -r file-manager
screen -r eproc-server
# etc.

# To detach from screen session: Ctrl+A, then D
```

## 🌐 Accessing Your Services

### Main Application
- **URL**: `http://your-ec2-public-ip/`
- **Port**: 8000 (Main Backend)

### Individual Services
- **File Manager**: `http://your-ec2-public-ip/file-manager/` (Port 5002)
- **E-Procurement**: `http://your-ec2-public-ip/eproc/` (Port 5023)
- **System Usage**: `http://your-ec2-public-ip/system/` (Port 5024)
- **Dashboard API**: `http://your-ec2-public-ip/dashboard/` (Port 8004)
- **Scrapers API**: `http://your-ec2-public-ip/scrapers/` (Port 5022)
- **Analytics API**: `http://your-ec2-public-ip/analytics/` (Port 8001)
- **Additional Analytics**: `http://your-ec2-public-ip/analytics-additional/` (Port 8002)
- **E-Proc WebSocket**: `http://your-ec2-public-ip/eproc-ws/` (Port 5020)
- **E-Proc API**: `http://your-ec2-public-ip/eproc-api/` (Port 5021)

## 🔍 Troubleshooting

### Service Not Starting
```bash
# Check service logs
screen -r [service-name]

# Check if port is in use
sudo netstat -tlnp | grep :[port-number]

# Restart specific service
screen -S [service-name] -X quit
# Then restart using start_all_services.sh
```

### Port Already in Use
```bash
# Find process using port
sudo lsof -i :[port-number]

# Kill process
sudo kill -9 [process-id]
```

### Screen Session Issues
```bash
# Kill all screen sessions
pkill screen

# Start fresh
./start_all_services.sh
```

### Nginx Issues
```bash
# Check Nginx status
sudo systemctl status nginx

# Check Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

## 🔒 Security Considerations

### Update Environment Variables
```bash
# Edit the .env file
nano .env

# Update with your actual API keys
GROQ_API_KEY=your_actual_groq_key
OPENAI_API_KEY=your_actual_openai_key
```

### Firewall Rules
- Only necessary ports are open
- SSH access restricted to your IP
- All services run behind Nginx proxy

### Database Security
- MySQL secured with strong password
- Database only accessible from localhost
- Regular backups recommended

## 📊 Monitoring and Maintenance

### System Resources
```bash
# Check system resources
htop
df -h
free -h
```

### Service Logs
```bash
# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# View system logs
sudo journalctl -u lavangam.service -f
```

### Regular Maintenance
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Restart services after updates
./stop_all_services.sh
./start_all_services.sh
```

## 🚀 Performance Optimization

### For High Traffic
- Use larger instance types (t3.large, t3.xlarge)
- Enable Nginx caching
- Use CDN for static files
- Monitor and scale based on usage

### Database Optimization
- Regular MySQL optimization
- Monitor slow queries
- Consider read replicas for heavy loads

## 📞 Support Commands

### Quick Status Check
```bash
# All in one status check
echo "=== SCREEN SESSIONS ===" && screen -ls && echo -e "\n=== PORT STATUS ===" && netstat -tlnp | grep -E ":8000|:5002|:5023|:5024|:8004|:5022|:8001|:8002|:5020|:5021" && echo -e "\n=== MEMORY ===" && free -h
```

### Emergency Restart
```bash
# Kill everything and restart
pkill screen
pkill python3
sleep 5
./start_all_services.sh
```

## 🎉 Success Indicators

Your deployment is successful when:
- ✅ All 10 services are running in screen sessions
- ✅ All ports are listening (8000, 5002, 5023, 5024, 8004, 5022, 8001, 8002, 5020, 5021)
- ✅ Nginx is running and accessible
- ✅ You can access `http://your-ec2-ip/`
- ✅ All service endpoints respond correctly
- ✅ MySQL database is accessible
- ✅ Firewall is configured and active

## 🔄 Auto-Start on Reboot

Your services will automatically start on system reboot because:
- Systemd service is enabled
- All dependencies are configured
- Screen sessions are managed by systemd

## 📚 Additional Resources

- [Screen Manual](https://www.gnu.org/software/screen/manual/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

---

**🎯 Key Benefits of This Deployment:**
1. **Screen Sessions**: All services run in background, survive SSH disconnections
2. **Multiple Ports**: Each service runs on its dedicated port
3. **Unified Access**: Single domain/IP with route-based service access
4. **Auto-Recovery**: Services restart automatically on failures
5. **Easy Management**: Simple scripts to start/stop/monitor all services
6. **Production Ready**: Includes monitoring, logging, and security
7. **Scalable**: Easy to add more services or scale existing ones

**🚀 Ready to deploy? Run the script and enjoy your production-ready backend!**




