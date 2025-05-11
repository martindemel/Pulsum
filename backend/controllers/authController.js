const { getDb } = require('../utils/db');
const axios = require('axios');

// Dexcom OAuth Configuration (these URLs will need to be verified)
const DEXCOM_AUTH_URL = 'https://api.dexcom.com/v2/oauth2/login';
const DEXCOM_TOKEN_URL = 'https://api.dexcom.com/v2/oauth2/token';
const DEXCOM_CLIENT_ID = process.env.DEXCOM_CLIENT_ID;
const DEXCOM_CLIENT_SECRET = process.env.DEXCOM_CLIENT_SECRET;
const DEXCOM_REDIRECT_URI = process.env.DEXCOM_REDIRECT_URI;
const DEXCOM_SCOPE = 'offline_access';

// Check Oura authentication status
exports.checkOuraAuthStatus = async (req, res) => {
  try {
    // Check if personal token exists in .env
    if (process.env.OURA_PERSONAL_TOKEN && process.env.OURA_PERSONAL_TOKEN.trim() !== '') {
      return res.json({ isAuthenticated: true, needsRefresh: false });
    }
    
    // Otherwise check the database
    const db = await getDb();
    const user = await db.get('SELECT oura_access_token FROM users LIMIT 1');
    
    const isAuthenticated = !!user.oura_access_token;
    
    res.json({ isAuthenticated, needsRefresh: false });
  } catch (error) {
    console.error('Error checking Oura auth status:', error);
    res.status(500).json({ error: 'Failed to check authentication status' });
  }
};

// Set Oura personal access token
exports.setOuraPersonalToken = async (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({ error: 'Token is required' });
    }
    
    // Store token in database
    const db = await getDb();
    const user = await db.get('SELECT id FROM users LIMIT 1');
    
    // Set expiry far in the future since personal tokens don't expire
    const expiresAt = new Date(Date.now() + 10 * 365 * 24 * 60 * 60 * 1000).toISOString(); // 10 years
    
    await db.run(
      `UPDATE users 
       SET oura_access_token = ?, oura_refresh_token = NULL, oura_token_expires_at = ?, updated_at = CURRENT_TIMESTAMP 
       WHERE id = ?`,
      [token, expiresAt, user.id]
    );
    
    res.json({ success: true, message: 'Oura personal token set successfully' });
  } catch (error) {
    console.error('Error setting Oura personal token:', error);
    res.status(500).json({ error: 'Failed to set Oura personal token' });
  }
};

// Get Dexcom login URL
exports.getDexcomLoginUrl = (req, res) => {
  // Check if Dexcom integration is enabled
  if (!DEXCOM_CLIENT_ID || !DEXCOM_CLIENT_SECRET) {
    return res.status(400).json({ error: 'Dexcom integration is not configured' });
  }
  
  const authUrl = `${DEXCOM_AUTH_URL}?client_id=${DEXCOM_CLIENT_ID}&redirect_uri=${encodeURIComponent(DEXCOM_REDIRECT_URI)}&response_type=code&scope=${encodeURIComponent(DEXCOM_SCOPE)}`;
  res.json({ authUrl });
};

// Handle Dexcom callback
exports.handleDexcomCallback = async (req, res) => {
  const { code } = req.query;
  if (!code) {
    return res.status(400).json({ error: 'Authorization code is missing' });
  }

  try {
    // Exchange code for tokens
    const tokenResponse = await axios.post(DEXCOM_TOKEN_URL, {
      grant_type: 'authorization_code',
      code,
      client_id: DEXCOM_CLIENT_ID,
      client_secret: DEXCOM_CLIENT_SECRET,
      redirect_uri: DEXCOM_REDIRECT_URI,
    });

    const { access_token, refresh_token, expires_in } = tokenResponse.data;
    const expiresAt = new Date(Date.now() + expires_in * 1000).toISOString();

    // Store tokens in database
    const db = await getDb();
    const user = await db.get('SELECT id FROM users LIMIT 1');
    
    await db.run(
      `UPDATE users 
       SET dexcom_access_token = ?, dexcom_refresh_token = ?, dexcom_token_expires_at = ?, use_dexcom = 1, updated_at = CURRENT_TIMESTAMP 
       WHERE id = ?`,
      [access_token, refresh_token, expiresAt, user.id]
    );

    // Redirect to frontend
    res.redirect(`${process.env.NODE_ENV === 'production' ? '/' : 'http://localhost:3000'}/dashboard?auth=dexcom-success`);
  } catch (error) {
    console.error('Dexcom authentication error:', error.response?.data || error.message);
    res.redirect(`${process.env.NODE_ENV === 'production' ? '/' : 'http://localhost:3000'}/dashboard?auth=dexcom-error`);
  }
};

// Check Dexcom authentication status
exports.checkDexcomAuthStatus = async (req, res) => {
  try {
    const db = await getDb();
    const user = await db.get('SELECT dexcom_access_token, dexcom_token_expires_at, use_dexcom FROM users LIMIT 1');
    
    const isAuthenticated = !!user.dexcom_access_token;
    const tokenExpired = user.dexcom_token_expires_at && new Date(user.dexcom_token_expires_at) < new Date();
    const isEnabled = !!user.use_dexcom;
    
    if (isAuthenticated && tokenExpired) {
      // Token is expired, should refresh
      res.json({ isAuthenticated, needsRefresh: true, isEnabled });
    } else {
      res.json({ isAuthenticated, needsRefresh: false, isEnabled });
    }
  } catch (error) {
    console.error('Error checking Dexcom auth status:', error);
    res.status(500).json({ error: 'Failed to check authentication status' });
  }
};

// Toggle Dexcom integration
exports.toggleDexcomIntegration = async (req, res) => {
  try {
    const { enabled } = req.body;
    
    const db = await getDb();
    await db.run('UPDATE users SET use_dexcom = ? WHERE id = 1', [enabled ? 1 : 0]);
    
    res.json({ success: true, isEnabled: !!enabled });
  } catch (error) {
    console.error('Error toggling Dexcom integration:', error);
    res.status(500).json({ error: 'Failed to toggle Dexcom integration' });
  }
}; 