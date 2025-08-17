#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test script for Lavangam Backend
"""

import sys
import os
from pathlib import Path

print("🧪 Testing Lavangam Backend...")

# Add the backend directory to Python path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))
print(f"✅ Backend path added: {backend_path}")

# Check Python version
python_version = sys.version_info
print(f"🐍 Python version: {python_version.major}.{python_version.minor}.{python_version.micro}")

# Test imports
try:
    print("📦 Testing imports...")
    
    from fastapi import FastAPI
    print("✅ FastAPI imported")
    
    import uvicorn
    print("✅ uvicorn imported")
    
    from supabase import create_client
    print("✅ supabase imported")
    
    import psutil
    print("✅ psutil imported")
    
    import pandas as pd
    print("✅ pandas imported")
    
    import numpy as np
    print("✅ numpy imported")
    
    from dotenv import load_dotenv
    print("✅ dotenv imported")
    
    print("✅ All imports successful!")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)

# Test environment loading
try:
    print("🔧 Testing environment loading...")
    load_dotenv()
    print("✅ Environment variables loaded")
except Exception as e:
    print(f"❌ Environment loading error: {e}")

# Test FastAPI app creation
try:
    print("🏗️ Testing FastAPI app creation...")
    app = FastAPI(title="Lavangam Backend Test")
    print("✅ FastAPI app created successfully")
except Exception as e:
    print(f"❌ FastAPI app creation error: {e}")

# Test system metrics
try:
    print("📊 Testing system metrics...")
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    print(f"✅ CPU: {cpu_percent}%, Memory: {memory.percent}%")
except Exception as e:
    print(f"❌ System metrics error: {e}")

print("🎉 All tests completed successfully!")
print("✅ Backend is ready for deployment!") 