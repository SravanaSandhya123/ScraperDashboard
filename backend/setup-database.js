const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || '44.244.61.85',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'thanuja',
  database: process.env.DB_NAME || 'Toolinformation',
  charset: 'utf8mb4'
});

async function setupDatabase() {
  try {
    console.log('Setting up Super Scraper database...');

    // Create users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
        email VARCHAR(255) UNIQUE NOT NULL,
        username VARCHAR(100) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        last_login TIMESTAMP NULL,
        is_active BOOLEAN DEFAULT true
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Create tools table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tools (
        id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
        name VARCHAR(255) NOT NULL,
        category VARCHAR(50) NOT NULL,
        description TEXT,
        states JSON,
        icon VARCHAR(50),
        is_active BOOLEAN DEFAULT true,
        created_by VARCHAR(36),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Create tools_1 table (for job tracking)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS tools_1 (
        id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
        user_id VARCHAR(36),
        tool_id VARCHAR(36),
        state VARCHAR(100),
        username VARCHAR(255),
        starting_name VARCHAR(255),
        status VARCHAR(20) DEFAULT 'pending',
        progress INTEGER DEFAULT 0,
        start_time TIMESTAMP NULL,
        end_time TIMESTAMP NULL,
        output_files JSON,
        logs JSON,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (tool_id) REFERENCES tools(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Create eprocurement_tenders table (for storing merged e-procurement data)
    await pool.query(`
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
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // Create index on tender_id for faster lookups
    await pool.query(`
      CREATE INDEX idx_eprocurement_tenders_tender_id 
      ON eprocurement_tenders(tender_id);
    `);

    // Create index on merge_session_id for filtering by merge session
    await pool.query(`
      CREATE INDEX idx_eprocurement_tenders_merge_session 
      ON eprocurement_tenders(merge_session_id);
    `);

    // Insert default super admin user
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash('SuperScraper2024!', 10);
    
    await pool.query(`
      INSERT INTO users (email, username, password_hash, role) 
      VALUES (?, ?, ?, ?) 
      ON DUPLICATE KEY UPDATE email = email
    `, ['super@scraper.com', 'Super Admin', hashedPassword, 'super_admin']);

    // Insert default admin user
    const adminPassword = await bcrypt.hash('admin123', 10);
    await pool.query(`
      INSERT INTO users (email, username, password_hash, role) 
      VALUES (?, ?, ?, ?) 
      ON DUPLICATE KEY UPDATE email = email
    `, ['admin@scraper.com', 'Admin', adminPassword, 'admin']);

    // Insert default tools
    const tools = [
      {
        name: 'Gem Portal Scraper',
        category: 'gem',
        description: 'Extract tender data from Government e-Marketplace portal',
        states: ['Delhi', 'Mumbai', 'Chennai', 'Kolkata', 'Bangalore', 'Hyderabad', 'Pune', 'Ahmedabad'],
        icon: 'gem'
      },
      {
        name: 'Global Trade Monitor',
        category: 'global',
        description: 'Monitor international trade opportunities',
        states: ['USA', 'UK', 'Germany', 'France', 'Japan', 'Singapore', 'Australia', 'Canada'],
        icon: 'globe'
      },
      {
        name: 'E-Procurement Monitor',
        category: 'eprocurement',
        description: 'Monitor e-procurement platforms for new opportunities',
        states: ['Central Govt', 'State Govt', 'PSU', 'Private', 'International'],
        icon: 'shopping-cart'
      }
    ];

    for (const tool of tools) {
      await pool.query(`
        INSERT INTO tools (name, category, description, states, icon) 
        VALUES (?, ?, ?, ?, ?) 
        ON DUPLICATE KEY UPDATE name = name
      `, [tool.name, tool.category, tool.description, JSON.stringify(tool.states), tool.icon]);
    }

    console.log('Database setup completed successfully!');
    console.log('Default accounts created:');
    console.log('Super Admin: super@scraper.com / SuperScraper2024!');
    console.log('Admin: admin@scraper.com / admin123');
    
  } catch (error) {
    console.error('Database setup error:', error);
  } finally {
    await pool.end();
  }
}

setupDatabase();