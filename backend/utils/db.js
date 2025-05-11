const sqlite3 = require('sqlite3').verbose();
const { open } = require('sqlite');
const path = require('path');
const fs = require('fs');

// Ensure the db directory exists
const dbDirectory = path.join(__dirname, '../../db');
if (!fs.existsSync(dbDirectory)) {
  fs.mkdirSync(dbDirectory, { recursive: true });
}

const dbPath = process.env.DB_PATH || path.join(dbDirectory, 'pulsum.db');

// Initialize the database connection
let db;

async function getDb() {
  if (!db) {
    db = await open({
      filename: dbPath,
      driver: sqlite3.Database
    });
  }
  return db;
}

async function setupDatabase() {
  const db = await getDb();
  
  // Enable foreign keys
  await db.exec('PRAGMA foreign_keys = ON');
  
  // Users table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      oura_access_token TEXT,
      oura_refresh_token TEXT,
      oura_token_expires_at TIMESTAMP,
      dexcom_access_token TEXT,
      dexcom_refresh_token TEXT,
      dexcom_token_expires_at TIMESTAMP,
      use_dexcom BOOLEAN DEFAULT 0
    )
  `);
  
  // Check if use_dexcom column exists (in case table was created without it)
  const tableInfo = await db.all('PRAGMA table_info(users)');
  const useDexcomExists = tableInfo.some(column => column.name === 'use_dexcom');
  
  // Add column if it doesn't exist
  if (!useDexcomExists) {
    try {
      console.log('Adding use_dexcom column to users table');
      await db.exec('ALTER TABLE users ADD COLUMN use_dexcom BOOLEAN DEFAULT 0');
    } catch (error) {
      // SQLite might throw error if column already exists, which is fine
      console.log('Note: use_dexcom column may already exist');
    }
  }
  
  // Oura data table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS oura_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      data_type TEXT NOT NULL,
      data JSON NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      UNIQUE(user_id, date, data_type)
    )
  `);
  
  // Dexcom data table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS dexcom_data (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      reading_time TIMESTAMP NOT NULL,
      glucose_value INTEGER NOT NULL,
      trend TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
  `);
  
  // Journal entries table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS journal_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      mood_rating INTEGER CHECK (mood_rating BETWEEN 1 AND 5),
      sleep_rating INTEGER CHECK (sleep_rating BETWEEN 1 AND 5),
      entry_text TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      UNIQUE(user_id, date)
    )
  `);
  
  // Recommendations table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS recommendations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      recommendation_text TEXT NOT NULL,
      category TEXT,
      subcategory TEXT,
      source TEXT,
      microaction TEXT,
      difficulty_level TEXT,
      time_to_complete TEXT,
      is_completed BOOLEAN DEFAULT 0,
      is_liked BOOLEAN DEFAULT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
  `);
  
  // Wellness scores table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS wellness_scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      objective_score REAL,
      subjective_score REAL,
      combined_score REAL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      UNIQUE(user_id, date)
    )
  `);
  
  // Chat history table
  await db.exec(`
    CREATE TABLE IF NOT EXISTS chat_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      role TEXT NOT NULL,
      content TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
  `);
  
  // Create a default user if none exists
  const userCount = await db.get('SELECT COUNT(*) as count FROM users');
  if (userCount.count === 0) {
    await db.run(`
      INSERT INTO users (created_at, updated_at)
      VALUES (CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    `);
  }
  
  return db;
}

module.exports = {
  getDb,
  setupDatabase
}; 