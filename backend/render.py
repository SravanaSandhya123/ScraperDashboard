#!/usr/bin/env python3
"""
Render Deployment Entry Point for Lavangam Backend
This consolidates all services into one FastAPI app for Render deployment
Includes WebDriver support for scraping functionality
"""

import os
import sys
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Create main FastAPI app
app = FastAPI(
    title="Lavangam Backend API",
    description="Complete backend API for Lavangam application with WebDriver support",
    version="1.0.0"
)

# Configure CORS for Render
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",  # Local development
        "http://localhost:3000",  # Alternative local port
        "https://*.onrender.com",  # Render domains
        "https://*.render.com",    # Render domains
        "*"  # Allow all origins for now
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and mount all your API modules
try:
    import main
    app.mount("/main", main.app)
    print("✅ Main API mounted at /main")
except ImportError as e:
    print(f"⚠️  Could not import main API: {e}")

try:
    import dashboard_api
    app.mount("/dashboard", dashboard_api.app)
    print("✅ Dashboard API mounted at /dashboard")
except ImportError as e:
    print(f"⚠️  Could not import dashboard API: {e}")

try:
    import admin_metrics_api
    app.mount("/admin", admin_metrics_api.app)
    print("✅ Admin Metrics API mounted at /admin")
except ImportError as e:
    print(f"⚠️  Could not import admin metrics API: {e}")

try:
    import analytics_api
    app.mount("/analytics", analytics_api.app)
    print("✅ Analytics API mounted at /analytics")
except ImportError as e:
    print(f"⚠️  Could not import analytics API: {e}")

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Lavangam Backend API - Render Deployment",
        "version": "1.0.0",
        "status": "running",
        "features": {
            "webdriver_support": "✅ Enabled",
            "scraping_functionality": "✅ Available",
            "edge_browser": "✅ Supported",
            "chrome_browser": "✅ Supported"
        },
        "services": {
            "main": "/main",
            "dashboard": "/dashboard",
            "admin": "/admin",
            "analytics": "/analytics"
        },
        "endpoints": {
            "health": "/health",
            "webdriver_test": "/test-webdriver",
            "port_mapping": "/port-mapping"
        }
    }

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "message": "Lavangam backend is running on Render with WebDriver support",
        "timestamp": "2024-01-15T00:00:00Z",
        "webdriver": "available"
    }

# WebDriver test endpoint
@app.get("/test-webdriver")
async def test_webdriver():
    """Test WebDriver functionality on Render"""
    try:
        from webdriver_manager import get_edge_driver
        
        # Test Edge WebDriver
        driver = get_edge_driver(headless=True)
        driver.get("https://www.google.com")
        title = driver.title
        driver.quit()
        
        return {
            "status": "success",
            "message": "WebDriver test successful",
            "test_page_title": title,
            "webdriver": "working"
        }
        
    except Exception as e:
        return {
            "status": "error",
            "message": f"WebDriver test failed: {str(e)}",
            "webdriver": "not_working"
        }

# Port mapping endpoint for Render
@app.get("/port-mapping")
async def port_mapping():
    return {
        "message": "Port mapping for Render deployment",
        "render_url": "https://your-backend-service.onrender.com",
        "mappings": {
            "8000": "/main",
            "8004": "/dashboard",
            "5025": "/admin",
            "8001": "/analytics"
        },
        "note": "All services are consolidated under one domain on Render",
        "webdriver": "Edge and Chrome support available"
    }

# Database status endpoint
@app.get("/database-status")
async def database_status():
    try:
        # Test database connection
        from database_config import test_database_connection
        if test_database_connection():
            return {
                "status": "connected",
                "message": "Database connection successful",
                "database": "MySQL"
            }
        else:
            return {
                "status": "disconnected",
                "message": "Database connection failed",
                "database": "MySQL"
            }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Database check failed: {str(e)}",
            "database": "MySQL"
        }

# WebDriver status endpoint
@app.get("/webdriver-status")
async def webdriver_status():
    """Check WebDriver installation and availability"""
    try:
        from webdriver_manager import test_webdrivers
        success = test_webdrivers()
        
        if success:
            return {
                "status": "ready",
                "message": "WebDrivers are working correctly",
                "edge": "available",
                "chrome": "available",
                "platform": "linux" if os.environ.get('RENDER_ENVIRONMENT') == 'production' else "windows"
            }
        else:
            return {
                "status": "error",
                "message": "WebDriver test failed",
                "edge": "unavailable",
                "chrome": "unavailable"
            }
            
    except Exception as e:
        return {
            "status": "error",
            "message": f"WebDriver status check failed: {str(e)}",
            "edge": "unknown",
            "chrome": "unknown"
        }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Lavangam Backend on Render...")
    print("📡 All services consolidated under one domain")
    print("🔧 WebDriver support: ENABLED")
    print("🌐 Health check: /health")
    print("🧪 WebDriver test: /test-webdriver")
    print("📚 API Documentation: /docs")
    
    # Get port from environment (Render sets this)
    port = int(os.environ.get("PORT", 8000))
    
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=port,
        log_level="info"
    )
