#!/usr/bin/env python3
"""
Start E-Procurement Server - Complete Fix
Handles all database scenarios and provides comprehensive feedback
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
        'openpyxl'
    ]
    
    # Optional database packages
    optional_packages = {
        'mysql-connector-python': 'MySQL support',
        'psycopg2': 'PostgreSQL support',
        'pymysql': 'MySQL alternative support'
    }
    
    missing_packages = []
    available_db_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    for package, description in optional_packages.items():
        try:
            __import__(package.replace('-', '_'))
            available_db_packages.append(f"✅ {package} - {description}")
        except ImportError:
            available_db_packages.append(f"❌ {package} - {description}")
    
    if missing_packages:
        print(f"❌ Missing required packages: {', '.join(missing_packages)}")
        print("Please install them using: pip install " + " ".join(missing_packages))
        return False
    
    print("✅ All required dependencies are installed")
    print("📊 Database packages:")
    for package_status in available_db_packages:
        print(f"   {package_status}")
    
    return True

def check_environment():
    """Check environment variables and configuration"""
    print("\n🔍 Environment Configuration:")
    print("=" * 50)
    
    # Check database type
    db_type = os.getenv('DB_TYPE', 'mysql').lower()
    print(f"Database Type: {db_type.upper()}")
    
    # Check database configuration
    if db_type == 'postgresql':
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '5432')
        database = os.getenv('DB_NAME', 'scraper_db')
        user = os.getenv('DB_USER', 'username')
    else:
        host = os.getenv('DB_HOST', 'localhost')
        port = os.getenv('DB_PORT', '3306')
        database = os.getenv('DB_NAME', 'Toolinformation')
        user = os.getenv('DB_USER', 'root')
    
    print(f"Database Host: {host}")
    print(f"Database Port: {port}")
    print(f"Database Name: {database}")
    print(f"Database User: {user}")
    
    # Check if password is set
    password = os.getenv('DB_PASSWORD', '')
    if password:
        print(f"Database Password: {'*' * len(password)}")
    else:
        print("Database Password: (not set)")
    
    return True

def test_database_connection():
    """Test database connection"""
    print("\n🔍 Testing Database Connection:")
    print("=" * 50)
    
    try:
        from database_config_fixed import test_database_connection
        success, message = test_database_connection()
        print(message)
        return success
    except Exception as e:
        print(f"❌ Database connection test failed: {e}")
        return False

def start_server():
    """Start the complete fix server"""
    print("\n🚀 Starting E-Procurement Server - Complete Fix...")
    print("📍 Server will be available at: http://localhost:5000")
    print("=" * 60)
    
    try:
        # Import and run the complete fix server
        from eproc_server_complete_fix import app, socketio, test_database_connection
        
        # Test database connection on startup
        print("🔍 Testing database connection...")
        success, message = test_database_connection()
        print(message)
        
        if not success:
            print("⚠️ Database connection failed - server will work without database storage")
            print("📁 Files will still be merged and downloaded successfully")
        
        print("🌐 Starting server...")
        socketio.run(app, host='0.0.0.0', port=5000, debug=True)
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        return False
    
    return True

def show_usage_instructions():
    """Show usage instructions"""
    print("\n📖 Usage Instructions:")
    print("=" * 50)
    print("1. Set environment variables (optional):")
    print("   - DB_TYPE=mysql|postgresql")
    print("   - DB_HOST=localhost|44.244.61.85")
    print("   - DB_PORT=3306|5432")
    print("   - DB_NAME=Toolinformation|scraper_db")
    print("   - DB_USER=root|username")
    print("   - DB_PASSWORD=your_password")
    print("\n2. Test database connection:")
    print("   python database_config_fixed.py")
    print("\n3. Check server health:")
    print("   curl http://localhost:5000/api/health")
    print("\n4. Check database status:")
    print("   curl http://localhost:5000/api/database-status")

if __name__ == "__main__":
    print("=" * 60)
    print("🔧 E-Procurement Server - Complete Fix")
    print("=" * 60)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Check environment
    check_environment()
    
    # Test database connection
    db_connected = test_database_connection()
    
    # Show usage instructions
    show_usage_instructions()
    
    # Start server
    start_server()
