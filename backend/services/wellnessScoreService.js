const { getDb } = require('../utils/db');

// Calculate wellness scores based on Oura data and subjective metrics
async function calculateWellnessScores(userId) {
  const db = await getDb();
  const today = new Date().toISOString().split('T')[0];
  
  // Get all dates with Oura data for the last 30 days
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const startDate = thirtyDaysAgo.toISOString().split('T')[0];
  
  const dates = await db.all(
    `SELECT DISTINCT date FROM oura_data 
     WHERE user_id = ? AND date BETWEEN ? AND ?
     ORDER BY date ASC`,
    [userId, startDate, today]
  );
  
  console.log(`Calculating wellness scores for ${dates.length} dates`);
  
  for (const { date } of dates) {
    try {
      console.log(`Processing wellness score for date: ${date}`);
      
      // Get objective data (Oura metrics)
      const ouraData = await getOuraDataForDate(userId, date);
      
      // Get subjective data (journal entries)
      const journalEntry = await db.get(
        `SELECT mood_rating, sleep_rating FROM journal_entries 
         WHERE user_id = ? AND date = ?`,
        [userId, date]
      );
      
      // Calculate scores
      const objectiveScore = calculateObjectiveScore(ouraData);
      const subjectiveScore = calculateSubjectiveScore(journalEntry);
      
      // Only calculate combined score if we have either objective or subjective data
      let combinedScore = null;
      
      if (objectiveScore !== null && subjectiveScore !== null) {
        combinedScore = (objectiveScore * 0.6) + (subjectiveScore * 0.4);
      } else if (objectiveScore !== null) {
        combinedScore = objectiveScore;
      } else if (subjectiveScore !== null) {
        combinedScore = subjectiveScore;
      }
      
      console.log(`Scores for ${date}: objective=${objectiveScore}, subjective=${subjectiveScore}, combined=${combinedScore}`);
      
      // Store the scores
      await db.run(
        `INSERT INTO wellness_scores (user_id, date, objective_score, subjective_score, combined_score, created_at)
         VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
         ON CONFLICT(user_id, date) 
         DO UPDATE SET objective_score = excluded.objective_score, 
                       subjective_score = excluded.subjective_score,
                       combined_score = excluded.combined_score,
                       created_at = CURRENT_TIMESTAMP`,
        [userId, date, objectiveScore, subjectiveScore, combinedScore]
      );
    } catch (error) {
      console.error(`Failed to calculate wellness scores for date ${date}:`, error);
      // Continue with next date
    }
  }
}

// Get Oura data for a specific date
async function getOuraDataForDate(userId, date) {
  const db = await getDb();
  
  const readinessData = await db.get(
    `SELECT data FROM oura_data 
     WHERE user_id = ? AND date = ? AND data_type = 'readiness'`,
    [userId, date]
  );
  
  const sleepData = await db.get(
    `SELECT data FROM oura_data 
     WHERE user_id = ? AND date = ? AND data_type = 'sleep'`,
    [userId, date]
  );
  
  const activityData = await db.get(
    `SELECT data FROM oura_data 
     WHERE user_id = ? AND date = ? AND data_type = 'activity'`,
    [userId, date]
  );
  
  return {
    readiness: readinessData ? JSON.parse(readinessData.data) : null,
    sleep: sleepData ? JSON.parse(sleepData.data) : null,
    activity: activityData ? JSON.parse(activityData.data) : null
  };
}

