#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Multi-Port Render Deployment Manager
Creates multiple Render services for different ports
"""

import os
import sys
import json
import subprocess
from pathlib import Path

# Service configurations for Render deployment
RENDER_SERVICES = {
    "main-backend": {
        "port": 8000,
        "script": "render.py",
        "description": "Main FastAPI Backend",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    },
    "analytics-api": {
        "port": 8001,
        "script": "analytics_api.py",
        "description": "Analytics API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    },
    "dashboard-api": {
        "port": 8004,
        "script": "dashboard_api.py",
        "description": "Dashboard API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    },
    "eproc-server": {
        "port": 5021,
        "script": "eproc_server.py",
        "description": "E-Procurement Server",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    },
    "file-manager": {
        "port": 5002,
        "script": "file_manager.py",
        "description": "File Manager Flask App",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "FLASK_ENV": "production"
        }
    },
    "system-usage": {
        "port": 5024,
        "script": "system_usage_api.py",
        "description": "System Usage API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production"
        }
    },
    "scrapers-api": {
        "port": 5022,
        "script": "scrapers/api.py",
        "description": "Scrapers API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production"
        }
    },
    "eproc-api": {
        "port": 5023,
        "script": "eproc_api.py",
        "description": "E-Procurement API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    },
    "admin-metrics": {
        "port": 8005,
        "script": "admin_metrics_api.py",
        "description": "Admin Metrics API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    },
    "unified-api": {
        "port": 8006,
        "script": "unified_api_complete.py",
        "description": "Unified API",
        "env_vars": {
            "RENDER_ENVIRONMENT": "production",
            "DB_HOST": "44.244.61.85"
        }
    }
}

def create_render_yaml():
    """Create render.yaml for multiple services"""
    render_config = {
        "services": []
    }
    
    for service_name, config in RENDER_SERVICES.items():
        service_config = {
            "type": "web",
            "name": f"lavangam-{service_name}",
            "env": "python",
            "plan": "free",
            "buildCommand": "pip install -r requirements-render.txt",
            "startCommand": f"python {config['script']}",
            "envVars": [
                {"key": "PORT", "value": str(config['port'])},
                {"key": "RENDER_ENVIRONMENT", "value": "production"}
            ]
        }
        
        # Add service-specific environment variables
        for key, value in config['env_vars'].items():
            if key != "RENDER_ENVIRONMENT":  # Already added above
                service_config["envVars"].append({"key": key, "value": value})
        
        render_config["services"].append(service_config)
    
    return render_config

def create_service_scripts():
    """Create individual service startup scripts"""
    scripts_dir = Path("render_scripts")
    scripts_dir.mkdir(exist_ok=True)
    
    for service_name, config in RENDER_SERVICES.items():
        script_content = f"""#!/usr/bin/env python3
# Auto-generated script for {service_name}
import os
import sys
from pathlib import Path

# Set environment variables
{chr(10).join([f'os.environ["{key}"] = "{value}"' for key, value in config["env_vars"].items()])}
os.environ["PORT"] = "{config["port"]}"

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import and run the service
try:
    if "{config["script"]}".endswith('.py'):
        script_name = "{config["script"]}"[:-3]
        module = __import__(script_name)
        
        # Check if it's a FastAPI app
        if hasattr(module, 'app'):
            import uvicorn
            port = int(os.getenv("PORT", {config["port"]}))
            print(f"Starting {{script_name}} on port {{port}}...")
            uvicorn.run(module.app, host="0.0.0.0", port=port)
        else:
            print(f"{{script_name}} doesn't have a FastAPI app")
    else:
        print(f"Unsupported script type: {{config["script"]}}")
        
except Exception as e:
    print(f"Failed to start {{service_name}}: {{e}}")
    sys.exit(1)
"""
        
        script_path = scripts_dir / f"start_{service_name}.py"
        with open(script_path, 'w') as f:
            f.write(script_content)
        
        print(f"✅ Created startup script: {script_path}")

def create_deployment_guide():
    """Create deployment guide for multiple services"""
    guide_content = """# Multi-Port Render Deployment Guide

## Overview
This guide explains how to deploy multiple Lavangam backend services on Render, each on different ports.

## Services to Deploy

"""
    
    for service_name, config in RENDER_SERVICES.items():
        guide_content += f"""
### {config['description']} (Port {config['port']})
- **Service Name**: lavangam-{service_name}
- **Script**: {config['script']}
- **Port**: {config['port']}
- **Environment**: {', '.join([f'{k}={v}' for k, v in config['env_vars'].items()])}

"""

    guide_content += """
## Deployment Steps

### 1. Create render.yaml
```bash
python render_multi_port.py --create-yaml
```

### 2. Deploy to Render
```bash
# Option 1: Use Render CLI
render deploy

# Option 2: Use Render Dashboard
# - Go to render.com
# - Create new web service
# - Connect your GitHub repo
# - Use the generated render.yaml
```

### 3. Manual Service Creation (Alternative)
If you prefer to create services manually:

1. Go to render.com dashboard
2. Click "New +" -> "Web Service"
3. Connect your GitHub repository
4. Configure each service:
   - **Name**: lavangam-[service-name]
   - **Environment**: Python
   - **Build Command**: `pip install -r requirements-render.txt`
   - **Start Command**: `python [script-name]`
   - **Port**: [port-number]

### 4. Environment Variables
Set these for each service:
- `PORT`: [service-port]
- `RENDER_ENVIRONMENT`: production
- `DB_HOST`: 44.244.61.85 (if database needed)

## Service URLs
After deployment, your services will be available at:

"""
    
    for service_name, config in RENDER_SERVICES.items():
        guide_content += f"- **{config['description']}**: https://lavangam-{service_name}.onrender.com\n"

    guide_content += """
## Testing
Test each service endpoint:
```bash
# Main backend
curl https://lavangam-main-backend.onrender.com/api/admin/supabase-users

# Analytics API
curl https://lavangam-analytics-api.onrender.com/api/system-metrics

# Dashboard API
curl https://lavangam-dashboard-api.onrender.com/api/dashboard
```

## Monitoring
- Check Render dashboard for service status
- Monitor logs for each service
- Set up alerts for service failures

## Troubleshooting
- If a service fails to start, check the logs
- Verify environment variables are set correctly
- Ensure all dependencies are in requirements-render.txt
"""

    with open("MULTI_PORT_DEPLOYMENT_GUIDE.md", 'w') as f:
        f.write(guide_content)
    
    print("✅ Created deployment guide: MULTI_PORT_DEPLOYMENT_GUIDE.md")

def main():
    """Main function"""
    print("🚀 Lavangam Multi-Port Render Deployment Manager")
    print("=" * 60)
    
    if len(sys.argv) > 1 and sys.argv[1] == "--create-yaml":
        # Create render.yaml
        render_config = create_render_yaml()
        with open("render.yaml", 'w') as f:
            json.dump(render_config, f, indent=2)
        print("✅ Created render.yaml for multiple services")
        
        # Create service scripts
        create_service_scripts()
        
        # Create deployment guide
        create_deployment_guide()
        
        print("\n📋 Next steps:")
        print("1. Review render.yaml")
        print("2. Deploy to Render using: render deploy")
        print("3. Or create services manually using the deployment guide")
        
    else:
        print("Usage: python render_multi_port.py --create-yaml")
        print("\nThis will create:")
        print("- render.yaml for multiple services")
        print("- Individual startup scripts")
        print("- Deployment guide")
        print("\nThen deploy using: render deploy")

if __name__ == "__main__":
    main()
