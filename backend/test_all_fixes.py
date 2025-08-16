#!/usr/bin/env python3
"""
Comprehensive test script to verify all fixes are working
"""

import requests
import time
import pymysql
from datetime import datetime
import os

def test_database_connection():
    """Test database connection to new IP"""
    print("🔍 Testing database connection to 44.244.61.85...")
    try:
        conn = pymysql.connect(
            host='44.244.61.85',
            port=3306,
            user='root',
            password='thanuja',
            database='Toolinformation',
            charset='utf8mb4'
        )
        print("✅ Database connection successful!")
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"📊 MySQL Version: {version[0]}")
            
            # Test database size
            cursor.execute("""
                SELECT 
                    COALESCE(SUM(data_length + index_length), 0) AS total_bytes
                FROM information_schema.tables 
                WHERE table_schema = 'Toolinformation'
            """)
            result = cursor.fetchone()
            total_bytes = result[0] if result else 0
            print(f"💾 Database size: {total_bytes} bytes")
        
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
        print("📡 Testing health endpoint...")
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint working")
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
        
        # Test real-time system resources
        print("📡 Testing real-time system resources...")
        start_time = time.time()
        response = requests.get(f"{base_url}/system-resources-realtime", timeout=5)
        end_time = time.time()
        
        if response.status_code == 200:
            print(f"✅ Real-time system resources working (took {end_time - start_time:.2f}s)")
            data = response.json()
            print(f"🖥️  CPU: {data.get('cpu_percent', 'N/A')}%")
            print(f"💾 Memory: {data.get('memory_percent', 'N/A')}%")
            print(f"💿 Disk: {data.get('disk_percent', 'N/A')}%")
        else:
            print(f"❌ Real-time system resources failed: {response.status_code}")
            return False
        
        # Test admin metrics endpoint
        print("📡 Testing admin metrics endpoint...")
        response = requests.get(f"{base_url}/admin-metrics", timeout=10)
        if response.status_code == 200:
            print("✅ Admin metrics endpoint working")
            data = response.json()
            if 'system_load' in data:
                print(f"🖥️  System Load: {data['system_load']}")
            if 'database_size' in data:
                print(f"🗄️  Database Size: {data['database_size']}")
            if 'jobs_info' in data:
                print(f"⚡ Jobs Info: {data['jobs_info']}")
        else:
            print(f"❌ Admin metrics endpoint failed: {response.status_code}")
            return False
            
        return True
            
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

def test_database_tables():
    """Test if required database tables exist"""
    print("\n🔍 Testing database tables...")
    try:
        conn = pymysql.connect(
            host='44.244.61.85',
            port=3306,
            user='root',
            password='thanuja',
            database='Toolinformation',
            charset='utf8mb4'
        )
        
        with conn.cursor() as cursor:
            # Check for required tables
            required_tables = ['gem_data', 'tender', 'eprocurement_tenders', 'users', 'tools', 'jobs']
            existing_tables = []
            
            for table in required_tables:
                cursor.execute("""
                    SELECT COUNT(*) as table_exists 
                    FROM information_schema.tables 
                    WHERE table_schema = 'Toolinformation' AND table_name = %s
                """, (table,))
                result = cursor.fetchone()
                if result and result[0] > 0:
                    existing_tables.append(table)
                    print(f"✅ Table '{table}' exists")
                else:
                    print(f"⚠️  Table '{table}' does not exist")
            
            print(f"📊 Found {len(existing_tables)} out of {len(required_tables)} required tables")
        
        conn.close()
        return len(existing_tables) >= 3  # At least gem_data, tender, and eprocurement_tenders should exist
        
    except Exception as e:
        print(f"❌ Database table check failed: {e}")
        return False

def test_file_manager_connection():
    """Test if file_manager.py can connect to database"""
    print("\n🔍 Testing file_manager.py database connection...")
    try:
        # Import and test the database connection from file_manager
        import sys
        sys.path.append('.')
        
        # Test the connection parameters that file_manager uses
        conn = pymysql.connect(
            host='44.244.61.85',
            port=3306,
            user='root',
            password='thanuja',
            db='Toolinformation',
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1 as test")
            result = cursor.fetchone()
            if result and result['test'] == 1:
                print("✅ file_manager.py database connection test passed")
                return True
            else:
                print("❌ file_manager.py database connection test failed")
                return False
        
        conn.close()
        
    except Exception as e:
        print(f"❌ file_manager.py database connection failed: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Comprehensive Test of All Fixes")
    print("=" * 50)
    print(f"⏰ Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test database connection
    db_success = test_database_connection()
    
    # Test admin metrics API
    api_success = test_admin_metrics_api()
    
    # Test phpMyAdmin access
    phpmyadmin_success = test_phpmyadmin_access()
    
    # Test database tables
    tables_success = test_database_tables()
    
    # Test file_manager connection
    file_manager_success = test_file_manager_connection()
    
    # Summary
    print("\n" + "=" * 50)
    print("📋 COMPREHENSIVE TEST SUMMARY")
    print("=" * 50)
    print(f"🗄️  Database Connection: {'✅ PASS' if db_success else '❌ FAIL'}")
    print(f"📊 Admin Metrics API: {'✅ PASS' if api_success else '❌ FAIL'}")
    print(f"🌐 phpMyAdmin Access: {'✅ PASS' if phpmyadmin_success else '❌ FAIL'}")
    print(f"📋 Database Tables: {'✅ PASS' if tables_success else '❌ FAIL'}")
    print(f"📁 File Manager DB: {'✅ PASS' if file_manager_success else '❌ FAIL'}")
    
    all_tests_passed = db_success and api_success and phpmyadmin_success and tables_success and file_manager_success
    
    if all_tests_passed:
        print("\n🎉 All tests passed! The fixes are working correctly.")
        print("\n📝 Next steps:")
        print("   1. Access the admin panel: http://44.244.61.85:3000/dashboard")
        print("   2. Check System Resources chart shows real-time data")
        print("   3. Test 'Merge all files' in GEM tool")
        print("   4. Verify data is stored in database")
        print("   5. Check phpMyAdmin: http://44.244.61.85/phpmyadmin/")
    else:
        print("\n⚠️  Some tests failed. Please check the errors above.")
        print("\n🔧 Troubleshooting:")
        if not db_success:
            print("   - Check if MySQL server is running on 44.244.61.85:3306")
        if not api_success:
            print("   - Check if admin metrics API is running on port 8001")
        if not file_manager_success:
            print("   - Check file_manager.py database configuration")
    
    print(f"\n⏰ Test completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
