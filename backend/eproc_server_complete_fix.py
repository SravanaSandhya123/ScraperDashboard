#!/usr/bin/env python3
"""
E-Procurement Server - Complete Fix
Handles all database scenarios: MySQL, PostgreSQL, Local, Remote, No Database
"""

import os
import glob
import json
import uuid
import logging
from datetime import datetime
from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS
from flask_socketio import SocketIO, emit
import pandas as pd

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Configuration
OUTPUT_BASE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'output')
if not os.path.exists(OUTPUT_BASE_DIR):
    os.makedirs(OUTPUT_BASE_DIR)

# Import fixed database configuration
try:
    from database_config_fixed import db_config, test_database_connection
    DATABASE_CONFIG = db_config.get_connection_params()
    DB_TYPE = db_config.db_type
except ImportError:
    # Fallback configuration
    DATABASE_CONFIG = {
        'host': 'localhost',
        'port': 3306,
        'user': 'root',
        'password': '',
        'database': 'Toolinformation'
    }
    DB_TYPE = 'mysql'

def test_db_connection():
    """Test database connection with detailed logging"""
    try:
        success, message = test_database_connection()
        logger.info(message)
        return success
    except Exception as e:
        logger.warning(f"Database connection test failed: {e}")
        return False

def store_data_in_database(merged_df, session_id, processed_files, tool_type=None):
    """Attempt to store data in database with comprehensive error handling"""
    try:
        # Test connection first
        if not test_db_connection():
            return {
                'success': False,
                'error': 'Database server not accessible',
                'records_inserted': 0,
                'db_type': DB_TYPE
            }
        
        # Try to import appropriate database operations
        if DB_TYPE == 'postgresql':
            try:
                from database_operations_postgresql import EProcurementDBPostgreSQL
                db = EProcurementDBPostgreSQL()
            except ImportError:
                return {
                    'success': False,
                    'error': 'PostgreSQL database operations not available',
                    'records_inserted': 0,
                    'db_type': DB_TYPE
                }
        else:
            try:
                # Use the fixed MySQL operations that handle date formats and multiple tools
                from database_operations_mysql_fixed import EProcurementDBMySQL
                db = EProcurementDBMySQL()
            except ImportError:
                # Fallback to original MySQL operations
                try:
                    from database_operations_mysql import EProcurementDBMySQL
                    db = EProcurementDBMySQL()
                except ImportError:
                    return {
                        'success': False,
                        'error': 'MySQL database operations not available',
                        'records_inserted': 0,
                        'db_type': DB_TYPE
                    }
        
        merge_session_id = f"merge_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        result = db.store_merged_data(
            df=merged_df,
            merge_session_id=merge_session_id,
            source_session_id=session_id,
            source_file=','.join(processed_files) if isinstance(processed_files, list) else processed_files,
            tool_type=tool_type
        )
        
        # Add database type to result
        result['db_type'] = DB_TYPE
        return result
        
    except Exception as e:
        logger.error(f"Database storage error: {e}")
        return {
            'success': False,
            'error': str(e),
            'records_inserted': 0,
            'db_type': DB_TYPE
        }

