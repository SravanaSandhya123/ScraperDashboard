#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Multi-Port Manager for Lavangam Backend
Runs all services simultaneously on different ports
"""

import os
import sys
import subprocess
import threading
import time
import signal
import socket
from pathlib import Path

# Add the backend directory to Python path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

print("🚀 Lavangam Multi-Port Manager Starting...")

# Service configurations
SERVICES = {
    "main_backend": {
        "command": ["python", "render.py"],
        "port": 8000,
        "description": "Main FastAPI Backend"
    },
    "file_manager": {
        "command": ["python", "file_manager.py"],
        "port": 5002,
        "description": "File Manager Flask App"
    },
    "eproc_server": {
        "command": ["python", "eproc_server.py"],
        "port": 5023,
        "description": "E-Procurement Server"
    },
    "system_usage": {
        "command": ["python", "system_usage_api.py"],
        "port": 5024,
        "description": "System Usage API"
    },
    "dashboard_api": {
        "command": ["python", "dashboard_api.py"],
        "port": 8004,
        "description": "Dashboard API"
    },
    "scrapers_api": {
        "command": ["python", "scrapers/api.py"],
        "port": 5022,
        "description": "Scrapers API"
    },
    "analytics_api": {
        "command": ["python", "-m", "uvicorn", "analytics_api:app", "--host", "0.0.0.0", "--port", "8001"],
        "port": 8001,
        "description": "Analytics API"
    },
    "additional_analytics": {
        "command": ["python", "-m", "uvicorn", "analytics_additional:app", "--host", "0.0.0.0", "--port", "8002"],
        "port": 8002,
        "description": "Additional Analytics API"
    },
    "eproc_websocket": {
        "command": ["python", "eproc_websocket.py"],
        "port": 5020,
        "description": "E-Procurement WebSocket"
    },
    "eproc_api": {
        "command": ["python", "eproc_api.py"],
        "port": 5021,
        "description": "E-Procurement API"
    }
}

# Store running processes
running_processes = {}

def check_port_availability(port):
    """Check if a port is available"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('0.0.0.0', port))
            return True
    except OSError:
        return False

def find_available_port(start_port):
    """Find an available port starting from start_port"""
    port = start_port
    while port < start_port + 100:  # Try next 100 ports
        if check_port_availability(port):
            return port
        port += 1
    return None

def start_service(service_name, config):
    """Start a single service"""
    try:
        print(f"🚀 Starting {service_name} on port {config['port']}...")
        
        # Check if port is available, if not find alternative
        port = config['port']
        if not check_port_availability(port):
            print(f"⚠️ Port {port} not available for {service_name}")
            alt_port = find_available_port(port)
            if alt_port:
                print(f"🔄 Using alternative port {alt_port} for {service_name}")
                port = alt_port
            else:
                print(f"❌ No available ports found for {service_name}")
                return None
        
        # Set environment variables
        env = os.environ.copy()
        env['PORT'] = str(port)
        env['FLASK_ENV'] = 'production'
        env['RENDER_ENVIRONMENT'] = 'production'
        
        # Start the process
        process = subprocess.Popen(
            config['command'],
            env=env,
            cwd=backend_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        running_processes[service_name] = {
            'process': process,
            'port': port,
            'config': config
        }
        
        print(f"✅ {service_name} started on port {port}")
        return process
        
    except Exception as e:
        print(f"❌ Failed to start {service_name}: {e}")
        return None

def stop_service(service_name):
    """Stop a single service"""
    if service_name in running_processes:
        process_info = running_processes[service_name]
        process = process_info['process']
        
        try:
            process.terminate()
            process.wait(timeout=5)
            print(f"🛑 {service_name} stopped")
        except subprocess.TimeoutExpired:
            process.kill()
            print(f"🔪 {service_name} force killed")
        except Exception as e:
            print(f"❌ Error stopping {service_name}: {e}")
        
        del running_processes[service_name]

def stop_all_services():
    """Stop all running services"""
    print("\n🛑 Stopping all services...")
    for service_name in list(running_processes.keys()):
        stop_service(service_name)

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    print(f"\n📡 Received signal {signum}, shutting down...")
    stop_all_services()
    sys.exit(0)

def monitor_services():
    """Monitor running services"""
    while True:
        time.sleep(10)  # Check every 10 seconds
        
        # Check if any processes have died
        for service_name in list(running_processes.keys()):
            process_info = running_processes[service_name]
            process = process_info['process']
            
            if process.poll() is not None:
                print(f"⚠️ {service_name} has stopped unexpectedly")
                # Restart the service
                print(f"🔄 Restarting {service_name}...")
                stop_service(service_name)
                start_service(service_name, process_info['config'])

def main():
    """Main function to start all services"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    print("=" * 60)
    print("🚀 Lavangam Multi-Port Manager")
    print("=" * 60)
    
    # Start all services
    for service_name, config in SERVICES.items():
        start_service(service_name, config)
        time.sleep(2)  # Small delay between starts
    
    # Print service status
    print("\n" + "=" * 60)
    print("📊 Service Status:")
    print("=" * 60)
    
    for service_name, info in running_processes.items():
        status = "🟢 Running" if info['process'].poll() is None else "🔴 Stopped"
        print(f"{service_name:20} | Port {info['port']:4} | {status}")
    
    print("\n🌐 Service URLs:")
    print("=" * 60)
    for service_name, info in running_processes.items():
        print(f"{service_name:20} | http://0.0.0.0:{info['port']}")
    
    print("\n📡 Monitoring services... (Press Ctrl+C to stop)")
    print("=" * 60)
    
    # Start monitoring in a separate thread
    monitor_thread = threading.Thread(target=monitor_services, daemon=True)
    monitor_thread.start()
    
    try:
        # Keep main thread alive
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Shutdown requested...")
        stop_all_services()

if __name__ == "__main__":
    main()
