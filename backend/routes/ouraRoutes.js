const express = require('express');
const router = express.Router();
const { getProcessedOuraData, syncOuraData, getDateRange } = require('../services/ouraService');

// Sync Oura data on demand
router.post('/sync', async (req, res) => {
  try {
    await syncOuraData();
    res.json({ success: true, message: 'Oura data sync initiated' });
  } catch (error) {
    console.error('Oura sync error:', error);
    res.status(500).json({ success: false, error: 'Failed to sync Oura data' });
  }
});

// Get Oura data for display
router.get('/data', async (req, res) => {
  try {
    const userId = 1; // Default user
    const { startDate, endDate } = req.query.range ? JSON.parse(req.query.range) : getDateRange();
    
    const ouraData = await getProcessedOuraData(userId, startDate, endDate);
    res.json(ouraData);
  } catch (error) {
    console.error('Error fetching Oura data:', error);
    res.status(500).json({ error: 'Failed to fetch Oura data' });
  }
});

module.exports = router; 