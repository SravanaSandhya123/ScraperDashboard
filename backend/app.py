#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simple app.py for Render deployment
This ensures proper port binding
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

# Import the app from render.py
from render import app

if __name__ == "__main__":
    import uvicorn
    
    # Get port from environment
    port = int(os.getenv("PORT", 8000))
    
    print(f"🚀 Starting Lavangam Backend on port {port}")
    print(f"🌐 Host: 0.0.0.0")
    print(f"🏭 Environment: {os.getenv('RENDER_ENVIRONMENT', 'production')}")
    
    # Start the server
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=port,
        log_level="info"
    ) 