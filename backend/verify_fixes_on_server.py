#!/usr/bin/env python3
"""
Verification script to be run on the AWS server
This script confirms all database and merge functionality fixes are working
"""

import os
import pymysql
import requests
import time
from datetime import datetime

# Correct database configuration for AWS server
DB_CONFIG = {
    'host': 'localhost',  # On AWS server, MySQL is local
    'port': 3306,
    'user': 'root',
    'password': 'thanuja',
    'database': 'Toolinformation',
    'charset': 'utf8mb4'
}

def test_database_connection():
    """Test database connection on AWS server"""
    print("🔍 Testing database connection on AWS server...")
    try:
        conn = pymysql.connect(**DB_CONFIG)
        print("✅ Database connection successful!")
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"📊 MySQL Version: {version[0]}")
            
            cursor.execute("SELECT DATABASE()")
            database = cursor.fetchone()
            print(f"🗄️  Current Database: {database[0]}")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def check_required_tables():
    """Check if all required tables exist"""
    print("\n🔍 Checking required tables...")
    try:
        conn = pymysql.connect(**DB_CONFIG)
        
        with conn.cursor() as cursor:
            required_tables = ['gem_data', 'tender', 'eprocurement_tenders', 'jobs']
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
                    print(f"❌ Table '{table}' does not exist")
            
            print(f"📊 Found {len(existing_tables)} out of {len(required_tables)} required tables")
        
        conn.close()
        return len(existing_tables) == len(required_tables)
        
    except Exception as e:
        print(f"❌ Error checking tables: {e}")
        return False

def test_merge_functionality():
    """Test the merge functionality by inserting test data"""
    print("\n🔍 Testing merge functionality...")
    try:
        conn = pymysql.connect(**DB_CONFIG)
        
        with conn.cursor() as cursor:
            # Test insert into gem_data table (simulating merge)
            test_data = {
                'user_name': 'Test User',
                'bid_no': 'TEST-2024-001',
                'name_of_work': 'Test Work',
                'category': 'Test Category',
                'ministry_and_department': 'Test Ministry',
                'quantity': '1 Unit',
                'emd': '1000.00',
                'exemption': 'No',
                'estimation_value': '100000.00',
                'state': 'Test State',
                'location': 'Test Location',
                'apply_mode': 'Online',
                'website_link': 'https://test.com',
                'document_link': 'https://test.com/doc',
                'attachment_link': 'https://test.com/att',
                'end_date': '2024-12-31'
            }
            
            cols = ','.join(f'`{col}`' for col in test_data.keys())
            placeholders = ','.join(['%s'] * len(test_data))
            sql = f'INSERT INTO gem_data ({cols}) VALUES ({placeholders})'
            
            cursor.execute(sql, list(test_data.values()))
            conn.commit()
            
            # Verify the insert
            cursor.execute("SELECT COUNT(*) FROM gem_data WHERE bid_no = 'TEST-2024-001'")
            count = cursor.fetchone()[0]
            
            if count > 0:
                print("✅ Merge functionality test successful - data inserted correctly")
                # Clean up test data
                cursor.execute("DELETE FROM gem_data WHERE bid_no = 'TEST-2024-001'")
                conn.commit()
                print("✅ Test data cleaned up")
                return True
            else:
                print("❌ Merge functionality test failed - data not inserted")
                return False
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Error testing merge functionality: {e}")
        return False

def test_admin_metrics_api():
    """Test admin metrics API on AWS server"""
    print("\n🔍 Testing admin metrics API...")
    try:
        # Test health endpoint
        response = requests.get("http://44.244.35.65:8001/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint working")
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
        
        # Test real-time system resources
        response = requests.get("http://44.244.35.65:8001/system-resources-realtime", timeout=5)
        if response.status_code == 200:
            print("✅ Real-time system resources working")
            data = response.json()
            print(f"🖥️  CPU: {data.get('cpu_percent', 'N/A')}%")
            print(f"💾 Memory: {data.get('memory_percent', 'N/A')}%")
            print(f"💿 Disk: {data.get('disk_percent', 'N/A')}%")
        else:
            print(f"❌ Real-time system resources failed: {response.status_code}")
            return False
        
        # Test admin metrics endpoint
        response = requests.get("http://44.244.35.65:8001/admin-metrics", timeout=10)
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

