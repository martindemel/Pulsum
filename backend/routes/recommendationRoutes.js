const express = require('express');
const router = express.Router();
const managerAgent = require('../agents/managerAgent');
const { RecommendationAgent } = require('../agents/recommendationAgent');
const { getDateRange } = require('../services/ouraService');
const { getDb } = require('../utils/db');

// Create singleton instance
const recommendationAgent = new RecommendationAgent();

// Helper function to get default user
async function getDefaultUser() {
  const db = await getDb();
  const user = await db.get('SELECT id FROM users LIMIT 1');
  
  if (!user) {
    throw new Error('No user found in the database');
  }
  
  return user.id;
}

// Generate new recommendations
router.post('/generate', async (req, res) => {
  try {
    const userId = await getDefaultUser();
    
    const recommendations = await managerAgent.generateDailyRecommendations(userId);
    
    if (!recommendations || !Array.isArray(recommendations)) {
      return res.status(500).json({ 
        error: 'Failed to generate recommendations',
        message: 'The recommendation engine returned an invalid response'
      });
    }
    
    res.json({ success: true, recommendations });
  } catch (error) {
    console.error('Error generating recommendations:', error);
    res.status(500).json({ 
      error: 'Failed to generate recommendations',
      message: error.message 
    });
  }
});

// Get recommendations for a date range
router.get('/list', async (req, res) => {
  try {
    const userId = await getDefaultUser();
    let dateRange;
    
    try {
      dateRange = req.query.range ? JSON.parse(req.query.range) : getDateRange();
    } catch (parseError) {
      console.error('Error parsing date range:', parseError);
      dateRange = getDateRange();
    }
    
    const { startDate, endDate } = dateRange;
    
    if (!startDate || !endDate || new Date(startDate) > new Date(endDate)) {
      return res.status(400).json({ 
        error: 'Invalid date range',
        message: 'Please provide a valid date range with startDate before endDate' 
      });
    }
    
    const recommendations = await recommendationAgent.getUserRecommendations(userId, startDate, endDate);
    res.json(recommendations);
  } catch (error) {
    console.error('Error fetching recommendations:', error);
    res.status(500).json({ 
      error: 'Failed to fetch recommendations',
      message: error.message
    });
  }
});

// Update recommendation feedback
router.post('/feedback/:id', async (req, res) => {
  try {
    const recommendationId = parseInt(req.params.id);
    
    if (isNaN(recommendationId) || recommendationId <= 0) {
      return res.status(400).json({ 
        error: 'Invalid recommendation ID',
        message: 'The recommendation ID must be a positive integer'
      });
    }
    
    const { isLiked, isCompleted } = req.body;
    
    if (isLiked === undefined && isCompleted === undefined) {
      return res.status(400).json({ 
        error: 'Missing feedback data',
        message: 'Either isLiked or isCompleted is required' 
      });
    }
    
    const userId = await getDefaultUser();
    
    const result = await recommendationAgent.updateRecommendationFeedback(
      userId,
      recommendationId,
      isLiked,
      isCompleted
    );
    
    res.json(result);
  } catch (error) {
    console.error('Error updating recommendation feedback:', error);
    res.status(500).json({ 
      error: 'Failed to update recommendation feedback',
      message: error.message
    });
  }
});

// Get today's recommendations
router.get('/today', async (req, res) => {
  try {
    const userId = await getDefaultUser();
    const today = new Date().toISOString().split('T')[0];
    
    const db = await getDb();
    const recommendations = await db.all(
      `SELECT id, recommendation_text, category, subcategory, source, 
              microaction, difficulty_level, time_to_complete, is_completed, is_liked
       FROM recommendations
       WHERE user_id = ? AND date = ?
       ORDER BY created_at DESC`,
      [userId, today]
    );
    
    // If no recommendations for today, generate some
    if (recommendations.length === 0) {
      try {
        const newRecommendations = await managerAgent.generateDailyRecommendations(userId);
        
        if (!newRecommendations || !Array.isArray(newRecommendations)) {
          return res.status(500).json({ 
            error: 'Failed to generate recommendations',
            message: 'The recommendation engine returned an invalid response'
          });
        }
        
        // Fetch the newly generated recommendations
        const freshRecommendations = await db.all(
          `SELECT id, recommendation_text, category, subcategory, source, 
                  microaction, difficulty_level, time_to_complete, is_completed, is_liked
           FROM recommendations
           WHERE user_id = ? AND date = ?
           ORDER BY created_at DESC`,
          [userId, today]
        );
        
        res.json(freshRecommendations);
      } catch (genError) {
        console.error('Error generating recommendations:', genError);
        res.status(500).json({ 
          error: 'Failed to generate recommendations',
          message: genError.message
        });
      }
    } else {
      res.json(recommendations);
    }
  } catch (error) {
    console.error('Error fetching today\'s recommendations:', error);
    res.status(500).json({ 
      error: 'Failed to fetch today\'s recommendations',
      message: error.message
    });
  }
});

module.exports = router; 