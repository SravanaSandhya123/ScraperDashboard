#!/bin/bash
# Render Build Script for Lavangam Backend with WebDriver Support

echo "🚀 Building Lavangam Backend for Render with WebDriver support..."

# Install system dependencies for WebDriver
echo "📦 Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    wget \
    unzip \
    xvfb \
    libxi6 \
    libgconf-2-4 \
    default-jdk \
    default-jre \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    xdg-utils

# Create drivers directory
echo "📁 Creating drivers directory..."
mkdir -p drivers

# Download Edge WebDriver for Linux
echo "📥 Downloading Edge WebDriver for Linux..."
EDGE_VERSION=$(curl -s https://msedgedriver.azureedge.net/LATEST_STABLE)
EDGE_DRIVER_URL="https://msedgedriver.azureedge.net/${EDGE_VERSION}/edgedriver_linux64.zip"

wget -O edge_driver.zip "$EDGE_DRIVER_URL"
unzip -o edge_driver.zip -d drivers/
chmod +x drivers/msedgedriver
rm edge_driver.zip

echo "✅ Edge WebDriver downloaded and configured"

# Download Chrome WebDriver for Linux
echo "📥 Downloading Chrome WebDriver for Linux..."
CHROME_VERSION=$(curl -s https://chromedriver.storage.googleapis.com/LATEST_RELEASE)
CHROME_DRIVER_URL="https://chromedriver.storage.googleapis.com/${CHROME_VERSION}/chromedriver_linux64.zip"

wget -O chrome_driver.zip "$CHROME_DRIVER_URL"
unzip -o chrome_driver.zip -d drivers/
chmod +x drivers/chromedriver
rm chrome_driver.zip

echo "✅ Chrome WebDriver downloaded and configured"

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip install -r requirements-render.txt

# Test WebDriver installation
echo "🧪 Testing WebDriver installation..."
python -c "
from webdriver_manager import test_webdrivers
success = test_webdrivers()
if success:
    print('✅ WebDriver test passed!')
else:
    print('❌ WebDriver test failed!')
    exit(1)
"

echo "🎉 Build completed successfully!"
echo "🔧 WebDrivers are ready for Render deployment"
