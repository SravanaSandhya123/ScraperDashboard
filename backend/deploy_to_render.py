#!/usr/bin/env python3
"""
Render Deployment Helper Script for Lavangam Backend
This script helps you deploy all 9 services to Render
"""

import os
import sys
import subprocess
import json
from pathlib import Path

def print_header():
    print("🚀 LAVANGAM BACKEND - RENDER DEPLOYMENT HELPER")
    print("=" * 60)
    print()

def check_prerequisites():
    print("🔍 Checking prerequisites...")
    
    # Check if render.yaml exists
    if not Path("render-correct.yaml").exists():
        print("❌ render-correct.yaml not found!")
        print("   Please ensure you have the correct render.yaml file")
        return False
    
    # Check if requirements-render.txt exists
    if not Path("requirements-render.txt").exists():
        print("❌ requirements-render.txt not found!")
        return False
    
    # Check if we're in the right directory
    if not Path("main.py").exists():
        print("❌ main.py not found! Please run this script from the backend directory")
        return False
    
    print("✅ All prerequisites met!")
    return True

def show_services():
    print("\n📋 YOUR BACKEND SERVICES:")
    print("-" * 40)
    
    services = [
        ("Main Backend", 8000, "backend/main.py"),
        ("Admin Metrics API", 8001, "admin_metrics_api.py"),
        ("Dashboard WebSocket", 8002, "dashboard_websocket.py"),
        ("Scraper WebSocket", 5003, "scraper_ws.py"),
        ("Dashboard API", 8004, "dashboard_api.py"),
        ("File Manager", 5002, "file_manager.py"),
        ("E-Procurement Server", 5021, "eproc_server.py"),
        ("Scrapers API", 5022, "backend/scrapers/api.py"),
        ("System Usage API", 5024, "system_usage_api.py")
    ]
    
    for i, (name, port, file) in enumerate(services, 1):
        print(f"{i:2d}. {name:<20} Port: {port:<4} File: {file}")
    
    print()

def show_deployment_options():
    print("🚀 DEPLOYMENT OPTIONS:")
    print("-" * 30)
    print("1. Deploy using Render Dashboard (Recommended)")
    print("2. Deploy using Render CLI")
    print("3. Manual service creation")
    print("4. Test services locally")
    print("5. Exit")
    print()

def deploy_via_dashboard():
    print("\n📱 RENDER DASHBOARD DEPLOYMENT:")
    print("-" * 40)
    print("1. Go to https://render.com and sign in")
    print("2. Click 'New +' → 'Blueprint'")
    print("3. Select 'Build and deploy from a Git repository'")
    print("4. Connect your GitHub account")
    print("5. Select your 'lavangam' repository")
    print("6. Upload 'render-correct.yaml' file")
    print("7. Click 'Apply' to deploy all services")
    print()
    print("✅ This will automatically create all 9 services!")
    print()

def deploy_via_cli():
    print("\n💻 RENDER CLI DEPLOYMENT:")
    print("-" * 35)
    
    # Check if Render CLI is installed
    try:
        result = subprocess.run(["render", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Render CLI is installed!")
            print("\nTo deploy:")
            print("render deploy --file render-correct.yaml")
        else:
            print("❌ Render CLI is not working properly")
    except FileNotFoundError:
        print("❌ Render CLI is not installed")
        print("\nTo install Render CLI:")
        print("npm install -g @render/cli")
        print("\nThen run:")
        print("render deploy --file render-correct.yaml")

def manual_creation():
    print("\n🔧 MANUAL SERVICE CREATION:")
    print("-" * 35)
    print("If you prefer to create services manually:")
    print()
    print("1. Go to render.com dashboard")
    print("2. Click 'New +' → 'Web Service'")
    print("3. Connect your GitHub repository")
    print("4. For each service, configure:")
    print("   - Name: lavangam-[service-name]")
    print("   - Environment: Python")
    print("   - Build Command: pip install -r requirements-render.txt")
    print("   - Start Command: [see guide below]")
    print("   - Port: [service-port]")
    print()
    print("📖 See RENDER_DEPLOYMENT_GUIDE_ACTUAL.md for detailed steps")

def test_local():
    print("\n🧪 LOCAL TESTING:")
    print("-" * 20)
    print("To test services locally before deployment:")
    print()
    
    test_commands = [
        ("Main Backend", "uvicorn backend.main:app --host 0.0.0.0 --port 8000"),
        ("Admin Metrics", "uvicorn admin_metrics_api:app --host 0.0.0.0 --port 8001"),
        ("Dashboard WebSocket", "python dashboard_websocket.py"),
        ("Scraper WebSocket", "python scraper_ws.py"),
        ("Dashboard API", "uvicorn dashboard_api:app --host 0.0.0.0 --port 8004"),
        ("File Manager", "python file_manager.py"),
        ("E-Procurement", "python eproc_server.py"),
        ("Scrapers API", "uvicorn backend.scrapers.api:app --host 0.0.0.0 --port 5022"),
        ("System Usage", "uvicorn system_usage_api:app --host 0.0.0.0 --port 5024")
    ]
    
    for name, cmd in test_commands:
        print(f"• {name}: {cmd}")
    
    print("\n⚠️  Note: Use 0.0.0.0 instead of 127.0.0.1 for production")

def show_environment_vars():
    print("\n🔑 ENVIRONMENT VARIABLES:")
    print("-" * 30)
    print("Set these for each service in Render:")
    print()
    print("For FastAPI services (8000, 8001, 8002, 8004, 5022, 5024):")
    print("PORT=[service-port]")
    print("RENDER_ENVIRONMENT=production")
    print("DB_HOST=44.244.61.85")
    print("DB_USER=[your-db-user]")
    print("DB_PASSWORD=[your-db-password]")
    print("DB_NAME=[your-db-name]")
    print()
    print("For Flask services (5002, 5003, 5021):")
    print("PORT=[service-port]")
    print("RENDER_ENVIRONMENT=production")
    print("FLASK_ENV=production")

def main():
    print_header()
    
    if not check_prerequisites():
        print("\n❌ Please fix the issues above before proceeding")
        return
    
    show_services()
    
    while True:
        show_deployment_options()
        
        try:
            choice = input("Enter your choice (1-5): ").strip()
            
            if choice == "1":
                deploy_via_dashboard()
            elif choice == "2":
                deploy_via_cli()
            elif choice == "3":
                manual_creation()
            elif choice == "4":
                test_local()
            elif choice == "5":
                print("\n👋 Goodbye! Good luck with your deployment!")
                break
            else:
                print("❌ Invalid choice. Please enter 1-5")
                
        except KeyboardInterrupt:
            print("\n\n👋 Deployment cancelled. Goodbye!")
            break
        except Exception as e:
            print(f"\n❌ Error: {e}")
        
        input("\nPress Enter to continue...")
        print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    main()
