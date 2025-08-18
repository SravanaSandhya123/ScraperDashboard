# 🚀 Complete Multi-Port Deployment Guide for Lavangam Backend

## 📋 Overview

This guide will walk you through deploying all 10 Lavangam backend services to Render, each on their designated ports. After deployment, you'll have a fully functional multi-service backend infrastructure.

## 🌐 Final Service URLs (After Deployment)

```
✅ https://lavangam-main-backend.onrender.com (Port 8000)
✅ https://lavangam-analytics-api.onrender.com (Port 8001)
✅ https://lavangam-dashboard-websocket.onrender.com (Port 8002)
✅ https://lavangam-dashboard-api.onrender.com (Port 8004)
✅ https://lavangam-admin-metrics.onrender.com (Port 8005)
✅ https://lavangam-unified-api.onrender.com (Port 8006)
✅ https://lavangam-file-manager.onrender.com (Port 5002)
✅ https://lavangam-eproc-server.onrender.com (Port 5021)
✅ https://lavangam-scrapers-api.onrender.com (Port 5022)
✅ https://lavangam-system-usage.onrender.com (Port 5024)
```

## 🔧 Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com)
2. **Git Repository**: Your backend code should be in a Git repository
3. **Database Access**: Your AWS MySQL database should be accessible from Render
4. **API Keys**: OpenAI, GROQ, and Supabase API keys ready

## 🚀 Step-by-Step Deployment Process

### Step 1: Prepare Your Repository

1. **Ensure all files are committed and pushed:**
   ```bash
   git add .
   git commit -m "Prepare for multi-port Render deployment"
   git push origin main
   ```

2. **Verify these files exist in your repository:**
   - ✅ `requirements-render.txt` (updated with all packages)
   - ✅ `render-correct.yaml` (multi-service configuration)
   - ✅ `render.env` (environment variables template)
   - ✅ All Python service files

### Step 2: Deploy Using render-correct.yaml

#### Option A: Automatic Deployment (Recommended)

