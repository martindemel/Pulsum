const axios = require('axios');
const { getDb } = require('../utils/db');
const { getDateRange } = require('./ouraService');

const DEXCOM_API_URL = 'https://api.dexcom.com/v2';

// Refresh Dexcom token if expired
async function refreshDexcomToken(refreshToken) {
  try {
    const response = await axios.post('https://api.dexcom.com/v2/oauth2/token', {
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: process.env.DEXCOM_CLIENT_ID,
      client_secret: process.env.DEXCOM_CLIENT_SECRET,
      redirect_uri: process.env.DEXCOM_REDIRECT_URI
    });

    const { access_token, refresh_token, expires_in } = response.data;
    const expiresAt = new Date(Date.now() + expires_in * 1000).toISOString();

    // Update tokens in database
    const db = await getDb();
    await db.run(
      `UPDATE users 
       SET dexcom_access_token = ?, dexcom_refresh_token = ?, dexcom_token_expires_at = ?, updated_at = CURRENT_TIMESTAMP 
       WHERE id = 1`,
      [access_token, refresh_token, expiresAt]
    );

    return access_token;
  } catch (error) {
    console.error('Failed to refresh Dexcom token:', error.response?.data || error.message);
    
    // More specific error messages based on error type
    if (error.response?.status === 400) {
      throw new Error('Invalid refresh token for Dexcom. Please re-authenticate.');
    } else if (error.response?.status === 401) {
      throw new Error('Unauthorized access to Dexcom API. Please check your client credentials.');
    }
    
    throw new Error(`Failed to refresh Dexcom token: ${error.message}`);
  }
}

// Get Dexcom access token (refreshing if needed)
async function getDexcomAccessToken() {
  const db = await getDb();
  const user = await db.get('SELECT dexcom_access_token, dexcom_refresh_token, dexcom_token_expires_at, use_dexcom FROM users LIMIT 1');

  if (!user) {
    throw new Error('No user found in database');
  }
  
  if (!user.use_dexcom) {
    throw new Error('Dexcom integration is disabled');
  }
  
  if (!user.dexcom_access_token || !user.dexcom_refresh_token) {
    throw new Error('User not authenticated with Dexcom');
  }

  // Check if token is expired
  if (user.dexcom_token_expires_at && new Date(user.dexcom_token_expires_at) < new Date()) {
    console.log('Dexcom token expired, refreshing...');
    return refreshDexcomToken(user.dexcom_refresh_token);
  }

  return user.dexcom_access_token;
}

// Fetch glucose data from Dexcom API with retry logic
async function fetchDexcomGlucoseData(startDate, endDate, retries = 3) {
  try {
    const accessToken = await getDexcomAccessToken();
    
    // Convert dates to Dexcom format
    const startDateTime = new Date(startDate);
    const endDateTime = new Date(endDate);
    
    // Add time to make it a complete datetime
    startDateTime.setUTCHours(0, 0, 0, 0);
    endDateTime.setUTCHours(23, 59, 59, 999);
    
    // Retry logic
    let lastError;
    for (let attempt = 0; attempt < retries; attempt++) {
      try {
        const response = await axios.get(`${DEXCOM_API_URL}/users/self/egvs`, {
          params: {
            startDate: startDateTime.toISOString(),
            endDate: endDateTime.toISOString()
          },
          headers: {
            Authorization: `Bearer ${accessToken}`
          },
          timeout: 10000 // 10 second timeout
        });

        if (!response.data || !response.data.records) {
          throw new Error('Invalid response format from Dexcom API');
        }
        
        return response.data;
      } catch (error) {
        lastError = error;
        
        // Check if token expired and needs refresh
        if (error.response?.status === 401) {
          console.log('Dexcom token appears expired during request, attempting to refresh...');
          try {
            const db = await getDb();
            const user = await db.get('SELECT dexcom_refresh_token FROM users LIMIT 1');
            if (user && user.dexcom_refresh_token) {
              // Get fresh token and retry immediately
              await refreshDexcomToken(user.dexcom_refresh_token);
              continue;
            }
          } catch (refreshError) {
            console.error('Failed to refresh token during request:', refreshError);
            throw refreshError;
          }
        }
        
        // Only retry on network errors or 5xx responses
        if (!error.response || (error.response.status >= 500 && error.response.status < 600)) {
          console.warn(`Attempt ${attempt + 1} failed for Dexcom API. Retrying in ${attempt + 1}s...`);
          await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1))); // Exponential backoff
          continue;
        }
        
        // Don't retry other client errors
        throw error;
      }
    }
    
    throw lastError;
  } catch (error) {
    console.error('Failed to fetch Dexcom glucose data:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      throw new Error('Authentication error - Dexcom token invalid or expired');
    } else if (error.response?.status === 403) {
      throw new Error('Access forbidden - check Dexcom permissions');
    } else if (error.code === 'ECONNABORTED') {
      throw new Error('Dexcom API request timed out');
    }
    
    throw new Error(`Failed to fetch Dexcom glucose data: ${error.message}`);
  }
}