@app.route('/api/merge-download/<session_id>', methods=['GET'])
def merge_download_session(session_id):
    """Merge all files from all tools in a session, download as CSV, and store in database"""
    try:
        # Import multi-tool file manager
        from file_manager_multi_tool import MultiToolFileManager
        file_manager = MultiToolFileManager(OUTPUT_BASE_DIR)
        
        # Merge all tool files
        merge_result = file_manager.merge_all_tool_files(session_id)
        
        if not merge_result['success']:
            return jsonify({'error': merge_result['error']}), 404
        
        merged_data = merge_result['merged_data']
        tool_summary = merge_result['tool_summary']
        
        if not merged_data:
            return jsonify({'error': 'No valid data found in any tool files'}), 404
        
        # Store data for each tool type in database
        total_records_inserted = 0
        db_results = {}
        
        for tool_type, df in merged_data.items():
            if df is not None and len(df) > 0:
                # Get list of files for this tool
                files_for_tool = tool_summary.get(tool_type, {}).get('files', [])
                source_file = ','.join(files_for_tool)
                
                # Store in database
                db_result = store_data_in_database(df, session_id, source_file, tool_type)
                db_results[tool_type] = db_result
                
                if db_result and db_result.get('success'):
                    total_records_inserted += db_result.get('records_inserted', 0)
                    logger.info(f"✅ {tool_type}: {db_result['records_inserted']} records stored")
                else:
                    logger.warning(f"⚠️ {tool_type}: Database storage failed - {db_result.get('error') if db_result else 'Unknown error'}")
        
        # Create combined CSV
        combined_csv = file_manager.create_combined_csv(merged_data, session_id)
        
        if not combined_csv:
            return jsonify({'error': 'Failed to create combined CSV'}), 500
        
        # Read the combined CSV file
        with open(combined_csv['path'], 'r', encoding='utf-8') as f:
            csv_data = f.read()
        
        # Create response
        response = Response(csv_data, mimetype='text/csv')
        response.headers['Content-Disposition'] = f'attachment; filename={combined_csv["filename"]}'
        
        # Add comprehensive database status to response headers
        if total_records_inserted > 0:
            response.headers['X-DB-Status'] = 'success'
            response.headers['X-DB-Records-Inserted'] = str(total_records_inserted)
            response.headers['X-DB-Type'] = 'multi-tool'
            response.headers['X-Tool-Breakdown'] = str(combined_csv['tool_breakdown'])
            logger.info(f"✅ Multi-tool database storage successful: {total_records_inserted} total records inserted")
        else:
            response.headers['X-DB-Status'] = 'failed'
            response.headers['X-DB-Error'] = 'No records were stored in database'
            response.headers['X-DB-Type'] = 'multi-tool'
            logger.warning(f"⚠️ Multi-tool database storage failed: No records inserted")
        
        # Always return the CSV file for download
        return response
        
    except Exception as e:
        logger.error(f"Multi-tool merge and download error: {e}")
        return jsonify({'error': f'Failed to merge and download files: {str(e)}'}), 500

@app.route('/api/merge/<session_id>', methods=['POST'])
def merge_session_files(session_id):
    """Merge all Excel files in a session into one file"""
    try:
        session_dir = os.path.join(OUTPUT_BASE_DIR, session_id)
        if not os.path.exists(session_dir):
            return jsonify({'error': 'Session directory not found'}), 404
        
        excel_files = glob.glob(os.path.join(session_dir, '*.xlsx'))
        if not excel_files:
            return jsonify({'error': 'No Excel files found in session'}), 404
        
        # Read and merge all Excel files
        all_data = []
        for file_path in excel_files:
            try:
                df = pd.read_excel(file_path)
                all_data.append(df)
            except Exception as e:
                logger.warning(f"Could not read {file_path}: {e}")
                continue
        
        if not all_data:
            return jsonify({'error': 'No valid Excel files found'}), 404
        
        # Merge all dataframes
        merged_df = pd.concat(all_data, ignore_index=True)
        
        # Save merged file
        merged_filename = f'merged_data_{session_id}.xlsx'
        merged_path = os.path.join(session_dir, merged_filename)
        merged_df.to_excel(merged_path, index=False)
        
        return jsonify({
            'message': 'Files merged successfully',
            'merged_file': merged_filename,
            'total_files': len(excel_files),
            'total_rows': len(merged_df)
        }), 200
            
    except Exception as e:
        logger.error(f"Merge error: {e}")
        return jsonify({'error': f'Failed to merge files: {str(e)}'}), 500

@app.route('/api/sessions', methods=['GET'])
def list_sessions():
    """List all scraping sessions"""
    try:
        if not os.path.exists(OUTPUT_BASE_DIR):
            return jsonify({'sessions': []})
        
        sessions = []
        for session_dir in os.listdir(OUTPUT_BASE_DIR):
            session_path = os.path.join(OUTPUT_BASE_DIR, session_dir)
            if os.path.isdir(session_path):
                excel_files = glob.glob(os.path.join(session_path, '*.xlsx'))
                sessions.append({
                    'session_id': session_dir,
                    'file_count': len(excel_files),
                    'files': [os.path.basename(f) for f in excel_files]
                })
        
        return jsonify({'sessions': sessions})
        
    except Exception as e:
        logger.error(f"List sessions error: {e}")
        return jsonify({'error': f'Failed to list sessions: {str(e)}'}), 500

