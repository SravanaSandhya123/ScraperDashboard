#!/usr/bin/env bash
# Build script for Render deployment

echo "🚀 Starting Lavangam Backend build process..."

# Check Python version
python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "🐍 Python version: $python_version"

# Upgrade pip to latest version
echo "📦 Upgrading pip..."
python3 -m pip install --upgrade pip

# Install wheel and setuptools first
echo "🔧 Installing build dependencies..."
python3 -m pip install --upgrade wheel setuptools

# Install requirements with specific flags for Python 3.13
echo "📦 Installing Python packages..."
if [[ "$python_version" == "3.13" ]]; then
    echo "⚠️ Python 3.13 detected - using compatibility flags..."
    python3 -m pip install -r requirements-render.txt --no-cache-dir --force-reinstall
else
    python3 -m pip install -r requirements-render.txt
fi

# Verify critical packages
echo "🔍 Verifying critical packages..."
python3 -c "
import sys
packages = ['fastapi', 'uvicorn', 'psutil', 'pandas', 'numpy', 'dotenv']
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} imported successfully')
    except ImportError:
        missing.append(pkg)
        print(f'❌ {pkg} import failed')

if missing:
    print(f'❌ Missing packages: {missing}')
    sys.exit(1)
else:
    print('✅ All critical packages verified')
"

echo "✅ Build process completed successfully!"
