#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Package Import Test for Render Deployment
This script tests if all required packages can be imported successfully.
Run this before deploying to Render to catch any import issues.
"""

import sys
import os
from pathlib import Path

print("🧪 Testing Package Imports for Render Deployment")
print("=" * 50)

# Test results
test_results = []
total_tests = 0
passed_tests = 0

def test_import(package_name, import_statement=None):
    """Test if a package can be imported successfully"""
    global total_tests, passed_tests
    total_tests += 1
    
    try:
        if import_statement:
            exec(import_statement)
        else:
            __import__(package_name)
        print(f"✅ {package_name} - Import successful")
        test_results.append(f"✅ {package_name}")
        passed_tests += 1
        return True
    except ImportError as e:
        print(f"❌ {package_name} - Import failed: {e}")
        test_results.append(f"❌ {package_name}: {e}")
        return False
    except Exception as e:
        print(f"⚠️  {package_name} - Import error: {e}")
        test_results.append(f"⚠️  {package_name}: {e}")
        return False

print("\n🔧 Core FastAPI and Dependencies:")
print("-" * 35)
test_import("fastapi")
test_import("uvicorn")
test_import("python-multipart", "import python_multipart")
test_import("python-jose", "from jose import jwt")
test_import("passlib", "from passlib.context import CryptContext")
test_import("bcrypt", "import bcrypt")

print("\n🗄️ Database Dependencies:")
print("-" * 25)
test_import("pymysql")
test_import("sqlalchemy")
test_import("mysql-connector-python", "import mysql.connector")

print("\n☁️ Supabase:")
print("-" * 12)
test_import("supabase")

print("\n🤖 AI/ML Dependencies:")
print("-" * 20)
test_import("openai")
test_import("groq")

print("\n🌐 Web Scraping and Automation:")
print("-" * 32)
test_import("selenium")
test_import("webdriver-manager", "from webdriver_manager.chrome import ChromeDriverManager")

print("\n📊 Data Processing:")
print("-" * 20)
test_import("pandas")
test_import("numpy")
test_import("openpyxl")
test_import("xlsxwriter")

print("\n🛠️ Utilities:")
print("-" * 12)
test_import("requests")
test_import("python-dotenv", "from dotenv import load_dotenv")
test_import("pydantic")
test_import("psutil")
test_import("websockets")
test_import("aiofiles")
test_import("jinja2")
test_import("cryptography")
test_import("setuptools")

print("\n🔥 Flask and WebSocket Dependencies:")
print("-" * 35)
test_import("flask")
test_import("flask-cors", "from flask_cors import CORS")
test_import("flask-socketio", "from flask_socketio import SocketIO")
test_import("eventlet")
test_import("python-socketio", "import socketio")
test_import("python-engineio", "import engineio")

print("\n🚀 Production Dependencies:")
print("-" * 25)
test_import("gunicorn")
test_import("whitenoise")

print("\n" + "=" * 50)
print(f"📊 Test Results: {passed_tests}/{total_tests} packages imported successfully")

if passed_tests == total_tests:
    print("🎉 All packages imported successfully! Ready for Render deployment.")
else:
    print(f"⚠️  {total_tests - passed_tests} packages failed to import.")
    print("Please check the requirements-render.txt file and install missing packages.")

print("\n📋 Failed Imports:")
print("-" * 20)
for result in test_results:
    if result.startswith("❌"):
        print(result)

print("\n🔧 Next Steps:")
if passed_tests == total_tests:
    print("1. ✅ All packages working - ready to deploy!")
    print("2. 🚀 Deploy to Render using the deployment guide")
    print("3. 📱 Test your endpoints after deployment")
else:
    print("1. ❌ Fix package import issues first")
    print("2. 🔧 Check requirements-render.txt")
    print("3. 📦 Install missing packages")
    print("4. 🧪 Run this test again")
    print("5. 🚀 Deploy to Render once all tests pass")

print("\n📚 Documentation:")
print("-" * 15)
print("📖 Complete guide: RENDER_DEPLOYMENT_COMPLETE_GUIDE.md")
print("🔧 Environment template: render.env")
print("📦 Requirements: requirements-render.txt")
print("🚀 Quick deploy: deploy-to-render-quick.ps1")

# Test environment variables
print("\n🌍 Environment Variables Test:")
print("-" * 30)
env_vars = [
    "DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD",
    "SUPABASE_URL", "SUPABASE_KEY", "OPENAI_API_KEY", "GROQ_API_KEY",
    "RENDER_ENVIRONMENT", "PORT", "SECRET_KEY"
]

for var in env_vars:
    value = os.getenv(var)
    if value:
        print(f"✅ {var}: {value[:20]}{'...' if len(value) > 20 else ''}")
    else:
        print(f"❌ {var}: Not set")

print("\n🎯 Ready for Render deployment!" if passed_tests == total_tests else "\n⚠️  Fix package issues before deploying!")
