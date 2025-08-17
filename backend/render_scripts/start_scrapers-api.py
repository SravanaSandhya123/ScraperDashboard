#!/usr/bin/env python3
# Auto-generated script for scrapers-api
import os
import sys
from pathlib import Path

# Set environment variables
os.environ["RENDER_ENVIRONMENT"] = "production"
os.environ["PORT"] = "5022"

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import and run the service
try:
    if "scrapers/api.py".endswith('.py'):
        script_name = "scrapers/api.py"[:-3]
        module = __import__(script_name)
        
        # Check if it's a FastAPI app
        if hasattr(module, 'app'):
            import uvicorn
            port = int(os.getenv("PORT", 5022))
            print(f"Starting {script_name} on port {port}...")
            uvicorn.run(module.app, host="0.0.0.0", port=port)
        else:
            print(f"{script_name} doesn't have a FastAPI app")
    else:
        print(f"Unsupported script type: {config["script"]}")
        
except Exception as e:
    print(f"Failed to start {service_name}: {e}")
    sys.exit(1)
