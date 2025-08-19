# Manual Deployment Guide for Admin Panel Fixes

## 🎯 Overview
This guide helps you manually apply the admin panel and database fixes to resolve the issues with:
- Database IP address update
- Real-time system resources display
- Merge files database storage
- Admin panel performance improvements

## 📋 Prerequisites
- Access to the AWS server (44.244.61.85)
- Ability to upload files to the server
- Basic knowledge of file editing

## 🔧 Step-by-Step Deployment

### Step 1: Database Configuration Updates

#### 1.1 Update `backend/database_config.py`
Replace the database configuration with:
```python
# Database configuration for AWS MySQL
DATABASE_CONFIG = {
    'host': os.getenv('DB_HOST', '44.244.61.85'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'database': os.getenv('DB_NAME', 'Toolinformation'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'thanuja'),
    'charset': 'utf8mb4'
}
```

#### 1.2 Update `backend/admin_metrics_api.py`
Find the DB_CONFIG section and update:
```python
# Database configuration - Updated to use AWS MySQL
DB_CONFIG = {
    'host': '44.244.61.85',
    'port': 3306,
    'user': 'root',
    'password': 'thanuja',
    'database': 'Toolinformation'
}
```

#### 1.3 Update `backend/database_operations_mysql.py`
Find the `__init__` method and update:
```python
def __init__(self):
    self.host = os.getenv('DB_HOST', '44.244.61.85')
    self.port = int(os.getenv('DB_PORT', '3306'))
    self.user = os.getenv('DB_USER', 'root')
    self.password = os.getenv('DB_PASSWORD', 'thanuja')
    self.database = os.getenv('DB_NAME', 'Toolinformation')
```

### Step 2: Admin Metrics API Improvements

#### 2.1 Add Real-time System Resources Endpoint
Add this new endpoint to `backend/admin_metrics_api.py` after the existing `/system-load` endpoint:

```python
@app.get("/system-resources-realtime")
async def get_system_resources_realtime():
    """Get real-time system resources for immediate display"""
    try:
        # Quick CPU check without interval for immediate response
        cpu_percent = psutil.cpu_percent()
        
        # Memory usage
        memory = psutil.virtual_memory()
        
        # Disk usage
        disk = psutil.disk_usage('/')
        
        return {
            "cpu_percent": round(cpu_percent, 1),
            "memory_percent": round(memory.percent, 1),
            "disk_percent": round((disk.used / disk.total) * 100, 1),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error getting real-time system resources: {e}")
        return {
            "cpu_percent": 0,
            "memory_percent": 0,
            "disk_percent": 0,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }
```

#### 2.2 Update Cache Timeout
Find the cache decorator in `backend/admin_metrics_api.py` and update:
```python
# Cache user data for 5 seconds to reduce Supabase API calls and improve real-time updates
@lru_cache(maxsize=1)
async def get_cached_user_data():
```

#### 2.3 Improve System Load Performance
Update the `/system-load` endpoint to use faster CPU measurement:
```python
# CPU usage with shorter interval for faster response
cpu_percent = psutil.cpu_percent(interval=0.1)
```

### Step 3: Merge Files Database Storage

#### 3.1 Update `backend/eproc_server_mysql.py`
Find the `/api/merge-download/<session_id>` endpoint and replace it with the enhanced version that includes automatic database storage. The key changes are:

1. Add source file tracking
2. Add automatic database storage
3. Add response headers with database status

### Step 4: Frontend Performance Improvements

#### 4.1 Update `src/config/api.ts`
Update the API configuration to use the new IP address:
```typescript
export const API_CONFIG = {
  MAIN_API: window.location.hostname === 'localhost' 
  ? 'http://localhost:8000'
    : 'http://44.244.61.85:8002',
  
  SYSTEM_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8001'
    : 'http://44.244.61.85:8001',
  
  DASHBOARD_API: window.location.hostname === 'localhost' 
    ? 'http://localhost:8004'
    : 'http://44.244.61.85:8002',
  
  WS_MAIN: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : 'ws://44.244.61.85:8002',
  
  WS_DASHBOARD: window.location.hostname === 'localhost'
    ? 'ws://localhost:8002'
    : 'ws://44.244.61.85:8002'
};
```

