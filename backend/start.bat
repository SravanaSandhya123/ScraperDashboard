@echo off
echo 🚀 Starting Lavangam Backend...

REM Check if we're in the right directory
if not exist "render.py" (
    echo ❌ render.py not found. Changing to backend directory...
    cd backend
)

REM Check Python version
python -c "import sys; print(f'🐍 Python version: {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"

REM Verify critical packages
echo 🔍 Verifying critical packages...
python -c "
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

REM Set environment variables
set PORT=8000
set RENDER_ENVIRONMENT=development

echo 🌐 Starting server on port %PORT%...
echo 🏭 Environment: %RENDER_ENVIRONMENT%

REM Start the application
python render.py
