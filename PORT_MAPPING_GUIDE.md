# Port Mapping Guide - All Ports to AWS

## 🚀 **Complete Port Mapping Solution**

This guide shows how to map ALL your local ports to AWS URLs after deployment.

## 📊 **Port to AWS URL Mapping**

### **Before (Local Development):**
```
http://127.0.0.1:8000  → Main API
http://127.0.0.1:5022  → Scrapers API  
http://127.0.0.1:5024  → System Usage API
http://127.0.0.1:8004  → Dashboard API
http://127.0.0.1:5002  → Service 5002
http://127.0.0.1:5003  → Service 5003
http://127.0.0.1:8001  → Service 8001
http://127.0.0.1:5021  → Service 5021
http://127.0.0.1:5023  → Service 5023
http://127.0.0.1:8002  → Service 8002
```

### **After (AWS Deployment):**
```
http://18.236.173.88:8000      → Main API (Port 8000)
http://18.236.173.88:5022      → Scrapers API (Port 5022)
http://18.236.173.88:5024      → System API (Port 5024)
http://18.236.173.88:8004      → Dashboard API (Port 8004)
http://18.236.173.88:5025      → Admin Metrics API (Port 5025)
http://18.236.173.88:8001      → Analytics API (Port 8001)
http://18.236.173.88:8002      → Additional Analytics (Port 8002)
http://18.236.173.88:5020      → E-Procurement WebSocket (Port 5020)
http://18.236.173.88:5021      → E-Procurement Server (Port 5021)
http://18.236.173.88:5023      → E-Procurement Fixed (Port 5023)
http://18.236.173.88:5001      → File Manager (Port 5001)
http://18.236.173.88:5002      → Export Server (Port 5002)
http://18.236.173.88:5005      → E-Procurement API (Port 5005)
```

## 🔧 **Frontend Configuration Update**

### **Update your frontend API configuration:**

```typescript
// src/config/api.ts
const API_CONFIG = {
  // Main API base URL - Updated to use AWS EC2 instance
  MAIN_API: window.location.hostname === 'localhost' 
  ? 'http://localhost:8000'
    : 'http://18.236.173.88:8000',
  
  // System metrics API
  SYSTEM_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8001'
    : 'http://18.236.173.88:8001',
  
  // Dashboard API
  DASHBOARD_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8004'
    : 'http://18.236.173.88:8004',
  
  // WebSocket URLs
  WS_MAIN: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : 'ws://18.236.173.88:8002',
  
  WS_DASHBOARD: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : 'ws://18.236.173.88:8002'
};
```

## 🌐 **AWS Access URLs**

### **Direct Port Access:**
- **Main API**: http://18.236.173.88:8000
- **Scrapers API**: http://18.236.173.88:5022
- **System Usage API**: http://18.236.173.88:5024
- **Dashboard API**: http://18.236.173.88:8004
- **Admin Metrics API**: http://18.236.173.88:5025
- **Analytics API**: http://18.236.173.88:8001
- **Additional Analytics**: http://18.236.173.88:8002
- **E-Procurement WebSocket**: ws://18.236.173.88:5020
- **E-Procurement Server**: http://18.236.173.88:5021
- **E-Procurement Fixed**: http://18.236.173.88:5023
- **File Manager**: http://18.236.173.88:5001
- **Export Server**: http://18.236.173.88:5002
- **E-Procurement API**: http://18.236.173.88:5005

### **Health Check Endpoints:**
- **Main API Health**: http://18.236.173.88:8000/health
- **Scrapers API Health**: http://18.236.173.88:5022/health
- **System API Health**: http://18.236.173.88:5024/health
- **Dashboard API Health**: http://18.236.173.88:8004/health
- **Admin Metrics Health**: http://18.236.173.88:5025/health
- **Analytics API Health**: http://18.236.173.88:8001/health

## 🔒 **Security Considerations**

### **AWS Security Groups:**
Make sure your EC2 security group allows inbound traffic on these ports:
- **HTTP (80)**: For web access
- **HTTPS (443)**: For secure web access
- **Custom TCP (8000)**: Main API
- **Custom TCP (5022)**: Scrapers API
- **Custom TCP (5024)**: System Usage API
- **Custom TCP (8004)**: Dashboard API
- **Custom TCP (5025)**: Admin Metrics API
- **Custom TCP (8001)**: Analytics API
- **Custom TCP (8002)**: Additional Analytics
- **Custom TCP (5020-5023)**: E-Procurement services
- **Custom TCP (5001-5005)**: File and Export services

### **Firewall Rules:**
```bash
# Example AWS CLI commands to update security groups
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 8000 \
  --cidr 0.0.0.0/0

# Repeat for all your ports
```

## 📱 **Mobile and External Access**

### **Before (Local Development):**
- ❌ Mobile can't access `localhost:8000`
- ❌ Mobile can't access `127.0.0.1:5022`
- ❌ External devices can't connect

### **After (AWS Deployment):**
- ✅ Mobile can access `http://18.236.173.88:8000`
- ✅ Mobile can access `http://18.236.173.88:5022`
- ✅ External devices can connect from anywhere
- ✅ Your app works on all devices and networks

## 🚀 **Deployment Steps**

1. **Update Frontend Configuration** (Already done above)
2. **Deploy Backend to AWS EC2**
3. **Configure Security Groups** for all ports
4. **Test All Endpoints** from external devices
5. **Update Mobile Apps** to use AWS URLs

## 🔍 **Testing Your AWS Deployment**

### **Test from External Device:**
```bash
# Test main API
curl http://18.236.173.88:8000/health

# Test scrapers API
curl http://18.236.173.88:5022/health

# Test system API
curl http://18.236.173.88:5024/health

# Test dashboard API
curl http://18.236.173.88:8004/health
```

### **Test from Mobile Browser:**
- Navigate to `http://18.236.173.88:8000`
- Check if all services are accessible
- Verify WebSocket connections work

## 📋 **Summary**

You now have:
- ✅ **All backend ports mapped to AWS IP**: `18.236.173.88`
- ✅ **Frontend configuration updated** for AWS deployment
- ✅ **Complete port mapping guide** for all services
- ✅ **Security group configuration** for all ports
- ✅ **Mobile and external access** enabled

**Next Steps:**
1. Deploy your backend to AWS EC2
2. Configure security groups for all ports
3. Test all endpoints from external devices
4. Your app will work everywhere! 🌍 