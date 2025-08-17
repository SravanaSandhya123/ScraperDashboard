#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Render-specific startup script for Lavangam Backend
Handles port binding and environment setup
"""

import os
import sys
import uvicorn
from pathlib import Path

print("🚀 Lavangam Backend - Render Startup")

# Add the backend directory to Python path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# Import the FastAPI app
try:
    from render import app
    print("✅ FastAPI app imported successfully")
except ImportError as e:
    print(f"❌ Failed to import app: {e}")
    sys.exit(1)

def get_port():
    """Get port from environment with fallbacks"""
    # Try multiple environment variables
    port_vars = ["PORT", "RENDER_PORT", "WEB_PORT"]
    
    for var in port_vars:
        port = os.getenv(var)
        if port:
            try:
                return int(port)
            except ValueError:
                print(f"⚠️ Invalid port in {var}: {port}")
    
    # Fallback ports
    fallback_ports = [8000, 8080, 3000, 5000]
    
    for port in fallback_ports:
        print(f"🔄 Trying fallback port: {port}")
        return port
    
    return 8000  # Final fallback

def main():
    """Main startup function"""
    # Get port
    port = get_port()
    print(f"🌐 Using port: {port}")
    
    # Get host
    host = os.getenv("HOST", "0.0.0.0")
    print(f"🏠 Using host: {host}")
    
    # Environment info
    env = os.getenv("RENDER_ENVIRONMENT", "production")
    print(f"🏭 Environment: {env}")
    
    # Print startup info
    print("=" * 50)
    print("🚀 Starting Lavangam Backend Server")
    print(f"🌐 URL: http://{host}:{port}")
    print(f"🏭 Environment: {env}")
    print(f"📊 Health Check: http://{host}:{port}/health")
    print("=" * 50)
    
    try:
        # Start the server
        uvicorn.run(
            app,
            host=host,
            port=port,
            log_level="info",
            access_log=True
        )
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        print("🔍 Check the logs above for more details")
        sys.exit(1)

if __name__ == "__main__":
    main()
