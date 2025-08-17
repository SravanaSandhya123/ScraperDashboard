#!/usr/bin/env python3
"""
Test script to verify all required packages are available
Run this locally before deploying to catch import issues
"""

print("🧪 Testing package imports for Lavangam Consolidated Backend...")

try:
    print("📦 Importing FastAPI...")
    from fastapi import FastAPI
    print("✅ FastAPI imported successfully")
    
    print("📦 Importing Uvicorn...")
    import uvicorn
    print("✅ Uvicorn imported successfully")
    
    print("📦 Importing Supabase...")
    from supabase import create_client
    print("✅ Supabase imported successfully")
    
    print("📦 Importing MySQL...")
    import mysql.connector
    print("✅ MySQL connector imported successfully")
    
    print("📦 Importing utilities...")
    from dotenv import load_dotenv
    import psutil
    import requests
    print("✅ Utilities imported successfully")
    
    print("📦 Importing data processing...")
    import pandas as pd
    import numpy as np
    print("✅ Data processing imported successfully")
    
    print("\n🎉 ALL PACKAGES IMPORTED SUCCESSFULLY!")
    print("✅ Your backend is ready for deployment!")
    
except ImportError as e:
    print(f"\n❌ IMPORT ERROR: {e}")
    print("🔧 Please install missing packages:")
    print("   pip install -r requirements-minimal.txt")
    exit(1)
except Exception as e:
    print(f"\n❌ UNEXPECTED ERROR: {e}")
    exit(1)