// Calculate objective wellness score based on Oura data
function calculateObjectiveScore(ouraData) {
  // Check if we have any data to work with
  if (!ouraData.readiness && !ouraData.sleep && !ouraData.activity) {
    return null; // Not enough data
  }
  
  let scoreComponents = [];
  let weightSum = 0;
  
  // Handle Oura API v2 data structure
  
  // Readiness score (if available)
  if (ouraData.readiness) {
    // In v2 API, check for both old and new structures
    // Try to get score from contributors first (v2 API)
    let readinessScore = null;
    
    if (ouraData.readiness.score !== undefined) {
      // Old API structure
      readinessScore = ouraData.readiness.score;
    } else if (ouraData.readiness.readiness_score !== undefined) {
      // New v2 API structure
      readinessScore = ouraData.readiness.readiness_score;
    } else if (ouraData.readiness.contributors && ouraData.readiness.contributors.score !== undefined) {
      // Alternative v2 structure
      readinessScore = ouraData.readiness.contributors.score;
    }
    
    if (readinessScore !== null) {
      scoreComponents.push({ score: readinessScore / 100, weight: 0.4 });
      weightSum += 0.4;
    }
  }
  
  // Sleep score (if available)
  if (ouraData.sleep) {
    let sleepScore = null;
    
    if (ouraData.sleep.score !== undefined) {
      // Old API structure
      sleepScore = ouraData.sleep.score;
    } else if (ouraData.sleep.sleep_score !== undefined) {
      // New v2 API structure
      sleepScore = ouraData.sleep.sleep_score;
    } else if (ouraData.sleep.contributors && ouraData.sleep.contributors.score !== undefined) {
      // Alternative v2 structure
      sleepScore = ouraData.sleep.contributors.score;
    }
    
    if (sleepScore !== null) {
      scoreComponents.push({ score: sleepScore / 100, weight: 0.3 });
      weightSum += 0.3;
    }
  }
  
  // Activity score (if available)
  if (ouraData.activity) {
    let activityScore = null;
    
    if (ouraData.activity.score !== undefined) {
      // Old API structure
      activityScore = ouraData.activity.score;
    } else if (ouraData.activity.activity_score !== undefined) {
      // New v2 API structure
      activityScore = ouraData.activity.activity_score;
    } else if (ouraData.activity.contributors && ouraData.activity.contributors.score !== undefined) {
      // Alternative v2 structure
      activityScore = ouraData.activity.contributors.score;
    } else if (ouraData.activity.active_calories !== undefined) {
      // Use active calories as a proxy (0-600 calories converted to 0-100 score)
      const activeCalories = Math.min(600, ouraData.activity.active_calories || 0);
      activityScore = (activeCalories / 600) * 100;
    }
    
    if (activityScore !== null) {
      scoreComponents.push({ score: activityScore / 100, weight: 0.3 });
      weightSum += 0.3;
    }
  }
  
  // If we don't have any data, return null
  if (scoreComponents.length === 0 || weightSum === 0) {
    return null;
  }
  
  // Calculate weighted average
  const weightedSum = scoreComponents.reduce((sum, component) => sum + (component.score * component.weight), 0);
  const normalizedScore = weightedSum / weightSum;
  
  // Return the score on a 0-100 scale
  return Math.round(normalizedScore * 100);
}

// Calculate subjective wellness score based on journal entries
function calculateSubjectiveScore(journalEntry) {
  if (!journalEntry || (!journalEntry.mood_rating && !journalEntry.sleep_rating)) {
    return null; // Not enough data
  }
  
  let scoreComponents = [];
  let weightSum = 0;
  
  // Mood rating (if available)
  if (journalEntry.mood_rating) {
    const moodScore = (journalEntry.mood_rating - 1) / 4; // Convert 1-5 to 0-1
    scoreComponents.push({ score: moodScore, weight: 0.6 });
    weightSum += 0.6;
  }
  
  // Sleep rating (if available)
  if (journalEntry.sleep_rating) {
    const sleepScore = (journalEntry.sleep_rating - 1) / 4; // Convert 1-5 to 0-1
    scoreComponents.push({ score: sleepScore, weight: 0.4 });
    weightSum += 0.4;
  }
  
  // If we don't have any data, return null
  if (scoreComponents.length === 0 || weightSum === 0) {
    return null;
  }
  
  // Calculate weighted average
  const weightedSum = scoreComponents.reduce((sum, component) => sum + (component.score * component.weight), 0);
  const normalizedScore = weightedSum / weightSum;
  
  // Return the score on a 0-100 scale
  return Math.round(normalizedScore * 100);
}

// Get wellness scores for a date range
async function getWellnessScores(userId, startDate, endDate) {
  const db = await getDb();
  
  const scores = await db.all(
    `SELECT date, objective_score, subjective_score, combined_score 
     FROM wellness_scores 
     WHERE user_id = ? AND date BETWEEN ? AND ?
     ORDER BY date ASC`,
    [userId, startDate, endDate]
  );
  
  return scores;
}

module.exports = {
  calculateWellnessScores,
  getWellnessScores
}; 