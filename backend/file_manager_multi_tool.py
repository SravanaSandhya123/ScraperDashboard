#!/usr/bin/env python3
"""
Multi-Tool File Manager - Handles GEM, E-Procurement, and IREPS tools
"""

import os
import glob
import logging
from datetime import datetime
import pandas as pd

logger = logging.getLogger(__name__)

class MultiToolFileManager:
    def __init__(self, output_base_dir):
        self.output_base_dir = output_base_dir
        self.tool_types = ['gem', 'eprocurement', 'ireps']
    
    def get_all_tool_files(self, session_id):
        """Get all Excel files from all tools in a session"""
        try:
            session_dir = os.path.join(self.output_base_dir, session_id)
            if not os.path.exists(session_dir):
                return []
            
            # Get all Excel files from the session
            excel_files = glob.glob(os.path.join(session_dir, '*.xlsx'))
            
            # Group files by tool type
            tool_files = {
                'gem': [],
                'eprocurement': [],
                'ireps': [],
                'unknown': []
            }
            
            for file_path in excel_files:
                filename = os.path.basename(file_path)
                tool_type = self.detect_tool_from_filename(filename)
                
                if tool_type in tool_files:
                    tool_files[tool_type].append({
                        'path': file_path,
                        'filename': filename,
                        'tool_type': tool_type
                    })
                else:
                    tool_files['unknown'].append({
                        'path': file_path,
                        'filename': filename,
                        'tool_type': 'unknown'
                    })
            
            logger.info(f"Found files: GEM={len(tool_files['gem'])}, E-Procurement={len(tool_files['eprocurement'])}, IREPS={len(tool_files['ireps'])}, Unknown={len(tool_files['unknown'])}")
            
            return tool_files
            
        except Exception as e:
            logger.error(f"Error getting tool files: {e}")
            return {}
    
    def detect_tool_from_filename(self, filename):
        """Detect tool type from filename"""
        filename_lower = filename.lower()
        
        if 'gem' in filename_lower or 'bid_no' in filename_lower:
            return 'gem'
        elif 'eproc' in filename_lower or 'tender' in filename_lower:
            return 'eprocurement'
        elif 'ireps' in filename_lower:
            return 'ireps'
        else:
            return 'unknown'
    
    def detect_tool_from_dataframe(self, df):
        """Detect tool type from dataframe columns"""
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
    
    def merge_all_tool_files(self, session_id):
        """Merge all files from all tools in a session"""
        try:
            tool_files = self.get_all_tool_files(session_id)
            
            if not any(tool_files.values()):
                return {
                    'success': False,
                    'error': 'No Excel files found in session',
                    'merged_data': None,
                    'tool_summary': {}
                }
            
            merged_data = {}
            tool_summary = {}
            
            # Process each tool type
            for tool_type, files in tool_files.items():
                if not files:
                    continue
                
                logger.info(f"Processing {tool_type} files: {len(files)} files")
                
                all_data = []
                processed_files = []
                
                for file_info in files:
                    try:
                        df = pd.read_excel(file_info['path'])
                        
                        # Add metadata
                        df['source_file'] = file_info['filename']
                        df['source_session'] = session_id
                        df['tool_type'] = tool_type
                        df['processed_date'] = datetime.now().isoformat()
                        
                        all_data.append(df)
                        processed_files.append(file_info['filename'])
                        
                        logger.info(f"✅ Loaded {len(df)} rows from {file_info['filename']}")
                        
                    except Exception as e:
                        logger.warning(f"Could not read {file_info['filename']}: {e}")
                        continue
                
                if all_data:
                    # Merge all dataframes for this tool
                    merged_df = pd.concat(all_data, ignore_index=True)
                    merged_data[tool_type] = merged_df
                    
                    tool_summary[tool_type] = {
                        'files_processed': len(processed_files),
                        'total_rows': len(merged_df),
                        'files': processed_files
                    }
                    
                    logger.info(f"✅ Merged {tool_type}: {len(merged_df)} rows from {len(processed_files)} files")
                else:
                    logger.warning(f"No valid data found for {tool_type}")
            
            return {
                'success': True,
                'merged_data': merged_data,
                'tool_summary': tool_summary
            }
            
        except Exception as e:
            logger.error(f"Error merging tool files: {e}")
            return {
                'success': False,
                'error': str(e),
                'merged_data': None,
                'tool_summary': {}
            }
    
    def create_combined_csv(self, merged_data, session_id):
        """Create a combined CSV with all tool data"""
        try:
            if not merged_data:
                return None
            
            # Combine all tool data
            all_combined_data = []
            
            for tool_type, df in merged_data.items():
                if df is not None and len(df) > 0:
                    # Add tool type column if not present
                    if 'tool_type' not in df.columns:
                        df['tool_type'] = tool_type
                    
                    all_combined_data.append(df)
            
            if not all_combined_data:
                return None
            
            # Combine all dataframes
            combined_df = pd.concat(all_combined_data, ignore_index=True)
            
            # Create combined CSV file
            session_dir = os.path.join(self.output_base_dir, session_id)
            combined_filename = f'combined_all_tools_{session_id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv'
            combined_path = os.path.join(session_dir, combined_filename)
            
            combined_df.to_csv(combined_path, index=False)
            
            logger.info(f"✅ Created combined CSV: {combined_filename} with {len(combined_df)} rows")
            
            return {
                'filename': combined_filename,
                'path': combined_path,
                'total_rows': len(combined_df),
                'tool_breakdown': {tool: len(df) for tool, df in merged_data.items() if df is not None}
            }
            
        except Exception as e:
            logger.error(f"Error creating combined CSV: {e}")
            return None
    
    def get_session_summary(self, session_id):
        """Get summary of all files in a session"""
        try:
            tool_files = self.get_all_tool_files(session_id)
            
            summary = {
                'session_id': session_id,
                'total_files': sum(len(files) for files in tool_files.values()),
                'tool_breakdown': {
                    tool: len(files) for tool, files in tool_files.items()
                },
                'files': {}
            }
            
            for tool_type, files in tool_files.items():
                summary['files'][tool_type] = [
                    {
                        'filename': f['filename'],
                        'tool_type': f['tool_type']
                    } for f in files
                ]
            
            return summary
            
        except Exception as e:
            logger.error(f"Error getting session summary: {e}")
            return None