@app.route('/api/download/<session_id>/<filename>', methods=['GET'])
def download_file(session_id, filename):
    """Download a specific file from a session"""
    try:
        file_path = os.path.join(OUTPUT_BASE_DIR, session_id, filename)
        if not os.path.exists(file_path):
            return jsonify({'error': 'File not found'}), 404
        
        return send_file(file_path, as_attachment=True, download_name=filename)
        
    except Exception as e:
        logger.error(f"Download error: {e}")
        return jsonify({'error': f'Failed to download file: {str(e)}'}), 500

@app.route('/api/delete-file/<session_id>', methods=['POST'])
def delete_file(session_id):
    """Delete a specific file from a session"""
    try:
        data = request.get_json()
        filename = data.get('filename')
        
        if not filename:
            return jsonify({'error': 'Filename not provided'}), 400
        
        file_path = os.path.join(OUTPUT_BASE_DIR, session_id, filename)
        if not os.path.exists(file_path):
            return jsonify({'error': 'File not found'}), 404
        
        os.remove(file_path)
        return jsonify({'message': f'File {filename} deleted successfully'})
        
    except Exception as e:
        logger.error(f"Delete file error: {e}")
        return jsonify({'error': f'Failed to delete file: {str(e)}'}), 500

@app.route('/api/merge-global', methods=['POST'])
def merge_global_files():
    """Merge all files from all sessions and store in database"""
    try:
        data = request.get_json()
        global_session_id = data.get('session_id')
        files = data.get('files', [])
        
        if not files:
            return jsonify({'error': 'No files specified'}), 400
        
        # Create global merge directory
        global_dir = os.path.join(OUTPUT_BASE_DIR, global_session_id)
        if not os.path.exists(global_dir):
            os.makedirs(global_dir)
        
        # Read and merge all files
        all_data = []
        processed_files = []
        
        for file_info in files:
            session_id = file_info.get('session_id')
            filename = file_info.get('filename')
            file_path = os.path.join(OUTPUT_BASE_DIR, session_id, filename)
            
            if os.path.exists(file_path):
                try:
                    df = pd.read_excel(file_path)
                    # Add source information
                    df['source_session'] = session_id
                    df['source_file'] = filename
                    df['processed_date'] = datetime.now().isoformat()
                    all_data.append(df)
                    processed_files.append(filename)
                except Exception as e:
                    logger.warning(f"Error reading {file_path}: {e}")
                    continue
        
        if not all_data:
            return jsonify({'error': 'No valid files found'}), 404
        
        # Concatenate all dataframes
        merged_df = pd.concat(all_data, ignore_index=True)
        
        # Save merged file
        merged_file_path = os.path.join(global_dir, f'global_merged_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv')
        merged_df.to_csv(merged_file_path, index=False)
        
        # Attempt to store in database
        db_result = store_data_in_database(merged_df, global_session_id, processed_files)
        
        return jsonify({
            'message': 'Global merge completed',
            'merged_file': os.path.basename(merged_file_path),
            'total_files': len(processed_files),
            'total_rows': len(merged_df),
            'database_status': 'success' if db_result and db_result.get('success') else 'failed',
            'database_records': db_result.get('records_inserted', 0) if db_result else 0,
            'database_error': db_result.get('error') if db_result and not db_result.get('success') else None,
            'database_type': db_result.get('db_type', 'unknown') if db_result else 'unknown'
        })
        
    except Exception as e:
        logger.error(f"Global merge error: {e}")
        return jsonify({'error': f'Failed to merge files globally: {str(e)}'}), 500

