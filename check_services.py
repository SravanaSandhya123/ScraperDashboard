#!/usr/bin/env python3
"""
LAVANGAM Backend Services Health Check Script
This script checks if all your backend services are running on their correct ports
"""

import requests
import socket
import subprocess
import sys
import time
from datetime import datetime

# All your service ports
SERVICES = {
    'Main API': 8000,
    'Scrapers API': 5022,
    'System Usage API': 5024,
    'Dashboard API': 8004,
    'Admin Metrics API': 5025,
    'Analytics API': 8001,
    'Additional Analytics': 8002,
    'E-Procurement WebSocket': 5020,
    'E-Procurement Server': 5021,
    'E-Procurement Fixed': 5023,
    'File Manager': 5001,
    'Export Server': 5002,
    'E-Procurement API': 5005
}

def check_port(port, service_name):
    """Check if a port is open and listening"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex(('localhost', port))
        sock.close()
        
        if result == 0:
            return True, f"✅ {service_name} (Port {port}): RUNNING"
        else:
            return False, f"❌ {service_name} (Port {port}): NOT RUNNING"
    except Exception as e:
        return False, f"❌ {service_name} (Port {port}): ERROR - {str(e)}"

def check_systemd_service(service_name):
    """Check if a systemd service is running"""
    try:
        result = subprocess.run(['systemctl', 'is-active', service_name], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip() == 'active':
            return True, f"✅ {service_name}: RUNNING"
        else:
            return False, f"❌ {service_name}: NOT RUNNING"
    except Exception as e:
        return False, f"❌ {service_name}: ERROR - {str(e)}"

def check_health_endpoints():
    """Check health endpoints if available"""
    health_endpoints = [
        ('http://localhost:8000/health', 'Main API Health'),
        ('http://localhost:5022/health', 'Scrapers API Health'),
        ('http://localhost:8004/health', 'Dashboard API Health'),
        ('http://localhost:5025/health', 'Admin Metrics Health'),
        ('http://localhost:8001/health', 'Analytics API Health'),
        ('http://localhost:8002/health', 'Additional Analytics Health'),
    ]
    
    results = []
    for url, name in health_endpoints:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                results.append(f"✅ {name}: HEALTHY (Status: {response.status_code})")
            else:
                results.append(f"⚠️  {name}: UNHEALTHY (Status: {response.status_code})")
        except requests.exceptions.RequestException as e:
            results.append(f"❌ {name}: UNREACHABLE - {str(e)}")
    
    return results

def main():
    print("🚀 LAVANGAM Backend Services Health Check")
    print("=" * 50)
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Check all ports
    print("🔍 Checking Service Ports:")
    print("-" * 30)
    
    port_results = []
    for service_name, port in SERVICES.items():
        is_running, message = check_port(port, service_name)
        port_results.append((is_running, message))
        print(message)
    
    print()
    
    # Check systemd services
    print("🔧 Checking System Services:")
    print("-" * 30)
    
    system_services = ['mysql', 'nginx', 'lavangam-backend']
    system_results = []
    
    for service in system_services:
        is_running, message = check_systemd_service(service)
        system_results.append((is_running, message))
        print(message)
    
    print()
    
    # Check health endpoints
    print("🏥 Checking Health Endpoints:")
    print("-" * 30)
    
    try:
        health_results = check_health_endpoints()
        for result in health_results:
            print(result)
    except Exception as e:
        print(f"❌ Health check failed: {str(e)}")
    
    print()
    
    # Summary
    print("📊 SUMMARY:")
    print("-" * 30)
    
    total_services = len(port_results) + len(system_results)
    running_services = sum(1 for is_running, _ in port_results + system_results if is_running)
    
    print(f"Total Services: {total_services}")
    print(f"Running Services: {running_services}")
    print(f"Failed Services: {total_services - running_services}")
    
    if running_services == total_services:
        print("🎉 All services are running successfully!")
        return 0
    else:
        print("⚠️  Some services are not running. Check the details above.")
        return 1

if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\n⏹️  Health check interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n💥 Unexpected error: {str(e)}")
        sys.exit(1)
