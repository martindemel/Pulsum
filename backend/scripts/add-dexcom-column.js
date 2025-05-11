require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const { getDb } = require('../utils/db');

async function addDexcomColumn() {
  try {
    console.log('Adding use_dexcom column to users table...');
    const db = await getDb();
    
    // Check if column exists
    const tableInfo = await db.all('PRAGMA table_info(users)');
    const columnExists = tableInfo.some(column => column.name === 'use_dexcom');
    
    if (!columnExists) {
      // Add the column if it doesn't exist
      await db.exec('ALTER TABLE users ADD COLUMN use_dexcom BOOLEAN DEFAULT 0');
      console.log('Column use_dexcom added successfully');
    } else {
      console.log('Column use_dexcom already exists');
    }
    
    process.exit(0);
  } catch (error) {
    console.error('Failed to add column:', error);
    process.exit(1);
  }
}

addDexcomColumn(); 