# 🚀 COMPLETE RENDER DEPLOYMENT GUIDE FOR LAVANGAM BACKEND

## 🎯 YOUR ACTUAL BACKEND SERVICES & PORTS

Based on your real backend code, here are your **EXACT** services and ports:

| Service | Port | Main File | Command | Type |
|---------|------|-----------|---------|------|
| **Main Backend** | 8000 | `backend/main.py` | `py -m uvicorn backend.main:app --reload --port 8000` | FastAPI |
| **Admin Metrics API** | 8001 | `backend/admin_metrics_api.py` | `uvicorn admin_metrics_api:app --port 8001` | FastAPI |
| **Dashboard WebSocket** | 8002 | `backend/dashboard_websocket.py` | `python dashboard_websocket.py` | WebSocket |
| **Scraper WebSocket** | 5003 | `backend/scraper_ws.py` | `python scraper_ws.py` | Flask-SocketIO |
| **Dashboard API** | 8004 | `backend/dashboard_api.py` | `uvicorn dashboard_api:app --port 8004` | FastAPI |
| **File Manager** | 5002 | `backend/file_manager.py` | `python file_manager.py` | Flask |
| **E-Procurement Server** | 5021 | `backend/eproc_server.py` | `python eproc_server.py` | Flask-SocketIO |
| **Scrapers API** | 5022 | `backend/scrapers/api.py` | `uvicorn backend.scrapers.api:app --port 5022` | FastAPI |
| **System Usage API** | 5024 | `backend/system_usage_api.py` | `uvicorn system_usage_api:app --port 5024` | FastAPI |

## 🚀 STEP-BY-STEP DEPLOYMENT PROCESS

### **Step 1: Use the Correct render.yaml**

I've created `render-correct.yaml` with your actual services. **Use this file instead of the old one!**

### **Step 2: Deploy Using Render Dashboard (Recommended)**

