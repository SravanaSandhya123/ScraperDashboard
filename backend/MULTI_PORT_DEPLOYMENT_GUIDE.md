# Multi-Port Render Deployment Guide

## Overview
This guide explains how to deploy multiple Lavangam backend services on Render, each on different ports.

## Services to Deploy


### Main FastAPI Backend (Port 8000)
- **Service Name**: lavangam-main-backend
- **Script**: render.py
- **Port**: 8000
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


### Analytics API (Port 8001)
- **Service Name**: lavangam-analytics-api
- **Script**: analytics_api.py
- **Port**: 8001
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


### Dashboard API (Port 8004)
- **Service Name**: lavangam-dashboard-api
- **Script**: dashboard_api.py
- **Port**: 8004
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


### E-Procurement Server (Port 5021)
- **Service Name**: lavangam-eproc-server
- **Script**: eproc_server.py
- **Port**: 5021
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


### File Manager Flask App (Port 5002)
- **Service Name**: lavangam-file-manager
- **Script**: file_manager.py
- **Port**: 5002
- **Environment**: RENDER_ENVIRONMENT=production, FLASK_ENV=production


### System Usage API (Port 5024)
- **Service Name**: lavangam-system-usage
- **Script**: system_usage_api.py
- **Port**: 5024
- **Environment**: RENDER_ENVIRONMENT=production


### Scrapers API (Port 5022)
- **Service Name**: lavangam-scrapers-api
- **Script**: scrapers/api.py
- **Port**: 5022
- **Environment**: RENDER_ENVIRONMENT=production


### E-Procurement API (Port 5023)
- **Service Name**: lavangam-eproc-api
- **Script**: eproc_api.py
- **Port**: 5023
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


### Admin Metrics API (Port 8005)
- **Service Name**: lavangam-admin-metrics
- **Script**: admin_metrics_api.py
- **Port**: 8005
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


### Unified API (Port 8006)
- **Service Name**: lavangam-unified-api
- **Script**: unified_api_complete.py
- **Port**: 8006
- **Environment**: RENDER_ENVIRONMENT=production, DB_HOST=44.244.61.85


## Deployment Steps

### 1. Create render.yaml
```bash
python render_multi_port.py --create-yaml
```

### 2. Deploy to Render
```bash
# Option 1: Use Render CLI
render deploy

# Option 2: Use Render Dashboard
# - Go to render.com
# - Create new web service
# - Connect your GitHub repo
# - Use the generated render.yaml
```

### 3. Manual Service Creation (Alternative)
If you prefer to create services manually:

1. Go to render.com dashboard
2. Click "New +" -> "Web Service"
3. Connect your GitHub repository
4. Configure each service:
   - **Name**: lavangam-[service-name]
   - **Environment**: Python
   - **Build Command**: `pip install -r requirements-render.txt`
   - **Start Command**: `python [script-name]`
   - **Port**: [port-number]

### 4. Environment Variables
Set these for each service:
- `PORT`: [service-port]
- `RENDER_ENVIRONMENT`: production
- `DB_HOST`: 44.244.61.85 (if database needed)

## Service URLs
After deployment, your services will be available at:

- **Main FastAPI Backend**: https://lavangam-main-backend.onrender.com
- **Analytics API**: https://lavangam-analytics-api.onrender.com
- **Dashboard API**: https://lavangam-dashboard-api.onrender.com
- **E-Procurement Server**: https://lavangam-eproc-server.onrender.com
- **File Manager Flask App**: https://lavangam-file-manager.onrender.com
- **System Usage API**: https://lavangam-system-usage.onrender.com
- **Scrapers API**: https://lavangam-scrapers-api.onrender.com
- **E-Procurement API**: https://lavangam-eproc-api.onrender.com
- **Admin Metrics API**: https://lavangam-admin-metrics.onrender.com
- **Unified API**: https://lavangam-unified-api.onrender.com

## Testing
Test each service endpoint:
```bash
# Main backend
curl https://lavangam-main-backend.onrender.com/api/admin/supabase-users

# Analytics API
curl https://lavangam-analytics-api.onrender.com/api/system-metrics

# Dashboard API
curl https://lavangam-dashboard-api.onrender.com/api/dashboard
```

## Monitoring
- Check Render dashboard for service status
- Monitor logs for each service
- Set up alerts for service failures

## Troubleshooting
- If a service fails to start, check the logs
- Verify environment variables are set correctly
- Ensure all dependencies are in requirements-render.txt
