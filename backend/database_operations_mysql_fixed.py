#!/usr/bin/env python3
"""
Fixed MySQL Database Operations - Handles date formats and multiple tools
"""

import os
import uuid
import logging
from datetime import datetime
import mysql.connector
from mysql.connector import Error
import pandas as pd

logger = logging.getLogger(__name__)

class EProcurementDBMySQL:
    def __init__(self):
        self.config = {
            'host': os.getenv('DB_HOST', '44.244.61.85'),
            'port': int(os.getenv('DB_PORT', '3306')),
            'user': os.getenv('DB_USER', 'root'),
            'password': os.getenv('DB_PASSWORD', 'thanuja'),
            'database': os.getenv('DB_NAME', 'Toolinformation'),
            'charset': 'utf8mb4'
        }
    
    def get_connection(self):
        """Get database connection"""
        try:
            return mysql.connector.connect(**self.config)
        except Error as e:
            logger.error(f"Error connecting to MySQL: {e}")
            raise
    
    def create_table_if_not_exists(self):
        """Create tables if they don't exist"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            # Create eprocurement_tenders table
            eprocurement_table_sql = """
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
                tool_type VARCHAR(50) DEFAULT 'eprocurement',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_tender_id (tender_id),
                INDEX idx_merge_session (merge_session_id),
                INDEX idx_tool_type (tool_type),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """
            
            # Create gem_data table with fixed date format
            gem_table_sql = """
            CREATE TABLE IF NOT EXISTS gem_data (
                id VARCHAR(36) PRIMARY KEY,
                user_name VARCHAR(100),
                bid_no VARCHAR(100),
                name_of_work TEXT,
                category VARCHAR(100),
                ministry_and_department VARCHAR(200),
                quantity VARCHAR(50),
                emd DECIMAL(15, 2),
                exemption VARCHAR(50),
                estimation_value DECIMAL(20, 2),
                state VARCHAR(100),
                location VARCHAR(200),
                apply_mode VARCHAR(50),
                website_link TEXT,
                document_link TEXT,
                attachment_link TEXT,
                end_date DATE,
                source_session_id VARCHAR(100),
                source_file VARCHAR(255),
                merge_session_id VARCHAR(100),
                tool_type VARCHAR(50) DEFAULT 'gem',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_bid_no (bid_no),
                INDEX idx_merge_session (merge_session_id),
                INDEX idx_tool_type (tool_type),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """
            
            # Create ireps_data table
            ireps_table_sql = """
            CREATE TABLE IF NOT EXISTS ireps_data (
                id VARCHAR(36) PRIMARY KEY,
                tender_id VARCHAR(100),
                tender_title TEXT,
                department VARCHAR(200),
                location VARCHAR(200),
                estimated_value DECIMAL(20, 2),
                submission_deadline DATE,
                document_link TEXT,
                source_session_id VARCHAR(100),
                source_file VARCHAR(255),
                merge_session_id VARCHAR(100),
                tool_type VARCHAR(50) DEFAULT 'ireps',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_tender_id (tender_id),
                INDEX idx_merge_session (merge_session_id),
                INDEX idx_tool_type (tool_type),
                INDEX idx_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            """
            
            cursor.execute(eprocurement_table_sql)
            cursor.execute(gem_table_sql)
            cursor.execute(ireps_table_sql)
            conn.commit()
            
            logger.info("✅ All tables created/verified successfully")
            
        except Error as e:
            logger.error(f"Error creating tables: {e}")
            raise
        finally:
            if conn.is_connected():
                cursor.close()
                conn.close()
    
    def fix_date_format(self, date_str):
        """Fix date format for MySQL compatibility"""
        if pd.isna(date_str) or date_str is None or str(date_str).strip() == '':
            return None
        
        try:
            # Handle various date formats
            date_str = str(date_str).strip()
            
            # Try different date formats
            date_formats = [
                '%d-%m-%Y %H:%M:%S',  # 16-08-2025 15:00:00
                '%d/%m/%Y %H:%M:%S',  # 16/08/2025 15:00:00
                '%Y-%m-%d %H:%M:%S',  # 2025-08-16 15:00:00
                '%d-%m-%Y',           # 16-08-2025
                '%d/%m/%Y',           # 16/08/2025
                '%Y-%m-%d',           # 2025-08-16
                '%m/%d/%Y',           # 08/16/2025
                '%d-%m-%Y %H:%M',     # 16-08-2025 15:00
                '%d/%m/%Y %H:%M'      # 16/08/2025 15:00
            ]
            
            for fmt in date_formats:
                try:
                    parsed_date = datetime.strptime(date_str, fmt)
                    return parsed_date.strftime('%Y-%m-%d')
                except ValueError:
                    continue
            
            # If no format matches, try to extract date part only
            if ' ' in date_str:
                date_part = date_str.split(' ')[0]
                for fmt in ['%d-%m-%Y', '%d/%m/%Y', '%Y-%m-%d', '%m/%d/%Y']:
                    try:
                        parsed_date = datetime.strptime(date_part, fmt)
                        return parsed_date.strftime('%Y-%m-%d')
                    except ValueError:
                        continue
            
            logger.warning(f"Could not parse date: {date_str}")
            return None
            
        except Exception as e:
            logger.warning(f"Error fixing date format for '{date_str}': {e}")
            return None
    
    def detect_tool_type(self, df):
        """Detect tool type based on dataframe columns"""
        columns = [col.lower() for col in df.columns]
        
        if 'bid_no' in columns or 'user_name' in columns:
            return 'gem'
        elif 'tender_id' in columns and 'name_of_work' in columns:
            return 'eprocurement'
        elif 'tender_title' in columns and 'department' in columns:
            return 'ireps'
        else:
            # Default based on most common columns
            if 'emd' in columns or 'tender_category' in columns:
                return 'eprocurement'
            elif 'estimation_value' in columns or 'ministry_and_department' in columns:
                return 'gem'
            else:
                return 'unknown'
    
    def store_merged_data(self, df, merge_session_id, source_session_id, source_file, tool_type=None):
        """Store merged data in appropriate table based on tool type"""
        try:
            self.create_table_if_not_exists()
            
            # Detect tool type if not provided
            if not tool_type:
                tool_type = self.detect_tool_type(df)
            
            logger.info(f"Storing data for tool type: {tool_type}")
            
            if tool_type == 'gem':
                return self._store_gem_data(df, merge_session_id, source_session_id, source_file)
            elif tool_type == 'eprocurement':
                return self._store_eprocurement_data(df, merge_session_id, source_session_id, source_file)
            elif tool_type == 'ireps':
                return self._store_ireps_data(df, merge_session_id, source_session_id, source_file)
            else:
                # Try to store in eprocurement table as fallback
                logger.warning(f"Unknown tool type '{tool_type}', storing in eprocurement table")
                return self._store_eprocurement_data(df, merge_session_id, source_session_id, source_file)
                
        except Exception as e:
            logger.error(f"Error storing merged data: {e}")
            return {
                'success': False,
                'error': str(e),
                'records_inserted': 0
            }
    
    def _store_gem_data(self, df, merge_session_id, source_session_id, source_file):
        """Store GEM data"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            records_inserted = 0
            
            for index, row in df.iterrows():
                try:
                    # Fix date format
                    end_date = self.fix_date_format(row.get('end_date', None))
                    
                    # Prepare data
                    data = {
                        'id': str(uuid.uuid4()),
                        'user_name': str(row.get('user_name', ''))[:100],
                        'bid_no': str(row.get('bid_no', ''))[:100],
                        'name_of_work': str(row.get('name_of_work', ''))[:65535],
                        'category': str(row.get('category', ''))[:100],
                        'ministry_and_department': str(row.get('ministry_and_department', ''))[:200],
                        'quantity': str(row.get('quantity', ''))[:50],
                        'emd': float(row.get('emd', 0)) if pd.notna(row.get('emd')) else None,
                        'exemption': str(row.get('exemption', ''))[:50],
                        'estimation_value': float(row.get('estimation_value', 0)) if pd.notna(row.get('estimation_value')) else None,
                        'state': str(row.get('state', ''))[:100],
                        'location': str(row.get('location', ''))[:200],
                        'apply_mode': str(row.get('apply_mode', ''))[:50],
                        'website_link': str(row.get('website_link', ''))[:65535],
                        'document_link': str(row.get('document_link', ''))[:65535],
                        'attachment_link': str(row.get('attachment_link', ''))[:65535],
                        'end_date': end_date,
                        'source_session_id': source_session_id,
                        'source_file': source_file,
                        'merge_session_id': merge_session_id,
                        'tool_type': 'gem'
                    }
                    
                    # Insert data
                    insert_sql = """
                    INSERT INTO gem_data (
                        id, user_name, bid_no, name_of_work, category, ministry_and_department,
                        quantity, emd, exemption, estimation_value, state, location, apply_mode,
                        website_link, document_link, attachment_link, end_date,
                        source_session_id, source_file, merge_session_id, tool_type
                    ) VALUES (
                        %(id)s, %(user_name)s, %(bid_no)s, %(name_of_work)s, %(category)s, %(ministry_and_department)s,
                        %(quantity)s, %(emd)s, %(exemption)s, %(estimation_value)s, %(state)s, %(location)s, %(apply_mode)s,
                        %(website_link)s, %(document_link)s, %(attachment_link)s, %(end_date)s,
                        %(source_session_id)s, %(source_file)s, %(merge_session_id)s, %(tool_type)s
                    )
                    """
                    
                    cursor.execute(insert_sql, data)
                    records_inserted += 1
                    
                except Exception as e:
                    logger.warning(f"Error inserting row {index}: {e}")
                    continue
            
            conn.commit()
            logger.info(f"✅ Successfully inserted {records_inserted} GEM records")
            
            return {
                'success': True,
                'records_inserted': records_inserted,
                'tool_type': 'gem'
            }
            
        except Exception as e:
            logger.error(f"Error storing GEM data: {e}")
            return {
                'success': False,
                'error': str(e),
                'records_inserted': 0,
                'tool_type': 'gem'
            }
        finally:
            if conn.is_connected():
                cursor.close()
                conn.close()
    
    def _store_eprocurement_data(self, df, merge_session_id, source_session_id, source_file):
        """Store E-Procurement data"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            records_inserted = 0
            
            for index, row in df.iterrows():
                try:
                    # Fix date format
                    closing_date = self.fix_date_format(row.get('closing_date', None))
                    
                    # Prepare data
                    data = {
                        'id': str(uuid.uuid4()),
                        'bid_user': str(row.get('bid_user', ''))[:100],
                        'tender_id': str(row.get('tender_id', ''))[:100],
                        'name_of_work': str(row.get('name_of_work', ''))[:65535],
                        'tender_category': str(row.get('tender_category', ''))[:50],
                        'department': str(row.get('department', ''))[:100],
                        'quantity': str(row.get('quantity', ''))[:50],
                        'emd': float(row.get('emd', 0)) if pd.notna(row.get('emd')) else None,
                        'exemption': str(row.get('exemption', ''))[:50],
                        'ecv': float(row.get('ecv', 0)) if pd.notna(row.get('ecv')) else None,
                        'state_name': str(row.get('state_name', ''))[:100],
                        'location': str(row.get('location', ''))[:100],
                        'apply_mode': str(row.get('apply_mode', ''))[:50],
                        'website': str(row.get('website', ''))[:100],
                        'document_link': str(row.get('document_link', ''))[:65535],
                        'closing_date': closing_date,
                        'pincode': str(row.get('pincode', ''))[:10],
                        'attachments': str(row.get('attachments', ''))[:65535],
                        'source_session_id': source_session_id,
                        'source_file': source_file,
                        'merge_session_id': merge_session_id,
                        'tool_type': 'eprocurement'
                    }
                    
                    # Insert data
                    insert_sql = """
                    INSERT INTO eprocurement_tenders (
                        id, bid_user, tender_id, name_of_work, tender_category, department,
                        quantity, emd, exemption, ecv, state_name, location, apply_mode,
                        website, document_link, closing_date, pincode, attachments,
                        source_session_id, source_file, merge_session_id, tool_type
                    ) VALUES (
                        %(id)s, %(bid_user)s, %(tender_id)s, %(name_of_work)s, %(tender_category)s, %(department)s,
                        %(quantity)s, %(emd)s, %(exemption)s, %(ecv)s, %(state_name)s, %(location)s, %(apply_mode)s,
                        %(website)s, %(document_link)s, %(closing_date)s, %(pincode)s, %(attachments)s,
                        %(source_session_id)s, %(source_file)s, %(merge_session_id)s, %(tool_type)s
                    )
                    """
                    
                    cursor.execute(insert_sql, data)
                    records_inserted += 1
                    
                except Exception as e:
                    logger.warning(f"Error inserting row {index}: {e}")
                    continue
            
            conn.commit()
            logger.info(f"✅ Successfully inserted {records_inserted} E-Procurement records")
            
            return {
                'success': True,
                'records_inserted': records_inserted,
                'tool_type': 'eprocurement'
            }
            
        except Exception as e:
            logger.error(f"Error storing E-Procurement data: {e}")
            return {
                'success': False,
                'error': str(e),
                'records_inserted': 0,
                'tool_type': 'eprocurement'
            }
        finally:
            if conn.is_connected():
                cursor.close()
                conn.close()
    
    def _store_ireps_data(self, df, merge_session_id, source_session_id, source_file):
        """Store IREPS data"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            records_inserted = 0
            
            for index, row in df.iterrows():
                try:
                    # Fix date format
                    submission_deadline = self.fix_date_format(row.get('submission_deadline', None))
                    
                    # Prepare data
                    data = {
                        'id': str(uuid.uuid4()),
                        'tender_id': str(row.get('tender_id', ''))[:100],
                        'tender_title': str(row.get('tender_title', ''))[:65535],
                        'department': str(row.get('department', ''))[:200],
                        'location': str(row.get('location', ''))[:200],
                        'estimated_value': float(row.get('estimated_value', 0)) if pd.notna(row.get('estimated_value')) else None,
                        'submission_deadline': submission_deadline,
                        'document_link': str(row.get('document_link', ''))[:65535],
                        'source_session_id': source_session_id,
                        'source_file': source_file,
                        'merge_session_id': merge_session_id,
                        'tool_type': 'ireps'
                    }
                    
                    # Insert data
                    insert_sql = """
                    INSERT INTO ireps_data (
                        id, tender_id, tender_title, department, location, estimated_value,
                        submission_deadline, document_link, source_session_id, source_file, merge_session_id, tool_type
                    ) VALUES (
                        %(id)s, %(tender_id)s, %(tender_title)s, %(department)s, %(location)s, %(estimated_value)s,
                        %(submission_deadline)s, %(document_link)s, %(source_session_id)s, %(source_file)s, %(merge_session_id)s, %(tool_type)s
                    )
                    """
                    
                    cursor.execute(insert_sql, data)
                    records_inserted += 1
                    
                except Exception as e:
                    logger.warning(f"Error inserting row {index}: {e}")
                    continue
            
            conn.commit()
            logger.info(f"✅ Successfully inserted {records_inserted} IREPS records")
            
            return {
                'success': True,
                'records_inserted': records_inserted,
                'tool_type': 'ireps'
            }
            
        except Exception as e:
            logger.error(f"Error storing IREPS data: {e}")
            return {
                'success': False,
                'error': str(e),
                'records_inserted': 0,
                'tool_type': 'ireps'
            }
        finally:
            if conn.is_connected():
                cursor.close()
                conn.close()
    
    def get_merged_data(self, limit=50, tool_type=None):
        """Get merged data from all tables"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            all_data = []
            total_count = 0
            
            # Get data from all tables
            tables = ['eprocurement_tenders', 'gem_data', 'ireps_data']
            
            for table in tables:
                try:
                    where_clause = f"WHERE tool_type = '{tool_type}'" if tool_type else ""
                    sql = f"SELECT *, '{table}' as source_table FROM {table} {where_clause} ORDER BY created_at DESC LIMIT {limit}"
                    
                    cursor.execute(sql)
                    results = cursor.fetchall()
                    
                    for row in results:
                        row['source_table'] = table
                        all_data.append(row)
                    
                    total_count += len(results)
                    
                except Exception as e:
                    logger.warning(f"Error querying table {table}: {e}")
                    continue
            
            # Sort by created_at
            all_data.sort(key=lambda x: x.get('created_at', ''), reverse=True)
            
            return {
                'success': True,
                'data': all_data[:limit],
                'total_count': total_count
            }
            
        except Exception as e:
            logger.error(f"Error getting merged data: {e}")
            return {
                'success': False,
                'error': str(e),
                'data': [],
                'total_count': 0
            }
        finally:
            if conn.is_connected():
                cursor.close()
                conn.close()
