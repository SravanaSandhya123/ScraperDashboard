#!/usr/bin/env python3
"""
Render Deployment Entry Point for Lavangam Backend
Consolidates all services under a single endpoint for Render deployment
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# Check Python version first
python_version = sys.version_info
print(f"🐍 Python version: {python_version.major}.{python_version.minor}.{python_version.micro}")

if python_version.major == 3 and python_version.minor >= 13:
    print("⚠️ Warning: Python 3.13+ detected. Some packages may have compatibility issues.")

try:
    from fastapi import FastAPI, Request, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse, HTMLResponse
    import uvicorn
    from supabase import create_client, Client
    import requests
    import json
    import time
    from datetime import datetime
    import asyncio
    import subprocess
    import platform
    import psutil
    import mysql.connector
    from mysql.connector import Error
    import pandas as pd
    from io import BytesIO
    import base64
    import logging
    from typing import Dict, Any, Optional
    import os
    from dotenv import load_dotenv
    
    print("✅ All imports successful!")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Installing missing packages...")
    try:
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements-render.txt"])
        print("Packages installed. Please restart the service.")
    except Exception as install_error:
        print(f"Failed to install packages: {install_error}")
        print("Please check your requirements-render.txt file and build script.")

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="Lavangam Backend API",
    description="Consolidated backend service for Lavangam platform",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Supabase client
supabase_url = os.getenv("SUPABASE_URL", "https://zjfjaezztfydiryzfd.supabase.co")
supabase_key = os.getenv("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqZmphZXp6dGZ5ZGlyeXpzeXZkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTAyNzAyMSwiZXhwIjoyMDY2NjAzMDIxfQ.sRbGz6wbBoMmY8Ol3vEPc4VOh2oEWpcONi9DkUsTpKk")

try:
    supabase: Client = create_client(supabase_url, supabase_key)
    print("✅ Supabase client initialized successfully!")
except Exception as e:
    print(f"⚠️ Supabase initialization warning: {e}")
    supabase = None

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint for Render monitoring"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "lavangam-backend",
        "environment": os.getenv("RENDER_ENVIRONMENT", "production"),
        "python_version": f"{python_version.major}.{python_version.minor}.{python_version.micro}"
    }

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with service information"""
    return {
        "message": "Welcome to Lavangam Backend API",
        "service": "lavangam-backend",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "python_version": f"{python_version.major}.{python_version.minor}.{python_version.micro}"
    }

# AI Assistant endpoint
@app.post("/api/ai-assistant")
async def ai_assistant(request: Request):
    """AI Assistant endpoint using GROQ API"""
    try:
        data = await request.json()
        user_message = data.get("message", "")
        
        # Get API key from environment
        api_key = os.getenv("GROQ_API_KEY") or os.getenv("OPENAI_API_KEY")
        
        if not api_key:
            raise HTTPException(status_code=400, detail="API key not configured")
        
        # For now, return a simple response
        # You can implement actual AI logic here
        response = {
            "message": f"AI Assistant received: {user_message}",
            "timestamp": datetime.now().isoformat(),
            "api_key_configured": bool(api_key)
        }
        
        return JSONResponse(content=response)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI Assistant error: {str(e)}")

# WebDriver test endpoint
@app.get("/test-webdriver")
async def test_webdriver():
    """Test WebDriver functionality"""
    try:
        # Test if WebDriver packages are available
        from webdriver_manager.microsoft import EdgeChromiumDriverManager
        from webdriver_manager.chrome import ChromeDriverManager
        
        return {
            "status": "success",
            "message": "WebDriver packages are available",
            "edge_driver": "EdgeChromiumDriverManager available",
            "chrome_driver": "ChromeDriverManager available",
            "timestamp": datetime.now().isoformat()
        }
        
    except ImportError as e:
        return {
            "status": "warning",
            "message": "WebDriver packages not fully available",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "error",
            "message": "WebDriver test failed",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

# Database test endpoint
@app.get("/test-database")
async def test_database():
    """Test database connectivity"""
    try:
        # Get database credentials from environment
        db_host = os.getenv("DB_HOST", "18.236.173.88")
        db_port = int(os.getenv("DB_PORT", "3306"))
        db_name = os.getenv("DB_NAME", "toolinfomation")
        db_user = os.getenv("DB_USER", "root")
        db_password = os.getenv("DB_PASSWORD", "thanuja")
        
        # Test connection
        connection = mysql.connector.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password
        )
        
        if connection.is_connected():
            cursor = connection.cursor()
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            cursor.close()
            connection.close()
            
            return {
                "status": "success",
                "message": "Database connection successful",
                "version": version[0] if version else "Unknown",
                "timestamp": datetime.now().isoformat()
            }
            
    except Error as e:
        return {
            "status": "error",
            "message": "Database connection failed",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "error",
            "message": "Database test failed",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

# System metrics endpoint
@app.get("/api/system-metrics")
async def system_metrics():
    """Get system metrics"""
    try:
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        
        # Disk usage
        disk = psutil.disk_usage('/')
        
        return {
            "cpu_percent": cpu_percent,
            "memory_percent": memory.percent,
            "memory_available": memory.available,
            "memory_total": memory.total,
            "disk_percent": disk.percent,
            "disk_free": disk.free,
            "disk_total": disk.total,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"System metrics error: {str(e)}")

# Supabase test endpoint
@app.get("/test-supabase")
async def test_supabase():
    """Test Supabase connectivity"""
    try:
        if supabase:
            # Try to get a simple response from Supabase
            response = supabase.table("test").select("*").limit(1).execute()
            return {
                "status": "success",
                "message": "Supabase connection successful",
                "timestamp": datetime.now().isoformat()
            }
        else:
            return {
                "status": "warning",
                "message": "Supabase client not initialized",
                "timestamp": datetime.now().isoformat()
            }
            
    except Exception as e:
        return {
            "status": "error",
            "message": "Supabase test failed",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

if __name__ == "__main__":
    print("🚀 Starting Lavangam Backend on Render...")
    print(f"✅ Environment: {os.getenv('RENDER_ENVIRONMENT', 'production')}")
    print(f"✅ Python Version: {python_version.major}.{python_version.minor}.{python_version.micro}")
    print(f"✅ Supabase URL: {supabase_url}")
    print(f"✅ Database Host: {os.getenv('DB_HOST', '18.236.173.88')}")
    
    # Get port from Render environment
    port = int(os.getenv("PORT", 8000))
    
    # Start the server
    uvicorn.run(
        "render:app",
        host="0.0.0.0",
        port=port,
        reload=False,
        log_level="info"
    )
