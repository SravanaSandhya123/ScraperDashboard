#!/usr/bin/env python3
"""
Start the Admin Metrics API server with updated configuration
"""

import uvicorn
import os
import sys
from pathlib import Path

# Add the current directory to Python path
sys.path.append(str(Path(__file__).parent))

def main():
    """Start the admin metrics API server"""
    print("🚀 Starting Admin Metrics API Server...")
    print("📡 Server will be available at: http://localhost:8001")
    print("🔧 Updated database configuration:")
    print("   - Host: 44.244.61.85")
    print("   - Database: Toolinformation")
    print("   - Real-time updates: Enabled")
    print("   - Cache timeout: 5 seconds")
    print("="*50)
    
    try:
        # Start the server
        uvicorn.run(
            "admin_metrics_api:app",
            host="0.0.0.0",
            port=8001,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Error starting server: {e}")

if __name__ == "__main__":
    main()