@app.route('/api/download-global-merge/<global_session_id>', methods=['GET'])
def download_global_merge(global_session_id):
    """Download the globally merged file"""
    try:
        global_dir = os.path.join(OUTPUT_BASE_DIR, global_session_id)
        if not os.path.exists(global_dir):
            return jsonify({'error': 'Global merge session not found'}), 404
        
        # Find the merged CSV file
        csv_files = glob.glob(os.path.join(global_dir, '*.csv'))
        if not csv_files:
            return jsonify({'error': 'No merged file found'}), 404
        
        # Return the most recent CSV file
        latest_file = max(csv_files, key=os.path.getctime)
        filename = os.path.basename(latest_file)
        
        return send_file(latest_file, as_attachment=True, download_name=filename)
        
    except Exception as e:
        logger.error(f"Download global merge error: {e}")
        return jsonify({'error': f'Failed to download merged file: {str(e)}'}), 500

@app.route('/api/merge-history', methods=['GET'])
def get_merge_history():
    """Get merge history from database"""
    try:
        if not test_db_connection():
            return jsonify({'error': 'Database not accessible'}), 503
        
        # Try to get merge history based on database type
        if DB_TYPE == 'postgresql':
            try:
                from database_operations_postgresql import EProcurementDBPostgreSQL
                db = EProcurementDBPostgreSQL()
            except ImportError:
                return jsonify({'error': 'PostgreSQL database operations not available'}), 500
        else:
            try:
                # Use the fixed MySQL operations that handle date formats and multiple tools
                from database_operations_mysql_fixed import EProcurementDBMySQL
                db = EProcurementDBMySQL()
            except ImportError:
                # Fallback to original MySQL operations
                try:
                    from database_operations_mysql import EProcurementDBMySQL
                    db = EProcurementDBMySQL()
                except ImportError:
                    return jsonify({'error': 'MySQL database operations not available'}), 500
        
        # Get recent merge sessions
        result = db.get_merged_data(limit=50)
        
        if result['success']:
            return jsonify({
                'merge_history': result['data'],
                'total_count': result['total_count'],
                'database_type': DB_TYPE
            })
        else:
            return jsonify({'error': result['error']}), 500
            
    except Exception as e:
        logger.error(f"Get merge history error: {e}")
        return jsonify({'error': f'Failed to get merge history: {str(e)}'}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint with database status"""
    db_accessible = test_db_connection()
    return jsonify({
        'status': 'healthy',
        'database_accessible': db_accessible,
        'database_type': DB_TYPE,
        'database_config': {
            'host': DATABASE_CONFIG.get('host'),
            'port': DATABASE_CONFIG.get('port'),
            'database': DATABASE_CONFIG.get('database')
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/database-status', methods=['GET'])
def database_status():
    """Detailed database status endpoint"""
    try:
        success, message = test_database_connection()
        return jsonify({
            'database_type': DB_TYPE,
            'connection_successful': success,
            'message': message,
            'config': {
                'host': DATABASE_CONFIG.get('host'),
                'port': DATABASE_CONFIG.get('port'),
                'database': DATABASE_CONFIG.get('database'),
                'user': DATABASE_CONFIG.get('user')
            }
        })
    except Exception as e:
        return jsonify({
            'database_type': DB_TYPE,
            'connection_successful': False,
            'message': f'Error testing connection: {str(e)}',
            'config': DATABASE_CONFIG
        })

@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    logger.info('Client connected')
    emit('connected', {'message': 'Connected to server'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    logger.info('Client disconnected')

if __name__ == '__main__':
    logger.info("🚀 Starting E-Procurement Server - Complete Fix...")
    logger.info(f"📊 Database Type: {DB_TYPE}")
    logger.info(f"🌐 Database Config: {DATABASE_CONFIG['host']}:{DATABASE_CONFIG['port']}/{DATABASE_CONFIG['database']}")
    
    # Test database connection on startup
    success, message = test_database_connection()
    logger.info(message)
    
    if not success:
        logger.warning("⚠️ Database connection failed - server will work without database storage")
        logger.info("📁 Files will still be merged and downloaded successfully")
    
    logger.info("🌐 Starting server on http://localhost:5000")
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
