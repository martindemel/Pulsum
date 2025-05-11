const express = require('express');
const router = express.Router();
const { getDb } = require('../utils/db');
const { getWellnessScores, calculateWellnessScores } = require('../services/wellnessScoreService');
const { getDateRange } = require('../services/ouraService');

// Get user profile and settings
router.get('/profile', async (req, res) => {
  try {
    const db = await getDb();
    const user = await db.get('SELECT id, created_at, updated_at, use_dexcom FROM users LIMIT 1');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ error: 'Failed to fetch user profile' });
  }
});

// Get wellness scores for a date range
router.get('/wellness-scores', async (req, res) => {
  try {
    const userId = 1; // Default user
    const { startDate, endDate } = req.query.range ? JSON.parse(req.query.range) : getDateRange();
    
    const scores = await getWellnessScores(userId, startDate, endDate);
    res.json(scores);
  } catch (error) {
    console.error('Error fetching wellness scores:', error);
    res.status(500).json({ error: 'Failed to fetch wellness scores' });
  }
});

// Get user dashboard summary
router.get('/dashboard-summary', async (req, res) => {
  try {
    const userId = 1; // Default user
    const db = await getDb();
    
    // Get today's date
    const today = new Date().toISOString().split('T')[0];
    
    // Get yesterday's date
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split('T')[0];
    
    // Get last 7 days
    const lastWeek = new Date();
    lastWeek.setDate(lastWeek.getDate() - 7);
    const lastWeekStr = lastWeek.toISOString().split('T')[0];
    
    // Try to get today's wellness scores first, fall back to yesterday if not available
    let wellnessScores = await db.get(
      `SELECT objective_score, subjective_score, combined_score 
       FROM wellness_scores 
       WHERE user_id = ? AND date = ?
       LIMIT 1`,
      [userId, today]
    );
    
    // If no scores for today, try yesterday
    if (!wellnessScores) {
      wellnessScores = await db.get(
        `SELECT objective_score, subjective_score, combined_score 
         FROM wellness_scores 
         WHERE user_id = ? AND date = ?
         LIMIT 1`,
        [userId, yesterdayStr]
      );
    }
    
    // If still no scores, get the most recent one
    if (!wellnessScores) {
      wellnessScores = await db.get(
        `SELECT objective_score, subjective_score, combined_score 
         FROM wellness_scores 
         WHERE user_id = ? 
         ORDER BY date DESC
         LIMIT 1`,
        [userId]
      );
    }
    
    console.log('Wellness scores for dashboard:', wellnessScores);
    
    // Get most recent journal entry
    const journalEntry = await db.get(
      `SELECT date, mood_rating, sleep_rating 
       FROM journal_entries 
       WHERE user_id = ? 
       ORDER BY date DESC 
       LIMIT 1`,
      [userId]
    );
    
    // Get today's recommendations count
    const recommendationsCount = await db.get(
      `SELECT COUNT(*) as count, SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
       FROM recommendations
       WHERE user_id = ? AND date = ?`,
      [userId, today]
    );
    
    // Get Oura data stats
    const ouraStats = await db.get(
      `SELECT 
         (SELECT COUNT(*) FROM oura_data WHERE user_id = ? AND data_type = 'sleep') as sleep_days,
         (SELECT COUNT(*) FROM oura_data WHERE user_id = ? AND data_type = 'readiness') as readiness_days,
         (SELECT COUNT(*) FROM oura_data WHERE user_id = ? AND data_type = 'activity') as activity_days,
         (SELECT MAX(date) FROM oura_data WHERE user_id = ?) as last_sync_date`,
      [userId, userId, userId, userId]
    );
    
    // First check if use_dexcom column exists
    let dexcomStatus = { use_dexcom: 0, glucose_readings_count: 0, last_sync_date: null };
    
    try {
      // Check if the column exists
      const tableInfo = await db.all('PRAGMA table_info(users)');
      const columnExists = tableInfo.some(column => column.name === 'use_dexcom');
      
      if (columnExists) {
        // Safe to query with use_dexcom column
        dexcomStatus = await db.get(
          `SELECT use_dexcom, 
             (SELECT COUNT(*) FROM dexcom_data WHERE user_id = ?) as glucose_readings_count,
             (SELECT MAX(date) FROM dexcom_data WHERE user_id = ?) as last_sync_date`,
          [userId, userId]
        ) || dexcomStatus;
      } else {
        // Just get counts without use_dexcom
        const dexcomCounts = await db.get(
          `SELECT COUNT(*) as glucose_readings_count, 
                  MAX(date) as last_sync_date 
           FROM dexcom_data WHERE user_id = ?`,
          [userId]
        );
        
        if (dexcomCounts) {
          dexcomStatus.glucose_readings_count = dexcomCounts.glucose_readings_count;
          dexcomStatus.last_sync_date = dexcomCounts.last_sync_date;
        }
      }
    } catch (dexcomError) {
      console.error('Error getting dexcom status (non-critical):', dexcomError);
      // Continue with default dexcomStatus
    }
    
    // Get 7-day wellness trend
    const wellnessTrend = await db.all(
      `SELECT date, combined_score
       FROM wellness_scores
       WHERE user_id = ? AND date BETWEEN ? AND ?
       ORDER BY date ASC`,
      [userId, lastWeekStr, today]
    );
    
    res.json({
      wellnessScores: wellnessScores || { objective_score: null, subjective_score: null, combined_score: null },
      journalEntry: journalEntry || { date: null, mood_rating: null, sleep_rating: null },
      recommendations: {
        count: recommendationsCount?.count || 0,
        completed: recommendationsCount?.completed || 0
      },
      ouraStats: {
        sleep_days: ouraStats?.sleep_days || 0,
        readiness_days: ouraStats?.readiness_days || 0,
        activity_days: ouraStats?.activity_days || 0,
        last_sync_date: ouraStats?.last_sync_date || null
      },
      dexcomStatus: {
        enabled: !!dexcomStatus?.use_dexcom,
        glucose_readings_count: dexcomStatus?.glucose_readings_count || 0,
        last_sync_date: dexcomStatus?.last_sync_date || null
      },
      wellnessTrend: wellnessTrend || []
    });
  } catch (error) {
    console.error('Error fetching dashboard summary:', error);
    res.status(500).json({ 
      error: 'Failed to fetch dashboard summary',
      message: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Recalculate wellness scores
router.post('/recalculate-wellness-scores', async (req, res) => {
  try {
    const userId = 1; // Default user
    
    console.log('Starting wellness score recalculation');
    
    // Recalculate scores
    await calculateWellnessScores(userId);
    
    // Get the updated scores
    const { startDate, endDate } = getDateRange();
    const scores = await getWellnessScores(userId, startDate, endDate);
    
    console.log(`Recalculated ${scores.length} wellness scores`);
    
    res.json({ 
      success: true, 
      message: `Recalculated ${scores.length} wellness scores`,
      scores: scores
    });
  } catch (error) {
    console.error('Error recalculating wellness scores:', error);
    res.status(500).json({ 
      error: 'Failed to recalculate wellness scores',
      message: error.message
    });
  }
});

module.exports = router; 