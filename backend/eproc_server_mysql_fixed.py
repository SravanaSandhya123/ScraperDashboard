#!/usr/bin/env python3
"""
E-Procurement Server with MySQL Database Support - Fixed Version
Handles database connection failures gracefully
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

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', '44.244.61.85'),
    'port': int(os.getenv('DB_PORT', '3306')),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'thanuja'),
    'database': os.getenv('DB_NAME', 'Toolinformation')
}

def test_database_connection():
    """Test if database is accessible"""
    try:
        import mysql.connector
        conn = mysql.connector.connect(**DB_CONFIG)
        conn.close()
        return True
    except Exception as e:
        logger.warning(f"Database connection failed: {e}")
        return False

def store_data_in_database(merged_df, session_id, processed_files):
    """Attempt to store data in database with error handling"""
    try:
        from database_operations_mysql import EProcurementDBMySQL
        
        # Test connection first
        if not test_database_connection():
            return {
                'success': False,
                'error': 'Database server not accessible',
                'records_inserted': 0
            }
        
        db = EProcurementDBMySQL()
        merge_session_id = f"merge_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        result = db.store_merged_data(
            df=merged_df,
            merge_session_id=merge_session_id,
            source_session_id=session_id,
            source_file=','.join(processed_files)
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Database storage error: {e}")
        return {
            'success': False,
            'error': str(e),
            'records_inserted': 0
        }

@app.route('/api/merge-download/<session_id>', methods=['GET'])
def merge_download_session(session_id):
    """Merge all files in a session, download as CSV, and attempt to store in database"""
    try:
        session_dir = os.path.join(OUTPUT_BASE_DIR, session_id)
        if not os.path.exists(session_dir):
            return jsonify({'error': 'Session directory not found'}), 404
        
        excel_files = glob.glob(os.path.join(session_dir, '*.xlsx'))
        if not excel_files:
            return jsonify({'error': 'No Excel files found in session'}), 404
        
        # Read and merge all Excel files
        all_data = []
        processed_files = []
        for file_path in excel_files:
            try:
                df = pd.read_excel(file_path)
                # Add source file information
                df['source_file'] = os.path.basename(file_path)
                df['source_session'] = session_id
                df['processed_date'] = datetime.now().isoformat()
                all_data.append(df)
                processed_files.append(os.path.basename(file_path))
            except Exception as e:
                logger.warning(f"Could not read {file_path}: {e}")
                continue
        
        if not all_data:
            return jsonify({'error': 'No valid Excel files found'}), 404
        
        # Merge all dataframes
        merged_df = pd.concat(all_data, ignore_index=True)
        
        # Attempt to store in database
        db_result = store_data_in_database(merged_df, session_id, processed_files)
        
        # Create CSV response
        csv_data = merged_df.to_csv(index=False)
        response = Response(csv_data, mimetype='text/csv')
        response.headers['Content-Disposition'] = f'attachment; filename=merged_data_{session_id}.csv'
        
        # Add database status to response headers
        if db_result and db_result.get('success'):
            response.headers['X-DB-Status'] = 'success'
            response.headers['X-DB-Records-Inserted'] = str(db_result.get('records_inserted', 0))
            logger.info(f"✅ Database storage successful: {db_result['records_inserted']} records inserted")
        else:
            response.headers['X-DB-Status'] = 'failed'
            response.headers['X-DB-Error'] = db_result.get('error', 'Unknown error') if db_result else 'Database not accessible'
            logger.warning(f"⚠️ Database storage failed: {db_result.get('error') if db_result else 'Database not accessible'}")
        
        # Always return the CSV file for download
        return response
        
    except Exception as e:
        logger.error(f"Merge and download error: {e}")
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
            'database_error': db_result.get('error') if db_result and not db_result.get('success') else None
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
        if not test_database_connection():
            return jsonify({'error': 'Database not accessible'}), 503
        
        from database_operations_mysql import EProcurementDBMySQL
        db = EProcurementDBMySQL()
        
        # Get recent merge sessions
        result = db.get_merged_data(limit=50)
        
        if result['success']:
            return jsonify({
                'merge_history': result['data'],
                'total_count': result['total_count']
            })
        else:
            return jsonify({'error': result['error']}), 500
            
    except Exception as e:
        logger.error(f"Get merge history error: {e}")
        return jsonify({'error': f'Failed to get merge history: {str(e)}'}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    db_accessible = test_database_connection()
    return jsonify({
        'status': 'healthy',
        'database_accessible': db_accessible,
        'timestamp': datetime.now().isoformat()
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
    logger.info("Starting E-Procurement Server with MySQL support...")
    logger.info(f"Database config: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")
    
    # Test database connection on startup
    if test_database_connection():
        logger.info("✅ Database connection successful")
    else:
        logger.warning("⚠️ Database connection failed - server will work without database storage")
    
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)
