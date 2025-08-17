#!/usr/bin/env python3
# Startup script for admin_metrics_api.py
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["DB_HOST"] = "44.244.61.85"
os.environ["PORT"] = "5030"

# Add backend directory to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Import and run admin_metrics_api
try:
    import uvicorn
    from admin_metrics_api import app
    
    port = int(os.getenv("PORT", 5030))
    print(f"Starting admin_metrics_api on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)
    
except Exception as e:
    print(f"Failed to start admin_metrics_api: {e}")
    sys.exit(1)
