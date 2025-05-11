const express = require('express');
const router = express.Router();
const { SentimentJournalAgent } = require('../agents/sentimentJournalAgent');
const { getDateRange } = require('../services/ouraService');

// Create sentinel instance
const sentimentJournalAgent = new SentimentJournalAgent();

// Create a new journal entry
router.post('/entry', async (req, res) => {
  try {
    const { date, moodRating, sleepRating, entryText } = req.body;
    
    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }
    
    if (!moodRating && !sleepRating && !entryText) {
      return res.status(400).json({ error: 'At least one of mood rating, sleep rating, or entry text is required' });
    }
    
    const userId = 1; // Default user
    
    const result = await sentimentJournalAgent.createJournalEntry(
      userId, 
      date, 
      moodRating || null, 
      sleepRating || null, 
      entryText || null
    );
    
    res.json(result);
  } catch (error) {
    console.error('Error creating journal entry:', error);
    res.status(500).json({ error: 'Failed to create journal entry' });
  }
});

// Get journal entries for a date range
router.get('/entries', async (req, res) => {
  try {
    const userId = 1; // Default user
    const { startDate, endDate } = req.query.range ? JSON.parse(req.query.range) : getDateRange();
    
    const entries = await sentimentJournalAgent.getJournalEntries(userId, startDate, endDate);
    res.json(entries);
  } catch (error) {
    console.error('Error fetching journal entries:', error);
    res.status(500).json({ error: 'Failed to fetch journal entries' });
  }
});

// Get the most recent journal entry
router.get('/latest', async (req, res) => {
  try {
    const userId = 1; // Default user
    
    const entry = await sentimentJournalAgent.getMostRecentEntry(userId);
    res.json(entry || { message: 'No journal entries found' });
  } catch (error) {
    console.error('Error fetching most recent journal entry:', error);
    res.status(500).json({ error: 'Failed to fetch most recent journal entry' });
  }
});

module.exports = router; 