#!/usr/bin/env python3
"""
Test script to verify database connection and admin metrics fixes
"""

import requests
import json
import time
from datetime import datetime

def test_database_connection():
    """Test the database connection"""
    print("🔍 Testing database connection...")
    
    try:
        import pymysql
        
        # Use the updated database configuration
        params = {
            'host': '44.244.61.85',
            'port': 3306,
            'user': 'root',
            'password': 'thanuja',
            'database': 'Toolinformation',
            'charset': 'utf8mb4'
        }
        
        print(f"📡 Connecting to: {params['host']}:{params['port']}/{params['database']}")
        
        conn = pymysql.connect(**params)
        print("✅ Database connection successful!")
        
        with conn.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"📊 MySQL Version: {version[0]}")
            
            # Test database size query
            cursor.execute("""
                SELECT 
                    COALESCE(SUM(data_length + index_length), 0) AS total_bytes
                FROM information_schema.tables 
                WHERE table_schema = %s
            """, (params['database'],))
            
            result = cursor.fetchone()
            total_bytes = result[0] if result else 0
            print(f"💾 Database size: {total_bytes} bytes")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def test_admin_metrics_api():
    """Test the admin metrics API"""
    print("\n🔍 Testing admin metrics API...")
    
    try:
        # Test admin metrics API on AWS server
        base_url = "http://44.244.61.85:8001"
        
        # Test health endpoint
        print("📡 Testing health endpoint...")
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint working")
            print(f"📊 Health data: {response.json()}")
        else:
            print(f"❌ Health endpoint failed: {response.status_code}")
            return False
        
        # Test admin metrics endpoint
        print("📡 Testing admin metrics endpoint...")
        start_time = time.time()
        response = requests.get(f"{base_url}/admin-metrics", timeout=10)
        end_time = time.time()
        
        if response.status_code == 200:
            print(f"✅ Admin metrics endpoint working (took {end_time - start_time:.2f}s)")
            data = response.json()
            
            # Check system load
            if 'system_load' in data:
                system_load = data['system_load']
                print(f"🖥️  CPU: {system_load.get('cpu_percent', 'N/A')}%")
                print(f"💾 Memory: {system_load.get('memory_percent', 'N/A')}%")
                print(f"💿 Disk: {system_load.get('disk_percent', 'N/A')}%")
            
            # Check database size
            if 'database_size' in data:
                db_size = data['database_size']
                print(f"🗄️  Database: {db_size.get('total_size', 'N/A')}")
                print(f"📈 Today's growth: {db_size.get('today_growth', 'N/A')}")
            
            # Check jobs info
            if 'jobs_info' in data:
                jobs = data['jobs_info']
                print(f"⚡ Active jobs: {jobs.get('active_jobs', 'N/A')}")
                print(f"📋 Queued jobs: {jobs.get('queued_jobs', 'N/A')}")
            
            return True
        else:
            print(f"❌ Admin metrics endpoint failed: {response.status_code}")
            print(f"Error: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ API request failed: {e}")
        return False

def test_real_time_endpoints():
    """Test real-time endpoints"""
    print("\n🔍 Testing real-time endpoints...")
    
    try:
        base_url = "http://44.244.61.85:8001"
        
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
        
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Real-time API request failed: {e}")
        return False

def main():
    """Main test function"""
    print("🚀 Starting database and admin metrics tests...")
    print(f"⏰ Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test database connection
    db_success = test_database_connection()
    
    # Test admin metrics API
    api_success = test_admin_metrics_api()
    
    # Test real-time endpoints
    realtime_success = test_real_time_endpoints()
    
    # Summary
    print("\n" + "="*50)
    print("📋 TEST SUMMARY")
    print("="*50)
    print(f"🗄️  Database Connection: {'✅ PASS' if db_success else '❌ FAIL'}")
    print(f"📊 Admin Metrics API: {'✅ PASS' if api_success else '❌ FAIL'}")
    print(f"⚡ Real-time Endpoints: {'✅ PASS' if realtime_success else '❌ FAIL'}")
    
    if db_success and api_success and realtime_success:
        print("\n🎉 All tests passed! The fixes are working correctly.")
    else:
        print("\n⚠️  Some tests failed. Please check the errors above.")
    
    print(f"⏰ Test completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
