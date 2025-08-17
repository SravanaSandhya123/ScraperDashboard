#!/usr/bin/env python3
# Startup script for scraper_ws.py
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["DB_HOST"] = "44.244.61.85"

# Add backend directory to path
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Test eventlet import first
try:
    import eventlet
    print(f"✅ eventlet imported successfully! Version: {eventlet.__version__}")
except ImportError as e:
    print(f"❌ CRITICAL ERROR: eventlet import failed: {e}")
    print("This service requires eventlet to run. Please check requirements-render.txt")
    sys.exit(1)

# Import and run scraper_ws
try:
    import uvicorn
    from scraper_ws import app
    
    port = int(os.getenv("PORT", 5003))
    print(f"Starting scraper_ws on port {port}...")
    uvicorn.run(app, host="0.0.0.0", port=port)
    
except Exception as e:
    print(f"Failed to start scraper_ws: {e}")
    sys.exit(1)
