#!/usr/bin/env python3
"""
Start the fixed E-Procurement server with MySQL support
"""

import os
import sys
import subprocess
import time

def check_dependencies():
    """Check if required dependencies are installed"""
    required_packages = [
        'flask',
        'flask-cors', 
        'flask-socketio',
        'pandas',
        'mysql-connector-python',
        'openpyxl'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"❌ Missing packages: {', '.join(missing_packages)}")
        print("Please install them using: pip install " + " ".join(missing_packages))
        return False
    
    print("✅ All dependencies are installed")
    return True

def start_server():
    """Start the fixed eproc server"""
    print("🚀 Starting Fixed E-Procurement Server...")
    print("📍 Server will be available at: http://44.244.35.65:5000")
    print("📊 Database: 44.244.61.85:3306/Toolinformation")
    print("=" * 60)
    
    try:
        # Import and run the fixed server
        from eproc_server_mysql_fixed import app, socketio, test_database_connection
        
        # Test database connection on startup
        print("🔍 Testing database connection...")
        if test_database_connection():
            print("✅ Database connection successful")
        else:
            print("⚠️ Database connection failed - server will work without database storage")
        
        print("🌐 Starting server...")
        socketio.run(app, host='0.0.0.0', port=5000, debug=True)
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("=" * 60)
    print("🔧 E-Procurement Server - Fixed Version")
    print("=" * 60)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Start server
    start_server()