1. **Go to [render.com](https://render.com) and sign in**

2. **Connect Your GitHub Repository**
   - Click "New +" → "Blueprint"
   - Select "Build and deploy from a Git repository"
   - Connect your GitHub account
   - Select your `lavangam` repository

3. **Deploy Using render-correct.yaml**
   - Upload the `render-correct.yaml` file
   - Click "Apply" to deploy all 9 services

### **Step 3: Manual Service Creation (Alternative)**

If you prefer manual creation, create each service individually:

#### **Service 1: Main Backend (Port 8000)**
- **Name**: `lavangam-main-backend`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
- **Port**: 8000

#### **Service 2: Admin Metrics API (Port 8001)**
- **Name**: `lavangam-admin-metrics`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `uvicorn admin_metrics_api:app --host 0.0.0.0 --port $PORT`
- **Port**: 8001

#### **Service 3: Dashboard WebSocket (Port 8002)**
- **Name**: `lavangam-dashboard-websocket`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `python dashboard_websocket.py`
- **Port**: 8002

#### **Service 4: Scraper WebSocket (Port 5003)**
- **Name**: `lavangam-scraper-websocket`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `python scraper_ws.py`
- **Port**: 5003

#### **Service 5: Dashboard API (Port 8004)**
- **Name**: `lavangam-dashboard-api`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `uvicorn dashboard_api:app --host 0.0.0.0 --port $PORT`
- **Port**: 8004

#### **Service 6: File Manager (Port 5002)**
- **Name**: `lavangam-file-manager`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `python file_manager.py`
- **Port**: 5002

#### **Service 7: E-Procurement Server (Port 5021)**
- **Name**: `lavangam-eproc-server`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `python eproc_server.py`
- **Port**: 5021

#### **Service 8: Scrapers API (Port 5022)**
- **Name**: `lavangam-scrapers-api`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `uvicorn backend.scrapers.api:app --host 0.0.0.0 --port $PORT`
- **Port**: 5022

#### **Service 9: System Usage API (Port 5024)**
- **Name**: `lavangam-system-usage`
- **Environment**: Python
- **Build Command**: `pip install -r requirements-render.txt`
- **Start Command**: `uvicorn system_usage_api:app --host 0.0.0.0 --port $PORT`
- **Port**: 5024

### **Step 4: Environment Variables Setup**

Set these for each service in Render dashboard:

```bash
# For FastAPI services (8000, 8001, 8002, 8004, 5022, 5024):
PORT=[service-port]
RENDER_ENVIRONMENT=production
DB_HOST=44.244.61.85
DB_USER=[your-db-user]
DB_PASSWORD=[your-db-password]
DB_NAME=[your-db-name]

# For Flask services (5002, 5003, 5021):
PORT=[service-port]
RENDER_ENVIRONMENT=production
FLASK_ENV=production
```

### **Step 5: Verify Deployment**

After deployment, test each service:

```bash
# Main Backend (8000)
curl https://lavangam-main-backend.onrender.com/docs

# Admin Metrics API (8001)
curl https://lavangam-admin-metrics.onrender.com/docs

# Dashboard WebSocket (8002)
curl https://lavangam-dashboard-websocket.onrender.com/

# Scraper WebSocket (5003)
curl https://lavangam-scraper-websocket.onrender.com/

# Dashboard API (8004)
curl https://lavangam-dashboard-api.onrender.com/docs

# File Manager (5002)
curl https://lavangam-file-manager.onrender.com/

# E-Procurement Server (5021)
curl https://lavangam-eproc-server.onrender.com/api/health

# Scrapers API (5022)
curl https://lavangam-scrapers-api.onrender.com/docs

# System Usage API (5024)
curl https://lavangam-system-usage.onrender.com/api/system-usage
```

## 🔧 CRITICAL CONFIGURATION FIXES

### **1. Fix Port Binding Issues**

Your current commands use `--reload` and `127.0.0.1` which won't work on Render. Use:

```bash
# Instead of: uvicorn backend.main:app --reload --port 8000
# Use: uvicorn backend.main:app --host 0.0.0.0 --port $PORT

# Instead of: python -m uvicorn dashboard_api:app --host 127.0.0.1 --port 8004
# Use: uvicorn dashboard_api:app --host 0.0.0.0 --port $PORT
```

### **2. Environment Variable Usage**

Always use `$PORT` in start commands, not hardcoded ports:

```bash
# ✅ Correct
uvicorn backend.main:app --host 0.0.0.0 --port $PORT

# ❌ Wrong
uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

### **3. Host Binding**

Use `0.0.0.0` to bind to all interfaces:

```bash
# ✅ Correct
uvicorn app:app --host 0.0.0.0 --port $PORT

# ❌ Wrong
uvicorn app:app --host 127.0.0.1 --port $PORT
```

## 🚨 TROUBLESHOOTING

### **Service Won't Start**
1. Check logs in Render dashboard
2. Verify `requirements-render.txt` has all dependencies
3. Ensure start commands use `$PORT` and `0.0.0.0`

### **Port Conflicts**
1. Each service must use different ports
2. Verify `PORT` environment variable is set correctly
3. Check for hardcoded ports in start commands

### **Database Connection Issues**
1. Verify `DB_HOST=44.244.61.85` is accessible
2. Check firewall settings
3. Ensure database credentials are correct

## 💡 OPTIMIZATION TIPS

1. **Use Free Tier Wisely**: Render free tier has limitations
2. **Optimize Dependencies**: Remove unused packages from requirements
3. **Implement Health Checks**: Add `/health` endpoints to all services
4. **Database Connection Pooling**: Optimize database connections
5. **Static File Serving**: Use CDN for static assets

## 🌐 FINAL SERVICE URLs

After deployment, your services will be available at:

- **Main Backend**: `https://lavangam-main-backend.onrender.com`
- **Admin Metrics API**: `https://lavangam-admin-metrics.onrender.com`
- **Dashboard WebSocket**: `https://lavangam-dashboard-websocket.onrender.com`
- **Scraper WebSocket**: `https://lavangam-scraper-websocket.onrender.com`
- **Dashboard API**: `https://lavangam-dashboard-api.onrender.com`
- **File Manager**: `https://lavangam-file-manager.onrender.com`
- **E-Procurement Server**: `https://lavangam-eproc-server.onrender.com`
- **Scrapers API**: `https://lavangam-scrapers-api.onrender.com`
- **System Usage API**: `https://lavangam-system-usage.onrender.com`

## 🚀 QUICK DEPLOYMENT COMMAND

```bash
# In your backend directory
cd backend

# Use the correct render.yaml
# Upload render-correct.yaml to Render dashboard
# Or use Render CLI:
render deploy --file render-correct.yaml
```

## ✅ CHECKLIST BEFORE DEPLOYMENT

- [ ] All 9 services have unique ports
- [ ] Start commands use `$PORT` and `0.0.0.0`
- [ ] `requirements-render.txt` has all dependencies
- [ ] Environment variables are configured
- [ ] Database connection details are correct
- [ ] No hardcoded ports in start commands
- [ ] All services have health check endpoints

Your backend is now properly configured for Render deployment! 🎉
