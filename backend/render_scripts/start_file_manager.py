#!/usr/bin/env python3
# Startup script for file_manager.py
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["DB_HOST"] = "44.244.61.85"
os.environ["PORT"] = "5026"

# Add backend directory to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Import and run file_manager
try:
    import uvicorn
    from file_manager import app
    
    port = int(os.getenv("PORT", 5026))
    print(f"Starting file_manager on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)
    
except Exception as e:
    print(f"Failed to start file_manager: {e}")
    sys.exit(1)
