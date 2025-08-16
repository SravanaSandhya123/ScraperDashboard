#!/usr/bin/env python3
"""
Test MySQL database connection with correct settings
"""

import os
import mysql.connector
from datetime import datetime

# Set the correct database configuration
DB_CONFIG = {
    'host': '44.244.61.85',
    'port': 3306,
    'user': 'root',
    'password': 'thanuja',
    'database': 'Toolinformation'
}

def test_connection():
    """Test MySQL database connection"""
    print("🔍 Testing MySQL Database Connection...")
    print(f"Host: {DB_CONFIG['host']}")
    print(f"Port: {DB_CONFIG['port']}")
    print(f"Database: {DB_CONFIG['database']}")
    print(f"User: {DB_CONFIG['user']}")
    
    try:
        # Test connection
        conn = mysql.connector.connect(**DB_CONFIG)
        print("✅ Database connection successful!")
        
        # Test cursor
        cursor = conn.cursor()
        
        # Check if eprocurement_tenders table exists
        cursor.execute("SHOW TABLES LIKE 'eprocurement_tenders'")
        table_exists = cursor.fetchone()
        
        if table_exists:
            print("✅ eprocurement_tenders table exists")
            
            # Count records
            cursor.execute("SELECT COUNT(*) FROM eprocurement_tenders")
            count = cursor.fetchone()[0]
            print(f"✅ Current records in table: {count}")
        else:
            print("⚠️ eprocurement_tenders table does not exist")
            
            # Create the table
            print("📝 Creating eprocurement_tenders table...")
            create_table_sql = """
            CREATE TABLE IF NOT EXISTS eprocurement_tenders (
                id VARCHAR(36) PRIMARY KEY,
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
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_tender_id (tender_id),
                INDEX idx_merge_session (merge_session_id),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """
            cursor.execute(create_table_sql)
            conn.commit()
            print("✅ eprocurement_tenders table created successfully")
        
        cursor.close()
        conn.close()
        print("✅ All tests passed!")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    exit(0 if success else 1)