1. **Go to Render Dashboard:**
   - Visit [dashboard.render.com](https://dashboard.render.com)
   - Sign in to your account

2. **Create New Blueprint:**
   - Click "New +" → "Blueprint"
   - Connect your Git repository
   - Select the branch (usually `main` or `master`)
   - Render will automatically detect `render-correct.yaml`

3. **Configure Blueprint:**
   - Name: `lavangam-backend-services`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: (Will be set automatically for each service)

4. **Deploy Blueprint:**
   - Click "Create Blueprint Instance"
   - Render will create all 10 services automatically
   - Wait for all services to build and deploy

#### Option B: Manual Service Creation

If automatic deployment doesn't work, create each service manually:

### Step 3: Manual Service Creation (If Needed)

#### Service 1: Main Backend (Port 8000)

1. **Create New Web Service:**
   - Name: `lavangam-main-backend`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=8000
   RENDER_ENVIRONMENT=production
   DB_HOST=44.244.61.85
   DB_PORT=3306
   DB_NAME=toolinfomation
   DB_USER=root
   DB_PASSWORD=thanuja
   SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
   SUPABASE_KEY=your-supabase-key
   OPENAI_API_KEY=sk-your-openai-key
   GROQ_API_KEY=gsk-your-groq-key
   SECRET_KEY=your-secret-key
   ```

#### Service 2: Analytics API (Port 8001)

1. **Create New Web Service:**
   - Name: `lavangam-analytics-api`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn analytics_api:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=8001
   RENDER_ENVIRONMENT=production
   DB_HOST=44.244.61.85
   DB_PORT=3306
   DB_NAME=toolinfomation
   DB_USER=root
   DB_PASSWORD=thanuja
   ```

#### Service 3: Dashboard WebSocket (Port 8002)

1. **Create New Web Service:**
   - Name: `lavangam-dashboard-websocket`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `python dashboard_websocket.py`

2. **Environment Variables:**
   ```
   PORT=8002
   RENDER_ENVIRONMENT=production
   DB_HOST=44.244.61.85
   DB_PORT=3306
   DB_NAME=toolinfomation
   DB_USER=root
   DB_PASSWORD=thanuja
   ```

#### Service 4: Dashboard API (Port 8004)

1. **Create New Web Service:**
   - Name: `lavangam-dashboard-api`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn dashboard_api:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=8004
   RENDER_ENVIRONMENT=production
   DB_HOST=44.244.61.85
   DB_PORT=3306
   DB_NAME=toolinfomation
   DB_USER=root
   DB_PASSWORD=thanuja
   ```

#### Service 5: Admin Metrics (Port 8005)

1. **Create New Web Service:**
   - Name: `lavangam-admin-metrics`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn admin_metrics_api:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=8005
   RENDER_ENVIRONMENT=production
   DB_HOST=44.244.61.85
   DB_PORT=3306
   DB_NAME=toolinfomation
   DB_USER=root
   DB_PASSWORD=thanuja
   ```

#### Service 6: Unified API (Port 8006)

1. **Create New Web Service:**
   - Name: `lavangam-unified-api`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn unified_api_complete:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=8006
   RENDER_ENVIRONMENT=production
   DB_HOST=44.244.61.85
   DB_PORT=3306
   DB_NAME=toolinfomation
   DB_USER=root
   DB_PASSWORD=thanuja
   ```

#### Service 7: File Manager (Port 5002)

1. **Create New Web Service:**
   - Name: `lavangam-file-manager`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `python file_manager.py`

2. **Environment Variables:**
   ```
   PORT=5002
   RENDER_ENVIRONMENT=production
   FLASK_ENV=production
   FLASK_DEBUG=false
   ```

#### Service 8: E-Procurement Server (Port 5021)

1. **Create New Web Service:**
   - Name: `lavangam-eproc-server`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `python eproc_server.py`

2. **Environment Variables:**
   ```
   PORT=5021
   RENDER_ENVIRONMENT=production
   FLASK_ENV=production
   FLASK_DEBUG=false
   ```

#### Service 9: Scrapers API (Port 5022)

1. **Create New Web Service:**
   - Name: `lavangam-scrapers-api`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn backend.scrapers.api:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=5022
   RENDER_ENVIRONMENT=production
   ```

#### Service 10: System Usage API (Port 5024)

1. **Create New Web Service:**
   - Name: `lavangam-system-usage`
   - Environment: `Python 3`
   - Build Command: `pip install -r requirements-render.txt`
   - Start Command: `uvicorn system_usage_api:app --host 0.0.0.0 --port $PORT`

2. **Environment Variables:**
   ```
   PORT=5024
   RENDER_ENVIRONMENT=production
   ```

## 🔍 Step 4: Monitor Deployment

### For Each Service:

1. **Check Build Status:**
   - Monitor build logs for package installation
   - Ensure no import errors occur
   - Verify all dependencies are installed

2. **Check Runtime Status:**
   - Monitor runtime logs for startup errors
   - Verify service is responding on the correct port
   - Check for any database connection issues

3. **Test Service Health:**
   - Visit the service URL to ensure it's running
   - Check if the service responds to basic requests

## 🧪 Step 5: Test All Services

### Test Commands for Each Service:

```bash
# Main Backend (Port 8000)
curl https://lavangam-main-backend.onrender.com/

# Analytics API (Port 8001)
curl https://lavangam-analytics-api.onrender.com/

# Dashboard WebSocket (Port 8002)
curl https://lavangam-dashboard-websocket.onrender.com/

# Dashboard API (Port 8004)
curl https://lavangam-dashboard-api.onrender.com/

# Admin Metrics (Port 8005)
curl https://lavangam-admin-metrics.onrender.com/

# Unified API (Port 8006)
curl https://lavangam-unified-api.onrender.com/

# File Manager (Port 5002)
curl https://lavangam-file-manager.onrender.com/

# E-Procurement Server (Port 5021)
curl https://lavangam-eproc-server.onrender.com/

# Scrapers API (Port 5022)
curl https://lavangam-scrapers-api.onrender.com/

# System Usage API (Port 5024)
curl https://lavangam-system-usage.onrender.com/
```

## 🚨 Common Issues and Solutions

### Issue 1: Port Already in Use
**Solution**: Render automatically handles port assignment. Use `$PORT` in your start commands.

### Issue 2: Import Errors
**Solution**: Ensure `requirements-render.txt` contains all necessary packages.

### Issue 3: Database Connection Failed
**Solution**: Verify environment variables are set correctly and database is accessible.

### Issue 4: Service Not Starting
**Solution**: Check runtime logs for specific error messages.

## 📊 Deployment Checklist

### Before Deployment:
- [ ] All code committed and pushed to Git
- [ ] `requirements-render.txt` updated with all packages
- [ ] `render-correct.yaml` configured correctly
- [ ] Environment variables template ready

### During Deployment:
- [ ] Blueprint created or services created manually
- [ ] All 10 services building successfully
- [ ] No package installation errors
- [ ] All services starting without errors

### After Deployment:
- [ ] All 10 services running and accessible
- [ ] Database connections working
- [ ] API endpoints responding correctly
- [ ] Health checks passing

## 🎯 Success Verification

### All Services Should:
1. ✅ **Build Successfully**: No package installation errors
2. ✅ **Start Without Errors**: No import or runtime errors
3. ✅ **Respond to Requests**: Basic HTTP requests work
4. ✅ **Connect to Database**: Database operations function
5. ✅ **Handle Traffic**: Services can process requests

## 🚀 Next Steps After Deployment

1. **Update Frontend Configuration:**
   - Point your frontend to the new Render backend URLs
   - Update API endpoint configurations

2. **Test All Functionality:**
   - Run comprehensive tests on all services
   - Verify database operations work correctly
   - Test API integrations

3. **Monitor Performance:**
   - Watch for any performance issues
   - Monitor database connection pools
   - Check service response times

4. **Set Up Monitoring:**
   - Configure alerts for service downtime
   - Monitor error rates and response times
   - Set up logging aggregation

## 📚 Additional Resources

- **Package Fixes**: `PACKAGE_FIXES_SUMMARY.md`
- **Environment Setup**: `render.env`
- **Requirements**: `requirements-render.txt`
- **Quick Deploy**: `deploy-to-render-quick.ps1`
- **Package Testing**: `test_packages_render.py`

---

## 🎉 Congratulations!

After following this guide, you'll have successfully deployed all 10 Lavangam backend services to Render, each running on their designated ports with full functionality!

**Your multi-service backend infrastructure is now live and ready to handle production traffic! 🚀**
