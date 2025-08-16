#!/usr/bin/env python3
"""
Fixed Database Configuration - Supports both local and remote databases
"""

import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration with fallback options
class DatabaseConfig:
    def __init__(self):
        # Try to get database type from environment
        self.db_type = os.getenv('DB_TYPE', 'mysql').lower()
        
        if self.db_type == 'postgresql':
            self.config = self._get_postgresql_config()
        else:
            self.config = self._get_mysql_config()
    
    def _get_mysql_config(self):
        """Get MySQL configuration with fallback options"""
        return {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', '3306')),
            'user': os.getenv('DB_USER', 'root'),
            'password': os.getenv('DB_PASSWORD', ''),
            'database': os.getenv('DB_NAME', 'Toolinformation'),
            'charset': 'utf8mb4'
        }
    
    def _get_postgresql_config(self):
        """Get PostgreSQL configuration"""
        return {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', '5432')),
            'user': os.getenv('DB_USER', 'username'),
            'password': os.getenv('DB_PASSWORD', 'password'),
            'database': os.getenv('DB_NAME', 'scraper_db')
        }
    
    def get_connection_params(self):
        """Get connection parameters for the current database type"""
        return self.config.copy()
    
    def get_connection_string(self):
        """Get connection string for the current database type"""
        if self.db_type == 'postgresql':
            return f"postgresql://{self.config['user']}:{self.config['password']}@{self.config['host']}:{self.config['port']}/{self.config['database']}"
        else:
            return f"mysql+pymysql://{self.config['user']}:{self.config['password']}@{self.config['host']}:{self.config['port']}/{self.config['database']}"
    
    def test_connection(self):
        """Test database connection"""
        try:
            if self.db_type == 'postgresql':
                import psycopg2
                conn = psycopg2.connect(**self.config)
            else:
                import mysql.connector
                conn = mysql.connector.connect(**self.config)
            
            conn.close()
            return True, f"✅ {self.db_type.upper()} connection successful"
        except Exception as e:
            return False, f"❌ {self.db_type.upper()} connection failed: {e}"

# Create global instance
db_config = DatabaseConfig()

# Export configuration
DATABASE_CONFIG = db_config.get_connection_params()
DATABASE_URL = db_config.get_connection_string()
DB_TYPE = db_config.db_type

def test_database_connection():
    """Test database connection and return status"""
    return db_config.test_connection()

def get_mysql_connection_params():
    """Get MySQL connection parameters (for backward compatibility)"""
    if db_config.db_type == 'mysql':
        return db_config.get_connection_params()
    else:
        # Return default MySQL config for fallback
        return {
            'host': 'localhost',
            'port': 3306,
            'user': 'root',
            'password': '',
            'database': 'Toolinformation',
            'charset': 'utf8mb4'
        }

if __name__ == "__main__":
    print("🔍 Database Configuration Test")
    print("=" * 50)
    print(f"Database Type: {DB_TYPE}")
    print(f"Host: {DATABASE_CONFIG.get('host', 'N/A')}")
    print(f"Port: {DATABASE_CONFIG.get('port', 'N/A')}")
    print(f"Database: {DATABASE_CONFIG.get('database', 'N/A')}")
    print(f"User: {DATABASE_CONFIG.get('user', 'N/A')}")
    print(f"Connection String: {DATABASE_URL}")
    print("-" * 50)
    
    success, message = test_database_connection()
    print(message)
