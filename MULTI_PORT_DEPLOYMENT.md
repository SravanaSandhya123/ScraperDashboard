# 🚀 Multi-Port Deployment Guide - Lavangam Backend

## 🎯 **Overview**

This guide sets up **ALL your services** to run simultaneously on Render with multiple ports:

- **Port 8000**: Main FastAPI Backend (Primary)
- **Port 5002**: File Manager Flask App
- **Port 5023**: E-Procurement Server
- **Port 5024**: System Usage API
- **Port 8004**: Dashboard API

## 📁 **Files Created**

### 1. **`backend/multi_port_manager.py`** - Local Multi-Port Manager
- Runs all services locally for development
- Auto-restart functionality
- Port availability checking

### 2. **`backend/render_multi_port.py`** - Render Multi-Port Deployment
- Optimized for Render deployment
- Environment variable support
- Service monitoring

### 3. **Updated `render.yaml`** - Render Configuration
- Multi-port environment variables
- Database connection settings
- All service ports configured

## 🔧 **Database Configuration**

### **Remote Database Connection:**
```env
DB_HOST=44.244.61.85
DB_PORT=3306
DB_NAME=Toolinformation
DB_USER=root
DB_PASSWORD=thanuja
```

### **Database URL:**
- **phpMyAdmin**: http://44.244.61.85/phpmyadmin/index.php?route=/&route=%2F&db=Toolinformation
- **Direct MySQL**: 44.244.61.85:3306

## 🚀 **Deployment Steps**

### **1. Push to Git**
```bash
git add .
git commit -m "Add multi-port deployment for all services"
git push origin main
```

### **2. Deploy on Render**
- Go to [dashboard.render.com](https://dashboard.render.com)
- Create new **Web Service**
- Connect your repository
- Render will use `render.yaml` automatically

### **3. Set Environment Variables in Render Dashboard**
```env
# Database Configuration
DB_HOST=44.244.61.85
DB_PORT=3306
DB_NAME=Toolinformation
DB_USER=root
DB_PASSWORD=thanuja

# API Keys (Set these in Render dashboard)
SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
SUPABASE_KEY=your_supabase_key_here
OPENAI_API_KEY=your_openai_key_here
GROQ_API_KEY=your_groq_key_here

# Service Ports
PORT=8000
FILE_MANAGER_PORT=5002
EPROC_SERVER_PORT=5023
SYSTEM_USAGE_PORT=5024
DASHBOARD_API_PORT=8004

# Environment
RENDER_ENVIRONMENT=production
```

## 🌐 **Service URLs After Deployment**

Once deployed, your services will be available at:

```
Main Backend:     https://your-app.onrender.com/ (Port 8000)
File Manager:     https://your-app.onrender.com:5002/
E-Procurement:    https://your-app.onrender.com:5023/
System Usage:     https://your-app.onrender.com:5024/
Dashboard API:    https://your-app.onrender.com:8004/
```

## 📊 **Expected Deployment Logs**

You should see in Render logs:

```
🚀 Lavangam Render Multi-Port Deployment Starting...
🏭 Environment: production
🏠 Database Host: 44.244.61.85

🚀 Starting main_backend on port 8000...
✅ main_backend started on port 8000

🚀 Starting file_manager on port 5002...
✅ file_manager started on port 5002

🚀 Starting eproc_server on port 5023...
✅ eproc_server started on port 5023

🚀 Starting system_usage on port 5024...
✅ system_usage started on port 5024

🚀 Starting dashboard_api on port 8004...
✅ dashboard_api started on port 8004

📊 Service Status:
main_backend        | Port 8000 | 🟢 Running
file_manager        | Port 5002 | 🟢 Running
eproc_server        | Port 5023 | 🟢 Running
system_usage        | Port 5024 | 🟢 Running
dashboard_api       | Port 8004 | 🟢 Running

🌐 Service URLs:
main_backend        | http://0.0.0.0:8000
file_manager        | http://0.0.0.0:5002
eproc_server        | http://0.0.0.0:5023
system_usage        | http://0.0.0.0:5024
dashboard_api       | http://0.0.0.0:8004
```

## 🔍 **Testing Your Deployment**

### **Health Checks:**
```bash
# Main backend health
curl https://your-app.onrender.com/ping

# File manager
curl https://your-app.onrender.com:5002/

# E-procurement
curl https://your-app.onrender.com:5023/

# System usage
curl https://your-app.onrender.com:5024/

# Dashboard API
curl https://your-app.onrender.com:8004/
```

### **Database Connection Test:**
```bash
curl https://your-app.onrender.com/test-database
```

## 🆘 **Troubleshooting**

### **If services don't start:**
1. Check Render logs for import errors
2. Verify all environment variables are set
3. Ensure database is accessible from Render

### **If ports are not accessible:**
1. Render may need time to bind all ports
2. Check if services are actually running
3. Verify port configuration in logs

### **If database connection fails:**
1. Verify database credentials
2. Check if database allows external connections
3. Test connection from Render's servers

## 🎉 **Success Indicators**

- ✅ All 5 services show "🟢 Running" status
- ✅ Health check responds: `{"message": "pong", "status": "ok"}`
- ✅ Database test shows successful connection
- ✅ All service URLs are accessible
- ✅ No "No open ports detected" errors

## 📝 **Local Testing**

To test locally before deploying:

```bash
cd backend
python multi_port_manager.py
```

This will start all services locally with the same configuration.

## 🔄 **Auto-Restart Features**

The deployment includes:
- **Service monitoring** every 30 seconds
- **Auto-restart** if any service crashes
- **Port availability checking**
- **Graceful shutdown handling**

**Your Lavangam Backend will now run ALL services simultaneously on Render!** 🚀
