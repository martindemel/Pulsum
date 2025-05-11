require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const { setupDatabase } = require('../utils/db');

async function initializeDatabase() {
  try {
    console.log('Initializing database...');
    await setupDatabase();
    console.log('Database initialization completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  }
}

initializeDatabase(); 