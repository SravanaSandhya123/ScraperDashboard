#!/usr/bin/env python3
"""
AWS Elastic Beanstalk Application Entry Point
This file automatically starts all backend services
"""

import os
import sys
import time
import threading
import subprocess
from datetime import datetime
from flask import Flask, jsonify
import signal

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Create Flask app for health check
application = Flask(__name__)

# Service configurations for AWS deployment
SERVICES = [
    {
        "name": "Main API",
        "command": ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"],
        "port": 8000,
        "description": "Main FastAPI application with all routers"
    },
    {
        "name": "Scrapers API",
        "command": ["python", "-m", "uvicorn", "scrapers.api:app", "--host", "0.0.0.0", "--port", "5022"],
        "port": 5022,
        "description": "Scraping tools and WebSocket endpoints"
    },
    {
        "name": "System Usage API",
        "command": ["python", "-m", "uvicorn", "system_usage_api:app", "--host", "0.0.0.0", "--port", "5024"],
        "port": 5024,
        "description": "System monitoring and metrics"
    },
    {
        "name": "Dashboard API",
        "command": ["python", "-m", "uvicorn", "dashboard_api:app", "--host", "0.0.0.0", "--port", "8004"],
        "port": 8004,
        "description": "Dashboard metrics and analytics"
    },
    {
        "name": "Admin Metrics API",
        "command": ["python", "-m", "uvicorn", "admin_metrics_api:app", "--host", "0.0.0.0", "--port", "5025"],
        "port": 5025,
        "description": "Admin dashboard metrics"
    }
]

# Store running processes
running_processes = {}
stop_event = threading.Event()

def log(message, level="INFO"):
    """Log messages with timestamp"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{level}] {message}", flush=True)

def start_service(service_config):
    """Start a single service in background"""
    name = service_config["name"]
    command = service_config["command"]
    port = service_config["port"]
    
    try:
        log(f"Starting {name} on port {port}...")
        
        # Start the process
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=os.path.dirname(os.path.abspath(__file__))
        )
        
        running_processes[name] = {
            "process": process,
            "config": service_config,
            "start_time": datetime.now()
        }
        
        log(f"✅ {name} started successfully (PID: {process.pid})")
        return True
        
    except Exception as e:
        log(f"❌ Failed to start {name}: {e}", "ERROR")
        return False

def start_all_services():
    """Start all services in background threads"""
    log("🚀 Starting all backend services...")
    
    for service in SERVICES:
        start_service(service)
        time.sleep(2)  # Small delay between starts
    
    log(f"✅ All services startup initiated")

def stop_all_services():
    """Stop all running services"""
    log("Stopping all services...")
    stop_event.set()
    
    for name, info in running_processes.items():
        try:
            log(f"Stopping {name}...")
            info["process"].terminate()
            info["process"].wait(timeout=10)
        except Exception as e:
            log(f"Error stopping {name}: {e}", "ERROR")
    
    running_processes.clear()
    log("All services stopped")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    log(f"Received signal {signum}, shutting down...")
    stop_all_services()
    sys.exit(0)

# Health check endpoint for AWS ELB
@application.route('/health')
def health_check():
    """Health check endpoint for AWS load balancer"""
    return jsonify({
        "status": "healthy",
        "services": len(running_processes),
        "timestamp": datetime.now().isoformat()
    })

@application.route('/')
def root():
    """Root endpoint"""
    return jsonify({
        "message": "Lavangam Backend Services",
        "status": "running",
        "services": list(running_processes.keys()),
        "endpoints": {
            "main_api": "http://localhost:8000",
            "scrapers_api": "http://localhost:5022",
            "system_api": "http://localhost:5024",
            "dashboard_api": "http://localhost:8004",
            "admin_metrics": "http://localhost:5025"
        }
    })

if __name__ == '__main__':
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    log("🚀 Lavangam AWS Backend Starting...")
    
    # Start all background services
    start_all_services()
    
    # Start the main Flask app on port 80 (default for EB)
    port = int(os.environ.get("PORT", 80))
    log(f"Starting health check server on port {port}")
    
    try:
        application.run(host='0.0.0.0', port=port, debug=False)
    except KeyboardInterrupt:
        log("Received interrupt signal")
    finally:
        stop_all_services()
