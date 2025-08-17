#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive Render deployment script for Lavangam Backend
Handles all port binding scenarios and environment setup
"""

import os
import sys
import uvicorn
import socket
from pathlib import Path

print("🚀 Lavangam Backend - Comprehensive Render Deployment")

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

def check_port_availability(port):
    """Check if a port is available"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('0.0.0.0', port))
            return True
    except OSError:
        return False

def find_available_port(start_port=8000, max_attempts=10):
    """Find an available port starting from start_port"""
    for i in range(max_attempts):
        port = start_port + i
        if check_port_availability(port):
            return port
    return None

def get_port():
    """Get port with multiple fallback strategies"""
    print("🔍 Determining port configuration...")
    
    # Strategy 1: Environment variables
    env_vars = ["PORT", "RENDER_PORT", "WEB_PORT", "APP_PORT"]
    for var in env_vars:
        port_str = os.getenv(var)
        if port_str:
            try:
                port = int(port_str)
                print(f"✅ Using port from {var}: {port}")
                return port
            except ValueError:
                print(f"⚠️ Invalid port in {var}: {port_str}")
    
    # Strategy 2: Common ports
    common_ports = [8000, 8080, 3000, 5000, 4000, 9000]
    for port in common_ports:
        if check_port_availability(port):
            print(f"✅ Using available common port: {port}")
            return port
    
    # Strategy 3: Find any available port
    available_port = find_available_port()
    if available_port:
        print(f"✅ Using found available port: {available_port}")
        return available_port
    
    # Strategy 4: Default fallback
    print("⚠️ No available ports found, using default: 8000")
    return 8000

def main():
    """Main deployment function"""
    print("=" * 60)
    print("🚀 Lavangam Backend - Render Deployment")
    print("=" * 60)
    
    # Environment info
    env = os.getenv("RENDER_ENVIRONMENT", "production")
    print(f"🏭 Environment: {env}")
    
    # Get port
    port = get_port()
    print(f"🌐 Port: {port}")
    
    # Get host
    host = os.getenv("HOST", "0.0.0.0")
    print(f"🏠 Host: {host}")
    
    # Print startup info
    print("=" * 60)
    print("🚀 Starting Lavangam Backend Server")
    print(f"🌐 URL: http://{host}:{port}")
    print(f"📊 Health Check: http://{host}:{port}/health")
    print(f"🏓 Ping Test: http://{host}:{port}/ping")
    print(f"🏠 Root: http://{host}:{port}/")
    print("=" * 60)
    
    # Verify port is available
    if not check_port_availability(port):
        print(f"❌ Port {port} is not available!")
        sys.exit(1)
    
    try:
        # Start the server with detailed logging
        print("🚀 Starting uvicorn server...")
        uvicorn.run(
            app,
            host=host,
            port=port,
            log_level="info",
            access_log=True,
            reload=False
        )
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        print("🔍 Check the logs above for more details")
        sys.exit(1)

if __name__ == "__main__":
    main()
