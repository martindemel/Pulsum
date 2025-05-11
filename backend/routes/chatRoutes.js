const express = require('express');
const router = express.Router();
const managerAgent = require('../agents/managerAgent');
const { getDb } = require('../utils/db');

// Diagnostic endpoint to check OpenAI availability
router.get('/status', (req, res) => {
  res.json({
    isAIAvailable: managerAgent.isAIAvailable,
    openaiInitialized: !!managerAgent.openai
  });
});

// Process a new chat message
router.post('/message', async (req, res) => {
  try {
    const { message } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    const userId = 1; // Default user
    const response = await managerAgent.processChat(userId, message);
    
    res.json(response);
  } catch (error) {
    console.error('Chat processing error:', error);
    res.status(500).json({ error: 'Failed to process chat message' });
  }
});

// Get chat history
router.get('/history', async (req, res) => {
  try {
    const userId = 1; // Default user
    const db = await getDb();
    
    // Get the most recent 50 messages
    const history = await db.all(
      `SELECT id, timestamp, role, content
       FROM chat_history
       WHERE user_id = ?
       ORDER BY timestamp DESC
       LIMIT 50`,
      [userId]
    );
    
    // Reverse to get chronological order
    res.json(history.reverse());
  } catch (error) {
    console.error('Error fetching chat history:', error);
    res.status(500).json({ error: 'Failed to fetch chat history' });
  }
});

// Clear chat history
router.delete('/history', async (req, res) => {
  try {
    const userId = 1; // Default user
    const db = await getDb();
    
    await db.run('DELETE FROM chat_history WHERE user_id = ?', [userId]);
    
    res.json({ success: true, message: 'Chat history cleared' });
  } catch (error) {
    console.error('Error clearing chat history:', error);
    res.status(500).json({ error: 'Failed to clear chat history' });
  }
});

module.exports = router; 