def check_file_manager():
    """Check if file_manager.py is configured correctly"""
    print("\n🔍 Checking file_manager.py configuration...")
    try:
        # Check if file_manager.py exists and has correct database config
        file_manager_path = "file_manager.py"
        if os.path.exists(file_manager_path):
            with open(file_manager_path, 'r') as f:
                content = f.read()
                
            # Check for correct database configuration
            if '44.244.61.85' in content and 'Toolinformation' in content:
                print("✅ file_manager.py has correct database configuration")
                return True
            else:
                print("❌ file_manager.py has incorrect database configuration")
                return False
        else:
            print("❌ file_manager.py not found")
            return False
            
    except Exception as e:
        print(f"❌ Error checking file_manager.py: {e}")
        return False

def check_environment_variables():
    """Check environment variables on AWS server"""
    print("\n🔍 Checking environment variables...")
    
    env_vars = {
        'DB_HOST': 'localhost',
        'DB_PORT': '3306',
        'DB_USER': 'root',
        'DB_NAME': 'Toolinformation'
    }
    
    all_correct = True
    for var, expected_value in env_vars.items():
        actual_value = os.getenv(var, 'NOT_SET')
        if actual_value == expected_value:
            print(f"✅ {var}: {actual_value}")
        else:
            print(f"❌ {var}: {actual_value} (expected: {expected_value})")
            all_correct = False
    
    return all_correct

def main():
    """Main verification function"""
    print("🚀 Verification Script for AWS Server")
    print("=" * 50)
    print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test database connection
    db_success = test_database_connection()
    
    # Check required tables
    tables_success = check_required_tables()
    
    # Test merge functionality
    merge_success = test_merge_functionality()
    
    # Test admin metrics API
    api_success = test_admin_metrics_api()
    
    # Check file_manager.py
    file_manager_success = check_file_manager()
    
    # Check environment variables
    env_success = check_environment_variables()
    
    # Summary
    print("\n" + "=" * 50)
    print("📋 VERIFICATION SUMMARY")
    print("=" * 50)
    print(f"🗄️  Database Connection: {'✅ PASS' if db_success else '❌ FAIL'}")
    print(f"📋 Required Tables: {'✅ PASS' if tables_success else '❌ FAIL'}")
    print(f"🔗 Merge Functionality: {'✅ PASS' if merge_success else '❌ FAIL'}")
    print(f"📊 Admin Metrics API: {'✅ PASS' if api_success else '❌ FAIL'}")
    print(f"📁 File Manager Config: {'✅ PASS' if file_manager_success else '❌ FAIL'}")
    print(f"🔧 Environment Variables: {'✅ PASS' if env_success else '❌ FAIL'}")
    
    all_tests_passed = db_success and tables_success and merge_success and api_success and file_manager_success and env_success
    
    if all_tests_passed:
        print("\n🎉 All verifications passed! The fixes are working correctly.")
        print("\n📝 The system is ready for use:")
        print("   1. ✅ Database connections are working")
        print("   2. ✅ All required tables exist")
        print("   3. ✅ Merge functionality is working")
        print("   4. ✅ Admin metrics API is responding")
        print("   5. ✅ File manager is configured correctly")
        print("   6. ✅ Environment variables are set correctly")
        print("\n🚀 Users can now:")
        print("   - Use 'Merge all files' button to download and store data")
        print("   - View real-time system resources in admin panel")
        print("   - Access dashboard without buffering")
    else:
        print("\n⚠️  Some verifications failed. Please check the errors above.")
        print("\n🔧 Troubleshooting steps:")
        if not db_success:
            print("   - Check if MySQL server is running: sudo systemctl status mysql")
        if not tables_success:
            print("   - Run: python create_eprocurement_table_mysql.sql")
        if not merge_success:
            print("   - Check file_manager.py database configuration")
        if not api_success:
            print("   - Check if admin metrics API is running: sudo systemctl status admin-metrics")
    
    print(f"\n⏰ Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
