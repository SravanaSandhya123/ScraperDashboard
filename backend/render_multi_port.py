#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Render Multi-Port Deployment for Lavangam Backend
Runs all services on different ports for Render deployment
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

print("🚀 Lavangam Render Multi-Port Deployment Starting...")

# Service configurations for Render
SERVICES = {
    "main_backend": {
        "command": ["python", "render.py"],
        "port": 8000,
        "description": "Main FastAPI Backend (Primary)"
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
    }
}

# Store running processes
running_processes = {}

def get_port_from_env(service_name, default_port):
    """Get port from environment variable or use default"""
    env_var = f"{service_name.upper()}_PORT"
    return int(os.getenv(env_var, default_port))

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
    while port < start_port + 50:  # Try next 50 ports
        if check_port_availability(port):
            return port
        port += 1
    return None

def start_service(service_name, config):
    """Start a single service"""
    try:
        # Get port from environment or use default
        port = get_port_from_env(service_name, config['port'])
        
        print(f"🚀 Starting {service_name} on port {port}...")
        
        # Check if port is available, if not find alternative
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
        env['DB_HOST'] = os.getenv('DB_HOST', '44.244.61.85')
        env['DB_PORT'] = os.getenv('DB_PORT', '3306')
        env['DB_NAME'] = os.getenv('DB_NAME', 'Toolinformation')
        env['DB_USER'] = os.getenv('DB_USER', 'root')
        env['DB_PASSWORD'] = os.getenv('DB_PASSWORD', 'thanuja')
        
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
        time.sleep(30)  # Check every 30 seconds
        
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
    print("🚀 Lavangam Render Multi-Port Deployment")
    print("=" * 60)
    
    # Environment info
    env = os.getenv('RENDER_ENVIRONMENT', 'production')
    print(f"🏭 Environment: {env}")
    print(f"🏠 Database Host: {os.getenv('DB_HOST', '44.244.61.85')}")
    
    # Start all services
    for service_name, config in SERVICES.items():
        start_service(service_name, config)
        time.sleep(3)  # Delay between starts
    
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
    
    # Special note for Render
    print("\n📝 Render Notes:")
    print("=" * 60)
    print("• Main backend runs on port 8000 (Render's default)")
    print("• Other services run on additional ports")
    print("• Health check available at /ping on main backend")
    print("• All services are monitored and auto-restarted")
    
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
