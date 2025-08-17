#!/usr/bin/env python3
# Startup script for eproc_server.py on port 5022
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["DB_HOST"] = "44.244.61.85"
os.environ["PORT"] = "5022"

# Add backend directory to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Import and run eproc_server
try:
    import uvicorn
    from eproc_server import app
    
    port = int(os.getenv("PORT", 5022))
    print(f"Starting eproc_server on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)
    
except Exception as e:
    print(f"Failed to start eproc_server: {e}")
    sys.exit(1)
