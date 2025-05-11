const express = require('express');
const router = express.Router();
const { getProcessedDexcomData, syncDexcomData, isDexcomEnabled } = require('../services/dexcomService');
const { getDateRange } = require('../services/ouraService');

// Sync Dexcom data on demand
router.post('/sync', async (req, res) => {
  try {
    // Check if Dexcom is enabled
    const dexcomEnabled = await isDexcomEnabled();
    if (!dexcomEnabled) {
      return res.status(400).json({ success: false, error: 'Dexcom integration is not enabled' });
    }
    
    await syncDexcomData();
    res.json({ success: true, message: 'Dexcom data sync initiated' });
  } catch (error) {
    console.error('Dexcom sync error:', error);
    res.status(500).json({ success: false, error: 'Failed to sync Dexcom data' });
  }
});

// Get Dexcom data for display
router.get('/data', async (req, res) => {
  try {
    // Check if Dexcom is enabled
    const dexcomEnabled = await isDexcomEnabled();
    if (!dexcomEnabled) {
      return res.status(400).json({ success: false, error: 'Dexcom integration is not enabled' });
    }
    
    const userId = 1; // Default user
    const { startDate, endDate } = req.query.range ? JSON.parse(req.query.range) : getDateRange();
    
    const dexcomData = await getProcessedDexcomData(userId, startDate, endDate);
    res.json(dexcomData);
  } catch (error) {
    console.error('Error fetching Dexcom data:', error);
    res.status(500).json({ error: 'Failed to fetch Dexcom data' });
  }
});

module.exports = router; 