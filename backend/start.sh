#!/usr/bin/env bash
# Startup script for Lavangam Backend on Render

echo "🚀 Starting Lavangam Backend..."

# Check if we're in the right directory
if [ ! -f "render.py" ]; then
    echo "❌ render.py not found. Changing to backend directory..."
    cd backend || exit 1
fi

# Check Python version
python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "🐍 Python version: $python_version"

# Verify critical packages are installed
echo "🔍 Verifying critical packages..."
python3 -c "
import sys
critical_packages = ['fastapi', 'uvicorn', 'psutil', 'dotenv']
missing = []

for pkg in critical_packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} available')
    except ImportError as e:
        missing.append(pkg)
        print(f'❌ {pkg} missing: {e}')

if missing:
    print(f'❌ Critical packages missing: {missing}')
    print('🔄 Attempting to install missing packages...')
    import subprocess
    try:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', 'requirements-minimal.txt'])
        print('✅ Missing packages installed')
    except Exception as e:
        print(f'❌ Failed to install packages: {e}')
        sys.exit(1)
else:
    print('✅ All critical packages available')
"

# Set environment variables if not set
export PORT=${PORT:-8000}
export RENDER_ENVIRONMENT=${RENDER_ENVIRONMENT:-production}

echo "🌐 Starting server on port $PORT..."
echo "🏭 Environment: $RENDER_ENVIRONMENT"

# Start the application
exec python3 render.py
