# 🚀 AWS EC2 Deployment Checklist

## ✅ Pre-Deployment Checklist

- [ ] AWS account ready with EC2 access
- [ ] EC2 instance launched (Ubuntu 22.04 LTS recommended)
- [ ] Security group configured with all required ports
- [ ] Key pair downloaded and accessible
- [ ] Application code ready (backend folder)
- [ ] SSH client ready (Terminal, PuTTY, etc.)

## 🔧 Deployment Steps

### Step 1: Launch EC2 Instance
- [ ] Choose Ubuntu Server 22.04 LTS AMI
- [ ] Select instance type (t3.medium for dev, t3.large+ for prod)
- [ ] Configure security group with these ports:
  - [ ] SSH (22) - Your IP only
  - [ ] HTTP (80) - 0.0.0.0/0
  - [ ] HTTPS (443) - 0.0.0.0/0
  - [ ] Custom TCP (8000) - 0.0.0.0/0
  - [ ] Custom TCP (5002) - 0.0.0.0/0
  - [ ] Custom TCP (5023) - 0.0.0.0/0
  - [ ] Custom TCP (5024) - 0.0.0.0/0
  - [ ] Custom TCP (8004) - 0.0.0.0/0
  - [ ] Custom TCP (5022) - 0.0.0.0/0
  - [ ] Custom TCP (8001) - 0.0.0.0/0
  - [ ] Custom TCP (8002) - 0.0.0.0/0
  - [ ] Custom TCP (5020) - 0.0.0.0/0
  - [ ] Custom TCP (5021) - 0.0.0.0/0
- [ ] Launch instance and note public IP

### Step 2: Connect to EC2
- [ ] SSH into instance: `ssh -i "key.pem" ubuntu@your-ip`
- [ ] Verify connection successful

### Step 3: Upload Application
- [ ] Upload backend folder to EC2
- [ ] Extract/unzip if needed
- [ ] Navigate to backend directory

### Step 4: Run Deployment Script
- [ ] Make script executable: `chmod +x aws_screen_deployment.sh`
- [ ] Run deployment: `./aws_screen_deployment.sh`
- [ ] Wait for completion (15-20 minutes)

### Step 5: Verify Deployment
- [ ] Check services: `./check_services.sh`
- [ ] Monitor services: `./monitor_services.sh`
- [ ] List screen sessions: `screen -ls`
- [ ] Test main endpoint: `curl http://localhost/`

## 🌐 Service Verification

### Port Status Check
- [ ] Port 8000 (Main Backend) - LISTENING
- [ ] Port 5002 (File Manager) - LISTENING
- [ ] Port 5023 (E-Proc Server) - LISTENING
- [ ] Port 5024 (System Usage) - LISTENING
- [ ] Port 8004 (Dashboard API) - LISTENING
- [ ] Port 5022 (Scrapers API) - LISTENING
- [ ] Port 8001 (Analytics API) - LISTENING
- [ ] Port 8002 (Additional Analytics) - LISTENING
- [ ] Port 5020 (E-Proc WebSocket) - LISTENING
- [ ] Port 5021 (E-Proc API) - LISTENING

### Service Endpoints Test
- [ ] Main Backend: `http://your-ip/` ✅
- [ ] File Manager: `http://your-ip/file-manager/` ✅
- [ ] E-Proc Server: `http://your-ip/eproc/` ✅
- [ ] System Usage: `http://your-ip/system/` ✅
- [ ] Dashboard API: `http://your-ip/dashboard/` ✅
- [ ] Scrapers API: `http://your-ip/scrapers/` ✅
- [ ] Analytics API: `http://your-ip/analytics/` ✅
- [ ] Additional Analytics: `http://your-ip/analytics-additional/` ✅
- [ ] E-Proc WebSocket: `http://your-ip/eproc-ws/` ✅
- [ ] E-Proc API: `http://your-ip/eproc-api/` ✅

## 🔒 Security Verification

- [ ] Firewall enabled and configured
- [ ] MySQL secured with strong password
- [ ] Nginx running and accessible
- [ ] SSH access restricted to your IP
- [ ] Environment variables configured

## 📊 System Health Check

- [ ] Memory usage reasonable (<80%)
- [ ] CPU usage normal (<70%)
- [ ] Disk space adequate (>20% free)
- [ ] All services responding
- [ ] No error logs in Nginx

## 🎮 Management Commands

### Essential Commands
```bash
# Start all services
./start_all_services.sh

# Stop all services
./stop_all_services.sh

# Check status
./check_services.sh

# Monitor services
./monitor_services.sh

# List screen sessions
screen -ls

# Connect to service session
screen -r [service-name]
```

### Emergency Commands
```bash
# Kill all services and restart
pkill screen
pkill python3
sleep 5
./start_all_services.sh

# Check all ports at once
netstat -tlnp | grep -E ":8000|:5002|:5023|:5024|:8004|:5022|:8001|:8002|:5020|:5021"
```

## 🚨 Troubleshooting Quick Reference

### Service Won't Start
1. Check logs: `screen -r [service-name]`
2. Check port: `netstat -tlnp | grep :[port]`
3. Restart service: `./start_all_services.sh`

### Port Already in Use
1. Find process: `sudo lsof -i :[port]`
2. Kill process: `sudo kill -9 [PID]`
3. Restart services: `./start_all_services.sh`

### Nginx Issues
1. Check status: `sudo systemctl status nginx`
2. Test config: `sudo nginx -t`
3. Restart: `sudo systemctl restart nginx`

### Screen Issues
1. Kill all: `pkill screen`
2. Start fresh: `./start_all_services.sh`

## 🎯 Success Criteria

Your deployment is successful when:
- [ ] All 10 services running in screen sessions
- [ ] All ports listening and accessible
- [ ] Nginx proxy working correctly
- [ ] Main application accessible at `http://your-ip/`
- [ ] All service endpoints responding
- [ ] No critical errors in logs
- [ ] System resources within normal ranges

## 📝 Post-Deployment Tasks

- [ ] Update environment variables with real API keys
- [ ] Test all service endpoints
- [ ] Set up monitoring alerts (optional)
- [ ] Configure SSL/HTTPS (recommended)
- [ ] Set up backup strategy
- [ ] Document any custom configurations

## 🔄 Maintenance Schedule

- [ ] Weekly: Check service status and logs
- [ ] Monthly: Update system packages
- [ ] Quarterly: Review security settings
- [ ] As needed: Monitor resource usage

---

**🎉 Deployment Complete!** Your Lavangam backend is now running on AWS EC2 with all services managed by screen sessions.

**📞 Need help?** Use the troubleshooting commands above or check the detailed deployment guide.