#### 4.2 Update `src/components/Admin/AdminPanel.tsx`
Add timeout handling and improve real-time updates:
```typescript
// Fetch admin metrics with improved real-time performance
const fetchAdminMetrics = async () => {
  try {
    const timestamp = new Date().getTime();
    const API_BASE_URL = window.location.hostname === 'localhost' 
      ? 'http://localhost:8001'
      : 'http://44.244.61.85:8001';
    
    // Use timeout to prevent hanging requests
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    
    const response = await axios.get<AdminMetrics>(`${API_BASE_URL}/admin-metrics?t=${timestamp}`, {
      signal: controller.signal,
      timeout: 5000
    });
    
    clearTimeout(timeoutId);
    setAdminMetrics(response.data);
    setMetricsError('');
  } catch (err: any) {
    console.error('Failed to fetch admin metrics:', err);
    const errorMessage = err.response?.status 
      ? `API Error: ${err.response.status} - ${err.response.statusText}`
      : err.message || 'Failed to fetch system metrics.';
    setMetricsError(errorMessage);
  }
};
```

#### 4.3 Update Update Intervals
Change the update interval from 3 seconds to 2 seconds:
```typescript
// Set up real-time updates every 2 seconds for faster updates
const metricsInterval = setInterval(fetchAdminMetrics, 2000);
```

#### 4.4 Update `src/components/SystemUsageChart.tsx`
Reduce the update interval:
```typescript
intervalRef.current = window.setInterval(fetchData, 2000);
```

### Step 5: Install Dependencies

Run these commands on the server:
```bash
cd /home/ubuntu/lavangam/backend
pip install psutil pymysql fastapi uvicorn
```

### Step 6: Restart Services

#### 6.1 Stop Existing Services
```bash
sudo systemctl stop lavangam-admin-metrics 2>/dev/null || true
sudo systemctl stop lavangam-backend 2>/dev/null || true
```

#### 6.2 Start Admin Metrics API
```bash
cd /home/ubuntu/lavangam/backend
nohup python start_admin_metrics.py > admin_metrics.log 2>&1 &
```

#### 6.3 Build Frontend
```bash
cd /home/ubuntu/lavangam/src
npm install
npm run build
```

### Step 7: Test the Fixes

#### 7.1 Test Database Connection
```bash
cd /home/ubuntu/lavangam/backend
python -c "import pymysql; conn = pymysql.connect(host='44.244.61.85', port=3306, user='root', password='thanuja', database='Toolinformation'); print('Database connection successful'); conn.close()"
```

#### 7.2 Test Admin Metrics API
```bash
curl http://44.244.35.65:8001/health
curl http://44.244.35.65:8001/system-resources-realtime
```

#### 7.3 Test Admin Panel
Access the admin panel at: `http://44.244.61.85:3000/dashboard`

## 🎯 Expected Results

After applying these fixes, you should see:

1. **Real-time System Resources**: Immediate display without buffering
2. **Database Size**: Accurate real-time tracking (128.0KB with growth)
3. **Active Jobs**: Real-time job queue monitoring (0 active, 0 queued)
4. **Merge Files**: Automatic database storage when merging Excel to CSV
5. **Performance**: Faster response times and better user experience

## 🔍 Verification Checklist

- [ ] Database connection successful to 44.244.61.85
- [ ] Admin metrics API responding on port 8001
- [ ] Real-time system resources updating every 2 seconds
- [ ] Admin panel loading without buffering
- [ ] Merge files functionality storing data in database
- [ ] System resources chart showing live data

## 🆘 Troubleshooting

### Database Connection Issues
- Verify the IP address is correct: `44.244.61.85`
- Check database name: `Toolinformation`
- Ensure MySQL is running on the server

### API Connection Issues
- Check if admin metrics API is running on port 8001
- Verify firewall settings allow port 8001
- Check server logs for errors

### Frontend Issues
- Clear browser cache
- Check browser console for errors
- Verify API endpoints are accessible

## 📞 Support

If you encounter issues during deployment:
1. Check the server logs: `tail -f /home/ubuntu/lavangam/backend/admin_metrics.log`
2. Verify database connectivity
3. Test individual components separately
4. Review the error messages for specific issues 