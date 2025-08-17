#!/usr/bin/env python3
# Startup script for dashboard_api.py on port 8004
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["DB_HOST"] = "44.244.61.85"
os.environ["PORT"] = "8004"

# Add backend directory to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Import and run dashboard_api
try:
    import uvicorn
    from dashboard_api import app
    
    port = int(os.getenv("PORT", 8004))
    print(f"Starting dashboard_api on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)
    
except Exception as e:
    print(f"Failed to start dashboard_api: {e}")
    sys.exit(1)
