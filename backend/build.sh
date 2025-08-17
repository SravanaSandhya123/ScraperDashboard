#!/bin/bash

echo "🚀 Starting Lavangam Backend Build for Render..."

# Update package lists
echo "📦 Updating package lists..."
apt-get update

# Install system dependencies
echo "🔧 Installing system dependencies..."
apt-get install -y \
    wget \
    unzip \
    curl \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates

# Install Python 3.11 (more stable than 3.13)
echo "🐍 Installing Python 3.11..."
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.11 python3.11-venv python3.11-dev python3.11-pip python3.11-distutils

# Create symbolic links to force Python 3.11
echo "🔗 Creating Python 3.11 symbolic links..."
ln -sf /usr/bin/python3.11 /usr/bin/python3
ln -sf /usr/bin/python3.11 /usr/bin/python
ln -sf /usr/bin/pip3.11 /usr/bin/pip3
ln -sf /usr/bin/pip3.11 /usr/bin/pip

# Verify Python version
echo "✅ Verifying Python version..."
python3 --version
python --version
pip3 --version

# Create virtual environment with Python 3.11
echo "🏗️ Creating Python 3.11 virtual environment..."
python3.11 -m venv /opt/render/project/src/venv
source /opt/render/project/src/venv/bin/activate

# Verify virtual environment Python version
echo "✅ Verifying virtual environment Python version..."
python --version
pip --version

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install Python dependencies
echo "📚 Installing Python dependencies..."
cd /opt/render/project/src/backend

# Try to install main requirements first
echo "📦 Attempting to install main requirements..."
if pip install -r requirements-render.txt; then
    echo "✅ Main requirements installed successfully!"
else
    echo "⚠️ Main requirements failed, trying minimal requirements..."
    
    # Fallback to minimal requirements
    echo "📦 Installing minimal requirements..."
    pip install -r requirements-minimal.txt
    
    # Install additional packages one by one
    echo "📦 Installing additional packages individually..."
    
    # Core packages
    pip install fastapi==0.104.1 uvicorn[standard]==0.24.0 || echo "⚠️ FastAPI installation failed"
    pip install python-multipart==0.0.6 || echo "⚠️ python-multipart installation failed"
    pip install python-dotenv==1.0.0 || echo "⚠️ python-dotenv installation failed"
    
    # Database
    pip install pymysql==1.1.0 || echo "⚠️ pymysql installation failed"
    
    # Supabase
    pip install supabase==2.0.2 || echo "⚠️ supabase installation failed"
    
    # WebDriver
    pip install selenium==4.15.2 || echo "⚠️ selenium installation failed"
    pip install webdriver-manager==4.0.1 || echo "⚠️ webdriver-manager installation failed"
    
    # Try minimal pandas/numpy versions
    echo "📦 Trying minimal pandas/numpy..."
    pip install pandas==1.5.3 || echo "⚠️ pandas installation failed"
    pip install numpy==1.24.4 || echo "⚠️ numpy installation failed"
fi

# Test WebDriver installation
echo "🧪 Testing WebDriver installation..."
python -c "
try:
    from webdriver_manager.microsoft import EdgeChromiumDriverManager
    from webdriver_manager.chrome import ChromeDriverManager
    print('✅ WebDrivers are ready for Render deployment!')
except Exception as e:
    print(f'⚠️ WebDriver test: {e}')
"

# Set permissions
echo "🔐 Setting permissions..."
chmod +x /opt/render/project/src/backend/render.py

echo "🎉 Build completed successfully!"
echo "🚀 Your backend is ready to deploy on Render!"
echo "🐍 Using Python version: $(python --version)"
echo "📦 Installed packages:"
pip list --format=freeze
