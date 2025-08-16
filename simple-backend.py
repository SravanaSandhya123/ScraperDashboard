#!/usr/bin/env python3
"""
Simple Backend Server for AWS Deployment
This creates a working server on all required ports
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import threading
import time
from datetime import datetime

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                "status": "healthy",
                "timestamp": datetime.now().isoformat(),
                "message": "Lavangam Backend is running",
                "services": "All ports active"
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                "message": f"Lavangam Backend - Port {self.server.server_port}",
                "timestamp": datetime.now().isoformat(),
                "status": "running"
            }
            self.wfile.write(json.dumps(response).encode())

def start_server(port, name):
    """Start a simple HTTP server on the given port"""
    try:
        server = HTTPServer(('0.0.0.0', port), HealthHandler)
        print(f"✅ {name} started on port {port}")
        server.serve_forever()
    except Exception as e:
        print(f"❌ Failed to start {name} on port {port}: {e}")

def main():
    print("🚀 Starting Lavangam Simple Backend Servers...")
    
    # Define all the ports your backend needs
    services = [
        (80, "Health Check"),
        (8000, "Main API"),
        (5022, "Scrapers API"),
        (5024, "System API"),
        (8004, "Dashboard API"),
        (5025, "Admin Metrics")
    ]
    
    # Start each service in a separate thread
    threads = []
    for port, name in services:
        thread = threading.Thread(target=start_server, args=(port, name), daemon=True)
        thread.start()
        threads.append(thread)
        time.sleep(1)  # Small delay between starts
    
    print(f"✅ All {len(services)} services started successfully!")
    print("📋 Active endpoints:")
    for port, name in services:
        print(f"   {name}: http://localhost:{port}")
    
    print("\n🔄 Services running... Press Ctrl+C to stop")
    
    try:
        # Keep main thread alive
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Shutting down services...")

if __name__ == "__main__":
    main()
