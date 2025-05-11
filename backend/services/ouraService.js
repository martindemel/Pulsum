const axios = require('axios');
const { getDb } = require('../utils/db');
const { calculateWellnessScores } = require('./wellnessScoreService');

const OURA_API_URL = 'https://api.ouraring.com/v2';

// Get Oura access token - standardized to use personal token
async function getOuraAccessToken() {
  // First, check if we have a personal token in .env
  const personalToken = process.env.OURA_PERSONAL_TOKEN;
  if (personalToken && personalToken.trim() !== '') {
    return personalToken;
  }

  // Otherwise, check the database for stored token
  const db = await getDb();
  const user = await db.get('SELECT oura_access_token FROM users LIMIT 1');

  if (!user || !user.oura_access_token) {
    throw new Error('User not authenticated with Oura. Please set OURA_PERSONAL_TOKEN in .env file');
  }

  return user.oura_access_token;
}

// Fetch data from Oura API with retry logic
async function fetchOuraData(endpoint, startDate, endDate, retries = 3) {
  try {
    const accessToken = await getOuraAccessToken();
    
    if (!accessToken) {
      throw new Error('No Oura access token available');
    }
    
    const apiUrl = `${OURA_API_URL}/${endpoint}`;
    
    // Retry logic
    let lastError;
    for (let attempt = 0; attempt < retries; attempt++) {
      try {
        const response = await axios.get(apiUrl, {
          params: {
            start_date: startDate,
            end_date: endDate
          },
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          timeout: 10000 // 10 second timeout
        });
    
        if (!response.data) {
          throw new Error(`Empty response from Oura API for ${endpoint}`);
        }
        
        return response.data;
      } catch (error) {
        lastError = error;
        
        // Only retry on network errors or 5xx responses
        if (!error.response || (error.response.status >= 500 && error.response.status < 600)) {
          console.warn(`Attempt ${attempt + 1} failed for ${endpoint}. Retrying...`);
          await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1))); // Exponential backoff
          continue;
        }
        
        // Don't retry auth errors or other client errors
        throw error;
      }
    }
    
    throw lastError;
  } catch (error) {
    console.error(`Failed to fetch Oura ${endpoint} data:`, error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      throw new Error('Authentication error - please check your Oura personal token');
    } else if (error.response?.status === 404) {
      throw new Error(`Oura API endpoint not found: ${endpoint}`);
    } else if (error.code === 'ECONNABORTED') {
      throw new Error(`Oura API request timed out for ${endpoint}`);
    }
    
    throw new Error(`Failed to fetch Oura ${endpoint} data: ${error.message}`);
  }
}

// Save Oura data to database
async function saveOuraData(userId, dataType, date, data) {
  const db = await getDb();
  
  try {
    await db.run(
      `INSERT INTO oura_data (user_id, date, data_type, data)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(user_id, date, data_type) 
       DO UPDATE SET data = excluded.data, created_at = CURRENT_TIMESTAMP`,
      [userId, date, dataType, JSON.stringify(data)]
    );
  } catch (error) {
    console.error(`Failed to save Oura ${dataType} data:`, error);
    throw error;
  }
}

// Calculate date range (30 days ago until today)
function getDateRange() {
  const today = new Date();
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(today.getDate() - 30);
  
  // Log actual dates for debugging
  const startDateStr = thirtyDaysAgo.toISOString().split('T')[0];
  const endDateStr = today.toISOString().split('T')[0];
  console.log(`Using actual date range: ${startDateStr} to ${endDateStr}`);
  
  return {
    startDate: startDateStr,
    endDate: endDateStr
  };
}

