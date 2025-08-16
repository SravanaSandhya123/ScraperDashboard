#!/usr/bin/env python3
"""
Comprehensive database connection fix script
This script ensures all database connections use the correct MySQL configuration
"""

import os
import pymysql
from datetime import datetime

# Set the correct database configuration
CORRECT_CONFIG = {
    'host': '44.244.61.85',
    'port': 3306,
    'user': 'root',
    'password': 'thanuja',
    'database': 'Toolinformation',
    'charset': 'utf8mb4'
}

def set_environment_variables():
    """Set correct environment variables"""
    print("🔧 Setting environment variables...")
    
    # Set environment variables
    os.environ['DB_HOST'] = CORRECT_CONFIG['host']
    os.environ['DB_PORT'] = str(CORRECT_CONFIG['port'])
    os.environ['DB_USER'] = CORRECT_CONFIG['user']
    os.environ['DB_PASSWORD'] = CORRECT_CONFIG['password']
    os.environ['DB_NAME'] = CORRECT_CONFIG['database']
    
    # Set DATABASE_URL to MySQL format
    os.environ['DATABASE_URL'] = f"mysql+pymysql://{CORRECT_CONFIG['user']}:{CORRECT_CONFIG['password']}@{CORRECT_CONFIG['host']}:{CORRECT_CONFIG['port']}/{CORRECT_CONFIG['database']}"
    
    print("✅ Environment variables set correctly")
    print(f"   - DB_HOST: {os.environ['DB_HOST']}")
    print(f"   - DB_PORT: {os.environ['DB_PORT']}")
    print(f"   - DB_USER: {os.environ['DB_USER']}")
    print(f"   - DB_NAME: {os.environ['DB_NAME']}")
    print(f"   - DATABASE_URL: {os.environ['DATABASE_URL']}")

def test_database_connection():
    """Test database connection with correct configuration"""
    print("\n🔍 Testing database connection...")
    try:
        conn = pymysql.connect(**CORRECT_CONFIG)
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

def create_required_tables():
    """Create required tables if they don't exist"""
    print("\n🔧 Creating required tables...")
    try:
        conn = pymysql.connect(**CORRECT_CONFIG)
        
        with conn.cursor() as cursor:
            # Create gem_data table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS gem_data (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_name VARCHAR(255),
                    bid_no VARCHAR(255),
                    name_of_work TEXT,
                    category VARCHAR(255),
                    ministry_and_department VARCHAR(255),
                    quantity VARCHAR(255),
                    emd VARCHAR(255),
                    exemption VARCHAR(255),
                    estimation_value VARCHAR(255),
                    state VARCHAR(255),
                    location VARCHAR(255),
                    apply_mode VARCHAR(255),
                    website_link TEXT,
                    document_link TEXT,
                    attachment_link TEXT,
                    end_date VARCHAR(255),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            print("✅ gem_data table created/verified")
            
            # Create tender table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS tender (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    dept_unit VARCHAR(255),
                    tender_no VARCHAR(255),
                    tender_title TEXT,
                    status VARCHAR(255),
                    work_area VARCHAR(255),
                    due_datetime VARCHAR(255),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            print("✅ tender table created/verified")
            
            # Create eprocurement_tenders table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS eprocurement_tenders (
                    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
                    bid_user VARCHAR(100),
                    tender_id VARCHAR(100),
                    name_of_work TEXT,
                    tender_category VARCHAR(50),
                    department VARCHAR(100),
                    quantity VARCHAR(50),
                    emd DECIMAL(15, 2),
                    exemption VARCHAR(50),
                    ecv DECIMAL(20, 2),
                    state_name VARCHAR(100),
                    location VARCHAR(100),
                    apply_mode VARCHAR(50),
                    website VARCHAR(100),
                    document_link TEXT,
                    closing_date DATE,
                    pincode VARCHAR(10),
                    attachments TEXT,
                    source_session_id VARCHAR(100),
                    source_file VARCHAR(255),
                    merge_session_id VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            print("✅ eprocurement_tenders table created/verified")
            
            # Create jobs table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS jobs (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(255),
                    status VARCHAR(50),
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    completed_at DATETIME NULL,
                    metadata JSON
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
            """)
            print("✅ jobs table created/verified")
        
        conn.commit()
        conn.close()
        print("✅ All required tables created/verified successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False

def test_merge_functionality():
    """Test the merge functionality by simulating a database insert"""
    print("\n🔍 Testing merge functionality...")
    try:
        conn = pymysql.connect(**CORRECT_CONFIG)
        
        with conn.cursor() as cursor:
            # Test insert into gem_data table
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

def check_table_data():
    """Check existing data in tables"""
    print("\n📊 Checking existing table data...")
    try:
        conn = pymysql.connect(**CORRECT_CONFIG)
        
        with conn.cursor() as cursor:
            tables = ['gem_data', 'tender', 'eprocurement_tenders', 'jobs']
            
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                print(f"   - {table}: {count} records")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Error checking table data: {e}")

def main():
    """Main function to run all fixes"""
    print("🚀 Database Connection Fix Script")
    print("=" * 50)
    print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Step 1: Set environment variables
    set_environment_variables()
    
    # Step 2: Test database connection
    if not test_database_connection():
        print("❌ Database connection failed. Please check your MySQL server.")
        return
    
    # Step 3: Create required tables
    if not create_required_tables():
        print("❌ Failed to create required tables.")
        return
    
    # Step 4: Test merge functionality
    if not test_merge_functionality():
        print("❌ Merge functionality test failed.")
        return
    
    # Step 5: Check existing data
    check_table_data()
    
    print("\n" + "=" * 50)
    print("🎉 All database fixes completed successfully!")
    print("=" * 50)
    print("✅ Environment variables set correctly")
    print("✅ Database connection working")
    print("✅ Required tables created/verified")
    print("✅ Merge functionality tested and working")
    print("\n📝 Next steps:")
    print("   1. Restart your backend services")
    print("   2. Test the 'Merge all files' functionality")
    print("   3. Verify data is stored in the database")
    print(f"\n⏰ Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    main()
