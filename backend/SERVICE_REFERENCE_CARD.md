# 🚀 Lavangam Backend Services Reference Card

## 📋 Quick Deployment Reference

This card provides all the essential information needed to deploy your 10 backend services to Render.

## 🌐 Service Configuration Summary

| # | Service Name | Port | URL | Start Command | Type |
|---|--------------|------|-----|---------------|------|
| 1 | **lavangam-main-backend** | 8000 | `https://lavangam-main-backend.onrender.com` | `uvicorn backend.main:app --host 0.0.0.0 --port $PORT` | FastAPI |
| 2 | **lavangam-analytics-api** | 8001 | `https://lavangam-analytics-api.onrender.com` | `uvicorn analytics_api:app --host 0.0.0.0 --port $PORT` | FastAPI |
| 3 | **lavangam-dashboard-websocket** | 8002 | `https://lavangam-dashboard-websocket.onrender.com` | `python dashboard_websocket.py` | WebSocket |
| 4 | **lavangam-dashboard-api** | 8004 | `https://lavangam-dashboard-api.onrender.com` | `uvicorn dashboard_api:app --host 0.0.0.0 --port $PORT` | FastAPI |
| 5 | **lavangam-admin-metrics** | 8005 | `https://lavangam-admin-metrics.onrender.com` | `uvicorn admin_metrics_api:app --host 0.0.0.0 --port $PORT` | FastAPI |
| 6 | **lavangam-unified-api** | 8006 | `https://lavangam-unified-api.onrender.com` | `uvicorn unified_api_complete:app --host 0.0.0.0 --port $PORT` | FastAPI |
| 7 | **lavangam-file-manager** | 5002 | `https://lavangam-file-manager.onrender.com` | `python file_manager.py` | Flask |
| 8 | **lavangam-eproc-server** | 5021 | `https://lavangam-eproc-server.onrender.com` | `python eproc_server.py` | Flask |
| 9 | **lavangam-scrapers-api** | 5022 | `https://lavangam-scrapers-api.onrender.com` | `uvicorn backend.scrapers.api:app --host 0.0.0.0 --port $PORT` | FastAPI |
| 10 | **lavangam-system-usage** | 5024 | `https://lavangam-system-usage.onrender.com` | `uvicorn system_usage_api:app --host 0.0.0.0 --port $PORT` | FastAPI |

## 🔧 Common Configuration for All Services

### Build Command
```bash
pip install -r requirements-render.txt
```

### Environment Variables (Set for each service)
```bash
# Required for all services
PORT=8000                    # Set specific port for each service
RENDER_ENVIRONMENT=production

# Database configuration (for services that need it)
DB_HOST=44.244.61.85
DB_PORT=3306
DB_NAME=toolinfomation
DB_USER=root
DB_PASSWORD=thanuja

# API Keys (for services that need them)
SUPABASE_URL=https://zjfjaezztfydiryzfd.supabase.co
SUPABASE_KEY=your-supabase-key
OPENAI_API_KEY=sk-your-openai-key
GROQ_API_KEY=gsk-your-groq-key
SECRET_KEY=your-secret-key

# Flask specific (for Flask services)
FLASK_ENV=production
FLASK_DEBUG=false
```

## 🚀 Deployment Methods

### Method 1: Automatic (Recommended)
1. Use `render-correct.yaml` as Blueprint
2. Render creates all 10 services automatically
3. Fastest and most reliable

### Method 2: Manual
1. Create each service individually
2. More control over configuration
3. Takes longer but allows customization

## 📱 Testing Commands

After deployment, test each service:

```bash
# Test all services
curl https://lavangam-main-backend.onrender.com/
curl https://lavangam-analytics-api.onrender.com/
curl https://lavangam-dashboard-websocket.onrender.com/
curl https://lavangam-dashboard-api.onrender.com/
curl https://lavangam-admin-metrics.onrender.com/
curl https://lavangam-unified-api.onrender.com/
curl https://lavangam-file-manager.onrender.com/
curl https://lavangam-eproc-server.onrender.com/
curl https://lavangam-scrapers-api.onrender.com/
curl https://lavangam-system-usage.onrender.com/
```

## 🔍 Service-Specific Requirements

### FastAPI Services (Ports 8000, 8001, 8004, 8005, 8006, 5022, 5024)
- Use `uvicorn` start command
- Support async operations
- Built-in API documentation

### Flask Services (Ports 5002, 5021)
- Use `python` start command
- Set `FLASK_ENV=production`
- Set `FLASK_DEBUG=false`

### WebSocket Service (Port 8002)
- Uses custom WebSocket implementation
- Handles real-time communication
- No database requirements

## 📊 Port Allocation Strategy

- **8000-8006**: Main API services (FastAPI)
- **5002**: File management service (Flask)
- **5021**: E-procurement service (Flask)
- **5022**: Web scraping service (FastAPI)
- **5024**: System monitoring service (FastAPI)

## 🚨 Important Notes

1. **Port Configuration**: Render automatically sets `$PORT` environment variable
2. **Database Access**: Ensure your AWS MySQL database allows connections from Render
3. **API Keys**: Never commit actual API keys to Git
4. **Free Plan Limits**: Free plan limited to 750 hours/month
5. **Service Dependencies**: Some services depend on database connectivity

## 📚 Quick Links

- **Complete Guide**: `COMPLETE_MULTI_PORT_DEPLOYMENT_GUIDE.md`
- **Deployment Script**: `deploy-multi-port-render.ps1`
- **Package Fixes**: `PACKAGE_FIXES_SUMMARY.md`
- **Environment Template**: `render.env`
- **Requirements**: `requirements-render.txt`
- **Multi-Service Config**: `render-correct.yaml`

## 🎯 Success Indicators

After successful deployment:
- ✅ All 10 services build without errors
- ✅ All services start and respond to requests
- ✅ Database connections work properly
- ✅ API endpoints return expected responses
- ✅ Services handle traffic without errors

---

**🚀 Ready to deploy your multi-service backend infrastructure!**