// Sync all Oura data for a user
async function syncOuraData() {
  try {
    // Check if we have a personal token in .env
    const personalToken = process.env.OURA_PERSONAL_TOKEN;
    if (personalToken && personalToken.trim() !== '') {
      // Ensure token is in the database too
      const db = await getDb();
      await db.run(
        `UPDATE users 
         SET oura_access_token = ?, updated_at = CURRENT_TIMESTAMP 
         WHERE id = 1`,
        [personalToken]
      );
    }
    
    const db = await getDb();
    const user = await db.get('SELECT id, oura_access_token FROM users LIMIT 1');
    
    if (!user || !user.oura_access_token) {
      console.log('No authenticated user found, skipping Oura sync');
      return { success: false, message: 'No authenticated user found' };
    }

    const { startDate, endDate } = getDateRange();
    console.log(`Syncing Oura data from ${startDate} to ${endDate}`);

    // Updated v2 API endpoints with proper mapping
    const dataTypes = [
      { type: 'sleep', endpoint: 'usercollection/daily_sleep' },
      { type: 'readiness', endpoint: 'usercollection/daily_readiness' },
      { type: 'activity', endpoint: 'usercollection/daily_activity' },
      { type: 'daily', endpoint: 'usercollection/daily_stress' }
    ];
    
    const results = [];
    
    for (const { type, endpoint } of dataTypes) {
      try {
        console.log(`Fetching ${type} data from endpoint ${endpoint}...`);
        const data = await fetchOuraData(endpoint, startDate, endDate);
        
        // Process the data based on its structure
        if (data.data && Array.isArray(data.data)) {
          console.log(`Got ${data.data.length} ${type} records from Oura API`);
          for (const item of data.data) {
            // Make sure we have a valid date (day field is the standard in v2 API)
            const date = item.day || item.timestamp?.split('T')[0] || item.date;
            if (!date) {
              console.warn(`No date found in ${type} item, skipping`);
              continue;
            }
            await saveOuraData(user.id, type, date, item);
          }
          results.push({ type, status: 'success', count: data.data.length });
        } else {
          console.warn(`Invalid data structure in Oura API response for ${type}`);
          results.push({ type, status: 'failed', error: 'Invalid data structure' });
        }
      } catch (error) {
        console.error(`Error processing ${type} data:`, error.message);
        results.push({ type, status: 'failed', error: error.message });
        // Continue with other data types even if one fails
      }
    }

    // Calculate and update wellness scores
    try {
      await calculateWellnessScores(user.id);
      results.push({ type: 'wellness_scores', status: 'success' });
    } catch (error) {
      console.error('Failed to calculate wellness scores:', error);
      results.push({ type: 'wellness_scores', status: 'failed', error: error.message });
    }

    console.log('Oura data sync completed');
    return { success: true, results };
  } catch (error) {
    console.error('Failed to sync Oura data:', error);
    return { success: false, error: error.message };
  }
}

// Get processed Oura data for frontend
async function getProcessedOuraData(userId, startDate, endDate) {
  const db = await getDb();
  
  const sleepData = await db.all(
    `SELECT date, data FROM oura_data 
     WHERE user_id = ? AND data_type = 'sleep' AND date BETWEEN ? AND ?
     ORDER BY date ASC`,
    [userId, startDate, endDate]
  );
  
  const readinessData = await db.all(
    `SELECT date, data FROM oura_data 
     WHERE user_id = ? AND data_type = 'readiness' AND date BETWEEN ? AND ?
     ORDER BY date ASC`,
    [userId, startDate, endDate]
  );
  
  const activityData = await db.all(
    `SELECT date, data FROM oura_data 
     WHERE user_id = ? AND data_type = 'activity' AND date BETWEEN ? AND ?
     ORDER BY date ASC`,
    [userId, startDate, endDate]
  );
  
  const dailyData = await db.all(
    `SELECT date, data FROM oura_data 
     WHERE user_id = ? AND data_type = 'daily' AND date BETWEEN ? AND ?
     ORDER BY date ASC`,
    [userId, startDate, endDate]
  );

  // Process the data into a format suitable for frontend charts
  return {
    sleep: sleepData.map(item => ({
      date: item.date,
      ...JSON.parse(item.data)
    })),
    readiness: readinessData.map(item => ({
      date: item.date,
      ...JSON.parse(item.data)
    })),
    activity: activityData.map(item => ({
      date: item.date,
      ...JSON.parse(item.data)
    })),
    daily: dailyData.map(item => ({
      date: item.date,
      ...JSON.parse(item.data)
    }))
  };
}

module.exports = {
  syncOuraData,
  getProcessedOuraData,
  getDateRange
}; 