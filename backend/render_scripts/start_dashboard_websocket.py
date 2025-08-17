#!/usr/bin/env python3
# Startup script for dashboard_websocket.py
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["DB_HOST"] = "44.244.61.85"

# Add backend directory to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Import and run dashboard_websocket directly
try:
    import asyncio
    from dashboard_websocket import main
    
    port = int(os.getenv("PORT", 5022))
    print(f"Starting dashboard_websocket on port {port}...")
    
    # Run the async main function
    asyncio.run(main())
    
except Exception as e:
    print(f"Failed to start dashboard_websocket: {e}")
    sys.exit(1)
