#!/usr/bin/env python3
"""
Quick test script to verify all fixes are working
"""

import requests
import time
from datetime import datetime

def test_database_connection():
    """Test database connection"""
    print("🔍 Testing database connection...")
    try:
        import pymysql
        conn = pymysql.connect(
            host='44.244.61.85',
            port=3306,
            user='root',
            password='thanuja',
            database='Toolinformation',
            charset='utf8mb4'
        )
        print("✅ Database connection successful!")
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def test_admin_metrics_api():
    """Test admin metrics API"""
    print("\n🔍 Testing admin metrics API...")
    try:
        base_url = "http://44.244.61.85:8001"
        
        # Test health endpoint
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint working")
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
        
        # Test real-time system resources
        start_time = time.time()
        response = requests.get(f"{base_url}/system-resources-realtime", timeout=5)
        end_time = time.time()
        
        if response.status_code == 200:
            print(f"✅ Real-time system resources working (took {end_time - start_time:.2f}s)")
            data = response.json()
            print(f"🖥️  CPU: {data.get('cpu_percent', 'N/A')}%")
            print(f"💾 Memory: {data.get('memory_percent', 'N/A')}%")
            print(f"💿 Disk: {data.get('disk_percent', 'N/A')}%")
            return True
        else:
            print(f"❌ Real-time system resources failed: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ API request failed: {e}")
        return False

def test_phpmyadmin_access():
    """Test phpMyAdmin access"""
    print("\n🔍 Testing phpMyAdmin access...")
    try:
        response = requests.get("http://44.244.61.85/phpmyadmin/", timeout=5)
        if response.status_code == 200:
            print("✅ phpMyAdmin accessible")
            return True
        else:
            print(f"❌ phpMyAdmin access failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ phpMyAdmin request failed: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Quick Test of All Fixes")
    print("=" * 40)
    print(f"⏰ Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test database connection
    db_success = test_database_connection()
    
    # Test admin metrics API
    api_success = test_admin_metrics_api()
    
    # Test phpMyAdmin access
    phpmyadmin_success = test_phpmyadmin_access()
    
    # Summary
    print("\n" + "=" * 40)
    print("📋 QUICK TEST SUMMARY")
    print("=" * 40)
    print(f"🗄️  Database Connection: {'✅ PASS' if db_success else '❌ FAIL'}")
    print(f"📊 Admin Metrics API: {'✅ PASS' if api_success else '❌ FAIL'}")
    print(f"🌐 phpMyAdmin Access: {'✅ PASS' if phpmyadmin_success else '❌ FAIL'}")
    
    if db_success and api_success and phpmyadmin_success:
        print("\n🎉 All tests passed! The fixes are working correctly.")
        print("\n📝 Next steps:")
        print("   1. Access the admin panel: http://44.244.61.85:3000/dashboard")
        print("   2. Check System Resources chart shows real-time data")
        print("   3. Test 'Merge all files' in GEM tool")
        print("   4. Verify data is stored in database")
    else:
        print("\n⚠️  Some tests failed. Please check the errors above.")
    
    print(f"\n⏰ Test completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
