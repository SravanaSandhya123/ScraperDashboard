# ✅ LAVANGAM EC2 Deployment Checklist

## 🚀 Pre-Deployment Checklist

- [ ] ✅ EC2 instance created (`13.219.190.100`)
- [ ] ✅ SSH key downloaded (`lavangam-key.pem`)
- [ ] ✅ Security groups configured for all ports
- [ ] ✅ Enhanced setup script ready (`setup-backend-on-ec2-enhanced.sh`)
- [ ] ✅ Health check script ready (`check_services.py`)
- [ ] ✅ Backend code ready for upload

## 🔧 Deployment Steps

### Phase 1: Initial Setup
- [ ] Connect to EC2: `ssh -i lavangam-key.pem ubuntu@13.219.190.100`
- [ ] Upload setup script: `scp -i lavangam-key.pem setup-backend-on-ec2-enhanced.sh ubuntu@13.219.190.100:~/`
- [ ] Make script executable: `chmod +x setup-backend-on-ec2-enhanced.sh`
- [ ] Run setup script: `./setup-backend-on-ec2-enhanced.sh`
- [ ] Wait for completion (15-20 minutes)

### Phase 2: Code Deployment
- [ ] Upload backend code: `scp -i lavangam-key.pem -r backend/* ubuntu@13.219.190.100:~/lavangam-backend/`
- [ ] Set proper permissions: `sudo chown -R ubuntu:ubuntu ~/lavangam-backend`
- [ ] Restart services: `sudo systemctl restart lavangam-backend nginx`

### Phase 3: Verification
- [ ] Check service status: `sudo systemctl status lavangam-backend`
- [ ] Check all ports: `sudo netstat -tlnp | grep -E ':(8000|5022|5024|8004|5025|8001|8002|5020|5021|5023|5001|5002|5005)'`
- [ ] Run health check: `python3 check_services.py`
- [ ] Test external access: `curl http://13.219.190.100/health`

## 🌐 Port Verification Checklist

| Port | Service | Status | Test Command |
|------|---------|--------|--------------|
| 8000 | Main API | ⬜ | `curl http://13.219.190.100/api/` |
| 5022 | Scrapers API | ⬜ | `curl http://13.219.190.100/scrapers/` |
| 5024 | System Usage API | ⬜ | `curl http://13.219.190.100/system/` |
| 8004 | Dashboard API | ⬜ | `curl http://13.219.190.100/dashboard/` |
| 5025 | Admin Metrics API | ⬜ | `curl http://13.219.190.100/admin/` |
| 8001 | Analytics API | ⬜ | `curl http://13.219.190.100/analytics/` |
| 8002 | Additional Analytics | ⬜ | `curl http://13.219.190.100/analytics2/` |
| 5020 | E-Procurement WebSocket | ⬜ | `netstat -tlnp \| grep :5020` |
| 5021 | E-Procurement Server | ⬜ | `curl http://13.219.190.100/eproc/` |
| 5023 | E-Procurement Fixed | ⬜ | `curl http://13.219.190.100/eproc-fixed/` |
| 5001 | File Manager | ⬜ | `curl http://13.219.190.100/files/` |
| 5002 | Export Server | ⬜ | `curl http://13.219.190.100/export/` |
| 5005 | E-Procurement API | ⬜ | `curl http://13.219.190.100/eproc-api/` |

## 🔍 Service Status Checklist

- [ ] MySQL service: `sudo systemctl status mysql`
- [ ] Nginx service: `sudo systemctl status nginx`
- [ ] LAVANGAM Backend: `sudo systemctl status lavangam-backend`
- [ ] Firewall status: `sudo ufw status`
- [ ] All ports listening: `sudo netstat -tlnp`

## 📊 Health Check Results

- [ ] Port availability: All 13 ports open
- [ ] Service health: All endpoints responding
- [ ] Database connectivity: MySQL accessible
- [ ] File permissions: Proper ownership set
- [ ] Log files: No critical errors

## 🚨 Troubleshooting Checklist

If issues occur:

- [ ] Check service logs: `sudo journalctl -u lavangam-backend -f`
- [ ] Verify port conflicts: `sudo lsof -i :8000`
- [ ] Check file permissions: `ls -la ~/lavangam-backend/`
- [ ] Verify firewall: `sudo ufw status`
- [ ] Check resource usage: `htop`, `df -h`

## 🎯 Post-Deployment Tasks

- [ ] Update frontend configuration with new EC2 IP
- [ ] Test all API endpoints from frontend
- [ ] Set up monitoring and alerts
- [ ] Configure SSL certificates
- [ ] Set up automated backups
- [ ] Document deployment process

## 📝 Notes

- **Setup Time**: ~15-20 minutes
- **Memory Usage**: ~2-3GB RAM
- **Disk Space**: ~5-10GB
- **MySQL Password**: `Lavangam2024!` (change in production)
- **SSH Access**: `ssh -i lavangam-key.pem ubuntu@13.219.190.100`

## 🎉 Success Criteria

- [ ] All 13 services running on correct ports
- [ ] External access working from internet
- [ ] Health check script shows all green
- [ ] Frontend can connect to all APIs
- [ ] Database accessible and functional
- [ ] No critical errors in logs

---

**Status**: ⬜ Not Started | 🟡 In Progress | ✅ Completed | ❌ Failed
