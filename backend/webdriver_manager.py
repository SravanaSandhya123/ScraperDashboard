#!/usr/bin/env python3
"""
WebDriver Manager for Render Deployment
Automatically downloads and manages Linux-compatible drivers
"""

import os
import sys
import platform
from pathlib import Path
from webdriver_manager.microsoft import EdgeChromiumDriverManager
from webdriver_manager.chrome import ChromeDriverManager
from selenium import webdriver
from selenium.webdriver.edge.service import Service as EdgeService
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.edge.options import Options as EdgeOptions
from selenium.webdriver.chrome.options import Options as ChromeOptions

class RenderWebDriverManager:
    """Manages WebDriver installation and configuration for Render"""
    
    def __init__(self):
        self.is_render = os.environ.get('RENDER_ENVIRONMENT') == 'production'
        self.drivers_dir = Path(__file__).parent / "drivers"
        self.drivers_dir.mkdir(exist_ok=True)
        
    def get_edge_driver(self, headless=True):
        """Get Edge WebDriver with automatic driver management"""
        try:
            print("🔧 Setting up Edge WebDriver for Render...")
            
            # Create Edge options
            options = EdgeOptions()
            
            # Render-specific options
            if self.is_render or headless:
                options.add_argument('--headless')
                options.add_argument('--no-sandbox')
                options.add_argument('--disable-dev-shm-usage')
                options.add_argument('--disable-gpu')
                options.add_argument('--disable-extensions')
                options.add_argument('--disable-plugins')
                options.add_argument('--disable-images')
                options.add_experimental_option("excludeSwitches", ["enable-automation"])
                options.add_experimental_option('useAutomationExtension', False)
                print("✅ Edge options configured for Render environment")
            
            # Download driver automatically
            if self.is_render:
                print("📥 Downloading Edge driver for Linux...")
                driver_path = EdgeChromiumDriverManager().install()
                print(f"✅ Edge driver downloaded: {driver_path}")
            else:
                # Local development - use existing driver
                driver_path = Path(__file__).parent / "scrapers" / "edgedriver_win64" / "msedgedriver.exe"
                if not driver_path.exists():
                    print("⚠️ Local Edge driver not found, downloading...")
                    driver_path = EdgeChromiumDriverManager().install()
            
            # Create service and driver
            service = EdgeService(executable_path=str(driver_path))
            driver = webdriver.Edge(service=service, options=options)
            
            print("✅ Edge WebDriver created successfully!")
            return driver
            
        except Exception as e:
            print(f"❌ Failed to create Edge WebDriver: {e}")
            raise
    
    def get_chrome_driver(self, headless=True):
        """Get Chrome WebDriver with automatic driver management"""
        try:
            print("🔧 Setting up Chrome WebDriver for Render...")
            
            # Create Chrome options
            options = ChromeOptions()
            
            # Render-specific options
            if self.is_render or headless:
                options.add_argument('--headless')
                options.add_argument('--no-sandbox')
                options.add_argument('--disable-dev-shm-usage')
                options.add_argument('--disable-gpu')
                options.add_argument('--disable-extensions')
                options.add_argument('--disable-plugins')
                options.add_argument('--disable-images')
                options.add_experimental_option("excludeSwitches", ["enable-automation"])
                options.add_experimental_option('useAutomationExtension', False)
                print("✅ Chrome options configured for Render environment")
            
            # Download driver automatically
            if self.is_render:
                print("📥 Downloading Chrome driver for Linux...")
                driver_path = ChromeDriverManager().install()
                print(f"✅ Chrome driver downloaded: {driver_path}")
            else:
                # Local development - use existing driver
                driver_path = Path(__file__).parent / "scrapers" / "edgedriver_win64" / "chromedriver.exe"
                if not driver_path.exists():
                    print("⚠️ Local Chrome driver not found, downloading...")
                    driver_path = ChromeDriverManager().install()
            
            # Create service and driver
            service = ChromeService(executable_path=str(driver_path))
            driver = webdriver.Chrome(service=service, options=options)
            
            print("✅ Chrome WebDriver created successfully!")
            return driver
            
        except Exception as e:
            print(f"❌ Failed to create Chrome WebDriver: {e}")
            raise
    
    def test_drivers(self):
        """Test if WebDrivers are working correctly"""
        print("🧪 Testing WebDrivers...")
        
        try:
            # Test Edge
            print("\n🔧 Testing Edge WebDriver...")
            edge_driver = self.get_edge_driver(headless=True)
            edge_driver.get("https://www.google.com")
            title = edge_driver.title
            edge_driver.quit()
            print(f"✅ Edge test successful: {title}")
            
            # Test Chrome
            print("\n🔧 Testing Chrome WebDriver...")
            chrome_driver = self.get_chrome_driver(headless=True)
            chrome_driver.get("https://www.google.com")
            title = chrome_driver.title
            chrome_driver.quit()
            print(f"✅ Chrome test successful: {title}")
            
            print("\n🎉 All WebDriver tests passed!")
            return True
            
        except Exception as e:
            print(f"\n❌ WebDriver test failed: {e}")
            return False

# Global instance
webdriver_manager = RenderWebDriverManager()

# Convenience functions
def get_edge_driver(headless=True):
    """Get Edge WebDriver instance"""
    return webdriver_manager.get_edge_driver(headless)

def get_chrome_driver(headless=True):
    """Get Chrome WebDriver instance"""
    return webdriver_manager.get_chrome_driver(headless)

def test_webdrivers():
    """Test all WebDrivers"""
    return webdriver_manager.test_drivers()

if __name__ == "__main__":
    print("🚀 Testing WebDriver Manager for Render...")
    success = test_webdrivers()
    if success:
        print("✅ WebDriver Manager is ready for Render deployment!")
    else:
        print("❌ WebDriver Manager needs configuration!")