// Save Dexcom data to database
async function saveDexcomData(userId, readings) {
  const db = await getDb();
  
  try {
    // Begin transaction
    await db.run('BEGIN TRANSACTION');
    
    // Prepare statement for better performance
    const stmt = await db.prepare(`
      INSERT OR REPLACE INTO dexcom_data 
      (user_id, date, reading_time, glucose_value, trend, created_at)
      VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
    `);
    
    for (const reading of readings) {
      const readingTime = new Date(reading.systemTime);
      const date = readingTime.toISOString().split('T')[0];
      await stmt.run(userId, date, readingTime.toISOString(), reading.value, reading.trend);
    }
    
    // Finalize statement and commit transaction
    await stmt.finalize();
    await db.run('COMMIT');
    
    console.log(`Saved ${readings.length} Dexcom readings`);
  } catch (error) {
    // Rollback in case of error
    await db.run('ROLLBACK');
    console.error('Failed to save Dexcom data:', error);
    throw error;
  }
}

// Sync all Dexcom data for a user
async function syncDexcomData() {
  try {
    const db = await getDb();
    const user = await db.get('SELECT id, dexcom_access_token, use_dexcom FROM users LIMIT 1');
    
    if (!user) {
      console.log('No user found, skipping Dexcom sync');
      return { success: false, message: 'No user found' };
    }
    
    if (!user.use_dexcom) {
      console.log('Dexcom integration is disabled, skipping Dexcom sync');
      return { success: false, message: 'Dexcom integration disabled' };
    }
    
    if (!user.dexcom_access_token) {
      console.log('No Dexcom access token found, skipping Dexcom sync');
      return { success: false, message: 'No Dexcom access token' };
    }

    const { startDate, endDate } = getDateRange();
    console.log(`Syncing Dexcom data from ${startDate} to ${endDate}`);

    try {
      const glucoseData = await fetchDexcomGlucoseData(startDate, endDate);
      
      if (glucoseData && glucoseData.records && glucoseData.records.length > 0) {
        await saveDexcomData(user.id, glucoseData.records);
        console.log('Dexcom data sync completed successfully');
        return { success: true, count: glucoseData.records.length };
      } else {
        console.log('No Dexcom records found for the specified date range');
        return { success: true, count: 0, message: 'No records found' };
      }
    } catch (apiError) {
      console.error('Error during Dexcom API call or data processing:', apiError);
      return { success: false, error: apiError.message };
    }
  } catch (error) {
    console.error('Failed to sync Dexcom data:', error);
    return { success: false, error: error.message };
  }
}

// Get processed Dexcom data for frontend
async function getProcessedDexcomData(userId, startDate, endDate) {
  const db = await getDb();
  
  try {
    const readings = await db.all(
      `SELECT date, reading_time, glucose_value, trend
       FROM dexcom_data 
       WHERE user_id = ? AND date BETWEEN ? AND ?
       ORDER BY reading_time ASC`,
      [userId, startDate, endDate]
    );
    
    // Group by date for daily statistics
    const dailyStats = {};
    
    for (const reading of readings) {
      if (!dailyStats[reading.date]) {
        dailyStats[reading.date] = {
          date: reading.date,
          readings: [],
          min: Infinity,
          max: -Infinity,
          avg: 0,
          readings_count: 0
        };
      }
      
      dailyStats[reading.date].readings.push({
        time: reading.reading_time,
        value: reading.glucose_value,
        trend: reading.trend
      });
      
      dailyStats[reading.date].min = Math.min(dailyStats[reading.date].min, reading.glucose_value);
      dailyStats[reading.date].max = Math.max(dailyStats[reading.date].max, reading.glucose_value);
      dailyStats[reading.date].readings_count++;
    }
    
    // Calculate averages
    for (const date in dailyStats) {
      const sum = dailyStats[date].readings.reduce((acc, r) => acc + r.value, 0);
      dailyStats[date].avg = sum / dailyStats[date].readings_count;
    }
    
    return {
      dailyStats: Object.values(dailyStats),
      allReadings: readings.map(r => ({
        date: r.date,
        time: r.reading_time,
        value: r.glucose_value,
        trend: r.trend
      }))
    };
  } catch (error) {
    console.error('Failed to get processed Dexcom data:', error);
    throw error;
  }
}

// Check if Dexcom is enabled for user
async function isDexcomEnabled() {
  const db = await getDb();
  const user = await db.get('SELECT use_dexcom FROM users LIMIT 1');
  return user && !!user.use_dexcom;
}

module.exports = {
  syncDexcomData,
  getProcessedDexcomData,
  isDexcomEnabled
}; 